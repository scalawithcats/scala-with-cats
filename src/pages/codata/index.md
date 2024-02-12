# Objects as Codata

In this chapter we will look at objects and classes as the dual of algebraic data types, also known as **codata**.
We'll see that we can transform algebraic data into codata, and vice versa, but that each has different properties that sometimes makes one preferrable over the other.

Classes and objects are familiar to most programmers. Part of their appeal is that they can express so many conceptually different abstractions. For example, we can use objects to express functions, modules, and data (and we'll see these all in this book). This gives them a surface appearance of simplicity; it seems we need to learn only one abstraction to solve a huge of number of coding problems. However this apparent simplicity hides real complexity, as this variety of uses forces us to reverse engineer the conceptual intention from the code.

Here we will limit the object-oriented features we use to a manageable subset. We won't use implementation inheritance, overriding, or state. This gives us a subset of object-oriented code that is easy to reason about and fits within the conceptual model we are building.


## Data vs Codata

The core distinction between data and codata is that data describes what things are, while codata describes what things can do. Data is transparent. If we have an instance of an algebraic data type can inspect all the values stored inside it, by using a pattern match for example. If have an instance of codata we don't know what is inside it, but we do know the operations we can perform on the instance. If you come from the object-oriented world you will recognize this as programming to an interface. In many ways codata is just cleaning up concepts from the object-oriented world and presenting them in a way that is consistent with the rest of the functional programming paradigm.


## Codata in Scala

- Representing codata in Scala is probably familiar to most.
- ~trait~, abstract methods to define an interface
- ~class~ to define concrete implementations
- Sane use of object oriented features: we don't have deep inheritance hierarchies. In fact we generally don't want to use any non-trivial inheritance. (Trivial = extending an interface.)
- Example: set with ~union~, ~contains~, ~insert~, and ~isEmpty~ as interface. Note we can represent infinite data (set of even numbers for example)

## Data versus Codata

- Converting between algebraic data types and codata. Church encoding or Boehm-Berarducci encoding. I call it **functionalization** for simplicity. Show Church-encoded list. This is fold! Fold connects algebraic data types and codata.
- Choosing between algebraic data types and codata: extensibility
- Constructor vs destructor focus
- Lazy vs eager duality. Representing things by what we can do means we don't have to evaluate any part of what they are until asked to do so. This means we can represent infinite data as codata. Stream.

## Case Study

Reverse mode automatic differentiation. Has simple types and OO extensibility is appropriate.

## References

- How to Add Laziness to a Strict Language Without Even Being Odd http://hh.diva-portal.org/smash/record.jsf?pid=diva2%3A413532&dswid=-2514
- Codata in Action
  https://www.microsoft.com/en-us/research/uploads/prod/2020/01/CoDataInAction.pdf
- Refunctionalization
