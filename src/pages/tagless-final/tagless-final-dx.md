## Tagless Final Developer Experience

```scala mdoc:invisible
type Validation[A] = A => Either[String, A]

// The validation rule that always succeeds
def succeed[A](value: A): Either[String, A] = Right(value)

trait Controls[Ui[_]] {
  def text(
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

This basic implementation of tagless final has quite a poor developer experience. Consider refactoring our example.

```scala mdoc:silent:nest
def name[Ui[_]](controls: Controls[Ui]): Ui[String] =
  controls.text("What is your name?", "John Doe")
  
def experience[Ui[_]](controls: Controls[Ui]): Ui[Int] =
  controls.choice(
    "How many years have you been using Scala?",
    Seq("0-2" -> 0, "3-5" -> 3, "5-7" -> 5, "8+" -> 8)
  )
  
def bio[Ui[_]](
    controls: Controls[Ui],
    layout: Layout[Ui]
): Ui[(String, Int)] =
  layout.and(name(controls), experience(controls))
```

This style of code quickly becomes tedious to write. The method signatures are quite involved, and passing the interfaces from method to method is annoying busy work.

The usual approach is to make the interfaces `given` instances. If we define the standard accessors

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
  Controls[Ui].text("What is your name?", "John Doe")
  
def experience[Ui[_]: Controls]: Ui[Int] =
  Controls[Ui].choice(
    "How many years have you been using Scala?",
    Seq("0-2" -> 0, "3-5" -> 3, "5-7" -> 5, "8+" -> 8)
  )
  
def bio[Ui[_]: Controls: Layout]: Ui[(String, Int)] =
  Layout[Ui].and(name, experience)
```

This is better, but it is still more complex than writing code using, say, a data interpreter.
We'll now see how we can use Scala language features to reduce the overhead of writing code using a tagless final style to the point where is a simple as standard code.

We'll use a combination of four techniques:

1. We'll define a type to represent a program, instead of using methods.
2. We'll use a subtyping relationship between 
3. the `Ui` type parameter will become a type member
4. extension methods for

