(function( jQuery, undefined ) {

let c;


function populate(isbnSelector, cb) {
  const isbns = [];
  const targetByIsbn = {};
  $(isbnSelector).each(function() {
    const target = $(this);
    const isbn = target.attr('data-isbn');
    targetByIsbn[isbn] = target;
    isbns.push(isbn);
  });
  if (!isbns.length) return;
  const url = `/api/v1/contrib/tamelec/notices?isbn=` + isbns.join(',');
  jQuery.getJSON(url)
    .done((infos) => {
      Object.keys(infos).forEach(function(isbn) {
        const info = infos[isbn];
        if (info.notfound) return;
        cb(info, targetByIsbn[isbn]);
      });
    });
}


function pageOpacDetail() {
  populate('.cover-slider', function(info, target) {
    const cod = c.opac.detail;
    if (cod.cover.enabled) {
      const url = info.electre[cod.cover.image];
      const style = cod.cover.maxwidth ? `style="max-width: ${cod.cover.maxwidth}px;"` : '';
      const hint = cod.cover.branding ? `<div class="hint">Image d'Electre</div>` : '';
      target.html(`
        <div class="cover-image" id="electre-bookcoverimg" style="display: block;">
          <a href="${url}" title="Image de couverture d'Electre">
            <img alt="Image de couverture d'Electre" src="${url}" ${style}>
          </a>
          ${hint}
        </div>
      `);
    }
    if (cod.infos.enabled) {
      const html = info.koha.opac.info;
      if (html) {
        $('#catalogue_detail_biblio').append(html);
      }
    }
  });
}


function pageOpacResult() {
  const cor = c.opac.result;
  populate('.cover-slides', function(info, target) {
    const url = info.electre[cor.cover.image];
    const style = cor.cover.maxwidth ? `style="max-width: ${cor.cover.maxwidth}px;"` : '';
    target.html(`
      <img src="${url}" alt="" class="item-thumbnail" ${style} />
    `);
  });
}


function run(conf) {
  c = conf;
  if (c?.opac?.detail?.enabled && $('body').is("#opac-detail")) {
    pageOpacDetail();
  }
  if (c?.opac?.result?.enabled && $('body').is("#results")) {
    pageOpacResult();
  }
}

$.extend({
  tamilElectre: (c) => run(c),
});


})( jQuery );
