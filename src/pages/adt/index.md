# Algebraic Data Types and Structural Recursion

In this section we'll see our first example of a programming strategy: **algebraic data types**. Any data we can describe using logical ands and logical ors is an algebraic data type. Once we recognize an algebraic data type we get two things for free:

- the Scala representation of the data; and
- a **structural recursion** skeleton to transform the algebraic data type into any other type.

The key point is this: from an implementation independent representation of data we can automatically derive most of the interesting implementation specific facets of working with that data.

We'll start with some examples of data, from which we'll extract the common structure that motivates algebraic data types. We then look at their representation in Scala 2 and Scala 3. We'll then turn to structural recursion, to transform algebraic data types. We'll finish by looking at the algebra of algebraic data types, which is interesting but not essential.



## Some Examples of Data

Our starting point is discussing typical data representations in a few different applications.

Lots of applications have some way of representing users. Let's say a user is a screen name, an email address, and a password. It's common for users to have different roles. Let's say a user's role is either administrator, editor, or reader. In summary, in our example a user is a screen name, an email address, a password and a role. A role is either administrator, editor or reader.

Representing products in an ecommerce store is usually quite involved. A product might have a stock keeping unit (a unique identifier for each variant of a product), a name, a description, a price, and a discount.

In a two-dimensional graphics application it's typical to represent shapes as a sequence of primitive elements, which are usually straight lines, Bezier curves, or movements that don't result in visible output. A straight line has an end point (the starting point is implicit), a Bezier curve has two control points and an end point, and a move has an end point.

What is common betwen all the examples above is that the individual elements---the atoms, if you like---are connected by either a logical and or a logical or. For example, a user is a screen name **and** an email address and so on. A 2D primitive is a straight line **or** a Bezier curve **or** a move. This is the core of algebraic data types: an algebraic data type is data that is combined using logical ands or logical ors. Conversely, whenever we can describe data in terms of logical ands and logicals or, we have an algebraic data type. 



## Sums, Products, and Algebraic Data Types

Being functional programmers, we can't let a simple concept go without attaching some fancy jargon:

- a **product type** means a logical and; and
- a **sum type** means a logical or.

So algebraic data types consist of sum and product types.


## Algebraic Data Types in Scala 

Whenever this is the case we can directly translate our description into code. In short, work out the structure of the data and the code directly follows from it.

### Algebraic Data Types in Scala 2
### Algebraic Data Types in Scala 3

## Connections and Extensions

Algebra of algebraic data types

Exponential types, quotient types.
