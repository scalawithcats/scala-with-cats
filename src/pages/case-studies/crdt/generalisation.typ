#import "../../stdlib.typ": info, warning, solution
== Generalisation


We've now created a distributed, eventually consistent,
increment-only counter.
This is a useful achievement but we don't want to stop here.
In this section we will attempt to abstract the operations
in the GCounter so it will work with more data types
than just natural numbers.

The GCounter uses the following operations on natural numbers:

- addition (in `increment` and `total`);
- maximum (in `merge`);
- and the identity element 0 (in `increment` and `merge`).

You can probably guess that there's a monoid in here somewhere,
but let's look in more detail at the properties we're relying on.

As a refresher, in @sec:monoids
we saw that monoids must satisfy two laws.
The binary operation `+` must be associative:

`(a + b) + c == a + (b + c)`

and the empty element must be an identity:

`0 + a == a + 0 == a`

We need an identity in `increment` to initialise the counter.
We also rely on associativity to ensure
the specific sequence of `merges` gives the correct value.

In `total` we implicitly rely
on associativity and commutativity
to ensure we get the correct value
no matter what arbitrary order we choose
to sum the per-machine counters.
We also implicitly assume an identity,
which allows us to skip machines
for which we do not store a counter.

The properties of `merge` are a bit more interesting.
We rely on commutativity to ensure that
machine `A` merging with machine `B`
yields the same result as
machine `B` merging with machine `A`.
We need associativity to ensure we obtain the correct result
when three or more machines are merging data.
We need an identity element to initialise empty counters.
Finally, we need an additional property,
called _idempotency_,
to ensure that if two machines hold the same data
in a per-machine counter,
merging data will not lead to an incorrect result.
Idempotent operations are ones that return
the same result again and again if they are executed multiple times.
Formally, a binary operation `max` is idempotent if
the following relationship holds:

```
a max a = a
```

Written more compactly, we have:

--------------------------------------------------------------------
  Method        Identity    Commutative   Associative   Idempotent
-------------- ----------- ------------- ------------- -------------
  `increment`   Y           N             Y             N

  `merge`       Y           Y             Y             Y

  `total`       Y           Y             Y             N
--------------------------------------------------------------------

From this we can see that

- `increment` requires a monoid;
- `total` requires a commutative monoid; and
- `merge` required an idempotent commutative monoid,
  also called a _bounded semilattice_.

Since `increment` and `get` both use
the same binary operation (addition)
it's usual to require the same commutative monoid for both.

This investigation demonstrates
the powers of thinking about properties or laws of abstractions.
Now we have identified these properties
we can substitute the natural numbers used in our GCounter
with any data type with operations satisfying these properties.
A simple example is a set,
with the binary operation being union
and the identity element the empty set.
With this simple substitution of `Int` for `Set[A]`
we can create a GSet type.

=== Implementation


Let's implement this generalisation in code.
Remember `increment` and `total`
require a commutative monoid
and `merge` requires a bounded semilattice
(or idempotent commutative monoid).

Cats provides a type class 
for both `Monoid` and `CommutativeMonoid`,
but doesn't provide one 
for bounded semilattice[^spire].
That's why we're going to implement
our own `BoundedSemiLattice` type class.

```scala mdoc:silent
import cats.kernel.CommutativeMonoid

trait BoundedSemiLattice[A] extends CommutativeMonoid[A] {
  def combine(a1: A, a2: A): A
  def empty: A
}
```

In the implementation above,
`BoundedSemiLattice[A]` extends `CommutativeMonoid[A]`
because a bounded semilattice is a commutative monoid
(a commutative idempotent one, to be exact).

=== Exercise: BoundedSemiLattice Instances


Implement `BoundedSemiLattice` type class instances
for `Ints` and for `Sets`.
The instance for `Int` will
technically only hold for non-negative numbers,
but you don't need to model non-negativity
explicitly in the types.

#solution[
It's common to place the instances
in the companion object of `BoundedSemiLattice`
so they are in the implicit scope without importing them.

Implementing the instance for `Set`
provides good practice with implicit methods.

```scala mdoc:invisible:reset-object
import cats.kernel.CommutativeMonoid
```

```scala mdoc:silent
object wrapper {
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
}; import wrapper._
```
]


=== Exercise: Generic GCounter


Using `CommutativeMonoid` and `BoundedSemiLattice`, generalise `GCounter`.

When you implement this,
look for opportunities to use methods and syntax on `Monoid`
to simplify your implementation.
This is a good example of how
type class abstractions work at multiple levels in our code.
We're using monoids to design a large component---our CRDTs---but
they are also useful in the small, simplifying our code
and making it shorter and clearer.

#solution[
Here's a working implementation.
Note the use of `|+|` in the definition of `merge`,
which significantly simplifies
the process of merging and maximising counters:

```scala mdoc:silent
import cats.instances.list._   // for Monoid
import cats.instances.map._    // for Monoid
import cats.syntax.semigroup._ // for |+|
import cats.syntax.foldable._  // for combineAll

final case class GCounter[A](counters: Map[String,A]) {
  def increment(machine: String, amount: A)
        (implicit m: CommutativeMonoid[A]): GCounter[A] = {
    val value = amount |+| counters.getOrElse(machine, m.empty)
    GCounter(counters + (machine -> value))
  }

  def merge(that: GCounter[A])
        (implicit b: BoundedSemiLattice[A]): GCounter[A] =
    GCounter(this.counters |+| that.counters)

  def total(implicit m: CommutativeMonoid[A]): A =
    this.counters.values.toList.combineAll
}
```
]

[^spire]: A closely related library
called #link("https://github.com/non/spire")[Spire]
already provides that abstractions.
