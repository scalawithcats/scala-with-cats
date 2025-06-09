#import "../stdlib.typ": info, warning, solution, exercise
== Structural Corecursion


Structural corecursion is the opposite—more correctly, the dual—of structural recursion.
Whereas structural recursion tells us how to take apart an algebraic data type, 
structural corecursion tells us how to build up, or construct, an algebraic data type.
Whereas we can use structural recursion whenever the input of a method or function is an algebraic data type,
we can use structural corecursion whenever the output of a method or function is an algebraic data type.


#info(title: [Duality in Functional Programming])[
Two concepts or structures are duals if one can be translated in a one-to-one fashion to the other.
Duality is one of the main themes of this book.
By relating concepts as duals we can transfer knowledge from one domain to another.

Duality is often indicated by attaching the co- prefix to one of the structures or concepts.
For example, corecursion is the dual of recursion, and sum types, also known as coproducts, are the dual of product types.
]


Structural recursion works by considering all the possible inputs (which we usually represent as patterns), and then working out what we do with each input case.
Structural corecursion works by considering all the possible outputs, which are the constructors of the algebraic data type, and then working out the conditions under which we'd call each constructor.

Let's return to the list with elements of type `A`, defined as:

- the empty list; or
- a pair containing an `A` and a tail, which is a list of `A`.

In Scala 3 we write

```scala mdoc:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
}
```

We can use structural corecursion if we're writing a method that produces a `MyList`.
A good example is `map`:

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    ???
}
```

The output of this method is a `MyList`, which is an algebraic data type.
Since we need to construct a `MyList` we can use structural corecursion.
The structural corecursion strategy says we write down all the constructors and then consider the conditions that will cause us to call each constructor.
So our starting point is to just write down the two constructors, and put in dummy conditions.

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    if ??? then Empty()
    else Pair(???, ???)
}
```

We can also apply the recursion rule: where the data is recursive so is the method.

```scala
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    if ??? then Empty()
    else Pair(???, ???.map(f))
}
```

To complete the left-hand side we can use the strategies we've already seen:

- we can use structural recursion to tell us there are two possible conditions; and
- we can follow the types to align these conditions with the code we have already written.

In short order we arrive at the correct solution

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

There are a few interesting points here. 
Firstly, we should acknowledge that `map` is both a structural recursion and a structural corecursion.
This is not always the case.
For example, `foldLeft` and `foldRight` are not structural corecursions because they are not constrained to only produce an algebraic data type.
Secondly, note that when we walked through the process of creating `map` as a structural recursion we implicitly used the structural corecursion pattern, as part of following the types.
We recognised that we were producing a `List`, that there were two possibilities for producing a `List`, and then worked out the correct conditions for each case.
Formalizing structural corecursion as a separate strategy allows us to be more conscious of where we apply it.
Finally, notice how I switched from an `if` expression to a pattern match expression as we progressed through defining `map`.
This is perfectly fine.
Both kinds of expression achieve the same effect.
Pattern matching is a little bit safer due to exhaustivity checking.
If we wanted to continue using an `if` we'd have to define a method (for example, `isEmpty`) that allows us to distinguish an `Empty` element from a `Pair`.
This method would have to use pattern matching in its implementation, so avoiding pattern matching directly is just pushing it elsewhere.


=== Unfolds as Structural Corecursion


Just as we could abstract structural recursion as a fold, for any given algebraic data type we can abstract structural corecursion as an unfold. Unfolds are much less commonly used than folds, but they are still a nice tool to have.

Let's work through the process of deriving unfold, using `MyList` as our example again.

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
}
```

The corecursion skeleton is

```scala
if ??? then MyList.Empty()
else MyList.Pair(???, recursion(???))
```

Our starting point is writing the skeleton for `unfold`. It's a little bit unusual in that I've added a parameter `seed`. This is the information we use to create an element. We'll need this, but we cannot derive it from our strategies, so I've added it in here as a starting assumption.

```scala
def unfold[A, B](seed: A): MyList[B] =
  ???
```

Now we start using our strategies to fill in the missing pieces. I'm using the corecursion skeleton and I've applied the recursion rule immediately in the code below, to save a bit of time in the derivation.

```scala
def unfold[A, B](seed: A): MyList[B] =
  if ??? then MyList.Empty()
  else MyList.Pair(???, unfold(seed))
```

We can abstract the condition using a function from `A => Boolean`.

```scala
def unfold[A, B](seed: A, stop: A => Boolean): MyList[B] =
  if stop(seed) then MyList.Empty()
  else MyList.Pair(???, unfold(seed, stop))
```

Now we need to handle the case for `Pair`. 
We have a value of type `A` (`seed`), so to create the `head` element of `Pair` we can ask for a function `A => B`

```scala
def unfold[A, B](seed: A, stop: A => Boolean, f: A => B): MyList[B] =
  if stop(seed) then MyList.Empty()
  else MyList.Pair(f(seed), unfold(???, stop, f))
```

Finally we need to update the current value of `seed` to the next value. That's a function `A => A`.

```scala mdoc:silent
def unfold[A, B](seed: A, stop: A => Boolean, f: A => B, next: A => A): MyList[B] =
  if stop(seed) then MyList.Empty()
  else MyList.Pair(f(seed), unfold(next(seed), stop, f, next))
```

At this point we're done.
Let's see that `unfold` is useful by declaring some other methods in terms of it.
We're going to declare `map`, which we've already seen is a structural corecursion, using `unfold`.
We will also define `fill` and `iterate`, which are methods that construct lists and correspond to the methods with the same names on `List` in the Scala standard library.

To make this easier to work with I'm going to declare `unfold` as a method on the `MyList` companion object. 
I have made a slight tweak to the definition to make type inference work a bit better.
In Scala, types inferred for one method parameter cannot be used for other method parameters in the same parameter list.
However, types inferred for one method parameter list can be used in subsequent lists.
Separating the function parameters from the `seed` parameter means that the value inferred for `A` from `seed` can be used for inference of the function parameters' input parameters.

I have also declared some *destructor* methods, which are methods that take apart an algebraic data type.
For `MyList` these are `head`, `tail`, and the predicate `isEmpty`.
We'll talk more about these a bit later.

Here's our starting point.

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(_head: A, _tail: MyList[A])

  def isEmpty: Boolean =
    this match {
      case Empty() => true
      case _       => false
    }
    
  def head: A =
    this match {
      case Pair(head, _) => head
    }
    
  def tail: MyList[A] =
    this match {
      case Pair(_, tail) => tail
    }
}
object MyList {
  def unfold[A, B](seed: A)(stop: A => Boolean, f: A => B, next: A => A): MyList[B] =
    if stop(seed) then MyList.Empty()
    else MyList.Pair(f(seed), unfold(next(seed))(stop, f, next))
}
```

Now let's define the constructors `fill` and `iterate`, and `map`, in terms of `unfold`. I think the constructors are a bit simpler, so I'll do those first.

```scala
object MyList {
  def unfold[A, B](seed: A)(stop: A => Boolean, f: A => B, next: A => A): MyList[B] =
    if stop(seed) then MyList.Empty()
    else MyList.Pair(f(seed), unfold(next(seed))(stop, f, next))
    
  def fill[A](n: Int)(elem: => A): MyList[A] =
    ???
    
  def iterate[A](start: A, len: Int)(f: A => A): MyList[A] =
    ???
}
```

Here I've just added the method skeletons, which are taken straight from the `List` documentation.
To implement these methods we can use one of two strategies:

- reasoning about loops in the way we might in an imperative language; or
- reasoning about structural recursion over the natural numbers.

Let's talk about each in turn.

You might have noticed that the parameters to `unfold` are almost exactly those you need to create a for-loop in a language like Java. A classic for-loop, of the `for(i = 0; i < n; i++)` kind, has four components:

+ the initial value of the loop counter;
+ the stopping condition of the loop; 
+ the statement that advances the counter; and
+ the body of the loop that uses the counter.

These correspond to the `seed`, `stop`, `next`, and `f` parameters of `unfold` respectively.

Loop variants and invariants are the standard way of reasoning about imperative loops. I'm not going to describe them here, as you have probably already learned how to reason about loops (though perhaps not using these terms). Instead I'm going to discuss the second reasoning strategy, which relates writing `unfold` to something we've already discussed: structural recursion.

Our first step is to note that natural numbers (the integers 0 and larger) are conceptually algebraic data types even though the implementation in Scala---using `Int`---is not. A natural number is either:

- zero; or
- 1 + a natural number.

It's the simplest possible algebraic data type that is both a sum and a product type.

Once we see this, we can use the reasoning tools for structural recursion for creating the parameters to `unfold`.
Let's show how this works with `fill`. The `n` parameter tells us how many elements there are in the `List` we're creating. The `elem` parameter creates those elements, and is called once for each element. So our starting point is to consider this as a structural recursion over the natural numbers. We can take `n` as `seed`, and `stop` as the function `x => x == 0`. These are the standard conditions for a structural recursion over the natural numbers. What about `next`? Well, the definition of natural numbers tells us we should subtract one in the recursive case, so `next` becomes `x => x - 1`. We only need `f`, and that comes from the definition of how `fill` is supposed to work. We create the value from `elem`, so `f` is just `_ => elem`

```scala
object MyList {
  def unfold[A, B](seed: A)(stop: A => Boolean, f: A => B, next: A => A): MyList[B] =
    if stop(seed) then MyList.Empty()
    else MyList.Pair(f(seed), unfold(next(seed))(stop, f, next))
    
  def fill[A](n: Int)(elem: => A): MyList[A] =
    unfold(n)(_ == 0, _ => elem, _ - 1)
    
  def iterate[A](start: A, len: Int)(f: A => A): MyList[A] =
    ???
}
```

```scala mdoc:reset:invisible
enum MyList[A] {
  case Empty()
  case Pair(_head: A, _tail: MyList[A])

  def isEmpty: Boolean =
    this match {
      case Empty() => true
      case _       => false
    }
    
  def head: A =
    this match {
      case Pair(head, _) => head
    }
    
  def tail: MyList[A] =
    this match {
      case Pair(_, tail) => tail
    }
    
  def map[B](f: A => B): MyList[B] =
    MyList.unfold(this)(
      _.isEmpty,
      pair => f(pair.head),
      pair => pair.tail
    )
    
  override def toString(): String = {
    def loop(list: MyList[A]): List[A] =
      list match {
        case Empty() => List.empty
        case Pair(h, t) => h :: loop(t)
      }
    s"MyList(${loop(this).mkString(", ")})"
  }
}
object MyList {
  def unfold[A, B](seed: A)(stop: A => Boolean, f: A => B, next: A => A): MyList[B] =
    if stop(seed) then MyList.Empty()
    else MyList.Pair(f(seed), unfold(next(seed))(stop, f, next))

  def fill[A](n: Int)(elem: => A): MyList[A] =
    unfold(n)(_ == 0, _ => elem, _ - 1)

  def iterate[A](start: A, len: Int)(f: A => A): MyList[A] =
    unfold((len, start))(
      (len, _) => len == 0,
      (_, start) => start,
      (len, start) => (len - 1, f(start))
    )
}
```

We should check that our implementation works as intended. We can do this by comparing it to `List.fill`.

```scala mdoc:to-string
List.fill(5)(1)
MyList.fill(5)(1)
```

Here's a slightly more complex example, using a stateful method to create a list of ascending numbers.
First we define the state and method that uses it.

```scala mdoc:silent
var counter = 0
def getAndInc(): Int = {
  val temp = counter
  counter = counter + 1
  temp 
}
```

Now we can create it to create lists.

```scala mdoc:to-string
List.fill(5)(getAndInc())
counter = 0
MyList.fill(5)(getAndInc())
```


#exercise[Iterate]


Implement `iterate` using the same reasoning as we did for `fill`.
This is slightly more complex than `fill` as we need to keep two bits of information: the value of the counter and the value of type `A`.

#solution[
```scala
object MyList {
  def unfold[A, B](seed: A)(stop: A => Boolean, f: A => B, next: A => A): MyList[B] =
    if stop(seed) then MyList.Empty()
    else MyList.Pair(f(seed), unfold(next(seed))(stop, f, next))
    
  def fill[A](n: Int)(elem: => A): MyList[A] =
    unfold(n)(_ == 0)(_ => elem, _ - 1)
    
  def iterate[A](start: A, len: Int)(f: A => A): MyList[A] =
    unfold((len, start)){
      (len, _) => len == 0,
      (_, start) => start,
      (len, start) => (len - 1, f(start))
    }
}
```

We should check that this works.

```scala mdoc:to-string
List.iterate(0, 5)(x => x - 1)
MyList.iterate(0, 5)(x => x - 1)
```
]


#exercise[Map]


Once you've completed `iterate`, try to implement `map` in terms of `unfold`. You'll need to use the destructors to implement it.

#solution[
```scala
def map[B](f: A => B): MyList[B] =
  MyList.unfold(this)(
    _.isEmpty,
    pair => f(pair.head),
    pair => pair.tail
  )
```

```scala mdoc:to-string
List.iterate(0, 5)(x => x + 1).map(x => x * 2)
MyList.iterate(0, 5)(x => x + 1).map(x => x * 2)
```
]

Now a quick discussion on destructors. The destructors do two things:

+ distinguish the different cases within a sum type; and
+ extract elements from each product type.

So for `MyList` the minimal set of destructors is `isEmpty`, which distinguishes `Empty` from `Pair`, and `head` and `tail`.
The extractors are partial functions in the conceptual, not Scala, sense; they are only defined for a particular product type and throw an exception if used on a different case. You may have also noticed that the functions we passed to `fill` are exactly the destructors for natural numbers.

The destructors are another part of the duality between structural recursion and corecursion. Structural recursion is:

- defined by pattern matching on the constructors; and
- takes apart an algebraic data type into smaller pieces.

Structural corecursion instead is:

- defined by conditions on the input, which may use destructors; and
- build up an algebraic data type from smaller pieces.

One last thing before we leave `unfold`. If we look at the usual definition of `unfold` we'll probably find the following definition.

```scala
def unfold[A, B](in: A)(f: A => Option[(A, B)]): List[B]
```

This is equivalent to the definition we used, but a bit more compact in terms of the interface it presents. We used a more explicit definition that makes the structure of the method clearer.
