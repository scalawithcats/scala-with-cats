# Monad Transformers

Monads are [like burritos][link-monads-burritos], which means that once you acquire a taste, you'll find yourself returning to them again and again. This is not without issues. As burritos can bloat the waist, monads can bloat the code base through nested for-comprehensions.

Imagine we are interacting with a database. We want to look up a user record. The user may or may not be present, so we return an `Option[User]`. Our communication with the database could fail for any number of reasons (network issues, authentication problems, database problems, and so on), so this result is wrapped up in a disjunction (`Xor`), giving us a final result of `Xor[Error, Option[User]]`.

To use this value we must nest `flatMap` calls (or equivalently, for-comprehensions):

```tut:book
import cats.data.Xor

// Define some data types representing users and errors:

type Error = String

case class User(id: Long, name: String)

// Define a lookupUser function
// as the source of our nested monad:

def lookupUser(id: Long): Xor[Error, Option[User]] =
  ???

// If we want to look up a user's name,
// we need two nested for comprehensions:

def lookupUserName(id: Long): Xor[Error, Option[String]] =
  for {
    optUser <- lookupUser(id)
  } yield {
    for {
      user <- optUser
    } yield user.name
  }

```

This quickly becomes very tedious.

A question arises. Given two monads, can we make one monad out of them in a generic way? That is, do monads *compose*? We can try to write the code but we'll soon find it impossible to implement `flatMap`:

```scala
// This code won't actually compile.
// It's just illustrating a point.
def compose[M1[_] : Monad, M2[_] : Monad] = {
  type Composed[A] = M1[M2[A]]

  new Monad[Composed] {
    def pure[A](a: A): Composed[A] = a.pure[M2].pure[M1]

    def flatMap[A, B](fa: Composed[A])(f: A => Composed[B]): Composed[B] =
      // This is impossible to implement in general
      // without knowing something about M1 or M2:
      ???
  }
}
```

We can't compose monads in general. This is not greatly surprising because we use monads to model effects and effects don't in general compose. However, some monads can be made to compose with monad-specific glue code. For these special cases we can use *monad transformers* to compose them.

Monad transformers allow us to squash together monads, creating one monad where we previously had two or more. With this transformed monad we can avoid nested calls to `flatMap`. Cats provides a library of such transformers: `XorT` for composing `Xor` with other monads, `OptionT` for composing `Option`, and so on.

## A Transformative Example

Let's see how we can use monad transformers to squash `List` and `Option` into a single monad:

```tut:book
import cats.data.OptionT

type ListOption[A] = OptionT[List, A]
```

`ListOption` is a monad that combines the properties of `List` and `Option`. Note how we build it from the inside out: we pass `List`, the type of the outer monad, as a parameter to `OptionT`, the transformer for the inner monad.

We can create instances with `pure` as usual:

```tut:book
import cats.Monad
import cats.std.list._
import cats.syntax.applicative._

val result: ListOption[Int] = 42.pure[ListOption]
```

The `map` and `flatMap` methods of `Result` combine the corresponding methods of `List` and `Option` into single operations:

```tut:book
val a = 10.pure[ListOption]
val b = 32.pure[ListOption]

a flatMap { (x: Int) =>
  b map { (y: Int) =>
    x + y
  }
}
```

This is the basics of using monad transformers. The combined `map` and `flatMap` methods allow us to use both component monads without having to recursively unpack and repack values at each stage in the computation. Now let's look at the API in more depth.

<div class="callout callout-warning">
*The complexity of imports*

Notice the imports in the code samples above, which hint at how everything is bolting together.

In the code sample where we define `results`, we import [`cats.syntax.applicative`][cats.syntax.applicative] to get the `pure` syntax. `pure` requires an implicit parameter of type `Applicative[ListOption]`. We haven't met `Applicatives` yet, but all `Monads` are also `Applicatives` so we can ignore that difference for now.

We need an `Applicative[ListOption]` to call `pure`. We have [`cats.data.OptionT`][cats.data.OptionT] in scope, which provides the implicits for for `OptionT`. However, in order to generate our `Applicative[ListOption]`, the implicits for `OptionT` also require an `Applicative` for `List`. Hence the additional import from [`cats.std.list`][cats.std.list].

In the second code sample notice we're not importing [`cats.syntax.functor`][cats.syntax.functor] or [`cats.syntax.flatMap`][cats.syntax.flatMap]. This is because `OptionT` is a concrete data type with its own explicit `map` and `flatMap` methods. It wouldn't have hurt to import the syntax---the compiler would have simply ignored it in favour of the explicit methods.

Once again, remember that we're subjecting ourselves to this shenanigans because we're stubbornly refusing to import our implicits from [`cats.implicits`][cats.implicits]. If we did that, everything would just work.
</div>

## Monad Transformers in Cats

Monad transformers are a little different to the other abstractions we've seen---they don't have their own type class in Cats. We normally only use monad transformers to build monads, which we use via the `Monad` type class. Thus the main points of interest when using monad transformers are:

- the available transformer classes;
- building stacks of monads using transformers;
- constructing instances of a monad stack; and
- pulling apart a stack to access the wrapped monads.

### The Monad Transformer Classes

By convention, in Cats a monad `Foo` will have a transformer class called `FooT`. In fact, many monads in Cats are defined by combining a monad transformer with the `Id` monad. Concretely, some of the available instances are:

- [cats.cata.OptionT][cats.data.OptionT] for `Option`;
- [cats.cata.XorT][cats.data.XorT], for `Xor`;
- [cats.cata.ReaderT][cats.data.ReaderT], [cats.cata.WriterT][cats.data.WriterT], and [cats.cata.StateT][cats.data.StateT];
- [cats.cata.IdT][cats.data.IdT], for the `Id` monad.

All of these monad transformers follow the same convention: the first type parameter specifies the monad that is wrapped around the monad implied by the transformer. The remaining type parameters are the types we're used to from the corresponding monads.

### Building Monad Stacks

Building monad stacks is a little confusing until you know the patterns. The first type parameter to a monad transformer is the *outer* monad in the stack---the transformer itself provides the inner monad. For example, our `ListOption` type above was built using `OptionT[List, A]` but the result was effectively a `List[Option[A]]`. In other words, we build monad stacks from the inside out.

Many monads and all transformers have at least two type parameters, so we often have to define type aliases for intermediate stages. For example, suppose we want to wrap `Xor` around `Option`. `Option` is the innermost type so we want to use the `OptionT` monad transformer. We need to use `Xor` as the first type parameter. However, `Xor` itself has two type parameters and monads only have one. We need a *type alias* to make everything the correct shape:

```tut:book
type Error = String

// Create a type alias, ErrorOr, to convert Xor to
// a type constructor with a single parameter:
type ErrorOr[A] = Error Xor A

// Use ErrorOr as a type parameter to OptionT:
type ErrorOptionOr[A] = OptionT[ErrorOr, A]
```

We can use `pure` as usual to create an instance of our monad:

```tut:book
val result = 42.pure[ErrorOptionOr]
```

Now let's add another monad into our stack. Let's create a `Future` of an `Xor` of `Option`. Once again we build this from the inside out. We need an `OptionT` of a `XorT` of `Future`, but we can't define this in one line because `XorT` has three type parameters:

```tut:book:fail
type FutureXorOption[A] = OptionT[XorT[Future, E, _], A]
```

As before, we can fix this by creating a type alias with a single parameter. This time we create an alias for `XorT` that fixes `Future` and `Error` allows `A` to vary:

```tut:book
import scala.concurrent.Future
import cats.data.{XorT, OptionT}

type Error = String
type FutureXor[A] = XorT[Future, String, A]
type FutureXorOption[A] = OptionT[FutureXor, A]
```

Our mammoth stack composes not two but *three* monads. Our `map` and `flatMap` methods cut through three layers of abstraction:

```tut:book
// Because we have Futures in our stack,
// we need an ExecutionContext to map and flatMap:
import scala.concurrent.ExecutionContext
import scala.concurrent.ExecutionContext.Implicits.global

// We need the type class instances for Future to make this all work
// (see the callout on "The Complexity of Implicits" above):
import cats.std.future._

val answer: FutureXorOption[Int] =
  for {
    a <- 10.pure[FutureXorOption]
    b <- 32.pure[FutureXorOption]
  } yield a + b
```

<div class="callout callout-info">
The general pattern for constructing a monad stack is as follows:

- build from the inside out;
- define type aliases with single type parameters for each intermediate layer.
</div>

### Constructing and Unpacking Instances

As we saw above, we can construct instances of our transformed monad stacks by directly injecting values using `pure`. We can also create instances from untransformed stacks using the monad transformer's `apply` method:

```tut:book
// Create using pure:

type ErrorOr[A] = Xor[String, A]
type ErrorOrOption[A] = OptionT[ErrorOr, A]

val monad1 = 123.pure[ErrorOrOption]

// Create using apply:

val stack2: ErrorOr[Option[Int]] = Xor.Right(Some(123))

val monad2: ErrorOrOption[Int] = OptionT(stack2)
```

We need a way to unpack monad transformers once we've used them. Fortunately this is quite straightforward. All monad transformers have a `value` method that extracts the stack within. We can then manipulate the individual monads in the usual way:

```tut:book
monad1.value

monad2.value
```

Each call to `value` unpacks a single monad transformer, so we may need more than one call to completely unpack a large stack:

```tut:book
import cats.data.{Writer, XorT, OptionT}

type Logged[A] = Writer[List[String], A]
type LoggedFallable[A] = XorT[Logged, String, A]
type LoggedFallableOption[A] = OptionT[LoggedFallable, A]

val packed = 123.pure[LoggedFallableOption]

val partiallyUnpacked = packed.value

val unpacked = partiallyUnpacked.value
```

The combination of `apply` and `value` allows us to conveniently use monad transformers as local "glue code" when processing APIs that return nested monads:

```tut:book
type Logged[A] = Writer[List[String], A]

// A method that returns nested monads:

def parseNumber(str: String): Logged[Option[Int]] =
  util.Try(str.toInt).toOption match {
    case Some(num) => Writer(List(s"Read $str"), Some(num))
    case None      => Writer(List(s"Failed on $str"), None)
  }

// We use OptionT to simplify summing the results from parseNumber:

def addNumbers(a: String, b: String, c: String): Logged[Option[Int]] = {
  val result = for {
    a <- OptionT(parseNumber(a))
    b <- OptionT(parseNumber(b))
    c <- OptionT(parseNumber(c))
  } yield a + b + c

  result.value
}

addNumbers("1", "2", "3")
addNumbers("1", "a", "3")
```

### Default Instances

Many monads in Cats are defined using the corresponding transformer and the `Id` monad. This is reassuring as it confirms that the APIs for these monads and transformers are identical. `Reader`, `Writer`, and `State` are all defined in this way:

```scala
type Reader[E, A] = ReaderT[Id, E, A]
type Writer[W, A] = WriterT[Id, W, A]
type State[S, A]  = StateT[Id, S, A]
```

In other cases monad transformers have separate definitions to their corresponding monads. In these cases, the methods of the transformer tend to mirror the methods on the monad. For example, `OptionT` defines `getOrElse`, and `XorT` defines `fold`, `bimap`, `swap`, and other useful methods.

## Exercise: Using Monad Transformers

Let's use monad transformers to model a classic combination of `Future` and `Xor`.
Start by defining appropriate type aliases to wrap `Xor` in `Future`,
using `String` as the error type. Call the transformer stack `FutureXor`.

<div class="solution">
This is a relatively simple combination.
We want `Future` on the outside and `Xor` on the inside,
so we build from the inside out using an `XorT` of `Future`:

```tut:book
import cats.data.XorT
import scala.concurrent.Future

type FutureXor[A] = XorT[Future, String, A]
```
</div>

Now let's define a simple analytics system to collate load averages from a set of imaginary servers.
Here's the data we'll use:

```tut:book
val loadAverages = Map(
  "a.example.com" -> 0.1,
  "b.example.com" -> 0.5,
  "c.example.com" -> 0.2
)
```

We'll pretend these are real servers that we have to contact asynchronously.
Let's define a `getLoad` function that accepts a hostname as a parameter and returns its load average:

```tut:book
def getLoad(hostname: String): FutureXor[Double] =
  ???
```

If `hostname` isn't in the `loadAverages` map, return an error message reporting that the host was unreachable.
Include `hostname` in the message for good effect.

<div class="solution">
```tut:book
import cats.std.future._
import cats.syntax.flatMap._
import scala.concurrent.ExecutionContext.Implicits.global

type FutureXor2[E, A] = XorT[Future, E, A]

def getLoad(hostname: String): FutureXor[Double] = {
  loadAverages.get(hostname) match {
    case Some(avg) => XorT.right(Future.successful(avg))
    case None      => XorT.left(Future.successful(s"Host unreachable: $hostname"))
  }
}
```
</div>

Write another method, `getMeanLoad`, which accepts a list of hostnames as a parameter
and returns the mean load average across all of them.
If any hosts are unreachable, fail with an appropriate error message.

```tut:book
def getMeanLoad(hostnames: List[String]): FutureXor[Double] =
  ???
```

<div class="solution">
We `map` over the list of hostnames colleting load averages from each server
and use `sequence` to combine the results.

The `map`, `flatMap`, and `sequence` methods cut through both layers in our monad stack,
allowing us to combine the results without hassle:

```tut:book
import cats.std.list._        // for Applicative[List]
import cats.syntax.traverse._ // for _.sequence

def getMeanLoad(hostnames: List[String]): FutureXor[Double] =
  hostnames.length match {
    case 0 => XorT.left(Future.successful(s"No hosts to contact"))
    case n => hostnames.map(getLoad).sequence.map(_.sum / n)
  }
```
</div>

Finally, write a method `report` that takes a `FutureXor` and prints the value within with an appropriate prefix based on whether the operation was a success or failure.

```tut:book
def report[A](input: FutureXor[A]): Unit = ???
```

You should be able to use `report` and `getMeanLoad` to query sets of hosts as follows:

```scala
report(getMeanLoad(List("a.example.com", "b.example.com")))
report(getMeanLoad(List("a.example.com", "c.example.com")))
report(getMeanLoad(List("a.example.com", "d.example.com")))
```

<div class="solution">
This is a simple exercise of peeling back layers until we have access to the disjunction at the bottom of our stack. We use `value` to unpack the monad transformer, `Await.result` to block on the `Future`, and `fold` to handle the disjunction:

```tut:book
import scala.concurrent.Await
import scala.concurrent.duration._

def report[A](input: FutureXor[A]): Unit =
  Await.result(input.value, 2.seconds).fold(
    msg => println("[FAIL] " + msg),
    ans => println("[DONE] " + ans)
  )

report(getMeanLoad(List("a.example.com", "b.example.com")))
report(getMeanLoad(List("a.example.com", "c.example.com")))
report(getMeanLoad(List("a.example.com", "d.example.com")))
```
</div>
