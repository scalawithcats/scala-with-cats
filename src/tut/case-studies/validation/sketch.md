## Sketching the Library Structure

Let's start with the bottom level, checking individual components of the data. Before getting into the code, let's try to develop a feel for what we'll be building. We can use our graphical notation to help us.

Start with our first goals: associating useful error messages with check failure. The output of a check could be either the value being checked, if it passed the check, or some kind of error message. We can abstactly represent this as a value in a context, where the context is the possibility of an error message.

* [.] *

Then a check itself is a function that transforms a value into a value in a context.

* . => [.] *

Our next goal is to combine smaller checks into larger ones? Is this an applicative?

* . => [.] |@| . => [.] = [(.,.)] *

Not really. Both checks are applied to the same value and we want to just get that value back, not a tuple with the value repeated. It feels more like a monoid.

* . => [.] |+| . => [.] = . => [.] *

We can even define a sensible identity---the check that always passes. So a monoid seems the right track. Thinking a bit more about the problem, we want to combine checks using logical operators---mainly and and or---so a monoid is the right abstraction. However we might not want to actually use a monoid API as we'll probably use and and or about equally often and it will be annoying to have to continuously wrap types to switch between the two methods. We'll probably want methods `and` and `or` instead.

Now we have the goal of transforming data. This seems like it should be a map or a flatMap depending on whether the transform can fail or not. In the example, parsing a `String` to an `Int`, that can definitely fail so it seems we also want checks to be a monad.

Finally we get to accumulating error messages. This feels like a monoid, which we've already discussed above.

We've now broken down our library into familiar abstractions and are in a good position to begin development. 
