## The *Identity* Monad {#id-monad}

In the previous section we demonstrated Cats' `flatMap` and `map` syntax
by writing a method that abstracted over different monads:

```tut:book:silent
import scala.language.higherKinds
import cats.Monad
import cats.syntax.functor._
import cats.syntax.flatMap._

def sumSquare[M[_] : Monad](a: M[Int], b: M[Int]): M[Int] =
  for {
    x <- a
    y <- b
  } yield x*x + y*y
```

This method works well on `Options` and `Lists`
but we can't call it passing in plain values:

```tut:book:fail
sumSquare(3, 4)
```

This would be incredibly useful because 
it would allow us to abstract over monadic and non-monadic code.
Fortunately, Cats provides the `Id` type to bridge this gap:

```tut:book:silent
import cats.Id
```

```tut:book
sumSquare(3 : Id[Int], 4 : Id[Int])
```

Now we can call our monadic method using plain values.
However, the exact semantics are difficult to understand.
We cast the parameters to `sumSquare` as `Id[Int]`
and received an `Int` back as a result!

What's going on? Here is the definition of `Id` to explain:

```scala
package cats

type Id[A] = A
```

`Id` is actually a type alias 
that turns an atomic type into a single-parameter type constructor.
We can cast any value of any type to a corresponding `Id`:

```tut:book
"Dave" : Id[String]
123 : Id[Int]
List(1, 2, 3) : Id[List[Int]]
```

Cats provides instances of various type classes for `Id`,
including `Functor` and `Monad`.
These let us call `map`, `flatMap` and so on on plain values:

```tut:book
val a = Monad[Id].pure(3)
val b = Monad[Id].flatMap(a)(_ + 1)
```

```tut:book:silent
import cats.syntax.flatMap._
import cats.syntax.functor._
```

```tut:book
for {
  x <- a
  y <- b
} yield x + y
```

The main use for `Id` is to write generic methods like `sumSquare`
that operate on monadic and non-monadic data types.
For example, 
we can run code asynchronously in production using `Future`
and synchronously in test using `Id`:

```tut:book:silent
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global
import cats.instances.future._
```

```tut:book
// In production:
Await.result(sumSquare(Future(3), Future(4)), Duration.Inf)

// In test:
sumSquare(a, b)
```

### Exercise: Monadic Secret Identities

Implement `pure`, `map`, and `flatMap` for `Id`!
What interesting discoveries do you uncover about the implementation?

<div class="solution">
Let's start by defining the method headers:

```tut:book:silent
import cats.Id

def pure[A](value: A): Id[A] =
  ???

def map[A, B](initial: Id[A])(func: A => B): Id[B] =
  ???

def flatMap[A, B](initial: Id[A])(func: A => Id[B]): Id[B] =
  ???
```

Now let's look at each method in turn.
The `pure` operation is a constructor---it 
creates an `Id[A]` from an initial value of type `A`.
But `A` and `Id[A]` are the same type!
All we have to do is return the initial value:

```tut:book:silent
def pure[A](value: A): Id[A] =
  value
```

```tut:book
pure(123)
```

The `map` method applies a function of type `A => B` to an `Id[A]`,
creating an `Id[B]`.
But `Id[A]` is simply `A` and `Id[B]` is simply `B`!
All we have to do is call the function---no packing or unpacking required:

```tut:book:silent
def map[A, B](initial: Id[A])(func: A => B): Id[B] =
  func(initial)
```

```tut:book
map(123)(_ * 2)
```

The final punch line is that,
once we strip away the `Id` type constructors,
`flatMap` and `map` are actually identical:

```tut:book
def flatMap[A, B](initial: Id[A])(func: A => Id[B]): Id[B] =
  func(initial)
```

```tut:book
flatMap(123)(_ * 2)
```

Notice that we haven't had to add any casts 
to any of the examples in this solution.
Scala is able to interpret values of type `A` as `Id[A]` and vice versa, 
simply by the context in which they are used.

The only restriction to this is that Scala cannot unify
different shapes of type constructor when searching for implicits.
Hence our need to cast to `Id[A]` 
in the call to `sumSquare` at the opening of this section:

```tut:book:silent
sumSquare(3 : Id[Int], 4 : Id[Int])
```
</div>
