/*
  this Class requires "Observable" and "jQuery"
*/
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
      Articles.CACHE[article.id] = new HtmlManipulator(article.content || article.description, article.channel.link)
        .pathToAbsolute('img', 'src', article.channel.link)
        .pathToAbsolute('a', 'href', article.channel.link)
        .stripTags('script')
        .stripTags('iframe')
        .stripTags('object')
        .stripTags('embed')
        .stripTags('form')
        .stripTags('link')
        .stripAttributes('class')
        .stripAttributes('style')
        .setTargetNameForAllAnchors('_blank')
        .inactivateAllForms()
        .html();
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
