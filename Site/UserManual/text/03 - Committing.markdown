Committing
==========

![GitX's commit view](assets/images/commitview.png "The Commit View") GitX
also has a commit interface. This interface mimicks some of `git gui`'s
functionality, but will be extended in future releases.

This view also consists of two parts. The top part will show the diff of the
currently selected file. The bottom part is a bit more complex.

On the left you will see changes that are _unstaged_. If you are already used to Git's terminology, you will know what this means. These are the changes that have not been added to the index, and thus also will not be committed.

The most right part shows the _staged changes_. These _will_ be committed in the next commit.

It is possible to have a filename in both parts at once. In that case, there are some changes in the file that will be committed, and some that have been left out. Clicking on their name will show you what the difference is in the top pane.

To stage a file, double-click on its name. This will move the file from the left to the right. In the same way, you can unstage changes by double clicking on the name in the right pane.

Every file has an icon associated with it. This shows the status of that file:

* A _green_ icon indicates there a changes to a file that is already tracked
* A _white_ icon indicates a file that is not tracked by Git, but also not ignored.
* A _red_ icon indicates a file that has been deleted.

### Committing

Once you have staged all your changes, you can commit them. Enter a commit message in the center pane, but remember to use proper commit messages: your first line should be a short description of what you have changed, on which you can elaborate below that. Make sure the subject of your commit is short enough to fit in GitX's history view! Pressing the commit button will hopefully convey to you that the commit was succesful, and also give you the commit hash.