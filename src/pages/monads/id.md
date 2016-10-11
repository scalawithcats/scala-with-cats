## The *Identity* Monad {#id-monad}

In the previous section we demonstrated Cats' `flatMap` and `map` syntax
by writing a method that abstracted over different monads:

```tut:book:silent
import scala.language.higherKinds
import cats.Monad
import cats.syntax.functor._
import cats.syntax.flatMap._
import cats.syntax.applicative._

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

`Id` is a type alias that turns any concrete type
into a type constructor with one parameter.
We can cast any value of any type to `Id` of that type:

```tut:book
"Dave"        : Id[String]
123           : Id[Int]
List(1, 2, 3) : Id[List[Int]]
```

Cats introduced this type constructor 
because it lets us write the types of normal values 
in a shape that supports summoning instances of type classes
such as `Monad` and `Functor`:

```tut:book
Monad[Id].pure(123)
Monad[Id].flatMap(40)(_ + 2)
```

The definitions of `pure`, `map`, and `flatMap` are trivial,
but the existence of these methods 
lets us use monadic code on plain values:

```tut:book
val a: Id[Int] = 1
val b: Id[Int] = 2

for {
  x <- a
  y <- b
} yield x + y
```

The main use for this is to write generic methods like `sumSquare` above.
For example, we can run code asynchronously in production
and synchronously in test by abstracting over `Future` and `Id`:

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
sumSquare(4 : Id[Int], 5 : Id[Int])
```

