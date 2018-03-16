var showFile = function(html) {
	var el = $("txt");
	el.style.display = "";
	el.innerHTML = "<pre>" + html + "</pre>";
	bindCommitSelectionLinks(el);
	
	SyntaxHighlighter.defaults['toolbar'] = false;

	SyntaxHighlighter.highlight();
	return;
}

var selectCommit = function(a) {
	Controller.selectCommit_(a);
}
