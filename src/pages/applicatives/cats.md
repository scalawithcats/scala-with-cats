## Using Applicatives in Cats

Now we have a firm understanding of the semantics of applicatives,
let's look at some of the useful methods and syntax we can use in Cats.

The applicative type class is [`cats.Applicative`][cats.Applicative].
`Applicative` extends `Apply`, which is where the `ap` method is defined.
`Applicative` itself defines `point` as we saw in the discussion of
[the `Monad` type class](#monad-type-class).

### Obtaining Instances

As usual, we obtain instances via `Applicative.apply`:

```scala
import cats.Applicative
// import cats.Applicative

import cats.instances.option._
// import cats.instances.option._

import cats.instances.list._
// import cats.instances.list._

val inc = (x: Int) => x + 2
// inc: Int => Int = <function1>

Applicative[Option].ap(Some(inc))(Some(1))
// res0: Option[Int] = Some(3)
```

In addition to `ap` and `point`, `Applicative` defines several helper methods. The `ap2` through `ap22` methods provide nested calls to `ap` for functions of 2 to 8 arguments:

```scala
val sum3 = (a: Int, b: Int, c: Int) => a + b + c
// sum3: (Int, Int, Int) => Int = <function3>

Applicative[Option].ap3(Some(sum3))(Some(1), Some(2), Some(3))
// res1: Option[Int] = Some(6)
```

<!--
TODO: Applicative extends Functor. Maybe move these later?

In additionn, `map` through `map22` provide versions of `ap` that work with an unwrapped function parameters:

```scala
Applicative[Option].map3(Some(1), Some(2), Some(3))(sum3)
// res2: Option[Int] = Some(6)
```
-->

<!--
TODO: Not present in Cats?

The `lift` through `lift12` methods lift functions into the relevant applicative:

```scala
val optSum3 = Applicative[Option].lift3(sum3)
// <console>:19: error: value lift3 is not a member of cats.Applicative[Option]
//        val optSum3 = Applicative[Option].lift3(sum3)
//                                          ^

optSum3(Some(1), Some(2), Some(3))
// <console>:19: error: not found: value optSum3
//        optSum3(Some(1), Some(2), Some(3))
//        ^
```
-->

Finally, the `sequence` method described in [the monads chapter](#monad-type-class) is also available on `Applicative`:

```scala
val sequence: Option[List[Int]] =
  Applicative[Option].sequence(List(Option(1), Option(2), Option(3)))
// sequence: Option[List[Int]] = Some(List(1, 2, 3))
```

### Applicative Builder Syntax

Cats provides a special *applicative builder* syntax to make using `apply2` and so on more convenient to use. Here's an example:

```scala
import cats.syntax.applicative._
// import cats.syntax.applicative._

def readInt(str: String): Validation[List[String], Int] =
  str.parseInt.leftMap(_ => List(s"Couldn't read $str"))
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
// <console>:22: error: value parseInt is not a member of String
//          str.parseInt.leftMap(_ => List(s"Couldn't read $str"))
//              ^

val readAllInts = (
// <console>:4: error: illegal start of simple expression
// val readAllInts = (
// ^
  readInt("123") |@|
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
// <console>:23: warning: postfix operator |@| should be enabled
// by making the implicit value scala.language.postfixOps visible.
// This can be achieved by adding the import clause 'import scala.language.postfixOps'
// or by setting the compiler option -language:postfixOps.
// See the Scala docs for value scala.language.postfixOps for a discussion
// why the feature should be explicitly enabled.
//          readInt("123") |@|
//                         ^
  readInt("bar") |@|
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
// <console>:23: warning: postfix operator |@| should be enabled
// by making the implicit value scala.language.postfixOps visible.
// This can be achieved by adding the import clause 'import scala.language.postfixOps'
// or by setting the compiler option -language:postfixOps.
// See the Scala docs for value scala.language.postfixOps for a discussion
// why the feature should be explicitly enabled.
//          readInt("bar") |@|
//                         ^
  readInt("baz")
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
)(_ + _ + _)
// <console>:4: error: illegal start of simple expression
// )(_ + _ + _)
// ^
```

`|@|` is an enriched method provided via `cats.syntax.applicative` that creates an `ApplicativeBuilder`. This is an object that has an `apply` method that behaves like `Applicative.apply2`:

```scala
readInt("123") |@| readInt("456")
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^

res5.apply(sum2)
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
// <console>:24: error: not found: value res5
//        res5.apply(sum2)
//        ^
// <console>:24: error: not found: value sum2
//        res5.apply(sum2)
//                   ^
```

In addition to `apply`, `ApplicativeBuilder` has another `|@|` method that builds a new builder for three arguments:

```scala
readInt("123") |@| readInt("456") |@| readInt("789")
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^

res7.apply(sum3)
// <console>:22: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
// <console>:26: error: not found: value res7
//        res7.apply(sum3)
//        ^
```

As you have probably guessed, the three-argument builder has an `apply` method that behaves like `apply3` and a `|@|` method to produce a four-argument builder... and so on up to 12 arguments. This system makes it incredibly easy to lift a function of multiple arguments into the context of an `Applicative`. The syntax is:

```scala
(
  wrappedArg1 |@|
  wrappedArg2 |@|
  wrappedArg3 |@|
  ...
// <console>:10: error: ')' expected but '.' found.
//   ...
//   ^
// <console>:10: error: identifier expected but '.' found.
//   ...
//    ^
// <console>:10: error: identifier expected but '.' found.
//   ...
//     ^
) {
  (arg1, arg2, arg3, ...) =>
// <console>:11: error: illegal start of simple expression
//   (arg1, arg2, arg3, ...) =>
//                      ^
    resultExpression
}
// <console>:21: error: not found: type Validation
//        def readInt(str: String): Validation[List[String], Int] =
//                                  ^
// <console>:26: error: not found: value wrappedArg1
//          wrappedArg1 |@|
//          ^
// <console>:27: error: not found: value wrappedArg2
//          wrappedArg2 |@|
//          ^
// <console>:28: error: not found: value wrappedArg3
//          wrappedArg3 |@|
//          ^
// <console>:30: error: not found: value resultExpression
//            resultExpression
//            ^
// <console>:28: warning: postfix operator |@| should be enabled
// by making the implicit value scala.language.postfixOps visible.
// This can be achieved by adding the import clause 'import scala.language.postfixOps'
// or by setting the compiler option -language:postfixOps.
// See the Scala docs for value scala.language.postfixOps for a discussion
// why the feature should be explicitly enabled.
//          wrappedArg3 |@|
//                      ^
```

Each builder also has a `tupled` method to quickly combine the results into a tuple:

```scala
(
  readInt("123") |@|
  readInt("234") |@|
  readInt("345")
).tupled
```

### Exercise

<div class="callout callout-danger">
  TODO: Applicative builder exercises!
</div>
