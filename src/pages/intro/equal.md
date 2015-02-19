## Example: *Equal*

We will finish off this chapter by looking at another useful type class: [scalaz.Equal].

[scalaz.Equal]: http://docs.typelevel.org/api/scalaz/stable/7.0.4/doc/#scalaz.Equal

### Equality, Liberty, and Fraternity

We can use `Equal` to define type-safe equality between instances of any given type:

~~~ scala
package scalaz

trait Equal[A] {
  def equal(a: A, b: A): Boolean
  // other concrete methods...
}
~~~

The interface syntax, defined in [scalaz.syntax.equal], provides two methods for performing type-safe equality checks provided there is an instance `Equal[A]` in scope:

 - `===` compares two objects for equality;
 - `=/=` compares two objects for inequality.

[scalaz.syntax.equal]: http://docs.typelevel.org/api/scalaz/stable/7.0.4/doc/#scalaz.syntax.Syntaxes$equal$

### Comparing Ints

Let's look at a few examples. First we import the type class:

~~~ scala
import scalaz.Equal
~~~

Now let's grab an instance for `Int`:

~~~ scala
import scalaz.std.anyVal._

val intEqual = Equal[Int]
~~~

We can use `intEqual` directly to test for equality:

~~~ scala
intEqual.equal(123, 123)   // true
intEqual.equal(123, 234)   // false
intEqual.equal(123, "234") // compile error
~~~

We can also import the interface syntax in [scalaz.syntax.equal] to use the `===` and `=/=` methods:

~~~ scala
import scala.syntax.equal._

123 === 123 // true
123 =/= 234 // true
123 === "abc" // compile error
~~~

[scalaz.syntax.equal]: http://docs.typelevel.org/api/scalaz/stable/7.0.4/doc/#scalaz.syntax.Syntaxes$equal$

### Comparing Options

Let's look at a more interesting example -- `Option[Int]`. To do this we need to import instances of `Equal` for `Option` as well as `Int`:

~~~ scala
import scalaz.std.anyVal._
import scalaz.std.option._

Some(1) === None
// console error: value === is not a member of Some[Int]
// Some(1) === None
//         ^
~~~

We have received a compile error here because `Equal` is invariant. The type class instances we have in scope are for `Int` and `Option[Int]`, not `Some[Int]`. To fix the issue we have to re-type the arguments as `Option[Int]`:

~~~ scala
(Some(1) : Option[Int]) === (None : Option[Int])
~~~

We can do this in a friendlier fashion using special `Option` syntax from Scalaz:

~~~ scala
some(1) === none[Int] // false
some(1) =/= none[Int] // true
~~~

### Comparing Custom Types

We can define our own instances of `Equal` using the `Equal.equal` method, which accepts a function of type `(A, A) => Boolean` and returns an `Equal[A]`:

~~~ scala
import java.util.Date

implicit val dateEqual = Equal.equal[Date] { (date1, date2) =>
  date1.getTime === date2.getTime
}
~~~

### Exercises

Implement an instance of `Equal` for our running `Cat` example:

~~~ scala
case class Cat(name: String, age: Int, owner: Option[String])
~~~

Use this to compare the following pairs of objects for equality and inequality:

~~~ scala
val cat1 = Cat("Garfield",   35, "orange and black")
val cat2 = Cat("Heathcliff", 30, "orange and black")

val optionCat1: Option[Cat] = Some(cat1)
val optionCat2: Option[Cat] = None
~~~

<div class="solution">
~~~ scala
import scalaz.Equal
import scalaz.syntax.equal._

case class Cat(name: String, age: Int, color: String)

object Cat {
  import scalaz.std.anyVal._
  import scalaz.std.string._

  implicit val catEqual = Equal.equal[Cat] { (cat1, cat2) =>
    (cat1.name  === cat2.name ) &&
    (cat1.age   === cat2.age  ) &&
    (cat1.color === cat2.color)
  }
}

object Main extends App {
  val cat1 = Cat("Garfield",   35, "orange and black")
  val cat2 = Cat("Heathcliff", 30, "orange and black")

  val optionCat1: Option[Cat] = Some(cat1)
  val optionCat2: Option[Cat] = None

  println("cat1 === cat2 : " + (cat1 === cat2))
  println("cat1 =/= cat2 : " + (cat1 =/= cat2))

  import scalaz.std.option._

  println("optionCat1 === optionCat2 : " + (optionCat1 === optionCat2))
  println("optionCat1 =/= optionCat2 : " + (optionCat1 =/= optionCat2))
}
~~~
</div>

### Take Home Points

In this section we introduced a new type class -- [scalaz.Equal] -- that lets us perform type-safe equality checks:

 - we create an instance `Equal[A]` to implement equality-testing functionality for `A`.

 - [scalaz.syntax.equal] provides two methods of interest -- `===` for testing equality and `=/=` for testing inequality.

Because `Equal` is invariant, we have to be precise about the types of the values we use as arguments. We sometimes need add type hints to ensure the compiler that everything is ok.

[scalaz.Equal]: http://docs.typelevel.org/api/scalaz/stable/7.0.4/doc/#scalaz.Equal
[scalaz.syntax.equal]: http://docs.typelevel.org/api/scalaz/stable/7.0.4/doc/#scalaz.syntax.Syntaxes$equal$
