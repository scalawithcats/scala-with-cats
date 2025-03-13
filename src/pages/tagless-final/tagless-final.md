## Tagless Final Interpreters

Now we understand codata interpreters we're ready to move on to tagless final.
Tagless final is a simple extension of the basic codata interpreter.
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

Broadly speaking, there are two kinds of user interfaces. When operating, say, a digital musical instrument, we require a continuous stream of values from the user interface. In contrast, when working with a form we only require the values once, when the form is submitted. Modeling a continuous stream of values is certainly doable (see functional reactive programming) but it is a distraction from our core goal here, which is to create user interfaces. Therefore we will stick with the simply kind of interface where the user submits values once.

In the previous example we used an ad-hoc process to produce the terminal interaction library, fixing problems as we uncovered them. Here we will take a more systematic approach, to illustrate how we can apply strategies to derive code.

We'll start by defining the algebra we are working with. We'll need at least one each of constructors, combinators, and interpreters. Constructors will be the atomic units of user interface our library can work with. The granularity we use here tradeoffs expressivity for convenience. At the very lowest level we work with vertex buffers and the like, which essentially makes our library a general graphics library. That's far too low level for this case study. At a higher level we might think of atomic units as user interface elements like labels, buttons, text inputs, and so on. This is better, but if we are too granular we'll be requiring the unit to wire up common functionality like field validation and form submission. We will go even higher level and work with atomic elements that are complete user interface elements consisting of a label, a control for user input, and optional validation rules. Let's model two such controls, to illustrate the idea.

```scala mdoc:silent
type Validation[A] = A => Either[String, A]

// The validation rule that always succeeds
def succeed[A](value: A): Either[String, A] = Right(value)

// The type of user interface elements. We don't know what this is yet.
type Element[A] = Nothing

trait Ui {
  def text(label: String, placeholder: String, validation: Validation[String] = succeed): Element[String]

  def choice[A](label: String, options: Seq[(String, A)]): Element[A]
}
```


Here we defined two controls:

- `text`, which creates a text input where the user can enter any text that passes the validation rule; and
- `choices`, which gives the user a choice of one of the given item.

Notice how our modeling decisions restrict our expressiviity. For example, `text` can have a placeholder, which is displayed before the user enters input, but does not have a default value. Notice that we don't have way to control the appearance of controls. This is deliberate; we are pushing that concern into the interpreters. 

These two constructors are enough to illustrate the problem, so we will move on to combinators.
