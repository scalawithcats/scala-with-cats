# *Foldable*

The `Foldable` type class captures the concept of data structures that we can iterate over.
`Lists` are foldable, as are `Vectors` and `Streams`.
Using `Foldable`, we can generalise code across any sequence type.
We can also invent new sequence types and plug them into our code.
`Foldable` gives us great use cases for `Monoids` and the `Eval` monad.

## Folds and Folding

Let's start with a quick recap on the concept of folding.
In general, a `fold` function allows users to transform one algebraic data type to another.
For example, the `fold` method on `Option` can return any data type we want by providing handlers for the `Some` and `None` cases:

```scala
def show[A](option: Option[A]): String =
  option.fold("it's none")(v => s"it's some with value $v")
// show: [A](option: Option[A])String

show(None)
// res0: String = it's none

show(Some(10))
// res1: String = it's some with value 10
```

`Foldable` is a type class for folding over sequences.
The typical use case is to accumulate a value as we traverse.
We supply a *seed* value and a *binary function*
to combine it with an item in the sequence.
The function produces another seed,
allowing us to recurse down the sequence.
When we reach the end, the final seed is our result.

The order in which we visit the items may be important
so we normally define two variants:

- `foldLeft` traverses the sequence from "left" to "right" (start to finish);
- `foldRight` traverses the sequence from "right" to "left" (finish to start).

For example, we can sum a `List[Int]` by folding in either direction,
using `0` as our seed and `+` as our binary operation:

```scala
List(1, 2, 3).foldLeft(0)(_ + _)
// res2: Int = 6

List(1, 2, 3).foldRight(0)(_ + _)
// res3: Int = 6
```

The process is illustrated in the figure below. The result is the same regardless of which direction we fold because `+` is associative. If we had provided a non-associative operator, the order of evaluation makes a difference.

![Illustration of foldLeft and foldRight](src/pages/foldable/fold.png)

### Exercise: Reflecting on folds

Try using `foldLeft` and `foldRight` with an empty list as the seed and `::` as the binary operator. What results do you get in each case?

<div class="solution">
Folding from left to right reverses the list:

```scala
List(1, 2, 3).foldLeft(List.empty[Int]) { (seed, item) =>
  item :: seed
}
// res4: List[Int] = List(3, 2, 1)
```

Folding right to left copies the list, leaving the order intact:

```scala
List(1, 2, 3).foldRight(List.empty[Int]) { (item, seed) =>
  item :: seed
}
// res5: List[Int] = List(1, 2, 3)
```

Note that, in order to avoid a type error,
we have to use `List.empty[Int]` as the seed instead of `Nil`.
The compiler type checks parameter lists on method calls from left to right.
If we don't specify that the seed is a `List` of some type,
it incorrectly infers its type as `Nil`, which is a subtype of `List`.
This type is propagated through the rest of the method call
and we get a compilation error because the result of `::` is not a `Nil`:

```scala
List(1, 2, 3).foldRight(Nil)(_ :: _)
// <console>:12: error: type mismatch;
//  found   : List[Int]
//  required: scala.collection.immutable.Nil.type
//        List(1, 2, 3).foldRight(Nil)(_ :: _)
//                                       ^
```

Also note that we can't use placeholder syntax
for the binary function on `foldLeft`,
because the parameters end up the wrong way around:

```scala
List(1, 2, 3).foldLeft(List.empty[Int])(_ :: _)
// <console>:12: error: value :: is not a member of Int
//        List(1, 2, 3).foldLeft(List.empty[Int])(_ :: _)
//                                                  ^
```
</div>

### Exercise: Scaf-fold-ing other methods

`foldLeft` and `foldRight` are very general transformations---they let us transform sequences into any other algebraic data type. We can use folds to implement all of the other high-level sequence operations we know. Prove this to yourself my implementing substitutes for `List's` `map`, `flatMap`, `filter`, and `sum` methods in terms of `foldRight`.

<div class="solution">
Here are the solutions:

```scala
def map[A, B](list: List[A])(func: A => B): List[B] =
  list.foldRight(List.empty[B]) { (item, seed) =>
    func(item) :: seed
  }
// map: [A, B](list: List[A])(func: A => B)List[B]

map(List(1, 2, 3))(_ * 2)
// res8: List[Int] = List(2, 4, 6)
```

```scala
def flatMap[A, B](list: List[A])(func: A => List[B]): List[B] =
  list.foldRight(List.empty[B]) { (item, seed) =>
    func(item) ::: seed
  }
// flatMap: [A, B](list: List[A])(func: A => List[B])List[B]

flatMap(List(1, 2, 3))(a => List(a, a * 10, a * 100))
// res9: List[Int] = List(1, 10, 100, 2, 20, 200, 3, 30, 300)
```

```scala
def filter[A](list: List[A])(func: A => Boolean): List[A] =
  list.foldRight(List.empty[A]) { (item, seed) =>
    if(func(item)) item :: seed else seed
  }
// filter: [A](list: List[A])(func: A => Boolean)List[A]

filter(List(1, 2, 3))(_ % 2 == 1)
// res10: List[Int] = List(1, 3)
```

We've provided two definitions of `sum`,
one using `scala.math.Numeric`
(which recreates the built-in functionality accurately)...

```scala
import scala.math.Numeric
// import scala.math.Numeric

def sumWithNumeric[A](list: List[A])(implicit numeric: Numeric[A]): A =
  list.foldRight(numeric.zero)(numeric.plus)
// sumWithNumeric: [A](list: List[A])(implicit numeric: scala.math.Numeric[A])A

sumWithNumeric(List(1, 2, 3))
// res11: Int = 6
```

and one using `cats.Monoid`
(which is more appropriate to the content of this book):

```scala
import cats.Monoid
// import cats.Monoid

def sumWithMonoid[A](list: List[A])(implicit monoid: Monoid[A]): A =
  list.foldRight(monoid.empty)(monoid.combine)
// sumWithMonoid: [A](list: List[A])(implicit monoid: cats.Monoid[A])A

import cats.std.int._
// import cats.std.int._

sumWithMonoid(List(1, 2, 3))
// res12: Int = 6
```
</div>
