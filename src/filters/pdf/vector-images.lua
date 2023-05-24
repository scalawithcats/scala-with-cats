if FORMAT:match 'latex' then
  function Image(elem)
    elem.src = string.gsub(elem.src, "%.pdf%+svg", ".pdf")
    return elem
  end
end
