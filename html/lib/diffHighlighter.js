// If we run from a Safari instance, we don't
// have a Controller object. Instead, we fake it by
// using the console
if (typeof Controller == 'undefined') {
	Controller = console;
	Controller.log_ = console.log;
}

var highlightDiff = function(diff, element, callbacks) {
	if (!callbacks)
		callbacks = {};
	var start = new Date().getTime();
	element.className = "diff"
	var content = diff.escapeHTML().replace(/\t/g, "    ");;
	
	var file_index = 0;

	var filename = "";
	var line1 = "";
	var line2 = "";
	var diffContent = "";
	var finalContent = "";
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
		} else if (firstChar == "d") { // New file, we have to reset everything
			header = true;

			if (file_index++) // Finish last file
			{
				finalContent += '<div class="file" id="file_index_' + (file_index - 2) + '">' +
									'<div class="fileHeader">' + filename + '</div>' +
									'<div class="diffContent">' +
										'<div class="lineno">' + line1 + "</div>" +
										'<div class="lineno">' + line2 + "</div>" +
										'<div class="lines">' + diffContent + "</div>" +
									'</div>' +
								'</div>';
				line1 = "";
				line2 = "";
				diffContent = "";
			}

			if(match = l.match(/diff --git a\/(\S*)/)) {
				filename = match[1];
				if (callbacks["newfile"])
					callbacks["newfile"](filename, "file_index_" + (file_index - 1));
			}
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
			if (header) {
				header = false;
			}

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

	finalContent += '<div class="file" id="file_index_' + (file_index - 1) + '">' +
						'<div class="fileHeader">' + filename + '</div>' +
						'<div class="diffContent">' +
							'<div class="lineno">' + line1 + "</div>" +
							'<div class="lineno">' + line2 + "</div>" +
							'<div class="lines">' + diffContent + "</div>" +
						'</div>' +
					'</div>';

	// This takes about 7ms
	element.innerHTML = finalContent;

	// TODO: Replace this with a performance pref call
	if (false)
		Controller.log_("Total time:" + (new Date().getTime() - start));
}