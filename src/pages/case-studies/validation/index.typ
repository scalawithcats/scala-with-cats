#import "../../stdlib.typ": info, warning, solution
= Case Study: Data Validation


In this case study we will build a library for validation.
What do we mean by validation?
Almost all programs must check their input meets certain criteria.
Usernames must not be blank, email addresses must be valid, and so on.
This type of validation often occurs in web forms,
but it could be performed on configuration files,
on web service responses, and any other case where
we have to deal with data that we can't guarantee is correct.
Authentication, for example, is just a specialised form of validation.

We want to build a library that performs these checks.
What design goals should we have?
For inspiration, let's look at some examples of
the types of checks we want to perform:

- A user must be over 18 years old
  or must have parental consent.

- A `String` ID must be parsable as a `Int`
  and the `Int` must correspond to a valid record ID.

- A bid in an auction must apply
  to one or more items and have a positive value.

- A username must contain at least four characters
  and all characters must be alphanumeric.

- An email address must contain a single `@` sign.
  Split the string at the `@`.
  The string to the left must not be empty.
  The string to the right must be
  at least three characters long and contain a dot.

With these examples in mind we can state some goals:

- We should be able to associate meaningful messages with each validation failure,
  so the user knows why their data is not valid.

- We should be able to combine small checks into larger ones.
  Taking the username example above,
  we should be able to express this
  by combining a check of length and a check for alphanumeric values.

- We should be able to transform data while we are checking it.
  There is an example above requiring we parse data,
  changing its type from `String` to `Int`.

- Finally, we should be able to accumulate all the failures in one go,
  so the user can correct all the issues before resubmitting.

These goals assume we're checking a single piece of data.
We will also need to combine checks across multiple pieces of data.
For a login form, for example,
we'll need to combine the check results for the username and the password.
This will turn out to be quite a small component of the library,
so the majority of our time will focus on checking a single data item.
