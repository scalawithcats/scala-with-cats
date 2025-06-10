#import "../stdlib.typ": info, warning, solution, narrative-cite
== Data and Codata


Data describes what things are, while codata describes what things can do. 

We have seen that data is defined in terms of constructors producing elements of the data type. Let's take a very simple example: a `Bool` is either `True` or `False`. We know we can represent this in Scala as

```scala mdoc:silent
enum Bool {
  case True
  case False
}
```

The definition tells us there are two ways to construct an element of type `Bool`.
Furthermore, if we have such an element we can tell exactly which case it is, by using a pattern match for example. Similarly, if the instances themselves hold data, as in `List` for example, we can always extract all the data within them. Again, we can use pattern matching to achieve this.

Codata, in contrast, is defined in terms of operations we can perform on the elements of the type. These operations are sometimes called *destructors* (which we've already encountered), *observations*, or *eliminators*. A common example of codata is a data structure such as a set. We might define the operations on a `Set` with elements of type `A` as:

- `contains`, which takes a `Set[A]` and an element `A` and returns a `Boolean` indicating if the set contains the element;
- `insert`, which takes a `Set[A]` and an element `A` and returns a `Set[A]` containing all the elements from the original set and the new element; and
- `union`, which takes a `Set[A]` and a set `Set[A]` and returns a `Set[A]` containing all the elements of both sets.

In Scala we could implement this definition as

```scala mdoc:silent
trait Set[A] {
  
  /** True if this set contains the given element */
  def contains(elt: A): Boolean
  
  /** Construct a new set containing all elements in this set and the given element */
  def insert(elt: A): Set[A]
  
  /** Construct the union of this and that set */
  def union(that: Set[A]): Set[A]
}
```

This definition does not tell us anything about the internal representation of the elements in the set. It could use a hash table, a tree, or something more exotic. It does, however, tell us what we can do with the set. We know we can take the union but not the intersection, for example. 

If you come from the object-oriented world you might recognize the description of codata above as programming to an interface. In some ways codata is just taking concepts from the object-oriented world and presenting them in a way that is consistent with the rest of the functional programming paradigm. However, this does not mean adopting all the features of object-oriented programming. We won't use state, which is difficult to reason about. We also won't use implementation inheritance either, for the same reason. In our subset of object-oriented programming we'll either be defining interfaces (which may have default implementations of some methods) or final classes that implement those interfaces. Interestingly, this subset of object-oriented programming is often recommended by advocates of object-oriented programming#footnote[For example, #narrative-cite(<bloch17:effective>) suggests developers "minimize mutability" and "favor composition over [implementation] inheritance". Together these form the subset of object-oriented programming that we consider to be codata.].

Let's now be a little more precise in our definition of codata, which will make the duality between data and codata clearer. Remember the definition of data: it is defined in terms of sums (logical ors) and products (logical ands). We can transform any data into a sum of products, which is disjunctive normal form. Each product in the sum is a constructor, and the product itself is the parameters that the constructor accepts. Finally, we can think of constructors as functions which take some arbitrary input and produce an element of data. Our end point is a sum of functions from arbitrary input to data.

More concretely, if we are constructing an element of some data type `A` we call one of the constructors

- `A1: (B, C, ...) => A`; or
- `A2: (D, E, ...) => A`; or
- `A3: (F, G, ...) => A`; and so on.


Now we'll turn to codata. Codata is defined as a product of functions, these functions being the destructors. The input to a destructor is always an element of the codata type and possibly some other parameters. The output is usually something that is not of the codata type. Thus constructing an element of some codata type `A` means defining


- `A1: (A, B, ...) => C`; and
- `A2: (A, D, ...) => E`; and
- `A3: (A, F, ...) => G`; and so on.

This hopefully makes the duality between the two clearer.

Now we understand what codata is, we will turn to representing codata in Scala.
