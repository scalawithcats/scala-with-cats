## Structural Corecursion and Infinite Codata

In this section we'll explore structural corecursion with an example of codata representing a potentially infinite set of elements. In particular, we will build a library for streams, sometimes known as lazy lists. These are the codata equivalent of lists. Where a list must have a finite length a stream's length may be unbounded.

Let's start by reviewing structural corecursion. The key idea is to use the output type of the method to drive the process of writing the method. We previously looked at structural corecursion when we were producing data.
In this case we saw that structural corecursion works by considering all the possible outputs, which are the constructors of the algebraic data type, and then working out the conditions under which we'd call each constructor. The process is similar for codata, but instead of considering each possible constructor we instead consider each method or function in the codata type, and what it's implementation should be.

We'll make this concrete by looking at an example. As mentioned in the introduction, we are going to work with potentially infinite streams. The destructors or observations that define a `Stream` of elements of type `A` are:

- `isEmpty` of type `Boolean`, true if this `Stream` has no more elements;
- a `head` of type `A`; and
- a `tail` of type `Stream[A]`.

Note these are exactly the destructors of `List`, but because we're implementing codata, not data, we can create an infinite 

We can translate this to Scala, as we've previously seen, giving us

```scala mdoc:silent
trait Stream[A] {
  def isEmpty: Boolean
  def head: A
  def tail: Stream[A]
}
```

As our first step let's create some instances of `Stream`. The simplest instance is the empty `Stream`.

```scala mdoc:silent
def empty[A]: Stream[A] =
  new Stream[A] {
    def isEmpty: Boolean = true

    def head: A =
      throw new UnsupportedOperationException("Cannot get the head of an empty Stream.")

    def tail: Stream[A] =
      throw new UnsupportedOperationException("Cannot get the tail of an empty Stream.")
  }
```

Having two methods throwing exceptions is a bit unsatisfactory, but unavoidable if we want to implement both finite and infinite lists in the one data type. If we only implemented infinite lists we would not need the `isEmpty` method and we could not implement `empty`. 

The methods are fairly straightforward to write, but we can try the usual strategies to help us. Following the types is not useful for `isEmpty`, as it returns a concrete type. However for `head` it quickly becomes apparent that we don't have any values of type `A` to return, so we're forced to throw an exception. For `tail` we could return `empty`, so here we have to rely on our understanding of how this method should behave in this case.

There are several craft level aspects to this code. I used an anonymous class to define `empty`. This is a convenient shortcut to avoid naming the profusion of subclasses of `Stream` that we'll require. We could have instead defined

```scala mdoc:silent
class Empty[A]() extends Stream[A] {
  def isEmpty: Boolean = true

  def head: A =
    throw new IllegalStateException("Cannot get the head of an empty Stream.")

  def tail: Stream[A] =
    throw new IllegalStateException("Cannot get the tail of an empty Stream.")
}
```

but this quickly becomes verbose.

It's necessary to define `empty` as a method, not a value using `val`, to handle the generic type `A`. This could be avoided if we made `Stream` covariant, which would allow us to define `empty` as a `Stream[Nothing]`. I'm avoiding variance in most of the code here, because I find that many people are not confident using it and it's a distraction from the main points we're looking at.

The empty `Stream` is certainly useful, but it's not the most exciting choice. Let's do something that really shows what we can do with codata and implement an infinite stream. In this case the infinite stream of ones.

```scala mdoc:silent
val ones: Stream[Int] =
  new Stream {
    def isEmpty: Boolean = false

    def head: Int = 1

    def tail: Stream[Int] = ones
  }
```

You might be alarmed to see the circular reference to `ones` in `tail`. This works because it is within a method, and so is only evaluated when that method is called. This delaying of evaluation is what allows us to represent an infinite number of elements, as we only ever evaluate a finite portion of them. This is a core difference from data, which is fully evaluated when it is constructed.

In writing `tail` we can make progress by following the types. We need to return a `Stream[Int]` and the only one available is `ones`.

Let's check that our definition of `ones` does indeed work.
We can't extract all the elements from an infinite `Stream` (at least, not in finite time) so in general we'll have to resort to checking a finite sequence of elements. 

```scala mdoc
ones.head
ones.tail.head
ones.tail.tail.head
```

We'll often want to check our implementation is this way, so let's implement a method, `take`, to make this easier.

```scala mdoc:reset:silent
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
}
```

We can use either the structural recursion or structural corecursion strategies for algebraic data to implement `take`. Since we've already covered these in detail I won't go through them here. The important point is that `take` only uses the destructors when interacting with the `Stream`. The pattern of code

**Describe derivation of this method. First, it's defined solely in terms of destructors. Second it's a structural recursion and structural corecursion. Then pattern for using codata / Stream**

Now we can more easily check our implementations are correct.

```scala mdoc:invisible
val ones: Stream[Int] =
  new Stream {
    def isEmpty: Boolean = false

    def head: Int = 1

    def tail: Stream[Int] = ones
  }
```
```scala mdoc
ones.take(3)
```


Now let's implement another method using structural corecursion. A good choice is `map`. We can start by writing out the method skeleton.

```scala mdoc:reset:silent
trait Stream[A] {
  def isEmpty: Boolean
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] =
    ???
}
```

The first step in structural corecursion that produces codata is create the skeleton of an instance of the type we're creating. As this is codata we can create an anonymous subtype of `Stream`.

```scala mdoc:reset:silent
trait Stream[A] {
  def isEmpty: Boolean
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
