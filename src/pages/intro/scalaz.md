---
layout: page
title: Meet Scalaz
---

# Meet Scalaz

 - intro/scalaz.md
    - What is Scalaz?
       - Collection of type classes
       - Standard structure for implementing/using type classes
       - SBT imports
    - `Show` - a quick example from Scalaz
       - Describe problem/motivation (toString isn't type-safe)
       - Describe how Show type class solves this
       - Provide example on existing types
       - Provide example involving custom type class instance
    - Structure of Scalaz
       - Describe the implementation of type classes in Scalaz (using Show to provide examples)
          - trait scalaz.Monoid   - type class
          - object scalaz.Monoid  - apply method to obtain instance for a given type
          - scala.std._           - instances of all the major type classes for "standard" Scala types
          - scala.syntax.monoid._ - special syntaxes for Monoid
