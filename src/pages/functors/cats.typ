#import "../stdlib.typ": info, warning, solution, href, exercise
== Functors in Cats


Let's look at the implementation of functors in Cats.
We'll examine the same aspects we did for monoids:
the _type class_, the _instances_, and the _syntax_.


=== The Functor Type Class and Instances

The functor type class is #href("http://typelevel.org/cats/api/cats/Functor.html")[`cats.Functor`].
We obtain instances using the standard `Functor.apply`
method on the companion object.
As usual, default instances are found on companion objects
and do not have to be explicity imported:

```scala mdoc:silent:reset-object
import cats.*
import cats.syntax.all.*
```

Once we have the imports we use the `map` method defined by `Functor`.
In the examples below we are explicitly summoning the type class instances to avoid using the built-ins that are defined on `List` and `Option`.

```scala mdoc
val list1 = List(1, 2, 3)
val list2 = Functor[List].map(list1)(_ * 2)

val option1 = Option(123)
val option2 = Functor[Option].map(option1)(_.toString)
```

`Functor` provides a method called `lift`,
which converts a function of type `A => B`
to one that operates over a functor and has type `F[A] => F[B]`:
Let's lift a function into the `Option` functor.

```scala mdoc:silent
val func = (x: Int) => x + 1

val liftedFunc = Functor[Option].lift(func)
```

Now we can directly apply it to an `Option`.

```scala mdoc
liftedFunc(Option(1))
```

The `as` method is the other method you are likely to use.
It replaces the value inside the `Functor` with the given value.

```scala mdoc
Functor[List].as(list1, "As")
```


=== Functor Syntax

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

```scala mdoc:silent
val func1 = (a: Int) => a + 1
val func2 = (a: Int) => a * 2
val func3 = (a: Int) => s"${a}!"
val func4 = func1.map(func2).map(func3)
```

Once we've constructed a function using `map` we can apply it.

```scala mdoc
func4(123)
```

Let's look at another example.
This time we'll abstract over functors
so we're not working with any particular concrete type.
We can write a method that applies an equation to a number
no matter what functor context it's in:

```scala mdoc:silent
def doMath[F[_]](start: F[Int])
    (using functor: Functor[F]): F[Int] =
  start.map(n => 2 * n + 1)
```

We can write this more compactly with a context bound.

```scala mdoc:nest
def doMath[F[_]: Functor](start: F[Int]): F[Int] =
  start.map(n => 2 * n + 1)
```

It works as expected, using whatever `Functor` instance we pass it.

```scala mdoc
doMath(Option(20))
doMath(List(1, 2, 3))
```

To illustrate how this works,
let's take a look at the definition of
the `map` method in `cats.syntax.functor`.
Here's a simplified version of the code:

```scala mdoc:compile-only
extension [F[_], A](src: F[A]) {
  def map[B](func: A => B)
      (using functor: Functor[F]): F[B] =
    functor.map(src)(func)
}
```

The compiler can use this extension method
to insert a `map` method wherever no built-in `map` is available.
If we have the code

```scala
foo.map(value => value + 1)
```

and assume `foo` has no built-in `map` method,
the compiler detects the potential error and
uses the extension method to fix it.
The `map` extension method requires
a given `Functor` as a parameter.
This means this code will only compile
if we have a `Functor` for `F` in scope.
If we don't, we get a compiler error.

Here's an example of the error.
First we define a new type that has no `Functor` instance.

```scala mdoc:silent
final case class Box[A](value: A)

val box = Box[Int](123)
```

Now attempting to call `map` fails.
Notice the error message gives us a hint as to what went wrong.

```scala mdoc:fail
box.map(value => value + 1)
```

The `as` method is also available as syntax,
and works in the same way.

```scala mdoc
List(1, 2, 3).as("As")
```


=== Instances for Custom Types

We can define a functor simply by defining its map method.
Here's an example of a `Functor` for `Option`,
even though such a thing already exists in #href("http://typelevel.org/cats/api/cats/instances/")[`cats.instances`].
The implementation is trivial---we simply call `Option's` `map` method:

```scala
given optionFunctor: Functor[Option] =
  new Functor[Option] {
    def map[A, B](value: Option[A])(func: A => B): Option[B] =
      value.map(func)
  }
```

Sometimes we need to inject dependencies into our instances.
For example, if we had to define a custom `Functor` for `Future`
(another hypothetical example---Cats provides one in `cats.instances.future`)
we would need to account for the given `ExecutionContext` parameter on `future.map`.
We can't add extra parameters to `functor.map`
so we have to account for the dependency when we create the instance:

```scala mdoc:silent
import scala.concurrent.{Future, ExecutionContext}

given futureFunctor(using ec: ExecutionContext): Functor[Future] =
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


#exercise[Branching out with Functors]

Write a `Functor` for the following binary tree data type.
Verify that the code works as expected on instances of `Branch` and `Leaf`:

```scala mdoc:silent
enum Tree[+A] {
  case Branch[A](left: Tree[A], right: Tree[A])
    extends Tree[A]

  case Leaf[A](value: A) extends Tree[A]
}
```

#solution[
The semantics are similar to writing a `Functor` for `List`.
We recurse over the data structure, applying the function to every `Leaf` we find.
The functor laws intuitively require us to retain the same structure
with the same pattern of `Branch` and `Leaf` nodes:

```scala mdoc:silent
import Tree.{Branch, Leaf}

given treeFunctor: Functor[Tree] =
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

```scala mdoc:fail
Branch(Leaf(10), Leaf(20)).map(_ * 2)
```

Perfect!
]
