// for diffs shown in the PBDiffWindow

var showFile = function(message) {
	highlightDiff(message,$("diff"));
}

var setMessage = function(message) {
	$("message").style.display = "";
	$("message").innerHTML = message.escapeHTML();
	$("diff").style.display = "none";
}

