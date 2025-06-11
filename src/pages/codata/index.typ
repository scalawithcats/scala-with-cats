#import "../stdlib.typ": chapter
#chapter[Objects as Codata] <sec:codata>


In this chapter we will look at *codata*, the dual of algebraic data types.
Algebraic data types focus on how things are constructed.
Codata, in contrast, focuses on how things are used.
We define codata by specifying the operations that can be performed on the type.
This is very similar to the use of interfaces in object-oriented programming, and this is the first reason that we are interested in codata: codata puts object-oriented programming into a coherent conceptual framework with the other strategies we are discussing.

We're not only interested in codata as a lens to view object-oriented programming.
Codata also has properties that algebraic data does not.
Codata allows us to create structures with an infinite number of elements, such as a list that never ends or a server loop that runs indefinitely. 
Codata has a different form of extensibility to algebraic data.
Whereas we can easily write new functions that transform algebraic data, we cannot add new cases to the definition of an algebraic data type without changing the existing code.
The reverse is true for codata. We can easily create new implementations of codata, but functions that transform codata are limited by the interface the codata defines.

In the previous chapter we saw structural recursion and structural corecursion as strategies to guide us in writing programs using algebraic data types.
The same holds for codata.
We can use codata forms of structural recursion and corecursion to guide us in writing programs that consume and produce codata respectively.

We'll begin our exploration of codata by more precisely defining it and seeing some examples. 
We'll then talk about representing codata in Scala, and the relationship to object-oriented programming.
Once we can create codata, we'll see how to work with it using structural recursion and corecursion, using an example of an infinite structure.
Next we will look at transforming algebraic data to codata, and vice versa.
We will finish by examining differences in extensibility.

A quick note about terminology before we proceed. We might expect to use the term algebraic codata for the dual of algebraic data, but conventionally just codata is used. I assume this is because data is usually understood to have a wider meaning than just algebraic data, but codata is not used outside of programming language theory. For simplicity and symmetry, within this chapter I'll just use the term data to refer to algebraic data types.
