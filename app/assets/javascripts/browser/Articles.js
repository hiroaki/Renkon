function Articles() {
  this.super = Observable.prototype;
  this.root_id = '#articles';
  this.$root = $(this.root_id);
  Observable.apply(this, arguments);
}
Articles.CACHE = {};
Articles.prototype = Object.create(Observable.prototype, {
  constructor: { value: Articles }
});
Articles.prototype.update = function(url) {
  $.ajax(url, {
    dataType: 'json'
  }).then(function(data) {
    var i, l, article, $ul;
    console.log(data);
    $ul = $('<ul>');
    this.$root.empty().append($ul);
    for ( i = 0, l = data.length; i < l; ++i ) {
      article = data[i];
      $ul.append('<li data-article-id="'+ article.id +'" title="'+ article.title +'">'+ article.title +'</li>');

      // WORKAROUND: quick implementation
      $('#contents').empty();
      Articles.CACHE[article.id] = (function(html_string, url_base) {
        var doc = new DOMParser().parseFromString(html_string, 'text/html'),
            abspath, strip_tags, strip_attr, target_blank, inactivate_form;
        // console.log(doc);
        strip_tags = function(tag_name) {
          var idx, ndlist = doc.body.getElementsByTagName(tag_name);
          for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
            ndlist[idx].parentNode.removeChild(ndlist[idx]);
          }
        };
        strip_attr = function (attr_name) {
          var idx, ndlist = doc.querySelectorAll('*');
          for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
            ndlist[idx].removeAttribute(attr_name);
          }
        };
        abspath = function(tag_name, attr_name) {
          $.each(doc.body.getElementsByTagName(tag_name), function(idx, elem) {
            elem.setAttribute(attr_name, URI(elem.getAttribute(attr_name), url_base).href());
          });
        };
        target_blank = function() {
          var idx, ndlist = doc.body.getElementsByTagName('a');
          for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
            ndlist[idx].setAttribute('target', '_blank');
          }
        };
        inactivate_form = function() {
          var idx, ndlist = doc.body.getElementsByTagName('form');
          for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
            ndlist[idx].setAttribute('method', 'GET');
            ndlist[idx].setAttribute('action', 'javascript:void(0);');
          }
        };
        // replace url relative to absolute
        abspath('img', 'src');
        abspath('a', 'href');
        // remove unexpected tags
        strip_tags('script');
        strip_tags('iframe');
        strip_tags('object');
        strip_tags('embed');
        strip_tags('form');
        strip_tags('link');
        //
        strip_attr('class');
        strip_attr('style');
        //
        target_blank();
        inactivate_form();

        return $(doc.body).html();
      })(article.content || article.description, article.channel.link);

    }
  }.bind(this));
}
Articles.prototype.build = function() {
  this.$root.empty();
  this.addListeners();
};
Articles.prototype.addListeners = function() {
  this.$root.on({
    click: function(evt) {
      var $target = $(evt.target);
      console.log("click: "+ $target.data('article-id'));
      $('li.active', this.root_id).removeClass('active');
      $target.addClass('active');
      this.notify();

      // WORKAROUND: quick implementation
      $('#contents').empty().append(Articles.CACHE[this.selectedValue()]);

      return false;
    }.bind(this)
  }, 'li');
};
Articles.prototype.selectedValue = function() {
  return $('li.active', this.root_id).data('article-id');
};
