## Kleislis

Let's start cleaning up the library by looking at `Check`. A justifiable criticism is that we've written a lot of code to do very little. A `Predicate` is essentially a function `A => Validated[E,A]`, and a `Check` is basically a wrapper that lets us compose these functions.

We can abstract `A => Validated[E,A]` to `A => F[B]`, which you'll recognise as the type of function you pass to the `flatMap` method on a monad. Imagine we have the following sequence of operations:

- We lift some value into a monad (by using `pure`, for example). This is a function with type `A => F[A]`.
- We then sequence some transformations on the monad using `flatMap`.

We can diagram this as

* (* => [*]) flatMap (* => [^]) flatMap (^ => [%]) *

To implement this with the monad API we could write a method like

```scala
def example[A](a: A): C =
  a.pure[F] flatMap aToB flatMap bToC
```

Now recall that `Check` is in the abstract allowing us to compose functions of type `A => F[B]`. We could write the above in terms of `andThen` as

```scala
((aToB) andThen (bToC))
```

to obtain a (wrapped) function of type `A => F[C]` which we can then apply to a value of type `A`. We have achieved the same thing as the method `example` above without having to define a method. The `andThen` method on `Check` is analogous to function composition, but is composing function `A => F[B]` instead of `A => B`.

The abstract concept of composing functions of type `A => F[B]` has a name: a *Kleisli*. We can replace all our uses of `Check` with it. It has all the methods on `Check`, and some additional ones. Here is a simple example of `Kleisli`, transforming an integer into a list of integers through three steps.

```scala
object kleisli {
  import cats.data.Kleisli
  import cats.instances.list._

  // To make the code more concise
  // A Kleisli that transforms an Int to a List[Int]
  type ToListT[A,B] = Kleisli[List,A,B]

  // Define a few functions that transform an integer to a list of integers
  val incrementAndDecrement: ToListT[Int,Int] =
    Kleisli(x => List(x + 1, x - 1))
  val doubleAndHalve: ToListT[Int,Int] =
    Kleisli(x => List(x * 2, x / 2))
  val valueAndNegation: ToListT[Int,Int] =
    Kleisli(x => List(x, -x))

  // Compose into a transformation pipeline
  val pipeline = incrementAndDecrement andThen valueAndNegation andThen doubleAndHalve

  // Apply the pipeline to data
  val result = pipeline.run(20)
}
// defined object kleisli

kleisli.result
// res0: List[Int] = List(42, 10, -42, -10, 38, 9, -38, -9)
```

Now let's use `Kleisli` in our examples where we had previously used `Check`. To do so we need to make a few changes to `Predicate`. We must be able to convert a `Predicate` to a function, as `Klesii` only works with functions. Somewhat more subtly, when we convert a `Predicate` to a function, it should have type `A => Xor[E,A]` rather than `A => Validated[E,A]`. Why is this? Remember that in the implementation of `andThen` we converted the `Validated` to an `Xor` so we could call its `flatMap` method. It's exactly the same in the `Kleisli`---it must be able to `flatMap` on the function's return type so it can implement sequencing.

In this design `Predicate` uses `Validated` internally---where it is joining together predicates using `and` and `or`---but exposes `Xor` externally so results can be sequenced.

Implement this.

<div class="solution">
I chose to implement the conversion to a function as a method named `run` (following the convention of `run` on `Kleisli` and other similar methods within Cats). This method must, like `apply`, accept an implicit `Semigroup`. Here's the complete code.

```scala
object predicate {
  import cats.Semigroup
  import cats.data.{Validated,Xor}
  import cats.syntax.semigroup._ // For |+|
  import cats.syntax.monoidal._ // For |@|

  sealed trait Predicate[E,A] {
    import Predicate._
    import cats.data.Validated._ // For Valid and Invalid

    def and(that: Predicate[E,A]): Predicate[E,A] =
      And(this, that)

    def or(that: Predicate[E,A]): Predicate[E,A] =
      Or(this, that)

    def run(implicit s: Semigroup[E]): A => Xor[E,A] =
      (a: A) => this.apply(a).toXor

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
```
</div>

Now we can rewrite our email address validation example in terms of `Kleisli` and `Predicate`. Do this now. A few tips:

- Remember that `Predicate#run` has an implicit parameter. If you call `aPredicate.run(a)` that will try to pass the implicit parameter explicitly. If you want to create a function from a `Predicate` and immediately apply that function, use `aPredicate.run.apply(a)`
- I found that type inference failed quite badly for `Kleisli`, and the following definitions allowed me to write code with fewer type declarations.

```scala
type Result[A] = Xor[Error,A]
type Check[A,B] = Kleisli[Result,A,B]
// This constructor helps with type inference
def Check[A,B](f: A => Result[B]): Check[A,B] =
  Kleisli(f)
```

<div class="solution">
Working around limitations of type inference was annoying when writing this code, and remembering to convert between `Validated` and `Xor` was also a bit less mechanical than I'd like. I'm unhappy with the line

```scala
((longerThan(0).run.apply(name)).toValidated |@|
   (longerThan(3) and contains('.')).run.apply(domain).toValidated).tupled.toXor
```

This is more complex than it should be. We'll discuss this soon enough. For now, here's the working code.

```scala
object example {
  import cats.data.{Kleisli,NonEmptyList,OneAnd,Validated,Xor}
  import cats.instances.list._
  import cats.instances.function._
  import cats.syntax.monoidal._
  import cats.syntax.validated._
  import predicate._

  type Error = NonEmptyList[String]
  def error(s: String): NonEmptyList[String] =
    OneAnd(s, Nil)

  type Result[A] = Xor[Error,A]
  type Check[A,B] = Kleisli[Result,A,B]
  // This constructor helps with type inference, which fails miserably in many cases below
  def Check[A,B](f: A => Result[B]): Check[A,B] =
    Kleisli(f)

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
  val checkUsername: Check[String,String] =
    Check((longerThan(3) and alphanumeric).run)

  // An email address must contain a single `@` sign. Split the string at the
  // `@`. The string to the left must not be empty. The string to the right must
  // be at least three characters long and contain a dot.
  val checkEmailAddress: Check[String,String] =
    Check { (string: String) =>
      string split '@' match {
        case Array(name, domain) => (name, domain).validNel[String].toXor
        case other => "Must contain a single @ character".invalidNel[(String,String)].toXor
      }
    } andThen Check[(String,String),(String,String)] { case (name, domain) =>
        ((longerThan(0).run.apply(name)).toValidated |@|
           (longerThan(3) and contains('.')).run.apply(domain).toValidated).tupled.toXor
    } map {
      case (name, domain) => s"${name}@${domain}"
    }

  final case class User(name: String, email: String)
  def makeUser(name: String, email: String): Xor[Error,User] =
    (checkUsername.run(name) |@| checkEmailAddress.run(email)) map (User.apply _)

  def go() = {
    println(makeUser("Noel", "noel@underscore.io"))
    println(makeUser("", "noel@underscore@io"))
  }

}
```
</div>

We have now written our code entirely in terms of `Kleisli` and `Predicate`, completely removing `Check`. This is a good first step to simplifying our library. It still feels a bit too difficult to work with `Predicate`, so let's see if we can simplify that a bit. There are a few issues:

Creating an `Predicate` from a function (the `apply` method on the companion object) is overly restrictive. We don't really care what type the function returns on success because in `apply` we ensure the input is always returned.

It would be useful to be able to join together two predicates, so if we have `Predicate[E,A]` and `Predicate[E,B]` we can create `Predicate[E,(A,B)]`. This feels like an applicative (or a monoidal). However we aren't allowing `map` for predicates, as this makes the output type different to the input type, so we can't implement applicative (or usefully implement monoidal). I chose to implement a method called `zip` that achieves this. Adding the case class for `Zip` created a complicated enough GADT that type inference failed in `apply`. This forced me to switch to polymorphism.

Here's the complete code.

```scala
object predicate {
  import cats.{Monoidal,Semigroup}
  import cats.data.{Validated,Xor}
  import cats.syntax.semigroup._ // For |+|
  import cats.syntax.monoidal._ // For |@|

  sealed trait Predicate[E,A] {
    import Predicate._

    def and(that: Predicate[E,A]): Predicate[E,A] =
      And(this, that)

    def or(that: Predicate[E,A]): Predicate[E,A] =
      Or(this, that)

    def zip[B](that: Predicate[E,B]): Predicate[E,(A,B)] =
      Zip(this, that)

    def run(implicit s: Semigroup[E]): A => Xor[E,A] =
      (a: A) => this.apply(a).toXor

    def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A]
  }
  object Predicate {
    final case class And[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A] {
      def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A] =
        (left(a) |@| right(a)) map { (_, _) => a }
    }
    final case class Or[E,A](left: Predicate[E,A], right: Predicate[E,A]) extends Predicate[E,A] {
      def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A] =
      {
        import Validated._ // For Valid and Invalid
        left(a) match {
          case Valid(a1)   => Valid(a)
          case Invalid(e1) =>
            right(a) match {
              case Valid(a2)   => Valid(a)
              case Invalid(e2) => Invalid(e1 |+| e2)
            }
        }
      }
    }
    final case class Zip[E,A,B](left: Predicate[E,A], right: Predicate[E,B]) extends Predicate[E,(A,B)] {
      def apply(a: (A,B))(implicit s: Semigroup[E]): Validated[E,(A,B)] = {
        val (theA, theB) = a
        (left(theA) |@| right(theB)).tupled
      }
    }
    final case class Pure[E,A,B](f: A => Validated[E,B]) extends Predicate[E,A] {
      def apply(a: A)(implicit s: Semigroup[E]): Validated[E,A] =
        f(a) map (_ => a)
    }

    def apply[E,A,B](f: A => Validated[E,B]): Predicate[E,A] =
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
```

With this we implement the example quite clearly.

```scala
object example {
  import cats.data.{Kleisli,NonEmptyList,OneAnd,Validated,Xor}
  import cats.instances.list._
  import cats.instances.function._
  import cats.syntax.monoidal._
  import cats.syntax.validated._
  import predicate._

  type Error = NonEmptyList[String]
  def error(s: String): NonEmptyList[String] =
    OneAnd(s, Nil)

  type Result[A] = Xor[Error,A]
  type Check[A,B] = Kleisli[Result,A,B]
  // This constructor helps with type inference, which fails miserably in many cases below
  def Check[A,B](f: A => Result[B]): Check[A,B] =
    Kleisli(f)

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
  val checkUsername: Check[String,String] =
    Check((longerThan(3) and alphanumeric).run)

  // An email address must contain a single `@` sign. Split the string at the
  // `@`. The string to the left must not be empty. The string to the right must
  // be at least three characters long and contain a dot.
  val checkEmailAddress: Check[String,String] =
    Check { (string: String) =>
      string split '@' match {
        case Array(name, domain) => (name, domain).validNel[String].toXor
        case other => "Must contain a single @ character".invalidNel[(String,String)].toXor
      }
    } andThen Check[(String,String),(String,String)] {
        (longerThan(0) zip (longerThan(3) and contains('.'))).run
    } map {
      case (name, domain) => s"${name}@${domain}"
    }

  final case class User(name: String, email: String)
  def makeUser(name: String, email: String): Xor[Error,User] =
    (checkUsername.run(name) |@| checkEmailAddress.run(email)) map (User.apply _)

  def go() = {
    println(makeUser("Noel", "noel@underscore.io"))
    println(makeUser("", "noel@underscore@io"))
  }
}
```

