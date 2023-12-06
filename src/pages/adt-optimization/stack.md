# Compilers and Virtual Machines

We've reified continuations and seen they contain a stack structure: each continuation contains a references to the next continuation, and continuations are constructed in a last-in first-out order. We'll now, once again, reify this structure. This time we'll create an explicit stack, giving rise to a stack-based **virtual machine** to run our code. We'll also introduce a compiler, transforming our code into a sequence of operations that run on this virtual machine. We'll then look at optimizing our virtual machine. As this code involves benchmarking, there is an [accompanying repository](https://github.com/scalawithcats/stack-machine).


## Virtual and Abstract Machines

A virtual machine is software that runs code. Virtual machines, like the Java Virtual Machine (JVM), usually hide the complexity of the underlying hardware from the code they run. Closely related are **abstract machines**. An abstract machine is a theoretical model that ignores many characteristics of real machines. Our work draws on both: stack machines are a common type of abstract machine, but we create a concrete implementation and hence a virtual machine.

A stack machine is a type of abstract machine that, as the name suggests, uses a stack. The two core operations for a stack are pushing a value on to the top of the stack, and popping the top value off the stack. Function arguments and results are both passed via the stack. So, for example, a binary operation like addition will pop the top two values off the stack, add them, and push the result onto the stack.

Stack machines are very easy to implement, and to write compilers for, and are thus very common. The JVM is a stack machine, as are the .Net and WASM virtual machines. However, why should we care about stack machines, or virtual machines in general? We've already developed several perfectly good interpreters. Virtual machines give us a lot of flexibility. It's simple to trace or otherwise inspect the execution of a virtual machine, which makes debugging easier. They are easy to port to different platforms and languages. Virtual machines are often very compact, as is the code they run. This makes them suitable for embedded devices. Finally, they open up many more opportunities for optimization. It is this last point that is probably the most relevant to the largest number of people. Although we won't go down the rabbit-hole of compiler optimizations, which would easily take up the rest of the book, we'll at least stand on the edge and have a look down.


## From Interpreter to Stack Machine

There are three parts to transforming an interpreter to a stack machine:

1. creating the instruction set the machine will run;
2. creating the compiler from the program to a sequence of stack machine instructions; and
3. implementing the stack machine to execute the instructions.

Notice there are two notions of program here, and two corresponding instruction sets: there is the program the interpreter executes, with an instruction set consisting of reified constructors and combinators, and there is the program we compile this into for the stack machine which consists of its own instruction set. We will call these the interpreter program and instruction set, and stack machine program and instruction set respectively.

Let's make this concrete by returning to our arithmetic interpreter.

```scala mdoc:silent
enum Expression {
  def +(that: Expression): Expression = Addition(this, that)
  def *(that: Expression): Expression = Multiplication(this, that)
  def -(that: Expression): Expression = Subtraction(this, that)
  def /(that: Expression): Expression = Division(this, that)

  def eval: Double =
    this match {
      case Literal(value)              => value
      case Addition(left, right)       => left.eval + right.eval
      case Subtraction(left, right)    => left.eval - right.eval
      case Multiplication(left, right) => left.eval * right.eval
      case Division(left, right)       => left.eval / right.eval
    }

  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)
}
object Expression {
  def literal(value: Double): Expression = Literal(value)
}
```

Interpreter programs are defined by the interpreter instruction set

```scala
enum Expression {
  case Literal(value: Double)
  case Addition(left: Expression, right: Expression)
  case Subtraction(left: Expression, right: Expression)
  case Multiplication(left: Expression, right: Expression)
  case Division(left: Expression, right: Expression)
}
```

Transforming the interpreter instruction set to the stack machine instruction set works as follows:

- each constructor interpreter instruction corresponds to stack machine instruction carrying exactly the same data; and
- each combinator interpreter instruction has a corresponding stack machine instruction that carries only non-recursive data. Recursive data, which is executed by recursive calls to the interpreter, will use the stack machine's stack.

Turning to the arithmetic interpreter's instruction set, we see that `Literal` is our sole constructor and thus has a mirror in our stack machine's instruction set. Here I've named the interpreter instruction set `Op` (short for "operation"), and shortened the name from `Literal` to `Lit` to make it clearer which instruction set we are using.

```scala
enum Op {
  case Lit(value: Double)
}
```

The other instructions are all combinators. They also all have contain only values of type `Expression` as data, and hence in the stack machine the corresponding values will be found on the stack. This gives us the complete stack machine instruction set.

```scala mdoc:silent
enum Op {
  case Lit(value: Double)
  case Add
  case Sub
  case Mul
  case Div
}
```


Our stack machine needs it's own set of operations that it will execute. We can derive these operations from the existing operations in our interpreter: every constructor or combinator becomes an operator. The stack machine's constructor operations need to carry their data with them, but combinators will get their data from the stack.

Whereas our structurally recursive interpreter depends on Scala's implementation of 

, as they morefully abstract the implemented language away from the host language

There are several reasons. A virtual machine, like a stack machine, 
Why should we care about 

In our machine we will have two stacks: one holding the program to run, and one holding the data the program operates on. 
