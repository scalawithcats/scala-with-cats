# Monad Transformers

Monads are [like burritos][link-monads-burritos], which means that once you acquire a taste, you'll find yourself returning to them again and again. This is not without issues. As burritos can bloat the waist, monads can bloat the code base through nested for-comprehensions.

Imagine we are interacting with a database. We wish to look up a user record. The user may or may not be present, so we return an `Option[User]`. Our communication with the database could fail for any number of reason (network issues, authentication problems, database problems, and so on), so this result is wrapped up in a disjunction (`\/`), giving us a final result of `\/[DBError, Option[User]]`.

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

Monad transformers allow us to squash together monads, creating one monad were before we had two or more. With this transformed monad we can avoid nested calls to `flatMap`.

Given two monads can we make one monad out of them in a generic way? That is, do monads *compose*? We can try to write the code but we'll soon find it impossible to implement `flatMap` (`bind`, as Scalaz calls it).

~~~ scala
import scalaz.Monad
import scalaz.syntax.monad._

object MonadCompose {
  def compose[M1[_] : Monad, M2[_] : Monad] = {
    type Composed[A] = M1[M2[A]]

    new Monad[Composed] {
      def point[A](a: => A): Composed[A] = a.point[M2].point[M1]

      def bind[A, B](fa: Composed[A])(f: (A) => Composed[B]): Composed[B] =
        // This is impossible to implement in general for a monad
        ???
    }
  }
}
~~~

We can't compose monads in general. This is not greatly surprising, because we use monads to model effects and effects don't in general compose. However some monads *do* compose, and for these special cases we can use *monad transformers* to compose them.


## An Example Using Monad Transformers

Let's see how we can use monad transformers to squash `\/[DBError, Option[A]]` in a single monad that we'll call a `Result`

We'll start be defining some type aliases. For simplicity we'll make the `DBError` type a `String`. A monad has kind `* => *` while `\/` has kind `* => * => *`. We need to fix one of the type parameters of `\/` to make a type with the same kind as a monad. This is what the second type alias does.

~~~ scala
type DBError = String // For simplicity
type Error[+A] = \/[String, A]
~~~

With these type aliases we can define our `Result` type. We use the `OptionT` type, which is the monad transformer equivalent of an `Option`. The first type parameter to `OptionT` is the monad that we wrap around our `Option`. This is the `Error` type we defined above.

~~~ scala
type Result[A] = OptionT[Error, A]
~~~

When we use an instance of `Result`, the `flatMap` method combines `flatMap` for the two monads `\/` and `Option` into a single method.

~~~
val result: Result[Int] = 42.point[Result]
// result: Result[Int] = OptionT(\/-(Some(42)))

val transformed =
  for {
    value <- result
  } yield value.toString
// transformed: scalaz.OptionT[Error,String] = OptionT(\/-(Some(42)))
~~~

This is the basics of using monad transformers. Let's now look in depth.


## Monad Transformers in Scalaz

Monad transformers are  a little different to the other abstractions we've seen. Although there is a [monad transformer type class][scala.MonadTrans] it is very uncommon to use it. We normally only use monad transformers to build monads, which we then use via the `Monad` type class. Thus the main points of interest when using monad transformers are:

- the available transformer classes;
- building stacks of monads using transformers;
- constructing instances of a monad stack; and
- pulling apart a stack to access the wrapped monads.

### The Monad Transformer Classes

By convention, in Scalaz a monad `Foo` will have a transformer class called `Foot`. In fact the monad instance is often just the transformer with the `Id` monad wrapped around it. Concretely, some of the available instances are:

- [OptionT][scalaz.OptionT] and [ListT][scalaz.ListT], for `Option` and `List` respectively;
- [EitherT][scalaz.EitherT], for Scalaz's disjunction;
- [ReaderT][scalaz.ReaderT] and [WriterT][scalaz.WriterT]; and
- [IdT][scalaz.IdT], for the `Id` monad.

All these monad transformers follow the same convention, using the first type parameter to specify the monad that is wrapped around the monad implied by the monad transformer.

### Building Monad Stacks

Building monad stacks is a little tricky until you know the patterns. Since a monad transformer takes a monad to wrap around it, we must build them from the bottom up. However many monads, and all monad transformers, have two or more type parameters (kind `* -> * -> *` or higher). We often have to define type aliases for intermediate stages so they have the correct kind, just as we did with the `Error` type above.

Let's look at some examples.

A straightforward example is wrapping a `Future` around an `Option`. `Future` has the correct kind so we don't need to define any type aliases.

~~~
import scalaz.OptionT
import scala.concurrent.Future

type Result[A] = OptionT[Future, A]
~~~

Notice how we build from the bottom.

Now let's add another monad into our stack. Let's have a `Future` around a `List` around an `Option`. We can't define this in one line like

~~~ scala
type Result[A] = OptionT[ListT[Future, _], A]
// error: scalaz.ListT[scala.concurrent.Future, _] takes no type parameters, expected: one
~~~

This is because `ListT` has two type parameters. It does not have the correct kind and there is no syntax in Scala for currying a higher kinded type. We must resort to defining an alias.

~~~
type FutureList[A] = ListT[Future, A]
type Result[A] = OptionT[FutureList, A]
~~~

This is the general pattern for constructing a monad stack:

1. Define type aliases for the intermediate layers that have the correct kind.
2. Build a stack from the bottom up using the type aliases just defined.


### Constructing Instances

We can construct an instance of our monad stack using `point`, as is normal for monads. Let's create an instance of the `Future` \ `List` \ `Option` monad we defined above. To get the type class instances for `Future` into scope we need to import `scalaz.std.scalaFuture` and have an implicit `ExecutionContext` in scope.

Here's the complete code for the example up to this point.

~~~ scala
import scalaz.{ListT, OptionT}
import scalaz.std.scalaFuture._
import scala.concurrent.Future
import scala.concurrent.ExecutionContext.Implicits.global
import scalaz.syntax.monad._

type FutureList[A] = ListT[Future, A]
type Result[A] = OptionT[FutureList, A]

42.point[Result]
// res: Result[Int] = OptionT(ListT(scala.concurrent.impl.Promise$DefaultPromise@3a3670a8))
~~~

Using `point` we constructed a monad instance on the `Some` branch of `OptionT`, but what about the `None` branch? Many monads encode some notion of failure, no how in general can we construct a "failed" monad? There is no general way to do this. We can either look for useful functions on the monad transformers we use, or we construct an entire monad stack by hand.

For the specific case of `OptionT`, we can call the `none` method on the companion object. I've put a type annotation in the example to show that we really are creating a value with the correct type (the code would not compile otherwise).

~~~ scala
OptionT.none[FutureList, Int] : Result[Int]
// res: Result[Int] = OptionT(ListT(scala.concurrent.impl.Promise$DefaultPromise@57afar7))
~~~

~~~ scala
OptionT[FutureList, Int](ListT.empty[Future, Option[Int]]) : Result[Int]
res12: Result[Int] = OptionT(ListT(scala.concurrent.impl.Promise$DefaultPromise@7f5f2483))
~~~

<div class="callout callout-danger">
TODO: `liftM`
</div>

### Default Instances

<div class="callout callout-danger">
TODO: Complete

Most monads in Scalaz are just the transformer with `Id` wrapped around them.
</div>

### Syntax

<div class="callout callout-danger">
TODO: Complete

None.
</div>

## Exercise: Using Monad Transformers

<div class="callout callout-danger">
TODO: Complete

`run`

type aliases / patterns.

constructing instances.

`liftM`.
</div>
