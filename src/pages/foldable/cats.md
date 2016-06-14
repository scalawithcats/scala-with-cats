## Foldable in Cats

Cats' `Foldable` abstracts the two operations `foldLeft` and `foldRight` into a type class.
Instances of `Foldable` have to define those two methods,
but inherit a host of derived methods for free.

Cats provides out-of-the-box instances of `Foldable` for a handful of Scala data types:
`List`, `Vector`, `Stream`, `Option`, and `Map`.
We can summon instances as usual using `Foldable.apply`
and call their implementations of `foldLeft` directly on the instances.

Here is an example using `List`:

```scala
import cats.Foldable
// import cats.Foldable

val ints = List(1, 2, 3)
// ints: List[Int] = List(1, 2, 3)

import cats.std.list._
// import cats.std.list._

Foldable[List].foldLeft(ints, 0)(_ + _)
// res0: Int = 6
```

And here is an example using `Option`:

```scala
val maybeInt = Option(1)
// maybeInt: Option[Int] = Some(1)

import cats.std.option._
// import cats.std.option._

Foldable[Option].foldLeft(maybeInt, "")(_ + _)
// res1: String = 1
```

The `Foldable` instance for `Map` allows us to fold over its values.
Because `Map` has two type parameters,
we have to fix one of them to create the single-parameter type constructor
we need to summon the `Foldable`:

```scala
type StringMap[A] = Map[String, A]
// defined type alias StringMap

val stringMap = Map("a" -> "b", "c" -> "d")
// stringMap: scala.collection.immutable.Map[String,String] = Map(a -> b, c -> d)

import cats.std.map._
// import cats.std.map._

Foldable[StringMap].foldLeft(stringMap, "nil")(_ + "," + _)
// res2: String = nil,b,d
```

### Folding right

`Foldable` defines `foldRight` differently to `foldLeft`,
in terms of the `Eval` monad:

```scala
def foldRight[A, B](fa: F[A], lb: Eval[B])(f: (A, Eval[B]) => Eval[B]): Eval[B]
```

Using `Eval` means folding with `Foldable` is always *stack safe*,
even when the collection's default definition of `foldRight` is not.

For example, the default implementation for `Stream` is not stack safe.
We can see the stack depth creeping up as we iterate across the stream:

```scala
import cats.Eval
// import cats.Eval

import cats.Foldable
// import cats.Foldable

def stackDepth: Int =
  new Exception().getStackTrace.length
// stackDepth: Int

// The default implementation of foldRight for Stream is not stack safe:
(1 to 5).toStream.foldRight(0) { (a: Int, b: Int) =>
  println(stackDepth)
  a + b
}
// 452
// 450
// 448
// 446
// 444
// res4: Int = 15
```

As we saw in the [monads chapter](#eval), however, `Eval's` `map` and `flatMap` are trampolined, so `Foldable's` `foldRight` method maintains the same stack depth throughout:

```scala
import cats.std.stream._
// import cats.std.stream._

val foldable = Foldable[Stream]
// foldable: cats.Foldable[Stream] = cats.std.StreamInstances$$anon$1@17bdc237

// The Foldable implementation is stack safe because we're using Eval:
foldable.foldRight((1 to 5).toStream, Eval.now(0)) {
  (a: Int, b: Eval[Int]) =>
    println(stackDepth)
    b.map(_ + a)
}.value
// 505
// 505
// 505
// 505
// 505
// res6: Int = 15
```

Note that we supply a seed value of type `Eval`,
and we use the `value` method to unpack the result afterwards.

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

```scala
Foldable[Option].nonEmpty(Option(42))
// res7: Boolean = true

Foldable[List].find(List(1, 2, 3))(_ % 2 == 0)
// res8: Option[Int] = Some(2)
```

In addition to these familiar methods, Cats provides two methods that make use of `Monoids`:

- `combineAll` (and its alias `fold`) combines all elements in the sequence using their `Monoid`;
- `foldMap` maps a user-supplied function over the sequence and combines the results using a `Monoid`.

Here are some examples:

```scala
import cats.std.int._ // import Monoid[Int]
// import cats.std.int._

Foldable[List].combineAll(List(1, 2, 3))
// res9: Int = 6

import cats.std.string._ // import Monoid[String]
// import cats.std.string._

Foldable[List].foldMap(List(1, 2, 3))(_.toString)
// res10: String = 123
```

Finally, we can compose `Foldables` to support deep traversal of nested sequences:

```scala
import cats.std.vector._
// import cats.std.vector._

val ints = List(Vector(1, 2, 3), Vector(4, 5, 6))
// ints: List[scala.collection.immutable.Vector[Int]] = List(Vector(1, 2, 3), Vector(4, 5, 6))

Foldable[List].compose(Foldable[Vector]).combineAll(ints)
// res11: Int = 21
```

### Syntax for Foldable

Every method in `Foldable` is available in syntax form via the `cats.syntax.foldable` import.
In each case, the first argument to the method on `Foldable` becomes the method receiver:

```scala
import cats.syntax.foldable._
// import cats.syntax.foldable._

List(1, 2, 3).combineAll
// res12: Int = 6

List(1, 2, 3).foldMap(_.toString)
// res13: String = 123
```

<div class="callout callout-info">
*Explicits over Implicits*

Remember that Scala will only use an instance of `Foldable`
if the method isn't explicitly available on the receiver.
For example, the following code will use the version of `foldLeft` defined on `List`:

```scala
List(1, 2, 3).foldLeft(0)(_ + _)
// res14: Int = 6
```

whereas the following generic code will use `Foldable`:

```scala
import scala.language.higherKinds
// import scala.language.higherKinds

def sum[F[_]: Foldable](values: F[Int]): Int =
  values.foldLeft(0)(_ + _)
// sum: [F[_]](values: F[Int])(implicit evidence$1: cats.Foldable[F])Int
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
