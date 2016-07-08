## Summary

While monads and functors are the most widely used types we've covered in this book, cartesians and applicatives are the most general. Cartesians and applicatives provide a generic mechanism to combine values and apply functions within a context, from which we can fashion monads and a variety of other combinators.

Cartesians are most commonly used as a means of combining independent values such as the results of validation rules. Cats provides the `Validated` type for this specific purpose, along with cartesian builder syntax as a convenient way to express the combination of rules.

We have a few stops left on our tour of functional programming concepts. In the next chapter we will cover two important type classes, `Traverse` and `Foldable`, which allow us to convert between the different data types we have discussed so far.

<!--
We have now covered all of the functional programming concepts on our agenda for this book. The remaining chapters dive into detail, using the concepts covered in a collection of case studies. We'll implement our own mapreduce system, solve data validation once and for all for all HTML forms, and even invent our own programming language.
-->
