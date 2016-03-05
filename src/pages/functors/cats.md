## Functors in Cats

Let's look at the implementation of functors in Cats. We'll follow the usual pattern of looking at the three main aspects of the implementation: the *type class*, the *instances*, and the *interface*.

### The *Functor* Type Class

The functor type class is [`cats.Functor`][cats.Functor]. We obtain instances using the standard `Functor.apply`. As usual, default instances are arranged by type in the [`cats.std`][cats.std] package:

```scala
import cats.Functor
// import cats.Functor

import cats.std.list._
// import cats.std.list._

import cats.std.option._
// import cats.std.option._

val list1 = List(1, 2, 3)
// list1: List[Int] = List(1, 2, 3)

val list2 = Functor[List].map(list1)(_ * 2)
// list2: List[Int] = List(2, 4, 6)

val option1 = Some(123)
// option1: Some[Int] = Some(123)

val option2 = Functor[Option].map(option1)(_.toString)
// option2: Option[String] = Some(123)
```

`Functor` also provides the `lift` method, which converts an function of type `A => B` to one that operates over a monad and has type `F[A] => F[B]`:

```scala
val func = (x: Int) => x + 1
// func: Int => Int = <function1>

val lifted = Functor[Option].lift(func)
// lifted: Option[Int] => Option[Int] = <function1>

lifted(Some(1))
// res0: Option[Int] = Some(2)
```

### *Functor* Syntax

The main method provided by the syntax for `Functor` is `map`. It's difficult to demonstrate this with `Options` and `Lists` as they have their own built-in `map` operations. Instead we will use *functions*:

```scala
import cats.std.function._
// import cats.std.function._

import cats.syntax.functor._
// import cats.syntax.functor._

val func1 = (a: Int) => a + 1
// func1: Int => Int = <function1>

val func2 = (a: Int) => a * 2
// func2: Int => Int = <function1>

val func3 = func1 map func2
// func3: Int => Int = <function1>

func3(123)
// res1: Int = 248
```

Other methods are available but we won't discuss them here. `Functors` are more important to us as building blocks for later abstrations than they are as a tool for direct use.

### Instances for Custom Types

We can define a functor simply by defining its map method. Here's an example of a `Functor` for `Option`, even though such a thing already exists in [`cats.std`][cats.std]:

```scala
val optionFunctor = new Functor[Option] {
  def map[A, B](value: Option[A])(func: A => B): Option[B] =
    value map func
}
// optionFunctor: cats.Functor[Option] = $anon$1@15755c25
```

The implementation is trivial---simply call `Option's` `map` method.

### Exercise: This Functor is Totally Valid

Imagine our application contains a custom validation type:

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

Write a `Functor` for this data type. Use similar fail-fast semantics to `Option`. Verify that the code works as expected on instances of `Success`, `Warning`, and `Failure`.

Note that we haven't specified what to do with `Warning`. Do we apply the mapping function or pass `Warnings` through unaltered? If you follow the types, you'll see that only one approach will work.

<div class="solution">
It is sensible to assume that we want to apply the `Functor's` mapping function to instances of `Success` and `Warning` but pass `Failures` straight through:

```scala
import cats.Functor
// import cats.Functor

implicit val resultFunctor = new Functor[Result] {
  def map[A, B](result: Result[A])(func: A => B): Result[B] =
    result match {
      case Success(value)          => Success(func(value))
      case Warning(value, message) => Warning(func(value), message)
      case Failure(message)        => Failure(message)
    }
}
// resultFunctor: cats.Functor[Result] = $anon$1@3d3a8d9e
```

Let's use our `Functor` in a sample application:

```scala
Success(100) map (_ * 2)
// <console>:35: error: value map is not a member of Success[Int]
//        Success(100) map (_ * 2)
//                     ^
```

Oops! This is the same inavariance problem we saw with `Monoids`. Let's add some smart constructors to compensate:

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

Now we can use our `Functor` properly:

```scala
success(100) map (_ * 2)
// res3: Result[Int] = Success(200)

warning(10, "Too low") map (_ * 2)
// res4: Result[Int] = Warning(20,Too low)

failure[Int]("Far too low") map (_ * 2)
// res5: Result[Int] = Failure(Far too low)
```
</div>
