## Applicative Parsers

In the previous sections we have developed all the tools we need to write parsers but they aren't especially convenient to use. One of the issues is how we combine parsers. We end up with nested tuples, as we saw in the numeric expresssion example, which are inconvenient to use. We'd ideally like two things:

1. to be able to ignore the output of certain parsers, such as whitespace; and
2. to able to combine the results of parsers without nesting.

We'll attack the second and along the way get the first.

### Abstracting Over Arity

There is a basic issue in most statically typed languages that we can't easily abstract over arity. What this means is that we can't express a function or tuple of varying size. When we specify, for example, a tuple type it must have a fixed number of elements.

Given a nested tuple like `((1, 2), 3)` we could write an implicit conversion to a flat tuple. It's worth doing this exercise to better understand the issue. We'll use the enrichment pattern here so we can add a method `flatten` to a tuple.

### Exercise: Flattening

Define a `Tuple2Flatten` enrichment with a method `flatten`, and an instance of `Flattener` for a nested tuple like `((1, 2), 3)`.

<div class="solution">
~~~ scala
implicit class Tuple2Flatten[A, B, C](val in: ((A, B), C)) extends AnyVal {
  def flatten: (A, B, C) =
    in match {
      case ((a, b), c) => (a, b, c)
    }
}
~~~

It's fairly straightforward to define this class, but we can't abstract over it in any way. If we want to define `flatten` for a tuple like `(a, (b, c))` we need to define a new enrichment. Similarly if we want to flatten a tuple with four elements.
</div>


### A New Hope

If we were to use the [Shapeless](https://github.com/milessabin/shapeless/wiki/) project we could its [features to abstract over arity](https://github.com/milessabin/shapeless/wiki/Feature-overview:-shapeless-2.0.0#hlist-style-operations-on-standard-scala-tuples) but we're going to take a somewhat roundabout route to arrive at the same place. Our route will allow us to understand a bit more of the plumbing that goes into libraries like Shapeless and Scalaz.

Our starting point is to see that we can abstract over arity, in a sense, if we use **curried** functions. Currying is a way of encoding a multiple-arity function as a sequence of functions of one argument. For example, the function

~~~ scala
(x: Int, y: Int, z: Int) => x + y + z
~~~

can be represented as a curried function as

~~~ scala
(x: Int) => (y: Int) => (z: Int) => x + y + z
~~~

Scala defined a method `curried` on each `Function` type to convert a function to its curried equivalent.

~~~ scala
scala> val foo = (x: Int, y: Int, z: Int) => x + y + z
val foo = (x: Int, y: Int, z: Int) => x + y + z
foo: (Int, Int, Int) => Int = <function3>

scala> foo.curried
foo.curried
res0: Int => (Int => (Int => Int)) = <function1>
~~~

With curried functions we can fake abstraction over arity. Say we have three `Ints` and our function `foo` above. We can apply each `Int` to `foo` in turn, getting back a new function till we have supplied all three arguments, when we get back an `Int`.

~~~ scala
scala> foo.curried(1)(2)(3)
foo.curried(1)(2)(3)
res2: Int = 6
~~~

So long as we have a fixed number of items we can "roll" a curried function down the series of items, applying an element each time, and we get static checking that aren't supplying too many or too few items.

Now imagine a similar curried function, but this time we're going to apply it to a series of `Parsers`. We could do the same trick with curried functions. Let's have a think about the types. We need some way to apply a function `A => B` to a `Parser[A]` and get back a `Parser[B]`. We already have this---it's `map`. However, in some cases our `B` above is actually going to be a function type like `X => Y`. So we'll have a `Parser[X => Y]` that we then want to apply to a `Parser[X]` to get a `Parser[Y]`. We don't have an operation to do this.

To make it really concrete, here's an example using `Option` which has the same "type shape" as `Parser`.

~~~ scala
scala> val adder = ((x: Int, y: Int, z: Int) => x + y + z).curried
val adder = ((x: Int, y: Int, z: Int) => x + y + z).curried
adder: Int => (Int => (Int => Int)) = <function1>

scala> Some(1).map(adder)
Some(1).map(adder)
res3: Option[Int => (Int => Int)] = Some(<function1>)
~~~

Note the result of the `map`, an `Option` containing a function of type `Int => Int => Int`. How do we apply this function inside the `Option` to another `Option`? The more experienced amongst you might reach for `flatMap`. It's true we could implement such a method using `flatMap`

~~~ scala
scala> val temp = Some(1).map(adder)
val temp = Some(1).map(adder)
temp: Option[Int => (Int => Int)] = Some(<function1>)

scala> temp.flatMap(f => Some(2).map(f))
temp.flatMap(f => Some(2).map(f))
res4: Option[Int => Int] = Some(<function1>)
~~~

but `flatMap` is strictly more powerful than we need. `flatMap` allows us choose the `Option` we return. We don't need this flexibility---we already have the `Option`, we just need to apply a function wrapped with an `Option` to it.

Let's write down a type table to help us. (For consistency I've rearranged the parameters of our mystery method.)

-----------------------------------------------
Method    We have     We provide   We get
--------- ----------- ------------ ------------
map       F[A]        A => B       F[B]

flatMap   F[A]        A => F[B]    F[B]

???       F[A]        F[A => B]    F[B]
-----------------------------------------------

The method is called `ap` and types `F[A]` that implement it are called **applicative functors**.

The Scalaz library provides an applicative functor type class, and instances for `Option` and many other types. In Scalaz, `ap` is written as `<*>` for consistency with Haskell. Here's an example:

~~~ scala
scala> import scalaz.syntax.applicative._
scala> import scalaz.std.option._

scala> val adder = ((x: Int, y: Int, z: Int) => x + y + z).curried
val adder = ((x: Int, y: Int, z: Int) => x + y + z).curried
adder: Int => (Int => (Int => Int)) = <function1>

scala> some(1) <*> some(adder)
some(1) <*> some(adder)
res1: Option[Int => (Int => Int)] = Some(<function1>)

scala> some(2) <*> (some(1) <*> some(adder))
some(2) <*> (some(1) <*> some(adder))
res3: Option[Int => Int] = Some(<function1>)

scala> some(3) <*> (some(2) <*> (some(1) <*> some(adder)))
some(3) <*> (some(2) <*> (some(1) <*> some(adder)))
res5: Option[Int] = Some(6)
~~~

A few notes:

- `some` returns a `Some` with type `Option` rather than type `Some`.
- We have to supply the elements in the opposite order to which they are applied, which is a bit annoying.


### Applicative Functors

Scalaz provides some fairly elaborate infrastructure for us:

- instances of `Applicative` for many common types such as `Option`;
- enrichment helpers that provide the `<*>` syntax we've already seen; and
- the actual `Applicative` type class itself, containing many utility functions.


Let's implement an instance of Scalaz's `Applicative` type class for our `Parser` type, and then we can take advantage of the rest of the support Scalaz provides.

### Exercise: Applicative Parser

Define a typeclass instance of `Applicative` for `Parser`. You must implement the following trait:

~~~ scala
Applicative[Parser] {
  def point[A](a: => A): Parser[A] =
    ???

  def ap[A,B](fa: => Parser[A])(f: => Parser[A => B]): Parser[B] =
    ???
}
~~~

Hints:

1. You must import `scalaz.Applicative`.
2. You can define `point` in terms of `map` and an *identity* parser which does nothing.
3. To implement `ap`, follow the types. There is one wrinkle: you should parse with `f` before you parse with `fa`.


<div class="solution">
The usual place to define typeclass instances is as implicit elements on the companion object, in this case the `Parser` object. Here's my implementation:

~~~ scala
val identity: Parser[Unit] =
  Parser { input => Success(Unit, input) }

implicit object applicativeInstance extends Applicative[Parser] {
  def point[A](a: => A): Parser[A] =
    identity map (_ => a)

  def ap[A,B](fa: => Parser[A])(f: => Parser[A => B]): Parser[B] =
    Parser { input =>
      f.parse(input) match {
        case fail @ Failure(_) =>
          fail
        case Success(aToB, remainder) =>
          fa.parse(remainder) match {
            case fail @ Failure(_) =>
              fail
            case Success(a, remainder1) =>
              Success(aToB(a), remainder1)
          }
      }
    }
}
~~~

Checkout the `parser-applicative` tag to see the full code and tests.
</div>


### Using Applicative

Once we have our `Applicative` instance we can take it for a spin:

~~~ scala
scala> import scalaz.syntax.applicative._

scala> val parser = Parser.string("chicken") <*> ((_: String) => "Tastes like chicken").point[Parser]
parser: underscore.parser.Parser[String] = Parser(<function1>)

scala> parser.parse("chicken")
res0: underscore.parser.Parse[String] = Success(Tastes like chicken,)
~~~

Note how we "lift" a function into `Parser` using `point`, and combine two `Parsers` using `<*>`.

Things get a bit cumbersome if we want to combine larger expressions:

~~~ scala
scala> val parser = Parser.string("man") <*> (Parser.string("bites") <*> (Parser.string("dog") <*> ((_: String, _: String, animal: String) => s"$animal tastes like chicken!").curried.point[Parser]))
parser: underscore.parser.Parser[String] = Parser(<function1>)

scala> parser.parse("dogbitesman")
res6: underscore.parser.Parse[String] = Success(man tastes like chicken!,)
~~~

To parse `"dogbitesman"` we have to specify the `Parser` in reverse order. We also have to curry the function we `point`. Why is the order reversed? Remember the type table above? It showed arguments in their idiomatic order in Scala. In the case of `Applicative` this idiomatic order isn't often the order we actually want to write the parameters. But don't worry, we'll fix this problem!

The first part of the solution is the methods `<*` and `*>` that `Applicative` defines for us. They have types

-----------------------------------------------
Method    We have     We provide   We get
--------- ----------- ------------ ------------
`<*`      F[A]        F[B]         F[A]

`*>`      F[A]        F[B]         F[B]
-----------------------------------------------

What this concretely means is they combine two `Parsers`, running them both but only keeping the result that the arrow points towards. With them we can simplify our definition:

~~~ scala
scala> val parser = Parser.string("dog") *> Parser.string("bites") *> Parser.string("man")
parser: underscore.parser.Parser[String] = Parser(<function1>)

scala> parser <*> ((flava: String) => s"$flava tastes like chicken!").point[Parser]
er]
res9: underscore.parser.Parser[String] = Parser(<function1>)

scala> res9.parse("dogbitesman")
res10: underscore.parser.Parse[String] = Success(man tastes like chicken!,)
~~~

This is much clearer.

Sometime we do need more than one result, so the problem still remains. In these cases we can combine `Applicatives` using the "caret" syntax. The `^` methods (`^`, `^^`, and so on) allow us to apply a method to a number of `Applicatives` in the order we expect.

Here is it in use

~~~ scala
scala> import scalaz.syntax.applicative._

scala> def taste(taster: String, action: String, flava: String): String = s"$flava tastes like chicken!"
taste: (taster: String, action: String, flava: String)String

scala> val parser = ^^(Parser.string("dog"), Parser.string("bites"), Parser.string("man"))(taste)
parser: underscore.parser.Parser[String] = Parser(<function1>)

scala> parser(taste).parse("dogbitesman")
res1: underscore.parser.Parse[String] = Success(man tastes like chicken!,)
~~~

We use a number of carets one less than the number of `Applicatives` we have.

We can combine `<*`, `*>`, and `^` to write expressions involving `Applicatives` in a natural order.

### Exercise

### Applicative Expressions

Rewrite your numeric expression parser to use `Applicative` style.

<div class="solution">
~~~ scala
val digits: Parser[Expression] =
  Parser.regex("[0-9]+") map (str => Number(str.toInt))

val addition: Parser[Expression] =
  ^(digits <* Parser.string("+"), expression){
    (number: Expression, expr: Expression) => Addition(number, expr)
  }

val subtraction: Parser[Expression] =
  ^(digits <* Parser.string("-"), expression) {
    (number: Expression, expr: Expression) => Subtraction(number, expr)
  }

val expression: Parser[Expression] =
  addition | subtraction | digits
~~~
</div>

### Whitespace

Now that we can easily drop results we're not interested in, extend your numeric expression parser to handle whitespace around digits and operators.

<div class="solution">

Checkout the `parser-applicative-numeric` tag to see the complete solution.
</div>

### A Note About Caret Syntax and Applicative Builder

In online tutorials you'll often find reference to "applicative builder" style which uses a `|@|` method to achieve the same thing we did with the caret functions. The reasons we haven't used it here is that evaluates its arguments too eagerly, causing infinite recursion in our numeric expression parser. The caret functions use call-by-name arguments and thus work.

Both the applicative builder and the caret functions are only defined for a finite number of arguments. Neither really gets around the inability to abstract over arity, just that if we use these methods someone else has already done the tedious work for us.

### Recap

Applicatives.

Context-free.
