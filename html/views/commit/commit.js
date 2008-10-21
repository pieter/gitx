var showNewFile = function(file)
{
	$('title').innerHTML = "New file: " + file.path;

	var contents = file.unstagedChanges();
	if (!contents) {
		notify("Can not display changes (Binary file?)", -1);
		return;
	}

	diff.innerHTML = contents.escapeHTML();
}

var showFileChanges = function(file, cached) {
	var diff = $("diff");
	diff.style.display = 'none';
	hideNotification();

	if (file.status == 0) // New file?
		return showNewFile(file);

	if (cached) {
		$("title").innerHTML = "Staged changes for " + file.path;
		diff.innerHTML = file.cachedChangesAmend_(Controller.amend()).escapeHTML();
	}
	else {
		$("title").innerHTML = "Unstaged changes for " + file.path;
		diff.innerHTML = file.unstagedChanges().escapeHTML();
	}

	highlightDiffs();
	diff.style.display = '';
}