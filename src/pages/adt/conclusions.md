## Conclusions

We have covered a lot of material in this chapter. The key points are:

- algebraic data types are expressed as logical ands and logical ors of types;
- algebraic data types are the main way to represent data in Scala;
- structural recursion gives a skeleton for converting a given algebraic data type into any type; 
- structural corecursion gives a skeleton for converting any type into a given algebraic data type; and
- there are other reasoning principles (primarily, following the types) that help us complete structural recursions and corecursions given the skeletons.

There is a lot packed into this chapter.
Don't worry if you're struggling to take it all in right now.
We'll see many more applications thoughout the rest of the book, which will reinforce the concepts.

I haven't covered everything there is to know about algebraic data types; I think doing so would be a book in its own right.
Below are some references that you might find useful if you want to dig in further, as well as some biographical remarks.


Algebraic data types are standard in introductory material on functional programming. 
Structural recursion is certainly extremely common in functional programming, but strangely seems to rarely be explicitly defined as I've done here.
I learned about both from [How to Design Programs](https://htdp.org/).

I'm not aware of any approachable yet thorough treatment of either algebraic data types or structural recursion.
Both seem to have become assumed background of any researcher in the field of programming languages,
and relatively recent work is caked in layers of mathematics that I find difficult reading.
The infamous [Functional Programming with Bananas, Lenses, Envelopes and Barbed Wire][banana] is an example of such work.

The earliest reference I've found to structural recursion is [Proving Properties of Programs by Structural Induction][structural-induction]), which dates to 1969. 
Algebraic data types don't seem to have been fully developed, along with pattern matching, until [NPL][npl] in 1977. 
NPL was quickly followed by the more influential language [Hope][hope], which spread the concept to other programming languages.
I suspect the core ideas in both date back to at least the emergence of computability theory in the 1930s, well before any digital computers existed.

Corecursion is a bit better documented in the contemporary literature. [How to Design Co-Programs][htdc] covers the main idea we have looked at here. 
[The Under-Appreciated Unfold][unfold] discusses uses of `unfold`. 
[The Derivative of a Regular Type is its Type of One-Hole Contexts][deriv] describes the derivative of algebraic data types.



[banana]: https://ris.utwente.nl/ws/portalfiles/portal/6142049/meijer91functional.pdf
[structural-induction]: https://academic.oup.com/comjnl/article/12/1/41/311605
[npl]: https://en.wikipedia.org/wiki/NPL_(programming_language)
[hope]: https://en.wikipedia.org/wiki/Hope_(programming_language)
[htdc]: https://www.cs.ox.ac.uk/jeremy.gibbons/publications/copro.pdf
[unfold]: https://dl.acm.org/doi/pdf/10.1145/289423.289455
[deriv]: https://citeseerx.ist.psu.edu/document?repid=rep1&type=pdf&doi=7de4f6fddb11254d1fd5f8adfd67b6e0c9439eaa
