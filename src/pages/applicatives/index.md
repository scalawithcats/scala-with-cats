# Cartesians and Applicatives {#applicatives}

In previous chapters we saw how functors and monads let us transform values within a context.
While these are both immensely useful abstractions,
there are types of transformation that are inconvenient to represent with `map` and `flatMap`.

One such example is form validation.
When we validate a form we want to return *all* the errors to the user,
not just stop on the first error we encounter.
If we model this with a monad like `Xor`, we fail fast and lose errors.
For example, the code below fails on the first call to `parseInt` and doesn't go any further:

```scala
import cats.data.Xor
// import cats.data.Xor

def parseInt(str: String): String Xor Int =
  Xor.catchOnly[NumberFormatException](str.toInt).
    leftMap(_ => s"Couldn't read $str")
// parseInt: (str: String)cats.data.Xor[String,Int]

for {
  a <- parseInt("a")
  b <- parseInt("b")
  c <- parseInt("c")
} yield (a + b + c)
// res0: cats.data.Xor[String,Int] = Left(Couldn't read a)
```

Another example is the concurrent evaluation of `Futures`.
If we have several long-running independent tasks,
it makes sense to execute them concurrently.
However, monadic comprehension only allows us to run them in sequence.
Even on a multicore CPU,
the code below runs in sequence as you can see from the timestamps:

```scala
import cats.data.Xor
// import cats.data.Xor

import scala.concurrent._
// import scala.concurrent._

import scala.concurrent.duration._
// import scala.concurrent.duration._

import scala.concurrent.ExecutionContext.Implicits.global
// import scala.concurrent.ExecutionContext.Implicits.global

lazy val timestamp0 = System.currentTimeMillis
// timestamp0: Long = <lazy>

def getTimestamp: Long = {
  val timestamp = System.currentTimeMillis - timestamp0
  Thread.sleep(1000)
  timestamp
}
// getTimestamp: Long

val timestamps = for {
  a <- Future(getTimestamp)
  b <- Future(getTimestamp)
  c <- Future(getTimestamp)
} yield (a, b, c)
// timestamps: scala.concurrent.Future[(Long, Long, Long)] = scala.concurrent.impl.Promise$DefaultPromise@1c589952

Await.result(timestamps, Duration.Inf)
// res1: (Long, Long, Long) = (0,1006,2011)
```

To achieve the desired semantics in either of these cases,
we need a way to combine computations *in parallel*.
In this chapter we will look at two type classes that support this pattern:

- *Cartesians* encompass the notion of "zipping" pairs of contexts.
  Cats provides a `CartesianBuilder` syntax that
  combines `Cartesians` and `Functors` to allow users
  to join values within a context using arbitrary functions.

- *Applicative functors*, also known simply as *applicatives*,
  extend cartesian with functor (`map`)
  and a constructor (`pure`).
  
Applicatives are often formulated in terms of function application,
instead of the cartesian formulation that is emphasised in Cats.
This alternative formulation provides a link to other libraries and languages such as Scalaz and Haskell,
so we'll also look at it.
