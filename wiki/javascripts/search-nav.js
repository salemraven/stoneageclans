/* MkDocs Material: ensure search result clicks always navigate (no silent instant-load miss). */
document.addEventListener("click", function (event) {
  var link = event.target.closest(".md-search-result__link");
  if (!link) {
    return;
  }
  var href = link.getAttribute("href");
  if (!href) {
    return;
  }
  event.preventDefault();
  window.location.assign(href);
}, true);
