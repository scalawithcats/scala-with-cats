## Summary

We covered three types of functor in this chapter:
regular covariant `Functors` with their `map` method,
as well as `Contravariant` functors with their `contramap` methods,
and `Invariant` functors with their `imap` methods.

Regular `Functors` are by far the most common of these type classes,
but even then is rare to use them on their own.
They form the building block of
several more interesting abstractions that we use all the time.
In the following chapters we will look at two of these abstractions:
`Monads` and `Applicatives`.

The `map` method for collection types is important because
each element in a collection can be transformed independently of the rest.
This allows us to parallelise or distribute
transformations on large collections,
a technique leveraged heavily in
"map reduce" frameworks like [Hadoop][link-hadoop].
We will investigate this approach in more detail in the
[Pygmy Hadoop](#map-reduce) case study later in the book.

The `Contravariant` and `Invariant` type classes are more situational.
We won't be doing much more work with them,
although we will revisit them to discuss [`Cartesians`](#cartesian),
and for the [JSON Codec](#json-codec) case study later in the book.
