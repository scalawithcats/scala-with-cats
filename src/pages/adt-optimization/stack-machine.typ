#import "../stdlib.typ": info, warning, solution, styled-table
== Compilers and Virtual Machines


We've reified continuations and seen they contain a stack structure: each continuation contains a references to the next continuation, and continuations are constructed in a last-in first-out order. We'll now, once again, reify this structure. This time we'll create an explicit stack, giving rise to a stack-based *virtual machine* to run our code. We'll also introduce a compiler, transforming our code into a sequence of operations that run on this virtual machine. We'll then look at optimizing our virtual machine. As this code involves benchmarking, there is an [accompanying repository][stack-machine] that contains benchmarks you can run on your own computer.


=== Virtual and Abstract Machines


A virtual machine is a computational machine implemented in software rather than hardware. A virtual machine runs programs written in some *instruction set*. The Java Virtual Machine (JVM), for example, runs programs written in Java bytecode.
Closely related are *abstract machines*. The two terms are sometimes used interchangeably but I'll make the distinction that a virtual machine has an implementation in software, while an abstract machine is a theoretical model without an implementation. Thus we can think of an abstract machine as a concept, and a virtual machine as a realization of a concept. This is a distinction we've made in many other parts of the book.

As an abstract machine, stack machines are represented by models such as push down automata and the SECD machine. From abstract stack machines we firstly get the concept itself of a stack machine. The two core operations for a stack are pushing a value on to the top of the stack, and popping the top value off the stack. Function arguments and results are both passed via the stack. So, for example, a binary operation like addition will pop the top two values off the stack, add them, and push the result onto the stack. Abstract stack machines also tell us that stack machines with a single stack are not universal computers. In other words, they are not as powerful as Turing machines. If we add a second stack, or some other form of additional memory, we have a universal computer. This informs the design of virtual machines based on a stack machine.

Stack machines are also very common virtual machines. The Java Virtual Machine is a stack machine, as are the .Net and WASM virtual machines. They are easy to implement, and to write compilers for. We've already seen how easy it is to implement an interpreter so why should we care about stack machines, or virtual machines in general? The usual answer is performance. Implementing a virtual machine opens up opportunities for optimizations that are difficult to implement in interpreters. Virtual machines also give us a lot of flexibility. It's simple to trace or otherwise inspect the execution of a virtual machine, which makes debugging easier. They are easy to port to different platforms and languages. Virtual machines are often very compact, as is the code they run. This makes them suitable for embedded devices. Our focus will be on performance. Although we won't go down the rabbit-hole of compiler and virtual machine optimizations, which would easily take up an entire book, we'll at least tip-toe to the edge and peek down.


=== Compilation


Let's now briefly talk about compilation. A compiler transforms a program from one representation to another. In our case we will transform our programs represented as an algebraic data type of reified constructors and combinators into the instruction set for our virtual machine. The virtual machine itself is an interpreter for its instruction set. Computation always bottoms out in interpretation: a hardware CPU is nothing but an interpreter for it's machine code.

Notice there are two notions of program here, and two corresponding instruction sets: there is the program the structurally recursive interpreter executes, with an instruction set consisting of reified constructors and combinators, and there is the program we compile this into for the stack machine using the stack machine's instruction set. We will call these the interpreter program and instruction set, and stack machine program and instruction set respectively.

The structurally recursive interpreter is an example of a *tree-walking interpreter* or *abstract syntax tree (AST) interpreter*. The stack machine is an example of a *byte-code interpreter*.


== From Interpreter to Stack Machine


There are three parts to transforming an interpreter to a stack machine:

+ creating the instruction set the stack machine will run;
+ creating the compiler from interpreter programs to stack machine programs; and
+ implementing the stack machine to execute stack machine instructions.

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

This completes the first step of the process. The second step is to implement the compiler. The secret to compiling for a stack machine is to transfrom instructions into *reverse polish notation (RPN)*. In RPN operations follow their operands. So, instead of writing `1 + 2` we write `1 2 +`. This is exactly the order in which a stack machine works. To evaluate `1 + 2` we should first push `1` onto the stack, then push `2`, and finally pop both these values, perform the addition, and push the result back to the stack. RPN also does not need nesting. To represent `1 + (2 + 3)` in RPN we simply use `2 3 + 1 +`. Doing away with brackets means that stack machine programs can be represented as a linear sequence of instructions, not a tree. Concretely, we can use `List[Op]`.

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


```scala
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

    ???
  }
}
```

Now we can define the main stack machine loop. It takes as parameters the program and the stack, and is a structural recursion over the program.

```scala
def eval: Double = {
  // pop and push defined here ...

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
```

I've implemented a simple benchmark for this code (see [the repository][stack-machine]) and it's roughly five times slower than the interpreter we started with. Clearly some optimization is needed.

[stack-machine]: https://github.com/scalawithcats/stack-machine


=== Effectful Interpreters


One of the reasons for using the interpreter strategy is to isolate effects, such as state or input and output. An interpreter can be effectful without impacting the ability to reason about or compose the programs the interpreter runs. Sometimes the effects are the entire point of the interpreter as the program may describe effectful actions, such as parsing network data or drawing on a screen, which the interpreter then carries out. Sometimes effects may just be optimizations, which is how we are going to use them in our arithmetic stack machine.

There are many inefficiencies in the stack machine we have just created. A `List` is a poor choice of data structure for both the stack and program. We can avoid a lot of pointer chasing and memory allocation by using a fixed size `Array`. The program never changes in size, and we can simply allocate a large enough stack that resizing it becomes very unlikely. We can also avoid the indirection of pushing and popping and operate directly on the stack array.

The code below shows a simple implementation, which in my benchmarking is about thirty percent faster than the tree-walking interpreter.

```scala
final case class StackMachine(program: Array[Op]) {
  // The data stack
  private val stack: Array[Double] = Array.ofDim[Double](256)

  def eval: Double = {
    // sp points to first free element on the stack
    // stack(sp - 1) is the first element with data
    //
    // pc points to the current instruction in program
    def loop(sp: Int, pc: Int): Double =
      if (pc == program.size) stack(sp - 1)
      else
        program(pc) match {
          case Op.Lit(value) =>
            stack(sp) = value
            loop(sp + 1, pc + 1)
          case Op.Add =>
            val a = stack(sp - 1)
            val b = stack(sp - 2)
            stack(sp - 2) = (a + b)
            loop(sp - 1, pc + 1)
          case Op.Sub =>
            val a = stack(sp - 1)
            val b = stack(sp - 2)
            stack(sp - 2) = (a - b)
            loop(sp - 1, pc + 1)
          case Op.Mul =>
            val a = stack(sp - 1)
            val b = stack(sp - 2)
            stack(sp - 2) = (a * b)
            loop(sp - 1, pc + 1)
          case Op.Div =>
            val a = stack(sp - 1)
            val b = stack(sp - 2)
            stack(sp - 2) = (a / b)
            loop(sp - 1, pc + 1)
        }

    loop(0, 0)
  }
}
```


=== Further Optimization


The above optimization is, to me, the most obvious and straightforward to implement. In this section we'll attempt to go further, by looking at some of the optimizations described in the literature. We'll see that there is not always a straight path to faster code.

The benchmark I used is the simple recursive Fibonacci. Calculating the $n^"th"$ Fibonacci number produces a large expression for a modest choice of $n$. I used a value of 25, and the expression has over one million elements. Notably the expressions only involve addition, and the only literals in use are zero and one. This limits the applicability of the optimizations to a wider range of inputs, but the intention is not to produce an optimized interpreter for this specific case but rather to discuss possible optimizations and issues that arise when attempting to optimize an interpreter in general.

We'll look at four different optimizations, which all use the optimized stack machine above as their base:

- *Algebraic simplification* performs simplifications at compile-time to produce smaller expressions. A small expression should require fewer interpreter steps and hence be faster. The only simplification I used was replacing $x + 0$ or $0 + x$ with $x$. This occurs frequently in the Fibonacci series. Since the expressions we are working with have no variables or control flow we could simplify the entire expression to a single literal at compile-time. This would be an extremely good optimization but rather defeats the purpose of trying to generalize to other applications.

- *Byte code* replaces the `Op` algebraic data type with a single byte. The hope here is that the smaller representation will lead to better cache utilization, and possibly a faster `match` expression, and therefore a faster overall interpreter. In this representation literals are also stored in a separate array of `Doubles`. More on this later.

- *Stack caching* stores the top of the stack in a variable, which we hope will be allocated to a register and therefore be extremely fast to access. The remainder of the stack is stored in an array as above. Stack caching involves more work when pushing values on to the stack, as we must copy the value from the top into the array, but less work when popping values off the stack. The hope is that the savings will outweigh the costs.

- *Superinstructions* replace common sequences of instructions with a single instruction. We already do this to an extent; a typical stack machine would have separate instructions for pushing and popping, but our instruction set merges these into the arithmetic operations. I used two superinstructions: one for incrementing a value, which frequently occurs in the Fibonacci, and one for adding two values from the stack and a literal.

Below are the benchmarks results obtained on an AMD Ryzen 5 3600 and an Apple M1, both running JDK 21. Results are shown in operations per second. The Baseline interpreter is the one using structural recursion. The Stack interpreter uses a `List` to represent the stack and program. The Optimized Stack represents the stack and program as arrays. The other interpreters build on the Optimized Stack interpreter and add the optimizations described above. The All interpreter has all the optimizations.

#styled-table(
    columns: (auto, auto, auto, auto, auto),
    alignment: (left, right, right, right, right),
    table.header([Interpreter], [Ryzen 5], [Speedup], [M1], [Speedup]),
    [ Baseline                 ], [ 2754.43 ], [ 1.00 ], [ 3932.93 ], [ 1.00 ],
    [ Stack                    ], [ 676.43  ], [ 0.25 ], [ 1004.16 ], [ 0.26 ],
    [ Optimized Stack          ], [ 3631.19 ], [ 1.32 ], [ 2953.21 ], [ 0.75 ],
    [ Algebraic Simplification ], [ 1630.93 ], [ 0.59 ], [ 4818.45 ], [ 1.23 ],
    [ Byte Code                ], [ 4057.11 ], [ 1.47 ], [ 3355.75 ], [ 0.85 ],
    [ Stack Caching            ], [ 3698.10 ], [ 1.34 ], [ 3237.17 ], [ 0.82 ],
    [ Superinstructions        ], [ 3706.10 ], [ 1.35 ], [ 4689.02 ], [ 1.19 ],
    [ All                      ], [ 7612.45 ], [ 2.76 ], [ 7098.06 ], [ 1.80 ]
)

There are a few lessons to take from this. The most important, in my opinion, is that _performance is not compositional_. The results of applying two optimizations is not simply the sum of applying the optimizations individually. You can see that most of the optimizations on their own make little or no change to performance relative to the Optimized Stack interpreter. Taken together, however, they make a significant improvement.

Basic structural recursion, the Baseline interpreter, is surprisingly fast; a bit slower than the Optimized Stack interpreter on the Ryzen 5 but faster on the M1. A stack machine emulates the processor's built-in call stack. The native call stack is extremely fast, so we need a good reason to avoid using it.

Details really matter in optimization. We see the choice of data structure makes a massive difference between the Stack and Optimized Stack interpreters. An earlier version of the Byte Code interpreter had worse performance than the Optimized Stack. As best I could tell this was because I was storing literals alongside byte code, and loading a `Double` from an `Array[Byte]` (using a `ByteBuffer`) was slow. Superinstructions are very dependent on the chosen superinstructions. The superinstruction to add two values from the stack plus a literal had little effect on it's own; in fact the interpreter with this single superinstruction was much slower on the Ryzen 5.

Compilers, and JIT compilers in particular, are difficult to understand. I cannot explain why, for example, the Algebraic Simplification interpreter is so slow on the Ryzen 5. This interpreter does strictly less work than the Optimized Stack interpreter. Just like the interpreter optimizations I implemented, compiler optimizations apply in restricted cases that the algorithms recognize. If code does not match the patterns the algorithms look for, the optimizations will not apply, which can lead to strange performance cliffs. My best guess is that something about my implementation caused me to run afoul of such an issue.

Finally, differences between platforms are also significant. It's hard to know how much this due to differences in the computer's architecture, and how much is down to differences in the JVM. Either way, be aware of which platform or platforms you expect the majority of users to run on, and don't naively assume performance on one platform will directly translate to another.
