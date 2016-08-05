# *Foldable*

The `Foldable` type class captures the concept of data structures that we can iterate over.
`Lists` are foldable, as are `Vectors` and `Streams`.
Using `Foldable`, we can generalise code across any sequence type.
We can also invent new sequence types and plug them into our code.
`Foldable` gives us great use cases for `Monoids` and the `Eval` monad.

## Folds and Folding

Let's start with a quick recap on the concept of folding.
In general, a `fold` function allows users to transform one algebraic data type to another.
For example, the `fold` method on `Option` can return any algebraic data type
by providing handlers for the `Some` and `None` cases:

```tut:book
def show[A](option: Option[A]): String =
  option.fold("it's none")(v => s"it's some with value $v")

show(None)

show(Some(10))
```

`Foldable` is a type class for folding over sequences,
which we can model as a sum type consisting of a
pair and a terminator, similar to a regular `List`.
We supply an *accumulator* value and a *binary function*
to combine it with an item in the sequence:

```tut:book
def show[A](list: List[A]): String =
  list.foldLeft("nil")((accum, item) => s"$item then $accum")

show(Nil)

show(List(1, 2, 3))
```

Sequences are recursive, so our binary function is called
recursively for each item in the sequence.
The function produces another accumulator,
which we use to process the tail of the list.
When we reach the end, the final accumulator is our result.
The typical use case is to accumulate a value as we traverse.

Depending on the operation we're performing,
the order in which we visit the items may be important.
Because of this, we normally define two variants of fold:

- `foldLeft` traverses the sequence from "left" to "right" (start to finish);
- `foldRight` traverses the sequence from "right" to "left" (finish to start).

We can sum a `List[Int]` by folding in either direction,
using `0` as our accumulator and `+` as our binary operation:

```tut:book
List(1, 2, 3).foldLeft(0)(_ + _)
List(1, 2, 3).foldRight(0)(_ + _)
```

The process of folding is illustrated in the figure below.
The result is the same regardless of which direction we fold because `+` is commutative:

![Illustration of foldLeft and foldRight](src/raw/foldable/fold.png)

If provide a non-commutative operator
the order of evaluation makes a difference.
For example, if we fold using `-`,
we get different results in each direction:

```tut:book
List(1, 2, 3).foldLeft(0)(_ - _)
List(1, 2, 3).foldRight(0)(_ - _)
```

### Exercise: Reflecting on folds

Try using `foldLeft` and `foldRight` with an empty list as the accumulator and `::` as the binary operator. What results do you get in each case?

<div class="solution">
Folding from left to right reverses the list:

```tut:book
List(1, 2, 3).foldLeft(List.empty[Int]) { (accum, item) =>
  item :: accum
}
```

Folding right to left copies the list, leaving the order intact:

```tut:book
List(1, 2, 3).foldRight(List.empty[Int]) { (item, accum) =>
  item :: accum
}
```

Note that, in order to avoid a type error,
we have to use `List.empty[Int]` as the accumulator instead of `Nil`.
The compiler type checks parameter lists on method calls from left to right.
If we don't specify that the accumulator is a `List` of some type,
it incorrectly infers its type as `Nil`, which is a subtype of `List`.
This type is propagated through the rest of the method call
and we get a compilation error because the result of `::` is not a `Nil`:

```tut:book:fail
List(1, 2, 3).foldRight(Nil)(_ :: _)
```

Also note that we can't use placeholder syntax
for the binary function on `foldLeft`,
because the parameters end up the wrong way around:

```tut:book:fail
List(1, 2, 3).foldLeft(List.empty[Int])(_ :: _)
```
</div>

### Exercise: Scaf-fold-ing other methods

`foldLeft` and `foldRight` are very general transformations---they let us transform sequences into any other algebraic data type. We can use folds to implement all of the other high-level sequence operations we know. Prove this to yourself my implementing substitutes for `List's` `map`, `flatMap`, `filter`, and `sum` methods in terms of `foldRight`.

<div class="solution">
Here are the solutions:

```tut:book
def map[A, B](list: List[A])(func: A => B): List[B] =
  list.foldRight(List.empty[B]) { (item, accum) =>
    func(item) :: accum
  }

map(List(1, 2, 3))(_ * 2)
```

```tut:book
def flatMap[A, B](list: List[A])(func: A => List[B]): List[B] =
  list.foldRight(List.empty[B]) { (item, accum) =>
    func(item) ::: accum
  }

flatMap(List(1, 2, 3))(a => List(a, a * 10, a * 100))
```

```tut:book
def filter[A](list: List[A])(func: A => Boolean): List[A] =
  list.foldRight(List.empty[A]) { (item, accum) =>
    if(func(item)) item :: accum else accum
  }

filter(List(1, 2, 3))(_ % 2 == 1)
```

We've provided two definitions of `sum`,
one using `scala.math.Numeric`
(which recreates the built-in functionality accurately)...

```tut:book
import scala.math.Numeric

def sumWithNumeric[A](list: List[A])(implicit numeric: Numeric[A]): A =
  list.foldRight(numeric.zero)(numeric.plus)

sumWithNumeric(List(1, 2, 3))
```

and one using `cats.Monoid`
(which is more appropriate to the content of this book):

```tut:book
import cats.Monoid

def sumWithMonoid[A](list: List[A])(implicit monoid: Monoid[A]): A =
  list.foldRight(monoid.empty)(monoid.combine)

import cats.instances.int._

sumWithMonoid(List(1, 2, 3))
```
</div>
