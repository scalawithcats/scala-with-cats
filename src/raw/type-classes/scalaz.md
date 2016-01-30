## Meet Scalaz

In the previous section we saw how to implement type classes in Scala. In this section we will look at how type classes are implemented in Scalaz.

Scalaz is written using a modular code structure that allows us to choose which type classes, instances, and interface methods we want to use. Let's take a first look using [scalaz.Show] as an example.

`Show` is an equivalent of the `Printable` type class we defined in the last section. It provides a mechanism for producing developer-friendly console output without using `toString`.

`Show` defines two methods of interest:

 - `def shows(value: A): String`---returns a `String` representation of `A`; and

 - `def show(value: A): Cord`---similar to `shows` but returns a [scalaz.Cord]---a data structure supporting efficient text manipulation.

### Importing Type Classes

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

Oops---that didn't work! The `apply` method uses *implicits* to look up individual instances, so we'll have to bring some instances into scope.

### Importing Default Instances {#importing-default-instances}

The [scalaz.std] package provides default instances for a wide variety of types. We can import these from the [scalaz.std] package as shown in the table below. Each import provides instances for a wide variety of type classes and one or several parameter types:

------------------------------------------------------------------------------
Import                                   Parameter types
---------------------------------------- -------------------------------------
[`scalaz.std.anyVal`][scalaz.std.anyVal] `Int`, `Double`, `Boolean`, etc...

[`scalaz.std.string`][scalaz.std.string] `String`

[`scalaz.std.list`][scalaz.std.list]     `List`

[`scalaz.std.option`][scalaz.std.option] `Option`

[`scalaz.std.map`][scalaz.std.map]       `Map` and subtypes

[`scalaz.std.tuple`][scalaz.std.tuple]   `Tuple1` to `Tuple8`

and so on...                             See the [`scalaz.std`][scalaz.std]
                                         package for more
------------------------------------------------------------------------------

Let's import the instances of `Show` for `Int` and `String`:

~~~ scala
import scalaz.std.anyVal._
import scalaz.std.string._

val intShow:    Show[Int]    = Show.apply[Int]
val stringShow: Show[String] = Show.apply[String]
~~~

That's better! We now have access to two instances of `Show`, and can use them to print `Ints` and `Strings`:

~~~ scala
val intAsString: String =
  intShow.shows(123)
// res0: String = "123"

val stringAsString: String =
  stringShow.shows("abc")
// res1: String = "\"abc\""
~~~

Notice that the output for `String` is wrapped in double quotes like a Scala string literal. This hints at `Show's` intended purpose---to provide useful debugging output for developers.

### Importing Interface Syntax

We can make `Show` easier to use by importing the *interface syntax* from [scalaz.syntax.show]. This adds `show`, `shows`, `print`, and `println` methods to any type for which we have an instance of `Show` in scope:

~~~ scala
import scalaz.syntax.show._

val shownInt = 123.shows
// shownInt: String = "123"

val shownString = "abc".shows
// shownString: String = "\"abc\""

123.println
// 123

"abc".println
// "abc"
~~~

Scalaz provides separate syntax imports for each type class. We will introduce these as we encounter them in later sections and chapters.

### Defining Custom Instances {#defining-custom-instances}

There are two methods for defining instances on the companion object of `Show`:

 - `def show[A](func: A => Cord): Show[A]` defines a `Show[A]` in terms of its `show` method; and
 - `def shows[A](func: A => String): Show[A]` defines a `Show[A]` in terms of its `shows` method.

In each case, Scalaz defines one of the two methods of `Show` in terms of `func` and provides a default definition of the other method:

~~~ scala
import java.util.Date

implicit val dateShow = Show.shows[Date] { date =>
  s"It's been ${date.getTime} milliseconds since the epoch."
}
~~~

These definition helpers exist for `Show` but don't make sense for all Scalaz type classes. We will introduce further helpers as we come to then.

### Exercise: Cat Show

Re-implement the `Cat` application from the previous section using `Show` instead of `Printable`.

<div class="solution">

First let's import everything we need from Scalaz: the `Show` type class, the instances for `Int` and `String`, and the interface syntax:

~~~ scala
import scalaz.Show
import scalaz.std.anyVal._
import scalaz.std.string._
import scalaz.syntax.show._
~~~

Our definition of `Cat` remains the same:

~~~ scala
case class Cat(name: String, age: Int, color: String)
~~~

In the companion object we replace our `Printable` with an instance of `Show`. We use one of the definition helpers discussed [above](#defining-custom-instances):

~~~ scala
object Cat {
  implicit val catShow = Show.shows[Cat] { cat =>
    val name = cat.name.show
    val age  = cat.age.show
    val color = cat.color.show
    s"$name is a $age year-old $color cat."
  }
}
~~~

Finally, we use the `Show` interface syntax to print our instance of `Cat`:

~~~ scala
object Main extends App {
  Cat("Garfield", 35, "ginger and black").println
  // prints '"Garfield" is a 35 year-old "ginger and black" cat.'
}
~~~
</div>

### Take Home Points

Scalaz type classes are defined in the [scalaz] package. For example, the `Show` type class is defined as [scalaz.Show].

Default instances are defined in the [scalaz.std] package. Imports are organized by parameter type (as opposed to by type class).

Interface syntax is defined in the [scalaz.syntax] package. There are separate syntax imports for each type class. For example, the syntax for `Show` is defined in [scalaz.syntax.show].
