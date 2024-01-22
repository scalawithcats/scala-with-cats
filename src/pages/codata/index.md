# Objects as Codata

- Classes and objects are familiar to most programmers.
- Part of their appeal is that they can express so many conceptually different abstractions. This gives them the surface appearance of simplicity, whilst hiding a lot of complexity in actual use.
- Here we will look at objects and classes as the dual of algebraic data types, also known as **codata**.

## Core Idea

- What things are vs what we can do with them
- Algebraic data types focuses on what things are. They are transparent. We know everything about them.
- Codata focuses on what things can do. They are opaque. We know only what we can do with them. I.e. their interface.

## Functions as Codata

- Functions as codata.
- In the previous chapter we had the example of HTTP requests and responses as algebraic data types. What about a request handler: something that processes a web request.
- A function ~Request => Response~. We don't know what is inside it. Only know that we can apply it to a ~Request~ and get a ~Response~. Not the most interesting representation because there is only action. We'll see more interesting ones in a moment.


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
