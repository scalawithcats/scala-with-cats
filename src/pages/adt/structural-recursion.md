## Structural Recursion

Structural recursion is our second programming strategy. 
Algebraic data types tell us how to create data given a certain structure.
Structural recursion tells us how to transform an algebraic data types into any other type.
Given an algebraic data type, *any* transformation can be implemented using structural recursion.

Just like with algebraic data types, there is distinction between the concept of structural recursion and the implementation in Scala.
In particular, there are two ways structural recursion can be implemented in Scala: via pattern matching or via polymorphism.
We'll look at both in turn.
