## Functors in Cats

Let's look at the implementation of functors in Cats. We'll follow the usual pattern of looking at the three main aspects of the implementation: the *type class*, the *instances*, and the *interface*.

### The *Functor* Type Class

The functor type class is [`cats.Functor`][cats.Functor]. We obtain instances using the standard `Functor.apply`. As usual, default instances are arranged by type in the [`cats.instances`][cats.instances] package:

```tut:book
import cats.Functor
import cats.instances.list._
import cats.instances.option._

val list1 = List(1, 2, 3)

val list2 = Functor[List].map(list1)(_ * 2)

val option1 = Some(123)

val option2 = Functor[Option].map(option1)(_.toString)
```

`Functor` also provides the `lift` method, which converts a function of type `A => B` to one that operates over a monad and has type `F[A] => F[B]`:

```tut:book
val func = (x: Int) => x + 1

val lifted = Functor[Option].lift(func)

lifted(Some(1))
```

### *Functor* Syntax

The main method provided by the syntax for `Functor` is `map`. It's difficult to demonstrate this with `Options` and `Lists` as they have their own built-in `map` operations. Instead we will use *functions*:

```tut:book
import cats.instances.function._
import cats.syntax.functor._

val func1 = (a: Int) => a + 1
val func2 = (a: Int) => a * 2
val func3 = func1 map func2

func3(123)
```

Other methods are available but we won't discuss them here. `Functors` are more important to us as building blocks for later abstrations than they are as a tool for direct use.

### Instances for Custom Types

We can define a functor simply by defining its map method. Here's an example of a `Functor` for `Option`, even though such a thing already exists in [`cats.instances`][cats.instances]:

```tut:book
val optionFunctor = new Functor[Option] {
  def map[A, B](value: Option[A])(func: A => B): Option[B] =
    value map func
}
```

The implementation is trivial---simply call `Option's` `map` method.

### Exercise: This Functor is Totally Valid

Imagine our application contains a custom validation type:

```tut:book
sealed trait Result[+A]
final case class Success[A](value: A) extends Result[A]
final case class Warning[A](value: A, message: String) extends Result[A]
final case class Failure(message: String) extends Result[Nothing]
```

Write a `Functor` for this data type. Use similar fail-fast semantics to `Option`. Verify that the code works as expected on instances of `Success`, `Warning`, and `Failure`.

Note that we haven't specified what to do with `Warning`. Do we apply the mapping function or pass `Warnings` through unaltered? If you follow the types, you'll see that only one approach will work.

<div class="solution">
It is sensible to assume that we want to apply the `Functor's` mapping function to instances of `Success` and `Warning` but pass `Failures` straight through:

```tut:book
import cats.Functor

implicit val resultFunctor = new Functor[Result] {
  def map[A, B](result: Result[A])(func: A => B): Result[B] =
    result match {
      case Success(value)          => Success(func(value))
      case Warning(value, message) => Warning(func(value), message)
      case Failure(message)        => Failure(message)
    }
}
```

Let's use our `Functor` in a sample application:

```tut:book:fail
Success(100) map (_ * 2)
```

Oops! This is the same invariance problem we saw with `Monoids`. Let's add some smart constructors to compensate:

```tut:book
def success[A](value: A): Result[A] =
  Success(value)

def warning[A](value: A, message: String): Result[A] =
  Warning(value, message)

def failure[A](message: String): Result[A] =
  Failure(message)
```

Now we can use our `Functor` properly:

```tut:book
success(100) map (_ * 2)

warning(10, "Too low") map (_ * 2)

failure[Int]("Far too low") map (_ * 2)
```
</div>
