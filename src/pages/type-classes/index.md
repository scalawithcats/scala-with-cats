# Introduction

Scalaz contains a wide variety of functional programming tools, and allows developers to pick and choose between them. A large proportion of the code is delivered in the form of *type classes* that we can apply to existing Scala types.

Quoting the introduction to Scalaz on [Github](https://github.com/scalaz/scalaz):

> Scalaz is a Scala library for functional programming.
>
> It provides purely functional data structures to complement those from the Scala standard library. It defines a set of foundational *type classes* (e.g. `Functor`, `Monad`) and corresponding instances for a large number of data structures.

**Type classes** are a programming pattern originating from Haskell. They allow us to extend existing libraries with new functionality, without using traditional inheritance, and without altering the original library source code.

In this chapter we will refresh our memory of type classes from Underscore's [Essential Scala][link-essential-scala], and take a first look at the Scalaz codebase. We will look at two example type classes---`Show` and `Equal`---and use them to identify patterns that will lay the foundations for the rest of the course.
