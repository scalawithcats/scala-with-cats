#import "../stdlib.typ": info, warning, exercise, solution
== The Writer Monad 
<writer-monad>


`cats.data.Writer`
is a monad that lets us carry a log along with a computation.
We can use it to record messages, errors,
or additional data about a computation,
and extract the log alongside the final result.

A common use for `Writer` is
recording sequences of steps in multi-threaded computations,
where standard imperative logging techniques
can result in interleaved messages from different contexts.
With `Writer` the log for the computation is tied to the result,
so we can run concurrent computations without mixing logs.

#info(title: [Cats Data Types])[
`Writer` is the first data type we've seen
from the `cats.data` package.
This package provides instances of various type classes
that produce useful semantics.
Other examples from `cats.data` include
the monad transformers that we will see in
@sec:monad-transformers,
and the `Validated` type
we will encounter in @sec:applicatives.
]


=== Creating and Unpacking Writers

A `Writer[W, A]` carries two values:
a _log_ of type `W` and a _result_ of type `A`.
We can create a `Writer` from values of each type as follows:

```scala mdoc
import cats.data.Writer

Writer(Vector(
  "It was the best of times",
  "it was the worst of times"
), 1859)
```

Notice that the type reported on the console
is actually `WriterT[Id, Vector[String], Int]`
instead of `Writer[Vector[String], Int]` as we might expect.
In the spirit of code reuse,
Cats implements `Writer` in terms of another type, `WriterT`.
`WriterT` is an example of a new concept called a *monad transformer*,
which we will cover in @sec:monad-transformers.

Let's try to ignore this detail for now.
`Writer` is a type alias for `WriterT`,
so we can read types like `WriterT[Id, W, A]` as `Writer[W, A]`:

```scala
type Writer[W, A] = WriterT[Id, W, A]
```

For convenience, Cats provides a way of creating `Writers`
specifying only the log or the result.
If we only have a result we can use the standard `pure` syntax.
To do this we must have a `Monoid[W]` in scope
so Cats knows how to produce an empty log.
In the example below we use the `Monoid` instance for `Vector`,
which Scala will find on the `Monoid` companion object.

```scala mdoc
import cats.syntax.all.*

type Logged[A] = Writer[Vector[String], A]

123.pure[Logged]
```

If we have a log and no result
we can create a `Writer[Unit]` using the `tell` syntax.

```scala mdoc
Vector("msg1", "msg2", "msg3").tell
```

If we have both a result and a log,
we can either use `Writer.apply`
or we can use the `writer` syntax.

```scala mdoc
val a = Writer(Vector("msg1", "msg2", "msg3"), 123)
val b = 123.writer(Vector("msg1", "msg2", "msg3"))
```

We can extract the result and log from a `Writer`
using the `value` and `written` methods respectively:

```scala mdoc
val aResult: Int =
  a.value
val aLog: Vector[String] =
  a.written
```

We can extract both values at the same time using the `run` method:

```scala mdoc
val (log, result) = b.run
```


=== Composing and Transforming Writers

The log in a `Writer` is preserved when we `map` or `flatMap` over it.
`flatMap` appends the logs from the source `Writer`
and the result of the user's sequencing function.
For this reason it's good practice to use a log type
that has an efficient append and concatenate operations,
such as a `Vector`.

```scala mdoc
val writer1 = for {
  a <- 10.pure[Logged]
  _ <- Vector("a", "b", "c").tell
  b <- 32.writer(Vector("x", "y", "z"))
} yield a + b

writer1.run
```

In addition to transforming the result with `map` and `flatMap`,
we can transform the log in a `Writer` with the `mapWritten` method.

```scala mdoc
val writer2 = writer1.mapWritten(_.map(_.toUpperCase))

writer2.run
```

We can transform both log and result simultaneously using `bimap` or `mapBoth`.
`bimap` takes two function parameters, one for the log and one for the result.
`mapBoth` takes a single function that accepts two parameters.

```scala mdoc
val writer3 = writer1.bimap(
  log => log.map(_.toUpperCase),
  res => res * 100
)

writer3.run

val writer4 = writer1.mapBoth { (log, res) =>
  val log2 = log.map(_ + "!")
  val res2 = res * 1000
  (log2, res2)
}

writer4.run
```

Finally, we can clear the log with the `reset` method,
and swap log and result with the `swap` method.

```scala mdoc
val writer5 = writer1.reset

writer5.run

val writer6 = writer1.swap

writer6.run
```


#exercise([Show Your Working])

`Writers` are useful for logging operations in multi-threaded environments.
Let's confirm this by computing (and logging) some factorials.

The `factorial` function below computes a factorial
and prints out the intermediate steps as it runs.
The `slowly` helper function ensures this takes a while to run,
even on the very small examples below:

```scala mdoc:silent
def slowly[A](body: => A) =
  try body finally Thread.sleep(100)

def factorial(n: Int): Int = {
  val ans = slowly(if(n == 0) 1 else n * factorial(n - 1))
  println(s"fact $n $ans")
  ans
}
```

Here's the output---a sequence of monotonically increasing values:

```scala mdoc
factorial(5)
```

If we start several factorials in parallel,
the log messages can become interleaved on standard out.
This makes it difficult to see
which messages come from which computation:

```scala
import scala.concurrent.*
import scala.concurrent.ExecutionContext.Implicits.*
import scala.concurrent.duration.*

Await.result(Future.sequence(Vector(
  Future(factorial(5)),
  Future(factorial(5))
)), 5.seconds)
// fact 0 1
// fact 0 1
// fact 1 1
// fact 1 1
// fact 2 2
// fact 2 2
// fact 3 6
// fact 3 6
// fact 4 24
// fact 4 24
// fact 5 120
// fact 5 120
// res: scala.collection.immutable.Vector[Int] =
//   Vector(120, 120)
```

Rewrite `factorial` so it captures
the log messages in a `Writer`.
Demonstrate that this allows us to
reliably separate the logs
for concurrent computations.

#solution[
We'll start by defining a type alias for `Writer`
so we can use it with `pure` syntax:

```scala mdoc:reset-object
import cats.data.Writer
import cats.syntax.all.*

type Logged[A] = Writer[Vector[String], A]

42.pure[Logged]
```

With these declarations, the definition of `factorial` becomes

```scala mdoc:invisible
def slowly[A](body: => A) =
  try body finally Thread.sleep(10)
```
```scala mdoc:silent
def factorial(n: Int): Logged[Int] =
  for {
    ans <- if(n == 0) {
             1.pure[Logged]
           } else {
             slowly(factorial(n - 1).map(_ * n))
           }
    _   <- Vector(s"fact $n $ans").tell
  } yield ans
```

When we call `factorial`,
we now have to `run` the return value
to extract the log and our factorial:

```scala mdoc
val (log, res) = factorial(5).run
```

We can run several `factorials` in parallel as follows,
capturing their logs independently
without fear of interleaving:

```scala
Await.result(Future.sequence(Vector(
  Future(factorial(5)),
  Future(factorial(5))
)).map(_.map(_.written)), 5.seconds)
// res: scala.collection.immutable.Vector[cats.Id[Vector[String]]] = 
//   Vector(
//     Vector(fact 0 1, fact 1 1, fact 2 2, fact 3 6, fact 4 24, fact 5 120), 
//     Vector(fact 0 1, fact 1 1, fact 2 2, fact 3 6, fact 4 24, fact 5 120)
//   )
```
]
