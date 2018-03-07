var selectCommit = function(a) {
	window.Controller.selectCommit_(a);
	return false;
}

var showFile = function(html) {
	var el = $("log");
	el.classList.remove("hidden");
	el.innerHTML = html;
	bindCommitSelectionLinks(el);
	return;
}
