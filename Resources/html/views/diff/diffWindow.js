// for diffs shown in the PBDiffWindow

var setMessage = function(message) {
	$("message").style.display = "";
	$("message").textContent = message;
	$("diff").style.display = "none";
};
