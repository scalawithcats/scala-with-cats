#import "../stdlib.typ": info, warning, solution, href
== Aside: Error Handling and MonadError


Cats provides an additional type class called `MonadError`
that abstracts over `Either`-like data types
that are used for error handling.
`MonadError` provides extra operations
for raising and handling errors.

#info[
==== This Section is Optional! {-}


You won't need to use `MonadError`
unless you need to abstract over error handling monads.
For example, you can use `MonadError`
to abstract over `Future` and `Try`,
or over `Either` and `EitherT`
(which we will meet in @sec:monad-transformers).

If you don't need this kind of abstraction right now,
feel free to skip onwards to @sec:monads:eval.
]

=== The MonadError Type Class


Here is a simplified version
of the definition of `MonadError`:

```scala
package cats

trait MonadError[F[_], E] extends Monad[F] {
  // Lift an error into the `F` context:
  def raiseError[A](e: E): F[A]

  // Handle an error, potentially recovering from it:
  def handleErrorWith[A](fa: F[A])(f: E => F[A]): F[A]
  
  // Handle all errors, recovering from them:
  def handleError[A](fa: F[A])(f: E => A): F[A]

  // Test an instance of `F`,
  // failing if the predicate is not satisfied:
  def ensure[A](fa: F[A])(e: E)(f: A => Boolean): F[A]
}
```

`MonadError` is defined in terms of two type parameters:

- `F` is the type of the monad;
- `E` is the type of error contained within `F`.

To demonstrate how these parameters fit together,
here's an example where we
instantiate the type class for `Either`:

```scala mdoc:silent
import cats.MonadError

type ErrorOr[A] = Either[String, A]

val monadError = MonadError[ErrorOr, String]
```

#warning[
*ApplicativeError*

In reality, `MonadError` extends another type class
called `ApplicativeError`.
However, we won't encounter `Applicatives`
until @sec:applicatives.
The semantics are the same for each type class
so we can ignore this detail for now.
]

=== Raising and Handling Errors


The two most important methods of `MonadError`
are `raiseError` and `handleErrorWith`.
`raiseError` is like the `pure` method for `Monad`
except that it creates an instance representing a failure:

```scala mdoc
val success = monadError.pure(42)
val failure = monadError.raiseError("Badness")
```

`handleErrorWith` is the complement of `raiseError`.
It allows us to consume an error and (possibly)
turn it into a success,
similar to the `recover` method of `Future`:

```scala mdoc
monadError.handleErrorWith(failure) {
  case "Badness" =>
    monadError.pure("It's ok")

  case _ =>
    monadError.raiseError("It's not ok")
}
```

If we know we can handle all possible errors 
we can use `handleWith`.

```scala mdoc
monadError.handleError(failure) {
  case "Badness" => 42

  case _ => -1
}
```

There is another useful method called `ensure`
that implements `filter`-like behaviour.
We test the value of a successful monad with a predicate
and specify an error to raise if the predicate returns `false`:

```scala mdoc
monadError.ensure(success)("Number too low!")(_ > 1000)
```

Cats provides syntax for `raiseError` and `handleErrorWith`
via #href("http://typelevel.org/cats/api/cats/syntax/package$$applicativeError$")[`cats.syntax.applicativeError`]
and `ensure` via #href("http://typelevel.org/cats/api/cats/syntax/package$$monadError$")[`cats.syntax.monadError`]:

```scala mdoc:invisible:reset
import cats.MonadError

type ErrorOr[A] = Either[String, A]
```
```scala mdoc:silent
import cats.syntax.applicative.*      // for pure
import cats.syntax.applicativeError.* // for raiseError etc
import cats.syntax.monadError.*       // for ensure
```

```scala mdoc
val success = 42.pure[ErrorOr]
val failure = "Badness".raiseError[ErrorOr, Int]
failure.handleErrorWith{
  case "Badness" =>
    256.pure

  case _ =>
    ("It's not ok").raiseError
}
success.ensure("Number to low!")(_ > 1000)
```

There are other useful variants of these methods.
See the source of #href("http://typelevel.org/cats/api/cats/MonadError.html")[`cats.MonadError`]
and #href("http://typelevel.org/cats/api/cats/ApplicativeError.html")[`cats.ApplicativeError`]
for more information.

=== Instances of MonadError


Cats provides instances of `MonadError`
for numerous data types including
`Either`, `Future`, and `Try`.
The instance for `Either` is customisable to any error type,
whereas the instances for `Future` and `Try`
always represent errors as `Throwables`:

```scala mdoc:silent
import scala.util.Try

val exn: Throwable =
  new RuntimeException("It's all gone wrong")
```

```scala mdoc
exn.raiseError[Try, Int]
```

=== Exercise: Abstracting


Implement a method `validateAdult` with the following signature

```scala
def validateAdult[F[_]](age: Int)(implicit me: MonadError[F, Throwable]): F[Int] =
  ???
```

When passed an `age` greater than or equal to 18 it should return that value as a success. Otherwise it should return a error represented as an `IllegalArgumentException`.

```scala mdoc:invisible
def validateAdult[F[_]](age: Int)(implicit me: MonadError[F, Throwable]): F[Int] =
  if(age >= 18) age.pure[F]
  else new IllegalArgumentException("Age must be greater than or equal to 18").raiseError[F, Int]
```

Here are some examples of use.

```scala mdoc
validateAdult[Try](18)
validateAdult[Try](8)
type ExceptionOr[A] = Either[Throwable, A]
validateAdult[ExceptionOr](-1)
```

#solution[
We can solve this using `pure` and `raiseError`. Note the use of type parameters to these methods, to aid type inference.

```scala mdoc:invisible:reset-object
import cats.MonadError
import cats.syntax.all.*
```
```scala mdoc:silent
def validateAdult[F[_]](age: Int)(implicit me: MonadError[F, Throwable]): F[Int] =
  if(age >= 18) age.pure[F]
  else new IllegalArgumentException("Age must be greater than or equal to 18").raiseError[F, Int]
```
]
