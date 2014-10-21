---
layout: page
title: Project: Pygmy Hadoop
---

In a previous section we implemented a function `foldMap` that folded a `List` using an implicit monoid. In this project we're going to extend this idea to parallel processing.

If you have used Hadoop or otherwise worked in the "big data" field you will have heard of the [MapReduce](http://research.google.com/archive/mapreduce.html) programming model. MapReduce is a model for parallel data processing that is commonly used to process data cross tens or hundreds of machines. As the name suggests, it is built around a map phase, which is the same `map` function we know from Scala, and a reduce phase, which we usually call `fold`. (In Hadoop there is also a shuffle phase, which we are going to ignore.)

It should be fairly obvious we can apply `map` in parallel. In general we cannot parallelize `fold`, but if we are prepared to restrict the type of functions we allow in fold we can do so. What kind of restrictions should be apply? If the function we provide to `fold` is associative (so `(x + y) + z == x + (y + z)`, for some binary function `+`) we can perform our fold in any order so long as we preserve ordering on the sequence of elements we're processing. If we have an identity element (so `x + 0 == 0 + x` for any `x`) we can introduce the identity at any point to in our fold and know we won't affect the result.

If this sounds like a monoid, it's because it is a monoid. We're not the first to recognise this. The [monoid design pattern for MapReduce jobs](http://arxiv.org/abs/1304.7544) is at the core of recent big data systems such as Twitter's [Summingbird](https://github.com/twitter/summingbird).

In this project we're going to implement a very simple single-machine MapReduce. In fact, we're just going to parallelize `foldMap` and then look at some of more interesting monoids that are applicable for processing large data sets.
