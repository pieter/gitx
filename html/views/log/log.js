var selectCommit = function(a) {
	window.Controler.selectCommit_(a);
	return false;
}

var showFile = function(txt) {
	$("log").style.display = "";
	$("log").innerHTML=txt;
	return;
}
