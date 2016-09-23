## Summary

In this chapter we took a first look at type classes. 
We implemented our own `Printable` type class using plain Scala 
before looking at two examples from Cats---`Show` and `Eq`.

We have now seen the general patterns in Cats type classes:

 - The type classes themselves are generic traits 
   in the [`cats`][cats.package] package.

 - Each type class has a companion object with:

    - an `apply` method for materializing instances;

    - typically, one or more additional methods for creating instances.

 - Default instances are 
   provided via the [`cats.instances`][cats.instances] package, 
   and are organized by parameter type rather than by type class.

 - Many type classes have *syntax*
   provided via the [`cats.syntax`][cats.syntax] package.

In the remaining chapters of this book
we will look at four broad and powerful 
type classes---`Monoids`, `Functors`, `Monads`, `Applicatives`, and more. 
In each case we will learn what functionality the type class provides, 
the formal rules it follows, and how it is implemented in Cats.
Many of these type classes are more abstract than `Show` or `Eq`.
While this makes them harder to learn,
it makes them far more useful for solving general problems in our code.
