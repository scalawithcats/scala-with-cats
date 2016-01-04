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

```tut:book
object predicate {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.semigroup._ // For |+|
  import cats.syntax.apply._ // For |@|

  sealed trait Predicate[E,A] {
    import cats.data.Validated._ // For Valid and Invalid
  
    def and(that: Predicate[E,A]): Predicate[E,A] =
      And(this, that)
  
    def or(that: Predicate[E,A]): Predicate[E,A] =
      Or(this, that)
  
    def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A] =
      this match {
        case Pure(f) => f(a)
        case And(l, r) =>
          (l(a) |@| r(a)) map { (_, _) => a }
        case Or(l, r) =>
          l(a) match {
            case Valid(a1)   => Valid(a)
            case Invalid(e1) =>
              r(a) match {
                case Valid(a2)   => Valid(a)
                case Invalid(e2) => Invalid(e1 |+| e2)
              }
          }
      }
  }
  final case class And[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A]
  final case class Or[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A]
  final case class Pure[E,A](f: A => Validated[E,A]) extends Predicate[E,A]
}
```

### Checks

Now `Check` will represent something we build from a `Predicate` that also allows transformation of its input.

Implement `Check` with the following interface. *Hint:* use the same strategy we used for implementing `Predicate`.

```scala
sealed trait Check[E,A,B] {
  def map[C](f: B => C): Check[E,A,C] =
    ???

  def apply(in: A): Validated[E,B] =
    ???
}
```

<div class="solution">
If you follow the same strategy as `Predicate` you should be able to create code similar to the below.

```tut:book
object check {
  import cats.Semigroup
  import cats.data.Validated

  import predicate._

  sealed trait Check[E,A,B] {
    def map[C](f: B => C): Check[E,A,C] =
      Map[E,A,B,C](this, f)
  
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,B]
  }
  final case class Map[E,A,B,C](check: Check[E,A,B], f: B => C) extends Check[E,A,C] {
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,C] =
      check(in) map f
  }
  final case class Pure[E,A](predicate: Predicate[E,A]) extends Check[E,A,A] {
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,A] =
      predicate(in)
  }
}
```
</div>

What about `flatMap`? The semantics are a bit unclear here. It's simple enough to define

```scala
def flatMap[C](f: B => Check[E,A,B]): Check[E,A,C] =
  FlatMap(this, f)
```

along with an appropriate definition of `FlatMap`. However it isn't so obvious what this means or how we should implement `apply` for this case. Have a think about this before reading on.

`FlatMap` allows us to choose a `Check` to apply based on the input we receive. For example, if we're checking an integer we could use `flatMap` to implement the following logic:

- if the integer is even, check if it is a prime number; else
- check if it is positive. 

This is a very silly example, but I have difficulty coming up with a good one. It seems that anything we can do with `flatMap` we can achieve with a combination of a `Predicate` and `map`. However it is reasonably easy to implement `flatMap` so we may as well add it and perhaps someone more far-sighted than I will find a use for it.

Implement `flatMap` for `Check`.

<div class="solution">
It's the same implementation strategy as before, with one wrinkle: `Validated` doesn't have a `flatMap` method. To implement `flatMap` we must momentarily switch to `Xor` and then switch back to `Validated`. The `withXor` method on `Validated` does exactly this. From here we can just follow the types to implement `apply`.

```tut:book
object check {
  import cats.Semigroup
  import cats.data.Validated

  import predicate._

  sealed trait Check[E,A,B] {
    def map[C](f: B => C): Check[E,A,C] =
      Map[E,A,B,C](this, f)

  def flatMap[C](f: B => Check[E,A,C]) =
    FlatMap[E,A,B,C](this, f)

    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,B]
  }
  final case class Map[E,A,B,C](check: Check[E,A,B], f: B => C) extends Check[E,A,C] {
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,C] =
      check(in) map f
  }
  final case class Pure[E,A](predicate: Predicate[E,A]) extends Check[E,A,A] {
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,A] =
      predicate(in)
  }
  final case class FlatMap[E,A,B,C](check: Check[E,A,B], f: B => Check[E,A,C]) extends Check[E,A,C] {
    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,C] =
      check(in).withXor { _.flatMap (a => f(a)(in).toXor) }
  }
}
```
</div>

We now have an implementation of `Check` and `Predicate` that combined do most of what we originally set out to do. However we are not finished yet. You have probably recognised structure in `Predicate` and `Check` that we can abstract over: `Predicate` has a monoid, and `Check` has a monad. Furthermore, in implementing `Check` you might have felt the implementation doesn't really do much---all we do in `apply` is call through to the underlying methods on `Predicate` and `Validated`. Perhaps there is an abstraction we're missing here? We'll address this issue with `Check` first, and then turn to abstracting out the remaining structure in `Predicate` and what is left of `Check`.
