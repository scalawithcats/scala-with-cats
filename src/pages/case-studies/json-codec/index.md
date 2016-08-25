# Case Study: Json Codec {#json-codec}

Scala famously has a thousand JSON libraries,
and we're going to create one more using our Cats toolkit.
In this case study we will create a simple way to
read and write JSON data and map it to useful Scala types.

Many functional JSON libraries manage mappings between
three different levels of representation:

1. Raw JSON---text written using the syntax
defined in the [JSON specification][link-json].

2. A "JSON DOM"---an algebraic data type
representing the JSON primitives in the raw JSON
(objects, arrays, strings, nulls, and so on).

3. Semantic data types---the types we care about
in our applications.

The "JSON DOM" is a useful abstraction.
If we can parse raw JSON to a DOM,
we know we have a syntactically valid file.
We can traverse and manipulate instances of an ADT
much more easily than we can raw string data,
making it easier to tackle the problem of mapping
on to semantic types.

## JSON DOM ADT

Let's start by designing an algebraic data type for our JSON DOM.
The [JSON spec][link-json] describes a "JSON value"
as being one of the following data types:

- an object
- an array
- a string
- a number
- a boolean
- a null

