#import "../stdlib.typ": info, warning, solution, chapter
#chapter[Indexed Types]


In this chapter we look at *indexed types*. An indexed type is a type constructor, so a type like `F[_]`, along with a set of types that can fill in the constructor's type parameters. Let's say this set of types is `Int`, `String`, and `Option[Double]`. Then, for a type constructor `F` we can construct an indexed type from the set `F[Int]`, `F[String]`, and `F[Option[Double]]`. 
The types `Int`, `String`, and `Option[Double]` act as indices into the set 
`F[Int]`, `F[String]`, and `F[Option[Double]]`, hence the name.
The type constructor `F` can be either data and codata. 

The description above is very abstract, and doesn't help us understand how indexed types are useful. We'll see a lot of details and examples in this chapter, but let's start with a more useful high-level overview. We can think of indexed types as working with proofs that a type parameter is equal to a particular element from the set of indices. Indexed _data_ provides this evidence when we destructure it, while indexed _codata_ requires this evidence when we call methods. Remember the definition of algebras we gave in @sec:interpreters:reification, where we said an algebra consists of three different kinds of methods: constructors, combinators, and interpreters. Indexed types allows us to do two things:

- We can restrict where constructors and combinators can be used. We can think of representing some state using a type parameter of `F`, and we can only call particular methods when we are in the correct state. In this case we are working with *indexed codata*.

- We restrict the types produced by interpreters, enabling us to create type-safe interpreters that guarantee they only encounter particular states when they run. Again these constraints are represented using type parameters. In this case we are working with *indexed data*.

Indexed data are more usually known as *generalized algebraic data types*. Indexed codata are sometimes known as *typestate*. Both can make use of what is known as *phantom types*. Indeed, an early name for indexed data was *first-class phantom types*. As you might expect, indexed data and indexed codata are dual to one another. 
