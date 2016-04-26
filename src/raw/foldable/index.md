# Foldable and Eval

The `Foldable` type class captures the concept of data structures that we can iterate over. `Lists` are foldable, as are `Vectors` and `Streams`. Using the `Foldable` type class, we can both write code that works with any iterable data type, and invent new iterable types and plug them into other peoples' code. `Foldable` also gives us a great use case for the `Monoids` we saw in the last chapter.

## Folds and Folding

Let's start with a quick recap on the concept of *folding* in functional programming. In general, a `fold` function allows users to transform one algebraic data type to another. It is a standard representation of structural recursion, typically implemented in Scala using pattern matching. For example, here is an implementation of `fold` for `Option`:

```tut:book
def foldOption[A, B](opt: Option[A], whenNone: => B)(whenSome: A => B): B =
  opt match {
    case Some(value) => whenSome(value)
    case None        => whenNone
  }

foldOption(Option(40), -1)(num => num + 2)

// Note: foldOption above has the same semantics
// as option.fold in the standard library:
Option(40).fold(-1)(num => num + 2)
```

When defining `fold` for sequences, it is natural to express the transformation recursively. We focus on each item in the sequence in turn, transforming it with the user's code and feeding the result into the transformation for the next item. The order in which we visit the items is important, so we normally define two variants of `fold`:

- `foldLeft` traverses the sequence from "left" to "right" (start to finish);
-  `foldRight` traverses the sequence from "right" to "left" (finish to start).

We can demonstrate the difference in traversal direction using the built-in `foldLeft` and `foldRight` methods on `List`:

```tut:book
val strings = List("a", "b", "c")

strings.foldLeft("nil")(_ + "," + _)
strings.foldRight("nil")(_ + "," + _)
```

We can treat folds as low-level functions on top of which we can implement any other algebraic transformation, including examples such as `map`, `flatMap`, `filter`, `reduceLeft`, and so on.

## The Foldable Type Class

`foldLeft` and `foldRight` form an essential part of almost every non-trivial functional program. It seems useful to extract these operations into their own type class, which allows us to:

- extend the built-in functionality of Scala collections with new methods based on folds;
- provide fold implementations for other sequence types, other than those provided in the core library.

Cats calls the type class `Foldable` type class for just this purpose. Before we look at Cats' definition, however, we should define `Foldable` ourselves.

Here is an example type class instance for `List`. We simply delegate to its built-in methods:

```tut:book
object ListFoldable {
  def foldLeft[A, B](lis: List[A], accum: => B)(func: (B, A) => B): B =
    lis.foldLeft(accum)(func)

  def foldRight[A, B](lis: List[A], accum: => B)(func: (A, B) => B): B =
    lis.foldRight(accum)(func)
}
```

Similarly for `Vector`:

```tut:book
object VectorFoldable {
  def foldLeft[A, B](vec: Vector[A], accum: => B)(func: (B, A) => B): B =
    vec.foldLeft(accum)(func)

  def foldRight[A, B](vec: Vector[A], accum: => B)(func: (A, B) => B): B =
    vec.foldRight(accum)(func)
}
```

To write a generic definition of `Foldable` that abstracts over different sequence types, we have to generalise over the `List` and `Vector` type constructors:

```tut:book
import scala.language.higherKinds

trait Foldable[F[_]] {
  def foldLeft[A, B](vec: Vector[A], accum: => B)(func: (A, B) => B): B
  def foldRight[A, B](vec: Vector[A], accum: => B)(func: (B, A) => B): B

  // ...other methods go here...
}
```

If you haven’t seen syntax like `F[_]` before, it’s time to take a brief detour to discuss *type constructors* and *higher kinded types*. We’ll explain that `scala.language` import as well.

<div class="callout callout-danger">
TODO: Exercise: define a few methods in terms of foldLeft and foldRight:

- filter
- map
- flatMap
- combineAll
</div>
