# _MemoryObjects

A collection of classes to be used as base objects for reading and writing specific memory values and addresses. The intent of these objects is to provide AHK script access to designated fields contained in the various types used in C# and mono applications, broadly, value and reference types, but also collections. When a desired value or address is read from or written to memory, the given AHK object will call a method requsting the address of the C# object it is a member of. This operation is repeated until the static base or a cached address is reached. The various project documents will commonly refer to these AHK objects individually as [Memory Object](#the-memory-object-type) and collectively as memory structures.

### Uses

- [Classes\Memory\classMemory.AHK](Memory\classMemory.md)
- [Classes\Memory\\_MemoryHandler.AHK](Memory\_MemoryHandler.md)

## Classes

### System._Collection
<blockquote>
<details><summary>Description</summary>
A base class with fields and methods common to items in a list or keys and values in a dictionary.
</details>

<details><summary>Fields</summary><blockquote>

<details><summary>CachedObjects</summary>

- As each [Memory Object](#the-memory-object-type) in a collection is instantiated it is stored in this array.
- Type: Array of [Memory Object](#the-memory-object-type)
</details>

<details><summary>OffsetBase</summary>

- Offset of first collection item, key, or value from [Memory Object](#the-memory-object-type) referenced by the ParentObj field.
- Type: IntPtr
</details>

<details><summary>OffsetStep</summary>

- Offset between collection items, keys, or values.
- Type: IntPtr
</details>

<details><summary>ParentObj</summary>

- The parent [Memory Object](#the-memory-object-type), necessary to recursively call back to the static base or cached address to create the memory structure. Typically [System.List](#systemlist)._items or [System.Dictionary](#systemdictionary).entries.
- Type: [Memory Object](#the-memory-object-type)
</details>

<details><summary>Type</summary>

- The collection item, key, or value [Memory Object](#the-memory-object-type) type.
- Type: The [Memory Object](#the-memory-object-type) type
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>

<details><summary>new</summary>

Creates a new instance of the class.

- Parameters
    - parent ([Memory Object](#the-memory-object-type)): Parent [Memory Object](#the-memory-object-type). Typically [System.List](#systemlist)._items or [System.Dictionary](#systemdictionary).entries.
    - type (The [Memory Object](#the-memory-object-type) type): The collection type.

- Returns
    - Instance of the class.
</details>

<details><summary>CreateObject</summary>

Instantiates a collection [Memory Object](#the-memory-object-type) for the desired index. Primarily called by other methods.

- Parameters
    - index (integer): The index of the desired collection [Memory Object](#the-memory-object-type).

- Returns
    - The instantiated [Memory Object](#the-memory-object-type).
</details>

<details><summary>GetIndexByValueType</summary>

Searches through the CachedObject array for a given value type.

- Parameters
    - value ([System.Value](#systemvalue)): A value type derived from [System.Value](#systemvalue).
    
- Return
    - Index of the matching value, -1 if CachedObject is empty, and -2 if no match is found.

</details>

<details><summary>GetObjectByIndex</summary>

Creates a new [Memory Object](#the-memory-object-type) and stores a reference in CachedObject array or returns a reference from the CachedObject array if previously created.

- Parameters
    - index (integer): The index of the desired collection [Memory Object](#the-memory-object-type).
    
- Returns
    - The requested [Memory Object](#the-memory-object-type).

</details>

<details><summary>GetOffset</summary>

Calcuates the offset for the desired collection [Memory Object](#the-memory-object-type) at a given index. Primarily called by other methods.

- Parameters
    - index (integer): The index of the collection [Memory Object](#the-memory-object-type).
    
- Returns
    - The requested offset value, IntPtr.

</details></blockquote>
</details></blockquote>

### System._DictionaryCollection
<blockquote>
<details><summary>Description</summary>

A base class for managing keys or values for a [System.Dictionary](#systemdictionary).

Extends [System._Collection](#system_collection)
</details>

<details><summary>Methods</summary><blockquote>

<details><summary>GetIndexCount</summary>
Reads system memory and returns count of key value pairs in the dictionary.

- Parameters
    - none

- Returns
    - Integer count of key value pairs in the dictionary, "" if failed memory read.
</details>
</blockquote></details>
</blockquote></details>

### System._ItemCollection
<blockquote>
<details><summary>Description</summary>

Used to manage items for a [System.List](#systemlist).

Extends [System._Collection](#system_collection)
</details>

<details><summary>Methods</summary><blockquote>

<details><summary>GetIndexCount</summary>
Reads system memory and returns count of items in the list.

- Parameters
    - none

- Returns
    - Integer count of items in the list, "" if failed memory read.
</details>

<details><summary>SetOffsetBaseAndStep</summary>
Internal method used to set 32 or 64 bit offset base and step fields.

- Parameters
    - none

- Returns
    - nothing
</details>
</blockquote></details>
</blockquote></details>

### System._KeyCollection
<blockquote>
<details><summary>Description</summary>

Used to manage keys for a [System.Dictionary](#systemdictionary).

Extends [System._DictionaryCollection](#system_dictionarycollection)
</details>

<details><summary>Methods</summary><blockquote>

<details><summary>SetOffsetBaseAndStep</summary>
Internal method used to set 32 or 64 bit offset base and step fields.

- Parameters
    - none

- Returns
    - nothing
</details>
</blockquote></details>
</blockquote></details>

### System._ValueCollection
<blockquote>
<details><summary>Description</summary>

Used to manage values for a [System.Dictionary](#systemdictionary).

Extends [System._DictionaryCollection](#system_dictionarycollection)
</details>

<details><summary>Methods</summary><blockquote>

<details><summary>SetOffsetBaseAndStep</summary>
Internal method used to set 32 or 64 bit offset base and step fields.

- Parameters
    - none

- Returns
    - nothing
</details>
</blockquote></details>
</blockquote></details>

### System.Boolean
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Boolean types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.Byte
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Byte types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.Dictionary
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Collections.Generic.Dictionary types.

Extends [System.Object](#systemobject)
</details>

<details><summary>Fields</summary><blockquote>

<details><summary>entries</summary>

- Parent object for key and value collections.
- Type: [System.Object](#systemobject)
</details>

<details><summary>count</summary>

- Total number of key value pairs collected within the dictionary.
- Type: [System.Int32](#sytemint32)
</details>

<details><summary>Keys</summary>

- Object used to handle the collection of keys.
- Type: [System._KeyCollection](#system_keycollection)
</details>

<details><summary>Values</summary>

- Object used to handle the collection of values.
- Type: [System._ValueCollection](#system_valuecollection)
</details>
</blockquote></details>

<details><summary>Properties</summary><blockquote>

<details><summary>Key</summary>

- Getter
  - Parameters
    - index (integer): Index of desired key.
  - Returns
    - Desired key [Memory Object](#the-memory-object-type).
- Setter
  - None
</details>

<details><summary>Value</summary>

- Getter
  - Parameters
    - index (integer): Index of desired value.
  - Returns
    - Desired value [Memory Object](#the-memory-object-type).
- Setter
  - None
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>

<details><summary>new</summary>
Creates a new instance of the class.

- Parameters
    - offset32 (integer): 32 bit offset from parent object.
    - offset64 (integer 64bit): 64 bit offset from parent object.
    - parentObj ([Memory Object](#the-memory-object-type)): Parent [Memory Object](#the-memory-object-type).
    - keyType (The [Memory Object](#the-memory-object-type) type): The [Memory Object](#the-memory-object-type) type of the dictionary keys.
    - valueType (The [Memory Object](#the-memory-object-type) type): The [Memory Object](#the-memory-object-type) type of the dictionary values.

- Returns
    - Instance of the class.
</details></blockquote>
</details></blockquote>

### System.Double
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Double types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.Enum
<blockquote>
<details><summary>Description</summary>

Used as a base class for memory objects representing C# enumerable types. When defining, type and enum fields have to be manually coded as part of the extended class definition.

Extends: [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>

<details><summary>Enum</summary>

- Array of the enumerables.
- Type: Array
</details>

<details><summary>isEnum</summary>

- A work around field to differentiate the object from other value types.
- Type: Boolean
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>

<details><summary>new</summary>
Creates a new instance of the class.

- Parameters
    - offset32 (integer): 32 bit offset from parent object.
    - offset64 (integer 64bit): 64 bit offset from parent object.
    - parentObj (memory object): Parent memory object.

- Returns
    - Instance of the class.
</details>

<details><summary>GetEnumerable</summary>
Returns the enumerable.

- Parameters
    - None
    
- Return
    - Enumerable as read from memory, "" if failed read.
</details></blockquote>

</blockquote>
</details></blockquote>

### System.Generic
<blockquote>
<details><summary>Description</summary>

A base class for value and string types. Currently under consideration to be refactored. Was primarily used to handle logging, but logging may be removed from all memory objects and handeled by another object.
</details>

<details><summary>Properties</summary><blockquote>

<details><summary>Value</summary>

- Getter
  - Parameters
    - none
  - Returns
    - Return value from GetValue method.
- Setter
  - Parameters
    - none
  - Returns
    - Return value from SetValue method.
</details>
</blockquote></details>

</blockquote></details>

### System.Int32
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Int32 types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.Int64
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Int64 types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.List
<blockquote>
<details><summary>Description</summary>

Used as a base class for memory objects representing C# System.Collections.Generic.List types.

Extends [System.Object](#systemobject)
</details>

<details><summary>Fields</summary><blockquote>

<details><summary>_items</summary>

- Parent object for item collections.
- Type: [System.Object](#systemobject)
</details>

<details><summary>_size</summary>

- Total number of items collected within the list.
- Type: [System.Integer](#syteminteger)
</details>

<details><summary>Items</summary>

- Object used to handle the collection of items.
- Type: [System._ItemCollection](#)
</details>
</blockquote></details>

<details><summary>Properties</summary><blockquote>

<details><summary>Item</summary>

- Getter
  - Parameters
    - index (integer): Index of desired item.
  - Returns
    - Desired item memory object.
- Setter
  - None
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>

<details><summary>new</summary>
Creates a new instance of the class.

- Parameters
    - offset32 (integer): 32 bit offset from parent object.
    - offset64 (integer 64bit): 64 bit offset from parent object.
    - parentObj (memory object): Parent memory object.
    - itemType (object):

- Returns
    - Instance of the class.
</details></blockquote>
</details></blockquote>

### System.Object
<blockquote>
<details><summary>Description</summary>

Used as a base class for memory objects representing C# reference types and other memory objects.
</details>

<details><summary>Fields</summary><blockquote>

<details><summary>CachedAddress</summary>

- The memory objects address when last set to use cached address.
- Type: Integer
</details>

<details><summary>ConsecutiveReads</summary>

- When logging, the count of consecutive memory reads matching the previous read.
- Type: Integer
</details>

<details><summary>Offset</summary>

- The memory objects offset from the parent memory object's address.
- Type: Integer
</details>

<details><summary>ParentObj</summary>

- The parent memory object.
- Type: _MemoryObject
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>

<details><summary>new</summary>
Creates a new instance of the class.

- Parameters
    - offset32 (integer): 32 bit offset from parent object.
    - offset64 (integer 64bit): 64 bit offset from parent object.
    - parentObj (memory object): Parent memory object.

- Returns
    - Instance of the class.
</details>

<details><summary>SetCachedAddress</summary>
Sets the CachedAddress field to the value returned from variableGetAddress method.

- Parameters
    - None
    
- Return
    - Nothing
</details>

<details><summary>staticGetAddress</summary>

- Parameters
    - None
    
- Returns
    - Value stored in CachedAddress field.

- Notes
    - This method is generally used internally.
</details>
<details><summary>UseCachedAddress</summary>

- Parameters
    - setStatic (boolean): True calls SetCachedAddress method and sets the GetAddress method to the staticGetAddressMethod. False sets the GetAddress method to the variableGetAddressMethod.
    
- Returns
    - Nothing.

- Notes
    - This method is used to toggle the memory object so that it uses a cached address value to reduce the number of reads. It is primarily used for iterating through collections.

</details>

<details><summary>variableGetAddress</summary>
Reads memory objects address based on parent memory objects address and the memory objects offset.

- Parameters
    - None

- Returns
    - Address on success, "" on failure.

- Note
    - This method is generally used internally.
</details></blockquote>
</details></blockquote>

### System.Short
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Short types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.Single
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.Single types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.StaticBase
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing the static base of a pointer.

</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Offset</summary>

- Offset from module.
- Type: IntPtr
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>
<details><summary>GetAddress</summary>

Reads the address of the static base.

- Parameters
    - None
    
- Return
    - Address read from memory, "" if failed read.
</details>
</blockquote></details>
</blockquote></details>

### System.String
<blockquote>
<details><summary>Description</summary>

Used as a base class for memory objects representing C# string types.

Extends: [System.Generic](#systemgeneric)
</details>

<details><summary>Fields</summary><blockquote>

<details><summary>Length</summary>

- The length of the string.
- Type: [System.Int](#)
</details>

<details><summary>stringOffset</summary>

- Offset from the given memory objects address to the actual memory location of the string.
- Type: IntPtr
</details>
</blockquote></details>

<details><summary>Methods</summary><blockquote>

<details><summary>new</summary>
Creates a new instance of the class.

- Parameters
    - offset32 (integer): 32 bit offset from parent object.
    - offset64 (integer 64bit): 64 bit offset from parent object.
    - parentObj (memory object): Parent memory object.

- Returns
    - Instance of the class.
</details>

<details><summary>GetValue</summary>
Reads string from memory associated with the given memory object.

- Parameters
    - None
    
- Return
    - String as read from memory, "" if read failed.
</details>

<details><summary>SetValue</summary>
Writes string to memory associated with the given memory object.

- Parameters
    - value: The string to be written to memory.

- Returns
    - Non zero indicates success, zero indicates failure.
</details></blockquote>

</blockquote>
</details></blockquote>

### System.UByte
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.UByte types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.UInt32
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.UInt32 types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.UInt64
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.UInt64 types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.USingle
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.USingle types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.UShort
<blockquote>
<details><summary>Description</summary>

Used as a base class for [Memory Object](#the-memory-object-type) representing C# System.UShort types.

Extends [System.Value](#systemvalue)
</details>

<details><summary>Fields</summary><blockquote>
<details><summary>Type</summary>

- Used to read the correct amount of bytes from memory. This field should not be modified.
- Type: String
</details>
</blockquote></details>
</blockquote></details>

### System.Value
<blockquote>
<details><summary>Description</summary>

Used as a base class for memory objects representing C# value types.

Extends [System.Generic](#systemgeneric)
</details>

<details><summary>Methods</summary><blockquote>

<details><summary>GetValue</summary>
Reads value from memory associated with the given memory object.

- Parameters
    - None

- Returns
    - Value read from memory. "" represents a failed read.
</details>

<details><summary>SetValue</summary>
Writes value to memory associated with the given memory object.

- Parameters
    - value: The value to be written to memory.

- Returns
    - Non zero indicates success, zero indicates failure.
</details></blockquote>
</details>

<details><summary>Notable Extensions</summary><blockquote>

- [System.Byte](#systembyte)
- [System.UByte](#systemubyte)
- [System.Short](#systemshort)
- [System.UShort](#systemushort)
- [System.Int32](#systemint32)
- [System.UInt32](#systemuint32)
- [System.Int64](#systemint64)
- [System.UInt64](#systemuint64)
- [System.Single](#systemsingle)
- [System.USingle](#systemusingle)
- [System.Double](#systemdouble)
- [System.Boolean](#systemboolean)
- [System.Enum](#systemenum)

</details></blockquote>
<br>

## The Memory Object Type
<br>

Within these documents there are references to '[Memory Object](#the-memory-object-type)' and 'The [Memory Object](#the-memory-object-type) type'. The former refers to an instance of a class nested within the System class or a class extended from a class nested within the the System class, while the latter refers to class, and in some cases the classes that are needed to instantiate the former.

<br>

When passing a parameter of 'The [Memory Object](#the-memory-object-type) type' there are the following options:

1. For [value](#systemvalue), [string](#systemstring), and types extended from [System.Object](#systemobject), the respective class should be the parameter passed.
2. For [System.List](#systemlist) types, an array where the first item is [System.List](#systemlist) and the second item is list item type as this section outlines.
3. For [System.Dictionar](#systemdictionary) types, an array where the first item is [System.Dictionar](#systemdictionary), the second item is the dictionary key type as this section outlines, and the third item is the dictionary value type as this section outlines.

Examples:

```ahk
Method(System.Int32) ;Passes type associated with 32 bit integer

Method(System.String) ;Passes type associated with literal string

class ExampleMemoryObject extends System.Object
{
    ;class definition
}

Method(ExampleMemoryObject) ;Passes type defined as ExampleMemoryObject, a reference type.

Method([System.List, System.Int32]) ;Passes a list of 32 bit integers

Method([System.Dictionary, System.Int, [System.List, ExampleMemoryObject]]) ;Passes a Dictionary of 32 bit integer key and List of ExampleMemoryObject type value pairs.
```