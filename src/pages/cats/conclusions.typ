#import "../stdlib.typ": href
== Conclusions

We have also seen the general patterns in Cats type classes:

 - The type classes themselves are generic traits
   in the `cats` package.

 - Each type class has a companion object with,
   an `apply` method for materializing instances,
   one or more construction methods for creating instances,
   and a collection of other relevant helper methods.

 - Many type classes have extension methods
   provided via the `cats.syntax` package.

In the remaining chapters of @sec:part:type-classes
we will look at several broad and powerful type classes---`Semigroup`,
`Monoid`, `Functor`, `Monad`, `Semigroupal`, `Applicative`, `Traverse`, and more.
In each case we will learn what functionality the type class provides,
the formal rules it follows, and how it is implemented in Cats.
Many of these type classes are more abstract than `Show` or `Eq`.
While this makes them harder to learn,
it makes them far more useful for solving general problems in our code.
