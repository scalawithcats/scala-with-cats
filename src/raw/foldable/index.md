# Foldable and Eval

The `Foldable` type class captures the concept of data structures that we can iterate over. `Lists` are foldable, as are `Vectors` and `Streams`. Using the `Foldable` type class, we can both write code that works with any iterable data type, and invent new iterable types and plug them into other peoples' code. `Foldable` also gives us a great use case for the `Monoids` we saw in the last chapter.

## Folds and Folding

Let's start with a quick recap on the concept of *folding* in functional programming. In general, a `fold` function allows users to transform one algebraic data type to another. It is a standard representation of structural recursion, typically implemented in Scala using pattern matching. For example, here is an implementation of `fold` for `Option`:

```tut:book
def foldOption[A, B](opt: Option[A], transformNone: => B, transformSome: A => B): B =
  opt match {
    case Some(value) => transformSome(value)
    case None        => transformNone
  }

transformOption(Option(40), -1, num => num + 2)

// Note: the `option.fold` method in the standard library
// has the same semantics as our example function above:
Option(40).fold(-1)(num => num + 2)
```

When defining `fold` for sequences, it is natural to express the transformation recursively. We focus on each item in the sequence in turn, transforming it with the user's code and feeding the result into the transformation for the next item. The order in which we visit the items is important, so we normally define two variants of `fold`:

- `foldLeft` traverses the sequence from "left" to "right" (start to finish);
-  `foldRight` traverses the sequence from "right" to "left" (finish to start).

Here are example implementations for `List`:

```tut:book
def foldListLeft[A, B](list: List[A])(handleNil: => B, handlePair: (A, B) => B): B =
  list match {
    case head :: tail => foldListLeft(tail)(handlePair(head, handleNil()), handlePair)
    case Nil          => handleNil()
  }

def foldListRight[A, B](list: List[A])(handleNil: => B, handlePair: (A, B) => B): B =
  list match {
    case head :: tail => handlePair(head, foldListRight(tail)(handleNil, handlePair))
    case Nil          => handleNil()
  }

val strings = List("a", "b", "c")

foldListLeft(strings)("nil", (x: String, y: String) => x + "," + y)
foldListRight(strings)("nil", (x: String, y: String) => x + "," + y)
```

We can view fold functions as *fundamental* transformation over an algebraic data type. Any other transformations---`maps`, `filters`, `flatMaps`, and so on---can be implementation in terms of folds. The same applies for `foldLeft` and `foldRight` and sequences. Cats provides a type class called `Foldable` to represent the two folds and a host of derived transformations.
