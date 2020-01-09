# Monad Transformers {#sec:monad-transformers}

Monads are [like burritos][link-monads-burritos],
which means that once you acquire a taste,
you'll find yourself returning to them again and again.
This is not without issues.
As burritos can bloat the waist,
monads can bloat the code base through nested for-comprehensions.

Imagine we are interacting with a database.
We want to look up a user record.
The user may or may not be present, so we return an `Option[User]`.
Our communication with the database could fail for many reasons
(network issues, authentication problems, and so on),
so this result is wrapped up in an `Either`,
giving us a final result of `Either[Error, Option[User]]`.

To use this value we must nest `flatMap` calls
(or equivalently, for-comprehensions):

```tut:invisible
type Error = String

final case class User(id: Long, name: String)

def lookupUser(id: Long): Either[Error, Option[User]] = ???
```

```tut:book:silent
def lookupUserName(id: Long): Either[Error, Option[String]] =
  for {
    optUser <- lookupUser(id)
  } yield {
    for { user <- optUser } yield user.name
  }
```

This quickly becomes very tedious.

## Exercise: Composing Monads

A question arises.
Given two arbitrary monads,
can we combine them in some way to make a single monad?
That is, do monads *compose*?
We can try to write the code but we soon hit problems:

```tut:book:silent
import cats.Monad
import cats.syntax.applicative._ // for pure
import cats.syntax.flatMap._     // for flatMap
import scala.language.higherKinds
```

```scala
// Hypothetical example. This won't actually compile:
def compose[M1[_]: Monad, M2[_]: Monad] = {
  type Composed[A] = M1[M2[A]]

  new Monad[Composed] {
    def pure[A](a: A): Composed[A] =
      a.pure[M2].pure[M1]

    def flatMap[A, B](fa: Composed[A])
        (f: A => Composed[B]): Composed[B] =
      // Problem! How do we write flatMap?
      ???
  }
}
```

It is impossible to write a general definition of `flatMap`
without knowing something about `M1` or `M2`.
However, if we *do* know something about one or other monad,
we can typically complete this code.
For example, if we fix `M2` above to be `Option`,
a definition of `flatMap` comes to light:

```scala
def flatMap[A, B](fa: Composed[A])
    (f: A => Composed[B]): Composed[B] =
  fa.flatMap(_.fold[Composed[B]](None.pure[M1])(f))
```

Notice that the definition above makes use of `None`---an
`Option`-specific concept that
doesn't appear in the general `Monad` interface.
We need this extra detail to combine `Option` with other monads.
Similarly, there are things about other monads
that help us write composed `flatMap` methods for them.
This is the idea behind monad transformers:
Cats defines transformers for a variety of monads,
each providing the extra knowledge we need
to compose that monad with others.
Let's look at some examples.

## A Transformative Example

Cats provides transformers for many monads,
each named with a `T` suffix:
`EitherT` composes `Either` with other monads,
`OptionT` composes `Option`, and so on.

Here's an example that uses `OptionT`
to compose `List` and `Option`.
We can use `OptionT[List, A]`,
aliased to `ListOption[A]` for convenience,
to transform a `List[Option[A]]` into a single monad:

```tut:book:silent
import cats.data.OptionT

type ListOption[A] = OptionT[List, A]
```

Note how we build `ListOption` from the inside out:
we pass `List`, the type of the outer monad,
as a parameter to `OptionT`,
the transformer for the inner monad.

We can create instances of `ListOption`
using the `OptionT` constructor,
or more conveniently using `pure`:

```tut:book:silent
import cats.Monad
import cats.instances.list._     // for Monad
import cats.syntax.applicative._ // for pure
```

```tut:book
val result1: ListOption[Int] = OptionT(List(Option(10)))

val result2: ListOption[Int] = 32.pure[ListOption]
```

The `map` and `flatMap` methods
combine the corresponding methods of `List` and `Option`
into single operations:

```tut:book
result1.flatMap { (x: Int) =>
  result2.map { (y: Int) =>
    x + y
  }
}
```

This is the basis of all monad transformers.
The combined `map` and `flatMap` methods
allow us to use both component monads
without having to recursively unpack
and repack values at each stage in the computation.
Now let's look at the API in more depth.

<div class="callout callout-warning">
*Complexity of Imports*

The imports in the code samples above
hint at how everything bolts together.

We import [`cats.syntax.applicative`][cats.syntax.applicative]
to get the `pure` syntax.
`pure` requires an implicit parameter of type `Applicative[ListOption]`.
We haven't met `Applicatives` yet,
but all `Monads` are also `Applicatives`
so we can ignore that difference for now.

In order to generate our `Applicative[ListOption]`
we need instances of `Applicative` for `List` and `OptionT`.
`OptionT` is a Cats data type so its instance
is provided by its companion object.
The instance for `List` comes from
[`cats.instances.list`][cats.instances.list].

Notice we're not importing
[`cats.syntax.functor`][cats.syntax.functor] or
[`cats.syntax.flatMap`][cats.syntax.flatMap].
This is because `OptionT` is a concrete data type
with its own explicit `map` and `flatMap` methods.
It wouldn't cause problems if we imported the syntax---the
compiler would ignore it in favour of the explicit methods.

Remember that we're subjecting ourselves to these shenanigans
because we're stubbornly refusing to use the universal Cats import,
[`cats.implicits`][cats.implicits].
If we did use that import,
all of the instances and syntax we needed would be in scope
and everything would just work.
</div>

## Monad Transformers in Cats

Each monad transformer is a data type,
defined in [`cats.data`][cats.data],
that allows us to *wrap* stacks of monads
to produce new monads.
We use the monads we've built via the `Monad` type class.
The main concepts we have to cover
to understand monad transformers are:

- the available transformer classes;
- how to build stacks of monads using transformers;
- how to construct instances of a monad stack; and
- how to pull apart a stack to access the wrapped monads.

### The Monad Transformer Classes

By convention, in Cats a monad `Foo`
will have a transformer class called `FooT`.
In fact, many monads in Cats are defined
by combining a monad transformer with the `Id` monad.
Concretely, some of the available instances are:

- [`cats.data.OptionT`][cats.data.OptionT] for `Option`;
- [`cats.data.EitherT`][cats.data.EitherT] for `Either`;
- [`cats.data.ReaderT`][cats.data.ReaderT] for `Reader`;
- [`cats.data.WriterT`][cats.data.WriterT] for `Writer`;
- [`cats.data.StateT`][cats.data.StateT] for `State`;
- [`cats.data.IdT`][cats.data.IdT] for the [`Id`][cats.Id] monad.

<div class="callout callout-info">
*Kleisli Arrows*

In Section [@sec:monads:reader]
we mentioned that the `Reader` monad was a specialisation
of a more general concept called a "kleisli arrow",
represented in Cats as
[`cats.data.Kleisli`][cats.data.Kleisli].

We can now reveal that `Kleisli` and `ReaderT`
are, in fact, the same thing!
`ReaderT` is actually a type alias for `Kleisli`.
Hence, we were creating `Readers` last chapter
and seeing `Kleislis` on the console.
</div>

### Building Monad Stacks

All of these monad transformers follow the same convention.
The transformer itself represents the *inner* monad in a stack,
while the first type parameter specifies the outer monad.
The remaining type parameters are the types
we've used to form the corresponding monads.

For example, our `ListOption` type above
is an alias for `OptionT[List, A]`
but the result is effectively a `List[Option[A]]`.
In other words, we build monad stacks from the inside out:

```tut:book:silent
type ListOption[A] = OptionT[List, A]
```

Many monads and all transformers have at least two type parameters,
so we often have to define type aliases for intermediate stages.

For example, suppose we want to wrap `Either` around `Option`.
`Option` is the innermost type
so we want to use the `OptionT` monad transformer.
We need to use `Either` as the first type parameter.
However, `Either` itself has two type parameters
and monads only have one.
We need a type alias
to convert the type constructor to the correct shape:

```tut:book:silent
// Alias Either to a type constructor with one parameter:
type ErrorOr[A] = Either[String, A]

// Build our final monad stack using OptionT:
type ErrorOrOption[A] = OptionT[ErrorOr, A]
```

`ErrorOrOption` is a monad, just like `ListOption`.
We can use `pure`, `map`, and `flatMap` as usual
to create and transform instances:

```tut:book:silent
import cats.instances.either._ // for Monad
```

```tut:book
val a = 10.pure[ErrorOrOption]
val b = 32.pure[ErrorOrOption]

val c = a.flatMap(x => b.map(y => x + y))
```

Things become even more confusing
when we want to stack three or more monads.

For example, let's create a `Future` of an `Either` of `Option`.
Once again we build this from the inside out
with an `OptionT` of an `EitherT` of `Future`.
However, we can't define this in one line
because `EitherT` has three type parameters:

```scala
case class EitherT[F[_], E, A](stack: F[Either[E, A]]) {
  // etc...
}
```

The three type parameters are as follows:

- `F[_]` is the outer monad in the stack (`Either` is the inner);
- `E` is the error type for the `Either`;
- `A` is the result type for the `Either`.

This time we create an alias for `EitherT` that
fixes `Future` and `Error` and allows `A` to vary:

```tut:book:silent
import scala.concurrent.Future
import cats.data.{EitherT, OptionT}

type FutureEither[A] = EitherT[Future, String, A]

type FutureEitherOption[A] = OptionT[FutureEither, A]
```

Our mammoth stack now composes three monads
and our `map` and `flatMap` methods
cut through three layers of abstraction:

```tut:book:silent
import cats.instances.future._ // for Monad
import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._
```

```tut:book:silent
val futureEitherOr: FutureEitherOption[Int] =
  for {
    a <- 10.pure[FutureEitherOption]
    b <- 32.pure[FutureEitherOption]
  } yield a + b
```

<div class="callout callout-warning">
*Kind Projector*

If you frequently find yourself
defining multiple type aliases when building monad stacks,
you may want to try
the [Kind Projector][link-kind-projector] compiler plugin.
Kind Projector enhances Scala's type syntax
to make it easier to define partially applied type constructors.
For example:

```tut:book
import cats.instances.option._ // for Monad

123.pure[EitherT[Option, String, ?]]
```

Kind Projector can't simplify all type declarations down to a single line,
but it can reduce the number of intermediate type definitions
needed to keep our code readable.
</div>

### Constructing and Unpacking Instances

As we saw above, we can create transformed monad stacks
using the relevant monad transformer's `apply` method
or the usual `pure` syntax[^eithert-monad-error]:

```tut:book
// Create using apply:
val errorStack1 = OptionT[ErrorOr, Int](Right(Some(10)))

// Create using pure:
val errorStack2 = 32.pure[ErrorOrOption]
```

[^eithert-monad-error]: Cats provides an instance
of `MonadError` for `EitherT`,
allowing us to create instances
using `raiseError` as well as `pure`.

Once we've finished with a monad transformer stack,
we can unpack it using its `value` method.
This returns the untransformed stack.
We can then manipulate the individual monads in the usual way:

```tut:book
// Extracting the untransformed monad stack:
errorStack1.value

// Mapping over the Either in the stack:
errorStack2.value.map(_.getOrElse(-1))
```

Each call to `value` unpacks a single monad transformer.
We may need more than one call to completely unpack a large stack.
For example, to `Await` the `FutureEitherOption` stack above,
we need to call `value` twice:

```tut:book
futureEitherOr

val intermediate = futureEitherOr.value

val stack = intermediate.value

Await.result(stack, 1.second)
```

### Default Instances

Many monads in Cats are defined
using the corresponding transformer and the `Id` monad.
This is reassuring as it confirms
that the APIs for monads and transformers are identical.
`Reader`, `Writer`, and `State`
are all defined in this way:

```scala
type Reader[E, A] = ReaderT[Id, E, A] // = Kleisli[Id, E, A]
type Writer[W, A] = WriterT[Id, W, A]
type State[S, A]  = StateT[Id, S, A]
```

In other cases monad transformers
are defined separately to their corresponding monads.
In these cases, the methods of the transformer tend
to mirror the methods on the monad.
For example, `OptionT` defines `getOrElse`,
and `EitherT` defines `fold`, `bimap`, `swap`,
and other useful methods.

### Usage Patterns

Widespread use of monad transformers is sometimes difficult
because they fuse monads together in predefined ways.
Without careful thought,
we can end up having to unpack and repack monads
in different configurations
to operate on them in different contexts.

We can cope with this in multiple ways.
One approach involves creating a single "super stack"
and sticking to it throughout our code base.
This works if the code is simple and largely uniform in nature.
For example, in a web application,
we could decide that all request handlers are asynchronous
and all can fail with the same set of HTTP error codes.
We could design a custom ADT representing the errors
and use a fusion `Future` and `Either` everywhere in our code:

```tut:book:silent
sealed abstract class HttpError
final case class NotFound(item: String) extends HttpError
final case class BadRequest(msg: String) extends HttpError
// etc...

type FutureEither[A] = EitherT[Future, HttpError, A]
```

The "super stack" approach starts to fail in larger,
more heterogeneous code bases
where different stacks make sense in different contexts.
Another design pattern that makes more sense in these contexts
uses monad transformers as local "glue code".
We expose untransformed stacks at module boundaries,
transform them to operate on them locally,
and untransform them before passing them on.
This allows each module of code to make its own decisions
about which transformers to use:

```tut:book:silent
import cats.data.Writer

type Logged[A] = Writer[List[String], A]

// Methods generally return untransformed stacks:
def parseNumber(str: String): Logged[Option[Int]] =
  util.Try(str.toInt).toOption match {
    case Some(num) => Writer(List(s"Read $str"), Some(num))
    case None      => Writer(List(s"Failed on $str"), None)
  }

// Consumers use monad transformers locally to simplify composition:
def addAll(a: String, b: String, c: String): Logged[Option[Int]] = {
  import cats.data.OptionT

  val result = for {
    a <- OptionT(parseNumber(a))
    b <- OptionT(parseNumber(b))
    c <- OptionT(parseNumber(c))
  } yield a + b + c

  result.value
}
```

```tut:book
// This approach doesn't force OptionT on other users' code:
val result1 = addAll("1", "2", "3")
val result2 = addAll("1", "a", "3")
```

Unfortunately, there aren't one-size-fits-all
approaches to working with monad transformers.
The best approach for you may depend on a lot of factors:
the size and experience of your team,
the complexity of your code base, and so on.
You may need to experiment and gather feedback from colleagues
to determine whether monad transformers are a good fit.

## Exercise: Monads: Transform and Roll Out

The Autobots, well-known robots in disguise,
frequently send messages during battle
requesting the power levels of their team mates.
This helps them coordinate strategies
and launch devastating attacks.
The message sending method looks like this:

```scala
def getPowerLevel(autobot: String): Response[Int] =
  ???
```

Transmissions take time in Earth's viscous atmosphere,
and messages are occasionally lost
due to satellite malfunction or sabotage by pesky Decepticons[^transformers].
`Responses` are therefore represented as a stack of monads:

```tut:book
type Response[A] = Future[Either[String, A]]
```

[^transformers]: It is a well known fact
that Autobot neural nets are implemented in Scala.
Decepticon brains are, of course, dynamically typed.

Optimus Prime is getting tired of
the nested for comprehensions in his neural matrix.
Help him by rewriting `Response` using a monad transformer.

<div class="solution">
This is a relatively simple combination.
We want `Future` on the outside
and `Either` on the inside,
so we build from the inside out
using an `EitherT` of `Future`:

```tut:book:silent
import cats.data.EitherT
import scala.concurrent.Future

type Response[A] = EitherT[Future, String, A]
```
</div>

Now test the code by implementing `getPowerLevel`
to retrieve data from a set of imaginary allies.
Here's the data we'll use:

```tut:book:silent
val powerLevels = Map(
  "Jazz"      -> 6,
  "Bumblebee" -> 8,
  "Hot Rod"   -> 10
)
```

If an Autobot isn't in the `powerLevels` map,
return an error message reporting
that they were unreachable.
Include the `name` in the message for good effect.

<div class="solution">
```tut:book:silent
import cats.instances.future._ // for Monad
import cats.syntax.flatMap._   // for flatMap
import scala.concurrent.ExecutionContext.Implicits.global

type Response[A] = EitherT[Future, String, A]

def getPowerLevel(ally: String): Response[Int] = {
  powerLevels.get(ally) match {
    case Some(avg) => EitherT.right(Future(avg))
    case None      => EitherT.left(Future(s"$ally unreachable"))
  }
}
```
</div>

Two autobots can perform a special move
if their combined power level is greater than 15.
Write a second method, `canSpecialMove`,
that accepts the names of two allies
and checks whether a special move is possible.
If either ally is unavailable,
fail with an appropriate error message:

```tut:book:silent
def canSpecialMove(ally1: String, ally2: String): Response[Boolean] =
  ???
```

<div class="solution">
We request the power level from each ally
and use `map` and `flatMap` to combine the results:

```tut:book:silent
def canSpecialMove(ally1: String, ally2: String): Response[Boolean] =
  for {
    power1 <- getPowerLevel(ally1)
    power2 <- getPowerLevel(ally2)
  } yield (power1 + power2) > 15
```
</div>

Finally, write a method `tacticalReport` that
takes two ally names and prints a message
saying whether they can perform a special move:

```tut:book:silent
def tacticalReport(ally1: String, ally2: String): String =
  ???
```

<div class="solution">
We use the `value` method to unpack the monad stack
and `Await` to unpack the `Future` and `Either`:

```tut:book:silent
import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

def tacticalReport(ally1: String, ally2: String): String = {
  val stack = canSpecialMove(ally1, ally2).value

  Await.result(stack, 1.second) match {
    case Left(msg) =>
      s"Comms error: $msg"
    case Right(true)  =>
      s"$ally1 and $ally2 are ready to roll out!"
    case Right(false) =>
      s"$ally1 and $ally2 need a recharge."
  }
}
```
</div>

You should be able to use `report` as follows:

```tut:book
tacticalReport("Jazz", "Bumblebee")
tacticalReport("Bumblebee", "Hot Rod")
tacticalReport("Jazz", "Ironhide")
```
