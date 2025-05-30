#import "../stdlib.typ": info, warning, solution
== Exercise: Sets


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

The implementation for `union` is a bit unsatisfactory; it's doesn't use any of our strategies for writing code. We can implement both `union` and `insert` in a generic way that works for _all_ sets (in other words, is implemented on the `Set` trait) and uses the strategies we've seen in this chapter. Go ahead and do this.

#solution[
I used structural corecursion to implement these methods. I decided to name the subclasses, as I think it's a little bit clearer what's going on in this case.

```scala mdoc:reset:silent
trait Set[A] {
  
  def contains(elt: A): Boolean
  
  def insert(elt: A): Set[A] =
    InsertOneSet(elt, this)
  
  def union(that: Set[A]): Set[A] =
    UnionSet(this, that)
}

final class InsertOneSet[A](element: A, source: Set[A]) 
    extends Set[A] {

  def contains(elt: A): Boolean =
    elt == element || source.contains(elt)
}

final class UnionSet[A](first: Set[A], second: Set[A])
    extends Set[A] {

  def contains(elt: A): Boolean =
    first.contains(elt) || second.contains(elt)
}
```
]

```scala mdoc:invisible
final class ListSet[A](elements: List[A]) extends Set[A] {

  def contains(elt: A): Boolean =
    elements.contains(elt)

  override def insert(elt: A): Set[A] =
    ListSet(elt :: elements)
}
object ListSet {
  def empty[A]: Set[A] = ListSet(List.empty)
}
```

Your next challenge is to implement `Evens`, the set of all even integers, which we'll represent as a `Set[Int]`. This is an infinite set; we cannot directly enumerate all the elements in this set. (We actually could enumerate all the even elements that are 32-bit `Ints`, but we don't want to as this would use excessive amounts of space.)

#solution[
I implemented `Evens` using an `object`. This is possible because all possible instances of this set are the same, so we only need one instance.

```scala mdoc:silent
object Evens extends Set[Int] {

  def contains(elt: Int): Boolean =
    (elt % 2 == 0)
}
```

It turns out, perhaps surprisingly, that this works.
Let's define a few sets using `Evens` and `ListSet`.

```scala mdoc:silent
val evensAndOne = Evens.insert(1)
val evensAndOthers = 
  Evens.union(ListSet.empty.insert(1).insert(3))
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
]

We can generalize this idea to defining sets in terms of *indicator functions*, which is a function of type `A => Boolean`, returning returns true if the input belows to the set. Implement `IndicatorSet`, which is constructed with a single indicator function parameter.

#solution[
```scala mdoc:silent
final class IndicatorSet[A](indicator: A => Boolean)
    extends Set[A] {

  def contains(elt: A): Boolean =
    indicator(elt)
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
val integers = Evens.union(odds)
```

It has the expected behaviour.

```scala mdoc
integers.contains(1)
integers.contains(2)
integers.contains(3)
```
]
