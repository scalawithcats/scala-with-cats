#import "../stdlib.typ": info, warning, solution, narrative-cite
== Conclusions


In this chapter we've seen monads up-close.
We saw that `flatMap` can be viewed
as an operator for sequencing computations,
dictating the order in which operations must happen.
From this viewpoint, `Option` represents a computation
that can fail without an error message,
`Either` represents computations that can fail with a message,
`List` represents multiple possible results,
and `Future` represents a computation
that may produce a value at some point in the future.

We've also seen some of
the custom types and data structures that Cats provides,
including `Id`, `Reader`, `Writer`, and `State`.
These cover a wide range of use cases.

Finally, in the unlikely event that
we have to implement a custom monad,
we've learned about defining our own instance using `tailRecM`.
`tailRecM` is an odd wrinkle that is a concession to building
a functional programming library that is stack-safe by default.
We don't need to understand `tailRecM` to understand monads,
but having it around gives us benefits
of which we can be grateful when writing monadic code.

#narrative-cite(<wadler92:essence>) introduced monads to functional programming. It describes monads in terms of `bind` and `unit`, which in Scala we call `flatMap` and `pure` respectively. It has several examples of interpreters built using monads, and relates monads to continuation-passing style, which we first met in @sec:interpreters:cps.
