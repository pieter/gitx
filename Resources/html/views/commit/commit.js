/* Commit: Interface for selecting, staging, discarding, and unstaging
   hunks, individual lines, or ranges of lines.  */

var contextLines = 0;

var showNewFile = function(file)
{
	setTitle("New file: " + file.path);
	diff.innerHTML = "";

	var contents = Index.diffForFile_staged_contextLines_(file, false, contextLines);
	if (!contents) {
		notify("Can not display changes (Binary file?)", -1);
		return;
	}

	var pre = document.createElement("pre");
	pre.textContent = contents;
	diff.appendChild(pre);
	diff.style.display = '';
}

var hideState = function() {
	$("state").style.display = "none";
}

var setState = function(state) {
	setTitle(state);
	hideNotification();
	$("state").style.display = "";
	$("diff").style.display = "none";
	$("state").textContent = state;
}

var setTitle = function(status) {
	$("status").textContent = status;
	$("contextSize").style.display = "none";
	$("contextTitle").style.display = "none";
}

var displayContext = function() {
	$("contextSize").style.display = "";
	$("contextTitle").style.display = "";
	contextLines = $("contextSize").value;
}

var showFileChanges = function(file, cached) {
	if (!file) {
		setState("No file selected");
		return;
	}

	hideNotification();
	hideState();

	$("contextSize").oninput = function(element) {
		contextLines = $("contextSize").value;
		Controller.refresh();
	}

	if (file.status == 0) // New file?
		return showNewFile(file);

	setTitle((cached ? "Staged" : "Unstaged") + " changes for " + file.path);
	displayContext();
	var changes = Index.diffForFile_staged_contextLines_(file, cached, contextLines);
	

	if (changes == "") {
		notify("This file has no more changes", 1);
		return;
	}

	displayDiff(changes, cached);
}

var findParentElementByTag = function (el, tagName)
{
	tagName = tagName.toUpperCase();
	while (el && el.tagName != tagName && el.parentNode) {
		el = el.parentNode;
	}
	return el;
}

/* Set the event handlers for mouse clicks/drags */
var setSelectHandlers = function()
{
	document.onmousedown = function(event) {
		if(event.which != 1) return false;
		deselect();
		currentSelection = false;
	}
	document.onselectstart = function () {return false;}; /* prevent normal text selection */

	var list = document.getElementsByClassName("lines");

	document.onmouseup = function(event) {
		// Handle button releases outside of lines list
		for (i = 0; i < list.length; ++i) {
			file = list[i];
			file.onmouseover = null;
			file.onmouseup = null;
		}
	}

	for (i = 0; i < list.length; ++i) {
		var file = list[i];
		file.ondblclick = function (event) {
			var target = findParentElementByTag(event.target, "div");
			var file = target.parentNode;
			if (file.id = "selected")
				file = file.parentNode;
			var start = target;
			var elemClasses = start.classList;
			if (!(elemClasses.contains("addline") || elemClasses.contains("delline")))
				return false;
			deselect();
			var bounds = findsubhunk(start);
			showSelection(file,bounds[0],bounds[1],true);
			return false;
		};

		file.onmousedown = function(event) {
			if (event.which != 1)
				return false;
			var elemClasses = event.target.classList;
			event.stopPropagation();
			if (elemClasses.contains("hunkheader") || elemClasses.contains("hunkbutton"))
				return false;

			var target = findParentElementByTag(event.target, "div");
			var file = target.parentNode;
			if (file.id && file.id == "selected")
				file = file.parentNode;

			file.onmouseup = function(event) {
				file.onmouseover = null;
				file.onmouseup = null;
				event.stopPropagation();
				return false;
			};

			if (event.shiftKey && currentSelection) { // Extend selection
				var index = parseInt(target.getAttribute("index"));
				var min = parseInt(currentSelection.bounds[0].getAttribute("index"));
				var max = parseInt(currentSelection.bounds[1].getAttribute("index"));
				var ender = 1;
				if(min > max) {
					var tmp = min; min = max; max = tmp;
					ender = 0;
				}

				if (index < min)
					showSelection(file,currentSelection.bounds[ender],target);
				else if (index > max)
					showSelection(file,currentSelection.bounds[1-ender],target);
				else
					showSelection(file,currentSelection.bounds[0],target);
				return false;
			}

			var srcElement = findParentElementByTag(event.target, "div");
			file.onmouseover = function(event2) {
                // not quite the right target, but we adjust
				var target2 = findParentElementByTag(event2.target, "div");
                if (target2.getAttribute("index") == null) {
                    // hit testing hit a button -> we need to find the sibling which is under
                    var hit = function(elem) {
                        var top = elem.offsetTop;
                        var bottom = top + elem.offsetHeight;
                        return  top < event2.y &&
                                bottom >= event2.y;
                    }
                    while (target2 && !hit(target2)) {
                        target2 = target2.nextSibling
                    }
                }
                if (target2)
                    showSelection(file, srcElement, target2);
				return false;
			};
			showSelection(file, srcElement, srcElement);
			return false;
		}
	}
}

var diffHeader;
var originalDiff;
var originalCached;

var displayDiff = function(diff, cached)
{
	diffHeader = diff.split("\n").slice(0,4).join("\n");
	originalDiff = diff;
	originalCached = cached;

	$("diff").style.display = "";
	highlightDiff(diff, $("diff"));
	hunkHeaders = $("diff").getElementsByClassName("hunkheader");

	for (i = 0; i < hunkHeaders.length; ++i) {
		var header = hunkHeaders[i];
		if (cached) {
			header.innerHTML = "<a href='#' class='hunkbutton unstage-button'>Unstage</a>" + header.innerHTML;
			header.getElementsByClassName('unstage-button')[0].addEventListener("click", function(e) {
				e.preventDefault();
				addHunk(this, true);
			});
		}
		else {
			header.innerHTML =
				"<a href='#' class='hunkbutton add-hunk-button'>Stage</a>" +
				"<a href='#' class='hunkbutton discard-hunk-button'>Discard</a>" +
				header.innerHTML;
			header.getElementsByClassName("add-hunk-button")[0].addEventListener("click", function(e) {
				e.preventDefault();
				addHunk(this, false);
			});
			header.getElementsByClassName("discard-hunk-button")[0].addEventListener("click", function(e) {
				e.preventDefault();
				discardHunk(this, event);
			});
		}
	}
	setSelectHandlers();
}

var getNextText = function(element)
{
	// gets the next DOM sibling which has type "text" (e.g. our hunk-header)
	next = element;
	while (next.nodeType != 3) {
		next = next.nextSibling;
	}
	return next;
}


/* Get the original hunk lines attached to the given hunk header */
var getLines = function (hunkHeader)
{
	var start = originalDiff.indexOf(hunkHeader);
	var end = originalDiff.indexOf("\n@@", start + 1);
	var end2 = originalDiff.indexOf("\ndiff", start + 1);
	if (end2 < end && end2 > 0)
		end = end2;
	if (end == -1)
		end = originalDiff.length;
	return originalDiff.substring(start, end)+'\n';
}

/* Get the full hunk test, including diff top header */
var getFullHunk = function(hunk)
{
	hunk = getNextText(hunk);
	var hunkHeader = hunk.data.split("\n")[0];
	var m;
	if (m = hunkHeader.match(/@@.*@@/))
		hunkHeader = m;
	return diffHeader + "\n" + getLines(hunkHeader);
}

var addHunkText = function(hunkText, reverse)
{
	//window.console.log((reverse?"Removing":"Adding")+" hunk: \n\t"+hunkText);
	if (Controller.stageHunk_reverse_)
		Controller.stageHunk_reverse_(hunkText, reverse);
	else
		alert(hunkText);
}

/* Add the hunk located below the current element */
var addHunk = function(hunk, reverse)
{
	addHunkText(getFullHunk(hunk),reverse);
}

var discardHunk = function(hunk, event)
{
	var hunkText = getFullHunk(hunk);

	if (Controller.discardHunk_altKey_) {
		Controller.discardHunk_altKey_(hunkText, event.altKey == true);
	} else {
		alert(hunkText);
	}
}

/* Find all contiguous add/del lines. A quick way to select "just this
 * chunk". */
var findsubhunk = function(start) {
	var findBound = function(direction) {
		var element=start;
		for (var next = element[direction]; next; next = next[direction]) {
			var elemClasses = next.classList;
			if (elemClasses.contains("hunkheader") || elemClasses.contains("noopline"))
				break;
			element=next;
		}
		return element;
	}
	return [findBound("previousSibling"), findBound("nextSibling")];
}

/* Remove existing selection */
var deselect = function() {
	var selection = document.getElementById("selected");
	if (selection) {
		while (selection.childNodes[1])
			selection.parentNode.insertBefore(selection.childNodes[1], selection);
		selection.parentNode.removeChild(selection);
	}
}

/* Stage individual selected lines.  Note that for staging, unselected
 * delete lines are context, and v.v. for unstaging. */
var stageLines = function(reverse) {
	var selection = document.getElementById("selected");
	if(!selection) return false;
	currentSelection = false;
	var hunkHeader = false;
	var preselect = 0;

	for(var next = selection.previousSibling; next; next = next.previousSibling) {
		if (next.classList.contains("hunkheader")) {
			hunkHeader = next.lastChild.data;
			break;
		}
		preselect++;
	}

	if (!hunkHeader) return false;

	var sel_len = selection.children.length-1;
	var subhunkText = getLines(hunkHeader);
	var lines = subhunkText.split('\n');
	lines.shift();  // Trim old hunk header (we'll compute our own)
	if (lines[lines.length-1] == "") lines.pop(); // Omit final newline

	var m;
	if (m = hunkHeader.match(/@@ \-(\d+)(,\d+)? \+(\d+)(,\d+)? @@/)) {
		var start_old = parseInt(m[1]);
		var start_new = parseInt(m[3]);
	} else return false;

	var patch = "", count = [0,0];
	for (var i = 0; i < lines.length; i++) {
		var l = lines[i];
		var firstChar = l.charAt(0);
		var isSelectedLine = (i >= preselect && i < preselect+sel_len);
		var isMarkerLine = (firstChar == '\\');
		if (isMarkerLine && isSelectedLine)
			sel_len++; // We cheat so our isSelectedLine test isn't confused by missing lines

		if (!isSelectedLine) {    // Before/after select
			if(firstChar == (reverse?'+':"-"))   // It's context now, make it so!
				l = ' '+l.substr(1);
			if(firstChar != (reverse?'-':"+")) { // Skip unincluded changes
				patch += l+"\n";
				if (!isMarkerLine) {
					// Missing-newlines don't count
					count[0]++; count[1]++;
				}
			}
		} else {                                      // In the selection
			if (firstChar == '-') {
				count[0]++;
			} else if (firstChar == '+') {
				count[1]++;
			} else if (!isMarkerLine) {
				count[0]++; count[1]++;
			}
			patch += l+"\n";
		}
	}
	patch = diffHeader + '\n' + "@@ -" + start_old.toString() + "," + count[0].toString() +
		" +" + start_new.toString() + "," + count[1].toString() + " @@\n"+patch;

	addHunkText(patch,reverse);
}

/* Compute the selection before actually making it.  Return as object
 * with 2-element array "bounds", and "good", which indicates if the
 * selection contains add/del lines. */
var computeSelection = function(list, from, to)
{
	var startIndex = parseInt(from.getAttribute("index"));
    var toIndex = to.getAttribute("index");
    if (toIndex === null) {
        to = to.nextSibling;// or the next one
        toIndex = to.getAttribute("index");
    }
    var endIndex = parseInt(toIndex);
	if (startIndex == -1 || endIndex == -1) {
		return false;
	}

	var up = (startIndex < endIndex);
	var nextelem = up?"nextSibling":"previousSibling";

	var insel = from.parentNode && from.parentNode.id == "selected";
	var good = false;
	for(var elem = last = from;;elem = elem[nextelem]) {
		if(!insel && elem.id && elem.id == "selected") {
			// Descend into selection div
			elem = up?elem.childNodes[1]:elem.lastChild;
			insel = true;
		}

		var elemClasses = elem.classList;
		if (elem.className) {
			if (elemClasses.contains("hunkheader")) {
				elem = last;
				break; // Stay inside this hunk
			}
			if (!good && (elemClasses.contains("addline") || elemClasses.contains("delline")))
				good = true; // A good selection
		}
		if (elem == to) break;

		if (insel) {
			if (up?
			    elem == elem.parentNode.lastChild:
			    elem == elem.parentNode.childNodes[1]) {
				// Come up out of selection div
				last = elem;
				insel = false;
				elem = elem.parentNode;
				continue;
			}
		}
		last = elem;
	}
	to = elem;
	return {bounds:[from,to],good:good};
}


var currentSelection = false;

/* Highlight the selection (if it is new) 

   If trust is set, it is assumed that the selection is pre-computed,
   and it is not recomputed.  Trust also assumes deselection has
   already occurred
*/
var showSelection = function(file, from, to, trust)
{
	if(trust)  // No need to compute bounds.
		var sel = {bounds:[from,to],good:true};
	else 
		var sel = computeSelection(file,from,to);
        
	if (!sel) {
		currentSelection = false;
		return;
	}

	if(currentSelection &&
	   currentSelection.bounds[0] == sel.bounds[0] &&
	   currentSelection.bounds[1] == sel.bounds[1] &&
	   currentSelection.good == sel.good) {
		return; // Same selection
	} else {
		currentSelection = sel;
	}

	if(!trust) deselect();

	var beg = parseInt(sel.bounds[0].getAttribute("index"));
	var end = parseInt(sel.bounds[1].getAttribute("index"));

	if (beg > end) { 
		var tmp = beg; 
		beg = end; 
		end = tmp; 
	} 

	var elementList = [];
	for (var i = beg; i <= end; ++i) 
		elementList.push(from.parentNode.childNodes[i]); 
	
	var selection = document.createElement("div");
	selection.setAttribute("id", "selected");

	var button = document.createElement('a');
	button.setAttribute("href","#");
	button.appendChild(document.createTextNode(
				   (originalCached?"Uns":"S")+"tage"));
	button.setAttribute("class","hunkbutton");
	button.setAttribute("id","stagelines");
	
	var copy_button = document.createElement('a');
	copy_button.setAttribute("href","#");
	copy_button.appendChild(document.createTextNode("Copy"));
	copy_button.setAttribute("class","hunkbutton");
	copy_button.setAttribute("id","copylines");
	
	var buttons_div = document.createElement('div');
	buttons_div.appendChild(button);
	buttons_div.appendChild(copy_button);

	if (sel.good) {
		button.addEventListener("click", function(e) {
			e.preventDefault();
			stageLines(originalCached);
		});
		copy_button.addEventListener("click", function(e) {
			e.preventDefault();
			copy();
		});
	} else {
		button.setAttribute("class","disabled");
		copy_button.setAttribute("class","disabled");
	}
	selection.appendChild(buttons_div);

	file.insertBefore(selection, from);
	for (i = 0; i < elementList.length; i++)
		selection.appendChild(elementList[i]);

	// Drag-selecting does not select the WebView, so make sure
	// it's selected so that menu items work.
	Controller.makeWebViewFirstResponder();
}

var copy = function()
{
	var selection = document.getElementById("selected");
	if(!selection) return false;
	var selectedText = "";
	for (var i = 0, n = selection.childNodes.length; i < n; ++i) {
		var line = selection.childNodes[i];
		if (line.getAttribute("index") !== null) {
			selectedText += line.innerText;
			selectedText += "\n";
		}
	}
	Controller.copy_(selectedText);
}


