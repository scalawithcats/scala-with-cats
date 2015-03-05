## Either and Disjunction (*\\/*)

The Scala standard library has a type `Either`. Scalaz provides an alternative called [`scalaz.\/`][scalaz.\/] (pronounced "disjunction", reminiscent of the mathematical symbol). Why have this? Aside from providing a few useful methods, the main reason is that `\/` is *right biased*.

### Left and Right Bias

`Either` is unbiased. It has no `map` or `flatMap` method---you have to decide which side you want to be "correct" side for `flatMap` by taking a left- or right-projection:

~~~ scala
Right[String, Int](123).flatMap(x => Right(x * 2))
// <console>:40: error: value flatMap is not a member of scala.util.Right[String,Int]

Right[String, Int](123).right.flatMap(x => Right(x * 2))
// res0: scala.util.Either[String,Int] = Right(246)

Right[String, Int](123).left.flatMap(x => Left(x + "!!!"))
// res1: scala.util.Either[String,Int] = Right(123)
~~~

This makes `Either` incovenient to use as a monad, especially as the convention in most functional languages is that `Right` is the success case. `\/` makes the decision that the right side (called `\/-`) is always the success case and thus it supports `map` and `flatMap` directly:

~~~ scala
\/.right(1).flatMap(x => \/-(x + 2))
// res2: scalaz.\/[Nothing,Int] = \/-(3)
~~~

### Creating Disjunctions

The `\/` object provides factory the `\/.left` and `\/.right` methods as we saw above. However, these are slightly unwieldy due to the finger gymnastics required to write `\/`. We typically import some syntax to get nicer constructors---`left` and `right` as enriched methods:

~~~ scala
import scalaz.syntax.either._

1.right[String].flatMap(x => (x + 2).right)
// res3: scalaz.\/[String,Int] = \/-(3)

for {
  x <- 1.right[String]
  y <- 2.right[String]
} yield x*x + y*y
// res4: scalaz.\/[String,Int] = \/-(5)
~~~

### Transforming Disjunctions

`\/` supports familiar methods like `fold`, `getOrElse`, and `orElse`. We use `fold` to convert a `\/` to some other type, by supplying transform functions for the left and right sides:

~~~ scala
1.right[String].fold(
  l = l => s"FAIL!",
  r = r => s"SUCCESS: $r!"
)
// res5: String = SUCCESS: 1!
~~~

We can use `getOrElse` to extract the right value or return a default:

~~~ scala
1.right[String].getOrElse(0)
// res6: Int = 1

"Error".left[Int].getOrElse(0)
// res7: Int = 0
~~~

We can use `orElse` if we want to default to another `\/`:

~~~ scala
1.right[String] orElse 2.right[String]
// res8: scalaz.\/[String,Int] = \/-(1)

"Error".left[Int] orElse 2.right[String]
// res9: scalaz.\/[String,Int] = \/-(2)
~~~

### Fail-Fast Error Handling

`\/` is typically used to implement fail-fast error handling. We sequence a number of computations using `flatMap`, and if one computation fails the remaining computations are not run:

~~~ scala
for {
  a <- 1.right[String]
  b <- 0.right[String]
  c <- if(b == 0) "DIV0".left[Int] else (a/b).right[String]
} yield c * 100
// res10: scalaz.\/[String,Int] = -\/(DIV0)
~~~

### Representing Errors {#representing-errors}

When using `\/` for error handling, we need to determine what type we want to use to represent errors. We could use `Exception` for this as follows:

~~~ scala
type Result[A] = \/[Exception, A]

// Or using infix notation:
type Result[A] = Exception \/ A
~~~

The problem here is that `Exception` is an extremely broad supertype. We have (almost) no idea about what type of error occurred.

Another approach is to define an algebraic data type to represent the types of error that can occur:

~~~ scala
sealed trait LoginError
final case class UserNotFound(username: String) extends LoginError
final case class PasswordIncorrect(username: String) extends LoginError
trait UnexpectedLoginError extends LoginError

type LoginResult = LoginError \/ User
~~~

This approach solves the problems we saw with `Exception`. It gives us a fixed set of expected error types and a catch-all for anything else that we didn't expect. We also get the safety of exhaustivity checking on any pattern matching we do.

### Swapping Control Flow

Occasionally we want to run a sequence of steps until one succeeds. We can model this using `\/` by flipping the left and right cases. The `swap` method provides this:

~~~ scala
123.right[String].swap
// res0: scalaz.\/[Int,String] = -\/(123)
~~~

### Exercise: What is Best?

Is the error handling strategy in the previous exercises well suited for all purposes? What other features might we want from error handling?

<div class="solution">
This is an open question. It's also kind of a trick question---the answer depends on the semantics we're looking for. Some points to ponder:

- Error recovery is important when processing large jobs. We don't want to run a job for a day and then find it failed on the last element.

- Error reporting is equally important. We need to know what went wrong, not just that something went wrong.

- In a number of cases we want to collect all the errors, not just the first one we encountered. A typical example is validating a web form. It's a far better experience to report all errors to the user when they submit a form than to report them one at a time.
</div>
