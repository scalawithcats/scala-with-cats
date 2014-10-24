---
layout: page
title: Monads in Scalaz
---

## The Monad Type Class

The monad type class is [`scalaz.Monad`](http://docs.typelevel.org/api/scalaz/nightly/index.html#scalaz.Monad).

There are a many utility methods defined on `Monad`. The one's you're mostly like to use are:

- `lift`, which converts an function of type `A => B` to one that operates over a monad and has type `F[A] => F[B]`.

  ~~~ scala
  val f = Monad[Option].lift((x: Int) => x + 1)
  ~~~

  This is actually defined on `Functor`, and monad uses it by inheritance. We mention it here because you're more likely to use it in the context of moands

- `tuple`, which converts a tuple of monads into a monad of tuples

  ~~~ scala
  val tupled: Option[(Int, String, Double)] =
    Monad[Option].tuple3(some(1), some("hi"), some(3.0))
  ~~~

- `sequence`, which converts a type like `F[G[A]]` to `G[F[A]]`. For example, we can convert a `List[Option[Int]]` to a `Option[List[Int]]`

  ~~~ scala
  val sequence: Option[List[Int]] =
    Monad[Option].sequence(List(some(1), some(2), some(3)))
  ~~~

  This method requires a `Traversable`, which is closely related to `Foldable` that we saw in the section on monoids.

## The User Interface

## Monad Instances

There are instances for all the monads in the standard library (`Option` etc). There are also some Scalaz-specific instances we'll look at in depth in later section.

## Monad Syntax

We don't tend to use a great deal of syntax for monads, as for comprehensions are built in to the language. Nonetheless there are a few methods that are used from time-to-time.

We can construct a monad from a value using `point`, supplying the type of the monad we want to construct.

~~~ scala
scala> 3.point[Option]
res0: Option[Int] = Some(3)
~~~

We can also use `lift` as an enriched method

~~~ scala
((x: Int) => x + 1).lift(Monad[Option])
~~~

There is a short-cut for `flatMap`, written `>>=`. This is the symbol used in Haskell for `flatMap` and is usually called "bind".

~~~ scala
option >>= ((x: Int) => (x + 39).point[Option])
~~~

A variant on bind, written `>>`, ignores the value in the monad on which we `flatMap`.

~~~ scala
option >> (42.point[Option])
~~~
