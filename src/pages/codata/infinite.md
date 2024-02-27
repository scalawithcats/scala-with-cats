## Structural Corecursion and Infinite Codata

In this section we'll explore structural corecursion with an example that shows codata representing an: streams of elements. These are the codata equivalent of lists, except where a list must have a finite length a stream's length can be unbounded.

Let's start by reviewing structural corecursion. We previously looked at structural corecursion when we were producing data.
We saw that structural corecursion works by considering all the possible outputs, which are the constructors of the algebraic data type, and then working out the conditions under which we'd call each constructor. It's similar for codata, but instead of considering each possible constructor we instead consider each method or function in the codata type, and what it's implementation should be.

We'll make this concrete by looking at an example. As mentioned in the introduction, we are going to work with infinite streams. A `Stream` of elements of type `A` is:

- a `head` of type `A`; and
- a `tail` of type `Stream[A]`.

Notice the similarity to `List`, but the lack of the base case means a `Stream` never ends.

We can translate this to Scala, as we've previously seen, giving us

```scala mdoc:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
}
```

As our first step let's see how to create instances of `Stream`. that we need to create an instance of `Stream`. The simplest constructor takes a `head` and a `tail`. It's important that these parameters are call-by-name so we don't end up with an infinite loop when we create instances.

```scala mdoc:silent
object Stream {
  def apply[A](hd: => A, tl: => Stream[A]): Stream[A] =
    new Stream {
      def head: A = hd
      def tail: Stream[A] = tl
    }
}
```


Now let's implement a method using structural corecursion. A good choice is `map`. We can start by writing out the method skeleton.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] =
    ???
}
```

The first step in structural corecursion that produces codata is create the skeleton of an instance of the type we're creating. As this is codata we can create an anonymous subtype of `Stream`.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] =
    new Stream[B] {
      def head: B = ???
      def tail: Stream[B] = ???
    }
}
```

The next step is to fill out the implementations of `head` and `tail`. Here we have problem-specific parts, but we can follow the types to help us.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = {
    val source = this
    new Stream[B] {
      def head: B = f(source.head)
      def tail: Stream[B] = source.tail.map(f)
    }
  }
}
```

This seems correct, but it's always good to test our code. 


Now we create an instance. Notice how we can define this

```scala mdoc:silent
val ones: Stream[Int] = Stream(1, ones)
```

First, let's check that this does indeed work.

```scala mdoc
ones.head
ones.tail.head
ones.tail.tail.head
```

Now we can see that `map` is working as expected.

```scala mdoc:silent
val twos = ones.map(_ + 1)
```

```scala mdoc
twos.head
twos.tail.head
twos.tail.tail.head
```
