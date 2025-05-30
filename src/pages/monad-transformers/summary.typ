#import "../stdlib.typ": info, warning, solution
== Summary


In this chapter we introduced monad transformers,
which eliminate the need for nested for comprehensions and pattern matching
when working with "stacks" of nested monads.

Each monad transformer, such as `FutureT`, `OptionT` or `EitherT`,
provides the code needed to merge its related monad with other monads.
The transformer is a data structure that wraps a monad stack,
equipping it with `map` and `flatMap` methods
that unpack and repack the whole stack.

The type signatures of monad transformers are written from the inside out,
so an `EitherT[Option, String, A]` is a wrapper for an `Option[Either[String, A]]`.
It is often useful to use type aliases
when writing transformer types for deeply nested monads.

With this look at monad transformers,
we have now covered everything we need to know about monads
and the sequencing of computations using `flatMap`.
In the next chapter we will switch tack
and discuss two new type classes, `Semigroupal` and `Applicative`,
that support new kinds of operation such as `zipping`
independent values within a context.
