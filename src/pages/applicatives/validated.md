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

```scala
import cats.data.Validated
// import cats.data.Validated

import cats.instances.list._
// import cats.instances.list._

import cats.syntax.cartesian._
// import cats.syntax.cartesian._

(
  Validated.invalid(List("Fail1")) |@|
  Validated.invalid(List("Fail2"))
).tupled
// res0: cats.data.Validated[List[String],(Nothing, Nothing)] = Invalid(List(Fail1, Fail2))
```

`Validated` accumulates errors using a `Semigroup` (the `append` part of a `Monoid`).
This means we can use any `Monoid` as an error type, including `Lists`, `Vectors`, and `Strings`.
Here are a few concrete examples:

```scala
import cats.Cartesian
// import cats.Cartesian

type StringOr[A] = Validated[String, A]
// defined type alias StringOr

type ListOr[A] = Validated[List[String], A]
// defined type alias ListOr

type VectorOr[A] = Validated[Vector[Int], A]
// defined type alias VectorOr

// Import the Semigroup for String:
import cats.instances.string._
// import cats.instances.string._

// Concatenate error strings:
Cartesian[StringOr].product(
  Validated.invalid("Hello"),
  Validated.invalid("world")
)
// res3: StringOr[(Nothing, Nothing)] = Invalid(Helloworld)

// Import the Semigroup for List:
import cats.instances.list._
// import cats.instances.list._

// Combine lists of errors:
Cartesian[ListOr].product(
  Validated.invalid(List("Hello")),
  Validated.invalid(List("world"))
)
// res6: ListOr[(Nothing, Nothing)] = Invalid(List(Hello, world))

// Import the Semigroup for Vector:
import cats.instances.vector._
// import cats.instances.vector._

// Combine vectors of errors:
Cartesian[VectorOr].product(
  Validated.invalid(Vector(404)),
  Validated.invalid(Vector(500))
)
// res9: VectorOr[(Nothing, Nothing)] = Invalid(Vector(404, 500))
```

### Creating Instances

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

However, it is better to use the `valid` and `invalid` smart constructors,
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
// res10: cats.data.Validated[String,Int] = Valid(123)

"message".invalid[Int]
// res11: cats.data.Validated[String,Int] = Invalid(message)
```

Finally, there are a variety of methods on `Validated` to created
instances from exceptions, `Either`, `Option`, and so on:

```scala
// Catch NumberFormatExceptions:
Validated.catchOnly[NumberFormatException]("foo".toInt)
// res13: cats.data.Validated[NumberFormatException,Int] = Invalid(java.lang.NumberFormatException: For input string: "foo")

// Catch any Exception (but not java.lang.Error):
Validated.catchNonFatal(sys.error("Badness"))
// res15: cats.data.Validated[Throwable,Nothing] = Invalid(java.lang.RuntimeException: Badness)

// Create from a Try:
Validated.fromTry(scala.util.Try("foo".toInt))
// res17: cats.data.Validated[Throwable,Int] = Invalid(java.lang.NumberFormatException: For input string: "foo")

// Create from an Either:
Validated.fromEither[String, Int](Left("Badness"))
// res19: cats.data.Validated[String,Int] = Invalid(Badness)

// Create from an Option:
Validated.fromOption[String, Int](None, "Badness")
// res21: cats.data.Validated[String,Int] = Invalid(Badness)
```

### Switching between *Validated* and *Xor*

We can convert back and forth between `Validated` and `Xor`
using the `toXor` and `toValidated` methods:

```scala
import cats.data.Xor
// import cats.data.Xor

"Badness".invalid[Int].toXor
// res22: cats.data.Xor[String,Int] = Left(Badness)

"Badness".invalid[Int].toXor.toValidated
// res23: cats.data.Validated[String,Int] = Invalid(Badness)
```

This allows us to switch error-handling semantics on the fly:

```scala
// Accumulate errors in an Xor:
(
  Xor.left[List[String], Int](List("Fail 1")).toValidated |@|
  Xor.left[List[String], Int](List("Fail 2")).toValidated
).tupled.toXor
// res25: cats.data.Xor[List[String],(Int, Int)] = Left(List(Fail 1, Fail 2))

// Sequence operations on Validated using flatMap:
for {
  a <- Validated.invalid[List[String], Int](List("Fail 1")).toXor
  b <- Validated.invalid[List[String], Int](List("Fail 2")).toXor
} yield (a, b)
// res27: cats.data.Xor[List[String],(Int, Int)] = Left(List(Fail 1))
```

### Methods of *Validated*

We can `map`, `leftMap`, and `bimap` to transform the values in a `Validated`:

```scala
123.valid.map(_ * 100)
// res28: cats.data.Validated[Nothing,Int] = Valid(12300)

"?".invalid.leftMap(_.toString)
// res29: cats.data.Validated[String,Nothing] = Invalid(?)

123.valid[String].bimap(_ + "!", _ * 100)
// res30: cats.data.Validated[String,Int] = Valid(12300)

"?".invalid[Int].bimap(_ + "!", _ * 100)
// res31: cats.data.Validated[String,Int] = Invalid(?!)
```

As with `Xor`, we can use the `ensure` method
to fail with a specified error if a predicate does not hold:

```scala
// 123.valid[String].ensure("Negative!")(_ > 0)
```

Finally, we can `getOrElse` or `fold` to extract the values:

```scala
"fail".invalid[Int].getOrElse(0)
// res33: Int = 0

"fail".invalid[Int].fold(_ + "!!!", _.toString)
// res34: String = fail!!!
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
import cats.data.Xor
// import cats.data.Xor

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
// res35: Result[User] = Valid(User(Dave,37))

readUser(Map("age" -> "-1"))
// res36: Result[User] = Invalid(List(name field not specified, age must be non-negative))
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
// res37: Result[User] = Valid(User(Dave,37))

readUser(Map("age" -> "-1"))
// res38: Result[User] = Invalid(List(name field not specified, age must be non-negative))
```
</div>
