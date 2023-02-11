## Working with Given Instances and Using Clauses

```scala mdoc:invisible
// Forward definitions

enum Json:
  case JsObject(get: Map[String, Json])
  case JsString(get: String)
  case JsNumber(get: Double)
  case JsNull

trait JsonWriter[A]:
  def write(value: A): Json

case class Person(name: String, email: String)

given stringWriter: JsonWriter[String] with
  def write(value: String): Json =
    Json.JsString(value)

given personWriter: JsonWriter[Person] with
  def write(value: Person): Json =
    Json.JsObject(Map(
      "name" -> Json.JsString(value.name),
      "email" -> Json.JsString(value.email)
    ))

// etc...

object Json:
  def toJson[A](value: A)(using w: JsonWriter[A]): Json =
    w.write(value)
```

Working with type classes in Scala means
working with given instances and using clauses.
There are a few rules we need to know to do this effectively.

### Implicit Scope

As we saw above, the compiler searches
for candidate type class instances by type.
For example, in the following expression
it will look for an instance of type
`JsonWriter[String]`:

```scala mdoc:silent
Json.toJson("A string!")
```

The places where the compiler searches for candidate instances
is known as the *implicit scope*.
The implicit scope applies at the call site;
that is the point where we call a method with a using clause.
The implicit scope which roughly consists of:

- local or inherited definitions;

- imported definitions;

- definitions in the companion object
  of the type class or the parameter type
  (in this case `JsonWriter` or `String`).

Furthermore, if the compiler sees multiple candidate definitions,
it fails with an *ambiguous given instances* error:

```scala mdoc:invisible:reset-object
enum Json:
  case JsObject(get: Map[String, Json])
  case JsString(get: String)
  case JsNumber(get: Double)
  case JsNull

trait JsonWriter[A]:
  def write(value: A): Json

given stringWriter: JsonWriter[String] with
  def write(value: String): Json =
    Json.JsString(value)

object Json:
  def toJson[A](value: A)(using w: JsonWriter[A]): Json =
    w.write(value)
```
```scala mdoc:fail
given secondStringWriter: JsonWriter[String] =
  JsonWriterInstances.stringWriter

Json.toJson("A string")
```

The precise rules of given instance resolution are more complex than this,
but the complexity is largely irrelevant for day-to-day use[^implicit-search].
For our purposes, we can package type class instances in roughly five ways:

1. by placing them as top level definitions in a package.
2. by placing them in an object such as `JsonWriterInstances`;
3. by placing them in a trait;
4. by placing them in the companion object of the type class;
5. by placing them in the companion object of the parameter type.

With option 1 and 2 we bring given instances into scope by `importing` them explicitly.
With option 3 we bring them into scope with inheritance.
With options 4 and 5 instances are *always* in implicit scope,
regardless of where we try to use them.

It is conventional to put type class instances in a companion object (option 4 and 5 above)
if there is only one sensible implementation,
or at least one implementation that is widely accepted as the default.
This makes type class instances easier to use
as no import is required to bring them into the implicit scope.

[^implicit-search]: If you're interested in the finer rules of implicit resolution in Scala,
start by taking a look at [this Stack Overflow post on implicit scope][link-so-implicit-scope]
and [this blog post on implicit priority][link-implicit-priority].


### Recursive Given Instance Resolution {#sec:type-classes:recursive-implicits}

The power of type classes with given instances and using clauses lies in
the compiler's ability to *combine* given instances definitions
when searching for candidate instances.
This is sometimes known as *type class composition*.

Earlier we insinuated that all type class instances
are `given`. This was a simplification.
We can actually define instances in two ways:

1. by defining concrete instances as
   `given` of the required type;

2. by defining `given` methods to
   construct instances from other type class instances.

Why would we construct instances from other instances?
As a motivational example,
consider defining a `JsonWriter` for `Option`.
We would need a `JsonWriter[Option[A]]`
for every `A` we care about in our application.
We could try to brute force the problem by creating
a library of `given`s:

```scala
given optionIntWriter: JsonWriter[Option[Int]] with
  ???

given optionPersonWriter: JsonWriter[Option[Person]] with
  ???

// and so on...
```

However, this approach clearly doesn't scale.
We end up requiring two `given` instances
for every type `A` in our application:
one for `A` and one for `Option[A]`.

Fortunately, we can abstract the code for handling `Option[A]`
into a common constructor based on the instance for `A`:

- if the option is `Some(aValue)`,
  write `aValue` using the writer for `A`;

- if the option is `None`, return `JsNull`.

Here is the same code written out as a `given` with a `using` clause:

```scala mdoc:silent
given optionWriter[A](using writer: JsonWriter[A]): JsonWriter[Option[A]] with
  def write(option: Option[A]): Json =
    option match {
      case Some(aValue) => writer.write(aValue)
      case None         => Json.JsNull
    }
```

This method *constructs* a `JsonWriter` for `Option[A]` by
relying on a using clause to
fill in the `A`-specific functionality.
When the compiler sees an expression like this:

```scala mdoc:silent
Json.toJson(Option("A string"))
```

it searches for an implicit `JsonWriter[Option[String]]`.
It finds the implicit method for `JsonWriter[Option[A]]`:

```scala mdoc:silent
Json.toJson(Option("A string"))(using optionWriter[String])
```

and recursively searches for a `JsonWriter[String]`
to use as the parameter to `optionWriter`:

```scala mdoc:silent
Json.toJson(Option("A string"))(using optionWriter(using stringWriter))
```

In this way, given instance resolution becomes
a search through the space of possible combinations
of given definitions, to find
a combination that creates a type class instance
of the correct overall type.

<div class="callout callout-warning">
*Implicit Conversions*

When you create a type class instance constructor
using an `given`,
be sure to mark the parameters to the method
as `using` parameters.
Without this keyword, the compiler won't be able to
fill in the parameters during given instance resolution.

`given` methods with non-`using` parameters
form a different Scala pattern called an *implicit conversion*. 
This is also different from the previous section on `Interface Syntax`, 
because in that case the `JsonWriter` is an implicit class with extension methods. 
Implicit conversion is an older programming pattern
that is frowned upon in modern Scala code.
Fortunately, the compiler will warn you when you do this.
You have to manually enable implicit conversions
by importing `scala.language.implicitConversions` in your file:

```scala mdoc:invisible:reset
type Json = Nothing
trait JsonWriter[A]:
  def write(value: A): Json
```
```scala modc:warn
given optionWriter[A](writer: JsonWriter[A]): JsonWriter[Option[A]] =
  ???
// warning: implicit conversion method foo should be enabled
// by making the implicit value scala.language.implicitConversions visible.
// This can be achieved by adding the import clause 'import scala.language.implicitConversions'
// or by setting the compiler option -language:implicitConversions.
// See the Scaladoc for value scala.language.implicitConversions for a discussion
// why the feature should be explicitly enabled.
```
</div>
