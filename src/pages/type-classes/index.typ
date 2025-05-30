#import "../stdlib.typ": info, warning, solution
= Contextual Abstraction 
<sec:type-classes>


All but the simplest programs depend on the *context* in which they run. The number of available CPU cores is an example of context provided by the computer, which a program might adapt to by changing how work is distributed. Other forms of context include configuration read from files and environment variables, and (and we'll see at lot of this later) values created at compile-time, such as serialization formats, in response to the type of some method parameters.

Scala is one of the few languages that provides features for *contextual abstraction*, known as *implicits* in Scala 2 or *given instances* in Scala 3. In Scala these features are intimately related to types; types are used to select between different available given instances and drive construction of given instances at compile-time.

Most Scala programmers are less confident with the features for contextual abstraction than with other parts of the language, and they are often entirely novel to programmers coming from other languages. Hence this chapter will start by reviewing the abstractions formely known as implicits: given instances and using clauses. We will then look at one of their major uses, *type classes*[^type-class-defn]. Type classes allow us to extend existing types with new functionality, without using traditional inheritance, and without altering the original source code. Type classes are the core of Cats, which we will be exploring in the next part of this book.

<!--
Type classes work well with another programming pattern: _algebraic data types_.
These are closed systems of types that we use to represent data or concepts.
Because the systems are closed (and therefore cannot be extended by other users),
we can process them using pattern matching
and the compiler will check the exhaustiveness of our case clauses.

There are two other patterns we need to cover in this chapter.
*Value classes* provide a way to wrap up
generic data types like `Strings` and `Ints`
and give them specific meanings in a given context.
The extra type information is useful when type classes.
*Type aliases* are another pattern that
provide aliases for large, complex types.
-->

[^type-class-defn]: The word "class" doesn't strictly mean `class` in the Scala or Java sense.
