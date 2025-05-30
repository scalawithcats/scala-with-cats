#import "../stdlib.typ": info, warning, solution
== Tail Recursive Interpreters


Structural recursion, as we have written it, uses the stack. This is not often a problem, but particularly deep recursions can lead to the stack running out of space. A solution is to write a *tail recursive* program. A tail recursive program does not need to use any stack space, and so is sometimes known as *stack safe*. Any program can be turned into a tail recursive version, which does not use the stack and therefore cannot run out of stack space.

#info[
==== The Call Stack {-}


Method and function calls are usually implemented using an area of memory known as the call stack, or just the stack for short.
Every method or function call uses a small amount of memory on the stack, called a stack frame.
When the method or function returns, this memory is freed and becomes available for future calls to use.

A large number of method calls, without corresponding returns, can require more stack frames than the stack can accommodate. When there is no more memory available on the stack we say we have overflowed the stack. In Scala a `StackOverflowError` is raised when this happens. 
]

In this section we will discuss tail recursion, converting programs to tail recursive form, and limitations and workarounds for the Scala's runtimes.


=== The Problem of Stack Safety


Let's start by seeing the problem. In Scala we can create a repeated `String` using the `*` method.

```scala mdoc
"a" * 4
```

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
        case OrElse(first, second) =>
          loop(first, idx).orElse(loop(second, idx))
        case Repeat(source) =>
          loop(source, idx)
            .flatMap(i => loop(regexp, i))
            .orElse(Some(idx))
        case Apply(string) =>
          Option.when(input.startsWith(string, idx))(idx + string.size)
        case Empty =>
          None
      }

    // Check we matched the entire input
    loop(this, 0).map(idx => idx == input.size).getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Empty
}
object Regexp {
  def apply(string: String): Regexp =
    Apply(string)
}
```

We can match such a `String` with a regular expression and `repeat`.

```scala mdoc
Regexp("a").repeat.matches("a" * 4)
```

However, if we make the input very long the interpreter will fail with a stack overflow exception.

```scala
Regexp("a").repeat.matches("a" * 20000)
// java.lang.StackOverflowError
```

This is because the interpreter calls `loop` for each instance of a repeat, without returning. However, all is not lost. We can rewrite the interpreter in a way that consumes a fixed amount of stack space, and therefore match input that is as large as we like.


=== Tail Calls and Tail Position


Our starting point is *tail calls*. A tail call is a method call that does not take any additional stack space. Only method calls that are in *tail position* are candidates to be turned into tail calls. Even then, runtime limitations mean that not all calls in tail position will be converted to tail calls.

A method call in tail position is a call that immediately returns the value returned by the call.
Let's see an example.
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

is not in tail position, because the value returned by the call is then used in the addition.
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

A method call in tail position is a candidate to be turned into a tail call. Limitations of Scala's runtimes mean that not all calls in tail position can be made tail calls. Currently, only calls from a method to itself that are also in tail position will be converted to tail calls. This means

```scala
case n => loop(n - 1, accum + n)
```

is converted to a tail call, because `loop` is calling itself. However, the call

```scala
loop(count, 0)
```

is not converted to a tail call, because the call is from `isTailRecursive` to `loop`. 
This will not cause issues with stack consumption, however, because this call only happens once.

#info[
==== Runtimes and Tail Calls {-}


Scala supports three different platforms: the JVM, Javascript via Scala.js, and native code via Scala Native. Each platform provides what is known as a runtime, which is code that supports our Scala code when it is running. The garbage collector, for example, is part of the runtime.

At the time of writing none of Scala's runtimes support full tail calls. However, there is reason to think this may change in the future. #link("https://wiki.openjdk.org/display/loom/Main")[Project Loom] should eventually add support for tail calls to the JVM. Scala Native is likely to support tail calls soon, as part of other work to implement continuations. Tail calls have been part of the Javascript specification for a long time, but remain unimplemented by the majority of Javascript runtimes. However, WebAssembly does support tail calls and will probably replace compiling Scala to Javascript in the medium term.
]

We can ask the Scala compiler to check that all self calls are in tail position by adding the `@tailrec` annotation to a method.
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


=== Continuation-Passing Style


Now that we know about tail calls, how do we convert the regular expression interpreter to use them? Any program can be converted to an equivalent program with all calls in tail position. This conversion is known as *continuation-passing style* or CPS for short. Our first step to understanding CPS is to understand *continuations*.

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
        case OrElse(first, second) =>
          loop(first, idx).orElse(loop(second, idx))
        case Repeat(source) =>
          loop(source, idx)
            .flatMap(i => loop(regexp, i))
            .orElse(Some(idx))
        case Apply(string) =>
          Option.when(input.startsWith(string, idx))(idx + string.size)
        case Empty =>
          None
      }

    // Check we matched the entire input
    loop(this, 0).map(idx => idx == input.size).getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Empty
}
object Regexp {
  val empty: Regexp = Empty

  def apply(string: String): Regexp =
    Apply(string)
}
```

Let's consider the case for `Append` in `matches`.

```scala
case Append(left, right) =>
  loop(left, idx).flatMap(i => loop(right, i))
```

What happens next when we call `loop(left, idx)`? Let's give the name `result` to the value returned by the call to `loop`. The answer is we run `result.flatMap(i => loop(right, i))`. We can represent this as a function, to which we pass `result`:

```scala
(result: Option[Int]) => result.flatMap(i => loop(right, i))
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
This is another example of duality, in this case between returning a value and calling a continuation.

Let's see how this works.
We'll start with a simple example written in the normal style, also known as *direct style*.

```scala mdoc
(1 + 2) * 3
```

To rewrite this in CPS style we need to create replacements for `+` and `*` with the extra continuation parameter.

```scala mdoc:silent
type Continuation = Int => Int

def add(x: Int, y: Int, k: Continuation) = k(x + y)
def mul(x: Int, y: Int, k: Continuation) = k(x * y)
```

Now we can rewrite our example in CPS. `(1 + 2)` becomes `add(1, 2, k)`, but what is `k`, the continuation?
What we do next is multiply the result by `3`. Thus the continuation is `a => mul(a, 3, k2)`. 
What is the next continuation, `k2`?
Here the program finishes, so we just return the value with the identity continuation `b => b`.
Put it all together and we get

```scala mdoc
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
  type Continuation = Option[Int] => Option[Int]

  def loop(regexp: Regexp, idx: Int, cont: Continuation): Option[Int] =
  // etc...
}
```

Now we go through each case and convert it to CPS. Each continuation we construct must call `cont` as its final step.
This is tedious and a bit error-prone, so good tests are helpful.

```scala
def matches(input: String): Boolean = {
  // Define a type alias so we can easily write continuations
  type Continuation = Option[Int] => Option[Int]

  def loop(
      regexp: Regexp,
      idx: Int,
      cont: Continuation
  ): Option[Int] =
    regexp match {
      case Append(left, right) =>
        val k: Continuation = _ match {
          case None    => cont(None)
          case Some(i) => loop(right, i, cont)
        }
        loop(left, idx, k)

      case OrElse(first, second) =>
        val k: Continuation = _ match {
          case None => loop(second, idx, cont)
          case some => cont(some)
        }
        loop(first, idx, k)

      case Repeat(source) =>
        val k: Continuation =
          _ match {
            case None    => cont(Some(idx))
            case Some(i) => loop(regexp, i, cont)
          }
        loop(source, idx, k)

      case Apply(string) =>
        cont(Option.when(input.startsWith(string, idx))(idx + string.size))
        
      case Empty =>
        cont(None)
    }

  // Check we matched the entire input
  loop(this, 0, identity).map(idx => idx == input.size).getOrElse(false)
}
```

Every call in this interpreter loop is in tail position. However Scala cannot convert these to tail calls because the calls go from `loop` to a continuation and vice versa. To make the interpreter fully stack safe we need to add *trampolining*. 


==== Exercise: CPS Arithmetic {-}


In a previous exercise we wrote an interpreter for arithmetic expressions. Your task now is to CPS this interpreter.
For reference, the definition of an arithmetic expression is:

- a literal number, which takes a `Double` and produces an `Expression`;
- an addition of two expressions;
- a substraction of two expressions;
- a multiplication of two expressions; or
- a division of two expressions;

#solution[
The continuations have a slightly different structure to the regular expression example.
In the regular expression example, all the information needs by a continuation is either found in the parameter to the continuation (the index) or values extracted via pattern matching.
In the arithmetic code we need values from previous continuations that are not passed as parameters.
This is to compute binary operations like additions.
The solution is to capture these values within the environment of the closure that represents the continuation.

```scala mdoc:reset:silent
type Continuation = Double => Double

enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)

  def eval: Double = {
    def loop(expr: Expression, cont: Continuation): Double =
      expr match {
        case Literal(value) => cont(value)
        case Addition(left, right) =>
          loop(left, l => loop(right, r => cont(l + r)))
        case Subtraction(left, right) =>
          loop(left, l => loop(right, r => cont(l - r)))
        case Multiplication(left, right) =>
          loop(left, l => loop(right, r => cont(l * r)))
        case Division(left, right) =>
          loop(left, l => loop(right, r => cont(l / r)))
      }

    loop(this, identity)
  }
  
  def +(that: Expression): Expression =
    Addition(this, that)

  def -(that: Expression): Expression =
    Subtraction(this, that)

  def *(that: Expression): Expression =
    Multiplication(this, that)

  def /(that: Expression): Expression =
    Division(this, that)
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```
]


=== Trampolining


Earlier we said that CPS utilizes the duality between function calls and returns: instead of returning a value we call a function with a value. This allows us to transform our code so it only has calls in tail positions. However, we still have a problem with stack safety. Scala's runtimes don't support full tail calls, so calls from a continuation to `loop` or from `loop` to a continuation will use a stack frame. We can use this same duality to avoid using the stack by, instead of making a call, returning a value that reifies the call we want to make. This idea is the core of trampolining. Let's see it in action, which will help clear up what exactly this all means.

Our first step is to reify all the method calls made by the interpreter loop and the continuations.
There are three cases: calls to `loop`, calls to a continuation, and, to avoid an infinite loop, the case when we're done.

```scala
type Continuation = Option[Int] => Call

enum Call {
  case Loop(regexp: Regexp, index: Int, continuation: Continuation)
  case Continue(index: Option[Int], continuation: Continuation)
  case Done(index: Option[Int])
}
```

Now we update `loop` to return instances of `Call` instead of making the calls directly.

```scala
def loop(regexp: Regexp, idx: Int, cont: Continuation): Call =
  regexp match {
    case Append(left, right) =>
      val k: Continuation = _ match {
        case None    => Call.Continue(None, cont)
        case Some(i) => Call.Loop(right, i, cont)
      }
      Call.Loop(left, idx, k)

    case OrElse(first, second) =>
      val k: Continuation = _ match {
        case None => Call.Loop(second, idx, cont)
        case some => Call.Continue(some, cont)
      }
      Call.Loop(first, idx, k)

    case Repeat(source) =>
      val k: Continuation =
        _ match {
          case None    => Call.Continue(Some(idx), cont)
          case Some(i) => Call.Loop(regexp, i, cont)
        }
      Call.Loop(source, idx, k)

    case Apply(string) =>
      Call.Continue(
        Option.when(input.startsWith(string, idx))(idx + string.size),
        cont
      )

    case Empty =>
      Call.Continue(None, cont)
  }
```

This gives us an interpreter loop that returns values instead of making calls, and so does not consume stack space.
However, we need to actually make these calls at some point, and doing this is the job of the trampoline.
The trampoline is simply a tail recursive loop that makes calls until it reaches `Done`.

```scala
def trampoline(next: Call): Option[Int] =
  next match {
    case Call.Loop(regexp, index, continuation) =>
      trampoline(loop(regexp, index, continuation))
    case Call.Continue(index, continuation) =>
      trampoline(continuation(index))
    case Call.Done(index) => index
  }
```

Now every call has a corresponding return, so the stack usage is limited. 
Our interpreter can handle input of any size, up to the limits of available memory.

Here's the complete code for reference.

```scala mdoc:reset:silent
// Define a type alias so we can easily write continuations
type Continuation = Option[Int] => Call

enum Call {
  case Loop(regexp: Regexp, index: Int, continuation: Continuation)
  case Continue(index: Option[Int], continuation: Continuation)
  case Done(index: Option[Int])
}

enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*` : Regexp = this.repeat

  def matches(input: String): Boolean = {
    def loop(regexp: Regexp, idx: Int, cont: Continuation): Call =
      regexp match {
        case Append(left, right) =>
          val k: Continuation = _ match {
            case None    => Call.Continue(None, cont)
            case Some(i) => Call.Loop(right, i, cont)
          }
          Call.Loop(left, idx, k)

        case OrElse(first, second) =>
          val k: Continuation = _ match {
            case None => Call.Loop(second, idx, cont)
            case some => Call.Continue(some, cont)
          }
          Call.Loop(first, idx, k)

        case Repeat(source) =>
          val k: Continuation =
            _ match {
              case None    => Call.Continue(Some(idx), cont)
              case Some(i) => Call.Loop(regexp, i, cont)
            }
          Call.Loop(source, idx, k)

        case Apply(string) =>
          Call.Continue(
            Option.when(input.startsWith(string, idx))(idx + string.size),
            cont
          )

        case Empty =>
          Call.Continue(None, cont)
      }

    def trampoline(next: Call): Option[Int] =
      next match {
        case Call.Loop(regexp, index, continuation) =>
          trampoline(loop(regexp, index, continuation))
        case Call.Continue(index, continuation) =>
          trampoline(continuation(index))
        case Call.Done(index) => index
      }

    // Check we matched the entire input
    trampoline(loop(this, 0, opt => Call.Done(opt)))
      .map(idx => idx == input.size)
      .getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Empty
}
object Regexp {
  val empty: Regexp = Empty

  def apply(string: String): Regexp =
    Apply(string)
}
```


==== Exericse: Trampolined Arithmetic {-}


Convert the CPSed arithmetic interpreter we wrote earlier to a trampolined version.

#solution[
The process to produce this code is very similar to the regular expression example.
We just identify all the different types of calls (which are the same as the regular expression example) and reify them.

```scala mdoc:reset:silent
type Continuation = Double => Call

enum Call {
  case Continue(value: Double, k: Continuation)
  case Loop(expr: Expression, k: Continuation)
  case Done(result: Double)
}

enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)

  def eval: Double = {
    def loop(expr: Expression, cont: Continuation): Call =
      expr match {
        case Literal(value) => Call.Continue(value, cont)
        case Addition(left, right) =>
          Call.Loop(
            left,
            l => Call.Loop(right, r => Call.Continue(l + r, cont))
          )
        case Subtraction(left, right) =>
          Call.Loop(
            left,
            l => Call.Loop(right, r => Call.Continue(l - r, cont))
          )
        case Multiplication(left, right) =>
          Call.Loop(
            left,
            l => Call.Loop(right, r => Call.Continue(l * r, cont))
          )
        case Division(left, right) =>
          Call.Loop(
            left,
            l => Call.Loop(right, r => Call.Continue(l / r, cont))
          )
      }

    def trampoline(call: Call): Double =
      call match {
        case Call.Continue(value, k) => trampoline(k(value))
        case Call.Loop(expr, k)      => trampoline(loop(expr, k))
        case Call.Done(result)       => result
      }

    trampoline(loop(this, x => Call.Done(x)))
  }

  def +(that: Expression): Expression =
    Addition(this, that)

  def -(that: Expression): Expression =
    Subtraction(this, that)

  def *(that: Expression): Expression =
    Multiplication(this, that)

  def /(that: Expression): Expression =
    Division(this, that)
}
object Expression {
  def apply(value: Double): Expression =
    Literal(value)
}
```
]


=== When Tail Recursion is Easy


Doing a full CPS conversion and trampoline can be quite involved. Some methods can made tail recursive without so large a change.
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

The tail recursive version doesn't seem to involve the complexity of CPS. How can we relate this to what we've just learned, and when can we avoid the work of CPS and trampolining?

Let's use substitution to show how the stack is used by each method, for a small value of `count`.

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

This doesn't explain, though, how we come to realize that addition is the correct operation to use. The second criteria is that we don't need any memory beyond the partial result calculated from the data we've already seen. Some implications of this are that we can stop at any time and have a usable result, and that we are only applying a single operation to the data. This is not the case in the regular expression example. For example, we have the following code in the `Append` case:

```scala
case Append(left, right) =>
  loop(left, idx).flatMap(i => loop(right, i))
```

To compute the result for the `Append` we need to compute and combine results from both `left` and `right`. So when we have computed the result for `right` we need to remember both the result from `left` and that we're combining the two results using the rule for `Append` rather than, say, `OrElse`. It's remembering this that is exactly what the continuation does, and what stops us from using the easy method we saw when summing the elements of a list.

So, in summary, if we are applying only a single associative operation to data we can use the simple method for writing a tail recursive method:

+ define an structurally recursive loop with an additional parameter that is the partial result or accumulator;
+ in the base cases return the accumulator; and
+ in the recursive cases update the accumulator and call the loop in tail position.

You might be wondering how we handle tree-shaped data with this technique. One consequence of an associative operation is that we can transform any sequence of operations into a list-shaped sequence. If, for example, we have an expression tree that suggests we should call operations in the order `(1 + 2) + (3 + 4)` (where I'm using `+` to indicate the operation) we can rewrite that to `(((1 + 2) + 3) + 4)` via associativity. So we can transform our tree into a list and then apply the recipe above.
