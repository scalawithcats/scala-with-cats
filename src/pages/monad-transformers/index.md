# Monad Transformers

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
(network issues, authentication problems, database problems, and so on),
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
    for {
      user <- optUser
    } yield user.name
  }
```

This quickly becomes very tedious.

A question arises.
Given two monads, can we make one monad out of them in a generic way?
That is, do monads *compose*?
We can try to write the code
but we'll soon find it impossible to implement `flatMap`:

```scala
// This code won't actually compile.
// It's just illustrating a point:
def compose[M1[_] : Monad, M2[_] : Monad] = {
  type Composed[A] = M1[M2[A]]

  new Monad[Composed] {
    def pure[A](a: A): Composed[A] =
      a.pure[M2].pure[M1]

    def flatMap[A, B](fa: Composed[A])
        (f: A => Composed[B]): Composed[B] =
      // This is impossible to implement in general
      // without knowing something about M1 or M2:
      ???
  }
}
```

We can't compose monads in general.
However, some monad instances can be made to compose with instance-specific glue code.
For these special cases we can use *monad transformers* to compose them.

Monad transformers allow us to squash together monads,
creating one monad where we previously had two or more.
With this transformed monad we can avoid nested calls to `flatMap`.

## A Transformative Example

Cats provides a library of such transformers:
`EitherT` for composing `Either` with other monads,
`OptionT` for composing `Option`,
and so on.
Here's an example that uses `OptionT`
to squash `List` and `Option` into a single monad.
Where we might use `List[Option[A]]` we can use `ListOption[A]`
to avoid nested `flatMap` calls.

```tut:book:silent
import cats.data.OptionT

type ListOption[A] = OptionT[List, A]
```

`ListOption` is a monad that combines
the properties of `List` and `Option`.
Note how we build it from the inside out:
we pass `List`, the type of the outer monad,
as a parameter to `OptionT`,
the transformer for the inner monad.

We can create instances with `pure` as usual:

```tut:book:silent
import cats.Monad
import cats.instances.list._
import cats.syntax.applicative._
```

```tut:book
val result: ListOption[Int] = 42.pure[ListOption]
```

The `map` and `flatMap` methods of `ListOption` combine
the corresponding methods of `List` and `Option`
into single operations:

```tut:book
val a = 10.pure[ListOption]
val b = 32.pure[ListOption]

a flatMap { (x: Int) =>
  b map { (y: Int) =>
    x + y
  }
}
```

This is the basics of using monad transformers.
The combined `map` and `flatMap` methods
allow us to use both component monads
without having to recursively unpack
and repack values at each stage in the computation.
Now let's look at the API in more depth.

<div class="callout callout-warning">
*Complexity of imports*

Note the imports in the code samples above---they
hint at how everything bolts together.

We import [`cats.syntax.applicative`][cats.syntax.applicative]
to get the `pure` syntax.
`pure` requires an implicit parameter of type `Applicative[ListOption]`.
We haven't met `Applicatives` yet,
but all `Monads` are also `Applicatives`
so we can ignore that difference for now.

We need an `Applicative[ListOption]` to call `pure`.
We have [`cats.data.OptionT`][cats.data.OptionT] in scope,
which provides the implicits for `OptionT`.
However, in order to generate our `Applicative[ListOption]`,
the implicits for `OptionT` also require an `Applicative` for `List`.
Hence the additional import from [`cats.instances.list`][cats.instances.list].

Notice we're not importing
[`cats.syntax.functor`][cats.syntax.functor] or
[`cats.syntax.flatMap`][cats.syntax.flatMap].
This is because `OptionT` is a concrete data type
with its own explicit `map` and `flatMap` methods.
It wouldn't hurt to import the syntax---the
compiler will simply ignore it
in favour of the explicit methods.

Remember that we're subjecting ourselves to this shenanigans
because we're stubbornly refusing to import our instances
from [`cats.instances.all`][cats.instances.all].
If we did that, everything would just work.
</div>

## Monad Transformers in Cats

Monad transformers are a little different
to the other abstractions we've seen---they
don't have their own type class.
We use monad transformers to build monads,
which we then use via the `Monad` type class.
Thus the main points of interest when using monad transformers are:

- the available transformer classes;
- building stacks of monads using transformers;
- constructing instances of a monad stack; and
- pulling apart a stack to access the wrapped monads.

### The Monad Transformer Classes

By convention, in Cats a monad `Foo`
will have a transformer class called `FooT`.
In fact, many monads in Cats are defined
by combining a monad transformer with the `Id` monad.
Concretely, some of the available instances are:

- [`cats.data.OptionT`][cats.data.OptionT] for `Option`;
- [`cats.data.EitherT`][cats.data.EitherT] for `Either`;
- [`cats.data.ReaderT`][cats.data.ReaderT],
  [`cats.data.WriterT`][cats.data.WriterT], and
  [`cats.data.StateT`][cats.data.StateT];
- [`cats.data.IdT`][cats.data.IdT] for the [`Id`][cats.Id] monad.

All of these monad transformers follow the same convention:
the first type parameter specifies the monad that is wrapped around
the monad implied by the transformer.
The remaining type parameters are the types
we've used to form the corresponding monads.

<div class="callout callout-info">
  *Kleisli Arrows*

  Last chapter, in the section on the `Reader` monad,
  we mentioned that `Reader` was a specialisation
  of a more general concept called a "kleisli arrow"
  (aka [`cats.data.Kleisli`][cats.data.Kleisli]).

  We can now reveal that `Kleisli` and `ReaderT`
  are, in fact, the same thing!
  `ReaderT` is actually a type alias for `Kleisli`.
  Hence why we were creating `Readers` last chapter
  and seeing `Kleislis` on the console.
</div>

### Building Monad Stacks

Building monad stacks is a little confusing until you know the patterns.
The first type parameter to a monad transformer
is the *outer* monad in the stack---the
transformer itself provides the inner monad.
For example, our `ListOption` type above was
built using `OptionT[List, A]` but
the result was effectively a `List[Option[A]]`.
In other words, we build monad stacks from the inside out.

Many monads and all transformers have at least two type parameters,
so we often have to define type aliases for intermediate stages.
For example, suppose we want to wrap `Either` around `Option`.
`Option` is the innermost type
so we want to use the `OptionT` monad transformer.
We need to use `Either` as the first type parameter.
However, `Either` itself has two type parameters
and monads only have one.
We need a *type alias* to make everything the correct shape:

```tut:book:silent
import cats.instances.either._

type Error = String

// Create a type alias, ErrorOr, to convert Either to
// a type constructor with a single parameter:
type ErrorOr[A] = Either[Error, A]

// Use ErrorOr as a type parameter to OptionT:
type ErrorOptionOr[A] = OptionT[ErrorOr, A]
```

`ErrorOptionOr` is a monad.
We can use `pure` and `flatMap` as usual
to create and transform instances:

```tut:book
val result1 = 41.pure[ErrorOptionOr]

val result2 = result1.flatMap(x => (x + 1).pure[ErrorOptionOr])
```

Now let's add another monad into our stack.
Let's create a `Future` of an `Either` of `Option`.
Once again we build this from the inside out
with an `OptionT` of an `EitherT` of `Future`.
However, we can't define this in one line
because `EitherT` has three type parameters:

```tut:book:silent
import scala.concurrent.Future
import cats.data.EitherT
```

```tut:book:fail
type FutureEitherOption[A] = OptionT[EitherT, A]
```

As before, we solve the problem by
creating a type alias with a single parameter.
This time we create an alias for `EitherT` that
fixes `Future` and `Error` and allows `A` to vary:

```tut:book:silent
import scala.concurrent.Future
import cats.data.{EitherT, OptionT}

type Error = String
type FutureEither[A] = EitherT[Future, String, A]
type FutureEitherOption[A] = OptionT[FutureEither, A]
```

Our mammoth stack composes not two but *three* monads.
Our `map` and `flatMap` methods cut through three layers of abstraction:

```tut:book:silent
import scala.concurrent.ExecutionContext.Implicits.global
import cats.instances.future._
```

```tut:book
val answer: FutureEitherOption[Int] =
  for {
    a <- 10.pure[FutureEitherOption]
    b <- 32.pure[FutureEitherOption]
  } yield a + b
```

<div class="callout callout-warning">
*Kind Projector*

If you frequently find yourself
defining multiple type aliases when building monad stacks,
you may want to try the [Kind Projector][link-kind-projector] compiler plugin.
Kind Projector enhances Scala's type syntax
to make it easier to define partial types.
For example:

```tut:book
import cats.instances.option._

123.pure[EitherT[Option, String, ?]]
```

Kind Projector can't simplify all type declarations down to a single line,
but it can reduce the number of intermediate type definitions we need
to keep our code readable.
</div>

### Constructing and Unpacking Instances

As we saw above, we can use `pure` to
directly inject raw values into transformed monad stacks.
We can also create instances from untransformed stacks
using the monad transformer's `apply` method:

```tut:book:silent
import cats.syntax.either._ // for foo.asRight
import cats.syntax.option._ // for foo.some

type ErrorOr[A]       = Either[String, A]
type ErrorOrOption[A] = OptionT[ErrorOr, A]
```

```tut:book
// Create using pure:
val stack1 = 123.pure[ErrorOrOption]

// Create using apply:
val stack2 = OptionT[ErrorOr, Int](
  123.some.asRight[String]
)
```

Once we've finished with a monad transformer stack,
we can unpack it using its `value` method.
This returns the untransformed stack.
We can then manipulate the individual monads in the usual way:

```tut:book
stack1.value
stack2.value
```

Each call to `value` unpacks a single monad transformer,
so we may need more than one call to completely unpack a large stack:

```tut:book:silent
import cats.instances.vector._
import cats.data.{Writer, EitherT, OptionT}

type Logged[A] = Writer[Vector[String], A]
type LoggedFallable[A] = EitherT[Logged, String, A]
type LoggedFallableOption[A] = OptionT[LoggedFallable, A]
```

```tut:book
val packed = 123.pure[LoggedFallableOption]
val partiallyPacked = packed.value
val completelyUnpacked = partiallyPacked.value
```

### Usage Patterns

Widespread use of monad tranformers is sometimes difficult
because they fuse monads together in predefined ways.
Without careful thought,
we can end up having to unpack and repack monads
in different configurations
to operate on them in different contexts.

One way of avoiding this is
to use monad transformers as local "glue code".
Expose untransformed stacks at module boundaries,
transform them to operate on them locally,
and untransform them before passing them on.
This allows each module of code to make its own decisions
about which transformers to use.
Here's an example:

```tut:book:silent
type Logged[A] = Writer[List[String], A]

// Example method that returns nested monads:
def parseNumber(str: String): Logged[Option[Int]] =
  util.Try(str.toInt).toOption match {
    case Some(num) => Writer(List(s"Read $str"), Some(num))
    case None      => Writer(List(s"Failed on $str"), None)
  }

// Example combining multiple calls to parseNumber:
def addNumbers(
  a: String,
  b: String,
  c: String
): Logged[Option[Int]] = {
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
```

```tut:book
// This approach doesn't force OptionT on other users' code:
val result1 = addNumbers("1", "2", "3")
val result2 = addNumbers("1", "a", "3")
```

### Default Instances

Many monads in Cats are defined
using the corresponding transformer
and the `Id` monad.
This is reassuring as it confirms
that the APIs for these monads
and transformers are identical.
`Reader`, `Writer`, and `State`
are all defined in this way:

```scala
type Reader[E, A] = ReaderT[Id, E, A] // = Kleisli[Id, E, A]
type Writer[W, A] = WriterT[Id, W, A]
type State[S, A]  = StateT[Id, S, A]
```

In other cases monad transformers
have separate definitions
to their corresponding monads.
In these cases,
the methods of the transformer tend
to mirror the methods on the monad.
For example, `OptionT` defines `getOrElse`,
and `EitherT` defines `fold`, `bimap`, `swap`,
and other useful methods.

## Exercise: Monads: Transform and Roll Out

The Autobots, well known robots in disguise,
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
due to malfunctioning satellites or Decepticon interception.
`Responses` are therefore represented as a stack of monads:

```tut:book
type Response[A] = Future[Either[String, A]]
```

[^transformers]: It is a well known fact
that autobot neural nets are implemented in Scala.
Decepticon brains are dynamically typed.

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
import cats.instances.future._
import cats.syntax.flatMap._
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
def canSpecialMove(
  ally1: String,
  ally2: String
): Response[Boolean] = ???
```

<div class="solution">
We request the power level from each ally
and use `map` and `flatMap` to combine the results:

```tut:book:silent
def canSpecialMove(
  ally1: String,
  ally2: String
): Response[Boolean] =
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
def tacticalReport(
  ally1: String,
  ally2: String
): String = ???
```

<div class="solution">
We use the `value` method to unpack the monad stack
and `Await` and `fold` to unpack the `Future` and `Either`:

```tut:book:silent
import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

def tacticalReport(
  ally1: String,
  ally2: String
): String =
  Await.result(
    canSpecialMove(ally1, ally2).value,
    1.second
  ) match {
    case Left(msg) =>
      s"Comms error: $msg"
    case Right(true)  =>
      s"$ally1 and $ally2 are ready to roll out!"
    case Right(false) =>
      s"$ally1 and $ally2 need a recharge."
  }
```
</div>

You should be able to use `report` as follows:

```tut:book
tacticalReport("Jazz", "Bumblebee")
tacticalReport("Bumblebee", "Hot Rod")
tacticalReport("Jazz", "Ironhide")
```

<!--

## Exercise: *ReaderWriterState*

Scalaz provides a ReaderWriterState monad. Cats does not.
Implement it using `ReaderT`, `WriterT`, and `StateT`!

Note: This is a hard exercise!

<div class="solution">
We build `ReaderWriterState` from the inside out
using `StateT`, `WriterT`, and `Reader`:

```
import cats.Applicative
import cats.instances.all._
import cats.data.{Reader, WriterT, StateT}

type ReaderWriterStateBuilder[I, O, S] = {
  type R[X]   = Reader[I, X]
  type RW[X]  = WriterT[R, O, X]
  type RWS[X] = StateT[RW, S, X]
}

type ReaderWriterState[I, O, S, A] = ReaderWriterStateBuilder[I, O, S]#RWS[A]

type Config  = String
type Log     = List[String]
type Counter = Int
type Test[A] = ReaderWriterState[Config, Log, Counter, A]

implicitly[Applicative[ReaderWriterStateBuilder[Config, Log, Counter]#R]]
implicitly[Applicative[ReaderWriterStateBuilder[Config, Log, Counter]#RW]]
implicitly[Applicative[ReaderWriterStateBuilder[Config, Log, Counter]#RWS]]

123.pure[Test]
```
</div>

-->
