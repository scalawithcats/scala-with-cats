## Summary

In this chapter we've seen monads up-close.
We saw that `flatMap` can be viewed as sequencing computations,
giving the order in which operations must happen.
In this view, `Option` represents a computation that can fail without an error message;
`Either` and `Xor` represent computations that can fail with a message;
`List` represents multiple possible results; and
`Future` represents a computation that may produce a value at some point in the future.

In this chapter we've also seen some of the custom data structures that Cats provides.
We've mentioned `Xor` in the paragraph above.
We've also seen `Id`, `Reader`, `Writer`, and `State`.
These cover a wide range of uses
and many problems can be solved by using one of the data structures that Cats comes with.

Finally, if we do have to implement our own monad instance,
we've have learned about `tailRecM` and `RecursiveTailRecM`.
