var commit;
var Commit = Class.create({
	initialize: function(obj) {
		this.raw = obj.details;

		var messageStart = this.raw.indexOf("\n\n") + 2;
		var diffStart = this.raw.indexOf("\ndiff ");
		this.header = this.raw.substring(0, messageStart);

		this.sha = this.header.match(/^commit ([0-9a-f]{40,40})/)[1];

		var match = this.header.match(/\nauthor (.*) <(.*@.*)> ([0-9].*)/);
		this.author_name = match[1];
		this.author_email = match[2];
		this.author_date = new Date(parseInt(match[3]) * 1000);

		match = this.header.match(/\ncommitter (.*) <(.*@.*)> ([0-9].*)/);
		this.committer_name = match[1];
		this.committer_email = match[2];
		this.committer_date = new Date(parseInt(match[3]) * 1000);

		this.parents = $A(this.header.match(/\nparent ([0-9a-f]{40,40})/g)).map(function(x) {
			return x.replace("\nparent ",""); 
		});

		this.message = this.raw.substring(messageStart, diffStart);
		this.diff = this.raw.substring(diffStart);
	},	
});

var selectCommit = function(a) {
	Controller.selectCommit_(a);
}

var showDiffs = function() {
	$("details").hide();
	$("details").innerHTML = commit.diff;
	highlightDiffs();
	$("details").show();
}

var doeHet = function() {
	commit = new Commit(CommitObject);

	$("commitID").innerHTML = commit.sha;
	$("authorID").innerHTML = commit.author_name + " &lt;<a href='mailto:" + commit.author_email + "'>" + commit.author_email + "</a>&gt;";
	$("date").innerHTML = commit.author_date;
	$("subjectID").innerHTML =CommitObject.subject;
	
	$A($("commit_header").rows).each(function(row) {
		if (row.innerHTML.match(/Parent:/))
			row.remove();
	});
	commit.parents.each(function(parent) {
		var new_row = $("commit_header").insertRow(-1);
		new_row.innerHTML = "<td class='property_name'>Parent:</td><td><a href='' onclick=\"selectCommit(this.innerHTML); return false;\">" + parent + "</a></td>";
	});

	$("message").innerHTML = commit.message.replace(/\n/g,"<br>");
	if (commit.diff.length < 10000) {
		showDiffs();
	} else {
		$("details").innerHTML = "<a class='showdiff' href='' onclick='showDiffs(); return false;'>This is a large commit. Click here to show the diff.</a>";
	}
}
