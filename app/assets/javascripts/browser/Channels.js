/*

*/
function Channels() {
  this.super = Observable.prototype;
  this.root_id = '#channels';
  this.$root = $(this.root_id);
  Observable.apply(this, arguments);
}
Channels.prototype = Object.create(Observable.prototype, {
  constructor: { value: Channels }
});
Channels.prototype.update = function(url) {
  $.ajax(url, {
    dataType: 'json'
  }).then(function(data) {
    var i, l, j, m, site, channel, $ul;
    console.log(data);
    $ul = $('<ul>');
    this.$root.empty().append($ul);
    for ( i = 0, l = data.length; i < l; ++i ) {
      site = data[i];
      for ( j = 0, m = site.channels.length; j < m; ++j ) {
        channel = site.channels[j];
        $ul.append('<li data-channel-id="'+ channel.id +'" data-url_articles="'+ channel.url_articles +'">'+ channel.title +'</li>');
      }
    }
  }.bind(this));
}
Channels.prototype.build = function() {
  this.$root.empty();
  this.addListeners();
};
Channels.prototype.addListeners = function() {
  this.$root.on({
    click: function(evt) {
      var $target = $(evt.target);
      console.log("click: "+ $target.data('channel-id'));
      $('li[data-channel-id].active', this.root_id).removeClass('active');
      $target.addClass('active');
      this.notify();
      return false;
    }.bind(this)
  }, 'li[data-channel-id]');
};
Channels.prototype.selectedValue = function() {
  return $('li.active', this.root_id).data('channel-id');
};
Channels.prototype.selectedUrlArticles = function() {
  return $('li.active', this.root_id).data('url_articles');
};
