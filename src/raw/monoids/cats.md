## Monoids in Cats

Now we've seen what a monoid is, let's look at their implementation in Cats. Once again we'll look at the three main aspects of the implementation: the *type class*, the *instances*, and the *interface*.

### The *Monoid* Type Class

The monoid type class is [`cats.Monoid`][cats.Monoid]. If we look at the implementation we see that `Monoid` extends `Semigroup`. A semigroup is a monoid without the identity element, leaving only `combine`.

There are a few utility methods defined on `Monoid`, mostly to do with checking if an element is `empty` (assuming we have an implemenation for equality on the monoid, denoted by the `Equal` type class). These are not commonly used in practice.

### Obtaining Instances

`Monoid` follows the standard Cats pattern for the user interface: the companion object has an `apply` method that returns the type class instance. So if we wanted the monoid instance for `String`, and we have the correct implicits in scope, we can write the following:

```tut:book
import cats.Monoid
import cats.std.string._

Monoid[String].combine("Hi ", "there")
```

which is equivalent to

```tut:book
Monoid.apply[String].combine("Hi ", "there")
```

### Default Instances

The type class instances for `Monoid` are organised under `cats.std` in the standard way described in [Chapter 1](#importing-default-instances). For example, if we want to pull in instances for `String` we import from [`cats.std.string`][cats.std.string]:

```tut:book
import cats.Monoid
import cats.std.string._

val instance = Monoid[String]
instance.combine("Monoids FTW!", instance.empty)
```

Refer back to [Chapter 1](#importing-default-instances) for a more comprehensive list of imports.

### *Monoid* Syntax {#monoid-syntax}

Cats provides syntax for the `combine` method in the form of the `|+|` operator.
Because `combine` technically comes from `Semigroup`,
we access the syntax by importing from [`cats.syntax.semigroup`][cats.syntax.semigroup]:

```tut:book
import cats.syntax.semigroup._
import cats.std.string._

val stringResult = "Hi " |+| "there" |+| Monoid[String].empty

import cats.std.int._

val intResult = 1 |+| 2 |+| Monoid[Int].empty
```

### Exercise: Adding All The Things

The cutting edge *SuperAdder v3.5a-32* is the world's first choice for adding together numbers. The main function in the program has signature `def add(items: List[Int]): Int`. In a tragic accident this code is deleted! Rewrite the method and save the day!

<div class="solution">
We can write the addition as a simple `foldLeft` using `0` and the `+` operator:

```tut:book
def add(items: List[Int]): Int =
  items.foldLeft(0)(_ + _)
```

We can alternatively write the fold using `Monoids`, although there's not a compelling use case for this yet:

```tut:book
import cats.Monoid
import cats.syntax.semigroup._

def add(items: List[Int]): Int =
  items.foldLeft(Monoid[Int].empty)(_ |+| _)
```
</div>

Well done! SuperAdder's market share continues to grow, and now there is demand for additional functionality. People now want to add `List[Option[Int]]`. Change `add` so this is possible. The SuperAdder code base is of the highest quality, so make sure there is no code duplication!

<div class="solution">
Now there is a use case for `Monoids`. We need a single method that adds `Ints` and instances of `Option[Int]`. We can write this as a generic method that accepts an implicit `Monoid` as a parameter:

```tut:book
import cats.Monoid
import cats.syntax.semigroup._

def add[A](items: List[A])(implicit monoid: Monoid[A]): A =
  items.foldLeft(monoid.empty)(_ |+| _)
```

We can optionally use Scala's *context bound* syntax to write the same code in a friendlier way:

```tut:book
def add[A: Monoid](items: List[A]): A =
  items.foldLeft(Monoid[A].empty)(_ |+| _)
```

We can use this code to add values of type `Int` and `Option[Int]` as requested:

```tut:book
import cats.std.int._

add(List(1, 2, 3))

import cats.std.option._

add(List(Some(1), None, Some(2), None, Some(3)))
```

Note that if we try to add a list consisting entirely of `Some` values,
we get a compile error:

```tut:fail
add(List(Some(1), Some(2), Some(3)))
```

This happens because the inferred type of the list is `List[Some[Int]]`,
while Cats will only generate a `Monoid` for `Option[Int]`.
We'll see how to get around this in a moment.
</div>

SuperAdder is entering the POS (point-of-sale, not the other POS) market.
Now we want to add up `Orders`:

```tut:book
case class Order(totalCost: Double, quantity: Double)
```

We need to release this code really soon so we can't make any modifications to `add`.
Make it so!

<div class="solution">
Easy---we simply define a monoid instance for `Order`!

```tut:book:silent
object Order {
  implicit val monoid: Monoid[Order] = new Monoid[Order] {
    def combine(o1: Order, o2: Order) =
      new Order(o1.totalCost + o2.totalCost, o1.quantity + o2.quantity)

    def empty = new Order(0, 0)
  }
}
```
</div>
