## Aside: Partial Unification {#sec:functors:partial-unification}

In Section [@sec:functors:more-examples]
we saw a curious compiler error.
The following code compiled perfectly
if we had the `-Ypartial-unification` compiler flag enabled:

```tut:book:silent
import cats.Functor
import cats.instances.function._
import cats.syntax.functor._

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

Obviously this compiler flag
enables some optional compiler behaviour,
without which our code will not compile.
We should take a moment to
describe what partial unification is
and discuss some gotchas and workarounds.

### Unifying Type Constructors

In order to compile an expression like `func1.map(func2)`
the compiler has to search for a `Functor` for `func1`.
It has two options to choose from:

```scala
Functor[Int => ?]
Functor[? => Double]
```

*We* know that the former of these is the correct choice.
However, earlier versions of the Scala compiler
were not able to make this choice.
This infamous limitation,
known as [SI-2712][link-si2712],
prevented the compiler "unifying" type constructors
of different arities.
This compiler limitation is now fixed.
However, in current versions of the Scala compiler
the fix is disabled by default
and must be enabled via
the `-Ypartial-unification` feature flag.

### Left-to-Right Elimination

The partial unification in the Scala compiler
works by fixing type parameters from left to right.
In the above example, the compiler fixes
the `Int` in `Int => Double`
and looks for a `Functor` for functions of type `Int => ?`.

This left-to-right elimination works for
a wide variety of common scenarios,
including funding `Functors` for binary type constructors
such as `Function1` and `Either`:

```tut:book:silent
import cats.instances.either._
```

```tut:book
val either: Either[String, Int] = Right(123)

either.map(_ + 1)
```

However, there are situations where
left-to-right elimination is not the correct choice.
One example is the `Or` type in [Scalactic][link-scalactic],
which is a conventionally left-biased equivalent of `Either`
allowing users to specify types such as `SomeResult Or SomeError`.
Another example is the `Contravariant` functor for `Function1`.

While the `Functor` for `Function1` implements
`andThen`-style left-to-right function composition,
the `Contravariant` functor implements `compose`-style
right-to-left composition.
In other words, the following expressions are equivalent:

```scala
// Hypothetical example - will not compile:
func2.contramap(func1)
func2.compose(func1)
a => func1(func2(a))
```

If we try this for real, however,
our code won't compile:

```tut:book:silent
import cats.syntax.contravariant._
```

```tut:book:fail
val func4 = func2.contramap(func1)
```

The problem here is that the `Contravariant` for `Function1`
fixes the return type and leaves the parameter type varying,
requiring the compiler to eliminate type parameters
from right to left:

```scala
Contravariant[? => Double]
```

The compiler fails here simply because of its left-to-right bias.
We can prove this by creating a type alias
that flips the parameters on Function1:

```tut:book:silent
type <=[B, A] = A => B
```

If we re-type `func2` as an instance of `<=`,
we reset the required order of elimination and
we can call `contramap` as desired:

```tut:book:silent
val func2b: Double <= Double = func2
```

```tut:book
val func4 = func2b.contramap(func1)
```

It is rare that we have to do
this kind of right-to-left elimination.
Most multi-parameter type constructors
are designed to be right-biased,
requiring the left-to-right elimination
supported by the compiler.
However, it's useful to know about
`-Ypartial-unification`
and this elimination order limitation
in case you ever come across
an odd scenario like the one above.
