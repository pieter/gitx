var commit;
var Commit = function(obj) {
	this.raw = obj.details;
	this.refs = obj.refs;
	this.object = obj;

	var diffStart = this.raw.indexOf("\ndiff ");
	var messageStart = this.raw.indexOf("\n\n") + 2;

	if (diffStart > 0) {
		this.message = this.raw.substring(messageStart, diffStart).replace(/^    /gm, "").escapeHTML();
		this.diff = this.raw.substring(diffStart);
	} else {
		this.message = this.raw.substring(messageStart).replace(/^    /gm, "").escapeHTML();
		this.diff = "";
	}
	this.header = this.raw.substring(0, messageStart);

	this.sha = this.header.match(/^commit ([0-9a-f]{40,40})/)[1];

	var match = this.header.match(/\nauthor (.*) <(.*@.*)> ([0-9].*)/);
	this.author_name = match[1];
	if (!(match[2].match(/@[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/)))
		this.author_email = match[2];

	this.author_date = new Date(parseInt(match[3]) * 1000);

	match = this.header.match(/\ncommitter (.*) <(.*@.*)> ([0-9].*)/);
	this.committer_name = match[1];
	this.committer_email = match[2];
	this.committer_date = new Date(parseInt(match[3]) * 1000);

	this.parents = obj.parents;

	this.reloadRefs = function() {
		this.refs = CommitObject.refs;
	}
};

var notify = function(text, state) {
	var n = $("notification");
	n.style.display = "";
	$("notification_message").innerHTML = text;

	// Change color
	if (!state) { // Busy
		$("spinner").style.display = "";
		n.setAttribute("class", "");
	}
	else if (state == 1) { // Success
		$("spinner").style.display = "none";
		n.setAttribute("class", "success");
	} else if (state == -1) {// Fail
		$("spinner").style.display = "none";
		n.setAttribute("class", "fail");
	}
}

var gistie = function() {
	notify("Uploading code to Gistie..", 0);

	parameters = {
		"file_ext[gistfile1]":      "patch",
		"file_name[gistfile1]":     commit.object.subject.replace(/[^a-zA-Z0-9]/g, "-") + ".patch",
		"file_contents[gistfile1]": commit.object.patch(),
	};

	// TODO: Replace true with private preference
	token = Controller.getConfig_("github.token");
	login = Controller.getConfig_("github.user");
	if (token && login) {
		parameters.login = login;
		parameters.token = token;
	} else {
		parameters.private = true;
	}

	var params = [];
	for (var name in parameters)
		params.push(encodeURIComponent(name) + "=" + encodeURIComponent(parameters[name]));
	params = params.join("&");

	var t = new XMLHttpRequest();
	t.onreadystatechange = function() {
		if (t.readyState == 4 && t.status >= 200 && t.status < 300) {
			if (m = t.responseText.match(/gist: ([a-f0-9]+)/))
				notify("Code uploaded to gistie <a target='_new' href='http://gist.github.com/" + m[1] + "'>#" + m[1] + "</a>", 1);
			else {
				notify("Pasting to Gistie failed :(.", -1);
				Controller.log_(t.responseText);
			}
		}
	}

	t.open('POST', "http://gist.github.com/gists");
	t.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
	t.setRequestHeader('Accept', 'text/javascript, text/html, application/xml, text/xml, */*');
	t.setRequestHeader('Content-type', 'application/x-www-form-urlencoded;charset=UTF-8');

	try {
		t.send(params);
	} catch(e) {
		notify("Pasting to Gistie failed: " + e, -1);
	}
}

var setGravatar = function(email, image) {
	if (Controller && !Controller.isReachable_("www.gravatar.com"))
		return;

	if (!email) {
		$("gravatar").src = "http://www.gravatar.com/avatar/?d=wavatar&s=60";
		return;
	}

	$("gravatar").src = "http://www.gravatar.com/avatar/" +
		hex_md5(commit.author_email) + "?d=wavatar&s=60";
}

var selectCommit = function(a) {
	Controller.selectCommit_(a);
}

var showDiffs = function() {
	var details = $("details");
	details.style.display = "none";
	details.innerHTML = commit.diff.escapeHTML();
	highlightDiffs();
	details.style.display = "";
}

var reload = function() {
	$("notification").style.display = "none";
	commit.refs = null;
	showRefs();
	commit.reloadRefs();
	showRefs();
}

var showRefs = function() {
	var refs = $("refs");
	if (commit.refs) {
		refs.parentNode.style.display = "";
		refs.innerHTML = "";
		for (var i = 0; i < commit.refs.length; i++) {
			var ref = commit.refs[i], curBranch = "";
			refs.innerHTML += '<span class="refs ' + ref.type()  + (CurrentBranch == ref.ref ? ' currentBranch' : '') + '">' + ref.shortName() + '</span>';
		}
	} else
		refs.parentNode.style.display = "none";
}

var loadCommit = function() {
	commit = new Commit(CommitObject);
	$("notification").style.display = "none";

	$("commitID").innerHTML = commit.sha;

	if (commit.author_email)
		$("authorID").innerHTML = commit.author_name + " &lt;<a href='mailto:" + commit.author_email + "'>" + commit.author_email + "</a>&gt;";
	else
		$("authorID").innerHTML = commit.author_name;

	$("date").innerHTML = commit.author_date;
	$("subjectID").innerHTML =CommitObject.subject.escapeHTML();

	var commitHeader = $("commit_header");
	for (var i = 0; i < commitHeader.rows.length; i++) {
		var row = commitHeader.rows[i];
		if (row.innerHTML.match(/Parent:/))
			row.parentNode.removeChild(row);
	}

	for (var i = 0; i < commit.parents; i++) {
		var parent = commit.parents[i], newRow = commitHeader.insertRow(-1);
		new_row.innerHTML = "<td class='property_name'>Parent:</td><td><a href='' onclick=\"selectCommit(this.innerHTML); return false;\">" + parent + "</a></td>";
	}

	showRefs();

	$("message").innerHTML = commit.message.replace(/\n/g,"<br>");

	if (commit.diff.length < 200000) {
		showDiffs();
	} else {
		$("details").innerHTML = "<a class='showdiff' href='' onclick='showDiffs(); return false;'>This is a large commit. Click here or press 'v' to view.</a>";
	}

	setGravatar(commit.author_email, $("gravatar"));

	scroll(0, 0);
}
