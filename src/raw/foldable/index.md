# Foldable and Eval

The `Foldable` type class captures the concept of data structures that we can iterate over.
`Lists` are foldable, as are `Vectors` and `Streams`.
Using `Foldable` we can write generalise code across any sequence type.
We can also invent new sequence types and plug them into other peoples' code.
`Foldable` gives us great use cases for `Monoids` and the `Eval` monad.

## Folds and Folding

Let's start with a quick recap on the concept of folding.
In general, a `fold` function allows users to transform one algebraic data type to another.
It is a standard representation of structural recursion that we find throughout,
typically implemented in Scala using pattern matching.
For example, here is an implementation of `fold` for `Option`:

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

`Foldable` is a type class for folding over sequences,
where it is natural to express the transformation recursively.
We focus on each item in the sequence in turn,
transforming it with the user's code and feeding the result into the transformation for the next item.
The order in which we visit the items is important so we normally define two variants of `fold`:

- `foldLeft` traverses the sequence from "left" to "right" (start to finish);
- `foldRight` traverses the sequence from "right" to "left" (finish to start).

We can demonstrate the difference in traversal direction using the built-in
`foldLeft` and `foldRight` methods on `List`:

```tut:book
val strings = List("a", "b", "c")
strings.foldLeft("nil")(_ + "," + _)
strings.foldRight("nil")(_ + "," + _)
```

Folds are low-level functions on which we can implement any other algebraic transformation,
including examples such as `map`, `flatMap`, `filter`, and the various variants of `reduce`.

<div class="callout callout-danger">
TODO: Exercise: define a few methods in terms of `foldLeft` and `foldRight`:

- filter
- map
- flatMap
- combineAll
</div>
