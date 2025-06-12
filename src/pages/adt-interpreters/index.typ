#import "../stdlib.typ": chapter, href
#chapter[Reified Interpreters] <sec:interpreters>


The interpreter strategy is perhaps the most important in all of functional programming. The central idea is to *separate description from action*. When we use the interpreter strategy our program consists of two parts: the description, instructions, or program that describes what we want to do, and the interpreter that carries the actions in the description. In this chapter we'll start exploring the design and implementation of interpreters, focusing on implementations using algebraic data types. 

Interpreters arise whenever there is this distinction between description and action. You may think an interpreter is a complex piece requiring a lot of development effort, but I hope to show you this is not the case. You probably already use lots of interpreters in your daily coding without realizing it. For example, consider the code below which is taken from a web framework called #href("https://github.com/creativescala/krop")[Krop]

```scala
val route =
  Route(
    Request.get(Path.root / "user" / Param.int),
    Response.ok(Entity.text)
  ).handle(userId => s"You asked for the user ${userId.toString}")
```

This defines a route, which matches `GET` requests for the path `"/user/<int>"`, and responds with an `Ok` containing text. This kind of routing library is ubiquitous in web frameworks, is simple to write, and yet contains everything we need for the interpreter strategy.

Interpreters are so important because they are the key to enabling compositionality and reasoning, particularly while allowing effects. For example, imagine implementing a graphics library using the interpreter strategy. A program simply describes what we want to draw on the screen, but critically it does not draw anything. The interpreter takes this description and creates the drawing described by it. We can freely compose descriptions only because they do not carry out any effects. For example, if we have a description that describes a circle, and one for a square, we can compose them by saying we should draw the circle next to the square thereby creating a new description. If we immediately drew pictures there would be nothing to compose with. Similarly, it's easier to reason about pictures in this system because a program describes exactly what will appear on the screen, and there is no state from prior drawing that we need to worry about.

Throughout this chapter we will explore the interpreter strategy by building a series of interpreters for regular expressions. We've chosen to use regular expressions because they are already familiar to many and they are simple to work with. This means we can focus on the details of the interpreter strategy without getting caught up in problem specific details, but we still end up with a realistic and useful result.

We'll start with a basic implementation strategy that uses algebraic data types and structural recursion. We'll then look at transformations to turn our interpreter into a version that avoids using the stack and hence avoids the possibility of stack overflow.
