var showFile = function(txt, fileName) {
  $("source").style.display = "";
  var brush = "objc";
  if (fileName && fileName != '') {
    brush = fileName.substr(fileName.lastIndexOf('.') + 1);
  }
  $("source").innerHTML="<pre class='first-line: 1;brush: " + brush + "'>" + txt + "</pre>";

  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.highlight();

  return;
}

var test=function(txt) {
  SyntaxHighlighter.defaults['toolbar'] = false;
  SyntaxHighlighter.highlight();

  return;
}
