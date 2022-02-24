## Three Levels for Thinking About Code

To start thinking about thinking about programming I find it helpful to consider three different levels from which we can talk about code. They are paradigm, theory, and craft. Let's discuss each in turn.

You're probably heard of programming paradigms, such as object-oriented and functional programming, but what exactly is a programming paradigm? To me the core of a programming paradigm is a set of principles that define, usually somewhat loosely, the properties of good code. A paradigm is also, implicitly, a claim that code that follows these principles will be better (have fewer bugs, be easier to modify) than code that does not. For functional programming I believe these principles are composition and reasoning. I'll explain these shortly. Object-oriented programmers might point to the SOLID principles as guiding their coding decisions.

The theory level moves from the broad principles of the paradigm to specific techniques that can be reasonably well defined and apply to many languages within the paradigm, but still exist at a level above the code. Design patterns are an example in the object-oriented world. Algebraic data types are an example in functional programming. Most languages that are firmly in the functional programming paradigm, such as Haskell and O'Caml, support algebraic data types, as do many languages that straddle multiple paradigms, such as Rust, Scala, and Swift.

At the craft level we get to actual code, and the language specific nuance that goes into it. An example in Scala is the particular implementation of algebraic data types in terms of `sealed trait` and `final case class` in Scala 2, or `enum` in Scala 3.

In the next section I'll describe the functional programming paradigm. The remainder of this book is concerned with theory and craft. The theory is language agnostic but the craft is firmly in the world of Scala. Before we get into this there are two points I want to emphasize:

1. Paradigms are social constructs. They change over time. Object-oriented programming as practiced todays differs from from the style originally used in Simula and Smalltalk, and functional programming todays is very different from the original LISP code.

2. The three level organization is just a tool for thought. In real world is more complicated. Languages can and do straddle multiple paradigms. What may be theory in one language may be directly supported by a language construct in another, hence becoming craft.
