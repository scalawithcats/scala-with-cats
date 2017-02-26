## *Cartesian* Applied to Different Types

`Cartesians` don't always provide the behaviour we expect,
particularly for types that also have instances of `Monad`.
We have seen the behaviour of the `Cartesian` for `Option`.
Let's look at some examples for other types.

### *Cartesian* Applied to *Future*

The semantics for `Future` are pretty much what we'd expect,
providing parallel as opposed to sequential execution:

```tut:book:silent
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

import cats.Cartesian
import cats.instances.future._

val futurePair = Cartesian[Future].
  product(Future("Hello"), Future(123))
```

```tut:book
Await.result(futurePair, 1.second)
```

The two `Futures` start executing the moment we create them,
so they are already calculating results by the time we call `product`.
Cartesian builder syntax provides a concise syntax
for zipping fixed numbers of `Futures`:

```tut:book:silent
import cats.syntax.cartesian._

case class Cat(
  name: String,
  yearOfBirth: Int,
  favoriteFoods: List[String]
)

val futureCat = (
  Future("Garfield") |@|
  Future(1978)       |@|
  Future(List("Lasagne"))
).map(Cat.apply)
```

```tut:book
Await.result(futureCat, 1.second)
```

### *Cartesian* Applied to *List*

There is a `Cartesian` instance for `List`.
What value do you think the following expression will produce?

```tut:book:silent
import cats.Cartesian
import cats.instances.list._

Cartesian[List].product(List(1, 2), List(3, 4))
```

There are at least two reasonable answers:

 1. `product` could *zip* the lists,
    returning `List((1, 3), (2, 4))`;

 2. `product` could compute the *cartesian product*,
    taking every element from the first list
    and combining it with every element from the second
    returning `List((1, 3), (1, 4), (2, 3), (2, 4))`.

The name `Cartesian` is a hint as to which answer we'll get,
but let's run the code to be sure:

```tut:book
Cartesian[List].product(List(1, 2), List(3, 4))
```

We get the cartesian product!
This is perhaps surprising:
zipping lists tends to be a more common operation.

### *Cartesian* Applied to *Either*

What about `Either`?
We opened this chapter with a discussion of
fail-fast versus accumulating error-handling.
Which behaviour will `product` produce?

```tut:book:silent
import cats.instances.either._

type ErrorOr[A] = Either[Vector[String], A]
```

```tut:book
Cartesian[ErrorOr].product(
  Left(Vector("Error 1")),
  Left(Vector("Error 2"))
)
```

Surprisingly, we still get fail-fast semantics.
The `product` method sees the first failure and stops,
despite knowing that the second parameter is also a failure.

### *Cartesian* Applied to Monads

The reason for these surprising results is that,
like `Option`, `List` and `Either` are both monads.
To ensure consistent semantics,
Cats' `Monad` (which extends `Cartesian`)
provides a standard definition of `product`
in terms of `map` and `flatMap`.

Try writing this implementation now:

```tut:book:silent
import scala.language.higherKinds
import cats.Monad

def product[M[_]: Monad, A, B](
  fa: M[A],
  fb: M[B]
): M[(A, B)] = ???
```

<div class="solution">
We can implement `product` in terms of `map` and `flatMap` like so:

```tut:book:silent
import cats.syntax.flatMap._
import cats.syntax.functor._

def product[M[_] : Monad, A, B](fa: M[A], fb: M[B]): M[(A, B)] =
  fa.flatMap(a => fb.map(b => (a, b)))
```

Unsurprisingly, this code is equivalent to a for comprehension:

```tut:book:silent
def product[M[_] : Monad, A, B](
  fa: M[A],
  fb: M[B]
): M[(A, B)] =
  for {
    a <- fa
    b <- fb
  } yield (a, b)
```

The semantics of `flatMap` are what give rise
to the behaviour for `List` and `Either`:

```tut:book:silent
import cats.instances.list._
```

```tut:book
product(List(1, 2), List(3, 4))
```

```tut:book:silent
type ErrorOr[A] = Either[Vector[String], A]
```

```tut:book
product[ErrorOr, Int, Int](
  Left(Vector("Error 1")),
  Left(Vector("Error 2"))
)
```

Even our results for `Future` are a trick of the light.
`flatMap` provides sequential ordering, so `product` provides the same.
The only reason we get parallel execution
is because our constituent `Futures` start running before we call `product`.
This is equivalent to the classic create-then-flatmap pattern:

```tut:book:silent
val a = Future("Future 1")
val b = Future("Future 2")

for {
  x <- a
  y <- b
} yield (x, y)
```
</div>

We can implement `product` in terms of the monad operations,
and Cats enforces this implementation for all monads.
This gives what we might think of as
unexpected and less useful behaviour
for a number of data types.
The consistency of semantics is actually
useful for higher level abstractions,
but we don't know about those yet.

So why bother with `Cartesian` at all?
The answer is that we can create useful data types that
have instances of `Cartesian` (and `Applicative`) but not `Monad`.
This frees us to implement `product` in different ways.
Let's examing this further by looking at
a new data type for error handling.
