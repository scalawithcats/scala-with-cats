---
layout: page
title: Writer
---

Carry a log along with our computation.

`Writer[W, A]`

- `W` is the type of the log. Usually want there to be a semigroup for `W`.
- `A` is the type of the result.

When we `flatMap` over a `Writer` instance, the logs are appended together. Good practice to use something with efficient append operation (such as `Vector` or `scalaz.FingerTree`).

To create:

- `set` to set the log on a value
- `tell` to just log without a value

Also available from `scalaz.syntax.writer._`

To get out the log, call `written` on the monad.

## Exercises

#### Post-Mortem

Log errors in `foldMap` whilst recovering from them.
