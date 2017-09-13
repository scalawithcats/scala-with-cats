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

```tut:book:silent
// Define a very simple JSON AST
sealed trait Json
final case class JsObject(get: Map[String, Json]) extends Json
final case class JsString(get: String) extends Json
final case class JsNumber(get: Double) extends Json

// The "serialize to JSON" behavior is encoded in this trait
trait JsonWriter[A] {
  def write(value: A): Json
}
```

`JsonWriter` is our type class in this example,
with `Json` and its subtypes providing supporting code.

### Type Class Instances

The *instances* of a type class
provide implementations for the types we care about,
including types from the Scala standard library
and types from our domain model.

In Scala we define instances by creating
concrete implementations of the type class
and tagging them with the `implicit` keyword:

```tut:book:silent
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

```tut:book:silent
object Json {
  def toJson[A](value: A)(implicit w: JsonWriter[A]): Json =
    w.write(value)
}
```

To use this object, we import any type class instances we care about
and call the relevant method:

```tut:book:silent
import JsonWriterInstances._
```

```tut:book
Json.toJson(Person("Dave", "dave@example.com"))
```

**Interface Syntax**

We can alternatively use *extension methods* to
extend existing types with interface methods[^pimping].
Cats refers to this as *"syntax"* for the type class:

[^pimping]: You may occasionally see extension methods
referred to as "type enrichment" or "pimping".
These are older terms that we don't use anymore.

```tut:book:silent
object JsonSyntax {
  implicit class JsonWriterOps[A](value: A) {
    def toJson(implicit w: JsonWriter[A]): Json =
      w.write(value)
  }
}
```

We use interface syntax by importing it
along-side the instances for the types we need:

```tut:book:silent
import JsonWriterInstances._
import JsonSyntax._
```

```tut:book
Person("Dave", "dave@example.com").toJson
```

**The *implicitly* Method**

The standard library provides a generic interface method called `implicitly`.
Its definition is very simple:

```scala
def implicitly[A](implicit value: A): A =
  value
```

We can use `implicitly` to summon any value from implicit scope.
We simply provide the type we want to summon and `implicitly` does the rest:

```tut:book
import JsonWriterInstances._

implicitly[JsonWriter[String]]
```

Most type classes in Cats provide other means to summon instances.
However, `implicitly` is a good fallback for debugging purposes.
We can insert a call to `implicitly` within the general flow of our code
to ensure the compiler is able to find an instance of a type class
and ensure that there are no ambiguous implicit errors.

### Packaging Type Class Instances

In a curious quirk of the language,
`implicit` values in Scala must be defined
inside an object or trait.
They can't be defined at the top level.
In the example above we packaged our instances
in an object called `JsonWriterInstances`.
We could equally have placed the instances
in a companion object to `JsonWriter`.
Placing instances in a companion object
to the type class has special significance in Scala.

The compiler looks for caldidate values for implicit parameters by type.
It searches in the *implicit scope* at the call site,
which roughly consists of:

- local or inherited values of the correct type;
- imported values of the correct type;
- values of the correct type that are defined
  in the companion object of the type class or parameter type
  (in this case `JsonWriter` or `Person`).

Values are only eligible if they are tagged with the `implicit` keyword,
and if the compiler sees multiple candidate values,
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

The precise rules of how the compiler searches for implicits
are actually a little more complex than we're letting on here.
However, the details are largely irrelevant for this book[^implicit-search].
For our purposes, we can package implicits in roughly four ways:

1. by placing them in an object such as `JsonWriterInstances`;
2. by placing them in a trait;
3. by placing them in the companion object of the type class;
4. by placing them in the companion object of the parameter type.

With option 1 we bring instances into scope by `importing` them.
With option 2 we bring them into scope with inheritance.
With options 3 and 4, instances are always in scope,
regardless of where we try to use them.

[^implicit-search]: If you're interested in the finer rules of implicit resolution in Scala,
start by taking a look at [this Stack Overflow post on implicit schope][link-so-implicit-scope]
and [this post on implicit priority][link-so-implicit-priority].

### Exercise: *Printable* Library

Scala provides a `toString` method
to let us convert any value to a `String`.
However, this method comes with a few disadvantages.
It is implemented for *every* type in the language,
many implementations are of limited use,
and we can't opt-in to specific implementations for specific types.

Let's define a `Printable` type class to work around these problems:

 1. Define a type class `Printable[A]` containing a single method `format`.
    `format` should accept a value of type `A` and return a `String`.

 2. Create an object `PrintableInstances`
    containing instances of `Printable` for `String` and `Int`.

 3. Define an object `Printable` with two generic interface methods:

    - `format` accepts a value of type `A`
      and a `Printable` of the corresponding type.
      It uses the relevant `Printable` to convert the `A` to a `String`.

    - `print` accepts the same parameters as `format` and returns `Unit`.
      It prints the `A` value to the console using `println`.

<div class="solution">
These steps define the three main components of our type class.
First we define `Printable`---the *type class* itself:

```tut:book:silent
trait Printable[A] {
  def format(value: A): String
}
```

Then we define some default *instances* of `Printable`
and package then in `PrintableInstances`:

```tut:book:silent
object PrintableInstances {
  implicit val stringPrintable = new Printable[String] {
    def format(input: String) = input
  }

  implicit val intPrintable = new Printable[Int] {
    def format(input: Int) = input.toString
  }
}
```

Finally we define an *interface* object, `Printable`:

```tut:book:silent
object Printable {
  def format[A](input: A)(implicit p: Printable[A]): String =
    p.format(input)

  def print[A](input: A)(implicit p: Printable[A]): Unit =
    println(format(input))
}
```
</div>

**Using the Library**

The code above forms a general purpose printing library
that we can use in multiple applications.
Let's define an "application" now that uses the library:

 1. Define a data type `Cat`:

    ```scala
    final case class Cat(
      name: String,
      age: Int,
      color: String
    )
    ```

 2. Create an implementation of `Printable` for `Cat`
    that returns content in the following format:

    ```
    NAME is a AGE year-old COLOR cat.
    ```

 3. Finally, use the type class on the console or in a short demo app:
    create a `Cat` and print it to the console:

    ```scala
    // Define a cat:
    val cat = Cat(/* ... */)

    // Print the cat!
    ```

<div class="solution">
This is a standard use of the type class pattern.
First we define a set of custom data types for our application:

```tut:book:silent
final case class Cat(name: String, age: Int, color: String)
```

Then we define type class instances for the types we care about.
These either go into the companion object of `Cat`
or a separate object to act as a namespace:

```tut:book:silent
import PrintableInstances._

implicit val catPrintable = new Printable[Cat] {
  def format(cat: Cat) = {
    val name  = Printable.format(cat.name)
    val age   = Printable.format(cat.age)
    val color = Printable.format(cat.color)
    s"$name is a $age year-old $color cat."
  }
}
```

Finally, we use the type class by
bringing the relevant instances into scope
and using interface object/syntax.
If we defined the instances in companion objects
Scala brings them into scope for us automatically.
Otherwise we use an `import` to access them:

```tut:book
val cat = Cat("Garfield", 38, "ginger and black")

Printable.print(cat)
```
</div>

**Better Syntax**

Let's make our printing library easier to use
by defining some extension methods to provide better syntax:

 1. Create an object called `PrintableSyntax`.

 2. Inside `PrintableSyntax` define an `implicit class PrintableOps[A]`
    to wrap up a value of type `A`.

 3. In `PrintableOps` define the following methods:

     - `format` accepts an implicit `Printable[A]`
       and returns a `String` representation of the wrapped `A`;

     - `print` accepts an implicit `Printable[A]` and returns `Unit`.
       It prints the wrapped `A` to the console.

 4. Use the extension methods to print the example `Cat`
    you created in the previous exercise.

<div class="solution">
First we define an `implicit class` containing our extension methods:

```tut:book:silent
object PrintableSyntax {
  implicit class PrintableOps[A](value: A) {
    def format(implicit p: Printable[A]): String =
      p.format(value)

    def print(implicit p: Printable[A]): Unit =
      println(p.format(value))
  }
}
```

With `PrintableOps` in scope,
we can call the imaginary `print` and `format` methods
on any value for which Scala can locate an implicit instance of `Printable`:

```tut:book:silent
import PrintableSyntax._
```

```tut:book
Cat("Garfield", 38, "ginger and black").print
```

We get a compile error if we haven't defined an instance of `Printable`
for the relevant type:

```tut:book:silent
import java.util.Date
```

```tut:book:fail
new Date().print
```
</div>

### Take Home Points

In this section we revisited the concept of a **type class**,
which allows us to add new functionality to existing types.

The Scala implementation of a type class has **three parts**:

 - the *type class* itself, a generic trait;
 - *instances* for each type we care about; and
 - one or more generic *interface* methods.

Interface methods can be defined in **interface objects** or **interface syntax**.
**Implicit classes** are the most common way of implementing syntax.

In the next section we will take a first look at Cats.
We will examine the standard code layout Cats uses
to organize its type classes,
and see how to select type classes, instances,
and syntax for use in our code.
