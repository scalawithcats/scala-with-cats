#import "../../stdlib.typ": info, warning, solution, chapter
#chapter[Case Study: CRDTs]


In this case study we will explore
*Commutative Replicated Data Types (CRDTs)*,
a family of data structures
that can be used to reconcile
eventually consistent data.

We'll start by describing
the utility and difficulty of eventually consistent systems,
then show how we can use monoids and their extensions
to solve the issues that arise.
Finally, we will model the solutions in Scala.

Our goal here is to focus on
the implementation in Scala of a particular type of CRDT.
We're not aiming at a comprehensive survey of all CRDTs.
CRDTs are a fast-moving field
and we advise you to read the literature to learn about more.
