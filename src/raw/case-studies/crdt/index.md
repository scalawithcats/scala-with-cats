# Commutative Replicated Data Types

In this case study we explore commutative replicated data types (CRDTs), a data structure that can be used to reconcile eventually consistent data.

We start by describing the utility and difficulty of eventually consistent systems, then show how we can use monoids and their extensions to solve the issues the issues that arise, and finally model the solutions in Scala.

Our goal here is to focus on the implementation in Scala of a particular type of CRDT. 
We're specifically not aiming at a comprehensive survey of all CRDTs. 
CRDTs are a fast moving field, and we advise you to read the literature to learn about more.
