## *Cartesian* {#cartesian}

`Cartesian` is a type class that allows us to "zip" values within a context.
If we have two objects of type `F[A]` and `F[B]`,
a `Cartesian[F]` allows us to combine them to form an `F[(A, B)]`.
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

```tut:book
import cats.Cartesian
import cats.instances.option._

Cartesian[Option].product(Some(123), Some("abc"))
```

If either argument evaluates to `None`, the entire result is `None`:

```tut:book
Cartesian[Option].product(None, Some("abc"))
Cartesian[Option].product(Some(123), None)
```

Given that `Option` is also a monad
can you implement the `product` method for `Option`
purely in terms of operations on `Monad` (i.e. `flatMap`, `map`, and `pure`)?
Your method should have the signature

```tut:book
def product[A,B](fa: Option[A], fb: Option[B]): Option[(A,B)] =
  ???
```

<div class="solution">
We can implement `product` in terms of `map` and `flatMap` like so:

```tut:book
def product[A,B](fa: Option[A], fb: Option[B]): Option[(A,B)] =
  fa.flatMap { a => fb.map { b => (a, b) } }

product(Some(123), Some("abc"))
```

You might recognise the `flatMap` / `map` combination
as being equivalent to a for comprehension,
so we can alternatively write `product` as

```tut:book
def product[A,B](fa: Option[A], fb: Option[B]): Option[(A,B)] =
  for {
    a <- fa
    b <- fb
  } yield (a, b)

product(Some(123), Some("abc"))
```
</div>

It appears we can implement `product` in terms of the monad operations.
Why bother with the `Cartesian` type class then?
Using `product` (and in particular the `CartesianBuilder` we'll see in the next section)
can be more convenient than writing out the for comprehension.
We'll also see some types for which we can define `product` but not a monad instance.


### Combining *Lists*

There is also a `Cartesian` instance for `List`. What do you think the following expression will evaluate to?

```scala
Cartesian[List].product(List(1,2,3), List(4,5,6))
```

<div class="solution">
There are at least two reasonable answers here.
The first is that `product` zips the lists, giving `List( (1,4) , (2,5), (3,6) )`.
The second is that `product` computes the *cartesian product*,
giving `List( (1,4), (1,5), (1,6), (2,4), (2,5), (2,6), (3,4), (3,5), (3,6) )`.
The name `Cartesian` is a bit of a hint as to which answer we'll get,
but let's run it too see for sure.

```tut:book
import cats.instances.list._
Cartesian[List].product(List(1,2,3), List(4,5,6))
```

We see that we get the cartesian product,
which is also the same answer we get
if we generalise the monadic implementation of `product`
that we developed for `Option`.

```tut:book
for {
  a <- List(1,2,3)
  b <- List(4,5,6)
} yield (a,b)
```
</div>

This raises two questions:

- why do we get the cartesian product, not `zip`; and
- what does "cartesian product" mean?

The reason we get the cartesian product is
to have consistent behavior for all monad instances.
We can define `product` for any `Monad` as

```tut:book
import cats.Monad
import cats.syntax.flatMap._
import cats.syntax.functor._
import scala.language.higherKinds

def product[F[_]: Monad, A, B](fa: F[A], fb: F[B]): F[(A,B)] =
  for {
   a <- fa
   b <- fb
  } yield (a, b)
```

Making this choice makes it easier
to reason about uses of `product` for a specific monad instance---we
only have to remember the semantics of `flatMap`
to understand how `product` will work.

As for the term "cartesian product",
you may recall the *Cartesian coordinate system*,
otherwise known as the standard xy plane we plot graphs on.
In mathematics terminology this is the product of the x and y axes,
and includes all possible combinations of x and y.
The cartesian product is a generalisation of this idea.
For lists it means we get all possible combinations of the elements in the two lists.


### Combining *Futures*

The semantics of `product` are, of course, different for every data type.
For example, the `Cartesian` for `Future`
zips the results of asynchronous computations:

```tut:book
import scala.concurrent._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration.Duration

import cats.instances.future._

val future = Cartesian[Future].product(Future(123), Future("abc"))

Await.result(future, Duration.Inf)
```

The example above illustrates nicely what we mean
by combining the results of *independent* compuatations.
The two `Futures`, `Future(123)` and `Future("abc")`,
are started independently of one another and execute in parallel.
This is in contrast to the following monadic combination,
which executes them in sequence:

```tut:book
val future = for {
  a <- Future(1)
  b <- Future(2)
} yield (a, b)
```

As we saw above, for consistency Cats implements the `product` method
for all monadic data types in the same way in terms of `flatMap`:

```scala
def product[F[_]: Monad, A, B](fa: F[A], fb: F[B]): F[(A,B)] =
  for {
   a <- fa
   b <- fb
  } yield (a, b)
```

This means our `product` example above is semantically identical
to the conventional approach for combining parallel compuatations in Scala:
create the `Futures` first and combine the results using `flatMap`:

```tut:book
// Start the futures in parallel:
val fa = Future(123)
val fb = Future("abc")

// Combine their results using flatMap:
val future = for {
  a <- fa
  b <- fb
} yield (a, b)
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

If we try to combine successful and failed `Xors`,
the `product` method returns the errors from the failed side:

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

Surprisingly, if *both* sides are failures, only the left-most errors are retained:

```tut:book
Cartesian[ErrorOr].product(
  Xor.left(List("Fail parameter 1")),
  Xor.left(List("Fail parameter 2"))
)
```

If you think back to our examples regarding `Futures`,
you'll see why this is the case.
`Xor` is a monad, so Cats implements `product` in terms of `flatMap`.
As we saw at the beginning of this chapter,
`flatMap` implements fail-fast error handling
so we can't use `Xor` to accumulate errors.

Fortunately there is a solution to this problem.
Cats provides another data type called `Validated` in addition to `Xor`.
`Validated` is a `Cartesian` but it is not a `Monad`.
This means Cats can provide an error-accumulating implementation of `product`
without introducing inconsistent semantics.

`Validated` is an important data type,
so we will cover it separately and extensively later on this chapter.


### Limitations of Product

In the next section we will introduce the `CartesianBuilder`,
which gives us more convenient syntax for combining elements using `product`.
To see the problem that this solves,
let's look at combining three or more elements using `product`.
For simplicity we'll use `Option`, but the idea generalises to other types.

If we combine three elements using `product` we get a nested tuple.

```tut:book
val instance = Cartesian[Option]

val result = instance.product(Some(1), instance.product(Some(2), Some(3)))
```

In fact there are two different results we can get, depending on the order of calls to `product`.

```tut:book
val instance = Cartesian[Option]

val result2 = instance.product(instance.product(Some(1), Some(2)), Some(3))
```

This difference is annoying in use
as we need to worry about how values were constructed when we come to use them.

What property would we like `product` to have, to avoid this issue?

<div class="solution">
We would like `product` to be associative, so that

`product(a, product(b, c)) == product(product(a, b), c)`
</div>

The `CartesianBuilder` provides associativity
by effectively flattening tuples when they are combined with `product`.
