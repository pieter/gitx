<% @title = "Release History"  %>
<h2>
	Release history
</h2>

### Changes in v0.5

This feature release has several new smaller or larger features:

* The current branch is now highlighted
* In the commit view, there is an option to amend commits
* The "Gist it" button now respects github.user/token
* Display a gravatar of the committer
* The commit message view now displays a vertical line at 50 characters
* It is now possible to revert changes by using the context menu in the
  commit view
* You can now stage only parts of a file by using the "Stage Hunk" buttons
  in the commit view
* You can now use GitX to show a diff of anything, for example by using
  'gitx --diff HEAD^^' or 'git diff HEAD~3 | gitx --diff'
* You can now drag and drop refs to move them and also create branches

In addition, the following bugs have been fixed:

* Better detection of git version
* Branch lines are no longer interspersed with half a pixel of whitespace
* The toolbar keeps its state when switching views

<h3>Changes in v0.4.1:</h3>
<ul>
<li>The diff display is now much faster</li>
	<li>More locations are now searched for a default git</li>
	<li>Code pasted online is now private</li>

</ul>
<h3>Changes in v0.4:</h3>
<ul>
<li>A new commitview, allowing you to selectively add changes and commit them.</li>
	<li>You can now upload a commit as a patch to gist.github.com</li>

	<li>GitX now searches for your git binary in more directories and is smarter
 about reporting errors regarding git paths.</li>
	<li>You can now remove branches by right-clicking on them in the detailed view</li>
	<li>GitX now comes with a spicy new icon</li>
	<li>The diff view has become prettier and now also highlights trailing
 whitespace.</li>
	<li>Various little changes and stability improvement</li>
</ul>
<h3>Changes in v0.3:</h3>
<ul>
<li>You can now pass on command-line arguments just like you can with ‘git log’</li>
	<li>The program has an icon</li>
	<li>Also displays remote branches in the branch list</li>

	<li>Is better in determining if a directory is a bare git repository</li>
	<li>Support for—left-right: use ‘gitx—left-right <span class="caps">HEAD</span>..origin/master’
 to see which commits are only on your branch or on their branch</li>
	<li>Navigate through changed hunks by using j/k keys</li>
	<li>Scroll down in webview by using space / shift-space</li>
</ul>

<h3>Changes in v0.2.1:</h3>
<ul>
<li>Added supercool auto-update feature (Sparkle)</li>
</ul>
<h3>Changes in v0.2</h3>
<ul>
<li>Branch lines now have colors</li>
<li>Ref labels added to commits</li>
</ul>
