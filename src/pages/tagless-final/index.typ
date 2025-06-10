#import "../stdlib.typ": info, warning, solution
= Tagless Final Interpreters
<sec:tagless-final>


In this chapter we'll explore the codata approach to interpreters, building up to a strategy known as *tagless final*.
Along the way we will build two interpreters: one for terminal interaction and one for user interfaces.

We've seen the duality between data and codata in many places, starting with @sec:codata. 
This chapter will begin by applying that duality to build an interpreter using codata, which contrasts with the data approach we saw in @sec:interpreters:reification.
This will illustrate the technique and give us a concrete example to discuss its shortcoming.
In particular we'll see that extensibility is limited, a problem we first encountered in @sec:codata:extensibility.

Solving the problem of extensibility, otherwise known as the *expression problem*, will lead us to tagless final. 
In the context of interpreters, solving the expression problem means allowing extensibility of both the programs we write and the interpreters that run them.
We'll start with the standard encoding of tagless final in Scala, and see that it is a bit painful to use in practice.
We'll then develop an alternative encoding that is easier to use. 
Solving the expression problem allows for very expressive code but it adds complexity, so we'll finish by talking about when tagless final is appropriate and when it's best to use a different strategy.
