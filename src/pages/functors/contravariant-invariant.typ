#import "../stdlib.typ": info, warning, solution
== Contravariant and Invariant Functors 
<sec:functors:contravariant-invariant>


As we have seen, we can think of `Functor's` `map` method as
"appending" a transformation to a chain.
We're now going to look at two other type classes,
one representing _prepending_ operations to a chain,
and one representing building a _bidirectional_
chain of operations. These are called _contravariant_
and _invariant functors_ respectively.

#info[
*This Section is Optional!*

You don't need to know about contravariant and invariant functors to understand monads,
which are the most important type class in this book and the focus of the next chapter.
However, contravariant and invariant do come in handy in
our discussion of `Semigroupal` and `Applicative` in @sec:applicatives.

If you want to move on to monads now,
feel free to skip straight to @sec:monads.
Come back here before you read @sec:applicatives.
]

=== Contravariant Functors and the *contramap* Method 
<sec:functors:contravariant>


The first of our type classes, the _contravariant functor_,
provides an operation called `contramap`
that represents "prepending" an operation to a chain.
The general type signature is shown in @fig:functors:contramap-type-chart.

#figure(image("generic-contramap.svg"), caption: [Type chart: the contramap method])
<fig:functors:contramap-type-chart>

The `contramap` method only makes sense for data types that represent _transformations_.
For example, we can't define `contramap` for an `Option`
because there is no way of feeding a value in an
`Option[B]` backwards through a function `A => B`.
However, we can define `contramap` for the `Display` type class
we discussed in @sec:type-classes:display:

```scala mdoc:silent
trait Display[A] {
  def display(value: A): String
}
```

A `Display[A]` represents a transformation from `A` to `String`.
Its `contramap` method accepts a function `func` of type `B => A`
and creates a new `Display[B]`:

```scala mdoc:silent:reset-object
trait Display[A] {
  def display(value: A): String

  def contramap[B](func: B => A): Display[B] =
    ???
}

def display[A](value: A)(using p: Display[A]): String =
  p.display(value)
```

==== Exercise: Showing off with Contramap


Implement the `contramap` method for `Display` above.
Start with the following code template
and replace the `???` with a working method body:

```scala
trait Display[A] {
  def display(value: A): String

  def contramap[B](func: B => A): Display[B] =
    new Display[B] {
      def display(value: B): String =
        ???
    }
}
```

If you get stuck, think about the types.
You need to turn `value`, which is of type `B`, into a `String`.
What functions and methods do you have available
and in what order do they need to be combined?

#solution[
Here's a working implementation.
We call `func` to turn the `B` into an `A`
and then use our original `Display`
to turn the `A` into a `String`.
In a small show of sleight of hand
we use a `self` alias to distinguish
the outer and inner `Displays`:

```scala mdoc:silent:reset-object
trait Display[A] { self =>

  def display(value: A): String

  def contramap[B](func: B => A): Display[B] =
    new Display[B] {
      def display(value: B): String =
        self.display(func(value))
    }
}

def display[A](value: A)(using p: Display[A]): String =
  p.display(value)
```
]

For testing purposes,
let's define some instances of `Display`
for `String` and `Boolean`:

```scala mdoc:silent
given stringDisplay: Display[String] with {
  def display(value: String): String =
    s"'${value}'"
}

given booleanDisplay: Display[Boolean] with {
  def display(value: Boolean): String =
    if value then "yes" else "no"
}
```

```scala mdoc
display("hello")
display(true)
```

Now define an instance of `Display` for
the following `Box` case class.
This is an example of type class composotion
as described in @sec:type-classes:composition:

```scala mdoc:silent
final case class Box[A](value: A)
```

Rather than writing out
the complete definition from scratch
(`new Display[Box]` etc...),
create your instance from an
existing instance using `contramap`.

```scala mdoc:invisible
given boxDisplay[A](using p: Display[A]): Display[Box[A]] =
  p.contramap[Box[A]](_.value)
```

Your instance should work as follows:

```scala mdoc
display(Box("hello world"))
display(Box(true))
```

If we don't have a `Display` for the type inside the `Box`,
calls to `display` should fail to compile:

```scala mdoc:fail
display(Box(123))
```

#solution[
To make the instance generic across all types of `Box`,
we base it on the `Display` for the type inside the `Box`.
We can either write out the complete definition by hand:

```scala mdoc:invisible:reset-object
trait Display[A] {
  self =>

  def display(value: A): String

  def contramap[B](func: B => A): Display[B] =
    new Display[B] {
      def display(value: B): String =
        self.display(func(value))
    }
}
final case class Box[A](value: A)
```
```scala mdoc:silent
given boxDisplay[A](
    using p: Display[A]
): Display[Box[A]] with {
  def display(box: Box[A]): String =
    p.display(box.value)
}
```

or use `contramap` to base the new instance
on the using clause:

```scala mdoc:invisible:reset-object
trait Display[A] {
  self =>

  def display(value: A): String

  def contramap[B](func: B => A): Display[B] =
    new Display[B] {
      def display(value: B): String =
        self.display(func(value))
    }
}

def display[A](value: A)(implicit p: Display[A]): String =
  p.display(value)

given stringDisplay: Display[String] =
  new Display[String] {
    def display(value: String): String =
      s"'${value}'"
  }

given booleanDisplay: Display[Boolean] =
  new Display[Boolean] {
    def display(value: Boolean): String =
      if(value) "yes" else "no"
  }
final case class Box[A](value: A)
```
```scala mdoc:silent
given boxDisplay[A](using p: Display[A]): Display[Box[A]] =
  p.contramap[Box[A]](_.value)
```

Using `contramap` is much simpler,
and conveys the functional programming approach
of building solutions by combining simple building blocks
using pure functional combinators.
]


=== Invariant functors and the *imap* method 
<sec:functors:invariant>


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
such as Circe's [`Codec`][link-circe-codec]
and Play JSON's [`Format`][link-play-json-format].
We can build our own `Codec` by enhancing `Display`
to support encoding and decoding to/from a `String`:

```scala mdoc:silent
trait Codec[A] {
  def encode(value: A): String
  def decode(value: String): A
  def imap[B](dec: A => B, enc: B => A): Codec[B] = ???
}
```

```scala mdoc:invisible:reset-object
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

```scala mdoc:silent
def encode[A](value: A)(using c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(using c: Codec[A]): A =
  c.decode(value)
```

The type chart for `imap` is shown in
@fig:functors:imap-type-chart.
If we have a `Codec[A]`
and a pair of functions `A => B` and `B => A`,
the `imap` method creates a `Codec[B]`:

#figure(image("generic-imap.svg"), caption: [Type chart: the imap method])
<fig:functors:imap-type-chart>

As an example use case, imagine we have a basic `Codec[String]`,
whose `encode` and `decode` methods both 
simply return the value they are passed:

```scala mdoc:silent
given stringCodec: Codec[String] with {
  def encode(value: String): String = value
  def decode(value: String): String = value
}
```

We can construct many useful `Codecs` for other types
by building off of `stringCodec` using `imap`:

```scala mdoc:silent
given intCodec: Codec[Int] =
  stringCodec.imap(_.toInt, _.toString)

given booleanCodec: Codec[Boolean] =
  stringCodec.imap(_.toBoolean, _.toString)
```

#info[
*Coping with Failure*

Note that the `decode` method of our `Codec` type class
doesn't account for failures.
If we want to model more sophisticated relationships
we can move beyond functors
to look at _lenses_ and _optics_.

Optics are beyond the scope of this book.
However, Julien Truffaut's library
[Monocle][link-monocle] provides a great
starting point for further investigation.
]


==== Transformative Thinking with *imap*


Implement the `imap` method for `Codec` above.

#solution[
Here's a working implementation:

```scala mdoc:silent:reset-object
trait Codec[A] { self =>
  def encode(value: A): String
  def decode(value: String): A

  def imap[B](dec: A => B, enc: B => A): Codec[B] = {
    new Codec[B] {
      def encode(value: B): String =
        self.encode(enc(value))

      def decode(value: String): B =
        dec(self.decode(value))
    }
  }
}
```

```scala mdoc:invisible
given stringCodec: Codec[String] =
  new Codec[String] {
    def encode(value: String): String = value
    def decode(value: String): String = value
  }

given intCodec: Codec[Int] =
  stringCodec.imap[Int](_.toInt, _.toString)

given booleanCodec: Codec[Boolean] =
  stringCodec.imap[Boolean](_.toBoolean, _.toString)

def encode[A](value: A)(using c: Codec[A]): String =
  c.encode(value)

def decode[A](value: String)(using c: Codec[A]): A =
  c.decode(value)
```
]

Demonstrate your `imap` method works by
creating a `Codec` for `Double`.

#solution[
We can implement this using
the `imap` method of `stringCodec`:

```scala mdoc:silent
given doubleCodec: Codec[Double] =
  stringCodec.imap[Double](_.toDouble, _.toString)
```
]

Finally, implement a `Codec` for the following `Box` type:

```scala mdoc:silent
final case class Box[A](value: A)
```

#solution[
We need a generic `Codec` for `Box[A]` for any given `A`.
We create this by calling `imap` on a `Codec[A]`,
which we bring into scope using an implicit parameter:

```scala mdoc:silent
given boxCodec[A](using c: Codec[A]): Codec[Box[A]] =
  c.imap[Box[A]](Box(_), _.value)
```
]

Your instances should work as follows:

```scala mdoc
encode(123.4)
decode[Double]("123.4")

encode(Box(123.4))
decode[Box[Double]]("123.4")
```

#warning[
*What's With the Names?*

What's the relationship between the terms
"contravariance", "invariance", and "covariance"
and these different kinds of functor?

If you recall from @sec:variance,
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
]
