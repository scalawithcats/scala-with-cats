## Conclusions

We have covered a lot of material in this chapter. The key points are:

- algebraic data types represent data expressed as logical ands and logical ors of types;
- algebraic data types are the main way to represent data in Scala;
- structural recursion gives a skeleton for converting a given algebraic data type into any other type; 
- structural corecursion gives a skeleton for converting any type into a given algebraic data type; and
- there are other reasoning principles (primarily, following the types) that help us complete structural recursions and corecursions.

There is a lot packed into this chapter.
We'll see many more examples thoughout the rest of the book, which will help reinforce the concepts.
Below are some references that you might find useful if you want to dig in further into the concepts covered in this chapter.


Algebraic data types are standard in introductory material on functional programming, but structural recursion seems to be much less commonly known.
I learned about both from [How to Design Program](https://htdp.org/).
I'm not aware of any concise reference for algebraic data types and structural recursion.
This original material, whatever it is, seems to be too old to be available online and now concepts have become so commonly known that they are assumed background knowledge in most sources.

Corecursion is a bit better documented. [How to Design Co-Programs](https://www.cs.ox.ac.uk/jeremy.gibbons/publications/copro.pdf) covers the main idea we have looked at here. [The Under-Appreciated Unfold](https://dl.acm.org/doi/pdf/10.1145/289423.289455) discusses uses of `unfold`. 

[The Derivative of a Regular Type is its Type of One-Hole Contexts] (https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=7de4f6fddb11254d1fd5f8adfd67b6e0c9439eaa) describes the derivative of algebraic data types.
