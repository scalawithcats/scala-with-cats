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

~~~ scala
type DBError = String // For simplicity
type Error[+A] = \/[String, A]
~~~

~~~ scala
type Result[+A] = OptionT[Error, A]

val result: Result[Int] = 42.point[Result]
val transformed =
  for {
    value <- result
  } yield value.toString
~~~

A monad transformer provides an implementation of some monad (`point` and `flatMap`) and some way to "wrap" another model around it.


## Monad Transformers in Scalaz

### The MonadTrans Type Class

There is a type class but we typically don't use it, as we're constructing monads as our end goal.

`Monad` / `MonadT` convention. First type variable is the monad to *wrap around* the monad we're constructing.


`run`

`liftM`

### Default Instances

Most monads in Scalaz are just the transformer with `Id` wrapped around them.

### Custom Instances

### Syntax

None.

Example.


## Using Monad Transformers

`run`

type aliases / patterns.

constructing instances.

`liftM`.
