## Tail Recursive Interpreters

Structural recursion, as we have written it, uses the stack. This is not often a problem, but particularly deep recursions can lead to the stack running out of space. A solution is to write a **tail recursive** program. A tail recursive program does not need to use any stack space. Any program can be turned into a tail recursive version, though it can require a lot of changes to do this.

In this section we will discuss tail recursion, converting programs to tail recursive form, and limitations and workarounds for the JVM.


### Tail Position and Tail Calls

Our starting point is a **tail call**. A tail call is a method call that does not take any additional stack space. Only method calls that are in **tail position** are candidates to be turned into tail calls. Even then, not all calls in tail position will be converted to tail calls due to runtime limitations.

A method call in tail position is a call that immediately returns the value returned by the call.
Below are two versions of a method to calculate the sum of the integers from 0 to `count`.

```scala mdoc:silent
def isntTailRecursive(count: Int): Int =
  count match {
    case 0 => 0
    case n => n + isntTailRecursive(n - 1)
  }

def isTailRecursive(count: Int): Int = {
  def loop(count: Int, accum: Int): Int =
    count match {
      case 0 => accum
      case n => loop(n - 1, accum + n)
    }
    
  loop(count, 0)
}
```

The method call to `isntTailRecursive` in

```scala
case n => n + isntTailRecursive(n - 1)
```

is not in tail position, because the value returned by the call is used in the addition.
However, the call to `loop` in

```scala
case n => loop(n - 1, accum + n)
```

is in tail position because the value returned by the call to `loop` is itself immediately returned.
Similarly, the call to `loop` in

```scala
loop(count, 0)
```

is also in tail position.

A method call in tail position is a candidate to be turned into a tail call. Limitations of the JVM and Javascript runtimes mean that not all calls in tail position can be made tail calls. (Scala Native may be getting full tail calls in the future.) In general, only calls in tail position from a method to itself will be converted to tail calls. This means

```scala
case n => loop(n - 1, accum + n)
```

is converted to a tail call, because `loop` is calling itself. However, the call

```scala
loop(count, 0)
```

is not converted to a tail call, because the call is from `isTailRecursive` to `loop`. 
This will not cause issues with stack consumption, however, because this call only happens once.

We can ask the Scala compiler to check that all self calls are in tail position  by adding the `@tailrec` annotation to a method.
The code will fail to compile if any calls from the method to itself are not in tail position.

```scala mdoc:reset-object:fail
import scala.annotation.tailrec

@tailrec
def isntTailRecursive(count: Int): Int =
  count match {
    case 0 => 0
    case n => n + isntTailRecursive(n - 1)
  }
```

```scala mdoc:invisible
def isntTailRecursive(count: Int): Int =
  count match {
    case 0 => 0
    case n => n + isntTailRecursive(n - 1)
  }

def isTailRecursive(count: Int): Int = {
  def loop(count: Int, accum: Int): Int =
    count match {
      case 0 => accum
      case n => loop(n - 1, accum + n)
    }
    
  loop(count, 0)
}
```

We can check the tail recursive version is truly tail recursive by passing it a very large input.
The non-tail recursive version crashes.

```scala
isntTailRecursive(100000)
// java.lang.StackOverflowError
```

The tail recursive version runs just fine.

```scala mdoc
isTailRecursive(100000)
```


### Converting To Tail Recursive Form

Any program can be converted to a tail recursive form, known as **continuation-passing style**, or CPS for short.
We'll look at two ways to do this. Firstly, the easy way when we can find a simple summary of the program's state, and then the full transformation when no such summary is available.

Let's start our discussion by looking at the two methods we've seen previously.

```scala mdoc:reset-object:silent
def isntTailRecursive(count: Int): Int =
  count match {
    case 0 => 0
    case n => n + isntTailRecursive(n - 1)
  }

def isTailRecursive(count: Int): Int = {
  def loop(count: Int, accum: Int): Int =
    count match {
      case 0 => accum
      case n => loop(n - 1, accum + n)
    }
    
  loop(count, 0)
}
```

Both methods calculate the sum of natural numbers from 0 to `count`. Let's us substitution to show how the stack is used by each method, for a small value of `count`.

```scala
isntTailRecursive(2)
// expands to
(2 match {
  case 0 => 0
  case n => n + isntTailRecursive(n - 1)
})
// expands to
(2 + isntTailRecursive(1))
// expands to
(2 + (1 match {
        case 0 => 0
        case n => n + isntTailRecursive(n - 1)
      }))
// expands to
(2 + (1 + isntTailRecursive(n - 1)))
// expands to
(2 + (1 + (0 match {
             case 0 => 0
             case n => n + isntTailRecursive(n - 1)
           })))
// expands to
(2 + (1 + (0)))
// expands to
3
```

Here each set of brackets indicates a new method call and hence a stack frame allocation.

Now let's do the same for `isTailRecursive`.

```scala
isTailRecursive(2)
// expands to
(loop(2, 0))
// expands to
(2 match {
   case 0 => 0
   case n => loop(n - 1, 0 + n)
 })
// expands to
(loop(1, 2))
// call to loop is a tail call, so no stack frame is allocated 
// expands to
(1 match {
   case 0 => 2
   case n => loop(n - 1, 2 + n)
 })
// expands to
(loop(0, 3))
// call to loop is a tail call, so no stack frame is allocated 
// expands to
(0 match {
   case 0 => 3
   case n => loop(n - 1, 3 + n)
 })
// expands to
(3)
// expands to
3
```

The non-tail recursive function computes the result `(2 + (1 + (0)))`
If we look closely, we'll see that the tail recursive version computes `(((2) + 1) + 0)`, which simply accumulates the result in the reverse order.
This works because addition is associative, meaning `(a + b) + c == a + (b + c)`.
This is our first criteria for using the "easy" method for converting to a tail recursive form: the operation that accumulates results must be associative.

The second criteria concerns the program being interpreted. It must be possible to represent any arbitrary portion of a program as a list. This is case above, where the "program" is simply a list of numbers. It's not the case for programs that are represented as trees, like `Regexp`. The problem with these structures is that we cannot remove part of the program and still have a valid program left over. For example, consider `case OrElse(first: Regexp, second: Regexp)`. If we remove `first` we aren't left with a valid `Regexp`, whereas if we remove an element from a `List` we're still left with a `List`.

If these two conditions hold, converting to a tail recursive form simply means:

1. create a nested method (I usually call this `loop`) with two parameters: a program and the accumulated result;
2. write the `loop` as a structural recursion;
3. the base case is to return the accumulator; and
4. recursive cases update the accumulator and tail call `loop`.

This method rarely works for interesting programs, for which we need to turn to full continuation-passing style. Our first step is to understand what a **continuation** is.

A continuation is an encapsulation of "what happens next". Let's return to our `Regexp` example. Here's the full code for reference.

```scala mdoc:invisible
enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*` : Regexp = this.repeat

  def matches(input: String): Boolean = {
    def loop(regexp: Regexp, idx: Int): Option[Int] =
      regexp match {
        case Append(left, right) =>
          loop(left, idx).flatMap(i => loop(right, i))
        case OrElse(first, second) => loop(first, idx).orElse(loop(second, idx))
        case Repeat(source) =>
          loop(source, idx)
            .map(i => loop(regexp, i).getOrElse(i))
            .orElse(Some(idx))
        case Apply(string) =>
          Option.when(input.startsWith(string, idx))(idx + string.size)
      }

    // Check we matched the entire input
    loop(this, 0).map(idx => idx == input.size).getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
}
object Regexp {
  def apply(string: String): Regexp =
    Apply(string)
}
```

Let's consider the case for `Append` in `matches`.

```scala
case Append(left, right) =>
  loop(left, idx).flatMap(i => loop(right, i))
```

What happens next when we call `loop(left, idx)`? The answer is `flatMap(i => loop(right, i))`, where we are calling `flatMap` on the `Option[Int]` returned from `loop(left, idx)`. We can represent this as a function:

```scala
(opt: Option[Int]) => opt.flatMap(i => loop(right, i))
```

This is exactly the continuation, reified as a value. As is often the case, there is a distinction between the concept and the representation. The concept of continutations always exists in code. It just means "what happens next" and there is always a concept of "what happens next" even that is just "the program halts". We can represent continuations as functions, making the concept concrete and hence reifying it.

Now that we know about continuations, and their reification as functions, we can move on to continuation-passing style.
In CPS we, as the name suggests, pass around continuations.
Specifically, in our interpreter loop we add an extra parameter for a continuation.
In the base cases of our structural recursion we pass the result to the continuation instead of directly returning a result.
In the recursive cases, we construct a continuation ... to be continued!
