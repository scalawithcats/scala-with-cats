#import "../../stdlib.typ": info, warning, solution
== Transforming Data


One of our requirements is the ability to transform data.
This allows us to support
additional scenarios like parsing input.
In this section we'll extend our check library
with this additional functionality.

The obvious starting point is `map`.
When we try to implement this,
we immediately run into a wall.
Our current definition of `Check`
requires the input and output types to be the same:

```scala mdoc:silent
type Check[E, A] = A => Either[E, A]
```

When we map over a check,
what type do we assign to the result?
It can't be `A` and it can't be `B`.
We are at an impasse:

```scala
def map(check: Check[E, A])(func: A => B): Check[E, ???]
```

To implement `map` we need to change the definition of `Check`.
Specifically, we need to a new type variable
to separate the input type from the output:

```scala mdoc:reset-object:silent
type Check[E, A, B] = A => Either[E, B]
```

Checks can now represent operations
like parsing a `String` as an `Int`:

```scala
val parseInt: Check[List[String], String, Int] =
  // etc...
```

However, splitting our input and output types
raises another issue.
Up until now we have operated under the assumption
that a `Check` always returns its input when successful.
We used this in `and` and `or`
to ignore the output of the left and right rules
and simply return the original input on success:

```scala
(this(a), that(a)) match {
  case And(left, right) =>
    (left(a), right(a))
      .mapN((result1, result2) => Right(a))

  // etc...
}
```

In our new formulation we can't return `Right(a)`
because its type is `Either[E, A]` not `Either[E, B]`.
We're forced to make an arbitrary choice
between returning `Right(result1)` and `Right(result2)`.
The same is true of the `or` method.
From this we can derive two things:

- we should strive to make the laws we adhere to explicit; and
- the code is telling us we have the wrong abstraction in `Check`.

=== Predicates


We can make progress by pulling apart the concept of a _predicate_,
which can be combined using logical operations such as _and_ and _or_,
and the concept of a _check_, which can transform data.

What we have called `Check` so far we will call `Predicate`.
For `Predicate` we can state the following _identity law_
encoding the notion that a predicate
always returns its input if it succeeds:

> For a predicate `p` of type `Predicate[E, A]`
> and elements `a1` and `a2` of type `A`,
> if `p(a1) == Success(a2)` then `a1 == a2`.

Making this change gives us the following code:

```scala mdoc:silent
import cats.Semigroup
import cats.data.Validated
import cats.syntax.semigroup._ // for |+|
import cats.syntax.apply._     // for mapN
import cats.data.Validated._   // for Valid and Invalid
```

```scala mdoc:silent
sealed trait Predicate[E, A] {
  def and(that: Predicate[E, A]): Predicate[E, A] =
    And(this, that)

  def or(that: Predicate[E, A]): Predicate[E, A] =
    Or(this, that)

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, A] =
    this match {
      case Pure(func) =>
        func(a)

      case And(left, right) =>
        (left(a), right(a)).mapN((_, _) => a)

      case Or(left, right) =>
        left(a) match {
          case Valid(_)   => Valid(a)
          case Invalid(e1) =>
            right(a) match {
              case Valid(_)   => Valid(a)
              case Invalid(e2) => Invalid(e1 |+| e2)
            }
        }
    }
}

final case class And[E, A](
  left: Predicate[E, A],
  right: Predicate[E, A]) extends Predicate[E, A]

final case class Or[E, A](
  left: Predicate[E, A],
  right: Predicate[E, A]) extends Predicate[E, A]

final case class Pure[E, A](
  func: A => Validated[E, A]) extends Predicate[E, A]
```

=== Checks


We'll use `Check` to represent
a structure we build from a `Predicate`
that also allows transformation of its input.
Implement `Check` with the following interface:

```scala
sealed trait Check[E, A, B] {
  def apply(a: A): Validated[E, B] =
    ???

  def map[C](func: B => C): Check[E, A, C] =
    ???
}
```

#solution[
If you follow the same strategy as `Predicate`
you should be able to create code similar to the below:

```scala mdoc:invisible:reset-object
import cats.Semigroup
import cats.data.Validated
import cats.implicits._

sealed trait Predicate[E, A] {
  import Predicate._
  import Validated._

  def and(that: Predicate[E, A]): Predicate[E, A] =
    And(this, that)

  def or(that: Predicate[E, A]): Predicate[E, A] =
    Or(this, that)

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, A] =
    this match {
      case Pure(func) =>
        func(a)

      case And(left, right) =>
        (left(a), right(a)).mapN((_, _) => a)

      case Or(left, right) =>
        left(a) match {
          case Valid(_)   => Valid(a)
          case Invalid(e1) =>
            right(a) match {
              case Valid(_)   => Valid(a)
              case Invalid(e2) => Invalid(e1 |+| e2)
            }
        }
    }
}
object Predicate {
  final case class And[E, A](
    left: Predicate[E, A],
    right: Predicate[E, A]) extends Predicate[E, A]
  
  final case class Or[E, A](
    left: Predicate[E, A],
    right: Predicate[E, A]) extends Predicate[E, A]
  
  final case class Pure[E, A](
    func: A => Validated[E, A]) extends Predicate[E, A]
}
```
```scala mdoc:silent
import cats.Semigroup
import cats.data.Validated
```

```scala mdoc:silent
sealed trait Check[E, A, B] {
  import Check._

  def apply(in: A)(implicit s: Semigroup[E]): Validated[E, B]

  def map[C](f: B => C): Check[E, A, C] =
    Map[E, A, B, C](this, f)
}

object Check {
  final case class Map[E, A, B, C](
    check: Check[E, A, B],
    func: B => C) extends Check[E, A, C] {
  
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E, C] =
      check(in).map(func)
  }
  
  final case class Pure[E, A](
    pred: Predicate[E, A]) extends Check[E, A, A] {
  
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E, A] =
      pred(in)
  }

  def apply[E, A](pred: Predicate[E, A]): Check[E, A, A] =
    Pure(pred)
}

```
]

What about `flatMap`?
The semantics are a bit unclear here.
The method is simple enough to declare
but it's not so obvious what it means
or how we should implement `apply`.
The general shape of `flatMap` is
shown in @fig:validation:generic-flatmap.

#figure(image("../../monads/generic-flatmap.svg"), caption: [Type chart for flatMap])
<fig:validation:generic-flatmap>

How do we relate `F` in the figure to `Check` in our code?
`Check` has _three_ type variables while `F` only has one.

To unify the types we need to fix two of the type parameters.
The idiomatic choices are the error type `E` and the input type `A`.
This gives us the relationships
shown in @fig:validation:check-flatmap.
In other words, the semantics of applying a `FlatMap` are:

- given an input of type `A`, convert to `F[B]`;

- use the output of type `B` to choose a `Check[E, A, C]`;

- return to the _original_ input of type `A`
  and apply it to the chosen check to generate
  the final result of type `F[C]`.

#figure(image("flatmap.svg"), caption: [Type chart for flatMap applied to Check])
<fig:validation:check-flatmap>

This is quite an odd method.
We can implement it, but it is hard to find a use for it.
Go ahead and implement `flatMap` for `Check`,
and then we'll see a more generally useful method.

#solution[
It's the same implementation strategy as before with one wrinkle:
`Validated` doesn't have a `flatMap` method.
To implement `flatMap` we must momentarily switch to `Either`
and then switch back to `Validated`.
The `withEither` method on `Validated` does exactly this.
From here we can just follow the types to implement `apply`.

```scala mdoc:silent:reset-object
import cats.Semigroup
import cats.data.Validated
```

```scala mdoc:silent
sealed trait Check[E, A, B] {
  def apply(in: A)(implicit s: Semigroup[E]): Validated[E, B]

  def flatMap[C](f: B => Check[E, A, C]) =
    FlatMap[E, A, B, C](this, f)

  // other methods...
}

final case class FlatMap[E, A, B, C](
  check: Check[E, A, B],
  func: B => Check[E, A, C]) extends Check[E, A, C] {

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, C] =
    check(a).withEither(_.flatMap(b => func(b)(a).toEither))
}

// other data types...
```
]

We can write a more useful combinator
that chains together two `Checks`.
The output of the first check is
connected to the input of the second.
This is analogous to function composition using `andThen`:

```scala
val f: A => B = ???
val g: B => C = ???
val h: A => C = f andThen g
```

A `Check` is basically a function `A => Validated[E, B]`
so we can define an analagous `andThen` method:

```scala
trait Check[E, A, B] {
  def andThen[C](that: Check[E, B, C]): Check[E, A, C]
}
```

Implement `andThen` now!

#solution[
Here's a minimal definition of `andThen`
and its corresponding `AndThen` class:

```scala mdoc:invisible:reset-object
import cats.Semigroup
import cats.data.Validated
```
```scala mdoc:silent
sealed trait Check[E, A, B] {
  def apply(in: A)(implicit s: Semigroup[E]): Validated[E, B]

  def andThen[C](that: Check[E, B, C]): Check[E, A, C] =
    AndThen[E, A, B, C](this, that)
}

final case class AndThen[E, A, B, C](
  check1: Check[E, A, B],
  check2: Check[E, B, C]) extends Check[E, A, C] {

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, C] =
    check1(a).withEither(_.flatMap(b => check2(b).toEither))
}
```
]

=== Recap


We now have two algebraic data types, `Predicate` and `Check`,
and a host of combinators with their
associated case class implementations.
Look at the following solution
for a complete definition of each ADT.

#solution[
Here's our final implementaton,
including some tidying and repackaging of the code:

```scala mdoc:silent:reset-object
import cats.Semigroup
import cats.data.Validated
import cats.data.Validated._   // for Valid and Invalid
import cats.syntax.semigroup._ // for |+|
import cats.syntax.apply._     // for mapN
import cats.syntax.validated._ // for valid and invalid
```

Here is our complete implementation of `Predicate`,
including the `and` and `or` combinators and
a `Predicate.apply` method to create
a `Predicate` from a function:

```scala mdoc:silent
sealed trait Predicate[E, A] {
  import Predicate._
  import Validated._

  def and(that: Predicate[E, A]): Predicate[E, A] =
    And(this, that)

  def or(that: Predicate[E, A]): Predicate[E, A] =
    Or(this, that)

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, A] =
    this match {
      case Pure(func) =>
        func(a)

      case And(left, right) =>
        (left(a), right(a)).mapN((_, _) => a)

      case Or(left, right) =>
        left(a) match {
          case Valid(_)   => Valid(a)
          case Invalid(e1) =>
            right(a) match {
              case Valid(_)   => Valid(a)
              case Invalid(e2) => Invalid(e1 |+| e2)
            }
        }
    }
}

object Predicate {
  final case class And[E, A](
    left: Predicate[E, A],
    right: Predicate[E, A]) extends Predicate[E, A]

  final case class Or[E, A](
    left: Predicate[E, A],
    right: Predicate[E, A]) extends Predicate[E, A]

  final case class Pure[E, A](
    func: A => Validated[E, A]) extends Predicate[E, A]

  def apply[E, A](f: A => Validated[E, A]): Predicate[E, A] =
    Pure(f)

  def lift[E, A](err: E, fn: A => Boolean): Predicate[E, A] =
    Pure(a => if(fn(a)) a.valid else err.invalid)
}
```

Here is a complete implementation of `Check`.
Due to [a type inference bug][link-si-6680]
in Scala's pattern matching,
we've switched to implementing `apply`
using inheritance:

```scala mdoc:silent
import cats.Semigroup
import cats.data.Validated
import cats.syntax.apply._     // for mapN
import cats.syntax.validated._ // for valid and invalid
```
```scala mdoc:silent
sealed trait Check[E, A, B] {
  import Check._

  def apply(in: A)(implicit s: Semigroup[E]): Validated[E, B]

  def map[C](f: B => C): Check[E, A, C] =
    Map[E, A, B, C](this, f)

  def flatMap[C](f: B => Check[E, A, C]) =
    FlatMap[E, A, B, C](this, f)

  def andThen[C](next: Check[E, B, C]): Check[E, A, C] =
    AndThen[E, A, B, C](this, next)
}

object Check {
  final case class Map[E, A, B, C](
    check: Check[E, A, B],
    func: B => C) extends Check[E, A, C] {

    def apply(a: A)
        (implicit s: Semigroup[E]): Validated[E, C] =
      check(a) map func
  }

  final case class FlatMap[E, A, B, C](
    check: Check[E, A, B],
    func: B => Check[E, A, C]) extends Check[E, A, C] {

    def apply(a: A)
        (implicit s: Semigroup[E]): Validated[E, C] =
      check(a).withEither(_.flatMap(b => func(b)(a).toEither))
  }

  final case class AndThen[E, A, B, C](
    check: Check[E, A, B],
    next: Check[E, B, C]) extends Check[E, A, C] {

    def apply(a: A)
        (implicit s: Semigroup[E]): Validated[E, C] =
      check(a).withEither(_.flatMap(b => next(b).toEither))
  }

  final case class Pure[E, A, B](
    func: A => Validated[E, B]) extends Check[E, A, B] {

    def apply(a: A)
        (implicit s: Semigroup[E]): Validated[E, B] =
      func(a)
  }

  final case class PurePredicate[E, A](
    pred: Predicate[E, A]) extends Check[E, A, A] {

    def apply(a: A)
        (implicit s: Semigroup[E]): Validated[E, A] =
      pred(a)
  }

  def apply[E, A](pred: Predicate[E, A]): Check[E, A, A] =
    PurePredicate(pred)

  def apply[E, A, B]
      (func: A => Validated[E, B]): Check[E, A, B] =
    Pure(func)
}
```
]

We have a complete implementation of `Check` and `Predicate`
that do most of what we originally set out to do.
However, we are not finished yet.
You have probably recognised structure
in `Predicate` and `Check`
that we can abstract over:
`Predicate` has a monoid and `Check` has a monad.
Furthermore, in implementing `Check` you might have felt
the implementation doesn't do much---all we do
is call through to underlying methods
on `Predicate` and `Validated`.

There are a lot of ways this library could be cleaned up.
However, let's implement some examples
to prove to ourselves that our library really does work,
and then we'll turn to improving it.

Implement checks for some of the examples given in the introduction:

- A username must contain at least four characters
  and consist entirely of alphanumeric characters

- An email address must contain an `@` sign.
  Split the string at the `@`.
  The string to the left must not be empty.
  The string to the right must be at least three characters long
  and contain a dot.

You might find the following predicates useful:

```scala mdoc:silent
import cats.data.{NonEmptyList, Validated}
```

```scala mdoc:silent
type Errors = NonEmptyList[String]

def error(s: String): NonEmptyList[String] =
  NonEmptyList(s, Nil)

def longerThan(n: Int): Predicate[Errors, String] =
  Predicate.lift(
    error(s"Must be longer than $n characters"),
    str => str.size > n)

val alphanumeric: Predicate[Errors, String] =
  Predicate.lift(
    error(s"Must be all alphanumeric characters"),
    str => str.forall(_.isLetterOrDigit))

def contains(char: Char): Predicate[Errors, String] =
  Predicate.lift(
    error(s"Must contain the character $char"),
    str => str.contains(char))

def containsOnce(char: Char): Predicate[Errors, String] =
  Predicate.lift(
    error(s"Must contain the character $char only once"),
    str => str.filter(c => c == char).size == 1)
```

#solution[
Here's our reference solution.
Implementing this required more thought than we expected.
Switching between `Check` and `Predicate` at appropriate places
felt a bit like guesswork till we got the rule into our heads
that `Predicate` doesn't transform its input.
With this rule in mind things went fairly smoothly.
In later sections we'll make some changes
that make the library easier to use.

```scala mdoc:silent
import cats.syntax.apply._     // for mapN
import cats.syntax.validated._ // for valid and invalid
```

Here's the implementation of `checkUsername`:

```scala mdoc:silent
// A username must contain at least four characters
// and consist entirely of alphanumeric characters

val checkUsername: Check[Errors, String, String] =
  Check(longerThan(3) and alphanumeric)
```

And here's the implementation of `checkEmail`,
built up from a number of smaller components:

```scala mdoc:silent
// An email address must contain a single `@` sign.
// Split the string at the `@`.
// The string to the left must not be empty.
// The string to the right must be
// at least three characters long and contain a dot.

val splitEmail: Check[Errors, String, (String, String)] =
  Check(_.split('@') match {
    case Array(name, domain) =>
      (name, domain).validNel[String]

    case _ =>
      "Must contain a single @ character".
        invalidNel[(String, String)]
  })

val checkLeft: Check[Errors, String, String] =
  Check(longerThan(0))

val checkRight: Check[Errors, String, String] =
  Check(longerThan(3) and contains('.'))

val joinEmail: Check[Errors, (String, String), String] =
  Check { case (l, r) =>
    (checkLeft(l), checkRight(r)).mapN(_ + "@" + _)
  }

val checkEmail: Check[Errors, String, String] =
  splitEmail andThen joinEmail
```

Finally, here's a check for a `User`
that depends on `checkUsername` and `checkEmail`:

```scala mdoc:silent
final case class User(username: String, email: String)

def createUser(
      username: String,
      email: String): Validated[Errors, User] =
  (checkUsername(username), checkEmail(email)).mapN(User.apply)
```

We can check our work by creating
a couple of example users:

```scala mdoc
createUser("Noel", "noel@underscore.io")
createUser("", "dave@underscore.io@io")
```

One distinct disadvantage of our example is that
it doesn't tell us _where_ the errors came from.
We can either achieve that through
judicious manipulation of error messages,
or we can modify our library
to track error locations as well as messages.
Tracking error locations is outside the scope of this case study,
so we'll leave this as an exercise to the reader.
]
