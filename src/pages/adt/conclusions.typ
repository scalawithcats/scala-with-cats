#import "../stdlib.typ": href
== Conclusions


We have covered a lot of material in this chapter. Let's recap the key points.

Algebraic data types allow us to express data types by combining existing data types with logical and and logical or. A logical and constructs a product type while a logical or constructs a sum type. Algebraic data types are the main way to represent data in Scala.

Structural recursion gives us a skeleton for transforming any given algebraic data type into any other type. Structural recursion can be abstracted into a `fold` method. 

We use several reasoning principles to help us complete the problem specific parts of a structural recursion:

+ reasoning independently by case;
+ assuming recursion is correct; and
+ following the types.

Following the types is a very general strategy that is can be used in many other situations.

Structural corecursion gives us a skeleton for creating any given algebraic data type from any other type. Structural corecursion can be abstracted into an `unfold` method. When reasoning about structural corecursion we can reason as we would for an imperative loop, or, if the input is an algebraic data type, use the principles for reasoning about structural recursion.

Notice that the two main themes of functional programming---composition and reasoning---are both already apparent. Algebraic data types are compositional: we compose algebraic data types using sum and product. We've seen many reasoning principles in this chapter.

I haven't covered everything there is to know about algebraic data types; I think doing so would be a book in its own right.
Below are some references that you might find useful if you want to dig in further, as well as some biographical remarks.

Algebraic data types are standard in introductory material on functional programming. 
Structural recursion is certainly extremely common in functional programming, but strangely seems to rarely be explicitly defined as I've done here.
I learned about both from _How to Design Programs_ @felleisen18:htdp.

I'm not aware of any approachable yet thorough treatment of either algebraic data types or structural recursion.
Both seem to have become assumed background of any researcher in the field of programming languages,
and relatively recent work is caked in layers of mathematics and obtuse notation that I find difficult reading.
The infamous _Functional Programming with Bananas, Lenses, Envelopes and Barbed Wire_ @meijer91:bananas is an example of such work.
I suspect the core ideas of both date back to at least the emergence of computability theory in the 1930s, well before any digital computers existed.

The earliest reference I've found to structural recursion is _Proving Properties of Programs by Structural Induction_ @burstall69:proving.
Algebraic data types don't seem to have been fully developed, along with pattern matching, until #href("https://en.wikipedia.org/wiki/NPL_(programming_language)")[NPL] in 1977.
NPL was quickly followed by the more influential language #href("https://en.wikipedia.org/wiki/Hope_(programming_language)")[Hope], which spread the concept to other programming languages.

Corecursion is a bit better documented in the contemporary literature. _How to Design Co-Programs_ @gibbons21:htdcp covers the main ideas we have looked at here, while _The under-appreciated unfold_ @gibbons98:unfold discusses uses of `unfold`.

_The Derivative of a Regular Type is its Type of One-Hole Contexts_ @mcbride01:deriv describes the derivative of algebraic data types.
