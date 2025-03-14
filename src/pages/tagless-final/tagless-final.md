## Tagless Final Interpreters

Now we understand codata interpreters we're ready to move on to tagless final.
The core of tagless final is a simple extension of the basic codata interpreter.
In our terminal interaction example our programs had type

```scala
State[Terminal, A]
```

which is equivalent to

```scala
Terminal => (Terminal, A)
```

In words, a program accepts a `Terminal` and returns a possibly updated `Terminal` and a value of type `A`. 
Note that the output type `A` is fixed by each particular operation. 
For example, when we write to the terminal the type `A` is fixed to `Unit`.

We saw that we had limited extensibility.
We could extend the `Terminal` type to add new operations, such as additional colors.
However we couldn't add new interpretations.
The root cause is that the output types are fixed.
For example, if we wanted to send output to a `String` buffer we would want `print` to return `String` instead of `Unit`.

The core of tagless final, relative to a basic codata interpreter, is to allow output types to vary.
We do this by making them type parameters.
So instead of `print` having type `State[Terminal, Unit]` it would have type `State[Terminal, A]`. Where does `A` comes from? We'll get to that in a moment. 
First I want to introduce a more motivating example we will use for tagless final. 

Changing the interpretation of our terminal programs is more a theoretical than a practical problem. While it is true that different interpretations, such as saving to a text buffer, or tracing the state changes, will have niche uses, the vast majority of the time we'll use the default interpretation. A much more motivating example is a cross-platform user interface library. User interfaces targeting the web and mobile platforms is a great source of the value provided by frameworks such as [Flutter](https://flutter.dev/), [React Native](https://reactnative.dev/), and [Capacitor](https://capacitorjs.com/). We'll be a bit less ambitious here, targeting the terminal and the web browser.


## Algebraic User Interfaces

Broadly speaking, there are two kinds of user interfaces. When operating, say, a digital musical instrument, we require a continuous stream of values from the user interface. In contrast, when working with a form we only require the values once, when the form is submitted. Modeling a continuous stream of values is certainly doable (see functional reactive programming) but it adds inessential complexity. Therefore we will stick with the simpler kind of interface where the user submits values once.

In the previous example we used an ad-hoc process to produce the terminal interaction library, fixing problems as we uncovered them. Here we will take a more systematic approach, to illustrate how we can apply strategies to derive code.

We'll start by defining the algebra we are working with. Remember that algebras consist of constructors, combinators, and interpreters. Let's consider each in turnn. 

Constructors will define the atomic units of user interface our library works with. The granularity we use here trades off expressivity for convenience. At the very lowest level we could work with vertex buffers and the like, which essentially makes our library a general graphics library. This gives us the ultimate flexibility but is far too low level for this case study. At a higher level we might think of atomic units as user interface elements like labels, buttons, text inputs, and so on. This is the level at which HTML operates. At this level we still usually require multiple elements to construct a complete control. For example, in HTML the developer usually has to use a number of DOM elements and Javascript to build common functionality like field validation. We will go even higher level. Our atomic elements will specify the kind of user input we wants, such as a choice between a number of elements, and leave it up to the interpreter to decide how to render this using the platform's available controls. For example, we could render a one-of-many control using either radio buttons or a dropdown, or choose between the two depending on the number of choices. We'll also add labels, and optional validation rules, to each elements. Let's model two such controls, to illustrate the idea.

```scala mdoc:silent
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
```


Here we defined two controls:

- `text`, which creates a text input where the user can enter any text that passes the validation rule; and
- `choice`, which gives the user a choice of one of the given items.

Notice how our modeling decisions restrict our expressivity. For example, `text` can have a placeholder, which is displayed before the user enters input, but does not have a default value. Notice that we don't have any way to control the appearance of controls. This is deliberate; we are pushing that concern into the interpreters. 

These controls generate an element of a type parameter `Ui`. Each particular interpreter, corresponding to a backend, will choose a concrete type for `Ui` corresponding to the needs of the user interface toolkit it is working with.

These two constructors are enough to illustrate the problem, so we will move on to combinators. In the context of user interfaces, the most common combinators will specify the layout of elements. As with the constructors, there are a number of possible designs. We could allow a lot of precision in layout, as CSS does for HTML. In keeping with our design for the constructors, and with the need to keep things simple, we will go with a very high-level design. Our single combinator, `and`, only specifies that two elements should occur together. It leaves it up to the interpreter how this should be achieved on the screen. 

```scala mdoc:silent
trait Layout[Ui[_]] {
  def and[A, B](first: Ui[A], second: Ui[B]): Ui[(A, B)]
}
```

You might have noticed that `and` is another name for `product` from `Semigroupal`, which we encountered in Section [@sec:semigroupal]. It has exactly the same signature, apart from the name, and it represents the same concept as applied to user interfaces.

The next step is to create an interpreter. Here we are going to create an extremely simple interpreter to illustrate the idea and to allow us to show how to write programs using our algebras. We will write more full featured interpreters later.

Our interpreter will use the very basic Console IO features of the standard library to interact with the user.

**TODO Does Cats provide applicative for Function0?**

```scala mdoc:silent
import cats.syntax.all.*
import scala.io.StdIn
import scala.util.Try

type Program[A] = () => A

object Simple extends Controls[Program], Layout[Program] {
  def and[A, B](first: Program[A], second: Program[B]): Program[(A, B)] =
    (first, second).tupled

  def text(
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

