# Monad Transformers

Monads are [like burritos][link-monads-burritos], which means that once you acquire a taste, you'll find yourself returning to them again and again. This is not without issues. As burritos can bloat the waist, monads can bloat the code base through nested for-comprehensions.

Imagine we are interacting with a database. We wish to look up a user record. The user may or may not be present, so we return an `Option[User]`. Our communication with the database could fail for any number of reason (network issues, authentication problems, database problems, and so on), so this result is wrapped up in a disjunction (`\/`), giving us a final result of `\/[Error, Option[User]]`.

To use this value we must nest `flatMap` calls (or equivalently, for-comprehensions):

~~~ scala
val transformed =
  for {
    option <- result
  } yield {
    for {
      user <- option
    } yield doSomethingWithUser(user)
  }
~~~

This quickly becomes very tedious.

Monad transformers allow us to squash together monads, creating one monad where we previously had two or more. With this transformed monad we can avoid nested calls to `flatMap`.

Given two monads can we make one monad out of them in a generic way? That is, do monads *compose*? We can try to write the code but we'll soon find it impossible to implement `flatMap` (or `bind`, as Scalaz calls it).

~~~ scala
import scalaz.Monad
import scalaz.syntax.monad._

object MonadCompose {
  def compose[M1[_] : Monad, M2[_] : Monad] = {
    type Composed[A] = M1[M2[A]]

    new Monad[Composed] {
      def point[A](a: => A): Composed[A] = a.point[M2].point[M1]

      def bind[A, B](fa: Composed[A])(f: (A) => Composed[B]): Composed[B] =
        // This is impossible to implement in general
        // without knowing something about M1 or M2
        ???
    }
  }
}
~~~

We can't compose monads in general. This is not greatly surprising because we use monads to model effects and effects don't in general compose. However, some monads can be made to compose with monad-specific glue code. For these special cases we can use *monad transformers* to compose them. Scalaz provides a library of such transformers: `EitherT` for composing `\/` with other monads, `OptionT` for composing `Option`, and so on.


## A Transformative Example

Let's see how we can use monad transformers to squash `List` and `Option` into a single monad called a `Result`:

~~~ scala
type ListOption[A] = OptionT[List, A]
~~~

Our `Result` type is a monad that combines the properties of `List` and `Option`. Note how we build it from the inside out: we pass to `OptionT` the type of the monad we wrap around it.

We can create instances with `point` as usual:

~~~
val result: ListOption[Int] = 42.point[ListOption]
// result: ListOption[Int] = OptionT(List(Some(42)))
~~~

The `map` and `flatMap` methods of `Result` combine the corresponding methods of `List` and `Option` into single operations:

~~~
val futureOptionSum = for {
  a <- 10.point[ListOption]
  b <- 32.point[ListOption]
} yield (a + b)
// sum: scalaz.OptionT[List, Int] = OptionT(List(Option(42)))
~~~

This is the basics of using monad transformers. The combined `map` and `flatMap` methods allow us to use both component monads without having to recursively unpack and repack values at each stage in the computation. Now let's look at the API in more depth.


## Monad Transformers in Scalaz

Monad transformers are a little different to the other abstractions we've seen. Although there is a [monad transformer type class][scalaz.MonadTrans] it is very uncommon to use it. We normally only use monad transformers to build monads, which we use via the `Monad` type class. Thus the main points of interest when using monad transformers are:

- the available transformer classes;
- building stacks of monads using transformers;
- constructing instances of a monad stack; and
- pulling apart a stack to access the wrapped monads.

### The Monad Transformer Classes

By convention, in Scalaz a monad `Foo` will have a transformer class called `FooT`. In fact, many monads in Scalaz are defined by combining a monad transformer with the `Id` monad. Concretely, some of the available instances are:

- [OptionT][scalaz.OptionT] and [ListT][scalaz.ListT], for `Option` and `List` respectively;
- [EitherT][scalaz.EitherT], for Scalaz's disjunction;
- [ReaderT][scalaz.ReaderT], [WriterT][scalaz.WriterT], and [StateT][scalaz.StateT];
- [ReaderWriterStateT][scalaz.ReaderWriterStateT]; and
- [IdT][scalaz.IdT], for the `Id` monad.

All of these monad transformers follow the same convention: the first type parameter specifies the monad that is wrapped around the monad implied by the transformer. The remaining type parameters are the types we're used to from the corresponding monads.

### Building Monad Stacks

Building monad stacks is a little tricky until you know the patterns. The first type parameter to a monad transformer is the *outer* monad in the stack---the transformer itself provides the inner monad. For example, our `ListOption` type above was built using `OptionT[List, A]` but the result was effectively a `List[Option[A]]`. In other words, we build monad stacks from the inside out.

Many monads and all transformers have at least two type parameters, so we often have to define type aliases for intermediate stages. For example, suppose we want to wrap `\/` around `Option`. `Option` is the innermost type so we want to use the `OptionT` monad transformer. We need to use `\/` as the first type parameter. However, `\/` has two type parameters and monads only have one. We need a type alias to make everything the correct shape:

~~~ scala
type Error = String

// Create a type alias, ErrorOr, to convert \/ to
// a type constructor with a single parameter:
type ErrorOr[A] = Error \/ A

// Use ErrorOr as a type parameter to OptionT:
type ErrorOptionOr[A] = OptionT[ErrorOr, A]
~~~

We can use `point` as usual to create an instance of our monad:

~~~ scala
val result = 42.point[ErrorOptionOr]
// result: EitherT[\/[String, Option[Int]]] = EitherT(\/-(Some(42)))
~~~

Now let's add another monad into our stack. Let's create a `Future` of a `List` of `Option`. Once again we build this from the inside out. We need an `OptionT` of a `ListT` of `Future`, but we can't define this in one line because `ListT` has two type parameters:

~~~ scala
type FutureListOption[A] = OptionT[ListT[Future, _], A]
// error: scalaz.ListT[scala.concurrent.Future, _] takes no type parameters, expected: one
~~~

As before, we can fix this by creating a type alias with a single parameter. This time we create an alias for `ListT` that fixes `Future` and allows `A` to vary:

~~~ scala
import scala.concurrent.{Future, ExecutionContext}
import scala.concurrent.ExecutionContext.Implicits.global
import scalaz.{ListT, OptionT}
import scalaz.std.scalaFuture._
import scalaz.syntax.monad._

type FutureList[A] = ListT[Future, A]
type FutureListOption[A] = OptionT[FutureList, A]
~~~

Our mammoth stack composes not two but *three* monads. Our `map` and `flatMap` methods cut through three layers of abstraction:

~~~ scala
def result(implicit ec: ExecutionContext): FutureListOption[A] =
  for {
    a <- 10.point[FutureListOption]
    b <- 32.point[FutureListOption]
  } yield a + b
~~~

<div class="callout callout-info">
The general pattern for constructing a monad stack is as follows:

- build from the inside out;
- define type aliases with single type parameters for each intermediate layer.
</div>


### Constructing Instances

As we saw above, we can construct instances of our monad stack using `point`. We've seen this several times above. However, many monads encode some notion of failure. How in general can we construct a "failed" monad? There are a couple of ways to do this.

Many monad transformers have sets of useful APIs on their companion objects. For example, `EitherT` has a `left` method for creating stacked left disjunctions, and `OptionT` has a `none` method for creating stacked empty options:

~~~ scala
val error = EitherT.left[Option, String, Int]("Badness")
// error: EitherT[Option[\/[String, Int]]] =
//   EitherT(Some(-\/("Badness")))

val missing = OptionT.none[List, Int]
// missing: OptionT[List, Int] = OptionT(List(None))
~~~

We can also use the `MonadError` type class and its `raiseError` syntax to create stacked left disjunctions:

~~~ scala
type OptionError[E, A] = EitherT[Option, E, A]

val instance = MonadError[OptionError, String]
// instance: scalaz.MonadError[OptionError,String] = ...

// Create a failure using the MonadError itself:
instance.raiseError[Int]("FAIL!")
// res0: OptionError[String,Int] = EitherT(Some(-\/(FAIL!)))

import scalaz.syntax.monadError._

// Create a failure using the MonadError syntax:
MonadError[OptionError, String].raiseError[Int]("FAIL!")
"Nooooo".raiseError[OptionError, Int]
// res1: OptionError[String,Int] = EitherT(Some(-\/(Nooooo)))
~~~

Finally, we can create instances of `EitherT` from any monad
using the `liftM` syntax:

<div class="callout callout-danger">
TODO: `liftM`
</div>


### Unpacking Instances

We need a way to unpack monad transformers once we've used them. Fortunately this is quite straightforward. All monad transformers have a `run` method that extracts the stack within. We can then manipulate the individual monads in the usual way:

~~~ scala
type Stack1[A] = EitherT[Option, String, A]

val packed = 42.point[Stack1]
// packed: Stack1[Int] = EitherT(Some(\/-(42)))

val unpacked = packed.run
// unpacked: Option[scalaz.\/[String,Int]] = Some(\/-(42))
~~~

Each call to `run` unpacks a single monad transformer, so we may need more than one call to completely unpack a large stack:

~~~ scala
type ListOption[A] = ListT[Option, A]
type ListOptionEither[A] = EitherT[ListOption, String, A]

val packed = 123.point[ListOptionEither]
// packed: ListOptionEither[Int] =
//   EitherT(ListT(Some(List(\/-(123)))))

val partiallyUnpacked = packed.run
// partiallyUnpacked: ListOption[scalaz.\/[String,Int]] =
//   ListT(Some(List(\/-(123))))

val unpacked = partiallyUnpacked.run
// unpacked: Option[List[scalaz.\/[String,Int]]] =
//   Some(List(\/-(123)))
~~~

### Default Instances

Many monads in Scalaz are defined using the corresponding transformer and the `Id` monad. This is reassuring as it confirms that the APIs for these monads and transformers are identical. `Reader`, `Writer`, and `State` are all defined in this way:

~~~ scala
type Reader[E, A] = ReaderT[Id, E, A]
type Writer[W, A] = WriterT[Id, W, A]
type State[S, A] = StateT[Id, S, A]
~~~

`ReaderWriterState` is defined similarly in terms of `ReaderWriterStateT`, although the definition is more complex and not recreated here.

In other cases monad transformers have separate definitions to their corresponding monads. In these cases, the methods of the transformer tend to mirror the methods on the monad. For example, `OptionT` defines `getOrElse`, and `EitherT` defines `fold`, `bimap`, `swap`, and other useful methods.

## Exercise: Using Monad Transformers

Let's use monad transformers to model a classic combination of `Future` and `\/`. Start by defining appropriate type aliases to wrap `\/` in `Future`, using `String` as the error type. Call the transformer stack `FutureEither`.

<div class="solution">
This is a relatively simple combination. We want `Future` on the outside and `\/` on the inside, so can build from the inside out using an `EitherT` of `Future`:

~~~ scala
import scalaz.EitherT
import scala.concurrent.Future

type FutureEither[A] = EitherT[Future, String, A]
~~~
</div>

Now let's define a simple analytics system to collate load averages from a set of imaginary servers. Here's the data we'll use:

~~~ scala
val loadAverages = Map(
  "a.example.com" -> 0.1,
  "b.example.com" -> 0.5,
  "c.example.com" -> 0.2
)
~~~

We'll pretend these are real servers that we have to contact asynchronously. Let's define a `getLoad` function that accepts a hostname as a parameter and returns its load average:

~~~ scala
def getLoad(hostname: String): FutureEither[Double] =
  ???
~~~

If `hostname` isn't in the `loadAverages` map, return an error message reporting that the host was unreachable. Include `hostname` in the message for good effect.

<div class="solution">
In the code below we use the `point` and `raiseError` syntaxes from `Monad` and `MonadError` respectively. There are a couple of wrinkles to note:

1. `raiseError` requires a binary type constructor as a type parameter, so we define the type alias `FutureEither2` as a helper;

2. Because we're using Scala's built-in `Future`, we need an implicit `ExecutionContext` in scope to summon either of the two type classes. If we don't have this, we get a rather misleading error message about a missing `Applicative` for `FutureEither`.

~~~ scala
import scalaz.std.scalaFuture._
import scalaz.syntax.monad._
import scalaz.syntax.monadError._
import scala.concurrent.ExecutionContext. ↩
         Implicits.global

type FutureEither2[E, A] = EitherT[Future, E, A]

def getLoad(hostname: String): FutureEither[Double] = {
  loadAverages.get(hostname).
    map(_.point[FutureEither]).
    getOrElse(s"Host unreachable: $hostname".
      raiseError[FutureEither2, Double])
}
~~~
</div>

Write another method, `getMeanLoad` that accepts a list of hostnames as a parameter and returns the mean load average across all of them. If any hosts are unreachable, fail with an appropriate error message.

~~~ scala
def getMeanLoad(hostnames: List[String]):
    FutureEither[Double] =
  ???
~~~

<div class="solution">
We `map` over the list of hostnames colleting load averages from each server, and use `sequence` to combine the results. The `map`, `flatMap`, and `sequence` methods cut through both layers in our monad stack, allowing us to combine the results without hassle:

~~~ scala
import scalaz.std.list._        // for Applicative[List]
import scalaz.syntax.traverse._ // for _.sequence

def getMeanLoad(hostnames: List[String]):
    FutureEither[Double] =
  hostnames.length match {
    case 0 => s"No hosts to contact".
                raiseError[FutureEither2, Double]
    case n => hostnames.map(getLoad).sequence.
                map(_.foldLeft(0.0)(_ + _) / n)
  }
~~~
</div>

Finally, write a method `report` that takes a `FutureEither` and prints the value within with an appropriate prefix based on whether the operation was a success or failure.

~~~ scala
def report[A](input: FutureEither[A]): Unit = ???
~~~

You should be able to use `report` and `getMeanLoad` to query sets of hosts as follows:

~~~ scala
report(getMeanLoad(List("a.example.com", "b.example.com")))
// [DONE] 0.3

report(getMeanLoad(List("a.example.com", "c.example.com")))
// [DONE] 0.15

report(getMeanLoad(List("a.example.com", "d.example.com")))
// [FAIL] Host unreachable: d.example.com
~~~

<div class="solution">
This is a simple exercise of peeling back layers until we have access to the disjunction at the bottom of our stack. We use `run` to unpack the monad transformer, `Await.result` to block on the `Future`, and `fold` to handle the disjunction:

~~~ scala
import scala.concurrent.Await
import scala.concurrent.duration._

def report[A](input: FutureEither[A]): Unit =
  Await.result(input.run, 2.seconds).fold(
    l = msg => println("[FAIL] " + msg),
    r = ans => println("[DONE] " + ans)
  )
~~~
</div>
