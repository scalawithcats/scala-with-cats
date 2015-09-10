lazy val root = project.in(file("."))
  .settings(tutSettings)

tutSourceDirectory := sourceDirectory.value / "tut"

tutTargetDirectory := sourceDirectory.value / "pages"

scalaVersion := "2.11.7"

scalacOptions ++= Seq(
  "-deprecation",
  "-encoding", "UTF-8",
  "-unchecked",
  "-feature",
  "-language:implicitConversions",
  "-language:postfixOps",
  "-Ywarn-dead-code",
  "-Xlint",
  "-Xfatal-warnings"
)

libraryDependencies ++= Seq(
  "org.scalaz" %% "scalaz-core" % "7.1.3"
)

lazy val pdf = taskKey[Unit]("Builds the PDF version of the book")

pdf := {
  val a = tut.value
  "grunt pdf" !
}


