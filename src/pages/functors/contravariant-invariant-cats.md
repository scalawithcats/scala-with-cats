## *Contravariant* and *Invariant* in Cats

Cats's [`Contravariant`][cats.functor.Contravariant] and
[`Invariant`][cats.functor.Invariant] type classes
are slightly different to its other type classes:
they live under [`cats.functor`][cats.functor.package]
instead of [`cats`][cats.package].
Here's a simplified version of the code:

```tut:book:invisible
import scala.language.higherKinds
```

```tut:book:silent
trait Invariant[F[_]] {
  def imap[A, B](fa: F[A])(f: A => B)(g: B => A): F[B]
}

trait Contravariant[F[_]] extends Invariant[F] {
  def contramap[A, B](fa: F[A])(f: B => A): F[B]

  def imap[A, B](fa: F[A])(f: A => B)(fi: B => A): F[B] =
    contramap(fa)(fi)
}

trait Functor[F[_]] extends Invariant[F] {
  def map[A, B](fa: F[A])(f: A => B): F[B]

  def imap[A, B](fa: F[A])(f: A => B)(fi: B => A): F[B] =
    map(fa)(f)
}
```

Cats treats `Functor` and `Contravariant` as specialisations of `Invariant`
where one side of the bidirectional transformation is ignored.
Cats uses this to provide operations
that work with any of the three types of functor[^tupled].

[^tupled]: One example is the `tupled` method
provided by the cartesian builder syntax
discussed in [Chapter 6](#applicatives).

### *Contravariant* in Cats

We can summon instances of `Contravariant`
using the `Contravariant.apply` method.
Cats provides instances for data types that consume parameters,
including `Eq`, `Show`, `Writer`, `WriterT`, and `Function1`:

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
It also provides an `imap` extension method
via the `cats.syntax.invariant` import.
Imagine we have a semigroup for a well known type,
for example `Semigroup[String]`,
and we want to convert it to another type like `Semigroup[Symbol]`.
To do this we need two functions:
one to convert the `Symbol` parameters to `Strings`,
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
