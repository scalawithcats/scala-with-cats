#import "../stdlib.typ": info, warning, solution
== Meet Cats


In the previous section we saw how to implement type classes in Scala.
In this section we will look at how type classes are implemented in Cats.

Cats is written using a modular structure
that allows us to choose which type classes, instances,
and interface methods we want to use.
Let's take a first look using [`cats.Show`][cats.Show] as an example.

`Show` is Cats' equivalent of
the `Printable` type class we defined in the last section.
It provides a mechanism for producing
developer-friendly console output without using `toString`.
Here's an abbreviated definition:

```scala
package cats

trait Show[A] {
  def show(value: A): String
}
```

=== Importing Type Classes


The type classes in Cats are defined in the [`cats`][cats.package] package.
We can import `Show` directly from this package:

```scala mdoc:silent
import cats.Show
```

The companion object of every Cats type class has an `apply` method
that locates an instance for any type we specify:

```scala mdoc
val showInt = Show.apply[Int]
```

Oops---that didn't work!
The `apply` method uses _implicits_ to look up individual instances,
so we'll have to bring some instances into scope.

=== Importing Default Instances 
<sec:importing-default-instances>


The [`cats.instances`][cats.instances] package
provides default instances for a wide variety of types.
We can import these as shown in the table below.
Each import provides instances of all Cats' type classes
for a specific parameter type:

- [`cats.instances.int`][cats.instances.int] provides instances for `Int`
- [`cats.instances.string`][cats.instances.string] provides instances for `String`
- [`cats.instances.list`][cats.instances.list] provides instances for `List`
- [`cats.instances.option`][cats.instances.option] provides instances for `Option`
- [`cats.instances.all`][cats.instances.all] provides all instances that are shipped out of the box with Cats

See the [`cats.instances`][cats.instances] package
for a complete list of available imports.

Let's import the instances of `Show` for `Int` and `String`:

```scala mdoc:reset:silent
import cats.Show
import cats.instances.int._    // for Show
import cats.instances.string._ // for Show

val showInt:    Show[Int]    = Show.apply[Int]
val showString: Show[String] = Show.apply[String]
```

That's better! We now have access to two instances of `Show`,
and can use them to print `Ints` and `Strings`:

```scala mdoc
val intAsString: String =
  showInt.show(123)

val stringAsString: String =
  showString.show("abc")
```

=== Importing Interface Syntax


We can make `Show` easier to use by
importing the _interface syntax_ from [`cats.syntax.show`][cats.syntax.show].
This adds an extension method called `show`
to any type for which we have an instance of `Show` in scope:

```scala mdoc:silent
import cats.syntax.show._ // for show
```

```scala mdoc
val shownInt = 123.show

val shownString = "abc".show
```

Cats provides separate syntax imports for each type class.
We will introduce these as we encounter them in later sections and chapters.

=== Importing All The Things!


In this book we will use specific imports to show you
exactly which instances and syntax you need in each example.
However, this doesn't add value in production code.
It is simpler and faster to use the following imports:

- `import cats._` imports all of Cats' type classes in one go;

- `import cats.implicits._` imports
  all of the standard type class instances
  _and_ all of the syntax in one go.


=== Defining Custom Instances 
<defining-custom-instances>


We can define an instance of `Show`
simply by implementing the trait for a given type:

```scala mdoc:silent
import java.util.Date

implicit val dateShow: Show[Date] =
  new Show[Date] {
    def show(date: Date): String =
      s"${date.getTime}ms since the epoch."
  }
```
```scala mdoc
new Date().show
```

However, Cats also provides
a couple of convenient methods to simplify the process.
There are two construction methods on the companion object of `Show`
that we can use to define instances for our own types:

```scala
object Show {
  // Convert a function to a `Show` instance:
  def show[A](f: A => String): Show[A] =
    ???

  // Create a `Show` instance from a `toString` method:
  def fromToString[A]: Show[A] =
    ???
}
```

These allow us to quickly construct instances
with less ceremony than defining them from scratch:

```scala mdoc:reset:invisible
import cats.Show
import java.util.Date
```
```scala mdoc:silent
implicit val dateShow: Show[Date] =
  Show.show(date => s"${date.getTime}ms since the epoch.")
```

As you can see, the code using construction methods
is much terser than the code without.
Many type classes in Cats provide helper methods like these
for constructing instances, either from scratch
or by transforming existing instances for other types.

=== Exercise: Cat Show


Re-implement the `Cat` application from the previous section
using `Show` instead of `Printable`.

#solution[
First let's import everything we need from Cats:
the `Show` type class,
the instances for `Int` and `String`,
and the interface syntax:

```scala mdoc:reset-object:silent
import cats.Show
import cats.instances.int._    // for Show
import cats.instances.string._ // for Show
import cats.syntax.show._      // for show
```

Our definition of `Cat` remains the same:

```scala mdoc:silent
final case class Cat(name: String, age: Int, color: String)
```

In the companion object we replace our `Printable` with an instance of `Show`
using one of the definition helpers discussed above:

```scala mdoc:silent
implicit val catShow: Show[Cat] = Show.show[Cat] { cat =>
  val name  = cat.name.show
  val age   = cat.age.show
  val color = cat.color.show
  s"$name is a $age year-old $color cat."
}
```

Finally, we use the `Show` interface syntax to print our instance of `Cat`:

```scala mdoc
println(Cat("Garfield", 38, "ginger and black").show)
```
]
