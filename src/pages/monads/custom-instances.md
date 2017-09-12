## Defining Custom Monads

We can define a `Monad` for a custom type
by providing implementations of three methods:
`flatMap`, `pure`, and a new method called `tailRecM`.
Here is an implementation of `Monad` for `Option` as an example:

```tut:book:silent
import cats.Monad
import scala.annotation.tailrec

val optionMonad =
  new Monad[Option] {
    def flatMap[A, B](opt: Option[A])
        (fn: A => Option[B]): Option[B] =
      opt flatMap fn

    def pure[A](opt: A): Option[A] =
      Some(opt)

    @tailrec
    def tailRecM[A, B](a: A)
        (fn: A => Option[Either[A, B]]): Option[B] =
      fn(a) match {
        case None           => None
        case Some(Left(a1)) => tailRecM(a1)(fn)
        case Some(Right(b)) => Some(b)
      }
  }
```

`tailRecM` is an optimisation in Cats that limits
the amount of stack space used by nested calls to `flatMap`.
The technique comes from a [2015 paper][link-phil-freeman-tailrecm]
by PureScript creator Phil Freeman.
The method should recursively call itself
until the result of `fn` returns a `Right`.

If we can make `tailRecM` tail-recursive,
Cats is able to guarantee stack safety
in complex operations involving recursive `flatMap` operations
such as folding over large lists (see Section [@sec:foldable]).
If we can't make `tailRecM` tail-recursive,
Cats cannot make these guarantees
and extreme use cases may result in `StackOverflowErrors`.
All of the built-in monads in Cats have
tail-recursive implementations of `tailRecM`,
although writing one for custom monads
can be a challenge... as we shall see.

### Exercise: Branching out Further with Monads

Let's write a `Monad` for our `Tree` data type from last chapter.
Here's the type again, together with the smart constructors we used
to simplify type class instance selection:

```tut:book:silent
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

Don't feel you have to make `tailRecM` tail-recursive.
Doing so is actually very hard.
We've included both tail-recursive
and non-tail-recursive implementations
in the solutions so you can check your work.

<div class="solution">
The code for `flatMap` is simple. It's similar to the code for `map`.
Again, we recurse down the structure
and use the results from `func` to build a new `Tree`.

The code for `tailRecM` is less simple.
In fact, it's fairly complex
regardless of whether we make it tail-recursive or not.

If we follow the types,
the non-tail-recursive solution falls out:

```tut:book:silent
import cats.Monad

implicit val treeMonad = new Monad[Tree] {
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
     (func: A => Tree[Either[A, B]]): Tree[B] =
   func(arg) match {
     case Branch(l, r) =>
       Branch(
         flatMap(l) {
           case Left(l)  => tailRecM(l)(func)
           case Right(l) => pure(l)
         },
         flatMap(r) {
           case Left(r)  => tailRecM(r)(func)
           case Right(r) => pure(r)
         }
       )

     case Leaf(Left(value)) =>
       tailRecM(value)(func)

     case Leaf(Right(value)) =>
       Leaf(value)
   }
}
```

The solution above is perfectly fine for this exercise.
Its only downside is that Cats cannot guarantee
stack safety in complex operations involving
recursive calls to `flatMap`.

The tail-recursive solution is much harder to write.
We actually adapted this solution from
[this Stack Overflow post][link-so-tree-tailrecm] by Nazarii Bardiuk
rather than attempt to write it ourselves.
It involves an explicit depth first traversal of the tree,
maintaining an `open` list of nodes to visit
and a `closed` list of nodes to use to reconstruct the tree:

```tut:book:silent
import cats.Monad

implicit val treeMonad = new Monad[Tree] {
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
      closed: List[Tree[B]]
    ): List[Tree[B]] = open match {
      case Branch(l, r) :: next =>
        l match {
          case Branch(_, _) =>
            loop(l :: r :: next, closed)
          case Leaf(Left(value)) =>
            loop(func(value) :: r :: next, closed)
          case Leaf(Right(value)) =>
            loop(r :: next, pure(value) :: closed)
        }

      case Leaf(Left(value)) :: next =>
        loop(func(value) :: next, closed)

      case Leaf(Right(value)) :: next =>
        closed match {
          case head :: tail =>
            loop(next, Branch(head, pure(value)) :: tail)
          case Nil =>
            loop(next, pure(value) :: closed)
        }
      case Nil =>
        closed
    }

    loop(List(func(arg)), Nil).head
  }
}
```

Regardless of which version of `tailRecM` we define,
we can use our `Monad` to `flatMap` and `map` on `Trees`:

```tut:book:silent
import cats.syntax.functor._
import cats.syntax.flatMap._
```

```tut:book
branch(leaf(100), leaf(200)).
  flatMap(x => branch(leaf(x - 1), leaf(x + 1)))
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
