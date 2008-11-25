// If we run from a Safari instance, we don't
// have a Controller object. Instead, we fake it by
// using the console
if (typeof Controller == 'undefined') {
	Controller = console;
	Controller.log_ = console.log;
}

var highlightDiff = function(diff, element) {
	var start = new Date().getTime();
	
	var content = diff.escapeHTML().replace(/\t/g, "    ");;
	
	var file_index = 0;

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
			++file_index;
			header = true;
			line1 += '\n';
			line2 += '\n';
			var match = l.match(/diff --git a\/(\S*)/);
			diffContent += '</div><div class="fileHeader" id="file_index_' + file_index + '">' + file_index + ' <span class="fileline">' + match[1] + '</span></div>';
			continue;
		}

		if (firstChar == "+") {
			// Highlight trailing whitespace
			if (m = l.match(/\s+$/))
				l = l.replace(/\s+$/, "<span class='whitespace'>" + m + "</span>");

			line1 += "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += "<div class='addline'>" + l + "</div>";
		} else if (firstChar == "-") {
			line1 += ++hunk_start_line_1 + "\n";
			line2 += "\n";
			diffContent += "<div class='delline'>" + l + "</div>";
		} else if (firstChar == "@") {
			header = false;
			if (m = l.match(/@@ \-([0-9]+),\d+ \+(\d+),\d+ @@/))
			{
				hunk_start_line_1 = parseInt(m[1]) - 1;
				hunk_start_line_2 = parseInt(m[2]) - 1;
			}
			line1 += "...\n";
			line2 += "...\n";
			diffContent += "<div class='hunkheader'>" + l + "</div>";
		} else if (firstChar == " ") {
			line1 += ++hunk_start_line_1 + "\n";
			line2 += ++hunk_start_line_2 + "\n";
			diffContent += l + "\n";
		}
	}

	// This takes about 7ms
	element.innerHTML = "<table class='diff'><tr><td class='lineno'l><pre>" + line1 + "</pre></td>" +
	                  "<td class='lineno'l><pre>" + line2 + "</pre></td>" +
	                  "<td width='100%'><pre width='100%'>" + diffContent + "</pre></td></tr></table>";

	// TODO: Replace this with a performance pref call
	if (false)
		Controller.log_("Total time:" + (new Date().getTime() - start));
}