## Algebraic Manipulation

Reifying a program represents it as a data structure. We can **rewrite** this data structure to several ends: as a way to simplify and therefore optimize the program being interpreted, and also a general form of computation that we can use to implement the interpreter. In this section we're going to return to our regular expression example, and show how rewriting can be used perform both of these tasks.

We will use a technique known as regular expression derivatives. Regular expression derivatives provide a simple way to match a regular expression against input (with the correct semantics for union, which you may recall we didn't deal with in the previous chapter). The derivative of a regular expression, with respect to a character, is the regular expression that remains after matching that character. Say we have the regular expression that matches the string `"osprey"`. In our library this would be `Regexp("osprey")`. The derivative with respect to the character `o` is `Regexp("sprey")`. In other words it's the regular expression that is looking for the string `"sprey"`. The derivative with respect to the character `a` is the regular expression that matches nothing, which is written `Regexp.empty` in our library. To take a more complicated example, the derivative with respect to `c` of `Regexp("cats").repeat` is `Regexp("ats") ++ Regexp("cats").repeat`. This indicates we're looking for the string `"ats"` followed by zero or more repeats of `"cats"`

All we need to do to determine if a regular expression matches some input is to calculate successive derivatives with respect to the characters in the input in the order in which they occur. If the resulting regular expression matches the empty string then we have a successful match. Otherwise it has failed to match.

To implement this algorithm we need three things:

1. an explicit representation of the regular expression that matches the empty string;
2. a method that tests if a regular expression matches the empty string; and
3. a method that computes the derivative of a regular expression with respect to a given character.

Our starting point is the basic reified interpreter we developed in the previous chapter. 
This is the simplest code and therefore the easiest to work with.

```scala mdoc:silent
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
  val empty: Regexp = Empty

  def apply(string: String): Regexp =
    Apply(string)
}
```

We want to explicitly represent the regular expression that matches the empty string, as it plays an important part in the algorithms that follow. 
This is simple to do: we just reify it and adjust the constructors as necessary.
I've called this case "epsilon", which matches the terminology used in the literature.

```scala
enum Regexp {
  // ...
  case Epsilon
}
object Regexp {
  val epsilon: Regexp = Epsilon

  def apply(string: String): Regexp =
    if string.isEmpty() then Epsilon
    else Apply(string)
}
```

Next up we will create a predicate that tells us if a regular expression matches the empty string. Such a regular expression is called "nullable". The code is so simple it's easier to read it than try to explain it in English.

```scala
def nullable: Boolean =
  this match {
    case Append(left, right) => left.nullable && right.nullable
    case OrElse(first, second) => first.nullable || second.nullable
    case Repeat(source) => true
    case Apply(string) => false
    case Epsilon => true
    case Empty => false
  }
```

Now we can implement the actual regular expression derivative.
It consists of two parts: the method to calculate the derivative which in turn depends on a method that handles a nullable regular expression. Both parts are quite simple so I'll give the code first and then explain the more complicated parts.

```scala
def delta: Regexp =
  if nullable then Epsilon else Empty

def derivative(ch: Char): Regexp =
  this match {
    case Append(left, right) =>
      (left.derivative(ch) ++ right).orElse(left.delta ++ right.derivative(ch))
    case OrElse(first, second) =>
      first.derivative(ch).orElse(second.derivative(ch))
    case Repeat(source) =>
      source.derivative(ch) ++ this
    case Apply(string) =>
      if string.size == 1 then
        if string.charAt(0) == ch then Epsilon
        else Empty
      else if string.charAt(0) == ch then Apply(string.tail)
      else Empty
    case Epsilon => Empty
    case Empty => Empty
  }
```

I think this code is reasonably straightforward, except perhaps for the cases for `OrElse` and `Append`. The case for `OrElse` is trying to match both regular expressions simultaneously, which gets around the problem in our earlier implementation. The definition of `nullable` ensures we match if either side matches. The case for `Append` is attempting to match the `left` side if it is still looking for characters; otherwise it is attempting to match the `right` side.

With this we redefine `matches` as follows.

```scala
def matches(input: String): Boolean = {
  val r = input.foldLeft(this){ (regexp, ch) => regexp.derivative(ch) }
  r.nullable
}
```

```scala mdoc:reset:invisible
enum Regexp {
  def ++(that: Regexp): Regexp = {
    Append(this, that)
  }

  def orElse(that: Regexp): Regexp = {
    OrElse(this, that)
  }

  def repeat: Regexp = {
    Repeat(this)
  }

  def `*` : Regexp = this.repeat

  /** True if this regular expression accepts the empty string */
  def nullable: Boolean =
    this match {
      case Append(left, right)   => left.nullable && right.nullable
      case OrElse(first, second) => first.nullable || second.nullable
      case Repeat(source)        => true
      case Apply(string)         => false
      case Epsilon               => true
      case Empty                 => false
    }

  def delta: Regexp =
    if nullable then Epsilon else Empty

  def derivative(ch: Char): Regexp =
    this match {
      case Append(left, right) =>
        (left.derivative(ch) ++ right)
          .orElse(left.delta ++ right.derivative(ch))
      case OrElse(first, second) =>
        first.derivative(ch).orElse(second.derivative(ch))
      case Repeat(source) =>
        source.derivative(ch) ++ this
      case Apply(string) =>
        if string.size == 1 then
          if string.charAt(0) == ch then Epsilon
          else Empty
        else if string.charAt(0) == ch then Apply(string.tail)
        else Empty
      case Epsilon => Empty
      case Empty   => Empty
    }

  def matches(input: String): Boolean = {
    val r = input.foldLeft(this) { (regexp, ch) => regexp.derivative(ch) }
    r.nullable
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Epsilon
  case Empty
}
object Regexp {
  val empty: Regexp = Empty

  val epsilon: Regexp = Epsilon

  def apply(string: String): Regexp =
    if string.isEmpty() then Epsilon
    else Apply(string)
}
```

We can show the code works as expected.

```scala mdoc:silent
val regexp = Regexp("Sca") ++ Regexp("la") ++ Regexp("la").repeat
```
```scala mdoc
regexp.matches("Scala")
regexp.matches("Scalalalala")
regexp.matches("Sca")
regexp.matches("Scalal")
```

It also solves the problem with the earlier implementation.

```scala mdoc
Regexp("cat").orElse(Regexp("cats")).matches("cats")
```

This is a nice result for a very simple algorithm.
However there is a problem.
You might notice that regular expression matching can become very slow. 
In fact we can run out of heap space trying a simple match like

```scala
Regexp("cats").repeat.matches("catscatscatscats")
// java.lang.OutOfMemoryError: Java heap space
```

This happens because the derivative of the regular expression can grow very large.
Look at this example, after only a few derivatives.

```scala mdoc:to-string
Regexp("cats").repeat.derivative('c').derivative('a').derivative('t')
```

The root cause is that the derivative rules for `Append`, `OrElse`, and `Repeat` can produce a regular expression that is larger than the input. However this output often contains redundant information. In the example above there are multiple occurrences of `Append(Empty, ...)`, which is equivalent to just `Empty`. This is similar to adding zero or multiplying by one in arithmetic, and we can use similar algebraic simplification rules to get rid of these unnecessary elements.

We can implement this simplification in one of two ways: we can make simplification a separate method that we apply to an existing `Regexp`, or we can do the simplification as we construct the `Regexp`. I've chosen to do the latter, modifying `++`, `orElse`, and `repeat` as follows:

```scala
def ++(that: Regexp): Regexp = {
  (this, that) match {
    case (Epsilon, re2) => re2
    case (re1, Epsilon) => re1
    case (Empty, _) => Empty
    case (_, Empty) => Empty
    case _ => Append(this, that)
  }
}

def orElse(that: Regexp): Regexp = {
  (this, that) match {
    case (Empty, re) => re
    case (re, Empty) => re
    case _ => OrElse(this, that)
  }
}

def repeat: Regexp = {
  this match {
    case Repeat(source) => this
    case Epsilon => Epsilon
    case Empty => Empty
    case _ => Repeat(this)
  }
}
```

With this small change in-place, our regular expressions stay at a reasonable size for any input.

```scala mdoc:reset:invisible
enum Regexp {
  def ++(that: Regexp): Regexp = {
    (this, that) match {
      case (Epsilon, re2) => re2
      case (re1, Epsilon) => re1
      case (Empty, _) => Empty
      case (_, Empty) => Empty
      case _ => Append(this, that)
    }
  }

  def orElse(that: Regexp): Regexp = {
    (this, that) match {
      case (Empty, re) => re
      case (re, Empty) => re
      case _ => OrElse(this, that)
    }
  }

  def repeat: Regexp = {
    this match {
      case Repeat(source) => this
      case Epsilon => Epsilon
      case Empty => Empty
      case _ => Repeat(this)
    }
  }

  def `*` : Regexp = this.repeat

  /** True if this regular expression accepts the empty string */
  def nullable: Boolean =
    this match {
      case Append(left, right) => left.nullable && right.nullable
      case OrElse(first, second) => first.nullable || second.nullable
      case Repeat(source) => true
      case Apply(string) => false
      case Epsilon => true
      case Empty => false
    }

  def delta: Regexp =
    if nullable then Epsilon else Empty

  def derivative(ch: Char): Regexp =
    this match {
      case Append(left, right) =>
        (left.derivative(ch) ++ right).orElse(left.delta ++ right.derivative(ch))
      case OrElse(first, second) =>
        first.derivative(ch).orElse(second.derivative(ch))
      case Repeat(source) =>
        source.derivative(ch) ++ this
      case Apply(string) =>
        if string.size == 1 then
          if string.charAt(0) == ch then Epsilon
          else Empty
        else if string.charAt(0) == ch then Apply(string.tail)
        else Empty
      case Epsilon => Empty
      case Empty => Empty
    }

  def matches(input: String): Boolean = {
    val r = input.foldLeft(this){ (regexp, ch) => regexp.derivative(ch) }
    r.nullable
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Epsilon
  case Empty
}
object Regexp {
  val empty: Regexp = Empty

  val epsilon: Regexp = Epsilon

  def apply(string: String): Regexp =
    if string.isEmpty() then Epsilon
    else Apply(string)
}
```

```scala mdoc:to-string
Regexp("cats").repeat.derivative('c').derivative('a').derivative('t')
```

Here's the final code for the complete system.

```scala mdoc:reset:silent
enum Regexp {
  def ++(that: Regexp): Regexp = {
    (this, that) match {
      case (Epsilon, re2) => re2
      case (re1, Epsilon) => re1
      case (Empty, _) => Empty
      case (_, Empty) => Empty
      case _ => Append(this, that)
    }
  }

  def orElse(that: Regexp): Regexp = {
    (this, that) match {
      case (Empty, re) => re
      case (re, Empty) => re
      case _ => OrElse(this, that)
    }
  }

  def repeat: Regexp = {
    this match {
      case Repeat(source) => this
      case Epsilon => Epsilon
      case Empty => Empty
      case _ => Repeat(this)
    }
  }

  def `*` : Regexp = this.repeat

  /** True if this regular expression accepts the empty string */
  def nullable: Boolean =
    this match {
      case Append(left, right) => left.nullable && right.nullable
      case OrElse(first, second) => first.nullable || second.nullable
      case Repeat(source) => true
      case Apply(string) => false
      case Epsilon => true
      case Empty => false
    }

  def delta: Regexp =
    if nullable then Epsilon else Empty

  def derivative(ch: Char): Regexp =
    this match {
      case Append(left, right) =>
        (left.derivative(ch) ++ right).orElse(left.delta ++ right.derivative(ch))
      case OrElse(first, second) =>
        first.derivative(ch).orElse(second.derivative(ch))
      case Repeat(source) =>
        source.derivative(ch) ++ this
      case Apply(string) =>
        if string.size == 1 then
          if string.charAt(0) == ch then Epsilon
          else Empty
        else if string.charAt(0) == ch then Apply(string.tail)
        else Empty
      case Epsilon => Empty
      case Empty => Empty
    }

  def matches(input: String): Boolean = {
    val r = input.foldLeft(this){ (regexp, ch) => regexp.derivative(ch) }
    r.nullable
  }

  case Append(left: Regexp, right: Regexp)
  case OrElse(first: Regexp, second: Regexp)
  case Repeat(source: Regexp)
  case Apply(string: String)
  case Epsilon
  case Empty
}
object Regexp {
  val empty: Regexp = Empty

  val epsilon: Regexp = Epsilon

  def apply(string: String): Regexp =
    if string.isEmpty() then Epsilon
    else Apply(string)
}
```

Let's go through the main points of that we've seen here.

Firstly, I hope you find the idea of regular derivatives interesting and a bit surprising. I certainly did when I first read about them. There is a deeper point, which runs throughout the book: most problems have already been solved and we can save a lot of time if we can just find those solutions. I elevate this idea of the status of a strategy, which I call **read the literature** for reasons that will soon be clear. Most developers read the occasional blog post and might attend a conference from time to time. Many fewer, I think, read academic papers. I think this is a shame as academic papers contain some great ideas and present them very concisely. Highlighting this work is one reason that I give paper suggestions in the conclusions of each chapter. Part of the fault is with the academics: they write in a style that is hard to read if you're not used to it. I can only encourage you to perserve, and with time you will find them easier to process.


Conceptually this is an interpreter, because it uses structural recursion, even though the result is of our program type.

Domain specific knowledge.

Rewriting as a form of computation.

There's no general purpose solution to this problem.
It depends on the nature of the structure we are simplifying and the rules we are using.
If repeated application of the rules is guaranteed to terminate in an expression that has no further possible simplifications, we call the rules **strongly normalizing**. 
An expression that has no possible further simplifications is said to be in a **normal form**.
We have already seen one example of a normal form when discussing algebraic data types, where we talked about disjunctive normal form.
Finally, if we can apply a function or method to it's own output, and it reaches a value where the input and the output are the same, we say the function or method has a **fixed point**.
If rewrite have a fixed point for all possible inputs then they are strongly normalizing.

