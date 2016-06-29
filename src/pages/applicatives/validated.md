## *Validated*

Cats provides two types for error handling: `Xor`, and a new type called `Validated`.
We've met `Xor` already---it is a monad that provides fail-fast error handling semantics.
In the following example, we never call `fail2` because `fail1` returns and error:

```scala
import cats.data.Xor
// import cats.data.Xor

type FailFast[A] = List[String] Xor A
// defined type alias FailFast

def fail1: FailFast[Int] = {
  println("Calling fail1")
  Xor.left(List("Fail1"))
}
// fail1: FailFast[Int]

def fail2: FailFast[Int] = {
  println("Calling fail2")
  Xor.left(List("Fail2"))
}
// fail2: FailFast[Int]

for {
  a <- fail1
  b <- fail2
} yield a + b
// Calling fail1
// res0: cats.data.Xor[List[String],Int] = Left(List(Fail1))
```

The `Xor` type is a `Cartesian` and an `Applicative` as well as a `Monad`.
However, the definitions of `product` and `ap` are written in terms of `flatMap`,
so we get the same fail-fast semantics:

```scala
import cats.Cartesian
// import cats.Cartesian

Cartesian[FailFast].product(fail1, fail2)
// Calling fail1
// Calling fail2
// res1: FailFast[(Int, Int)] = Left(List(Fail1))
```

Fail-fast is not always the correct type of error handling.
Imagine validating a web form:
we want to check all validation rules and return all errors we find.
Cats models this cumulative style of error handling with a different type called `Validated`.
`Validated` is a `Cartesian` and an `Applicative` but not a `Monad`.
It accumulates errors on failure:

```scala
import cats.data.Validated
// import cats.data.Validated

import cats.instances.list._
// import cats.instances.list._

type FailSlow[A] = Validated[List[String], A]
// defined type alias FailSlow

def fail1: FailSlow[String] = {
  println("Calling fail1")
  Validated.invalid(List("Fail1"))
}
// fail1: FailSlow[String]

def fail2: FailSlow[Int] = {
  println("Calling fail2")
  Validated.invalid(List("Fail2"))
}
// fail2: FailSlow[Int]

Cartesian[FailSlow].product(fail1, fail2)
// Calling fail1
// Calling fail2
// res2: FailSlow[(String, Int)] = Invalid(List(Fail1, Fail2))
```

`Validated` uses a `Semigroup` to accumulate errors.
Remember that a `Semigroup` is the `append` operation of a `Monoid`
without the `zero` component.
Here are a few concrete examples:

```scala
import cats.instances.string._
// import cats.instances.string._

import cats.instances.vector._
// import cats.instances.vector._

type StringOr[A] = Validated[String, A]
// defined type alias StringOr

type ListOr[A]   = Validated[List[String], A]
// defined type alias ListOr

// type VectorOr[A] = Validated[Vector[Int], A]

Cartesian[StringOr].product(
  Validated.invalid("Hello"),
  Validated.invalid("world")
)
// res5: StringOr[(Nothing, Nothing)] = Invalid(Helloworld)

Cartesian[ListOr].product(
  Validated.invalid(List("Hello")),
  Validated.invalid(List("world"))
)
// res6: ListOr[(Nothing, Nothing)] = Invalid(List(Hello, world))

// Cartesian[VectorOr].product(
//   Validated.invalid(Vector(404)),
//   Validated.invalid(Vector(500))
// )
```

### Validated Methods and Syntax

`Validated` has two subtypes,
`Validated.Valid` and `Validated.Invalid`,
that correspond loosely to `Xor.Right` and `Xor.Left`.
We can create instances directly using their `apply` methods:

```scala
val v = Validated.Valid(123)
// v: cats.data.Validated.Valid[Int] = Valid(123)

val i = Validated.Invalid("Badness")
// i: cats.data.Validated.Invalid[String] = Invalid(Badness)
```

or we can use the `valid` and `invalid` smart constructors,
which return a type of `Validated`:

```scala
val v = Validated.valid[String, Int](123)
// v: cats.data.Validated[String,Int] = Valid(123)

val i = Validated.invalid[String, Int]("Badness")
// i: cats.data.Validated[String,Int] = Invalid(Badness)
```

As a third option, we can import enriched `valid` and `invalid` methods
from `cats.syntax.validated`:

```scala
import cats.syntax.validated._
// import cats.syntax.validated._

123.valid[String]
// res11: cats.data.Validated[String,Int] = Valid(123)

"message".invalid[Int]
// res12: cats.data.Validated[String,Int] = Invalid(message)
```

There are also methods on `Validated` to catch certain types of exception.
For example:

```scala
// Catch NumberFormatExceptions:
Validated.catchOnly[NumberFormatException]("foo".toInt)
// res14: cats.data.Validated[NumberFormatException,Int] = Invalid(java.lang.NumberFormatException: For input string: "foo")

// Catch any Exception (not Error):
Validated.catchNonFatal(sys.error("Badness"))
// res16: cats.data.Validated[Throwable,Nothing] = Invalid(java.lang.RuntimeException: Badness)

// Create from a Try:
Validated.fromTry(scala.util.Try("foo".toInt))
// res18: cats.data.Validated[Throwable,Int] = Invalid(java.lang.NumberFormatException: For input string: "foo")

// Create from an Either:
Validated.fromEither[String, Int](Left("Badness"))
// res20: cats.data.Validated[String,Int] = Invalid(Badness)

// Create from an Option:
Validated.fromOption[String, Int](None, "Badness")
// res22: cats.data.Validated[String,Int] = Invalid(Badness)
```

We can convert back and forth between `Validated` and `Xor`
using the `toXor` and `toValidated` methods.
This allows us to switch between
fail-fast and error-accumulating semantics on the fly:

```scala
"Badness".invalid[Int].toXor
// res23: cats.data.Xor[String,Int] = Left(Badness)

"Badness".invalid[Int].toXor.toValidated
// res24: cats.data.Validated[String,Int] = Invalid(Badness)
```

We can `map`, `leftMap`, and `bimap` to
transform the values in a `Validated`:

```scala
123.valid.map(_ * 100)
// res25: cats.data.Validated[Nothing,Int] = Valid(12300)

"?".invalid.leftMap(_.toString)
// res26: cats.data.Validated[String,Nothing] = Invalid(?)

123.valid[String].bimap(_ + "!", _ * 100)
// res27: cats.data.Validated[String,Int] = Valid(12300)

"?".invalid[Int].bimap(_ + "!", _ * 100)
// res28: cats.data.Validated[String,Int] = Invalid(?!)
```

As with `Xor`, we can use the `ensure` method
to fail with a specified error if a predicate does not hold:

```scala
// 123.valid[String].ensure("Negative!")(_ > 0)
```

Finally, we can `getOrElse` or `fold` to extract the values:

```scala
"fail".invalid[Int].getOrElse(0)
// res30: Int = 0

"fail".invalid[Int].fold(_ + "!!!", _.toString)
// res31: String = fail!!!
```

### Exercise: Form Validation

We want to validate an HTML registration form.
We receive request data from the client in a `Map[String, String]`
and we want to parse it to create a `User` object:

```scala
case class User(name: String, age: Int)
// defined class User
```

Our goal is to implement code that
parses the incoming data enforcing the following rules:

 - the name and age must be specified;
 - the name must not be blank;
 - the the age must be a valid non-negative integer.

If all the rules pass our parser we should return a `User`.
If any rules fail, we should return a `List` of the error messages.

Let's model this using the `Validated` data type.
The first step is to determine an error type
and write a type alias called `Result`
to help us use `Validated` with `Cartesian`:

<div class="solution">
The problem description specifies that we need
to return a `List` of error messages in the event of a failure.
`List[String]` is a sensible type to use to report errors.

We need to fix the error type for our `Validated`
to create a type constructor with a single parameter
that we can use with `Cartesian`.
We can do this with a simple type alias:

```scala
type Result[A] = Validated[List[String], A]
// defined type alias Result
```
</div>

Now define two methods to read the `"name"` and `"age"` fields:

- `readName` should take a `Map[String, String]` parameter,
  extract the `"name"` field,
  check the relevant validation rules,
  and return a `Result[String]`;

- `readAge` should take a `Map[String, String]` parameter,
  extract the `"age"` field,
  check the relevant validation rules,
  and return a `Result[Int]`.

Tip: We need a combination of fail-fast and accumulating error handling here.
Use `Xor` for the former and `Validated` for the latter.
You can switch between the two easily using `toXor` and `toValidated`.

<div class="solution">
Here are the methods.
We use `Xor` in places where we need fail-fast semantics
and switch to `Validated` when we need to accumulate errors:

```scala
def getValue(name: String)(data: Map[String, String]): List[String] Xor String =
  Xor.fromOption(data.get(name), List(s"$name field not specified"))
// getValue: (name: String)(data: Map[String,String])cats.data.Xor[List[String],String]

def nonBlank(name: String)(data: String): List[String] Xor String =
  Xor.right(data).
    ensure(List(s"$name cannot be blank"))(_.nonEmpty)
// nonBlank: (name: String)(data: String)cats.data.Xor[List[String],String]

def parseInt(name: String)(data: String): List[String] Xor Int =
  Xor.right(data).
    flatMap(str => Xor.catchOnly[NumberFormatException](str.toInt)).
    leftMap(_ => List(s"$name must be an integer"))
// parseInt: (name: String)(data: String)cats.data.Xor[List[String],Int]

def nonNegative(name: String)(data: Int): List[String] Xor Int =
  Xor.right(data).
    ensure(List(s"$name must be non-negative"))(_ >= 0)
// nonNegative: (name: String)(data: Int)cats.data.Xor[List[String],Int]

def readName(data: Map[String, String]): Result[String] =
  getValue("name")(data).
    flatMap(nonBlank("name")).
    toValidated
// readName: (data: Map[String,String])Result[String]

def readAge(data: Map[String, String]): Result[Int] =
  getValue("age")(data).
    flatMap(nonBlank("age")).
    flatMap(parseInt("age")).
    flatMap(nonNegative("age")).
    toValidated
// readAge: (data: Map[String,String])Result[Int]
```
</div>

Finally, use a `Cartesian` to combine the results of `readName` and `readAge` to produce a `User`:

<div class="solution">
There are a couple of ways to do this.
One option is to use `product` and `map`:

```scala
def readUser(data: Map[String, String]): Result[User] =
  Cartesian[Result].product(
    readName(data),
    readAge(data)
  ).map(User.tupled)
// readUser: (data: Map[String,String])Result[User]

readUser(Map("name" -> "Dave", "age" -> "37"))
// res32: Result[User] = Valid(User(Dave,37))

readUser(Map("age" -> "-1"))
// res33: Result[User] = Invalid(List(name field not specified, age must be non-negative))
```

More idiomatically we can use the cartesian builder syntax:

```scala
import cats.syntax.cartesian._
// import cats.syntax.cartesian._

def readUser(data: Map[String, String]): Result[User] = (
  readName(data) |@|
  readAge(data)
).map(User.apply)
// readUser: (data: Map[String,String])Result[User]

readUser(Map("name" -> "Dave", "age" -> "37"))
// res34: Result[User] = Valid(User(Dave,37))

readUser(Map("age" -> "-1"))
// res35: Result[User] = Invalid(List(name field not specified, age must be non-negative))
```
</div>
