## Eval

### Folding Right

<div class="callout callout-danger">
TODO: Incorporate this lot:

One of the big differences between `foldLeft` and `foldRight` in the Scala standard library is that only `foldLeft` is stack-safe for `Lists`. This is because `foldLeft` is written using tail recursion, whereas `foldRight` is a properly recursive method.

Cats works around this by defining `foldRight` in terms of a data type called `Eval`:

```scala
import cats.Eval
import scala.language.higherKinds

trait Foldable[F[_]] {
  def foldLeft[A, B](fa: F[A], b: B)(f: (B, A) => B): B
  def foldRight[A, B](fa: F[A], lb: Eval[B])(f: (A, Eval[B]) => Eval[B]): Eval[B]

  // ...other methods...
}
```

`Eval` is a tool that allows us to abstract over computation strategies such as strict and lazy evaluation. In this instance we can
Calling `foldRight` requires some extra machinery. It expects the accumulated result to be wrapped in a Cats data type called `Eval`:

```tut:book:fail
listFoldable.foldRight(ints, 0)(_ + _)
```

One of the problems with the classic definition of `foldRight` is that it is not stack-safe for left-recursive data structures like `List`. `Eval` is a Cats data structure that we can use to avoid stack overflows.

The full definition of `foldRight` in Cats is as follows:

We will discuss `Eval` and `foldRight` in more detail later this chapter. For now let's look at some of the other methods that `Foldable` defines based on `foldLeft`:
</div>

### Motivation for Eval

<div class="callout callout-danger">
TODO:

`Eval` is a type that Cats uses to abstract over evaluation strategies (lazy, eager, etc).
See more information here:

- https://github.com/typelevel/cats/blob/master/core/src/main/scala/cats/Eval.scala
- http://eed3si9n.com/herding-cats/Eval.html
- Erik's talk from Typelevel Philly (once the video is up)
</div>

### Evaluation Strategies

<div class="callout callout-danger">
TODO:

- now
- later
- always
</div>

### Trampolining

<div class="callout callout-danger">
TODO:

- Discuss trampolining
- Discuss foldRight on Foldable
- Examples of folding with different strategies
- Maybe show a stack explosion
</div>

### Exercises

<div class="callout callout-danger">
TODO:

- Exercises
</div>
