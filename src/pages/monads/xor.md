## *Either* and *Xor*

Let's look at another useful monadic data type.
The Scala standard library has a type `Either`.
Cats provides an alternative called [`cats.data.Xor`][cats.data.Xor].
Why have this? Aside from providing a few useful methods,
the main reason is that `Xor` is *right biased*.

<div class="callout callout-info">
*Cats data types*

`Xor` is the first concrete data type we've seen in Cats.
Cats provides numerous data types,
all of which exist in the [`cats.data`][cats.data.package] package.
Other examples include the monad transformers that we will see in the next chapter,
and the [`Validated`][cats.data.Validated] type
that we will see in the chapter on [applicatives](#applicatives).
</div>

### Left and Right Bias

`Either` is unbiased. It has no `map` or `flatMap` method:

```tut:book:fail
Right(123).flatMap(x => Right(x * 2))
```

Instead of calling `map` or `flatMap` directly,
we have to decide which side we want to be the "correct" side
by taking a left- or right-projection:

```tut:book
val either: Either[String, Int] = Right(123)

either.right.flatMap(x => Right(x * 2))
either.left.flatMap(x => Left(x + "!!!"))
```

This makes `Either` incovenient to use as a monad.
`Xor` makes the decision that the right side
is always the success case and thus it supports `map` and `flatMap` directly:

```tut:book:silent
import cats.data.Xor
```

```tut:book
Xor.right(1).flatMap(x => Xor.right(x + 2))
```

### Creating Xors

The `Xor` object provides the `Xor.left` and `Xor.right` factory methods as we saw above.
However, these are slightly unwieldy
due to the finger gymnastics required to write `Xor`.
We typically import syntax from [`cats.syntax.xor`][cats.syntax.xor]
to get nicer constructors---`left` and `right` as enriched methods:

```tut:book:silent
import cats.syntax.xor._
```

```tut:book
val a = 3.right[String]
val b = 4.right[String]

for {
  x <- a
  y <- b
} yield x*x + y*y
```

### Transforming Xors

`Xor` supports familiar methods like `fold`, `getOrElse`, and `orElse`.
We use `fold` to convert a `Xor` to some other type,
by supplying transform functions for the left and right sides:

```tut:book
1.right[String].fold(
  left  => s"FAIL!",
  right => s"SUCCESS: $right!"
)
```

We can use `getOrElse` to extract the right value or return a default:

```tut:book
1.right[String].getOrElse(0)

"Error".left[Int].getOrElse(0)
```

We can use `orElse` if we want to default to another `Xor`:

```tut:book
1.right[String] orElse 2.right[String]

"Error".left[Int] orElse 2.right[String]
```

`Xor` also has a useful method called `ensure`
that checks whether the wrapped value satisfies a predicate
and fails with a specified error if it does not:

```tut:book
-1.right[String].ensure("Must be non-negative!")(_ > 0)
```

### Fail-Fast Error Handling

`Xor` is typically used to implement fail-fast error handling.
We sequence a number of computations using `flatMap`,
and if one computation fails the remaining computations are not run:

```tut:book
for {
  a <- 1.right[String]
  b <- 0.right[String]
  c <- if(b == 0) "DIV0".left[Int] else (a / b).right[String]
} yield c * 100
```

### Representing Errors {#representing-errors}

When using `Xor` for error handling,
we need to determine what type we want to use to represent errors.
We could use `Throwable` for this as follows:

```tut:book:silent
// Using prefix notation:
type Result[A] = Xor[Throwable, A]

// Or using infix notation:
type Result[A] = Throwable Xor A
```

This gives us similar semantics to `Try` from the Scala standard library.
The problem, however, is that `Throwable` is an extremely broad supertype.
We have (almost) no idea about what type of error occurred.

Another approach is to define an algebraic data type
to represent the types of error that can occur:

```tut:book:silent
case class User(username: String, password: String)

sealed trait LoginError

final case class UserNotFound(
  username: String
) extends LoginError

final case class PasswordIncorrect(
  username: String
) extends LoginError

case object UnexpectedError extends LoginError

type LoginResult = LoginError Xor User
```

This approach solves the problems we saw with `Throwable`.
It gives us a fixed set of expected error types
and a catch-all for anything else that we didn't expect.
We also get the safety of exhaustivity checking on any pattern matching we do:

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
val result1: LoginResult = User("dave", "passw0rd").right
val result2: LoginResult = UserNotFound("dave").left

result1.fold(handleError, println)
result2.fold(handleError, println)
```

### Swapping Control Flow

Occasionally we want to run a sequence of steps until one succeeds.
We can model this using `Xor` by flipping the left and right cases.
The `swap` method provides this:

```tut:book
val a = 123.right[String]
val b = a.swap
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
