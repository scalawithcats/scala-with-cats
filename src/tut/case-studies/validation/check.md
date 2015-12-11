## The Check Datatype

Let's start with the bottom level, checking individual components of the data. From the description it's fairly obvious we need to represent "checks" somehow. What should a check be? The simplest implementation might be a predicate---a function returning a boolean. However this won't allow us to include a useful error message. We could represent a check as a function that accepts some input of type `A` and returns either an error message or the value `A`. As soon as you see this description you should think of something like

```scala
import cats.data.Xor

type Check[A] = A => String Xor A
```

Here we've represented the error message as a `String`. This is probably not the best representation. We might want to internationalize our error messages, for example, which requires user specific formatting. We could attempt to build some kind of `ErrorMessage` type that holds all the information we can think of. This is a mistake. When we can't predict the user's requirements don't try. Instead *let them specify what they want*. The way to do this is with a type parameter. Then the user can plug in whatever type they desire.
```scala
type Check[E,A] = A => E Xor A
```

We could just run with the declaration above, but we will probably want to add custom methods to `Check` so perhaps we'd better declare a trait instead of a type alias.

```tut
trait Check[E,A] extends (A => E Xor A)
```

Given a `trait` there are only two options available in the Essential Scala orthodoxy to which we subscribe:

- make the trait a typeclass; or
- make it an algebraic data type (and hence seal it).

A typeclass doesn't seem like a sensible direction here. We aren't trying to unify disparate types with a common interface. That leaves us with an algebraic data type. Let's keep that thought in mind as we explore the design a bit further.

## Basic Combinators

Let's now add some of the basic methods to `Check`, starting with `and`. This method combines two checks into one, succeeding only if both checks succeed. Try to implement this method, with signature

```scala
def and(that: Check[E,A]): Check[E,A]
```

You should very quickly run into a problem: what do you do when *both* checks fail? The correct thing to do is to return both errors, but we don't currently have any way to combine errors. What constraint should we add to `E` so we can combine two objects of type `E` into a third object of type `E`?

<div class="solution">
We should require a semigroup for `E`. Then we can combine values of `E` using the addition operation defined on semigroup. Note we don't need a monoid, as we don't need the identity element. Always try to keep your constraints as small as possible!
</div>

There is another semantic issue that will come up quite quickly: should `and` short-circuit if the first check fails. What do you think the most useful behavior is?

<div class="solution">
I favor *not* short-circuiting. The reason being that we want to report all errors to the user. 
</div>

Using this knowledge, implement `and`. Make sure you test you have the expected behavior!

<div class="solution">
I can think of two implementation strategies: one where we represent checks as functions and push the logic into the function, and one where we represent checks as an algebraic data type and represent the logic explicitly. Code will make this clearer.

First, the implementation where we push the logic inside the function. I've called this one `CheckF`.

```tut
import scalaz.{\/,-\/,\/-}
import scalaz.Semigroup
import scalaz.syntax.either._ // For .left and .right
import scalaz.syntax.semigroup._ // For |+|

final case class CheckF[E,A](f: A => E \/ A) {
  def and(that: CheckF[E,A])(implicit s: Semigroup[E]): CheckF[E,A] = {
    val self = this
    CheckF(a =>
      (self(a), that(a)) match {
        case (-\/(e1), -\/(e2)) => (e1 |+| e2).left
        case (-\/(e),  \/-(a))  => e.left
        case (\/-(a),  -\/(e))  => e.left
        case (\/-(a1), \/-(a2)) => a.right
      }
    )
  }

  override def apply(a: A): E \/ A =
    f(a)
}
```

Let's test the behavior we get. First we'll setup some checks.

```tut
import scalaz.std.list._ // For semigroup instance on List
import scalaz.std.string._ // For semigroup instance on String

val check1 = CheckF[List[String], Int]{ v =>
  if(v > 2)
    v.right
  else
    List("Value must be greater than 2").left
}

val check2 = CheckF[List[String], Int]{ v =>
  if(v < -2)
    v.right
  else
    List("Value must be less than -2").left
}

val check = check1 and check2
```

Now run the check with some data.

```tut
val result = check(0)
val expected = List("Value must be greater than 2", "Value must be less than -2")
```

Finally check we got the expected output.

```tut
assert(result == expected.left)
```

Now let's see the other implementation strategy.

```tut
sealed trait Check[E,A] {
  def and(that: Check[E,A]): Check[E,A] =
    And(this, that)

  override def apply(a: A)(implicit s: Semigroup[E]): E \/ A =
    this match {
      case Pure(f) => f(a)
      case And(l, r) =>
        (l(a), r(a)) match {
          case (-\/(e1), -\/(e2)) => (e1 |+| e2).left
          case (-\/(e),  \/-(a))  => e.left
          case (\/-(a),  -\/(e))  => e.left
          case (\/-(a1), \/-(a2)) => a.right
        }
    }
}
final case class And[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
final case class Pure[E,A](f: A => E \/ A) extends Check[E,A]
```

Note that in this implementation, the requirement for the `Semigroup` shifts from `and` method to the `apply` method. In general I prefer this implementation, as it cleanly separates the structure of the computation (which we represent with an algebraic data type) with the process that gives meaning to that computation (the `apply` method). We will use this implementation for the rest of this case study.
</div>

Using `E \/ A` for the output of our check is the wrong abstraction. Why is this the case, and what kind of abstraction should we be using? Change your implementation accordingly.

<div class="solution">
The implementation of `apply` for `And` is using the pattern for applicative functors. Disjunction has an `Applicative` instance, but it doesn't have the semantics we want. Namely, it does not accumulate errors but fails on the first error encountered. If we want to accumulate errors, `Validation` is the right abstraction to use. As a bonus, we get more code reuse as we can reuse the applicative instance on `Validation` in the implementation of `apply`.

Here's the complete implementation.

```tut
package validation

import scalaz.{Validation,Semigroup}
import scalaz.syntax.validation._ // For .success and .failure
import scalaz.syntax.semigroup._ // For |+|
import scalaz.syntax.applicative._ // For |@|

sealed trait Check[E,A] {
  def and(that: Check[E,A]): Check[E,A] =
    And(this, that)

  override def apply(a: A)(implicit s: Semigroup[E]): Validation[E,A] =
    this match {
      case Pure(f) => f(a)
      case And(l, r) =>
        (l(a) |@| r(a)){ (_, _) => a }
    }
}
final case class And[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
final case class Pure[E,A](f: A => Validation[E,A]) extends Check[E,A]
```
</div>

Now implement `or`.

<div class="solution">
This reuses the same technique for `and`. In the `apply` method we have to do a bit more work, and it is ok to short-circuit.

```tut
sealed trait Check[E,A] {
  def and(that: Check[E,A]): Check[E,A] =
    And(this, that)

  def or(that: Check[E,A]): Check[E,A] =
    Or(this, that)

  override def apply(a: A)(implicit s: Semigroup[E]): Validation[E,A] =
    this match {
      case Pure(f) => f(a)
      case And(l, r) =>
        (l(a) |@| r(a)){ (_, _) => a }
      case Or(l, r) =>
        l(a) match {
          case Success(a)  => Success(a)
          case Failure(e1) =>
            r(a) match {
              case Success(a)  => Success(a)
              case Failure(e2) => Failure(e1 |+| e2)
            }
        }
    }
}
final case class And[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
final case class Or[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
final case class Pure[E,A](f: A => Validation[E,A]) extends Check[E,A]
```
</div>

With `and` and `or` we can implement many of checks we'll want in practice, but we still have a few more methods to add. We'll turn to `map` and related methods next.
