---
layout: page
title: Reader
---

Functions of one argument are monads. Fix the input type, allow the output to vary.

Show this.

Want to implement something that depends on some configuration. Can write

~~~ scala
def findUser(userRepository: Repository, userId: Id): User = ...
~~~

Passing around `userRepository` gets boring. OO approach is to move it into a constructor. Reader monad is an alternative approach.

~~~ scala
def findUser(userId: Id) =
  (userRepository: Repository) => ...
~~~

Can call `findUser` without having a `Repository` and move the dependency up.

Compose with for comprehensions.

Not convinced of value of this.
