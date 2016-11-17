## *Validated*

By now we are familiar with the fail-fast error handling behaviour of `Xor`.
Furthermore, because `Xor` is a monad,
we know that the semantics of `product` are the same as those for `flatMap`.
In fact, it is impossible for us to design a monadic data type
that implements error accumulating semantics
without breaking the consistency rules between `product` and `flatMap`.

Fortunately, Cats provides another data type called `Validated`
that has an instance of `Cartesian` but *no* instace of `Monad`.
The implementation of `product` is therefore free to accumulate errors:

```tut:book:silent
import cats.Cartesian
import cats.data.Validated
import cats.instances.list._ // Semigroup for List

type ErrorUsingValidated[A] = Validated[List[String], A]
```

```tut:book
Cartesian[ErrorUsingValidated].product(
  Validated.invalid(List("Error 1")),
  Validated.invalid(List("Error 2"))
)
```

`Validated` complements `Xor` nicely.
Between the two we have a complete set of semantics
for combining and sequencing validation rules.

### Creating Instances of *Validated*

`Validated` has two subtypes,
`Validated.Valid` and `Validated.Invalid`,
that correspond loosely to `Xor.Right` and `Xor.Left`.
We can create instances directly using their `apply` methods:

```tut:book
val v = Validated.Valid(123)
val i = Validated.Invalid("Badness")
```

However, it is often easier to use 
the `valid` and `invalid` smart constructors,
which return a type of `Validated`:

```tut:book
val v = Validated.valid[String, Int](123)
val i = Validated.invalid[String, Int]("Badness")
```

As a third option
we can import the `valid` and `invalid` extension methods
from `cats.syntax.validated`:

```tut:book:silent
import cats.syntax.validated._
```

```tut:book
123.valid[String]
"Badness".invalid[Int]
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

### Combining Instances of *Validated*

We can combine instances of `Validated` 
using any of the methods described above:
`product`, `map2..22`, cartesian builder syntax,
and so on.

`Validated` accumulates errors using a `Semigroup`.
We need this to be in scope to summon an instance of `Cartesian`:

```tut:book:silent
type ErrorOr[A] = Validated[String, A]
```

```tut:book:fail
// No Semigroup[String] in scope:
Cartesian[ErrorOr]
```

```tut:book:silent
// Import the Semigroup:
import cats.instances.string._

// Now we can summon a Cartesian:
Cartesian[ErrorOr]
```

Once we can summon the `Cartesian` and `Functor` for our `Validated`,
we can use cartesian builder syntax to accumulate errors:

```tut:book:silent
import cats.syntax.cartesian._
```

```tut:book
(
  "Error 1".invalid[Int] |@|
  "Error 2".invalid[Int]
).tupled
```

As you can see, `String` isn't an ideal type
for accumulating errors.
We commonly use `Lists` or `Vectors` instead:

```tut:book:silent
import cats.instances.vector._ // Semigroup for Vector
```

```tut:book
(
  Vector(404).invalid[Int] |@|
  Vector(500).invalid[Int]
).tupled
```

Cats also provides 
the [`cats.data.NonEmptyList`][cats.data.NonEmptyList]
and [`cats.data.NonEmptyVector`][cats.data.NonEmptyVector]
types that prevent us failing without at least one error:

```tut:book:silent
import cats.data.NonEmptyList
```

```tut:book
(
  NonEmptyList.of("Error 1").invalid[Int] |@|
  NonEmptyList.of("Error 2").invalid[Int]
).tupled
```

### Methods of *Validated*

We can use `map`, `leftMap`, and `bimap` 
to transform the values in a `Validated`:

```tut:book
123.valid.map(_ * 100)

"?".invalid.leftMap(_.toString)

123.valid[String].bimap(_ + "!", _ * 100)

"?".invalid[Int].bimap(_ + "!", _ * 100)
```

We can't `flatMap` because `Validated` isn't a monad.
However, we can convert back and forth between `Validated` and `Xor`
using the `toXor` and `toValidated` methods.
This allows us to switch error-handling semantics on the fly:

```tut:book
"Badness".invalid[Int]
"Badness".invalid[Int].toXor
"Badness".invalid[Int].toXor.toValidated
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

```tut:book:silent
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

```tut:book:silent
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

```tut:book:silent
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

```tut:book:silent
def readUser(data: Map[String, String]): Result[User] =
  Cartesian[Result].product(
    readName(data),
    readAge(data)
  ).map(User.tupled)
```

```tut:book
readUser(Map("name" -> "Dave", "age" -> "37"))

readUser(Map("age" -> "-1"))
```

More idiomatically we can use the cartesian builder syntax:

```tut:book:silent
import cats.syntax.cartesian._

def readUser(data: Map[String, String]): Result[User] = (
  readName(data) |@|
  readAge(data)
).map(User.apply)
```

```tut:book
readUser(Map("name" -> "Dave", "age" -> "37"))

readUser(Map("age" -> "-1"))
```
</div>
