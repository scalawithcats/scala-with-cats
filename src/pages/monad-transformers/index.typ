#import "../stdlib.typ": info, warning, exercise, solution, chapter, href
#chapter[Monad Transformers] <sec:monad-transformers>


Monads are #href("http://blog.plover.com/prog/burritos.html")[like burritos],
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

```scala mdoc:invisible:reset-object
type Error = String

final case class User(id: Long, name: String)

def lookupUser(id: Long): Either[Error, Option[User]] = ???
```

```scala mdoc:silent
def lookupUserName(id: Long): Either[Error, Option[String]] =
  for {
    optUser <- lookupUser(id)
  } yield {
    for { user <- optUser } yield user.name
  }
```

This quickly becomes very tedious.


== Composing Monads

A question arises.
Given two arbitrary monads,
can we combine them in some way to make a single monad?
That is, do monads _compose_?
We can try to write the code but we soon hit problems:

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
However, if we _do_ know something about one or other monad,
we can typically complete this code.
For example, if we fix `M2` above to be `Option`,
a definition of `flatMap` comes to light:

```scala
def flatMap[A, B](fa: Composed[A])
    (f: A => Composed[B]): Composed[B] =
  fa.flatMap(_.fold[Composed[B]](None.pure[M1])(f))
```

Notice that the definition above makes use of `None`, an
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


== A Transformative Example

Cats provides transformers for many monads,
each named with a `T` suffix:
`EitherT` composes `Either` with other monads,
`OptionT` composes `Option`, and so on.

Here's an example that uses `OptionT`
to compose `List` and `Option`.
We can use `OptionT[List, A]`,
aliased to `ListOption[A]` for convenience,
to transform a `List[Option[A]]` into a single monad:

```scala mdoc:silent
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

```scala mdoc
import cats.syntax.all.*

val result1: ListOption[Int] = OptionT(List(Option(10)))

val result2: ListOption[Int] = 32.pure[ListOption]
```

The `map` and `flatMap` methods
combine the corresponding methods of `List` and `Option`
into single operations:

```scala mdoc
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


== Monad Transformers in Cats

Each monad transformer is a data type,
defined in #href("http://typelevel.org/cats/api/cats/data/")[`cats.data`],
that allows us to _wrap_ stacks of monads
to produce new monads.
We use the monads we've built via the `Monad` type class.
The main concepts we have to cover
to understand monad transformers are:

- the available transformer classes;
- how to build stacks of monads using transformers;
- how to construct instances of a monad stack; and
- how to pull apart a stack to access the wrapped monads.


=== The Monad Transformer Classes

By convention, in Cats a monad `Foo`
will have a transformer class called `FooT`.
In fact, many monads in Cats are defined
by combining a monad transformer with the `Id` monad.
Concretely, some of the available instances are:

- `cats.data.OptionT` for `Option`;
- `cats.data.EitherT` for `Either`;
- `cats.data.ReaderT` for `Reader`;
- `cats.data.WriterT` for `Writer`;
- `cats.data.StateT` for `State`;
- `cats.data.IdT` for the `Id` monad.

#info(title: [Kleisli Arrows])[
In @sec:monads:reader
we mentioned that the `Reader` monad was a specialisation
of a more general concept called a "kleisli arrow",
represented in Cats as
`cats.data.Kleisli`.

We can now reveal that `Kleisli` and `ReaderT`
are, in fact, the same thing!
`ReaderT` is actually a type alias for `Kleisli`.
Hence, we were creating `Readers` last chapter
and seeing `Kleislis` on the console.
]


=== Building Monad Stacks

All of these monad transformers follow the same convention.
The transformer itself represents the _inner_ monad in a stack,
while the first type parameter specifies the outer monad.
The remaining type parameters are the types
we've used to form the corresponding monads.

For example, our `ListOption` type above
is an alias for `OptionT[List, A]`
but the result is effectively a `List[Option[A]]`.
In other words, we build monad stacks from the inside out:

```scala mdoc:invisible:reset
import cats.*
import cats.data.*
import cats.syntax.all.*
```
```scala mdoc:silent
type ListOption[A] = OptionT[List, A]
```

Many monads and all transformers have at least two type parameters,
so we often end up defining type aliases for intermediate stages.

For example, suppose we want to wrap `Either` around `Option`.
`Option` is the innermost type
so we want to use the `OptionT` monad transformer.
We need to use `Either` as the first type parameter.
However, `Either` itself has two type parameters
and monads only have one.
We can use a type alias
to convert the type constructor to the correct shape.

```scala mdoc:silent
// Alias Either to a type constructor with one parameter:
type ErrorOr[A] = Either[String, A]

// Build our final monad stack using OptionT:
type ErrorOrOption[A] = OptionT[ErrorOr, A]
```

`ErrorOrOption` is a monad, just like `ListOption`.
We can use `pure`, `map`, and `flatMap` as usual
to create and transform instances.

```scala mdoc
val a = 10.pure[ErrorOrOption]
val b = 32.pure[ErrorOrOption]

val c = a.flatMap(x => b.map(y => x + y))
```

Things become even more confusing
when we want to stack three or more monads.

For example, let's create a `Future` of an `Either` of `Option`.
Once again we build this from the inside out
with an `OptionT` of an `EitherT` of `Future`.
However, defining this in one line is harder
because `EitherT` has three type parameters:

```scala
final case class EitherT[F[_], E, A](stack: F[Either[E, A]]) {
  // etc...
}
```

The three type parameters are as follows:

- `F[_]` is the outer monad in the stack (`Either` is the inner);
- `E` is the error type for the `Either`;
- `A` is the result type for the `Either`.

The simplest approach is to create an alias for `EitherT` that
fixes `Future` and `Error` but allows `A` to vary.

```scala mdoc:silent
import scala.concurrent.Future

type FutureEither[A] = EitherT[Future, String, A]

type FutureEitherOption[A] = OptionT[FutureEither, A]
```

Our mammoth stack now composes three monads
and our `map` and `flatMap` methods
cut through three layers of abstraction.

```scala mdoc:silent
import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.*

val futureEitherOr: FutureEitherOption[Int] =
  for {
    a <- 10.pure[FutureEitherOption]
    b <- 32.pure[FutureEitherOption]
  } yield a + b
```


#info(title: [Type Lambdas])[
    If you frequently find yourself
    defining multiple type aliases when building monad stacks,
    you may want to try Scala 3's type lambdas.
    In Scala 2.13
    you can use the #href("https://github.com/typelevel/kind-projector")[Kind Projector] compiler plugin
    to get the same functionality with slightly different syntax.

    Type lambdas make it more compact to define partially applied type constructors.
    For example we can write

```scala mdoc:nest
type FutureEitherOption[A] = OptionT[[A] =>> EitherT[Future, String, A], A]
```

    instead of the longer (but perhaps clearer!)

```scala mdoc:nest
type FutureEither[A] = EitherT[Future, String, A]

type FutureEitherOption[A] = OptionT[FutureEither, A]
```
]


=== Constructing and Unpacking Instances

As we saw above, we can create transformed monad stacks
using the relevant monad transformer's `apply` method
or the usual `pure` syntax#footnote[Cats provides an instance
of `MonadError` for `EitherT`,
allowing us to create instances
using `raiseError` as well as `pure`.
].

```scala mdoc
// Create using apply:
val errorStack1 = OptionT[ErrorOr, Int](Right(Some(10)))

// Create using pure:
val errorStack2 = 32.pure[ErrorOrOption]
```

Once we've finished with a monad transformer stack,
we can unpack it using its `value` method.
This returns the untransformed stack.
We can then manipulate the individual monads in the usual way.

```scala mdoc
// Extracting the untransformed monad stack:
errorStack1.value

// Mapping over the Either in the stack:
errorStack2.value.map(_.getOrElse(-1))
```

Each call to `value` unpacks a single monad transformer.
We may need more than one call to completely unpack a large stack.
For example, to `Await` the `FutureEitherOption` stack above,
we need to call `value` twice.

```scala mdoc
futureEitherOr

val intermediate = futureEitherOr.value

val stack = intermediate.value

Await.result(stack, 1.second)
```


=== Default Instances

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


=== Usage Patterns

Widespread use of monad transformers is sometimes difficult
because they fuse monads together in predefined ways.
Without careful thought,
we can end up having to unpack and repack monads
in different configurations
to operate on them in different contexts.

The most practical solution is to forego monad transformers entirely,
and use a single "super-monad" that combines several useful monads into one.
This is the approach taken by so-called IO monads, such as #href("https://typelevel.org/cats-effect/")[Cats Effect].
These monad types usually provide asynchronicity, error-handling, and more in one type.

A similar approach is to create a single "super stack"
and sticking to it throughout our code base.
This works if the code is simple and largely uniform in nature.
For example, in a web application,
we could decide that all request handlers are asynchronous
and all can fail with the same set of HTTP error codes.
We could design a custom ADT representing the errors
and use a fusion `Future` and `Either` everywhere in our code:

```scala mdoc:invisible:reset-object
import cats.data.EitherT
import cats.instances.list._
import scala.concurrent.Future
```
```scala mdoc:silent
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

```scala mdoc:silent
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

```scala mdoc
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


#exercise[Monads: Transform and Roll Out]

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
due to satellite malfunction or sabotage by pesky Decepticons#footnote[
It is a well known fact
that Autobot neural nets are implemented in Scala.
Decepticon brains are, of course, dynamically typed.
]. `Responses` are therefore represented as a stack of monads:

```scala mdoc
type Response[A] = Future[Either[String, A]]
```

Optimus Prime is getting tired of
the nested for comprehensions in his neural matrix.
Help him by rewriting `Response` using a monad transformer.

#solution[
This is a relatively simple combination.
We want `Future` on the outside
and `Either` on the inside,
so we build from the inside out
using an `EitherT` of `Future`:

```scala mdoc:silent:reset-object
import cats.data.EitherT
import scala.concurrent.Future

type Response[A] = EitherT[Future, String, A]
```
]

Now test the code by implementing `getPowerLevel`
to retrieve data from a set of imaginary allies.
Here's the data we'll use:

```scala mdoc:silent
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

#solution[
```scala mdoc:silent:reset
import cats.data.EitherT
import scala.concurrent.Future
val powerLevels = Map(
  "Jazz"      -> 6,
  "Bumblebee" -> 8,
  "Hot Rod"   -> 10
)
```
```scala mdoc:silent
import cats.instances.future._ // for Monad
import scala.concurrent.ExecutionContext.Implicits.global

type Response[A] = EitherT[Future, String, A]

def getPowerLevel(ally: String): Response[Int] = {
  powerLevels.get(ally) match {
    case Some(avg) => EitherT.right(Future(avg))
    case None      => EitherT.left(Future(s"$ally unreachable"))
  }
}
```
]

Two autobots can perform a special move
if their combined power level is greater than 15.
Write a second method, `canSpecialMove`,
that accepts the names of two allies
and checks whether a special move is possible.
If either ally is unavailable,
fail with an appropriate error message:

```scala mdoc:silent
def canSpecialMove(ally1: String, ally2: String): Response[Boolean] =
  ???
```

#solution[
We request the power level from each ally
and use `map` and `flatMap` to combine the results:

```scala mdoc:invisible:reset-object
import cats.*
import cats.data.*
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

type Response[A] = EitherT[Future, String, A]

val powerLevels = Map(
  "Jazz"      -> 6,
  "Bumblebee" -> 8,
  "Hot Rod"   -> 10
)

def getPowerLevel(ally: String): Response[Int] = {
  powerLevels.get(ally) match {
    case Some(avg) => EitherT.right(Future(avg))
    case None      => EitherT.left(Future(s"$ally unreachable"))
  }
}
```
```scala mdoc:silent
def canSpecialMove(ally1: String, ally2: String): Response[Boolean] =
  for {
    power1 <- getPowerLevel(ally1)
    power2 <- getPowerLevel(ally2)
  } yield (power1 + power2) > 15
```
]

Finally, write a method `tacticalReport` that
takes two ally names and prints a message
saying whether they can perform a special move:

```scala mdoc:silent
def tacticalReport(ally1: String, ally2: String): String =
  ???
```

#solution[
We use the `value` method to unpack the monad stack
and `Await` and `fold` to unpack the `Future` and `Either`:

```scala mdoc:invisible:reset
import cats.*
import cats.data.*
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global

type Response[A] = EitherT[Future, String, A]

val powerLevels = Map(
  "Jazz"      -> 6,
  "Bumblebee" -> 8,
  "Hot Rod"   -> 10
)

def getPowerLevel(ally: String): Response[Int] = {
  powerLevels.get(ally) match {
    case Some(avg) => EitherT.right(Future(avg))
    case None      => EitherT.left(Future(s"$ally unreachable"))
  }
}
```
```scala mdoc:silent
import scala.concurrent.Await
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

def canSpecialMove(ally1: String, ally2: String): Response[Boolean] =
  for {
    power1 <- getPowerLevel(ally1)
    power2 <- getPowerLevel(ally2)
  } yield (power1 + power2) > 15

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
]

You should be able to use `report` as follows:

```scala mdoc
tacticalReport("Jazz", "Bumblebee")
tacticalReport("Bumblebee", "Hot Rod")
tacticalReport("Jazz", "Ironhide")
```
