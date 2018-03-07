var showMultipleFilesSelection = function(files)
{
	hideNotification();
	setTitle("");

	var div = $("diff");
    div.style.display = "";
	div.innerHTML = '<div id="multiselect">' +
		'<div class="title">Multiple Selection</div>' +
        '<ul></ul>' +
        '</div>';

    var ul = div.getElementsByTagName("ul")[0];
	for (var i = 0; i < files.length; ++i)
	{
		var file = files[i];
        var li = document.createElement("li");
        li.textContent = file.path;
        ul.appendChild(li);
	}
}
