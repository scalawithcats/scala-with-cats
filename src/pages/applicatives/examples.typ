#import "../stdlib.typ": info, warning, exercise, solution
== Semigroupal Applied to Different Types


`Semigroupal` doesn't always provide the behaviour we expect,
particularly for types that also have instances of `Monad`.
We have seen the behaviour of the `Semigroupal` for `Option`.
Let's look at some examples for other types.


=== Semigroupal Applied to List

Combining `Lists` with `Semigroupal`
produces some potentially unexpected results.
We might expect code like the following to _zip_ the lists,
but we actually get the cartesian product of their elements:

```scala mdoc:silent
import cats.Semigroupal
import cats.syntax.all.*

Semigroupal[List].product(List(1, 2), List(3, 4))
```
This is perhaps surprising.
Zipping lists tends to be a more common operation.
We'll see why we get this behaviour in a moment,
but let's first look at `Either`.


=== Semigroupal Applied to Either

We opened this chapter with a discussion of
fail-fast versus accumulating error-handling.
We might expect `product` applied to `Either`
to accumulate errors instead of fail fast.
Again, perhaps surprisingly,
we find that `product` implements
the same fail-fast behaviour as `flatMap`.

```scala mdoc

type ErrorOr[A] = Either[Vector[String], A]

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

So why bother with `Semigroupal` at all?
The answer is that we can create useful data types that
have instances of `Semigroupal` (and `Applicative`) but not `Monad`.
This frees us to implement `product` in different ways.
We'll examine this further in a moment
when we look at an alternative data type for error handling.


#exercise[The Product of Lists]

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
import cats.syntax.all.*

def product[F[_]: Monad, A, B](x: F[A], y: F[B]): F[(A, B)] =
  x.flatMap(a => y.map(b => (a, b)))
```

This code is equivalent to a for comprehension:

```scala mdoc:nest:silent
def product[F[_]: Monad, A, B](x: F[A], y: F[B]): F[(A, B)] =
  for {
    a <- x
    b <- y
  } yield (a, b)
```

The semantics of `flatMap` are what give rise
to the behaviour for `List` and `Either`:

```scala mdoc
product(List(1, 2), List(3, 4))
```
]
