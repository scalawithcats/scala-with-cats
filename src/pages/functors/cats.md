## Functors in Cats

Let's look at the implementation of functors in Cats. 
We'll follow the usual pattern of looking at the three main aspects of the implementation: the *type class*, the *instances*, and the *interface*.

### The *Functor* Type Class

The functor type class is [`cats.Functor`][cats.Functor]. 
We obtain instances using the standard `Functor.apply` method on the companion object.
As usual, default instances are arranged by type in the [`cats.instances`][cats.instances] package:

```tut:book
import cats.Functor
import cats.instances.list._
import cats.instances.option._

val list1 = List(1, 2, 3)

val list2 = Functor[List].map(list1)(_ * 2)

val option1 = Option(123)

val option2 = Functor[Option].map(option1)(_.toString)
```

`Functor` also provides the `lift` method, which converts a function of type `A => B` to one that operates over a functor and has type `F[A] => F[B]`:

```tut:book
val func = (x: Int) => x + 1

val lifted = Functor[Option].lift(func)

lifted(Option(1))
```

### *Functor* Syntax

The main method provided by the syntax for `Functor` is `map`. 
It's difficult to demonstrate this with `Options` and `Lists` as they have their own built-in `map` operations. 
If there is a built-in method it will always be called in preference to an extension method.
Instead we will use *functions*:

```tut:book
import cats.instances.function._
import cats.syntax.functor._

val func1 = (a: Int) => a + 1
val func2 = (a: Int) => a * 2
val func3 = func1 map func2

func3(123)
```

Other methods are available but we won't discuss them here. 
`Functors` are more important to us as building blocks for later abstractions than they are as a tool for direct use.

### Instances for Custom Types

We can define a functor simply by defining its map method. 
Here's an example of a `Functor` for `Option`, even though such a thing already exists in [`cats.instances`][cats.instances]:

```tut:book
val optionFunctor = new Functor[Option] {
  def map[A, B](value: Option[A])(func: A => B): Option[B] =
    value map func
}
```

The implementation is trivial---simply call `Option's` `map` method.

### Exercise: Branching out with Functors

Write a `Functor` for the following binary tree data type.
Verify that the code works as expected on instances of `Branch` and `Leaf`:

```tut:book
sealed trait Tree[+A]
final case class Branch[A](left: Tree[A], right: Tree[A]) extends Tree[A]
final case class Leaf[A](value: A) extends Tree[A]
```

<div class="solution">
The semantics are similar to writing a `Functor` for `List`.
We recurse over the data structure, applying the function to every `Leaf` we find:

```tut:book
import cats.Functor
import cats.syntax.functor._

implicit val treeFunctor = new Functor[Tree] {
  def map[A, B](tree: Tree[A])(func: A => B): Tree[B] =
    tree match {
      case Branch(left, right) => Branch(map(left)(func), map(right)(func))
      case Leaf(value)         => Leaf(func(value))
    }
}
```

Let's use our `Functor` to transform some `Trees`:

```tut:book:fail
Leaf(10) map (_ * 2)
```

Oops! This is the same invariance problem we saw with `Monoids`.
The compiler can't find a `Functor` instance for `Leaf`.
Let's add some smart constructors to compensate:

```tut:book
def branch[A](left: Tree[A], right: Tree[A]): Tree[A] =
  Branch(left, right)

def leaf[A](value: A): Tree[A] =
  Leaf(value)
```

Now we can use our `Functor` properly:

```tut:book
leaf(100) map (_ * 2)

branch(leaf(10), leaf(20)) map (_ * 2)
```
</div>
