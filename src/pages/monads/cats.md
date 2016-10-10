## Monads in Cats

It's time to give monads our standard Cats treatment.
As usual we'll look at the type class, instances, and syntax.

### The *Monad* Type Class {#monad-type-class}

The monad type class is [`cats.Monad`][cats.Monad].
`Monad` extends two other type classes: `FlatMap`,
which provides the `flatMap` method, and `Applicative`,
which extends `Functor`.
We'll discuss `Applicatives` in a later chapter.

The main methods on `Monad` are `pure` and `flatMap`:

```tut:book:silent
import cats.Monad
import cats.instances.option._
import cats.instances.list._
```

```tut:book
val opt1 = Monad[Option].pure(3)
val opt2 = Monad[Option].flatMap(opt1)(a => Some(a + 2))

val list1 = Monad[List].pure(3)
val list2 = List(1, 2, 3)
val list3 = Monad[List].flatMap(list2)(x => List(x, x*10))
```

`Monad` provides all of the methods from `Functor`,
including `map` and `lift`, and adds plenty of new methods as well.
Here are a couple of examples:

The `tupleN` methods convert a tuple of monads into a monad of tuples:

```tut:book
val tupled: Option[(Int, String, Double)] =
  Monad[Option].tuple3(Option(1), Option("hi"), Option(3.0))
```

The `sequence` method converts a type like `F[G[A]]` to `G[F[A]]`.
For example, we can convert a `List[Option[Int]]` to a `Option[List[Int]]`:

```tut:book
val sequence: Option[List[Int]] =
  Monad[Option].sequence(List(Option(1), Option(2), Option(3)))
```

`sequence` requires an instance of [`cats.Traverse`][cats.Traverse]
to be in scope.

### Default Instances

Cats provides instances for all the monads in the standard library
(`Option`, `List`, `Vector` and so on) via [`cats.instances`][cats.instances]:

```tut:book:silent
import cats.instances.option._
```

```tut:book
Monad[Option].flatMap(Option(1))(x => Option(x*2))
```

```tut:book:silent
import cats.instances.list._
```

```tut:book
Monad[List].flatMap(List(1, 2, 3))(x => List(x, x*10))
```

```tut:book:silent
import cats.instances.vector._
```

```tut:book
Monad[Vector].flatMap(Vector(1, 2, 3))(x => Vector(x, x*10))
```

There are also a load of Cats-specific monad instances.
We'll familiarise ourselves with several of these in a moment.

### *Monad* Syntax

The syntax for monads comes from three places:

 - [`cats.syntax.flatMap`][cats.syntax.flatMap] provides syntax for `flatMap`;
 - [`cats.syntax.functor`][cats.syntax.functor] provides syntax for `map`;
 - [`cats.syntax.applicative`][cats.syntax.applicative] provides syntax for `pure`.

In practice it's often easier to import everything in one go
from [`cats.implicits`][cats.implicits].
However, we'll use the individual imports here for clarity.

It's difficult to demonstrate the `flatMap` and `map`
directly on Scala monads like `Option` and `List`,
because they define their own explicit versions of those methods.
Instead we'll write a contrived generic function that
returns `3*3 + 4*4` wrapped in a monad of the user's choice:

```tut:book:silent
import scala.language.higherKinds
import cats.Monad
import cats.syntax.functor._
import cats.syntax.flatMap._
import cats.syntax.applicative._

def sumSquare[A[_] : Monad](a: Int, b: Int): A[Int] = {
  val x = a.pure[A]
  val y = a.pure[A]
  x flatMap (x => y map (y => x*x + y*y))
}

import cats.instances.option._
import cats.instances.list._
```

```tut:book
sumSquare[Option](3, 4)
sumSquare[List](3, 4)
```

We can rewrite this code using for comprehensions.
The Scala compiler will "do the right thing" by
rewriting our comprehension in terms of `flatMap` and `map`
and inserting the correct implicit conversions to use our `Monad`:

```tut:book:silent
def sumSquare[A[_] : Monad](a: Int, b: Int): A[Int] = {
  for {
    x <- a.pure[A]
    y <- b.pure[A]
  } yield x*x + y*y
}
```

```tut:book
sumSquare[Option](3, 4)
sumSquare[List](3, 4)
```
