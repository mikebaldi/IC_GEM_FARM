# Idle Champions - Gem Farm Script

A work in progress barebones gem farm script. May not comply with CNE terms of services.

To Do List:

- Create docs
- Optimization
- Nullable memory object
- Some sort of method that can have methods added or removed from it.
- Rework the the various function library classes with CreateOrGetInstance methods
- Standardize memory code
- Try to fix JSON class to parse class objects and detect recursion.
- Fix Known Issues.

Known Issues:

- Lists of value types other than Int32 may not work correctly.
- Docs are now out of date.
- Methods to delete dictionary entries don't appear to work, need to better understand how object delete method works.
- Script can get stuck in a modron reset in rare cases.
- Offset updater is currently broken until solution for field name 'type' doesn't create conflicts between memory objects and memory structures.

[Documentation](Docs/index.md)