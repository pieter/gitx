/*
 * GitX Javascript library
 * This library contains functions that can be shared across all
 * webviews in GitX.
 * It is written only for Safari 3 and higher.
 */

function $(element) {
	return document.getElementById(element);
}

String.prototype.escapeHTML = (function() {
	var div = document.createElement("div");
	return function() {
		div.textContent = this;
		return div.innerHTML;
	};
})();

Element.prototype.toggleDisplay = function() {
	if (this.style.display != "")
		this.style.display = "";
	else
		this.style.display = "none";
}

Array.prototype.indexOf = function(item, i) {
  i || (i = 0);
  var length = this.length;
  if (i < 0) i = length + i;
  for (; i < length; i++)
    if (this[i] === item) return i;
  return -1;
};

var notify = function(html, state) {
	var n = $("notification");
	n.classList.remove("hidden");
	$("notification_message").innerHTML = html;
	
	// Change color
	if (!state) { // Busy
		$("spinner").classList.remove("hidden");
		n.classList.remove("success");
		n.classList.remove("fail");
	}
	else if (state == 1) { // Success
		$("spinner").classList.add("hidden");
		n.classList.add("success");
	} else if (state == -1) {// Fail
		$("spinner").classList.add("hidden");
		n.classList.add("fail");
	}
}

var hideNotification = function() {
	$("notification").classList.add("hidden");
}

var bindCommitSelectionLinks = function(el) {
	var links = el.getElementsByClassName("commit-link");
	for (var i = 0, n = links.length; i < n; ++i) {
		links[i].addEventListener("click", function(e) {
			e.preventDefault();
			selectCommit(this.dataset.commitId || this.innerHTML);
		}, false);
	}
};
