## Foldable in Cats

Cats provides out-of-the-box instances of `Foldable` for a handful of Scala data types: `List`, `Vector`, `Stream`, `Option`, and `Map`. We can summon instances as usual using `Foldable.apply` and call their implementations of `foldLeft` directly:

```scala
val ints = List(1, 2, 3)
// ints: List[Int] = List(1, 2, 3)

import cats.Foldable
// import cats.Foldable

import cats.std.list._
// import cats.std.list._

Foldable[List].foldLeft(ints, 0)(_ + _)
// res0: Int = 6

val maybeInt = Option(1)
// maybeInt: Option[Int] = Some(1)

import cats.std.option._
// import cats.std.option._

Foldable[Option].foldLeft(maybeInt, "")(_ + _)
// res1: String = 1
```

The `Foldable` instance for `Map` allows us to fold over its values. Because `Map` has two type parameters, we have to fix one of them to create the expected single-parameter type constructor:

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

Note that we haven't looked at `foldRight` in these examples. This is because Cats defines `foldRight` slightly differently to what we've seen so far, in terms of another tool called `Eval`. We'll look at `Eval` and `foldRight` in more detail in a bit.

### Methods of Foldable

Cats' `Foldable`  provides us with a host of useful methods defined on top of `foldLeft`. Many of these are facimiles of familiar methods from the standard library, including `find`, `exists`, `forall`, `toList`, `isEmpty`, and `nonEmpty`:

```scala
Foldable[Option].nonEmpty(Option(42))
// res3: Boolean = true

Foldable[List].find(List(1, 2, 3))(_ % 2 == 0)
// res4: Option[Int] = Some(2)
```

In addition to these familiar methods, Cats provides two methods that make use of `Monoids`:

- `combineAll` (and its alias `fold`) combines all elements in the sequence using their `Monoid`;
- `foldMap` maps a user-supplied function over the sequence and combines the results using a `Monoid`.

Here are some examples:

```scala
import cats.std.int._ // import Monoid[Int]
// import cats.std.int._

Foldable[List].combineAll(List(1, 2, 3))
// res5: Int = 6

import cats.std.string._ // import Monoid[String]
// import cats.std.string._

Foldable[List].foldMap(List(1, 2, 3))(_.toString)
// res6: String = 123
```

Finally, we can compose `Foldables` to support deep traversal of nested sequences:

```scala
import cats.std.vector._
// import cats.std.vector._

val ints = List(Vector(1, 2, 3), Vector(4, 5, 6))
// ints: List[scala.collection.immutable.Vector[Int]] = List(Vector(1, 2, 3), Vector(4, 5, 6))

Foldable[List].compose(Foldable[Vector]).combineAll(ints)
// res7: Int = 21
```

### Syntax for Foldable

Every method in `Foldable` is available in syntax form via the `cats.syntax.foldable` import. In each case, the first argument to the method on `Foldable` becomes the method receiver:

```scala
import cats.syntax.foldable._
// import cats.syntax.foldable._

List(1, 2, 3).combineAll
// res8: Int = 6

List(1, 2, 3).foldMap(_.toString)
// res9: String = 123
```

<div class="callout callout-info">
*Explicits over Implicits*

Remember that Scala will only use an instance of `Foldable` if the method isn't explicitly available on the receiver. For example, the following code will use the version of `foldLeft` defined on `List`:

```scala
List(1, 2, 3).foldLeft(0)(_ + _)
// res10: Int = 6
```

whereas the following generic code will use `Foldable`:

```scala
import scala.language.higherKinds
// import scala.language.higherKinds

def sum[F[_]: Foldable](values: F[Int]): Int =
  values.foldLeft(0)(_ + _)
// sum: [F[_]](values: F[Int])(implicit evidence$1: cats.Foldable[F])Int
```

In practice, we don't need to worry about this distinction. It's a feature! We call the method we want, and the compiler uses a `Foldable` if necessary to ensure our code works as expected.
</div>

### Exercises

<div class="callout callout-danger">
TODO:

- Exercises
</div>

### Methods returning Eval

<div class="callout callout-danger">
TODO:

- Talk about foldRight
- Mention Eval
</div>
