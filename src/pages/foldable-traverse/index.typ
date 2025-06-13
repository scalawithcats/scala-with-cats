#import "../stdlib.typ": info, warning, solution, chapter
#chapter[Foldable and Traverse] <sec:foldable-traverse>


In this chapter we'll look at two type classes
that capture iteration over collections:

  - `Foldable` abstracts the familiar
    `foldLeft` and `foldRight` operations;
  - `Traverse` is a higher-level abstraction
    that uses `Applicatives` to iterate
    with less pain than folding.

We'll start by looking at `Foldable`,
and then examine cases where folding becomes complex
and `Traverse` becomes convenient.
