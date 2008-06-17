var highlightDiffs = function() {
	var diffs = document.getElementsByClassName("diffcode");
	$A(diffs).each(function(diff) {
		var content = diff.innerHTML;
		diff.innerHTML = "";

		var newContent = "";
		var lines = $A(content.split("\n"));

		var start = new Date();
		lines.each(function(l) {
			if (l.length > 100)
			l = l.substring(0, 100);

			l = l.gsub("\t", "  ");

			if (l.startsWith("+"))
				newContent += "<div class='addline'>" + l + "</div>";
			else if (l.startsWith("-"))
				newContent += "<div class='delline'>" + l + "</div>";
			else if (l.startsWith("@"))
				newContent += "<div class='meta'>" + l + "</div>";
			else
				newContent += l + "\n";
		});
		var duration = new Date() - start;
		diff.innerHTML = newContent;
	});
}