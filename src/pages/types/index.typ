#import "../stdlib.typ": chapter
#chapter[Types as Constraints] <sec:types>

Our very first strategy is using *types as constraints*.
We'll start by discussing two different ways we can think of types:
by a type is, sometimes known as an *extensional* view; and
by what a type can do, sometimes known as an *intensional* view.
The latter view is less familiar,
but is necessary to get the most from an expressive type system
and is the core of the strategy.
Hence we'll spend some time elaborating on this idea and discussing examples.

Once we understand the concept of types as constraints,
we'll look at a Scala 3 feature, known as *opaque types*.
Opaque types allow us to create a distinct type that has the same runtime representation as another type.
As such, they provide a way to decouple representation from operations,
and allow us to work with a purely intensional view.
