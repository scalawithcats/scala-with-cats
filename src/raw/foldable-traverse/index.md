# *Foldable* and *Traverse*

In this chapter we'll look at two type classes
that capture different ways of iterating over collections:

- `Foldable` is a type class that
  abstracts over the `foldLeft` and `foldRight` operations
  that many people discover along-side general combinators like `map` and `filter`;

- `Traverse` is a higher-level abstraction
  that uses `Applicatives` to do the heavy lifting typically associated with folds.

We'll start by looking at `Foldable`,
and then look at cases where folding becomes complex and `Traverse` becomes convenient.