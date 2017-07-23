# Monoids and Semigroups {#sec:monoids}

In this section we explore our first type classes, **monoid** and **semigroup**.
These allow us to add or combine values.
There are instances for `Ints`, `Strings`, `Lists`, `Options`, and many, many more.
Let's start by looking at a few simple types and operations
to see what common principles we can extract.

**Integer addition**

Addition of `Ints` is a binary operation that is *closed*,
meaning that adding two `Ints` always produces another `Int`:

```tut:book
2 + 1
```

There is also the *identity* element `0` with the property
that `a + 0 == 0 + a == a` for any `Int` `a`:

```tut:book
2 + 0

0 + 2
```

There are also other properties of addition.
For instance, it doesn't matter in what order we add elements
because we always get the same result.
This is a property known as *associativity*:

```tut:book
(1 + 2) + 3

1 + (2 + 3)
```

**Integer multiplication**

The same properties for addition also apply for multiplication,
provided wee use `1` as the identity instead of `0`:

```tut:book
1 * 3

3 * 1
```

Multiplication, like addition, is associative:

```tut:book
(1 * 2) * 3

1 * (2 * 3)
```

**String and sequence concatenation**

We can also add `Strings`,
using string concatenation as our binary operator:

```tut:book
"One" ++ "two"
```

and the empty string as the identity:

```tut:book
"" ++ "Hello"

"Hello" ++ ""
```

Once again, concatenation is associative:

```tut:book
("One" ++ "Two") ++ "Three"

"One" ++ ("Two" ++ "Three")
```

Note that we used `++` above instead of the more usual `+`
to suggest a parallel with sequences.
We can do exactly the same with other types of sequence,
using concatenation as as the binary operator
and the empty sequence as our identity.

## Definition of a Monoid

We've seen a number of "addition" scenarios above
each with an associative binary addition
and an identity element.
It will be no surprise to learn that this is a monoid.
Formally, a monoid for a type `A` is:

- an operation `combine` with type `(A, A) => A`
- an element `empty` of type `A`

This definition translates nicely into Scala code.
Here is a simplified version of the definition from Cats:

```tut:book:silent
trait Monoid[A] {
  def combine(x: A, y: A): A
  def empty: A
}
```

In addition to providing these operations,
monoids must formally obey several *laws*.
For all values `x`, `y`, and `z`, in `A`,
`combine` must be associative and
`empty` must be an identity element:

```tut:book:silent
def associativeLaw[A](x: A, y: A, z: A)
    (implicit m: Monoid[A]): Boolean =
  m.combine(x, m.combine(y, z)) == m.combine(m.combine(x, y), z)

def identityLaw[A](x: A)
    (implicit m: Monoid[A]): Boolean = {
  (m.combine(x, m.empty) == x) &&
  (m.combine(m.empty, x) == x)
}
```

Integer subtraction, for example,
is not a monoid because subtraction is not associative:

```tut:book
(1 - 2) - 3

1 - (2 - 3)
```

In practice we only need to think about laws
when we are writing our own `Monoid` instances for custom data types.
Most of the time we can rely on the instances provided by Cats
and assume the library authors know what they're doing.

## Definition of a Semigroup

A semigroup is simply the `combine` part of a monoid.
While many semigroups are also monoids,
there are some data types for which we cannot define an `empty` element.
For example, we have just seen that
sequence concatenation and integer addition are monoids.
However, if we restrict ourselves to non-empty sequences and positive integers,
we lose access to an `empty` element.
Cats has a [`NonEmptyList`][cats.data.NonEmptyList] data type
that has an implementation of `Semigroup` but no implementation of `Monoid`.

A more accurate (though still simplified)
definition of Cats' [`Monoid`][cats.Monoid] is:

```tut:book:silent
trait Semigroup[A] {
  def combine(x: A, y: A): A
}

trait Monoid[A] extends Semigroup[A] {
  def empty: A
}
```

We'll see this kind of inheritance often when discussing type classes.
It provides modularity and allows us to re-use behaviour.
If we define a `Monoid` for a type `A`, we get a `Semigroup` for free.
Similarly, if a method requires a parameter of type `Semigroup[B]`,
we can pass a `Monoid[B]` instead.

## Exercise: The Truth About Monoids

We've seen a few examples of monoids but there are plenty more to be found.
Consider `Boolean`. How many monoids can you define for this type?
For each monoid, define the `combine` and `empty` operations
and convince yourself that the monoid laws hold.
Use the following definitions as a starting point:

```tut:book:reset:silent
trait Semigroup[A] {
  def combine(x: A, y: A): A
}

trait Monoid[A] extends Semigroup[A] {
  def empty: A
}

object Monoid {
  def apply[A](implicit monoid: Monoid[A]) =
    monoid
}
```

<div class="solution">
There are four monoids for `Boolean`!
First, we have *and* with operator `&&` and identity `true`:

```tut:book:silent
implicit val booleanAndMonoid: Monoid[Boolean] =
  new Monoid[Boolean] {
    def combine(a: Boolean, b: Boolean) = a && b
    def empty = true
  }
```

Second, we have *or* with operator `||` and identity `false`:

```tut:book:silent
implicit val booleanOrMonoid: Monoid[Boolean] =
  new Monoid[Boolean] {
    def combine(a: Boolean, b: Boolean) = a || b
    def empty = false
  }
```

Third, we have *exclusive or* with identity `false`:

```tut:book:silent
implicit val booleanEitherMonoid: Monoid[Boolean] =
  new Monoid[Boolean] {
    def combine(a: Boolean, b: Boolean) =
      (a && !b) || (!a && b)

    def empty = false
  }
```

Finally, we have *exclusive nor* (the negation of exclusive or)
with identity `true`:

```tut:book:silent
implicit val booleanXnorMonoid: Monoid[Boolean] =
  new Monoid[Boolean] {
    def combine(a: Boolean, b: Boolean) =
      (!a || b) && (a || !b)

    def empty = true
  }
```

Showing that the identity law holds in each case is straightforward.
Similarly associativity of the `combine` operation
can be shown by enumerating the cases.
</div>

## Exercise: All Set for Monoids

What monoids and semigroups are there for sets?

<div class="solution">
*Set union* forms a monoid along with the empty set:

```tut:book:silent
implicit def setUnionMonoid[A]: Monoid[Set[A]] =
  new Monoid[Set[A]] {
    def combine(a: Set[A], b: Set[A]) = a union b
    def empty = Set.empty[A]
  }
```

We need to define `setUnionMonoid` as a method
rather than a value so we can accept the type parameter `A`.
Scala's implicit resolution is fine with this---it is capable of
determining the correct type parameter
to create a `Monoid` of the desired type:

```tut:book:silent
implicit val intMonoid: Monoid[Int] = new Monoid[Int] {
  def combine(a: Int, b: Int) = a + b
  def empty = 0
}
```

```tut:book
val intSetMonoid = Monoid[Set[Int]]

intSetMonoid.combine(Set(1, 2), Set(2, 3))
```

Set intersection forms a semigroup,
but doesn't form a monoid because it has no identity element:

```tut:book:silent
implicit def setIntersectionSemigroup[A]: Semigroup[Set[A]] =
  new Semigroup[Set[A]] {
    def combine(a: Set[A], b: Set[A]) =
      a intersect b
  }
```

Set complement and set difference are not associative,
so they cannot be considered for either monoids or semigroups.

However symmetric difference (the union less the intersection)
does also form a monoid with the empty set:

```tut:book:silent
implicit def symDiffMonoid[A]: Monoid[Set[A]] = 
  new Monoid[Set[A]] {
    def combine(a: Set[A], b: Set[A]): Set[A] = 
      (a diff b) union (b diff a)
    def empty: Set[A] = Set.empty
  }
```

</div>
