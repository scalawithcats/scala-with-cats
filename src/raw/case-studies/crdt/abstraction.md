## Abstracting GCounter to a Type Class

We've created a generic GCounter that works with any value that has (commutative) `Monoid` and `BoundedSemiLattice` type class instances.
However we're still tied to a particular representation of the map from machine IDs to values.
There is no need to have this restriction, and indeed it can be useful to abstract away from it.
There are many key-value stores that might like to work with our GCounter, from a simple `Map` to a relational database.

If we define a `GCounter` type class we can abstract over different concrete implementations. This allows us to seemlessly substitute an in-memory store for a persistent store, for example, if we want to change performance and durability tradeoffs.

There are a number of ways we can implement this. Try your own implementation before reading on.

A simple way to achieve this is by defining a `GCounter` type class with dependencies on `Monoid` and `BoundedSemiLattice`. I defined this type class as taking a higher-kinded type with *two* type parameters, intended to represent the key and value types of the map abstraction.

```tut:book
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

trait GCounter[F[_,_],K,V] {
  def increment(f: F[K,V])(k: K, v: V)(implicit m: Monoid[V]): F[K,V]
  def total(f: F[K,V])(implicit m: Monoid[V]): V
  def merge(f1: F[K,V], f2: F[K,V])(implicit b: BoundedSemiLattice[V]): F[K,V]
}
```

We can easily define some instances of this type class. Here's a complete example, containing a type class instance for `Map` and a simple test.

```tut:book
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

  trait GCounter[F[_,_],K,V] {
    def increment(f: F[K,V])(k: K, v: V)(implicit m: Monoid[V]): F[K,V]
    def total(f: F[K,V])(implicit m: Monoid[V]): V
    def merge(f1: F[K,V], f2: F[K,V])(implicit b: BoundedSemiLattice[V]): F[K,V]
  }
  object GCounter {
    implicit def mapGCounterInstance[K,V]: GCounter[Map,K,V] =
      new GCounter[Map,K,V] {
        import cats.instances.map._
        
        def increment(f: Map[K,V])(k: K, v: V)(implicit m: Monoid[V]): Map[K,V] =
          f + (k -> (f.getOrElse(k, m.empty) |+| v))
  
        def total(f: Map[K,V])(implicit m: Monoid[V]): V =
          f.foldMap(identity)
  
        def merge(f1: Map[K,V], f2: Map[K,V])(implicit b: BoundedSemiLattice[V]): Map[K,V] =
          f1 |+| f2
      }
  
    def apply[F[_,_],K,V](implicit g: GCounter[F,K,V]) = g
  }
  
  import cats.instances.int._
    
  val g1 = Map("a" -> 7, "b" -> 3)
  val g2 = Map("a" -> 2, "b" -> 5)
  
  println(s"Merged: ${GCounter[Map,String,Int].merge(g1,g2)}")
  println(s"Total: ${GCounter[Map,String,Int].total(g1)}")
}
```
