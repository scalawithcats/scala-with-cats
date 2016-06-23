## Meet Cats

In the previous section we saw how to implement type classes in Scala. In this section we will look at how type classes are implemented in Cats.

Cats is written using a modular code structure that allows us to choose which type classes, instances, and interface methods we want to use. Let's take a first look using [cats.Show] as an example.

`Show` is an equivalent of the `Printable` type class we defined in the last section. It provides a mechanism for producing developer-friendly console output without using `toString`.

`Show` defines one method of interest:

```scala
def show(value: A): String
```

### Importing Type Classes

The type classes in Cats are defined in the [cats] package. We can import `Show` directly from this package:

```tut:book
import cats.Show
```

The companion object of each Cats type class has an `apply` method that locates an instance for any type we specify:

```tut:fail:book
val showInt = Show.apply[Int]
```

Oops---that didn't work! The `apply` method uses *implicits* to look up individual instances, so we'll have to bring some instances into scope.

### Importing Default Instances {#importing-default-instances}

The [cats.instances] package provides default instances for a wide variety of types. We can import these from the [cats.instances] package as shown in the table below. Each import provides instances for a wide variety of type classes and one or several parameter types:

------------------------------------------------------------------------------
Import                                   Parameter types
---------------------------------------- -------------------------------------
[`cats.instances.int`][cats.instances.int]           `Int`

[`cats.instances.string`][cats.instances.string]     `String`

[`cats.instances.list`][cats.instances.list]         `List`

[`cats.instances.option`][cats.instances.option]     `Option`

[`cats.instances.map`][cats.instances.map]           `Map` and subtypes

[`cats.instances.all`][cats.instances.all]           All instances for the standard library

and so on...                             See the [`cats.instances`][cats.instances]
                                         package for more
------------------------------------------------------------------------------

<div class="callout callout-info">
Most people use `import cats.implicits._` to bring all instances into scope at the same time.
In this book we will use specific imports to show you exactly what instances we need for the code to compile.
Don't feel you need to do this in your code.
</div>

Let's import the instances of `Show` for `Int` and `String`:

```tut:book
import cats.instances.int._
import cats.instances.string._

val showInt:    Show[Int]    = Show.apply[Int]
val showString: Show[String] = Show.apply[String]
```

That's better! We now have access to two instances of `Show`, and can use them to print `Ints` and `Strings`:

```tut:book
val intAsString: String =
  showInt.show(123)

val stringAsString: String =
  showString.show("abc")
```

Notice that the output for `String` is wrapped in double quotes like a Scala string literal.
This hints at `Show's` intended purpose---to provide useful debugging output for developers.

### Importing Interface Syntax

We can make `Show` easier to use by importing the *interface syntax* from [cats.syntax.show].
This adds a `show` method to any type for which we have an instance of `Show` in scope:

```tut:book
import cats.syntax.show._

val shownInt = 123.show

val shownString = "abc".show
```

Cats provides separate syntax imports for each type class.
We will introduce these as we encounter them in later sections and chapters.

### Defining Custom Instances {#defining-custom-instances}

There are two methods for defining instances on the companion object of `Show`:

```scala
// defined a `Show[A]` in terms of its `show` method
def show[A](f: A => String): Show[A]

// define a `Show[A]` in terms of its `toString` method
def fromToString[A]: Show[A]
```

This allows us to quickly construct instances of `Show`.

```tut:book
import java.util.Date

implicit val dateShow = Show.show[Date] { date =>
  s"It's been ${date.getTime} milliseconds since the epoch."
}
```

These definition helpers exist for `Show` but don't make sense for all Cats type classes.
We will introduce further helpers as we come to then.

### Exercise: Cat Show

Re-implement the `Cat` application from the previous section using `Show` instead of `Printable`.

<div class="solution">

First let's import everything we need from Cats: the `Show` type class,
the instances for `Int` and `String`, and the interface syntax:

```tut:book
import cats.Show
import cats.instances.int._
import cats.instances.string._
import cats.syntax.show._
```

Our definition of `Cat` remains the same:

```scala
final case class Cat(name: String, age: Int, color: String)
```

In the companion object we replace our `Printable` with an instance of `Show`.
We use one of the definition helpers discussed [above](#defining-custom-instances):

```scala
object Cat {
  implicit val catShow = Show.show[Cat] { cat =>
    val name = cat.name.show
    val age  = cat.age.show
    val color = cat.color.show
    s"$name is a $age year-old $color cat."
  }
}
```

```tut:silent
object cat {
  final case class Cat(name: String, age: Int, color: String)
  object Cat {
    implicit val catShow = Show.show[Cat] { cat =>
      val name = cat.name.show
      val age  = cat.age.show
      val color = cat.color.show
      s"$name is a $age year-old $color cat."
    }
  }
}
import cat._
```

Finally, we use the `Show` interface syntax to print our instance of `Cat`:

```tut:book
object Main extends App {
  println(Cat("Garfield", 35, "ginger and black").show)
  // prints '"Garfield" is a 35 year-old "ginger and black" cat.'
}
```
</div>

### Take Home Points

Cats type classes are defined in the [`cats`][cats] package.
For example, the `Show` type class is defined as [`cats.Show`][cats.Show].

Default instances are defined in the [`cats.instances`][cats.instances] package.
Imports are organized by parameter type (as opposed to by type class).

Interface syntax is defined in the [`cats.syntax`][cats.syntax] package.
There are separate syntax imports for each type class.
For example, the syntax for `Show` is defined in [`cats.syntax.show`][cats.syntax.show].
