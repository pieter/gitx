### Committing

![GitX's commit view](images/UserManual/commitview.png "The Commit View") GitX
also has a commit interface. This interface mimicks some of `git gui`'s
functionality, but will be extended in future releases.

This view also consists of two parts. The top part will show the diff of the
currently selected file. The bottom part is a bit more complex.

On the left you will see changes that are _unstaged_. If you are already used to Git's terminology, you will know what this means. These are the changes that have not been added to the index, and thus also will not be committed.

The most right part shows the _staged changes_. These _will_ be committed in the next commit.

It is possible to have a filename in both parts at once. In that case, there are some changes in the file that will be committed, and some that have been left out. Clicking on their name will show you what the difference is in the top pane.

To stage a file, double-click on its name. This will move the file from the left to the right. In the same way, you can unstage changes by double clicking on the name in the right pane. If you prefer, you can also drag and drop the files from one list to the other. You can also select multiple files, and then drag them to the other side all at once.

Every file has an icon associated with it. This shows the status of that file:

* A _green_ icon indicates there a changes to a file that is already tracked
* A _white_ icon indicates a file that is not tracked by Git, but also not ignored.
* A _red_ icon indicates a file that has been deleted.

#### Partial staging

Sometimes you have done more than one thing in a file, but would still prefer to create more than one git commit; the more specific the commits, the better, right? In this case, GitX can help you too. Next to each specific change in a file, called a _hunk_, you will see a blue 'stage' button. If you click on this button, only those specific changes will be staged.

If the hunk isn't specific enough, you can decrease the context size by manipulating the _context slider_. This is the slider in the top right of the commit view; if you pull it to the left, adjacent changes will be pulled together, if you pull it to the right, they will be split off in smaller hunks. That way you can try to split a hunk two and commit just the hunk that you need.

#### Committing

Once you have staged all your changes, you can commit them. Enter a commit message in the center pane, but remember to use proper commit messages: your first line should be a short description of what you have changed, on which you can elaborate below that. Make sure the subject of your commit is short enough to fit in GitX's history view! Pressing the commit button will hopefully convey to you that the commit was succesful, and also give you the commit hash.