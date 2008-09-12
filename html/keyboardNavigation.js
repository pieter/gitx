var scrollToCenter = function(element) {
	var pos = element.cumulativeOffset();
    window.scrollTo(pos[0], pos[1] - 100);
}

var handleKeys = function(event) {
	if (event.altKey || event.ctrlKey || event.metaKey || event.shiftKey)
		return;
	if (event.keyCode == 74)
		return changeHunk(true);
	else if (event.keyCode == 75)
		return changeHunk(false);
	else if (event.keyCode == 86) {// 'v'
		showDiffs();
		return false;
	}
	return true;
}

var handleKeyFromCocoa = function(key) {
	if (key == 'j')
		changeHunk(true);
	else if (key == 'k')
		changeHunk(false);
	else if (key == 'v')
		showDiffs();
}

var changeHunk = function(next) {
	var hunks = $A(document.getElementsByClassName("hunkheader"));
	if (hunks.length == 0)
		return;

	var currentHunk = document.getElementById("CurrentHunk");
	var newHunk;

	if (currentHunk && hunks.indexOf(currentHunk) >= 0) {
		currentHunk.id = null;
		if (next)
			newHunk = hunks[hunks.indexOf(currentHunk) + 1];
		else
			newHunk = hunks[hunks.indexOf(currentHunk) - 1];
	}
	if (!newHunk)
		newHunk = hunks[0];

	newHunk.id = 'CurrentHunk';
	scrollToCenter(newHunk);
	return false;
}

document.onkeydown = function(event) {
	return handleKeys(event);
};