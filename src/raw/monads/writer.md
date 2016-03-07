## Writer

[`cats.data.Writer`][cats.data.Writer] is a monadic data type that lets us carry a log along with a computation.

One common use for `Writers` is logging during multi-threaded computations, where traditional logging can result in interleaved messages from different threads. With a `Writer`, the log for the computation is carried around with the result as a single, coherent sequence, and can be inspected in isolation once the computation is complete.

<div class="callout callout-danger">
TODO: Convert the `Lists` in the examples below to `Vectors`.
</div>

### Creating Writers

A `Writer[W, A]` carries two values: a *log* of type `W` and a *result* of type `A`. We can create a `Writer` from a log and a result as follows:

```tut:book
import cats.data.Writer

Writer(List("It all starts here."), 123)
```

Notice that the type of the writer is actually `WriterT[Id, List[String], Int]` instead of `Writer[List[String], Int]` as we might expect. To remove redundancy, Cats implements the `Writer` monad in terms of another type, `WriterT`. `WriterT` is an example of a new concept called a "monad tranformer". We will introduce monad transformers in the next chapter. For now, try to ignore this detail by reading `WriterT[Id, W, A]` as `Writer[W, A]`.

As with other monads, we can also create a `Writer` using the `pure` syntax. In order to use `pure` the log has to be a type with a `Monoid`. This tells Cats what to use as the initial empty log:

```tut:book
import cats.data.WriterT
import cats.std.list._
import cats.syntax.applicative._

type Logged[A] = Writer[List[String], A]

321.pure[Logged]
```

<div class="callout callout-danger">
TODO: Describe `set` and `tell` constructors/syntax.
They're currently implemented on the `WriterT` companion object, but not on `Writer` and not as syntax.
</div>

### Composing and Transforming Writers

When we `flatMap` over a `Writer` instance, the logs are appended together. For this reason it's good practice to use a log type that has an efficient append operation, such as a `Vector`. Logs are also preserved through `map` and other transformations:

```tut:book
val answer = for {
  a <- Writer(List("a", "b", "c"), 10)
  b <- Writer(List("x", "y", "z"), 32)
} yield a + b
```

In addition to transforming the result with `map` and `flatMap`, we can transform the log with the `mapWritten` method:

```tut:book
answer.mapWritten(_.map(_.toUpperCase))
```

We can tranform the log and result simultaneously using `bimap` or `mapBoth`. `bimap` takes two function parameters, one for the log and one for the result. `mapBoth` takes a single function of two parameters:

```tut:book
answer.bimap(
  log    => log.map(_.toUpperCase),
  result => result * 100
)

answer.mapBoth { (log, result) =>
  val log2    = log.map(_ + "!")
  val result2 = result * 1000
  (log2, result2)
}
```

Finally, we can clear the log with the `reset` method and swap log and result with the `swap` method:

```tut:book
answer.reset
answer.swap
```

### Unpacking Writers

When we are done chaining computations we can extract the result and log from a `Writer` using the `value` and `written` methods respectively:

```tut:book
answer.value
answer.written
```

or both at once using the `run` method:

```tut:book
answer.run
```

### Exercise: Post-Mortem

<div class="callout callout-danger">
TODO: Log errors in `foldMap` whilst recovering from them.
</div>
