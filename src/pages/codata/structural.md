## Structural Corecursion and Infinite Codata

In this section we'll build a library for streams, also known as lazy lists. These are the codata equivalent of lists. Where a list must have a finite length, streams have an infinite length. We'll use this example to explore structural recursion and structural corecursion as applied to codata.

Let's start by reviewing structural recursion and corecursion. The key idea is to use the input or output type, respectively, to drive the process of writing the method. We've already seen how this works with data, where we emphasized structural recursion. With codata it's more often the case the structural corecursion is used. The steps for using structural corecursion are:

1. recognize the output of the method or function is codata;
2. write down the skeleton to construct an instance of the codata type, usually using an anonymous subclass; and
3. fill in the methods, using strategies such as structural recursion or following the types to help.

For structural recursion the steps are:

1. recognize the input of the method or function is codata;
2. note the codata's destructors as possible sources of values in writing the method; and
3. complete the method, using strategies such as following the types or structural corecursion and the methods identified above.

An example will make this clearer, but before we can see an example we need to define our stream type. As this is codata, it is defined in terms of its destructors. The destructors that define a `Stream` of elements of type `A` are:

- a `head` of type `A`; and
- a `tail` of type `Stream[A]`.

Note these are almost the destructors of `List`. We haven't defined `isEmpty` as a destructor because our streams never end and thus this method would always return `false`. (A lot of real implementations, such as the `LazyList` in the Scala standard library, do define such a method which allows them to represent finite and infinite lists in the same structure. We're not doing this for simplicity and because we want to work with codata in its purest form.)

We can translate this to Scala, as we've previously seen, giving us

```scala mdoc:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
}
```

Now we can create an instance of `Stream`. Let's create a never-ending stream of ones.
We will start with the skeleton below and apply strategies to complete the code.

```scala
val ones: Stream[Int] = ???
```

The first strategy is structural corecursion. We're returning an instance of codata, so we can insert the skeleton to construct a `Stream`.

```scala
val ones: Stream[Int] =
  new Stream[Int] {
    def head: Int = ???
    def tail: Stream[Int] = ???
  }
```

Here I've used the anonymous subclass approach, so I can just write all the code in one place.

The next step is to fill in the method bodies. The first method, `head`, is trivial. The answer is `1` by definition.

```scala
val ones: Stream[Int] =
  new Stream[Int] {
    def head: Int = 1
    def tail: Stream[Int] = ???
  }
```

It's not so obvious what to do with `tail`. We want to return a `Stream[Int]` so we could apply structural corecursion again.

```scala
val ones: Stream[Int] =
  new Stream[Int] {
    def head: Int = 1
    def tail: Stream[Int] =
      new Stream[Int] {
        def head: Int = 1
        def tail: Stream[Int] = ???
      }
  }
```

This approach doesn't seem like it's going to work. We'll have to write this out an infinite number of times to correctly implement the method, which might be a problem.

Instead we can follow the types. We need to return a `Stream[Int]`. We have one in scope: `ones`. This is exactly the `Stream` we need to return: the infinite stream of ones!

```scala mdoc:silent
val ones: Stream[Int] =
  new Stream[Int] {
    def head: Int = 1
    def tail: Stream[Int] = ones
  }
```

You might be alarmed to see the circular reference to `ones` in `tail`. This works because it is within a method, and so is only evaluated when that method is called. This delaying of evaluation is what allows us to represent an infinite number of elements, as we only ever evaluate a finite portion of them. This is a core difference from data, which is fully evaluated when it is constructed.

Let's check that our definition of `ones` does indeed work.
We can't extract all the elements from an infinite `Stream` (at least, not in finite time) so in general we'll have to resort to checking a finite sequence of elements. 

```scala mdoc
ones.head
ones.tail.head
ones.tail.tail.head
```

This all looks correct. We'll often want to check our implementation in this way, so let's implement a method, `take`, to make this easier.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }
}
```

We can use either the structural recursion or structural corecursion strategies for data to implement `take`. Since we've already covered these in detail I won't go through them here. The important point is that `take` only uses the destructors when interacting with the `Stream`. 

Now we can more easily check our implementations are correct.

```scala mdoc:invisible
val ones: Stream[Int] =
  new Stream {
    def head: Int = 1

    def tail: Stream[Int] = ones
  }
```
```scala mdoc
ones.take(3)
```

For our next task we'll implement `map`. Implementing a method on `Stream` allows us to see both structural recursion and corecursion for codata in action. As usual we begin by writing out the method skeleton.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = 
    ???
    
  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }
}
```

Now we have a choice of strategy to use. Since we haven't used structural recursion yet, let's start with that. Since the input is codata, a `Stream`, the structural recursion strategy tells us we should consider using the destructors. Let's write them down to remind us of them.

```scala
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = {
    this.head ???
    this.tail ???
  }
    
  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }
}
```

To make progress we can follow the types or use structural corecursion. Let's choose corecursion to see another example of it in use.

```scala
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = {
    this.head ???
    this.tail ???
  }
    
  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }
}
```
`unfold`

Exercise: `filter`
Exercise: `zip`
Exercise: `scan`

Examples: natural

Effects, odd, and even.

Computing approximations to Pi.

Benefits:
- represent infinite things (like events)
- only take as much space as data that is processed





Now let's implement another method using structural corecursion. A good choice is `map`. We can start by writing out the method skeleton.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] =
    ???
}
```

Now we have two choices: we can use structural recursion (because `Stream` is an input) or we can use structural corecursion (because the output is also a `Stream`).

The first step in structural corecursion that produces codata is create the skeleton of an instance of the type we're creating. As this is codata we can create an anonymous subtype of `Stream`.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] =
    new Stream[B] {
      def isEmpty: Boolean = ???
      def head: B = ???
      def tail: Stream[B] = ???
    }
}
```

The next step is to fill out the implementations of `head` and `tail`. Here we have problem-specific parts, but we can follow the types to help us.

```scala mdoc:reset:silent
trait Stream[A] {
  def isEmpty: Boolean
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = {
    val source = this
    new Stream[B] {
      def isEmpty: Boolean = source.isEmpty
      def head: B = f(source.head)
      def tail: Stream[B] = source.tail.map(f)
    }
  }
}
```
```scala mdoc:reset:invisible
trait Stream[A] {
  def isEmpty: Boolean
  def head: A
  def tail: Stream[A]
  
  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => 
        if isEmpty then Nil
        else head :: tail.take(n - 1)
    }

  def map[B](f: A => B): Stream[B] = {
    val source = this
    new Stream[B] {
      def isEmpty: Boolean = source.isEmpty
      def head: B = f(source.head)
      def tail: Stream[B] = source.tail.map(f)
    }
  }
}
```
```scala mdoc:invisible
val ones: Stream[Int] =
  new Stream {
    def isEmpty: Boolean = false

    def head: Int = 1

    def tail: Stream[Int] = ones
  }
```

This seems correct, but it's always good to test our code. 
We can see that `map` is working as expected.

```scala mdoc
ones.map(_ + 1).take(3)
```
