var Commit = Class.create({
	initialize: function(obj) {
		this.raw = obj.details();
		this.sha = this.raw.match(/^commit ([0-9a-f]{40,40})/)[1];

		var match = this.raw.match(/\nauthor (.*) <(.*@.*)> ([0-9].*)/);
		this.author_name = match[1];
		this.author_email = match[2];
		this.author_date = new Date(parseInt(match[3]) * 1000);

		match = this.raw.match(/\ncommitter (.*) <(.*@.*)> ([0-9].*)/);
		this.committer_name = match[1];
		this.committer_email = match[2];
		this.committer_date = new Date(parseInt(match[3]) * 1000);

		this.parents = $A(this.raw.match(/\nparent ([0-9a-f]{40,40})/g)).map(function(x) {
			return x.replace("\nparent ",""); 
		});
	},	
});

var doeHet = function() {
	var commit = new Commit(CommitObject);
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
		new_row.innerHTML = "<td class='property_name'>Parent:</td><td><a href=''>" + parent + "</a></td>";
	});

	details = CommitObject.details();
	messageStart = details.indexOf("\n\n") + 2;
	diffStart = details.indexOf("diff");
	
	header  = details.substring(0, messageStart);
	message = details.substring(messageStart, diffStart);
	details = details.substring(diffStart);
	
	
	$("message").innerHTML = message.replace(/\n/g,"<br>");
	$("details").innerHTML = details;
}
