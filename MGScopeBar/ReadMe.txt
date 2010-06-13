MGScopeBar
By Matt Legend Gemmell
http://mattgemmell.com/
http://instinctivecode.com/



What is MGScopeBar?
-------------------

MGScopeBar is a control which provides a "scope bar" or "filter bar", much like that found in iTunes, the Finder (in the Find/Spotlight window), and Mail.



What platforms does it support?
-------------------------------

MGScopeBar supports Mac OS X 10.5 (Leopard) or later.



What are the licensing requirements?
------------------------------------

A license documented is included with the source code, but essentially it's a BSD-like license but requiring attribution. You're free to use the code in any kind of project, commercial or otherwise. You're also free to redistribute it, either modified or as-is. Read the license document for more details, and contact me if you have questions.



How do I use it in my project?
------------------------------

Just copy the five files whose names start with "MG" into your project, and you're good to go. You can also use the AppController class as a handy reference, since it provides a demo of how MGScopeBar works.



What can it do?
---------------

MGScopeBar gives you a scope bar control which gets its data from a delegate; it's very like NSTableView and other similar controls, so you should find it easy to use.

You can specify multiple "groups" of buttons, each of which can have:

1. An optional separator before the group.

2. An optional label to the left of the first button (and after the separator).

3. A series of buttons, each of which has a title, unique identifier string, and optional icon.

4. A selection-mode for the group; either radio-mode (only one item selected at a time), or multiple-selection (zero or more items can be selected at a time).

Scope bars also support an optional accessory view, displayed at the right side of the bar.

You can choose whether to use the Smart Resize feature (which is on by default). Smart Resize causes the scope bar to automatically collapse button-groups into popup-menus to better fit the available space.

You should read the MGScopeBarDelegateProtocol.h file to see a list of the delegate methods your delegate object will need to implement.



How do I know which buttons are selected in which groups?
---------------------------------------------------------

There's a delegate method which will be called whenever the user interacts with the scope bar in such a way as to change the selection in any group; see the delegate protocol (and the example code in AppController) for more details.

You can also call the -selectedItems method on MGScopeBar to find out exactly what's selected at any time. See the MGScopeBar.h file for an explanation of the data returned from this method.



Getting in touch
----------------

Whilst I can't provide specific help with integrating MGScopeBar into your application, I always welcome feedback, suggestions and bug reports. Feel free to get in touch with me via my gmail address (matt.gemmell) anytime.

I hope you enjoy using MGScopeBar.

-Matt Legend Gemmell
