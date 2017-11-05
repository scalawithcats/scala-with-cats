## Generalisation

We've now created a distributed eventually consistent increment only counter.
This is a nice achievement, but don't want to stop here.
In this section we will attempt to abstract the operations used in the GCounter
so it will work with more data types than just natural numbers.

The GCounter uses the following operations on natural numbers:
- addition (in `increment` and `get`);
- maximum (in `merge`);
- and the identity element 0 (in `increment` and `merge`).

This should already make you feel there is a monoid somewhere in here,
but let's look in more detail on the properties we rely on.

As a refresher, here are the properties we've of monoids we've seen earlier:

- the binary operation `+` is associative, meaning `(a + b) + c = a + (b + c)`;
- the identity `0` is commutative, meaning `a + 0 = 0 + a`; and
- the identity is an identity, meaning `a + 0 = a`.

In `increment`, we need an identity to initialise the counter.
We also rely on associativity to ensure
the specific sequence of additions we perform gives the correct value.

In `get` we implicitly rely on associativity and commutivity
to ensure we get the correct value
no matter what arbitrary order we choose to sum the per-machine counters.
We also implicitly assume an identity,
which allows us to skip machines for which we do not store a counter.

The properties `merge` relies on are a bit more interesting.
We rely on commutivity
to ensure that machine `A` merging with machine `B`
yields the same result as machine `B` merging with machine `A`.
We need associativity to ensure we obtain the correct result
when three or more machines are merging data.
We need an identity element to initialise empty counters.
Finally, we need an additional property, called *idempotency*,
to ensure that if two machines hold the same data in a per-machine counter,
merging data will not lead to an incorrect result.
Formally, a binary operation `max` is idempotent if `a max a = a`.

Written more compactly, we have:

--------------------------------------------------------------------
  Method        Identity    Commutative   Associative   Idempotent
-------------- ----------- ------------- ------------- -------------
  `increment`   Y           N             Y             N

  `get`         Y           Y             Y             N

  `merge`       Y           Y             Y             Y
--------------------------------------------------------------------

From this we can see that

- `increment` requires a monoid;
- `get` requires a commutative monoid; and
- `merge` required an idempotent commutative monoid,
  also called a bounded semilattice.

Since `increment` and `get` both use the same binary operation (addition)
it's usual to require the same commutative monoid for both.

This investigation demonstrates
the powers of thinking about properties or laws of abstractions.
Now we have identified these properties
we can substitute the natural numbers used in our GCounter
with any data type with operations meeting these properties.
A simple example is a set,
with union being the binary operation
and the identity element the empty set.
Set union is idempotent, commutative, and associative
and therefore fits all our requirements to work with a GCounter.
With this simple substitution of `Int` for `Set[A]` we can create a GSet type.

### Implementation

Let us now implement this generalisation in code.
Remember `increment` and `get` require a commutative monoid
and `merge` requires a bounded semilattice
(or idempotent commutative monoid).

Cats provides a `Monoid`,
but no commutative monoid or bounded semilattice type class[^spire].
For simplicity of implementation we'll use `Monoid`
when we really mean a commutative monoid,
and require the programmer to ensure the implementation is commutative.
We'll implement our own `BoundedSemiLattice` type class.

```tut:book:silent
import cats.Monoid

trait BoundedSemiLattice[A] extends Monoid[A] {
  def combine(a1: A, a2: A): A
  def empty: A
}
```

In the implementation above,
`BoundedSemiLattice[A]` extends `Monoid[A]`
because a bounded semilattice is a monoid
(a commutative idempotent one, to be exact).

### Exercises

#### BoundedSemiLattice Instances

Implement some `BoundedSemiLattice` type class instances (e.g. for non-negative `Int`, and for `Set`).

<div class="solution">
It's natural to place the instance
in the companion object of `BoundedSemiLattice`
so they are in the implicit scope without importing them.

Implementing the instance for `Set`
is good practice with using implicit methods.

```tut:book:silent
trait BoundedSemiLattice[A] extends Monoid[A] {
  def combine(a1: A, a2: A): A
  def empty: A
}

object BoundedSemiLattice {
  /** This BoundedSemiLattice instance is for non-negative `Int` only. */
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
```
</div>


#### Generic GCounter

Using `Monoid` and `BoundedSemiLattice`, generalise `GCounter`.

When you implement this,
look for opportunities to use methods and syntax on monoid
to simplify your implementation.
This is a good example of how
type class abstractions work at multiple levels of code.
We're using monoids to design a large component---our CRDTs---but
they are also useful in the small, making our code simpler.

<div class="solution">

```tut:book:silent
import cats.syntax.semigroup._
import cats.syntax.foldable._
import cats.instances.list._
import cats.instances.map._

final case class GCounter[A](counters: Map[String,A]) {
  def increment(machine: String, amount: A)(implicit m: Monoid[A]) =
    GCounter(counters + (machine -> (amount |+| counters.getOrElse(machine, m.empty))))

  def get(implicit m: Monoid[A]): A =
    this.counters.values.toList.combineAll

  def merge(that: GCounter[A])(implicit b: BoundedSemiLattice[A]): GCounter[A] =
    GCounter(this.counters |+| that.counters)
}
```
</div>

[^spire]: A closely related library called [Spire](https://github.com/non/spire)
provides both these abstractions.
