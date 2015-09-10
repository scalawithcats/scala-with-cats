# Case Study: Data Validation

In this case study we will build a library for validation. What do we mean by validation? Almost all programs must check their input meets certain criteria. For example, perhaps we want to ensure that email addresses contain an `@` symbol, and that usernames are not blank. This type of validation often occurs in web forms, but it could performed on configuration files, on web service responses, and in any other case where we have to deal with data that we can't guarantee is correct. Authentication, for example, is just a specialised form of validation.

We want to build a library that performs these checks. What design goals should we have? Let's look at some examples of the types of checks we want to perform:

- A bid must apply to one or more items and have a positive value.

- An ID must be parsable as a `UUID` and must correspond to a valid user account.

- An email address must contain an `@` sign. Split the string at the `@`. The string to the left must not be empty. The string to the right must be at least three characters long and contain a dot.


Here are some:

- We should be able associate meaningful messages with each failure.
- We should be able to combine small checks into larger ones. So if, for example, a username must contain at least four characters and consist entirely of alphanumeric characters, we could be able to express this by combining two checks.
- We should be able to transform data while we are checking it. For example, if we receive a `String` representing an age that must be greater than 18, we probably want to parse that `String` as an `Int` before performing the check.
- Finally, when we are performing checks we should be able to accumulate all the failures in one go, so the user can correct all the issues in one go.

