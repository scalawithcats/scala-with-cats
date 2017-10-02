## Working with Implicits

```tut:book:invisible
// Forward definitions

sealed trait Json
final case class JsObject(get: Map[String, Json]) extends Json
final case class JsString(get: String) extends Json
final case class JsNumber(get: Double) extends Json
case object JsNull extends Json

trait JsonWriter[A] {
  def write(value: A): Json
}

final case class Person(name: String, email: String)

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

import JsonWriterInstances._

object Json {
  def toJson[A](value: A)(implicit w: JsonWriter[A]): Json =
    w.write(value)
}
```

Working with type classes in Scala means
working with implicit values and implicit parameters.
There are a few rules we need to know to do this effectively.

### Packaging Implicits

In a curious quirk of the language,
any definitions marked `implicit` in Scala must be placed
inside an object or trait rather than at the top level.
In the example above we packaged our type class instances
in an object called `JsonWriterInstances`.
We could equally have placed them
in a companion object to `JsonWriter`.
Placing instances in a companion object
to the type class has special significance in Scala
because it plays into something called *implicit scope*.

### Implicit Scope

As we saw above, the compiler searches
for candidate type class instances by type.
For example, in the following expression
it will look for an instance of type
`JsonWriter[String]`:

```tut:book:silent
Json.toJson("A string!")
```

The compiler searches for candidate instances
in the *implicit scope* at the call site,
which roughly consists of:

- local or inherited definitions;

- imported definitions;

- definitions in the companion object
  of the type class or the parameter type
  (in this case `JsonWriter` or `String`).

Definitions are only included in implicit scope
if they are tagged with the `implicit` keyword.
Furthermore, if the compiler sees multiple candidate definitions,
it fails with an *ambiguous implicit values* error:

```scala
implicit val writer1: JsonWriter[String] =
  JsonWriterInstances.stringWriter

implicit val writer2: JsonWriter[String] =
  JsonWriterInstances.stringWriter

Json.toJson("A string")
// <console>:23: error: ambiguous implicit values:
//  both value stringWriter in object JsonWriterInstances of type => JsonWriter[String]
//  and value writer1 of type => JsonWriter[String]
//  match expected type JsonWriter[String]
//          Json.toJson("A string")
//                     ^
```

The precise rules of implicit resolution are more complex than this,
but the complexity is largely irrelevant for this book[^implicit-search].
For our purposes, we can package type class instances in roughly four ways:

1. by placing them in an object such as `JsonWriterInstances`;
2. by placing them in a trait;
3. by placing them in the companion object of the type class;
4. by placing them in the companion object of the parameter type.

With option 1 we bring instances into scope by `importing` them.
With option 2 we bring them into scope with inheritance.
With options 3 and 4, instances are *always* in implicit scope,
regardless of where we try to use them.

[^implicit-search]: If you're interested in the finer rules of implicit resolution in Scala,
start by taking a look at [this Stack Overflow post on implicit scope][link-so-implicit-scope]
and [this blog post on implicit priority][link-implicit-priority].

### Recursive Implicit Resolution {#sec:type-classes:recursive-implicits}

The power of type classes and implicits lies in
the compiler's ability to *combine* implicit definitions
when searching for candidate instances.

Earlier we insinuated that all type class instances
are `implicit vals`. This was a simplification.
We can actually define instances in two ways:

1. by defining concrete instances as
   `implicit vals` of the required type[^implicit-objects];

2. by defining `implicit` methods to
   construct instances from other type class instances.

[^implicit-objects]: `implicit objects` are treated the same way.

Why would we construct instances from other instances?
As a motivational example,
consider defining a `JsonWriter` for `Options`.
We would need a `JsonWriter[Option[A]]`
for every `A` we care about in our application.
We could try to brute force the problem by creating
a library of `implicit vals`:

```scala
implicit val optionIntWriter: JsonWriter[Option[Int]] =
  ??? // and so on...

implicit val optionPersonWriter: JsonWriter[Option[Person]] =
  ??? // and so on...
```

However, this approach clearly doesn't scale.
We end up requiring two `implicit vals`
for every type `A` in our application:
one for `A` and one for `Option[A]`.

Fortunately, we can abstract the code for handling `Option[A]`
into a common constructor based on the instance for `A`:

- if the option is `Some(aValue)`,
  write `aValue` using the writer for `A`;

- if the option is `None`, write `null`.

Here is the same code written out as an `implicit def`:

```tut:book:silent
implicit def optionWriter[A]
    (implicit writer: JsonWriter[A]): JsonWriter[Option[A]] =
  new JsonWriter[Option[A]] {
    def write(option: Option[A]): Json =
      option match {
        case Some(aValue) => writer.write(aValue)
        case None         => JsNull
      }
  }
```

This method *constructs* a `JsonWriter` for `Option[A]` by
relying on an implicit parameter to
fill in the `A`-specific functionality.
When the compiler sees an expression like this:

```tut:book:silent
Json.toJson(Option("A string"))
```

it searches for an implicit `JsonWriter[Option[String]]`.
It finds the implicit method for `JsonWriter[Option[A]]`:

```tut:book:silent
Json.toJson(Option("A string"))(optionWriter[String])
```

and recursively searches for a `JsonWriter[String]`
to use as the parameter to `optionWriter`:

```tut:book:silent
Json.toJson(Option("A string"))(optionWriter(stringWriter))
```

In this way, implicit resolution becomes
a search through the space of possible combinations
of implicit definitions, to find
a combination that summons a type class instance
of the correct overall type.

<div class="callout callout-warning">
*Implicit conversions*

When you create a type class instance constructor
using an `implicit def`,
be sure to mark the parameters to the method
as `implicit` parameters.
Without this keyword, the compiler won't be able to
fill in the parameters during implicit resolution.

`implicit` methods with non-`implicit` parameters
form a different Scala pattern called an *implicit conversion*.
This is an older programming pattern
that is frowned upon in modern Scala code.
Fortunately, the compiler will warn you when you do this.
You have to manually enable implicit conversions
by importing `scala.language.implicitConversions` in your file,
so if you forget to tag parameters as `implicit`
you will see a compiler warning like this:

```tut:book:fail
implicit def optionWriter[A]
    (writer: JsonWriter[A]): JsonWriter[Option[A]] =
  ???
```
</div>
