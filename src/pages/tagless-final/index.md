# Tagless Final Interpreters

In this chapter we'll explore interpreters using codata, building up to a strategy known as **tagless final**.
Along the way we will build two interpreters: one for terminal interaction and one for creating user interfaces.

We've seen the duality between data and codata in many places, starting with Chapter [@sec:codata]. 
This chapter will begin by applying that duality to build an interpreter using codata, which contrasts with the data approach we saw in Section [@sec:interpreters:reification].
This will illustrate the technique and give us a concrete example to discuss its shortcoming.
In particular we'll see that extensibility is limited, a problem we first encountered in Section [@sec:codata:extensibility].

Solving the problem of extensibility, otherwise known as the **expression problem**, will lead us to tagless final. 
In the context of interpreters, solving the expression problem allows extensibility of both the programs we write and the interpreters that run them.
The standard encoding of tagless final in Scala is a bit painful to use in practice, so we'll develop a different encoding that is easier to use. 
Solving the expression problem allows for very expressive code, as the name suggests, but it adds complexity. 
We'll finish by talking about when tagless final is appropriate and when it's best left alone.
