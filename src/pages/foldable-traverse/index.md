# *Foldable* and *Traverse*

In this chapter we'll look at two type classes
that capture iterating over collections:

  - `Foldable` abstracts over the familiar `foldLeft` and `foldRight` operations;
  - `Traverse` is a higher-level abstraction 
    that uses `Applicatives` to iterate with less pain than with folds.

We'll start by looking at `Foldable`,
and then examine cases where folding becomes complex
and `Traverse` becomes convenient.
