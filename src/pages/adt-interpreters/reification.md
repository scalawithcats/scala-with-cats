## Interpreters and Reification

There are two different concepts at play here:

1. the interpreter strategy; and
2. the interpreter's implementation strategy of reification.

The essence of the **interpreter strategy** is to separate description and action. Descriptions are programs; things that we want to happen. The interpreter runs the programs, carrying out the actions described within them.

In the example we just saw, a `Regexp` value is a program. It is a description of a pattern we are looking for within a `String`.
The `matches` method is an interpreter. It carries our the instructions in the description, looking for the pattern within the input.


### The Structure of Interpreters

All uses of the interpreter strategy have a particular structure to their methods.
There are three different types of methods:

1. constructors, or introduction forms, have type `A => Program`, where `A` is any type and `Program` is the type of programs. Constructors conventionally live on the `Program` companion object in Scala. We see that `apply` is a constructor of `Regexp`. It has type `String => Regexp`, which matches the pattern `A => Program` for a constructor.

2. combinators have a program input and output, so the type is similar to `Program => Program` but there are often additional parameters. In our regular expression example, all of `++`, `orElse`, and `repeat` are combinators. They all have a `Regexp` input (the `this` parameter) and produce a `Regexp`. They sometimes have additional parameters, as is the case for `++` or `orElse`. In both these methods the parameter is a `Regexp`, but it is not the case that additional parameters to a combinator must be of the program type. Conventionally these methods live on the `Program` type.

3. destructors, interpreters, or elimination forms, have type `Program => A`. In our regular expression example we have a single interpreter, `matches`, but we could easily add more. For example, we often want to extract elements from the input.

This structure is often called an **algebra** in the functional programming world.


## Implementing Interpreters with Reification

Now that we understand the components of interpreter we can talk more clearly about the implementation strategy we used.
We used a strategy called a **reification**, **deep embedding**, or **initial algebra**.

Reification, in an abstract sense, means to make concrete what is abstract. Concretely, reification in the programming sense means to turn methods into data. When using the interpreter strategy, we reify all the components of the program type. This means reifying constructors and combinators.

Here are the rules for reification:

1. We define some type, which we'll call `Program`, to represent programs.
2. We make `Program` an algebraic data type.
3. All constructors and combinators become product types within the `Program` algebraic data type.
4. Each product type holds exactly the parameters to the constructor or combinator, including the `this` parameter for combinators.

If we do this, the interpreter becomes a structural recursion on the algebraic data type we have just defined.
