## Versions {-}

This book is written for Scala @SCALA_VERSION@ and Cats @CATS_VERSION@.
Here is a minimal `build.sbt` containing
the relevant dependencies and settings[^sbt-version]:

```scala
scalaVersion := "@SCALA_VERSION@"

libraryDependencies +=
  "org.typelevel" %% "cats-core" % "@CATS_VERSION@"

scalacOptions ++= Seq(
  "-explain",
  "-Werror"
)
```

[^sbt-version]: We assume you are using SBT 1.0.0 or newer.

### Template Projects {-}

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
