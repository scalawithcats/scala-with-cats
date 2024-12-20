# Tagless Final Interpreters

We've seen the duality between data and codata in many places, starting in Chapter [@sec:codata], but we haven't yet explored interpreters that use the codata approach. In this chapter we'll do so, looking at a strategy known as **tagless final**.

Tagless final is a little bit more than a straightforward application of the data-codata duality.
In particular, it solves a problem around extensibility known as the **expression problem**.
We first met this problem in Section [@sec:codata:extensibility].
In the context of interpreters, solving the expression problem allowing extensibility of both the programs we write and the interpreters that run them.

We'll start this chapter looking at codata interpreters.
We'll see they have a shortcoming, which motivates the expression problem.
After describing the expression problem we'll look into tagless final proper.
The standard presentation is simpler to understand but painful to use in practice, so we'll explore Scala language features that hide complexity from the user.
Solving the expression problem allows for very expressive code, as the name suggests, so we'll finish by talking about when tagless final is appropriate and when it's best left alone.
