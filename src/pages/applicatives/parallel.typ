#import "../stdlib.typ": info, warning, solution
== Parallel


In the previous section we saw that
when call `product` on a type that
has a `Monad` instance
we get sequential semantics.
This makes sense from the point-of-view
of keeping consistency with 
implementations of `product` in terms of `flatMap` and `map`.
However it's not always what we want.
The `Parallel` type class, and its associated syntax,
allows us to access alternate semantics
for certain monads.

We've seen how the `product` method on `Either`
stops at the first error.

```scala mdoc:silent
import cats.Semigroupal
import cats.instances.either._ // for Semigroupal

type ErrorOr[A] = Either[Vector[String], A]
val error1: ErrorOr[Int] = Left(Vector("Error 1"))
val error2: ErrorOr[Int] = Left(Vector("Error 2"))
```

```scala mdoc
Semigroupal[ErrorOr].product(error1, error2)
```

We can also write this
using `tupled`
as a short-cut.

```scala mdoc:silent
import cats.syntax.apply._ // for tupled
import cats.instances.vector._ // for Semigroup on Vector
```
```scala mdoc
(error1, error2).tupled
```

To collect all the errors
we simply replace `tupled` with its "parallel" version
called `parTupled`.

```scala mdoc:silent
import cats.syntax.parallel._ // for parTupled
```
```scala mdoc
(error1, error2).parTupled
```

Notice that both errors are returned! 
This behaviour is not special to using `Vector` as the error type.
Any type that has a `Semigroup` instance will work.
For example, here we use `List` instead.

```scala mdoc:silent
import cats.instances.list._ // for Semigroup on List

type ErrorOrList[A] = Either[List[String], A]
val errStr1: ErrorOrList[Int] = Left(List("error 1"))
val errStr2: ErrorOrList[Int] = Left(List("error 2"))
```
```scala mdoc

(errStr1, errStr2).parTupled
```

There are many syntax methods provided by `Parallel`
for methods on `Semigroupal` and related types,
but the most commonly used is `parMapN`.
Here's an example of `parMapN` 
in an error handling situation.

```scala mdoc:silent
val success1: ErrorOr[Int] = Right(1)
val success2: ErrorOr[Int] = Right(2)
val addTwo = (x: Int, y: Int) => x + y
```
```scala mdoc
(error1, error2).parMapN(addTwo)
(success1, success2).parMapN(addTwo)
```

Let's dig into how `Parallel` works.
The definition below is the core of `Parallel`.

```scala
trait Parallel[M[_]] {
  type F[_]
  
  def applicative: Applicative[F]
  def monad: Monad[M]
  def parallel: ~>[M, F]
}
```

This tells us if there is a `Parallel` instance for some type constructor `M` then:

- there must be a `Monad` instance for `M`;
- there is a related type constructor `F` that has an `Applicative` instance; and
- we can convert `M` to `F`.

We haven't seen `~>` before. 
It's a type alias for [`FunctionK`][cats.arrow.FunctionK] 
and is what performs the conversion from `M` to `F`. 
A normal function `A => B` converts values of type `A` to values of type `B`. 
Remember that `M` and `F` are not types; they are type constructors. 
A `FunctionK` `M ~> F` is a function from a value with type `M[A]` to a value with type `F[A]`. 
Let's see a quick example 
by defining a `FunctionK` that converts an `Option` to a `List`.

```scala mdoc:silent
import cats.arrow.FunctionK

object optionToList extends FunctionK[Option, List] {
  def apply[A](fa: Option[A]): List[A] =
    fa match {
      case None    => List.empty[A]
      case Some(a) => List(a)
    }
}
```
```scala mdoc
optionToList(Some(1))
optionToList(None)
```

As the type parameter `A` is generic a `FunctionK` cannot inspect
any values contained with the type constructor `M`.
The conversion must be performed
purely in terms of the structure of the type constructors `M` and `F`.
We can see in `optionToList` above
this is indeed the case.

So in summary,
`Parallel` allows us to take a type that has a monad instance
and convert it to some related type 
that instead has an applicative (or semigroupal) instance.
This related type will have some useful alternate semantics.
We've seen the case above where the related applicative for `Either`
allows for accumulation of errors
instead of fail-fast semantics.

Now we've seen `Parallel`
it's time to finally learn about `Applicative`.


==== Exercise: Parallel List


Does `List` have a `Parallel` instance? If so, what does the `Parallel` instance do?

#solution[
`List` does have a `Parallel` instance, 
and it zips the `List`
instead of creating the cartesian product.

We can see by writing a little bit of code.

```scala mdoc:silent
import cats.instances.list._
```
```scala mdoc
(List(1, 2), List(3, 4)).tupled
(List(1, 2), List(3, 4)).parTupled
```
]
