#import "../../stdlib.typ": info, warning, solution
== Abstracting GCounter to a Type Class


We've created a generic GCounter
that works with any value
that has instances of `BoundedSemiLattice`
and `CommutativeMonoid`.
However we're still tied to
a particular representation of the map from machine IDs to values.
There is no need to have this restriction,
and indeed it can be useful to abstract away from it.
There are many key-value stores that we want to work with,
from a simple `Map` to a relational database.

If we define a `GCounter` type class
we can abstract over different concrete implementations.
This allows us to, for example,
seamlessly substitute an in-memory store for a persistent store
when we want to change performance and durability tradeoffs.

There are a number of ways we can implement this.
One approach is to define a `GCounter` type class
with dependencies on `CommutativeMonoid` and `BoundedSemiLattice`.
We define this as a type class that takes
a type constructor with _two_ type parameters
represent the key and value types of the map abstraction.

```scala mdoc:reset-object:invisible
import cats.kernel.CommutativeMonoid

trait BoundedSemiLattice[A] extends CommutativeMonoid[A] {
  def combine(a1: A, a2: A): A
  def empty: A
}

object BoundedSemiLattice {
  implicit val intInstance: BoundedSemiLattice[Int] =
    new BoundedSemiLattice[Int] {
      def combine(a1: Int, a2: Int): Int =
        a1 max a2

      val empty: Int =
        0
    }

  implicit def setInstance[A]: BoundedSemiLattice[Set[A]] =
    new BoundedSemiLattice[Set[A]]{
      def combine(a1: Set[A], a2: Set[A]): Set[A] =
        a1 union a2

      val empty: Set[A] =
        Set.empty[A]
    }
}
```
```scala mdoc:silent
trait GCounter[F[_,_],K, V] {
  def increment(f: F[K, V])(k: K, v: V)
        (implicit m: CommutativeMonoid[V]): F[K, V]

  def merge(f1: F[K, V], f2: F[K, V])
        (implicit b: BoundedSemiLattice[V]): F[K, V]

  def total(f: F[K, V])
        (implicit m: CommutativeMonoid[V]): V
}

object GCounter {
  def apply[F[_,_], K, V]
        (implicit counter: GCounter[F, K, V]) =
    counter
}
```

Try defining an instance of this type class for `Map`.
You should be able to reuse your code from the
case class version of `GCounter`
with some minor modifications.

#solution[
Here's the complete code for the instance.
Write this definition
in the companion object for `GCounter`
to place it in global implicit scope:

```scala mdoc:silent
import cats.instances.list._   // for Monoid
import cats.instances.map._    // for Monoid
import cats.syntax.semigroup._ // for |+|
import cats.syntax.foldable._  // for combineAll

implicit def mapGCounterInstance[K, V]: GCounter[Map, K, V] =
  new GCounter[Map, K, V] {
    def increment(map: Map[K, V])(key: K, value: V)
          (implicit m: CommutativeMonoid[V]): Map[K, V] = {
      val total = map.getOrElse(key, m.empty) |+| value
      map + (key -> total)
    }

    def merge(map1: Map[K, V], map2: Map[K, V])
          (implicit b: BoundedSemiLattice[V]): Map[K, V] =
      map1 |+| map2

    def total(map: Map[K, V])
        (implicit m: CommutativeMonoid[V]): V =
      map.values.toList.combineAll
  }
```
]

You should be able to use your instance as follows:

```scala mdoc:silent
import cats.instances.int._ // for Monoid

val g1 = Map("a" -> 7, "b" -> 3)
val g2 = Map("a" -> 2, "b" -> 5)

val counter = GCounter[Map, String, Int]
```

```scala mdoc
val merged = counter.merge(g1, g2)
val total  = counter.total(merged)
```

The implementation strategy
for the type class instance
is a bit unsatisfying.
Although the structure of the implementation
will be the same for most instances we define,
we won't get any code reuse.

== Abstracting a Key Value Store


One solution is to capture
the idea of a key-value store within a type class,
and then generate `GCounter` instances
for any type that has a `KeyValueStore` instance.
Here's the code for such a type class:

```scala mdoc:silent
trait KeyValueStore[F[_,_]] {
  def put[K, V](f: F[K, V])(k: K, v: V): F[K, V]

  def get[K, V](f: F[K, V])(k: K): Option[V]

  def getOrElse[K, V](f: F[K, V])(k: K, default: V): V =
    get(f)(k).getOrElse(default)

  def values[K, V](f: F[K, V]): List[V]
}
```

Implement your own instance for `Map`.

#solution[
Here's the code for the instance.
Write the definition in
the companion object for `KeyValueStore`
to place it in global implicit scope:

```scala mdoc:silent
implicit val mapKeyValueStoreInstance: KeyValueStore[Map] =
  new KeyValueStore[Map] {
    def put[K, V](f: Map[K, V])(k: K, v: V): Map[K, V] =
      f + (k -> v)

    def get[K, V](f: Map[K, V])(k: K): Option[V] =
      f.get(k)

    override def getOrElse[K, V](f: Map[K, V])
        (k: K, default: V): V =
      f.getOrElse(k, default)

    def values[K, V](f: Map[K, V]): List[V] =
      f.values.toList
  }
```
]

With our type class in place we can implement syntax
to enhance data types for which we have instances:

```scala mdoc:silent
implicit class KvsOps[F[_,_], K, V](f: F[K, V]) {
  def put(key: K, value: V)
        (implicit kvs: KeyValueStore[F]): F[K, V] =
    kvs.put(f)(key, value)

  def get(key: K)(implicit kvs: KeyValueStore[F]): Option[V] =
    kvs.get(f)(key)

  def getOrElse(key: K, default: V)
        (implicit kvs: KeyValueStore[F]): V =
    kvs.getOrElse(f)(key, default)

  def values(implicit kvs: KeyValueStore[F]): List[V] =
    kvs.values(f)
}
```

Now we can generate `GCounter` instances
for any data type that has
instances of `KeyValueStore` and `CommutativeMonoid`
using an `implicit def`:

```scala mdoc:silent
implicit def gcounterInstance[F[_,_], K, V]
    (implicit kvs: KeyValueStore[F], km: CommutativeMonoid[F[K, V]]): GCounter[F, K, V] =
  new GCounter[F, K, V] {
    def increment(f: F[K, V])(key: K, value: V)
          (implicit m: CommutativeMonoid[V]): F[K, V] = {
      val total = f.getOrElse(key, m.empty) |+| value
      f.put(key, total)
    }

    def merge(f1: F[K, V], f2: F[K, V])
          (implicit b: BoundedSemiLattice[V]): F[K, V] =
      f1 |+| f2

    def total(f: F[K, V])(implicit m: CommutativeMonoid[V]): V =
      f.values.combineAll
  }
```

The complete code for this case study is quite long,
but most of it is boilerplate setting up syntax
for operations on the type class.
We can cut down on this using compiler plugins
such as [Simulacrum][link-simulacrum]
and [Kind Projector][link-kind-projector].
