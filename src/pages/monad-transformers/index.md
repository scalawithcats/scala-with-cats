# Monad Transformers

Monads are [like burritos][link-monads-burritos], which means that once you acquire a taste, you'll find yourself returning to them again and again. This is not without issues. As burritos can bloat the waist, monads can bloat the code base through nested for-comprehensions.

Imagine we are interacting with a database. We want to look up a user record. The user may or may not be present, so we return an `Option[User]`. Our communication with the database could fail for any number of reasons (network issues, authentication problems, database problems, and so on), so this result is wrapped up in a disjunction (`Xor`), giving us a final result of `Xor[Error, Option[User]]`.

To use this value we must nest `flatMap` calls (or equivalently, for-comprehensions):




```scala
import cats.data.Xor
// import cats.data.Xor

def lookupUserName(id: Long): Xor[Error, Option[String]] =
  for {
    optUser <- lookupUser(id)
  } yield {
    for {
      user <- optUser
    } yield user.name
  }
// lookupUserName: (id: Long)cats.data.Xor[Error,Option[String]]
```

This quickly becomes very tedious.

A question arises. Given two monads, can we make one monad out of them in a generic way? That is, do monads *compose*? We can try to write the code but we'll soon find it impossible to implement `flatMap`:

```scala
// This code won't actually compile.
// It's just illustrating a point:
def compose[M1[_] : Monad, M2[_] : Monad] = {
  type Composed[A] = M1[M2[A]]

  new Monad[Composed] {
    def pure[A](a: A): Composed[A] =
      a.pure[M2].pure[M1]

    def flatMap[A, B](fa: Composed[A])(f: A => Composed[B]): Composed[B] =
      // This is impossible to implement in general
      // without knowing something about M1 or M2:
      ???
  }
}
```

We can't compose monads in general. This is not greatly surprising because we use monads to model effects and effects don't in general compose. However, some monads can be made to compose with monad-specific glue code. For these special cases we can use *monad transformers* to compose them.

Monad transformers allow us to squash together monads, creating one monad where we previously had two or more. With this transformed monad we can avoid nested calls to `flatMap`.

## A Transformative Example

Cats provides a library of such transformers: `XorT` for composing `Xor` with other monads, `OptionT` for composing `Option`, and so on. Here's an example that uses `OptionT` to squash `List` and `Option` into a single monad:

```scala
import cats.data.OptionT
// import cats.data.OptionT

type ListOption[A] = OptionT[List, A]
// defined type alias ListOption
```

`ListOption` is a monad that combines the properties of `List` and `Option`. Note how we build it from the inside out: we pass `List`, the type of the outer monad, as a parameter to `OptionT`, the transformer for the inner monad.

We can create instances with `pure` as usual:

```scala
import cats.Monad
// import cats.Monad

import cats.std.list._
// import cats.std.list._

import cats.syntax.applicative._
// import cats.syntax.applicative._

val result: ListOption[Int] = 42.pure[ListOption]
// result: ListOption[Int] = OptionT(List(Some(42)))
```

The `map` and `flatMap` methods of `Result` combine the corresponding methods of `List` and `Option` into single operations:

```scala
val a = 10.pure[ListOption]
// a: ListOption[Int] = OptionT(List(Some(10)))

val b = 32.pure[ListOption]
// b: ListOption[Int] = OptionT(List(Some(32)))

a flatMap { (x: Int) =>
  b map { (y: Int) =>
    x + y
  }
}
// res0: cats.data.OptionT[List,Int] = OptionT(List(Some(42)))
```

This is the basics of using monad transformers. The combined `map` and `flatMap` methods allow us to use both component monads without having to recursively unpack and repack values at each stage in the computation. Now let's look at the API in more depth.

<div class="callout callout-warning">
*The complexity of imports*

Note the imports in the code samples above---they hint at how everything bolts together.

We import [`cats.syntax.applicative`][cats.syntax.applicative] to get the `pure` syntax. `pure` requires an implicit parameter of type `Applicative[ListOption]`. We haven't met `Applicatives` yet, but all `Monads` are also `Applicatives` so we can ignore that difference for now.

We need an `Applicative[ListOption]` to call `pure`. We have [`cats.data.OptionT`][cats.data.OptionT] in scope, which provides the implicits for for `OptionT`. However, in order to generate our `Applicative[ListOption]`, the implicits for `OptionT` also require an `Applicative` for `List`. Hence the additional import from [`cats.std.list`][cats.std.list].

Notice we're not importing [`cats.syntax.functor`][cats.syntax.functor] or [`cats.syntax.flatMap`][cats.syntax.flatMap]. This is because `OptionT` is a concrete data type with its own explicit `map` and `flatMap` methods. It wouldn't hurt to import the syntax---the compiler will simply ignore it in favour of the explicit methods.

Remember that we're subjecting ourselves to this shenanigans because we're stubbornly refusing to import our implicits from [`cats.implicits`][cats.implicits]. If we did that, everything would just work.
</div>

## Monad Transformers in Cats

Monad transformers are a little different to the other abstractions we've seen---they don't have their own type class. We use monad transformers to build monads, which we then use via the `Monad` type class. Thus the main points of interest when using monad transformers are:

- the available transformer classes;
- building stacks of monads using transformers;
- constructing instances of a monad stack; and
- pulling apart a stack to access the wrapped monads.

### The Monad Transformer Classes

By convention, in Cats a monad `Foo` will have a transformer class called `FooT`. In fact, many monads in Cats are defined by combining a monad transformer with the `Id` monad. Concretely, some of the available instances are:

- [cats.cata.OptionT][cats.data.OptionT] for `Option`;
- [cats.cata.XorT][cats.data.XorT] for [`Xor`][cats.data.Xor];
- [cats.cata.ReaderT][cats.data.ReaderT],
  [cats.cata.WriterT][cats.data.WriterT], and
  [cats.cata.StateT][cats.data.StateT];
- [cats.cata.IdT][cats.data.IdT] for the [`Id`][cats.Id] monad.

All of these monad transformers follow the same convention: the first type parameter specifies the monad that is wrapped around the monad implied by the transformer. The remaining type parameters are the types we're used to from the corresponding monads.

### Building Monad Stacks

Building monad stacks is a little confusing until you know the patterns. The first type parameter to a monad transformer is the *outer* monad in the stack---the transformer itself provides the inner monad. For example, our `ListOption` type above was built using `OptionT[List, A]` but the result was effectively a `List[Option[A]]`. In other words, we build monad stacks from the inside out.

Many monads and all transformers have at least two type parameters, so we often have to define type aliases for intermediate stages. For example, suppose we want to wrap `Xor` around `Option`. `Option` is the innermost type so we want to use the `OptionT` monad transformer. We need to use `Xor` as the first type parameter. However, `Xor` itself has two type parameters and monads only have one. We need a *type alias* to make everything the correct shape:

```scala
type Error = String
// defined type alias Error

// Create a type alias, ErrorOr, to convert Xor to
// a type constructor with a single parameter:
type ErrorOr[A] = Error Xor A
// defined type alias ErrorOr

// Use ErrorOr as a type parameter to OptionT:
type ErrorOptionOr[A] = OptionT[ErrorOr, A]
// defined type alias ErrorOptionOr
```

`ErrorOptionOr` is a monad. We can use `pure` and `flatMap` as usual to create and transform instances:

```scala
val result1 = 41.pure[ErrorOptionOr]
// result1: ErrorOptionOr[Int] = OptionT(Right(Some(41)))

val result2 = result1.flatMap(x => (x + 1).pure[ErrorOptionOr])
// result2: cats.data.OptionT[ErrorOr,Int] = OptionT(Right(Some(42)))
```

Now let's add another monad into our stack. Let's create a `Future` of an `Xor` of `Option`. Once again we build this from the inside out with an `OptionT` of a `XorT` of `Future`. However, we can't define this in one line because `XorT` has three type parameters:

```scala
type FutureXorOption[A] = OptionT[XorT[Future, E, _], A]
// <console>:21: error: not found: type XorT
//        type FutureXorOption[A] = OptionT[XorT[Future, E, _], A]
//                                          ^
```

As before, we solve the problem by creating a type alias with a single parameter. This time we create an alias for `XorT` that fixes `Future` and `Error` and allows `A` to vary:

```scala
import scala.concurrent.Future
// import scala.concurrent.Future

import cats.data.{XorT, OptionT}
// import cats.data.{XorT, OptionT}

type Error = String
// defined type alias Error

type FutureXor[A] = XorT[Future, String, A]
// defined type alias FutureXor

type FutureXorOption[A] = OptionT[FutureXor, A]
// defined type alias FutureXorOption
```

Our mammoth stack composes not two but *three* monads. Our `map` and `flatMap` methods cut through three layers of abstraction:

```scala
// We need an ExecutionContext to summon monad instances involving futures:
import scala.concurrent.ExecutionContext.Implicits.global
// import scala.concurrent.ExecutionContext.Implicits.global

import cats.std.future._
// import cats.std.future._

val answer: FutureXorOption[Int] =
  for {
    a <- 10.pure[FutureXorOption]
    b <- 32.pure[FutureXorOption]
  } yield a + b
// answer: FutureXorOption[Int] = OptionT(XorT(scala.concurrent.impl.Promise$DefaultPromise@28c485c4))
```

<div class="callout callout-info">
The general pattern for constructing a monad stack is as follows:

- build from the inside out;
- define type aliases with single type parameters for each intermediate layer.
</div>

### Constructing and Unpacking Instances

As we saw above, we can use `pure` to directly inject raw values into transformed monad stacks. We can also create instances from untransformed stacks using the monad transformer's `apply` method:

```scala
type ErrorOr[A] = Xor[String, A]
// defined type alias ErrorOr

type ErrorOrOption[A] = OptionT[ErrorOr, A]
// defined type alias ErrorOrOption

// Create using pure:
val monad1: ErrorOrOption[Int] =
  123.pure[ErrorOrOption]
// monad1: ErrorOrOption[Int] = OptionT(Right(Some(123)))

// Create using apply:
val monad2: ErrorOrOption[Int] =
  OptionT[ErrorOr, Int](Xor.right[String, Option[Int]](Some(123)))
// monad2: ErrorOrOption[Int] = OptionT(Right(Some(123)))
```

Once we've used a monad transformer, we can unpack it using its `value` method. This returns the untransformed stack. We can then manipulate the individual monads in the usual way:

```scala
monad1.value
// res7: ErrorOr[Option[Int]] = Right(Some(123))

monad2.value
// res8: ErrorOr[Option[Int]] = Right(Some(123))
```

Each call to `value` unpacks a single monad transformer, so we may need more than one call to completely unpack a large stack:

```scala
import cats.data.{Writer, XorT, OptionT}
// import cats.data.{Writer, XorT, OptionT}

type Logged[A] = Writer[List[String], A]
// defined type alias Logged

type LoggedFallable[A] = XorT[Logged, String, A]
// defined type alias LoggedFallable

type LoggedFallableOption[A] = OptionT[LoggedFallable, A]
// defined type alias LoggedFallableOption

val packed = 123.pure[LoggedFallableOption]
// packed: LoggedFallableOption[Int] = OptionT(XorT(WriterT((List(),Right(Some(123))))))

val partiallyPacked = packed.value
// partiallyPacked: LoggedFallable[Option[Int]] = XorT(WriterT((List(),Right(Some(123)))))

val completelyUnpacked = partiallyPacked.value
// completelyUnpacked: Logged[cats.data.Xor[String,Option[Int]]] = WriterT((List(),Right(Some(123))))
```

### Usage Patterns

Widespread use of monad tranformers can sometimes causes inconvenience because they fuse monads together in predefined ways. Without careful thought, we can end up having to unpack and repack monads in different configurations to operate on them in different contexts.

One way of avoiding this is to use monad transformers as local "glue code". Expose untransformed stacks at module boundaries, transform them to operate on them locally, and untransform them before passing them on. This allows each module of code to make its own decisions about which transformers to use. Here's an example:

```scala
type Logged[A] = Writer[List[String], A]
// defined type alias Logged

// Example method that returns nested monads:
def parseNumber(str: String): Logged[Option[Int]] =
  util.Try(str.toInt).toOption match {
    case Some(num) => Writer(List(s"Read $str"), Some(num))
    case None      => Writer(List(s"Failed on $str"), None)
  }
// parseNumber: (str: String)Logged[Option[Int]]

// Example combining multiple calls to parseNumber:
def addNumbers(a: String, b: String, c: String): Logged[Option[Int]] = {
  import cats.data.OptionT

  // Transform the incoming stacks to work on them:
  val result = for {
    a <- OptionT(parseNumber(a))
    b <- OptionT(parseNumber(b))
    c <- OptionT(parseNumber(c))
  } yield a + b + c

  // Return the untransformed monad stack:
  result.value
}
// addNumbers: (a: String, b: String, c: String)Logged[Option[Int]]

// OptionT isn't forced on user code:
val result1 = addNumbers("1", "2", "3")
// result1: Logged[Option[Int]] = WriterT((List(Read 1, Read 2, Read 3),Some(6)))

val result2 = addNumbers("1", "a", "3")
// result2: Logged[Option[Int]] = WriterT((List(Read 1, Failed on a),None))
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

```scala
import cats.data.XorT
// import cats.data.XorT

import scala.concurrent.Future
// import scala.concurrent.Future

type FutureXor[A] = XorT[Future, String, A]
// defined type alias FutureXor
```
</div>

Now let's define a simple analytics system to collate load averages from a set of imaginary servers.
Here's the data we'll use:

```scala
val loadAverages = Map(
  "a.example.com" -> 0.1,
  "b.example.com" -> 0.5,
  "c.example.com" -> 0.2
)
// loadAverages: scala.collection.immutable.Map[String,Double] = Map(a.example.com -> 0.1, b.example.com -> 0.5, c.example.com -> 0.2)
```

We'll pretend these are real servers that we have to contact asynchronously.
Let's define a `getLoad` function that accepts a hostname as a parameter and returns its load average:

```scala
def getLoad(hostname: String): FutureXor[Double] =
  ???
// getLoad: (hostname: String)FutureXor[Double]
```

If `hostname` isn't in the `loadAverages` map, return an error message reporting that the host was unreachable.
Include `hostname` in the message for good effect.

<div class="solution">
```scala
import cats.std.future._
// import cats.std.future._

import cats.syntax.flatMap._
// import cats.syntax.flatMap._

import scala.concurrent.ExecutionContext.Implicits.global
// import scala.concurrent.ExecutionContext.Implicits.global

type FutureXor2[E, A] = XorT[Future, E, A]
// defined type alias FutureXor2

def getLoad(hostname: String): FutureXor[Double] = {
  loadAverages.get(hostname) match {
    case Some(avg) => XorT.right(Future.successful(avg))
    case None      => XorT.left(Future.successful(s"Host unreachable: $hostname"))
  }
}
// getLoad: (hostname: String)FutureXor[Double]
```
</div>

Write another method, `getMeanLoad`, which accepts a list of hostnames as a parameter
and returns the mean load average across all of them.
If any hosts are unreachable, fail with an appropriate error message.

```scala
def getMeanLoad(hostnames: List[String]): FutureXor[Double] =
  ???
// getMeanLoad: (hostnames: List[String])FutureXor[Double]
```

<div class="solution">
We `map` over the list of hostnames colleting load averages from each server
and use `sequence` to combine the results.

The `map`, `flatMap`, and `sequence` methods cut through both layers in our monad stack,
allowing us to combine the results without hassle:

```scala
import cats.std.list._        // for Applicative[List]
// import cats.std.list._

import cats.syntax.traverse._ // for _.sequence
// import cats.syntax.traverse._

def getMeanLoad(hostnames: List[String]): FutureXor[Double] =
  hostnames.length match {
    case 0 => XorT.left(Future.successful(s"No hosts to contact"))
    case n => hostnames.map(getLoad).sequence.map(_.sum / n)
  }
// getMeanLoad: (hostnames: List[String])FutureXor[Double]
```
</div>

Finally, write a method `report` that takes a `FutureXor` and prints the value within with an appropriate prefix based on whether the operation was a success or failure.

```scala
def report[A](input: FutureXor[A]): Unit = ???
// report: [A](input: FutureXor[A])Unit
```

You should be able to use `report` and `getMeanLoad` to query sets of hosts as follows:

```scala
report(getMeanLoad(List("a.example.com", "b.example.com")))
report(getMeanLoad(List("a.example.com", "c.example.com")))
report(getMeanLoad(List("a.example.com", "d.example.com")))
```

<div class="solution">
This is a simple exercise of peeling back layers until we have access to the disjunction at the bottom of our stack. We use `value` to unpack the monad transformer, `Await.result` to block on the `Future`, and `fold` to handle the disjunction:

```scala
import scala.concurrent.Await
// import scala.concurrent.Await

import scala.concurrent.duration._
// import scala.concurrent.duration._

def report[A](input: FutureXor[A]): Unit =
  Await.result(input.value, 2.seconds).fold(
    msg => println("[FAIL] " + msg),
    ans => println("[DONE] " + ans)
  )
// report: [A](input: FutureXor[A])Unit

report(getMeanLoad(List("a.example.com", "b.example.com")))
// [DONE] 0.3

report(getMeanLoad(List("a.example.com", "c.example.com")))
// [DONE] 0.15000000000000002

report(getMeanLoad(List("a.example.com", "d.example.com")))
// [FAIL] Host unreachable: d.example.com
```
</div>

## Exercise: *ReaderWriterState*

<div class="callout callout-danger">
  TODO: Scalaz provides a ReaderWriterState monad. Cats doesn't.
  Implement it using `ReaderT`, `WriterT`, and `StateT`.
</div>
