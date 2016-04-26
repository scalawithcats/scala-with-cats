# Monoids and Semigroups

In this section we explore our first type classes: `Monoid` and `Semigroup`.
These allow us to add or combine values.
Let's start by looking at a few types and operations
and seeing what common principles we can extract.

**Integer addition**

Addition of `Ints` is a binary operation that is *closed*,
meaning given two `Ints` we always get another `Int` back.
There is also the *identity* element `0` with the property
that `a + 0 == 0 + a == a` for any `Int` `a`.

```scala
2 + 1
// res0: Int = 3

2 + 0
// res1: Int = 2
```

There are also other properties of addition.
For instance, it doesn't matter in what order we add elements
because we always get the same result.
This is a property known as *associativity*.

```scala
(1 + 2) + 3
// res2: Int = 6

1 + (2 + 3)
// res3: Int = 6
```

**Integer multiplication**

We can do the same things with multiplication as we can with addition
if we use `1` as the identity.

```scala
(1 * 2) * 3
// res4: Int = 6

1 * (2 * 3)
// res5: Int = 6

2 * 3
// res6: Int = 6
```

**String and sequence concatenation**

We can do the same things with `String`,
using string concatenation as our binary operator
and the empty string as the identity.

```scala
"" ++ "Hello"
// res7: String = Hello

"Hello" ++ ""
// res8: String = Hello

("One" ++ "Two") ++ "Three"
// res9: String = OneTwoThree

"One" ++ ("Two" ++ "Three")
// res10: String = OneTwoThree
```

Note that we used `++` instead of the more usual `+`
to suggest a parallel with sequences.
We can do exactly the same with other types of sequence,
using concatenation as as the binary operator
and the empty sequence as our identity.

## Definition of a Monoid

We've seen a number of types that we can "add" and have an identity element.
It will be no surprise to learn that this is a monoid.
Formally, a monoid for a type `A` is:

- an operation `combine` with type `(A, A) => A`; and
- an element `empty` of type `A`.

The following laws must hold for all values `x`, `y`, and `z`, in `A`:

- `combine` must be associative: `combine(x, combine(y, z)) == combine(combine(x, y), z)`
- `empty` must be an identity element: `combine(x, empty) == combine(empty, x) == x`

In practice we only have to concern ourselves with these rules
if we find ourselves writing `Monoid` instances for custom data types.
Most of the time we can rely on the instances provided by Cats
and simply assume the library authors know what they're doing.

Here is a simplified version of the definition of the [`Monoid`] from Cats:

```scala
trait Monoid[A] {
  def combine(x: A, y: A): A
  def empty: A
}
// defined trait Monoid
```

## Definition of a Semigroup

A semigroup is simply the `combine` part of a monoid.

While many semigroups are also monoids,
there are some data types for which we cannot define an `empty` element.
For example, we have just seen that sequences
such as `Strings` and `Lists` are monoids under concatenation.
Similarly, `Ints` are monoids under addition.
However, if we restrict ourselves to non-empty sequences and positive integers,
we lose access to an `empty` element that obeys the identity law above.

A more accurate (though still simplidied) version of the [`Monoid`] from Cats is:

```scala
trait Semigroup[A] {
  def combine(x: A, y: A): A
}
// defined trait Semigroup

trait Monoid[A] extends Semigroup[A] {
  def empty: A
}
// defined trait Monoid
```

We'll see this kind of inheritance often when discussing type classes.
It provides modularity and allows us to re-use behaviour.
If we define a `Monoid` for a type `A`, we get a `Semigroup` for free.
Similarly, if a method requires a parameter of type `Semigroup[B]`,
we can pass a `Monoid[B]` instead.

## Exercise: The Truth About Monoids

We've seen a few monoid examples, but there are plenty more available.
Consider `Boolean`. How many monoids can you define for this type?
For each monoid, define  the `combine` and `empty` operations
and convince yourself that the monoid laws hold.
Use the following definitions as a starting point:

```scala
trait Semigroup[A] {
  def combine(x: A, y: A): A
}
// defined trait Semigroup

trait Monoid[A] extends Semigroup[A] {
  def empty: A
}
// defined trait Monoid

object Monoid {
  def apply[A](implicit monoid: Monoid[A]) =
    monoid
}
// defined object Monoid
// warning: previously defined trait Monoid is not a companion to object Monoid.
// Companions must be defined together; you may wish to use :paste mode for this.
```

<div class="solution">
There are four monoids for `Boolean`.

First, we have *and* with operator `&&` and identity `true`:

```scala
implicit val booleanAndMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = a && b
  def empty = true
}
// booleanAndMonoid: Monoid[Boolean] = $anon$1@35c97869
```

Second, we have *or* with operator `||` and identity `false`:

```scala
implicit val booleanOrMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = a || b
  def empty = false
}
// booleanOrMonoid: Monoid[Boolean] = $anon$1@3e52c551
```

Third, we have *exclusive or* with identity `false`:

```scala
implicit val booleanXorMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = (a && !b) || (!a && b)
  def empty = false
}
// booleanXorMonoid: Monoid[Boolean] = $anon$1@ca0ed27
```

Finally, we have *exclusive nor* (the negation of exclusive or) with identity `true`:

```scala
implicit val booleanXnorMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = (!a || b) && (a || !b)
  def empty = true
}
// booleanXnorMonoid: Monoid[Boolean] = $anon$1@11c16745
```

Showing that the identity law holds in each case is straightforward.
Similarly associativity of the `combine` operation can be shown by enumerating the cases.
</div>

## Exercise: All Set for Monoids

What monoids are there for sets?

<div class="solution">
*Set union* forms a monoid along with the empty set:

```scala
implicit def setUnionMonoid[A]: Monoid[Set[A]] = new Monoid[Set[A]] {
  def combine(a: Set[A], b: Set[A]) = a union b
  def empty = Set.empty[A]
}
// setUnionMonoid: [A]=> Monoid[Set[A]]
```

We need to define `setUnionMonoid` as a method rather than a value so we can accept the type parameter `A`.
Scala's implicit resolution algorithm is fine with this---it is capable of
determining the correct type parameter to create a `Monoid` of the desired type:

```scala
implicit val intMonoid: Monoid[Int] = new Monoid[Int] {
  def combine(a: Int, b: Int) = a + b
  def empty = 0
}
// intMonoid: Monoid[Int] = $anon$1@71676a9d

val intSetMonoid = Monoid[Set[Int]] // this will work
// intSetMonoid: Monoid[Set[Int]] = $anon$1@477f3a2e
```

Set intersection does not form a monoid as there is no identity element.
We call this weaker structure a *semigroup*---an combine operation without a empty.
Scala provides the `Semigroup` type class for this, of which `Monoid` is a subtype:

```scala
implicit def setIntersectionSemigroup[A]: Semigroup[Set[A]] =
  new Semigroup[Set[A]] {
    def combine(a: Set[A], b: Set[A]) = a intersect b
  }
// setIntersectionSemigroup: [A]=> Semigroup[Set[A]]
```
</div>
