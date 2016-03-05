# Functors

In this chapter we will investigate **functors**. Functors on their own aren't so useful, but special cases of functors such as as **monads** and **applicative functors** are some of the most commonly used abstractions in Cats.

Informally, a functor is anything with a `map` method. You probably know lots of types that have this: `Option`, `Seq`, `Either`, and `Future`, to name a few.

Let's start as we did with monoids by looking at a few types and operations and seeing what general principles we can abstract.

**Sequences**

The `map` method is perhaps the most commonly used method on `Seq`. If we have a `Seq[A]` and a function `A => B`, `map` will create a `Seq[B]`.

```tut:book
Seq(1, 2, 3) map (_ * 2)
```

**Options**

We can do the same thing with an `Option`. If we have a `Option[A]` and a function `A => B`, `map` will create a `Option[B]`:

```tut:book
Some(1) map (_.toString)
```

**Functions (?!)**

Now let's think about mapping over functions of a single argument. What would this mean?

All our examples above have had the following general shape:

 - start with `F[A]`;
 - supply a function `A => B`;
 - get back `F[B]`.

A function with a single argument has two types: the parameter type and the result type. To get them to the same shape we can fix the parameter and let the result type vary:

 - start with `R => A`;
 - supply a function `A => B`;
 - get back `R => B`.

In other words, "mapping" over a `Function1` is just function composition:

```tut:book
import cats.std.function._
import cats.syntax.functor._

val func1 = (x: Int) => x.toDouble
val func2 = (y: Double) => y * 2
val func3 = func1 map func2

func3(1)
```

## Definition of a Functor

Formally, a functor is a type `F[A]` with an operation `map` with type `(A => B) => F[B]`.

The following laws must hold:

- `map` preserves identity, meaning `fa map (a => a)` is equal to `fa`.
- `map` respects composition, meaning `fa map (g(f(_)))` is equal to `(fa map f) map g`.

If we consider the laws in the context of the functors we've discussed above, we can see they make sense and are true. But that's a job for category theorists, so let's move on!

A simplified version of the definition from Cats is:

```tut:book
import scala.language.higherKinds

trait Functor[F[_]] {
  def map[A, B](fa: F[A])(f: A => B): F[B]
}
```

If you haven't seen syntax like `F[_]` before, it's time to take a brief detour to discuss *type constructors* and *higher kinded types*. We'll explain that `scala.language` import as well.

## Aside: Higher Kinds and Type Constructors

Kinds are like types for types. They describe the number of "holes" in a type. We distinguish between regular types that have no holes, and "type constructors" that have holes that we can fill to produce types.

For example, `List` is a type constructor with one hole. We fill that hole by specifying a parameter to produce a regular type like `List[Int]` or `List[A]`. The trick is not to confuse type constructors with generic types. `List` is a type constructor, `List[A]` is a type:

```scala
List    // type constructor, takes one parameter
List[A] // type, produced using a type parameter
```

There's a close analogy here with functions and values. Functions are "value constructors"---they produce values when we supply parameters:

```scala
math.abs    // function, takes one parameter
math.abs(x) // value, produced using a value parameter
```

<div class="callout callout-warning">
*Kind notation*

We sometimes use "kind notation" to describe the shape of types and their constructors. Regular types have a kind `*`. `List` has kind `* => *` to indicate that it produces a type given a single parameter. `Either` has kind `* => * => *` because it accepts two parameters, and so on.
</div>

In Scala we declare type constructors using underscores but refer to them without:

```scala
// Declare F using underscores:
def myMethod[F[_]] = {

  // Refer to F without underscores:
  val functor = Functor.apply[F]

  // ...
}
```

This is analogous to specifying a function's parameters in its definition and omitting them when referring to it:

```scala
// Declare f specifying parameters:
val f = (x: Int) => x * 2

// Refer to f without parameters:
val f2 = f andThen f
```

Armed with this knowledge of type constructors, we can see that the Cats definition of `Functor` allows us to create instances for any single-parameter type constructor, such as `List`, `Option`, or `Future`.

<div class="callout callout-info">
*Language feature imports*

Higher kinded types are considered an advanced language feature in Scala. Wherever we *declare* a type constructor with `A[_]` syntax, we need to "import" the feature to suppress compiler warnings:

```scala
import scala.language.higherKinds
```
</div>
