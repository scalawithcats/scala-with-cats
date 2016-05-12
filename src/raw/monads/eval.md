## Eval

[`cats.Eval`][cats.Eval] is a monad that allows us to abstract over different *models of evaluation*. We typically hear of two such models: *eager* and *lazy*. `Eval` throws in a further distinction of *memoized* and *unmemoized* to create three models of evaluation:

 - *now*---evaluated once immediately (equivalent to `val`);
 - *later*---evaluated once when value is needed (equivalent to `lazy val`);
 - *always*---evaluated every time value is needed (equivalent to `def`).

<div class="callout callout-danger">
TODO: Explain why this is useful. Maybe a model of lazy evaluation? Fibonacci numbers?
</div>

### Eager, lazy, memoized, oh my!

What do these terms mean?

*Eager* computations happen immediately, whereas *lazy* computations happen on access. For example, Scala `vals` are eager definitions, whereas `defs` and `lazy vals` are lazy:

```tut:book
// vals are eager.
// They are computed immediately on declaration:

val x = {
  println("Computing X")
  1 + 1
}

// defs and lazy vals are lazy.
// They aren't computed until they are accessed:

def y = {
  println("Computing Y")
  1 + 1
}

y
```

*Memoized* computations happen once. After that, their results are cached and re-used on subsequent accesses without being re-computed. Scala `vals` and `lazy vals` are memoized, whereas `defs` are not memoized:

```tut:book
// vals and lazy vals are memoized.
// They are computed once and cached.
// Subsequent accesses do not re-compute the result:
val x = {
  println("Computing X")
  1 + 1
}

x
x

// defs are not memoized.
// They are re-computed every time they are accessed:
def y = {
  println("Computing Y")
  1 + 1
}

y
y
```

The table below shows a summary of these behaviours:

+------------------+--------------------+---------------------+
|                  | Eager              | Lazy                |
+==================+====================+=====================+
| Memoized         | `val`, `now`       | `lazy val`, `later` |
+------------------+--------------------+---------------------+
| Not memoized     | `def`, `always`    | N/A (impossible)    |
+------------------+--------------------+---------------------+

### Eval's models of evaluation


### Folding Right

def add(x: Int, y: Int) = {
  println(new Exception().getStackTrace().length)
  x + y
}



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
