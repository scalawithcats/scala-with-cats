#import "../stdlib.typ": chapter
#chapter[Algebraic Data Types] <sec:adt>


This chapter has our first example of a programming strategy: *algebraic data types*. Any data we can describe using logical ands and logical ors is an algebraic data type. Once we recognize an algebraic data type we get three things for free:

- the Scala representation of the data;
- a *structural recursion* skeleton to transform the algebraic data type into any other type; and
- a *structural corecursion* skeleton to construct the algebraic data type from any other type.

The key point is this: from an implementation independent representation of data we can automatically derive most of the interesting implementation specific parts of working with that data.

We'll start with some examples of data, from which we'll extract the common structure that motivates algebraic data types. We will then look at their representation in Scala 2 and Scala 3. Next we'll turn to structural recursion for transforming algebraic data types, followed by structural corecursion for constructing them. We'll finish by looking at the algebra of algebraic data types, which is interesting but not essential.



== Building Algebraic Data Types


Let's start with some examples of data from a few different domains. These are simplified description but they are all representative of real applications.

A user in a discussion forum will typically have a screen name, an email address, and a password. Users also typically have a specific role: normal user, moderator, or administrator, for example. From this we get the following data:

- a user is a screen name, an email address, a password, and a role; and
- a role is normal, moderator, or administrator.

A product in an e-commerce store might have a stock keeping unit (a unique identifier for each variant of a product), a name, a description, a price, and a discount.

In two-dimensional vector graphics it's typical to represent shapes as a path, which is a sequence of actions of a virtual pen. The possible actions are usually straight lines, Bezier curves, or movement that doesn't result in visible output. A straight line has an end point (the starting point is implicit), a Bezier curve has two control points and an end point, and a move has an end point.

What is common between all the examples above is that the individual elements---the atoms, if you like---are connected by either a logical and or a logical or. For example, a user is a screen name _and_ an email address _and_ a password _and_ a role. A 2D action is a straight line _or_ a Bezier curve _or_ a move. This is the core of algebraic data types: an algebraic data type is data that is combined using logical ands or logical ors. Conversely, whenever we can describe data in terms of logical ands and logical ors we have an algebraic data type. 


=== Sums and Products


Being functional programmers we can't let a simple concept go without attaching some fancy jargon:

- a *product type* means a logical and; and
- a *sum type* means a logical or.

So algebraic data types consist of sum and product types.


=== Closed Worlds


Algebraic data types are closed worlds, which means they cannot be extended after they have been defined. In practical terms this means we have to modify the source code where we define the algebraic data type if we want to add or remove elements.

The closed world property is important because it gives us guarantees we would not otherwise have. In particular, it allows the compiler to check that we handle all possible cases when we use an algebraic data type. This is known as *exhaustivity checking*. This is an example of how functional programming prioritizes reasoning about code---in this case automated reasoning by the compiler---over other properties such as extensibility. We'll learn more about exhaustivity checking soon.
