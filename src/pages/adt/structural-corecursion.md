## Structural Corecursion

Structural corecursion is the opposite—more correctly, the dual—of structural recursion.
Whereas structural recursion tells us how to take apart an algebraic data types, 
structural corecursion tells us how to build up an algebraic data type.
We can use structural corecursion whenever the output of a method or function is an algebraic data type.

<div class="callout callout-info">
#### Duality in Functional Programming

Duality means that there is some concept or structure that can be translated in a one-to-one fashion to some other concept or structure.
Duality is often indicated by attaching the co- prefix to a term.
So corecursion is the dual of recursion, and sum types, also known as coproducts, are the dual of product types.

Duality is one of the main themes of this book.
By relating concepts as duals, we can transfer knowledge from one domain to another.
</div>

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

If we're writing a method that produces a `MyList` then we can use structural corecursion.
A good example is `map`:

```scala mdoc:reset:silent
enum MyList[A] {
  case Empty()
  case Pair(head: A, tail: MyList[A])
  
  def map[B](f: A => B): MyList[B] = 
    ???
}
```

The structural corecursion strategy says we write down all the constructors and then consider the conditions that will cause us to call each constructor.
So our starting point is to just write down the two constructors, and put in some dummy conditions for each.

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

Now to get the left-hand side we can use the strategies we've already seen:

* we can use structural recursion to tell us there are two possible conditions; and
* we can follow the types to align these conditions with the code we have already written.

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
Finally, noticed how I switched from an `if` expression to a pattern match expression as we progressed through defining `map`.
This is perfectly fine.
Both kinds of expression can achieve the same effect, though if we wanted to continue using an `if` we'd have to define a method (for example, `isEmpty`) that allows us to distinguish an `Empty` element from a `Pair`.
This method would have to use pattern matching in its implementation, so avoiding pattern matching directly is just pushing it elsewhere.

**TODO: desribe abstract structural corecursion**


### Structural Corecursion as Unfold
