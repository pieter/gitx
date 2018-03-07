var selectCommit = function(a) {
	window.Controller.selectCommit_(a);
	return false;
}

var showFile = function(html) {
	var el = $("log");
	el.style.display = "";
	el.innerHTML = html;
	bindCommitSelectionLinks(el);
	return;
}
