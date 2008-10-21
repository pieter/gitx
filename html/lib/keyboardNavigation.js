var scrollToCenter = function(element) {
    window.scrollTo(0, element.offsetTop);
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
	else if (key == 'c')
		Controller.copySource();
}

var changeHunk = function(next) {
	var hunks = document.getElementsByClassName("hunkheader");

	if (hunks.length == 0)
		return;

	var currentHunk = document.getElementById("CurrentHunk");
	var newHunk;

	var index = -1;
	for (; index < hunks.length; ++index) {
		if (hunks[index] == currentHunk)
			break;
	}

	if (currentHunk && index >= 0) {
		currentHunk.id = null;
		if (next)
			newHunk = hunks[index + 1];
		else
			newHunk = hunks[index - 1];
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