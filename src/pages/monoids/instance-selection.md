---
layout: page
title: Controlling Type Class Instance Selection
---

When working with type classes we must consider two issues the control type class instance selection:

- What is the relationship between an instance defined on a type and its subtypes. For example, if we define a `Monoid[Option]` will the expression `mzero[Some]` select this instance? (Remember that `Some` is a subtype of `Option`).
- How do we choose between type class instances when there are many available. We've seen there are two monoids for `Int`: addition and zero, and multiplication and one. Similarly there are three monoids for `Boolean`. When we write `1 |+| 2`, for example, which instance is selected?

In this section we explore how Scalaz answers these questions.
