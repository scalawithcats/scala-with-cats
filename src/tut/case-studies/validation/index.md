# Case Study: Data Validation

In this case study we will build a library for validation. What do we mean by validation? Almost all programs must check their input meets certain criteria. For example, perhaps we want to ensure that email addresses contain an `@` symbol, and that usernames are not blank. This type of validation often occurs in web forms, but it could performed on configuration files, on web service responses, and in any other case where we have to deal with data that we can't guarantee is correct. Authentication, for example, is just a specialised form of validation.

We want to build a library that performs these checks. What design goals should we have? For inspiration, let's look at some examples of the types of checks we want to perform:

- A bid must apply to one or more items and have a positive value.

- An ID must be parsable as a `UUID` and must correspond to a valid user account.

- A username must contain at least four characters and consist entirely of alphanumeric characters

- An email address must contain an `@` sign. Split the string at the `@`. The string to the left must not be empty. The string to the right must be at least three characters long and contain a dot.

With these examples in mind, we can state some goals:

- We should be able associate meaningful messages with each validation failure, so the user knows why their data is not valid.
- We should be able to combine small checks into larger ones. Taking the username example above, we should be able to express this by combining a check of length and a check for alphanumeric values.
- We should be able to transform data while we are checking it. There is an example above requires we parse data, changing its type from `String` to `UUID`. 
- Finally, when we are performing checks we should be able to accumulate all the failures in one go, so the user can correct all the issues in one go.

Note there are two levels of structure in our library. We have seen that there is structure in the checks we apply to data. The data itself also has structure. We described checks for username and email address above. Now consider that this data may arrive as part of a user signup, and we wish to chceck this entire signup as one piece, accumulating the errors found in each component piece of data.
