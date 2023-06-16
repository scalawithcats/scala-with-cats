## Structural Recursion

Structural recursion is our second programming strategy. 
Algebraic data types tell us how to create data given a certain structure.
Structural recursion tells us how to transform an algebraic data types into any other type.
Given an algebraic data type, *any* transformation can be implemented using structural recursion.

Just like with algebraic data types, there is distinction between the concept of structural recursion and the implementation in Scala.
In particular, there are two ways structural recursion can be implemented in Scala: via pattern matching or via dynamic dispatch.
We'll look at both in turn.


### Pattern Matching

I'm assuming you're familiar with pattern matching in Scala, so I'll only talk about how to implement structural recursion using pattern matching.
Remember there are two kinds of algebraic data types: sum types (logical ors) and product types (logical ands).
We have corresponding rules for structural recursion implemented using pattern matching:

1. For each branch in a sum type we have a distinct `case` in the pattern match; and
2. Each `case` corresponds to a product type with the pattern written in the usual way.

Let's see this in code.
Remember in the general case, we can have

- `A` is a `B` or `C`; and
- `B` is a `D` and `E`; and
- `C` is a `F` and `G`

which we represent (in Scala 3) as

```scala mdoc:silent
enum A {
  case B(d: D, e: E)
  case C(f: F, g: G)
}
```

Following the rules above means a structural recursion would look like

```scala
anA match {
  case B(d, e) => ???
  case C(f, g) => ???
}
```

The `???` bits are problem specific, and we cannot give a general solution for them (though we'll soon see strategies to help create them.)


### The Recursion in Structural Recursion

At this point you might be wondering where the recursion in structural recursion comes from.
This is an additional rule for recursion: whenever the data is recursive the method is recursive in the same place.

Let's see this in action for a real data type.

We can define a list with elements of type `A` as:

- the empty list; or
- a pair containing an `A` and a tail, which is a list of `A`.

This is exactly the definition of `List` in the standard library.
Notice it's an algebraic data type as it consists of sums and products.
It is also recursive: in the pair case the tail is itself a list.

We can directly translate this to code, using the strategy for algebraic data types we saw previously.
In Scala 3 we write.

```scala mdoc:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
}
```

Let's implement `map` for `MyList`.
We start with the method skeleton specifying just the name and types.

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    ???
}
```

Now apply the structural recursion strategy, giving us

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    this match {
      case Empty() => ???
      case Pair(head, tail) => ???
    }
}
```

I forgot the recursion rule! 
The data is recursive in the `tail` of `Pair`, so `map` is recursive there as well.

```scala
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    this match {
      case Empty() => ???
      case Pair(head, tail) => ??? tail.map(f)
    }
}
```

I've left the `???` to indicate that we haven't finished with this case.
