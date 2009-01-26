<% @title = "Release History"  %>
<h2>
	Release history
</h2>

### Changes in v0.6

This release has the following new features and enhancements:

* The diff display now looks much nicer, using boxes to segment files
* The toolbar can now me customized
* Images that have been changed or added in a commit can now be viewed
  inline in GitX
* GitX has gained a preference pane which allows you to specify a git path
  and disable the Gist and Gravatar integration
* The commit interface is now more intuitive. Particularly, you can now
  select multiple files and use drag and drop to stage / unstage files
* You can now drag and drop files out of the commit view
* The files in the commit view have gained a context menu that allows you
  to revert changes / open the file / ignore the file
* It is now possible to adjust the amount of context lines in the commit view.
  Using a smaller context size allows you to do more fine-grained commits
* The branch menu is now organized in branches/remotes/tags
* The view switch button now uses icons rather than words
* The view shortcuts have changed to use command 1/2 for the history/commit 
  view. The history's subviews can now be changed using command-option-1/2/3
* Listing commits has become much faster
* GitX no longer spawns zombie processes
* GitX now shows a list of files that have been changed in a commit
* GitX now uses libgit2 to store object id's, reducing it's memory footprint

In addition many bugs were fixed, including the correct calculation of a
gravatar MD5 hash.

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
