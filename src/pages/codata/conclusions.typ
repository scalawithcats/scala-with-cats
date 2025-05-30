#import "../stdlib.typ": info, warning, solution
== Conclusions


In this chapter we've explored codata, the dual of data. Codata is defined by its interface---what we can do with it---as opposed to data, which is defined by what it is. More formally, codata is a product of destructors, where destructors are functions from the codata type (and, optionally, some other inputs) to some type. By avoiding the elements of object-oriented programming that make it hard to reason about---state and implementation inheritance---codata brings elements of object-oriented programming that accord with the other functional programming strategies. In Scala we define codata as a `trait`, and implement it as a `final class`, anonymous subclass, or an object.

We have two strategies for implementing methods using codata: structural corecursion, which we can use when the result is codata, and structural recursion, which we can use when an input is codata. Structural corecursion is usually the more useful of the two, as it gives more structure (pun intended) to the method we are implementing. The reverse is true for data.

We saw that data is connected to codata via fold: any data can instead be implemented as codata with a single destructor that is the fold for that data. The reverse is also: we can enumerate all potential pairs of inputs and outputs of destructors to represent codata as data. However this does not mean that data and codata are equivalent. We have seen many examples of codata representing infinite structures, such as sets of all even numbers and streams of all natural numbers. We have also seen that data and codata offer different forms of extensibility: data makes it easy to add new functions, but adding new elements requires changing existing code, while it is easy to add new elements to codata but we change existing code if we add new functions.

The earliest reference I could find to codata in programming languages is #cite(<hagino89:codatatypes>, form: "prose"). This is much more recent than algebraic data, which I think explains why codata is relatively unknown. There are some excellent recent papers that deal with codata.
I highly recommend #cite(<downen19:codata>, form: "prose"), which inspired large portions of this chapter.
 #cite(<sullivan19:exploring-codata>, form: "prose") is also worthwhile.
#cite(<wadler98:odd>, form: "prose") is an older paper that discusses the implementation of streams, and in particular the difference between a not-quite-lazy-enough implementation they label odd and the version we saw, which they call even. These correspond to `Stream` and `LazyList` in the Scala standard library respectively.
*Classical (Co)Recursion: Programming* #cite(<downen21:classical>, form: "prose"):classical is an interesting survey of corecursion in different languages, and covers many of the same examples that I used here.
Finally, if you really want to get into the weeds of the relationship between data and codata, #cite(<kiselyov05:beyond>, form: "prose") is for you.
