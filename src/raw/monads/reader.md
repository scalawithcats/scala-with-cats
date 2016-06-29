## The *Reader* Monad

[`cats.data.Reader`][cats.data.Reader] is a monad that allows us to compose operations
that depend on some input. Instances of `Reader` wrap up functions of one argument,
providing us with useful methods for composing them.

One common use for `Readers` is injecting configuration.
If we have a number of operations that all depend on some external configuration,
we can chain them together using a `Reader`.
The `Reader` produces one large operation that
accepts the configuration as a parameter and runs everything as specified.

### Creating and Unpacking Readers

We can create a `Reader[A, B]` from a function `A => B` using the `Reader.apply` constructor:

```tut:book
import cats.data.Reader

def double(a: Int): Int =
  a * 2

val doubleReader: Reader[Int, Int] =
  Reader(double)
```

We can extract the function again using the `Reader's` `run` method:

```tut:book
val double2: Int => Int =
  doubleReader.run

double(10)
```

So far so simple, but what advantage do `Readers` give us over plain functions?

<div class="callout callout-warning">
  *Kleisli arrows*

  Notice that `Reader` is implemented in terms of another type called `Kleisli`.
  *Kleisli arrows* are a more general form of the `Reader` monad
  that generalise over type type constructor of the result type.
  We won't cover them in this chapter.
</div>

### Composing Readers

The power of `Readers` comes from their `map` and `flatMap` methods,
both of which represent kinds of function composition.
The `map` method simply extends the computation in the `Reader`
by passing its result through a function:

```tut:book
val mapExampleReader: Reader[Int, String] =
  doubleReader.map(x => x + "!")

val mapExample: Int => String =
  mapExampleReader.run

mapExample(10)
```

The `flatMap` method is more interesting.
It allows us to combine two readers that depend on the same input type:

```tut:book
val add1Reader: Reader[Int, Int] =
  Reader((x: Int) => x + 1)

val flatMapExampleReader: Reader[Int, (Int, Int)] =
  for {
    x <- doubleReader
    y <- add1Reader
  } yield (x, y)

val flatMapExample: Int => (Int, Int) =
  flatMapExampleReader.run

flatMapExample(10)
```

Notice that the same input value is passed to both `doubleReader` and `add1Reader`.
This is the value of the `Reader` monad, which ensures that the same "configuration"
(in this case an input number) is passed to each part of the system.

Of course, `flatMap` has the same sequencing properties that all monads do.
We can use the output of the prior step to determine which step to run next.
For example:

```tut:book
val sub5Reader: Reader[Int, Int] =
  Reader((a: Int) => a - 5)

val sequencingExampleReader: Reader[Int, (Int, Int)] =
  for {
    x <- doubleReader
    y <- if(x > 20) sub5Reader else add1Reader
  } yield (x, y)

val sequencingExample: Int => (Int, Int) =
  sequencingExampleReader.run

sequencingExample(5)

sequencingExample(15)
```

### Uses for Readers

The classic use case for a `Reader` is to inject a configuration into a computation:

```tut:book
import cats.data.Reader
import cats.syntax.applicative._

final case class Database(users: Map[Int, String], passwords: Map[String, String])

type DatabaseReader[A] = Reader[Database, A]

def findUsername(userId: Int): DatabaseReader[Option[String]] =
  Reader { (database: Database) =>
    database.users.get(userId)
  }

def checkPassword(username: String, password: String): DatabaseReader[Boolean] =
  Reader { (database: Database) =>
    database.passwords.get(username).filter(_ == password).isDefined
  }

def checkLogin(userId: Int, password: String): DatabaseReader[Boolean] =
  for {
    username   <- findUsername(userId)
    passwordOk <- username.map(checkPassword(_, password))
                    .getOrElse(false.pure[DatabaseReader])
  } yield passwordOk

val program: Database => Boolean =
  checkLogin(123, "secret").run
```

In this example, `program` represents a complete computation to
check whether user `1` has access to our software.
We simply need to provide a `Database` to get a result:

```tut:book
program(Database(Map(123 -> "noel", 321 -> "dave"), Map("noel" -> "shhh", "dave" -> "secret")))

program(Database(Map(123 -> "dave", 321 -> "noel"), Map("noel" -> "shhh", "dave" -> "secret")))
```

In practice, Scala has many other tools that we can use for dependency injection,
including trait-based inheritance and implicit parameter lists.
The `Reader` monad provides a simple functional technique that
achieves similar results without the need for additional language features.
However, its usefulness in a language like Scala is debatable.

<div class="callout callout-danger">
  TODO: Discuss the relative merits of implicit arguments and readers:
</div>

### Exercise

<div class="callout callout-danger">
  TODO: Reader exercise
</div>
