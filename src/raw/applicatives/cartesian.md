## The *Cartesian* type class

`Cartesian` is a type class that allows us to "zip" values.
If we have two objects of type `F[A]` and `F[B]`,
a `Cartesian[F]` allows us to zip combine them to form an `F[(A, B)]`.

The definition of Cartesian in Cats is:

```scala
trait Cartesian[F[_]] {
  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
}
```

### Combining *Options*

Let's see this in action.
The code below summons a `Cartesian` for `Option`
and uses it to zip two values:

```tut:book
import cats.Cartesian
import cats.std.option._

Cartesian[Option].product(Some(123), Some("abc"))
```

In the case of `Option`,
if either or both of the argument values is `None`,
the result is always `None`:

```tut:book
Cartesian[Option].product(None, Some("abc"))
Cartesian[Option].product(Some(123), None)
```

### Combining *Futures*

The semantics of `product` are, of course, different for every data type.
For example, the `Cartesian[Future]` combines `Futures` in parallel:

```tut:book
import scala.concurrent._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.Duration

import cats.std.future._

val future = Cartesian[Future].product(Future(123), Future("abc"))

Await.result(future, Duration.Inf)
```

### Combining *Xors*

When combining `Xors`, we have to use a type alias to fix the left hand side:

```tut:book
import cats.data.Xor

type ErrorOr[A] = List[String] Xor A

Cartesian[ErrorOr].product(
  Xor.right(123),
  Xor.right("abc")
)
```

If we try to combine failed and successful `Xors`,
the `product` method returns the errors from the failed parameter:

```tut:book
Cartesian[ErrorOr].product(
  Xor.left(List("Fail parameter 1")),
  Xor.right("abc")
)

Cartesian[ErrorOr].product(
  Xor.right(123),
  Xor.left(List("Fail parameter 2"))
)
```

However, if *both* sides are failures,
only one set of errors is retained:

```tut:book
Cartesian[ErrorOr].product(
  Xor.left(List("Fail parameter 1")),
  Xor.left(List("Fail parameter 2"))
)
```

Why does this happen? It seems counter-intuitive.
The reason is that `Xor` is a monad.
The designers of Cats decided to keep
the definitions of `product` and `flatMap` consistent for all monads
by defining the one in terms of the other:

```scala
def product[A, B](fa: F[A], fb: F[B]): F[(A, B)] =
  for {
    a <- fa
    b <- fb
  } yield (a, b)
```

To retain errors from both sides,
we have to use a different data type called `Validated`.
`Validated` is very similar to `Xor`,
except it isn't a `Monad`
and its `Cartesian` and `Applicative` instances retain all errors.
We will look at `Validated` in more detail later in the chapter.
