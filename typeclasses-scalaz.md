# Type Classes, Scalaz, and All That
## Introduction
The goal of this course is to cover type classes, the major abstractions from abstract algebra / category theory (monoids, monads, and so) and their use and implementation in Scala and Scalaz 7.
### Setup
sbt etc. to work along
### Typeclasses
- Explain type classes. Separate implementation from data. "Ad hoc polymorphism" Simple example of Equal or Show (or maybe summing).
- This is all about abstraction. Abstraction wins in the large, so some of the examples may feel trivial or simple. Remember the idea is to learn concepts through simple examples, but understand these concepts have broad applicability.
- Implementation pattern in Scala. Traits and implicits. Implicit classes. Context bounds and View bounds.
- Quick overview of implicit resolution rules.
### Scalaz
- Code organisation (syntax.std vs std)
- Relationship to other libraries (Scala stdlib, Spire, Algebird)
- Relationship to Haskell
## Show and Equal
This is just warmup stuff. Examples. Show how we can implement our own instances.
- Ordering? It's in the stdlib, so might be a nice example.
## Monoid
- Let's turn to an interesting and useful typeclass, the Monoid.
- A Monoid has zero, and +, and obeys associative and identity laws.
- Obvious instance: numbers, 0, +. Less obvious: numbers, 1, *. Less obvious still: numbers, -inf, and max.
- Summing up stuff.
- Examples: numbers, lists, strings, option, ordering
- Monoid laws
## Controlling Typeclass Selection
- Unboxed tags
  - Issues with subtyping and contravariance
- Value classes
## Functor?
- We can think of things like Option and List as boxes containing values. An Option contains zero or one values. A List contains zero or more values.
- A basic operation on these boxes is transforming the values they contain. You probably already know the `map` function, which does this.
- A Functor is just a generalisation of this idea. A container of values with a `map` operation is a Functor.
- Example: Option. Replace with List---it still works!
- So Functors aren't that exciting, but being able to name this concept (mappable) is useful as it allows us to abstract over it, and also to discuss it.
- Example: Option and \/. Introduce type lambda (might as well get that horror out the way amongst the easy stuff.)
- Derived functions on Functor.## Applicative
## Monad
- ???
- \/
- Writer
- MonadPlus---monads that are monoids.
## Monad Transformers
## Controlling Implicit Selection
- Unboxed tagged types
  - Issues (subtyping)
- Value classes
## Traverse and other iteration
## scalaz-contrib
- Future as a monad
## Case Study: Futures
- Future + Writer + \/
## Case Study: Algebird
- Algebird, analytics, etc.
