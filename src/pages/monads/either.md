## Either

Let's look at another useful monad:
the `Either` type from the Scala standard library.
In Scala 2.11 and earlier,
many people didn't consider `Either` a monad
because it didn't have `map` and `flatMap` methods.
In Scala 2.12, however, `Either` became *right biased*.

### Left and Right Bias

In Scala 2.11, `Either` had no default
`map` or `flatMap` method.
This made the Scala 2.11 version of `Either`
inconvenient to use in for comprehensions.
We had to insert calls to `.right`
in every generator clause:

```tut:book:silent
val either1: Either[String, Int] = Right(10)
val either2: Either[String, Int] = Right(32)
```

```tut:book
for {
  a <- either1.right
  b <- either2.right
} yield a + b
```

In Scala 2.12, `Either` was redesigned.
The modern `Either` makes the decision
that the right side represents the success case
and thus supports `map` and `flatMap` directly.
This makes for comprehensions much more pleasant:

```tut:book
for {
  a <- either1
  b <- either2
} yield a + b
```

Cats back-ports this behaviour to Scala 2.11
via the `cats.syntax.either` import,
allowing us to use right-biased `Either`
in all supported versions of Scala.
In Scala 2.12+ we can either omit this import
or leave it in place without breaking anything:

```tut:book:silent
import cats.syntax.either._ // for map and flatMap

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
import cats.syntax.either._ // for asRight
```

```tut:book
val a = 3.asRight[String]
val b = 4.asRight[String]

for {
  x <- a
  y <- b
} yield x*x + y*y
```

These "smart constructors" have
advantages over `Left.apply` and `Right.apply`
because they return results of type `Either`
instead of `Left` and `Right`.
This helps avoid type inference bugs
caused by over-narrowing,
like the bug in the example below:

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

This code fails to compile for two reasons:

1. the compiler infers the type of the accumulator
   as `Right` instead of `Either`;
2. we didn't specify type parameters for `Right.apply`
   so the compiler infers the left parameter as `Nothing`.

Switching to `asRight` avoids both of these problems.
`asRight` has a return type of `Either`,
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

`cats.syntax.either` adds
some useful extension methods
to the `Either` companion object.
The `catchOnly` and `catchNonFatal` methods
are great for capturing `Exceptions`
as instances of `Either`:

```tut:book
Either.catchOnly[NumberFormatException]("foo".toInt)
Either.catchNonFatal(sys.error("Badness"))
```

There are also methods for creating an `Either`
from other data types:

```tut:book
Either.fromTry(scala.util.Try("foo".toInt))
Either.fromOption[String, Int](None, "Badness")
```

### Transforming Eithers

`cats.syntax.either` also adds
some useful methods for instances of `Either`.
We can use `orElse` and `getOrElse` to extract
values from the right side or return a default:

```tut:book:silent
import cats.syntax.either._
```

```tut:book
"Error".asLeft[Int].getOrElse(0)
"Error".asLeft[Int].orElse(2.asRight[String])
```

The `ensure` method allows us
to check whether the right-hand value
satisfies a predicate:

```tut:book
-1.asRight[String].ensure("Must be non-negative!")(_ > 0)
```

The `recover` and `recoverWith` methods
provide similar error handling to their namesakes on `Future`:

```tut:book
"error".asLeft[Int].recover {
  case str: String => -1
}

"error".asLeft[Int].recoverWith {
  case str: String => Right(-1)
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

### Error Handling

`Either` is typically used to implement fail-fast error handling.
We sequence computations using `flatMap` as usual.
If one computation fails,
the remaining computations are not run:

```tut:book
for {
  a <- 1.asRight[String]
  b <- 0.asRight[String]
  c <- if(b == 0) "DIV0".asLeft[Int]
       else (a / b).asRight[String]
} yield c * 100
```

When using `Either` for error handling,
we need to determine
what type we want to use to represent errors.
We could use `Throwable` for this:

```tut:book:silent
type Result[A] = Either[Throwable, A]
```

This gives us similar semantics to `scala.util.Try`.
The problem, however, is that `Throwable`
is an extremely broad type.
We have (almost) no idea about what type of error occurred.

Another approach is to define an algebraic data type
to represent errors that may occur in our program:

```tut:book:silent
object wrapper {
  sealed trait LoginError extends Product with Serializable

  final case class UserNotFound(username: String)
    extends LoginError

  final case class PasswordIncorrect(username: String)
    extends LoginError

  case object UnexpectedError extends LoginError
}; import wrapper._
```

```tut:book:silent
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

Is the error handling strategy in the previous examples
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

- In a number of cases, we want to collect all the errors,
  not just the first one we encountered.
  A typical example is validating a web form.
  It's a far better experience to
  report all errors to the user when they submit a form
  than to report them one at a time.
</div>
