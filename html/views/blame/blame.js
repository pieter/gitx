var showFile = function(txt) {
	$("txt").style.display = "";
	$("txt").innerHTML="<pre>"+txt+"</pre>";
	
	SyntaxHighlighter.defaults['toolbar'] = false;

	SyntaxHighlighter.highlight();
	return;
}
