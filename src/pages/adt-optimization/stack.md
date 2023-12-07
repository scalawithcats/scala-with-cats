## Compilers and Virtual Machines

We've reified continuations and seen they contain a stack structure: each continuation contains a references to the next continuation, and continuations are constructed in a last-in first-out order. We'll now, once again, reify this structure. This time we'll create an explicit stack, giving rise to a stack-based **virtual machine** to run our code. We'll also introduce a compiler, transforming our code into a sequence of operations that run on this virtual machine. We'll then look at optimizing our virtual machine. As this code involves benchmarking, there is an [accompanying repository](https://github.com/scalawithcats/stack-machine) that contains benchmarks you can run on your own computer.


### Virtual and Abstract Machines

A virtual machine is a computational machine implemented in software rather than hardware. A virtual machine runs programs written in some **instruction set**. The Java Virtual Machine (JVM), for example, runs programs written in Java bytecode.
Closely related are **abstract machines**. The two terms are sometimes used interchangeably but I'll make the distinction that a virtual machine has an implementation in software, while an abstract machine is a theoretical model without an implementation. Thus we can think of an abstract machine as a concept, and a virtual machine as a realization of a concept. This is a distinction we've made in many other parts of the book.

As an abstract machine, stack machines are represented by models such as push down automata and the SECD machine. From abstract stack machines we firstly get the concept itself of a stack machine. The two core operations for a stack are pushing a value on to the top of the stack, and popping the top value off the stack. Function arguments and results are both passed via the stack. So, for example, a binary operation like addition will pop the top two values off the stack, add them, and push the result onto the stack. Abstract stack machines also tell us that stack machines with a single stack are not universal computers. In other words, they are not as powerful as Turing machines. If we add a second stack, or some other form of additional memory, we have a universal computer. This informs the design of virtual machines based on a stack machine.

Stack machines are also very common virtual machines. The Java Virtual Machine is a stack machine, as are the .Net and WASM virtual machines. They are easy to implement, and to write compilers for. We've already seen how easy it is to implement an interpreter so why should we care about stack machines, or virtual machines in general? The usual answer is performance. Implementing a virtual machine opens up opportunities for optimizations that are difficult to implement in interpreters. Virtual machines also give us a lot of flexibility. It's simple to trace or otherwise inspect the execution of a virtual machine, which makes debugging easier. They are easy to port to different platforms and languages. Virtual machines are often very compact, as is the code they run. This makes them suitable for embedded devices. Our focus will be on performance. Although we won't go down the rabbit-hole of compiler and virtual machine optimizations, which would easily take up an entire book, we'll at least tip-toe to the edge and peek down.


### Compilation

Let's now briefly talk about compilation. A compiler transforms a program from one representation to another. In our case we will transform our programs represented as an algebraic data type of reified constructors and combinators into the instruction set for our virtual machine. The virtual machine itself is an interpreter for its instruction set. Computation always bottoms out in interpretation: a hardware CPU is nothing but an interpreter for it's machine code.

Notice there are two notions of program here, and two corresponding instruction sets: there is the program the structurally recursive interpreter executes, with an instruction set consisting of reified constructors and combinators, and there is the program we compile this into for the stack machine using the stack machine's instruction set. We will call these the interpreter program and instruction set, and stack machine program and instruction set respectively.

The structurally recursive interpreter is an example of a **tree-walking interpreter** or **abstract syntax tree (AST) interpreter**. The stack machine is an example of a **byte-code interpreter**.


## From Interpreter to Stack Machine

There are three parts to transforming an interpreter to a stack machine:

1. creating the instruction set the stack machine will run;
2. creating the compiler from interpreter programs to stack machine programs; and
3. implementing the stack machine to execute stack machine instructions.

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
- each combinator interpreter instruction has a corresponding stack machine instruction that carries only non-recursive data. Recursive data, which is executed by recursive calls to the interpreter, will be represented by data on the stack machine's stack.

Turning to the arithmetic interpreter's instruction set, we see that `Literal` is our sole constructor and thus has a mirror in our stack machine's instruction set. Here I've named the interpreter instruction set `Op` (short for "operation"), and shortened the name from `Literal` to `Lit` to make it clearer which instruction set we are using.

```scala
enum Op {
  case Lit(value: Double)
}
```

The other instructions are all combinators. They also all only contain values of type `Expression`, and hence in the stack machine the corresponding values will be found on the stack. This gives us the complete stack machine instruction set.

```scala mdoc:silent
enum Op {
  case Lit(value: Double)
  case Add
  case Sub
  case Mul
  case Div
}
```

This completes the first step of the process. The second step is to implement the compiler. The secret to working with a stack machine is to transfrom instructions into **reverse polish notation (RPN)**. In RPN operations follow their operands. So, instead of writing `1 + 2` we write `1 2 +`. This is exactly the order in which a stack machine works. To evaluate `1 + 2` we should first push `1` onto the stack, then push `2`, and finally pop both these values, perform the addition, and push the result back to the stack. RPN also does not need nesting. To represent `1 + (2 + 3)` in RPN we simply use `2 3 + 1 +`. Doing away with brackets means that stack machine programs can be represented as a linear sequence of instructions, not a tree. Concretely, we can use `List[Op]`.

How we should we implement the conversion to RPN. We are performing a transformation on an algebraic data type, our interpreter instruction set and therefore we can use structural recursion. The following code shows one way to implement this. It's not very efficient (appending lists is a slow operation) but this doesn't matter for our purposes.

```scala
def compile: List[Op] =
  this match {
    case Literal(value) => List(Op.Lit(value))
    case Addition(left, right) =>
      left.compile ++ right.compile ++ List(Op.Add)
    case Subtraction(left, right) =>
      left.compile ++ right.compile ++ List(Op.Sub)
    case Multiplication(left, right) =>
      left.compile ++ right.compile ++ List(Op.Mul)
    case Division(left, right) =>
      left.compile ++ right.compile ++ List(Op.Div)
  }
```

We now are left to implement the stack machine. We'll start by sketching out the interface for the stack machine.

```scala
final case class StackMachine(program: List[Op]) {
  def eval: Double = ???
}
```

In this design the program is fixed for a given `StackMachine` instance, but we can run the program multiple times.

Now we'll implement `eval`. It is a structural recursion over an algebraic data type, in this case the `program` of type `List[Op]`. It's a little bit more complicated than some of the structural recursions we have seen, because we need to implement the stack as well. We'll represent the stack as a `List[Double]`, and define methods to push and pop the stack.


```scala mdoc:silent
final case class StackMachine(program: List[Op]) {
  def eval: Double = {
    def pop(stack: List[Double]): (Double, List[Double]) =
      stack match {
        case head :: next => (head, next)
        case Nil =>
          throw new IllegalStateException(
            s"The data stack does not have any elements."
          )
      }

    def push(value: Double, stack: List[Double]): List[Double] =
      value :: stack

    def loop(stack: List[Double], program: List[Op]): Double =
      program match {
        case head :: next =>
          head match {
            case Op.Lit(value) => loop(push(value, stack), next)
            case Op.Add =>
              val (a, s1) = pop(stack)
              val (b, s2) = pop(s1)
              val s = push(a + b, s2)
              loop(s, next)
            case Op.Sub =>
              val (a, s1) = pop(stack)
              val (b, s2) = pop(s1)
              val s = push(a + b, s2)
              loop(s, next)
            case Op.Mul =>
              val (a, s1) = pop(stack)
              val (b, s2) = pop(s1)
              val s = push(a + b, s2)
              loop(s, next)
            case Op.Div =>
              val (a, s1) = pop(stack)
              val (b, s2) = pop(s1)
              val s = push(a + b, s2)
              loop(s, next)
          }

        case Nil => stack.head
      }

    loop(List.empty, program)
  }
}
```
