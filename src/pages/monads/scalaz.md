## Monads in Cats

It's time to give monads our standard Cats treatment. As usual we'll look at the type class, instances, and syntax.

### The *Monad* Type Class {#monad-type-class}

The monad type class is [`cats.Monad`][cats.Monad]. `Monad` extends `Applicative`, which we'll discuss later, and `Bind`, which defines the `bind` method.

The main methods on `Monad` are `point` and `bind`. As we saw in the last section, `bind` is our `flatMap` operation and `point` is our constructor:

```scala
import cats.Monad
// import cats.Monad

import cats.std.option._
// import cats.std.option._

import cats.std.list._
// import cats.std.list._

Monad[Option].point(3)
// <console>:19: error: value point is not a member of cats.Monad[Option]
//        Monad[Option].point(3)
//                      ^

// res0: Option[Int] = Some(3)

Monad[List].point(3)
// <console>:21: error: value point is not a member of cats.Monad[List]
//        Monad[List].point(3)
//                    ^
// res1: List[Int] = List(3)

Monad[List].bind(List(1, 2, 3))(x => List(x, x*10))
// <console>:23: error: value bind is not a member of cats.Monad[List]
//        Monad[List].bind(List(1, 2, 3))(x => List(x, x*10))
//                    ^
// res2: List[Int] = List(1, 10, 2, 20, 3, 30)
```

`Monad` provides all of the methods from `Functor`, including `map` and `lift`, and adds plenty of new methods as well. Here are a couple of examples:

The `tupleN` methods convert a tuple of monads into a monad of tuples:

```scala
val tupled: Option[(Int, String, Double)] =
  Monad[Option].tuple3(some(1), some("hi"), some(3.0))
// <console>:24: error: not found: value some
//          Monad[Option].tuple3(some(1), some("hi"), some(3.0))
//                               ^
// <console>:24: error: not found: value some
//          Monad[Option].tuple3(some(1), some("hi"), some(3.0))
//                                        ^
// <console>:24: error: not found: value some
//          Monad[Option].tuple3(some(1), some("hi"), some(3.0))
//                                                    ^
```

The `sequence` method converts a type like `F[G[A]]` to `G[F[A]]`. For example, we can convert a `List[Option[Int]]` to a `Option[List[Int]]`:

```scala
val sequence: Option[List[Int]] =
// <console>:8: error: illegal start of simple expression
// val sequence: Option[List[Int]] =
// ^
  Monad[Option].sequence(List(some(1), some(2), some(3)))
// <console>:24: error: not found: value some
//          Monad[Option].sequence(List(some(1), some(2), some(3)))
//                                      ^
// <console>:24: error: not found: value some
//          Monad[Option].sequence(List(some(1), some(2), some(3)))
//                                               ^
// <console>:24: error: not found: value some
//          Monad[Option].sequence(List(some(1), some(2), some(3)))
//                                                        ^
```

`sequence` requires an instance of [`cats.Traversable`][cats.Traversable] to be in scope.

### Default Instances

Cats provides instances for all the monads in the standard library (`Option`, `List`, `Vector` and so on) via `cats.std`:

```scala
Monad[Option].bind(some(1))(x => some(x*2))
// <console>:24: error: value bind is not a member of cats.Monad[Option]
//        Monad[Option].bind(some(1))(x => some(x*2))
//                      ^
// <console>:24: error: not found: value some
//        Monad[Option].bind(some(1))(x => some(x*2))
//                           ^
// <console>:24: error: not found: value some
//        Monad[Option].bind(some(1))(x => some(x*2))
//                                         ^
// res4: Option[Int] = Some(2)

Monad[List].bind(List(1, 2, 3))(x => List(x, x*10))
// <console>:26: error: value bind is not a member of cats.Monad[List]
//        Monad[List].bind(List(1, 2, 3))(x => List(x, x*10))
//                    ^
// res5: List[Int] = List(1, 10, 2, 20, 3, 30)

Monad[Vector].bind(Vector(1, 2, 3))(x => Vector(x, x*10))
// <console>:28: error: could not find implicit value for parameter instance: cats.Monad[Vector]
//        Monad[Vector].bind(Vector(1, 2, 3))(x => Vector(x, x*10))
//             ^
// res6: Vector[Int] = Vector(1, 10, 2, 20, 3, 30)
```

There are also some Cats-specific instances that we'll see later on.

### Defining Custom Instances

We can define a `Monad` for a custom type simply by providing the implementations of `bind` and `point`. Other methods such as `map` are provided for us based on these definitions.

Here is an implementation of `Monad` for `Option` as an example. Note that the `point` method takes a by-name argument:

```scala
val optionMonad = new Monad[Option] {
// <console>:13: error: illegal start of simple expression
// val optionMonad = new Monad[Option] {
// ^
  def bind[A, B](value: Option[A])(func: A => Option[B]): Option[B] =
// <console>:13: error: illegal start of simple expression
//   def bind[A, B](value: Option[A])(func: A => Option[B]): Option[B] =
//   ^
    value flatMap func
// <console>:29: error: not found: value value
//            value flatMap func
//            ^
// <console>:29: error: not found: value func
//            value flatMap func
//                          ^

  def point[A](value: => A): Option[A] =
// <console>:14: error: illegal start of simple expression
//   def point[A](value: => A): Option[A] =
//   ^
    Some(A)
// <console>:30: error: not found: value A
//            Some(A)
//                 ^
}
// <console>:14: error: illegal start of simple expression
// }
// ^
```

### *Monad* Syntax

`cats.syntax.monad` provides us with syntax versions of `flatMap` and `point`, as well as `map` and `lift` from `cats.syntax.functor`.

It's difficult to demonstrate the `flatMap` and `map` directly on Scala monads, because most of them already define these methods explicitly. Instead we'll write a contrived generic function that returns `3*3 + 4*4` wrapped in a monad of the user's choice:

```scala
import cats.Monad
// <console>:14: error: illegal start of simple expression
// import cats.Monad
// ^
import cats.std.option._
// <console>:14: error: illegal start of simple expression
// import cats.std.option._
// ^
import cats.std.list._
// <console>:14: error: illegal start of simple expression
// import cats.std.list._
// ^
import cats.syntax.monad._
// <console>:14: error: illegal start of simple expression
// import cats.syntax.monad._
// ^

def sumSquare[A[_] : Monad]: A[Int] = {
// <console>:15: error: illegal start of simple expression
// def sumSquare[A[_] : Monad]: A[Int] = {
// ^
  val a = 3.point[A]
// <console>:15: error: illegal start of simple expression
//   val a = 3.point[A]
//   ^
  val b = 4.point[A]
// <console>:15: error: illegal start of simple expression
//   val b = 4.point[A]
//   ^
  a flatMap (x => b map (y => x*x + y*y))
// <console>:31: error: not found: value a
//          a flatMap (x => b map (y => x*x + y*y))
//          ^
// <console>:31: error: not found: value b
//          a flatMap (x => b map (y => x*x + y*y))
//                          ^
}
// <console>:15: error: illegal start of simple expression
// }
// ^

sumSquare[Option]
// <console>:32: error: not found: value sumSquare
//        sumSquare[Option]
//        ^
// res7: Option[Int] = Some(25)

sumSquare[List]
// <console>:34: error: not found: value sumSquare
//        sumSquare[List]
//        ^
// res8: List[Int] = List(25)
```

We can rewrite this code using for comprehensions. The Scala compiler will "do the right thing" by rewriting our comprehension in terms of `flatMap` and `map` and inserting the correct implicit conversions to use our `Monad`:

```scala
def sumSquare[A[_] : Monad]: A[Int] = {
// <console>:19: error: illegal start of simple expression
// def sumSquare[A[_] : Monad]: A[Int] = {
// ^
  for {
    x <- 3.point[A]
    y <- 4.point[A]
  } yield x*x + y*y
// <console>:36: error: value point is not a member of Int
//            x <- 3.point[A]
//                   ^
// <console>:36: error: not found: type A
//            x <- 3.point[A]
//                         ^
// <console>:37: error: value point is not a member of Int
//            y <- 4.point[A]
//                   ^
// <console>:37: error: not found: type A
//            y <- 4.point[A]
//                         ^
}

sumSquare[Option]
// <console>:36: error: value point is not a member of Int
//            x <- 3.point[A]
//                   ^
// <console>:36: error: not found: type A
//            x <- 3.point[A]
//                         ^
// <console>:37: error: value point is not a member of Int
//            y <- 4.point[A]
//                   ^
// <console>:37: error: not found: type A
//            y <- 4.point[A]
//                         ^
// <console>:40: error: not found: value sumSquare
//        sumSquare[Option]
//        ^
// res9: Option[Int] = Some(25)

sumSquare[List]
// <console>:36: error: value point is not a member of Int
//            x <- 3.point[A]
//                   ^
// <console>:36: error: not found: type A
//            x <- 3.point[A]
//                         ^
// <console>:37: error: value point is not a member of Int
//            y <- 4.point[A]
//                   ^
// <console>:37: error: not found: type A
//            y <- 4.point[A]
//                         ^
// <console>:42: error: not found: value sumSquare
//        sumSquare[List]
//        ^
// res10: List[Int] = List(25)
```

### Exercise: My Monad is Way More Valid Than Your Functor

Let's write a `Monad` for our `Result` data type from last chapter:

```scala
sealed trait Result[+A]
// <console>:27: error: illegal start of simple expression
// sealed trait Result[+A]
// ^
final case class Success[A](value: A) extends Result[A]
// <console>:27: error: illegal start of simple expression
// final case class Success[A](value: A) extends Result[A]
// ^
final case class Warning[A](value: A, message: String) extends Result[A]
// <console>:27: error: illegal start of simple expression
// final case class Warning[A](value: A, message: String) extends Result[A]
// ^
final case class Failure(message: String) extends Result[Nothing]
// <console>:27: error: illegal start of simple expression
// final case class Failure(message: String) extends Result[Nothing]
// ^
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
// <console>:27: error: illegal start of simple expression
// import cats.Monad
// ^

implicit val resultMonad = new Monad[Result] {
// <console>:28: error: identifier expected but 'val' found.
// implicit val resultMonad = new Monad[Result] {
//          ^
  def bind[A, B](result: Result[A])(func: A => Result[B]): Result[B] =
// <console>:28: error: illegal start of simple expression
//   def bind[A, B](result: Result[A])(func: A => Result[B]): Result[B] =
//   ^
    result match {
      case Success(value)           => func(value)
      case Failure(message)         => Failure(message)
      case Warning(value, message1) =>
        func(value) match {
          case Success(value) =>
            Warning(value, message1)
          case Warning(value, message2) =>
            Warning(value, s"$message1 $message2")
          case Failure(message2) =>
            Failure(s"$message1 $message2")
        }
    }
// <console>:36: error: value point is not a member of Int
//            x <- 3.point[A]
//                   ^
// <console>:36: error: not found: type A
//            x <- 3.point[A]
//                         ^
// <console>:37: error: value point is not a member of Int
//            y <- 4.point[A]
//                   ^
// <console>:37: error: not found: type A
//            y <- 4.point[A]
//                         ^
// <console>:44: error: not found: value result
//            result match {
//            ^
// <console>:45: error: not found: value Success
//              case Success(value)           => func(value)
//                   ^
// <console>:45: error: not found: value func
//              case Success(value)           => func(value)
//                                               ^
// <console>:46: error: not found: value Failure
//              case Failure(message)         => Failure(message)
//                   ^
// <console>:46: error: not found: value Failure
//              case Failure(message)         => Failure(message)
//                                               ^
// <console>:47: error: not found: value Warning
//              case Warning(value, message1) =>
//                   ^
// <console>:48: error: not found: value func
//                func(value) match {
//                ^
// <console>:49: error: not found: value Success
//                  case Success(value) =>
//                       ^
// <console>:50: error: not found: value Warning
//                    Warning(value, message1)
//                    ^
// <console>:51: error: not found: value Warning
//                  case Warning(value, message2) =>
//                       ^
// <console>:52: error: not found: value Warning
//                    Warning(value, s"$message1 $message2")
//                    ^
// <console>:53: error: not found: value Failure
//                  case Failure(message2) =>
//                       ^
// <console>:54: error: not found: value Failure
//                    Failure(s"$message1 $message2")
//                    ^

  def point[A](value: => A): Result[A] =
    Success(value)
}
// <console>:36: error: value point is not a member of Int
//            x <- 3.point[A]
//                   ^
// <console>:36: error: not found: type A
//            x <- 3.point[A]
//                         ^
// <console>:37: error: value point is not a member of Int
//            y <- 4.point[A]
//                   ^
// <console>:37: error: not found: type A
//            y <- 4.point[A]
//                         ^
// <console>:44: error: not found: value result
//            result match {
//            ^
// <console>:45: error: not found: value Success
//              case Success(value)           => func(value)
//                   ^
// <console>:45: error: not found: value func
//              case Success(value)           => func(value)
//                                               ^
// <console>:46: error: not found: value Failure
//              case Failure(message)         => Failure(message)
//                   ^
// <console>:46: error: not found: value Failure
//              case Failure(message)         => Failure(message)
//                                               ^
// <console>:47: error: not found: value Warning
//              case Warning(value, message1) =>
//                   ^
// <console>:48: error: not found: value func
//                func(value) match {
//                ^
// <console>:49: error: not found: value Success
//                  case Success(value) =>
//                       ^
// <console>:50: error: not found: value Warning
//                    Warning(value, message1)
//                    ^
// <console>:51: error: not found: value Warning
//                  case Warning(value, message2) =>
//                       ^
// <console>:52: error: not found: value Warning
//                    Warning(value, s"$message1 $message2")
//                    ^
// <console>:53: error: not found: value Failure
//                  case Failure(message2) =>
//                       ^
// <console>:54: error: not found: value Failure
//                    Failure(s"$message1 $message2")
//                    ^
// <console>:57: error: not found: type Result
//          def point[A](value: => A): Result[A] =
//                                     ^
// <console>:58: error: not found: value Success
//            Success(value)
//            ^
```

We'll pre-empt any compile errors concerning variance by defining our usual smart constructors:

```scala
def success[A](value: A): Result[A] = Success(value)
def warning[A](value: A, message: String): Result[A] = Warning(value, message)
def failure[A](message: String): Result[A] = Failure(message)
```

Now we can use our `Monad` to `flatMap` and `map`:

```scala
import cats.syntax.monad._

warning(100, "Message1") flatMap (x => Warning(x*2, "Message2"))
// res11: Result[Int] = Warning(200, "Message1 Message2")

warning(10, "Too low") map (_ - 5)
// res12: Result[Int] = Warning(20, "Too low")
```

We can also `Results` in for comprehensions:

```scala
for {
  a <- success(1)
  b <- warning(2, "Message1")
  c <- warning(a + b, "Message2")
} yield c * 10
// res13: Result[Int] = Warning(30, "Message1 Message2")
```
</div>
