## Controlling Instance Selection

When working with type classes we must consider two issues that control instance selection:

 -  What is the relationship between an instance defined on a type and its subtypes?

    For example, if we define a `Monoid[Option[Int]]`,
    will the expression `Some(1) |+| Some(2)` select this instance?
    (Remember that `Some` is a subtype of `Option`).

 -  How do we choose between type class instances when there are many available?

    We've seen two monoids for `Int`: addition and zero, and multiplication and one.
    Similarly there are at least four monoids for `Boolean` (and, or, equal, and not equal).
    When we write `true |+| false`, which instance is selected?

In this section we explore how Cats answers these questions.

### Type Class Variance

When we define type classes we can add variance annotations to the type parameter like we can for any other generic type. To quickly recap, there are three cases:

- A type with an unannotated parameter `Foo[A]` is *invariant* in `A`. This means there is no relationship between `Foo[B]` and `Foo[C]` no matter what the sub- or super-type relationship is between `B` and `C`.

- A type with a parameter `Foo[+A]` is *covariant* in `A`. If `C` is a subtype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

- An type with a parameter `Foo[-A]` is *contravariant* in `A`. If `C` is a supertype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

When the compiler searches for an implicit it looks for one matching the type *or subtype*. Thus we can use variance annotations to control type class instance selection to some extent.

There are two issues that tend to arise. Let's imagine we have an algebraic data type like:

```scala
sealed trait A
// defined trait A

final case object B extends A
// defined object B

final case object C extends A
// defined object C
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

```scala
import cats.instances.option._
// import cats.instances.option._

import cats.syntax.option._
// import cats.syntax.option._

Some(1)   // direct construction yields `Some[Int]`
// res0: Some[Int] = Some(1)

1.some    // smart constructor yields `Option[Int]`
// res1: Option[Int] = Some(1)

None      // direct construction yields `None.type`
// res2: None.type = None

none[Int] // smart constructor yields `Option[Int]`
// res3: Option[Int] = None
```

### Identically Typed Instances

The other issue is choosing between type class instances
when several are available for a specific type.
For example, how do we select the monoid for integer multiplication
instead of the monoid for integer addition?

At this point in time Cats has no mechanism for selecting alternative instances, 
though this is likely to change in the future.

We can always define or import a type class instance into the local scope.
This will take precedence over other type class instances in the implicit scope.

```scala
import cats.Monoid
// import cats.Monoid

import cats.syntax.semigroup._
// import cats.syntax.semigroup._

implicit val multiplicationMonoid = 
  new Monoid[Int] {
    def empty: Int = 1
    override def combine(x: Int, y: Int): Int = x * y
  }
// multiplicationMonoid: cats.Monoid[Int] = $anon$1@7719b3ae

3 |+| 2
// res4: Int = 6
```
