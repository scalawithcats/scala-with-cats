## *Foldable* {#sec:foldable}

The `Foldable` type class captures the `foldLeft` and `foldRight` methods
we're used to in sequences like `Lists`, `Vectors`, and `Streams`.
Using `Foldable`, we can write generic folds that work with a variety of sequence types.
We can also invent new sequences and plug them into our code.
`Foldable` gives us great use cases for `Monoids` and the `Eval` monad.

### Folds and Folding

Let's start with a quick recap on the general concept of folding.
`Foldable` is a type class for folding over sequences.
We supply an *accumulator* value and a *binary function*
to combine it with an item in the sequence:

```tut:book:silent
def show[A](list: List[A]): String =
  list.foldLeft("nil")((accum, item) => s"$item then $accum")
```

```tut:book
show(Nil)

show(List(1, 2, 3))
```

The view provided by `Foldable` is recursive.
Our binary function is called repeatedly
for each item in the sequence,
result from each call becoming the accumulator for the next.
When we reach the end of the sequence,
the final accumulator becomes our result.

Depending on the operation we're performing,
the order in which we fold may be important.
Because of this there are two standard variants of fold:

- `foldLeft` traverses from "left" to "right" (start to finish);
- `foldRight` traverses from "right" to "left" (finish to start).

Figure [@fig:foldable-traverse:fold] illustrates each direction.

![Illustration of foldLeft and foldRight](src/pages/foldable-traverse/fold.pdf+svg){#fig:foldable-traverse:fold}

`foldLeft` and `foldRight` are equivalent
if our binary operation is commutative.
For example, we can sum a `List[Int]` by folding in either direction,
using `0` as our accumulator and `+` as our operation:

```tut:book
List(1, 2, 3).foldLeft(0)(_ + _)
List(1, 2, 3).foldRight(0)(_ + _)
```

If provide a non-commutative operator
the order of evaluation makes a difference.
For example, if we fold using `-`,
we get different results in each direction:

```tut:book
List(1, 2, 3).foldLeft(0)(_ - _)
List(1, 2, 3).foldRight(0)(_ - _)
```

### Exercise: Reflecting on Folds

Try using `foldLeft` and `foldRight` with an empty list as the accumulator
and `::` as the binary operator. What results do you get in each case?

<div class="solution">
Folding from left to right reverses the list:

```tut:book
List(1, 2, 3).foldLeft(List.empty[Int])((a, i) => i :: a)
```

Folding right to left copies the list, leaving the order intact:

```tut:book
List(1, 2, 3).foldRight(List.empty[Int])((i, a) => i :: a)
```

Note that we have to carefully specify
the type of the accumulator to avoid a type error.
We use `List.empty[Int]` to avoid
inferring the accumulator type as `Nil.type` or `List[Nothing]`:

```tut:book:fail
List(1, 2, 3).foldRight(Nil)(_ :: _)
```
</div>

### Exercise: Scaf-fold-ing other methods

`foldLeft` and `foldRight` are very general methods.
We can use them to implement many of the other
high-level sequence operations we know.
Prove this to yourself by implementing substitutes
for `List's` `map`, `flatMap`, `filter`, and `sum` methods
in terms of `foldRight`.

<div class="solution">
Here are the solutions:

```tut:book:silent
def map[A, B](list: List[A])(func: A => B): List[B] =
  list.foldRight(List.empty[B]) { (item, accum) =>
    func(item) :: accum
  }
```

```tut:book
map(List(1, 2, 3))(_ * 2)
```

```tut:book:silent
def flatMap[A, B](list: List[A])(func: A => List[B]): List[B] =
  list.foldRight(List.empty[B]) { (item, accum) =>
    func(item) ::: accum
  }
```

```tut:book
flatMap(List(1, 2, 3))(a => List(a, a * 10, a * 100))
```

```tut:book:silent
def filter[A](list: List[A])(func: A => Boolean): List[A] =
  list.foldRight(List.empty[A]) { (item, accum) =>
    if(func(item)) item :: accum else accum
  }
```

```tut:book
filter(List(1, 2, 3))(_ % 2 == 1)
```

We've provided two definitions of `sum`,
one using `scala.math.Numeric`
(which recreates the built-in functionality accurately)...

```tut:book:silent
import scala.math.Numeric

def sumWithNumeric[A](list: List[A])
    (implicit numeric: Numeric[A]): A =
  list.foldRight(numeric.zero)(numeric.plus)
```

```tut:book
sumWithNumeric(List(1, 2, 3))
```

and one using `cats.Monoid`
(which is more appropriate to the content of this book):

```tut:book:silent
import cats.Monoid

def sumWithMonoid[A](list: List[A])
    (implicit monoid: Monoid[A]): A =
  list.foldRight(monoid.empty)(monoid.combine)

import cats.instances.int._
```

```tut:book
sumWithMonoid(List(1, 2, 3))
```
</div>
