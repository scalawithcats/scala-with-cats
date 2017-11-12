## Aside: Partial Unification {#sec:functors:partial-unification}

In Section [@sec:functors:more-examples]
we saw a curious compiler error.
The following code compiled perfectly
if we had the `-Ypartial-unification` compiler flag enabled:

```tut:book:silent
import cats.Functor
import cats.instances.function._ // for Functor
import cats.syntax.functor._     // for map

val func1 = (x: Int)    => x.toDouble
val func2 = (y: Double) => y * 2
```

```tut:book
val func3 = func1.map(func2)
```

but failed if the flag was missing:

```scala
val func3 = func1.map(func2)
// <console>: error: value map is not a member of Int => Double
//        val func3 = func1.map(func2)
                            ^
```

Obviously "partial unification" is
some kind of optional compiler behaviour,
without which our code will not compile.
We should take a moment to describe this behaviour
and discuss some gotchas and workarounds.

### Unifying Type Constructors

In order to compile an expression like `func1.map(func2)` above,
the compiler has to search for a `Functor` for `Function1`.
However, `Functor` accepts a type constructor with one parameter:

```scala
trait Functor[F[_]] {
  def map[A, B](fa: F[A])(func: A => B): F[B]
}
```

and `Function1` has two type parameters
(the function argument and the result type):

```scala
trait Function1[-A, +B] {
  def apply(arg: A): B
}
```

The compiler has to fix one of the two parameters
of `Function1` to create a type constructor
of the correct kind to pass to `Functor`.
It has two options to choose from:

```tut:book:silent
type F[A] = Int => A
type F[A] = A => Double
```

*We* know that the former of these is the correct choice.
However, earlier versions of the Scala compiler
were not able to make this inference.
This infamous limitation,
known as [SI-2712][link-si2712],
prevented the compiler "unifying" type constructors
of different arities.
This compiler limitation is now fixed,
although we have to enable the fix
via a compiler flag in `build.sbt`:

```scala
scalacOptions += "-Ypartial-unification"
```

### Left-to-Right Elimination

The partial unification in the Scala compiler
works by fixing type parameters from left to right.
In the above example, the compiler fixes
the `Int` in `Int => Double`
and looks for a `Functor` for functions of type `Int => ?`:

```tut:book:silent
type F[A] = Int => A

val functor = Functor[F]
```

This left-to-right elimination works for
a wide variety of common scenarios,
including `Functors` for
types such as `Function1` and `Either`:

```tut:book:silent
import cats.instances.either._ // for Functor
```

```tut:book
val either: Either[String, Int] = Right(123)

either.map(_ + 1)
```

However, there are situations where
left-to-right elimination is not the correct choice.
One example is the `Or` type in [Scalactic][link-scalactic],
which is a conventionally left-biased equivalent of `Either`:

```scala
type PossibleResult = ActualResult Or Error
```

Another example is the `Contravariant` functor for `Function1`.

While the covariant `Functor` for `Function1` implements
`andThen`-style left-to-right function composition,
the `Contravariant` functor implements `compose`-style
right-to-left composition.
In other words, the following expressions are all equivalent:

```tut:book:silent
val func3a: Int => Double =
  a => func2(func1(a))

val func3b: Int => Double =
  func2.compose(func1)
```

```tut:book:fail:silent
// Hypothetical example. This won't actually compile:
val func3c: Int => Double =
  func2.contramap(func1)
```

If we try this for real, however,
our code won't compile:

```tut:book:silent
import cats.syntax.contravariant._ // for contramap
```

```tut:book:fail
val func3c = func2.contramap(func1)
```

The problem here is that the `Contravariant` for `Function1`
fixes the return type and leaves the parameter type varying,
requiring the compiler to eliminate type parameters
from right to left, as shown below and in Figure [@fig:functors:function-contramap-type-chart]:

```scala
type F[A] = A => Double
```

![Type chart: contramapping over a Function1](src/pages/functors/function-contramap.pdf+svg){#fig:functors:function-contramap-type-chart}

The compiler fails simply because of its left-to-right bias.
We can prove this by creating a type alias
that flips the parameters on Function1:

```tut:book:silent
type <=[B, A] = A => B

type F[A] = Double <= A
```

If we re-type `func2` as an instance of `<=`,
we reset the required order of elimination and
we can call `contramap` as desired:

```tut:book:silent
val func2b: Double <= Double = func2
```

```tut:book
val func3c = func2b.contramap(func1)
```

The difference between `func2` and `func2b` is
purely syntactic---both refer to the same value
and the type aliases are otherwise completely compatible.
Incredibly, however,
this simple rephrasing is enough to
give the compiler the hint it needs
to solve the problem.

It is rare that we have to do
this kind of right-to-left elimination.
Most multi-parameter type constructors
are designed to be right-biased,
requiring the left-to-right elimination
that is supported by the compiler
out of the box.
However, it is useful to know about
`-Ypartial-unification`
and this quirk of elimination order
in case you ever come across
an odd scenario like the one above.
