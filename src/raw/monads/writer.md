## The *Writer* Monad {#writer-monad}

[`cats.data.Writer`][cats.data.Writer] is a monad that lets us carry a log along with a computation. We can use it to record messages, errors, or additional data about a computation, and extract the log with the final result.

One common use for `Writers` is logging during multi-threaded computations, where traditional logging can result in interleaved messages from different contexts. With a `Writer` the log for the computation is tied to the result, so we can run concurrent computations without mixing log messages.

<div class="callout callout-danger">
TODO: Convert the `Lists` in the examples below to `Vectors`.
</div>

### Creating and Unpacking Writers

A `Writer[W, A]` carries two values: a *log* of type `W` and a *result* of type `A`. We can create a `Writer` from a log and a result as follows:

```tut:book
import cats.data.Writer

Writer(List("It all starts here."), 123)
```

Notice that the type of the writer is actually `WriterT[Id, List[String], Int]` instead of `Writer[List[String], Int]` as we might expect. To remove redundancy, Cats implements the `Writer` monad in terms of another type, `WriterT`. `WriterT` is an example of a new concept called a "monad tranformer". We will introduce monad transformers in the next chapter. For now, try to ignore this detail by reading `WriterT[Id, W, A]` as `Writer[W, A]`.

As with other monads, we can also create a `Writer` using the `pure` syntax. In order to use `pure` the log has to be a type with a `Monoid`. This tells Cats what to use as the initial empty log:

```tut:book
import cats.std.list._
import cats.syntax.applicative._

type Logged[A] = Writer[List[String], A]

123.pure[Logged]
```

We can create a `Writer` from a log using the `tell` syntax. The `Writer` is initialised with the value `()`:

```tut:book
import cats.syntax.writer._

List("msg1", "msg2", "msg3").tell
```

If we have both a result and a log, we can create a `Writer` in two ways: using the `Writer.apply` method or the `writer` syntax:

```tut:book
import cats.syntax.writer._

val a = Writer(123, List("msg1", "msg2", "msg3"))

val b = 123.writer(List("msg1", "msg2", "msg3"))
```

We can extract the result and log from a `Writer` using the `value` and `written` methods respectively:

```tut:book
a.value
a.written
```

or both at once using the `run` method:

```tut:book
b.run
```

### Composing and Transforming Writers

When we transform or `map` over a `Writer`, its log is preserved. When we `flatMap`, the logs of the two `Writers` are appended. For this reason it's good practice to use a log type that has an efficient append operation, such as a `Vector`:

```tut:book
val writer1 = for {
  a <- 10.pure[Logged]
  _ <- List("a", "b", "c").tell
  b <- 32.writer(List("x", "y", "z"))
} yield a + b

writer1.run
```

In addition to transforming the result with `map` and `flatMap`, we can transform the log with the `mapWritten` method:

```tut:book
val writer2 = writer1.mapWritten(_.map(_.toUpperCase))

writer2.run
```

We can also tranform both log and result simultaneously using `bimap` or `mapBoth`. `bimap` takes two function parameters, one for the log and one for the result. `mapBoth` takes a single function of two parameters:

```tut:book
val writer3 = writer1.bimap(
  log    => log.map(_.toUpperCase),
  result => result * 100
)

writer3.run

val writer4 = writer1.mapBoth { (log, result) =>
  val log2    = log.map(_ + "!")
  val result2 = result * 1000
  (log2, result2)
}

writer4.run
```

Finally, we can clear the log with the `reset` method and swap log and result with the `swap` method:

```tut:book
val writer5 = writer1.reset

writer5.run

val writer6 = writer1.swap

writer6.run
```

### Exercise: Post-Mortem

<div class="callout callout-danger">
TODO: Log errors in `foldMap` whilst recovering from them.
</div>
