var showFile = function(html) {
	$("source").style.display = "";
	$("source").innerHTML="<pre class='first-line: 1;brush: objc'>"+html+"</pre>";
	
	SyntaxHighlighter.defaults['toolbar'] = false;
	SyntaxHighlighter.highlight();
	
	return;
}
