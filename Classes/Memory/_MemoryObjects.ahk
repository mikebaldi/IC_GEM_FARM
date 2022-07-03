class System
{
    class Object
    {
        __new(offset32, offset64, parentObj)
        {
            this.Offset := _MemoryHandler.ClassMemory.isTarget64bit ? offset64 : offset32
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        variableGetAddress()
        {
            return _MemoryHandler.ClassMemory.read(this.ParentObj.GetAddress() + this.Offset, _MemoryHandler.ClassMemory.ptrType)
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
            address := _MemoryHandler.ClassMemory.read(parentAddress + this.Offset, _MemoryHandler.ClassMemory.ptrType)
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
            this.Parent := parent
            this.Type := type
            this.CachedObjects := {}
            return this
        }

        GetObjectByIndex(index, offset)
        {
            if !(this.CachedObjects.HasKey(index))
                this.CachedObjects[index] := this.CreateObject(offset)
            return this.CachedObjects[index]
        }

        CreateObject(offset)
        {
            if (this.Type[1].__Class == "System.List")
                obj := new System.List(offset, offset, this.Parent, this.Type[2])
            else if (this.Type[1].__Class == "System.DIctionary")
                obj := new System.Dictionary(offset, offset, this.Parent, this.Type[2], this.Type[3])
            else
                obj := new this.Type(offset, offset, this.Parent)
            return obj
        }
    }

    class _Collection_WIP
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
                obj := new System.List(offset, offset, this.ParentObj, this.Type[2])
            else if (this.Type[1].__Class == "System.DIctionary")
                obj := new System.Dictionary(offset, offset, this.ParentObj, this.Type[2], this.Type[3])
            else
                obj := new this.Type(offset, offset, this.ParentObj)
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
                if (key == obj.Value)
                    return i
                ++i
            }
            return -1
        }

        GetOffset(index)
        {
            return this.OffsetBase + (index * this.OffsetStep)
        }
    }

    class _ItemCollection extends System._Collection_WIP
    {
        SetOffsetBaseAndStep()
        {
            this.OffsetBase := _MemoryHandler.ClassMemory.isTarget64bit ? 0x20 : 0x10
            this.OffsetStep := _MemoryHandler.ClassMemory.isTarget64bit ? 0x8 : 0x4
        }

        GetIndexCount()
        {
            return this.ParentObj.ParentObj._size.Value
        }
    }

    ;item base is the memory class, and item type is the c# type
    class List extends System.Object
    {
        __new(offset32, offset64, parentObject, itemType)
        {
            this.Offset := _MemoryHandler.ClassMemory.isTarget64bit ? offset64 : offset32
            this.ParentObj := parentObject
            this.GetAddress := this.variableGetAddress
            ;not sure what this.List is used for
            ;this.List := new System.Object(offset32, offset64, parentObject)
            this._items := new System.Object(0x8, 0x10, this)
            this._size := new System.Int32(0xC, 0x18, this)
            ;this.ItemOffsetBase := _MemoryHandler.ClassMemory.isTarget64bit ? 0x20 : 0x10
            ;this.ItemOffsetStep := _MemoryHandler.ClassMemory.isTarget64bit ? 0x8 : 0x4
            ;this.ItemType := itemType
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            ;this.Items := new System._Collection(this._items, this.ItemType)
            this.Items := new System._ItemCollection(this._items, itemType)
            return this 
        }
        
        ;Size()
        ;{
        ;    return this._size.GetValue()
        ;}

        ;GetItemOffset(index)
        ;{
        ;    return this.ItemOffsetBase + (index * this.ItemOffsetStep)
        ;}

        Item[index]
        {
            get
            {
                ;return this.NewChild(this._items, this.ItemType, this.GetItemOffset(index))
                ;return this.Items.GetObjectByIndex(index, this.GetItemOffset(index))
                return this.Items.GetObjectByIndex(index)
            }
        }
    }

    class _DictionaryCollection extends System._Collection_WIP
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
            this.OffsetBase := _MemoryHandler.ClassMemory.isTarget64bit ? 0x28 : 0x18
            this.OffsetStep := _MemoryHandler.ClassMemory.isTarget64bit ? 0x18 : 0x10
        }
    }

    class _ValueCollection extends System._DictionaryCollection
    {
        SetOffsetBaseAndStep()
        {
            this.OffsetBase := _MemoryHandler.ClassMemory.isTarget64bit ? 0x30 : 0x1C
            this.OffsetStep := _MemoryHandler.ClassMemory.isTarget64bit ? 0x18 : 0x10
        }
    }

    class Dictionary extends System.Object
    {
        __new(offset32, offset64, parentObject, keyType, valueType)
        {
            this.Offset := _MemoryHandler.ClassMemory.isTarget64bit ? offset64 : offset32
            this.ParentObj := parentObject
            this.GetAddress := this.variableGetAddress
            ;not sure what this is used for
            ;this.Dict := new System.Object(offset32, offset64, parentObject)
            this.entries := new System.Object(0xC, 0x10, this)
            this.count := new System.Int32(0x20, 0x18, this)
            ;this.KeyOffsetBase := _MemoryHandler.ClassMemory.isTarget64bit ? 0x28 : 0x18
            ;this.ValueOffsetBase := _MemoryHandler.ClassMemory.isTarget64bit ? 0x30 : 0x1C
            ;this.OffsetStep := _MemoryHandler.ClassMemory.isTarget64bit ? 0x18 : 0x10
            ;this.KeyType := keyType
            ;this.ValueType := valueType
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            ;this.Keys := new System._Collection(this.entries, this.KeyType)
            this.Keys := new System._KeyCollection(this.entries, keyType)
            ;this.Values := new System._Collection(this.entries, this.ValueType)
            this.Values := new System._ValueCollection(this.entries, valueType)
            return this
        }

        Key[index]
        {
            get
            {
                ;return this.NewChild(this.entries, this.KeyType, this.GetKeyOffset(index))
                ;return this.Keys.GetObjectByIndex(index, this.GetKeyOffset(index))
                return this.Keys.GetObjectByIndex(index)
            }
        }

        Value[index]
        {
            get
            {
                ;return this.NewChild(this.entries, this.ValueType, this.GetValueOffset(index))
                ;return this.Values.GetObjectByIndex(index, this.GetValueOffset(index))
                return this.Values.GetObjectByIndex(index)
            }
        }

        ;GetKeyOffset(index)
        ;{
        ;    return this.KeyOffsetBase + (index * this.OffsetStep)
        ;}

        ;GetValueOffset(index)
        ;{
        ;    return this.ValueOffsetBase + (index * this.OffsetStep)
        ;}
        /*
        GetIndexFromKey(key)
        {
            count := this.count.GetValue()
            if !count
                return -1
            i := 0
            loop %count%
            {
                if (key == this.Key[i].Value)
                    return i
                ++i
            }
            return -1
        }

        GetIndexFromValue(value)
        {
            count := this.count.GetValue()
            if !count
                return -1
            i := 0
            loop %count%
            {
                if (value == this.Value[i].Value)
                    return i
                ++i
            }
            return -1
        }
        */
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
            return _MemoryHandler.ClassMemory.read(this.ParentObj.GetAddress() + this.Offset, this.Type)
        }

        SetValue(value)
        {
            return _MemoryHandler.ClassMemory.write(this.ParentObj.GetAddress() + this.Offset, value, this.Type)
        }

        LogGetValue()
        {
            this.Log.CreateEvent(this.LogDesc . ".Value.get")
            parentAddress := this.ParentObj.LogGetAddress(this.Log)
            value := _MemoryHandler.ClassMemory.read(parentAddress + this.Offset, this.Type)
            this.Log.AddDataSimple(parentAddress . "+" . this.Offset . "->" . value)
            this.Log.LogStack()
            return value
        }

        LogSetValue(value)
        {
            this.Log.CreateEvent(this.LogDesc . ".Value.set")
            parentAddress := this.ParentObj.LogGetAddress(this.Log)
            retValue := _MemoryHandler.ClassMemory.write(parentAddress + this.Offset, value, this.Type)
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
        __new(offset32, offset64, parentObject)
        {
            this.isEnum := true ;this is hokey fix for tree view to differentiate enums from pointers, but I'm lazy right now.
            this.Offset := _MemoryHandler.ClassMemory.isTarget64bit ? offset64 : offset32
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
        __new(offset32, offset64, parentObj)
        {
            this.Offset := _MemoryHandler.ClassMemory.isTarget64bit ? offset64 : offset32
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.Length := new System.Int32(0x8, 0x10, this)
            ;this.Value := {}
            this.stringOffset := _MemoryHandler.ClassMemory.isTarget64bit ? 0x14 : 0xC
            this.prevValue := ""
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        GetValue()
        {
            baseAddress := this.GetAddress()
            return _MemoryHandler.ClassMemory.readstring(baseAddress + this.stringOffset, 0, "UTF-16")
        }

        SetValue(value)
        {
            length := StrLen(value)
            this.Length.SetValue(length)
            baseAddress := this.GetAddress()
            return _MemoryHandler.ClassMemory.writestring(baseAddress = this.stringOffset, value, "UTF-16")
        }

        LogGetValue()
        {
            this.Log.CreateEvent(this.LogDesc . ".String.get")
            baseAddress := this.LogGetAddress(this.Log)
            value := _MemoryHandler.ClassMemory.readstring(baseAddress + this.stringOffset, 0, "UTF-16")
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
            retValue := _MemoryHandler.ClassMemory.writestring(baseAddress = this.stringOffset, value, "UTF-16")
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
            return _MemoryHandler.ClassMemory.read(_MemoryHandler.ModuleBaseAddress + this.Offset, _MemoryHandler.ClassMemory.ptrType)
        }

        LogGetAddress(log)
        {
            if this.useCachedAddress
                return this.CachedAddress
            parentAddress := _MemoryHandler.ModuleBaseAddress
            address := _MemoryHandler.ClassMemory.read(parentAddress + this.Offset, _MemoryHandler.ClassMemory.ptrType)
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