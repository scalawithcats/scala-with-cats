## The Check Datatype

```tut:invisible
// Setup some basic imports
import scalaz.\/
```

Let's start with the basic abstraction. From the description it's fairly obvious
we need to represent "checks" somehow. What should a check be? The simplest
implementation might be a predicate---a function returning a boolean. However
this won't allow us to include a useful error message. We could represent a check as a function that accepts some input of type `A` and returns either an error message or the value `A`. As soon as you see this description you should think of something like

```scala
type Check[A] = A => String \/ A
```

Here we've represented the error message as a `String`. This is probably not the best representation. We might want to internationalize our error messages, for example, which requires user specific formatting. We could attempt to build some kind of `ErrorMessage` type that holds all the information we can think of. If you find yourself trying to build this kind of type, stop. It's a sign you've gone down the wrong path. If you can't predict the user's requirements don't try. Instead *let them specify what they want*. The way to do this is with a type parameter. Then the user can plug in whatever type they want.

```scala
type Check[E,A] = A => E \/ A
```

We could just run with the declaration above, but we will probably want to add custom methods to `Check` so perhaps we'd better declare a trait instead of a type alias.

```tut
trait Check[E,A] extends (A => E \/ A)
```

Given a `trait` there are only two options available in the Essential Scala orthodoxy to which we subscribe:

- make the trait a typeclass; or
- make it an algebraic data type (and hence seal it).

A typeclass doesn't seem like a sensible direction here. We aren't trying to unify disparate types with a common interface. That leaves us with an algebraic data type. Let's keep that thought in mind as we explore the design a bit further.

## Basic Combinators

Let's now add some of the basic methods to `Check`, starting with `or`. This method combines two checks into one, which succeeds if either check succeeds. Try to implement this method, with signature

```scala
def or(that: Check[E,A]): Check[E,A]
```

You should very quickly run into a problem: what do you when *both* checks fail? The correct thing to do is to return both errors, but we don't currently have any way to combine errors. What constraint should we add to `E` so we can combine two objects of type `E` into a third object of type `E`?

<div class="solution">
We should require a semigroup for `E`. Then we can combine values of `E` using the addition operation defined on semigroup. Note we don't need a monoid, as we don't need the identity element. Always try to keep your constraints as small as possible!
</div>

Using this knowledge, implement `or`. Make sure you test you have the expected behavior!

<div class="solution">
I can think of two implementation strategies: one where we represent checks as functions and push the logic into the function, and one where we represent checks as an algebraic data type and represent the logic explicitly. Code will make this clearer.

First, the implementation where we push the logic inside the function. I've called this one `CheckF`.

```tut
import scalaz.Semigroup
import scalaz.syntax.applicative._

final case class CheckF[E,A](f: A => E \/ A) {
  def or(that: CheckF[E,A])(implicit s: Semigroup[E]): CheckF[E,A] = {
    val self = this
    CheckF(a => (self(a) |@| that(a)){ (_,_) => a })
  }

  def apply(a: A): E \/ A =
    f(a)
}
```

Let's test the behavior we get.

```tut
import scalaz.syntax.either._ // For .left and .right
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

val check = check1 or check2
val result = check(0)
val expected = List("Value must be greater than 2", "Value must be less than -2")
```
```tut:fail
assert(result == expected.left)
```

/*sealed trait Check[E,A] extends (A => E \/ A) {
def or(that: Check[E,A]): Check[E,A] =
  Or(this, that)

def apply(a: A): E \/ A =
this match {
case Or(l, r) => (l(a) |@| r(a)){ (_,_) => a }
case Pure(f) => f(a)
}
}
final case class Or[E,A](l: Check[E,A], r: Check[E,A]) extends Check[E,A]
final case class Pure[E,A](f: A => E \/ A) extends Check[E,A]*/


</div>
