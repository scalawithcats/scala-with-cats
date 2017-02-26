## *Either*

Let's look at another useful monadic data type.
The Scala standard library has a type `Either`.
In Scala 2.11 and earlier,
`Either` wasn't technically a monad
because it didn't have `map` and `flatMap` methods.
In Scala 2.12, however, `Either` became *right biased*.

### Left and Right Bias

In Scala 2.11, `Either` was unbiased.
It had no `map` or `flatMap` method:

```scala
// Scala 2.11 example

Right(123).flatMap(x => Right(x * 2))
// <console>:12: error: value flatMap is not a member
//   of scala.util.Right[Nothing,Int]
//        Right(123).flatMap(x => Right(x * 2))
//                   ^
```

Instead of calling `map` or `flatMap` directly,
we had to decide which side we wanted
to be the "correct" side
by taking a left- or right-projection:

```tut:book
// Valid in Scala 2.11 and Scala 2.12

val either1: Either[String, Int] = Right(123)
val either2: Either[String, Int] = Right(321)

either1.right.flatMap(x => Right(x * 2))

either2.left.flatMap(x => Left(x + "!!!"))
```

This made the Scala 2.11 version of `Either`
incovenient to use as a monad.
If we wanted to use for comprehensions,
for example, we had to insert calls to `.right`
in every generator clause:

```tut:book
for {
  a <- either1.right
  b <- either2.right
} yield a + b
```

In Scala 2.12, `Either` was redesigned.
The modern `Either` makes the decision
that the right side is always the success case
and thus supports `map` and `flatMap` directly.
This turns `Either` into a monad
and makes working with it much more pleasant:

```tut:book
for {
  a <- either1
  b <- either2
} yield a + b
```

### Creating Instances

In addition to creating instances of `Left` and `Right` directly,
we can also import the `asLeft` and `asRight` extension methods
from [`cats.syntax.either`][cats.syntax.either]:

```tut:book:silent
import cats.syntax.either._
```

```tut:book
val a = 3.asRight[String]
val b = 4.asRight[String]

for {
  x <- a
  y <- b
} yield x*x + y*y
```

<div class="callout callout-info">
*Smart Constructors and Avoiding Over-Narrowing*

The `asLeft` and `asRight` methods
have advantages over `Left.apply` and `Right.apply`
in terms of type inference.
The following code provides an example:

```tut:book:fail
def countPositive(nums: List[Int]) =
  nums.foldLeft(Right(0)) { (accumulator, num) =>
    if(num > 0) {
      accumulator.map(_ + 1)
    } else {
      Left("Negative. Stopping!")
    }
  }
```

There are two problems here,
both arising because the compiler
chooses the type of `accumulator`
based on the first parameter list to `foldRight`:

1. the type of the accumulator
   ends up being `Right` instead of `Either`;
2. we didn't specify type parameters for `Right.apply`
   so the compiler infers the left parameter as `Nothing`.

Switching to `asRight` avoids both of these problems.
It as a return type of `Either`,
and allows us to completely specify the type
with only one type parameter:

```tut:book:silent
def countPositive(nums: List[Int]) =
  nums.foldLeft(0.asRight[String]) { (accumulator, num) =>
    if(num > 0) {
      accumulator.map(_ + 1)
    } else {
      Left("Negative. Stopping!")
    }
  }
```

```tut:book
countPositive(List(1, 2, 3))
countPositive(List(1, -2, 3))
```
</div>

In addition to `asLeft` and `asRight`,
`cats.syntax.either` also adds
some useful extension methods
to the `Either` companion object.
The `catchOnly` and `catchNonFatal` methods
are for capturing `Exceptions` in instances of `Either`:

```scala
Either.catchOnly[NumberFormatException]("foo".toInt)
Either.catchNonFatal(sys.error("Badness"))
```

There are also methods for creating an `Either`
from other data types:

```scala
Either.fromTry(scala.util.Try("foo".toInt))
Either.fromOption[String, Int](None, "Badness")
```

### Transforming Eithers

`cats.syntax.either` adds
a number of useful methods to `Either`.
We can use `orElse` and `getOrElse` to extract
values from the right side:
the right value or return a default:

```tut:book:silent
import cats.syntax.either._
```

```tut:book
"Error".asLeft[Int].getOrElse(0)
"Error".asLeft[Int].orElse(2.asRight[String])
```

The `ensure` method allows us
to check whether a wrapped value satisfies a predicate:

```tut:book
-1.asRight[String].ensure("Must be non-negative!")(_ > 0)
```

The `recover` and `recoverWith` methods
provide similar error handling to their namesakes on `Future`:

```tut:book
"error".asLeft[String] recover {
  case str: String =>
    "Recovered from " + str
}

"error".asLeft[String] recoverWith {
  case str: String =>
    Right("Recovered from " + str)
}
```

There are `leftMap` and `bimap` methods to complement `map`:

```tut:book
"foo".asLeft[Int].leftMap(_.reverse)
6.asRight[String].bimap(_.reverse, _ * 7)
"bar".asLeft[Int].bimap(_.reverse, _ * 7)
```

The `swap` method lets us exchange left for right:

```tut:book
123.asRight[String]
123.asRight[String].swap
```

Finally, Cats adds a host of conversion methods:
`toOption`, `toList`, `toTry`, `toValidated`, and so on.

### Fail-Fast Error Handling

`Either` is typically used to implement fail-fast error handling.
We sequence a number of computations using `flatMap`,
and if one computation fails the remaining computations are not run:

```tut:book
for {
  a <- 1.asRight[String]
  b <- 0.asRight[String]
  c <- if(b == 0) "DIV0".asLeft[Int] else (a / b).asRight[String]
} yield c * 100
```

### Representing Errors {#representing-errors}

When using `Either` for error handling,
we need to determine
what type we want to use to represent errors.
We could use `Throwable` for this as follows:

```tut:book:silent
type Result[A] = Either[Throwable, A]
```

This gives us similar semantics to `scala.util.Try`.
The problem, however,
is that `Throwable` is an extremely broad supertype.
We have (almost) no idea about what type of error occurred.

Another approach is to define an algebraic data type
to represent the errors that can occur:

```tut:book:silent
sealed trait LoginError extends Product with Serializable

final case class UserNotFound(
  username: String
) extends LoginError

final case class PasswordIncorrect(
  username: String
) extends LoginError

case object UnexpectedError extends LoginError

case class User(username: String, password: String)

type LoginResult = Either[LoginError, User]
```

This approach solves the problems we saw with `Throwable`.
It gives us a fixed set of expected error types
and a catch-all for anything else that we didn't expect.
We also get the safety of exhaustivity checking
on any pattern matching we do:

```tut:book:silent
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

```tut:book
val result1: LoginResult = User("dave", "passw0rd").asRight
val result2: LoginResult = UserNotFound("dave").asLeft

result1.fold(handleError, println)
result2.fold(handleError, println)
```

### Exercise: What is Best?

Is the error handling strategy in the previous exercises
well suited for all purposes?
What other features might we want from error handling?

<div class="solution">
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

- In a number of cases we want to collect all the errors,
not just the first one we encountered.
A typical example is validating a web form.
It's a far better experience to
report all errors to the user when they submit a form
than to report them one at a time.
</div>
