## Foldable in Cats

Cats' `Foldable` abstracts the two operations `foldLeft` and `foldRight` into a type class.
Instances are required to define those two methods,
and inherit a host of derived methods for free.

Cats provides out-of-the-box instances of `Foldable` for a handful of Scala data types:
`List`, `Vector`, `Stream`, `Option`, and `Map`.
We can summon instances as usual using `Foldable.apply`
and call their implementations of `foldLeft` directly:

```tut:book
val ints = List(1, 2, 3)

import cats.Foldable
import cats.std.list._

Foldable[List].foldLeft(ints, 0)(_ + _)

val maybeInt = Option(1)

import cats.std.option._

Foldable[Option].foldLeft(maybeInt, "")(_ + _)
```

The `Foldable` instance for `Map` allows us to fold over its values.
Because `Map` has two type parameters,
we have to fix one of them to create the expected single-parameter type constructor:

```tut:book
type StringMap[A] = Map[String, A]

val stringMap = Map("a" -> "b", "c" -> "d")

import cats.std.map._

Foldable[StringMap].foldLeft(stringMap, "nil")(_ + "," + _)
```

`Foldable` defines `foldRight` differently to `foldLeft`, in terms of the `Eval` monad:

```scala
def foldRight[A, B](fa: F[A], lb: Eval[B])(f: (A, Eval[B]) => Eval[B]): Eval[B]
```

Using `Eval` means folding with `Foldable` is always *stack safe*,
even when the collection's default definition of `foldRight` is not.

```tut:book
def stackDepth: Int =
  new Exception().getStackTrace.length

// The default implementation of foldRight for Stream is not stack safe:
(1 to 5).toStream.foldRight(0) { (a: Int, b: Int) =>
  println(stackDepth)
  a + b
}

// The Foldable implementation is stack safe because we're using Eval:
(1 to 5).toStream.foldRight(0) { (a: Int, b: Eval[Int]) =>
  println(stackDepth)
  b.map(_ + a)
}.value
```

<div class="callout callout-info">
*What is stack safety?*

A *stack safe* algorithm always consumes the same number of stack frames,
regardless of the size of the data structure on which it is operating.
They are "safe" because they can never cause `StackOverflowExceptions`.

Many sequences such as `Lists` and `Streams` are right-associative.
We can write stack safe implementations of `foldLeft` for these types using tail recursion.
However, implementations of `foldRight` have to work against the direction of associativity.
We can either resort to regular recursion, using the stack to combine values on the way back up,
or use a technique called "trampolining" to rewrite the computation as a (heap allocated) list of functions.

Trampolining is beyond the scope of this book,
suffice to say that `Eval` uses this technique to ensure that all our `foldRights` are stack safe by default.
</div>

### Methods of Foldable

Cats' `Foldable` provides us with a host of useful methods defined on top of `foldLeft`.
Many of these are facimiles of familiar methods from the standard library,
including `find`, `exists`, `forall`, `toList`, `isEmpty`, and `nonEmpty`:

```tut:book
Foldable[Option].nonEmpty(Option(42))

Foldable[List].find(List(1, 2, 3))(_ % 2 == 0)
```

In addition to these familiar methods, Cats provides two methods that make use of `Monoids`:

- `combineAll` (and its alias `fold`) combines all elements in the sequence using their `Monoid`;
- `foldMap` maps a user-supplied function over the sequence and combines the results using a `Monoid`.

Here are some examples:

```tut:book
import cats.std.int._ // import Monoid[Int]

Foldable[List].combineAll(List(1, 2, 3))

import cats.std.string._ // import Monoid[String]

Foldable[List].foldMap(List(1, 2, 3))(_.toString)
```

Finally, we can compose `Foldables` to support deep traversal of nested sequences:

```tut:book
import cats.std.vector._

val ints = List(Vector(1, 2, 3), Vector(4, 5, 6))

Foldable[List].compose(Foldable[Vector]).combineAll(ints)
```

### Syntax for Foldable

Every method in `Foldable` is available in syntax form via the `cats.syntax.foldable` import.
In each case, the first argument to the method on `Foldable` becomes the method receiver:

```tut:book
import cats.syntax.foldable._

List(1, 2, 3).combineAll

List(1, 2, 3).foldMap(_.toString)
```

<div class="callout callout-info">
*Explicits over Implicits*

Remember that Scala will only use an instance of `Foldable`
if the method isn't explicitly available on the receiver.
For example, the following code will use the version of `foldLeft` defined on `List`:

```tut:book
List(1, 2, 3).foldLeft(0)(_ + _)
```

whereas the following generic code will use `Foldable`:

```tut:book
import scala.language.higherKinds

def sum[F[_]: Foldable](values: F[Int]): Int =
  values.foldLeft(0)(_ + _)
```

In practice, we don't need to worry about this distinction. It's a feature!
We call the method we want and the compiler uses a `Foldable` when needed
to ensure our code works as expected.
</div>

### Exercises

<div class="callout callout-danger">
TODO:

- Exercises
</div>
