## Algebraic User Interfaces

Changing the interpretation of our terminal programs is more a theoretical than a practical problem. While it is true that different interpretations, such as saving to a text buffer, or tracing the state changes, will have niche uses, the vast majority of the time we'll use the default interpretation. A much more motivating example is a cross-platform user interface library. Frameworks such as [Flutter](https://flutter.dev/), [React Native](https://reactnative.dev/), and [Capacitor](https://capacitorjs.com/) derive a lot of their value by allowing programmers to define a single interface that works across web and mobile. We will build such a library here, but our ambitions are a bit reduced: we will create a terminal backend but leave other backends up to your inspiration and perspiration.

Broadly speaking, there are two kinds of user interfaces. When operating, say, a digital musical instrument, we require a continuous stream of values from the user interface. In contrast, when working with a form we only require the values once, when the form is submitted. Modelling a continuous stream of values is certainly doable (see functional reactive programming) but it adds inessential complexity. Therefore we will stick with the simpler kind of interface where the user submits values once.

We'll consider each of constructors, combinators, and interpreters in turn. 

Constructors will define the atomic units of user interface for our library. The granularity we use here trades off expressivity and convenience. At the very lowest level we could work with vertex buffers and the like, which would make our library a general purpose graphics library. This gives us the ultimate flexibility but is far too low level for this case study. At a higher level we might think of atomic units as user interface elements like labels, buttons, text inputs, and so on. This is the level at which HTML operates. At this level we still usually require multiple elements to construct a complete control. For example, in HTML what is conceptually a single form field will often consist of separate DOM elements for the label, the input control, and the control to show validation errors, plus some Javascript to add interactivity. We will go even higher level. Our atomic elements will specify the kind of user input we wants, such as a choice between a number of elements, and leave it up to the interpreter to decide how to render this using the platform's available controls. For example, we could render a one-of-many control using either radio buttons or a dropdown, or choose between the two depending on the number of choices. We'll also add labels, and optional validation rules, to each element. Let's model two such elements, to illustrate the idea.

```scala mdoc:silent
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
```


Here we defined two controls:

- `textInput`, which creates a text input where the user can enter any text that passes the validation rule; and
- `choice`, which gives the user a choice of one of the given items.

Notice how our modelling decisions restrict our expressivity. For example, `textInput` has a placeholder, which is displayed before the user enters input, but does not have a default value. By reducing expressivity we gain convenience. If the user's requirements fit our model it is very easy to create controls. Also notice that we don't have any way to control the appearance of controls. This is deliberate; we are pushing that concern into the interpreters. 

These controls generate an element of the program type `Ui`. Each particular interpreter, corresponding to a backend, will choose a concrete type for `Ui` corresponding to the needs of the user interface toolkit it is working with.

These two constructors are enough to illustrate the idea, so we will move on to combinators. In the context of user interfaces the most common combinators will specify the layout of elements. As with the constructors there are a number of possible designs: we could allow a lot of precision in layout, as CSS does for HTML, or we could provide a few pre-defined layouts, or we could even push layout into the interpreter. In keeping with our design for the constructors, and with the need to keep things simple, we will go with a very high-level design. Our single combinator, `and`, only specifies that two elements should occur together. It leaves it up to the interpreter how this should be rendered on the screen. 

```scala mdoc:silent
trait Layout[Ui[_]] {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
```

You might have noticed that `and` is another name for `product` from `Semigroupal`, which we encountered in Section [@sec:semigroupal]. It has exactly the same signature, apart from the name, and it represents the same concept as applied to user interfaces.

At this point we have defined two program algebras, `Controls` and `Layout`, and shown examples of both constructors and combinators.
The next step is to create an interpreter. Here we are going to create an extremely simple interpreter to illustrate the idea and to allow us to show how to write programs using our algebras. More full featured interpreters are certainly possible, but they don't introduce any new concepts and take considerably more code.

Our interpreter will use the Console IO features of the standard library to interact with the user.

```scala mdoc:silent
import cats.syntax.all.*
import scala.io.StdIn
import scala.util.Try

type Program[A] = () => A

object Simple extends Controls[Program], Layout[Program] {
  def and[A, B](first: Program[A], second: Program[B]): Program[(A, B)] =
    // Use Cats Semigroupal for Function0
    (first, second).tupled

  def textInput(
      label: String,
      placeholder: String,
      validation: Validation[String] = succeed
  ): Program[String] =
    () => {
      def loop(): String = {
        println(s"$label (e.g. $placeholder):")
        val input = StdIn.readLine

        validation(input).fold(
          msg => {
            println(msg)
            loop()
          },
          value => value
        )
      }

      loop()
    }

  def choice[A](label: String, options: Seq[(String, A)]): Program[A] =
    () => {
      def loop(): A = {
        println(label)
        options.zipWithIndex.foreach { case ((desc, _), idx) =>
          println(s"$idx: $desc")
        }

        Try(StdIn.readInt).fold(
          _ => {
            println("Please enter a valid number.")
            loop()
          },
          idx => {
            if idx >= 0 && idx < options.size then options(idx)(1)
            else {
              println("Please enter a valid number.")
              loop()
            }
          }
        )
      }

      loop()
    }
}
```

Now we can implement a simple example.

```scala mdoc:silent
def quiz[Ui[_]](
    controls: Controls[Ui],
    layout: Layout[Ui]
): Ui[(String, Int)] =
  layout.and(
    controls.textInput("What is your name?", "John Doe"),
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
  )
```

We can run this example with code like the following.

```scala
val (name, rating) = quiz(Simple, Simple)()
println(s"Hello $name!")
println(s"You gave tagless final a rating of $rating.")
```

Here is an example of interaction.

```sh
What is your name? (e.g. John Doe):
Noel Welsh
Tagless final is the greatest thing ever
0: Strongly disagree
1: Disagree
2: Neutral
3: Agree
4: Strongly agree
4
Hello Noel Welsh!
You gave tagless final a rating of 5.
```

We have a basic example working, but it is not very nice to work with. The way in which we write code in tagless final style is very convoluted compared to normal code. In the next section we'll see a different encoding of tagless final that gives the user a much better experience.
