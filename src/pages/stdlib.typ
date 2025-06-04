#let callout(body, title: "", fill: blue, title-color: white, body-color: black) = {
    block(
        stroke: (left: 8pt + fill),
        fill: color.mix((white, 70%), (fill, 30%)),
        width: 100%,
        inset: 16pt
    )[
        #if title.len() == 0 {
            text(body-color)[#body]
        } else {
            [
                #heading(level: 4, outlined: false, title)
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

        #v-space
        #text(1.6em, authors)

        #if not half [
            #v-space
            #text([Draft built on #datetime.today().display()])
            #v-space

            Copyright 2022--#datetime.today().display("[year]") Noel Welsh.
            Licensed under CC BY-SA 4.0

            Portions of this work are based on Scala with Cats, by Dave
            Pereira-Gurnell and Noel Welsh. Scala with Cats is licensed under
            CC BY-SA 3.0.

            Artwork by Jenny Clements.

            #v-space

            Published by Inner Product Consulting Ltd, UK.
        ]
      ],
    ),
  )
}

// A link to an external site
#let href(destination, body) = {
    link(destination)[#body #footnote(destination)]
}

// A part heading page
//
// image-path: path to the hero image for this part
// name: the name of part as printed in the book
// tag: a tag for references to this part (e.g. "sec:part:one")
// content: content in the part
#let part(image-path, name, tag, content) = [
    #align(center)[
        #image(image-path, width: 50%)
        #heading(level: 1)[
            #name
        ]
        #label(tag)
    ]
    <part>

    #content
]

#let heading-multiplier = 1.2
#let heading-base = 24pt
#let heading-space-base = 12pt
