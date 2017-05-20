## Abstracting GCounter to a Type Class

We've created a generic GCounter
that works with any value
that has (commutative) `Monoid` and `BoundedSemiLattice` type class instances.
However we're still tied to
a particular representation of the map from machine IDs to values.
There is no need to have this restriction,
and indeed it can be useful to abstract away from it.
There are many key-value stores that might like to work with our GCounter,
from a simple `Map` to a relational database.

If we define a `GCounter` type class
we can abstract over different concrete implementations.
This allows us to, for example,
seamlessly substitute an in-memory store for a persistent store
when we want to change performance and durability tradeoffs.

There are a number of ways we can implement this.
Try your own implementation before reading on.

A simple way to achieve this is by defining a `GCounter` type class
with dependencies on `Monoid` and `BoundedSemiLattice`.
I defined this type class as taking a higher-kinded type with *two* type parameters,
intended to represent the key and value types of the map abstraction.

```tut:book:silent
import scala.language.higherKinds
import cats.Monoid

trait BoundedSemiLattice[A] extends Monoid[A] {
  def combine(a1: A, a2: A): A
  def empty: A
}
object BoundedSemiLattice {
  implicit object intBoundedSemiLatticeInstance extends BoundedSemiLattice[Int] {
    def combine(a1: Int, a2: Int): Int =
      a1 max a2

    val empty: Int = 0
  }

  implicit def setBoundedSemiLatticeInstance[A]: BoundedSemiLattice[Set[A]] =
    new BoundedSemiLattice[Set[A]]{
      def combine(a1: Set[A], a2: Set[A]): Set[A] =
        a1 union a2

      val empty: Set[A] =
        Set.empty[A]
    }
}

trait GCounter[F[_,_],K, V] {
  def increment(f: F[K, V])(k: K, v: V)(implicit m: Monoid[V]): F[K, V]
  def total(f: F[K, V])(implicit m: Monoid[V]): V
  def merge(f1: F[K, V], f2: F[K, V])(implicit b: BoundedSemiLattice[V]): F[K, V]
}
```

We can easily define some instances of this type class.
Here's a complete example,
containing a type class instance for `Map` and a simple test.

```tut:book:silent
import cats.syntax.semigroup._
import cats.syntax.foldable._

object GCounterExample {
  trait BoundedSemiLattice[A] extends Monoid[A] {
    def combine(a1: A, a2: A): A
    def empty: A
  }
  object BoundedSemiLattice {
    implicit object intBoundedSemiLatticeInstance extends BoundedSemiLattice[Int] {
      def combine(a1: Int, a2: Int): Int =
        a1 max a2

      val empty: Int = 0
    }

    implicit def setBoundedSemiLatticeInstance[A]: BoundedSemiLattice[Set[A]] =
      new BoundedSemiLattice[Set[A]]{
        def combine(a1: Set[A], a2: Set[A]): Set[A] =
          a1 union a2

        val empty: Set[A] =
          Set.empty[A]
      }
  }

  trait GCounter[F[_,_],K, V] {
    def increment(f: F[K, V])(k: K, v: V)(implicit m: Monoid[V]): F[K, V]
    def total(f: F[K, V])(implicit m: Monoid[V]): V
    def merge(f1: F[K, V], f2: F[K, V])(implicit b: BoundedSemiLattice[V]): F[K, V]
  }
  object GCounter {
    implicit def mapGCounterInstance[K, V]: GCounter[Map, K, V] =
      new GCounter[Map, K, V] {
        import cats.instances.map._

        def increment(f: Map[K, V])(k: K, v: V)(implicit m: Monoid[V]): Map[K, V] =
          f + (k -> (f.getOrElse(k, m.empty) |+| v))

        def total(f: Map[K, V])(implicit m: Monoid[V]): V =
          f.foldMap(identity)

        def merge(f1: Map[K, V], f2: Map[K, V])(implicit b: BoundedSemiLattice[V]): Map[K, V] =
          f1 |+| f2
      }

    def apply[F[_,_],K, V](implicit g: GCounter[F, K, V]) = g
  }

  import cats.instances.int._

  val g1 = Map("a" -> 7, "b" -> 3)
  val g2 = Map("a" -> 2, "b" -> 5)

  println(s"Merged: ${GCounter[Map, String, Int].merge(g1,g2)}")
  println(s"Total: ${GCounter[Map, String, Int].total(g1)}")
}
```

This implementation strategy is a bit unsatisfying.
Although the structure of the implementation
will be the same for most of the type class instances
we won't get any code reuse.

One solution is to capture the idea of a key-value store within a type class,
and then generate `GCounter` instances for any type that has a `KeyValueStore` instance.
Here's the code for `KeyValueStore`,
including syntax and an example instance for `Map`.

```tut:book:silent
trait KeyValueStore[F[_,_]] {
  def +[K, V](f: F[K, V])(key: K, value: V): F[K, V]
  def get[K, V](f: F[K, V])(key: K): Option[V]

  def getOrElse[K, V](f: F[K, V])(key: K, default: V): V =
    get(f)(key).getOrElse(default)
}

object KeyValueStore {
  implicit class KeyValueStoreOps[F[_,_],K, V](f: F[K, V]) {
    def +(key: K, value: V)(implicit kv: KeyValueStore[F]): F[K, V] =
      kv.+(f)(key, value)

    def get(key: K)(implicit kv: KeyValueStore[F]): Option[V] =
      kv.get(f)(key)

    def getOrElse(key: K, default: V)(implicit kv: KeyValueStore[F]): V =
      kv.getOrElse(f)(key, default)
  }

  implicit object mapKeyValueStoreInstance extends KeyValueStore[Map] {
    def +[K, V](f: Map[K, V])(key: K, value: V): Map[K, V] =
      f + (key, value)

    def get[K, V](f: Map[K, V])(key: K): Option[V] =
      f.get(key)

    override def getOrElse[K, V](f: Map[K, V])(key: K, default: V): V =
      f.getOrElse(key, default)
  }
}
```

Now we can generate `GCounter` instances with an `implicit def`.
This implementation is moderately advanced:
it has a number of type class dependencies,
including one on `Foldable` that uses a type lambda.

```tut:book:silent
import cats.Foldable

implicit def keyValueInstance[F[_,_],K, V](
  implicit
  k: KeyValueStore[F],
  km: Monoid[F[K, V]],
  kf: Foldable[({type l[A]=F[K, A]})#l]
): GCounter[F, K, V] =
  new GCounter[F, K, V] {
    import KeyValueStore._  // For KeyValueStore syntax

    def increment(f: F[K, V])(key: K, value: V)(implicit m: Monoid[V]): F[K, V] =
      f + (key, (f.getOrElse(key, m.empty) |+| value))

    def total(f: F[K, V])(implicit m: Monoid[V]): V =
      f.foldMap(identity _)

    def merge(f1: F[K, V], f2: F[K, V])(implicit b: BoundedSemiLattice[V]): F[K, V] =
      f1 |+| f2
  }
```

Here's the complete code, including an example.
This code is quite long but the majority of it is boilerplate.
We could cut down on the boilerplate
by using compiler plugins
such as [Simulacrum][link-simulacrum] and [Kind Projector][link-kind-projector].

```tut:book:silent
object GCounterExample {
  import cats.{Monoid, Foldable}
  import cats.syntax.foldable._
  import cats.syntax.semigroup._

  import scala.language.higherKinds

  trait BoundedSemiLattice[A] extends Monoid[A] {
    def combine(a1: A, a2: A): A
    def empty: A
  }
  object BoundedSemiLattice {
    implicit object intBoundedSemiLatticeInstance extends BoundedSemiLattice[Int] {
      def combine(a1: Int, a2: Int): Int =
        a1 max a2

      val empty: Int = 0
    }

    implicit def setBoundedSemiLatticeInstance[A]: BoundedSemiLattice[Set[A]] =
      new BoundedSemiLattice[Set[A]]{
        def combine(a1: Set[A], a2: Set[A]): Set[A] =
          a1 union a2

        val empty: Set[A] =
          Set.empty[A]
      }
  }

  trait GCounter[F[_,_],K, V] {
    def increment(f: F[K, V])(key: K, value: V)(implicit m: Monoid[V]): F[K, V]
    def total(f: F[K, V])(implicit m: Monoid[V]): V
    def merge(f1: F[K, V], f2: F[K, V])(implicit b: BoundedSemiLattice[V]): F[K, V]
  }
  object GCounter {
    def apply[F[_,_],K, V](implicit g: GCounter[F, K, V]) = g

    implicit class GCounterOps[F[_,_],K, V](f: F[K, V]) {
      def increment(key: K, value: V)(implicit g: GCounter[F, K, V], m: Monoid[V]): F[K, V] =
        g.increment(f)(key, value)

      def total(implicit g: GCounter[F, K, V], m: Monoid[V]): V =
        g.total(f)

      def merge(that: F[K, V])(implicit g: GCounter[F, K, V], b: BoundedSemiLattice[V]): F[K, V] =
        g.merge(f, that)
    }

    implicit def keyValueInstance[F[_,_],K, V](implicit k: KeyValueStore[F], km: Monoid[F[K, V]], kf: Foldable[({type l[A]=F[K, A]})#l]): GCounter[F, K, V] =
      new GCounter[F, K, V] {
        import KeyValueStore._  // For KeyValueStore syntax

        def increment(f: F[K, V])(key: K, value: V)(implicit m: Monoid[V]): F[K, V] =
          f + (key, (f.getOrElse(key, m.empty) |+| value))

        def total(f: F[K, V])(implicit m: Monoid[V]): V =
          f.foldMap(identity _)

        def merge(f1: F[K, V], f2: F[K, V])(implicit b: BoundedSemiLattice[V]): F[K, V] =
          f1 |+| f2
      }
  }

  trait KeyValueStore[F[_,_]] {
    def +[K, V](f: F[K, V])(key: K, value: V): F[K, V]
    def get[K, V](f: F[K, V])(key: K): Option[V]

    def getOrElse[K, V](f: F[K, V])(key: K, default: V): V =
      get(f)(key).getOrElse(default)
  }

  object KeyValueStore {
    implicit class KeyValueStoreOps[F[_,_],K, V](f: F[K, V]) {
      def +(key: K, value: V)(implicit kv: KeyValueStore[F]): F[K, V] =
        kv.+(f)(key, value)

      def get(key: K)(implicit kv: KeyValueStore[F]): Option[V] =
        kv.get(f)(key)

      def getOrElse(key: K, default: V)(implicit kv: KeyValueStore[F]): V =
        kv.getOrElse(f)(key, default)
    }

    implicit object mapKeyValueStoreInstance extends KeyValueStore[Map] {
      def +[K, V](f: Map[K, V])(key: K, value: V): Map[K, V] =
        f + (key, value)

      def get[K, V](f: Map[K, V])(key: K): Option[V] =
        f.get(key)

      override def getOrElse[K, V](f: Map[K, V])(key: K, default: V): V =
        f.getOrElse(key, default)
    }
  }

  object Example {
    import cats.instances.map._
    import cats.instances.int._

    import KeyValueStore._
    import GCounter._

    val crdt1 = Map("a" -> 1, "b" -> 3, "c" -> 5)
    val crdt2 = Map("a" -> 2, "b" -> 4, "c" -> 6)

    crdt1.increment("a", 20).merge(crdt2).total
  }
}
```
