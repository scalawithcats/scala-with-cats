### *Foldable* in Cats

Cats' `Foldable` abstracts the two operations
`foldLeft` and `foldRight` into a type class.
Instances of `Foldable` define these two methods
and inherit a host of derived methods for free.

Cats provides out-of-the-box instances of `Foldable`
for a handful of Scala data types:
`List`, `Vector`, `Stream`, `Option`, and `Map`.
We can summon instances as usual using `Foldable.apply`
and call their implementations of `foldLeft` directly.
Here is an example using `List`:

```tut:book:silent
import cats.Foldable
import cats.instances.list._

val ints = List(1, 2, 3)
```

```tut:book
Foldable[List].foldLeft(ints, 0)(_ + _)
```

And here is an example using `Option`:

```tut:book:silent
import cats.instances.option._

val maybeInt = Option(1)
```

```tut:book
Foldable[Option].foldLeft(maybeInt, "")(_ + _)
```

The `Foldable` instance for `Map` allows us to
fold over its values (as opposed to its keys).
Because `Map` has two type parameters,
we have to fix one of them to summon the `Foldable`:

```tut:book:silent
import cats.instances.map._

type StringMap[A] = Map[String, A]

val stringMap = Map("a" -> "b", "c" -> "d")
```

```tut:book
Foldable[StringMap].foldLeft(stringMap, "nil")(_ + "," + _)
```

#### Folding Right

`Foldable` defines `foldRight` differently to `foldLeft`,
in terms of the `Eval` monad:

```scala
def foldRight[A, B](fa: F[A], lb: Eval[B])(f: (A, Eval[B]) => Eval[B]): Eval[B]
```

Using `Eval` means folding with `Foldable` is always *stack safe*,
even when the collection's default definition of `foldRight` is not.

For example, the default implementation for `Stream` is not stack safe.
We can see the stack depth changing as we iterate across the stream.
The longer the stream, the larger the stack requirements for the fold.
A sufficiently large stream will trigger a `StackOverflowException`:

```tut:book:silent
import cats.Eval
import cats.Foldable

def stackDepth: Int =
  Thread.currentThread.getStackTrace.length
```

```tut:book
(1 to 5).toStream.foldRight(0) { (item, accum) =>
  println(stackDepth)
  item + accum
}
```

As we saw in the [monads chapter](#eval), however,
`Eval's` `map` and `flatMap` are trampolined:
`Foldable's` `foldRight` maintains the same stack depth throughout:

```tut:book:silent
import cats.instances.stream._

val foldable = Foldable[Stream]
```

```tut:book
val accum: Eval[Int] = // the accumulator is an Eval
  Eval.now(0)

val result: Eval[Int] = // and the result is an Eval
  foldable.foldRight((1 to 5).toStream, accum) {
    (item: Int, accum: Eval[Int]) =>
      println(stackDepth)
      accum.map(_ + item)
  }

result.value // we call `value` to start the actual calculation
```

<div class="callout callout-info">
*What is stack safety?*

A *stack safe* algorithm always consumes the same number of stack frames,
regardless of the size of the data structure on which it is operating.
They are "safe" because they can never cause `StackOverflowExceptions`.

Many sequences such as `Lists` and `Streams` are left-associative.
We can write stack safe implementations of `foldLeft`
for these types using tail recursion.
However, implementations of `foldRight`
have to work against the direction of associativity.
We can either resort to regular recursion,
using the stack to combine values on the way back up,
or use a technique called "trampolining"
to rewrite the computation as a (heap allocated) list of functions.
Regular recursion is not stack safe.
Trampolining, on the other hand, is.

A discussion of trampolining is beyond the scope of this book,
suffice to say that `Eval` uses this technique
to ensure that all our `foldRights` are stack safe by default.
</div>

#### Folding with Monoids

Cats' `Foldable` provides us with
a host of useful methods defined on top of `foldLeft`.
Many of these are facimiles of familiar methods from the standard library,
including `find`, `exists`, `forall`, `toList`, `isEmpty`, and `nonEmpty`:

```tut:book
Foldable[Option].nonEmpty(Option(42))

Foldable[List].find(List(1, 2, 3))(_ % 2 == 0)
```

In addition to these familiar methods,
Cats provides two methods that make use of `Monoids`:

- `combineAll` (and its alias `fold`) combines
  all elements in the sequence using their `Monoid`;

- `foldMap` maps a user-supplied function over the sequence
  and combines the results using a `Monoid`.

For example, we can use `combineAll` to sum over a `List[Int]`:

```tut:book:silent
import cats.instances.int._ // Monoid of Int
```

```tut:book
Foldable[List].combineAll(List(1, 2, 3))
```

Alternatively, we can use `foldMap`
to convert each `Int` to a `String` and concatenate them:

```tut:book:silent
import cats.instances.string._ // Monoid of String
```

```tut:book
Foldable[List].foldMap(List(1, 2, 3))(_.toString)
```

Finally, we can compose `Foldables` to support deep traversal of nested sequences:

```tut:book:silent
import cats.instances.vector._ // Monoid of Vector

val ints = List(Vector(1, 2, 3), Vector(4, 5, 6))
```

```tut:book
Foldable[List].compose(Foldable[Vector]).combineAll(ints)
```

#### Syntax for Foldable

Every method in `Foldable` is available
in syntax form via `cats.syntax.foldable`.
In each case, the first argument to the method on `Foldable`
becomes the method receiver:

```tut:book:silent
import cats.syntax.foldable._
```

```tut:book
List(1, 2, 3).combineAll

List(1, 2, 3).foldMap(_.toString)
```

<div class="callout callout-info">
*Explicits over Implicits*

Remember that Scala will only use an instance of `Foldable`
if the method isn't explicitly available on the receiver.
For example, the following code will
use the version of `foldLeft` defined on `List`:

```tut:book
List(1, 2, 3).foldLeft(0)(_ + _)
```

whereas the following generic code will use `Foldable`:

```tut:book:silent
import scala.language.higherKinds
```

```tut:book
def sum[F[_]: Foldable](values: F[Int]): Int =
  values.foldLeft(0)(_ + _)
```

In practice, we typically don't need to worry about this distinction. It's a feature!
We call the method we want and the compiler uses a `Foldable` when needed
to ensure our code works as expected.
</div>
