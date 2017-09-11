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
If we can make `tailRecM` tail recursive,
we should do so to allow Cats to perform
additional internal optimisations.

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

<div class="solution">
The code for `flatMap` is simple. It's similar to the code for `map`.
Again, we recurse down the structure
and use the results from `func` to build a new `Tree`.

The code for `tailRecM` is less simple.
In fact, it's fairly complex!
However, if we follow the types the solution falls out.
Note that we can't make `tailRecM` tail recursive in this case
because we have to recurse twice when processing a `Branch`.
We implement the `tailRecM` method,
and we don't use the `tailrec` annotation:

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

Now we can use our `Monad` to `flatMap` and `map`:

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
