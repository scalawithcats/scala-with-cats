# Tagless Final Interpreters

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

Changing the interpretation of our terminal programs is more a theoretical than a practical problem. While it is true that different interpretations, such as saving to a text buffer, or tracing the state changes, will have niche uses, the vast majority of the time we'll use the default interpretation. A much more motivating example is a cross-platform user interface library. User interfaces targeting the web and mobile platforms is a great source of value provided by frameworks such as [React Native](https://reactnative.dev/) and [Capacitor](https://capacitorjs.com/). We'll be a bit less ambitious here, targeting the terminal and the web browser.
