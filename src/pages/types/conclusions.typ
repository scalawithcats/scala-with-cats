#import "../stdlib.typ": narrative-cite, href
== Conclusions <sec:types:conclusions>

In this chapter we've looked at using types to represent constraints,
which allows the compiler to help us ensure these constraints are met throughout our program.
We call this strategy "types as constraints".
We constrasted this strategy to the better known view of types that focuses on representation.
Finally, we saw opaque types as a lightweight tool that decouples types from their representation,
allowing us to define a type that uses the same representation as some other type.

The view of types as constraints is perhaps best presented in Alexis King's blog post #href("https://lexi-lambda.github.io/blog/2019/11/05/parse-don-t-validate/")[Parse, don't validate].
#narrative-cite(<morris73:types>) is a very early paper (typewritten in two column justified text, a truly virtuoso performance on the type writer!) that also presents the intensional view of types. I feel it ends a bit abruptly, but has the seed of many ideas that will only be fully developed much later. You can see the suggestion of opaque types as discussed in this chapter, and also module systems and existential types.

From a programming language perspective, #narrative-cite(<pierce02:tapl>) is the standard reference on type systems.
They define a type system as "a tractable syntactic method for proving the absence of certain program behaviours by classifying phrases by the kinds of values they compute".
The introduction provides a very nice overview of the role of type systems in programming languages, as well as pointers to the broader study of type systems in mathematics and philosophy. 

Having said that types are not sets, it feels only fair to mention there are type systems that do treat types as sets. #narrative-cite(<castagna23:elixir>) describes one such system. 
These type systems emphasize the extensional view, and have a very different feel to conventional type systems.

I'm very far from an expert in mathematical type theory. As such, I found #narrative-cite(<klev19:comparison>) useful to relate type theory to something I better understand, set theory.
