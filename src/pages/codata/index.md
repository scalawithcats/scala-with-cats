# Objects as Codata

In this chapter we will look at **codata**, the dual of algebraic data types.
We'll see that codata encompasses a large subset of object-oriented programming, and puts these features into a coherent conceptual framework along with other functional programming concepts such as algebraic data types.
We'll start by describing codata and seeing some examples. We'll then look at the relationship between codata and algebraic data types, and see how we can transform one into the other. Having seen how they are related, we will next look at the differences, which gives guidance on when to choose each representation. We will finish with a case study **todo**.

A quick note about terminology. We might expect the term algebraic codata for the dual of algebraic data, but conventionally just codata is used. I expect this is because data is usually understood to have a wider meaning than just algebraic data, but codata is not used outside of programming language theory. For simplicity and symmetry, within this chapter I'll just use data to refer to algebraic data types.


  - What about differences?
    - Finite vs infinite
    - Lazy vs eager
    - Extensibility

## Data versus Codata

The core distinction between data and codata is that data describes what things are, while codata describes what things can do. Let's take a very simple algebraic data type:

```scala mdoc:silent
enum Bool {
  case True
  case False
}
```

If we have an instance of this algebraic data type we can tell exactly which case it is, by using a pattern match for example. Similarly, if the instances themselves hold data, as in `List` for example, we can always extract all the data within them. Again, we can use pattern matching to achieve this.

Codata, on the other hand, cannot be freely inspected like data. However we do know what operations we can perform on any given instance. A common example is a data structure, such as a set. Sets could be implemented using a hash table, or a tree structure, for example. For the outside we cannot tell what this implementation is but we do know the operations we can perform, such as testing if a set contains an element or performing a set union. 

To be a more precise, data is defined in terms of constructors and consumed using structural recursion. Codata is defined in terms of destructors and produced using structural corecursion.

If you come from the object-oriented world you might recognize the description of codata above as programming to an interface. In many ways codata is just taking concepts from the object-oriented world and presenting them in a way that is consistent with the rest of the functional programming paradigm.

In the previous chapter we discussed both destructors and structural corecursion, so why are we introducing them again in the context of codata? This illustrates the difference between the theory and craft level. Data and codata are distinct at the theory level. However Scala realizes both as variations of the same language features of classes and objects. So we cannot, for example, define an algebraic data type without also defining names for the fields within the data, and thus defining destructors. Thus we can treat any particular class or object as either data or codata, or even both. 

Part of the appeal, I think, of classes and objects is that they can express so many conceptually different abstractions with the same language constructs. For example, we can use objects to express modules, data, and codata. This gives them a surface appearance of simplicity; it seems we need to learn only one abstraction to solve a huge of number of coding problems. However this apparent simplicity hides real complexity, as this variety of uses forces us to reverse engineer the conceptual intention from the code. Just like we did with algebraic data, we will limit the object-oriented features we in defining codata. In particular, we won't use implementation inheritance, subtyping, overriding, or state. This gives us a subset of object-oriented code that fits within the conceptual model we are building.

## Case Study

Reverse mode automatic differentiation. Has simple types and OO extensibility is appropriate.


