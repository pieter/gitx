
// If we run from a Safari instance, we don't
// have a Controller object. Instead, we fake it by
// using the console
if (typeof Controller == 'undefined')
{
	Controller = console;
	Controller.log_ = console.log;
}

var highlightDiffs = function() {
	var start = new Date().getTime();
	var diffs = document.getElementsByClassName("diffcode");
	for (var diffn = 0; diffn < diffs.length; diffn++) {
		var diff = diffs[diffn];

		var content = diff.innerHTML.replace(/\t/g, "    ");;

		var line1 = "";
		var line2 = "";
		var diffContent = "";
		var lines = content.split('\n');

		var hunk_start_line_1 = -1;
		var hunk_start_line_2 = -1;

		var header = false;

		for (var lineno = 0; lineno < lines.length; lineno++) {
			var l = lines[lineno];

			var firstChar = l.charAt(0);

			if (header) {
				if (firstChar == "+" || firstChar == "-")
					continue;
			} else if (firstChar == "d") {
				header = true;
				line1 += '\n';
				line2 += '\n';
				diffContent += '<div class="fileHeader"><span class="fileline">' + l + '</span></div>';
				continue;
			}


			if (firstChar == "+") {
				// Highlight trailing whitespace
				if (m = l.match(/\s+$/))
				  l = l.replace(/\s+$/, "<span class='whitespace'>" + m + "</span>");

				line1 += "\n";
				line2 += ++hunk_start_line_2 + "\n";
				diffContent += "<div class='addline'>" + l + "</div>";
			}
			else if (firstChar == "-") {
				line1 += ++hunk_start_line_1 + "\n";
				line2 += "\n";
				diffContent += "<div class='delline'>" + l + "</div>";
			}
			else if (firstChar == "@")
			{
				header = false;
				if (m = l.match(/@@ \-([0-9]+),\d+ \+(\d+),\d+ @@/))
				{
					hunk_start_line_1 = parseInt(m[1]) - 1;
					hunk_start_line_2 = parseInt(m[2]) - 1;
				}
				line1 += "...\n";
				line2 += "...\n";
				diffContent += "<div class='hunkheader'>" + l + "</div>";
			}
			else if (firstChar == " ")
			{
				line1 += ++hunk_start_line_1 + "\n";
				line2 += ++hunk_start_line_2 + "\n";
				diffContent += l + "\n";
			}
		}


		// This takes about 7ms
		diff.innerHTML = "<table class='diff'><tr><td class='lineno'l><pre>" + line1 + "</pre></td>" +
		                  "<td class='lineno'l><pre>" + line2 + "</pre></td>" +
		                  "<td width='100%'><pre width='100%'>" + diffContent + "</pre></td></tr></table>";

	}
	// TODO: Replace this with a performance pref call
	if (false)
		Controller.log_("Total time:" + (new Date().getTime() - start));
}