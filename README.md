# Idle Champions - Gem Farm Script

A work in progress barebones gem farm script. May not comply with CNE terms of services.

To Do List:

Check if stuck
Create docs
Optimization
Nullable memory object
Update formation handler with a method that stops leveling champions after specializations.
Some sort of method that can have methods added or removed from it.
Rework the the various function library classes with CreateOrGetInstance methods
Standardize memory code
Collect data on load game and adventure and update methods accordingly
Try to fix JSON class to parse class objects and detect recursion.
Fix Known Issues.

Known Issues:

Missing our out of date EGS offsets
QT handler stops working if script is reloaded during the run.
Methods to delete dictionary entries don't appear to work, need to better understand how object delete method works.
Script appears to get stuck on World Map even though it knows it is on World Map.