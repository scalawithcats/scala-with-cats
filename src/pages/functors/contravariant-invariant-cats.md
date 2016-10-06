## *Contravariant* and *Invariant* in Cats

Cats's [`Contravariant`][cats.functor.Contravariant] and
[`Invariant`][cats.functor.Invariant] type classes
are slightly different to its other type classes:
they live under [`cats.functor`][cats.functor.package]
instead of [`cats`][cats.package].
Here's a simplified version of the code,
throwing regular `Functor` into the mix as well:

```scala
package cats.functor {
  trait Invariant[F[_]] {
    def imap[A, B](fa: F[A])(f: A => B)(g: B => A): F[B]
  }

  trait Contravariant[F[_]] extends Invariant[F] {
    def contramap[A, B](fa: F[A])(f: B => A): F[B]

    override def imap[A, B](fa: F[A])(f: A => B)(fi: B => A): F[B] =
      contramap(fa)(fi)
  }
}

package cats {
  trait Functor[F[_]] extends functor.Invariant[F] {
    def map[A, B](fa: F[A])(f: A => B): F[B]

    def imap[A, B](fa: F[A])(f: A => B)(fi: B => A): F[B] =
      map(fa)(f)
  }
}
```

Note that `Functor` and `Contravariant` both extend `Invariant`.
Each implements `imap` by throwing away one of the two transformation functions.
If we write code that depends on `Invariant`,
it will work with both the other types of functor as well.

### *Contravariant* in Cats

We can summon instances of `Contravariant`
using the `Contravariant.apply` method.
Cats provides instances for data types that consume parameters,
including `Eq`, `Show`, `Writer`, `WriterT`, and `Function1`:

```tut:book:silent
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
which provides a `contravariant` extension method:

```tut:book:silent
import cats.instances.function._
import cats.syntax.contravariant._

val div2: Int => Double = _ / 2.0
val add1: Int => Int    = _ + 1
```

```tut:book
div2.contramap(add1)(2)
```

#### *Invariant* in Cats

Cats provides instances of `Invariant` for `Semigroup` and `Monoid`.
Imagine we have a semigroup for a well known type, for example `Semigroup[String]`,
and we want to convert it to another type like `Semigroup[Symbol]`.
To do this we need two functions: one to convert the `Symbol` parameters to `Strings`,
and one to convert the result of the `String` append back to a `Symbol`:

```tut:book:silent
import cats.Semigroup
import cats.instances.string._ // semigroup for String
import cats.syntax.invariant._ // imap extension method

implicit val symbolSemigroup: Semigroup[Symbol] =
  Semigroup[String].imap(Symbol.apply)(_.name)

import cats.syntax.semigroup._
```

```tut:book
'a |+| 'few |+| 'words
```
