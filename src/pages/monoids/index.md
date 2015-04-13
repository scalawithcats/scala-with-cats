# Monoids

In this section we explore our first type class: **monoids**. Let's start by looking a few types and operations, and see what common principles we can extract.

**Integer addition**

Addition of `Ints` is a binary operation that is *closed*, meaning given two `Ints` we always get another `Int` back. There is also the *identity* element `0` with the property that `a + 0 = 0 + a = a` for any `Int` `a`.

~~~ scala
2 + 1
// res0: Int = 3

2 + 0
// res1: Int = 2
~~~

There are also other properties of addition. For instance, it doesn't matter in what order we add elements as we always get the same result. This is a property known as *associativity*.

~~~ scala
(1 + 2) + 3
// res0: Int = 6

1 + (2 + 3)
// res1: Int = 6
~~~

**Integer multiplication**

We can do the same things with multiplication that we did with addition if we use `1` as the identity.

~~~ scala
(1 * 2) * 3
// res2: Int = 6

1 * (2 * 3)
// res3: Int = 6

2 * 3
// res4: Int = 6
~~~

**String and sequence concatenation**

We can do the same things with `String`, using string concatenation as our binary operator and the empty string as the identity.

~~~ scala
"" ++ "Hello"
// res6: String = Hello

"Hello" ++ ""
// res7: String = Hello

("One" ++ "Two") ++ "Three"
// res8: String = OneTwoThree

"One" ++ ("Two" ++ "Three")
// res9: String = OneTwoThree
~~~

Note that we used `++` for string concatentation instead of the more usual `+` to suggest a parallel with sequence concatenation. We can do exactly the same with sequence concatenation and the empty sequence as our identity.

## Definition of a Monoid

We've seen a number of types that we can "add" and have an identity element. It will be no surprise to learn that this is a monoid. Formally, a monoid for a type `A` is:

- an operation `append` with type `(A, A) => A`; and
- an element `zero` of type `A`.

The following laws must hold:

- `append` is associative, meaning `append(x, append(y, z)) == append(append(x, y), z)` for all `x`, `y`, and `z`, in `A`.
- `zero` is an identity of `append`, meaning `append(a, zero) == append(zero, a) == a` for any `a` in `A`.

A simplified version of the definition from Scalaz is:

~~~ scala
trait Monoid[A] {
  def append(f1: A, f2: => A): A
  def zero: A
}
~~~

where `append` is the binary operation and `zero` is the identity.

## Exercise: The Truth About Monoids

We've seen a few monoid examples, but there are plenty more available. Consider `Boolean`. How many monoids can you define for this type? For each monoid, define  the `append` and `zero` operations, and convince yourself that the monoid laws hold.

<div class="solution">
There are three monoids for `Boolean`.

First, we have *and* with operator `&&` and identity `true`:

~~~ scala
implicit val booleanAndMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def append(a: Boolean, b: => Boolean) = a && b
  def zero = true
}
~~~

Second, we have *or* with operator `||` and identity `false`:

~~~ scala
implicit val booleanOrMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def append(a: Boolean, b: => Boolean) = a || b
  def zero = false
}
~~~

Third, we have *exclusive or* with identity `false`:

~~~ scala
implicit val booleanXorMonoid: Monoid[Boolean] = new Monoid[Boolean] {
  def append(a: Boolean, b: => Boolean) = (a && !b) || (!a && b)
  def zero = false
}
~~~

Showing that the identity law holds in each case is straightforward. Similarly associativity of the `append` operation can be shown by enumerating the cases.
</div>

## Exercise: All Set for Monoids

What monoids are there for sets?

<div class="solution">
*Set union* forms a monoid along with the empty set:

~~~ scala
implicit def setUnionMonoid[A]: Monoid[Set[A]] = new Monoid[Set[A]] {
  def append(a: Set[A], b: => Set[A]) = a union b
  def zero = Set.empty[A]
}
~~~

We need to define `setUnionMonoid` as a method rather than a value so we can accept the type parameter `A`. Scala's implicit resolution algorithm is fine with this---it is capable of determining the correct type parameter to create a `Monoid` of the desired type:

~~~ scala
val intSetMonoid = Monoid[Set[Int]] // this will work
~~~

Set intersection does not form a monoid as there is no identity element. We call this weaker structure a *semigroup*---an append operation without a zero. Scala provides the `Semigroup` type class for this, of which `Monoid` is a subtype:

~~~ scala
implicit def setIntersectionSemigroup[A]: Semigroup[Set[A]] = new Semigroup[Set[A]] {
  def append(a: Set[A], b: => Set[A]) = a intersect b
}
~~~
</div>
