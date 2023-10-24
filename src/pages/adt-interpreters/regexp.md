## Regular Expressions

We'll start this case study by briefly describing the usual task for regular expressions---matching text---and then take a more theoretical view. We'll then move on to implementation.

Programmers mostly commonly use regular expressions for matching text. For example, if we wanted to match all the strings like `"Scala"`, `"Scalala"`, `"Scalalala"` and so on, we could use the following regular expression.

```scala mdoc:silent
val regexp = raw"Sca(la)+".r
```

Let's check it matches what we're looking for.

```scala mdoc
regexp.matches("Scala")
regexp.matches("Scalalalala")
regexp.matches("Sca")
regexp.matches("Scalal")
```

So, it seems to work, but how does the code relate to the problem we've solving? Regular expressions are a domain specific language encoded in a `String`. The basic rules for regular expressions are that they match exactly the characters in the string, unless they one of the special characters that encode a particular rule. In the example above, we use `(` and `)` to group the sequence of characters `"la"`, and  `+` to match this group one or more times.
