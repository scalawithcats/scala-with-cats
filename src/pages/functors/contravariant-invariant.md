## *Contravariant* and *Invariant* Functors {#contravariant-invariant}

By now we are used to thinking of `map` as
"appending" a transformation to a chain.
We start with an `F[A]`,
run it through a function `A => B`,
and end up with an `F[B]`.
We can extend the chain further by mapping again:
run the `F[B]` through a function `B => C`
and end up with an `F[C]`.

We're now going to look at two other type classes,
one that represents *prepending* operations to a chain,
and one that represents building a *bidirectional*
chain of operations.

The main use case for these new type classes is
building libraries that transform, read, and write values.
The content ties in tightly to the [JSON codec](#json-codec)
case study later in the book.

### Contravariant functors and the *contramap* method {#contravariant}

The first of our type classes, the *contravariant functor*,
provides an operation called `contramap`
that represents "prepending" a transformation to a chain:

<div class="callout callout-danger">
  TODO: Diagram of contravariant functor contramap
</div>

We'll talk about `contramap` itself directly for now,
bringing the type class in later when we talk about Cats.

The `contramap` method only makes sense for certain data types.
For example, we can't define `contramap` for an `Option`
because there is no way of feeding a value in an
`Option[B]` backwards through a function `A => B`.

`contramap` starts to make sense when we have a data types
that represent tranformations.
For example, consider a simple data type `JsonEncoder[A]`:

```tut:book:silent
sealed trait Json
final case class JsObject(get: Map[String, Json]) extends Json
final case class JsString(get: String) extends Json
final case class JsNumber(get: Double) extends Json

trait JsonEncoder[A] {
  def encode(value: A): Json
}
```

A `JsonEncoder[A]` represents a transformation from `A` to `Json`.

We can define a `contramap` method for `JsonEncoder` that
"prepends" the encoder with a function,
transforming the input to a value that it can encode:

```tut:book:silent
trait JsonEncoder[A] {
  def encode(value: A): Json

  def contramap[B](func: B => A): JsonEncoder[B] =
    ???
}
```

<div class="callout callout-danger">
  TODO: Mention why it's called "contravariant"
</div>

#### Exercise: Writing JSON

Implement the `contramap` method for `JsonEncoder` above.
Get your code to compile. Don't worry about running it yet.

<div class="solution">
Here's a working implementation:

```scala
trait JsonEncoder[A] {
  def encode(value: A): Json

  def contramap[B](func: B => A): JsonEncoder[B] = {
    val self = this
    new JsonEncoder[B] {
      def encode(value: B): Json =
        self.encode(func(value))
    }
  }
}
```

We can't actually run this code without a lot of infrastructure.
We'd have to fully define the `Json` data type and add a host of writers.
There's no need to do this now---check
the [JSON codec](#json-codec) case study for a full treatment.
</div>

### Invariant functors and the *imap* method {#invariant}

The second of our type classes, the *invariant functor*,
provides a method called `imap` that is informally equivalent to
a combination of `map` and `contramap`.

`imap` is even more specialised than `contramap`.
It only makes sense for data types that represent
bidirectional transformations between two data types.
We can demonstrate this by extending our `JsonEncoder` example
to create a bidirectional `JsonCodec`:

```tut:book:silent
trait JsonCodec[A] {
  def encode(value: A): Json
  def decode(value: Json): A

  def imap[B](prependFunc: B => A, appendFunc: A => B): JsonCodec[B] =
    ???
}
```

As the types tell us, `imap` lets us build a `JsonCodec[B]` from a `JsonCodec[A]`
if we have functions to tranform `A` to `B` and `B` to `A`.

<div class="callout callout-danger">
  TODO: Mention why it's called "invariant"
</div>

#### Exercise: Reading and Writing JSON

Implement the `imap` method for `JsonEncoder` above.
Get your code to compile. Don't worry about running it yet.

<div class="solution">
Here's a working implementation:

```scala
trait JsonCodec[A] {
  def encode(value: A): Json
  def decode(value: Json): A

  def imap[B](prependFunc: B => A, appendFunc: A => B): JsonCodec[B] = {
    val self = this
    new JsonCodec[B] {
      def encode(value: B): Json = self.encode(func(value))
      def decode(value: B): Json = func(self.decode(value))
    }
  }
}
```

Note that this simple example doesn't take into account
that decoding is fallible.
For a full treatment see the [JSON Codec](#json-codec) case study.
</div>
