#import "../stdlib.typ": info, warning, solution
== Contravariant and Invariant in Cats


Let's look at the implementation of
contravariant and invariant functors in Cats,
provided by the [`cats.Contravariant`][cats.Contravariant]
and [`cats.Invariant`][cats.Invariant] type classes respectively.
Here's a simplified version of the code:

```scala mdoc:invisible
```

```scala mdoc:silent
trait Contravariant[F[_]] {
  def contramap[A, B](fa: F[A])(f: B => A): F[B]
}

trait Invariant[F[_]] {
  def imap[A, B](fa: F[A])(f: A => B)(g: B => A): F[B]
}
```

=== Contravariant in Cats


We can summon instances of `Contravariant`
using the `Contravariant.apply` method.
Cats provides instances for data types that consume parameters,
including `Eq`, `Show`, and `Function1`.
Here's an example:

```scala mdoc:silent:reset
import cats.*

val showString = Show[String]

val showSymbol = Contravariant[Show].
  contramap(showString)((sym: Symbol) => s"'${sym.name}")
```

```scala mdoc
showSymbol.show(Symbol("dave"))
```

More conveniently, we can use
[`cats.syntax.contravariant`][cats.syntax.contravariant],
which provides a `contramap` extension method:

```scala mdoc:silent
import cats.syntax.contravariant.* // for contramap
```

```scala mdoc
showString
  .contramap[Symbol](sym => s"'${sym.name}")
  .show(Symbol("dave"))
```

=== Invariant in Cats


Among other types,
Cats provides an instance of `Invariant` for `Monoid`.
This is a little different from the `Codec`
example we introduced in @sec:functors:invariant.
If you recall, this is what `Monoid` looks like:

```scala
package cats

trait Monoid[A] {
  def empty: A
  def combine(x: A, y: A): A
}
```

Imagine we want to produce a `Monoid`
for Scala's [`Symbol`][link-symbol] type.
Cats doesn't provide a `Monoid` for `Symbol`
but it does provide a `Monoid` for a similar type: `String`.
We can write our new semigroup with
an `empty` method that relies on the empty `String`,
and a `combine` method that works as follows:

+ accept two `Symbols` as parameters;
+ convert the `Symbols` to `Strings`;
+ combine the `Strings` using `Monoid[String]`;
+ convert the result back to a `Symbol`.

We can implement `combine` using `imap`,
passing functions of type `String => Symbol`
and `Symbol => String` as parameters.
Here' the code, written out using
the `imap` extension method
provided by `cats.syntax.invariant`:

```scala mdoc:silent
import cats.*
import cats.syntax.invariant.* // for imap
import cats.syntax.semigroup.* // for |+|

given symbolMonoid: Monoid[Symbol] =
  Monoid[String].imap(Symbol.apply)(_.name)
```

```scala mdoc
Monoid[Symbol].empty

Symbol("a") |+| Symbol("few") |+| Symbol("words")
```
