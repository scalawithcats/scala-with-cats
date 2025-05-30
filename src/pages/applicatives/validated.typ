#import "../stdlib.typ": info, warning, solution
== Validated


By now we are familiar with
the fail-fast error handling behaviour of `Either`.
Furthermore, because `Either` is a monad,
we know that the semantics of `product`
are the same as those for `flatMap`.
In fact, it is impossible for us
to design a monadic data type
that implements error accumulating semantics
without breaking the consistency
of these two methods.

Fortunately, Cats provides
a data type called `Validated`
that has an instance of `Semigroupal`
but _no_ instance of `Monad`.
The implementation of `product`
is therefore free to accumulate errors:

```scala mdoc:silent
import cats.Semigroupal
import cats.data.Validated
import cats.instances.list._ // for Monoid

type AllErrorsOr[A] = Validated[List[String], A]
```

```scala mdoc
Semigroupal[AllErrorsOr].product(
  Validated.invalid(List("Error 1")),
  Validated.invalid(List("Error 2"))
)
```

`Validated` complements `Either` nicely.
Between the two we have support for
both of the common types of error handling:
fail-fast and accumulating.

=== Creating Instances of Validated


`Validated` has two subtypes,
`Validated.Valid` and `Validated.Invalid`,
that correspond loosely to `Right` and `Left`.
There are a lot of ways to
create instances of these types.
We can create them directly
using their `apply` methods:

```scala mdoc
val v = Validated.Valid(123)
val i = Validated.Invalid(List("Badness"))
```

However, it is often easier to use
the `valid` and `invalid` smart constructors,
which widen the return type to `Validated`:

```scala mdoc:invisible:reset-object
import cats.data.Validated
import cats.instances.list._ // for Monoid

type AllErrorsOr[A] = Validated[List[String], A]
```
```scala mdoc
val v = Validated.valid[List[String], Int](123)
val i = Validated.invalid[List[String], Int](List("Badness"))
```

As a third option we can import
the `valid` and `invalid` extension methods
from `cats.syntax.validated`:

```scala mdoc:silent
import cats.syntax.validated._ // for valid and invalid
```

```scala mdoc
123.valid[List[String]]
List("Badness").invalid[Int]
```

As a fourth option we can use `pure` and `raiseError`
from [`cats.syntax.applicative`][cats.syntax.applicative]
and [`cats.syntax.applicativeError`][cats.syntax.applicativeError]
respectively:

```scala mdoc:silent
import cats.syntax.applicative._      // for pure
import cats.syntax.applicativeError._ // for raiseError

type ErrorsOr[A] = Validated[List[String], A]
```

```scala mdoc
123.pure[ErrorsOr]
List("Badness").raiseError[ErrorsOr, Int]
```

Finally, there are helper methods
to create instances of `Validated` from different sources.
We can create them from `Exceptions`,
as well as instances of `Try`, `Either`, and `Option`:

```scala mdoc
Validated.catchOnly[NumberFormatException]("foo".toInt)

Validated.catchNonFatal(sys.error("Badness"))

Validated.fromTry(scala.util.Try("foo".toInt))

Validated.fromEither[String, Int](Left("Badness"))

Validated.fromOption[String, Int](None, "Badness")
```

=== Combining Instances of Validated


We can combine instances of `Validated`
using any of the methods or syntax
described for `Semigroupal` above.

All of these techniques require
an instance of `Semigroupal` to be in scope.
As with `Either`, we need to fix the error type
to create a type constructor with the correct
number of parameters for `Semigroupal`:

```scala mdoc:invisible:reset-object
import cats.data.Validated
import cats.Semigroupal
import cats.syntax.validated._
```
```scala mdoc:silent
type AllErrorsOr[A] = Validated[String, A]
```

`Validated` accumulates errors using a `Semigroup`,
so we need one of those in scope to summon the `Semigroupal`.
If no `Semigroup` is visible at the call site,
we get an annoyingly unhelpful compilation error:

```scala mdoc
Semigroupal[AllErrorsOr]
```

Once we import a `Semigroup` for the error type,
everything works as expected:

```scala mdoc:silent
import cats.instances.string._ // for Semigroup
```

```scala mdoc
Semigroupal[AllErrorsOr]
```

As long as the compiler has all the implicits in scope
to summon a `Semigroupal` of the correct type,
we can use apply syntax
or any of the other `Semigroupal` methods
to accumulate errors as we like:

```scala mdoc:silent
import cats.syntax.apply._ // for tupled
```

```scala mdoc
(
  "Error 1".invalid[Int],
  "Error 2".invalid[Int]
).tupled
```

As you can see, `String` isn't an ideal type
for accumulating errors.
We commonly use `Lists` or `Vectors` instead:

```scala mdoc:silent
import cats.instances.vector._ // for Semigroupal
```

```scala mdoc
(
  Vector(404).invalid[Int],
  Vector(500).invalid[Int]
).tupled
```

The `cats.data` package also provides
the [`NonEmptyList`][cats.data.NonEmptyList]
and [`NonEmptyVector`][cats.data.NonEmptyVector]
types that prevent us failing without at least one error:

```scala mdoc:silent
import cats.data.NonEmptyVector
```

```scala mdoc
(
  NonEmptyVector.of("Error 1").invalid[Int],
  NonEmptyVector.of("Error 2").invalid[Int]
).tupled
```

=== Methods of Validated


`Validated` comes with a suite of methods
that closely resemble those available for `Either`,
including the methods from [`cats.syntax.either`][cats.syntax.either].
We can use `map`, `leftMap`, and `bimap`
to transform the values inside
the valid and invalid sides:

```scala mdoc
123.valid.map(_ * 100)

"?".invalid.leftMap(_.toString)

123.valid[String].bimap(_ + "!", _ * 100)

"?".invalid[Int].bimap(_ + "!", _ * 100)
```

We can't `flatMap` because `Validated` isn't a monad.
However, Cats does provide a stand-in for `flatMap` called `andThen`.
The type signature of `andThen` is
identical to that of `flatMap`,
but it has a different name
because it is not a lawful implementation
with respect to the monad laws:

```scala mdoc
32.valid.andThen { a =>
  10.valid.map { b =>
    a + b
  }
}
```

If we want to do more than just `flatMap`,
we can convert back and forth
between `Validated` and `Either`
using the `toEither` and `toValidated` methods.
Note that `toValidated` comes from [`cats.syntax.either`]:

```scala mdoc
import cats.syntax.either._ // for toValidated

"Badness".invalid[Int]
"Badness".invalid[Int].toEither
"Badness".invalid[Int].toEither.toValidated
```

As with `Either`, we can use the `ensure` method
to fail with a specified error
if a predicate does not hold:

```scala mdoc
// 123.valid[String].ensure("Negative!")(_ > 0)
```

Finally, we can call `getOrElse` or `fold`
to extract values from the `Valid` and `Invalid` cases:

```scala mdoc
"fail".invalid[Int].getOrElse(0)

"fail".invalid[Int].fold(_ + "!!!", _.toString)
```

=== Exercise: Form Validation


Let's get used to `Validated` by implementing
a simple HTML registration form.
We receive request data from the client
in a `Map[String, String]`
and we want to parse it to create a `User` object:

```scala mdoc:silent
case class User(name: String, age: Int)
```

Our goal is to implement code that
parses the incoming data enforcing the following rules:

 - the name and age must be specified;
 - the name must not be blank;
 - the age must be a valid non-negative integer.

If all the rules pass our parser we should return a `User`.
If any rules fail we should return
a `List` of the error messages.

To implement this example
we'll need to combine rules
in sequence and in parallel.
We'll use `Either` to combine computations
in sequence using fail-fast semantics,
and `Validated` to combine them
in parallel using accumulating semantics.

Let's start with some sequential combination.
We'll define two methods to
read the `"name"` and `"age"` fields:

- `readName` will take a `Map[String, String]` parameter,
  extract the `"name"` field,
  check the relevant validation rules,
  and return an `Either[List[String], String]`.

- `readAge` will take a `Map[String, String]` parameter,
  extract the `"age"` field,
  check the relevant validation rules,
  and return an `Either[List[String], Int]`.

We'll build these methods up from smaller building blocks.
Start by defining a method `getValue` that
reads a `String` from the `Map` given a field name.

#solution[
We'll be using `Either` and `Validated`
so we'll start with some imports:

```scala mdoc:silent
import cats.data.Validated

type FormData = Map[String, String]
type FailFast[A] = Either[List[String], A]
type FailSlow[A] = Validated[List[String], A]
```

The `getValue` rule
extracts a `String` from the form data.
We'll be using it in sequence
with rules for parsing `Ints` and checking values,
so we'll define it to return an `Either`:

```scala mdoc:silent
def getValue(name: String)(data: FormData): FailFast[String] =
  data.get(name).
    toRight(List(s"$name field not specified"))
```

We can create and use an instance of `getValue` as follows:

```scala mdoc
val getName = getValue("name") _

getName(Map("name" -> "Dade Murphy"))
```

In the event of a missing field,
our instance returns an error message
containing an appropriate field name:

```scala mdoc
getName(Map())
```
]

Next define a method `parseInt` that
consumes a `String` and parses it as an `Int`.

#solution[
We'll use `Either` again here.
We use `Either.catchOnly` to
consume the `NumberFormatException` from `toInt`,
and we use `leftMap` to
turn it into an error message:

```scala mdoc:silent
import cats.syntax.either._ // for catchOnly

type NumFmtExn = NumberFormatException

def parseInt(name: String)(data: String): FailFast[Int] =
  Either.catchOnly[NumFmtExn](data.toInt).
    leftMap(_ => List(s"$name must be an integer"))
```

Note that our solution accepts an extra parameter
to name the field we're parsing.
This is useful for creating better error messages,
but it's fine if you leave it out in your code.

If we provide valid input,
`parseInt` converts it to an `Int`:

```scala mdoc
parseInt("age")("11")
```

If we provide erroneous input,
we get a useful error message:

```scala mdoc
parseInt("age")("foo")
```
]

Next implement the validation checks:
`nonBlank` to check `Strings`,
and `nonNegative` to check `Ints`.

#solution[
These definitions use the same patterns as above:

```scala mdoc:silent
def nonBlank(name: String)(data: String): FailFast[String] =
  Right(data).
    ensure(List(s"$name cannot be blank"))(_.nonEmpty)

def nonNegative(name: String)(data: Int): FailFast[Int] =
  Right(data).
    ensure(List(s"$name must be non-negative"))(_ >= 0)
```

Here are some examples of use:

```scala mdoc
nonBlank("name")("Dade Murphy")
nonBlank("name")("")
nonNegative("age")(11)
nonNegative("age")(-1)
```
]

Now combine `getValue`, `parseInt`,
`nonBlank` and `nonNegative`
to create `readName` and `readAge`:

#solution[
We use `flatMap` to combine the rules sequentially:

```scala mdoc:silent
def readName(data: FormData): FailFast[String] =
  getValue("name")(data).
    flatMap(nonBlank("name"))

def readAge(data: FormData): FailFast[Int] =
  getValue("age")(data).
    flatMap(nonBlank("age")).
    flatMap(parseInt("age")).
    flatMap(nonNegative("age"))
```

The rules pick up all the error cases we've seen so far:

```scala mdoc
readName(Map("name" -> "Dade Murphy"))
readName(Map("name" -> ""))
readName(Map())
readAge(Map("age" -> "11"))
readAge(Map("age" -> "-1"))
readAge(Map())
```
]

Finally, use a `Semigroupal` to combine the results
of `readName` and `readAge` to produce a `User`.
Make sure you switch from `Either` to `Validated`
to accumulate errors.

#solution[
We can do this by switching from `Either` to `Validated`
and using apply syntax:

```scala mdoc:silent
import cats.instances.list._ // for Semigroupal
import cats.syntax.apply._   // for mapN

def readUser(data: FormData): FailSlow[User] =
  (
    readName(data).toValidated,
    readAge(data).toValidated
  ).mapN(User.apply)
```

```scala mdoc
readUser(Map("name" -> "Dave", "age" -> "37"))
readUser(Map("age" -> "-1"))
```

The need to switch back and forth
between `Either` and `Validated` is annoying.
The choice of whether to use `Either` or `Validated`
as a default is determined by context.
In application code, we typically find
areas that favour accumulating semantics
and areas that favour fail-fast semantics.
We pick the data type that best suits our need
and switch to the other
as necessary in specific situations.
]
