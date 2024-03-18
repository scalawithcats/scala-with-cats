## Exercise: Sets

In this extended exercise we'll explore the `Set` interface we have already used in several examples, reproduced below.

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

We also saw a simple implementation, storing the elements in the set in a `List`.

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

Your first challenge is to implement `EvenSet`, the set of even integers. Note this is infinite; you cannot directly represent all the elements in this set. Hint: 

<div class="solution">
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
</div>

We can generalize this idea to defining sets in terms of **indicator functions**, which is a function of type `A => Boolean`, returning returns true if the input belows to the set. Implement `IndicatorSet`, which accepts

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
