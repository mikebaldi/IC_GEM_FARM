class System
{
    Refresh()
    {
        this.Memory := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.ModuleBaseAddress := this.Memory.getModuleBaseAddress("mono-2.0-bdwgc.dll")
    }

    class Object
    {
        __new(offset, parentObj)
        {
            this.Offset := offset
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        variableGetAddress()
        {
            return System.Memory.read(this.ParentObj.GetAddress() + this.Offset, System.Memory.ptrType)
        }

        ;to be deprecated
        SetAddress(setStatic)
        {
            if setStatic
            {
                this.CachedAddress := this.variableGetAddress()
                this.GetAddress := this.staticGetAddress
            }
            else
                this.GetAddress := this.variableGetAddress
        }

        SetCachedAddress()
        {
            this.CachedAddress := this.variableGetAddress()
        }

        UseCachedAddress(setStatic)
        {
            if setStatic
            {
                this.CachedAddress := this.variableGetAddress()
                this.GetAddress := this.staticGetAddress
            }
            else
                this.GetAddress := this.variableGetAddress
        }

        staticGetAddress()
        {
            return this.CachedAddress
        }

        LogGetAddress(log)
        {
            parentAddress := this.ParentObj.LogGetAddress(log)
            address := System.Memory.read(parentAddress + this.Offset, System.Memory.ptrType)
            log.AddDataSimple(parentAddress . "+" . this.Offset . "->" . address)
            if (address != this.CachedAddress)
            {
                this.CachedAddress := address
                this.ConsecutiveReads := 0
            }
            else
                this.ConsecutiveReads += 1
            log.AddDataSimple("ConsecutiveReads: " . this.ConsecutiveReads)
            return address
        }
    }

    class _Collection
    {
        __new(parent, type)
        {
            this.ParentObj := parent
            this.Type := type
            this.CachedObjects := {}
            this.SetOffsetBaseAndStep()
            return this
        }

        GetObjectByIndex(index)
        {
            if !(this.CachedObjects.HasKey(index))
                this.CachedObjects[index] := this.CreateObject(index)
            return this.CachedObjects[index]
        }

        CreateObject(index)
        {
            offset := this.GetOffset(index)
            if (this.Type[1].__Class == "System.List")
                obj := new System.List(offset, this.ParentObj, this.Type[2])
            else if (this.Type[1].__Class == "System.DIctionary")
                obj := new System.Dictionary(offset, this.ParentObj, this.Type[2], this.Type[3])
            else
                obj := new this.Type(offset, this.ParentObj)
            return obj
        }

        GetIndexByValueType(value)
        {
            count := this.GetIndexCount()
            if !count
                return -1
            i := 0
            loop %count%
            {
                obj := this.GetObjectByIndex(i)
                if (value == obj.Value)
                    return i
                ++i
            }
            return -2
        }

        GetOffset(index)
        {
            return this.OffsetBase + (index * this.OffsetStep)
        }
    }

    class _ItemCollection extends System._Collection
    {
        SetOffsetBaseAndStep()
        {
            this.OffsetBase := 0x20 ;System.Memory.isTarget64bit ? 0x20 : 0x10
            this.OffsetStep := this.Type == System.Int32 ? 0x4 : 0x8 ;0x8 ;System.Memory.isTarget64bit ? 0x8 : 0x4
            ;potential solution to lists of value types
            ;if (this.Type.Type AND System.Memory.aTypeSize[this.Type.Type] <= 4)
            ;    this.OffsetStep := 0x4
            ;else
            ;    this.OffsetStep := 0x8
        }

        GetIndexCount()
        {
            return this.ParentObj.ParentObj._size.Value
        }
    }

    class List extends System.Object
    {
        __new(offset, parentObject, itemType)
        {
            this.Offset := offset
            this.ParentObj := parentObject
            this.GetAddress := this.variableGetAddress
            this._items := new System.Object(0x10, this) ;32bit == 0x8
            this._size := new System.Int32(0x18, this) ;32bit == 0xX
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            this.Items := new System._ItemCollection(this._items, itemType)
            return this 
        }

        Item[index]
        {
            get
            {
                return this.Items.GetObjectByIndex(index)
            }
        }
    }

    class _DictionaryCollection extends System._Collection
    {
        GetIndexCount()
        {
            return this.ParentObj.ParentObj.count.Value
        }
    }

    class _KeyCollection extends System._DictionaryCollection
    {
        SetOffsetBaseAndStep()
        {
            ;this.OffsetBase := this.Type == System.Int32 ? 0x20 : 0x28 ;System.Memory.isTarget64bit ? 0x28 : 0x18
            this.OffsetBase := 0x28
            this.OffsetStep := this.Type == System.Int32 ? 0x10 : 0x18 ;System.Memory.isTarget64bit ? 0x18 : 0x10
        }
    }

    class _ValueCollection extends System._DictionaryCollection
    {
        SetOffsetBaseAndStep()
        {
            this.OffsetBase := this.Type == System.Int32 ? 0x2C : 0x30 ;System.Memory.isTarget64bit ? 0x30 : 0x1C
            this.OffsetStep := this.Type == System.Int32 ? 0x10 : 0x18 ;System.Memory.isTarget64bit ? 0x18 : 0x10
        }
    }

    class Dictionary extends System.Object
    {
        __new(offset, parentObject, keyType, valueType)
        {
            this.Offset := offset
            this.ParentObj := parentObject
            this.GetAddress := this.variableGetAddress
            this.entries := new System.Object(0x18, this)
            this.count := new System.Int32(0x40, this) ;32bit == 0x20
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            this.Keys := new System._KeyCollection(this.entries, keyType)
            this.Values := new System._ValueCollection(this.entries, valueType)
            return this
        }

        Key[index]
        {
            get
            {
                return this.Keys.GetObjectByIndex(index)
            }
        }

        Value[index]
        {
            get
            {
                return this.Values.GetObjectByIndex(index)
            }
        }
    }

    class Generic extends System.Object
    {
        Value[]
        {
            get
            {
                if !(this.doLog)
                    return this.GetValue()
                else
                    return this.LogGetValue()
            }

            set
            {
                if !(this.doLog)
                    return this.SetValue(value)
                else
                    return this.LogSetValue(value)
            }
        }
    }

    class Value extends System.Generic
    {
        GetValue()
        {
            return System.Memory.read(this.ParentObj.GetAddress() + this.Offset, this.Type)
        }

        SetValue(value)
        {
            return System.Memory.write(this.ParentObj.GetAddress() + this.Offset, value, this.Type)
        }

        LogGetValue()
        {
            this.Log.CreateEvent(this.LogDesc . ".Value.get")
            parentAddress := this.ParentObj.LogGetAddress(this.Log)
            value := System.Memory.read(parentAddress + this.Offset, this.Type)
            this.Log.AddDataSimple(parentAddress . "+" . this.Offset . "->" . value)
            this.Log.LogStack()
            return value
        }

        LogSetValue(value)
        {
            this.Log.CreateEvent(this.LogDesc . ".Value.set")
            parentAddress := this.ParentObj.LogGetAddress(this.Log)
            retValue := System.Memory.write(parentAddress + this.Offset, value, this.Type)
            this.Log.AddDataSimple(parentAddress . "+" this.Offset ":=" value)
            if retValue
                this.Log.AddDataSimple("retValue: " . retValue)
            else if (retValue == 0)
            {
                this.Log.AddDataSimple("ErrorLevel: " . ErrorLevel)
                this.Log.AddDataSimple("A_LastError: " . A_LastError)
            }
            else
                this.Log.AddDataSimple("type: " . this.Type)
            this.Log.LogStack()
            return retValue
        }
    }

    class Byte extends System.Value
    {
        Type := "Char"
    }

    class UByte extends System.Value
    {
        Type := "UChar"
    }

    class Short extends System.Value
    {
        Type := "Short"
    }

    class UShort extends System.Value
    {
        Type := "UShort"
    }

    class Int32 extends System.Value
    {
        Type := "Int"
    }

    class UInt32 extends System.Value
    {
        Type := "UInt"
    }

    class Int64 extends System.Value
    {
        Type := "Int64"
    }

    class UInt64 extends System.Value
    {
        Type := "UInt64"
    }

    class Single extends System.Value
    {
        Type := "Float"
    }

    class USingle extends System.Value
    {
        Type := "UFloat"
    }

    class Double extends System.Value
    {
        Type := "Double"
    }

    class Boolean extends System.Value
    {
        Type := "Char"
    }

    class Enum extends System.Value
    {
        __new(offset, parentObject)
        {
            this.isEnum := true ;this is hokey fix for tree view to differentiate enums from pointers, but I'm lazy right now.
            this.Offset := offset
            if !(System.valueTypeSize.HasKey(this.Type))
                ExceptionHandler.ThrowError("Value type parameter is invalid.`nInvalid Parameter: " . this.Type, -2)
            this.Type := System.valueTypeSize[this.Type]
            this.ParentObj := parentObject
            return this
        }

        GetEnumerable()
        {
            return this.Enum[this.GetValue()]
        }
    }

    class String extends System.Generic
    {
        __new(offset, parentObj)
        {
            this.Offset := offset
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.Length := new System.Int32(0x10, this)
            this.stringOffset := 0x14 ;System.Memory.isTarget64bit ? 0x14 : 0xC
            this.prevValue := ""
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        GetValue()
        {
            baseAddress := this.GetAddress()
            return System.Memory.readstring(baseAddress + this.stringOffset, 0, "UTF-16")
        }

        SetValue(value)
        {
            length := StrLen(value)
            this.Length.SetValue(length)
            baseAddress := this.GetAddress()
            return System.Memory.writestring(baseAddress = this.stringOffset, value, "UTF-16")
        }

        LogGetValue()
        {
            this.Log.CreateEvent(this.LogDesc . ".String.get")
            baseAddress := this.LogGetAddress(this.Log)
            value := System.Memory.readstring(baseAddress + this.stringOffset, 0, "UTF-16")
            this.Log.AddDataSimple(baseAddress . "+" . this.stringOffset . "->" . value)
            this.Log.LogStack()
            return value
        }

        LogSetValue(value)
        {
            this.Log.CreateEvent(this.LogDesc . ".String.set")
            length := StrLen(value)
            this.Length.LogSetValue(length)
            baseAddress := this.LogGetAddress(this.Log)
            retValue := System.Memory.writestring(baseAddress = this.stringOffset, value, "UTF-16")
            this.Log.AddDataSimple(baseAddress . "+" this.stringOffset ":=" value)
            if retValue
                this.Log.AddDataSimple("retValue: " . retValue)
            else if (retValue == 0)
            {
                this.Log.AddDataSimple("ErrorLevel: " . ErrorLevel)
                this.Log.AddDataSimple("A_LastError: " . A_LastError)
            }
            else
                this.Log.AddDataSimple("type: " . this.Type)
            this.Log.LogStack()
            return retValue
        }
    }

    class Action extends System.Object
    {

    }

    static valueTypeSize :=     {   "System.Byte": "Char",     "System.UByte": "UChar"
                                ,   "System.Short": "Short",   "System.UShort": "UShort"
                                ,   "System.Int32": "Int",     "System.UInt32": "UInt"
                                ,   "System.Int64": "Int64",   "System.UInt64": "UInt64"
                                ,   "System.Single": "Float",  "System.USingle": "UFloat"
                                ,   "System.Double": "Double", "System.Boolean": "Char"}

    class StaticBase
    {
        GetAddress()
        {
            return System.Memory.read(System.ModuleBaseAddress + this.Offset, System.Memory.ptrType)
        }

        LogGetAddress(log)
        {
            if this.useCachedAddress
                return this.CachedAddress
            parentAddress := System.ModuleBaseAddress
            address := System.Memory.read(parentAddress + this.Offset, System.Memory.ptrType)
            log.AddDataSimple(parentAddress . "+" . this.Offset . "->" . address)
            if (address != this.CachedAddress)
            {     
                this.CachedAddress := address
                this.ConsecutiveReads := 0
            }
            else
                this.ConsecutiveReads += 1
            log.AddDataSimple("ConsecutiveReads: " . this.ConsecutiveReads)
            return address
        }
    }
}