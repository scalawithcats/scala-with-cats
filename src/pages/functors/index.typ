#import "../stdlib.typ": info, warning, solution
= Functors


In this chapter we will investigate *functors*,
an abstraction that allows us to
represent sequences of operations within a context
such as a `List`, an `Option`,
or any one of thousands of other possibilities.
Functors on their own aren't so useful,
but special cases of functors, 
such as *monads* and *applicative functors*,
are some of the most commonly used abstractions.


== Examples of Functors 
<sec:functors:examples>


Informally, a functor is anything with a `map` method.
You probably know lots of types that have this:
`Option`, `List`, and `Either`, to name a few.

We typically first encounter `map` when iterating over `Lists`.
However, to understand functors
we need to think of the method in another way.
Rather than traversing the list, we should think of it as
transforming all of the values inside in one go.
We specify the function to apply,
and `map` ensures it is applied to every item.
The values change but the structure of the list
(the number of elements and their order)
remains the same:

```scala mdoc
List(1, 2, 3).map(n => n + 1)
```

Similarly, when we `map` over an `Option`,
we transform the contents but leave
the `Some` or `None` context unchanged.
The same principle applies to `Either`
with its `Left` and `Right` contexts.
This general notion of transformation,
along with the common pattern of type signatures
shown in @fig:functors:list-option-either-type-chart,
is what connects the behaviour of `map`
across different data types.

#figure(
    image("list-option-either-map.svg", width: 80%),
    caption: [Type chart: mapping over List, Option, and Either]
) <fig:functors:list-option-either-type-chart>

Because `map` leaves the structure of the context unchanged,
we can call it repeatedly to sequence multiple computations
on the contents of an initial data structure:

```scala mdoc
List(1, 2, 3).
  map(n => n + 1).
  map(n => n * 2).
  map(n => s"${n}!")
```

We should think of `map` not as an iteration pattern,
but as a way of sequencing computations
on values ignoring some complication
dictated by the relevant data type:

- `Option`---the value may or may not be present;
- `Either`---there may be a value or an error;
- `List`---there may be zero or more values.


== More Examples of Functors 
<sec:functors:more-examples>


The `map` methods of `List`, `Option`, and `Either`
apply functions eagerly.
However, the idea of sequencing computations
is more general than this.
Let's investigate the behaviour of some other functors
that apply the pattern in different ways.

*Futures*

`Future` is a functor that
sequences asynchronous computations by queueing them
and applying them as their predecessors complete.
The type signature of its `map` method,
shown in @fig:functors:future-type-chart,
has the same shape as the signatures above.
However, the behaviour is very different.

#figure(
  image("future-map.svg", width: 80%),
  caption: [Type chart: mapping over a Future]
) <fig:functors:future-type-chart>

When we work with a `Future` we have no guarantees
about its internal state.
The wrapped computation may be
ongoing, complete, or rejected.
If the `Future` is complete,
our mapping function can be called immediately.
If not, some underlying thread pool queues
the function call and comes back to it later.
We don't know _when_ our functions will be called,
but we do know _what order_ they will be called in.
In this way, `Future` provides
the same sequencing behaviour
seen in `List`, `Option`, and `Either`:

```scala mdoc:silent
import scala.concurrent.{Future, Await}
import scala.concurrent.ExecutionContext.Implicits.global
import scala.concurrent.duration._

val future: Future[String] =
  Future(123).
    map(n => n + 1).
    map(n => n * 2).
    map(n => s"${n}!")
```

```scala mdoc
Await.result(future, 1.second)
```

#info[
*Futures and Referential Transparency*

Note that Scala's `Futures` aren't a great example
of pure functional programming
because they aren't _referentially transparent_.
`Future` always computes and caches a result
and there's no way for us to tweak this behaviour.
This means we can get unpredictable results
when we use `Future` to wrap side-effecting computations.
For example:

```scala mdoc:silent
import scala.util.Random

val future1 = {
  // Initialize Random with a fixed seed:
  val r = new Random(0L)

  // nextInt has the side-effect of moving to
  // the next random number in the sequence:
  val x = Future(r.nextInt())

  for {
    a <- x
    b <- x
  } yield (a, b)
}

val future2 = {
  val r = new Random(0L)

  for {
    a <- Future(r.nextInt())
    b <- Future(r.nextInt())
  } yield (a, b)
}
```

```scala mdoc
val result1 = Await.result(future1, 1.second)
val result2 = Await.result(future2, 1.second)
```

Ideally we would like `result1` and `result2`
to contain the same value.
However, the computation for `future1` calls `nextInt` once
and the computation for `future2` calls it twice.
Because `nextInt` returns a different result every time
we get a different result in each case.

This kind of discrepancy makes it hard to reason about
programs involving `Futures` and side-effects.
There also are other problematic aspects of `Future's` behaviour,
such as the way it always starts computations immediately
rather than allowing the user to dictate when the program should run.
For more information
see [this excellent Reddit answer][link-so-future]
by Rob Norris.

When we look at Cats Effect 
we'll see that the `IO` type solves these problems.
]

If `Future` isn't referentially transparent,
perhaps we should look at another similar data-type that is.
You should recognise this one...

*Functions (?!)*

It turns out that single argument functions are also functors.
To see this we have to tweak the types a little.
A function `A => B` has two type parameters:
the parameter type `A` and the result type `B`.
To coerce them to the correct shape we can
fix the parameter type and let the result type vary:

 - start with `X => A`;
 - supply a function `A => B`;
 - get back `X => B`.

If we alias `X => A` as `MyFunc[A]`,
we see the same pattern of types
we saw with the other examples in this chapter.
We also see this in @fig:functors:function-type-chart:

 - start with `MyFunc[A]`;
 - supply a function `A => B`;
 - get back `MyFunc[B]`.

#figure(
    image("function-map.svg", width: 80%),
    caption: [Type chart: mapping over a Function1]
)<fig:functors:function-type-chart>

In other words, "mapping" over a `Function1` is function composition:

```scala mdoc:silent
import cats.syntax.all.*     // for map

val func1: Int => Double =
  (x: Int) => x.toDouble

val func2: Double => Double =
  (y: Double) => y * 2
```

```scala mdoc
(func1.map(func2))(1)     // composition using map
(func1.andThen(func2))(1) // composition using andThen
func2(func1(1))           // composition written out by hand
```

How does this relate to our general pattern
of sequencing operations?
If we think about it,
function composition _is_ sequencing.
We start with a function that performs a single operation
and every time we use `map` we append another operation to the chain.
Calling `map` doesn't actually _run_ any of the operations,
but if we can pass an argument to the final function
all of the operations are run in sequence.
We can think of this as lazily queueing up operations
similar to `Future`:

```scala mdoc:silent
val func =
  ((x: Int) => x.toDouble).
    map(x => x + 1).
    map(x => x * 2).
    map(x => s"${x}!")
```

```scala mdoc
func(123)
```

#warning[
*Partial Unification*

For the above examples to work,
in versions of Scala before 2.13,
we need to add the following compiler option to `build.sbt`:

```scala
scalacOptions += "-Ypartial-unification"
```

otherwise we'll get a compiler error:

```scala
func1.map(func2)
// <console>: error: value map is not a member of Int => Double
//        func1.map(func2)
                ^
```

We'll look at why this happens in detail
in @sec:functors:partial-unification.
]


== Definition of a Functor


Every example we've looked at so far is a functor:
a class that encapsulates sequencing computations.
Formally, a functor is a type `F[A]`
with an operation `map` with type `(A => B) => F[B]`.
The general type chart is shown in
@fig:functors:functor-type-chart.

#figure(
    image("generic-map.svg", width: 80%),
    caption: [Type chart: generalised functor map]
)<fig:functors:functor-type-chart>

Cats encodes `Functor` as a type class,
[`cats.Functor`][cats.Functor],
so the method looks a little different.
It accepts the initial `F[A]` as a parameter
alongside the transformation function.
Here's a simplified version of the definition:

```scala
package cats

trait Functor[F[_]] {
  def map[A, B](fa: F[A])(f: A => B): F[B]
}
```

If you haven't seen syntax like `F[_]` before,
it's time to take a brief detour to discuss
*type constructors_ and _higher kinded types*.

#warning[
*Functor Laws*

Functors guarantee the same semantics
whether we sequence many small operations one by one,
or combine them into a larger function before `mapping`.
To ensure this is the case the following laws must hold:

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
]

== Aside: Higher Kinds and Type Constructors


Kinds are like types for types.
They describe the number of "holes" in a type.
We distinguish between regular types that have no holes
and "type constructors" that have
holes we can fill to produce types.

For example, `List` is a type constructor with one hole.
We fill that hole by specifying a parameter to produce
a regular type like `List[Int]` or `List[A]`.
The trick is not to confuse type constructors with generic types.
`List` is a type constructor, `List[A]` is a type:

```scala
List    // type constructor, takes one parameter
List[A] // type, produced by applying a type parameter
```

There's a close analogy here with functions and values.
Functions are "value constructors"---they
produce values when we supply parameters:

```scala
math.abs    // function, takes one parameter
math.abs(x) // value, produced by applying a value parameter
```

In Scala we declare type constructors using underscores.
This specifies how many "holes" the type constructor has.
However, to use them we refer to just the name.

```scala
// Declare F using underscores:
def myMethod[F[_]] = {

  // Reference F without underscores:
  val functor = Functor.apply[F]

  // ...
}
```

This is analogous to specifying function parameter types.
When we declare a parameter we also give its type.
However, to use them we refer to just the name.

```scala
// Declare f specifying parameter types
def f(x: Int): Int = 
  // Reference x without type
  x * 2
```

Armed with this knowledge of type constructors,
we can see that the Cats definition of `Functor`
allows us to create instances for any single-parameter type constructor,
such as `List`, `Option`, `Future`, or a type alias such as `MyFunc`.

#info[
*Language Feature Imports*

In versions of Scala before 2.13
we need to "enable" the higher kinded type language feature,
to suppress warnings from the compiler,
whenever we declare a type constructor with `A[_]` syntax.
We can either do this with a "language import" as above:

```scala
import scala.language.higherKinds
```

or by adding the following to `scalacOptions` in `build.sbt`:

```scala
scalacOptions += "-language:higherKinds"
```

In practice we find the `scalacOptions` flag to be
the simpler of the two options.
]
