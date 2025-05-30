#import "../stdlib.typ": info, warning, solution
== Semigroupal Applied to Different Types


`Semigroupal` doesn't always provide the behaviour we expect,
particularly for types that also have instances of `Monad`.
We have seen the behaviour of the `Semigroupal` for `Option`.
Let's look at some examples for other types.

*Future*

The semantics for `Future`
provide parallel as opposed to sequential execution:

```scala mdoc:silent
import cats.Semigroupal
import cats.instances.future._ // for Semigroupal
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

val futurePair = Semigroupal[Future].
  product(Future("Hello"), Future(123))
```

```scala mdoc
Await.result(futurePair, 1.second)
```

The two `Futures` start executing the moment we create them,
so they are already calculating results
by the time we call `product`.
We can use apply syntax to zip fixed numbers of `Futures`:

```scala mdoc:silent
import cats.syntax.apply._ // for mapN

case class Cat(
  name: String,
  yearOfBirth: Int,
  favoriteFoods: List[String]
)

val futureCat = (
  Future("Garfield"),
  Future(1978),
  Future(List("Lasagne"))
).mapN(Cat.apply)
```

```scala mdoc
Await.result(futureCat, 1.second)
```

*List*

Combining `Lists` with `Semigroupal`
produces some potentially unexpected results.
We might expect code like the following to _zip_ the lists,
but we actually get the cartesian product of their elements:

```scala mdoc:silent
import cats.Semigroupal
import cats.instances.list._ // for Semigroupal
```

```scala mdoc
Semigroupal[List].product(List(1, 2), List(3, 4))
```

This is perhaps surprising.
Zipping lists tends to be a more common operation.
We'll see why we get this behaviour in a moment.

*Either*

We opened this chapter with a discussion of
fail-fast versus accumulating error-handling.
We might expect `product` applied to `Either`
to accumulate errors instead of fail fast.
Again, perhaps surprisingly,
we find that `product` implements
the same fail-fast behaviour as `flatMap`:

```scala mdoc:silent
import cats.instances.either._ // for Semigroupal

type ErrorOr[A] = Either[Vector[String], A]
```

```scala mdoc
Semigroupal[ErrorOr].product(
  Left(Vector("Error 1")),
  Left(Vector("Error 2"))
)
```

In this example `product` sees the first failure and stops,
even though it is possible to examine the second parameter
and see that it is also a failure.

=== Semigroupal Applied to Monads


The reason for the surprising results
for `List` and `Either` is that they are both monads.
If we have a monad we can implement `product` as follows.

```scala mdoc:silent
import cats.Monad
import cats.syntax.functor._ // for map
import cats.syntax.flatMap._ // for flatmap

def product[F[_]: Monad, A, B](fa: F[A], fb: F[B]): F[(A,B)] =
  fa.flatMap(a => 
    fb.map(b =>
      (a, b)
    )
  )
```

It would be very strange
if we had different semantics
for `product` depending
on how we implemented it.
To ensure consistent semantics,
Cats' `Monad` (which extends `Semigroupal`)
provides a standard definition of `product`
in terms of `map` and `flatMap`
as we showed above.

Even our results for `Future` are a trick of the light.
`flatMap` provides sequential ordering,
so `product` provides the same.
The parallel execution we observe
occurs because our constituent `Futures`
start running before we call `product`.
This is equivalent to the classic
create-then-flatMap pattern:

```scala mdoc:silent
val a = Future("Future 1")
val b = Future("Future 2")

for {
  x <- a
  y <- b
} yield (x, y)
```

So why bother with `Semigroupal` at all?
The answer is that we can create useful data types that
have instances of `Semigroupal` (and `Applicative`) but not `Monad`.
This frees us to implement `product` in different ways.
We'll examine this further in a moment
when we look at an alternative data type for error handling.

==== Exercise: The Product of Lists


Why does `product` for `List`
produce the Cartesian product?
We saw an example above.
Here it is again.

```scala mdoc
Semigroupal[List].product(List(1, 2), List(3, 4))
```

We can also write this in terms of `tupled`.

```scala mdoc
(List(1, 2), List(3, 4)).tupled
```

#solution[
This exercise is checking that you understood
the definition of `product` in terms of
`flatMap` and `map`.

```scala mdoc:invisible:reset-object
import cats.Monad
```
```scala mdoc:silent
import cats.syntax.functor._ // for map
import cats.syntax.flatMap._ // for flatMap

def product[F[_]: Monad, A, B](x: F[A], y: F[B]): F[(A, B)] =
  x.flatMap(a => y.map(b => (a, b)))
```

This code is equivalent to a for comprehension:

```scala mdoc:invisible:reset-object
import cats.Monad
import cats.syntax.flatMap._ // for flatMap
import cats.syntax.functor._ // for map
```
```scala mdoc:silent
def product[F[_]: Monad, A, B](x: F[A], y: F[B]): F[(A, B)] =
  for {
    a <- x
    b <- y
  } yield (a, b)
```

The semantics of `flatMap` are what give rise
to the behaviour for `List` and `Either`:

```scala mdoc:silent
import cats.instances.list._ // for Semigroupal
```

```scala mdoc
product(List(1, 2), List(3, 4))
```
]
