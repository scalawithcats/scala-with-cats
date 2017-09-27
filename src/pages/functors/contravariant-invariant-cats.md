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

Cats treats `Functor` and `Contravariant` as specialisations of `Invariant`.
This means Cats can provide operations
that work with any of the three types of functor[^tupled].

[^tupled]: One example is the `tupled` method
provided by the *apply syntax*
discussed in Chapter [@sec:applicatives].

### *Contravariant* in Cats

We can summon instances of `Contravariant`
using the `Contravariant.apply` method.
Cats provides instances for data types that consume parameters,
including `Eq`, `Show`, and `Function1`.
As you may have guessed, the instance for `Function1`
fixes the return type and allows the parameter type to vary
as shown in Figure [@fig:functors:function-contramap-type-chart]:

![Type chart: contramapping over a Function1](src/pages/functors/function-contramap.pdf+svg){#fig:functors:function-contramap-type-chart}

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

Cats provides instances of `Invariant` for `Semigroup` and `Monoid`.
It also provides an `imap` extension method
via the `cats.syntax.invariant` import.
Imagine we have a semigroup for a well known type,
for example `Semigroup[String]`,
and we want to convert it to another type like `Semigroup[Symbol]`:

- the `combine` method accepts two `Symbols` as parameters;
- we need a function to convert the `Symbols` to `Strings`;
- we combine the `Strings` using the `Semigroup[String]`;
- we need a second function to convert the result to a `Symbol`.

Here's a demonstration:

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
