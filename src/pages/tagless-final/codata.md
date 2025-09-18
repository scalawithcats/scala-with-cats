## Codata Interpreters

In this section we'll explore codata interpreters, using a DSL for terminal interaction as a case study.
The terminal is familiar to most programmers, and terminal applications are common for developer focused tools. Most terminal features are controlled by writing so-called escape codes to the terminal. However, applications benefit from higher-level abstractions, motivating textual user interface (TUI) libraries that present a more ergonomic interface[^tuis]. Our library will showcase codata interpreters, monads, and the central role of designing for composition and reasoning. 


### The Terminal

The modern terminal is an accretion of features that started with the VT-100 in 1978 and continues [to this day][kitty-kp].
Most terminal features are accessed by reading and writing ANSI escape codes, which are sequence of characters starting with the escape character.
We will work only with escape codes that change the text style.
This allows us to produce interesting output, and raises all the design issues we want to address, but keeps the system simple.
The ideas here are extended to a more complete system in the [Terminus][terminus] library.

The code below is written so that with a single change it can pasted into a file and run with any recent version of Scala with just `scala <filename>`.
The required change is to add the `@main` annotation before the method `go`.
That is, change 

`def go(): Unit =`

to 

`@main def go(): Unit =`

(This is due to a limitation of the software that compiles the code in the book.)

The examples should work with any terminal from the last 40 odd years.
If you're on Windows you can use Windows Terminal, [WSL][wsl], or another terminal that runs on Windows such as [WezTerm][wezterm].


### Color Codes

We will start by writing color codes straight to the terminal.
This will introduce us to controlling the terminal, and show the problems of using ANSI escape codes directly.
Here's our starting point:

```scala mdoc:reset-object:silent
val csiString = "\u001b["

def printRed(): Unit =
  print(csiString)
  print("31")
  print("m")

def printReset(): Unit =
  print(csiString)
  print("0")
  print("m")

def go(): Unit =
  print("Normal text, ")
  printRed()
  print("now red text, ")
  printReset()
  println("and now back to normal.")
```

Try running the above code (e.g. add the `@main` annotation to `go`, save it to a file `ColorCodes.scala` and run `scala ColorCodes.scala`.) 
You should see text in the normal style for your terminal, followed by text colored red, and then some more text in the normal style.
The change in color is controlled by writing escape codes.
These are strings starting with `ESC` (which is the character `'\u001b'`) followed by `'['`.
This is the value of `csiString` (where CSI stands for Control Sequence Introducer).
The CSI is followed by a string indicating the text style to use, and ended with a `"m"`
The string `"\u001b[31m"` tells the terminal to set the text foreground color to red, and the 
string `"\u001b[0m"` tells the terminal to reset all text styling to the default.


### The Trouble with Escape Codes

Escape codes are simple for the terminal to process but lack useful structure for the programmer generating them.
The code above shows one potential problem: we must remember to reset the color when we finish a run of styled text. This problem is no different to that of remembering to free manually allocated memory, and the long history of memory safety problems in C programs show us that we cannot expect to do this reliably. Luckily, we're unlikely to crash our program if we forget an escape code!

To solve this problem we might decide to write functions like `printRed` below, which prints a colored string and resets the styling afterwards.

```scala mdoc:reset-object:silent
val csiString = "\u001b["
val redCode = s"${csiString}31m"
val resetCode = s"${csiString}0m"

def printRed(output: String): Unit =
  print(redCode)
  print(output)
  print(resetCode)

def go(): Unit =
  print("Normal text, ")
  printRed("now red text, ")
  println("and now back to normal.")
```

Changing color is the not the only way that we can style terminal output. We can also, for example, turn text bold. Continuing the above design gives us the following.

```scala mdoc:reset-object:silent
val csiString = "\u001b["
val redCode = s"${csiString}31m"
val resetCode = s"${csiString}0m"
val boldOnCode = s"${csiString}1m"
val boldOffCode = s"${csiString}22m"

def printRed(output: String): Unit =
  print(redCode)
  print(output)
  print(resetCode)

def printBold(output: String): Unit =
  print(boldOnCode)
  print(output)
  print(boldOffCode)

def go(): Unit =
  print("Normal text, ")
  printRed("now red text, ")
  printBold("and now bold.\n")
```

This works, but what if we want text that is *both* red and bold? We cannot express this with our current design, without creating methods for every possible combination of styles. Concretely this means methods like

```scala
def printRedAndBold(output: String): Unit =
  print(redCode)
  print(boldOnCode)
  print(output)
  print(resetCode)
```

This is not feasible to implement for all possible combinations of styles. The root problem is that our design is not compositional: there is no way to build a combination of styles from smaller pieces.


### Programs and Interpreters

To solve the problem above we need `printRed` and `printBold` to accept not a `String` to print but a program to run. 
We don't need to know what these programs do; we just need a way to run them.
Then the combinators `printRed`, `printBold`, and so on, can also return programs.
These programs will set the style appropriately before running their program parameter, and reset it after the parameter program has finished running.
By accepting and returning programs the combinators have the property of closure, meaning that type of the input (a program) is the same as the type of the output. Closure in turn makes composition possible.

How should we represent a program?
We will choose codata and in particular functions, the simplest form of codata.
In the code below we define the type `Program[A]`, which is a function `() => A`.
The interpreter, which is the thing that runs programs, is just function application.
To make it clearer when we are running programs I have a created method `run` that does just that.


```scala mdoc:reset-object:silent
type Program[A] = () => A

val csiString = "\u001b["
val redCode = s"${csiString}31m"
val resetCode = s"${csiString}0m"
val boldOnCode = s"${csiString}1m"
val boldOffCode = s"${csiString}22m"

def run[A](program: Program[A]): A = program()

def print(output: String): Program[Unit] =
  () => Console.print(output)

def printRed[A](output: Program[A]): Program[A] =
  () => {
    run(print(redCode))
    val result = run(output)
    run(print(resetCode))
    
    result
  }


def printBold[A](output: Program[A]): Program[A] = 
  () => {
    run(print(boldOnCode))
    val result = run(output)
    run(print(boldOffCode))
    
    result
  }


def go(): Unit =
  run(() => {
    run(print("Normal text, "))
    run(printRed(print("now red text, ")))
    run(printBold(print("and now bold ")))
    run(printBold(printRed(print("and now bold and red.\n"))))
  })
```

Notice that we have the usual structure for an algebra, which we first met in Section [@sec:interpreters:structure]:

1. we have a constructor in `print`;
2. we have two combinators in `printRed` and `printBold`; and
3. we have an interpreter in `run`.

This code works, for the example we have chosen, but there are two issues: composition and ergonomics.
That we have a problem with composition is perhaps surprising, as that's the problem we set out to solve.
We have made the system compositional in some aspects, but there are still ways in which it does not work correctly.
For example, take the following code:

```scala mdoc:compile-only
run(printBold(() => {
  run(print("This should be bold, "))
  run(printBold(print("as should this ")))
  run(print("and this.\n"))
}))
```

We would expect output like 

**This should be bold, as should that and this**

but we get 

**This should be bold, as should this** and this. 

The inner call to `printBold` resets the bold styling when it finishes, which means the surrounding call to `printBold` does not have effect on later statements.

The issue with ergonomics is that this code is tedious and error-prone to write. We have to pepper calls to `run` in just the right places, and even in these small examples I found myself making mistakes. This is actually another failing of composition, because we don't have methods to combine together programs. For example, we don't have methods to say that the program above is the sequential composition of three sub-programs.

We can solve the first problem by keeping track of the state of the terminal. If `printBold` is called within a state that is already printing bold it should do nothing, otherwise it should update the state to indicate bold styling has been turned on. This means the type of programs changes from `() => A` to `Terminal => (Terminal, A)`, where `Terminal` holds the current state of the terminal.

To solve the second problem we're looking for a way to sequentially compose programs. Remember programs have type `Terminal => (Terminal, A)` and pass around the state in `Terminal`. When you hear the phrase "sequentially compose", or see that type, your monad sense might start tingling. You are correct: this is an instance of the state monad, which we first met in Section [@sec:monad:state]. 

Using Cats we can define

```scala mdoc:reset:silent
import cats.data.State
type Program[A] = State[Terminal, A]
```

assuming some suitable definition of `Terminal`. Let's accept this definition for now, and focus on defining `Terminal`.

`Terminal` has two pieces of state: the current bold setting and the current color. (The real terminal has much more state, but these are representative and modelling additional state does not introduce any new concepts.) The bold setting could simply be a toggle that is either on or off, but when we come to the implementation it will be easier to work with a counter that records the depth of the nesting. The current color must be a stack. We can nest color changes, and the color should change back to the surrounding color when a nested level exits. Concretely, we should be able to write code like

```scala
printBlue(.... printRed(...) ...)
```

and have output in blue or red as we would expect.

Given this we can define `Terminal` as

```scala mdoc:silent
final case class Terminal(bold: Int, color: List[String]) {
  def boldOn: Terminal = this.copy(bold = bold + 1)
  def boldOff: Terminal = this.copy(bold = bold - 1)
  def pushColor(c: String): Terminal = this.copy(color = c :: color)
  // Only call this when we know there is at least one color on the
  // stack
  def popColor: Terminal = this.copy(color = color.tail)
  def peekColor: Option[String] = this.color.headOption
}
```

where we use `List` to represent the stack of color codes. (We could also use a mutable stack, as working with the state monad ensures the state will be threaded through our program.) I've also defined some convenience methods to simplify working with the state.

With this in place we can write the rest of the code, which is shown below. Compared to the previous code I've shortened a few method names and abstracted the escape codes.
Remember this code can be directly executed by `scala`. Just copy it into a file (e.g. `Terminal.scala`), add the `@main` annotation to `go`, and run `scala Terminal.scala`. 

```scala mdoc:reset-object:silent
//> using dep org.typelevel::cats-core:2.13.0

import cats.data.State
import cats.syntax.all.*

object AnsiCodes {
  val csiString: String = "\u001b["

  def csi(arg: String, terminator: String): String =
    s"${csiString}${arg}${terminator}"

  // SGR stands for Select Graphic Rendition. 
  // All the codes that change formatting are SGR codes.
  def sgr(arg: String): String =
    csi(arg, "m")

  val reset: String = sgr("0")
  val boldOn: String = sgr("1")
  val boldOff: String = sgr("22")
  val red: String = sgr("31")
  val blue: String = sgr("34")
}

final case class Terminal(bold: Int, color: List[String]) {
  def boldOn: Terminal = this.copy(bold = bold + 1)
  def boldOff: Terminal = this.copy(bold = bold - 1)
  def pushColor(c: String): Terminal = this.copy(color = c :: color)
  // Only call this when we know there is at least one color on the
  // stack
  def popColor: Terminal = this.copy(color = color.tail)
  def peekColor: Option[String] = this.color.headOption
}
object Terminal {
  val empty: Terminal = Terminal(0, List.empty)
}

type Program[A] = State[Terminal, A]
object Program {
  def print(output: String): Program[Unit] =
    State[Terminal, Unit](
      terminal => (terminal, Console.print(output))
    )

  def bold[A](program: Program[A]): Program[A] =
    for {
      _ <- State.modify[Terminal] { terminal =>
        if terminal.bold == 0 then Console.print(AnsiCodes.boldOn)
        terminal.boldOn
      }
      a <- program
      _ <- State.modify[Terminal] { terminal =>
        val newTerminal = terminal.boldOff
        if terminal.bold == 0 then Console.print(AnsiCodes.boldOff)
        newTerminal
      }
    } yield a

  // Helper to construct methods that deal with color
  def withColor[A](code: String)(program: Program[A]): Program[A] =
    for {
      _ <- State.modify[Terminal] { terminal =>
        Console.print(code)
        terminal.pushColor(code)
      }
      a <- program
      _ <- State.modify[Terminal] { terminal =>
        val newTerminal = terminal.popColor
        newTerminal.peekColor match {
          case None    => Console.print(AnsiCodes.reset)
          case Some(c) => Console.print(c)
        }
        newTerminal
      }
    } yield a

  def red[A](program: Program[A]): Program[A] =
    withColor(AnsiCodes.red)(program)

  def blue[A](program: Program[A]): Program[A] =
    withColor(AnsiCodes.blue)(program)

  def run[A](program: Program[A]): A =
    program.runA(Terminal.empty).value
}

def go(): Unit = {
  val program =
    Program.blue(
      Program.print("This is blue ") >>
        Program.red(Program.print("and this is red ")) >>
        Program.bold(Program.print("and this is blue and bold "))
    ) >>
      Program.print("and this is back to normal.\n")

  Program.run(program)
}

```

Having defined the structure of `Terminal`, the majority of the remaining code manipulates the `Terminal` state. Most of the methods on `Program` have a common structure that specifies a state change before and after the main program runs.

Notice we don't need to implement combinators like `flatMap` or `>>` because we get them from the `State` monad. This is one of the big benefits of reusing abstractions like monads: we get a full library of methods without doing additional work.


### Composition and Reasoning

In Section [@sec:what-is-fp] I argued that the core of functional programming is reasoning and composition. Both of these are central to this case study. We've explicitly designed the DSL for ease of reasoning. Indeed that's the whole point of creating a DSL instead of just spitting control codes at the terminal. An example is how we paid attention to making sure nested calls work as we'd expect. Composition comes in at two levels: both our design and our implementation are compositional. Within the case study we discussed compositionality in the design. Implementationally, a `Program` is a composition of the state monad and the functions inside the state monad. The state monad provides the sequential flow of the `Terminal` state, and the functions provide the domain specific actions.


### Codata and Extensibility

We made a seemingly arbitrary choice to use a codata interpreter. Let's now explore this choice and its implications.

We described codata as programming to an interface. The interface for functions is essentially one method: the ability to apply them. This corresponds to the single interpretation we have for `Program`: run it and carry out the effects therein. If we wanted to have multiple interpretations (such as logging the `Terminal` state or saving the output to a buffer) we would need to have a richer interface. In Scala this would be a `trait` or `class` exposing more than one method.

Keen readers will recall that data makes it easy to add new interpreters but hard to add new operations, while codata makes it easy to add new operations but hard to add new interpreters. We see that in action here. For example, it's trivial to add a new color combinator by defining a method like the below.

```scala
def green[A](program: Program[A]): Program[A] =
  withColor(AnsiCodes.sgr("32"))(program)
```

However, changing `Program` to something that allows more interpretations requires changing all of the existing code.

Another advantage of codata is that we can mix in arbitrary other Scala code. For example, we can use `map` like shown below.

```scala
Program.print("Hello").map(_ => 42)
```

Using the native representation of programs (i.e. functions) gives us the entire Scala language for free. In a data representation we have to reify every kind of expression we wish to support. There is a downside to this as well: we get Scala semantics whether we like them or not. A codata representation would not be appropriate if we wanted to make an exotic language that worked in a different way.

We could factor the interpreter in different ways, and it would still be a codata interpreter. For example, we could put a method to write to the terminal on the `Terminal` type. This would give us a bit more flexibility as changing the implementation of `Terminal` could, say, write to a network socket or a terminal embedded in a browser. We still have the limitation that we cannot create truly different interpretations, such as serializing programs to disk, with the codata approach. We'll address this limitation in the next section where we look at tagless final.


[^tuis]: If you're interested in [TUI][tui] libraries you might like to look at the brilliantly named [ratatui](https://github.com/ratatui/ratatui)  for Rust, [brick](https://github.com/jtdaugherty/brick) for Haskell, or [Textual](https://textual.textualize.io/) for Python.

[terminus]: https://www.creativescala.org/terminus/
[wsl]: https://learn.microsoft.com/en-us/windows/wsl/about
[wezterm]: https://wezfurlong.org/wezterm/index.html
[tui]: https://en.wikipedia.org/wiki/Text-based_user_interface
[fp]: @/posts/2020-07-05-what-and-why-fp.md

