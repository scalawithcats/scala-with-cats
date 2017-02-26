## Transforming Data

One of our requirements is the ability to transform data,
for example when parsing input.
We'll now implement this functionality.
The obvious starting point is `map`.
We can try to implement this using the same strategy as before,
but we'll run into a type error
that we can't resolve with the current interface for `Check`.
The issue is that `Check` as currently defined
expects to return the same type on success as it is given as input.
To implement `map` we need to change this,
in particular by adding a new type variable
to represent the output type.
So `Check[E, A]` becomes `Check[E, A, B]`
with `B` representing the output type `B`.

With this fix in place we'll run into another issue.
Up until now we have had an implicit assumption
that a `Check` always returns it's input when it is succesful.
We can enforce this in `and` and `or`
by ignoring their output on success
and just returning the original input.
Adding `map` breaks this assumption,
forcing us to make an arbitrary choice
of which output to return from `and` and `or`.
From this we can derive two things:

- we should strive to make explicit the laws we adhere to; and
- the code is telling us we have the wrong abstraction in `Check`.

### Predicates

We can make progress by pulling apart the concept of a predicate,
which can be combined using logical and and or,
and the concept of a check, which can transform data.

What we have called `Check` so far we will call `Predicate`.
For `Predicate` we can state the law:

- *Identity Law*: For a predicate `p` of type `Predicate[E,A]`
  and elements `a1` and `a2` of type `A`,
  if `p(a1) == Success(a2)` then `a1 == a2`.

This identity law encodes the notion
that predicate always returns its input if it succeeds.

Making this change gives us the following code:

```tut:book:silent
object predicate {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.semigroup._ // |+|
  import cats.syntax.cartesian._ // |@|

  sealed trait Predicate[E,A] {
    import cats.data.Validated._ // Valid and Invalid

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

Now `Check` will represent something we build from a `Predicate`
that also allows transformation of its input.

Implement `Check` with the following interface.
*Hint:* use the same strategy we used for implementing `Predicate`.

```scala
sealed trait Check[E,A,B] {
  def map[C](f: B => C): Check[E,A,C] =
    ???

  def apply(in: A): Validated[E,B] =
    ???
}
```

<div class="solution">
If you follow the same strategy as `Predicate`
you should be able to create code similar to the below.

```tut:book:silent
object check {
  import cats.Semigroup
  import cats.data.Validated

  import predicate._

  sealed trait Check[E,A,B] {
    def map[C](f: B => C): Check[E,A,C] =
      Map[E,A,B,C](this, f)

    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,B]
  }
  object Check {
    def apply[E,A](pred: Predicate[E,A]): Check[E,A,A] =
      Pure(pred)
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

What about `flatMap`?
The semantics are a bit unclear here.
It's simple enough to define

```scala
def flatMap[C](f: B => Check[E,A,C]): Check[E,A,C] =
  FlatMap(this, f)
```

along with an appropriate definition of `FlatMap`.
However it isn't so obvious what this means
or how we should implement `apply` for this case.
Have a think about this before reading on.

The general shape of `flatMap` is

```
[.] flatMap . => [^] == [^]
```

Now `Check` has *three* type variables,
while `Monad` only has one.
So to make `Check` a `Monad` we need to fix two of those variables.
The idiomatic choices are to fix the error type `E`
and the input type `A`. This gives us a diagram

```
. => [%] flatMap % => (. => [^]) == . => [^]
```

In words, the semantics of applying a `FlatMap` are:

- given an input of type `A`, convert to a `B` in a context;
- use the output value of type `B` to choose a `Check[E,A,C]`;
- now apply the *original* input of type `A`
  to the chosen check and return the output of type `C` in a context.

This is quite an odd method.
We can implement it, but it is hard to find a use for it.
Go ahead and implement `flatMap` for `Check`,
and then we'll see a more generally useful method.

<div class="solution">
It's the same implementation strategy as before with one wrinkle:
`Validated` doesn't have a `flatMap` method.
To implement `flatMap` we must momentarily switch to `Either`
and then switch back to `Validated`.
The `withEither` method on `Validated` does exactly this.
From here we can just follow the types to implement `apply`.

```tut:book:silent
object check {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.either._

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
      check(in).withEither { _.flatMap (a => f(a)(in).toEither) }
  }
}
```
</div>

A more useful method chains together two `Checks`,
so the output of the first is connected to the input of the second.
This is analogous to function composition.
With two functions `f: A => B` and `g: B => C` we can write

```scala
f andThen g
```

to get a function with type `A => C`.
A `Check` is basically a function `A => Validated[E,B]`
so we can define an analagous `andThen` method on it.
Its signature is

```scala
def andThen[C](f: Check[E,B,C]): Check[E,A,C]
```

Implement `andThen`.

To complete our implementation we should add some constructors---generally
`apply` methods on the companion objects---for `Predicate` and `Check`.
Here's the complete implementation I ended up with,
which includes some tidying up of the code.

```tut:book:silent
object predicate {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.semigroup._ // |+|
  import cats.syntax.cartesian._ // |@|

  sealed trait Predicate[E,A] {
    import Predicate._
    import cats.data.Validated._ // Valid and Invalid

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
  object Predicate {
    final case class And[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A]
    final case class Or[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A]
    final case class Pure[E,A](f: A => Validated[E,A]) extends Predicate[E,A]

    def apply[E,A](f: A => Validated[E,A]): Predicate[E,A] =
      Pure(f)

    def lift[E,A](msg: E)(pred: A => Boolean): Predicate[E,A] =
      Pure { (a: A) =>
        if(pred(a))
          Validated.valid(a)
        else
          Validated.invalid(msg)
      }
  }
}

object check {
  import cats.Semigroup
  import cats.data.Validated
  import cats.syntax.either._

  import predicate._

  sealed trait Check[E,A,B] {
    import Check._

    def map[C](f: B => C): Check[E,A,C] =
      Map[E,A,B,C](this, f)

    def flatMap[C](f: B => Check[E,A,C]) =
      FlatMap[E,A,B,C](this, f)

    def andThen[C](next: Check[E,B,C]): Check[E,A,C] =
      AndThen[E,A,B,C](this, next)

    def apply(in: A)(implicit s: Semigroup[E]): Validated[E,B]
  }
  object Check {
    final case class Map[E,A,B,C](check: Check[E,A,B], f: B => C) extends Check[E,A,C] {
      def apply(in: A)(implicit s: Semigroup[E]): Validated[E,C] =
        check(in) map f
    }
    final case class FlatMap[E,A,B,C](check: Check[E,A,B], f: B => Check[E,A,C]) extends Check[E,A,C] {
      def apply(in: A)(implicit s: Semigroup[E]): Validated[E,C] =
        check(in).withEither { _.flatMap (b => f(b)(in).toEither) }
    }
    final case class AndThen[E,A,B,C](check: Check[E,A,B], next: Check[E,B,C]) extends Check[E,A,C] {
      def apply(in: A)(implicit s: Semigroup[E]): Validated[E,C] =
        check(in).withEither { _.flatMap (b => next(b).toEither) }
    }
    final case class Pure[E,A,B](f: A => Validated[E,B]) extends Check[E,A,B] {
      def apply(in: A)(implicit s: Semigroup[E]): Validated[E,B] =
        f(in)
    }
    final case class PurePredicate[E,A,B](predicate: Predicate[E,A]) extends Check[E,A,A] {
      def apply(in: A)(implicit s: Semigroup[E]): Validated[E,A] =
        predicate(in)
    }

    def apply[E,A](predicate: Predicate[E,A]): Check[E,A,A] =
      PurePredicate(predicate)

    def apply[E,A,B](f: A => Validated[E,B]): Check[E,A,B] =
      Pure(f)
  }
}
```

We now have an implementation of `Check` and `Predicate`
that combined do most of what we originally set out to do.
However we are not finished yet.
You have probably recognised structure in `Predicate` and `Check`
that we can abstract over:
`Predicate` has a monoid, and `Check` has a monad.
Furthermore, in implementing `Check` you might have felt
the implementation doesn't really do much---all
we do in `apply` is call through to the underlying methods on `Predicate` and `Validated`.
It feels to me there are a lot of ways this library could be cleaned up.
Let's implement some examples
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

You might find the following predicates useful.

```tut:book:silent
object example {
  import cats.data.{NonEmptyList,OneAnd,Validated}
  import cats.instances.list._
  import cats.syntax.cartesian._
  import cats.syntax.validated._
  import check._
  import predicate._

  type Error = NonEmptyList[String]
  def error(s: String): NonEmptyList[String] =
    NonEmptyList(s, Nil)

  // Utilities. We could implement all the checks using regular expressions but
  // this shows off the compositionality of the library.
  def longerThan(n: Int): Predicate[Error,String] =
    Predicate.lift(error(s"Must be longer than $n characters")){ _.size > n }

  val alphanumeric: Predicate[Error,String] =
    Predicate.lift(error(s"Must be all alphanumeric characters")){
      _.forall(_.isLetterOrDigit)
    }

  def contains(char: Char): Predicate[Error,String] =
    Predicate.lift(error(s"Must contain the character $char")){ _.contains(char) }

  def containsOnce(char: Char): Predicate[Error,String] =
    Predicate.lift(error(s"Must contain the character $char only once")){
      _.filter(c => c == char).size == 1
    }
}
```

<div class="solution">

Here's my solution.
Implementing this required more thought than I expected---switching
between `Check` and `Predicate` at the appropriate places
felt a bit like guesswork till I got the rule into my head
that `Predicate` doesn't transform its input.
With that in mind things went fairly smoothly.
In later sections we'll make some changes
that make the library easier to use.

```tut:book:silent
object example {
  import cats.data.{NonEmptyList,OneAnd,Validated}
  import cats.instances.list._
  import cats.syntax.cartesian._
  import cats.syntax.validated._
  import check._
  import predicate._

  type Error = NonEmptyList[String]
  def error(s: String): NonEmptyList[String] =
    NonEmptyList(s, Nil)

  // Utilities. We could implement all the checks using regular expressions but
  // this shows off the compositionality of the library.
  def longerThan(n: Int): Predicate[Error,String] =
    Predicate.lift(error(s"Must be longer than $n characters")){ _.size > n }

  val alphanumeric: Predicate[Error,String] =
    Predicate.lift(error(s"Must be all alphanumeric characters")){ _.forall(_.isLetterOrDigit) }

  def contains(char: Char): Predicate[Error,String] =
    Predicate.lift(error(s"Must contain the character $char")){ _.contains(char) }

  def containsOnce(char: Char): Predicate[Error,String] =
    Predicate.lift(error(s"Must contain the character $char only once")){
      _.filter(c => c == char).size == 1
    }

  // A username must contain at least four characters and consist entirely of
  // alphanumeric characters
  val checkUsername: Check[Error,String,String] =
    Check(longerThan(3) and alphanumeric)

  // An email address must contain a single `@` sign. Split the string at the
  // `@`. The string to the left must not be empty. The string to the right must
  // be at least three characters long and contain a dot.
  val checkEmailAddress: Check[Error,String,String] =
    Check { (string: String) =>
      string split '@' match {
        case Array(name, domain) => (name, domain).validNel[String]
        case other => "Must contain a single @ character".invalidNel[(String,String)]
      }
    } andThen Check[Error,(String,String),(String,String)] { case (name, domain) =>
        ((longerThan(0))(name) |@| (longerThan(3) and contains('.'))(domain)).tupled
    } map {
      case (name, domain) => s"${name}@${domain}"
    }

  final case class User(name: String, email: String)
  def makeUser(name: String, email: String): Validated[Error,User] =
    (checkUsername(name) |@| checkEmailAddress(email)) map (User.apply _)

  def go() = {
    println(makeUser("Noel", "noel@underscore.io"))
    println(makeUser("", "noel@underscore@io"))
  }

}
```
</div>
