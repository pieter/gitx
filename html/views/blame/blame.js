var showFile = function(txt) {
	$("txt").style.display = "";
	$("txt").innerHTML="<pre>"+txt+"</pre>";
	SyntaxHighlighter.highlight();
	return;
}
