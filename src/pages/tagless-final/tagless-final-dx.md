## A Better Encoding

```scala mdoc:invisible
type Validation[A] = A => Either[String, A]

// The validation rule that always succeeds
def succeed[A](value: A): Either[String, A] = Right(value)

trait Controls[Ui[_]] {
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Ui[String]

  def choice[A](label: String, options: Seq[(String, A)]): Ui[A]
}

trait Layout[Ui[_]] {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
```

The basic implementation of tagless final has quite a poor developer experience. Consider the refactoring of our example below.

```scala mdoc:silent:nest
def name[Ui[_]](controls: Controls[Ui]): Ui[String] =
  controls.textInput("What is your name?", "John Doe")
  
def rating[Ui[_]](controls: Controls[Ui]): Ui[Int] =
  controls.choice(
    "Tagless final is the greatest thing ever",
    Seq(
      "Strongly disagree" -> 1,
      "Disagree" -> 2,
      "Neutral" -> 3,
      "Agree" -> 4,
      "Strongly agree" -> 5
    )
  )
  
def quiz[Ui[_]](
    controls: Controls[Ui],
    layout: Layout[Ui]
): Ui[(String, Int)] =
  layout.and(name(controls), rating(controls))
```

This style of code quickly becomes tedious to write. The method signatures are quite involved, and passing the program algebras from method to method is annoying busy work.

An improvement is to make the program algebras `given` instances. If we define accessors

```scala mdoc:silent
object Controls {
  def apply[Ui[_]](using controls: Controls[Ui]): Controls[Ui] =
    controls
}

object Layout {
  def apply[Ui[_]](using layout: Layout[Ui]): Layout[Ui] =
    layout
}
```

we can then write

```scala mdoc:silent:nest
def name[Ui[_]: Controls]: Ui[String] =
  Controls[Ui].textInput("What is your name?", "John Doe")
  
def rating[Ui[_]: Controls]: Ui[Int] =
  Controls[Ui].choice(
    "Tagless final is the greatest thing ever",
    Seq(
      "Strongly disagree" -> 1,
      "Disagree" -> 2,
      "Neutral" -> 3,
      "Agree" -> 4,
      "Strongly agree" -> 5
    )
  )
  
def quiz[Ui[_]: Controls: Layout]: Ui[(String, Int)] =
  Layout[Ui].and(name, rating)
```

This is the encoding of tagless final that is common in the Scala community, but there is still a lot of notational overhead for the developer who has to write this code.
We can use Scala language features to reduce the overhead of writing code using a tagless final style to the point where is a simple as standard code.

We'll use a combination of five techniques:

1. creating a base type for program algebras;
2. making the program type a type member;
3. defining a type for programs;
4. defining constructors on companion objects; and
5. using extension methods for combinators.

This is quite involved, but each step is relatively simple. Let's see how it works.

Our first step is to create a base type for algebras. This is just a trait like

```scala mdoc:silent:nest
trait Algebra[Ui[_]]
```

Our program algebras extend this trait.

```scala mdoc:silent
trait Controls[Ui[_]] extends Algebra[Ui[_]]{
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Ui[String]

  def choice[A](label: String, options: Seq[(String, A)]): Ui[A]
}

trait Layout[Ui[_]] extends Algebra[Ui[_]]{
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
```

Now we make the program type a type member.

```scala mdoc:silent:nest
trait Algebra {
  type Ui[_]
}

trait Controls extends Algebra {
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Ui[String]

  def choice[A](label: String, options: Seq[(String, A)]): Ui[A]
}

trait Layout extends Algebra {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
```

At this point we've made sufficient changes that our example program is meaningfully changed.
Our starting point was

```scala
def quiz[Ui[_]: Controls: Layout](
    controls: Controls[Ui],
    layout: Layout[Ui]
): Ui[(String, Int)] =
  Layout[Ui].and(
    Controls[Ui].textInput("What is your name?", "John Doe"),
    Controls[Ui].choice(
      "Tagless final is the greatest thing ever",
      Seq(
        "Strongly disagree" -> 1,
        "Disagree" -> 2,
        "Neutral" -> 3,
        "Agree" -> 4,
        "Strongly agree" -> 5
      )
    )
  )
```

With the changes above we can instead write

```scala
def quiz(using alg: Controls & Layout): alg.Ui[(String, Int)] =
  alg.and(
    alg.textInput("What is your name?", "John Doe"),
    alg.choice(
      "Tagless final is the greatest thing ever",
      Seq(
        "Strongly disagree" -> 1,
        "Disagree" -> 2,
        "Neutral" -> 3,
        "Agree" -> 4,
        "Strongly agree" -> 5
      )
    )
  )
```

The key changes are:

1. the program algebras are a single parameter to the method, which is possible because they extend a common base type;
2. the `Ui` type parameter is no longer needed, as it has become a type member; and
3. we must now use a dependent method to specify the result type.

Our next step is to define a type for programs. Programs are conceptually functions from an algebra to a program type, so we can define such a type.

```scala mdoc:silent
trait Program[-Alg <: Algebra, A] {
  def apply(alg: Alg): alg.Ui[A]
}
```

Pay particular attention to the result type, `alg.Ui[A]`. As `Program` requires a dependent method type it cannot be a standard function.

The example now becomes

```scala mdoc:silent
val quiz =
  new Program[Controls & Layout, (String, Int)] {
    def apply(alg: Controls & Layout) =
      alg.and(
        alg.textInput("What is your name?", "John Doe"),
        alg.choice(
          "Tagless final is the greatest thing ever",
          Seq(
            "Strongly disagree" -> 1,
            "Disagree" -> 2,
            "Neutral" -> 3,
            "Agree" -> 4,
            "Strongly agree" -> 5
          )
        )
      )
  }
```

Programs are now values instead of methods. 
Notice that first type parameter of `Program` declares all the program algebras the program requires. 
It's still quite involved to write this code, though we can simplify it a bit by using the *single abstract method* technique, which means a `trait` with a single abstract method (like `Program`) can be implemented with a function.

```scala mdoc:silent:nest
val quiz: Program[Controls & Layout, (String, Int)] =
  (alg: Controls & Layout) =>
    alg.and(
      alg.textInput("What is your name?", "John Doe"),
      alg.choice(
        "Tagless final is the greatest thing ever",
        Seq(
          "Strongly disagree" -> 1,
          "Disagree" -> 2,
          "Neutral" -> 3,
          "Agree" -> 4,
          "Strongly agree" -> 5
        )
      )
    )
```

Programs-as-values is the key that unlocks the next two improvements. The first is to define constructors as methods on companion objects. 

```scala mdoc:silent
object Controls {
  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Program[Controls, String] =
    alg => alg.textInput(label, placeholder, validation)

  def choice[A](
    label: String, 
    options: Seq[(String, A)]
  ): Program[Controls, A] =
    alg => alg.choice(label, options)
}
```

This works because methods can now return programs.

The second and final improvement is to define extension methods for combinators. Since we only have one combinator, `and`, that means a single extension method.

```scala mdoc:silent
extension [Alg <: Algebra, A](p: Program[Alg, A]) {
  def and[Alg2 <: Algebra, B](
    second: Program[Alg2, B]
  ): Program[Alg & Alg2 & Layout, (A, B)] =
    alg => alg.and(p(alg), second(alg))
}
```

Pay particular attention to how the types are defined for this extension method. We define the extension on a `Program` requiring algebras `Alg`. The parameter to the `and` method is a `Program` requiring algebras `Alg2`. The result requires algebras `Alg & Alg2 & Layout`, which is the union of the algebras required by the two programs and the `Layout` algebra. In this way the combinators build up the algebras required for the program.

The net result is that users can write

```scala mdoc:silent:nest
val quiz  =
  Controls
    .textInput("What is your name?", "John Doe")
    .and(
      Controls.choice(
        "Tagless final is the greatest thing ever",
        Seq(
          "Strongly disagree" -> 1,
          "Disagree" -> 2,
          "Neutral" -> 3,
          "Agree" -> 4,
          "Strongly agree" -> 5
        )
      )
    )
```

which looks just like normal code. The type of `quiz` shows that type inference has correctly inferred all the needed program algebras.

```scala mdoc
quiz
```

This encoding requires more work from the library developer. However this is a one off cost, and result is that library users write much simpler code. For most applications of tagless final I think this is an appropriate trade off.
