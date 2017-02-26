## Summary

In this chapter we've seen monads up-close.
We saw that `flatMap` can be viewed as sequencing computations,
giving the order in which operations must happen.
In this view, `Option` represents a computation
that can fail without an error message;
`Either` represents computations that can fail with a message;
`List` represents multiple possible results; and
`Future` represents a computation that
may produce a value at some point in the future.

In this chapter we've also seen some of
the custom types and data structures that Cats provides,
including `Id`, `Reader`, `Writer`, and `State`.
These cover a wide range of uses
and many problems can be solved
by using one of these constructs.

Finally, if we do have to implement our own monad instance,
we've have learned about `tailRecM`.
This is an odd wrinkle---a concession
to building a functional programming library
that is stack-safe by default.
We don't need to understand `tailRecM` to understand monads,
but having it around gives us mechanical benefits
that we can be grateful for when writing monadic code.
