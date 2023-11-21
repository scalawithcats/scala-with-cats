## Conclusions

In this chapter we've discussed why we might want to build interpreters, and seen techniques for building them.
To recap, the core of the interpreter strategy is a separation between description and action.
The description is the program, and the interpreter is the action that carries out the program. 
This separation is allows for composition of programs, and managing effects by delaying them till the time the program is run.
We sometimes call this structure an algebra.
Although the name of the strategy focuses on the interpreter, the design of the program is just as important as it is the user interface through which the programmer interacts with the system.

Our starting implementation technique is reification of the algebra's constructors and compositional methods as an algebraic data type. The interpreter is then a structural recursion over this ADT.
We saw that the straightforward implementation is not stack-safe, and which caused us to introduction the idea of tail recursion and continuations.
We reified continuations as functions, as saw that we can convert any program into continuation-passing style which has every method call in tail position.
Due to Scala runtime limitations not all calls in tail position can be converted to a tail call, so we reified calls and returns these data structures to a recursive loop called a trampoline.
Underlying all these strategies in the concept of duality. We have seen a duality between functions and data, which we utilize in reification, and a duality between calling functions and returning data, which we use in continuations and trampolines.

centered around reification and duality, which are the concepts underlying continuation-passing style and trampolines.


seen techniques for buil

Continuation-Passing Style, Defunctionalization, Accumulations, and Associativity
https://www.cs.ox.ac.uk/jeremy.gibbons/publications/continued.pdf

Definitional Interpreters for Higher-Order Programming Languages
https://homepages.inf.ed.ac.uk/wadler/papers/papers-we-love/reynolds-definitional-interpreters-1998.pdf

Defunctionalization at Work
https://www.brics.dk/RS/01/23/BRICS-RS-01-23.pdf
