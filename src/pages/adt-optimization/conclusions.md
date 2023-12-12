## Conclusions


Our regular expression derivative algorithm is taken from [Regular-expression derivatives reexamined][rere].
This work is based on [Derivatives of Regular Expressions][regexp-deriv], which was published in 1964. Although the style of the paper will be immediately recognizable to anyone familiar with the more theoretical end of computer science, anachronisms like "State Diagram Construction" are a reminder that this work comes from the very beginnings of the discipline. Regular expression derivatives can be extended to context-free grammars and therefore used to implement parsers. This is explored in [Parsing with Derivatives][parsing-deriv].

[regexp-deriv]: https://dl.acm.org/doi/pdf/10.1145/321239.321249
[rere]: https://www.khoury.northeastern.edu/home/turon/re-deriv.pdf
[parsing-deriv]: https://matt.might.net/papers/might2011derivatives.pdf



[From Interpreter to Compiler and Virtual Machine: A Functional Derivation][interpreter-to-compiler]

[interpreter-to-compiler]: https://www.brics.dk/RS/03/14/BRICS-RS-03-14.pdf


[Stack Caching for Intrepters][stack-caching] introduces the idea of stack caching.

[Towards Superinstructions for Java Interpreters][towards-super] is a nice example of applying superinstructions to a interpreted JVM. 

If you're interested in the design considerations in a general purpose stack based instruction set, [Bringing the Web up to Speed with WebAssembly][wasm] is the paper for you. It covers the design of WebAssembly, and the rationale behind the choices.

Stack machines are not the only virtual machine used for implementing interpreters. Register machines are the most common alternative. The Lua virtual machine, for example, is a register machine. [Virtual Machine Showdown: Stack Versus Registers][stacks-vs-registers] compares the two and concludes that register machines are faster. However they are more complex to implement.

[stack-caching]: https://dl.acm.org/doi/pdf/10.1145/207110.207165
[towards-super]: https://core.ac.uk/download/pdf/297029962.pdf 
[wasm]: https://dl.acm.org/doi/pdf/10.1145/3062341.3062363
[stacks-vs-registers]: https://dl.acm.org/doi/pdf/10.1145/1328195.1328197 
