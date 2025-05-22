#let page-numbering = context {
    let current = counter(page).get().first()
    let unnumbered = counter(page).at(<unnumbered>).first()
    if current < unnumbered [#none] else [#counter(page).display("1")]
}
