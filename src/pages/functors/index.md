# Functors

In this section we will investigate **functors**. Functors on their own aren't so useful, but special cases of functors such as as **monads** and **applicative functors** are some of the most commonly used abstractions in Scalaz.

Let's start as we did with monoids by looking at a few types and operations and seeing what general principles we can abstract.

The `map` method is perhaps the most commonly used method on `Seq`. If we have a `Seq[A]` and a function `A => B`, `map` will create a `Seq[B]`.

~~~ scala
scala> Seq(1, 2, 3) map (_.toString)
res31: Seq[String] = List(1, 2, 3)
~~~

We can do the same thing with an `Option`. If we have a `Option[A]` and a function `A => B`, `map` will create a `Option[B]`.

~~~ scala
scala> Some(1) map (_.toString)
res32: Option[String] = Some(1)
~~~

Now let's think about mapping over functions of a single argument. What would this mean? All our examples above have had the general shape of `F[A]`, supplying a function `A => B` to map, and getting a `F[B]` in return. A function has two types, the input *and* the output type. Let's fix the input type `R` and just consider the output type `A`, meaning a function `R => A`. Then a function has the shape we need, and map, giving us a `F[B]` means a function `R => B`. Thus `map` is just function composition:

~~~ scala
import scalaz.std.function._
val func1 = (x: Int) => x.toDouble
val func2 = (y: Double) => y * 2
val func3 = func1 map func2

func3(1) // == 2.0
~~~

## Definition of a Functor

Formally, a functor is a type `F[A]` with an operation `map` with type `(A => B) => F[B]`.

The following laws must hold:

- `map` preserves identity, meaning `fa map (a => a)` is equal to `fa`.
- `map` respects composition, meaning `fa map (g(f(_)))` is equal to `(fa map f) map g`.

If we consider the laws in the context of the functors we've discussed above, we can see they make sense and are true.

## Higher Kinds

Functors are the first type we've seen that has a *higher kind*. Kinds are like types for types.

Concrete types like `Int` and `String` have kind `*`. First order types are type constructors like `List`. `List` has kind `* => *`. Given a concrete type like `Double` we can "apply" `List` to it to yield the concrete type `List[Double]`. Higher order types like `Functor` accept type constructors as parameters. `Functor` has kind `(* => *) => *`---it constructs a type given a type constructor of kind `* => *`.

When we declare a generic type variable we must give it's kind. This is analogous to declaring the type of an expression. We're used to proper types like:

~~~ scala
def identity[A](a: A): A = a
~~~

When first or higher order type variables we must indicate how many type parameters they take using notation like `F[_]`. When we actually use this type we just use it's name. Remember the kind is like the type declaration of a binding (e.g. a `val` declaration like `val foo: String = "Hi"`). When we use a binding we don't repeat the type declaration. We just write, for example, `foo`. Similarly when we use a type variable we don't repeat the kind. So, for example, we could write:

~~~ scala
def concreteType[F[_]](fa: F[Int]) = ...
~~~

or more commonly:

~~~ scala
def genericType[F[_], A](fa: F[A]) = ...
~~~

We can add a context bound to indicate that our method accepts a `Functor` for our higher order type parameter:

~~~ scala
def functor[F[_] : Functor, A](fa: F[A]) = ...
~~~

Higher kinded types are an optional language feature in Scala. We need to `import scala.language.higherKinds` in code that uses higher kinds to suppress compiler warnings.

## Exercise: A Higher Kind of FoldMap

When we looked at `foldMap` earlier, we couldn't write a type class for it because we didn't know how to write the type of the objects that type class should work over. We do now.

Define all the machinery needed for a `FoldMappable` type class: the trait, an interface, some instances, and an enrichment.

<div class="solution">
This exercise is really intended to make us practive defining and using higher kinds. Here is the model solution:

~~~ scala
import scala.language.higherKinds
import scalaz.Monoid
import scalaz.syntax.monoid._

trait FoldMappable[F[_]] {
  def foldMap[A, B : Monoid](fa: F[A])(f: A => B): B
}

object FoldMappable {
  def apply[F[_] : FoldMappable]: FoldMappable[F] =
    implicitly[FoldMappable[F]]

  implicit object ListFoldMappable extends FoldMappable[List] {
    def foldMap[A, B : Monoid](fa: List[A])(f: A => B): B =
      fa.foldLeft(mzero[B]){ _ |+| f(_) }
  }
}

object FoldMappableSyntax {
  implicit class IsFoldMappable[F[_] : FoldMappable, A](fa: F[A]) {
    def foldMap[B : Monoid](f: A => B): B =
      FoldMappable[F].foldMap(fa)(f)
  }
}
~~~
</div>
