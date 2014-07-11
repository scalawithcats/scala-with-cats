$(function() {
  var relative = null;

  if (location.protocol==='file:') {
    relative = Array($('link[rel="canonical"]').attr('href').match(/\//g).length-2).join('../');
    if (relative == '') relative = './';
  }

  function toRelative(link, index) {
    if (!relative) return link;
    var hash = link ? link.match(/#.*$/) : null;
    if (hash) link = link.replace(/#.*$/, '');
    return link?(link.replace(/^\//, relative)+(index?(link.substr(-1)=='/'?'index.html':''):'')+(hash?hash[0]:'')):null;
  }

  if (relative) {
    $('a').attr('href', function(a,b) {return toRelative(b, true);});
    $('img').attr('src', function(a,b) {return toRelative(b, false);});
  }

  // Transform
  //
  // <div class="solution">blah</div>
  //
  // To
  //
  // <div class="solution-block">
  //   <h5>...</h5>
  //   <div class="solution">blah</div>
  // </div>
  //
  // with click handler on h5 to toggle visibility of solution

  $('.solution').each(function() {
    var solution = $(this);

    solution
      .addClass("panel-body")
      .wrap('<div class="panel panel-default"></div>')
      .hide();

    $('<div class="panel-heading"><h5><a href="javascript:void 0">Solution (click to reveal)</a></h5></div>')
      .insertBefore(solution)
      .find("a")
      .click(function(evt) {
        solution.toggle();
        evt.preventDefault();
      });

  })
});
