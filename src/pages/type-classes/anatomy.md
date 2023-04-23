## Anatomy of a Type Class

There are three important components to the type class pattern:
the *type class* itself,
*instances* for particular types,
and the methods that *use* type classes.

Type classes in Scala are implemented using *traits*, *given instances* and *using clauses*,
and optionally using *extension methods*.
Scala language constructs correspond to the components of type classes as follows:

- traits: type classes;
- given instances: type class instances;
- using clauses: type class use; and
- extension methods: optional utilities that make type classes easier to use.

Let's see how this works in detail.


### The Type Class

A *type class* is an interface or API
that represents some functionality we want to implement.
In Scala a type class is represented by a trait with at least one type parameter.
For example, we can represent generic "serialize to JSON" behaviour
as follows:

```scala mdoc:silent:reset-object
// Define a very simple JSON AST
enum Json:
  case JsObject(get: Map[String, Json])
  case JsString(get: String)
  case JsNumber(get: Double)
  case JsNull

// The "serialize to JSON" behaviour is encoded in this trait
trait JsonWriter[A]:
  def write(value: A): Json
```

`JsonWriter` is our type class in this example,
with `Json` and its subtypes providing supporting code.
When we come to implement instances of `JsonWriter`,
the type parameter `A` will be the concrete type of data we are writing.

### Type Class Instances

The *instances* of a type class
provide implementations of the type class for specific types we care about,
which can include types from the Scala standard library
and types from our domain model.

In Scala we define instances by creating
concrete implementations of the type class
and tagging them with the `given` keyword:

```scala mdoc:silent
final case class Person(name: String, email: String)

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
```

These are known as given instances.

### Type Class Use

A type class *use* is any functionality 
that requires a type class instance to work.
In Scala this means any method 
that accepts instances of the type class as using clauses.

Cats provides utilities that make type classes easier to use,
and you will sometimes seem these patterns in other libraries.
There are two ways it does this: *Interface Objects* and *Interface Syntax*.

**Interface Objects**

The simplest way of creating an interface that uses a type class
is to place methods in a singleton object:

```scala mdoc:silent
object Json:
  def toJson[A](value: A)(using w: JsonWriter[A]): Json =
    w.write(value)
```

To use this object, we import any type class instances we care about
and call the relevant method:

```scala mdoc
Json.toJson(Person("Dave", "dave@example.com"))
```

The compiler spots that we've called the `toJson` method
without providing the using clauses.
It tries to fix this by searching for type class instances
of the relevant types and inserting them at the call site:

```scala mdoc:silent
Json.toJson(Person("Dave", "dave@example.com"))(using personWriter)
```

**Interface Syntax**

We can alternatively use *extension methods* to
extend existing types with interface methods[^pimping].
Cats refers to this as *"syntax"* for the type class:

[^pimping]: You may occasionally see extension methods
referred to as "type enrichment" or "pimping".
These are older terms that we don't use anymore.

```scala mdoc:silent
extension [A](value: A)
  def toJson(using w: JsonWriter[A]): Json =
    w.write(value)
```

We use interface syntax by importing it
alongside the instances for the types we need:

```scala mdoc
Person("Dave", "dave@example.com").toJson
```

Again, the compiler searches for candidates
for the using clauses and fills them in for us:

```scala mdoc:silent
Person("Dave", "dave@example.com").toJson(using personWriter)
```

**The *summon* Method**

The Scala standard library provides
a generic type class interface called `summon`.
Its definition is very simple:

```scala
def summon[A](using value: A): A = value
```

We can use `summon` to summon any value from the contextual abstractions scope.
We provide the type we want and `summon` does the rest:

```scala mdoc
summon[JsonWriter[String]]
```

Most type classes in Cats provide other means to summon instances.
However, `summon` is a good fallback for debugging purposes.
We can insert a call to `summon` within the general flow of our code
to ensure the compiler can find an instance of a type class
and ensure that there are no ambiguous given instances errors.
