## Summary

In this chapter we took a first look at type classes. We implemented our own `Printable` type class using plain Scala before looking at two examples from Cats---`Show` and `Eq`.

We have now seen the general patterns in Cats type classes:

 - The type classes themselves are generic traits in the [`cats`][cats] package.

 - Each type class has a companion object with:

    - an `apply` method for materializing instances;

    - typically, one or more additional methods for creating instances.
      These methods are typically named after the type class or one of its methods,
      for example `Eq.eqv` and `Show.show`.

 - Default instances are provided via the [`cats.std`][cats.std] package, and are organized by
   *parameter type* rather than *type class type*.

 - Many type classes have *syntax* provided via the [`cats.syntax`][cats.syntax] package.

In the remaining chapters of this course we will look at four broad and powerful type classes---`Monoids`, `Functors`, `Monads`, and `Applicatives`. In each case we will learn what functionality the type class provides, the formal rules it follows, and how it is implemented in Cats.
