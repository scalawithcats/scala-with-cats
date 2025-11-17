#import "../stdlib.typ": info, warning, solution, href
=== Foldable in Cats


Cats' `Foldable` abstracts `foldLeft` and `foldRight` into a type class.
Instances of `Foldable` define these two methods
and inherit a host of derived methods.
Cats provides out-of-the-box instances of `Foldable`
for a handful of Scala data types:
`List`, `Vector`, `LazyList`, and `Option`.

We can summon instances as usual using `Foldable.apply`
and call their implementations of `foldLeft` directly.
Let's define an instance of `List`.

```scala mdoc:silent
val ints = List(1, 2, 3)
```

Here is an example using the `Foldable` instance on `List`.

```scala mdoc
import cats.Foldable

Foldable[List].foldLeft(ints, 0)(_ + _)
```

Other sequences like `Vector` and `LazyList` work in the same way.
Here is an example using `Option`,
which is treated like a sequence of zero or one elements.

```scala mdoc:silent
val maybeInt = Option(123)

Foldable[Option].foldLeft(maybeInt, 10)(_ * _)
```


==== Folding Right

`Foldable` defines `foldRight` differently to `foldLeft`,
in terms of the `Eval` monad:

```scala
def foldRight[A, B](fa: F[A], lb: Eval[B])
                     (f: (A, Eval[B]) => Eval[B]): Eval[B]
```

Using `Eval` means folding is always stack safe,
even when the collection's default definition of `foldRight` is not.
For example, the default implementation of `foldRight` for `LazyList` is not stack safe.
The longer the lazy list, the larger the stack requirements for the fold.
A sufficiently large lazy list will trigger a `StackOverflowError`:

```scala mdoc:fail:invisible
// This example isn't printed... it's here to check the next code block is ok:
val bigData = (1 to 100000).to(LazyList)
bigData.foldRight(0L)(_ + _)
```

```scala
val bigData = (1 to 100000).to(LazyList)

bigData.foldRight(0L)(_ + _)
// java.lang.StackOverflowError ...
```

Using `Foldable` forces us to use stack safe operations.

```scala mdoc:invisible
val bigData = (1 to 100000).to(LazyList)
```
```scala mdoc:silent
import cats.Eval

val eval: Eval[Long] =
  Foldable[LazyList].
    foldRight(bigData, Eval.now(0L)) { (num, eval) =>
      eval.map(_ + num)
    }
```

This fixes the overflow exception.

```scala mdoc
eval.value
```


#info(title: [Stack Safety in the Standard Library])[

Stack safety isn't typically an issue when using the standard library.
The most commonly used collection types, such as `List` and `Vector`,
provide stack safe implementations of `foldRight`.

```scala mdoc
(1 to 100000).toList.foldRight(0L)(_ + _)
(1 to 100000).toVector.foldRight(0L)(_ + _)
```

We've called out `LazyList` because it is an exception to this rule.
Whatever data type we're using, though,
it's useful to know that `Eval` has our back.
]


==== Folding with Monoids

`Foldable` provides us with
a host of useful methods defined on top of `foldLeft`.
Many of these are copies of familiar methods from the standard library:
`find`, `exists`, `forall`, `toList`, `isEmpty`, `nonEmpty`, and so on:

```scala mdoc
Foldable[Option].nonEmpty(Option(42))

Foldable[List].find(List(1, 2, 3))(_ % 2 == 0)
```

In addition to these familiar methods,
Cats provides two methods that make use of `Monoids`:

- `combineAll` (and its alias `fold`) combines
  all elements in the sequence using a `Monoid`;

- `foldMap` maps a user-supplied function over the sequence
  and combines the results using a `Monoid`.

For example, we can use `combineAll` to sum over a `List[Int]`.

```scala mdoc
Foldable[List].combineAll(List(1, 2, 3))
```

Alternatively, we can use `foldMap`
to convert each `Int` to a `String` and concatenate them.

```scala mdoc
Foldable[List].foldMap(List(1, 2, 3))(_.toString)
```

Finally, we can compose `Foldables` to work on nested sequences.
Take `ints` below.

```scala mdoc:silent:nest
val ints = List(Vector(1, 2, 3), Vector(4, 5, 6))
```

Composing `Foldables` for `List` and `Vector` supports deep traversal on `ints`.

```scala mdoc
(Foldable[List].compose(using Foldable[Vector])).combineAll(ints)
```


==== Syntax for Foldable

Every method in `Foldable` is available in syntax form.
In each case, the first argument to the method on `Foldable`
becomes the receiver of the method call:

```scala mdoc
import cats.syntax.all.*

List(1, 2, 3).combineAll

List(1, 2, 3).foldMap(_.toString)
```


#info(title: [Explicits over Implicits])[

Remember that Scala will only use an instance of `Foldable`
if the method isn't explicitly available on the receiver.
For example, the following code will
use the version of `foldLeft` defined on `List`

```scala mdoc
List(1, 2, 3).foldLeft(0)(_ + _)
```

whereas the following generic code will use `Foldable`.

```scala mdoc
def sum[F[_]: Foldable](values: F[Int]): Int =
  values.foldLeft(0)(_ + _)
```

We typically don't need to worry about this distinction. It's a feature!
We call the method we want and the compiler uses a `Foldable` when needed
to ensure our code works as expected.
If we need a stack-safe implementation of `foldRight`,
using `Eval` as the accumulator is enough to
force the compiler to select the method from Cats.
]
