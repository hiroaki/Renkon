/*
  this Class requires "URI" and "jQuery"
*/
function HtmlManipulator() {
  this.initialize.apply(this, arguments);
}

HtmlManipulator.prototype.initialize = function(html_string) {
  this.html_string = html_string;
  this.doc = new DOMParser().parseFromString(this.html_string, 'text/html');
};

HtmlManipulator.prototype.stripTags = function(tag_name) {
  var idx, ndlist = this.doc.body.getElementsByTagName(tag_name);
  for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
    ndlist[idx].parentNode.removeChild(ndlist[idx]);
  }
  return this;
};

HtmlManipulator.prototype.stripAttributes = function(attr_name) {
  var idx, ndlist = this.doc.querySelectorAll('*');
  for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
    ndlist[idx].removeAttribute(attr_name);
  }
  return this;
};

HtmlManipulator.prototype.pathToAbsolute = function(tag_name, attr_name, url_base) {
  $.each(this.doc.body.getElementsByTagName(tag_name), function(idx, elem) {
    elem.setAttribute(attr_name, URI(elem.getAttribute(attr_name), url_base).href());
  });
  return this;
};

HtmlManipulator.prototype.setTargetNameForAllAnchors = function(target_name) {
  var idx, ndlist = this.doc.body.getElementsByTagName('a');
  target_name = target_name || '_blank';
  for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
    ndlist[idx].setAttribute('target', target_name);
  }
  return this;
};

HtmlManipulator.prototype.inactivateAllForms = function() {
  var idx, ndlist = this.doc.body.getElementsByTagName('form');
  for ( idx = ndlist.length - 1; 0 <= idx; --idx ) {
    ndlist[idx].setAttribute('method', 'GET');
    ndlist[idx].setAttribute('action', 'javascript:void(0);');
  }
  return this;
};

HtmlManipulator.prototype.html = function() {
  return $(this.doc.body).html();
}

