## The *Writer* Monad {#writer-monad}

[`cats.data.Writer`][cats.data.Writer] is a monad that lets us carry a log along with a computation.
We can use it to record messages, errors, or additional data about a computation,
and extract the log with the final result.

One common use for `Writers` is logging during multi-threaded computations,
where traditional logging can result in interleaved messages from different contexts.
With a `Writer` the log for the computation is tied to the result,
so we can run concurrent computations without mixing log messages.


### Creating and Unpacking Writers

A `Writer[W, A]` carries two values: a *log* of type `W` and a *result* of type `A`. We can create a `Writer` from a log and a result as follows:

```tut:book
import cats.data.Writer
import cats.instances.vector._

Writer(Vector("It all starts here."), 123)
```

We've used a `Vector` to hold our log as it has a more efficient append operation than `List`.

Notice that the type of the writer is actually `WriterT[Id, Vector[String], Int]`
instead of `Writer[Vector[String], Int]` as we might expect.
In the spirit of code reuse, Cats implements the `Writer` monad in terms of another type, `WriterT`.
`WriterT` is an example of a new concept called a "monad tranformer".
We will introduce monad transformers in the next chapter.
For now, try to ignore this detail by reading `WriterT[Id, W, A]` as `Writer[W, A]`.

As with other monads, we can also create a `Writer` using the `pure` syntax.
In order to use `pure` the log has to be a type with a `Monoid`.
This tells Cats what to use as the initial empty log:

```tut:book
import cats.syntax.applicative._

type Logged[A] = Writer[Vector[String], A]

123.pure[Logged]
```

We can create a `Writer` from a log using the `tell` syntax.
The `Writer` is initialised with the value `()`:

```tut:book
import cats.syntax.writer._

Vector("msg1", "msg2", "msg3").tell
```

If we have both a result and a log, we can create a `Writer` in two ways:
using the `Writer.apply` method or the `writer` syntax:

```tut:book
import cats.syntax.writer._

val a = Writer(123, Vector("msg1", "msg2", "msg3"))

val b = 123.writer(Vector("msg1", "msg2", "msg3"))
```

We can extract the result and log from a `Writer`
using the `value` and `written` methods respectively:

```tut:book
a.value
a.written
```

or both at once using the `run` method:

```tut:book
val (log, result) = b.run
```

### Composing and Transforming Writers

When we transform or `map` over a `Writer`, its log is preserved.
When we `flatMap`, the logs of the two `Writers` are appended.
For this reason it's good practice to use a log type that has an efficient append operation,
such as a `Vector`.

```tut:book
val writer1 = for {
  a <- 10.pure[Logged]
  _ <- Vector("a", "b", "c").tell
  b <- 32.writer(Vector("x", "y", "z"))
} yield a + b

writer1.run
```

In addition to transforming the result with `map` and `flatMap`,
we can transform the log with the `mapWritten` method:

```tut:book
val writer2 = writer1.mapWritten(_.map(_.toUpperCase))

writer2.run
```

We can also tranform both log and result simultaneously using `bimap` or `mapBoth`.
`bimap` takes two function parameters, one for the log and one for the result.
`mapBoth` takes a single function of two parameters:

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

We mentioned earlier that `Writers` are useful for logging operations in multi-threaded environments.
Let's confirm this by computing (and logging) some factorials.

The `factorial` function below computes a factorial,
printing out the intermediate steps in the calculation as it runs.
The `slowly` helper function ensures this takes a while to run,
even on the very small examples we have to use to fit in these pages,
so we can see the interleaving when we run multiple factorials in parallel.

```tut:book
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
This makes it difficult to see which lines of output come from which computation.

```tut:book
import scala.concurrent._
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

Await.result(Future.sequence(Vector(
  Future(factorial(5)),
  Future(factorial(5))
)), Duration.Inf)
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
```

<!-- HACK: tut isn't capturing stdout from the threads above, so i gone done hacked it. -->

Rewrite `factorial` so it captures the log messages in a `Writer`.
Demonstrate that this allows us to reliably separate the logs for concurrent computations.

<div class="solution">
We'll start by defining a type alias for `Writer` so we can use it with `pure` syntax:

```tut:book
import cats.data.Writer
import cats.syntax.applicative._

type Logged[A] = Writer[Vector[String], A]

42.pure[Logged]
```

We'll import the `tell` syntax as well:

```tut:book
import cats.syntax.writer._

Vector("Message").tell
```

Finally, we'll import the `Semigroup` instance for `Vector`.
We need this to `map` and `flatMap` over `Logged`:

```tut:book
import cats.instances.vector._

41.pure[Logged].map(_ + 1)
```

With these in scope, the definition of `factorial` becomes:

```tut:book
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
