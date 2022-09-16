# GemFarm_Final_Run

A basic script to farm gems in the game Idle Champions of the Forgotten Realms.

This script differs from more popular gem farming scripts in that it uses memory writes as a solution to the games various bugs and inconsistencies. Two examples:

1. The game does not properly save when closing for Briv stack farming and no or too few stacks are gained. Instead of trying again, the script will write the appropriate amount of stacks to memory and continue on.
2. For any number of reasons, the game cannot progress or earn gold because click level was not saved. Premptively, the script will write the values saved as the modron reset level to click level field stored in memory. Additionally, the script will periodically check and rewrite the value if necessary.

Additional differences:

- No GUI
- Some logging of data
- Very few settings or options