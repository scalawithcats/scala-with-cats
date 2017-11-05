## *Semigroupal* {#semigroupal}

`Semigroupal` is a type class that
allows us to combine values within a context[^semigroupal-name].
If we have two objects of type `F[A]` and `F[B]`,
a `Semigroupal[F]` allows us to combine them to form an `F[(A, B)]`.
Its definition in Cats is:

```scala
trait Semigroupal[F[_]] {
  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
}
```

As we discussed above,
the parameters `fa` and `fb` are independent of one another.
This gives us a lot more flexibility when
defining instances of `Semigroupal` than we do when defining `Monads`.

[^semigroupal-name]: It
is also the winner of Underscore's 2017 award for
the most difficult functional programming term
to work into a coherent English sentence.

### Joining Two Contexts

While `Semigroup` allows us to join values,
`Semigroupal` allows us to join contexts.
Let's join some `Options` as an example:

```tut:book:silent
import cats.Semigroupal
import cats.instances.option._ // Semigroupal for Option
```

```tut:book
Semigroupal[Option].product(Some(123), Some("abc"))
```

If both parameters are instances of `Some`,
we end up with a tuple of the values within.
If either parameter evaluates to `None`,
the entire result is `None`:

```tut:book
Semigroupal[Option].product(None, Some("abc"))
Semigroupal[Option].product(Some(123), None)
```

### Joining Three or More Contexts

The companion object for `Semigroupal` defines
a set of methods on top of `product`.
For example, the methods `tuple2` through `tuple22`
generalise `product` to different arities:

```tut:book:silent
import cats.instances.option._ // Semigroupal for Option
```

```tut:book
Semigroupal.tuple3(Option(1), Option(2), Option(3))
Semigroupal.tuple3(Option(1), Option(2), Option.empty[Int])
```

The methods `map2` through `map22`
apply a user-specified function
to the values inside 2 to 22 contexts:

```tut:book
Semigroupal.map3(
  Option(1),
  Option(2),
  Option(3)
)(_ + _ + _)

Semigroupal.map3(
  Option(1),
  Option(2),
  Option.empty[Int]
)(_ + _ + _)
```

There are also methods `contramap2` through `contramap22`
and `imap2` through `imap22`,
that require instances of `Contravariant` and `Invariant` respectively.

<!--
### *Semigroupal* Laws

There is only one law for `Semigroupal`:
the `product` method must be associative:

```scala
product(a, product(b, c)) == product(product(a, b), c)
```
-->

## *Apply* Syntax

Cats provides a convenient syntax called *apply syntax*,
that provides a shorthand for the methods described above.
We import the syntax from [`cats.syntax.apply`][cats.syntax.apply].
Here's an example:

```tut:book:silent
import cats.instances.option._
import cats.syntax.apply._
```

```tut:book
(Option(123), Option("abc")).tupled
```

The `tupled` method is implicitly added to the tuple of `Options`.
It uses the `Semigroupal` for `Option` to zip the values inside the
`Options`, creating a single `Option` of a tuple.

We can use the same trick on tuples of up to 22 values.
Cats defines a separate `tupled` method for each arity:

```tut:book
(Option(123), Option("abc"), Option(true)).tupled
```

In addition to `tupled`, Cats' apply syntax provides
a method called `mapN` that accepts an implicit `Functor`
and a function of the correct arity to combine the values:

```tut:book:silent
case class Cat(name: String, born: Int, color: String)
```

```tut:book
(
  Option("Garfield"),
  Option(1978),
  Option("Orange and black")
).mapN(Cat.apply)
```

Internally `mapN` uses the `Semigroupal`
to extract the values from the `Option`
and the `Functor` to apply the values to the function.

It's nice to see that this syntax is type checked.
If we supply a function that
accepts the wrong number or types of parameters,
we get a compile error:

```tut:book
val add: (Int, Int) => Int = (a, b) => a + b
```

```tut:book:fail
(Option(1), Option(2), Option(3)).mapN(add)
```

```tut:book:fail
(Option("cats"), Option(true)).mapN(add)
```

### Fancy Functors and Apply Syntax

Apply syntax also has `contramapN` and `imapN` methods
that accept [Contravariant](#contravariant)
and [Invariant](#invariant) functors.
For example, we can combine `Monoids` and `Semigroups`
using `Invariant`.
Here's an example:

```tut:book:silent
import cats.Monoid
import cats.instances.boolean._
import cats.instances.int._
import cats.instances.list._
import cats.instances.string._
import cats.syntax.apply._

case class Cat(
  name: String,
  yearOfBirth: Int,
  favoriteFoods: List[String]
)

def catToTuple(cat: Cat) =
  (cat.name, cat.yearOfBirth, cat.favoriteFoods)

implicit val catMonoid = (
  Monoid[String],
  Monoid[Int],
  Monoid[List[String]]
).imapN(Cat.apply)(catToTuple)
```

Our `Monoid` allows us to create "empty" `Cats`
and add `Cats` together using the syntax from
Chapter [@sec:monoids]:

```tut:book:silent
import cats.syntax.monoid._
```

```tut:book
Monoid[Cat].empty
```

```tut:book:silent
val garfield   = Cat("Garfield", 1978, List("Lasagne"))
val heathcliff = Cat("Heathcliff", 1988, List("Junk Food"))
```

```tut:book
garfield |+| heathcliff
```
