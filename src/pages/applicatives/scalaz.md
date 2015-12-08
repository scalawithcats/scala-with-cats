## Using Applicatives in Scalaz

Now we have a firm understanding of the semantics of applicatives,
let's look at some of the useful methods and syntax we can use in Scalaz.

The applicative type class is [`scalaz.Applicative`][scalaz.Applicative].
`Applicative` extends `Apply`, which is where the `ap` method is defined.
`Applicative` itself defines `point` as we saw in the discussion of
[the `Monad` type class](#monad-type-class).

### Obtaining Instances

As usual, we obtain instances via `Applicative.apply`:

~~~ scala
import scalaz.Applicative
import scalaz.std.option._
import scalaz.std.list._

val inc = (x: Int) => x + 2
// inc: Int => Int = <function1>

Applicative[Option].ap(Some(1))(Some(inc))
// res8: Option[Int] = Some(3)
~~~

In addition to `ap` and `point`, `Applicative` defines several helper methods. The `ap2` through `ap8` methods provide nested calls to `ap` for functions of 2 to 8 arguments:

~~~ scala
val sum3 = (a: Int, b: Int, c: Int) => a + b + c
// sum3: (Int, Int, Int) => Int = <function3>

Applicative[Option].ap3(Some(1), Some(2), Some(3))(Some(sum3))
// res9: Option[Int] = Some(6)
~~~

In addition, `apply` through `apply12` provide versions of `ap` that work with an unwrapped function parameters:

~~~ scala
Applicative[Option].apply3(Some(1), Some(2), Some(3))(sum3)
// res10: Option[Int] = Some(6)
~~~

The `lift` through `lift12` methods lift functions into the relevant applicative:

~~~ scala
val optSum3 = Applicative[Option].lift3(sum3)
// optSum3: (Option[Int], Option[Int], Option[Int]) => Option[Int] = ...

optSum3(Some(1), Some(2), Some(3))
// res11: Option[Int] = Some(6)
~~~

Finally, the `sequence` method described in [the monads chapter](#monad-type-class) is also available on `Applicative`:

~~~ scala
val sequence: Option[List[Int]] =
  Applicative[Option].sequence(List(some(1), some(2), some(3)))
// res12: Option[List[Int]] = Some(List(1, 2, 3))
~~~

### Applicative Builder Syntax

Scalaz provides a special *applicative builder* syntax to make using `apply2` and so on more convenient to use. Here's an example:

~~~ scala
import scalaz.syntax.applicative._

def readInt(str: String): Validation[List[String], Int] =
  str.parseInt.leftMap(_ => List(s"Couldn't read $str"))

val readAllInts = (
  readInt("123") |@|
  readInt("bar") |@|
  readInt("baz")
)(_ + _ + _)
// readAllInts: Validation[List[String], Int] =
//   Failure(List(Couldn't read bar, Couldn't read baz))
~~~

`|@|` is an enriched method provided via `scalaz.syntax.applicative` that creates an `ApplicativeBuilder`. This is an object that has an `apply` method that behaves like `Applicative.apply2`:

~~~ scala
readInt("123") |@| readInt("456")
// Reading 123
// Reading bar
// res5: ApplicativeBuilder[Result,Int,Int] = ...

res5.apply(sum2)
// res6: result[Int] = Pass(579)
~~~

In addition to `apply`, `ApplicativeBuilder` has another `|@|` method that builds a new builder for three arguments:

~~~ scala
readInt("123") |@| readInt("456") |@| readInt("789")
// Reading 123
// Reading 456
// Reading 789
// res7: ApplicativeBuilder[Result,Int,Int]#ApplicativeBuilder3[Int] = ↩
//   scalaz.syntax.ApplicativeBuilder$$anon$1@18379284

res7.apply(sum3)
// res8: Result[Int] = Pass(1368)
~~~

As you have probably guessed, the three-argument builder has a `|@|` method to produce a four-argument builder, and so on up to 12 arguments. This system makes it incredibly easy to lift a function of multiple arguments into the context of an `Applicative`. The syntax is:

~~~ scala
(
  wrappedArg1 |@|
  wrappedArg2 |@|
  wrappedArg3 |@|
  ...
) {
  (arg1, arg2, arg3, ...) =>
    resultExpression
}
~~~

Each builder also has a `tupled` method to quickly combine the results into a tuple:

~~~ scala
(
  readInt("123") |@|
  readInt("234") |@|
  readInt("345")
).tupled
// res9: Validation[List[String],(Int, Int, Int)] =
//   Success((123,234,345))
~~~

### Exercise

<div class="callout callout-danger">
  TODO: Applicative builder exercises!
</div>
