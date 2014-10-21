---
layout: page
title: Type Classes
---

# Type Classes

The **type class** programming pattern allows us to extend existing libraries with new functionality, without traditional inheritance, and without altering the original library source code. In this section we will cover the implementation of the pattern in Scala to ensure we understand it thoroughly.

## Anatomy of a Type Class

There are three important components to the type class pattern:

1. **The type class** itself -- the functionality we want to implement, expressed as a generic type. For example, we can represent a "serialize to JSON" type class as a generic trait:

   ~~~ scala
   trait JsonWriteable[A] {
     def write(value: A): Json
   }
   ~~~

2. **Instances** -- implementations of the type class for the types we care about, including standard Scala types and types from our domain model. We tag these with the `implicit` keyword:

   ~~~ scala
   object DefaultJsonWriteables {
     implicit val stringJsonWriteable = new JsonWriteable[String] { ... }
     implicit val dateJsonWriteable   = new JsonWriteable[Date]   { ... }
     implicit val personJsonWriteable = new JsonWriteable[Person] { ... }
     // etc...
    }
   ~~~

3. **Interface(s)** -- one or more widely-accessible methods that accept values together with the corresponding type class instances, and perform some useful functionality:

   ~~~ scala
   object Json {
     def toJson[A](value: A)(implicit writer: JsonWriteable[A]): Json = {
       writer.write(value)
     }
   }
   ~~~

To use a type class, we import the instances we care about and call the interface method:

~~~ scala
import DefaultJsonWriteables._

val json: Json = Json.toJson(Person("Dave", "dave@example.com"))
~~~

## Exercises

The `toString` method of `scala.Any` allows us to convert any value to a `String`. However, use of the method comes with a few disadvantages:

 - `toString` is implemented for *every* type in Scala, we want it or not;

 - the default implementations for many types are of little/no use (e.g. `AnyRef`);

 - it is difficult to specify alternative implementations of `toString` for a given type.

We can work around thes problems by defining a type class `Printable`. Let's do this now with the following steps:

 1. Define a trait `Printable[A]` containing a single method:

     - `print` accepts a value of type `A` and returns a `String`.

 2. Create an object `DefaultPrintables` containing default implementations of
    `Printable[A]` for `String` and `Int`.

 3. Define an object `Print` with two generic interface methods:

    - `stringify` accepts a value of type `A` and a `Printable` of the corresponding type. It returns the printable form of `A`;

    - `apply` accepts the same parameters as `stringify` and returns `Unit`. It prints the `A` value to the console using `println`.

The code in steps 1 to 3 can be considered a "printing library". Now define an "application" to use the library:

 1. Define a data type `Cat`:

    ~~~ scala
    case class Cat(name: String, age: Int, color: String)
    ~~~

 2. Create an implementation of `Printable` for `Cat` that returns content in the
    following format:

    ~~~
    NAME is a AGE year-old COLOR cat.
    ~~~

 3. Create an object `Main` to act as a front-end for your application. `Main` should create a `Cat` and print it to the console:

    ~~~ scala
    object Main extends App {
      val cat = Cat(/* ... */)

      // etc...
    }

<div class="solution">
// Library code -------------

trait Printable[A] {
  def print(value: A): String
}

object DefaultPrintables {
  implicit val stringPrintable = new Printable[String] {
    def print(input: String) = input
  }

  implicit val intPrintable = new Printable[Int] {
    def print(input: Int) = input.toString
  }
}

object Print {
  def stringify[A](input: A)(implicit printer: Printable[A]): String = {
    printer.print(input)
  }

  def apply[A](input: A)(implicit printer: Printable[A]): Unit = {
    println(stringify(input))
  }
}

// Application code ---------

case class Cat(name: String, age: Int, color: String)

object Cat {
  import DefaultPrintables._

  implicit val catPrintable = new Printable[Cat] {
    def print(cat: Cat) = {
      val name  = Print(cat.name)
      val age   = Print(cat.age)
      val color = Print(cat.color)

      s"$name is a $age year-old $color cat."
    }
  }
}

object Main extends App {
  val cat = Cat("Garfield", 35 "ginger and black")

  Print(p)
  // prints "Carfield is a 35 year-old ginger and black cat."
}
~~~
</div>

## Take Home Points

In this section we covered the concept of a *type class*, which allows us to add new functionality to existing types:

 - in a modular fashion;
 - without changing any existing code;
 - only providing implementations for types we care about.

We implemented a `Printable` type class to familiarize ourselves with the main parts of the Scala implementation:

 - the *type class* itself, a generic trait;
 - *instances* for each type we care about, and;
 - one or more generic *interface* methods.

Scalaz is a modular library that provides a set of foundational type classes for use in a wide variety of situations. The modularity allows us to choose exactly which type classes, instances, and interfaces we need at any given location in our code.

In the next section we will take a first look at Scalaz using its `Show` type class as an example. `Show` is a built-in equivalent of `Printable` -- we will use it to re-implement the cat-printing functionality above with equivalent feline awesome and far less boilerplate!
