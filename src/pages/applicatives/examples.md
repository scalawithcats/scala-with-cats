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
```

```tut:book
val futurePair = Cartesian[Future].product(
  Future("Hello"),
  Future(123)
)

Await.result(futurePair, Duration.Inf)
```

The two `Futures` start executing the moment we create them,
so they are already calculating results by the time we call `product`.
Cartesian builder syntax provides a concise syntax 
for zipping fixed numbers of parameters:

```tut:book:silent
import cats.syntax.cartesian._

case class Cat(name: String, yearOfBirth: Int, favoriteFoods: List[String])
```

```tut:book
val futureCat = (
  Future("Garfield") |@|
  Future(1978) |@|
  Future(List("Lasagne"))
).map(Cat.apply)

Await.result(futureCat, Duration.Inf)
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

### *Cartesian* Applied to *Xor*

What about `Xor`? 
We opened this chapter with a discussion of 
fail-fast versus accumulating error-handling.
Which behaviour will `product` produce?

```tut:book:silent
import cats.data.Xor

type ErrorOr[A] = Vector[String] Xor A
```

```tut:book
Cartesian[ErrorOr].product(
  Xor.left(Vector("Error 1")),
  Xor.left(Vector("Error 2"))
)
```

Surprisingly, we still get fail-fast semantics.
The `product` method sees the first failure and stops,
despite knowing that the second parameter is also a failure.

### *Cartesian* Applied to Monads

The reason for these surprising results is that,
like `Option`, `List` and `Xor` are both monads.
To ensure consistent semantics, 
Cats' `Monad` (which extends `Cartesian`) 
provides a standard definition of `product` 
in terms of `map` and `flatMap`.

Try writing this implementation now:

```tut:book:silent
import scala.language.higherKinds
import cats.Monad

def product[M[_] : Monad, A, B](fa: M[A], fb: M[B]): M[(A, B)] =
  ???
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
def product[M[_] : Monad, A, B](fa: M[A], fb: M[B]): M[(A, B)] =
  for {
    a <- fa
    b <- fb
  } yield (a, b)
```

The semantics of `flatMap` are what give rise
to the behaviour for `List` and `Xor`:

```tut:book:silent
import cats.instances.list._
```

```tut:book
product(List(1, 2), List(3, 4))
```

```tut:book:silent
import cats.data.Xor

type ErrorOr[A] = Vector[String] Xor A
```

```tut:book
product[ErrorOr, Int, Int](
  Xor.left(Vector("Error 1")),
  Xor.left(Vector("Error 2"))
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
This gives us unexpected, and some would say less useful,
behaviour for a number of data types.


If this is the case, why bother with `Cartesian` at all?
The answer is that we can create useful data types that 
have instances of `Cartesian` but not `Monad`.
This frees us to implement `product` in different ways.
Let's examing this further by looking at 
the error handling example from the start of the chapter.
