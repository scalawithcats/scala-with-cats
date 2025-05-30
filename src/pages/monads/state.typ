#import "../stdlib.typ": info, warning, solution
== The State Monad 
<sec:monad:state>


[`cats.data.State`][cats.data.State]
allows us to pass additional state around as part of a computation.
We define `State` instances representing atomic state operations
and thread them together using `map` and `flatMap`.
In this way we can model mutable state in a purely functional way,
without using actual mutation.

=== Creating and Unpacking State


Boiled down to their simplest form,
instances of `State[S, A]` represent functions of type `S => (S, A)`.
`S` is the type of the state and `A` is the type of the result.

```scala mdoc:silent
import cats.data.State
```

```scala mdoc:silent
val a = State[Int, String]{ state =>
  (state, s"The state is $state")
}
```

In other words, an instance of `State` is a function
that does two things:

- transforms an input state to an output state;
- computes a result.

We can "run" our monad by supplying an initial state.
`State` provides three methods---`run`, `runS`, and `runA`---that return
different combinations of state and result.
Each method returns an instance of `Eval`,
which `State` uses to maintain stack safety.
We call the `value` method as usual to extract the actual result:

```scala mdoc
// Get the state and the result:
val (state, result) = a.run(10).value

// Get the state, ignore the result:
val justTheState = a.runS(10).value

// Get the result, ignore the state:
val justTheResult = a.runA(10).value
```

=== Composing and Transforming State


As we've seen with `Reader` and `Writer`,
the power of the `State` monad comes from combining instances.
The `map` and `flatMap` methods thread the state from one instance to another.
Each individual instance represents an atomic state transformation,
and their combination represents a complete sequence of changes:

```scala mdoc:invisible:reset-object
import cats.data.State
val a = State[Int, String]{ state =>
  (state, s"The state is $state")
}
```
```scala mdoc:silent
val step1 = State[Int, String]{ num =>
  val ans = num + 1
  (ans, s"Result of step1: $ans")
}

val step2 = State[Int, String]{ num =>
  val ans = num * 2
  (ans, s"Result of step2: $ans")
}

val both = for {
  a <- step1
  b <- step2
} yield (a, b)
```

```scala mdoc
val (state, result) = both.run(20).value
```

As you can see, in this example the final state
is the result of applying both transformations in sequence.
State is threaded from step to step
even though we don't interact with it in the for comprehension.

The general model for using the `State` monad
is to represent each step of a computation as an instance
and compose the steps using the standard monad operators.
Cats provides several convenience constructors for creating primitive steps:

  - `get` extracts the state as the result;
  - `set` updates the state and returns unit as the result;
  - `pure` ignores the state and returns a supplied result;
  - `inspect` extracts the state via a transformation function;
  - `modify` updates the state using an update function.

```scala mdoc
val getDemo = State.get[Int]
getDemo.run(10).value

val setDemo = State.set[Int](30)
setDemo.run(10).value

val pureDemo = State.pure[Int, String]("Result")
pureDemo.run(10).value

val inspectDemo = State.inspect[Int, String](x => s"${x}!")
inspectDemo.run(10).value

val modifyDemo = State.modify[Int](_ + 1)
modifyDemo.run(10).value
```

We can assemble these building blocks using a for comprehension.
We typically ignore the result of intermediate stages
that only represent transformations on the state:

```scala mdoc:silent:reset-object
import cats.data.State
import State._
```

```scala mdoc
val program: State[Int, (Int, Int, Int)] = for {
  a <- get[Int]
  _ <- set[Int](a + 1)
  b <- get[Int]
  _ <- modify[Int](_ + 1)
  c <- inspect[Int, Int](_ * 1000)
} yield (a, b, c)

val (state, result) = program.run(1).value
```

=== Exercise: Post-Order Calculator


The `State` monad allows us to implement
simple interpreters for complex expressions,
passing the values of mutable registers along with the result.
We can see a simple example of this by implementing
a calculator for post-order integer arithmetic expressions.

In case you haven't heard of post-order expressions before
(don't worry if you haven't),
they are a mathematical notation
where we write the operator _after_ its operands.
So, for example, instead of writing `1 + 2` we would write:

```scala
1 2 +
```

Although post-order expressions are difficult for humans to read,
they are easy to evaluate in code.
All we need to do is traverse the symbols from left to right,
carrying a _stack_ of operands with us as we go:

- when we see a number, we push it onto the stack;

- when we see an operator, we pop two operands off the stack,
  operate on them, and push the result in their place.

This allows us to evaluate complex expressions without using parentheses.
For example, we can evaluate `(1 + 2) * 3)` as follows:

```scala
1 2 + 3 * // see 1, push onto stack
2 + 3 *   // see 2, push onto stack
+ 3 *     // see +, pop 1 and 2 off of stack,
          //        push (1 + 2) = 3 in their place
3 3 *     // see 3, push onto stack
3 *       // see 3, push onto stack
*         // see *, pop 3 and 3 off of stack,
          //        push (3 * 3) = 9 in their place
```

Let's write an interpreter for these expressions.
We can parse each symbol into a `State` instance
representing a transformation on the stack
and an intermediate result.
The `State` instances can be threaded together using `flatMap`
to produce an interpreter for any sequence of symbols.

Start by writing a function `evalOne` that
parses a single symbol into an instance of `State`.
Use the code below as a template.
Don't worry about error handling for now---if
the stack is in the wrong configuration,
it's OK to throw an exception.

```scala mdoc:reset:silent
import cats.data.State

type CalcState[A] = State[List[Int], A]

def evalOne(sym: String): CalcState[Int] = ???
```

If this seems difficult,
think about the basic form of the `State` instances you're returning.
Each instance represents a functional transformation
from a stack to a pair of a stack and a result.
You can ignore any wider context and focus on just that one step:

```scala mdoc:invisible
def someTransformation(input: List[Int]): List[Int] = input
def someCalculation: Int = 123
```

```scala mdoc:silent
State[List[Int], Int] { oldStack =>
  val newStack = someTransformation(oldStack)
  val result   = someCalculation
  (newStack, result)
}
```

Feel free to write your `Stack` instances in this form
or as sequences of the convenience constructors we saw above.

#solution[
The stack operation required is different for operators and operands.
For clarity we'll implement `evalOne` in terms of two helper functions,
one for each case:

```scala mdoc:invisible:reset-object
import cats.data.State

type CalcState[A] = State[List[Int], A]
```
```scala
def evalOne(sym: String): CalcState[Int] =
  sym match {
    case "+" => operator(_ + _)
    case "-" => operator(_ - _)
    case "*" => operator(_ * _)
    case "/" => operator(_ / _)
    case num => operand(num.toInt)
  }
```

Let's look at `operand` first.
All we have to do is push a number onto the stack.
We also return the operand as an intermediate result:

```scala mdoc:silent
def operand(num: Int): CalcState[Int] =
  State[List[Int], Int] { stack =>
    (num :: stack, num)
  }
```

The `operator` function is a little more complex.
We have to pop two operands off the stack 
(having the second operand at the top of the stack)i
and push the result in their place.
The code can fail if the stack doesn't have enough operands on it,
but the exercise description allows us to throw an exception in this case:

```scala mdoc:silent
def operator(func: (Int, Int) => Int): CalcState[Int] =
  State[List[Int], Int] {
    case b :: a :: tail =>
      val ans = func(a, b)
      (ans :: tail, ans)

    case _ =>
      sys.error("Fail!")
  }
```

```scala mdoc:invisible
def evalOne(sym: String): CalcState[Int] =
  sym match {
    case "+" => operator(_ + _)
    case "-" => operator(_ - _)
    case "*" => operator(_ * _)
    case "/" => operator(_ / _)
    case num => operand(num.toInt)
  }
```
]

`evalOne` allows us to evaluate single-symbol expressions as follows.
We call `runA` supplying `Nil` as an initial stack,
and call `value` to unpack the resulting `Eval` instance:

```scala mdoc
evalOne("42").runA(Nil).value
```

We can represent more complex programs using `evalOne`, `map`, and `flatMap`.
Note that most of the work is happening on the stack,
so we ignore the results of the intermediate steps for `evalOne("1")` and `evalOne("2")`:

```scala mdoc
val program = for {
  _   <- evalOne("1")
  _   <- evalOne("2")
  ans <- evalOne("+")
} yield ans

program.runA(Nil).value
```

Generalise this example by writing an `evalAll` method
that computes the result of a `List[String]`.
Use `evalOne` to process each symbol,
and thread the resulting `State` monads together using `flatMap`.
Your function should have the following signature:

```scala mdoc:silent
def evalAll(input: List[String]): CalcState[Int] =
  ???
```

#solution[
We implement `evalAll` by folding over the input.
We start with a pure `CalcState` that returns `0` if the list is empty.
We `flatMap` at each stage,
ignoring the intermediate results as we saw in the example:

```scala mdoc:invisible:reset-object
import cats.data.State

type CalcState[A] = State[List[Int], A]
def operand(num: Int): CalcState[Int] =
  State[List[Int], Int] { stack =>
    (num :: stack, num)
  }
def operator(func: (Int, Int) => Int): CalcState[Int] =
  State[List[Int], Int] {
    case b :: a :: tail =>
      val ans = func(a, b)
      (ans :: tail, ans)

    case _ =>
      sys.error("Fail!")
  }
def evalOne(sym: String): CalcState[Int] =
  sym match {
    case "+" => operator(_ + _)
    case "-" => operator(_ - _)
    case "*" => operator(_ * _)
    case "/" => operator(_ / _)
    case num => operand(num.toInt)
  }
```
```scala mdoc:silent
import cats.syntax.applicative._ // for pure

def evalAll(input: List[String]): CalcState[Int] =
  input.foldLeft(0.pure[CalcState]) { (a, b) =>
    a.flatMap(_ => evalOne(b))
  }
```

]

We can use `evalAll` to conveniently evaluate multi-stage expressions:

```scala mdoc
val multistageProgram = evalAll(List("1", "2", "+", "3", "*"))

multistageProgram.runA(Nil).value
```

Because `evalOne` and `evalAll` both return instances of `State`,
we can thread these results together using `flatMap`.
`evalOne` produces a simple stack transformation and
`evalAll` produces a complex one, but they're both pure functions
and we can use them in any order as many times as we like:

```scala mdoc
val biggerProgram = for {
  _   <- evalAll(List("1", "2", "+"))
  _   <- evalAll(List("3", "4", "+"))
  ans <- evalOne("*")
} yield ans

biggerProgram.runA(Nil).value
```

Complete the exercise by implementing an `evalInput` function that
splits an input `String` into symbols, calls `evalAll`,
and runs the result with an initial stack.

#solution[
We've done all the hard work now.
All we need to do is split the input into terms
and call `runA` and `value` to unpack the result:

```scala mdoc:silent
def evalInput(input: String): Int =
  evalAll(input.split(" ").toList).runA(Nil).value
```

```scala mdoc
evalInput("1 2 + 3 4 + *")
```
]
