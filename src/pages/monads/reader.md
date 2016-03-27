## The *Reader* Monad

[`cats.data.Reader`][cats.data.Reader] is a monad that allows us to compose operations that depend on some input. Instances of `Reader` wrap up functions of one argument, providing us with useful methods for composing them.

One common use for `Readers` is injecting configuration. If we have a number of operations that all depend on some external configuration, we can chain them together using a `Reader`. The `Reader` produces one large operation that accepts the configuration as a parameter and runs everything as specified.

### Creating and Unpacking Readers

We can create a `Reader[A, B]` from a function `A => B` using the `Reader.apply` constructor:

```scala
import cats.data.Reader
// import cats.data.Reader

def double(a: Int): Int =
  a * 2
// double: (a: Int)Int

val doubleReader: Reader[Int, Int] =
  Reader(double)
// doubleReader: cats.data.Reader[Int,Int] = Kleisli(<function1>)
```

We can extract the function again using the `Reader's` `run` method:

```scala
val double2: Int => Int =
  doubleReader.run
// double2: Int => Int = <function1>

double(10)
// res0: Int = 20
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

The power of `Readers` comes from their `map` and `flatMap` methods, both of which represent kinds of function composition. The `map` method simply extends the computation in the `Reader` by passing its result through a function:

```scala
val mapExampleReader: Reader[Int, String] =
  doubleReader.map(x => x + "!")
// mapExampleReader: cats.data.Reader[Int,String] = Kleisli(<function1>)

val mapExample: Int => String =
  mapExampleReader.run
// mapExample: Int => String = <function1>

mapExample(10)
// res1: String = 20!
```

The `flatMap` method is more interesting. It allows us to combine two readers that depend on the same input type:

```scala
val add1Reader: Reader[Int, Int] =
  Reader((x: Int) => x + 1)
// add1Reader: cats.data.Reader[Int,Int] = Kleisli(<function1>)

val flatMapExampleReader: Reader[Int, (Int, Int)] =
  for {
    x <- doubleReader
    y <- add1Reader
  } yield (x, y)
// flatMapExampleReader: cats.data.Reader[Int,(Int, Int)] = Kleisli(<function1>)

val flatMapExample: Int => (Int, Int) =
  flatMapExampleReader.run
// flatMapExample: Int => (Int, Int) = <function1>

flatMapExample(10)
// res2: (Int, Int) = (20,11)
```

Notice that the same input value is passed to both `doubleReader` and `add1Reader`. This is the value of the `Reader` monad, which ensures that the same "configuration" (in this case an input number) is passed to each part of the system.

Of course, `flatMap` has the same sequencing properties that all monads do---we can use the output of the prior step to determine which step to run next. For example:

```scala
val sub5Reader: Reader[Int, Int] =
  Reader((a: Int) => a - 5)
// sub5Reader: cats.data.Reader[Int,Int] = Kleisli(<function1>)

val sequencingExampleReader: Reader[Int, (Int, Int)] =
  for {
    x <- doubleReader
    y <- if(x > 20) sub5Reader else add1Reader
  } yield (x, y)
// sequencingExampleReader: cats.data.Reader[Int,(Int, Int)] = Kleisli(<function1>)

val sequencingExample: Int => (Int, Int) =
  sequencingExampleReader.run
// sequencingExample: Int => (Int, Int) = <function1>

sequencingExample(5)
// res3: (Int, Int) = (10,6)

sequencingExample(15)
// res4: (Int, Int) = (30,10)
```

### Uses for Readers

The classic use case for a `Reader` is to inject a configuration into a computation:

```scala
import cats.data.Reader
// import cats.data.Reader

import cats.syntax.applicative._
// import cats.syntax.applicative._

case class Database(usernames: List[String], passwords: Map[String, String])
// defined class Database

type DatabaseReader[A] = Reader[Database, A]
// defined type alias DatabaseReader

def findUsername(userId: Int): DatabaseReader[Option[String]] =
  Reader { (database: Database) =>
    database.usernames.lift.apply(userId)
  }
// findUsername: (userId: Int)DatabaseReader[Option[String]]

def checkPassword(username: String, password: String): DatabaseReader[Boolean] =
  Reader { (database: Database) =>
    database.passwords
      .get(username)
      .filter(_ == password)
      .isDefined
  }
// checkPassword: (username: String, password: String)DatabaseReader[Boolean]

def checkLogin(userId: Int, password: String): DatabaseReader[Boolean] =
  for {
    username   <- findUsername(userId)
    passwordOk <- username
                    .map(checkPassword(_, password))
                    .getOrElse(false.pure[DatabaseReader])
  } yield passwordOk
// checkLogin: (userId: Int, password: String)DatabaseReader[Boolean]

val program: Database => Boolean =
  checkLogin(123, "secret").run
// program: Database => Boolean = <function1>
```

In this example, `program` represents a complete computation to check whether user `1` has access to our software. We simply need to provide a `Database` to get a result:

```scala
program(Database(List("noel", "dave"), Map("noel" -> "shhh", "dave" -> "secret")))
// res5: Boolean = false

program(Database(List("dave", "noel"), Map("noel" -> "shhh", "dave" -> "secret")))
// res6: Boolean = false
```

In practice, Scala has many other tools that we can use for dependency injection, including trait-based inheritance and implicit parameter lists. The `Reader` monad provides a simple functional technique that achieves similar results without the need for additional language features. However, its usefulness in a language like Scala is debatable.
