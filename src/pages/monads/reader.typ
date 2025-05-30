#import "../stdlib.typ": info, warning, solution
== The Reader Monad 
<sec:monads:reader>


[`cats.data.Reader`][cats.data.Reader] is a monad
that allows us to sequence operations that depend on some input.
Instances of `Reader` wrap up functions of one argument,
providing us with useful methods for composing them.

One common use for `Readers` is dependency injection.
If we have a number of operations
that all depend on some external configuration,
we can chain them together using a `Reader`
to produce one large operation that
accepts the configuration as a parameter
and runs our program in the order specified.

=== Creating and Unpacking Readers


We can create a `Reader[A, B]` from a function `A => B`
using the `Reader.apply` constructor:

```scala mdoc:silent:reset-object
import cats.data.Reader
```

```scala mdoc
final case class Cat(name: String, favoriteFood: String)

val catName: Reader[Cat, String] =
  Reader(cat => cat.name)
```

We can extract the function again
using the `Reader's` `run` method
and call it using `apply` as usual:

```scala mdoc
catName.run(Cat("Garfield", "lasagne"))
```

So far so simple,
but what advantage do `Readers` give us over the raw functions?

=== Composing Readers


The power of `Readers` comes from their `map` and `flatMap` methods,
which represent different kinds of function composition.
We typically create a set of `Readers`
that accept the same type of configuration,
combine them with `map` and `flatMap`,
and then call `run` to inject the config at the end.

The `map` method simply extends the computation in the `Reader`
by passing its result through a function:

```scala mdoc:silent
val greetKitty: Reader[Cat, String] =
  catName.map(name => s"Hello ${name}")
```

```scala mdoc
greetKitty.run(Cat("Heathcliff", "junk food"))
```

The `flatMap` method is more interesting.
It allows us to combine readers that depend on the same input type.
To illustrate this, let's extend our greeting example
to also feed the cat:

```scala mdoc:silent
val feedKitty: Reader[Cat, String] =
  Reader(cat => s"Have a nice bowl of ${cat.favoriteFood}")

val greetAndFeed: Reader[Cat, String] =
  for {
    greet <- greetKitty
    feed  <- feedKitty
  } yield s"$greet. $feed."
```

```scala mdoc
greetAndFeed(Cat("Garfield", "lasagne"))
greetAndFeed(Cat("Heathcliff", "junk food"))
```

=== Exercise: Hacking on Readers


The classic use of `Readers` is to build programs
that accept a configuration as a parameter.
Let's ground this with a complete example
of a simple login system.
Our configuration will consist of two databases:
a list of valid users and a list of their passwords:

```scala mdoc:silent
final case class Db(
  usernames: Map[Int, String],
  passwords: Map[String, String]
)
```

Start by creating a type alias `DbReader` for
a `Reader` that consumes a `Db` as input.
This will make the rest of our code shorter.

#solution[
Our type alias fixes the `Db` type
but leaves the result type flexible:

```scala mdoc:silent
type DbReader[A] = Reader[Db, A]
```
]

Now create methods that generate `DbReaders` to
look up the username for an `Int` user ID, and
look up the password for a `String` username.
The type signatures should be as follows:

```scala mdoc:silent
def findUsername(userId: Int): DbReader[Option[String]] =
  ???

def checkPassword(
      username: String,
      password: String): DbReader[Boolean] =
  ???
```

#solution[
Remember: the idea is to leave injecting the configuration until last.
This means setting up functions that accept the config as a parameter
and check it against the concrete user info we have been given:

```scala mdoc:invisible:reset-object
import cats.data.Reader
final case class Db(
  usernames: Map[Int, String],
  passwords: Map[String, String]
)
type DbReader[A] = Reader[Db, A]
```
```scala mdoc:silent
def findUsername(userId: Int): DbReader[Option[String]] =
  Reader(db => db.usernames.get(userId))

def checkPassword(
      username: String,
      password: String): DbReader[Boolean] =
  Reader(db => db.passwords.get(username).contains(password))
```

]

Finally create a `checkLogin` method
to check the password for a given user ID.
The type signature should be as follows:

```scala mdoc:silent
def checkLogin(
      userId: Int,
      password: String): DbReader[Boolean] =
  ???
```

#solution[
As you might expect,
here we use `flatMap` to chain `findUsername` and `checkPassword`.
We use `pure` to lift a `Boolean` to a `DbReader[Boolean]`
when the username is not found:

```scala mdoc:invisible:reset-object
import cats.data.Reader
final case class Db(
  usernames: Map[Int, String],
  passwords: Map[String, String]
)
type DbReader[A] = Reader[Db, A]
def findUsername(userId: Int): DbReader[Option[String]] =
  Reader(db => db.usernames.get(userId))

def checkPassword(
      username: String,
      password: String): DbReader[Boolean] =
  Reader(db => db.passwords.get(username).contains(password))
```
```scala mdoc:silent
import cats.syntax.applicative._ // for pure

def checkLogin(
      userId: Int,
      password: String): DbReader[Boolean] =
  for {
    username   <- findUsername(userId)
    passwordOk <- username.map { username =>
                    checkPassword(username, password)
                  }.getOrElse {
                    false.pure[DbReader]
                  }
  } yield passwordOk
```
]

You should be able to use `checkLogin` as follows:

```scala mdoc:silent
val users = Map(
  1 -> "dade",
  2 -> "kate",
  3 -> "margo"
)

val passwords = Map(
  "dade"  -> "zerocool",
  "kate"  -> "acidburn",
  "margo" -> "secret"
)

val db = Db(users, passwords)
```

```scala mdoc
checkLogin(1, "zerocool").run(db)
checkLogin(4, "davinci").run(db)
```

=== When to Use Readers?


`Readers` provide a tool for doing dependency injection.
We write steps of our program as instances of `Reader`,
chain them together with `map` and `flatMap`,
and build a function that accepts the dependency as input.

There are many ways of implementing dependency injection in Scala,
from simple techniques like methods with multiple parameter lists,
through implicit parameters and type classes,
to complex techniques like the cake pattern and DI frameworks.

`Readers` are most useful in situations where:

- we are constructing a program
  that can easily be represented by a function;

- we need to defer injection of a known parameter
  or set of parameters;

- we want to be able to test
  parts of the program in isolation.

By representing the steps of our program as `Readers`
we can test them as easily as pure functions,
plus we gain access to the `map` and `flatMap` combinators.

For more complicated problems where we have lots of dependencies,
or where a program isn't easily represented as a pure function,
other dependency injection techniques tend to be more appropriate.

#warning[
  _Kleisli Arrows_

  You may have noticed from console output
  that `Reader` is implemented in terms of another type called `Kleisli`.
  _Kleisli arrows_ provide a more general form of `Reader`
  that generalise over the type constructor of the result type.
  We will encounter Kleislis again in @sec:monad-transformers.
]
