## Meet Scalaz

In the previous section we saw how to implement type classes in Scala. In this section we will look at how type classes are implemented in Scalaz.

### The Structure of Scalaz

Scalaz is written using a modular code structure that allows us to choose which type classes, instances, and interface methods we want to use. Let's take a first look using [scalaz.Show] as an example.

`Show` is an equivalent of the `Printable` type class we defined in the last section. It provides a mechanism for producing developer-friendly console output without using `toString`.

`Show` defines two methods of interest:

 - `def shows(value: A): String` -- returns a `String` representation of `A`;

 - `def show(value: A): Cord` -- similar to `shows` but returns a [scalaz.Cord] -- a data structure supporting efficient text manipulation.

#### Type Classes

The type classes in Scalaz are defined in the [scalaz] package. We can import `Show` directly from this package:

~~~ scala
import scalaz.Show
~~~

The companion object of each Scalaz type class has an `apply` method that locates an instance for any type we specify:

~~~ scala
val intShow = Show.apply[Int]
// compile error:
// could not find implicit value for parameter e: scalaz.Show[Int]
~~~

Oops - that didn't work! The `apply` method uses *implicits* to look up individual instances, so we'll have to bring some instances into scope.

#### Importing Default Instances

The [scalaz.std] package provides default instances for a wide variety of types. We can import these from the [scalaz.std] package as shown in the table below. Each import provides instances for a wide variety of type classes and one or several parameter types:

-------------------------------------------------------------------------
Import                         Parameter types
------------------------------ ------------------------------------------
[scalaz.std.anyVal]            `Int`, `Double`, `Boolean`, etc...

[scalaz.std.string]            `String`

[scalaz.std.list]              `List`

[scalaz.std.option]            `Option`

[scalaz.std.map]               `Map` and subtypes

[scalaz.std.tuple]             `Tuple1` to `Tuple8`

and so on...                   and so on...
-------------------------------------------------------------------------

Let's import the instances of `Show` for `Int` and `String`:

~~~ scala
import scalaz.std.anyVal._
import scalaz.std.string._

val intShow    : Show[Int]    = Show.apply[Int]
val stringShow : Show[String] = Show.apply[String]
~~~

That's better! We now have access to two instances of `Show`, and can use them to print `Ints` and `Strings`:

~~~ scala
val intAsString: String =
  intShow.shows(123)
  // == "123"

val stringAsString: String =
  stringShow.shows("abc")
  // == "\"abc\""
~~~

Notice that the output for `String` is wrapped in double quotes like a Scala string literal. This hints at `Show's` intended purpose -- to provide useful debugging output for developers.

#### Interface Syntax

We can make `Show` easier to use by importing the *interface syntax* from [scalaz.syntax.show]. This adds `show` and `shows` methods to any type for which we have an instance of `Show` in scope:

~~~ scala
import scalaz.syntax.show._

val shownInt    = 123.shows   // == "123"
val shownString = "abc".shows // == "\"abc\""
~~~

Scalaz provides separate syntax imports for each type class. We will introduce these as we encounter them in later sections and chapters.

#### Defining Custom Instances

There are two methods for defining instances on the companion object of `Show`:

 - `def show[A](func: A => Cord): Show[A]` defines a `Show[A]` in terms of its `show` method;
 - `def shows[A](func: A => String): Show[A]` defines a `Show[A]` in terms of its `shows` method.

In each case, Scalaz defines one of the two methods of `Show` in terms of `func` and provides a default definition of the other method:

~~~ scala
import java.util.Date

implicit val dateShow = Show.shows { date =>
  s"It's been ${date.getTime} milliseconds since the epoch."
}
~~~

### Exercises

Re-implement the `Cat` application from the previous section using `Show` instead of `Printable`.

<div class="solution">
~~~ scala
import scalaz.Show
import scalaz.std.anyVal._
import scalaz.std.string._
import scalaz.syntax.show._

case class Cat(name: String, age: Int, color: String)

object Cat {
  implicit val catShow = Show.shows[Cat] { cat =>
    val name = cat.name.show
    val age  = cat.age.show
    val color = cat.color.show
    s"$name is a $age year-old $color cat."
  }
}

object Main extends App {
  Cat("Garfield", 35, "ginger and black").println
  // prints '"Garfield" is a 35 year-old "ginger and black" cat.'
}
~~~
</div>

### Take Home Points

Scalaz type classes are defined in the [scalaz] package. For example, the `Show` type class is defined as [scalaz.Show].

Default instances are defined in the [scalaz.std] package. Imports are organized by parameter type (as opposed to type class).

Interface syntax is defined in the [scalaz.syntax] package. There are separate syntax imports for each type class. For example, the syntax for `Show` is defined in [scalaz.syntax.show].
