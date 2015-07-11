## Monads in Scalaz

It's time to give monads our standard Scalaz treatment. As usual we'll look at the type class, instances, and syntax.

### The *Monad* Type Class {#monad-type-class}

The monad type class is [`scalaz.Monad`][scalaz.Monad]. `Monad` extends `Applicative`, which we'll discuss later, and `Bind`, which defines the `bind` method.

The main methods on `Monad` are `point` and `bind`. As we saw in the last section, `bind` is our `flatMap` operation and `point` is our constructor:

~~~ scala
import scalaz.Monad
import scalaz.std.option._
import scalaz.std.list._

Monad[Option].point(3)
// res0: Option[Int] = Some(3)

Monad[List].point(3)
// res1: List[Int] = List(3)

Monad[List].bind(List(1, 2, 3))(x => List(x, x*10))
// res2: List[Int] = List(1, 10, 2, 20, 3, 30)
~~~

`Monad` provides all of the methods from `Functor`, including `map` and `lift`, and adds plenty of new methods as well. Here are a couple of examples:

The `tupleN` methods convert a tuple of monads into a monad of tuples:

~~~ scala
val tupled: Option[(Int, String, Double)] =
  Monad[Option].tuple3(some(1), some("hi"), some(3.0))
~~~

The `sequence` method converts a type like `F[G[A]]` to `G[F[A]]`. For example, we can convert a `List[Option[Int]]` to a `Option[List[Int]]`:

~~~ scala
val sequence: Option[List[Int]] =
  Monad[Option].sequence(List(some(1), some(2), some(3)))
~~~

`sequence` requires an instance of [`scalaz.Traversable`][scalaz.Traversable] to be in scope.

### Default Instances

Scalaz provides instances for all the monads in the standard library (`Option`, `List`, `Vector` and so on) via `scalaz.std`:

~~~ scala
Monad[Option].bind(some(1))(x => some(x*2))
// res4: Option[Int] = Some(2)

Monad[List].bind(List(1, 2, 3))(x => List(x, x*10))
// res5: List[Int] = List(1, 10, 2, 20, 3, 30)

Monad[Vector].bind(Vector(1, 2, 3))(x => Vector(x, x*10))
// res6: Vector[Int] = Vector(1, 10, 2, 20, 3, 30)
~~~

There are also some Scalaz-specific instances that we'll see later on.

### Defining Custom Instances

We can define a `Monad` for a custom type simply by providing the implementations of `bind` and `point`. Other methods such as `map` are provided for us based on these definitions.

Here is an implementation of `Monad` for `Option` as an example. Note that the `point` method takes a by-name argument:

~~~ scala
val optionMonad = new Monad[Option] {
  def bind[A, B](value: Option[A])(func: A => Option[B]): Option[B] =
    value flatMap func

  def point[A](value: => A): Option[A] =
    Some(A)
}
~~~

### *Monad* Syntax

`scalaz.syntax.monad` provides us with syntax versions of `flatMap` and `point`, as well as `map` and `lift` from `scalaz.syntax.functor`.

It's difficult to demonstrate the `flatMap` and `map` directly on Scala monads, because most of them already define these methods explicitly. Instead we'll write a contrived generic function that returns `3*3 + 4*4` wrapped in a monad of the user's choice:

~~~ scala
import scalaz.Monad
import scalaz.std.option._
import scalaz.std.list._
import scalaz.syntax.monad._

def sumSquare[A[_] : Monad]: A[Int] = {
  val a = 3.point[A]
  val b = 4.point[A]
  a flatMap (x => b map (y => x*x + y*y))
}

sumSquare[Option]
// res7: Option[Int] = Some(25)

sumSquare[List]
// res8: List[Int] = List(25)
~~~

We can rewrite this code using for comprehensions. The Scala compiler will "do the right thing" by rewriting our comprehension in terms of `flatMap` and `map` and inserting the correct implicit conversions to use our `Monad`:

~~~ scala
def sumSquare[A[_] : Monad]: A[Int] = {
  for {
    x <- 3.point[A]
    y <- 4.point[A]
  } yield x*x + y*y
}

sumSquare[Option]
// res9: Option[Int] = Some(25)

sumSquare[List]
// res10: List[Int] = List(25)
~~~

### Exercise: My Monad is Way More Valid Than Your Functor

Let's write a `Monad` for our `Result` data type from last chapter:

~~~ scala
sealed trait Result[+A]
final case class Success[A](value: A) extends Result[A]
final case class Warning[A](value: A, message: String) extends Result[A]
final case class Failure(message: String) extends Result[Nothing]
~~~

Assume similar fail-fast semantics to the `Functor` we wrote previously: apply the mapping function to `Successes` and `Warnings` and return `Failures` unaltered.

Verify that the code works on instances of `Success`, `Warning`, and `Failure`, and that the `Monad` provides `Functor`-like behaviour for free.

Finally, verify that having a `Monad` in scope allows us to use for comprehensions, despite the fact that we haven't directly implemented `flatMap` or `map` on `Result`.

<div class="solution">
We'll keep the same semantics as our previous `Functor`---apply the mapping function to instances of `Success` and `Warning` but not `Failures`.

There is a wrinkle here. What should we do when we `flatMap` from a `Warning` to another `Result`? Do we keep the message from the old warning? Do we throw it away? Do we ignore any new error messages and stick with the original?

This is a design decision. The "correct" answer depends on the semantics we want to create. This ambiguity perhaps indicates why types like our `Result` are not more commonly available in libraries.

In this solution we'll opt to preserve all messages as we go. You may choose different semantics. This will give you different results from your tests, which is fine.

~~~ scala
import scalaz.Monad

implicit val resultMonad = new Monad[Result] {
  def bind[A, B](result: Result[A])(func: A => Result[B]): Result[B] =
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

  def point[A](value: => A): Result[A] =
    Success(value)
}
~~~

We'll pre-empt any compile errors concerning variance by defining our usual smart constructors:

~~~ scala
def success[A](value: A): Result[A] = Success(value)
def warning[A](value: A, message: String): Result[A] = Warning(value, message)
def failure[A](message: String): Result[A] = Failure(message)
~~~

Now we can use our `Monad` to `flatMap` and `map`:

~~~ scala
import scalaz.syntax.monad._

warning(100, "Message1") flatMap (x => Warning(x*2, "Message2"))
// res11: Result[Int] = Warning(200, "Message1 Message2")

warning(10, "Too low") map (_ - 5)
// res12: Result[Int] = Warning(20, "Too low")
~~~

We can also `Results` in for comprehensions:

~~~ scala
for {
  a <- success(1)
  b <- warning(2, "Message1")
  c <- warning(a + b, "Message2")
} yield c * 10
// res13: Result[Int] = Warning(30, "Message1 Message2")
~~~
</div>
