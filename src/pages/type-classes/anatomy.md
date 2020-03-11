## Anatomy of a Type Class

There are three important components to the type class pattern:
the *type class* itself,
*instances* for particular types,
and the *interface* methods that we expose to users.

### The Type Class

A *type class* is an interface or API
that represents some functionality we want to implement.
In Cats a type class is represented by a trait with at least one type parameter.
For example, we can represent generic "serialize to JSON" behaviour
as follows:

```scala mdoc:silent:reset-object
// Define a very simple JSON AST
sealed trait Json
final case class JsObject(get: Map[String, Json]) extends Json
final case class JsString(get: String) extends Json
final case class JsNumber(get: Double) extends Json
final case object JsNull extends Json

// The "serialize to JSON" behaviour is encoded in this trait
trait JsonWriter[A] {
  def write(value: A): Json
}
```

`JsonWriter` is our type class in this example,
with `Json` and its subtypes providing supporting code.

### Type Class Instances

The *instances* of a type class
provide implementations of the type class for the types we care about,
including types from the Scala standard library
and types from our domain model.

In Scala we define instances by creating
concrete implementations of the type class
and tagging them with the `implicit` keyword:

```scala mdoc:silent
case class Person(name: String, email: String)

object JsonWriterInstances {
  implicit val stringWriter: JsonWriter[String] =
    new JsonWriter[String] {
      def write(value: String): Json =
        JsString(value)
    }

  implicit val personWriter: JsonWriter[Person] =
    new JsonWriter[Person] {
      def write(value: Person): Json =
        JsObject(Map(
          "name" -> JsString(value.name),
          "email" -> JsString(value.email)
        ))
    }

  // etc...
}
```

### Type Class Interfaces

A type class *interface* is any functionality we expose to users.
Interfaces are generic methods that accept
instances of the type class as implicit parameters.

There are two common ways of specifying an interface:
*Interface Objects* and *Interface Syntax*.

**Interface Objects**

The simplest way of creating an interface
is to place methods in a singleton object:

```scala mdoc:silent
object Json {
  def toJson[A](value: A)(implicit w: JsonWriter[A]): Json =
    w.write(value)
}
```

To use this object, we import any type class instances we care about
and call the relevant method:

```scala mdoc:silent
import JsonWriterInstances._
```

```scala mdoc
Json.toJson(Person("Dave", "dave@example.com"))
```

The compiler spots that we've called the `toJson` method
without providing the implicit parameters.
It tries to fix this by searching for type class instances
of the relevant types and inserting them at the call site:

```scala mdoc:silent
Json.toJson(Person("Dave", "dave@example.com"))(personWriter)
```

**Interface Syntax**

We can alternatively use *extension methods* to
extend existing types with interface methods[^pimping].
Cats refers to this as *"syntax"* for the type class:

[^pimping]: You may occasionally see extension methods
referred to as "type enrichment" or "pimping".
These are older terms that we don't use anymore.

```scala mdoc:silent
object JsonSyntax {
  implicit class JsonWriterOps[A](value: A) {
    def toJson(implicit w: JsonWriter[A]): Json =
      w.write(value)
  }
}
```

We use interface syntax by importing it
alongside the instances for the types we need:

```scala mdoc:silent
import JsonWriterInstances._
import JsonSyntax._
```

```scala mdoc
Person("Dave", "dave@example.com").toJson
```

Again, the compiler searches for candidates
for the implicit parameters and fills them in for us:

```scala mdoc:silent
Person("Dave", "dave@example.com").toJson(personWriter)
```

**The *implicitly* Method**

The Scala standard library provides
a generic type class interface called `implicitly`.
Its definition is very simple:

```scala
def implicitly[A](implicit value: A): A =
  value
```

We can use `implicitly` to summon any value from implicit scope.
We provide the type we want and `implicitly` does the rest:

```scala mdoc
import JsonWriterInstances._

implicitly[JsonWriter[String]]
```

Most type classes in Cats provide other means to summon instances.
However, `implicitly` is a good fallback for debugging purposes.
We can insert a call to `implicitly` within the general flow of our code
to ensure the compiler can find an instance of a type class
and ensure that there are no ambiguous implicit errors.
