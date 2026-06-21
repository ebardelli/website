'use strict';

document.addEventListener('click', function(e) {
    var btn = e.target.closest && e.target.closest('.copy-code-button');
    if (!btn) return;
    var highlight = btn.closest('.highlight');
    if (!highlight) return;
    var pre = highlight.querySelector('pre') || highlight.querySelector('code');
    var text = pre ? pre.textContent : '';
    if (!text) return;
    var originalHTML = btn.innerHTML;

    function onSuccess() {
        btn.innerHTML = '<span class="icon" aria-hidden="true">'
            + '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">'
            + '<path d="M20 6L9 17l-5-5"></path></svg></span>'
            + '<span class="sr-only">Copied</span>';
        setTimeout(function() { btn.innerHTML = originalHTML; }, 2000);
    }

    if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(onSuccess).catch(function() { fallbackCopy(text, onSuccess); });
    } else {
        fallbackCopy(text, onSuccess);
    }

    function fallbackCopy(text, cb) {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', '');
        ta.style.position = 'absolute';
        ta.style.left = '-9999px';
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand('copy'); cb(); } catch(err) { console.warn('copy failed', err); }
        document.body.removeChild(ta);
    }
}, false);
