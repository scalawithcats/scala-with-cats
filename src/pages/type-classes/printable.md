## Exercise: Printable Library

Scala provides a `toString` method
to let us convert any value to a `String`.
However, this method comes with a few disadvantages:
it is implemented for *every* type in the language,
many implementations are of limited use,
and we can't opt-in to specific implementations for specific types.

Let's define a `Printable` type class to work around these problems:

 1. Define a type class `Printable[A]` containing a single method `format`.
    `format` should accept a value of type `A` and return a `String`.

 2. Create an object `PrintableInstances`
    containing instances of `Printable` for `String` and `Int`.

 3. Define an object `Printable` with two generic interface methods:

    `format` accepts a value of type `A`
    and a `Printable` of the corresponding type.
    It uses the relevant `Printable` to convert the `A` to a `String`.

    `print` accepts the same parameters as `format` and returns `Unit`.
    It prints the `A` value to the console using `println`.

<div class="solution">
These steps define the three main components of our type class.
First we define `Printable`---the *type class* itself:

```scala mdoc:silent:reset-object
trait Printable[A] {
  def format(value: A): String
}
```

Then we define some default *instances* of `Printable`
and package them in `PrintableInstances`:

```scala mdoc:silent
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

```scala mdoc:silent
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
Let's define an "application" now that uses the library.

First we'll define a data type to represent a well-known type of furry animal:

```scala
final case class Cat(name: String, age: Int, color: String)
```

Next we'll create an implementation of `Printable` for `Cat`
that returns content in the following format:

```ruby
NAME is a AGE year-old COLOR cat.
```

Finally, use the type class on the console or in a short demo app:
create a `Cat` and print it to the console:

```scala
// Define a cat:
val cat = Cat(/* ... */)

// Print the cat!
```

<div class="solution">
This is a standard use of the type class pattern.
First we define a set of custom data types for our application:

```scala mdoc:silent
final case class Cat(name: String, age: Int, color: String)
```

Then we define type class instances for the types we care about.
These either go into the companion object of `Cat`
or a separate object to act as a namespace:

```scala mdoc:silent
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

```scala mdoc
val cat = Cat("Garfield", 41, "ginger and black")

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

```scala mdoc:silent
object PrintableSyntax {
  implicit class PrintableOps[A](value: A) {
    def format(implicit p: Printable[A]): String =
      p.format(value)

    def print(implicit p: Printable[A]): Unit =
      println(format(p))
  }
}
```

With `PrintableOps` in scope,
we can call the imaginary `print` and `format` methods
on any value for which Scala can locate an implicit instance of `Printable`:

```scala mdoc:silent
import PrintableSyntax._
```

```scala mdoc
Cat("Garfield", 41, "ginger and black").print
```

We get a compile error if we haven't defined an instance of `Printable`
for the relevant type:

```scala mdoc:fail
import java.util.Date
new Date().print
```
</div>
