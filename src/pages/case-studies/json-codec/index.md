# Case Study: Json Codec {#json-codec}

Scala famously has a thousand JSON libraries,
and we're going to create one more using our Cats toolkit.
In this case study we will create a simple way to
read and write JSON data and map it to useful Scala types.

Many functional JSON libraries manage mappings between
three different levels of representation:

1. Raw JSON---text written using the syntax
defined in the [JSON specification][link-json].

2. A "JSON DOM"---an algebraic data type
representing the JSON primitives in the raw JSON
(objects, arrays, strings, nulls, and so on).

3. Semantic data types---the types we care about
in our applications.

The "JSON DOM" is a useful abstraction.
If we can parse raw JSON to a DOM,
we know we have a syntactically valid file.
We can traverse and manipulate instances of an ADT
much more easily than we can raw string data,
making it easier to tackle the problem of mapping
on to semantic types.

## Creating a *JsonValue* ADT

Let's start by designing an algebraic data type for our JSON DOM.
The [JSON spec][link-json] describes a "JSON value"
as being one of the following data types:

- a string
- a number
- a boolean
- a null
- an object
- an array

Create a type `JsonValue` to represent this type hierarchy.

<div class="solution">
Here's a suitable ADT, created using sealed traits and case classes:

```tut:book
sealed trait JsonValue
final case class JsonString(value: String) extends JsonValue
final case class JsonNumber(value: Double) extends JsonValue
final case class JsonBoolean(value: Boolean) extends JsonValue
case object JsonNull extends JsonValue
final case class JsonObject(fields: List[(String, JsonValue)]) extends JsonValue
final case class JsonArray(values: List[JsonValue]) extends JsonValue
```

There are a couple of notable design decisions here:

1. We can't simply use raw Scala types like `String` and `Boolean`
   to represent JSON strings and booleans because
   there's no way of saying "`String extends JsonValue`".
   Instead we wrap each of the primitive types in a case class
   to adapt it to our JSON algebra.

2. JSON supports `nulls` but we want to avoid them in our Scala code.
   We use a singleton value to represent `JsonNull`,
   which is consistent with the way `None` is modelled in `Option`
   and `Nil` is modelled in `List.

3. We've modelled the compound JSON types, `JsonObject` and `JsonArray`,
   using `Lists` to store their constituent parts.
   There is a valid argument for using a `Map` inside `JsonObject`
   to enforce key uniqueness.
   However, a `List` of tuples suits this example just fine,
   and allows us to model the order of keys.
</div>

```scala
sealed trait JsonValue
final case class String(...) extends JsonValue
final case class Boolean(...) extends JsonValue
// ...
```

## Converting Between *JsonValues* and Raw JSON

The first building block we would need
if we were writing a real JSON library,
is a pair of methods
converting between `JsonValues` and raw JSON strings.

We won't write these methods here because
implementing them is complex and doesn't involve much Cats code.
However, we can discuss their type signatures usefully.

We can easily serialize a `JsonValue` to a `String`
without fear failure, so a simple type signature will suffice:

```tut:book
object Json {
  def stringify(value: JsonValue): String =
    ???
}
```

Parsing JSON strings is a different story.
The user may provide a malformed string that we can't parse.
If this happens we should fail gracefully
offer some feedback as to what went wrong.
The type signature should therefore include
an error handling monad and a suitable error type.
Here's an example:

```tut:book
import cats.data.Xor

case class JsonParserError(message: String)

object Json {
  def parse(json: String): JsonParserError Xor JsonValue =
    ???

  def stringify(value: JsonValue): String =
    ???
}
```

We'll leave the implementation of these methods as an optional exercise
and move on to the interesting part:
converting `JsonValues` to semantic Scala types.

## Decoding and Encoding *JsonValues*

Imagine we have a Scala application with some app-specific data types:

```tut:book
case class Address(house: Int, street: String)
case class Person(name: String, address: Address)
```

If we can write code to encode these types as `JsonValues`,
we can use the `Json.stringify` method from last section
to convert them all the way to raw JSON.
Similarly, if we can write code to decode `JsonValues`
as `Addresses` and `People` (and other types we care about),
we can build a complete conversion all the say from raw JSON.

In other words, we want to create two generalised mappings
and implement them for any types of interest:

- "encoding" an arbitrary type `A` to a `JsonValue`;
- "decoding" a `JsonValue` to an arbitrary type `A`.

This is a perfect scenario for some custom type classes.
Write two type classes, `JsonEncoder` and `JsonEncoder`,
to model these processes.

<div class="solution">
Each type class has a single method
representing the corresponding operation.
The `decode` operation can fail so
we model the failure using `Xor` and a custom error type.

```tut:book
case class JsonDecoderError(message: String)

trait JsonEncoder[A] {
  def encode(value: A): JsonValue
}

trait JsonDecoder[A] {
  def decode(value: JsonValue): JsonDecoderError Xor A
}
```

We also add the usual companion objects with `apply`
methods to summon instances of the type class:

```scala
object JsonEncoder {
  def apply[A](implicit encoder: JsonEncoder[A]): JsonEncoder[A] =
    encoder
}

object JsonDecoder {
  def apply[A](implicit decoder: JsonDecoder[A]): JsonDecoder[A] =
    decoder
}
```
</div>

Implement a library of basic type class instances
for the following primitive Scala types:
`String`, `Double`, `Int`, `Boolean`,
`Option[A]`, `List[A]`, and `Map[String, A]`.

<div class="solution">
Here are the encoders.
Note that we define a `pure` method to
avoid continually writing `new JsonEncoder` and `def encode`:

```tut:book
trait JsonEncoderInstances {
  def pure[A](func: A => JsonValue): JsonEncoder[A] =
    new JsonEncoder[A] {
      def encode(value: A): JsonValue =
        func(value)
    }

  implicit val string: JsonEncoder[String] =
    pure(JsonString(_))

  implicit val double: JsonEncoder[Double] =
    pure(JsonNumber(_))

  implicit val int: JsonEncoder[Int] =
    pure(JsonNumber(_))

  implicit val boolean: JsonEncoder[Boolean] =
    pure(JsonBoolean(_))

  implicit def option[A](implicit aEncoder: JsonEncoder[A]): JsonEncoder[Option[A]] =
    pure(opt => opt.fold[JsonValue](JsonNull)(aEncoder.encode))

  implicit def list[A](implicit aEncoder: JsonEncoder[A]): JsonEncoder[List[A]] =
    pure(list => JsonArray(list map aEncoder.encode))

  implicit def map[A](implicit aEncoder: JsonEncoder[A]): JsonEncoder[Map[String, A]] =
    pure(dict => JsonObject(dict.toList map {
      case (key, value) => (key, aEncoder.encode(value))
    }))
}
```

We make it easy for users to import our instances
with a singleton `encoders `object:

```tut:book
object encoders extends JsonEncoderInstances
```

The advantage of this approach is that users can "remix"
our defaults by extending `JsonEncoderInstances`
themselves and overriding some of the default instances.

Here are the decoders.
We define two helper methods here:
`pure` to create instances as before,
and `fail` to make it easier to create `JsonDecoderErrors`:

```tut:book
import cats.instances.list._,
       cats.syntax.traverse._,
       cats.syntax.xor._

trait JsonDecoderInstances {
  def pure[A](func: JsonValue => JsonDecoderError Xor A): JsonDecoder[A] =
    new JsonDecoder[A] {
      def decode(value: JsonValue): JsonDecoderError Xor A =
        func(value)
    }

  def fail(message: String): JsonDecoderError =
    JsonDecoderError(message)

  implicit val string: JsonDecoder[String] =
    pure {
      case JsonString(value) =>
        value.right

      case other =>
        fail(s"Could not decode $other").left
    }

  implicit val double: JsonDecoder[Double] =
    pure {
      case JsonNumber(value) =>
        value.right

      case other =>
        fail(s"Could not decode $other").left
    }

  implicit val int: JsonDecoder[Int] =
    pure {
      case JsonNumber(value) if math.abs(value - math.floor(value)) < 0.001 =>
        value.toInt.right

      case other =>
        fail(s"Expected an integer, received $other").left
    }

  implicit val boolean: JsonDecoder[Boolean] =
    pure {
      case JsonBoolean(value) => value.right
      case other              => fail(s"Could not decode $other").left
    }

  implicit def option[A](implicit aDecoder: JsonDecoder[A]): JsonDecoder[Option[A]] =
    pure { json =>
      aDecoder.decode(json).fold(
        error => json match {
                   case JsonNull => None.right
                   case other    => fail(s"Could not decode $other").left
                 },
        value => Some(value).right
      )
    }

  implicit def list[A](implicit aDecoder: JsonDecoder[A]): JsonDecoder[List[A]] =
    pure {
      case json @ JsonArray(values) =>
        values.map(aDecoder.decode).sequenceU

      case other =>
        fail(s"Could not decode $other").left
    }

  implicit def map[A](implicit aDecoder: JsonDecoder[A]): JsonDecoder[Map[String, A]] =
    pure {
      case json @ JsonObject(fields) =>
        fields.map {
          case (name, value) =>
            aDecoder.decode(value).map(name -> _)
        }.sequenceU.map(_.toMap)

      case other =>
        fail(s"Could not decode $other").left
    }
}
```

Again, we make these easy to import with an object:

```tut:book
object decoders extends JsonDecoderInstances
```
</div>
