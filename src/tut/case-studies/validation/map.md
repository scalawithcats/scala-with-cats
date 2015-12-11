## Transforming Data

One of our requirements is the ability to transform data, for example when parsing input. We'll now implement this functionality. The obvious method is `map`. We can try to implement this using the same strategy as before, but we'll run into a type error that we can't resolve with the current interface for `Check`. The issue is that `Check` as currently defined expects to return the same type on success as it is given as input. To implement `map` we need to change this, in particular by adding a new type variable to represent the output type. So `Check[E,A]` becomes `Check[E,A,B]` with `B` representing the output type `B`.

However we run into another issue with this case. Up until now we have had an implicit assumption that a `Check` always returns it's input when it is succesful. Adding `map` breaks this assumption and forces us to make an arbitrary choice of which output to return from `and` and `or`. From this we can derive two things:

- we should strive to make explicit the laws we adhere to; and
- the code is telling us we have the wrong abstraction in `Check`.

### Predicates

If we separate the concept of a predicate, which can be combined using logical and and or, and the concept of a check, which can transform data, we can work out way out of our muddle.

What we have called `Check` so far we will call `Predicate`. For `Predicate` we can state the law:

- *Identity Law*: For a predicate `p` of type `Predicate[E,A]` and elements `a1` and `a2` of type `A`, if `p(a1) == Success(a2)` then `a1 == a2`.

This identity law encodes the notion that predicate always returns its input if it succeeds.

Making this change gives us the following code:

```tut
import scalaz.{Validation,Semigroup,Success,Failure}
import scalaz.syntax.validation._ // For .success and .failure
import scalaz.syntax.semigroup._ // For |+|
import scalaz.syntax.applicative._ // For |@|

sealed trait Predicate[E,A] {
  def and(that: Predicate[E,A]): Predicate[E,A] =
    And(this, that)

  def or(that: Predicate[E,A]): Predicate[E,A] =
    Or(this, that)

  override def apply(a: A)(implicit s: Semigroup[E]): Validation[E] =
    this match {
      case Pure(f) => f(a)
      case And(l, r) =>
        (l(a) |@| r(a)){ (_, _) => a }
      case Or(l, r) =>
        l(a) match {
          case Success(a1) => Success(a)
          case Failure(e1) =>
            r(a) match {
              case Success(a2) => Success(a)
              case Failure(e2) => Failure(e1 |+| e2)
            }
        }
    }
}
final case class And[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A]
final case class Or[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A]
final case class Pure[E,A](f: A => Validation[E]) extends Predicate[E,A]
```

### Checks

Now `Check` will represent something we build from a `Predicate` that also allows transformation of its input.

Implement `Check` with the following interface. *Hint:* use the same strategy we used for implementing `Predicate`.

```scala
sealed trait Check[E,A,B] {
  def map[C](f: B => C): Check[E,A,C] =
    ???

  def apply(in: A): Validation[E,B] =
    ???
}
```

<div class="solution">
If you follow the same strategy as `Predicate` you should be able to create code similar to the below.

```tut
import scalaz.{Validation}

sealed trait Check[E,A,B] {
  def map[C](f: B => C): Check[E,A,C] =
    Map[E,A,C](this, f)

  def apply(in: A): Validation[E,B] =
    this match {
      case Map(c, f) => c(in) map f
      case Pure(p)   => p(in)
    }
}
final case class Map[E,A,B,C](check: Check[E,A,B], f: B => C) extends Check[E,A,C]
final case class Pure[E,A](predicate: Predicate[E,A]) extends Check[E,A,A]
```
</div>

What about `flatMap`? The semantics are a bit unclear here. It's simple enough to define

```scala
def flatMap[C](f: B => Check[E,A,B]): Check[E,A,C] =
  FlatMap(this, f)
```

along with an appropriate definition of `FlatMap`. However it isn't so obvious what this means or how we should implement `apply` for this case. Have a think about this before reading on.

`FlatMap` allows us to choose a `Check` to apply based on the input we receive. For example, if we're checking an integer we could decide to check if it is a prime number if it is positive, while checking for an even number if it is negative. This is a very silly example, but I have difficulty coming up with a good one. It seems that anything we can do with `flatMap` we can achieve with a combination of a `Predicate` and `map`. However it is reasonably easy to implement `flatMap` so we may as well add it and perhaps someone more far-sighted than I will find a use for it.

Implement `flatMap` for `Check`.

<div class="solution">
It's the same implementation strategy as before. Just follow the types to implement `apply`.

```tut
import scalaz.{Validation}

sealed trait Check[E,A,B] {
  def map[C](f: B => C): Check[E,A,C] =
    Map[E,A,C](this, f)

  def apply(in: A): Validation[E,B] =
    this match {
      case FlatMap(c,f) => c(in) flatMap (a => f(a)(a))
      case Map(c, f)    => c(in) map f
      case Pure(p)      => p(in)
    }
}
final case class FlatMap[E,A,B,C](check: Check[E,A,B], f: B => Check[E,A,C]): Check[E,A,C]
final case class Map[E,A,B,C](check: Check[E,A,B], f: B => C) extends Check[E,A,C]
final case class Pure[E,A](predicate: Predicate[E,A]) extends Check[E,A,A]
```
</div>

We now have an implementation of `Check` and `Predicate` that combined do most of what we originally set out to do. However we are not finished yet. You have probably recognised structure in `Predicate` and `Check` that we can abstract over: `Predicate` has a monoid, and `Check` has a monad. Furthermore, in implementing `Check` you might have felt the implementation doesn't really do much---all we do in `apply` is call through to the underlying methods on `Predicate` and `Validation`. Perhaps there is an abstraction we're missing here? We'll address this issue with `Check` first, and then turn to abstracting out the remaining structure in `Predicate` and what is left of `Check`.
