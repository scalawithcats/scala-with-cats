#import "../stdlib.typ": info, warning, solution, exercise
== Structural Recursion and Corecursion for Codata


In this section we'll build a library for streams, also known as lazy lists. These are the codata equivalent of lists. Whereas a list must have a finite length, streams have an infinite length. We'll use this example to explore structural recursion and structural corecursion as applied to codata.

Let's start by reviewing structural recursion and corecursion. The key idea is to use the input or output type, respectively, to drive the process of writing the method. We've already seen how this works with data, where we emphasized structural recursion. With codata it's more often the case that structural corecursion is used. The steps for using structural corecursion are:

+ recognize the output of the method or function is codata;
+ write down the skeleton to construct an instance of the codata type, usually using an anonymous subclass; and
+ fill in the methods, where strategies such as structural recursion or following the types can help.

It's important that all computations are defined within the methods, and so only run when the methods are called. Once we start creating streams the importance of this will become clear.

For structural recursion the steps are:

+ recognize the input of the method or function is codata;
+ note the codata's destructors as possible sources of values in writing the method; and
+ complete the method, using strategies such as following the types or structural corecursion and the methods identified above.

Now on to creating streams. Our first step is to define our stream type. As this is codata, it is defined in terms of its destructors. The destructors that define a `Stream` of elements of type `A` are:

- a `head` of type `A`; and
- a `tail` of type `Stream[A]`.

Note these are almost the destructors of `List`. We haven't defined `isEmpty` as a destructor because our streams never end and thus this method would always return `false`#footnote[A lot of real implementations, such as the `LazyList` in the Scala standard library, do define such a method which allows them to represent finite and infinite lists in the same structure. We're not doing this for simplicity and because we want to work with codata in its purest form.].

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
ones.take(5)
```

For our next task we'll implement `map`. Implementing a method on `Stream` allows us to see both structural recursion and corecursion for codata in action. As usual we begin by writing out the method skeleton.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = 
    ???
}
```

Now we have a choice of strategy to use. Since we haven't used structural recursion yet, let's start with that. The input is codata, a `Stream`, and the structural recursion strategy tells us we should consider using the destructors. Let's write them down to remind us of them.

```scala
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = {
    this.head ???
    this.tail ???
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
    
    new Stream[B] {
      def head: B = ???
      def tail: Stream[B] = ???
    }
  }
}
```

Now we've used structural recursion and structural corecursion, a bit of following the types is in order. This quickly arrives at the correct solution.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]
  
  def map[B](f: A => B): Stream[B] = {
    val self = this 
    new Stream[B] {
      def head: B = f(self.head)
      def tail: Stream[B] = self.tail.map(f)
    }
  }
}
```

There are two important points. Firstly, notice how I gave the name `self` to `this`. This is so I can access the value inside the new `Stream` we are creating, where `this` would be bound to this new `Stream`. Next, notice that we access `self.head` and `self.tail` inside the methods on the new `Stream`. This maintains the correct semantics of only performing computation when it has been asked for. If we perform computation outside of the methods we create the possibility of infinite loops.

As our final example, let's return to constructing `Stream`, and implement the universal constructor `unfold`. We start with the skeleton for `unfold`, remembering the `seed` parameter.

```scala mdoc:reset:silent 
trait Stream[A] {
  def head: A
  def tail: Stream[A]
}
object Stream {
  def unfold[A, B](seed: A): Stream[B] =
    ???
}
```

It's natural to apply structural corecursion to make progress.

```scala mdoc:reset:silent 
trait Stream[A] {
  def head: A
  def tail: Stream[A]
}
object Stream {
  def unfold[A, B](seed: A): Stream[B] =
    new Stream[B]{
      def head: B = ???
      def tail: Stream[B] = ???
    }
}
```

Now we can follow the types, adding parameters as we need them. This gives us the complete method shown below.

```scala mdoc:reset:silent 
trait Stream[A] {
  def head: A
  def tail: Stream[A]
}
object Stream {
  def unfold[A, B](seed: A, f: A => B, next: A => A): Stream[B] =
    new Stream[B]{
      def head: B = 
        f(seed)
      def tail: Stream[B] = 
        unfold(next(seed), f, next)
    }
}
```

We can use this to implement some interesting streams. Here's a stream that alternates between `1` and `-1`.

```scala mdoc:reset:invisible
trait Stream[A] {
  def head: A
  def tail: Stream[A]

  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }
}
object Stream {
  def unfold[A, B](seed: A, f: A => B, next: A => A): Stream[B] =
    new Stream[B]{
      def head: B = 
        f(seed)
      def tail: Stream[B] = 
        unfold(next(seed), f, next)
    }
}
```

```scala mdoc:silent
val alternating = Stream.unfold(
  true, 
  x => if x then 1 else -1, 
  x => !x
)
```

We can check it works.

```scala mdoc
alternating.take(5)
```


#exercise[Stream Combinators]


It's time for you to get some practice with structural recursion and structural corecursion using codata.
Implement `filter`, `zip`, and `scanLeft` on `Stream`. They have the same semantics as the same methods on `List`, and the signatures shown below.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]

  def filter(pred: A => Boolean): Stream[A]
  def zip[B](that: Stream[B]): Stream[(A, B)]
  def scanLeft[B](zero: B)(f: (B, A) => B): Stream[B]
}
```

#solution[
For all of these methods I found that structural corecursion was the most natural way to tackle them. You could start with structural recursion, though.

You might be worried about the inefficiency of `filter`. That's something we'll discuss a bit later.

```scala mdoc:reset:silent
trait Stream[A] {
  def head: A
  def tail: Stream[A]

  def filter(pred: A => Boolean): Stream[A] = {
    val self = this
    new Stream[A] {
      def head: A = {
        def loop(stream: Stream[A]): A =
          if pred(stream.head) then stream.head
          else loop(stream.tail)
          
        loop(self)
      }
      
      def tail: Stream[A] = {
        def loop(stream: Stream[A]): Stream[A] =
          if pred(stream.head) then stream.tail.filter(pred)
          else loop(stream.tail)
          
        loop(self)
      }
    }
  }

  def zip[B](that: Stream[B]): Stream[(A, B)] = {
    val self = this 
    new Stream[(A, B)] {
      def head: (A, B) = (self.head, that.head)
      
      def tail: Stream[(A, B)] =
        self.tail.zip(that.tail)
    }
  }

  def scanLeft[B](zero: B)(f: (B, A) => B): Stream[B] = {
    val self = this
    new Stream[B] {
      def head: B = zero
      
      def tail: Stream[B] =
        self.tail.scanLeft(f(zero, self.head))(f)
    }
  }
}
```
]

We can do some neat things with the methods defined above. For example, here is the stream of natural numbers.

```scala mdoc:reset:invisible
trait Stream[A] {
  def head: A
  def tail: Stream[A]

  def filter(pred: A => Boolean): Stream[A] = {
    val self = this
    new Stream[A] {
      def head: A = {
        def loop(stream: Stream[A]): A =
          if pred(stream.head) then stream.head
          else loop(stream.tail)
          
        loop(self)
      }
      
      def tail: Stream[A] = {
        def loop(stream: Stream[A]): Stream[A] =
          if pred(stream.head) then stream.tail.filter(pred)
          else loop(stream.tail)
          
        loop(self)
      }
    }
  }

  def scanLeft[B](zero: B)(f: (B, A) => B): Stream[B] = {
    val self = this
    new Stream[B] {
      def head: B = zero
      
      def tail: Stream[B] =
        self.tail.scanLeft(f(zero, self.head))(f)
    }
  }

  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }

  def zip[B](that: Stream[B]): Stream[(A, B)] = {
    val self = this 
    new Stream[(A, B)] {
      def head: (A, B) = (self.head, that.head)
      
      def tail: Stream[(A, B)] =
        self.tail.zip(that.tail)
    }
  }

}
object Stream {
  def unfold[A, B](seed: A, f: A => B, next: A => A): Stream[B] =
    new Stream[B]{
      def head: B = 
        f(seed)
      def tail: Stream[B] = 
        unfold(next(seed), f, next)
    }
    
  val ones = unfold(1, identity, identity)
}
```

```scala mdoc:silent
val naturals = Stream.ones.scanLeft(0)((b, a) => b + a)
```

As usual, we should check it works.

```scala mdoc
naturals.take(5)
```

We could also define `naturals` using `unfold`. 
More interesting is defining it in terms of itself.

```scala mdoc:reset:invisible
trait Stream[A] {
  def head: A
  def tail: Stream[A]

  def +:(elt: => A): Stream[A] = {
    val self = this
    new Stream[A] {
      def head: A = elt
      def tail: Stream[A] = self
    }
  }

  def filter(pred: A => Boolean): Stream[A] = {
    val self = this
    new Stream[A] {
      def head: A = {
        def loop(stream: Stream[A]): A =
          if pred(stream.head) then stream.head
          else loop(stream.tail)
          
        loop(self)
      }
      
      def tail: Stream[A] = {
        def loop(stream: Stream[A]): Stream[A] =
          if pred(stream.head) then stream.tail.filter(pred)
          else loop(stream.tail)
          
        loop(self)
      }
    }
  }

  def map[B](f: A => B): Stream[B] = {
    val self = this
    new Stream[B] {
      def head: B = f(self.head)
      def tail: Stream[B] = self.tail.map(f)
    }
  }

  def scanLeft[B](zero: B)(f: (B, A) => B): Stream[B] = {
    val self = this
    new Stream[B] {
      def head: B = zero
      
      def tail: Stream[B] =
        self.tail.scanLeft(f(zero, self.head))(f)
    }
  }

  def take(count: Int): List[A] =
    count match {
      case 0 => Nil
      case n => head :: tail.take(n - 1)
    }

  def zip[B](that: Stream[B]): Stream[(A, B)] = {
    val self = this 
    new Stream[(A, B)] {
      def head: (A, B) = (self.head, that.head)
      
      def tail: Stream[(A, B)] =
        self.tail.zip(that.tail)
    }
  }

}
object Stream {
  def unfold[A, B](seed: A, f: A => B, next: A => A): Stream[B] =
    new Stream[B]{
      def head: B = 
        f(seed)
      def tail: Stream[B] = 
        unfold(next(seed), f, next)
    }
    
  val ones = unfold(1, identity, identity)
}
```
```scala mdoc:silent
val naturals: Stream[Int] =
  new Stream {
    def head = 1
    def tail = naturals.map(_ + 1)
  }
```

This might be confusing. If so, spend a bit of time thinking about it. It really does work!

```scala mdoc
naturals.take(5)
```


=== Efficiency and Effects


You may have noticed that our implement recomputes values, possibly many times. 
A good example is the implementation of `filter`.
This recalculates the `head` and `tail` on each call, which could be a very expensive operation.

```scala 
def filter(pred: A => Boolean): Stream[A] = {
  val self = this
  new Stream[A] {
    def head: A = {
      def loop(stream: Stream[A]): A =
        if pred(stream.head) then stream.head
        else loop(stream.tail)
        
      loop(self)
    }
    
    def tail: Stream[A] = {
      def loop(stream: Stream[A]): Stream[A] =
        if pred(stream.head) then stream.tail.filter(pred)
        else loop(stream.tail)
        
      loop(self)
    }
  }
}
```

We know that delaying the computation until the method is called is important, because that is how we can handle infinite and self-referential data. However we don't need to redo this computation on successive calls. We can instead cache the result from the first call and use that next time.
Scala makes this easy with `lazy val`, which is a `val` that is not computed until its first call.
Additionally, Scala's use of the *uniform access principle* means we can implement a method with no parameters using a `lazy val`.
Here's a quick example demonstrating it in use.

```scala mdoc:silent
def always[A](elt: => A): Stream[A] =
  new Stream[A] {
    lazy val head: A = elt
    lazy val tail: Stream[A] = always(head)
  }
  
val twos = always(2)
```

As usual we should check our work.

```scala mdoc
twos.take(5)
```

We get the same result whether we use a method or a `lazy val`, because we are assuming that we are only dealing with pure computations that have no dependency on state that might change. In this case a `lazy val` simply consumes additional space to save on time.

Recomputing a result every time it is needed is known as *call by name*, while caching the result the first time it is computed is known as *call by need*. These two different *evaluation strategies* can be applied to individual values, as we've done here, or across an entire programming. Haskell, for example, uses call by need; all values in Haskell are only computed the first time they are needed. Call by need is also commonly known as *lazy evaluation*. Another alternative, called *call by value*, computes results when they are defined instead of waiting until they are needed. This is the default in Scala.

We can illustrate the difference between call by name and call by need if we use an impure computation. 
For example, we can define a stream of random numbers.
Random number generators depend on some internal state.

Here's the call by name implementation, using the methods we have already defined.

```scala mdoc:silent
import scala.util.Random

val randoms: Stream[Double] = 
  Stream.unfold(Random, r => r.nextDouble(), r => r)
```

Notice that we get _different_ results each time we `take` a section of the `Stream`.
We would expect these results to be the same.

```scala mdoc
randoms.take(5)
randoms.take(5)
```

Now let's define the same stream in a call by need style, using `lazy val`.

```scala mdoc:silent
val randomsByNeed: Stream[Double] =
  new Stream[Double] {
    lazy val head: Double = Random.nextDouble()
    lazy val tail: Stream[Double] = randomsByNeed
  }
```

This time we get the _same_ result when we `take` a section, and each number is the same.

```scala mdoc
randomsByNeed.take(5)
randomsByNeed.take(5)
```

If we wanted a stream that had a different random number for each element but those numbers were constant, we could redefine `unfold` to use call by need.

```scala mdoc:silent
def unfoldByNeed[A, B](seed: A, f: A => B, next: A => A): Stream[B] =
  new Stream[B]{
    lazy val head: B = 
      f(seed)
    lazy val tail: Stream[B] = 
      unfoldByNeed(next(seed), f, next)
  }
```

Now redefining `randomsByNeed` using `unfoldByNeed` gives us the result we are after. First, redefine it.

```scala mdoc:silent
val randomsByNeed2 =
  unfoldByNeed(Random, r => r.nextDouble(), r => r)
```

Then check it works.

```scala mdoc
randomsByNeed2.take(5)
randomsByNeed2.take(5)
```

These subtleties are one of the reasons that functional programmers try to avoid using state as far as possible.
