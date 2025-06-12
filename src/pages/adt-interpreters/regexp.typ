#import "../stdlib.typ": info, warning, solution, href
== Regular Expressions


We'll start this case study by briefly describing the usual task for regular expressions---matching text---and then take a more theoretical view. We'll then move on to implementation.

We most commonly use regular expressions to determine if a string matches a particular pattern.
The simplest regular expression is one that matches only one string.
In Scala we can create a regular expression by calling the `r` method on `String`.
Here's a regular expression that matches exactly the string `"Scala"`.

```scala mdoc:silent 
val regexp = "Scala".r
```

We can see that it matches only `"Scala"` and fails if we give it a shorter or longer input.

```scala mdoc
regexp.matches("Scala")
regexp.matches("Sca")
regexp.matches("Scalaland")
```

Notice we already have a separation between description and action. 
The description is the regular expression itself, created by calling the `r` method, and the action is calling the `matches` method on the regular expression.

There are some characters that have a special meaning within the `String` describing a regular expression.
For example, the character `*` matches the preceding character zero or more times.

```scala mdoc:reset:silent
val regexp = "Scala*".r
```
```scala mdoc
regexp.matches("Scal")
regexp.matches("Scala")
regexp.matches("Scalaaaa")
```

We can also use parentheses to group sequences of characters.
For example, if we wanted to match all the strings like `"Scala"`, `"Scalala"`, `"Scalalala"` and so on, we could use the following regular expression.

```scala mdoc:reset:silent
val regexp = "Scala(la)*".r
```

Let's check it matches what we're looking for.

```scala mdoc
regexp.matches("Scala")
regexp.matches("Scalalalala")
```

We should also check it fails to match as expected.

```scala mdoc
regexp.matches("Sca")
regexp.matches("Scalal")
regexp.matches("Scalaland")
```

That's all I'm going to say about Scala's built-in regular expressions. If you'd like to learn more there are many resources online. The #href("https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/regex/Pattern.html")[JDK documentation] is one example, which describes all the features available in the JVM implementation of regular expressions.

Let's turn to the theoretical description, such as we might find in a textbook. A regular expression is:

+ the empty regular expression that matches nothing;
+ a string, which matches exactly that string (including the empty string); 
+ the concatenation of two regular expressions, which matches the first regular expression and then the second;
+ the union of two regular expressions, which matches if either expression matches; and
+ the repetition of a regular expression (often known as the Kleene star), which matches zero or more repetitions of the underlying expression.

This kind of description may seem very abstract if you're not used to it. It is very useful for our purposes because it defines a minimal API that we can easily implement. Let's walk through the description and see how each part relates to code.

The empty regular expression is defining a constructor with type `() => Regexp`, which we can simplify to a value of type `Regexp`.
In Scala we put constructors on the companion object, so this tells us we need

```scala
object Regexp {
  val empty: Regexp =
    ???
}
```

The second part tells us we need another constructor, this one with type `String => Regexp`.

```scala
object Regexp {
  val empty: Regexp =
    ???

  def apply(string: String): Regexp =
    ???
}
```

The other three components all take a regular expression and produce a regular expression.
In Scala these will become methods on the `Regexp` type.
Let's model this as a `trait` for now, and define these methods.

The first method, the concatenation of two regular expressions, is conventionally called `++` in Scala.

```scala
trait Regexp {
  def ++(that: Regexp): Regexp
}
```

Union is conventionally called `orElse`.

```scala
trait Regexp {
  def ++(that: Regexp): Regexp
  def orElse(that: Regexp): Regexp
}
```

Repetition we'll call `repeat`, and define an alias `*` that matches how this operation is written in conventional regular expression notation.

```scala
trait Regexp {
  def ++(that: Regexp): Regexp
  def orElse(that: Regexp): Regexp
  def repeat: Regexp
  def `*`: Regexp = this.repeat
}
```

We're missing one thing: a method to actually match our regular expression against some input. Let's call this method `matches`.

```scala
trait Regexp {
  def ++(that: Regexp): Regexp
  def orElse(that: Regexp): Regexp
  def repeat: Regexp
  def `*`: Regexp = this.repeat
  
  def matches(input: String): Boolean
}
```

This completes our API.
Now we can turn to implementation.
We're going to represent `Regexp` as an algebraic data type, and each method that returns a `Regexp` will return an instance of this algebraic data type.
What should be the elements that make up the algebraic data type?
There will be one element for each method, and the constructor arguments will be exactly the parameters passed to the method _including the hidden `this` parameter for methods on the trait_.

Here's the resulting code.

```scala mdoc:silent
enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*`: Regexp = this.repeat
  
  def matches(input: String): Boolean =
    ???
  
  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Empty
}
object Regexp {
  val empty: Regexp = Empty
  
  def apply(string: String): Regexp =
    Apply(string)
}
```

A quick note about `this`. We can think of every method on an object as accepting a hidden parameter that is the object itself. This is `this`. (If you have used Python, it makes this explicit as the `self` parameter.) As we consider `this` to be a parameter to a method call, and our implementation strategy is to capture all the method parameters in a data structure, we must make sure we capture `this` when it is available. The only case where we don't capture `this` is when we are defining a constructor on a companion object.

Notice that we haven't implemented `matches`. It doesn't return a `Regexp` so we cannot return an element of our algebraic data type. What should we do here? `Regexp` is an algebraic data type and `matches` transforms an algebraic data type into a `Boolean`. Therefore we can use structural recursion! Let's write out the skeleton, including the recursion rule.

```scala
def matches(input: String): Boolean =
  this match {
    case Append(left, right) =>
      left.matches(???) ??? right.matches(???)
    case OrElse(first, second) =>
      first.matches(???) ??? second.matches(???)
    case Repeat(source) =>
      source.matches(???) ???
    case Apply(string) => ???
    case Empty => ???
  }
```

Now we can apply the usual strategies to complete the implementation. Let's reason independently by case, starting with the case for `Empty`. This case is trivial as it always fails to match, so we just return `false`.

```scala
def matches(input: String): Boolean =
  this match {
    case Append(left, right)   => left.matches(???) ??? right.matches(???)
    case OrElse(first, second) => first.matches(???) ??? second.matches(???)
    case Repeat(source)        => source.matches(???) ???
    case Apply(string)         => ???
    case Empty                 => false
  }
```

Let's move on to the `Append` case. This should match if the `left` regular expression matches the start of the `input`, and the `right` regular expression matches starting where the `left` regular expression stopped. This has uncovered a hidden requirement: we need to keep an index into the `input` that tells us where we should start matching from. Using a nested method is the easiest way to keep around additional information that we need. Here I've created a nested method that returns an `Option[Int]`. The `Int` is the new index to use, and we return an `Option` to indicate if the regular expression matched or not.

```scala
def matches(input: String): Boolean = {
  def loop(regexp: Regexp, idx: Int): Option[Int] =
    regexp match {
      case Append(left, right) =>
        loop(left, idx).flatMap(idx => loop(right, idx))
      case OrElse(first, second) => 
        loop(first, idx) ??? loop(second, ???)
      case Repeat(source) => 
        loop(source, idx) ???
      case Apply(string) => 
        ???
      case Empty =>
        None
    }

  // Check we matched the entire input
  loop(this, 0).map(idx => idx == input.size).getOrElse(false)
}
```

Now we can go ahead and complete the implementation.

```scala
def matches(input: String): Boolean = {
  def loop(regexp: Regexp, idx: Int): Option[Int] =
    regexp match {
      case Append(left, right) =>
        loop(left, idx).flatMap(i => loop(right, i))
      case OrElse(first, second) => 
        loop(first, idx).orElse(loop(second, idx))
      case Repeat(source) =>
        loop(source, idx)
          .flatMap(i => loop(regexp, i))
          .orElse(Some(idx))
      case Apply(string) =>
        Option.when(input.startsWith(string, idx))(idx + string.size)
    }

  // Check we matched the entire input
  loop(this, 0).map(idx => idx == input.size).getOrElse(false)
}
```

The implementation for `Repeat` is a little tricky, so I'll walk through the code.

```scala
case Repeat(source) =>
  loop(source, idx)
    .flatMap(i => loop(regexp, i))
    .orElse(Some(idx))
```

The first line (`loop(source, index)`) is seeing if the `source` regular expression matches.
If it does we loop again, but on `regexp` (which is `Repeat(source)`), not `source`. 
This is because we want to repeat an indefinite number of times. 
If we looped on `source` we would only try twice.
Remember that failing to match is still a success; repeat matches zero or more times.
This condition is handled by the `orElse` clause.

We should test that our implementation works.

```scala mdoc:reset:invisible
enum Regexp {
  def ++(that: Regexp): Regexp =
    Append(this, that)

  def orElse(that: Regexp): Regexp =
    OrElse(this, that)

  def repeat: Regexp =
    Repeat(this)

  def `*` : Regexp = this.repeat

  def matches(input: String): Boolean = {
    def loop(regexp: Regexp, idx: Int): Option[Int] =
      regexp match {
        case Append(left, right) =>
          loop(left, idx).flatMap(i => loop(right, i))
        case OrElse(first, second) =>
          loop(first, idx).orElse(loop(second, idx))
        case Repeat(source) =>
          loop(source, idx)
            .flatMap(i => loop(regexp, i))
            .orElse(Some(idx))
        case Apply(string) =>
          Option.when(input.startsWith(string, idx))(idx + string.size)
        case Empty =>
          None
      }

    // Check we matched the entire input
    loop(this, 0).map(idx => idx == input.size).getOrElse(false)
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Empty
}
object Regexp {
  def apply(string: String): Regexp =
    Apply(string)
}
```

Here's the example regular expression we started the chapter with.

```scala mdoc:silent
val regexp = Regexp("Sca") ++ Regexp("la") ++ Regexp("la").repeat
```

Here are cases that should succeed.

```scala mdoc
regexp.matches("Scala")
regexp.matches("Scalalalala")
```

Here are cases that should fail.

```scala mdoc
regexp.matches("Sca")
regexp.matches("Scalal")
regexp.matches("Scalaland")
```

Success! At this point we could add many extensions to our library. For example, regular expressions usually have a method (by convention denoted `+`) that matches one or more times, and one that matches zero or once (usually denoted `?`). These are both conveniences we can build on our existing API. However, our goal at the moment is to fully understand interpreters and the implementation technique we've used here. So in the next section we'll discuss these in detail.

#info(title: [Regular Expression Semantics])[
Our regular expression implementation handles union differently to Scala's built-in regular expressions. Look at the following example comparing the two.

```scala mdoc:silent
val r1 = "(z|zxy)ab".r
val r2 = Regexp("z").orElse(Regexp("zxy")) ++ Regexp("ab")
```
```scala mdoc
r1.matches("zxyab")
r2.matches("zxyab")
```

The reason for this difference is that our implementation commits to the first branch in a union that successfully matches some of the input, regardless of how that affects later matching. We should instead try both branches, but doing so makes the implementation more complex. The semantics of regular expressions are not essential to what we're trying to do here; we're just using them as an example to motivate the programming strategies we're learning. I decided the extra complexity of implementing union in the usual way outweighed the benefits, and so kept the simpler implementation. Don't worry, we'll see how to do it properly in @sec:adt-optimization!
]
