## Relating Data and Codata

We earlier saw that we could implement `Bool` as both data and codata. This suggests there is some relationship between the two. In this section we'll explore that relationship. We'll look at it in two ways: firstly a very surface-level relationship between the two, and then a deep connection via `fold`.

Remember that (algebraic) data is a sum of products, where the products are constructors. Meanwhile, codata is a product of functions. These two don't appear related on the surface, but let's look a bit more closely.

Constructors are functions: they accept arguments and return a result. When we look at codata, we see a product of functions. We can make an correspondence between these functions and the constructor functions in data. What about the sum part of data? Well, when we have a product of functions we only call one at any point in our code. So the logical or is in the choice of function to call.

Let's see how this works with a familiar example of data, `List`. As an algebraic data type we can define

```scala
enum List[A] {
  case Pair(head: A, tail: List[A])
  case Empty()
}
```

The codata equivalent is

```scala
trait List[A] {
  def pair(head: A, tail: List[A]): List[A]
  def empty: List[A]
}
```

This isn't the pattern we used to represent `Bool` as codata, and it doesn't immediately appear to be useful. In a few chapters we'll see a use for this duality, but for now we'll leave it and move on.

The connection between `Bool` as data and `Bool` as codata comes from `fold`. We've already learned how to derive the `fold` for any algebraic data type. For `Bool`, defined as

```scala
enum Bool {
  case True
  case False
}
```

the `fold` method is

```scala mdoc:silent
enum Bool {
  case True
  case False
  
  def fold[A](t: A)(f: A): A =
    this match {
      case True => t
      case False => f
    }
}
```

This `fold` is `if` that we used earlier, except in defining `if` we didn't need an explicit representation of data; instead it was implicit in the definition of `True` and `False`. I've repeated the codata version of `Bool` below so you can compare the two.

```scala mdoc:reset:silent
trait Bool {
  def `if`[A](t: A)(f: A): A
}

val True = new Bool {
  def `if`[A](t: A)(f: A): A = t
}

val False = new Bool {
  def `if`[A](t: A)(f: A): A = f
}
```

The rules here are:

1. On the interface (`trait`) defining the codata, define a method with the same signature as `fold`.
2. Define an implementation of the interface for each product case in the data. The data's constructor arguments become constructor arguments on the codata `classes`. If there are no constructor arguments, as in `Bool`, we can define values instead of classes.
3. Each implementation implements the case of `fold` that it corresponds to.

Let's see an example for `List`. We'll start by defining it as data and implementing `fold`. I've chosen to implement `foldRight` but `foldLeft` would be just as good.

```scala mdoc:silent
enum List[A] {
  case Pair(head: A, tail: List[A])
  case Empty()
  
  def foldRight[B](empty: B)(f: (A, B) => B): B =
    this match { 
      case Pair(head, tail) => f(head, tail.foldRight(empty)(f))
      case Empty() => empty
    }
}
```

Now let's implement it as codata. We start by defining the interface with the `fold` method. In this case I'm calling it `foldRight` as it's going to exactly mirror the `foldRight` we just defined.

```scala mdoc:reset:silent
trait List[A] {
  def foldRight[B](empty: B)(f: (A, B) => B): B
}
```

Now we define the implementations. There is one for `Pair` and one for `Empty`, which are the two cases in data definition of `List`.

```scala
final class Pair[A](head: A, tail: List[A]) extends List[A] {
  def foldRight[B](empty: B)(f: (A, B) => B): B =
    ???
}

final class Empty[A]() extends List[A] {
  def foldRight[B](empty: B)(f: (A, B) => B): B =
    ???
}
```

I didn't implement the bodies of` foldRight` so I could show this as a separate step. The implementation here directly mirrors `foldRight` on the data implementation, and we can use the strategies to implement the codata equivalents. That is to say, we can use the recursion rule, reasoning by case, and following the types. I'm going to skip these details as we've already gone through them in depth.

```scala mdoc:silent
final class Pair[A](head: A, tail: List[A]) extends List[A] {
  def foldRight[B](empty: B)(f: (A, B) => B): B =
    f(head, tail.foldRight(empty)(f))
}

final class Empty[A]() extends List[A] {
  def foldRight[B](empty: B)(f: (A, B) => B): B =
    empty
}
```

This code is almost the same as the dynamic dispatch implementation, which again shows the relationship between codata and object-oriented code.
