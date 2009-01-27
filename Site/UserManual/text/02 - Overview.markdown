### Overview

![GitX's Open Dialog](images/UserManual/opendialog.png)
When you open GitX for the first time, you will be greeted by an open-dialog. In this dialog, you should select the Git repository you want to open. You can select either a directory containing a .git directory, or a .git directory itself. After doing this, you will be greeted by the default GitX view, which is the history-view. The history-view consists of two main parts. In the top part, there is an overview of all commits in your currently checked out branch. In the bottom part is a detail view that can show you more information about the selected commit.


#### The commit list

![History View](images/UserManual/historyview.png)
On the left side in the commit list you can see the _branch lines_. These show you how your history has diverged and merged. As newer commits are on top, two lines joining each other from the bottom is a merge. This way you see which branches were merged in without any effort.

On some commits, to the right of the branch lines you will find _commit labels_. These indicate references to these commits, for example branch heads and remote heads. _Green_ labels indicate local branches. _Blue_ labels indicate remote branches (it will be in the form of remote/branch). _Yellow_ labels indicate tags.

There are three columns, the first showing the commit _subject_ (which is the top line of your commit message), the second the _author name_ and the third the commit date. You can sort on any of these columns. However, if you sort the branch lines will disappear. If you click three times on a row, the sorting will be cancelled and the original overview will be restored, including the branch lines.

In the top right you will also find the search bar. Here you can search on subject, author or hash. If you do this, the branch lines will also disappear.

#### The detail view

![The detail switch controller](images/UserManual/detailswitcher.png "The detail switch controller")
In the bottom part of the history view, you can see the detail view. This part changes every time you select another commit. The detail view can switch between three different parts using the _detail switch controller_. The first one shows information about the current commit in a nice markup and will probably be the view you use most. In this mode, you can see a pretty diff of the commit, and information such as the parent hashes and the author's email address.

If you right-click on a reference in this view, you can choose to remove them. Be careful with this, there is no undo option! ![Removing a ref](images/UserManual/remove_ref.png "Removing references"). The diff view is created in such a way, that it is possible to select a part of the diff and copy and paste it, for example to paste it online and share it with someone. As this is such a common thing to do, GitX provides a way to do it automatically. If you click on the "Gist it" link, GitX will try to upload your current commit as a _git patch_ to [gist.github.com](http://gist.github.com "Github's gist"). This will use your Github cookie from Safari if it has one -- otherwise it will create an anonymous gist. Because this patch is a proper git patch, others can then simply apply it using 'git am'. For example, if your Gistie id is 14667, someone else can run

	curl gist.github.com/14667.txt | git am

to apply it to their own repository!

The second detailed view will show a raw commit text, much like 'git show --pretty=raw' would. The third detailed view is more interesting: it allows you to browse your repository as it was at that time point. This is also where the quicklook button in the bottom right comes in: pressing it while selecting a file that can be QuickLooked (an image, for example), will display it in the same way as the Finder's quicklook. GitX even imitates this behaviour by allowing you to press space to quicklook a file.
