var showFileChanges = function(file, cached) {
	// New file?
	var diff = $("diff");

	if (file.status == 0)
	{
		var contents = file.unstagedChanges();
		if (contents)
			diff.innerHTML = contents.escapeHTML();
		else
			diff.innerHTML = "Could not display changes";

		diff.style.display= '';
		$('title').innerHTML = "New file: " + file.path;
	}  else {
		diff.style.display = 'none';
		if (cached)
			diff.innerHTML = file.cachedChangesAmend_(Controller.amend()).escapeHTML();
		else
			diff.innerHTML = file.unstagedChanges().escapeHTML();
		highlightDiffs();
		diff.style.display = '';
		$("title").innerHTML = "Changes for " + file.path;
	}
}
