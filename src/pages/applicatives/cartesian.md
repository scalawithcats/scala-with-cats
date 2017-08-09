## *Cartesian* {#cartesian}

`Cartesian` is a type class that allows us to "zip" values within a context.
If we have two objects of type `F[A]` and `F[B]`,
a `Cartesian[F]` allows us to combine them to form an `F[(A, B)]`.
Its definition in Cats is:

```scala
trait Cartesian[F[_]] {
  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
}
```

As we discussed above,
the parameters `fa` and `fb` are independent of one another.
This gives us a lot more flexibility when
defining instances of `Cartesian` than we do when defining `Monads`.

### Joining Two Contexts

Whereas `Semigroups` allow us to join values,
`Cartesians` allow us to join contexts.
Let's join some `Options` as an example:

```tut:book:silent
import cats.Cartesian
import cats.instances.option._ // Cartesian for Option
```

```tut:book
Cartesian[Option].product(Some(123), Some("abc"))
```

If both parameters are instances of `Some`,
we end up with a tuple of the values within.
If either parameter evaluates to `None`,
the entire result is `None`:

```tut:book
Cartesian[Option].product(None, Some("abc"))
Cartesian[Option].product(Some(123), None)
```

### Joining Three or More Contexts

The companion object for `Cartesian` defines
a set of methods on top of `product`.
For example, the methods `tuple2` through `tuple22`
generalise `product` to different arities:

```tut:book:silent
import cats.instances.option._ // Cartesian for Option
```

```tut:book
Cartesian.tuple3(Option(1), Option(2), Option(3))
Cartesian.tuple3(Option(1), Option(2), Option.empty[Int])
```

The methods `map2` through `map22`
apply a user-specified function
to the values inside 2 to 22 contexts:

```tut:book
Cartesian.map3(
  Option(1),
  Option(2),
  Option(3)
)(_ + _ + _)

Cartesian.map3(
  Option(1),
  Option(2),
  Option.empty[Int]
)(_ + _ + _)
```

There are also methods `contramap2` through `contramap22`
and `imap2` through `imap22`,
that require instances of `Contravariant` and `Invariant` respectively.

<!--
### *Cartesian* Laws

There is only one law for `Cartesian`:
the `product` method must be associative:

```scala
product(a, product(b, c)) == product(product(a, b), c)
```
-->

## *Cartesian Builder* Syntax

Cats provides a convenient syntax called *cartesian builder syntax*,
that provides shorthand for methods like `tupleN` and `mapN`.
We import the syntax from [`cats.syntax.cartesian`][cats.syntax.cartesian].
Here's an example:

```tut:book:silent
import cats.instances.option._
import cats.syntax.apply._
```

```tut:book
(Option(123), Option("abc")).tupled
```

The `|@|` operator, better known as a "tie fighter",
creates a temporary "builder" object that provides
several methods for combining the parameters
to create useful data types.
For example, the `tupled` method zips the values into a tuple:

```tut:book:silent
val builder2 = (Option(123), Option("abc"))
```

```tut:book
builder2.tupled
```

We can use `|@|` repeatedly to create builders for up to 22 values.
Each arity of builder, from 2 to 22, defines a `tupled` method
to combine the values to form a tuple of the correct size:

```tut:book:silent
val builder3 = (Option(123), Option("abc"), Option(true))
```

```tut:book
builder3.tupled
```

The idiomatic way of writing builder syntax is
to combine `|@|` and `tupled` in a single expression,
going from single values to a tuple in one step:

```tut:book
(
  Option(1),
  Option(2),
  Option(3)
).tupled
```

In addition to `tupled`, every builder has a `map` method
that accepts an implicit `Functor`
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

### Fancy Functors and Cartesian Builder Syntax

Cartesian builders also have a `contramap` and `imap` methods
that accept [Contravariant](#contravariant)
and [Invariant](#invariant) functors.
For example, we can combine `Monoids` and `Semigroups` using `Invariant`.
Here's an example:

```tut:book:silent
import cats.Monoid
import cats.instances.boolean._
import cats.instances.int._
import cats.instances.list._
import cats.instances.string._
import cats.instances.monoid._
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
