#import "../stdlib.typ": info, warning, solution
== The Identity Monad 
<sec:monads:identity>


In the previous section we demonstrated Cats' `flatMap` and `map` syntax
by writing a method that abstracted over different monads:

```scala mdoc:silent
import cats.Monad
import cats.syntax.all.*

def sumSquare[F[_]: Monad](a: F[Int], b: F[Int]): F[Int] =
  for {
    x <- a
    y <- b
  } yield x*x + y*y
```

This method works well on `Options` and `Lists`
but we can't call it passing in plain values:

```scala mdoc:fail
sumSquare(3, 4)
```

It would be incredibly useful if we could use `sumSquare`
with parameters that were either in a monad or not in a monad at all.
This would allow us to abstract over monadic and non-monadic code.
Fortunately, Cats provides the `Id` type to bridge the gap:

```scala mdoc:silent
import cats.Id
```

```scala mdoc
sumSquare(3 : Id[Int], 4 : Id[Int])
```

`Id` allows us to call our monadic method using plain values.
However, the exact semantics are difficult to understand.
We cast the parameters to `sumSquare` as `Id[Int]`
and received an `Id[Int]` back as a result!

What's going on? Here is the definition of `Id` to explain:

```scala
package cats

type Id[A] = A
```

`Id` is actually a type alias
that turns an atomic type into a single-parameter type constructor.
We can cast any value of any type to a corresponding `Id`:

```scala mdoc
"Dave" : Id[String]
123 : Id[Int]
List(1, 2, 3) : Id[List[Int]]
```

Cats provides instances of various type classes for `Id`,
including `Functor` and `Monad`.
These let us call `map`, `flatMap`, and `pure`
on plain values:

```scala mdoc
val a = Monad[Id].pure(3)
val b = Monad[Id].flatMap(a)(_ + 1)
```

```scala mdoc:silent
import cats.syntax.functor.* // for map
import cats.syntax.flatMap.* // for flatMap
```

```scala mdoc
for {
  x <- a
  y <- b
} yield x + y
```

The ability to abstract over monadic and non-monadic code
is extremely powerful.
For example,
we can run code asynchronously in production using `Future`
and synchronously in test using `Id`.
We'll see this in our first case study
in @sec:case-studies:testing.


=== Exercise: Monadic Secret Identities

Implement `pure`, `map`, and `flatMap` for `Id`!
What interesting discoveries do you uncover about the implementation?

#solution[
Let's start by defining the method signatures:

```scala mdoc:silent
import cats.Id

def pure[A](value: A): Id[A] =
  ???

def map[A, B](initial: Id[A])(func: A => B): Id[B] =
  ???

def flatMap[A, B](initial: Id[A])(func: A => Id[B]): Id[B] =
  ???
```

Now let's look at each method in turn.
The `pure` operation creates an `Id[A]` from an `A`.
But `A` and `Id[A]` are the same type!
All we have to do is return the initial value:

```scala mdoc:invisible:reset-object
import cats.{Id,Monad}
import cats.syntax.functor.* 
import cats.syntax.flatMap.*
def sumSquare[F[_]: Monad](a: F[Int], b: F[Int]): F[Int] =
  for {
    x <- a
    y <- b
  } yield x*x + y*y
```
```scala mdoc:silent
def pure[A](value: A): Id[A] =
  value
```

```scala mdoc
pure(123)
```

The `map` method takes a parameter of type `Id[A]`,
applies a function of type `A => B`, and returns an `Id[B]`.
But `Id[A]` is simply `A` and `Id[B]` is simply `B`!
All we have to do is call the function---no boxing or unboxing required:

```scala mdoc:silent
def map[A, B](initial: Id[A])(func: A => B): Id[B] =
  func(initial)
```

```scala mdoc
map(123)(_ * 2)
```

The final punch line is that,
once we strip away the `Id` type constructors,
`flatMap` and `map` are actually identical:

```scala mdoc
def flatMap[A, B](initial: Id[A])(func: A => Id[B]): Id[B] =
  func(initial)
```

```scala mdoc
flatMap(123)(_ * 2)
```
]

The `Id` monad does find occasional use in highly generic code,
but I think it is more useful as a tool for understanding monads in general.
Remember we said a monad is a tool for sequencing computations.
When we write

```scala
a.flatMap(b)
```

we are saying that `b` occurs after `a`,
subject to whatever complications the concrete monad and `a` might introduce.
In other words, monads express control flow.
Our programming languages already have built-in ways of expressing control flow.
In Scala, like most languages, control flow goes top-to-bottom and left-to-right.
We can think of this as an "ambient" monad,
a monad that conceptually exists but we don't work with directly.
When we write

```scala mdoc
1 + 2
```

we can instead express it in monadic terms as

```scala mdoc
Id(1).flatMap(_ + 2)
```

This shows us that monads are reifying control flow,
making it explicit.
This in turn puts the control flow
under the control of the monad,
which allows, for example, the error handling behaviour we saw with `Option`.
