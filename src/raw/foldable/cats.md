## Foldable in Cats

Cats provides out-of-the-box instances of `Foldable` for a handful of Scala data types: `List`, `Vector`, `Stream`, `Option`, and `Map`. We can summon instances as usual using `Foldable.apply` and call their implementations of `foldLeft` directly:

```tut:book
val ints = List(1, 2, 3)

import cats.Foldable
import cats.std.list._

Foldable[List].foldLeft(ints, 0)(_ + _)

val maybeInt = Option(1)

import cats.std.option._

Foldable[Option].foldLeft(maybeInt, "")(_ + _)
```

The `Foldable` instance for `Map` allows us to fold over its values. Because `Map` has two type parameters, we have to fix one of them to create the expected single-parameter type constructor:

```tut:book
type StringMap[A] = Map[String, A]

val stringMap = Map("a" -> "b", "c" -> "d")

import cats.std.map._

Foldable[StringMap].foldLeft(stringMap, "nil")(_ + "," + _)
```

Note that we haven't looked at `foldRight`. Cats defines this method slightly differently than what we have seen---we'll need to introduce some new infrastructure to discuss it. We'll take a detour now to discuss some useful methods based on `foldLeft` and circle back to `foldRight` in a moment.

### Methods of Foldable

Cats' `Foldable`  provides us with a host of useful methods defined on top of `foldLeft`. Many of these are facimiles of familiar methods from the standard library, including `find`, `exists`, `forall`, `toList`, `isEmpty`, and `nonEmpty`:

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

Every method in `Foldable` is available in syntax form via the `cats.syntax.foldable` import. In each case, the first argument to the method on `Foldable` becomes the method receiver:

```tut:book
import cats.syntax.foldable._

List(1, 2, 3).combineAll

List(1, 2, 3).foldMap(_.toString)
```

<div class="callout callout-info">
*Explicits over Implicits*

Remember that Scala will only use an instance of `Foldable` if the method isn't explicitly available on the receiver. For example, the following code will use the version of `foldLeft` defined on `List`:

```tut:book
List(1, 2, 3).foldLeft(0)(_ + _)
```

whereas the following generic code will use `Foldable`:

```tut:book
import scala.language.higherKinds

def sum[F[_]: Foldable](values: F[Int]): Int =
  values.foldLeft(0)(_ + _)
```

In practice, we don't need to worry about this distinction. It's a feature! We call the method we want, and the compiler uses a `Foldable` if necessary to ensure our code works as expected.
</div>

### Exercises

<div class="callout callout-danger">
TODO:

- Exercises
</div>

### Folding Right

So far we have talked about a lot of methods based on `foldLeft`, but we haven't talked about `foldRight`. If we try to call Cats' version of `foldRight` we will see that it is defined differently to what we're used to:

```tut:book
Foldable[List].foldRight(List(1, 2, 3), 0)(_ + _)
```

Cats' `foldRight` method expects us to define our accumulator in terms of a new type called `Eval`. The actual method definition looks like this:

```scala
trait Foldable[F[_]] {
  def foldLeft[A, B](fa: F[A], b: B)(f: (B, A) => B): B
  def foldRight[A, B](fa: F[A], lb: Eval[B])(f: (A, Eval[B]) => Eval[B]): Eval[B]
  // etc...
}
```

The difference in definition is an efficiency consideration that allows us to iterate over very large data structures without stack overflows.

If we define `foldLeft` for a left-associative data structure such as a `List` or `Stream`, we find that we can use tail recursion (via Scala's `tailrec` annotation) to write an efficient implementation that does not consume stack as it iterates over the sequence. This makes intuitive sense as our algorithm can peel off the head of the sequence at each iteration and forget about it for the next iteration:

```scala
val ints = (1 to 100000000).toStream
// ints: Stream[Int] = ...

ints.foldLeft(0)(_ + _)
// completes after a very long time
```

<div class="callout callout-danger">
TODO: Exercise: define this yourself
</div>

The same is not true of `foldRight`. In a left-associative sequence, we have to recurse all the way to the end so we can traverse the elements on the way back up. When working with large enough sequences this can lead to stack overflows:

```scala
ints.foldRight(0)(_ + _)
// java.lang.StackOverflowError
//   etc...
```

<div class="callout callout-danger">
TODO: Exercise: define this yourself
</div>

<div class="callout callout-danger">
Talk briefly about `Eval` and segue into the next section.
</div>
