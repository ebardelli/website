(function () {
  var BREAKPOINT = 1100;

  function getContent(fnId) {
    var item = document.getElementById(fnId);
    if (!item) return null;
    var clone = item.cloneNode(true);
    var backref = clone.querySelector('.footnote-backref');
    if (backref) backref.parentNode.removeChild(backref);
    var p = clone.querySelector('p');
    return p ? p.innerHTML.trim() : clone.innerHTML.trim();
  }

  function clearSidenotes(container) {
    var old = container.querySelectorAll('.sidenote');
    for (var i = 0; i < old.length; i++) {
      old[i].parentNode.removeChild(old[i]);
    }
  }

  function build() {
    var content = document.querySelector('.page-content');
    var footnotes = document.querySelector('.footnotes');
    if (!content || !footnotes) return;

    clearSidenotes(content);

    if (window.innerWidth < BREAKPOINT) {
      footnotes.style.display = '';
      return;
    }

    footnotes.style.display = 'none';

    var refs = content.querySelectorAll('sup[id^="fnref:"] a[href^="#fn:"]');
    if (refs.length === 0) return;

    var pending = [];
    var contentRect = content.getBoundingClientRect();

    for (var i = 0; i < refs.length; i++) {
      var ref = refs[i];
      var fnId = ref.getAttribute('href').substring(1);
      var html = getContent(fnId);
      if (!html) continue;

      var num = fnId.replace('fn:', '');
      var aside = document.createElement('aside');
      aside.className = 'sidenote';
      aside.innerHTML = '<span class="sidenote-number">' + num + '</span> ' + html;
      content.appendChild(aside);

      var supRect = ref.parentElement.getBoundingClientRect();
      pending.push({ el: aside, ideal: supRect.top - contentRect.top });
    }

    // Wait one frame so the browser has laid out the sidenotes and their heights are available
    requestAnimationFrame(function () {
      var cursor = 0;
      for (var i = 0; i < pending.length; i++) {
        var top = Math.max(pending[i].ideal, cursor);
        pending[i].el.style.top = top + 'px';
        cursor = top + pending[i].el.offsetHeight + 12;
      }
    });
  }

  function init() {
    build();
    var resizeTimer;
    window.addEventListener('resize', function () {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(build, 150);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
