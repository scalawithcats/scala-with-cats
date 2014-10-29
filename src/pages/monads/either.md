---
layout: page
title: Either
---

The Scala standard library has a type `Either`. Scalaz provides an alternative called [`\/`](http://docs.typelevel.org/api/scalaz/nightly/index.html#scalaz.$bslash$div) (reminiscent of the math sign for disjunction). Why have this? It provides a few useful methods, and more useful default behaviour for `flatMap`. `Either` is not biased -- it has no `flatMap` method and you have to decide which side you want to be "correct" side for `flatMap` by taking a left- or right-projection. This is incovenient to use, especially as the convention is that `Right` is the success case. `\/` makes the decision that the right side (called `\/-`) is always the success case and thus it can support a `flatMap` method.

~~~ scala
scala> \/.right(1).flatMap(x => \/.right(x + 2))
res9: scalaz.\/[Nothing,Int] = \/-(3)
~~~

It's inconvenient to construct instances using `\/.left` and `\/.right` so we typically import some syntax to get `left` and `right` as enriched methods.

~~~ scala
import scalaz.syntax.either._
for {
  x <- 1.left[String]
  y <- (x + 2).left[String]
} yield y * 3
// res: scalaz.\/[String,Int] = -\/(9)
~~~

`\/` supports familiar methods like `fold`, `getOrElse`, and `orElse`. We use `fold` to convert a `\/` to some other type. We must supply methods to handle the left and right sides

~~~ scala
scala> 1.right[String].fold(
         l = l => "We failed :(",
         r = r => s"We succeeded with $r"
       )
res12: String = We succeeded with 1
~~~

If we just want the value of the right side or a default we can use `getOrElse` instead.

~~~ scala
scala> 1.right[String].getOrElse(0)
res13: Int = 1

scala> "Error".left[Int].getOrElse(0)
res14: Int = 0
~~~

We can use `orElse` if we want to convert to another `\/`.

~~~ scala
scala> 1.right[String] orElse 2.right[String]
res15: scalaz.\/[String,Int] = \/-(1)

scala> "Error".left[Int] orElse 2.right[String]
res16: scalaz.\/[String,Int] = \/-(2)
~~~

## Fail-Fast Error Handling

The typical usage for `\/` is to implement fail-fast error handling. We can sequence a number of computations using `flatMap`, and if one fails we won't run any more.

### Representing Errors

We could use `type Result[A] = \/[Exception, A]` (or `type Result[A] = Exception \/ A` using infix notation) to represent errors, but then we've lost (almost) all useful information about what kind of errors can occur. I prefer representing errors using an algebraic data type, with one case reserved to hold "other" errors. E.g. imagine we're writing something that manipulates the file system. We might write

~~~ scala
type Result[A] = FileSystemError \/ A
sealed trait FileSystemError
final case object FileNotFound extends FileSystemError
final case object OperationNotAllowed extends FileSystemError
final case class UnexpectedError(exn: Exception) extends FileSystemError
~~~

Then we have the safety of pattern matching on an algebraic data type for handling the errors we expect to occur and be able to handle, and the `UnexpectedError` case to wrap the items we're not expecting or not interested in handling.

### Swapping Control Flow

Occasionally we want to run a sequence of steps until one succeeds. We can model this using `\/` by flipping the left and right cases. The `swap` method provides this.

## Exercises

#### Seeing is Believing

Call `foldMapM` with `\/` as your monad of choice and verify that is really does stop execution as soon an error is encountered. You can force an error by trying to convert a `String` to an `Int` using the method shown below.

~~~ scala
scala> import scalaz.syntax.std.string._

scala> "Cat".parseInt.disjunction
res8: scalaz.\/[NumberFormatException,Int] = -\/(java.lang.NumberFormatException: For input string: "Cat")

scala> "1".parseInt.disjunction
res9: scalaz.\/[NumberFormatException,Int] = \/-(1)
~~~

Here is an example of use:

~~~ scala
scala> Seq("1", "x", "3").foldMapM[Result, Int](_.parseInt.disjunction)
res25: Result[Int] = -\/(java.lang.NumberFormatException: For input string: "x")

scala> Seq("1", "2", "3").foldMapM[Result, Int](_.parseInt.disjunction)
res26: Result[Int] = \/-(6)
~~~

Note that a monad has a single type parameter (it "looks like" `F[A]`) while `\/` has two parameters. To make `\/` have the right kind you'll need to define a type alias fixing one of the types. The syntax for doing so is

~~~ scala
type Alias = ExpandedType
~~~

For example

~~~ scala
type Foo[A] = \/[String, A]
~~~

I've called the type `Result` in my example above.

<div class="solution">
You can verify this by adding some `println` statements in judicious places.
</div>

#### What is Best?

Is this error handling strategy well suited to the task at hand? What other features might we want from error handling?

<div class="solution">
Some points to ponder:

- Error recovery is important when processing large jobs. We don't want to run a job for a day and then find it failed on the last element.

- Error reporting is equally important. We need to know what went wrong, not just that something went wrong.

- In a number of cases we want to collect all the errors, not just the first one we encountered. A typical example is validating a web form. It's a far better experience to report all errors to the user when they submit a form than to report them one at a time.
</div>
