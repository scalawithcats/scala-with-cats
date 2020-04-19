var $ = require("jquery");

function init(toggle, toc) {
  toggle = $(toggle);
  toc = $(toc);
  toggle.on("click", function (evt) {
    toc.slideDown();
    toggle.remove();
  });
}

module.exports = { init };
