#import "../stdlib.typ": info, warning, solution
== Versions


This book is written for Scala @SCALA_VERSION@ and Cats @CATS_VERSION@.
Here is a minimal `build.sbt` containing
the relevant dependencies and settings #footnote[We assume you are using SBT 1.0.0 or newer]:

```scala
scalaVersion := "@SCALA_VERSION@"

libraryDependencies +=
  "org.typelevel" %% "cats-core" % "@CATS_VERSION@"

scalacOptions ++= Seq(
  "-Xfatal-warnings"
)
```


=== Template Projects


For convenience, we have created
a Giter8 template to get you started.
To clone the template type the following:

```bash
$ sbt new scalawithcats/cats-seed.g8
```

This will generate a sandbox project
with Cats as a dependency.
See the generated `README.md` for
instructions on how to run the sample code
and/or start an interactive Scala console.
