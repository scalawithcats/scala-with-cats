#import "../stdlib.typ": info, warning, solution, exercise
== Either


Let's look at another useful monad:
the `Either` type from the Scala standard library.
`Either` has two cases, `Left` and `Right`.
By convention `Right` represents a success case,
and `Left` a failure.
When we call `flatMap` on `Either`, computation continues if we have a `Right` case.

```scala mdoc
Right(10).flatMap(a => Right(a + 32))
```

A `Left`, however, stops the computation.

```scala mdoc
Right(10).flatMap(a => Left("Oh no!"))
```

AS these examples suggest,
`Either` is typically used to implement fail-fast error handling.
We sequence computations using `flatMap` as usual.
If one computation fails,
the remaining computations are not run.
Here's an example where we fail if we attempt to divide by zero.

```scala mdoc
for {
  a <- Right(1)
  b <- Right(0)
  c <- if(b == 0) Left("DIV0")
       else Right(a / b)
} yield c * 100
```

We can see `Either` as similar to `Option`,
but it allows us to record some information in the case of failure,
whereas `Option` represents failure by `None`.
In the examples above we used strings to hold information about the cause of failure,
but we can use any type we like.
For example, we could use `Throwable` instead:

```scala mdoc:silent
type Result[A] = Either[Throwable, A]
```

This gives us similar semantics to `scala.util.Try`.
The problem, however, is that `Throwable`
is an extremely broad type.
We have (almost) no idea about what type of error occurred.

Another approach is to define an algebraic data type
to represent errors that may occur in our program:

```scala mdoc:silent
enum LoginError {
  case UserNotFound(username: String)
  case PasswordIncorrect(username: String)
  case UnexpectedError 
}
```

We could use the `LoginError` type along with `Either` as shown below.

```scala mdoc:silent
case class User(username: String, password: String)

type LoginResult = Either[LoginError, User]
```

This approach solves the problems we saw with `Throwable`.
It gives us a fixed set of expected error types
and a catch-all for anything else that we didn't expect.
We also get the safety of exhaustivity checking
on any pattern matching we do:

```scala mdoc:silent
import LoginError.*

// Choose error-handling behaviour based on type:
def handleError(error: LoginError): Unit =
  error match {
    case UserNotFound(u) =>
      println(s"User not found: $u")

    case PasswordIncorrect(u) =>
      println(s"Password incorrect: $u")

    case UnexpectedError =>
      println(s"Unexpected error")
  }
```

Here's an example of use.

```scala mdoc
val result1: LoginResult = Right(User("dave", "passw0rd"))
val result2: LoginResult = Left(UserNotFound("dave"))

result1.fold(handleError, println)
result2.fold(handleError, println)
```

We have much more to say about error handling in @sec:error-handling.


=== Cats Utilities

Cats provides several utilities for working with `Either`.
Here we go over the most useful of them.


==== Creating Instances

In addition to creating instances of `Left` and `Right` directly,
we can also use the `asLeft` and `asRight` extension methods
from Cats. For these methods we need to import the Cats syntax:

```scala mdoc:silent
import cats.syntax.all.* 
```

Now we can construct instances using the extensions.

```scala mdoc
val a = 3.asRight[String]
val b = 4.asRight[String]

for {
  x <- a
  y <- b
} yield x*x + y*y
```

These "smart constructors" have
advantages over `Left.apply` and `Right.apply`.
They return results of type `Either`
instead of `Left` and `Right`.
This helps avoid type inference problems
caused by over-narrowing,
like the issue in the example below:

```scala mdoc:fail
def countPositive(nums: List[Int]) =
  nums.foldLeft(Right(0)) { (accumulator, num) =>
    if(num > 0) {
      accumulator.map(_ + 1)
    } else {
      Left("Negative. Stopping!")
    }
  }
```

This code fails to compile for two reasons:

+ the compiler infers the type of the accumulator
   as `Right` instead of `Either`;
+ we didn't specify type parameters for `Right.apply`
   so the compiler infers the left parameter as `Nothing`.

Switching to `asRight` avoids both of these problems.
`asRight` has a return type of `Either`,
and allows us to completely specify the type
with only one type parameter:

```scala mdoc:silent
def countPositive(nums: List[Int]) =
  nums.foldLeft(0.asRight[String]) { (accumulator, num) =>
    if(num > 0) {
      accumulator.map(_ + 1)
    } else {
      Left("Negative. Stopping!")
    }
  }
```

```scala mdoc
countPositive(List(1, 2, 3))
countPositive(List(1, -2, 3))
```

The Cats syntax also adds
some useful extension methods
to the `Either` companion object.
The `catchOnly` and `catchNonFatal` methods
are great for capturing `Exceptions`
as instances of `Either`:

```scala mdoc
Either.catchOnly[NumberFormatException]("foo".toInt)
Either.catchNonFatal(sys.error("Badness"))
```

There are also methods for creating an `Either`
from other data types:

```scala mdoc
Either.fromTry(scala.util.Try("foo".toInt))
Either.fromOption[String, Int](None, "Badness")
```


==== Transforming Eithers

Cats syntax also adds
some useful methods for instances of `Either`.

The `ensure` method allows us
to check whether the right-hand value
satisfies a predicate:

```scala mdoc
-1.asRight[String].ensure("Must be non-negative!")(_ > 0)
```

The `recover` and `recoverWith` methods
provide similar error handling to their namesakes on `Future`:

```scala mdoc
"error".asLeft[Int].recover {
  case _: String => -1
}

"error".asLeft[Int].recoverWith {
  case _: String => Right(-1)
}
```

There are `leftMap` and `bimap` methods to complement `map`:

```scala mdoc
"foo".asLeft[Int].leftMap(_.reverse)
6.asRight[String].bimap(_.reverse, _ * 7)
"bar".asLeft[Int].bimap(_.reverse, _ * 7)
```

The `swap` method lets us exchange left for right:

```scala mdoc
123.asRight[String]
123.asRight[String].swap
```

Finally, Cats adds a host of conversion methods:
`toOption`, `toList`, `toTry`, `toValidated`, and so on.




#exercise([What is Best?])

Is the error handling strategy in the previous examples
well suited for all purposes?
What other features might we want from error handling?

#solution[
This is an open question.
It's also kind of a trick question---the
answer depends on the semantics we're looking for.
Some points to ponder:

- Error recovery is important when processing large jobs.
  We don't want to run a job for a day
  and then find it failed on the last element.

- Error reporting is equally important.
  We need to know what went wrong,
  not just that something went wrong.

- In a number of cases, we want to collect all the errors,
  not just the first one we encountered.
  A typical example is validating a web form.
  It's a far better experience to
  report all errors to the user when they submit a form
  than to report them one at a time.
]
