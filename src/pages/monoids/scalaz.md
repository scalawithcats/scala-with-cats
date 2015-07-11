## Monoids in Scalaz

Now we've seen what a monoid is, let's look at their implementation in Scalaz. Once again we'll look at the three main aspects of the implementation: the *type class*, the *instances*, and the *interface*.

### The *Monoid* Type Class

The monoid type class is [`scalaz.Monoid`][scalaz.Monoid]. If we look at the implementation we see that `Monoid` extends `Semigroup`. A semigroup is a monoid without the identity element, leaving only `append`.

There are a few utility methods defined on `Monoid`, mostly to do with checking if an element is `zero` (assuming we have an implemenation for equality on the monoid, denoted by the `Equal` type class). These are not commonly used in practice.

### Obtaining Instances

`Monoid` follows the standard Scalaz pattern for the user interface: the companion object has an `apply` method that returns the type class instance. So if we wanted the monoid instance for `String`, and we have the correct implicits in scope, we can write the following:

~~~ scala
Monoid[String].append("Hi ", "there")
~~~

which is equivalent to

~~~ scala
Monoid.apply[String].append("Hi ", "there")
~~~

### Default Instances

The type class instances for `Monoid` are organised under `scalaz.std` in the standard way described in [Chapter 1](#importing-default-instances). For example, if we want to pull in instances for `String` we `import scalaz.std.string._`:

~~~ scala
import scalaz.Monoid
import scalaz.std.string._

val instance = Monoid[String]
instance.append("Monoids FTW!", instance.zero)
~~~

Refer back to [Chapter 1](#importing-default-instances) for a more comprehensive list of imports.

### Instances for Custom Types

There is a useful helper method on the `Monoid` companion object to help us declare instances for our own types:

~~~ scala
val bitwiseXorInstance: Monoid[Int] =
  Monoid.instance[Int](_ ^ _, 0)
~~~

### *Monoid* Syntax {#monoid-syntax}

We access the monoid syntax by importing `scalaz.syntax.monoid._`. This provides:

- the `|+|` operator for appending two values for which there is a monoid instance; and
- the `mzero` method to access the identity element for a monoid.

When we use `mzero` we usually have to specify a type to avoid ambiguity:

~~~ scala
import scalaz.syntax.monoid._
import scalaz.std.string._
import scalaz.std.anyVal._

val stringResult = "Hi " |+| "there" |+| mzero[String]
// stringResult: String = Hi there

val intResult = 1 |+| 2 |+| mzero[Int]
// intResult: Int = 3
~~~

### Exercise: Adding All The Things

The cutting edge *SuperAdder v3.5a-32* is the world's first choice for adding together numbers. The main function in the program has signature `def add(items: List[Int]): Int`. In a tragic accident this code is deleted! Rewrite the method and save the day!

<div class="solution">
We can write the addition as a simple `foldLeft` using `0` and the `+` operator:

~~~ scala
def add(items: List[Int]): Int =
  items.foldLeft(0){ _ + _ }
~~~

We can alternatively write the fold using `Monoids`, although there's not a compelling use case for this yet:

~~~ scala
import scalaz.Monoid
import scalaz.syntax.monoid._

def add(items: List[Int]): Int =
  items.foldLeft(mzero[Int]){ _ |+| _ }
~~~
</div>

Well done! SuperAdder's market share continues to grow, and now there is demand for additional functionality. People now want to add `List[Option[Int]]`. Change `add` so this is possible. The SuperAdder code base is of the highest quality, so make sure there is no code duplication:

<div class="solution">
Now there is a use case for `Monoids`. We need a single method that adds `Ints` and instances of `Option[Int]`. We can write this as a generic method that accepts an implicit `Monoid` as a parameter:

~~~ scala
import scalaz.Monoid
import scalaz.syntax.monoid._

def add[A](items: List[A])(implicit monoid: Monoid[A]): A =
  items.foldLeft(mzero[A]){ _ |+| _ }
~~~

We can optionally use Scala's *context bound* syntax to write the same code in a friendlier way:

~~~ scala
def add[A: Monoid](items: List[A]): A =
  items.foldLeft(mzero[A]){ _ |+| _ }
~~~
</div>

SuperAdder is entering the POS (point-of-sale, not the other POS) market. Now we want to add up `Orders`:

~~~ scala
case class Order(totalCost: Double, quantity: Double)
~~~

We need to release this code really soon so we can't make any modifications to `add`. Make it so!

<div class="solution">
Easy---we simply define a monoid instance for `Order`!
Notice the type signature of `append`---the second argument must be call-by-name:

~~~ scala
object Order {
  implicit val monoid: Monoid[Order] = new Monoid[Order] {
    def append(o1: Order, o2: => Order) =
      Order(o1.totalCost + o2.totalCost, o1.quantity + o2.quantity)

    def zero = Order(0, 0)
  }
}
~~~
</div>
