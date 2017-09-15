## *Contravariant* and *Invariant* Functors {#contravariant-invariant}

As we have seen, we can think of `Functor's` `map` method as
"appending" a transformation to a chain.
We're now going to look at two other type classes,
one representing *prepending* operations to a chain,
and one representing building a *bidirectional*
chain of operations. These are called *contravariant*
and *invariant functors* respectively.

### Contravariant functors and the *contramap* method {#contravariant}

The first of our type classes, the *contravariant functor*,
provides an operation called `contramap`
that represents "prepending" a transformation to a chain.
This is illustrated in Figure [@fig:functors:contramap-type-chart].

![Type chart: the contramap method](src/pages/functors/generic-contramap.pdf+svg){#fig:functors:contramap-type-chart}

We'll talk about the `contramap` method first,
introducing the Cats type class in a moment.

`contramap` only makes sense for certain data types.
For example, we can't define `contramap` for an `Option`
because there is no way of feeding a value in an
`Option[B]` backwards through a function `A => B`.

`contramap` makes more sense for
types that represent transformations.
For example, consider the `Printable` type class
we discussed in Chapter [@sec:type-classes]:

```tut:book:silent
trait Printable[A] {
  def format(value: A): String
}
```

A `Printable[A]` represents a transformation from `A` to `String`.
We can define a `contramap` method that
"prepends" a transformation from another type `B`:

```tut:book:silent
trait Printable[A] {
  def format(value: A): String

  def contramap[B](func: B => A): Printable[B] =
    ???
}

def format[A](value: A)(implicit p: Printable[A]): String =
  p.format(value)
```

This says that if `A` is `Printable`,
and we can transform `B` into `A`,
then `B` is also `Printable`.

#### Exercise: Showing off with Contramap

Implement the `contramap` method for `Printable` above.

<div class="solution">
Here's a working implementation.
In a small show of sleight of hand
we use a `self` alias
to refer to the outer `Printable`
from the `format` method of the inner `Printable`:

```tut:book:silent
trait Printable[A] {
  self =>

  def format(value: A): String

  def contramap[B](func: B => A): Printable[B] =
    new Printable[B] {
      def format(value: B): String =
        self.format(func(value))
    }
}

def format[A](value: A)(implicit p: Printable[A]): String =
  p.format(value)
```
</div>

Let's define some instances of `Printable`
for `String` and `Boolean` for testing purposes:

```tut:book:silent
implicit val stringPrintable: Printable[String] =
  new Printable[String] {
    def format(value: String): String =
      "\"" + value + "\""
  }

implicit val booleanPrintable: Printable[Boolean] =
  new Printable[Boolean] {
    def format(value: Boolean): String =
      if(value) "yes" else "no"
  }
```

```tut:book
format("hello")
format(true)
```

Now define an instance of `Printable` for
the following `Box` case class.
You'll need to write this as an `implicit def`:

```tut:book:silent
final case class Box[A](value: A)
```

Rather than writing out
the complete definition from scratch
(`new Printable[Box]` etc...),
create your instance from an
existing instance using `contramap`:

<div class="solution">
To make the instance generic across all types of `Box`,
we base it on the `Printable` for the type inside the `Box`.
We can either write out the complete definition by hand:

```tut:book:silent
implicit def boxPrintable[A](implicit p: Printable[A]) =
  new Printable[Box[A]] {
    def format(box: Box[A]): String =
      p.format(box.value)
  }
```

or use `contramap` to base the new instance
on the implicit parameter:

```tut:book:silent
implicit def boxPrintable[A](implicit p: Printable[A]) =
  p.contramap[Box[A]](_.value)
```

Using `contramap` is much simpler,
and conveys the functional programming approach
of building solutions by combining simple building blocks
using pure functional combinators.
</div>

Your instance should work as follows:

```tut:book
format(Box("hello world"))
format(Box(true))
```

If we don't have a `Printable` for the type inside the `Box`,
calls to `format` should fail to compile:

```tut:book:fail
format(Box(123))
```

### Invariant functors and the *imap* method {#invariant}

The second of our type classes, the *invariant functor*,
provides a method called `imap` that is informally equivalent to
a combination of `map` and `contramap`.
We can demonstrate this by extending `Printable`
to support encoding and decoding to/from a `String`:

```tut:book:silent
trait Codec[A] {
  def encode(value: A): String

  def decode(value: String): A

  def imap[B](dec: A => B, enc: B => A): Codec[B] =
    ???
}
```

```tut:book:invisible
trait Codec[A] {
  self =>

  def encode(value: A): String

  def decode(value: String): A

  def imap[B](dec: A => B, enc: B => A): Codec[B] =
    new Codec[B] {
      def encode(value: B): String =
        self.encode(enc(value))

      def decode(value: String): B =
        dec(self.decode(value))
    }
}
```

```tut:book:silent
def encode[A](value: A)(implicit c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(implicit c: Codec[A]): A =
  c.decode(value)
```

The type chart for `imap` is shown in
Figure [@fig:functors:imap-type-chart].

![Type chart: the imap method](src/pages/functors/generic-imap.pdf+svg){#fig:functors:imap-type-chart}

As an example use case, imagine we have a basic `Codec[String]`,
whose `encode` and `decode` methods are both a no-op:

```tut:book:silent
implicit val stringCodec: Codec[String] =
  new Codec[String] {
    def encode(value: String): String = value
    def decode(value: String): String = value
  }
```

We can construct many useful `Codecs` for other types
by building off of `stringCodec` using `imap`:

```tut:book:silent
implicit val intCodec: Codec[Int] =
  stringCodec.imap(_.toInt, _.toString)

implicit val booleanCodec: Codec[Boolean] =
  stringCodec.imap(_.toBoolean, _.toString)
```

Note that the `decode` method of our `Codec` type class
doesn't account for failures.
If we want to model more sophisticated relationships,
we need to move beyond functors and look at
*lenses* and *optics*, which are beyond the scope of this book.
See Julien Truffaut's excellent library
[Monocle][link-monocle] for an implementation
of many useful kinds of optics.

#### Transformative Thinking with Imap

Implement the `imap` method for `Codec` above.

<div class="solution">
Here's a working implementation:

```tut:book:silent:reset
trait Codec[A] {
  def encode(value: A): String
  def decode(value: String): A

  def imap[B](dec: A => B, enc: B => A): Codec[B] = {
    val self = this
    new Codec[B] {
      def encode(value: B): String =
        self.encode(enc(value))

      def decode(value: String): B =
        dec(self.decode(value))
    }
  }
}
```

```tut:book:invisible
implicit val stringCodec: Codec[String] =
  new Codec[String] {
    def encode(value: String): String = value
    def decode(value: String): String = value
  }

implicit val intCodec: Codec[Int] =
  stringCodec.imap[Int](_.toInt, _.toString)

implicit val booleanCodec: Codec[Boolean] =
  stringCodec.imap[Boolean](_.toBoolean, _.toString)

def encode[A](value: A)(implicit c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(implicit c: Codec[A]): A =
  c.decode(value)
```
</div>

Demonstrate your `imap` method works by creating a
`Codec` for conversions between `Strings` and `Boxes`:

```tut:book:silent
case class Box[A](value: A)
```

<div class="solution">
```tut:book:silent
implicit def boxCodec[A](implicit c: Codec[A]): Codec[Box[A]] =
  c.imap[Box[A]](Box(_), _.value)
```
</div>

Your instance should work as follows:

```tut:book
encode(Box(123))
decode[Box[Int]]("123")
```

<div class="callout callout-info">
*What's with the names?*

What's the relationship between the terms
"contravariance", "invariance", and "covariance"
and these different kinds of functor?

If you recall from Section [@sec:variance],
variance affects to subtyping,
which essentially controls
our ability to use a value of one type
in place of a value of another type
without breaking the code.

Subtyping can be viewed as conversion.
`A` is a subtype of `B` if we can always convert `A` to `B`.
Equivalently we could say that `A` is a subtype of `B`
if there exists a function `A => B`.
A standard covariant functor captures exactly this.
If `F` is a covariant functor,
wherever we have an `F[A]` and a conversion `A => B`
we can always convert to an `F[B]`.

A contravariant functor captures the opposite case.
If `F` is a contravariant functor,
whenever we have a `F[A]` and a conversion `B => A`
we can convert to an `F[B]`.

Finally, invariant functors capture the case where
we can convert from `F[A]` to `F[B]`
via a function `A => B`
and vice versa via a function `B => A`.
</div>
