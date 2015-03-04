## Functors in Scalaz

Let's look at the implementation of functors in Scalaz. We'll follow the usual pattern of looking at the three main aspects of the implementation: the *type class*, the *instances*, and the *interface*.

### The *Functor* Type Class

The functor type class is [`scalaz.Functor`][scalaz.Functor]. We obtain instances using the standard `Functor.apply`. As usual, default instances are arranged by type in the [`scalaz.std`][scalaz.std] package:

~~~ scala
import scalaz.Functor
import scalaz.std.list._
import scalaz.std.option._

Functor[List].map(List(1, 2, 3))(x => x * 2)

Functor[Option].map(Some(123))(_.toString)
~~~

`Functor` also provides the `lift` method, which converts an function of type `A => B` to one that operates over a monad and has type `F[A] => F[B]`:

~~~ scala
val lifted = Functor[Option].lift((x: Int) => x + 1)
// lifted: Option[Int] => Option[Int] = <function1>

lifted(Some(1))
// res0: Option[Int] = Some(2)
~~~

### *Functor* Syntax

The main method provided by the syntax for `Functor` is `map`:

~~~ scala
import scalaz.std.option._
import scalaz.syntax.functor._

val f = ((a: Int) => a + 1) map ((a: Int) => a * 2)

f(123)
// res1: Int = 248
~~~

We can also use `lift` as an enriched method:

~~~ scala
val func = ((x: Int) => x + 1) lift Monad[Option]

func(some(1))
// res2: Option[Int] = Some(2)
~~~

Other methods are also available but we won't discuss them here. `Functors` are more important to us as building blocks for later abstrations than they are as a tool for direct use.

### Instances for Custom Types

We can define a functor simply by defining its map method. Here's an example of a `Functor` for `Option`, even though such a thing already exists in `scalaz.std`:

~~~ scala
val optionFunctor = new Functor[Option] {
  def map[A, B](value: Option[A])(func: A => B): Option[B] =
    value map func
}
~~~

The implementation is trivial---simply call `Option's` `map` method.

### Exercise: This Functor is Totally Valid

Imagine our application contains a custom validation type:

~~~ scala
sealed trait Result[+A]
final case class Success[A](value: A) extends Result[A]
final case class Warning[A](value: A, message: String) extends Result[A]
final case class Failure(message: String) extends Result[Nothing]
~~~

Write a `Functor` for this data type. Use similar fail-fast semantics to `Option`. Verify that the code works as expected on instances of `Success`, `Warning`, and `Failure`.

Note that we haven't specified what to do with `Warning`. Do we apply the mapping function or pass `Warnings` through unaltered? If you follow the types, you'll see that only one approach will work.

<div class="solution">
It is sensible to assume that we want to apply the `Functor's` mapping function to instances of `Success` and `Warning` but pass `Failures` straight through:

~~~ scala
import scalaz.Functor

implicit val resultFunctor = new Functor[Result] {
  def map[A, B](result: Result[A])(func: A => B): Result[B] =
    result match {
      case Success(value)          => Success(func(value))
      case Warning(value, message) => Warning(func(value), message)
      case Failure(message)        => Failure(message)
    }
}
~~~

Let's use our `Functor` in a sample application:

~~~ scala
Success(100) map (_ * 2)
// <console>:23: error: value map is not a member of Success[Int]
//               Success(100) map (_ * 2)
//                            ^
~~~

Oops! This is the same inavariance problem we saw with `Monoids`. Let's add some smart constructors to compensate:

~~~ scala
def success[A](value: A): Result[A] = Success(value)
def warning[A](value: A, message: String): Result[A] = Warning(value, message)
def failure[A](message: String): Result[A] = Failure(message)
~~~

Now we can use our `Functor` properly:

~~~ scala
success(100) map (_ * 2)
// res1: Result[Int] = Success(200)

warning(10, "Too low") map (_ * 2)
// res2: Result[Int] = Warning(20,Too low)

failure[Int]("Far too low") map (_ * 2)
// res3: Result[Int] = Failure(Far too low)
~~~
</div>
