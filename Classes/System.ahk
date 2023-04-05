; A class to

; Dependencies:
#Include %A_LineFile%\..\ClassMemoryManager.ahk
if (_ClassMemoryManager.__Class != "_ClassMemoryManager")
{
    msgbox "_ClassMemoryManager" not correctly installed. Or the (global class) variable "_ClassMemoryManager" has been overwritten. Exiting App.
    ExitApp
}

class System
{
    ; System.StaticBase, a class representing the base object, generally one or a few hops from the pointer's static base address.
    ; Example usage
    ; idleGameManager := new _IdleGameManager("IdleDragons.exe", "mono-2.0-bdwgc.dll", 0x495A90, [0xCB0])
    class StaticBase
    {
        __new(exeName, moduleName, moduleOffset, offsets*)
        {
            this.s_exeName := exeName
            this.s_moduleName := moduleName
            this.s_moduleOffset := moduleOffset
            this.s_offsets := offsets
            this.s_offset := offsets[offsets.count()] ? offsets[offsets.count()]:moduleOffset ;final offset for tree view
            this.s_GetValue := this.s_readValue
            return this
        }

        ; these need to be properties as the reference back to class memory manager can break when class memory fails to construct an instance.
        s_classMemory[]
        {
            get
            {
                return _ClassMemoryManager.ClassMemory[this.s_exeName]
            }
        }

        s_moduleBaseAddress[]
        {
            get
            {
                return _ClassMemoryManager.BaseAddress[this.s_exeName, this.s_moduleName]
            }
        }

        s_readAddress()
        {
            return this.s_classMemory.read(this.s_moduleBaseAddress + this.s_moduleOffset, "Int64")
        }

        s_readValue()
        {
            return this.s_classMemory.read(this.s_moduleBaseAddress + this.s_moduleOffset, "Int64", this.s_offsets*)
        }

        s_OpenProcess()
        {
            return _ClassMemoryManager.OpenProcess(this.s_exeName, this.s_moduleName)
        }
    }

    ; System.Object, base class of all objects meant to represent memory structures, except the static base.
    class Object
    {
        __new(offset, parentObj, params*)
        {
            this.s_offset := offset
            this.s_parent := parentObj
            this.s_exeName := this.s_parent.s_exeName
            this.s_GetValue := this.s_readValue
            this.s_classMemoryType := System.classMemoryType[this.__Class] ? System.classMemoryType[this.__Class]:"Int64"
            return this
        }

        __Get(type := System.Array)
        {
            return new type(this.s_offset, this.s_parent, this.s_params*)
        }

        s_classMemory[]
        {
            get
            {
                return _ClassMemoryManager.ClassMemory[this.s_exeName]
            }
        }

        s_readValue()
        {
            return this.s_classMemory.read(this.s_parent.S_GetValue() + this.s_offset, this.s_classMemoryType)
        }
    }

    class Collections
    {
        class Generic
        {
            class List extends System.Object
            {
                __new(offset, parentObj, params*)
                {
                    this.s_offset := offset
                    this.s_parent := parentObj
                    this.s_GetValue := this.s_readValue
                    this._items := new System.Object(0x10, this)
                    this._items.s_isCollection := true
                    this._size := new System.Int32(0x18, this)
                    itemTypeSize := System.classMemoryTypeSize[this.s_item.s_classMemoryType]
                    this.s_itemCollection := new System.Collection.Collection("Item", this._items, this._size, 0x20, itemTypeSize ? itemTypeSize:0x8, params*)
                    return this
                }

                Item[index]
                {
                    get
                    {
                        return this.s_itemCollection.s_GetObject(index)
                    }
                }
            }
        }

        class Collection extends System.Object
        {
            __new(name, parentObj, count, offsetBase, offsetStep, params*)
            {
                this.s_name := name
                this.s_parent := parentObj
                this.s_count := count
                this.s_offsetBase := offsetBase
                this.s_offsetStep := offsetStep
                this.s_type := params[1]
                this.s_params := params[2]
                this.s_cache := {}
                return this
            }

            s_GetObject(index)
            {
                if !IsObject(this.s_cache[index])
                {
                    this.s_cache[index] := new this.s_type(this.s_getOffset(index), this.s_parent, this.s_params*)
                }
                return this.s_cache[index]
            }

            s_getOffset(index)
            {
                return this.s_offsetBase + this.s_offsetStep * index
            }

            s_Count()
            {
                return this.s_count.s_GetValue()
            }
        }
    }

    class String extends System.Object
    {
        Length := new System.Int32(0x10, this)
        Value := new System.String.s_String(0x14, this)

        class s_String extends System.Object
        {
            s_isGeneric := true

            s_readValue()
            {
                return this.s_classMemory.readString(this.s_parent.S_GetValue() + this.s_offset, this.s_parent.Length.s_GetValue() * 2, "UTF-16")
            }
        }
    }

    class Array extends System.Object
    {

    }

    class Generic extends System.Object
    {
        s_isGeneric := true
    }

    class Boolean extends System.Generic
    {}

    class Int32 extends System.Generic
    {}

    class Single extends System.Generic
    {}

    static classMemoryType :=   {   "System.Byte": "Char",      "System.UByte": "UChar",    "System.Short": "Short"
                                ,   "System.UShort": "UShort",  "System.Int32": "Int",      "System.UInt32": "UInt"
                                ,   "System.Int64": "Int64",    "System.UInt64": "Int64",   "System.Single": "Float"
                                ,   "System.USingle": "UFloat", "System.Double": "Double",  "System.Boolean": "Char"}
    
    static classMemoryTypeSize :=   {"Char": 0x4, "UChar": 0x4, "Short": 0x4, "UShort": 0x4, "Int": 0x4, "UInt": 0x4, "Int64": 0x8
                                    , "UInt64": 0x8,"Float": 0x4, "UFloat": 0x4, "Double": 0x8, "Char": 0x4, "Quad": 0x10}

    ; A class containing methods and types used to obtain data generally for debugging
    class Reflection
    {
        GetFields(typeInstance)
        {
            if (typeInstance.s_isCollection)
            {
                return this.GetCollectedFields(typeInstance)
            }
            fields := {}
            for k, v in typeInstance
            {
                ; check if member name begins with s_
                if (InStr(k, "s_") == 1)
                {
                    continue
                }
                ; get the fields base type
                fieldType := v.base.__Class
                while fieldType
                {
                    try
                    {
                        fieldType := %fieldType%.base.__Class
                    }
                    catch
                    {
                        break
                    }
                }
                fields[v.s_offset] := new System.Reflection.FieldInfo(k, v, fieldType)
            }
            return fields
        }

        GetCollectedFields(collection)
        {
            fields := {}
            for k, v in collection
            {
                ; find class System.Collections.Collection
                fieldType := v.base.__Class
                while fieldType
                {
                    try
                    {
                        fieldType := %fieldType%.base.__Class
                    }
                    catch
                    {
                        break
                    }
                }
                if (fieldType == "System.Collections.Collection")
                {
                    i := 0
                    count := v.s_Count()
                    loop % count
                    {
                        obj := v.s_GetObject(i)
                        fieldType := obj.base.__Class
                        while fieldType
                        {
                            try
                            {
                                fieldType := %fieldType%.base.__Class
                            }
                            catch
                            {
                                break
                            }
                        }
                        fields[obj.s_offset] := new System.Reflection.FieldInfo(obj.s_name . "[" . i . "]", obj, fieldType)
                    }
                }
            }
            return fields
        }

        class FieldInfo
        {
            __new(name, field, type)
            {
                this.Name := name
                this.Field := field
                this.Type := type
                return this
            }

            ; TODO add full name property
            ; TODO flags for properties to retrieve
        }
    }
}