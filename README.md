# Idle Champions - Gem Farm Script

A barebones gem farm script. Does not include a GUI or any sort of stats.

May not comply with CNE terms of services.

This project started as a study of memory object alternative to the current method used as part of Script Hub. The project progressed as a learning exercise and as such will likely not be completed any further.

This repo also contains Tree View.ahk, a script that mimics Cheat Engine structure viewer, though only for script defined memory structures. Tree view script primarily serves as a debugging tool, but can be very helpful when creating or updating code involving dictionary collections.

There are a couple other functioning scripts that serve as helpers and should be self explanitory.

## Current IC Version: 475.1

Known Issues:

- Methods to delete dictionary entries don't appear to work.
- Script can get stuck in a modron reset in rare cases.
- Reloading or re-running the script without restarting the client (and clearing memory writes) may break the QT and Hew handlers, with the former actually making it so there is a high liklihood of not jumping with Briv. A finalizer probably should be added to write back default values to fix this, but that still wouldn't help if the script crashed.