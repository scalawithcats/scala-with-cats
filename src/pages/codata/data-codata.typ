#import "../stdlib.typ": info, warning, solution
== Relating Data and Codata


In this section we'll explore the relationship between data and codata, and in particular converting one to the other. We'll look at it in two ways: firstly a very surface-level relationship between the two, and then a deep connection via `fold`.

Remember that data is a sum of products, where the products are constructors and we can view constructors as functions. So we can view data as a sum of functions. Meanwhile, codata is a product of functions. We can easily make a direct correspondence between the functions-as-constructors and the functions in codata. What about the difference between the sum and the product that remains.
Well, when we have a product of functions we only call one at any point in our code. So the logical or is in the choice of function to call.

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

In the codata implementation we are explicitly representing the constructors as methods, and pushing the choice of constructor to the caller. In a few chapters we'll see a use for this relationship, but for now we'll leave it and move on.

The other way to view the relationship is a connection via `fold`.
We've already learned how to derive the `fold` for any algebraic data type. For `Bool`, defined as

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

We know that `fold` is universal: we can write any other method in terms of it. It therefore provides a universal destructor and is the key to treating data as codata. In this case the `fold` is something we use all the time, except we usually call it `if`.

Here's the codata version of `Bool`, with `fold` renamed to `if`. (Note that Scala allows us to define methods with the same name as key words, in this case `if`, but we have to surround them in backticks to use them.)

```scala mdoc:reset:silent
trait Bool {
  def `if`[A](t: A)(f: A): A
}
```

Now we can define the two instances of `Bool` purely as codata.

```scala mdoc:silent
val True = new Bool {
  def `if`[A](t: A)(f: A): A = t
}

val False = new Bool {
  def `if`[A](t: A)(f: A): A = f
}
```

Let's see this in use by defining `and` in terms of `if`, and then creating some examples.
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

Notice that, once again, computation only happens on demand. In this case, nothing happens until `if` is actually called. Until that point we're just building up a representation of what we want to happen. This again points to how codata can handle infinite data, by only computing the finite amount required by the actual computation.


The rules here for converting from data to codata are:

+ On the interface (`trait`) defining the codata, define a method with the same signature as `fold`.
+ Define an implementation of the interface for each product case in the data. The data's constructor arguments become constructor arguments on the codata `classes`. If there are no constructor arguments, as in `Bool`, we can define values instead of classes.
+ Each implementation implements the case of `fold` that it corresponds to.

Let's apply this to a slightly more complex example: `List`. We'll start by defining it as data and implementing `fold`. I've chosen to implement `foldRight` but `foldLeft` would be just as good.

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

Now we define the implementations. There is one for `Pair` and one for `Empty`, which are the two cases in data definition of `List`. Notice that in this case the classes have constructor arguments, which correspond to the constructor arguments on the correspnding product types.

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

I didn't implement the bodies of` foldRight` so I could show this as a separate step. The implementation here directly mirrors `foldRight` on the data implementation, and we can use the same strategies to implement the codata equivalents. That is to say, we can use the recursion rule, reasoning by case, and following the types. I'm going to skip these details as we've already gone through them in depth. The final code is shown below.

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

The transformation from data to codata goes under several names: *refunctionalization*, *Church encoding*, and *Böhm-Berarducci encoding*. The latter two terms specifically refer to transformations into the untyped and typed lambda calculus respectively. The lambda calculus is a simple model programming language that contains only functions. We're going to take a quick detour to show that we can, indeed, encode lists using just functions. This demonstrates that objects and functions have equivalent power.

The starting point is creating a type alias `List`, which defines a list as a fold. This uses a polymorphic function type, which is new in Scala 3. Inspect the type signature and you'll see it is the same as `foldRight` above.

```scala mdoc:reset:silent
type List[A, B] = (B, (A, B) => B) => B
```
Now we can define `Pair` and `Empty` as functions. The first parameter list is the constructor arguments, and the second parameter list is the parameters for `foldRight`.

```scala mdoc:silent
val Empty: [A, B] => () => List[A, B] = 
  [A, B] => () => (empty, f) => empty

val Pair: [A, B] => (A, List[A, B]) => List[A, B] =
  [A, B] => (head: A, tail: List[A, B]) => (empty, f) => 
    f(head, tail(empty, f))
```

Finally, let's see an example to show it working.
We will first define the list containing `1`, `2`, `3`.
Due to a restriction in polymorphic function types, I have to add the useless empty parameter.

```scala mdoc:silent
val list: [B] => () => List[Int, B] = 
  [B] => () => Pair(1, Pair(2, Pair(3, Empty())))
```

Now we can compute the sum and product of the elements in this list.

```scala mdoc
val sum = list()(0, (a, b) => a + b)
val product = list()(1, (a, b) => a * b)
```

It works!

The purpose of this little demonstration is to show that functions are just objects (in the codata sense) with a single method. Scala this makes apparent, as functions _are_ objects with an `apply` method.

We've seen that data can be translated to codata. The reverse is also possible: we simply tabulate the results of each possible method call. In other words, the data representation is memoisation, a lookup table, or a cache.

Although we can convert data to codata and vice versa, there are good reasons to choose one over the other. We've already seen one reason: with codata we can represent infinite structures. In this next section we'll see another difference: the extensibility that data and codata permit.
