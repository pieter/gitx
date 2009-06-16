var showNewFile = function(file)
{
	setTitle("New file: " + file.path);

	var contents = IndexController.unstagedChangesForFile_(file);
	if (!contents) {
		notify("Can not display changes (Binary file?)", -1);
		diff.innerHTML = "";
		return;
	}

	diff.innerHTML = "<pre>" + contents.escapeHTML() + "</pre>";
	diff.style.display = '';
}

var hideState = function() {
	$("state").style.display = "none";
}

var setState = function(state) {
	setTitle(state);
	hideNotification();
	$("state").style.display = "";
	$("diff").style.display = "none";
	$("state").innerHTML = state.escapeHTML();
}

var setTitle = function(status) {
	$("status").innerHTML = status;
	$("contextSize").style.display = "none";
	$("contextTitle").style.display = "none";
}

var displayContext = function() {
	$("contextSize").style.display = "";
	$("contextTitle").style.display = "";
}

var showFileChanges = function(file, cached) {
	if (!file) {
		setState("No file selected");
		return;
	}

	hideNotification();
	hideState();

	$("contextSize").oninput = function(element) {
		Controller.setContextSize_($("contextSize").value);
	}

	if (file.status == 0) // New file?
		return showNewFile(file);

	var changes;
	if (cached) {
		setTitle("Staged changes for " + file.path);
		displayContext();
		changes = IndexController.stagedChangesForFile_(file);
	}
	else {
		setTitle("Unstaged changes for " + file.path);
		displayContext();
		changes = IndexController.unstagedChangesForFile_(file);
	}

	if (changes == "") {
		notify("This file has no more changes", 1);
		return;
	}

	displayDiff(changes, cached);
}

var diffHeader;
var originalDiff;

var displayDiff = function(diff, cached)
{
	diffHeader = diff.split("\n").slice(0,4).join("\n");
	originalDiff = diff;

	$("diff").style.display = "";
	highlightDiff(diff, $("diff"));
	hunkHeaders = $("diff").getElementsByClassName("hunkheader");

	for (i = 0; i < hunkHeaders.length; ++i) {
		var header = hunkHeaders[i];
		if (cached)
			header.innerHTML = "<a href='#' class='hunkbutton' onclick='addHunk(this, true); return false'>Unstage</a>" + header.innerHTML;
		else {
			header.innerHTML = "<a href='#' class='hunkbutton' onclick='addHunk(this, false); return false'>Stage</a>" + header.innerHTML;
			header.innerHTML = "<a href='#' class='hunkbutton' onclick='discardHunk(this, event); return false'>Discard</a>" + header.innerHTML;
		}
	}
}

var getNextText = function(element)
{
	// gets the next DOM sibling which has type "text" (e.g. our hunk-header)
	next = element;
	while (next.nodeType != 3) {
		next = next.nextSibling;
	}
	return next;
}


/* Get the original hunk lines attached to the given hunk header */
var getLines = function (hunkHeader)
{
	var start = originalDiff.indexOf(hunkHeader);
	var end = originalDiff.indexOf("\n@@", start + 1);
	var end2 = originalDiff.indexOf("\ndiff", start + 1);
	if (end2 < end && end2 > 0)
		end = end2;
	if (end == -1)
		end = originalDiff.length;
	var hunkText = originalDiff.substring(start, end)+'\n';
	return hunkText;
}

/* Get the full hunk test, including diff top header */
var getFullHunk = function(hunk)
{
	hunk = getNextText(hunk);
	var hunkHeader = hunk.data.split("\n")[0];
	var m;
	if (m = hunkHeader.match(/@@.*@@/))
		hunkHeader = m;
	return diffHeader + "\n" + getLines(hunkHeader);
}

var addHunkText = function(hunkText, reverse)
{
	//window.console.log((reverse?"Removing":"Adding")+" hunk: \n\t"+hunkText);
	if (Controller.stageHunk_reverse_)
		Controller.stageHunk_reverse_(hunkText, reverse);
	else
		alert(hunkText);
}

/* Add the hunk located below the current element */
var addHunk = function(hunk, reverse)
{
	addHunkText(getFullHunk(hunk),reverse);
}

var discardHunk = function(hunk, event)
{
	var hunkText = getHunkText(hunk);

	if (Controller.discardHunk_altKey_) {
		Controller.discardHunk_altKey_(hunkText, event.altKey == true);
	} else {
		alert(hunkText);
	}
}
