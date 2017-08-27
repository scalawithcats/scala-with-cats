## *Contravariant* and *Invariant* Functors {#contravariant-invariant}

We can think of `Functor's` `map` method as
"appending" a transformation to a chain.
We start with an `F[A]`,
run it through a function `A => B`,
and end up with an `F[B]`.
We can extend the chain further by mapping again:
run the `F[B]` through a function `B => C`
and end up with an `F[C]`:

```tut:book
Option(1).map(_ + 2).map(_ * 3).map(_ + 100)
```

We're now going to look at two other type classes,
one that represents *prepending* operations to a chain,
and one that represents building a *bidirectional*
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

`contramap` starts to make sense when we have a data types
that represent tranformations.
For example, consider the `Printable` type class
we discussed in [Chapter 2](#type-classes):

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
Here's a working implementation:

```tut:book:silent
trait Printable[A] {
  def format(value: A): String

  def contramap[B](func: B => A): Printable[B] = {
    val self = this
    new Printable[B] {
      def format(value: B): String =
        self.format(func(value))
    }
  }
}

def format[A](value: A)(implicit p: Printable[A]): String =
  p.format(value)
```
</div>

Let's define some basic instances of `Printable`
for `String` and `Boolean`:

```tut:book:silent
implicit val stringPrintable =
  new Printable[String] {
    def format(value: String): String =
      "\"" + value + "\""
  }

implicit val booleanPrintable =
  new Printable[Boolean] {
    def format(value: Boolean): String =
      if(value) "yes" else "no"
  }
```

```tut:book
format("hello")
format(true)
```

Define an instance of `Printable` that prints
the value from this case class:

```tut:book:silent
final case class Box[A](value: A)
```

Rather than writing out
the complete definition from scratch
(`new Printable[Box]` etc...),
create your instance using
the `contramap` method of one of the instances above.

<div class="solution">
To make the instance generic across all types of `Box`,
we base it on the `Printable` for the type inside the `Box`:

```tut:book:silent
implicit def boxPrintable[A](implicit p: Printable[A]) =
  p.contramap[Box[A]](_.value)
```
</div>

Your instance should work as follows:

```tut:book
format(Box("hello world"))
format(Box(true))
```

If we don't have a `Printable` for the contents of the `Box`,
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

  def decode(value: String): Option[A]

  def imap[B](dec: A => B, enc: B => A): Codec[B] =
    ???
}

def encode[A](value: A)(implicit c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(implicit c: Codec[A]): Option[A] =
  c.decode(value)
```

The type chart for `imap` is shown in
Figure [@fig:functors:imap-type-chart].

![Type chart: the imap method](src/pages/functors/generic-imap.pdf+svg){#fig:functors:imap-type-chart}

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

```tut:book:silent
trait Codec[A] {
  def encode(value: A): String
  def decode(value: String): Option[A]

  def imap[B](dec: A => B, enc: B => A): Codec[B] = {
    val self = this
    new Codec[B] {
      def encode(value: B): String =
        self.encode(enc(value))

      def decode(value: String): Option[B] =
        self.decode(value).map(dec)
    }
  }
}

def encode[A](value: A)(implicit c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(implicit c: Codec[A]): Option[A] =
  c.decode(value)
```
</div>

Here's an example `Codec` representing parsing and serializing `Ints`:

<div class="solution">
```tut:book:silent
implicit val intCodec =
  new Codec[Int] {
    def encode(value: Int): String =
      value.toString

    def decode(value: String): Option[Int] =
      scala.util.Try(value.toInt).toOption
  }
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

### What's With the Name?

What's the relationship between the terms
"contravariance", "invariance", and "covariance"
and these different finds of functors?

These three variance terms relate to subtypes.
We say that `B` is a subtype of `A`
if we can use a value of type `B`
anywhere we expect a value of type `A`.

Co- and contravariance annotations arise
when working with type constructors.
For example, we denote covariance with a `+` symbol:

```scala
trait F[+A] // the "+" means "covariant"
```

**Covariance**

Covariance means that the type `F[B]`
is a subtype of the type `F[A]` if `B` is a subtype of `A`.
This is useful for modelling many types,
including collections like `List` and `Option`:

```scala
trait List[+A]
trait Option[+A]
```

The covariance of Scala collections allows
us to substitute collections of one type for another in our code.
For example, we can use a `List[Circle]`
anywhere we expect a `List[Shape]` because
`Circle` is a subtype of `Shape`:

```tut:book:silent
sealed trait Shape
case class Circle(radius: Double) extends Shape
```

```scala
val circles: List[Circle] = ???
val shapes: List[Shape] = circles
```

```tut:book:invisible
val circles: List[Circle] = null
val shapes: List[Shape] = circles
```

What about contravariance?
We write contravariant type constructors
with a `-` symbol like this:

```scala
trait F[-A]
```

**Contravariance**

Confusingly, contravariance means that the type `F[B]`
is a subtype of `F[A]` if `A` is a subtype of `B`.
This is useful for modelling types that represent processes,
like our `Printable` type class above:

```scala
trait Printable[-A] {
  def format(value: A): String
}
```

Let's unpack this a bit further.
Remember that variance is all about
the ability to substitute one value for another.
Consider a scenario where we have two values,
one of type `Shape` and one of type `Circle`,
and two `Printables`, one for `Shape` and one for `Circle`:

```scala
val shape: Shape = ???
val circle: Circle = ???

val shapePrinter: Printable[Shape] = ???
val circlePrinter: Printable[Circle] = ???
```

```tut:book:invisible
val shape: Shape = null
val circle: Circle = null

val shapePrinter: Printable[Shape] = null
val circlePrinter: Printable[Circle] = null
```

```tut:book
def format[A](value: A, printable: Printable[A]): String =
  printable.format(value)
```

Now ask yourself the question:
"Which of combinations of value and printer can I pass to `format`?"
We can combine `circle` with either printer
because all `Circles` are `Shapes`.
Conversely, we can't combine `shape` with `circlePrinter`
because not all `Shapes` are `Circles`.

This relationship is what we formally model using contravariance.
`Printable[Shape]` is a subtype of `Printable[Circle]`
because `Circle` is a subtype of `Shape`.
This means we can use `shapePrinter`
anywhere we expect to see a `Printable[Circle]`.

**Invariance**

Invariance is actually the easiest situation to describe.
It's what we get when we don't write a `+` or `-`
in a type constructor:

```scala
trait F[A]
```

This means the types `F[A]` and `F[B]` are never subtypes of one another,
no matter what the relationship between `A` and `B`.
This is the default semantics for Scala type constructors.

**Back to Functors**

Co- and contravariant functors capture the
principles of co- and contravariance
without the limitations of subtyping.

As we said above, subtyping can be viewed as a conversion.
`B` is a subtype of `A` if we can convert `A` to `B`.
In other words there exists a function `A => B`.
A standard covariant functor captures exactly this.
If `F` is a covariant functor,
wherever we have an `F[A]` and a conversion `A => B`
we can convert to an `F[B]`.

A contravariant functor captures the opposite case.
If `F` is a contravariant functor,
whenever we have a `F[A]` and a conversion `B => A`
we can convert to an `F[B]`.

Finally, invariant functors capture the case where
we can convert from `F[A]` to `F[B]`
via a function `A => B` or `B => A`.
