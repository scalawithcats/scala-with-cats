## Monads in Cats

It's time to give monads our standard Cats treatment. As usual we'll look at the type class, instances, and syntax.

### The *Monad* Type Class {#monad-type-class}

The monad type class is [`cats.Monad`][cats.Monad]. `Monad` extends two other type classes: `FlatMap`, which provides the `flatMap` method, and `Applicative`, which extends `Functor`. We'll discuss `Applicatives` in a later chapter.

The main methods on `Monad` are `pure` and `flatMap`:

```scala
import cats.Monad
// import cats.Monad

import cats.std.option._
// import cats.std.option._

import cats.std.list._
// import cats.std.list._

val opt1 = Monad[Option].pure(3)
// opt1: Option[Int] = Some(3)

val opt2 = Monad[Option].flatMap(opt1)(a => Some(a + 2))
// opt2: Option[Int] = Some(5)

val list1 = Monad[List].pure(3)
// list1: List[Int] = List(3)

val list2 = List(1, 2, 3)
// list2: List[Int] = List(1, 2, 3)

val list3 = Monad[List].flatMap(list2)(x => List(x, x*10))
// list3: List[Int] = List(1, 10, 2, 20, 3, 30)
```

`Monad` provides all of the methods from `Functor`, including `map` and `lift`, and adds plenty of new methods as well. Here are a couple of examples:

The `tupleN` methods convert a tuple of monads into a monad of tuples:

```scala
val tupled: Option[(Int, String, Double)] =
  Monad[Option].tuple3(Option(1), Option("hi"), Option(3.0))
// tupled: Option[(Int, String, Double)] = Some((1,hi,3.0))
```

The `sequence` method converts a type like `F[G[A]]` to `G[F[A]]`. For example, we can convert a `List[Option[Int]]` to a `Option[List[Int]]`:

```scala
val sequence: Option[List[Int]] =
  Monad[Option].sequence(List(Option(1), Option(2), Option(3)))
// sequence: Option[List[Int]] = Some(List(1, 2, 3))
```

`sequence` requires an instance of [`cats.Traversable`][cats.Traversable] to be in scope.

### Default Instances

Cats provides instances for all the monads in the standard library (`Option`, `List`, `Vector` and so on) via [`cats.std`][cats.std]:

```scala
import cats.std.option._
// import cats.std.option._

Monad[Option].flatMap(Option(1))(x => Option(x*2))
// res0: Option[Int] = Some(2)

import cats.std.list._
// import cats.std.list._

Monad[List].flatMap(List(1, 2, 3))(x => List(x, x*10))
// res1: List[Int] = List(1, 10, 2, 20, 3, 30)

import cats.std.vector._
// import cats.std.vector._

Monad[Vector].flatMap(Vector(1, 2, 3))(x => Vector(x, x*10))
// res2: Vector[Int] = Vector(1, 10, 2, 20, 3, 30)
```

There are also some Cats-specific monad instances that we'll see later on.

### Defining Custom Instances

We can define a `Monad` for a custom type simply by providing the implementations of `flatMap` and `pure`. Other methods such as `map` are provided for us based on these definitions.

Here is an implementation of `Monad` for `Option` as an example:

```scala
val optionMonad = new Monad[Option] {
  def flatMap[A, B](value: Option[A])(func: A => Option[B]): Option[B] =
    value flatMap func

  def pure[A](value: A): Option[A] =
    Some(value)
}
// optionMonad: cats.Monad[Option] = $anon$1@5b1dd6dd
```

### *Monad* Syntax

The syntax for monads comes from three places:

 - [`cats.syntax.flatMap`][cats.syntax.flatMap] provides syntax for `flatMap`;
 - [`cats.syntax.functor`][cats.syntax.functor] provides syntax for `map`;
 - [`cats.syntax.applicative`][cats.syntax.applicative] provides syntax for `pure`.

In practice it's often easier to import everything in one go from [`cats.implicits`][cats.implicits]. However, we'll use the individual imports here for clarity.

It's difficult to demonstrate the `flatMap` and `map` directly on Scala monads like `Option` and `List`, because they define their own explicit versions of those methods. Instead we'll write a contrived generic function that returns `3*3 + 4*4` wrapped in a monad of the user's choice:

```scala
import scala.language.higherKinds
// import scala.language.higherKinds

import cats.Monad
// import cats.Monad

import cats.syntax.functor._
// import cats.syntax.functor._

import cats.syntax.flatMap._
// import cats.syntax.flatMap._

import cats.syntax.applicative._
// import cats.syntax.applicative._

def sumSquare[A[_] : Monad](a: Int, b: Int): A[Int] = {
  val x = a.pure[A]
  val y = a.pure[A]
  x flatMap (x => y map (y => x*x + y*y))
}
// sumSquare: [A[_]](a: Int, b: Int)(implicit evidence$1: cats.Monad[A])A[Int]

import cats.std.option._
// import cats.std.option._

import cats.std.list._
// import cats.std.list._

sumSquare[Option](3, 4)
// res3: Option[Int] = Some(18)

sumSquare[List](3, 4)
// res4: List[Int] = List(18)
```

We can rewrite this code using for comprehensions. The Scala compiler will "do the right thing" by rewriting our comprehension in terms of `flatMap` and `map` and inserting the correct implicit conversions to use our `Monad`:

```scala
def sumSquare[A[_] : Monad](a: Int, b: Int): A[Int] = {
  for {
    x <- a.pure[A]
    y <- b.pure[A]
  } yield x*x + y*y
}
// sumSquare: [A[_]](a: Int, b: Int)(implicit evidence$1: cats.Monad[A])A[Int]

sumSquare[Option](3, 4)
// res5: Option[Int] = Some(25)

sumSquare[List](3, 4)
// res6: List[Int] = List(25)
```

### Exercise: My Monad is Way More Valid Than Your Functor

Let's write a `Monad` for our `Result` data type from last chapter:

```scala
sealed trait Result[+A]
// defined trait Result

final case class Success[A](value: A) extends Result[A]
// defined class Success

final case class Warning[A](value: A, message: String) extends Result[A]
// defined class Warning

final case class Failure(message: String) extends Result[Nothing]
// defined class Failure
```

Assume similar fail-fast semantics to the `Functor` we wrote previously: apply the mapping function to `Successes` and `Warnings` and return `Failures` unaltered.

Verify that the code works on instances of `Success`, `Warning`, and `Failure`, and that the `Monad` provides `Functor`-like behaviour for free.

Finally, verify that having a `Monad` in scope allows us to use for comprehensions, despite the fact that we haven't directly implemented `flatMap` or `map` on `Result`.

<div class="solution">
We'll keep the same semantics as our previous `Functor`---apply the mapping function to instances of `Success` and `Warning` but not `Failures`.

There is a wrinkle here. What should we do when we `flatMap` from a `Warning` to another `Result`? Do we keep the message from the old warning? Do we throw it away? Do we ignore any new error messages and stick with the original?

This is a design decision. The "correct" answer depends on the semantics we want to create. This ambiguity perhaps indicates why types like our `Result` are not more commonly available in libraries.

In this solution we'll opt to preserve all messages as we go. You may choose different semantics. This will give you different results from your tests, which is fine.

```scala
import cats.Monad
// import cats.Monad

implicit val resultMonad = new Monad[Result] {
  def pure[A](value: A): Result[A] =
    Success(value)

  def flatMap[A, B](result: Result[A])(func: A => Result[B]): Result[B] =
    result match {
      case Success(value) =>
        func(value)
      case Warning(value, message1) =>
        func(value) match {
          case Success(value) =>
            Warning(value, message1)
          case Warning(value, message2) =>
            Warning(value, s"$message1 $message2")
          case Failure(message2) =>
            Failure(s"$message1 $message2")
        }
      case Failure(message) =>
        Failure(message)
    }
}
// resultMonad: cats.Monad[Result] = $anon$1@69f9dfcf
```

We'll pre-empt any compile errors concerning variance by defining our usual smart constructors:

```scala
def success[A](value: A): Result[A] =
  Success(value)
// success: [A](value: A)Result[A]

def warning[A](value: A, message: String): Result[A] =
  Warning(value, message)
// warning: [A](value: A, message: String)Result[A]

def failure[A](message: String): Result[A] =
  Failure(message)
// failure: [A](message: String)Result[A]
```

Now we can use our `Monad` to `flatMap` and `map`:

```scala
import cats.syntax.functor._
// import cats.syntax.functor._

import cats.syntax.flatMap._
// import cats.syntax.flatMap._

warning(100, "Message1") flatMap (x => Warning(x*2, "Message2"))
// res7: Result[Int] = Warning(200,Message1 Message2)

warning(10, "Too low") map (_ - 5)
// res8: Result[Int] = Warning(5,Too low)
```

We can also `Results` in for comprehensions:

```scala
for {
  a <- success(1)
  b <- warning(2, "Message1")
  c <- warning(a + b, "Message2")
} yield c * 10
// res9: Result[Int] = Warning(30,Message1 Message2)
```
</div>
