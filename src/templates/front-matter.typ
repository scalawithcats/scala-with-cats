#let front-matter(title, subtitle) = {
    // Half title page
    pagebreak(to: "even")
    place(center + horizon, float: false)[
        #align(center)[#block(inset: 2em)[
            #text(weight: "bold", size: 2.5em)[#title]
        ]]
    ]
    // Title page
    pagebreak(to: "even")
    place(center + horizon, float: false)[
        #align(center)[#block(inset: 2em)[
            #text(weight: "bold", size: 2.5em)[#title]
            #(if subtitle != none {
                parbreak()
                text(weight: "bold", size: 1.25em)[#subtitle]
            })
        ]]
    ]
    [#metadata(()) <unnumbered>]
    pagebreak(to: "even")
    counter(page).update(1)
}
