// If we run from a Safari instance, we don't
// have a Controller object. Instead, we fake it by
// using the console
if (typeof Controller == 'undefined') {
	Controller = console;
	Controller.log_ = console.log;
}

var highlightDiff = function(diff, element, callbacks) {
	if (!diff || diff == "")
		return;

	if (!callbacks)
		callbacks = {};
	var start = new Date().getTime();
	element.className = "diff"
	var content = diff.escapeHTML().replace(/\t/g, "    ");;
	
	var file_index = 0;

	var startname = "";
	var endname = "";
	var line1 = "";
	var line2 = "";
	var diffContent = "";
	var finalContent = "";
	var lines = content.split('\n');
	var binary = false;

	var hunk_start_line_1 = -1;
	var hunk_start_line_2 = -1;

	var header = false;

	var finishContent = function()
	{
		if (!file_index)
		{
			file_index++;
			return;
		}

		if (callbacks["newfile"])
			callbacks["newfile"](startname, endname, "file_index_" + (file_index - 1));

		var title = startname;
		if (endname == "/dev/null")
			title = startname;
		else if (startname == "/dev/null")
			title = endname;
		else if (startname != endname)
			title = startname + " renamed to " + endname;

		finalContent += '<div class="file" id="file_index_' + (file_index - 1) + '">' +
							'<div class="fileHeader">' + title + '</div>';

		if (!binary)  {
			finalContent +=		'<div class="diffContent">' +
								'<div class="lineno">' + line1 + "</div>" +
								'<div class="lineno">' + line2 + "</div>" +
								'<div class="lines">' + diffContent + "</div>" +
							'</div>';
		}
		else {
			if (callbacks["binaryFile"])
				finalContent += callbacks["binaryFile"](filename);
			else
				finalContent += "<div>Binary file differs</div>";
		}

		finalContent += '</div>';

		line1 = "";
		line2 = "";
		diffContent = "";
		file_index++;
		startname = "";
		endname = "";
	}
	for (var lineno = 0; lineno < lines.length; lineno++) {
		var l = lines[lineno];

		var firstChar = l.charAt(0);

		if (firstChar == "d" && l.charAt(1) == "i") {			// "diff", i.e. new file, we have to reset everything
			header = true;						// diff always starts with a header

			finishContent(); // Finish last file

			binary = false;
			continue;
		}

		if (header) {
			if (firstChar == "-") {
				if (match = l.match(/^--- (a\/)?(.*)$/))
					startname = match[2];
				continue;
			}
			if (firstChar == "+") {
				if (match = l.match(/^\+\+\+ (b\/)?(.*)$/))
					endname = match[2];
				continue;
			}
			// If it is a complete rename, we don't know the name yet
			// We can figure this out from the 'rename from.. rename to.. thing
			if (firstChar == 'r')
			{
				if (match = l.match(/^rename (from|to) (.*)$/))
				{
					if (match[1] == "from")
						startname = match[2];
					else
						endname = match[2];
				}
				continue;
			}
			if (firstChar == "B") // "Binary files"
			{
				binary = true;
				Controller.log_("Binary file");
			}

			// Finish the header
			if (firstChar == "@")
				header = false;
			else
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

	finishContent();

	// This takes about 7ms
	element.innerHTML = finalContent;

	// TODO: Replace this with a performance pref call
	if (false)
		Controller.log_("Total time:" + (new Date().getTime() - start));
}
