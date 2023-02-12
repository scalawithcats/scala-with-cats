## Contravariant and Invariant Functors {#sec:functors:contravariant-invariant}

As we have seen, we can think of `Functor's` `map` method as
"appending" a transformation to a chain.
We're now going to look at two other type classes,
one representing *prepending* operations to a chain,
and one representing building a *bidirectional*
chain of operations. These are called *contravariant*
and *invariant functors* respectively.

<div class="callout callout-info">
*This Section is Optional!*

You don't need to know about contravariant and invariant functors to understand monads,
which are the most important pattern in this book and the focus of the next chapter.
However, contravariant and invariant do come in handy in
our discussion of `Semigroupal` and `Applicative` in Chapter [@sec:applicatives].

If you want to move on to monads now,
feel free to skip straight to Chapter [@sec:monads].
Come back here before you read Chapter [@sec:applicatives].
</div>

### Contravariant Functors and the *contramap* Method {#sec:functors:contravariant}

The first of our type classes, the *contravariant functor*,
provides an operation called `contramap`
that represents "prepending" an operation to a chain.
The general type signature is shown in Figure [@fig:functors:contramap-type-chart].

![Type chart: the contramap method](src/pages/functors/generic-contramap.pdf+svg){#fig:functors:contramap-type-chart}

The `contramap` method only makes sense for data types that represent *transformations*.
For example, we can't define `contramap` for an `Option`
because there is no way of feeding a value in an
`Option[B]` backwards through a function `A => B`.
However, we can define `contramap` for the `Printable` type class
we discussed in Chapter [@sec:type-classes]:

```scala mdoc:silent
trait Printable[A]:
  def format(value: A): String
```

A `Printable[A]` represents a transformation from `A` to `String`.
Its `contramap` method accepts a function `func` of type `B => A`
and creates a new `Printable[B]`:

```scala mdoc:silent:reset-object
trait Printable[A]:
  def format(value: A): String

  def contramap[B](func: B => A): Printable[B] =
    ???

def format[A](value: A)(using p: Printable[A]): String =
  p.format(value)
```

#### Exercise: Showing off with Contramap

Implement the `contramap` method for `Printable` above.
Start with the following code template
and replace the `???` with a working method body:

```scala
trait Printable[A]:
  def format(value: A): String

  def contramap[B](func: B => A): Printable[B] =
    new Printable[B]:
      def format(value: B): String =
        ???
```

If you get stuck, think about the types.
You need to turn `value`, which is of type `B`, into a `String`.
What functions and methods do you have available
and in what order do they need to be combined?

<div class="solution">
Here's a working implementation.
We call `func` to turn the `B` into an `A`
and then use our original `Printable`
to turn the `A` into a `String`.
In a small show of sleight of hand
we use a `self` alias to distinguish
the outer and inner `Printables`:

```scala mdoc:silent:reset-object
trait Printable[A]:
  self =>
    def format(value: A): String

    def contramap[B](func: B => A): Printable[B] =
      new Printable[B]:
        def format(value: B): String =
          self.format(func(value))

def format[A](value: A)(using p: Printable[A]): String =
  p.format(value)
```
</div>

For testing purposes,
let's define some instances of `Printable`
for `String` and `Boolean`:

```scala mdoc:silent
given stringPrintable: Printable[String] with
  def format(value: String): String =
    s"'${value}'"

given booleanPrintable: Printable[Boolean] with
  def format(value: Boolean): String =
    if(value) "yes" else "no"
```

```scala mdoc
format("hello")
format(true)
```

Now define an instance of `Printable` for
the following `Box` case class.
You'll need to write this as a `given` instance
as described in Section [@sec:type-classes:recursive-implicits]:

```scala mdoc:silent
final case class Box[A](value: A)
```

Rather than writing out
the complete definition from scratch
(`new Printable[Box]` etc...),
create your instance from an
existing instance using `contramap`.

```scala mdoc:invisible
given boxPrintable[A](using p: Printable[A]): Printable[Box[A]] =
  p.contramap[Box[A]](_.value)
```

Your instance should work as follows:

```scala mdoc
format(Box("hello world"))
format(Box(true))
```

If we don't have a `Printable` for the type inside the `Box`,
calls to `format` should fail to compile:

```scala mdoc:fail
format(Box(123))
```

<div class="solution">
To make the instance generic across all types of `Box`,
we base it on the `Printable` for the type inside the `Box`.
We can either write out the complete definition by hand:

```scala mdoc:invisible:reset-object
trait Printable[A]:
  self =>
    def format(value: A): String

    def contramap[B](func: B => A): Printable[B] =
      (value: B) => self.format(func(value))

final case class Box[A](value: A)
```
```scala mdoc:silent
given boxPrintable[A](using p: Printable[A]): Printable[Box[A]] with
  def format(box: Box[A]): String =
    p.format(box.value)
```

or use `contramap` to base the new instance
on the implicit parameter:

```scala mdoc:invisible:reset-object
trait Printable[A]:
  self =>
    def format(value: A): String

    def contramap[B](func: B => A): Printable[B] =
      new Printable[B]:
        def format(value: B): String =
          self.format(func(value))

def format[A](value: A)(using p: Printable[A]): String =
  p.format(value)

given stringPrintable: Printable[String] with
  def format(value: String): String =
    s"'${value}'"

given booleanPrintable: Printable[Boolean] with
  def format(value: Boolean): String =
    if(value) "yes" else "no"

final case class Box[A](value: A)
```
```scala mdoc:silent
given boxPrintable[A](using p: Printable[A]): Printable[Box[A]] =
  p.contramap[Box[A]](_.value)
```

Using `contramap` is much simpler,
and conveys the functional programming approach
of building solutions by combining simple building blocks
using pure functional combinators.
</div>

### Invariant functors and the *imap* method {#sec:functors:invariant}

*Invariant functors* implement a method called `imap`
that is informally equivalent to a
combination of `map` and `contramap`.
If `map` generates new type class instances by
appending a function to a chain,
and `contramap` generates them by
prepending an operation to a chain,
`imap` generates them via
a pair of bidirectional transformations.

The most intuitive examples of this are a type class
that represents encoding and decoding as some data type,
such as Play JSON's [`Format`][link-play-json-format]
and scodec's [`Codec`][link-scodec-codec].
We can build our own `Codec` by enhancing `Printable`
to support encoding and decoding to/from a `String`:

```scala mdoc:silent
trait Codec[A]:
  def encode(value: A): String
  def decode(value: String): A
  def imap[B](dec: A => B, enc: B => A): Codec[B] = ???
```

```scala mdoc:invisible:reset-object
trait Codec[A]:
  self =>
    def encode(value: A): String
    def decode(value: String): A

    def imap[B](dec: A => B, enc: B => A): Codec[B] =
      new Codec[B]:
        def encode(value: B): String =
          self.encode(enc(value))

        def decode(value: String): B =
          dec(self.decode(value))
```

```scala mdoc:silent
def encode[A](value: A)(using c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(using c: Codec[A]): A =
  c.decode(value)
```

The type chart for `imap` is shown in
Figure [@fig:functors:imap-type-chart].
If we have a `Codec[A]`
and a pair of functions `A => B` and `B => A`,
the `imap` method creates a `Codec[B]`:

![Type chart: the imap method](src/pages/functors/generic-imap.pdf+svg){#fig:functors:imap-type-chart}

As an example use case, imagine we have a basic `Codec[String]`,
whose `encode` and `decode` methods both 
simply return the value they are passed:

```scala mdoc:silent
given stringCodec: Codec[String] with
  def encode(value: String): String = value
  def decode(value: String): String = value
```

We can construct many useful `Codecs` for other types
by building off of `stringCodec` using `imap`:

```scala mdoc:silent
given intCodec: Codec[Int] =
  stringCodec.imap(_.toInt, _.toString)

given booleanCodec: Codec[Boolean] =
  stringCodec.imap(_.toBoolean, _.toString)
```

<div class="callout callout-info">
*Coping with Failure*

Note that the `decode` method of our `Codec` type class
doesn't account for failures.
If we want to model more sophisticated relationships
we can move beyond functors
to look at *lenses* and *optics*.

Optics are beyond the scope of this book.
However, Julien Truffaut's library
[Monocle][link-monocle] provides a great
starting point for further investigation.
</div>

#### Transformative Thinking with *imap*

Implement the `imap` method for `Codec` above.

<div class="solution">
Here's a working implementation:

```scala mdoc:silent:reset-object
trait Codec[A]:
  self =>
    def encode(value: A): String
    def decode(value: String): A

    def imap[B](dec: A => B, enc: B => A): Codec[B] =
      new Codec[B]:
        def encode(value: B): String =
          self.encode(enc(value))

        def decode(value: String): B =
          dec(self.decode(value))
```

```scala mdoc:invisible
given stringCodec: Codec[String] with
  def encode(value: String): String = value
  def decode(value: String): String = value

given intCodec: Codec[Int] =
  stringCodec.imap[Int](_.toInt, _.toString)

given booleanCodec: Codec[Boolean] =
  stringCodec.imap[Boolean](_.toBoolean, _.toString)

def encode[A](value: A)(using c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(using c: Codec[A]): A =
  c.decode(value)
```
</div>

Demonstrate your `imap` method works by
creating a `Codec` for `Double`.

<div class="solution">
We can implement this using
the `imap` method of `stringCodec`:

```scala mdoc:silent
given doubleCodec: Codec[Double] =
  stringCodec.imap[Double](_.toDouble, _.toString)
```
</div>

Finally, implement a `Codec` for the following `Box` type:

```scala mdoc:silent
final case class Box[A](value: A)
```

<div class="solution">
We need a generic `Codec` for `Box[A]` for any given `A`.
We create this by calling `imap` on a `Codec[A]`,
which we bring into scope using an implicit parameter:

```scala mdoc:silent
given boxCodec[A](using c: Codec[A]): Codec[Box[A]] =
  c.imap[Box[A]](Box(_), _.value)
```
</div>

Your instances should work as follows:

```scala mdoc
encode(123.4)
decode[Double]("123.4")

encode(Box(123.4))
decode[Box[Double]]("123.4")
```

<div class="callout callout-warning">
*What's With the Names?*

What's the relationship between the terms
"contravariance", "invariance", and "covariance"
and these different kinds of functor?

If you recall from Section [@sec:variance],
variance affects subtyping,
which is essentially our ability to use a value of one type
in place of a value of another type
without breaking the code.

Subtyping can be viewed as a conversion.
If `B` is a subtype of `A`,
we can always convert a `B` to an `A`.

Equivalently we could say that `B` is a subtype of `A`
if there exists a function `B => A`.
A standard covariant functor captures exactly this.
If `F` is a covariant functor,
wherever we have an `F[B]` and a conversion `B => A`
we can always convert to an `F[A]`.

A contravariant functor captures the opposite case.
If `F` is a contravariant functor,
whenever we have a `F[A]` and a conversion `B => A`
we can convert to an `F[B]`.

Finally, invariant functors capture the case where
we can convert from `F[A]` to `F[B]`
via a function `A => B`
and vice versa via a function `B => A`.
</div>
