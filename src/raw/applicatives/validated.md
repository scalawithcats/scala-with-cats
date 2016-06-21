## *Validated*

Cats provides two types for error handling: `Xor`, and a new type called `Validated`.
We've met `Xor` already---it is a monad that provides fail-fast error handling semantics.
In the following example, we never call `fail2` because `fail1` returns and error:

```tut:book
import cats.data.Xor

type FailFast[A] = List[String] Xor A

def fail1: FailFast[Int] = {
  println("Calling fail1")
  Xor.left(List("Fail1"))
}

def fail2: FailFast[Int] = {
  println("Calling fail2")
  Xor.left(List("Fail2"))
}

for {
  a <- fail1
  b <- fail2
} yield a + b
```

The `Xor` type is a `Cartesian` and an `Applicative` as well as a `Monad`.
However, the definitions of `product` and `ap` are written in terms of `flatMap`,
so we get the same fail-fast semantics:

```tut:book
import cats.Cartesian

Cartesian[FailFast].product(fail1, fail2)
```

Fail-fast is not always the correct type of error handling.
Imagine validating a web form:
we want to check all validation rules and return all errors we find.
Cats models this cumulative style of error handling with a different type called `Validated`.
`Validated` is a `Cartesian` and an `Applicative` but not a `Monad`.
It accumulates errors on failure:

```tut:book
import cats.data.Validated
import cats.std.list._

type FailSlow[A] = Validated[List[String], A]

def fail1: FailSlow[String] = {
  println("Calling fail1")
  Validated.invalid(List("Fail1"))
}

def fail2: FailSlow[Int] = {
  println("Calling fail2")
  Validated.invalid(List("Fail2"))
}

Cartesian[FailSlow].product(fail1, fail2)
```

`Validated` uses a `Semigroup` to accumulate errors.
Remember that a `Semigroup` is the `append` operation of a `Monoid`
without the `zero` component.
Here are a few concrete examples:

```tut:book
import cats.std.string._
import cats.std.vector._

type StringOr[A] = Validated[String, A]
type ListOr[A]   = Validated[List[String], A]
// type VectorOr[A] = Validated[Vector[Int], A]

Cartesian[StringOr].product(
  Validated.invalid("Hello"),
  Validated.invalid("world")
)

Cartesian[ListOr].product(
  Validated.invalid(List("Hello")),
  Validated.invalid(List("world"))
)

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

```tut:book
val v = Validated.Valid(123)
val i = Validated.Invalid("Badness")
```

or we can use the `valid` and `invalid` smart constructors,
which return a type of `Validated`:

```tut:book
val v = Validated.valid[String, Int](123)
val i = Validated.invalid[String, Int]("Badness")
```

As a third option, we can import enriched `valid` and `invalid` methods
from `cats.syntax.validated`:

```tut:book
import cats.syntax.validated._

123.valid[String]
"message".invalid[Int]
```

There are also methods on `Validated` to catch certain types of exception.
For example:

```tut:book
// Catch NumberFormatExceptions:
Validated.catchOnly[NumberFormatException]("foo".toInt)

// Catch any Exception (not Error):
Validated.catchNonFatal(sys.error("Badness"))

// Create from a Try:
Validated.fromTry(scala.util.Try("foo".toInt))

// Create from an Either:
Validated.fromEither[String, Int](Left("Badness"))

// Create from an Option:
Validated.fromOption[String, Int](None, "Badness")
```

We can convert back and forth between `Validated` and `Xor`
using the `toXor` and `toValidated` methods.
This allows us to switch between
fail-fast and error-accumulating semantics on the fly:

```tut:book
"Badness".invalid[Int].toXor
"Badness".invalid[Int].toXor.toValidated
```

We can `map`, `leftMap`, and `bimap` to
transform the values in a `Validated`:

```tut:book
123.valid.map(_ * 100)

"?".invalid.leftMap(_.toString)

123.valid[String].bimap(_ + "!", _ * 100)

"?".invalid[Int].bimap(_ + "!", _ * 100)
```

As with `Xor`, we can use the `ensure` method
to fail with a specified error if a predicate does not hold:

```tut:book
// 123.valid[String].ensure("Negative!")(_ > 0)
```

Finally, we can `getOrElse` or `fold` to extract the values:

```tut:book
"fail".invalid[Int].getOrElse(0)

"fail".invalid[Int].fold(_ + "!!!", _.toString)
```

### Exercise: Form Validation

We want to validate an HTML registration form.
We receive request data from the client in a `Map[String, String]`
and we want to parse it to create a `User` object:

```tut:book
case class User(name: String, age: Int)
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

```tut:book
type Result[A] = Validated[List[String], A]
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

```tut:book
def getValue(name: String)(data: Map[String, String]): List[String] Xor String =
  Xor.fromOption(data.get(name), List(s"$name field not specified"))

def nonBlank(name: String)(data: String): List[String] Xor String =
  Xor.right(data).
    ensure(List(s"$name cannot be blank"))(_.nonEmpty)

def parseInt(name: String)(data: String): List[String] Xor Int =
  Xor.right(data).
    flatMap(str => Xor.catchOnly[NumberFormatException](str.toInt)).
    leftMap(_ => List(s"$name must be an integer"))

def nonNegative(name: String)(data: Int): List[String] Xor Int =
  Xor.right(data).
    ensure(List(s"$name must be non-negative"))(_ >= 0)

def readName(data: Map[String, String]): Result[String] =
  getValue("name")(data).
    flatMap(nonBlank("name")).
    toValidated

def readAge(data: Map[String, String]): Result[Int] =
  getValue("age")(data).
    flatMap(nonBlank("age")).
    flatMap(parseInt("age")).
    flatMap(nonNegative("age")).
    toValidated
```
</div>

Finally, use a `Cartesian` to combine the results of `readName` and `readAge` to produce a `User`:

<div class="solution">
There are a couple of ways to do this.
One option is to use `product` and `map`:

```tut:book
def readUser(data: Map[String, String]): Result[User] =
  Cartesian[Result].product(
    readName(data),
    readAge(data)
  ).map(User.tupled)

readUser(Map("name" -> "Dave", "age" -> "37"))

readUser(Map("age" -> "-1"))
```

More idiomatically we can use the cartesian builder syntax:

```tut:book
import cats.syntax.cartesian._

def readUser(data: Map[String, String]): Result[User] = (
  readName(data) |@|
  readAge(data)
).map(User.apply)

readUser(Map("name" -> "Dave", "age" -> "37"))

readUser(Map("age" -> "-1"))
```
</div>
