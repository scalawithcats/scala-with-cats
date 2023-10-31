## Tail Recursive Interpreters

Structural recursion, as we have written it, uses the stack. This is not often a problem, but particularly deep recursions can lead to the stack running out of space. A solution is to write a **tail recursive** program. A tail recursive program does not need to use any stack space. Any program can be turned into a tail recursive version, though it can require a lot of changes to do this.

In this section we will discuss tail recursion, converting programs to tail recursive form, and limitations and workarounds for the JVM.


### Tail Position and Tail Calls

Our starting point is a **tail call**. A tail call is a method call that does not take any additional stack space. Only method calls that are in **tail position** are candidates to be turned into tail calls. Even then, not all call in tail position can be converted to tail calls due to runtime limitations.

A method call in tail position is a call that immediately returns the value of the call.
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
      case n => loop(count, accum + n)
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
case n => loop(count, accum + n)
```

is in tail position because the value returned by the call to `loop` is itself immediately returned.
Similarly, the call to `loop` in

```scala
loop(count, 0)
```

is also in tail position.

A method in tail position is a candidate to be turned into a tail call. Some languages will turn all calls in tail position into tail calls. However, limitations of the JVM and Javascript runtimes mean that this is not the case for Scala. (Scala Native may be getting full tail calls in the future.) In Scala, the only method calls that are converted to tail calls are calls in tail position by a method to itself. This means the call 

```scala
case n => loop(count, accum + n)
```

is converted to a tail call, because `loop` is calling itself. However, the call

```scala
loop(count, 0)
```

is not converted to a tail call, because the call is from `isTailRecursive` to `loop`.

All the method calls in `isTailRecursive` are tail calls. Therefore we can say the entire method is tail recursive and it should not consume any stack space when running.
We can ask the Scala compiler to check this for us by using the `@tailrec` annotation to the method.

```scala mdoc:reset-object:silent
import scala.annotation.tailrec

def isTailRecursive(count: Int): Int = {
  @tailrec
  def loop(count: Int, accum: Int): Int =
    count match {
      case 0 => accum
      case n => loop(count, accum + n)
    }
    
  loop(count, 0)
}
```

The code will fail to compile if the compiler cannot show that the method is tail recursive.

```scala mdoc:fail
@tailrec
def isntTailRecursive(count: Int): Int =
  count match {
    case 0 => 0
    case n => n + isntTailRecursive(n - 1)
  }
```


