#import "../../stdlib.typ": info, warning, solution
== Error Handling


There is much wrong with our initial parser code. In this section we're going to fix error handling. Right now it has many issues:

- Errors handling is a convention (the `result` field is the empty string), so there is nothing to enforce we handle an failed parse.
- We can't distinguish from a perfectly valid parser that parsed nothing and a parser that failed to parse.

We will fix this by thinking and coding systematically. The first thing is ask ourselves what kind of things could a parser return? We have already made a start on an answer above. A parser can either have:

- a successful parse; or
- a failure.

Once we make this realisation the code follows straight-away. For this type of data we use the _sealed trait_ pattern.

=== The Sealed Trait Pattern


If some data `A` can be a `B` or a `C` and nothing else, we should write

~~~ scala
sealed trait A
final case class B() extends A
final case class C() extends A
~~~

Sealed traits. Extension points (final / non-final)

=== Exercise


=== Better ParserResult


Implement a better `ParserResult`. This exercise is deliberately vague about what exactly you should implement. Use your personal style and flava to fill in the missing details.

#solution[

Here's my implementation. It follows the existing pattern for success, maintaining the `result` and `remainder` fields, but returns an error message on failure. I also renamed `ParseResult` to just `Parse`. With the subtypes it's fairly obvious that a `Parse` is the result of a `Parser`.

~~~ scala
sealed trait Parse
final case class Failure(message: String) extends Parse
final case class Success(result: String, remainder: String) extends Parse
~~~
]


=== Parser Error Handling


Make the necessary chages to `Parser` to use the new `ParserResult` type.

#solution[
Checkout the `parser-error-handling` tag.

There are a few interesting points to note:

- I implemented a custom matcher in tests, to match for failures.
- The tests for `*` had to change now we have clarified the difference between success and failure.
]


=== One or More


Implement the `+` operator, which matches a parser one or more times.

#solution[
Checkout the `parser-operators` tag.

`+` is straightforward to implement by composing `~` and `*`.

~~~ scala
def `+`: Parser =
  this ~ (this.*)
~~~
]


=== Alternatives


Now we can distinguish failure and success implement alternative (`|`), which returns the result of the first parser if it succeeds, and otherwise tries the second parser.

#solution[
Checkout the `parser-operators` tag.

`|` simply requires making the appropriate choice on the `Parse` of the first `Parser`.

~~~ scala
def `|`(that: Parser): Parser =
  Parser { input =>
    this.parse(input) match {
      case fail @ Failure(_) =>
        that.parse(input)
      case good @ Success(_, _) =>
        good
    }
  }
~~~
]


=== Recognising Expressions


With and (`~`), or (`|`), and repetition (`*`) we have the fundamental operators for our parser library. We can't actually do anything useful when we're parsing an expression, but we'll get to that in a moment. Right now we'll take a quick break to explore the power of what we have implemented, by writing a parser to recognise arithemetic expressions.

Let's begin with a very simple grammar. An expression can be either digits (one or more of the characters 0 to 9), or an addition or subtraction expression. We'll approach this in very small pieces

=== Regular Expressions


It will be handy to be able to construct a parser from a regular expression, so add such a constructor to the `Parser` companion object.

#solution[
~~~ scala
def regex(regex: String): Parser = {
  val compiled = new Regex(regex)
  Parser { input =>
    compiled.findPrefixOf(input) match {
      case None =>
        Failure(s"$input did not match the regular expression $regex")
      case Some(str) =>
        Success(str, input.drop(str.size))
    }
  }
}
~~~
]

=== Digits


Implement a parser for digits using the regular expression `"[0-9]"` to match a digits.

#solution[
~~~ scala
package underscore.parser

object NumericParser {

  val digits = Parser.regex("[0-9]").+

}
~~~
]

=== Expressions


Implement a parser for addition and subtraction expressions. An expression is digits, or `<expression>+<expression>` or `<expression>-<expression>` (we're ignoring whitespace for now).

#solution[
The obvious implementation is this:

~~~ scala
val expression: Parser =
  digits | (expression ~ Parser.string("+") ~ expression) | (expression ~ Parser.string("-") ~ expression)
~~~

If you try to use this (say, by using the `console` within sbt) you will get a `NullPointerException`. This is because `expression` is defined in terms of itself, and it begins with an initial value of `null`. Hence the self-referential part of `expression` encounters a `null`.

The obvious fix is to change the `val` to a `def`. Try this and you'll get a `StackOverflowError`. The recursion again causes the problem, this time by evaluating `expression` without end.

We now have two choices: give up and cry in a corner, or fix the problem properly. So really we only have one choice. The solution is the make parser construction _lazy_. When we build a parser using `~` or `|` we only build the parser when we need it. Luckily Scala provides just the tool we need: call-by-name parameters.

A call-by-name method parameter has the syntax `(name: => Type)` instead of `(name: Type)`. This type looks like a function with no arguments, which is essentially what such a parameter is. Just like a method with no arguments, whenever we refer to a call-by-name parameter by its name we actually invoke the function. The advantage of such a parameter type is that the user doesn't need to know they must provide a function. They just write a normal expression and Scala will wrap it up in a function for us. Here's a simple example to show what's going on. Try it at the Scala console.

Start by defining a method with a call-by-name parameter:

~~~ scala
def add(x: => Int) = x + x
// add: (x: => Int)Int
~~~

We can call it with an `Int` just like a normal method.

~~~ scala
add(2)
// res4: Int = 4
~~~

However if we replace our `Int` with an expression that prints and then returns an `Int`, we'll see that we actually print twice:

~~~ scala
add({println("Hi"); 2})
// Hi
// res5: Int = 4
~~~

If `add` was a normal method we'ld only print `"Hi"` once.

If we make the parameter of `~` and `|` call-by-name, our `Parser` will work. Try it and you'll see another issue---the way the grammar is written we'll stop after parsing the first number. (Try `expression.parse("123+456")` and you'll see.) The solution is to rewrite the grammar so we look for compound expressions first and we proceed left-to-right.

~~~ scala
object NumericParser {

  val digits = Parser.regex("[0-9]").+

  def expression: Parser =
    (digits ~ Parser.string("+") ~ expression) | (digits ~ Parser.string("-") ~ expression) | digits

}
~~~

The code is tagged with `parser-numeric-expression`.
]

=== Recap


In this section we've seen many concepts.

We've used Scala's sealed trait pattern to implement algebraic data types. Algebraic data types can express data modelled with logical ors and ands (sometimes called sums and products) and give us type safety as the compiler checks we match all cases.

We've have implemented the core of our parser combinator library. A combinator library consists of three things:

- the primitive data objects, in our the methods for constructing basic `Parsers`;
- the operators for combining objects into new objects, in our case `~`, `*`, `|`, and derived operations; and
- some way of using the objects we build, in our case the `parse` method on `Parser`.

Finally, we've seen call-by-name parameters and there use when we're building infinite data structures.

In the next section we're going to see how we can actually do something useful during a parse.
