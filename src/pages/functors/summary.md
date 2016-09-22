## Summary

We covered three types of functor in this chapter:
regular covariant `Functors` with their `map` method,
as well as `Contravariant` and `Invariant` functors
with their `contramap` and `imap` methods.

Regular `Functors` are by far the most common of these type classes.
It is rare to use them on their own.
However, they form the building block of
several more interesting abstractions that we use all the time.
In the following chapters we will look at two of these useful abstractions:
`Monads` and `Applicatives`.

`Contravariant` and `Invariant` functors
are much more specialised type classes.
We won't be doing much more work with them,
although we will revisit them briefly
in the chapter on [`Cartesians`](#cartesian),
and they do form the basis of
the [JSON Codec](#json-codec) case study
in the second half of the book.
