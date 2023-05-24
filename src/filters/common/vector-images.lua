-- extension is the string extension to replace the "pdf+svg" extension. E.g. ".svg" to just use SVG.
function createFilter(extension)
  return function (elem)
    elem.src = string.gsub(elem.src, "%.pdf%+svg", extension)
    return elem
  end
end
