## Data and Codata

Data describes what things are, while codata describes what things can do. 

We have seen that data is defined by giving constructors that produce elements of the data type. Let's take a very simple algebraic data type: a `Bool` is either `True` or `False`. We know we can represent this in Scala as

```scala mdoc:silent
enum Bool {
  case True
  case False
}
```

The definition tells us there are two ways to construct an element of type `Bool`.
Furthermore, if we have such an element we can tell exactly which case it is, by using a pattern match for example. Similarly, if the instances themselves hold data, as in `List` for example, we can always extract all the data within them. Again, we can use pattern matching to achieve this.

Codata, in contrast, is defined in terms of operations we can perform on the elements of the type. These operations are sometimes called **destructors** (which we've already encountered), **observations**, or **eliminators**. Common example of codata are data structures such as sets. We might define the operations on a `Set` with elements of type `A` as:

- `contains` which takes a `Set[A]` and an element `A` and returns a `Boolean` indicating if the set contains the element,
- `insert` which takes a `Set[A]` and an element `A` and returns a `Set[A]` containing all the elements from the original set and the new element, and
- `union` which takes a `Set[A]` and a set `Set[A]` and returns a `Set[A]` containing all the elements of both sets.

In Scala we could translate this definition as

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

This definition does not tell us anything about the internal representation of the set. It could use a hash table, a tree, or something more exotic. It does, however, tell us what we can do with the set. We know we can take the union but not the intersection, for example. 

If you come from the object-oriented world you might recognize the description of codata above as programming to an interface. In many ways codata is just taking concepts from the object-oriented world and presenting them in a way that is consistent with the rest of the functional programming paradigm.

Let's now be a little more precise in our definition, which will make the duality between data and codata clearer:

- Data is defined as a sum of products. Each element in the sum is a constructor, and the product is the parameters that the constructor accepts. We can think of constructors as functions which take some arbitrary input and produce an element of data. 

- Codata is defined as a product of functions, these functions being the destructors, or observations, or eliminators. The input to a destructor is always an element of the codata type and possibly some other parameters. The output is usually something that is not of the codata type. 
