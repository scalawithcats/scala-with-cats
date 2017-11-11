## Functors in Cats

Let's look at the implementation of functors in Cats.
We'll examine the aspects we did for monoids:
the *type class*, the *instances*, and the *syntax*.

### The Functor Type Class

The functor type class is [`cats.Functor`][cats.Functor].
We obtain instances using the standard `Functor.apply`
method on the companion object.
As usual, default instances are arranged by type in
the [`cats.instances`][cats.instances] package:

```tut:book:silent
import scala.language.higherKinds
import cats.Functor
import cats.instances.list._
import cats.instances.option._
```

```tut:book
val list1 = List(1, 2, 3)
val list2 = Functor[List].map(list1)(_ * 2)

val option1 = Option(123)
val option2 = Functor[Option].map(option1)(_.toString)
```

`Functor` also provides the `lift` method,
which converts a function of type `A => B`
to one that operates over a functor and has type `F[A] => F[B]`:

```tut:book
val func = (x: Int) => x + 1

val liftedFunc = Functor[Option].lift(func)

liftedFunc(Option(1))
```

### Functor Syntax

The main method provided by the syntax for `Functor` is `map`.
It's difficult to demonstrate this with `Options` and `Lists`
as they have their own built-in `map` methods
and the Scala compiler will always prefer
a built-in method over an extension method.
We'll work around this with two examples.

First let's look at mapping over functions.
Scala's `Function1` type doesn't have a `map` method
(it's called `andThen` instead)
so there are no naming conflicts:

```tut:book:silent
import cats.instances.function._
import cats.syntax.functor._
```

```tut:book:silent
val func1 = (a: Int) => a + 1
val func2 = (a: Int) => a * 2
val func3 = (a: Int) => a + "!"
val func4 = func1.map(func2).map(func3)
```

```tut:book
func4(123)
```

Let's look at another example.
This time we'll abstract over functors
so we're not working with any particular concrete type.
We can write a method that applies an equation to a number
no matter what functor context it's in:

```tut:book:silent
def doMath[F[_]](start: F[Int])
    (implicit functor: Functor[F]): F[Int] =
  start.map(n => n + 1 * 2)

import cats.instances.option._
import cats.instances.list._
```

```tut:book
doMath(Option(20))
doMath(List(1, 2, 3))
```

To illustrate how this works,
let's take a look at the definition of
the `map` method in `cats.syntax.functor`.
Here's a simplified version of the code:

```scala
implicit class FunctorOps[F[_], A](src: F[A]) {
  def map[B](func: A => B)
      (implicit functor: Functor[F]): F[B] =
    functor.map(src)(func)
}
```

The compiler can use this extension method
to insert a `map` method wherever no built-in `map` is available:

```scala
foo.map(value => value + 1)
```

Assuming `foo` has no built-in `map` method,
the compiler detects the potential error and
wraps the expression in a `FunctorOps` to fix the code:

```scala
new FunctorOps(foo).map(value => value + 1)
```

The `map` method of `FunctorOps` requires
an implicit `Functor` as a parameter.
This means this code will only compile
if we have a `Functor` for `expr1` in scope.
If we don't, we get a compiler error:

```tut:book:silent
final case class Box[A](value: A)

val box = Box[Int](123)
```

```tut:book:fail
box.map(value => value + 1)
```

### Instances for Custom Types

We can define a functor simply by defining its map method.
Here's an example of a `Functor` for `Option`,
even though such a thing already exists in [`cats.instances`][cats.instances].
The implementation is trivial---we simply call `Option's` `map` method:

```tut:book:silent
implicit val optionFunctor: Functor[Option] =
  new Functor[Option] {
    def map[A, B](value: Option[A])(func: A => B): Option[B] =
      value.map(func)
  }
```

Sometimes we need to inject dependencies into our instances.
For example, if we had to define a custom `Functor` for `Future`
(another hypothetical example---Cats provides one in `cats.instances.future`)
we would need to account for the implicit `ExecutionContext` parameter on `future.map`.
We can't add extra parameters to `functor.map`
so we have to account for the dependency when we create the instance:

```tut:book:silent
import scala.concurrent.{Future, ExecutionContext}

implicit def futureFunctor
    (implicit ec: ExecutionContext): Functor[Future] =
  new Functor[Future] {
    def map[A, B](value: Future[A])(func: A => B): Future[B] =
      value.map(func)
  }
```

Whenever we summon a `Functor` for `Future`,
either directly using `Functor.apply`
or indirectly via the `map` extension method,
the compiler will locate `futureFunctor` by implicit resolution
and recursively search for an `ExecutionContext` at the call site.
This is what the expansion might look like:

```scala
// We write this:
Functor[Future]

// The compiler expands to this first:
Functor[Future](futureFunctor)

// And then to this:
Functor[Future](futureFunctor(executionContext))
```

### Exercise: Branching out with Functors

Write a `Functor` for the following binary tree data type.
Verify that the code works as expected on instances of `Branch` and `Leaf`:

```tut:book:silent
sealed trait Tree[+A]
final case class Branch[A](left: Tree[A], right: Tree[A]) extends Tree[A]
final case class Leaf[A](value: A) extends Tree[A]
```

<div class="solution">
The semantics are similar to writing a `Functor` for `List`.
We recurse over the data structure, applying the function to every `Leaf` we find.
The functor laws intuitively require us to retain the same structure
with the same pattern of `Branch` and `Leaf` nodes:

```tut:book:silent
import cats.Functor
import cats.syntax.functor._

implicit val treeFunctor: Functor[Tree] =
  new Functor[Tree] {
    def map[A, B](tree: Tree[A])(func: A => B): Tree[B] =
      tree match {
        case Branch(left, right) =>
          Branch(map(left)(func), map(right)(func))
        case Leaf(value) =>
          Leaf(func(value))
      }
  }
```

Let's use our `Functor` to transform some `Trees`:

```tut:book:fail
Branch(Leaf(10), Leaf(20)).map(_ * 2)
```

Oops! This is falls foul of
the same invariance problem we discussed in Section [@sec:variance].
The compiler can find a `Functor` instance for `Tree` but not for `Branch` or `Leaf`.
Let's add some smart constructors to compensate:

```tut:book:silent
object Tree {
  def branch[A](left: Tree[A], right: Tree[A]): Tree[A] =
    Branch(left, right)

  def leaf[A](value: A): Tree[A] =
    Leaf(value)
}
```

Now we can use our `Functor` properly:

```tut:book:silent
import Tree._
```

```tut:book
leaf(100).map(_ * 2)

branch(leaf(10), leaf(20)).map(_ * 2)
```
</div>
