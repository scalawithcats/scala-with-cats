#import "../../stdlib.typ": info, warning, solution
== The Check Datatype


Our design revolves around a `Check`,
which we said was a function from a value to a value in a context.
As soon as you see this description you should think of something like

```scala mdoc:silent
type Check[A] = A => Either[String, A]
```

Here we've represented the error message as a `String`.
This is probably not the best representation.
We may want to accumulate messages in a `List`, for example,
or even use a different representation
that allows for internationalization or standard error codes.

We could attempt to build some kind of `ErrorMessage` type
that holds all the information we can think of.
However, we can't predict the user's requirements.
Instead let's let the user specify what they want.
We can do this by adding a second type parameter to `Check`:

```scala mdoc:silent:reset-object
type Check[E, A] = A => Either[E, A]
```

We will probably want to add custom methods to `Check`
so let's declare it as a `trait` instead of a type alias:

```scala mdoc:silent:reset-object
trait Check[E, A] {
  def apply(value: A): Either[E, A]

  // other methods...
}
```

As we said in [Essential Scala][link-essential-scala],
there are two functional programming patterns
that we should consider when defining a trait:

- we can make it a typeclass, or;
- we can make it an algebraic data type (and hence seal it).

Type classes allow us to unify disparate data types with a common interface.
This doesn't seem like what we're trying to do here.
That leaves us with an algebraic data type.
Let's keep that thought in mind as we explore the design a bit further.

== Basic Combinators


Let's add some combinator methods to `Check`, starting with `and`.
This method combines two checks into one,
succeeding only if both checks succeed.
Think about implementing this method now.
You should hit some problems. Read on when you do!

```scala mdoc:silent:reset-object
trait Check[E, A] {
  def and(that: Check[E, A]): Check[E, A] =
    ???

  // other methods...
}
```

The problem is: what do you do when _both_ checks fail?
The correct thing to do is to return both errors,
but we don't currently have any way to combine `Es`.
We need a _type class_ that abstracts over
the concept of "accumulating" errors
as shown in @fig:validation:error-semigroup
What type class do we know that looks like this?
What method or operator should we use
to implement the `?` operation?

#figure(image("error-semigroup.svg"), caption: [Combining error messages])
<fig:validation:error-semigroup>

#solution[
We need a `Semigroup` for `E`.
Then we can combine values of `E` using
the `combine` method or its associated `|+|` syntax:

```scala mdoc:silent
import cats.Semigroup
import cats.instances.list._   // for Semigroup
import cats.syntax.semigroup._ // for |+|

val semigroup = Semigroup[List[String]]
```

```scala mdoc
// Combination using methods on Semigroup
semigroup.combine(List("Badness"), List("More badness"))

// Combination using Semigroup syntax
List("Oh noes") |+| List("Fail happened")
```

Note we don't need a full `Monoid` because
we don't need the identity element.
We should always try to keep our constraints
as small as possible!
]

There is another semantic issue that will come up quite quickly:
should `and` short-circuit if the first check fails.
What do you think the most useful behaviour is?

#solution[
We want to report all the errors we can,
so we should prefer _not_ short-circuiting
whenever possible.

In the case of the `and` method,
the two checks we're combining are independent of one another.
We can always run both rules and combine any errors we see.
]

Use this knowledge to implement `and`.
Make sure you end up with the behaviour you expect!

#solution[
There are at least two implementation strategies.

In the first we represent checks as functions.
The `Check` data type becomes a simple wrapper for a function
that provides our library of combinator methods.
For the sake of disambiguation,
we'll call this implementation `CheckF`:

```scala mdoc:silent
import cats.Semigroup
import cats.syntax.either._    // for asLeft and asRight
import cats.syntax.semigroup._ // for |+|
```

```scala mdoc:silent
final case class CheckF[E, A](func: A => Either[E, A]) {
  def apply(a: A): Either[E, A] =
    func(a)

  def and(that: CheckF[E, A])
        (implicit s: Semigroup[E]): CheckF[E, A] =
    CheckF { a =>
      (this(a), that(a)) match {
        case (Left(e1),  Left(e2))  => (e1 |+| e2).asLeft
        case (Left(e),   Right(_))  => e.asLeft
        case (Right(_),  Left(e))   => e.asLeft
        case (Right(_), Right(_)) => a.asRight
      }
    }
}
```

Let's test the behaviour we get.
First we'll setup some checks:

```scala mdoc:silent
import cats.instances.list._ // for Semigroup

val a: CheckF[List[String], Int] =
  CheckF { v =>
    if(v > 2) v.asRight
    else List("Must be > 2").asLeft
  }

val b: CheckF[List[String], Int] =
  CheckF { v =>
    if(v < -2) v.asRight
    else List("Must be < -2").asLeft
  }

val check: CheckF[List[String], Int] =
  a and b
```

Now run the check with some data:

```scala mdoc
check(5)
check(0)
```

Excellent! Everything works as expected!
We're running both checks and
accumulating errors as required.

What happens if we try to create checks
that fail with a type that we can't accumulate?
For example, there is no `Semigroup` instance for `Nothing`.
What happens if we create instances of `CheckF[Nothing, A]`?

```scala mdoc:invisible:reset-object
import cats.Semigroup
import cats.syntax.semigroup._
import cats.syntax.either._
final case class CheckF[E, A](func: A => Either[E, A]) {
  def apply(a: A): Either[E, A] =
    func(a)

  def and(that: CheckF[E, A])
        (implicit s: Semigroup[E]): CheckF[E, A] =
    CheckF { a =>
      (this(a), that(a)) match {
        case (Left(e1),  Left(e2))  => (e1 |+| e2).asLeft
        case (Left(e),   Right(_))  => e.asLeft
        case (Right(_),  Left(e))   => e.asLeft
        case (Right(_), Right(_)) => a.asRight
      }
    }
}
```
```scala mdoc:silent
val a: CheckF[Nothing, Int] =
  CheckF(v => v.asRight)

val b: CheckF[Nothing, Int] =
  CheckF(v => v.asRight)
```

We can create checks just fine
but when we come to combine them
we get an error we might expect:

```scala mdoc:fail
val check = a and b
```

Now let's see another implementation strategy.
In this approach we model checks as
an algebraic data type,
with an explicit data type for each combinator.
We'll call this implementation `Check`:

```scala mdoc:invisible:reset-object
import cats.Semigroup
import cats.syntax.either._    // for asLeft and asRight
import cats.syntax.semigroup._ // for |+|
```

```scala mdoc:silent
sealed trait Check[E, A] {
  import Check._

  def and(that: Check[E, A]): Check[E, A] =
    And(this, that)

  def apply(a: A)(implicit s: Semigroup[E]): Either[E, A] =
    this match {
      case Pure(func) =>
        func(a)

      case And(left, right) =>
        (left(a), right(a)) match {
          case (Left(e1),  Left(e2))  => (e1 |+| e2).asLeft
          case (Left(e),   Right(_))  => e.asLeft
          case (Right(_),  Left(e))   => e.asLeft
          case (Right(_), Right(_)) => a.asRight
        }
    }
}
object Check {
  final case class And[E, A](
    left: Check[E, A],
    right: Check[E, A]) extends Check[E, A]
  
  final case class Pure[E, A](
    func: A => Either[E, A]) extends Check[E, A]
    
  def pure[E, A](f: A => Either[E, A]): Check[E, A] =
    Pure(f)
}
```

Let's see an example:

```scala mdoc:silent
val a: Check[List[String], Int] =
  Check.pure { v =>
    if(v > 2) v.asRight
    else List("Must be > 2").asLeft
  }

val b: Check[List[String], Int] =
  Check.pure { v =>
    if(v < -2) v.asRight
    else List("Must be < -2").asLeft
  }

val check: Check[List[String], Int] =
  a and b
```

While the ADT implementation is more verbose
than the function wrapper implementation,
it has the advantage of cleanly separating
the structure of the computation (the ADT instance we create)
from the process that gives it meaning (the `apply` method).
From here we have a number of options:

- inspect and refactor checks after they are created;
- move the `apply` "interpreter" out into its own module;
- implement alternative interpreters
  providing other functionality (for example visualizing checks).

Because of its flexibility,
we will use the ADT implementation
for the rest of this case study.
]

Strictly speaking, `Either[E, A]` is the wrong abstraction
for the output of our check. Why is this the case?
What other data type could we use instead?
Switch your implementation over to this new data type.

#solution[
The implementation of `apply` for `And`
is using the pattern for applicative functors.
`Either` has an `Applicative` instance,
but it doesn't have the semantics we want.
It fails fast instead of accumulating errors.

If we want to accumulate errors
`Validated` is a more appropriate abstraction.
As a bonus, we get more code reuse
because we can lean on the applicative instance of `Validated`
in the implementation of `apply`.

Here's the complete implementation:

```scala mdoc:silent:reset-object
import cats.Semigroup
import cats.data.Validated
import cats.syntax.apply._     // for mapN
```

```scala mdoc:silent
sealed trait Check[E, A] {
  import Check._

  def and(that: Check[E, A]): Check[E, A] =
    And(this, that)

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, A] =
    this match {
      case Pure(func) =>
        func(a)

      case And(left, right) =>
        (left(a), right(a)).mapN((_, _) => a)
    }
}
object Check {
  final case class And[E, A](
    left: Check[E, A],
    right: Check[E, A]) extends Check[E, A]
  
  final case class Pure[E, A](
    func: A => Validated[E, A]) extends Check[E, A]
}
```
]

Our implementation is looking pretty good now.
Implement an `or` combinator to complement `and`.

#solution[
This reuses the same technique for `and`.
We have to do a bit more work in the `apply` method.
Note that it's OK to short-circuit in this case
because the choice of rules
is implicit in the semantics of "or".

```scala mdoc:silent:reset-object
import cats.Semigroup
import cats.data.Validated
import cats.syntax.semigroup._ // for |+|
import cats.syntax.apply._     // for mapN
import cats.data.Validated._   // for Valid and Invalid
```

```scala mdoc:silent
sealed trait Check[E, A] {
  import Check._

  def and(that: Check[E, A]): Check[E, A] =
    And(this, that)

  def or(that: Check[E, A]): Check[E, A] =
    Or(this, that)

  def apply(a: A)(implicit s: Semigroup[E]): Validated[E, A] =
    this match {
      case Pure(func) =>
        func(a)

      case And(left, right) =>
        (left(a), right(a)).mapN((_, _) => a)

      case Or(left, right) =>
        left(a) match {
          case Valid(a)    => Valid(a)
          case Invalid(e1) =>
            right(a) match {
              case Valid(a)    => Valid(a)
              case Invalid(e2) => Invalid(e1 |+| e2)
            }
        }
    }
}
object Check {
  final case class And[E, A](
    left: Check[E, A],
    right: Check[E, A]) extends Check[E, A]
  
  final case class Or[E, A](
    left: Check[E, A],
    right: Check[E, A]) extends Check[E, A]
  
  final case class Pure[E, A](
    func: A => Validated[E, A]) extends Check[E, A]
}
```
]

With `and` and `or`
we can implement many of checks we'll want in practice.
However, we still have a few more methods to add.
We'll turn to `map` and related methods next.
