# Objects as Codata

In this chapter we will look at **codata**, the dual of algebraic data types.
We'll see that codata encompasses a large subset of object-oriented programming, whilst putting object-oriented features into a coherent conceptual framework with functional programming concepts such as algebraic data types.
We'll start by describing codata and seeing some examples. We'll then look at the relationship between codata and algebraic data types, and see how we can transform one into the other. Having seen how they are related, we will next look at the differences, which gives guidance on when to choose each representation. We will finish with a case study **todo**.




  - What about differences?
    - Finite vs infinite
    - Lazy vs eager
    - Extensibility

## Data vs Codata

The core distinction between data and codata is that data describes what things are, while codata describes what things can do. Data is transparent. Let's take a very simple algebraic data type:

```scala mdoc:silent
enum Bool {
  case True
  case False
}
```

If we have an instance of this algebraic data type we can tell exactly which case it is, by using a pattern match for example. Similarly, if the instances themselves hold data, as in `List` for example, we can always extract all the data within them.

Codata, on the other hand, is opaque. We cannot freely inspect it, like we can with data. However we do know what operations we can perform on any given instance. A common example is a data structure, such as a set. We don't know the internal representation, but we do know the operations we can perform, such as testing if a set contains an element or performing a set union. 

If you come from the object-oriented world you might recognize the description of codata above as programming to an interface. In many ways codata is just taking concepts from the object-oriented world and presenting them in a way that is consistent with the rest of the functional programming paradigm.

Classes and objects are familiar to most programmers. Part of their appeal is that they can express so many conceptually different abstractions with the same language constructs. For example, we can use objects to express functions, modules, and data (and we'll see these all in this book). This gives them a surface appearance of simplicity; it seems we need to learn only one abstraction to solve a huge of number of coding problems. However this apparent simplicity hides real complexity, as this variety of uses forces us to reverse engineer the conceptual intention from the code.

We will limit the object-oriented features we use to a subset that is easy to reason about. We won't use implementation inheritance, subtyping, overriding, or state. This gives us a subset of object-oriented code that fits within the conceptual model we are building.




## Data versus Codata

- Converting between algebraic data types and codata. Church encoding or Boehm-Berarducci encoding. I call it **functionalization** for simplicity. Show Church-encoded list. This is fold! Fold connects algebraic data types and codata.
- Choosing between algebraic data types and codata: extensibility
- Constructor vs destructor focus
  - observations (instance variables / fields) or eliminations
- Lazy vs eager duality. Representing things by what we can do means we don't have to evaluate any part of what they are until asked to do so. This means we can represent infinite data as codata. Stream.

## Case Study

Reverse mode automatic differentiation. Has simple types and OO extensibility is appropriate.


