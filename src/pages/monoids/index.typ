#import "../stdlib.typ": info, warning, solution, chapter, href
#chapter[Monoids and Semigroups] <sec:monoids>


In this section we explore our first type classes, *monoid* and *semigroup*.
These allow us to add or combine values.
There are instances for `Ints`, `Strings`, `Lists`, `Options`, and many more.
Let's start by looking at a few simple types and operations
to see what common principles we can extract.

==== Integer addition


Addition of `Ints` is a binary operation that is _closed_,
meaning that adding two `Ints` always produces another `Int`:

```scala mdoc
2 + 1
```

There is also the _identity_ element `0` with the property
that `a + 0 == 0 + a == a` for any `Int` `a`:

```scala mdoc
2 + 0

0 + 2
```

There are also other properties of addition.
For instance, it doesn't matter in what order we add elements
because we always get the same result.
This is a property known as _associativity_:

```scala mdoc
(1 + 2) + 3

1 + (2 + 3)
```


==== Integer multiplication


The same properties for addition also apply for multiplication,
provided we use `1` as the identity instead of `0`:

```scala mdoc
1 * 3

3 * 1
```

Multiplication, like addition, is associative:

```scala mdoc
(1 * 2) * 3

1 * (2 * 3)
```


==== String and sequence concatenation


We can also add `Strings`,
using string concatenation as our binary operator:

```scala mdoc
"One" ++ "two"
```

and the empty string as the identity:

```scala mdoc
"" ++ "Hello"

"Hello" ++ ""
```

Once again, concatenation is associative:

```scala mdoc
("One" ++ "Two") ++ "Three"

"One" ++ ("Two" ++ "Three")
```

Note that we used `++` above instead of the more usual `+`
to suggest a parallel with sequences.
We can do the same with other types of sequence,
using concatenation as the binary operator
and the empty sequence as our identity.


== Definition of a Monoid


We've seen a number of "addition" scenarios above
each with an associative binary addition
and an identity element.
It will be no surprise to learn that this is a monoid.
Formally, a monoid for a type `A` is:

- an operation `combine` with type `(A, A) => A`
- an element `empty` of type `A`

This definition translates nicely into Scala code.
Here is a simplified version of the definition from Cats:

```scala mdoc:silent
trait Monoid[A] {
  def combine(x: A, y: A): A
  def empty: A
}
```

In addition to providing the `combine` and `empty` operations,
monoids must formally obey several _laws_.
For all values `x`, `y`, and `z`, in `A`,
`combine` must be associative and
`empty` must be an identity element:

```scala mdoc:silent
def associativeLaw[A](x: A, y: A, z: A)
      (using m: Monoid[A]): Boolean = {
  m.combine(x, m.combine(y, z)) ==
    m.combine(m.combine(x, y), z)
}

def identityLaw[A](x: A)
      (using m: Monoid[A]): Boolean = {
  (m.combine(x, m.empty) == x) &&
    (m.combine(m.empty, x) == x)
}
```

Integer subtraction, for example,
is not a monoid because subtraction is not associative:

```scala mdoc
(1 - 2) - 3

1 - (2 - 3)
```

In practice we only need to think about laws
when we are writing our own `Monoid` instances.
Unlawful instances are dangerous because
they can yield unpredictable results
when used with the rest of Cats' machinery.
Most of the time we can rely on the instances provided by Cats
and assume the library authors know what they're doing.


== Definition of a Semigroup


A semigroup is just the `combine` part of a monoid,
without the `empty` part.
While many semigroups are also monoids,
there are some data types for which we cannot define an `empty` element.
For example, we have just seen that
sequence concatenation and integer addition are monoids.
However, if we restrict ourselves
to non-empty sequences and positive integers,
we are no longer able to define a sensible `empty` element.
Cats has a #href("http://typelevel.org/cats/api/cats/data/NonEmptyList.html")[`NonEmptyList`] data type
that has an implementation of `Semigroup` but no implementation of `Monoid`.

A more accurate (though still simplified)
definition of Cats' #href("http://typelevel.org/cats/api/cats/Monoid.html")[`Monoid`] is:

```scala mdoc:silent:reset-object
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


==== Exercise: The Truth About Monoids 


We've seen a few examples of monoids but there are plenty more to be found.
Consider `Boolean`. How many monoids can you define for this type?
For each monoid, define the `combine` and `empty` operations
and convince yourself that the monoid laws hold.
Use the following definitions as a starting point:

```scala mdoc:reset:silent
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

#solution[
There are at least four monoids for `Boolean`!
First, we have _and_ with operator `&&` and identity `true`:

```scala mdoc:silent
given booleanAndMonoid: Monoid[Boolean] with {
  def combine(a: Boolean, b: Boolean) = a && b
  def empty = true
}
```

Second, we have _or_ with operator `||` and identity `false`:

```scala mdoc:silent
given booleanOrMonoid: Monoid[Boolean] with {
  def combine(a: Boolean, b: Boolean) = a || b
  def empty = false
}
```

Third, we have _exclusive or_ with identity `false`:

```scala mdoc:silent
given booleanEitherMonoid: Monoid[Boolean] with {
  def combine(a: Boolean, b: Boolean) =
    (a && !b) || (!a && b)

  def empty = false
}
```

Finally, we have _exclusive nor_ (the negation of exclusive or)
with identity `true`:

```scala mdoc:silent
given booleanXnorMonoid: Monoid[Boolean] with {
  def combine(a: Boolean, b: Boolean) =
    (!a || b) && (a || !b)

  def empty = true
}
```

Showing that the identity law holds in each case is straightforward.
Similarly associativity of the `combine` operation
can be shown by enumerating the cases.
]


==== Exercise: All Set for Monoids


What monoids and semigroups are there for sets?

#solution[
*Set union* forms a monoid along with the empty set:

```scala mdoc:silent
given setUnionMonoid[A]: Monoid[Set[A]] with {
  def combine(a: Set[A], b: Set[A]) = a.union(b)
  def empty = Set.empty[A]
}
```

We need to define `setUnionMonoid` as a method
rather than a value so we can accept the type parameter `A`.
The type parameter allows us to use the same definition
to summon `Monoids` for `Sets` of any type of data:

```scala mdoc:silent
val intSetMonoid = Monoid[Set[Int]]
val strSetMonoid = Monoid[Set[String]]
```

```scala mdoc
intSetMonoid.combine(Set(1, 2), Set(2, 3))
strSetMonoid.combine(Set("A", "B"), Set("B", "C"))
```

Set intersection forms a semigroup,
but doesn't form a monoid because it has no identity element:

```scala mdoc:silent
given setIntersectionSemigroup[A]: Semigroup[Set[A]] with {
  def combine(a: Set[A], b: Set[A]) =
    a.intersect(b)
}
```

Set complement and set difference are not associative,
so they cannot be considered for either monoids or semigroups.
However, symmetric difference (the union less the intersection)
does form a monoid with the empty set:

```scala mdoc:invisible:reset-object
import cats.Monoid
```
```scala mdoc:silent
given symDiffMonoid[A]: Monoid[Set[A]] with {
  def combine(a: Set[A], b: Set[A]): Set[A] =
    (a.diff(b)).union(b.diff(a))

  def empty: Set[A] = Set.empty
}
```
]
