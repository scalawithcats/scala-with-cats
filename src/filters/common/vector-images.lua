if FORMAT:match 'latex' then
  function Image(elem)
    elem.src = string.gsub(elem.src, ".pdf+svg", ".pdf")
    return elem
  end
end

if FORMAT:match 'html' then
  function Image(elem)
    elem.src = string.gsub(elem.src, ".pdf+svg", ".svg")
    return elem
  end
end
