#let callout(body, title: "", category: "Callout", fill: blue, title-color: white, body-color: black, icon: none) = {
  block(fill: fill,
       width: 100%,
       inset: 8pt)[
           #text(title-color)[#icon #category #title]
           #text(body-color)[#body]
       ]
}

// Presets

#let note = callout.with(category: "Note",
    fill: rgb(21, 30, 44),
    icon: "✎",
    title-color: rgb(21, 122, 255),
    body-color: white)

#let info = callout.with(category: "Info",
    fill: rgb("#5BC0DE"),
    icon: "🛈",
    title-color: rgb(21, 122, 255),
    body-color: rgb(8, 109, 221))

#let warning = callout.with(category: "Warning",
    fill: rgb("#F0AD4E"),
    icon: "⚠",
    title-color: rgb(233, 151, 63),
    body-color: white)

#let solutions = state("solutions", ())
#let solution(body) = {
    solutions.update(s => s.push(body))
}


#let title = "Functional Programming Strategies"
#let subtitle = "In Scala with Cats"
#let authors = "Noel Welsh"
#let edition = "May 2025"
