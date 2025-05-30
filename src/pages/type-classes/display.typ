#import "../stdlib.typ": info, warning, solution
== Exercise: Display Library 
<sec:type-classes:display>


Scala provides a `toString` method
to let us convert any value to a `String`.
This method comes with a few disadvantages:

+ It is implemented for _every_ type in the language.
   There are situations where we don't want to be able to view data.
   For example, we may want to ensure we don't log sensitive information,
   such as passwords,
   in plain text.

+ We can't customize `toString` for types we don't control.

Let's define a `Display` type class to work around these problems:

 + Define a type class `Display[A]` containing a single method `display`.
    `display` should accept a value of type `A` and return a `String`.

 + Create instances of `Display` for `String` and `Int` 
    on the `Display` companion object.

 + On the `Display` companion object create two generic interface methods:

    - `display` accepts a value of type `A`
    and a `Display` of the corresponding type.
    It uses the relevant `Display` to convert the `A` to a `String`.

    - `print` accepts the same parameters as `display` and returns `Unit`.
    It prints the displayed `A` value to the console using `println`.

#solution[
These steps define the three main components of our type class.
First we define `Display`---the type class itself:

```scala mdoc:silent:reset-object
trait Display[A] {
  def display(value: A): String
}
```

Then we define some default instances of `Display`
and package them in the `Display` companion object:

```scala mdoc:silent
object Display {
  given stringDisplay: Display[String] with {
    def display(input: String) = input
  }

  given intDisplay: Display[Int] with {
    def display(input: Int) = input.toString
  }
}
```

Finally we extend the `Display` companion object to provide a basic interface:

```scala mdoc:invisible:reset-object
trait Display[A] {
  def display(value: A): String
}
```
```scala mdoc:silent
object Display {
  given stringDisplay: Display[String] with {
    def display(input: String) = input
  }

  given intDisplay: Display[Int] with {
    def display(input: Int) = input.toString
  }

  def display[A](input: A)(using p: Display[A]): String =
    p.display(input)

  def print[A](input: A)(using Display[A]): Unit =
    println(display(input))
}
```

Notice that the `Display` instance on `print` is anonymous.
This is allowed in Scala 3, and works because we only pass it to `display`.
]

=== Using the Library 
<sec:type-classes:cat>


The code above forms a general purpose printing library
that we can use in multiple applications.
Let's define an "application" now that uses the library.

First we'll define a data type to represent a well-known type of furry animal:

```scala
final case class Cat(name: String, age: Int, color: String)
```

Next we'll create an implementation of `Display` for `Cat`
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

#solution[
This is a standard use of the type class pattern.
First we define custom data type for our application:

```scala mdoc:silent
final case class Cat(name: String, age: Int, color: String)
```

Then we define type class instances for the types we care about.
These either go into the companion object of `Cat`
or a separate object to act as a namespace:

```scala mdoc:silent
given catDisplay: Display[Cat] = new Display[Cat] {
  def display(cat: Cat) = {
    val name  = Display.display(cat.name)
    val age   = Display.display(cat.age)
    val color = Display.display(cat.color)
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

```scala mdoc:silent
val cat = Cat("Garfield", 41, "ginger and black")
```
```scala mdoc
Display.print(cat)
```
]


=== Better Syntax


Let's make our printing library easier to use
by adding extension methods for its functionality:

 + Create an object `DisplaySyntax`.
 
 + Define `display` and `print` as extension methods on `DisplaySyntax`. 

 + Use the extension methods to print the example `Cat`
    you created in the previous exercise.

#solution[
First we define `DisplaySyntax` with the extension methods we want.

```scala mdoc:silent
object DisplaySyntax {
  extension [A](value: A)(using p: Display[A]) {
    def display: String = p.display(value)
    def print: Unit = Display.print(value)
  }
}
```

Now we can show everything working by calling `print` on a `Cat`.

```scala mdoc
import DisplaySyntax.*

Cat("Garfield", 41, "ginger and black").print
```

We get a compile error if we haven't defined an instance of `Display`
for the relevant type:

```scala mdoc:fail
import java.util.Date
new Date().print
```
]
