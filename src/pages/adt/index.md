# Algebraic Data Types and Structural Recursion

In this section we'll see our first example of a programming strategy: **algebraic data types**. Any data we can describe using logical ands and logical ors is an algebraic data type. Once we recognize an algebraic data type we get two things for free:

- the Scala representation of the data; and
- a **structural recursion** skeleton to transform the algebraic data type into any other type.

The key point is this: from an implementation independent representation of data we can automatically derive most of the interesting implementation specific parts of working with that data.

We'll start with some examples of data, from which we'll extract the common structure that motivates algebraic data types. We then look at their representation in Scala 2 and Scala 3. We'll then turn to structural recursion, to transform algebraic data types. We'll finish by looking at the algebra of algebraic data types, which is interesting but not essential.



## Some Examples of Data

Let's start with some examples of data from a few different domains. These are simplified description but they are all representative of real applications.

A user in a discussion forum will typically have a screen name, an email address, and a password. Users also typically have a specific role: normal user, moderator, or administrator, for example. From this we get the following data:

- a user is a screen name, an email address, a password, and a role; and
- a role is normal, moderator, or administrator.

A product in an e-commerce store might have a stock keeping unit (a unique identifier for each variant of a product), a name, a description, a price, and a discount.

In two-dimensional vector graphics it's typical to represent shapes as a sequence of actions of a virtual pen. The possible actions are usually straight lines, Bezier curves, or movement that doesn't result in visible output. A straight line has an end point (the starting point is implicit), a Bezier curve has two control points and an end point, and a move has an end point.

What is common betwen all the examples above is that the individual elements---the atoms, if you like---are connected by either a logical and or a logical or. For example, a user is a screen name **and** an email address and so on. A 2D action is a straight line **or** a Bezier curve **or** a move. This is the core of algebraic data types: an algebraic data type is data that is combined using logical ands or logical ors. Conversely, whenever we can describe data in terms of logical ands and logicals or we have an algebraic data type. 


## Sums and Products

Being functional programmers, we can't let a simple concept go without attaching some fancy jargon:

- a **product type** means a logical and; and
- a **sum type** means a logical or.

So algebraic data types consist of sum and product types.


## Closed Worlds

Algebraic data types are closed worlds, which means they cannot be extended after that fact. In practical terms this means we have to modify the source code where we define the algebraic data type if we want to add or remove elements.

The closed world property is important because it gives us some guarantees we would not otherwise have. In particular, it allows the compiler to check, when we use an algebraic data type, that we handle all possible cases and alert us if we don't. This is known as **exhaustivity checking**. This is an example of how functional programming prioritizes reasoning about code---in this case automated reasoning by the compiler---over other properties such as extensibility.


## Algebraic Data Types in Scala 

Now we know about algebraic data types we can turn to their representation in Scala. The important point here is that the translation to Scala is entirely determined by the structure of the data, no thinking is required. In other words the work is finding the structure of the data that best represents the problem at hand. Work out the structure of the data and the code directly follows from it.

Scala 3 can directly represent algebraic data types using `enum`, but Scala 2 doesn't have this language feature. Hence we'll look at algebraic data types separately in Scala 3 and Scala 2.

### Algebraic Data Types in Scala 3
### Algebraic Data Types in Scala 2

## Applications of Algebraic Data Types

## The Algebra of Algebraic Data Types

Algebra of algebraic data types

Exponential types, quotient types.
