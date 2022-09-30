# Idle Champions - Gem Farm Script

A barebones gem farm script. Does not include a GUI or any sort of stats.

May not comply with CNE terms of services.

Prior to Script Hub being updated with automatic offset updater, I studied an alternative method for reading memory to ensure the current method used by Script Hub was the correct one to build the updater around. This project was born from that study.

This repo also contains Tree View.ahk, a script that mimics Cheat Engine structure viewer, though only for the memory structures defined herein. This script primarily serves as a debugging tool, but can be very helpful when creating or updating code.

The final script contained in this repo is IC_Helper.ahk. I work in progress script that takes some of the functionality of the gem farm script and allows it to more easily be used in a non gem farm run.

## Current IC Version: 471

To Do List:

- Clean up code to be consistent
- Refine quad memory object
- Nullable memory object
- Remove logging code from memory object classes.
- Try to fix JSON class to parse class objects and detect recursion.
- Fix Known Issues
- Clean up log class and eliminate superflous text created in the output json.

Known Issues:

- Lists of value types other than Int32 are untested and may not work correctly
- Docs are out of date and far from complete.
- Methods to delete dictionary entries don't appear to work.
- Script can get stuck in a modron reset in rare cases.
- Offset updater is currently broken until solution for field name 'type' doesn't create conflicts between memory objects and memory structures.
- Reloading script may break the QT and Hew handlers, with the latter actually making it so there is a high liklihood of not jumping with Briv.