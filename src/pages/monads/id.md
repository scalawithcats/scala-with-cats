## The *Identity* Monad {#id-monad}

We can unify monadic and normal code by using the `Id` monad. The `Id` monad provides a monad instance (and many other instances) for plain values. Note that such values are not wrapped in any class. They continue to be the plain values we started with:

```scala
import cats.Id
// import cats.Id

import cats.syntax.flatMap._
// import cats.syntax.flatMap._

val a: Id[Int] = 3
// a: cats.Id[Int] = 3

val b: Id[Int] = a.flatMap(_ + 2)
// b: cats.Id[Int] = 5

val c: Id[Int] = a + 2
// c: cats.Id[Int] = 5
```

This seems confusing---how can we `flatMap` over an `Id[Int]` *and* simply add a number to it? The answer is in the definition of `Id`:

```scala
type Id[A] = A
// defined type alias Id
```

`Id[A]` is simply a type alias for `A` itself. Cats provides the type class instances to allow us to `map` and `flatMap` on elements with type `Id[A]`, but Scala still allows us to operate on them as plain values of type `A`.
