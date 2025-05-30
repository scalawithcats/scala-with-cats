#import "../stdlib.typ": info, warning, solution
== Conclusions


In this chapter we've discussed why we might want to build interpreters, and seen techniques for building them.
To recap, the core of the interpreter strategy is a separation between description and action.
The description is the program, and the interpreter is the action that carries out the program. 
This separation is allows for composition of programs, and managing effects by delaying them till the time the program is run.
We sometimes call this structure an algebra, with constructs and combinators defining programs and destructors defining interpreters.
Although the name of the strategy focuses on the interpreter, the design of the program is just as important as it is the user interface through which the programmer interacts with the system.

Our starting implementation strategy is reification of the algebra's constructors and compositional methods as an algebraic data type. The interpreter is then a structural recursion over this ADT.
We saw that the straightforward implementation is not stack-safe, and which caused us to introduction the idea of tail recursion and continuations.
We reified continuations as functions, and saw that we can convert any program into continuation-passing style which has every method call in tail position.
Due to Scala runtime limitations not all calls in tail position can be converted to tail calls, so we reified calls and returns into data structures used by a recursive loop called a trampoline.
Underlying all these strategies in the concept of duality. We have seen a duality between functions and data, which we utilize in reification, and a duality between calling functions and returning data, which we use in continuations and trampolines.

Stack-safe interpreters are important in many situations, but the code is harder to read than the basic structural recursion.
In some contexts a basic interpreter may be just fine.
It's unlikely to run out of stack space when evaluating a straightforward expression tree, as in the arithmetic example.
The depth of such a tree grows logarithmically with the number of elements, so only extremely large trees will have sufficient depth that stack safety becomes relevant.
However, in the regular expression example the stack consumption is determined not by the depth of the regular expression tree, but by the length of the input being matched.
In this situation stack safety is more important.
There may still be other constraints that allow a simpler implementation.
For example, if we know the library will only used in situations where inputs were guaranteed to be small.
As always, only use coding techniques where they make sense.

These ideas are classics in programming language theory.
#cite(<reynolds72:definitional>, form: "prose") details defunctionalization, a limited form of reification and continuation passing style. (If you want to read this paper, I suggest the #link("https://homepages.inf.ed.ac.uk/wadler/papers/papers-we-love/reynolds-definitional-interpreters-1998.pdf")[re-typeset version from 1998], which is much more readable than the original typewriter version.)
These ideas are expanded on in #cite(<danvy01:defunctionalization>, form: "prose")
#cite(<gibbons22:cps>, form: "prose") is a very readable and elegant paper that highlights the importance of associativity in these transformations.
