## Codata in Scala

Let's now see the representation of codata in Scala.
We have already seen an example, which I have repeated here.

```scala mdoc:silent
trait Set[A] {
  
  /** True if this set contains the given element */
  def contains(elt: A): Boolean
  
  /** Construct a new set containing all elements in this set and the given element */
  def insert(elt: A): Set[A]
  
  /** Construct the union of this and that set */
  def union(that: Set[A]): Set[A]
}
```

The abstract definition of this, which is a product of functions, is below.

A `Set` with elements of type `A` is:

- a function `contains` which takes a `Set[A]` and an element `A` and returns a `Boolean`,
- a function `insert` which takes a `Set[A]` and an element `A` and returns a `Set[A]`, and
- a function `union` which takes a `Set[A]` and a set `Set[A]` and returns a `Set[A]`.

Notice that the first parameter of each function is the type we are defining, `Set[A]`.

The translation to Scala becomes:

- the overall type becomes a `trait`; and
- each function becomes a method on that `trait` where the first parameter is the hidden `this` parameter and other parameters become normal parameters to the method.

This gives us the Scala representation we started with.

This is only half the story for codata. We also need to actually implement the interface we've just defined. Here there are two approaches we can use:

1. We can use a `final` subclass in the case where we want to name the implementation; or
2. We can use an anonymous subclass.

Using a `final` class or a subclass means we cannot use implementation inheritance, which is difficult to reason about. Using a `class` rather than a `case class` means we don't expose implementation detail like constructor arguments.

An example is in order. Here's a simple example of `Set`, which uses a `List` to hold the elements in the set.

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

This uses the first implementation approach, a `final` subclass. Where would we use an anonymous subclass? They are most useful when implementing methods that return our codata type. Let's take `union` as an example. It returns our codata type, `Set`, and we could implement it as shown below.

```scala mdoc:reset:silent
trait Set[A] {
  
  def contains(elt: A): Boolean
  
  def insert(elt: A): Set[A]
  
  def union(that: Set[A]): Set[A] = {
    val self = this
    new Set[A] {
      def contains(elt: A): Boolean =
        self.contains(elt) || that.contains(elt)
        
      def insert(elt: A): Set[A] =
        // Arbitrary choice to insert into self
        self.insert(elt).union(that)
    }
  }
}
```

This uses an anonymous subclass to implement `union` on the `Set` trait, and hence defines the method for all subclasses. In this case it's probably not a great decision to do this, as different representations of `Set` will likely have more efficient ways to implement `union`. Nonetheless it illustrates the technique. Not making `union` `final` means that subclasses can provide a more efficient implementation, though it does open us up to the dangers of implementation inheritance. This is one example of where theory and craft diverge. In theory we never want implementation inheritance, but in practice it can be useful.

It can also be useful to implement utility methods defined purely in terms of the destructors. Let's say we wanted to implement a method `containsAll` that checks if a `Set` `contains` all the elements in an `Iterable` collection.

```scala
def containsAll(elements: Iterable[A]): Boolean
```

We can implement this purely in terms of `contains` on `Set` and `forall` on `Iterable`.

```scala mdoc:reset:silent
trait Set[A] {
  
  def contains(elt: A): Boolean
  
  def insert(elt: A): Set[A]
  
  def union(that: Set[A]): Set[A]
  
  def containsAll(elements: Iterable[A]): Boolean =
    elements.forall(elt => this.contains(elt))
}
```

Once again we could make this a `final` method. In this case it's probably more justified as it's difficult to imagine a more efficient implementation.


This illustrates the difference between the theory and craft level. Data and codata are distinct at the theory level. However Scala, like most programming languages conflates the two. 

Data and codata are both realized in Scala as variations of the same language features of classes and objects. This means that, when implemented, each can have properties of the other. We cannot, for example, define an algebraic data type without also defining names for the fields within the data and thus defining destructors. This is the same in most languages, which don't make a hard distinction between data and codata. 

Part of the appeal, I think, of classes and objects is that they can express so many conceptually different abstractions with the same language constructs. This gives them a surface appearance of simplicity; it seems we need to learn only one abstraction to solve a huge of number of coding problems. However this apparent simplicity hides real complexity, as this variety of uses forces us to reverse engineer the conceptual intention from the code. 
