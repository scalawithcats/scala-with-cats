## Either and *Xor*

The Scala standard library has a type `Either`. Cats provides an alternative called [`cats.data.Xor`][cats.data.Xor]. Why have this? Aside from providing a few useful methods, the main reason is that `Xor` is *right biased*.

### Left and Right Bias

`Either` is unbiased. It has no `map` or `flatMap` method:

```scala
Right(123).flatMap(x => Right(x * 2))
// <console>:12: error: value flatMap is not a member of scala.util.Right[Nothing,Int]
//        Right(123).flatMap(x => Right(x * 2))
//                   ^
```

Instead of calling `map` or `flatMap` directly, we have to decide which side we want to be the "correct" side by taking a left- or right-projection:

```scala
val either: Either[String, Int] = Right(123)
// either: Either[String,Int] = Right(123)

either.right.flatMap(x => Right(x * 2))
// res1: scala.util.Either[String,Int] = Right(246)

either.left.flatMap(x => Left(x + "!!!"))
// res2: scala.util.Either[String,Int] = Right(123)
```

This makes `Either` incovenient to use as a monad, especially as the convention in most functional languages is that `Right` side represents. `Xor` makes the decision that the right side is always the success case and thus it supports `map` and `flatMap` directly:

```scala
import cats.data.Xor
// import cats.data.Xor

Xor.right(1).flatMap(x => Xor.right(x + 2))
// res3: cats.data.Xor[Nothing,Int] = Right(3)
```

### Creating Xors

The `Xor` object provides factory the `Xor.left` and `Xor.right` methods as we saw above. However, these are slightly unwieldy due to the finger gymnastics required to write `Xor`. We typically import syntax from [`cats.syntax.xor`][cats.syntax.xor] to get nicer constructors---`left` and `right` as enriched methods:

```scala
import cats.syntax.xor._
// import cats.syntax.xor._

val a = 3.right[String]
// a: cats.data.Xor[String,Int] = Right(3)

val b = 4.right[String]
// b: cats.data.Xor[String,Int] = Right(4)

for {
  x <- a
  y <- b
} yield x*x + y*y
// res4: cats.data.Xor[String,Int] = Right(25)
```

### Transforming Xors

`Xor` supports familiar methods like `fold`, `getOrElse`, and `orElse`. We use `fold` to convert a `Xor` to some other type, by supplying transform functions for the left and right sides:

```scala
1.right[String].fold(
  left  => s"FAIL!",
  right => s"SUCCESS: $right!"
)
// res5: String = SUCCESS: 1!
```

We can use `getOrElse` to extract the right value or return a default:

```scala
1.right[String].getOrElse(0)
// res6: Int = 1

"Error".left[Int].getOrElse(0)
// res7: Int = 0
```

We can use `orElse` if we want to default to another `Xor`:

```scala
1.right[String] orElse 2.right[String]
// res8: cats.data.Xor[String,Int] = Right(1)

"Error".left[Int] orElse 2.right[String]
// res9: cats.data.Xor[String,Int] = Right(2)
```

### Fail-Fast Error Handling

`Xor` is typically used to implement fail-fast error handling. We sequence a number of computations using `flatMap`, and if one computation fails the remaining computations are not run:

```scala
for {
  a <- 1.right[String]
  b <- 0.right[String]
  c <- if(b == 0) "DIV0".left[Int] else (a / b).right[String]
} yield c * 100
// res10: cats.data.Xor[String,Int] = Left(DIV0)
```

### Representing Errors {#representing-errors}

When using `Xor` for error handling, we need to determine what type we want to use to represent errors. We could use `Throwable` for this as follows:

```scala
type Result[A] = Xor[Throwable, A]
// defined type alias Result

// Or using infix notation:
type Result[A] = Throwable Xor A
// defined type alias Result
```

This gives us similar semantics to `Try` from the Scala standard library. The problem, however, is that `Throwable` is an extremely broad supertype. We have (almost) no idea about what type of error occurred.

Another approach is to define an algebraic data type to represent the types of error that can occur:

```scala
case class User(username: String, password: String)
// defined class User

sealed trait LoginError
// defined trait LoginError

final case class UserNotFound(username: String) extends LoginError
// defined class UserNotFound

final case class PasswordIncorrect(username: String) extends LoginError
// defined class PasswordIncorrect

trait UnexpectedError extends LoginError
// defined trait UnexpectedError

type LoginResult = LoginError Xor User
// defined type alias LoginResult
```

This approach solves the problems we saw with `Throwable`. It gives us a fixed set of expected error types and a catch-all for anything else that we didn't expect. We also get the safety of exhaustivity checking on any pattern matching we do:

```scala
// Choose precise error-handling behaviour based on the error type:
def handleError(error: LoginError): Unit = error match {
  case UserNotFound(u)      => println(s"User not found: $u")
  case PasswordIncorrect(u) => println(s"Password incorrect: $u")
  case _ : UnexpectedError  => println(s"Unexpected error")
}
// handleError: (error: LoginError)Unit

val result1: LoginResult = User("dave", "passw0rd").right
// result1: LoginResult = Right(User(dave,passw0rd))

val result2: LoginResult = UserNotFound("dave").left
// result2: LoginResult = Left(UserNotFound(dave))

result1.fold(handleError, println)
// User(dave,passw0rd)

result2.fold(handleError, println)
// User not found: dave
```

### Swapping Control Flow

Occasionally we want to run a sequence of steps until one succeeds. We can model this using `Xor` by flipping the left and right cases. The `swap` method provides this:

```scala
val a = 123.right[String]
// a: cats.data.Xor[String,Int] = Right(123)

val b = a.swap
// b: cats.data.Xor[Int,String] = Left(123)
```

### Exercise: What is Best?

Is the error handling strategy in the previous exercises well suited for all purposes? What other features might we want from error handling?

<div class="solution">
This is an open question. It's also kind of a trick question---the answer depends on the semantics we're looking for. Some points to ponder:

- Error recovery is important when processing large jobs. We don't want to run a job for a day and then find it failed on the last element.

- Error reporting is equally important. We need to know what went wrong, not just that something went wrong.

- In a number of cases we want to collect all the errors, not just the first one we encountered. A typical example is validating a web form. It's a far better experience to report all errors to the user when they submit a form than to report them one at a time.
</div>
