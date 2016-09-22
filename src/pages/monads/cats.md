## Monads in Cats

It's time to give monads our standard Cats treatment. As usual we'll look at the type class, instances, and syntax.

### The *Monad* Type Class {#monad-type-class}

The monad type class is [`cats.Monad`][cats.Monad]. `Monad` extends two other type classes: `FlatMap`, which provides the `flatMap` method, and `Applicative`, which extends `Functor`. We'll discuss `Applicatives` in a later chapter.

The main methods on `Monad` are `pure` and `flatMap`:

```tut:book
import cats.Monad
import cats.instances.option._
import cats.instances.list._

val opt1 = Monad[Option].pure(3)

val opt2 = Monad[Option].flatMap(opt1)(a => Some(a + 2))

val list1 = Monad[List].pure(3)

val list2 = List(1, 2, 3)

val list3 = Monad[List].flatMap(list2)(x => List(x, x*10))
```

`Monad` provides all of the methods from `Functor`, including `map` and `lift`, and adds plenty of new methods as well. Here are a couple of examples:

The `tupleN` methods convert a tuple of monads into a monad of tuples:

```tut:book
val tupled: Option[(Int, String, Double)] =
  Monad[Option].tuple3(Option(1), Option("hi"), Option(3.0))
```

The `sequence` method converts a type like `F[G[A]]` to `G[F[A]]`. For example, we can convert a `List[Option[Int]]` to a `Option[List[Int]]`:

```tut:book
val sequence: Option[List[Int]] =
  Monad[Option].sequence(List(Option(1), Option(2), Option(3)))
```

`sequence` requires an instance of [`cats.Traversable`][cats.Traversable] to be in scope.

### Default Instances

Cats provides instances for all the monads in the standard library (`Option`, `List`, `Vector` and so on) via [`cats.instances`][cats.instances]:

```tut:book
import cats.instances.option._

Monad[Option].flatMap(Option(1))(x => Option(x*2))

import cats.instances.list._

Monad[List].flatMap(List(1, 2, 3))(x => List(x, x*10))

import cats.instances.vector._

Monad[Vector].flatMap(Vector(1, 2, 3))(x => Vector(x, x*10))
```

There are also some Cats-specific monad instances that we'll see later on.

### Defining Custom Instances

We can define a `Monad` for a custom type by providing implementations of thee methods:
`flatMap`, `pure`, and a new method called `tailRecM`:

Here is an implementation of `Monad` for `Option` as an example:

```tut:book
import cats.RecursiveTailRecM
import cats.data.Xor
import scala.annotation.tailrec

val optionMonad = new Monad[Option] with RecursiveTailRecM[Option] {
  def flatMap[A, B](value: Option[A])(func: A => Option[B]): Option[B] =
    value flatMap func

  def pure[A](value: A): Option[A] =
    Some(value)

  @tailrec
  def tailRecM[A, B](a: A)(f: A => Option[A Xor B]): Option[B] =
    f(a) match {
      case None               => None
      case Some(Xor.Left(a1)) => tailRecM(a1)(f)
      case Some(Xor.Right(b)) => Some(b)
    }
}
```

`tailRecM` is an internal optimisation that limits
the amount of stack space used by nested calls to `flatMap`.
The technique comes from a [2015 paper][link-phil-freeman-tailrecm]
by PureScript creator Phil Freeman.
The method should recursively call itself
as long as the result of `f` contains an `Xor.Right`.
If we can make `tailRecM` tail recursive,
we should do so and inherit from `RecursiveTailRecM`
to allow Cats to perform additional internal optimisations.

<div class="callout callout-danger">
  TODO: Remove this? Or move it after the discussion of `Xor`?

  The `tailRecM` stuff (new in Cats 0.7) seems a little heavyweight for discussion here,
  and defining custom instances is arguably not that important.
</div>

### *Monad* Syntax

The syntax for monads comes from three places:

 - [`cats.syntax.flatMap`][cats.syntax.flatMap] provides syntax for `flatMap`;
 - [`cats.syntax.functor`][cats.syntax.functor] provides syntax for `map`;
 - [`cats.syntax.applicative`][cats.syntax.applicative] provides syntax for `pure`.

In practice it's often easier to import everything in one go from [`cats.implicits`][cats.implicits]. However, we'll use the individual imports here for clarity.

It's difficult to demonstrate the `flatMap` and `map` directly on Scala monads like `Option` and `List`, because they define their own explicit versions of those methods. Instead we'll write a contrived generic function that returns `3*3 + 4*4` wrapped in a monad of the user's choice:

```tut:book
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

sumSquare[Option](3, 4)
sumSquare[List](3, 4)
```

We can rewrite this code using for comprehensions. The Scala compiler will "do the right thing" by rewriting our comprehension in terms of `flatMap` and `map` and inserting the correct implicit conversions to use our `Monad`:

```tut:book
def sumSquare[A[_] : Monad](a: Int, b: Int): A[Int] = {
  for {
    x <- a.pure[A]
    y <- b.pure[A]
  } yield x*x + y*y
}

sumSquare[Option](3, 4)

sumSquare[List](3, 4)
```

### Exercise: Branching out Further with Monads

Let's write a `Monad` for our `Tree` data type from last chapter.
Here's the type again, together with the smart constructors we used
to simplify type class instance selection:

```tut:book
sealed trait Tree[+A]
final case class Branch[A](left: Tree[A], right: Tree[A]) extends Tree[A]
final case class Leaf[A](value: A) extends Tree[A]

def branch[A](left: Tree[A], right: Tree[A]): Tree[A] =
  Branch(left, right)

def leaf[A](value: A): Tree[A] =
  Leaf(value)
```

Verify that the code works on instances of `Branch` and `Leaf`,
and that the `Monad` provides `Functor`-like behaviour for free.

Verify that having a `Monad` in scope allows us to use for comprehensions,
despite the fact that we haven't directly implemented `flatMap` or `map` on `Tree`.

<div class="solution">
The code for `flatMap` is simple. It's similar to the code for `map`.
Again, we recurse down the structure
and use the results from `func` to build a new `Tree`.

The code for `tailRecM` is less simple.
In fact, it's fairly complex!
However, if we follow the types the solution falls out.
Note that we can't make `tailRecM` recursive in this case
because of the double-left case.
We implement the `tailRecM` method,
but don't extend `RecursiveTailRecM`
and we don't use the `tailrec` annotation:

```tut:book
import cats.{Monad, RecursiveTailRecM}

implicit val treeMonad = new Monad[Tree] {
  def pure[A](value: A): Tree[A] =
    Leaf(value)

  def flatMap[A, B](tree: Tree[A])(func: A => Tree[B]): Tree[B] =
    tree match {
      case Branch(l, r) => Branch(flatMap(l)(func), flatMap(r)(func))
      case Leaf(value)  => func(value)
    }

  def tailRecM[A, B](arg: A)(func: A => Tree[A Xor B]): Tree[B] =
    func(arg) match {
      case Branch(l: Tree[A Xor B], r: Tree[A Xor B]) =>
        Branch(
          flatMap(l) {
            case Xor.Left(l)  => tailRecM(l)(func)
            case Xor.Right(l) => pure(l)
          },
          flatMap(r) {
            case Xor.Left(r)  => tailRecM(r)(func)
            case Xor.Right(r) => pure(r)
          }
        )

      case Leaf(Xor.Left(value)) =>
        tailRecM(value)(func)

      case Leaf(Xor.Right(value)) =>
        Leaf(value)
    }
}
```

Now we can use our `Monad` to `flatMap` and `map`:

```tut:book
import cats.syntax.functor._
import cats.syntax.flatMap._

branch(leaf(100), leaf(200)) flatMap (x => branch(leaf(x - 1), leaf(x + 1)))
```

We can also transform `Trees` using for comprehensions:

```tut:book
for {
  a <- branch(leaf(100), leaf(200))
  b <- branch(leaf(a - 10), leaf(a + 10))
  c <- branch(leaf(b - 1), leaf(b + 1))
} yield c
```

The monad for `Option` provides fail-fast semantics.
The monad for `List` provides concatenation semantics.
What are the semantics of `flatMap` for a binary tree?
Every node in the tree has the potential to be replaced with a whole subtree,
producing a kind of "growing" or "feathering" behaviour,
reminiscent of list concatenation along two axes.
</div>
