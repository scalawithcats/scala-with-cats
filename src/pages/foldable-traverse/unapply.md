### *Unapply*, *traverseU*, and *sequenceU*

One frequent problem people encounter when using `Traverse`
is that it doesn't play well with effects
with two or more type parameters.
For example, suppose we have a `List` of `Xors`:

```tut:book:silent
import cats.data.Xor
import cats.instances.list._
import cats.syntax.traverse._

val xors: List[Xor[String, String]] = List(
  Xor.right("Wow!"),
  Xor.right("Such cool!")
)
```

When we call `sequence` we get a compile error:

```tut:book:fail
xors.sequence
```

The reason for this failure is that
the compiler can't find an implicit `Applicative`.
This isn't a problem in our code---we
have the correct syntax and instances in scope---it's
simply a weakness of Scala's type inference
that has only recently been fixed
(more on the fix in a moment).

To understand what's going on,
let's look again at the definition of `sequence`:

```scala
trait Traverse[F[_]]
  def sequence[G[_]: Applicative, B]: G[F[B]] =
    // etc...
}
```

To compile a call like `xors.sequence`,
the compiler has to find values for the type parameters `G` and `B`.
The types it is attempting to unify them with are `Xor[String, Int]` and `Int`,
so it has to make a decision about which parameter on `Xor` to fix
to create a type constructor of the correct shape.

There are two possible solutions as you can see below:

```tut:book:silent
type G[A] = Xor[A, Int]
type G[A] = Xor[String, A]
```

It's obvious to us which unification method to choose.
However, prior to Scala 2.12,
an infamous compiler limitation called [SI-2712][link-si2712]
prevented this inferrence.

To work around this issue
Cats provides a utilitiy type class called `Unapply`,
whose purpose is to tell the compiler which parameters to "fix"
to create a unary type constructor for a given type.
Cats provides instances of `Unapply` for the common binary types:
`Either`, `Xor`, `Validated`, and `Function1`, and so on.
`Traverse` provides variants of `traverse` and `sequence`---called
`traverseU` and `sequenceU`---that
use `Unapply` to guide the compiler to the correct solution:

```tut:book
xors.sequenceU
```

The inner workings of `Unapply` aren't particularly important---
all we need to know is that this tool is available
to fix these kinds of problems.

<div class="callout callout-info">
*Fixes to SI-2712*

[SI-2712][link-si2712] is fixed in Lightbend Scala 2.12.1
and [Typelevel Scala][link-typelevel-scala] 2.11.8.
The fix allows calls to `traverse` and `sequence`
to compile in a much wider set of cases,
although tools like `Unapply` are still necessary
in certain situations.

The SI-2712 fix can be backported to Scala 2.11 and 2.10
using [this compiler plugin][link-si2712-compiler-plugin].
</div>
