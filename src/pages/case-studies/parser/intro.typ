#import "../../stdlib.typ": info, warning, solution
== Getting Started


Checkout the `parser-initial` tag.

~~~ bash
git checkout parser-initial
~~~

At this point you probably want to create your own branch to work off, comparing your branch to ours as we progress through the course. You may even want to create two copies of the repository, so you can compare you code side-by-side against ours.

~~~ bash
git checkout -b my-parser
~~~

To get you started we have implemented a basic framework for parser combinators, along with some tests. Start by loading `sbt`, changing to the `parser` project, and running the tests.

~~~ bash
> sbt 'project parser' '~test'
[info] Loading project definition from /Users/noel/dev/scala-with-cats-code/project
[info] Set current project to scala-with-cats (in build file:/Users/noel/dev/scala-with-cats-code/)
[info] Set current project to parser (in build file:/Users/noel/dev/scala-with-cats-code/)
[info] Compiling 1 Scala source to /Users/noel/dev/scala-with-cats-code/parser/target/scala-2.10/classes...
scala.NotImplementedError: an implementation is missing
~~~

You'll see the tests are failing, because we have left a method unimplemented. Let's look now look at the code, so we can understand how it works and fix the problem.

The code is reproduced below.

~~~ scala
package underscore.parser

import scala.annotation.tailrec

case class ParseResult(result: String, remainder: String) {

  def failed: Boolean =
    result.isEmpty

  def success: Boolean =
    !failed

}

case class Parser(parse: String => ParseResult) {

  def ~(next: Parser): Parser = ???

  def `*`: Parser =
    Parser { input =>
      @tailrec
      def loop(result: String, remainder: String): ParseResult = {
        val result1 = this.parse(remainder)
        result1 match {
          case _ if result1.failed =>
            ParseResult(result, remainder)
          case ParseResult(result1, remainder1) =>
            loop(result + result1, remainder1)
        }
      }
      loop("", input)
    }

}

object Parser {

  def string(literal: String): Parser =
    Parser { input =>
      if(input.startsWith(literal))
        ParseResult(literal, input.drop(literal.size))
      else
        ParseResult("", input)
    }

}
~~~

What does the code do? The first thing is to look at what a `Parser` is. It is basically a wrapper around a function `String => ParseResult`. The `String` parameter is the input to parse, and returned is the result of parsing that `String`.

A `ParseResult` stores the `String` that was parsed, and any remaining input. If nothing was parsed that indicates the parser failed.

On the companion object for `Parser` we have a constructor to create a parser that matches a `String`. We simply check if the input starts with the given `String`.

More interesting is the `_` method on `Parser`. It creates a `Parser` that matches zero or more of instances of the `String` matched by the original parser. It's analogous to the `_` in regular expressions, also known as the #link("http://en.wikipedia.org/wiki/Kleene_star")[Kleene star].

<div class="aside">
=== A Note on Symbolic Method Names


Symbolic method names are a controversial subject. Restraint is required lest we turn our programs into an incomprehensible mess of symbols. My rules for using symobolic method names are:

+ the notation has some precedence outside of this library; and
+ the symbolic names should be limited to the main features of the library.

In this case there is a strong precedence from regular expressions, with which most programmers should be familiar. Nonetheless, it wouldn't be a bad idea to add non-symbolic alternatives.
]

There are some small technical details in the implementation of `_`. Firstly, we have to enclose the method name in backticks to tell Scala we want to use a non-alphanumeric name for a method. The internal `loop` method has a `@tailrec` annotation. This entirely optional annotation asks the Scala compiler to check that `loop` is _tail-recursive*. A tail-recursive method is one that runs without consuming stack space. This means we can recur indefinitely in `loop` without blowing up the stack.

Tail-recursive methods are the fastest way to implement loops in Scala, so let's quickly review how they work. Due to limitations on the JVM a method can only be made tail-recursive if it exclusively calls itself. (In other language runtimes more general forms of recursion can be made tail recursive.) The second condition for a tail recursive function is that it must return immediately from any self call. If these conditions are met the Scala compiler will convert a recursive method into a loop, which runs much faster. Because tail recursion is an important property we can ask the compiler to ensure methods we think are tail-recursive actually are. We do this using the `@tailrec` annotation. If the compiler determines that an annotated method is not infact tail-recursive it will complain.


=== Exercise: At The Console


Open up the console in `sbt` (use the `console`) command and play around with the `Parser` code. Create some parsers, parse some data, and see how `*` works. Make sure you are comfortable with the code before continuing.

=== Exercise: Sequencing


Implement the `~` method. This method sequences parsers, so `a ~ b` is the parser that results from parsing first with `a` and then parsing with `b`. If either `a` or `b` fails the combined parser should fail. Inspect the tests to see concrete examples of the expected semantics.

#solution[
Checkout the `parser-initial-a` tag to see the complete code with `~` implemented. Here's just the method:

~~~ scala
def ~(next: Parser): Parser =
  Parser { input =>
    val result = this.parse(input)
    result match {
      case _ if result.failed =>
        result
      case ParseResult(parsed, remainder) =>
        val result1 = next.parse(remainder)
        result1 match {
          case _ if result1.failed =>
            ParseResult("", input)
          case ParseResult(parsed1, remainder1) =>
            ParseResult(parsed + parsed1, remainder1)
        }
    }
  }
~~~
]
