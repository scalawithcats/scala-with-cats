# Foldable and Eval

The `Foldable` type class captures the concept of data structures that we can iterate over. `Lists` are foldable, as are `Vectors` and `Streams`. Using the `Foldable` type class, we can both write code that works with any iterable data type, and invent new iterable types and plug them into other peoples' code. `Foldable` also gives us a great use case for the `Monoids` we saw in the last chapter.

## Folds and Folding

Let's start with a quick recap on the concept of *folding* in functional programming.

In general, a `fold` is a function that allows users to transform one algebraic data type to another. Given an ADT, we can always define a fold operation that supports arbitrary transformations.

For example, suppose we have a simple ADT such as `Option`:

```scala
sealed trait Option[+A]
final case class Some[A](value: Double) extends Option[A]
final case object None extends Option[Nothing]
```

Given this structural knowledge, we can define a `fold` function that allows users to perform arbitrary transformations on `Options` without knowing about implementation details such as `Some` and `None`. The user provides parameters specifying the transformations for the full and empty cases and `fold` handles the rest:

```tut:book
def foldOption[A, B](opt: Option[A])(handleNone: () => B, handleSome: A => B): B =
  opt match {
    case Some(value) => handleSome(value)
    case None        => handleNone()
  }

val opt = Option(42)

foldOption(opt)(
  () => "Empty",
  num => if(num == 42) "We have the answer!" else "Another number"
)
```

`fold` is a fundamental building block on which we can define all other transformational methods:

```tut:book
def flatMapOption[A, B](opt: Option[A])(func: A => Option[B]): Option[B] =
  foldOption(opt)(() => None, func)

def mapOption[A, B](opt: Option[A])(func: A => B): Option[B] =
  foldOption(opt)(() => None, value => Some(func(value)))

def filterOption[A](opt: Option[A])(func: A => Boolean): Boolean =
  foldOption(opt)(() => false, func)
```

When defining `fold` for recursive data structures such as `Lists`, we need a way to feed the result at one level of recursion into the computation at the next level of recursion. We do this by adding a parameter to the transformation function for the recursive case:

```tut:book
def foldList[A, B](list: List[A])(handleNil: () => B, handlePair: (A, B) => B): B =
  ???
```

We often also find that there are multiple ways we can write `fold` that traverse the data structure in different directions. With sequences we call these `foldLeft`, which applies the handlers from left to right, and `foldRight`, which applies them from right to left:

```tut:book
def foldListLeft[A, B](list: List[A])(handleNil: () => B, handlePair: (A, B) => B): B =
  list match {
    case head :: tail => foldListLeft(tail)(() => handlePair(head, handleNil()), handlePair)
    case Nil          => handleNil()
  }

def foldListRight[A, B](list: List[A])(handleNil: () => B, handlePair: (A, B) => B): B =
  list match {
    case head :: tail => handlePair(head, foldListRight(tail)(handleNil, handlePair))
    case Nil          => handleNil()
  }

val strings = List("a", "b", "c")

foldListLeft(strings)(
  () => "nil",
  (x: String, y: String) => x + "," + y)

foldListRight(strings)(
  () => "nil",
  (x, y) => x + "," + y)
```

 the transformation functions themselves have to become `fold` typically becomes recursive. The result of one level of recursion is fed as an input to the handler for the recursive case. Hence

the  sequences such as `List`, there are multiple ways of writing `fold`:

```tut:book
def foldListLeft[A, B](list: List[A], handleNil: B)(handleHead: A => B): B =
  list match {
    case head :: tail => handleHead()
  }
```

## The Concept of a Foldable

<div class="callout callout-danger">
TODO:

- Foldable captures the concept of a data structure that can be iterated over
- Talk about sequences (Lists, Streams, etc)
- Talk about non-obvious instances
</div>
