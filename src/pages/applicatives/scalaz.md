## Applicatives in Scalaz

### The Applicative Type Class

The applicative type class in Scalaz is [`scalaz.Applicative`][scalaz.Applicative]. `Applicative` extends `Apply`, which is where the `ap` method is defined. `Applicative` itself defines `point` as we saw in the discussion of [the `Monad` type class](#monad-type-class).

### Obtaining Instances

As usual, we obtain instances via `Applicative.apply`:

~~~ scala
import scalaz.Applicative
import scalaz.std.option._
import scalaz.std.list._

val inc = (x: Int) => x + 2
// inc: Int => Int = <function1>

Applicative[Option].ap(Some(1))(Some(inc))
// res8: Option[Int] = Some(3)
~~~

In addition to `ap` and `point`, `Applicative` defines several helper methods. The `ap2` through `ap8` methods provide nested calls to `ap` for functions of 2 to 8 arguments:

~~~ scala
val sum3 = (a: Int, b: Int, c: Int) => a + b + c
// sum3: (Int, Int, Int) => Int = <function3>

Applicative[Option].ap3(Some(1), Some(2), Some(3))(Some(sum3))
// res9: Option[Int] = Some(6)
~~~

In addition, `apply` through `apply12` provide versions of `ap` that work with an unwrapped function parameters:

~~~ scala
Applicative[Option].apply3(Some(1), Some(2), Some(3))(sum3)
// res10: Option[Int] = Some(6)
~~~

The `lift` through `lift12` methods lift functions into the relevant applicative:

~~~ scala
val optSum3 = Applicative[Option].lift3(sum3)
// optSum3: (Option[Int], Option[Int], Option[Int]) => Option[Int] = ...

optSum3(Some(1), Some(2), Some(3))
// res11: Option[Int] = Some(6)
~~~

Finally, the `sequence` method described in [the monads chapter](#monad-type-class) is also available on `Applicative`:

~~~ scala
val sequence: Option[List[Int]] =
  Applicative[Option].sequence(List(some(1), some(2), some(3)))
// res12: Option[List[Int]] = Some(List(1, 2, 3))
~~~

### Applicatives for Custom Types

We can define instances of `Applicative` by implementing the `ap` and `point` methods:

~~~ scala
val myApplicative = new Applicative[MyType] {
  def ap[A, B](value: => MyType[A])(func: => MyType[A => B]): MyType[B] = ???

  def point[A](value: => A): MyType[A] = ???
}
~~~

We also get an `Applicative` for free whenever we define a `Monad`. The implementation of `ap` in this case is the same monadic sequencing we saw for `apply2_monadic` earlier:

~~~ scala
def ap[A, B](value: MyType[A])(func: MyType[A => B]): MyType[B] =
  bind(func)(map(value)(_))
~~

### Exercise: An Applicative for Result

Define two `Applicatives` for `Result`: one that mimics `apply2_keepLeft` and one that mimics `apply2_keepAll`. Demonstrate the behaviour of each using `readInt` and `sum3`.

Implement a `Monad` for `Result` and show that it provides the same semantics as `apply2_monadic`.

<div class="solution">
Here are the `Applicatives`:

~~~ scala
val keepLeft = new Applicative[Result] {
  def ap[A, B](a: => Result[A])(b: => Result[A => B]): Result[B] =
    (a, b) match {
      case (Pass(a), Pass(b)) => Pass(b(a))
      case (Pass(a), Fail(f)) => Fail(f)
      case (Fail(e), Pass(b)) => Fail(e)
      case (Fail(e), Fail(f)) => Fail(e)
    }

  def point[A](a: => A): Result[A] =
    Pass(a)
}

val keepAll = new Applicative[Result] {
  def ap[A, B](a: => Result[A])(b: => Result[A => B]): Result[B] =
    (a, b) match {
      case (Pass(a), Pass(b)) => Pass(b(a))
      case (Pass(a), Fail(f)) => Fail(f)
      case (Fail(e), Pass(b)) => Fail(e)
      case (Fail(e), Fail(f)) => Fail(e ++ f)
    }

  def point[A](a: => A): Result[A] =
    Pass(a)
}
~~~

Here is a demonstration of each applicative. We always call `readInt` three times, regardless of the results:

~~~ scala
keepLeft.apply3(readInt("foo"), readInt("bar"), readInt("baz"))(sum3)
// Reading baz
// Reading bar
// Reading foo
// res1: Result[Int] = Fail(List(Error reading baz))

keepAll.apply3(readInt("foo"), readInt("bar"), readInt("baz"))(sum3)
// Reading baz
// Reading bar
// Reading foo
// res2: Result[Int] = Fail(List(Error reading baz, ↩
//   Error reading bar, Error reading foo))
~~~

The `Monad` for `Result` provides different behaviour---we only read values until we get a `Fail`:

~~~ scala
val failFast = new Monad[Result] {
  def bind[A, B](value: Result[A])(func: A => Result[B]): Result[B] =
    value match {
      case Pass(value)  => func(value)
      case Fail(errors) => Fail(errors)
    }

  def point[A](value: => A): Result[A] =
    Pass(value)
}

failFast.apply3(readInt("123"), readInt("bar"), readInt("baz"))(sum3)
// Reading 123
// Reading bar
// res3: Result[Int] = Fail(List(Error reading bar))

failFast.apply3(readInt("foo"), readInt("bar"), readInt("baz"))(sum3)
// Reading foo
// res4: Result[Int] = Fail(List(Error reading foo))
~~~
</div>
