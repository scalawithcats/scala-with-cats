#let callout(body, title: none, fill: blue, title-color: white, body-color: black) = {
    block(
        stroke: (left: 8pt + fill),
        fill: color.mix((white, 70%), (fill, 30%)),
        width: 100%,
        inset: 16pt
    )[
        #if title == none {
            text(body-color)[#body]
        } else {
            [
                #heading(depth: 4, numbering: none, outlined: false, title)
                #text(body-color)[#body]
            ]
        }
    ]
}

// Presets

#let info-color = rgb("#5BC0DE")
#let warning-color = rgb("#F0AD4E")

#let note = callout.with(
    fill: rgb(21, 30, 44),
    title-color: rgb(21, 122, 255),
    body-color: white)

#let info = callout.with(
    fill: info-color,
    title-color: rgb(21, 122, 255),
    body-color: black)

#let warning = callout.with(
    fill: warning-color,
    title-color: rgb(233, 151, 63),
    body-color: black)

#let solutions = state("solutions", ())
#let solution(body) = {
    solutions.update(s => s.push(body))
}


#let title = "Functional Programming Strategies"
#let subtitle = "In Scala with Cats"
#let authors = "Noel Welsh"

#let title-page(half: true) = {
  page(
    align(
      left + horizon,
      block(width: 90%)[
        #let v-space = v(2em, weak: true)
        #text(3em)[*#title*]

        #if not half [
            #v-space
            #text(1.6em, authors)

            #v-space
            #text([Draft built on #datetime.today().display()])
        ]
      ],
    ),
  )
}

// A link to an external site
#let href(destination, body) = {
    link(destination)[#body #footnote(destination)]
}

// A chapter heading
//
// Typical use is
// #chapter[Name] <sec:name>
#let chapter(name) = heading(depth: 1, supplement: "Chapter")[#name]

// A part heading
//
// Typical use is
// #part[Name] <label>
#let part = figure.with(
    // Matches the key of the counter above
    kind: "part",
    numbering: "I",
    supplement: "Part",
    // Empty caption so that parts can be included in the outline
    caption: []
)


#let exercise(title) = {
    heading(depth: 4, numbering: none, outlined: false, "Exercise: " + title)
}

#let narrative-cite(label) = {
    show cite.where(form: "prose"): it => {
        show "{": ""
        show "~": " ["
        show "}": "]"
        cite(it.key, style: it.style)
    }
    cite(label, form: "prose", style: "/fps-title.csl")
}


// A table that is styled with a line above and below the heading, and line
// below the final row in the table.
#let styled-table(columns: auto, alignment: auto, ..children) = {
    let content = children.pos()
    let num-rows = calc.ceil(content.len() / columns.len())
    let last-row = num-rows - 1

    show table.cell.where(y: 0): strong
    align(center,
        table(
            columns: columns,
            align: alignment,
            stroke: (x, y) => {
                if y == 0 {
                    // Header: line above and below
                    (top: 0.5pt + black, bottom: 0.5pt + black, left: none, right: none)
                } else if y == last-row {
                    // Last row: line below only
                    (bottom: 0.5pt + black, top: none, left: none, right: none)
                } else {
                    // Data rows: no lines
                    (top: none, bottom: none, left: none, right: none)
                }
            },
            ..content
        )
    )
}
