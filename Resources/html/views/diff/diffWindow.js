// for diffs shown in the PBDiffWindow

var showDiff = function(diff) {
	highlightDiff(diff, $("diff"));
};

var setMessage = function(message) {
	$("message").classList.remove("hidden");
	$("message").textContent = message;
	$("diff").style.display = "none";
};
