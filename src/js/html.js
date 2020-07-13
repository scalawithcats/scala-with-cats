var $ = require("jquery");

var toc = require("./toc");

function addToggle(className, name, additionalClasses) {
  function toggleMain() {
    var toggleable = $(this);

    var extraClasses =
      additionalClasses != null ? additionalClasses : { additionalClasses: "" };

    function theToggling(evt) {
      toggleable.toggle();
      return evt.preventDefault();
    }

    toggleable
      .addClass("panel-body")
      .wrap('<div class="panel panel-default #{extraClasses}"></div>')
      .hide();

    return $(
      `<a href="javascript:void 0">
        <div class="panel-heading">
          <h5>${name} (click to reveal)</h5>
        </div>
      </a>`
    )
      .insertBefore(toggleable)
      .click(theToggling);
  }
  return $(`.${className}`).each(toggleMain);
}

$(function () {
  toc.init(".toc-toggle", ".cover-notes,.toc-contents");
  addToggle("solution", "Solution");
});
