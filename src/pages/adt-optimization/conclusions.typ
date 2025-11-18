#import "../stdlib.typ": href, narrative-cite, info, warning, solution
== Conclusions


In this chapter we explored two main techniques for optimizing interpeters: algebraic simplification of programs, and interpretation in a virtual machine.

Our regular expression derivative algorithm is taken from #narrative-cite(<owen09:rere>).
Regular expression derivatives are very easy to implement and nicely illustrate algebraic simplification.
However we have to recompute the derivative on each input character.
If we instead compile the regular expression to a finite state machine ahead of time, we save time when parsing input.
The details of this algorithm are in the paper.

#narrative-cite(<owen09:rere>) is in turn based on #narrative-cite(<brzozowski64:deriv>), published in 1964. Although the style of the paper will be immediately recognizable to anyone familiar with the more theoretical end of computer science, anachronisms like "State Diagram Construction" are a reminder that this comes from the very beginnings of the discipline.

Regular expression derivatives can be extended to context-free grammars and therefore used to implement parsers @might11:parsing. Other work has added additional operators to regular expression derivatives, such as anchors and restricted lookaround, and created best-in-class regular expression engines @moseley23:deriv @varatalu25:re. The ease of algebraically manipulating regular expression derivatives a key to this advance.

A lot of work has looked at systematically transforming an interpreter into a compiler and virtual machine. See, for example, #narrative-cite(<ager03:interpreter>) for some earlier work, and #narrative-cite(<bahr15:calculate>) for more recent work. These are only a few examples; there is too much work in this field for me to adequately summarise.

Interpreters and their optimization has a similarly enormous body of work. However, we spent a bit more time on this, and it's also a personal interest, so I've been a bit more through in collecting references for this section.

We looked at four techniques for optimization: algebraic simplification, byte code, stack caching, and superinstructions. 
Algebraic simplification is as old as algebra, and something familiar to any secondary school student. 
In the world of compilers, different aspects of algebraic simplification are known as constant folding, constant propagation, and common subexpression elimination. 
Byte code is probably as old as interpreters, and dates back to at least the 1960s in the form of #href("https://en.wikipedia.org/wiki/P-code_machine")[P-code]. 
#narrative-cite(<ertl95:stack-caching>) introduces the idea of stack caching, and shows some rather more complex realizations than the simple system I used. 
Superinstructions were introduced in #narrative-cite(<proebsting95:superoperators>).
#narrative-cite(<casey03:superinstructions>) is a nice example of applying superinstructions to an interpreted JVM. 

Let's now talk about instruction dispatch, which is area we did not consider for optimization.
Instruction dispatch is the process by which the interpreter chooses the code to run for a given interpreter instruction. 
#narrative-cite(<ertl03:spei>) argues that instruction dispatch makes up a major portion of an interpreter's execution time.
The approach we used is known as switch dispatch in the literature.
There are several alternative approaches.
Direct threading @bell73:threaded represents an instruction by the function that implements it. This requires first-class functions and full tail calls. It is generally considered the fastest form of dispatch. Notice that it leverages the duality between data and functions.
Subroutine threading is like direct threading, but uses normal calls and returns instead of tail calls.
Indirect threaded code @dewar75:indirect represents each bytecode as an index into a lookup table that points to the implementing function.

Stack machines are not the only virtual machine used for implementing interpreters. Register machines are the most common alternative. The Lua virtual machine, for example, is a register machine. #narrative-cite(<shi08:showdown>) compares the two and concludes that register machines are faster. However, register machines are more complex to implement.

If you're interested in the design considerations in a general purpose stack based instruction set, #narrative-cite(<haas17:wasm>) is the paper for you. It covers the design of WebAssembly, and the rationale behind the design choices. An interpreter for WebAssembly is described in #narrative-cite(<titzer22:in-place>). Notice how often tail calls arise in the discussion!
