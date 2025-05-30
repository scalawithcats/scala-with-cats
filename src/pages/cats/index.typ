#import "../stdlib.typ": info, warning, solution
= Using Cats 
<sec:cats>


In this Chapter we'll learn how to use the #link("https://typelevel.org/cats")[Cats] library.
Cats provides two main things: type classes and their instances, and some useful data structures.
Our focus will mostly be on the type classes, though we will touch on the data structures where appropriate.


== Quick Start


The easiest, and recommended, way to use Cats is to add the following imports:

```scala mdoc:silent
import cats.*
import cats.syntax.all.*
```

The first import adds all the type classes 
(and makes their instances available, as they are found in the companion objects.)
The second import adds the syntax helpers,
which makes the type classes easier to work with.
Note we don't need to `import cats.{*, given}` as, at the time of writing, Cats is written in Scala 2 style (using `implicits`) and these are imported by the wildcard import.

If we want use some of Cats' datastructures, we also need to add

```scala mdoc:silent
import cats.data.*
```


== Using Cats


Let's now see how we work with Cats, 
using [`cats.Show`][cats.Show] as an example.

`Show` is Cats' equivalent of
the `Display` type class we defined in @sec:type-classes:display.
It provides a mechanism for producing
developer-friendly console output without using `toString`.
Here's an abbreviated definition:

```scala
package cats

trait Show[A] {
  def show(value: A): String
}
```

The easiest way to use `Show` is with the wildcard import above.
However, we can also import `Show` directly from the [cats][cats.package] package:

```scala mdoc:silent
import cats.Show
```

The companion object of every Cats type class has an `apply` method
that locates an instance for any type we specify:

```scala mdoc:silent
val showInt = Show.apply[Int]
```

Once we have an instance we can call methods on it.

```scala mdoc
showInt.show(42)
```

More common, however, is to use the syntax or extension methods,
which we imported with `import cats.syntax.all.*`.
In the case of `Show`, an extension method `show` is defined.

```scala mdoc
42.show
```

If, for some reason, we wanted just the syntax for `show`,
we could import [`cats.syntax.show`][cats.syntax.show].

```scala mdoc:silent
import cats.syntax.show.* // for show
```


=== Defining Custom Instances 
<defining-custom-instances>


We can define an instance of `Show`
simply by implementing the trait for a given type:

```scala mdoc:silent
import java.util.Date

given dateShow: Show[Date] with 
  def show(date: Date): String =
    s"${date.getTime}ms since the epoch."
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
given dateShow: Show[Date] =
  Show.show(date => s"${date.getTime}ms since the epoch.")
```

As you can see, the code using construction methods
is much terser than the code without.
Many type classes in Cats provide helper methods like these
for constructing instances, either from scratch
or by transforming existing instances for other types.


==== Exercise: Cat Show


Re-implement the `Cat` application from @sec:type-classes:cat
using `Show` instead of `Display`.

Using this data type to represent a well-known type of furry animal:

```scala
final case class Cat(name: String, age: Int, color: String)
```

create an implementation of `Display` for `Cat`
that returns content in the following format:

```ruby
NAME is a AGE year-old COLOR cat.
```

Then use the type class on the console or in a short demo app:
create a `Cat` and print it to the console:

```scala
// Define a cat:
val cat = Cat(/* ... */)

// Print the cat!
```


#solution[
First let's import everything we need from Cats.

```scala mdoc:reset-object:silent
import cats.*
import cats.syntax.all.*
```

Our definition of `Cat` remains the same:

```scala mdoc:silent
final case class Cat(name: String, age: Int, color: String)
```

In the companion object we replace our `Display` instance with an instance of `Show`
using one of the definition helpers discussed above:

```scala mdoc:silent
given catShow: Show[Cat] = Show.show[Cat] { cat =>
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

