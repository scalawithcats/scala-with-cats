#import "../stdlib.typ": info, warning, solution
== Algebraic Manipulation


Reifying a program represents it as a data structure. We can *rewrite* this data structure to several ends: as a way to simplify and therefore optimize the program being interpreted, but also as a general form of computation implementing the interpreter. In this section we're going to return to our regular expression example, and show how rewriting can be used perform both of these tasks.

We will use a technique known as regular expression derivatives. Regular expression derivatives provide a simple way to match a regular expression against input (with the correct semantics for union, which you may recall we didn't deal with in the previous chapter). The derivative of a regular expression, with respect to a character, is the regular expression that remains after matching that character. Say we have the regular expression that matches the string `"osprey"`. In our library this would be `Regexp("osprey")`. The derivative with respect to the character `o` is `Regexp("sprey")`. In other words it's the regular expression that is looking for the string `"sprey"`. The derivative with respect to the character `a` is the regular expression that matches nothing, which is written `Regexp.empty` in our library. To take a more complicated example, the derivative with respect to `c` of `Regexp("cats").repeat` is `Regexp("ats") ++ Regexp("cats").repeat`. This indicates we're looking for the string `"ats"` followed by zero or more repeats of `"cats"`

All we need to do to determine if a regular expression matches some input is to calculate successive derivatives with respect to the characters in the input in the order in which they occur. If the resulting regular expression matches the empty string then we have a successful match. Otherwise it has failed to match.

To implement this algorithm we need three things:

+ an explicit representation of the regular expression that matches the empty string;
+ a method that tests if a regular expression matches the empty string; and
+ a method that computes the derivative of a regular expression with respect to a given character.

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

Here's the final code.

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

Notice that our implementation is tail recursive. The only "looping" is the call to the tail recursive `foldLeft` in `matches`. No continuation-passing style transform is necessary here! (Calculating the derivatives is not tail recursive but it very unlikely this would overflow the stack.) This may not be surprising if you've studied theory of computation. A key result from that field is the equivalence between regular expressions and finite state machines. If you know this you may have found it a bit surprising we had to use a stack at all in our prior implementations. But hold on a minute. If we think carefully about regular expression derivatives we'll see that they actually are continuations! A continuation means "what comes next", which is exactly what a regular expression derviative defines for a regular expression and a particular character. So our interpreter does use CPS, but reified as a regular expression not a function, and derived through a different route.

Continuations reify control-flow. That is, they give us an explicit representation of how control moves through our program. This means we can change the control flow by applying continuations in a different order. Let's make this concrete. A regular expression derivative represents a continuation. So imagine we're running a regular expression on data that arrives asynchronously; we want to match as much data as we have available, and then suspend the regular expression and continue matching when more data arrives. This is trival. When we run out of data we just store the current derivative. When more data arrives we continue processing using the derivative we stored. Here's an example.

Start by defining the regular expression.

```scala mdoc:silent
val cats = Regexp("cats").repeat
```

Process the first piece of data and store the continuation.

```scala mdoc:silent
val next = "catsca".foldLeft(cats){ (regexp, ch) => regexp.derivative(ch) }
```

Continue processing when more data arrives.

```scala mdoc:silent
"tscats".foldLeft(next){ (regexp, ch) => regexp.derivative(ch) }
```

Notice that we could just as easily go back to a previous regular expression if we wanted to. This would give us backtracking. We don't need backtracking for regular expressions, but for more general parsers we do. In fact with continuations we can define any control flow we like, including backtracking search, exceptions, cooperative threading, and much much more.

In this section we've also seen the power of rewrites. Regular expression matching using derivatives works solely by rewriting the regular expression. We also used rewriting to simplify the regular expressions, avoiding the explosion in size that derivatives can cause.
The abstract type of these methods is `Program => Program` so we might think they are combinators. However the implementation uses structural recursion and they serve the role of interpreters. Rewrites are the one place where the types alone can lead us astray.

I hope you find regular expression derivatives interesting and a bit surprising. I certainly did when I first read about them. There is a deeper point here, which runs throughout the book: most problems have already been solved and we can save a lot of time if we can just find those solutions. I elevate this idea of the status of a strategy, which I call *read the literature* for reasons that will soon be clear. Most developers read the occasional blog post and might attend a conference from time to time. Many fewer, I think, read academic papers. This is unfortunate. Part of the fault is with the academics: they write in a style that is hard to read without some practice. However I think many developers think the academic literature is irrelevant. One of the goals of this book is to show the relevance of academic work, which is why each chapter conclusion sketches the development of its main ideas with links to relevant papers.
