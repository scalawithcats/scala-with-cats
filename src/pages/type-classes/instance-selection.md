## Controlling Instance Selection

When working with type classes
we must consider two issues
that control instance selection:

 -  What is the relationship between
    an instance defined on a type and its subtypes?

    For example, if we define a `JsonWriter[Option[Int]]`,
    will the expression `Json.toJson(Some(1))` select this instance?
    (Remember that `Some` is a subtype of `Option`).

 -  How do we choose between type class instances
    when there are many available?

    What if we define two `JsonWriters` for `Person`?
    When we write `Json.toJson(aPerson)`,
    which instance is selected?

### Type Class Variance

When we define type classes we can
add variance annotations to the type parameter
like we can for any other generic type.
To quickly recap, there are three cases:

 -  A type with an unannotated parameter
    `Foo[A]` is *invariant* in `A`.

    This means there is no relationship between `Foo[B]` and `Foo[C]`
    no matter what the sub- or super-type relationship is between `B` and `C`.

 -  A type with a parameter `Foo[+A]` is *covariant* in `A`.

    If `C` is a subtype of `B`, `Foo[C]` is a subtype of `Foo[B]`.

    This is common in "collection" types such as `List` and `Option`.
    It is useful for a `List[C]` is a subtype of `List[B]`.

 -  A type with a parameter `Foo[-A]` is *contravariant* in `A`.

    If `C` is a subtype of `B`, `Foo[B]` is a subtype of `Foo[C]`.

    This is common when modelling function parameters,
    including the parameters of Scala's built-in function types.
    For example, a function that accepts
    a parameter of type `List[B]`
    will always accept a parameter of type `List[C]`.
    We therefore say that `List[B] => R` is
    a subtype of `List[C] => R` for any given `R`.

When the compiler searches for an implicit
it looks for one matching the type *or subtype*.
Thus we can use variance annotations
to control type class instance selection to some extent.

There are two issues that tend to arise.
Let's imagine we have an algebraic data type like:

```tut:book:silent
sealed trait A
final case object B extends A
final case object C extends A
```

The issues are:

 1. Will an instance defined on a supertype be selected
    if one is available?
    For example, can we define an instance for `A`
    and have it work for values of type `B` and `C`?

 2. Will an instance for a subtype be selected
    in preference to that of a supertype.
    For instance, if we define an instance for `A` and `B`,
    and we have a value of type `B`,
    will the instance for `B` be selected in preference to `A`?

It turns out we can't have both at once.
The three choices give us behaviour as follows:

-----------------------------------------------------------------------
Type Class Variance             Invariant   Covariant   Contravariant
------------------------------- ----------- ----------- ---------------
Supertype instance used?        No          No          Yes

More specific type preferred?   No          Yes         No
-----------------------------------------------------------------------

It's clear there is no perfect system.
Cats generally prefers to use invariant type classes.
This allows us to specify
more specific instances for subtypes if we want.
It does mean that if we have, for example,
a value of type `Some[Int]`,
our type class instance for `Option` will not be used.
We can solve this problem with
a type annotation like `Some(1) : Option[Int]`
or by using "smart constructors" that construct values
with the type of the base trait in an algebraic data type.
For example, the Scala standard library
`Option.apply` and `Option.empty` constructors for `Option`:

```tut:book
Option(1)
Option.empty[Int]
```

Cats also provides `some` and `none` extension methods
via the `cats.syntax.option` import:

```tut:book:silent
import cats.syntax.option._
```

```tut:book
1.some
none[Int]
```
