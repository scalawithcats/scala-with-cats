## Monads in Cats

It's time to give monads our standard Cats treatment.
As usual we'll look at the type class, instances, and syntax.

### The Monad Type Class {#monad-type-class}

The monad type class is [`cats.Monad`][cats.Monad].
`Monad` extends two other type classes:
`FlatMap`, which provides the `flatMap` method,
and `Applicative`, which provides `pure`.
`Applicative` also extends `Functor`,
which gives every `Monad` a `map` method
as we saw in the exercise above.
We'll discuss `Applicatives` in Chapter [@sec:applicatives].

Here are some examples using `pure` and `flatMap`, and `map` directly:

```scala mdoc:silent
import cats.Monad
import cats.instances.option._ // for Monad
import cats.instances.list._   // for Monad
```

```scala mdoc
val opt1 = Monad[Option].pure(3)
val opt2 = Monad[Option].flatMap(opt1)(a => Some(a + 2))
val opt3 = Monad[Option].map(opt2)(a => 100 * a)

val list1 = Monad[List].pure(3)
val list2 = Monad[List].
  flatMap(List(1, 2, 3))(a => List(a, a*10))
val list3 = Monad[List].map(list2)(a => a + 123)
```

`Monad` provides many other methods,
including all of the methods from `Functor`.
See the [scaladoc][cats.Monad] for more information.

### Default Instances

Cats provides instances for all the monads in the standard library
(`Option`, `List`, `Vector`, and so on) via [`cats.instances`][cats.instances]:

```scala mdoc:silent
import cats.instances.option._ // for Monad
```

```scala mdoc
Monad[Option].flatMap(Option(1))(a => Option(a*2))
```

```scala mdoc:silent
import cats.instances.list._ // for Monad
```

```scala mdoc
Monad[List].flatMap(List(1, 2, 3))(a => List(a, a*10))
```

```scala mdoc:silent
import cats.instances.vector._ // for Monad
```

```scala mdoc
Monad[Vector].flatMap(Vector(1, 2, 3))(a => Vector(a, a*10))
```

Cats also provides a `Monad` for `Future`.
Unlike the methods on the `Future` class itself,
the `pure` and `flatMap` methods on the monad
can't accept implicit `ExecutionContext` parameters
(because the parameters aren't part of the definitions in the `Monad` trait).
To work around this, Cats requires us to have an `ExecutionContext` in scope
when we summon a `Monad` for `Future`:

```scala mdoc:silent
import cats.instances.future._ // for Monad
import scala.concurrent._
import scala.concurrent.duration._
```

```scala mdoc:fail
val fm = Monad[Future]
```

Bringing the `ExecutionContext` into scope
fixes the implicit resolution required to summon the instance:

```scala mdoc:silent
import scala.concurrent.ExecutionContext.Implicits.global
```

```scala mdoc
val fm = Monad[Future]
```

The `Monad` instance uses the captured `ExecutionContext`
for subsequent calls to `pure` and `flatMap`:

```scala mdoc:silent
val future = fm.flatMap(fm.pure(1))(x => fm.pure(x + 2))
```

```scala mdoc
Await.result(future, 1.second)
```

In addition to the above,
Cats provides a host of new monads that we don't have in the standard library.
We'll familiarise ourselves with some of these in a moment.

### Monad Syntax

The syntax for monads comes from three places:

 - [`cats.syntax.flatMap`][cats.syntax.flatMap]
   provides syntax for `flatMap`;
 - [`cats.syntax.functor`][cats.syntax.functor]
   provides syntax for `map`;
 - [`cats.syntax.applicative`][cats.syntax.applicative]
   provides syntax for `pure`.

In practice it's often easier to import everything in one go
from [`cats.implicits`][cats.implicits].
However, we'll use the individual imports here for clarity.

We can use `pure` to construct instances of a monad.
We'll often need to specify the type parameter to disambiguate the particular instance we want.

```scala mdoc:silent
import cats.instances.option._   // for Monad
import cats.instances.list._     // for Monad
import cats.syntax.applicative._ // for pure
```

```scala mdoc
1.pure[Option]
1.pure[List]
```

It's difficult to demonstrate the `flatMap` and `map` methods
directly on Scala monads like `Option` and `List`,
because they define their own explicit versions of those methods.
Instead we'll write a generic function that
performs a calculation on parameters
that come wrapped in a monad of the user's choice:

```scala mdoc:silent
import cats.Monad
import cats.syntax.functor._ // for map
import cats.syntax.flatMap._ // for flatMap

def sumSquare[F[_]: Monad](a: F[Int], b: F[Int]): F[Int] =
  a.flatMap(x => b.map(y => x*x + y*y))

import cats.instances.option._ // for Monad
import cats.instances.list._   // for Monad
```

```scala mdoc
sumSquare(Option(3), Option(4))
sumSquare(List(1, 2, 3), List(4, 5))
```

We can rewrite this code using for comprehensions.
The compiler will "do the right thing" by
rewriting our comprehension in terms of `flatMap` and `map`
and inserting the correct implicit conversions to use our `Monad`:

```scala mdoc:invisible:reset-object
import cats.Monad
import cats.implicits._
```
```scala mdoc:silent
def sumSquare[F[_]: Monad](a: F[Int], b: F[Int]): F[Int] =
  for {
    x <- a
    y <- b
  } yield x*x + y*y
```

```scala mdoc
sumSquare(Option(3), Option(4))
sumSquare(List(1, 2, 3), List(4, 5))
```

That's more or less everything we need to know
about the generalities of monads in Cats.
Now let's take a look at some useful monad instances
that we haven't seen in the Scala standard library.
