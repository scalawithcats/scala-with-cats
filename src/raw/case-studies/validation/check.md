## The Check Datatype

Our design revolves around a `Check`, which we said was a function from a value to a value in a context. As soon as you see this description you should think of something like

```tut:book
import cats.data.Xor

type Check[A] = A => String Xor A
```

Here we've represented the error message as a `String`. This is probably not the best representation. We might want to internationalize our error messages, for example, which requires user specific formatting. We could attempt to build some kind of `ErrorMessage` type that holds all the information we can think of. This is a mistake. When we can't predict the user's requirements don't try. Instead *let them specify what they want*. The way to do this is with a type parameter. Then the user can plug in whatever type they desire.

```tut:book
type Check[E,A] = A => E Xor A
```

We could just run with the declaration above, but we will probably want to add custom methods to `Check` so perhaps we'd better declare a trait instead of a type alias.

```tut:book
trait Check[E,A]
```

We have two patterns we can use with a trait. We can either

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

```tut:book
import cats.Semigroup
import cats.data.Xor
import cats.syntax.xor._ // For .left and .right
import cats.syntax.semigroup._ // For |+|

final case class CheckF[E,A](f: A => E Xor A) {
  import cats.data.Xor._ // For Left and Right

  def and(that: CheckF[E,A])(implicit s: Semigroup[E]): CheckF[E,A] = {
    val self = this
    CheckF(a =>
      (self(a), that(a)) match {
        case (Left(e1),  Left(e2))  => (e1 |+| e2).left
        case (Left(e),   Right(a))  => e.left
        case (Right(a),  Left(e))   => e.left
        case (Right(a1), Right(a2)) => a.right
      }
    )
  }

  def apply(a: A): E Xor A =
    f(a)
}
```

Let's test the behavior we get. First we'll setup some checks.

```tut:book
import cats.std.list._ // For semigroup instance on List
import cats.std.string._ // For semigroup instance on String

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

```tut:book
val result = check(0)
val expected = List("Value must be greater than 2", "Value must be less than -2")
```

Finally check we got the expected output.

```tut:book
assert(result == expected.left)
```

Now let's see the other implementation strategy.

```tut:book
object check {
  import cats.Semigroup
  import cats.data.Xor
  import cats.syntax.semigroup._ // For |+|

  sealed trait Check[E,A] {
    import cats.data.Xor._ // For Left and Right
  
    def and(that: Check[E,A]): Check[E,A] =
      And(this, that)
  
    def apply(a: A)(implicit s: Semigroup[E]): E Xor A =
      this match {
        case Pure(f) => f(a)
        case And(l, r) =>
          (l(a), r(a)) match {
            case (Left(e1),  Left(e2))  => (e1 |+| e2).left
            case (Left(e),   Right(a))  => e.left
            case (Right(a),  Left(e))   => e.left
            case (Right(a1), Right(a2)) => a.right
          }
      }
  }
  final case class And[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
  final case class Pure[E,A](f: A => E Xor A) extends Check[E,A]
}
```

Note that in this implementation the requirement for the `Semigroup` shifts from the `and` method to the `apply` method. In general I prefer this implementation, as it cleanly separates the structure of the computation (which we represent with an algebraic data type) with the process that gives meaning to that computation (the `apply` method). We will use this implementation for the rest of this case study.
</div>

Using `E Xor A` for the output of our check is the wrong abstraction. Why is this the case, and what kind of abstraction should we be using? Change your implementation accordingly.

<div class="solution">
The implementation of `apply` for `And` is using the pattern for applicative functors. `Xor` has an `Applicative` instance, but it doesn't have the semantics we want. Namely, it does not accumulate errors but fails on the first error encountered. If we want to accumulate errors, `Validated` is the right abstraction to use. As a bonus, we get more code reuse as we can reuse the applicative instance on `Validated` in the implementation of `apply`.

Here's the complete implementation.

```tut:book
object check {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.semigroup._ // For |+|
  import cats.syntax.cartesian._ // For |@|

  sealed trait Check[E,A] {
    def and(that: Check[E,A]): Check[E,A] =
      And(this, that)
  
    def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A] =
      this match {
        case Pure(f) => f(a)
        case And(l, r) =>
          (l(a) |@| r(a)) map { (_, _) => a }
      }
  }
  final case class And[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
  final case class Pure[E,A](f: A => Validated[E,A]) extends Check[E,A]
}
```
</div>

Now implement `or`.

<div class="solution">
This reuses the same technique for `and`. In the `apply` method we have to do a bit more work, and it is ok to short-circuit.

```tut:book
object check {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.semigroup._ // For |+|
  import cats.syntax.cartesian._ // For |@|

  sealed trait Check[E,A] {
    import cats.data.Validated._ // For Valid and Invalid
    def and(that: Check[E,A]): Check[E,A] =
      And(this, that)
  
    def or(that: Check[E,A]): Check[E,A] =
      Or(this, that)
  
    def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A] =
      this match {
        case Pure(f) => f(a)
        case And(l, r) =>
          (l(a) |@| r(a)) map { (_, _) => a }
        case Or(l, r) =>
          l(a) match {
            case Valid(a) => Valid(a)
            case Invalid(e1) =>
              r(a) match {
                case Valid(a) => Valid(a)
                case Invalid(e2) => Invalid(e1 |+| e2)
              }
          }
      }
  }
  final case class And[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
  final case class Or[E,A](left: Check[E,A], right: Check[E,A]) extends Check[E,A]
  final case class Pure[E,A](f: A => Validated[E,A]) extends Check[E,A]
}
```
</div>

With `and` and `or` we can implement many of checks we'll want in practice, but we still have a few more methods to add. We'll turn to `map` and related methods next.
