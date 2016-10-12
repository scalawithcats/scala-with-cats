## The *Writer* Monad {#writer-monad}

[`cats.data.Writer`][cats.data.Writer]
is a monad that lets us carry a log along with a computation.
We can use it to record messages, errors,
or additional data about a computation,
and extract the log with the final result.

One common use for `Writers` is 
recording sequences of steps in multi-threaded computations,
where standard imperative logging techniques 
can result in interleaved messages from different contexts.
With `Writer` the log for the computation is tied to the result,
so we can run concurrent computations without mixing logs.

### Creating and Unpacking Writers

A `Writer[W, A]` carries two values: 
a *log* of type `W` and a *result* of type `A`.
We can create a `Writer` from values of each type as follows:

```tut:book:silent
import cats.data.Writer
import cats.instances.vector._
```

```tut:book
Writer(Vector("It was the best of times", "It was the worst of times"), 123)
```

We've used a `Vector` as the log in this example 
as it is a sequence structure with an efficient append operation.

Notice that the type of the writer reported on the console
is actually `WriterT[Id, Vector[String], Int]`
instead of `Writer[Vector[String], Int]` as we might expect.
In the spirit of code reuse,
Cats implements `Writer` in terms of another type, `WriterT`.
`WriterT` is an example of a new concept called a "monad tranformer",
which we will cover in the next chapter.

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
so Cats knows how to produce an empty log:

```tut:book:silent:reset
import cats.syntax.applicative._ // `pure` method

type Logged[A] = Writer[Vector[String], A]
```

```tut:book
123.pure[Logged]
```

If we have a log and no result,
we can create a `Writer[Unit]` using the `tell` syntax
from [`cats.syntax.writer`][cats.syntax.writer]:

```tut:book:silent
import cats.syntax.writer._
```

```tut:book
Vector("msg1", "msg2", "msg3").tell
```

If we have both a result and a log,
in addition to using `Writer.apply` as we did above 
we can use the `writer` syntax 
from [`cats.syntax.writer`][cats.syntax.writer]:

```tut:book:silent
import cats.syntax.writer._
```

```tut:book
val a = Writer(123, Vector("msg1", "msg2", "msg3"))
val b = 123.writer(Vector("msg1", "msg2", "msg3"))
```

We can extract the result and log from a `Writer`
using the `value` and `written` methods respectively:

```tut:book
a.value
a.written
```

or we can extract log and result at the same time
using the `run` method:

```tut:book
val (log, result) = b.run
```

### Composing and Transforming Writers

The log in a `Writer` is preserved when we `map` or `flatMap` over it.
`flatMap` actually appends the logs 
from the source `Writer` and the result of the user's sequencing function.
For this reason it's good practice to use a log type
that has an efficient append and concatenate operations,
such as a `Vector`:

```tut:book
val writer1 = for {
  a <- 10.pure[Logged]
  _ <- Vector("a", "b", "c").tell
  b <- 32.writer(Vector("x", "y", "z"))
} yield a + b

writer1.run
```

In addition to transforming the result with `map` and `flatMap`,
we can transform the log in a `Writer` with the `mapWritten` method:

```tut:book
val writer2 = writer1.mapWritten(_.map(_.toUpperCase))

writer2.run
```

We can tranform both log and result simultaneously using `bimap` or `mapBoth`.
`bimap` takes two function parameters, one for the log and one for the result.
`mapBoth` takes a single function that accepts two parameters:

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

Finally, we can clear the log with the `reset` method
and swap log and result with the `swap` method:

```tut:book
val writer5 = writer1.reset

writer5.run

val writer6 = writer1.swap

writer6.run
```

### Exercise: Show Your Working

`Writers` are useful for logging operations in multi-threaded environments.
Let's confirm this by computing (and logging) some factorials.

The `factorial` function below computes a factorial,
printing out the intermediate steps in the calculation as it runs.
The `slowly` helper function ensures this takes a while to run,
even on the very small examples we need in this book 
to fit the output on the page:

```tut:book:silent
def slowly[A](body: => A) =
  try body finally Thread.sleep(100)

def factorial(n: Int): Int = {
  val ans = slowly(if(n == 0) 1 else n * factorial(n - 1))

  println(s"fact $n $ans")

  ans
}
```

Here's the output---a sequence of monotonically increasing values:

```tut:book
factorial(5)
```

If we start several factorials in parallel,
the log messages can become interleaved on standard out.
This makes it difficult to see 
which messages come from which computation.

```tut:book:silent
import scala.concurrent._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

Await.result(Future.sequence(Vector(
  Future(factorial(3)),
  Future(factorial(3))
)), Duration.Inf)
// fact 0 1
// fact 0 1
// fact 1 1
// fact 1 1
// fact 2 2
// fact 2 2
// fact 3 6
// fact 3 6
// res14: scala.collection.immutable.Vector[Int] = Vector(120, 120)
```

<!-- HACK: tut isn't capturing stdout from the threads above, so i gone done hacked it. -->

Rewrite `factorial` so it captures the log messages in a `Writer`.
Demonstrate that this allows us to
reliably separate the logs for concurrent computations.

<div class="solution">
We'll start by defining a type alias for `Writer` so we can use it with `pure` syntax:

```tut:book:silent
import cats.data.Writer
import cats.syntax.applicative._

type Logged[A] = Writer[Vector[String], A]
```

```tut:book
42.pure[Logged]
```

We'll import the `tell` syntax as well:

```tut:book:silent
import cats.syntax.writer._
```

```tut:book
Vector("Message").tell
```

Finally, we'll import the `Semigroup` instance for `Vector`.
We need this to `map` and `flatMap` over `Logged`:

```tut:book:silent
import cats.instances.vector._
```

```tut:book
41.pure[Logged].map(_ + 1)
```

With these in scope, the definition of `factorial` becomes:

```tut:book:silent
def factorial(n: Int): Logged[Int] = {
  if(n == 0) {
    1.pure[Logged]
  } else {
    for {
      a <- slowly(factorial(n - 1))
      _ <- Vector(s"fact $n ${a*n}").tell
    } yield a * n
  }
}
```

Now, when we call `factorial`, we have to `run` the result
to extract the log and our factorial:

```tut:book
val (log, result) = factorial(5).run
```

We can run several `factorials` in parallel as follows,
capturing their logs independently without fear of interleaving:

```tut:book
val Vector((logA, ansA), (logB, ansB)) =
  Await.result(Future.sequence(Vector(
    Future(factorial(5).run),
    Future(factorial(5).run)
  )), Duration.Inf)
```
</div>
