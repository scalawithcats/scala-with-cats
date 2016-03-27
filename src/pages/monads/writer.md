## The *Writer* Monad {#writer-monad}

[`cats.data.Writer`][cats.data.Writer] is a monad that lets us carry a log along with a computation. We can use it to record messages, errors, or additional data about a computation, and extract the log with the final result.

One common use for `Writers` is logging during multi-threaded computations, where traditional logging can result in interleaved messages from different contexts. With a `Writer` the log for the computation is tied to the result, so we can run concurrent computations without mixing log messages.

<div class="callout callout-danger">
TODO: Convert the `Lists` in the examples below to `Vectors`.
</div>

### Creating and Unpacking Writers

A `Writer[W, A]` carries two values: a *log* of type `W` and a *result* of type `A`. We can create a `Writer` from a log and a result as follows:

```scala
import cats.data.Writer
// import cats.data.Writer

Writer(List("It all starts here."), 123)
// res0: cats.data.WriterT[cats.Id,List[String],Int] = WriterT((List(It all starts here.),123))
```

Notice that the type of the writer is actually `WriterT[Id, List[String], Int]` instead of `Writer[List[String], Int]` as we might expect. To remove redundancy, Cats implements the `Writer` monad in terms of another type, `WriterT`. `WriterT` is an example of a new concept called a "monad tranformer". We will introduce monad transformers in the next chapter. For now, try to ignore this detail by reading `WriterT[Id, W, A]` as `Writer[W, A]`.

As with other monads, we can also create a `Writer` using the `pure` syntax. In order to use `pure` the log has to be a type with a `Monoid`. This tells Cats what to use as the initial empty log:

```scala
import cats.std.list._
// import cats.std.list._

import cats.syntax.applicative._
// import cats.syntax.applicative._

type Logged[A] = Writer[List[String], A]
// defined type alias Logged

123.pure[Logged]
// res1: Logged[Int] = WriterT((List(),123))
```

We can create a `Writer` from a log using the `tell` syntax. The `Writer` is initialised with the value `()`:

```scala
import cats.syntax.writer._
// import cats.syntax.writer._

List("msg1", "msg2", "msg3").tell
// res2: cats.data.Writer[List[String],Unit] = WriterT((List(msg1, msg2, msg3),()))
```

If we have both a result and a log, we can create a `Writer` in two ways: using the `Writer.apply` method or the `writer` syntax:

```scala
import cats.syntax.writer._
// import cats.syntax.writer._

val a = Writer(123, List("msg1", "msg2", "msg3"))
// a: cats.data.WriterT[cats.Id,Int,List[String]] = WriterT((123,List(msg1, msg2, msg3)))

val b = 123.writer(List("msg1", "msg2", "msg3"))
// b: cats.data.Writer[List[String],Int] = WriterT((List(msg1, msg2, msg3),123))
```

We can extract the result and log from a `Writer` using the `value` and `written` methods respectively:

```scala
a.value
// res3: cats.Id[List[String]] = List(msg1, msg2, msg3)

a.written
// res4: cats.Id[Int] = 123
```

or both at once using the `run` method:

```scala
b.run
// res5: cats.Id[(List[String], Int)] = (List(msg1, msg2, msg3),123)
```

### Composing and Transforming Writers

When we transform or `map` over a `Writer`, its log is preserved. When we `flatMap`, the logs of the two `Writers` are appended. For this reason it's good practice to use a log type that has an efficient append operation, such as a `Vector`:

```scala
val writer1 = for {
  a <- 10.pure[Logged]
  _ <- List("a", "b", "c").tell
  b <- 32.writer(List("x", "y", "z"))
} yield a + b
// writer1: cats.data.WriterT[cats.Id,List[String],Int] = WriterT((List(a, b, c, x, y, z),42))

writer1.run
// res6: cats.Id[(List[String], Int)] = (List(a, b, c, x, y, z),42)
```

In addition to transforming the result with `map` and `flatMap`, we can transform the log with the `mapWritten` method:

```scala
val writer2 = writer1.mapWritten(_.map(_.toUpperCase))
// writer2: cats.data.WriterT[cats.Id,List[String],Int] = WriterT((List(A, B, C, X, Y, Z),42))

writer2.run
// res7: cats.Id[(List[String], Int)] = (List(A, B, C, X, Y, Z),42)
```

We can also tranform both log and result simultaneously using `bimap` or `mapBoth`. `bimap` takes two function parameters, one for the log and one for the result. `mapBoth` takes a single function of two parameters:

```scala
val writer3 = writer1.bimap(
  log    => log.map(_.toUpperCase),
  result => result * 100
)
// writer3: cats.data.WriterT[cats.Id,List[String],Int] = WriterT((List(A, B, C, X, Y, Z),4200))

writer3.run
// res8: cats.Id[(List[String], Int)] = (List(A, B, C, X, Y, Z),4200)

val writer4 = writer1.mapBoth { (log, result) =>
  val log2    = log.map(_ + "!")
  val result2 = result * 1000
  (log2, result2)
}
// writer4: cats.data.WriterT[cats.Id,List[String],Int] = WriterT((List(a!, b!, c!, x!, y!, z!),42000))

writer4.run
// res9: cats.Id[(List[String], Int)] = (List(a!, b!, c!, x!, y!, z!),42000)
```

Finally, we can clear the log with the `reset` method and swap log and result with the `swap` method:

```scala
val writer5 = writer1.reset
// writer5: cats.data.WriterT[cats.Id,List[String],Int] = WriterT((List(),42))

writer5.run
// res10: cats.Id[(List[String], Int)] = (List(),42)

val writer6 = writer1.swap
// writer6: cats.data.WriterT[cats.Id,Int,List[String]] = WriterT((42,List(a, b, c, x, y, z)))

writer6.run
// res11: cats.Id[(Int, List[String])] = (42,List(a, b, c, x, y, z))
```

### Exercise: Post-Mortem

<div class="callout callout-danger">
TODO: Log errors in `foldMap` whilst recovering from them.
</div>
