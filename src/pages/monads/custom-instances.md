## Defining Custom Monads

We can define a `Monad` for a custom type
by providing implementations of three methods:
`flatMap`, `pure`, and
a method we haven't seen yet called `tailRecM`.
Here is an implementation of `Monad` for `Option` as an example:

```scala mdoc:silent:reset-object
import cats.Monad
import scala.annotation.tailrec

val optionMonad = new Monad[Option] {
  def flatMap[A, B](opt: Option[A])
      (fn: A => Option[B]): Option[B] =
    opt.flatMap(fn)

  def pure[A](opt: A): Option[A] =
    Some(opt)

  @tailrec
  def tailRecM[A, B](a: A)(fn: A => Option[Either[A, B]]): Option[B] = {
    fn(a) match {
      case None           => None
      case Some(Left(a1)) => tailRecM(a1)(fn)
      case Some(Right(b)) => Some(b)
    }
  }
}
```

The `tailRecM` method is an optimisation used in Cats to limit
the amount of stack space consumed by nested calls to `flatMap`.
The technique comes from a [2015 paper][link-phil-freeman-tailrecm]
by PureScript creator Phil Freeman.
The method should recursively call itself
until the result of `fn` returns a `Right`.

To motivate its use let's use the following example:
Suppose we want to write a method that calls a
function until the function indicates it should stop.
The function will return a monad instance because,
as we know,
monads represent sequencing
and many monads have some notion of stopping.

We can write this method in terms of `flatMap`.

```scala mdoc:silent
import cats.syntax.flatMap._ // For flatMap

def retry[F[_]: Monad, A](start: A)(f: A => F[A]): F[A] =
  f(start).flatMap{ a =>
    retry(a)(f)
  }
```

Unfortunately it is not stack-safe.
It works for small input.

```scala mdoc
import cats.instances.option._

retry(100)(a => if(a == 0) None else Some(a - 1))
```

but if we try large input we get a `StackOverflowError`.

```scala
retry(100000)(a => if(a == 0) None else Some(a - 1))
// KABLOOIE!!!!
```

We can instead rewrite this method
using `tailRecM`.

```scala mdoc:silent
import cats.syntax.functor._ // for map

def retryTailRecM[F[_]: Monad, A](start: A)(f: A => F[A]): F[A] =
  Monad[F].tailRecM(start){ a =>
    f(a).map(a2 => Left(a2))
  }
```

Now it runs successfully
no matter how many time we recurse.

```scala mdoc
retryTailRecM(100000)(a => if(a == 0) None else Some(a - 1))
```

It's important to note
that we have to explicitly call `tailRecM`.
There isn't a code transformation
that will convert non-tail recursive
code into tail recursive code
that uses `tailRecM`.
However there are several utilities
provided by the `Monad` type class
that makes these kinds of methods easier to write.
For example, we can rewrite `retry`
in terms of `iterateWhileM`
and we don't have to explicitly call `tailRecM`.

```scala mdoc:silent
import cats.syntax.monad._ // for iterateWhileM

def retryM[F[_]: Monad, A](start: A)(f: A => F[A]): F[A] =
  start.iterateWhileM(f)(a => true)
```

```scala mdoc
retryM(100000)(a => if(a == 0) None else Some(a - 1))
```

We'll see more methods that use `tailRecM` in Section [@sec:foldable].

All of the built-in monads in Cats have
tail-recursive implementations of `tailRecM`,
although writing one for custom monads
can be a challenge... as we shall see.

### Exercise: Branching out Further with Monads

Let's write a `Monad` for our `Tree` data type from last chapter.
Here's the type again:

```scala mdoc:silent
sealed trait Tree[+A]

final case class Branch[A](left: Tree[A], right: Tree[A])
  extends Tree[A]

final case class Leaf[A](value: A) extends Tree[A]

def branch[A](left: Tree[A], right: Tree[A]): Tree[A] =
  Branch(left, right)

def leaf[A](value: A): Tree[A] =
  Leaf(value)
```

Verify that the code works on instances of `Branch` and `Leaf`,
and that the `Monad` provides `Functor`-like behaviour for free.

Also verify that having a `Monad` in scope allows us to use for comprehensions,
despite the fact that we haven't directly implemented `flatMap` or `map` on `Tree`.

Don't feel you have to make `tailRecM` tail-recursive.
Doing so is quite difficult.
We've included both tail-recursive
and non-tail-recursive implementations
in the solutions so you can check your work.

<div class="solution">
The code for `flatMap` is similar to the code for `map`.
Again, we recurse down the structure
and use the results from `func` to build a new `Tree`.

The code for `tailRecM` is fairly complex
regardless of whether we make it tail-recursive or not.

If we follow the types,
the non-tail-recursive solution falls out:

```scala mdoc:silent
import cats.Monad

implicit val treeMonad: Monad[Tree] = new Monad[Tree] {
  def pure[A](value: A): Tree[A] =
    Leaf(value)

  def flatMap[A, B](tree: Tree[A])
      (func: A => Tree[B]): Tree[B] =
    tree match {
      case Branch(l, r) =>
        Branch(flatMap(l)(func), flatMap(r)(func))
      case Leaf(value)  =>
        func(value)
    }

  def tailRecM[A, B](a: A)(func: A => Tree[Either[A, B]]): Tree[B] = {
    flatMap(func(a)) {
      case Left(value) =>
        tailRecM(value)(func)
      case Right(value) =>
        Leaf(value)
    }
  }
}
```

The solution above is perfectly fine for this exercise.
Its only downside is that Cats cannot make guarantees about stack safety.

The tail-recursive solution is much harder to write.
We adapted this solution from
[this Stack Overflow post][link-so-tree-tailrecm] by Nazarii Bardiuk.
It involves an explicit depth first traversal of the tree,
maintaining an `open` list of nodes to visit
and a `closed` list of nodes to use to reconstruct the tree:

```scala mdoc:invisible:reset-object
sealed trait Tree[+A]

final case class Branch[A](left: Tree[A], right: Tree[A])
  extends Tree[A]

final case class Leaf[A](value: A) extends Tree[A]

def branch[A](left: Tree[A], right: Tree[A]): Tree[A] =
  Branch(left, right)

def leaf[A](value: A): Tree[A] =
  Leaf(value)
```
```scala mdoc:silent
import cats.Monad
import scala.annotation.tailrec

implicit val treeMonad: Monad[Tree] = new Monad[Tree] {
  def pure[A](value: A): Tree[A] =
    Leaf(value)

  def flatMap[A, B](tree: Tree[A])
      (func: A => Tree[B]): Tree[B] =
    tree match {
      case Branch(l, r) =>
        Branch(flatMap(l)(func), flatMap(r)(func))
      case Leaf(value)  =>
        func(value)
    }

  def tailRecM[A, B](arg: A)
      (func: A => Tree[Either[A, B]]): Tree[B] = {
    @tailrec
    def loop(
          open: List[Tree[Either[A, B]]],
          closed: List[Option[Tree[B]]]): List[Tree[B]] =
      open match {
        case Branch(l, r) :: next =>
          loop(l :: r :: next, None :: closed)

        case Leaf(Left(value)) :: next =>
          loop(func(value) :: next, closed)

        case Leaf(Right(value)) :: next =>
          loop(next, Some(pure(value)) :: closed)

        case Nil =>
          closed.foldLeft(Nil: List[Tree[B]]) { (acc, maybeTree) =>
            maybeTree.map(_ :: acc).getOrElse {
              acc match {
                case left :: right :: tail => branch(left, right) :: tail
              }
            }
          }
      }

    loop(List(func(arg)), Nil).head
  }
}
```

Regardless of which version of `tailRecM` we define,
we can use our `Monad` to `flatMap` and `map` on `Trees`:

```scala mdoc:silent
import cats.syntax.functor._ // for map
import cats.syntax.flatMap._ // for flatMap
```

```scala mdoc
branch(leaf(100), leaf(200)).
  flatMap(x => branch(leaf(x - 1), leaf(x + 1)))
```

We can also transform `Trees` using for comprehensions:

```scala mdoc
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
