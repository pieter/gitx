var EMPTY_SIDE = "<span class='lineno'> </span><span class='lineno'> </span>\n";
var highlightDiffs = function() {
	var diffs = document.getElementsByClassName("diffcode");
	$A(diffs).each(function(diff) {
		var content = diff.innerHTML.strip();
		diff.innerHTML = "";

		var line1 = "";
		var line2 = "";
		var diffContent = "";
		var lines = $A(content.split("\n"));

		var hunk_start_line_1 = -1;
		var hunk_start_line_2 = -1;

		var start = new Date();
		lines.each(function(l) {
			if (l.length > 250)
			l = l.substring(0, 250);

			l = l.gsub("\t", "  ");

			if (l.startsWith("diff")) {
				line1 += "\n";
				line2 += "\n";
				diffContent += "<div class='fileHeader'><span class='fileline'>" + l + "</span></div>";
				return;
			}
			if (l.startsWith("---")) {
				return;
				line1 += "\n";
				line2 += "\n";
				diffContent += "<div class='oldfile'>" + l + "</div></div>";
				return;
			}

			if (l.startsWith("+++")) {
				return;
				line1 += "\n";
				line2 += "\n";
				diffContent += "<div class='newfile'>" + l + "</div></div>";
				return;
			}

			if (l.startsWith("+")) {
				line1 += "\n";
				line2 += ++hunk_start_line_2 + "\n";
				diffContent += "<div class='addline'>" + l + "</div>";
			}
			else if (l.startsWith("-")) {
				line1 += ++hunk_start_line_1 + "\n";
				line2 += "\n";
				diffContent += "<div class='delline'>" + l + "</div>";
			}
			else if (l.startsWith("@"))
			{
				if (m = l.match(/@@ \-([0-9]+),\d+ \+(\d+),\d+ @@/))
				{
					hunk_start_line_1 = parseInt(m[1]) - 1;
					hunk_start_line_2 = parseInt(m[2]) - 1;
				}
				line1 += "...\n";
				line2 += "...\n";
				diffContent += "<div class='hunkheader'>" + l + "</div>";
			}
			else if (l.startsWith(" "))
			{
				line1 += ++hunk_start_line_1 + "\n";
				line2 += ++hunk_start_line_2 + "\n";
				diffContent += l + "\n";
			}
		});
		var duration = new Date() - start;
		var new_content = "<table class='diff'><tr><td class='lineno'l><pre>" + line1 + "</pre></td>";
		new_content += "<td class='lineno'l><pre>" + line2 + "</pre></td>";
		new_content +=  "<td width='100%'><pre width='100%'>" + diffContent + "</pre></td></tr></table>";
		diff.innerHTML = new_content;
	});
}