## Controlling Instance Selection

When working with type classes we must consider two issues that control instance selection:

 -  What is the relationship between an instance defined on a type and its subtypes?

    For example, if we define a `Monoid[Option]` will the expression `Some(1) |+| Some(2)` select this instance? (Remember that `Some` is a subtype of `Option`).

 -  How do we choose between type class instances when there are many available?

    We've seen there are two monoids for `Int`: addition and zero, and multiplication and one. Similarly there are three monoids for `Boolean`. When we write `true |+| false`, which instance is selected?

In this section we explore how Cats answers these questions.

### Type Class Variance

When we define type classes we can add variance annotations to the type parameter like we can for any other generic type. To quickly recap, there are three cases:

- A type with an unannotated parameter `Foo[A]` is *invariant* in `A`. This means there is no relationship between `Foo[B]` and `Foo[C]` no matter what the sub- or super-type relationship is between `B` and `C`.

- A type with a parameter `Foo[+A]` is *covariant* in `A`. If `C` is a subtype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

- An type with a parameter `Foo[-A]` is *contravariant* in `A`. If `C` is a supertype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

When the compiler searches for an implicit it looks for one matching the type *or subtype*. Thus we can use variance annotations to control type class instance selection to some extent.

There are two issues that tend to arise. Let's imagine we have an algebraic data type like:

```tut:book
sealed trait A
final case object B extends A
final case object C extends A
```

The issues are:

 1. Will an instance defined on a supertype be selected if one is available? For example, can we define an instance for `A` and have it work for values of type `B` and `C`?

 2. Will an instance for a subtype be selected in preference to that of a supertype. For instance, if we define an instance for `A` and `B`, and we have a value of type `B`, will the instance for `B` be selected in preference to `A`?

It turns out we can't have both at once. The three choices give us behaviour as follows:

-----------------------------------------------------------------------
Type Class Variance             Invariant   Covariant   Contravariant
------------------------------- ----------- ----------- ---------------
Supertype instance used?        No          No          Yes

More specific type preferred?   Yes         Yes         No
-----------------------------------------------------------------------

It's clear there is no perfect system. Cats generally prefers to use invariant type classes. This allows us to specify more specific instances for subtypes if we want. It does mean that if we have, for example, a value of type `Some[Int]`, our monoid instance for `Option` will not be used. We can solve this problem with a type annotation like `Some(1) : Option[Int]` or by using "smart constructors" that construct values with the type of the base trait in an algebraic data type. For example, Cats provides `some` and `none` constructors for `Option`:

```tut:book
import cats.std.option._
import cats.syntax.option._

Some(1)   // direct construction yields `Some[Int]`

1.some    // smart constructor yields `Option[Int]`

None      // direct construction yields `None.type`

none[Int] // smart constructor yields `Option[Int]`
```

### Identically Typed Instances

The other issue is choosing between type class instances
when several are available for a specific type.
For example, how do we select the monoid for integer multiplication
instead of the monoid for integer addition?

Cats handles this by only providing at most one implicit monoid for each type.
The default monoid for `Int` is addition:

```tut:book
import cats.Monoid
import cats.std.int._

Monoid[Int].combine(2, 3)
```

but we can summon the multiplication monoid explicitly:

```tut:book
val multMonoid: Monoid[Int] =
  cats.std.int.intAlgebra.multiplicative

multMonoid.combine(2, 3)
```

Cats doesn't provide a default monoid for `Boolean`,
although we can summon monoids for conjuction and disjunction explicitly:

```tut:book
val conjMonoid: Monoid[Boolean] =
  cats.std.boolean.booleanAlgebra.multiplicative

val disjMonoid: Monoid[Boolean] =
  cats.std.boolean.booleanAlgebra.additive

conjMonoid.combine(true, false)
disjMonoid.combine(true, false)
```

If we want to select a specific monoid for use with the `|+|` syntax,
we need only assign it to an `implicit val` of the correct type.
This will override the monoids imported from `cats.std`:

```tut:book
import cats.syntax.semigroup._

implicit val multMonoid: Monoid[Int] =
  cats.std.int.intAlgebra.multiplicative

2 |+| 3
```
