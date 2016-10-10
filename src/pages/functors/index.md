# Functors

In this chapter we will investigate **functors**.
Functors on their own aren't so useful,
but special cases of functors such as
**monads** and **applicative functors**
are some of the most commonly used abstractions in Cats.

## Examples of Functors

Informally, a functor is anything with a `map` method.
You probably know lots of types that have this:
`Option`, `List`, `Either`, and `Future`, to name a few.

Let's start as we did with monoids by looking at
a few types and operations
and seeing what general principles we can abstract.

**Sequences**

The `map` method is perhaps the most commonly used method on `List`.
If we have a `List[A]` and a function `A => B`, `map` will create a `List[B]`.

```tut:book
List(1, 2, 3).map(x => (x % 2) == 0)
```

There are some properties of `map` that we rely on without even thinking about them. For example, we expect the two snippets below to produce the same output:

```tut:book
List(1, 2, 3).map(_ * 2).map(_ + 4)

List(1, 2, 3).map(x => (x * 2) + 4)
```

In general, the `map` method for a `List` works like this:
We start with a `List[A]` of length `n`,
we supply a function from `A` to `B`,
and we end up with a `List[B]` of length `n`.
The elements are changed
but the ordering and length of the list are preserved.
This is illustrated in [@fig:functor:list-type-chart].

![Type chart: mapping over a List](src/pages/functors/list-map.pdf+svg){#fig:functor:list-type-chart}

**Options**

We can do the same thing with an `Option`.
If we have a `Option[A]` and a function `A => B`,
`map` will create a `Option[B]`:

```tut:book
Option(1).map(_.toString)
```

We expect `map` on  `Option` to behave in the same way as `List`:

```tut:book
Option(123).map(_ * 4).map(_ + 4)

Option(123).map(x => (x * 2) + 4)
```

In general, the `map` method for an `Option` works
similarly to that for a `List`.
We start with an `Option[A]`
that is either a `Some[A]` or a `None`,
we supply a function from `A` to `B`,
and the result is either a `Some[B]` or a `None`.
Again, the structure is preserved:
if we start with a `Some` we end up with a `Some`, and a `None` always maps to a `None`.
This is shown in [@fig:functor:option-type-chart].

![Type chart: mapping over an Option](src/pages/functors/option-map.pdf+svg){#fig:functor:option-type-chart}

## More Examples of Functors

Let's expand how we think about `map`
by taking some other examples into account:

**Futures**

`Future` is also a functor
with a `map` method[^future-error-handling].
If we start with a `Future[A]`
and call map supplying a function `A => B`,
we end up with a `Future[B]`:

[^future-error-handling]: Some functional purists disagree with this
because the exception handling in Scala futures breaks the functor laws.
We're going to ignore this detail
because *real* functional programs don't do exceptions.

```tut:book:silent
import scala.concurrent.{Future, Await}
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._
```

```tut:book
val future1 = Future("Hello world!")
val future2 = future1.map(_.length)

Await.result(future1, Duration.Inf)
Await.result(future2, Duration.Inf)
```

The general pattern looks like [@fig:functor:future-type-chart]. Seem familiar?

![Type chart: mapping over a Future](src/pages/functors/future-map.pdf+svg){#fig:functor:future-type-chart}

**Functions (?!)**

Can we map over functions of a single argument?
What would this mean?

All our examples above have had the following general shape:

 - start with `F[A]`;
 - supply a function `A => B`;
 - get back `F[B]`.

A function with a single argument has two types:
the parameter type and the result type.
To get them to the same shape we can
fix the parameter type and let the result type vary:

 - start with `X => A`;
 - supply a function `A => B`;
 - get back `X => B`.

We can see this with our trusty type chart in [@fig:functor:function-type-chart].

![Type chart: mapping over a Function1](src/pages/functors/function-map.pdf+svg){#fig:functor:function-type-chart}

In other words, "mapping" over a `Function1`
is just function composition:

```tut:book:silent
import cats.instances.function._
import cats.syntax.functor._
```

```tut:book
val func1 = (x: Int)    => x.toDouble
val func2 = (y: Double) => y * 2
val func3 = func1.map(func2)

func3(1) // function composition by calling map

func2(func1(1)) // function composition written out by hand
```

## Definition of a Functor

Formally, a functor is a type `F[A]`
with an operation `map` with type `(A => B) => F[B]`.
The general type chart is shown in [@fig:functor:functor-type-chart].

![Type chart: generalised functor map](src/pages/functors/generic-map.pdf+svg){#fig:functor:functor-type-chart}

Intuitively, a functor `F[A]` represents some data (the `A` type) in a context (the `F` type).
The `map` operation modifies the data within but retains the structure of the surrounding context. 
To ensure this is the case, the following laws must hold:

*Identity*: calling `map` with the identity function 
is the same as doing nothing:

```scala
fa.map(a => a) == fa
```

*Composition*: `mapping` with two functions `f` and `g` is 
the same as `mapping` with `f` and then `mapping` with `g`:

```scala
fa.map(g(f(_))) == fa.map(f).map(g)
```

If we consider the laws
in the context of the functors we've discussed above,
we can see they make sense and are true.
We've seen some examples of the second law already.

A simplified version of the definition from Cats is:

```tut:book:silent
import scala.language.higherKinds

trait Functor[F[_]] {
  def map[A, B](fa: F[A])(f: A => B): F[B]
}
```

If you haven't seen syntax like `F[_]` before,
it's time to take a brief detour to discuss
*type constructors* and *higher kinded types*.
We'll explain that `scala.language` import as well.

## Aside: Higher Kinds and Type Constructors

Kinds are like types for types.
They describe the number of "holes" in a type.
We distinguish between regular types that have no holes,
and "type constructors" that have holes that we can fill to produce types.

For example, `List` is a type constructor with one hole.
We fill that hole by specifying a parameter to produce
a regular type like `List[Int]` or `List[A]`.
The trick is not to confuse type constructors with generic types.
`List` is a type constructor, `List[A]` is a type:

```scala
List    // type constructor, takes one parameter
List[A] // type, produced using a type parameter
```

There's a close analogy here with functions and values.
Functions are "value constructors"---they
produce values when we supply parameters:

```scala
math.abs    // function, takes one parameter
math.abs(x) // value, produced using a value parameter
```

<div class="callout callout-warning">
*Kind notation*

We sometimes use "kind notation" to describe
the shape of types and their constructors.
Regular types have a kind `*`.
`List` has kind `* => *` to indicate that it
produces a type given a single parameter.
`Either` has kind `* => * => *` because it accepts two parameters,
and so on.
</div>

In Scala we declare type constructors using underscores
but refer to them without:

```scala
// Declare F using underscores:
def myMethod[F[_]] = {

  // Refer to F without underscores:
  val functor = Functor.apply[F]

  // ...
}
```

This is analogous to specifying a function's parameters
in its definition and omitting them when referring to it:

```scala
// Declare f specifying parameters:
val f = (x: Int) => x * 2

// Refer to f without parameters:
val f2 = f andThen f
```

Armed with this knowledge of type constructors,
we can see that the Cats definition of `Functor`
allows us to create instances for any single-parameter type constructor,
such as `List`, `Option`, or `Future`.

<div class="callout callout-info">
*Language feature imports*

Higher kinded types are considered an advanced language feature in Scala.
Wherever we *declare* a type constructor with `A[_]` syntax,
 we need to "import" the feature to suppress compiler warnings:

```scala
import scala.language.higherKinds
```
</div>
