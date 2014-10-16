---
layout: page
title: Monoids in Scalaz
---

Now we've seen what a monoid is, let's look at their implementation in Scalaz. The four main points around any type class implementation are:

- the type class trait;
- the user interface;
- the type class instances; and
- any convenience syntax

We'll address each in turn.


## The Monoid Type Class

The monoid type class is [`scalaz.Monoid`](http://docs.typelevel.org/api/scalaz/nightly/index.html#scalaz.Monoid). If you look at the implementation you'll see that `Monoid` extends `Semigroup`. A semigroup is a monoid without the identity element, leaving only `append`.

There are a few utility methods defined on `Monoid`, mostly to do with checking if an element is `zero` (assuming we have an implemenation for equality on the monoid, denoted by the `Equal` type class). In my experience they are little used in practice.


## The User Interface

`Monoid` follows the standard Scalaz pattern for the user interface: the companion object has an `apply` method that returns the type class instance. So if we wanted the monoid instance for `String`, and we have the correct implicits in scope, we can write

~~~ scala
Monoid[String].append("Hi ", "there")
~~~

which is equivalent to

~~~ scala
Monoid.apply[String].append("Hi ", "there")
~~~

There is another useful method on the `Monoid` companion object that creates an instance of the `Monoid` type class.

~~~ scala
Monoid.instance[Int](_ * _, 1)
~~~


## Monoid Instances

The type class instances are organised in the standard way for Scalaz. Instances for types in the standard libary are found under `scalaz.std`. So if we wanted to pull in the instances for `String` we would import `scalaz.std.string._`. Here is a complete program using the monoid instance for `String`.

~~~ scala
import scalaz.Monoid
import scalaz.std.string._

val instance = Monoid[String]
instance.append("Monoids FTW!", instance.zero)
~~~

A non-exhaustive list of instances includes:

- `Unit`, `Boolean` and `Int` in `scalaz.std.anyVal`;
- `String` in `scalaz.std.string`;
- `List` in `scalaz.std.list`;
- `Set` in `scalaz.std.set`;
- `Option` in `scalaz.std.option`; and
- tuple types in `scalaz.std.tuple`.


## Monoid Syntax

We access the monoid syntax by importing `scalaz.syntax.monoid._`. This provides:

- the `|+|` operator for appending two values for which there is a monoid instance; and
- the `mzero` method to access the identity element for a monoid.

When we use `mzero` we usually have to specify a type to avoid ambiguity.

~~~ scala
import scalaz.syntax.monoid._
import scalaz.std.string._
import scalaz.std.anyVal._

"Hi " |+| "there" |+| mzero[String]
1 |+| 2 |+| mzero[Int]
~~~

## Exercises

Doing this exercises will give you experience using the Scalaz monoid API.

### Adding All The Things

The cutting edge SuperAdder v3.5a-32, the world's first choice for adding together numbers. The main function in the program has signature `def add(items: List[Int]): Int`. In a tragic accident this code is deleted! Rewrite the method and save the day!

<div class="solution">
~~~ scala
def add(items: List[Int]): Int =
  items.foldLeft(0){ _ + _ }
~~~
</div>

Well dome! SuperAdder's market share continues to grow, and now there is demand for additional functionality. People now want to add `List[Option[Int]]`. Change `add` so this is possible. The SuperAdder code base is of the highest quality, so make sure there is no code duplication.

<div class="solution">
Hey, we can use a monoid for this!

~~~ scala
import scalaz.Monoid
import scalaz.syntax.monoid._

def add[A: Monoid](items: List[A]): A =
    items.foldLeft(mzero[A]){ _ |+| _ }
~~~
</div>

SuperAdder is entering the POS (point-of-sale, not the other POS) market. Now we want to add up

~~~ scala
case class Order(unitCost: Int, quantity: Int)
~~~

but we need to release this code really soon so we can't make any modifications to `add`. Make it so!

<div class="solution">
Easy-peasy.

~~~ scala
object Order {
  val zero = Order(0, 0)
  def add(o1: Order, o2: Order): Order =
    Order(o1,unitCost
  implict val order = Monoid.instance[Order](zero, (a, b) =>
}
~~~
</div>
