#import "../stdlib.typ": info, warning, solution
== Examples of Codata


Let's make this discussion concrete by looking at some examples of codata implemented in Scala.
We'll start with the set example we described earlier, with the operations `contains`, `insert`, and `union`. In Scala we can define this as a `trait`.

```scala mdoc:silent
trait Set[A] {
  
  /** True if this set contains the given element */
  def contains(elt: A): Boolean
  
  /** Construct a new set containing the given element */
  def insert(elt: A): Set[A]
  
  /** Construct the union of this and that set */
  def union(that: Set[A]): Set[A]
}
```

Now we can create some implementations. A very simple representation is a list of elements.
Implementing this is straightforward.

```scala mdoc:silent
final class ListSet[A](elements: List[A]) extends Set[A] {

  def contains(elt: A): Boolean =
    elements.contains(elt)

  def insert(elt: A): Set[A] =
    ListSet(elt :: elements)

  def union(that: Set[A]): Set[A] =
    elements.foldLeft(that) { (set, elt) => set.insert(elt) }
}
object ListSet {
  def empty[A]: Set[A] = ListSet(List.empty)
}
```

What about something more interesting? We can try to implement the set of even integers, which is infinite.

```scala mdoc:silent
final class EvenSet(elements: Set[Int]) extends Set[Int] {

  def contains(elt: Int): Boolean =
    (elt % 2 == 0) || elements.contains(elt)

  def insert(elt: Int): Set[Int] =
    EvenSet(elements.insert(elt))

  def union(that: Set[Int]): Set[Int] =
    EvenSet(that.union(elements))
}
object EvenSet {
  val evens: Set[Int] = EvenSet(ListSet.empty)
}
```

It turns out, perhaps surprisingly, that this works.
Let's define a few sets using `EvenSet` and `ListSet`.

```scala mdoc:silent
val evensAndOne = EvenSet.evens.insert(1)
val evensAndOthers = 
  EvenSet.evens.union(ListSet.empty.insert(1).insert(3))
```

Now show that they work as expected.

```scala mdoc
evensAndOne.contains(1)
evensAndOthers.contains(1)
evensAndOne.contains(2)
evensAndOthers.contains(2)
evensAndOne.contains(3)
evensAndOthers.contains(3)
```

We can generalize this idea to defining sets in terms of *indicator functions*, which is a function that returns true if an element is a member of a set.

```scala mdoc:silent
final class IndicatorSet[A](indicator: A => Boolean, elements: Set[A])
    extends Set[A] {

  def contains(elt: A): Boolean =
    indicator(elt) || elements.contains(elt)

  def insert(elt: A): Set[A] =
    new IndicatorSet(indicator, elements.insert(elt))

  def union(that: Set[A]): Set[A] =
    new IndicatorSet(indicator, that.union(elements))
}
object IndicatorSet {
  def apply[A](f: A => Boolean): Set[A] = 
    new IndicatorSet(f, ListSet.empty)
}
```

To test this, let's define the infinite set of odd integers.

```scala mdoc:silent
val odds = IndicatorSet[Int](_ % 2 == 1)
```

Now we'll show it works as expected.

```scala mdoc
odds.contains(1)
odds.contains(2)
odds.contains(3)
```

Taking the union of even and odd integers gives us a set that contains all integers.

```scala mdoc:silent
val integers = EvenSet.evens.union(odds)
```

It has the expected behaviour.

```scala mdoc
integers.contains(1)
integers.contains(2)
integers.contains(3)
```

There are several points we should take from this example. Firstly, we've seen that codata is in fact useful. Mixing different implementations of the same interface allows us create abstractions that we would not otherwise be able to do. The example we've used is typical of what you might see in an object-oriented textbook, so perhaps it's not too surprising to you. Notice that several of the implementations represent an infinite set. This is something that only codata can do. Data must be built up from the base cases in its definition, and so must be finite. Codata, being defined only in terms of its operations, only needs to compute the finite amount required by the operations that are used, not the infinite amount required to compute what it is.

In the next section we'll look at the Scala language features we can use in defining codata. First though, let's see another example that may be a bit more surprising than the set example.

I previously used booleans as an example of an algebraic data type.

```scala mdoc:silent
enum Bool {
  case True
  case False
}
```

We can also represent booleans as codata. There are many operations on booleans (for example, `and`, `or`, `xor`, `not`, and so on) but we can define all of them in terms of a simple and familiar operation, `if`.

```scala mdoc:reset:silent
trait Bool {
  def `if`[A](t: A)(f: A): A
}
```

(Note that Scala allows us to define methods with the same name as key words, in this case `if`, but we have to surround them in backticks to use them.)

We can define true and false as follows.

```scala mdoc:silent
val True = new Bool {
  def `if`[A](t: A)(f: A): A = t
}

val False = new Bool {
  def `if`[A](t: A)(f: A): A = f
}
```

Let's see it in use by defining `and` in terms of `if`, and then seeing examples of use.
First the definition of `and`.

```scala mdoc:silent
def and(l: Bool, r: Bool): Bool =
  new Bool {
    def `if`[A](t: A)(f: A): A =
      l.`if`(r)(False).`if`(t)(f)
  }
```

Now the examples. This is simple enough that we can try the entire truth table.

```scala mdoc
and(True, True).`if`("yes")("no")
and(True, False).`if`("yes")("no")
and(False, True).`if`("yes")("no")
and(False, False).`if`("yes")("no")
```

==== Exercise: Or and Not {-}


Test your understanding of `Bool` by implementing `or` and `not` in the same way we implemented `and` above.

#solution[
We can follow the same structure as `and`.

```scala mdoc:silent
def or(l: Bool, r: Bool): Bool =
  new Bool {
    def `if`[A](t: A)(f: A): A =
      l.`if`(True)(r).`if`(t)(f)
  }

def not(b: Bool): Bool =
  new Bool {
    def `if`[A](t: A)(f: A): A =
      b.`if`(False)(True).`if`(t)(f)
  }
```

Once again, we can test the entire truth table.

```scala mdoc
or(True, True).`if`("yes")("no")
or(True, False).`if`("yes")("no")
or(False, True).`if`("yes")("no")
or(False, False).`if`("yes")("no")

not(True).`if`("yes")("no")
not(False).`if`("yes")("no")
```
]

There are a couple of important points to note about this example. Firstly, it hints at a connection between data and codata, as we could define `Bool` as either an algebraic data type or as codata. We'll look at this relationship more formally in just a moment. Notice that, once again, computation only happens on demand. In this case, nothing happens until `if` is actually called. Until that point we're just building up a representation of what we want to happen. This again points to the fact that codata can handle infinite data, by only computing the finite amount required by the actual computation.
