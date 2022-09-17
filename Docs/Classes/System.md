# Class: System

A class containing members that provide the script with memory reading and writing functionality.

## Members

### Fields
<blockquote>
<details><summary>Memory</summary>

A reference of the current instance of [classMemory](classMemory.md). Assigned by Refresh method.
</details>
<details><summary>ModuleBaseAddress</summary>

Memory address of the module. Assigned by Refresh method.
</details>
<details><summary>ValueTypeSize</summary>

Array of string pairs where pair key is the C# value type and the pair value is the classMemory corresponding size.

May be deprecated.
</details>
</blockquote>

### Methods
<blockquote>
<details><summary>Refresh</summary>

- Creates a new instance of [classMemory](classMemory.md) with a reference at this.Memory.

- Reads the module base address and stores the value at this.ModuleBaseAddress. 

- This method must be called prior to using memory objects each time the client is restarted.

Parameters: None

Returns: Nothing
</details>
</blockquote>