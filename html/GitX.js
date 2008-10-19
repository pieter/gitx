/*
 * GitX Javascript library
 * This library contains functions that can be shared across all
 * webviews in GitX.
 * It is written only for Safari 3 and higher.
 */

function $(element) {
	Controller.log_("Calling _");
	return document.getElementById(element);
}

String.prototype.escapeHTML = function() {
  return this.replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
};

String.prototype.unEscapeHTML = function() {
  return this.replace(/&amp;/g,'&').replace(/&lt;/g,'<').replace(/&gt;/g,'>');
};

Array.prototype.indexOf = function(item, i) {
  i || (i = 0);
  var length = this.length;
  if (i < 0) i = length + i;
  for (; i < length; i++)
    if (this[i] === item) return i;
  return -1;
};