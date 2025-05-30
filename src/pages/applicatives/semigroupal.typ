#import "../stdlib.typ": info, warning, solution
== Semigroupal 
<sec:semigroupal>


[`cats.Semigroupal`][cats.semigroupal] is a type class that
allows us to combine contexts[^semigroupal-name].
If we have two objects of type `F[A]` and `F[B]`,
a `Semigroupal[F]` allows us to combine them to form an `F[(A, B)]`.
Its definition in Cats is:

```scala
trait Semigroupal[F[_]] {
  def product[A, B](fa: F[A], fb: F[B]): F[(A, B)]
}
```

As we discussed at the beginning of this chapter,
the parameters `fa` and `fb` are independent of one another:
we can compute them in either order before passing them to `product`.
This is in contrast to `flatMap`,
which imposes a strict order on its parameters.
This gives us more freedom when defining
instances of `Semigroupal` than we get when defining `Monads`.

[^semigroupal-name]: It
is also the winner of Underscore's 2017 award for
the most difficult functional programming term
to work into a coherent English sentence.

=== Joining Two Contexts


While `Semigroup` allows us to join values,
`Semigroupal` allows us to join contexts.
Let's join some `Options` as an example:

```scala mdoc:silent:reset-object
import cats.Semigroupal
import cats.instances.option._ // for Semigroupal
```

```scala mdoc
Semigroupal[Option].product(Some(123), Some("abc"))
```

If both parameters are instances of `Some`,
we end up with a tuple of the values within.
If either parameter evaluates to `None`,
the entire result is `None`:

```scala mdoc
Semigroupal[Option].product(None, Some("abc"))
Semigroupal[Option].product(Some(123), None)
```

=== Joining Three or More Contexts


The companion object for `Semigroupal` defines
a set of methods on top of `product`.
For example, the methods `tuple2` through `tuple22`
generalise `product` to different arities:

```scala mdoc:silent
import cats.instances.option._ // for Semigroupal
```

```scala mdoc
Semigroupal.tuple3(Option(1), Option(2), Option(3))
Semigroupal.tuple3(Option(1), Option(2), Option.empty[Int])
```

The methods `map2` through `map22`
apply a user-specified function
to the values inside 2 to 22 contexts:

```scala mdoc
Semigroupal.map3(Option(1), Option(2), Option(3))(_ + _ + _)

Semigroupal.map2(Option(1), Option.empty[Int])(_ + _)
```

There are also methods `contramap2` through `contramap22`
and `imap2` through `imap22`,
that require instances of `Contravariant` and `Invariant` respectively.

=== Semigroupal Laws


There is only one law for `Semigroupal`:
the `product` method must be associative.

```scala
product(a, product(b, c)) == product(product(a, b), c)
```

== Apply Syntax


Cats provides a convenient _apply syntax_
that provides a shorthand for the methods described above.
We import the syntax from [`cats.syntax.apply`][cats.syntax.apply].
Here's an example:

```scala mdoc:silent
import cats.instances.option._ // for Semigroupal
import cats.syntax.apply._     // for tupled and mapN
```

The `tupled` method is implicitly added to the tuple of `Options`.
It uses the `Semigroupal` for `Option` to zip the values inside the
`Options`, creating a single `Option` of a tuple:

```scala mdoc
(Option(123), Option("abc")).tupled
```

We can use the same trick on tuples of up to 22 values.
Cats defines a separate `tupled` method for each arity:

```scala mdoc
(Option(123), Option("abc"), Option(true)).tupled
```

In addition to `tupled`, Cats' apply syntax provides
a method called `mapN` that accepts an implicit `Functor`
and a function of the correct arity to combine the values.

```scala mdoc:silent
final case class Cat(name: String, born: Int, color: String)
```

```scala mdoc
(
  Option("Garfield"),
  Option(1978),
  Option("Orange & black")
).mapN(Cat.apply)
```

Of all the methods mentioned here,
it is most common to use `mapN`.

Internally `mapN` uses the `Semigroupal`
to extract the values from the `Option`
and the `Functor` to apply the values to the function.

It's nice to see that this syntax is type checked.
If we supply a function that
accepts the wrong number or types of parameters,
we get a compile error:

```scala mdoc
val add: (Int, Int) => Int = (a, b) => a + b
```

```scala mdoc:fail
(Option(1), Option(2), Option(3)).mapN(add)
```

```scala mdoc:fail
(Option("cats"), Option(true)).mapN(add)
```

=== Fancy Functors and Apply Syntax


Apply syntax also has `contramapN` and `imapN` methods
that accept Contravariant and Invariant functors
(@sec:functors:contravariant-invariant).
For example, we can combine `Monoids` using `Invariant`.
Here's an example:

```scala mdoc:silent:reset-object
import cats.Monoid
import cats.instances.int._        // for Monoid
import cats.instances.invariant._  // for Semigroupal
import cats.instances.list._       // for Monoid
import cats.instances.string._     // for Monoid
import cats.syntax.apply._         // for imapN

final case class Cat(
  name: String,
  yearOfBirth: Int,
  favoriteFoods: List[String]
)

val tupleToCat: (String, Int, List[String]) => Cat =
  Cat.apply _

val catToTuple: Cat => (String, Int, List[String]) =
  cat => (cat.name, cat.yearOfBirth, cat.favoriteFoods)

implicit val catMonoid: Monoid[Cat] = (
  Monoid[String],
  Monoid[Int],
  Monoid[List[String]]
).imapN(tupleToCat)(catToTuple)
```

Our `Monoid` allows us to create "empty" `Cats`,
and add `Cats` together using the syntax from @sec:monoids:

```scala mdoc:silent
import cats.syntax.semigroup._ // for |+|

val garfield   = Cat("Garfield", 1978, List("Lasagne"))
val heathcliff = Cat("Heathcliff", 1988, List("Junk Food"))
```

```scala mdoc
garfield |+| heathcliff
```
