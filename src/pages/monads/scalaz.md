## Monads in Scalaz

### The Monad Type Class

The monad type class is [`scalaz.Monad`](http://docs.typelevel.org/api/scalaz/nightly/index.html#scalaz.Monad). `Monad` extends `Applicative`, an abstraction we'll discuss later, and `Bind` which defines `bind` (aka `flatMap`).


### The User Interface

The main methods on `Monad` are `point` and `bind`. `Point` is a monad constructor.

~~~ scala
scala> import scalaz.Monad
scala> import scalaz.std.option._
scala> import scalaz.std.list._

scala> Monad[Option].point(3)
res0: Option[Int] = Some(3)

scala> Monad[List].point(3)
res1: List[Int] = List(3)
~~~

`Bind` is just another name for the familiar `flatMap`.

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


### Monad Instances

There are instances for all the monads in the standard library (`Option` etc). There are also some Scalaz-specific instances we'll look at in depth in later section.

### Monad Syntax

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

### Exercise: Monadic FoldMap

It's useful to allow the user of `foldMap` to perform monadic actions within their mapping function. This, for example, allows the mapping to indicate failure by returning an `Option`.

Implement a variant of `foldMap` called `foldMapM` that allows this. The focus here is on the monadic component, so you can base your code on `foldMap` or `foldMapP` as you see fit. Here are some examples of use

~~~ scala
import scalaz.std.anyVal._
import scalaz.std.option._
import scalaz.std.list._

val seq = Seq(1, 2, 3)

seq.foldMapM(a => some(a))
// res4: Option[Int] = Some(6)

seq.foldMapM(a => List(a))
// res5: List[Int] = List(6)

seq.foldMap(a => if(a % 2 == 0) some(a) else none[Int])
// res6: Option[Int] = Some(2)
~~~

<div class="solution">
See `FoldMap.scala` in `monad/src/main/scala/parallel/FoldMap.scala`. Here's the most important bit:

~~~ scala
def foldMapM[A, M[_] : Monad, B: Monoid](iter: Iterable[A])(f: A => M[B]): M[B] =
  iter.foldLeft(mzero[B].point[M]){ (accum, elt) =>
    for {
      a <- accum
      b <- f(elt)
    } yield a |+| b
  }
~~~
</div>

### Exercise: Everything is Monadic

We can unify monadic and normal code by using the `Id` monad. The `Id` monad provides a monad instance (and many other instances) for plain values. Note that such values are not wrapped in any class. They continue to be the plain values we started with. To access it's instances we require `scalaz.Id._`.

~~~ scala
scala> import scalaz.Id._
scala> import scalaz.syntax.monad._

scala> 3.point[Id]
res2: scalaz.Id.Id[Int] = 3

scala> 3.point[Id] flatMap (_ + 2)
res3: scalaz.Id.Id[Int] = 5

scala> 3.point[Id] + 2
res4: Int = 5
~~~

Using this one neat trick, implement a default function for `foldMapM`. This allows us to write code like

~~~ scala
scala> seq.foldMapM()
res10: scalaz.Id.Id[Int] = 6
~~~

<div class="solution">
~~~ scala
def foldMapM[A, M[_] : Monad, B: Monoid](iter: Iterable[A])(f: A => M[B] = (a: A) => a.point[Id]): M[B] =
  iter.foldLeft(mzero[B].point[M]){ (accum, elt) =>
    for {
      a <- accum
      b <- f(elt)
    } yield a |+| b
  }
~~~
</div>

Now implement `foldMap` in terms of `foldMapM`.

<div class="solution">
~~~ scala
def foldMap[A, B : Monoid](iter: Iterable[A])(f: A => B = (a: A) => a): B =
  foldMapM[A, Id, B](iter){ a => f(a).point[Id] }
~~~
</div>
