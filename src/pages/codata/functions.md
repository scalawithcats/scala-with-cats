## Functions as Codata

Functions are the simplest form of codata. We cannot inspect the instructions inside a function; all we can do with them is apply them to arguments. (In Scala functions have other methods like `andThen` and `compose`, but these are built on `apply`.)

Functions are ubiquitous in Scala, so you are probably familiar with their use, but let's quickly look at an example. Say we're writing a web server.

- In the previous chapter we had the example of HTTP requests and responses as algebraic data types. What about a request handler: something that processes a web request.
- A function ~Request => Response~. We don't know what is inside it. Only know that we can apply it to a ~Request~ and get a ~Response~. Not the most interesting representation because there is only action. We'll see more interesting ones in a moment.

