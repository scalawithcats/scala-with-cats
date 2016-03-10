# Monoids

In this section we explore our first type class: **monoids**. Let's start by looking a few types and operations, and see what common principles we can extract.

**Integer addition**

Addition of `Ints` is a binary operation that is *closed*, meaning given two `Ints` we always get another `Int` back. There is also the *identity* element `0` with the property that `a + 0 == 0 + a == a` for any `Int` `a`.

```scala
2 + 1
// res0: Int = 3

2 + 0
// res1: Int = 2
```

There are also other properties of addition. For instance, it doesn't matter in what order we add elements as we always get the same result. This is a property known as *associativity*.

```scala
(1 + 2) + 3
// res2: Int = 6

1 + (2 + 3)
// res3: Int = 6
```

**Integer multiplication**

We can do the same things with multiplication that we did with addition if we use `1` as the identity.

```scala
(1 * 2) * 3
// res4: Int = 6

1 * (2 * 3)
// res5: Int = 6

2 * 3
// res6: Int = 6
```

**String and sequence concatenation**

We can do the same things with `String`, using string concatenation as our binary operator and the empty string as the identity.

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

Note that we used `++` instead of the more usual `+` to suggest a parallel with sequences. We can do exactly the same with other types of sequence, using concatenation as as the binary operator and the empty sequence as our identity.

## Definition of a Monoid

We've seen a number of types that we can "add" and have an identity element. It will be no surprise to learn that this is a monoid. Formally, a monoid for a type `A` is:

- an operation `combine` with type `(A, A) => A`; and
- an element `empty` of type `A`.

The following laws must hold:

- `combine` is associative, meaning `combine(x, combine(y, z)) == combine(combine(x, y), z)` for all `x`, `y`, and `z`, in `A`;
- `empty` is an identity of `combine`, meaning `combine(a, empty) == combine(empty, a) == a` for any `a` in `A`.

A simplified version of the definition from Cats is:

```scala
trait Monoid[A] {
  def combine(x: A, y: A): A
  def empty: A
}
// defined trait Monoid
```

where `combine` is the binary operation and `empty` is the identity.

## Exercise: The Truth About Monoids

We've seen a few monoid examples, but there are plenty more available. Consider `Boolean`. How many monoids can you define for this type? For each monoid, define  the `combine` and `empty` operations, and convince yourself that the monoid laws hold.

<div class="solution">
There are four monoids for `Boolean`.

First, we have *and* with operator `&&` and identity `true`:

```scala
import cats.Monoid
// import cats.Monoid

implicit val booleanAndMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = a && b
  def empty = true
}
// booleanAndMonoid: cats.Monoid[Boolean] = $anon$1@7bfdf3ed
```

Second, we have *or* with operator `||` and identity `false`:

```scala
implicit val booleanOrMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = a || b
  def empty = false
}
// booleanOrMonoid: cats.Monoid[Boolean] = $anon$1@40af8a6e
```

Third, we have *exclusive or* with identity `false`:

```scala
implicit val booleanXorMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = (a && !b) || (!a && b)
  def empty = false
}
// booleanXorMonoid: cats.Monoid[Boolean] = $anon$1@503f82c9
```

Finally, we have *exclusive nor* (the negation of exclusive or) with identity `true`:

```scala
implicit val booleanXnorMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def combine(a: Boolean, b: Boolean) = (!a || b) && (a || !b)
  def empty = true
}
// booleanXnorMonoid: cats.Monoid[Boolean] = $anon$1@46f81f47
```

Showing that the identity law holds in each case is straightforward. Similarly associativity of the `combine` operation can be shown by enumerating the cases.
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
// setUnionMonoid: [A]=> cats.Monoid[Set[A]]
```

We need to define `setUnionMonoid` as a method rather than a value so we can accept the type parameter `A`. Scala's implicit resolution algorithm is fine with this---it is capable of determining the correct type parameter to create a `Monoid` of the desired type:

```scala
val intSetMonoid = Monoid[Set[Int]] // this will work
// intSetMonoid: algebra.Monoid[Set[Int]] = $anon$1@1cb47480
```

Set intersection does not form a monoid as there is no identity element. We call this weaker structure a *semigroup*---an combine operation without a empty. Scala provides the `Semigroup` type class for this, of which `Monoid` is a subtype:

```scala
import cats.Semigroup
// import cats.Semigroup

implicit def setIntersectionSemigroup[A]: Semigroup[Set[A]] =
  new Semigroup[Set[A]] {
    def combine(a: Set[A], b: Set[A]) = a intersect b
  }
// setIntersectionSemigroup: [A]=> cats.Semigroup[Set[A]]
```
</div>
