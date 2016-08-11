# *Foldable* and *Traverse*

In this chapter we'll look at two type classes
that capture iterating over collections:

- `Foldable` abstracts over the `foldLeft` and `foldRight` operations
  that we're probably all familiar with.

- `Traverse` is a higher-level abstraction that
  uses `Applicatives` to do the heavy lifting typically associated with folds.

We'll start by looking at `Foldable`,
and then look at cases where folding becomes complex and `Traverse` becomes convenient.
