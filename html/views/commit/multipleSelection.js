var showMultipleFilesSelection = function(files)
{

	setTitle("Multiple selection");

	var div = $("diff");

	var contents = "<h3>Multiple Selection:</h3>";
	contents += "<ul>";

	for (var i = 0; i < files.length; ++i)
	{
		var file = files[i];
		contents += "<li>" + file.path + "</li>";
	}
	contents += "</ul>";

	div.innerHTML = contents;
}