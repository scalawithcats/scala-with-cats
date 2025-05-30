#import "../stdlib.typ": info, warning, solution
== Conclusions


We have also seen the general patterns in Cats type classes:

 - The type classes themselves are generic traits
   in the [`cats`][cats.package] package.

 - Each type class has a companion object with,
   an `apply` method for materializing instances,
   one or more _construction_ methods for creating instances,
   and a collection of other relevant helper methods.

 - Many type classes have _syntax_
   provided via the [`cats.syntax`][cats.syntax] package.

In the remaining chapters of Part {#sec:part:two}
we will look at several broad and powerful type classes---`Semigroup`,
`Monoid`, `Functor`, `Monad`, `Semigroupal`, `Applicative`, `Traverse`, and more.
In each case we will learn what functionality the type class provides,
the formal rules it follows, and how it is implemented in Cats.
Many of these type classes are more abstract than `Show` or `Eq`.
While this makes them harder to learn,
it makes them far more useful for solving general problems in our code.
