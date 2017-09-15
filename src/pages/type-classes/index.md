# Introduction {#sec:type-classes}

Cats contains a wide variety of functional programming tools
and allows developers to pick and choose the ones we want to use.
The majority of these tools are delivered in the form of *type classes*
that we can apply to existing Scala types.

Type classes are a programming pattern originating in Haskell [^type-class-defn].
They allow us to extend existing libraries with new functionality,
without using traditional inheritance,
and without altering the original library source code.

<!--
Type classes work well with another programming pattern: *algebraic data types*.
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

In this chapter we will refresh our memory of type classes
from Underscore's [Essential Scala][link-essential-scala] book,
and take a first look at the Cats codebase.
We will look at two example type classes---`Show` and `Eq`---using
them to identify patterns that lay the foundations for the rest of the book.

We'll finish by tying type classes back into algebraic data types,
pattern matching, value classes, and type aliases,
presenting a structured approach to functional programming in Scala.

[^type-class-defn]: The word "class" doesn't strictly mean `class` in the Scala or Java sense.
