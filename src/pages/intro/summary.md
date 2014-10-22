---
layout: page
title: Summary
---

# Summary

In this chapter we took a first look at type classes. We implemented our own `Printable` type class using plain Scala, before looking at the equivalent `Show` type class in Scalaz.

We used two type classes -- `Show` and `Equal` -- to look at the modular code organization in Scalaz. We can select which type classes, instances, and interface syntax we want by selectively importing definitions from `scalaz`, `scalaz.std`, and `scalaz.syntax`.

In the remaining chapters of this course we will look at four broad and powerful type classes -- `Monoids`, `Functors`, `Monads`, and `Applicatives`. In each case we will learn what functionality the type class provides, the formal rules it follows, and how it is implemented in Scalaz.
