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
If we look closely, we'll see that the tail recursive version computes `(((2) + 1) + 0)`.

