#import "../stdlib.typ": info, warning, exercise, solution
== Foldable 
<sec:foldable>


The `Foldable` type class captures the `foldLeft` and `foldRight` methods
we're used to using with sequences like `List` and `Vector`.
Using `Foldable`, we can write generic folds that work with a variety of sequence types.
We can also invent new sequences and plug them into our code.
`Foldable` gives us great use cases for `Monoids` and the `Eval` monad.


=== Folds and Folding

Let's start with a quick recap of the general concept of folding
a sequence.
Here's an example of a fold.

```scala mdoc:silent
def show[A](list: List[A]): String =
  list.foldLeft("nil")((accum, item) => s"$item then $accum")
```

This produces output like the following.

```scala mdoc
show(Nil)

show(List(1, 2, 3))
```

There are two parameters we pass to `foldLeft`:
an *accumulator* value and a *binary function*
to combine it with each item in the sequence.

The `foldLeft` method works recursively down the sequence.
Our binary function is called repeatedly for each item,
the result of each call becoming the accumulator for the next.
When we reach the end of the sequence,
the final accumulator becomes our final result.

Depending on the operation we're performing,
the order in which we fold may be important.
Because of this there are two standard variants of fold:

- `foldLeft` traverses from "left" to "right" (start to finish);
- `foldRight` traverses from "right" to "left" (finish to start).

@fig:foldable-traverse:fold illustrates each direction.

#figure(
    image("fold.svg", width: 80%),
    caption: [Illustration of foldLeft and foldRight]
)<fig:foldable-traverse:fold>

`foldLeft` and `foldRight` are equivalent
if our binary operation is associative.
For example, we can sum a `List[Int]` by folding in either direction,
using `0` as our accumulator and addition as our operation:

```scala mdoc
List(1, 2, 3).foldLeft(0)(_ + _)
List(1, 2, 3).foldRight(0)(_ + _)
```

If we provide a non-associative operator
the order of evaluation makes a difference.
For example, if we fold using subtraction,
we get different results in each direction:

```scala mdoc
List(1, 2, 3).foldLeft(0)(_ - _)
List(1, 2, 3).foldRight(0)(_ - _)
```

#info(title: [Folds on Sequences])[
    In @sec:adt:structural we learned that folds are an abstraction of structural recursion.
    Here we are looking only at folds on sequences,
    which are ordered collections of data.
    Every sequence, regardless of implementation,
    can be viewed as a list.
    This means it is either an empty sequence
    or contains an elements and a sequence.
    Using this view we can define `foldLeft`
    and `foldRight` for any sequence.
]


#exercise[Reflecting on Folds]

Try using `foldLeft` and `foldRight` with an empty list as the accumulator
and `::` as the binary operator. What results do you get in each case?

#solution[
Folding from left to right reverses the list:

```scala mdoc
List(1, 2, 3).foldLeft(List.empty[Int])((a, i) => i :: a)
```

Folding right to left copies the list, leaving the order intact:

```scala mdoc
List(1, 2, 3).foldRight(List.empty[Int])((i, a) => i :: a)
```

Note that we have to carefully specify
the type of the accumulator to avoid a type error.
We use `List.empty[Int]` to avoid
inferring the accumulator type as `Nil.type` or `List[Nothing]`:

```scala mdoc
List(1, 2, 3).foldRight(Nil)(_ :: _)
```
]


#exercise[Scaf-fold-ing Other Methods]

`foldLeft` and `foldRight` are very general methods.
We can use them to implement many of the other
high-level sequence operations we know.
Prove this to yourself by implementing substitutes
for `List's` `map`, `flatMap`, `filter`, and `sum` methods
in terms of `foldRight`.

#solution[
Here are the solutions:

```scala mdoc:silent
def map[A, B](list: List[A])(func: A => B): List[B] =
  list.foldRight(List.empty[B]) { (item, accum) =>
    func(item) :: accum
  }
```

```scala mdoc
map(List(1, 2, 3))(_ * 2)
```

```scala mdoc:silent
def flatMap[A, B](list: List[A])(func: A => List[B]): List[B] =
  list.foldRight(List.empty[B]) { (item, accum) =>
    func(item) ::: accum
  }
```

```scala mdoc
flatMap(List(1, 2, 3))(a => List(a, a * 10, a * 100))
```

```scala mdoc:silent
def filter[A](list: List[A])(func: A => Boolean): List[A] =
  list.foldRight(List.empty[A]) { (item, accum) =>
    if(func(item)) item :: accum else accum
  }
```

```scala mdoc
filter(List(1, 2, 3))(_ % 2 == 1)
```

We've provided two definitions of `sum`,
one using `scala.math.Numeric`
(which recreates the built-in functionality accurately)...

```scala mdoc:silent
import scala.math.Numeric

def sumWithNumeric[A](list: List[A])
      (using numeric: Numeric[A]): A =
  list.foldRight(numeric.zero)(numeric.plus)
```

```scala mdoc
sumWithNumeric(List(1, 2, 3))
```

and one using `cats.Monoid`
(which is more appropriate to the content of this book):

```scala mdoc:silent
import cats.Monoid

def sumWithMonoid[A](list: List[A])
      (using monoid: Monoid[A]): A =
  list.foldRight(monoid.empty)(monoid.combine)
```

```scala mdoc
sumWithMonoid(List(1, 2, 3))
```
]
