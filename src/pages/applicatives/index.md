# Cartesians and Applicatives {#applicatives}

In previous chapters we saw
how functors and monads let us transform values using `map` and `flatMap`.
While functors and monads are both immensely useful abstractions,
there are types of transformation
that are inconvenient to represent with these methods.

One such example is form validation.
When we validate a form we want to return *all* the errors to the user,
not simply stop on the first error we encounter.
If we model this with a monad like `Xor`, we fail fast and lose errors.
For example, the code below fails on the first call to `parseInt`
and doesn't go any further:

```tut:book:silent
import cats.data.Xor

def parseInt(str: String): String Xor Int =
  Xor.catchOnly[NumberFormatException](str.toInt).
    leftMap(_ => s"Couldn't read $str")
```

```tut:book
for {
  a <- parseInt("a")
  b <- parseInt("b")
  c <- parseInt("c")
} yield (a + b + c)
```

Another example is the concurrent evaluation of `Futures`.
If we have several long-running independent tasks,
it makes sense to execute them concurrently.
However, monadic comprehension only allows us to run them in sequence.
Even on a multicore CPU,
the code below runs in sequence as you can see from the timestamps:

```tut:book:silent
import cats.data.Xor
import scala.concurrent._
import scala.concurrent.duration._
import scala.concurrent.ExecutionContext.Implicits.global

lazy val timestamp0 = System.currentTimeMillis

def getTimestamp: Long = {
  val timestamp = System.currentTimeMillis - timestamp0
  Thread.sleep(1000)
  timestamp
}

val timestamps = for {
  a <- Future(getTimestamp)
  b <- Future(getTimestamp)
  c <- Future(getTimestamp)
} yield (a, b, c)
```

```tut:book
Await.result(timestamps, Duration.Inf)
```

`map` and `flatMap` aren't quite capable
of capturing what we want here because
they make the assumption that each computation
is *dependent* on the previous one:

```scala
// context2 is dependent on value1:
context1.flatMap(value1 => context2)
```

The calls to `parseInt` and `Future.apply` above
are *independent* of one another,
but `map` and `flatMap` can't exploit this.
We need a weaker construct---one that doesn't guarantee sequencing---to
achieve the result we want.
In this chapter we will look at two type classes that support this pattern:

  - *Cartesians* encompass the notion of "zipping" pairs of contexts.
    Cats provides a `CartesianBuilder` syntax that
    combines `Cartesians` and `Functors` to allow users
    to join values within a context using arbitrary functions.

  - *Applicative functors*, also known as `Applicatives`,
    extend `Cartesian` and `Functor` and provide
    a way of applying functions to parameters within a context.
    `Applicative` is the source of the `pure` method
    we introduced in Chapter [@sec:monads].

Applicatives are often formulated in terms of function application,
instead of the cartesian formulation that is emphasised in Cats.
This alternative formulation provides a link
to other libraries and languages such as Scalaz and Haskell.
We'll take a look a different formulations of Applicative,
as well as the relationships between
`Cartesian`, `Functor`, `Applicative`, and `Monad`,
towards the end of the chapter.
