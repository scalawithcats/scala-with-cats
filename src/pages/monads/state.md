## The *State* Monad

[`cats.data.State`][cats.data.State] allows us to pass additional state around as part of a computation.
We define `State` instances representing atomic operations on the state,
and thread them together using `map` and `flatMap`.
In this way we can model "mutable" state without in a purely functional way without using mutation.

### Creating and Unpacking State

Boiled down to its simplest form, instances of `State[S, A]` represent functions of type `S => (S, A)`.
`S` is the type of the state and and `A` is the type of the result.

```scala
import cats.data.State
// import cats.data.State

val a = State[Int, String] { state =>
  (state, s"The state is $state")
}
// a: cats.data.State[Int,String] = cats.data.StateT@766a2ae8
```

In other words, an instance of `State` is a combination of two things:

- a transformation from an input state to an output state;
- a computation of a result.

We can "run" our monad by supplying an initial state.
`State` provides three methods---`run`, `runS`, and `runA`---that return
different combinations of state and result as follows:

```scala
// Get the state and the result:
val (state, result) = a.run(10).value
// state: Int = 10
// result: String = The state is 10

// Get the state, ignore the result:
val state = a.runS(10).value
// state: Int = 10

// Get the result, ignore the state:
val result = a.runA(10).value
// result: String = The state is 10
```

### Composing and Transforming State

As we've seen with `Reader` and `Writer`,
the power of the `State` monad comes from combining instances.
The `map` and `flatMap` methods thread the `State` from one instance to another.
Because each primitive instance represents a transformation on the state,
the combined instance represents a more complex transformation.

```scala
val step1 = State[Int, String] { num =>
  val ans = num + 1
  (ans, s"Result of step1: $ans")
}
// step1: cats.data.State[Int,String] = cats.data.StateT@3bb99894

val step2 = State[Int, String] { num =>
  val ans = num * 2
  (ans, s"Result of step2: $ans")
}
// step2: cats.data.State[Int,String] = cats.data.StateT@1580014d

val both = for {
  a <- step1
  b <- step2
} yield (a, b)
// both: cats.data.StateT[cats.Eval,Int,(String, String)] = cats.data.StateT@b80befa

val (state, result) = both.run(20).value
// state: Int = 42
// result: (String, String) = (Result of step1: 21,Result of step2: 42)
```

As you can see, in this example the final state is the result of applying both transformations in sequence.
The state is threaded from step to step even though we don't interact with it in the for comprehension.

The general model for using the `State` monad, then,
is to represent each step of a computation as an instance of `State`,
and compose the steps using the standard monad operators.
Cats provides several convenience constructors for creating primitive steps:

 - `get` extracts the state as the result;
 - `set` updates the state and returns unit as the result;
 - `pure` ignores the state and returns a supplied result;
 - `inspect` extracts the state via a transformation function;
 - `modify` updates the state using an update function.

```scala
val step1 = State.get[Int]
// step1: cats.data.State[Int,Int] = cats.data.StateT@61893887

val step2 = State.set[Int](30)
// step2: cats.data.State[Int,Unit] = cats.data.StateT@319fbb9

val step3 = State.pure[Int, String]("Result")
// step3: cats.data.State[Int,String] = cats.data.StateT@6c3cf34f

val step4 = State.inspect[Int, String](_ + "!")
// step4: cats.data.State[Int,String] = cats.data.StateT@22b01e4c

val step5 = State.modify[Int](_ + 1)
// step5: cats.data.State[Int,Unit] = cats.data.StateT@6be5258c

val (state, result) = step1.run(10).value
// state: Int = 10
// result: Int = 10

val (state, result) = step2.run(10).value
// state: Int = 30
// result: Unit = ()

val (state, result) = step3.run(10).value
// state: Int = 10
// result: String = Result

val (state, result) = step4.run(10).value
// state: Int = 10
// result: String = 10!

val (state, result) = step5.run(10).value
// state: Int = 11
// result: Unit = ()
```

We can assemble these building blocks to into useful computations.
We often end up ignoring the results of intermediate stages
when they only represent transformations on the state:

```scala
import State._
// import State._

val program: State[Int, (Int, Int, Int)] = for {
  a <- get[Int]
  _ <- set[Int](a + 1)
  b <- get[Int]
  _ <- modify[Int](_ + 1)
  c <- inspect[Int, Int](_ * 1000)
} yield (a, b, c)
// program: cats.data.State[Int,(Int, Int, Int)] = cats.data.StateT@65a60a17

val (state, result) = program.run(1).value
// state: Int = 3
// result: (Int, Int, Int) = (1,2,3000)
```

### Exercise: Post-Order Calculator

The `State` monad allows us to implement simple evaluators for complex expressions,
passing the values of mutable registers along in the state component.
We model the atomic operations as instances of `State`,
and combine them to evaluate whole sequences of inputs.
We can see a simple example of this by implementing
a calculator for post-order integer arithmetic expressions.

In case you haven't heard of post-order expressions before (I wouldn't be surprised if you haven't),
they are a notation where we write the operator *after* its oprands.
So, for example, instead of writing `1 + 2` we would write:

```scala
1 2 +
```

Although post-order expressions are difficult for humans to read,
they are easy to evaluate using a computer program.

All we need to do is traverse the symbols from left to right,
carrying a *stack* of operands with us as we go:

- when we see a number, we push it onto the stack;

- when we see an operator, we pop two operands off the stack,
  operate on them, and push the result in their place.

This allows us to evaluate complex expressions without using parentheses.
For example, we can evaluate `(1 + 2) * 3)` as follows:

```scala
1 2 + 3 * // see 1, push onto stack
2 + 3 *   // see 2, push onto stack
+ 3 *     // see +, pop 1 and 2 off of stack, push (1 + 2) = 3 in their place
3 3 *     // see 3, push onto stack
3 *       // see 3, push onto stack
*         // see *, pop 3 and 3 off of stack, push (3 * 3) = 9 in their place
```

We can write a simple interpreter for these expressions using the `State` monad.
We can parse each symbol into a `State` instance
representing a context-free stack transform and intermediate result.
The `State` instances can be threaded together using `flatMap`
to produce an interpreter for any sequence of symbols.

Let's do this now. Start by writing a function `evalOne` that parses a single symbol
into an instance of `State`. Use the code below as a template.
Don't worry about error handling for now---if the stack is in the wrong configuration,
it's ok to throw an exception and fail.

```scala
import cats.data.State
// import cats.data.State

type CalcState[A] = State[List[Int], A]
// defined type alias CalcState

def evalOne(sym: String): CalcState[Int] = ???
// evalOne: (sym: String)CalcState[Int]
```

If this seems difficult, think about the basic form of the `State` instances you're returning.
Each instance represents a functional transformation from a stack to a pair of a stack and a result.
You can ignore any wider context and focus on just that one step:




```scala
State[List[Int], Int] { oldStack =>
  val newStack = someTransformation(oldStack)
  val result   = someCalculation
  (newStack, result)
}
```

Feel free to write your `Stack` instances in this form
or as sequences of the convenience constructors we saw above.

<div class="solution">
The stack operation required is different for operators and operands.
For clarity we'll implement `evalOne` in terms of two helper functions,
one for each case:

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

Let's look at `operand` first. All we have to do is push a number onto the stack.
We also return the operand as an intermediate result:

```scala
def operand(num: Int): CalcState[Int] =
  State[List[Int], Int] { stack =>
    (num :: stack, num)
  }
// operand: (num: Int)CalcState[Int]
```

The `operator` function is a little more complex.
We have to pop two operands off the stack and push the result in their place.
The code can fail if the stack doesn't have enough operands on it,
but the exercise description allows us to throw an exception in this case:

```scala
def operator(func: (Int, Int) => Int): CalcState[Int] =
  State[List[Int], Int] {
    case a :: b :: tail =>
      val ans = func(a, b)
      (ans :: tail, ans)

    case _ =>
      sys.error("Fail!")
  }
// operator: (func: (Int, Int) => Int)CalcState[Int]
```



</div>

`evalOne` allows us to evaluate single-symbol expressions as follows.
We call `runA` supplying `Nil` as an initial stack,
and call `value` to unpack the resulting `Eval` instance:

```scala
evalOne("42").runA(Nil).value
// res1: Int = 42
```

We can represent more complex programs using `evalOne`, `map`, and `flatMap`.
Note that most of the work is happening on the stack,
so we ignore the results of the intermediate steps for `evalOne("1")` and `evalOne("2")`:

```scala
val program = for {
  _   <- evalOne("1")
  _   <- evalOne("2")
  ans <- evalOne("+")
} yield ans
// program: cats.data.StateT[cats.Eval,List[Int],Int] = cats.data.StateT@51754669

program.runA(Nil).value
// res2: Int = 3
```

Generalise this example by writing an `evalAll` method that computes the result of a `List[String]`.
Use `evalOne` to process each symbol, and thread the resulting `State` monads together using `flatMap`.
Your function should have the following signature:

```scala
def evalAll(input: List[String]): CalcState[Int] = ???
// evalAll: (input: List[String])CalcState[Int]
```

<div class="solution">
We implement `evalAll` by folding over the input.
We start with a pure `CalcState` that returns `0` if the list is empty.
We `flatMap` at each stage, ignoring the intermediate results as we saw in the example:

```scala
import cats.syntax.applicative._
// import cats.syntax.applicative._

def evalAll(input: List[String]): CalcState[Int] = {
  input.foldLeft(0.pure[CalcState]) { (a, b) =>
    a flatMap (_ => evalOne(b))
  }
```
</div>

We can use `evalAll` to conveniently evaluate multi-stage expressions:

```scala
val program = evalAll(List("1", "2", "+", "3", "*"))

program.runA(Nil).value
```

Because `evalOne` and `evalAll` both return instances of `State`,
we can even thread these results together using `flatMap`.
`evalOne` produces a simple stack transformation and
`evalAll` produces a complex one, but they're both pure functions
and we can use them in any order as many times as we like:

```scala
val program = for {
  _   <- evalAll(List("1", "2", "+"))
  _   <- evalAll(List("3", "4", "+"))
  ans <- evalOne("*")
} yield ans

program.runA(Nil).value
```

<!--
Complete the exercise by implementing an `evalInput` function that
splits an input `String` into symbols, calls `evalAll`,
and runs the result with an initial stack:

```scala
def evalInput(input: String): Int =
  evalAll(input.split(" ").toList).runA(Nil).value

evalInput("1 2 + 3 4 + *")
```
 -->
