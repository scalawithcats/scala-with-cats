---
layout: page
title: Writer
---

Carry a log along with our computation.

`Writer[W, A]`

- `W` is the type of the log. Usually want there to be a semigroup for `W`.
- `A` is the type of the result.

Perhaps we'd like to accumulate a log of errors we encountered during `foldMap`.

Very useful for logging with `Future`, which continually changes thread making conventional logs very difficult to interpret.

When we `flatMap` over a `Writer` instance, the logs are appended together. Good practice to use something with efficient append operation (such as `Vector` or `scalaz.FingerTree`).

To create:

- `set` to set the log on a value
- `tell` to just log without a value

Also available from `scalaz.syntax.writer._`

To get out the log, call `written` on the monad.

Example

~~~ scala
val writer = for {
  v <- 42.set(Vector("The answer"))
  _ <- Vector("Just log something").tell
  w <- (v + 1).set(Vector("One more than the answer"))
} yield w

writer.written.map(println)
~~~

## Exercises

#### Post-Mortem

Log errors in `foldMap` whilst recovering from them.
