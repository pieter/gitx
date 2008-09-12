var highlightDiffs = function() {
	var diffs = document.getElementsByClassName("diffcode");
	$A(diffs).each(function(diff) {
		var content = diff.innerHTML;
		diff.innerHTML = "";

		var newContent = "";
		var lines = $A(content.split("\n"));

		var start = new Date();
		lines.each(function(l) {
			if (l.length > 250)
			l = l.substring(0, 250);

			l = l.gsub("\t", "  ");

			if (l.startsWith("diff")) {
				newContent += "<div class='fileHeader'><div class='fileline'>" + l + "</div></div>";
				return;
			}
			if (l.startsWith("---")) {
				newContent += "<div class='oldfile'>" + l + "</div></div>";
				return;
			}

			if (l.startsWith("+++")) {
				newContent += "<div class='newfile'>" + l + "</div></div>";
				return;
			}

			if (l.startsWith("+"))
				newContent += "<div class='addline'>" + l + "</div>";
			else if (l.startsWith("-"))
				newContent += "<div class='delline'>" + l + "</div>";
			else if (l.startsWith("@"))
				newContent += "<div class='hunkheader'>" + l + "</div>";
			else
				newContent += l + "\n";
		});
		var duration = new Date() - start;
		diff.innerHTML = newContent;
	});
}