#import "../stdlib.typ": info, warning, solution
== Conclusions


In this chapter we explored two main techniques for optimizing interpeters: algebraic simplification of programs, and interpretation in a virtual machine.

Our regular expression derivative algorithm is taken from [Regular-expression derivatives reexamined][rere].
What we didn't explore, but we should if we really care about performance, is compiling regular expressions to a finite state machine, another kind of virtual machine.
Regular expression derivatives are very easy to implement and nicely illustrate the point of algebraic simplification.
However we have to recompute the derivative on each input character.
If we instead compile the regular expression to a finite state machine ahead of time, we save time when parsing input.
The details of this algorithm are in the paper.


This work is based on [Derivatives of Regular Expressions][regexp-deriv]. Derivatives of Regular Expressions was published in 1964. Although the style of the paper will be immediately recognizable to anyone familiar with the more theoretical end of computer science, anachronisms like "State Diagram Construction" are a reminder that this work comes from the very beginnings of the discipline. Regular expression derivatives can be extended to context-free grammars and therefore used to implement parsers. This is explored in [Parsing with Derivatives][parsing-deriv].

[regexp-deriv]: https://dl.acm.org/doi/pdf/10.1145/321239.321249
[rere]: https://www.khoury.northeastern.edu/home/turon/re-deriv.pdf
[parsing-deriv]: https://matt.might.net/papers/might2011derivatives.pdf


A lot of work has looked at systematically transforming an interpreter into a compiler and virtual machine.
[From Interpreter to Compiler and Virtual Machine: A Functional Derivation][interpreter-to-compiler] is an earlier example. [Calculating Correct Compilers][calculating-correct] is more recent, and follow-up papers extend the technique in a number of directions.

[interpreter-to-compiler]: https://www.brics.dk/RS/03/14/BRICS-RS-03-14.pdf
[calculating-correct]: https://www.cambridge.org/core/journals/journal-of-functional-programming/article/calculating-correct-compilers/70AA17724EBCA4182B1B2B522362A9AF


Interpreter and their optimization is an enormous area of work. It also one I find very interesting, so I've been a bit more through in collecting references for this section.

We looked at four techniques for optimization: algebraic simplification, byte code, stack caching, and superinstructions. 
Algebraic simplification is as old as algebra, and something familiar to any secondary school student. 
In the world of compilers, different aspects of algebraic simplification are known as constant folding, constant propagation, and common subexpression elimination. 
Byte code is probably as old as interpreters, and dates back to at least the 1960s in the form of [p-code]. 
[Stack Caching for Interpreters][stack-caching] introduces the idea of stack caching, and shows some rather more complex realizations than the simple system I used. 
Superinstructions were introduced in [Optimizing an ANSI C interpreter with superoperators][superoperators].
[Towards Superinstructions for Java Interpreters][towards-super] is a nice example of applying superinstructions to a interpreted JVM. 

Let's now talk about instruction dispatch, which is area we did not consider for optimization.
Instruction dispatch is the process by which the interpreter chooses the code to run for a given interpreter instruction. 
[The Structure and Performance of Efficient Interpreters][spei] argues that instruction dispatch makes up a major portion of an interpreter's execution time.
The approach we used is generally called switch dispatch in the literature.
There are several alternative approaches.
Direct threaded dispatch is described in [Threaded Code][threaded-code]. Direct threading represents an instruction by the function that implements it. This requires first-class functions and full tail calls. It is generally considered the fastest form of dispatch. Notice that it relies on the duality between data and functions.
Subroutine threading is like direct threading, but uses normal calls and returns instead of tail calls.
In indirect threaded code (described in [Indirect Threaded Code][indirect-threaded-code]), each bytecode is the index into a lookup table that points to the implementing function.

Stack machines are not the only virtual machine used for implementing interpreters. Register machines are the most common alternative. The Lua virtual machine, for example, is a register machine. [Virtual Machine Showdown: Stack Versus Registers][stacks-vs-registers] compares the two and concludes that register machines are faster. However they are more complex to implement.

If you're interested in the design considerations in a general purpose stack based instruction set, [Bringing the Web up to Speed with WebAssembly][wasm] is the paper for you. It covers the design of WebAssembly, and the rationale behind the design choices. An interpreter for WebAssembly is described in [A Fast In-Place Interpreter for WebAssembly][wasm-interp]. Notice how often tail calls arise in the discussion!


[stack-caching]: https://dl.acm.org/doi/pdf/10.1145/207110.207165
[p-code]: https://en.wikipedia.org/wiki/P-code_machine
[superoperators]: https://dl.acm.org/doi/abs/10.1145/199448.199526
[towards-super]: https://core.ac.uk/download/pdf/297029962.pdf 
[spei]: https://jilp.org/vol5/v5paper12.pdf 
[threaded-code]: https://dl.acm.org/doi/pdf/10.1145/362248.362270
[indirect-threaded-code]: http://figforth.org.uk/library/Indirect.Threaded.Code.p330-dewar.pdf 

[wasm]: https://dl.acm.org/doi/pdf/10.1145/3062341.3062363
[stacks-vs-registers]: https://dl.acm.org/doi/pdf/10.1145/1328195.1328197 
[wasm-interp]: https://dl.acm.org/doi/pdf/10.1145/3563311
