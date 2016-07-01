## *Cartesian* {#cartesian}

`Cartesian` is a type class that allows us to "zip" values within a context.
If we have two objects of type `F[A]` and `F[B]`,
a `Cartesian[F]` allows us to zip combine them to form an `F[(A, B)]`.
Its definition in Cats is:

```scala
trait Cartesian[F[_]] {
  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
}
```

Note that the parameters `fa` and `fb` are independent of one another.
This contrasts with `flatMap`,
in which `fb` is evaluated strictly after `fa`:

```scala
trait FlatMap[F[_]] {
  def flatMap[A, B](fa: F[A])(fb: A => F[B]): F[B]
}
```

### Combining *Options*

Let's see `Cartesian` in action.
The code below summons a type class instance for `Option`
and uses it to zip two values:

```scala
import cats.Cartesian
// import cats.Cartesian

import cats.instances.option._
// import cats.instances.option._

Cartesian[Option].product(Some(123), Some("abc"))
// res0: Option[(Int, String)] = Some((123,abc))
```

If either argument evaluates to `None`, the entire result is `None`:

```scala
Cartesian[Option].product(None, Some("abc"))
// res1: Option[(Nothing, String)] = None

Cartesian[Option].product(Some(123), None)
// res2: Option[(Int, Nothing)] = None
```

### Combining *Futures*

The semantics of `product` are, of course, different for every data type.
For example, the `Cartesian` for `Future`
zips the results of asynchronous computations:

```scala
import scala.concurrent._
// import scala.concurrent._

import scala.concurrent.ExecutionContext.Implicits.global
// import scala.concurrent.ExecutionContext.Implicits.global

import scala.concurrent.duration.Duration
// import scala.concurrent.duration.Duration

import cats.instances.future._
// import cats.instances.future._

val future = Cartesian[Future].product(Future(123), Future("abc"))
// future: scala.concurrent.Future[(Int, String)] = scala.concurrent.impl.Promise$DefaultPromise@36410e5

Await.result(future, Duration.Inf)
// res3: (Int, String) = (123,abc)
```

The example above illustrates nicely what we mean
by combining the results of *independent* compuatations.
The two `Futures`, `Future(123)` and `Future("abc")`,
are started independently of one another and execute in parallel.
This is in contrast to monadic combination, which executes them in sequence:

```scala
val future = for {
  a <- Future(1)
  b <- Future(2)
} yield (a, b)
// future: scala.concurrent.Future[(Int, Int)] = scala.concurrent.impl.Promise$DefaultPromise@5d1d43d0
```

In fact, for consistency, Cats implements the `product` method
for all monadic data types in the same way: in terms of `flatMap`:

```scala
def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
  for {
    a <- fa
    b <- fb
  } yield (a, b)
```

This means our `product` example above is semantically identical
to the conventional approach for combining parallel compuatations in Scala:
create the `Futures` first and combine the results using `flatMap`:

```scala
// Start the futures in parallel:
val fa = Future(123)
// fa: scala.concurrent.Future[Int] = scala.concurrent.impl.Promise$DefaultPromise@49405e2c

val fb = Future("abc")
// fb: scala.concurrent.Future[String] = scala.concurrent.impl.Promise$DefaultPromise@65c12e6f

// Combine their results using flatMap:
val future = for {
  a <- fa
  b <- fb
} yield (a, b)
// future: scala.concurrent.Future[(Int, String)] = scala.concurrent.impl.Promise$DefaultPromise@447c6e86
```

### Combining *Xors*

When combining `Xors`, we have to use a type alias to fix the left hand side:

```scala
import cats.data.Xor
// import cats.data.Xor

type ErrorOr[A] = List[String] Xor A
// defined type alias ErrorOr

Cartesian[ErrorOr].product(
  Xor.right(123),
  Xor.right("abc")
)
// res6: ErrorOr[(Int, String)] = Right((123,abc))
```

If we try to combine successful and failed `Xors`,
the `product` method returns the errors from the failed side:

```scala
Cartesian[ErrorOr].product(
  Xor.left(List("Fail parameter 1")),
  Xor.right("abc")
)
// res7: ErrorOr[(Nothing, String)] = Left(List(Fail parameter 1))

Cartesian[ErrorOr].product(
  Xor.right(123),
  Xor.left(List("Fail parameter 2"))
)
// res8: ErrorOr[(Int, Nothing)] = Left(List(Fail parameter 2))
```

Surprisingly, if *both* sides are failures, only the left-most errors are retained:

```scala
Cartesian[ErrorOr].product(
  Xor.left(List("Fail parameter 1")),
  Xor.left(List("Fail parameter 2"))
)
// res9: ErrorOr[(Nothing, Nothing)] = Left(List(Fail parameter 1))
```

If you think back to our examples regarding `Futures`,
you'll see why this is the case.
`Xor` is a monad, so Cats implements `product` in terms of `flatMap`.
As we saw at the beginning of this chapter,
`flatMap` implements fail-fast error handling
so we can't use `Xor` to accumulate errors.

Fortunately there is a solution to this problem.
Cats provides another data type called `Validated` in addition to `Xor`.
`Validated` is a `Cartesian` but it is not a `Monad.
This means Cats can provide an error-accumulating implementation of `product`
without introducing inconsistent semantics.

`Validated` is an important data type,
so we will cover it separately and extensively later on this chapter.
