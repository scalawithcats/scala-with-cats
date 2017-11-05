## Meet Cats

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

### Importing Type Classes

The type classes in Cats are defined in the [`cats`][cats.package] package.
We can import `Show` directly from this package:

```tut:book:silent
import cats.Show
```

The companion object of every Cats type class has an `apply` method
that locates an instance for any type we specify:

```tut:book:fail
val showInt = Show.apply[Int]
```

Oops---that didn't work!
The `apply` method uses *implicits* to look up individual instances,
so we'll have to bring some instances into scope.

### Importing Default Instances {#importing-default-instances}

The [`cats.instances`][cats.instances] package
provides default instances for a wide variety of types.
We can import these as shown in the table below.
Each import provides instances of all Cats' type classes
for a specific parameter type:

------------------------------------------------------------------------------
Import                                           Parameter types
------------------------------------------------ -----------------------------
[`cats.instances.int`][cats.instances.int]       `Int`

[`cats.instances.string`][cats.instances.string] `String`

[`cats.instances.list`][cats.instances.list]     `List`

[`cats.instances.option`][cats.instances.option] `Option`

[`cats.instances.map`][cats.instances.map]       `Map` and subtypes

[`cats.instances.all`][cats.instances.all]       All instances

and so on...                                     See the [`cats.instances`][cats.instances]
                                                 package for more
------------------------------------------------------------------------------

Let's import the instances of `Show` for `Int` and `String`:

```tut:book:silent
import cats.instances.int._
import cats.instances.string._

val showInt:    Show[Int]    = Show.apply[Int]
val showString: Show[String] = Show.apply[String]
```

That's better! We now have access to two instances of `Show`,
and can use them to print `Ints` and `Strings`:

```tut:book
val intAsString: String =
  showInt.show(123)

val stringAsString: String =
  showString.show("abc")
```

### Importing Interface Syntax

We can make `Show` easier to use by
importing the *interface syntax* from [`cats.syntax.show`][cats.syntax.show].
This adds an extension method called `show`
to any type for which we have an instance of `Show` in scope:

```tut:book:silent
import cats.syntax.show._
```

```tut:book
val shownInt = 123.show

val shownString = "abc".show
```

Cats provides separate syntax imports for each type class.
We will introduce these as we encounter them in later sections and chapters.

### Importing All The Things!

In this book we will use specific imports to show you
exactly which instances and syntax you need in each example.
However, this can be time consuming for many use cases.
You should feel free to take one of the following shortcuts
to simplify your imports:

- `import cats._` imports all of Cats' type classes in one go;

- `import cats.instances.all._` imports
  all of the type class instances for the standard library in one go;

- `import cats.syntax.all._` imports all of the syntax in one go;

- `import cats.implicits._` imports
  all of the standard type class instances
  *and* all of the syntax in one go.

Most people start their files with the following imports,
reverting to more specific imports only
if they encounter naming conflicts
or problems ambiguous implicits:

```tut:book
import cats._
import cats.implicits._
```

### Defining Custom Instances {#defining-custom-instances}

We can define an instance of `Show`
simply by implementing the trait for a given type:

```tut:book:silent
import java.util.Date

implicit val dateShow: Show[Date] =
  new Show[Date] {
    def show(date: Date): String =
      s"${date.getTime}ms since the epoch."
  }
```

However, Cats also provides
a couple of convenient methods to simplfy the process.
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

These allows us to quickly construct instances
with less ceremony than defining them from scratch:

```tut:book:silent
implicit val dateShow: Show[Date] =
  Show.show(date => s"${date.getTime}ms since the epoch.")
```

As you can see, the code using construction methods
is much terser than the code without.
Many type classes in Cats provide helper methods like these
for constructing instances, either from scratch
or by transforming existing instances for other types.

### Exercise: Cat Show

Re-implement the `Cat` application from the previous section
using `Show` instead of `Printable`.

<div class="solution">
First let's import everything we need from Cats:
the `Show` type class,
the instances for `Int` and `String`,
and the interface syntax:

```tut:book:silent
import cats.Show
import cats.instances.int._
import cats.instances.string._
import cats.syntax.show._
```

Our definition of `Cat` remains the same:

```tut:book:silent
final case class Cat(name: String, age: Int, color: String)
```

In the companion object we replace our `Printable` with an instance of `Show`
using one of the definition helpers discussed above:

```tut:book:silent
implicit val catShow = Show.show[Cat] { cat =>
  val name  = cat.name.show
  val age   = cat.age.show
  val color = cat.color.show
  s"$name is a $age year-old $color cat."
}
```

Finally, we use the `Show` interface syntax to print our instance of `Cat`:

```tut:book
println(Cat("Garfield", 38, "ginger and black").show)
```
</div>

### Take Home Points

Cats type classes are defined in the [`cats`][cats.package] package.
For example, the `Show` type class is defined as [`cats.Show`][cats.Show].

Default instances are defined in the
[`cats.instances`][cats.instances] package.
There are separate objects in this package for each parameter type
(as opposed to by type class):
`cats.instances.int` for `Int`,
`cats.instances.string` for `String`, and so on.

Interface syntax is defined in the [`cats.syntax`][cats.syntax] package.
There are separate syntax imports for each type class.
For example, the syntax for `Show` is defined in
[`cats.syntax.show`][cats.syntax.show].
