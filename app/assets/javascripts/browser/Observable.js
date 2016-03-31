/*
  Abstract class Observable
*/
Observable = function() {
  this.initialize.apply(this, arguments);
};

Observable.prototype.initialize = function() {
  this.observers = [];
};

Observable.prototype.addObserver = function(observer) {
  this.observers.push(observer);
  return this;
};

Observable.prototype.notify = function(category) {
  var i;
  for ( i in this.observers ) {
    this.observers[i].update(this, category);
  }
  return this;
};
