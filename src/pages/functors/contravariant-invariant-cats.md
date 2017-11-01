## *Contravariant* and *Invariant* in Cats

Let's look at the implementation of
contravariant and invariant functors in Cats.
The [`Contravariant`][cats.functor.Contravariant] and
[`Invariant`][cats.functor.Invariant] type classes
are slightly different to Cats' other type classes:
they live under [`cats.functor`][cats.functor.package]
instead of [`cats`][cats.package].
Here's a simplified version of the code:

```tut:book:invisible
import scala.language.higherKinds
```

```tut:book:silent
trait Contravariant[F[_]] {
  def contramap[A, B](fa: F[A])(f: B => A): F[B]
}

trait Invariant[F[_]] {
  def imap[A, B](fa: F[A])(f: A => B)(g: B => A): F[B]
}
```

### *Contravariant* in Cats

We can summon instances of `Contravariant`
using the `Contravariant.apply` method.
Cats provides instances for data types that consume parameters,
including `Eq`, `Show`, and `Function1`.
Here's an example:

```tut:book:silent:reset
import cats.Show
import cats.functor.Contravariant
import cats.instances.string._

val showString = Show[String]

val showSymbol = Contravariant[Show].
  contramap(showString)((sym: Symbol) => s"'${sym.name}")
```

```tut:book
showSymbol.show('dave)
```

More conveniently, we can use
[`cats.syntax.contravariant`][cats.syntax.contravariant],
which provides a `contramap` extension method:

```tut:book:silent
import cats.syntax.contravariant._
```

```tut:book
showString.contramap[Symbol](_.name).show('dave)
```

### *Invariant* in Cats

Among other types,
Cats provides instances of `Invariant`
for `Semigroup` and `Monoid`.
These are a little different from the `Codec`
example we introduced in Section [@sec:functors:invariant].
Let's look at semigroups as an example.
If you recall, this is what `Semigroup` looks like:

```scala
package cats

trait Semigroup[A] {
  def combine(x: A, y: A): A
}
```

Imagine we want to produce a `Semigroup`
for Scala's [`Symbol`][link-symbol] type.
Cats doesn't provide a `Semigroup` for `Symbol`
but it does provide a `Semigroup` for a similar type: `String`.
We can write our new semigroup with
a `combine` method that works as follows:

1. accept two `Symbols` as parameters;
2. convert the `Symbols` to `Strings`;
3. combine the `Strings` using `Semigroup[String]`;
4. convert the result back to a `Symbol`.

We can implement this code using `imap`,
passing functions of type `String => Symbol`
and `Symbol => String` as parameters.
Here' the code, written out using
the `imap` extension method
provided by `cats.syntax.invariant`:

```tut:book:silent
import cats.Semigroup
import cats.instances.semigroup._ // Cartesian for Semigroup
import cats.instances.string._    // Semigroup for String
import cats.syntax.invariant._    // imap extension method

implicit val symbolSemigroup: Semigroup[Symbol] =
  Semigroup[String].imap(Symbol.apply)(_.name)

import cats.syntax.semigroup._
```

```tut:book
'a |+| 'few |+| 'words
```
