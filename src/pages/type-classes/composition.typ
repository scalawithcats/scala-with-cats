#import "../stdlib.typ": info, warning, solution
== Type Class Composition 
<sec:type-classes:composition>


```scala mdoc:invisible:reset-object
// Define a very simple JSON AST
sealed trait Json
final case class JsObject(get: Map[String, Json]) extends Json
final case class JsString(get: String) extends Json
final case class JsNumber(get: Double) extends Json
case object JsNull extends Json
object Json {
  def toJson[A](value: A)(using w: JsonWriter[A]): Json =
    w.write(value)
}

// The "serialize to JSON" behaviour is encoded in this trait
trait JsonWriter[A] {
  def write(value: A): Json
}
```

So far we've seen type classes as a way to get the compiler to pass values to methods.
This is nice but it does seem like we've introduced a lot of new concepts for a small gain.
The real power of type classes lies in
the compiler's ability to combine given instances
to construct new given instances.
This is known as *type class composition*.

Type class composition works by a feature of given instances we have not yet seen:
given instances can themselves have context parameters.
However, before we go into this
let's see a motivational example.

Consider defining a `JsonWriter` for `Option`.
We would need a `JsonWriter[Option[A]]`
for every `A` we care about in our application.
We could try to brute force the problem by creating
a library of given instances:

```scala
given optionIntWriter: JsonWriter[Option[Int]] =
  ???

given optionPersonWriter: JsonWriter[Option[Person]] =
  ???

// and so on...
```

However, this approach clearly doesn't scale.
We end up requiring two given instances
for every type `A` in our application:
one for `A` and one for `Option[A]`.

Fortunately, we can abstract the code for handling `Option[A]`
into a common constructor based on the instance for `A`:

- if the option is `Some(aValue)`,
  write `aValue` using the writer for `A`;

- if the option is `None`, return `JsNull`.

Here is the same code written out using a parameterized given instance:

```scala mdoc:silent
given optionWriter[A](using writer: JsonWriter[A]): JsonWriter[Option[A]] =
  new JsonWriter[Option[A]] {
    def write(option: Option[A]): Json =
      option match {
        case Some(aValue) => writer.write(aValue)
        case None         => JsNull
      }
  }
```

This method constructs a `JsonWriter` for `Option[A]` by
relying on a context parameter to
fill in the `A`-specific functionality.
When the compiler sees an expression like this:

```scala mdoc:invisible
given stringWriter: JsonWriter[String] =
  new JsonWriter[String] {
    def write(value: String): Json = JsString(value)
  }
```
```scala mdoc:silent
Json.toJson(Option("A string"))
```

it searches for an given instance `JsonWriter[Option[String]]`.
It finds the given instance for `JsonWriter[Option[A]]`:

```scala mdoc:silent
Json.toJson(Option("A string"))(using optionWriter[String])
```

and recursively searches for a `JsonWriter[String]`
to use as the context parameter to `optionWriter`:

```scala mdoc:silent
Json.toJson(Option("A string"))(using optionWriter(using stringWriter))
```

In this way, given instance resolution becomes
a search through the space of possible combinations
of given instance, to find
a combination that creates a type class instance
of the correct overall type.


=== Type Class Composition in Scala 2


In Scala 2 we can achieve the same effect with an `implicit` method with `implicit` parameters.
Here's the Scala 2 equivalent of `optionWriter` above.

```scala mdoc:invisible:reset-object
// Define a very simple JSON AST
sealed trait Json
final case class JsObject(get: Map[String, Json]) extends Json
final case class JsString(get: String) extends Json
final case class JsNumber(get: Double) extends Json
case object JsNull extends Json

// The "serialize to JSON" behaviour is encoded in this trait
trait JsonWriter[A] {
  def write(value: A): Json
}
```
```scala mdoc:silent
implicit def scala2OptionWriter[A]
    (implicit writer: JsonWriter[A]): JsonWriter[Option[A]] =
  new JsonWriter[Option[A]] {
    def write(option: Option[A]): Json =
      option match {
        case Some(aValue) => writer.write(aValue)
        case None         => JsNull
      }
  }
```

Make sure you make the method's parameter implicit!
If you don't, you'll end up defining an *implicit conversion*.
Implicit conversion is an older programming pattern
that is frowned upon in modern Scala code.
Fortunately, the compiler will warn you should you do this.
