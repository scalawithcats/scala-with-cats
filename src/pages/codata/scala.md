## Codata in Scala

So far we've been a bit informal of our definition of codata. We'll now make that more precise. Codata is a product (logical and) of functions. Let's take the set example, which we defined in Scala as

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

We can abstract away the Scala to give us the representation purely in terms of a product of functions:

A `Set` with elements of type `A` is:

- a function `contains` which takes a `Set[A]` and an element `A` and returns a `Boolean`,
- a function `insert` which takes a `Set[A]` and an element `A` and returns a `Set[A]`, and
- a function `union` which takes a `Set[A]` and a set `Set[A]` and returns a `Set[A]`.

Notice that the first parameter of each function is the type we are defining, `Set[A]`.

The translation to Scala becomes:

- the overall type becomes a `trait`; and
- each function becomes a method on that `trait` where the first parameter is the hidden `this` parameter and other parameters become normal parameters to the method.

This gives us the Scala representation we started with.

We also need to actually implement the interface we've just defined. Here the rule is to use a `final` class. This is because we don't want to use implementation inheritance, which is difficult to reason about, nor do we want to expose implementation details like constructor arguments.

This illustrates the difference between the theory and craft level. Data and codata are distinct at the theory level. However Scala, like most programming languages conflates the two. In Scala both data and codata are realized as variations of the same language features of classes and objects. We cannot, for example, define an algebraic data type without also defining names for the fields within the data, and thus defining destructors. Thus we can treat any particular class or object as either data or codata, or even both. 

Part of the appeal, I think, of classes and objects is that they can express so many conceptually different abstractions with the same language constructs. For example, we can use objects to express modules, data, and codata. This gives them a surface appearance of simplicity; it seems we need to learn only one abstraction to solve a huge of number of coding problems. However this apparent simplicity hides real complexity, as this variety of uses forces us to reverse engineer the conceptual intention from the code. Just like we did with algebraic data, we will limit the object-oriented features we in defining codata. In particular, we won't use implementation inheritance, subtyping, overriding, or state. This gives us a subset of object-oriented code that fits within the conceptual model we are building.
