### *Unapply*, *traverseU*, and *sequenceU*

One of the frequent problems people encounter when using `Traverse`
is that it doesn't play well with effect types with two or more type parameters.
For example, suppose we have a `List` of `Xors`:

```tut:book
import cats.data.Xor,
       cats.instances.list._,
       cats.syntax.traverse._

val xors: List[Xor[String, Int]] =
  List(Xor.left("poor"), Xor.right(1337))
```

When we call `sequence` we get a compile error:

```tut:book:fail
xors.sequence
```

The reason for this failure is that
the compiler can't find an implicit value for its `Applicative` parameter.
This isn't a problem we're causing---we have the correct syntax and instances in scope---it's
simply a weakness of Scala's type inference that was only just fixed in Scala 2.12
(more on the fix in a moment).

To understand what's going on, let's look again at the definition of `sequence`:

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

```tut:book
type G[A] = Xor[A, Int]
type G[A] = Xor[String, A]
```

It's obvious to us which unification method to choose.
However, due to an infamous limitation called [SI-2712][link-si2712],
the Scala type checker was unable to make this choice until recently
(the limitation was fixed in Scala 2.12---more on this in a moment).

To work around this issue, Cats includes a type class called `Unapply`,
whose purpose is to hint to the compiler which hole to "fix" to turn a
binary type constructor into a unary one.
Cats provides instances of `Unapply` for all the common binary types:
`Either`, `Xor`, `Validated`, and `Function1`, and so on.
The `Traversable` type class provides variants
of `traverse` and `sequence`---called `traverseU` and `sequenceU`---that
use `Unapply` to fix the problem and guide the compiler to the correct solution:

```tut:book
xors.sequenceU
```

The inner workings of `Unapply` aren't particularly important---
all we need to know is that this tool is available to fix these kinds of problems.

It is worth noting that [SI-2712][link-si2712] was fixed by Miles Sabin in a patch to Scala 2.12.
The fix allows calls to `traverse` and `sequence` to compile in a much wider set of situations,
although tools like `Unapply` will still be necessary in certain cases in the future.

For a more comprehensive write-up of SI-2712
see [this post by Daniel Spiewak][link-spiewak-si2712].
Miles' SI-2712 fix can also be backported
to Scala 2.11 and 2.10 using [this compiler plugin][link-si2712-compiler-plugin].
