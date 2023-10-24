## Regular Expressions

We'll start this case study by briefly describing the usual task for regular expressions---matching text---and then take a more theoretical view. We'll then move on to implementation.

Programmers mostly commonly use regular expressions for matching text. For example, if we wanted to match all the strings like `"Scala"`, `"Scalala"`, `"Scalalala"` and so on, we could use the following regular expression.

```scala mdoc:silent
val regexp = "Sca(la)+".r
```

Let's check it matches what we're looking for.

```scala mdoc
regexp.matches("Scala")
regexp.matches("Scalalalala")
regexp.matches("Sca")
regexp.matches("Scalal")
```

It seems to work, but how does the code relate to the problem we've solving? Regular expressions are a domain specific language encoded in a `String`. The basic rules for regular expressions are that they match exactly the characters in the string, unless they one of the special characters that encode a particular rule. In the example above, we use `(` and `)` to group the sequence of characters `"la"`, and  `+` to match this group one or more times.

That's all I'm going to say about regular expressions as they exist in Scala. If you'd like to learn more there are many resources online. The [JDK documentation](https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/regex/Pattern.html) is one example, which describes all the features available in the JVM implementation of regular expressions.

Let's turn to the theoretical description. A regular expression is:

1. a string, which matches exactly that string; 
2. the concatenation of two regular expressions, which matches the first regular expression and then the second;
3. the union of two regular expressions, which matches if either expression matches; and
4. the repetition of a regular expression (often known as the Kleene star), which matches zero or more repetitions of the underlying expression.

This description is useful because it defines an API. Let's walk through the four parts of the description and see how they relate to code.

The first part tells us we need a constructor with type `String => Regexp`.
In Scala we put constructors on the companion object, so this tells us we need code

```scala
object Regexp {
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

Repetition we'll call `repeat`, and define an alias `*` that matches how this operation is written in conventional regular expressions.

```scala
trait Regexp {
  def ++(that: Regexp): Regexp
  def orElse(that: Regexp): Regexp
  def repeat: Regexp
  def `*`: Regexp = this.repeat
}
```

We're missing on thing: a method to actually match our regular expression against some input. Let's call this method `matches`.

```scala
trait Regexp {
  def ++(that: Regexp): Regexp
  def orElse(that: Regexp): Regexp
  def repeat: Regexp
  def `*`: Regexp = this.repeat
  
  def matches(input: String): Boolean
}
```

Now we've defined the API we can turn to implementation.
We're going to represent `Regexp` as an algebraic data type, and each method that returns a `Regexp` will return an instance of this algebraic data type.
What should be the elements that make up the algebraic data type?
They're going to exactly match the method calls, and their constructor arguments will be exactly the parameters passed to the method *including the hidden `this` parameter for methods on the trait*.

Here's the code.

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
}
object Regexp {
  def apply(string: String): Regexp =
    Apply(string)
}
```

