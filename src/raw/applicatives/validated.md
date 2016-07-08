## *Validated*

Cats provides two types for error handling:
`Xor`, which we have already seen,
and `Validated`, which we introduce here.

We've met `Xor` and its fail-fast semantics already.
However, fail-fast semantics aren't always the best choice.
When validating a web form, for example, we want to accumulate errors for all invalid fields,
not just the first one we find.

Cats provides another data type called `Validated` that is an applicative, *not* a monad.
The implementation of `product` for `Validated` is therefore free to accumulate errors.
Here's an example:

```tut:book
import cats.data.Validated
import cats.instances.list._
import cats.syntax.cartesian._

(
  Validated.invalid(List("Fail1")) |@|
  Validated.invalid(List("Fail2"))
).tupled
```

`Validated` accumulates errors using a `Semigroup` (the `append` part of a `Monoid`).
This means we can use any `Monoid` as an error type, including `Lists`, `Vectors`, and `Strings`.
Here are a few concrete examples:

```tut:book
import cats.Cartesian

type StringOr[A] = Validated[String, A]
type ListOr[A] = Validated[List[String], A]
type VectorOr[A] = Validated[Vector[Int], A]

// Import the Semigroup for String:
import cats.instances.string._

// Concatenate error strings:
Cartesian[StringOr].product(
  Validated.invalid("Hello"),
  Validated.invalid("world")
)

// Import the Semigroup for List:
import cats.instances.list._

// Combine lists of errors:
Cartesian[ListOr].product(
  Validated.invalid(List("Hello")),
  Validated.invalid(List("world"))
)

// Import the Semigroup for Vector:
import cats.instances.vector._

// Combine vectors of errors:
Cartesian[VectorOr].product(
  Validated.invalid(Vector(404)),
  Validated.invalid(Vector(500))
)
```

### Creating Instances

`Validated` has two subtypes,
`Validated.Valid` and `Validated.Invalid`,
that correspond loosely to `Xor.Right` and `Xor.Left`.
We can create instances directly using their `apply` methods:

```tut:book
val v = Validated.Valid(123)
val i = Validated.Invalid("Badness")
```

However, it is better to use the `valid` and `invalid` smart constructors,
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

Finally, there are a variety of methods on `Validated` to created
instances from exceptions, `Either`, `Option`, and so on:

```tut:book
// Catch NumberFormatExceptions:
Validated.catchOnly[NumberFormatException]("foo".toInt)

// Catch any Exception (but not java.lang.Error):
Validated.catchNonFatal(sys.error("Badness"))

// Create from a Try:
Validated.fromTry(scala.util.Try("foo".toInt))

// Create from an Either:
Validated.fromEither[String, Int](Left("Badness"))

// Create from an Option:
Validated.fromOption[String, Int](None, "Badness")
```

### Switching between *Validated* and *Xor*

We can convert back and forth between `Validated` and `Xor`
using the `toXor` and `toValidated` methods:

```tut:book
"Badness".invalid[Int].toXor
"Badness".invalid[Int].toXor.toValidated
```

This allows us to switch error-handling semantics on the fly:

```tut:book
// Accumulate errors in an Xor:
(
  Xor.left(List("Fail 1")).toValidated |@|
  Xor.left(List("Fail 2")).toValidated
).tupled.toXor

// Sequence operations on Validated using flatMap:
for {
  a <- Validated.invalid(List("Fail 1")).toXor
  b <- Validated.invalid(List("Fail 2")).toXor
} yield (a, b)
```

### Methods of *Validated*

We can `map`, `leftMap`, and `bimap` to transform the values in a `Validated`:

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
import cats.data.Xor

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
