# Introduction

Cats contains a wide variety of functional programming tools
and allows developers to pick and choose the ones we want to use. 
A large proportion of the code is delivered in the form of *type classes* 
that we can apply to existing Scala types.

Type classes are a programming pattern originating in Haskell. 
They allow us to extend existing libraries with new functionality, 
without using traditional inheritance, 
and without altering the original library source code.

In this chapter we will refresh our memory of type classes 
from Underscore's [Essential Scala][link-essential-scala] book, 
and take a first look at the Cats codebase. 
We will look at two example type classes---`Show` and `Eq`---using
them to identify patterns that lay the foundations for the rest of the book.
