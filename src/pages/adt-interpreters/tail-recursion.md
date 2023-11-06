## Tail Recursive Interpreters

Structural recursion, as we have written it, uses the stack. This is not often a problem, but particularly deep recursions can lead to the stack running out of space. A solution is to write a **tail recursive** program. A tail recursive program does not need to use any stack space, and so is sometimes known as **stack safe**. Any program can be turned into a tail recursive version, though it can require a lot of changes to do this.

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
Our first step is to understand what a **continuation** is.

A continuation is an encapsulation of "what happens next". Let's return to our `Regexp` example. Here's the full code for reference.

```scala mdoc:silent
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

What happens next when we call `loop(left, idx)`? Let's give the name `result` to the result of the call to `loop`. The answer is we run `result.flatMap(i => loop(right, i))`. We can represent this as a function, to which we pass `result`:

```scala
(opt: Option[Int]) => opt.flatMap(i => loop(right, i))
```

This is exactly the continuation, reified as a value. 

As is often the case, there is a distinction between the concept and the representation. 
The concept of continuations always exists in code.
A continuation means "what happens next". 
In other words, it is the program's control flow.
There is always some concept of control flow, even if it is just "the program halts". 
We can represent continuations as functions in code.
This transforms the abstract concept of continuations into concrete values in our program, and hence reifies them.

Now that we know about continuations, and their reification as functions, we can move on to continuation-passing style.
In CPS we, as the name suggests, pass around continuations.
Specifically, each function or method takes an extra parameter that is a continuation.
Instead of returning a value it calls that continuation with the value.
(This is another example of duality, in this case between returning a value and calling a continuation.)

Let's see how this works.
We'll start with a simple example written in the normal style, also known as direct style.

```scala mdoc:silent
(1 + 2) * 3
```

To rewrite this in CPS style we need to create replacements for `+` and `*` with the extra continuation parameter.

```scala mdoc:silent
type Cont = Int => Int

def add(x: Int, y: Int, k: Cont) = k(x + y)
def mul(x: Int, y: Int, k: Cont) = k(x * y)
```

Now we can rewrite this in CPS. `(1 + 2)` becomes `add(1, 2, k)`, but what is `k`, the continuation?
What we do next is multiply the result by `3`. In other words `a => mul(a, 3, k2)`. 
What is the next continuation, `k2`?
Here the program finishes, so we just return the value with the identity continuation `b => b`.
Put it all together and we get

```scala mdoc:silent
add(1, 2, a => mul(a, 3, b => b))
```

Notice that every continuation call is in tail position in the CPS code.
This means that code written in CPS can potentially consume no stack space.

Now we can return to the interpreter loop for `Regexp`.
We are going to CPS it, so we need to add an extra parameter for the continuation.
In this case the contination accepts and returns the result type of `loop`: `Option[Int]`.

```scala
def matches(input: String): Boolean = {
  // Define a type alias so we can easily write continuations
  type Cont = Option[Int] => Option[Int]

  def loop(regexp: Regexp, idx: Int, cont: Cont): Option[Int] =
  ...
}
```

Now we go through each case and convert it to CPS. Each continuation we construct must call `cont` as its final step.
This is tedious and a bit error-prone, so good tests are helpful.

```scala
def matches(input: String): Boolean = {
  // Define a type alias so we can easily write continuations
  type Cont = Option[Int] => Option[Int]

  def loop(
      regexp: Regexp,
      idx: Int,
      cont: Cont
  ): Option[Int] =
    regexp match {
      case Append(left, right) =>
        val k: Cont = _ match {
          case None    => cont(None)
          case Some(i) => loop(right, i, cont)
        }
        loop(left, idx, k)

      case OrElse(first, second) =>
        val k: Cont = _ match {
          case None => loop(second, idx, cont)
          case some => cont(some)
        }
        loop(first, idx, k)

      case Repeat(source) =>
        val k: Cont =
          _ match {
            case None    => cont(Some(idx))
            case Some(i) => loop(regexp, i, cont)
          }
        loop(source, idx, k)

      case Apply(string) =>
        cont(Option.when(input.startsWith(string, idx))(idx + string.size))
    }

  // Check we matched the entire input
  loop(this, 0, identity).map(idx => idx == input.size).getOrElse(false)
}
```

Every call in this interpreter loop is in tail position. However Scala cannot convert these to tail calls, because the calls go from `loop` to a continuation and vice versa.

To make the interpreter fully stack safe we need to add **trampolining**. 
A trampoline is a tail-recursive loop to which we return either a continuation or the final value.
If the trampoline receives a continuation is calls it, otherwise it stops and returns the value.
In terms of code, we need a type to represent the value the trampoline receives. I've called in `Resumable`.

```scala mdoc:silent
enum Resumable {
  case Done(result: Option[Int])
  case Resume(cont: () => Resumable)
}
```

The trampoline is a simple loop.

```scala mdoc:silent
def trampoline(resumable: Resumable): Option[Int] =
  resumable match {
    case Resumable.Done(result) => result
    case Resumable.Resume(cont) => trampoline(cont())
  }
```

We next need to change the interpreter so it returns a `Resumable` to the trampoline.
For example, we could write

```scala
def loop(
    regexp: Regexp,
    idx: Int,
    cont: Option[Int] => Resumable
): Resumable =
  Resumable.Resume(() => regexp match ...)
```

or we could change every call to `loop` in the body to return a `Resumable.Resume`, or every call to a continuation.
It doesn't really matter where we do this; we just have to make sure that only a finite amount of recursion can occur before we end up back in the trampoline.
Each time we return to the trampoline we unwind the stack, which is the secret to avoiding overflowing it.

Here's the implementation I came up with.

```scala 
def matches(input: String): Boolean = {
  enum Resumable {
    case Done(result: Option[Int])
    case Resume(cont: () => Resumable)
  }
  // Define a type alias so we can easily write continuations
  type Cont = Option[Int] => Resumable

  def loop(
      regexp: Regexp,
      idx: Int,
      cont: Option[Int] => Resumable
  ): Resumable =
    regexp match {
      case Append(left, right) =>
        val k: Cont = _ match {
          case None    => cont(None)
          case Some(i) => loop(right, i, cont)
        }
        Resumable.Resume(() => loop(left, idx, k))

      case OrElse(first, second) =>
        val k: Cont = _ match {
          case None => loop(second, idx, cont)
          case some => cont(some)
        }
        Resumable.Resume(() => loop(first, idx, k))

      case Repeat(source) =>
        val k: Cont =
          _ match {
            case None    => cont(Some(idx))
            case Some(i) => loop(regexp, i, cont)
          }
        Resumable.Resume(() => loop(source, idx, k))

      case Apply(string) =>
        Resumable.Resume(() =>
          cont(Option.when(input.startsWith(string, idx))(idx + string.size))
        )
    }

  def trampoline(cont: Resumable): Option[Int] =
    cont match {
      case Resumable.Done(result) => result
      case Resumable.Resume(cont) => trampoline(cont())
    }

  // Check we matched the entire input
  trampoline(loop(this, 0, opt => Resumable.Done(opt)))
    .map(idx => idx == input.size)
    .getOrElse(false)
}
```

Doing a full CPS conversion can be quite involved. Some methods can made tail recursive or stack safe without requiring full CPS.
Remember these examples we looked at earlier?

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
