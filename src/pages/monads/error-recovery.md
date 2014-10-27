---
layout: page
title: Error Recovery
---

In the previous section we looked at modelling fail fast error handling using monads, and the `\/` monad in particular.

In this section we're going to look at recovering from errors

### Succeeding or Choosing a Default

MonadPlus

`<+>`

### Abstracting Over Error Handling

Optional

## Exercise

#### Folding Over Errors

Let the `map` part of `foldMap` fail.

#### Don't Stop For Nothing

Don't let an error stop our fold. Just replace it with the identity! Model this.
