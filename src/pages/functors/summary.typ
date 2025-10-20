#import "../stdlib.typ": href, info, warning, solution
== Summary


Functors represent sequencing behaviours.
We covered three types of functor in this chapter:

- Regular covariant `Functors`, with their `map` method,
  represent the ability to apply functions
  to a value in some context.
  Successive calls to `map`
  apply these functions in _sequence_,
  each accepting the result of its predecessor
  as a parameter.

- `Contravariant` functors, with their `contramap` method,
  represent the ability to "prepend" functions
  to a function-like context.
  Successive calls to `contramap`
  sequence these functions in the opposite order to `map`.

- `Invariant` functors, with their `imap` method,
  represent bidirectional transformations.

Regular `Functors` are by far the most common of these type classes,
but even then it is rare to use them on their own.
Functors form a foundational building block of
several more interesting abstractions that we use all the time.
In the following chapters we will look at two of these abstractions:
*monads* and *applicative functors*.

Functors for collections are extremely important, as they transform each element independently of the rest.
This allows us to parallelise or distribute
transformations on large collections,
a technique leveraged heavily in
"map-reduce" frameworks popularized by #href("http://hadoop.apache.org")[Hadoop].
We will investigate this approach in more detail in the
map-reduce case study later in @sec:map-reduce.

The `Contravariant` and `Invariant` type classes
are less widely applicable but are still useful
for building data types that represent transformations.
We will revisit them to discuss the `Semigroupal`
type class later in @sec:applicatives.
