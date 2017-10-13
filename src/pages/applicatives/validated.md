## *Validated*

By now we are familiar with
the fail-fast error handling behaviour of `Either`.
Furthermore, because `Either` is a monad,
we know that the semantics of `product`
are the same as those for `flatMap`.
In fact, it is impossible for us
to design a monadic data type
that implements error accumulating semantics
without breaking the consistency rules
between these two methods.

Fortunately, Cats provides
a data type called `Validated`
that has an instance of `Cartesian`
but *no* instance of `Monad`.
The implementation of `product`
is therefore free to accumulate errors:

```tut:book:silent
import cats.Cartesian
import cats.data.Validated
import cats.instances.list._ // Semigroup for List

type AllErrorsOr[A] = Validated[List[String], A]
```

```tut:book
Cartesian[AllErrorsOr].product(
  Validated.invalid(List("Error 1")),
  Validated.invalid(List("Error 2"))
)
```

`Validated` complements `Either` nicely.
Between the two we have support for
both of the common types of error handling:
fail-fast and accumulating.

### Creating Instances of *Validated*

`Validated` has two subtypes,
`Validated.Valid` and `Validated.Invalid`,
that correspond loosely to `Right` and `Left`.
We can create instances directly
using their `apply` methods:

```tut:book
val v = Validated.Valid(123)
val i = Validated.Invalid("Badness")
```

However, it is often easier to use
the `valid` and `invalid` smart constructors,
which widen the return type to `Validated`:

```tut:book
val v = Validated.valid[String, Int](123)
val i = Validated.invalid[String, Int]("Badness")
```

As a third option we can import
the `valid` and `invalid` extension methods
from `cats.syntax.validated`:

```tut:book:silent
import cats.syntax.validated._
```

```tut:book
123.valid[String]
"Badness".invalid[Int]
```

Finally, there are a variety of methods on `Validated`
to create instances from different sources.
We can create them from `Exceptions`,
as well as instances of `Try`, `Either`, and `Option`:

```tut:book
Validated.catchOnly[NumberFormatException]("foo".toInt)

Validated.catchNonFatal(sys.error("Badness"))

Validated.fromTry(scala.util.Try("foo".toInt))

Validated.fromEither[String, Int](Left("Badness"))

Validated.fromOption[String, Int](None, "Badness")
```

### Combining Instances of *Validated*

We can combine instances of `Validated`
using any of the methods described above:
`product`, `map2..22`, apply syntax,
and so on.

All of these techniques require
an appropriate `Cartesian` to be in scope.
As with `Either`, we need to fix the error type
to create a type constructor with the correct
number of parameters for `Cartesian`:

```tut:book:silent
type AllErrorsOr[A] = Validated[String, A]
```

`Validated` accumulates errors using a `Semigroup`,
so we need one of those in scope to summon the `Cartesian`.
If we don't have one we get
an annoyingly unhelpful compilation error:

```tut:book:fail
Cartesian[AllErrorsOr]
```

Once we import a `Semigroup[String]`,
everything works as expected:

```tut:book:silent
import cats.instances.string._
```

```tut:book
Cartesian[AllErrorsOr]
```

As long as the compiler has all the implicits in scope
to summon a `Cartesian` of the correct type,
we can use apply syntax
or any of the other `Cartesian` methods
to accumulate errors as we like:

```tut:book:silent
import cats.syntax.apply._
```

```tut:book
(
  "Error 1".invalid[Int],
  "Error 2".invalid[Int]
).tupled
```

As you can see, `String` isn't an ideal type
for accumulating errors.
We commonly use `Lists` or `Vectors` instead:

```tut:book:silent
import cats.instances.vector._
```

```tut:book
(
  Vector(404).invalid[Int],
  Vector(500).invalid[Int]
).tupled
```

The `cats.data` package also provides
the [`NonEmptyList`][cats.data.NonEmptyList]
and [`NonEmptyVector`][cats.data.NonEmptyVector]
types that prevent us failing without at least one error:

```tut:book:silent
import cats.data.NonEmptyVector
```

```tut:book
(
  NonEmptyVector.of("Error 1").invalid[Int],
  NonEmptyVector.of("Error 2").invalid[Int]
).tupled
```

### Methods of *Validated*

`Validated` comes with a suite of methods
that closely resemble those available for `Either`,
including the methods from [`cats.syntax.either`][cats.syntax.either].
We can use `map`, `leftMap`, and `bimap`
to transform the values inside
the valid and invalid sides:

```tut:book
123.valid.map(_ * 100)

"?".invalid.leftMap(_.toString)

123.valid[String].bimap(_ + "!", _ * 100)

"?".invalid[Int].bimap(_ + "!", _ * 100)
```

We can't `flatMap` because `Validated` isn't a monad.
However, we can convert back and forth
between `Validated` and `Either`
using the `toEither` and `toValidated` methods.
This allows us to switch error-handling semantics on the fly.
Note that `toValidated` comes from [`cats.syntax.either`]:

```tut:book
import cats.syntax.either._ // toValidated method

"Badness".invalid[Int]
"Badness".invalid[Int].toEither
"Badness".invalid[Int].toEither.toValidated
```

As with `Either`, we can use the `ensure` method
to fail with a specified error
if a predicate does not hold:

```tut:book
// 123.valid[String].ensure("Negative!")(_ > 0)
```

Finally, we can call `getOrElse` or `fold`
to extract values from the `Valid` and `Invalid` cases:

```tut:book
"fail".invalid[Int].getOrElse(0)

"fail".invalid[Int].fold(_ + "!!!", _.toString)
```

### Exercise: Form Validation

Let's get used to `Validated` by implementing
a simple HTML registration form.
We receive request data from the client
in a `Map[String, String]`
and we want to parse it to create a `User` object:

```tut:book:silent
case class User(name: String, age: Int)
```

Our goal is to implement code that
parses the incoming data enforcing the following rules:

 - the name and age must be specified;
 - the name must not be blank;
 - the age must be a valid non-negative integer.

If all the rules pass,
our parser we should return a `User`.
If any rules fail,
we should return a `List`
of the error messages.

To implement this complete example
we'll need to combine rules
in sequence and in parallel
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

<div class="solution">
We'll be using `Either` and `Validated`
so we'll start with some imports:

```tut:book:silent
import cats.data.Validated

type FormData = Map[String, String]
type ErrorsOr[A] = Either[List[String], A]
type AllErrorsOr[A] = Validated[List[String], A]
```

The `getValue` rule
extracts a `String` from the form data.
We'll be using it in sequence
with rules for parsing `Ints` and checking values,
so we'll define it to return an `Either`:

```tut:book:silent
def getValue(name: String)(data: FormData): ErrorsOr[String] =
  data.get(name).
    toRight(List(s"$name field not specified"))
```

We can create and use an instance of `getValue` as follows:

```tut:book
val getName = getValue("name") _

getName(Map("name" -> "Dade Murphy"))
```

In the event of a missing field,
our instance returns an error message
containing an appropriate field name:

```tut:book
getName(Map())
```
</div>

Next define a method `parseInt` that
consumes a `String` and parses it as an `Int`.

<div class="solution">
We'll use `Either` again here.
We use `Either.catchOnly` to
consume the `NumberFormatException` from `toInt`,
and we use `leftMap` to
turn it into an error message:

```tut:book:silent
import cats.syntax.either._

type NumFmtExn = NumberFormatException

def parseInt(name: String)(data: String): ErrorsOr[Int] =
  Either.catchOnly[NumFmtExn](data.toInt).
    leftMap(_ => List(s"$name must be an integer"))
```

Note that our solution accepts an extra parameter
to name the field we're parsing.
This is useful for creating better error messages,
but it's fine if you leave it out in your code.

If we provide valid input,
`parseInt` converts it to an `Int`:

```tut:book
parseInt("age")("11")
```

If we provide erroneous input,
we get a useful error message:

```tut:book
parseInt("age")("foo")
```
</div>

Next implement the validation checks:
`nonBlank` to check `Strings`,
and `nonNegative` to check `Ints`.

<div class="solution">
These definitions use the same patterns as above:

```tut:book:silent
def nonBlank(name: String)(data: String): ErrorsOr[String] =
  Right(data).
    ensure(List(s"$name cannot be blank"))(_.nonEmpty)

def nonNegative(name: String)(data: Int): ErrorsOr[Int] =
  Right(data).
    ensure(List(s"$name must be non-negative"))(_ >= 0)
```

Here are some examples of use:

```tut:book
nonBlank("name")("Dade Murphy")
nonBlank("name")("")
nonNegative("age")(11)
nonNegative("age")(-1)
```
</div>

Now combine `getValue`, `parseInt`,
`nonBlank` and `nonNegative`
to create `readName` and `readAge`:

<div class="solution">
We use `flatMap` to combine the rules sequentially:

```tut:book:silent
def readName(data: FormData): ErrorsOr[String] =
  getValue("name")(data).
    flatMap(nonBlank("name"))

def readAge(data: FormData): ErrorsOr[Int] =
  getValue("age")(data).
    flatMap(nonBlank("age")).
    flatMap(parseInt("age")).
    flatMap(nonNegative("age"))
```

The rules pick up all the error cases we've seen so far:

```tut:book
readName(Map("name" -> "Dade Murphy"))
readName(Map("name" -> ""))
readName(Map())
readAge(Map("age" -> "11"))
readAge(Map("age" -> "-1"))
readAge(Map())
```
</div>

Finally, use a `Cartesian` to combine the results
of `readName` and `readAge` to produce a `User`.
Make sure you switch from `Either` to `Validated`
to accumulate errors.

<div class="solution">
We can do this by switching from `Either` to `Validated`
and using apply syntax:

```tut:book:silent
import cats.instances.list._
import cats.syntax.apply._

def readUser(data: FormData): AllErrorsOr[User] =
  (
    readName(data).toValidated,
    readAge(data).toValidated
  ).mapN(User.apply)
```

```tut:book
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
</div>
