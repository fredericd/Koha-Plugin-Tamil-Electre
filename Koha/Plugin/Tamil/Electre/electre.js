(function( jQuery, undefined ) {

let c;


function pageOpacDetail() {
  const isbns = [];
  const targetByIsbn = {};
  $('.cover-slider').each(function() {
    const target = $(this);
    const isbn = target.attr('data-isbn');
    isbns.push(isbn);
    targetByIsbn[isbn] = target;
  });
  const url = `/api/v1/contrib/tamelec/notices?isbn=` + isbns.join(',');
  const cod = c.opac.detail;
  if (cod.infos.enabled) {
    // TODO: On pourrait ajouter un onglet à la table Exemplaires...
  }
  jQuery.getJSON(url)
    .done((infos) => {
      Object.keys(infos).forEach(function(isbn) {
        const info = infos[isbn];
        if (info.notfound) return;
        if (cod.cover.enabled) {
          const url = info.electre[cod.cover.image];
          const target = targetByIsbn[isbn];
          const style = cod.cover.maxwidth ? `style="max-width: ${cod.cover.maxwidth}px;"` : '';
          target.html(`
            <div class="cover-image" id="electre-bookcoverimg" style="display: block;">
              <a href="${url}" title="Image de couverture d'Electre">
                <img alt="Image de couverture d'Electre" src="${url}" ${style}>
              </a>
              <div class="hint">Image d'Electre</div>
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
    });
}

function pageOpacResult() {
  const isbns = [];
  const targetByIsbn = {};
  $('.cover-slides').each(function() {
    const target = $(this);
    const isbn = target.attr('data-isbn');
    if (isbn) {
      isbns.push(isbn);
      targetByIsbn[isbn] = target;
    }
  });
  const url = `/api/v1/contrib/tamelec/notices?isbn=` + isbns.join(',');
  const cor = c.opac.result;
  jQuery.getJSON(url)
    .done((infos) => {
      Object.keys(infos).forEach(function(isbn) {
        const info = infos[isbn];
        if (cor.cover.enabled) {
          if (info.notfound) return;
          const url = info.electre[cor.cover.image];
          const target = targetByIsbn[isbn];
          target.html(`
            <img src="${url}" alt="" class="item-thumbnail" />
          `);
        }
      });
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
