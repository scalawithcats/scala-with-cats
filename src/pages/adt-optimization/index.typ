#import "../stdlib.typ": info, warning, solution, chapter
#chapter[Optimizing Interpreters and Compilers] <sec:adt-optimization>


In a previous chapter we introduced interpreters as a key strategy in functional programming.
In many cases simple structurally recursive interpreters are sufficient.
However, in a few cases we need more performance than they can offer so in this chapter we'll turn to optimization.
This is a huge subject, which we cannot hope to cover in just one book chapter.
Instead we'll focus on two techniques that I believe use key ideas found in more complex techniques: algebraic manipulation and compilation to a virtual machine.

We'll start looking at algebraic manipulation, returning to the regular expression example we used earlier.
We'll then move to virtual machine, this time using a simple arithmetic interpreter example. 
We'll see how we can compile code to a stack machine, and then look at some of the optimizations that are available when we 
use a virtual machine.
