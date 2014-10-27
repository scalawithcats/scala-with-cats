---
layout: page
title: Functors
---

In this section we're investigate **functors**. Functors on their own aren't so useful, but special cases of functors such as as **monads** and **applicative functors** are some of the most commonly used abstractions in Scalaz.

As we did with monads let's start by looking at a few types with common operations and see what general principles we can abstract.

The `map` method is perhaps the most commonly used one on `Seq`. If we have a `Seq[A]` and a function `A => B`, `map` will create a `Seq[B]`.

~~~ scala
scala> Seq(1, 2, 3) map (_.toString)
res31: Seq[String] = List(1, 2, 3)
~~~

We can do the same thing with an `Option`. If we have a `Option[A]` and a function `A => B`, `map` will create a `Option[B]`.

~~~ scala
scala> Some(1) map (_.toString)
res32: Option[String] = Some(1)
~~~

Now let's think about mapping over functions of a single argument. What would this mean? All our examples above have had the general shape of `F[A]`, supplying a function `A => B` to map, and getting a `F[B]` in return. A function has two types, the input *and* the output type. Let's fix the input type `R` and just consider the output type `A`, meaning a funciton `R => A`. Then a function has the shape we need, and map, giving us a `F[B]` means a function `R => B`. Thus `map` is just function composition.

~~~ scala
scala> import scalaz.std.function._
scala> val f = ((x: Int) => x.toString) map ((y: String) => y.toDouble)
f: Int => Double = <function1>

scala> f(1)
res39: Double = 1.0
~~~


## Functor Definition

Formally, a functor is a type `F[A]` with an operation `map` with type `(A => B) => F[B]`.

The following laws must hold:

- `map` preserves identity, meaning `fa map (a => a)` is equal to `fa`.
- `map` respects composition, meaning `fa map (g(f(_)))` is equal to `(fa map f) map g`.

If we consider the laws in the context of the functors we've discussed above, we can see they make sense and are true.


## Higher Kinds

Functors are the first type we've seen that has a *higher kind*. Kinds are like types for types. Concrete types like `Int` and `String` have kind `*`. First order types are type constructors like `List`. `List` has kind `* => *`. Given a concrete type like `Double` we can "apply" `List` to it to yield the concrete type `List[Double]`. Higher order types like `Functor` accept type constructors as parameters. `Functor` has kind `(* => *) => *`. Given a type constructor is constructs a type.

When we declare a generic type variable we must give it's kind. This is analogous to declaring the type of an expression. We're used to proper types like

~~~ scala
def identity[A](a: A): A = a
~~~

When first or higher order type variables we must indicate how many type parameters they take using notation like `F[_]`. When we actually use this type we just use it's name. Remember the kind is like the type declaration of a binding (e.g. a `val` declaration like `val foo: String = "Hi"`). When we use a binding we don't repeat the type declaration. We just write, for example, `foo`. Similarly when we use a type variable we don't repeat the kind. So, for example, we could write

~~~ scala
def concreteType[F[_]](fa: F[Int]) = ...
~~~

or more commonly

~~~ scala
def genericType[F[_], A](fa: F[A]) = ...
~~~

We can also add a context bound, so to indicate our method accepts a `Functor` we could write

~~~ scala
def functor[F[_] : Functor, A](fa: F[A]) = ...
~~~

For reasons I find difficult to understand we should also require `scala.language.higherKinds` in code that uses higher kinds or the compiler will complain at us.

## Exercises

#### FoldMap of a Higher Kind

When we looked at `foldMap` earlier, we couldn't write a type class for it because we didn't know how to write the type of objects that type class should work over. We do now.

Define all the machinery needed for a `FoldMapable` type class: the trait, an interface, some instances, and an enrichment.

<div class="solution">
This exercise is really intended to drill in the definition and use of higher kinds. Here is my solution.

~~~ scala
import scala.language.higherKinds

import scalaz.Monoid
import scalaz.syntax.monoid._

trait FoldMapable[F[_]] {
  def foldMap[A, B : Monoid](fa: F[A])(f: A => B): B
}

object FoldMapable {
  def apply[F[_] : FoldMapable]: FoldMapable[F] =
    implicitly[FoldMapable[F]]

  implicit object ListFoldMapable extends FoldMapable[List] {
    def foldMap[A, B : Monoid](fa: List[A])(f: A => B): B =
      fa.foldLeft(mzero[B]){ _ |+| f(_) }
  }
}

object FoldMapableSyntax {
  implicit class IsFoldMapable[F[_] : FoldMapable, A](fa: F[A]) {
    def foldMap[B : Monoid](f: A => B): B =
      FoldMapable[F].foldMap(fa)(f)
  }
}
~~~
</div>
