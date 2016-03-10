## Writer

[`cats.data.Writer`][cats.data.Writer] is a monadic data type that lets us carry a log along with a computation.

One common use for `Writers` is logging during multi-threaded computations, where traditional logging can result in interleaved messages from different threads. With a `Writer`, the log for the computation is carried around with the result as a single, coherent sequence, and can be inspected in isolation once the computation is complete.

<div class="callout callout-danger">
TODO: Convert the `Lists` in the examples below to `Vectors`.
</div>

### Creating Writers

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
// <console>:18: error: object writer is not a member of package cats.syntax
//        import cats.syntax.writer._
//                           ^
List("msg1", "msg2", "msg3").tell
// <console>:19: error: value tell is not a member of List[String]
//        List("msg1", "msg2", "msg3").tell
//                                     ^
```

If we have both a result and a log, we can create a `Writer` in two ways: using the `Writer.apply` method or the `writer` syntax:

```scala
import cats.syntax.writer._
// <console>:18: error: object writer is not a member of package cats.syntax
//        import cats.syntax.writer._
//                           ^
Writer(123, List("msg1", "msg2", "msg3"))
// res3: cats.data.WriterT[cats.Id,Int,List[String]] = WriterT((123,List(msg1, msg2, msg3)))

123.writer(List("msg1", "msg2", "msg3"))
// <console>:19: error: value writer is not a member of Int
//        123.writer(List("msg1", "msg2", "msg3"))
//            ^
```

### Composing and Transforming Writers

When we transform or `map` over a `Writer`, its log is preserved. When we `flatMap`, the logs of the two `Writers` are appended. For this reason it's good practice to use a log type that has an efficient append operation, such as a `Vector`:

```scala
val answer = for {
  a <- 10.pure[Logger]
  _ <- List("a", "b", "c").tell
  c <- 32.writer(List("x", "y", "z"))
} yield a + b
// <console>:19: error: not found: type Logger
//          a <- 10.pure[Logger]
//                       ^
// <console>:20: error: value tell is not a member of List[String]
//          _ <- List("a", "b", "c").tell
//                                   ^
// <console>:21: error: value writer is not a member of Int
//          c <- 32.writer(List("x", "y", "z"))
//                  ^
```

In addition to transforming the result with `map` and `flatMap`, we can transform the log with the `mapWritten` method:

```scala
answer.mapWritten(_.map(_.toUpperCase))
// <console>:6: error: ')' expected but '.' found.
// answer.mapWritten(_.map(_.toUpperCase))
//                    ^
// <console>:6: error: '<-' expected but ')' found.
// answer.mapWritten(_.map(_.toUpperCase))
//                                       ^
```

We can tranform the log and result simultaneously using `bimap` or `mapBoth`. `bimap` takes two function parameters, one for the log and one for the result. `mapBoth` takes a single function of two parameters:

```scala
answer.bimap(
  log    => log.map(_.toUpperCase),
// <console>:7: error: ')' expected but '=>' found.
//   log    => log.map(_.toUpperCase),
//          ^
  result => result * 100
// <console>:7: error: ')' expected but '=>' found.
//   result => result * 100
//          ^
)

answer.mapBoth { (log, result) =>
// <console>:9: error: '<-' expected but ';' found.
// answer.mapBoth { (log, result) =>
// ^
// <console>:9: error: '<-' expected but '{' found.
// answer.mapBoth { (log, result) =>
//                ^
  val log2    = log.map(_ + "!")
// <console>:9: error: '<-' expected but ';' found.
//   val log2    = log.map(_ + "!")
// ^
// <console>:9: warning: val keyword in for comprehension is deprecated
//   val log2    = log.map(_ + "!")
//               ^
  val result2 = result * 1000
// <console>:9: error: '<-' expected but ';' found.
//   val result2 = result * 1000
// ^
// <console>:9: warning: val keyword in for comprehension is deprecated
//   val result2 = result * 1000
//               ^
  (log2, result2)
// <console>:9: error: '<-' expected but ';' found.
//   (log2, result2)
// ^
}
// <console>:9: error: '<-' expected but '}' found.
// }
// ^
```

Finally, we can clear the log with the `reset` method and swap log and result with the `swap` method:

```scala
answer.reset
// <console>:9: error: '<-' expected but ';' found.
// answer.reset
// ^
answer.swap
// <console>:9: error: '<-' expected but ';' found.
// answer.swap
// ^
```

### Unpacking Writers

When we are done chaining computations we can extract the result and log from a `Writer` using the `value` and `written` methods respectively:

```scala
answer.value
// <console>:9: error: '<-' expected but ';' found.
// answer.value
// ^
answer.written
// <console>:9: error: '<-' expected but ';' found.
// answer.written
// ^
```

or both at once using the `run` method:

```scala
answer.run
// <console>:9: error: '<-' expected but ';' found.
// answer.run
// ^
```

### Exercise: Post-Mortem

<div class="callout callout-danger">
TODO: Log errors in `foldMap` whilst recovering from them.
</div>
