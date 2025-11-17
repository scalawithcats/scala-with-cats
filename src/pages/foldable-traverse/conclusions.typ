#import "../stdlib.typ": info, warning, solution
== Conclusions

In this chapter we were introduced to `Foldable` and `Traverse`,
two type classes for iterating over sequences.

`Foldable` abstracts
the `foldLeft` and `foldRight` methods we know
from collections in the standard library.
It adds stack-safe implementations of these methods
to a handful of extra data types,
and defines a host of situationally useful additions.
That said, `Foldable` doesn't introduce much
that we didn't already know.

The real power comes from `Traverse`,
which abstracts and generalises
the `traverse` and `sequence` methods we know from `Future`.
Using these methods we can turn an `F[G[A]]` into a `G[F[A]]`
for any `F` with an instance of `Traverse`
and any `G` with an instance of `Applicative`.
In terms of the reduction we get in lines of code,
`Traverse` is one of the most powerful patterns in this book.
We can reduce `folds` of many lines down to a single `foo.traverse`.

-----

...and with that,
we've finished all of the theory in this book.
There's plenty more to come, though,
as we put everything we've learned into practice
in a series of in-depth case studies in Part II!
