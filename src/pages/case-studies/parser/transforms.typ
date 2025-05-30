#import "../../stdlib.typ": info, warning, solution
== Transforming Parses


Until now we have built recognisers: we can detect is a string matches a grammar but we can't transform the data we match. In this section we're going to change that.

=== An Output Type


Right now our parsers return `Strings`. If we're going to change the output of our parser we need to introduce a type for the output. Since the type varies according to the use of the parser, it needs to be a generic type.

=== Exercise


=== Parse Output


Add a generic type to `Parse` to represent the output type (I've called it `O` in my implementation.) To get the code to compile you'll have to make changes to `Parser` as well:

- `*` should return `Parser[Seq[O]]`;
- `~` should return `Parser[(O, O1)]` for some generic type `O1`; and
- `|` should return `Parser[O]`.

#solution[
Checkout the tag `parser-output-type`.
]

=== Transforming


Now we have the infrastructure in place to transform the values produced by our parser. Let's start simple and avoid considering transformations that can fail. In this case the simplest transform is a function with type `O => O1`. So we will write a method on `Parser` that accepts a transformation function of type `O => O1` and applys it on a successfull parse. What is the correct name and type signature of this method?

#solution[
The method has signature

~~~ scala
def ???(f: O => O1): Parser[O1]
~~~

The type table is

|--------+-----------+------------+------------|
| Method | We have   | We provide | We get     |
|--------+-----------+------------+------------|
| ???    | Parser[O] | O => O1    | Parser[O1] |
|--------+-----------+------------+------------|
{: .table .table-bordered .table-responsive }

You should recognise this method as `map`, familiar from the collections classes. We can write the general type of `map` as

|--------+-----------+------------+------------|
| Method | We have   | We provide | We get     |
|--------+-----------+------------+------------|
| map    | F[A]      | A => B     | F[B]       |
|--------+-----------+------------+------------|
{: .table .table-bordered .table-responsive }

Any type that implements such a `map` method is called a *functor*.
]


Write the method on `Parser`.

#solution[
The way to approach this is to write first the type signature and then fill in the skeleton by following the types. So we start with

~~~ scala
def map#link("f: O => O1")[O1]: Parser[O1] =
  ???
~~~

We know we need to construct a `Parser` as the result, so we can immediately write

~~~ scala
def map#link("f: O => O1")[O1]: Parser[O1] =
  Parser { input => ??? }
~~~

This parser must have a result of type `O1`. The only way to construct an `O1` is to apply `f` to an `O`. The only way to get an `O` is to call `parse` and match on the returned `Parse`. Thus we end up with

~~~ scala
def map#link("f: O => O1")[O1]: Parser[O1] =
  Parser { input =>
    this.parse(input) match {
      case fail @ Failure(_) =>
        fail
      case Success(result, remainder) =>
        Success(f(result), remainder)
    }
  }
~~~

The complete code with tests is tagged with `parser-map`.
]

=== Calculators


With `map` in hand we can extend our calculator example to actually calculate the values of the expressions we parse. This is mostly a repeat of techniques we've seen before, so we'll do this as a series of exercises.

=== Exercise


=== Abstract Syntax Tree


Start by implementing data structures to store the result of a successful parse. Such a data structure is known as an abstract syntax tree (AST). Tip 1: The structure of the AST should closely follow the structure of the grammar. Tip 2: Use an algebraic data type.

#solution[
An expression is an addition, or a substraction, or a number. Once we have this structure its realisation in code is straightforward.

~~~ scala
sealed trait Expression
final case class Addition(left: Expression, right: Expression) extends Expression
final case class Subtraction(left: Expression, right: Expression) extends Expression
final case class Number(value: Int) extends Expression
~~~
]

=== Parsing Expressions


Change your parser to return objects of the AST type you created above.

#solution[
This should be a straightforward application `map`. My solution is

~~~ scala
val digits: Parser[Expression] =
  Parser.regex("[0-9]+") map (str => Number(str.toInt))

val addition: Parser[Expression] =
  (digits ~ Parser.string("+") ~ expression) map {
    case ((number, plus), expr) => Addition(number, expr)
  }

val subtraction: Parser[Expression] =
  (digits ~ Parser.string("-") ~ expression) map {
    case ((number, sub), expr) => Subtraction(number, expr)
  }

val expression: Parser[Expression] =
  addition | subtraction | digits
~~~

Note that I used the partial function syntax (e.g. `case ((number, plus), expr) => ...` to simplify destructuring of the nested tuples returned by `~`. For readability I also split the definition into a number of pieces. Finally, to make parsing numbers simpler I used a regular expression to pull out the whole string in one go.
]


=== Evaluating Expressions


Write a method called `eval` to evalute expressions to the `Int` they represent.

#solution[
There are two ways we could write this method: as a method on `Expression` using polymorphism or as method on a companion object using pattern matching. As `eval` depends only on data already stored in `Expression` I have decided to use polymorphism. If we expected to write many tree traversal methods---if we were writing a compiler for example and wanted to optimise expressions before evaluation---we might decide to extract our method to a companion object so we don't clutter `Expression` with a huge number of similar methods.

Either way, `eval` is a straightforward application of structural recursion. My implementation is:

~~~ scala
sealed trait Expression {
  def eval: Int
}
final case class Addition(left: Expression, right: Expression) extends Expression {
  def eval: Int =
    left.eval + right.eval
}
final case class Subtraction(left: Expression, right: Expression) extends Expression {
  def eval: Int =
    left.eval - right.eval
}
final case class Number(value: Int) extends Expression {
  def eval: Int =
    value
}
~~~

The code is tagged with `parser-eval`. Pay particular attention to the tests---I spent longer refactoring them than I did writing `eval`.
]

=== Recap


In this section we've added a `map` method to `Parser`, allowing us to transform parsed data into a more useful representation. We have used `map` to implementation a simple evaluator for numeric expressions, and in doing so revisited the algebraic data type and structural recursion patterns.

We noted in passing that the `map` method makes `Parser` a Functor. A Functor is a type class. We'll be talking a lot more about them very shortly.
