## Structural Recursion

Structural recursion is our second programming strategy. 
Algebraic data types tell us how to create data given a certain structure.
Structural recursion tells us how to transform an algebraic data types into any other type.
Given an algebraic data type, the transformation can be implemented using structural recursion.

As with algebraic data types, there is distinction between the concept of structural recursion and the implementation in Scala.
This is more obvious because there are two ways to implement structural recursion in Scala: via pattern matching or via dynamic dispatch.
We'll look at each in turn.


### Pattern Matching

I'm assuming you're familiar with pattern matching in Scala, so I'll only talk about how to implement structural recursion using pattern matching.
Remember there are two kinds of algebraic data types: sum types (logical ors) and product types (logical ands).
We have corresponding rules for structural recursion implemented using pattern matching:

1. For each branch in a sum type we have a distinct `case` in the pattern match; and
2. Each `case` corresponds to a product type with the pattern written in the usual way.

Let's see this in code, using an example ADT that includes both sum and product types:

- `A` is a `B` or `C`; and
- `B` is a `D` and `E`; and
- `C` is a `F` and `G`

which we represent (in Scala 3) as

```scala
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

The `???` bits are problem specific, and we cannot give a general solution for them. 
However we'll soon see strategies to help create them.


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
In Scala 3 we write

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

Our first step is to recognize that `map` can be written using a structural recursion.
`MyList` is an algebraic data type, `map` is transforming this algebraic data type, and therefore structural recursion is applicable.
We now apply the structural recursion strategy, giving us

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

I left the `???` to indicate that we haven't finished with that case.

Now we can move on to the problem specific parts.
Here we have three strategies to help us:

1. reasoning independently by case; 
2. assuming recursion is correct; and
3. following the types

The first two are specific to structural recursion, while the final one is a general strategy we can use in many situations.
Let's briefly discuss each and then see how they apply to our example.

The first strategy is relatively simple: when we consider the problem specific code on the right hand side of a pattern matching `case`, we can ignore the code in any other pattern match cases. So, for example, when considering the case for `Empty` above we don't need to worry about the case for `Pair`, and vice versa.

The next strategy is a little bit more complicated, and has to do with recursion. Remember that the structural recursion strategy tells us where to place any recursive calls. This means we don't have to think through the recursion. Instead we assume the recursive call will correctly compute what it claims, and only consider how to further process the result of the recursion. The result is guaranteed to be correct so long as we get the non-recursive parts correct. 

In the example above we have the recursion `tail.map(f)`. We can assume this correctly computes `map` on the tail of the list, and we only need to think about what we should do with the remaining data: the `head` and the result of the recursive call. 

It's this property that allows us to consider cases independently. Recursive calls are the only thing that connect the different cases, and they are given to us by the structural recursion strategy.

Our final strategy is **following the types**. It can be used in many situations, not just structural recursion, so I consider it a separate strategy. The core idea is to use the information in the types to restrict the possible implementations. We can look at the types of inputs and outputs to help us.

Now let's use these strategies to finish the implementation of `map`. We start with

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

Our first strategy is to consider the cases independently. Let's start with the `Empty` case. There is no recursive call here, so reasoning using structural recursion doesn't come into play. Let's instead use the types. There is no input here other than the `Empty` case we have already matched, so we cannot use the input types to further restrict the code. However can use the output types. We're trying to create a `MyList[B]`. There are only two ways to create a `MyList[B]`: an `Empty` or a `Pair`. To create a `Pair` we need a `head` of type `B`, which we don't have. So we can only use `Empty`. *This is the only possible code we can write*. The types are sufficiently restrictive that we cannot write incorrect code for this case.

```scala
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    this match {
      case Empty() => Empty()
      case Pair(head, tail) => ??? tail.map(f)
    }
}
```

Now let's move to the `Pair` case. We can apply both the structural recursion reasoning strategy and following the types. Let's use each in turn.

The case for `Pair` is

```scala 
case Pair(head, tail) => ??? tail.map(f)
```

Remember we can consider this independently of the other case. We assume the recursion is correct. This means we only need to think about what we should do with the `head`, and how we should combine this result with `tail.map(f)`. Let's now follow the types to finish the code. Our goal is to produce a `MyList[B]`. We already the following available:

- `tail.map(f)`, which has type `MyList[B]`;
- `head`, with type `A`;
- `f`, with type `A => B`; and
- the constructors `Empty` and `Pair`.

We could return just `Empty`, matching the case we've already written. This has the correct type but we might expect it is not the correct answer because it does not use the result of the recursion, `head`, or `f` in any way.

We could return just `tail.map(f)`. This has the correct type but we might expect it is not correct because we don't use `head` or `f` in any way.

We can call `f` on `head`, producing a value of type `B`, and then combine this value and the result of the recursive call using `Pair` to produce a `MyList[B]`. This is the correct solution.

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    this match {
      case Empty() => Empty()
      case Pair(head, tail) => Pair(f(head), tail.map(f))
    }
}
```

If you've followed this example you've hopefully see how we can use the three strategies to systematically find the correct implementation. Notice how we interleaved the recursion strategy and following the types to guide us to a solution for the `Pair` case. Also note how following the types alone gave us three possible implementations for the `Pair` case. In this code, and as is usually the case, the solution was the implementation that used all of the available inputs.


### Exhaustivity Checking

Remember that algebraic data types are a closed world: they cannot be extended once defined. 
The Scala compiler can use this to check that we handle all possible cases in a pattern match,
so long as we write the pattern match in a way the compiler can work with.
This is known as exhaustivity checking.

Here's a simple example.
We start by defining a straight-forward algebraic data type.

```scala mdoc:silent
// Some of the possible units for lengths in CSS
enum CssLength {
  case Em(value: Double)
  case Rem(value: Double)
  case Pt(value: Double)
}
```

If we write a pattern match using the structural recursion strategy,
the compiler will complain if we're missing a case.

```scala
import CssLength.*

CssLength.Em(2.0) match {
  case Em(value) => value
  case Rem(value) => value
}
// -- [E029] Pattern Match Exhaustivity Warning: ----------------------------------
// 1 |CssLength.Em(2.0) match {
//   |^^^^^^^^^^^^^^^^^
//   |match may not be exhaustive.
//   |
//   |It would fail on pattern case: CssLength.Pt(_)
//   |
//   | longer explanation available when compiling with `-explain`
```

Exhaustivity checking is incredibly useful.
For example, if we add or remove a case from an algebraic data type, the cmopiler will us all the pattern matches that need to be updated.


### Dynamic Dispatch

Using dynamic dispatch to implement structural recursion is an implementation technique that may feel more natural to people with a background in object-oriented programming.

The dynamic dispatch approach consists of:

1. defining an *abstract method* at the root of the algebraic data types; and
2. implementing that abstract method at every leaf of the algebraic data type.

This implementation technique is only available if we use the Scala 2 encoding of algebraic data types.

Let's see it in the `MyList` example we just looked at.
Our first step is to rewrite the definition of `MyList` to the Scala 2 style.

```scala mdoc:reset:silent
sealed abstract class MyList[A] extends Product with Serializable
final case class Empty[A]() extends MyList[A]
final case class Pair[A](head: A, tail: MyList[A]) extends MyList[A]
```

Next we define an abstract method for `map` on `MyList`.

```scala
sealed abstract class MyList[A] extends Product with Serializable {
  def map[B](f: A => B): MyList[B]
}
final case class Empty[A]() extends MyList[A]
final case class Pair[A](head: A, tail: MyList[A]) extends MyList[A]
```

Then we implement `map` on the concrete subtypes `Empty` and `Pair`.

```scala mdoc:reset:silent
sealed abstract class MyList[A] extends Product with Serializable {
  def map[B](f: A => B): MyList[B]
}
final case class Empty[A]() extends MyList[A] {
  def map[B](f: A => B): MyList[B] = 
    Empty()
}
final case class Pair[A](head: A, tail: MyList[A]) extends MyList[A] {
  def map[B](f: A => B): MyList[B] =
    Pair(f(head), tail.map(f))
}
```

We can use exactly the same strategies we used in the pattern matching case to create this code.
The implementation technique is different but the underlying concept is the same.

Given we have two implementation strategies, which should we use?
If we're using `enum` in Scala 3 we don't have a choice; we must use pattern matching.
In other situations we can choose between the two.
I prefer to use pattern matching when I can, as it puts the entire method definition in one place.
However, Scala 2 in particular has problems inferring types in some pattern matches.
In these situations we can use dynamic dispatch instead.
We'll learn more about this when we look at generalized algebraic data types.


### Folds as Structural Recursions 

Let's finish by looking at the fold method as an abstraction over structural recursion.
We know that every algebraic data type has a structural recursion skeleton that is determined entirely by the structure of the algebraic data type.
For `MyList`, defined as

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
}
```

the skeleton is

```scala
aList match {
  case Empty() => ???
  case Pair(head, tail) => ??? recursion(tail)
}
```

For any algebraic data type we can define at least one method, called a fold, that captures all the parts of structural recursion that don't change and allows the caller to specify all the problem specific parts.
For `MyList` this means defining a method

```scala
def fold[A, B](list: MyList[A]): B =
  list match {
    case Empty() => ???
    case Pair(head, tail) => ??? fold(tail)
  }
```

where `B` is the type the caller wants to create. 

To complete `fold` we add method parameters for the problem specific (`???`) parts.
In the case for `Empty`, we need a value of type `B` (notice that I'm following the types here).

```scala
def fold[A,B](list: MyList[A], empty: B): B =
  list match {
    case Empty() => empty
    case Pair(head, tail) => ??? fold(tail, empty)
  }
```

For the `Pair` case, we have the head of type `A` and the recursion producing a value of type `B`. This means we need a function to combine these two values.

```scala mdoc:invisible
import MyList.*
```
```scala mdoc:silent
def foldRight[A,B](list: MyList[A], empty: B, f: (A, B) => B): B =
  list match {
    case Empty() => empty
    case Pair(head, tail) => f(head, foldRight(tail, empty, f))
  }
```

This is `foldRight` (and I've renamed the method to indicate this).
You might have noticed there is another valid solution.
Both `empty` and the recursion produce values of type `B`.
If we follow the types we can come up with

```scala mdoc:silent
def foldLeft[A,B](list: MyList[A], empty: B, f: (A, B) => B): B =
  list match {
    case Empty() => empty
    case Pair(head, tail) => foldLeft(tail, f(head, empty), f)
  }
```

which is `foldLeft`, the tail-recursive variant of fold for a list.

We can follow the same process for any algebraic data type to create its folds. 
The rules are:

- a fold is a function from the algebraic data type and additional parameters to some generic type that I'll call `B` below for simplicity;
- the fold has one additional parameter for each case in a logical or;
- each parameter is a function, with result of type `B` and parameters that have the same type as the corresponding constructor arguments *except* recursive values are replaced with `B`; and
- if the constructor has no arguments (for example, `Empty`) we can use a value of type `B` instead of a function with no arguments.

Returning to `MyList`, it has:

- two cases, and hence two parameters to fold (other than the parameter that is the list itself);
- `Empty` is a constructor with no arguments and hence we use a parameter of type `B`; and
- `Pair` is a constructor with one parameter of type `A` and one recursive parameter, and hence the corresponding function has type `(A, B) => B`.
