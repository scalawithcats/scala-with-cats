const pandoc = require("pandoc-filter");

function createFilter(extension) {
  return function ({t: type, c: value}, format, meta) {
    if (type === "Image") {
      const [caption, inline, [filename, prefix]] = value;

      const match = filename.match(/^(.*)[.]pdf[+]svg$/i);

      if (match != null) {
        const basename = match[1];
        return pandoc.Image(caption, inline, [
          `${basename}.${extension}`,
          prefix,
        ]);
      }
    }
  };
}

module.exports = {
  createFilter,
};
