class System
{
    class Object
    {
        __new(offset32, offset64, parentObj)
        {
            this.Offset := MemoryReader.Reader.isTarget64bit ? offset64 : offset32
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        variableGetAddress()
        {
            return MemoryReader.Reader.read(this.ParentObj.GetAddress() + this.Offset, MemoryReader.Reader.ptrType)
        }

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

        staticGetAddress()
        {
            return this.CachedAddress
        }

        Address[]
        {
            get
            {
                if this.useCachedAddress
                    return this.CachedAddress
                g_Log.CreateEvent("Address.get")
                parentAddress := this.ParentObj.Address
                address := MemoryReader.Reader.read(parentAddress + this.Offset, MemoryReader.Reader.ptrType)
                if (address != this.CachedAddress)
                {
                    g_Log.AddData("Read", parentAddress . "+" . this.Offset . "=" . address)
                    g_Log.AddData("ConsecutiveReads", this.ConsecutiveReads)
                    this.ConsecutiveReads := 0
                }
                else
                    this.ConsecutiveReads += 1
                g_Log.EndEvent()
                return address
            }
        }
    }

    class Collection extends System.Object
    {
        NewChild(parent, type, offset)
        {
            if (type[1].__Class == "System.List")
                obj := new System.List(offset, offset, parent, type[2])
            else if (type[1].__Class == "System.DIctionary")
                obj := new System.Dictionary(offset, offset, parent, type[2], type[3])
            else
                obj := new type(offset, offset, parent)
            return obj
        }
    }

    ;item base is the memory class, and item type is the c# type
    class List extends System.Collection
    {
        __new(offset32, offset64, parentObject, itemType)
        {
            this.Offset := MemoryReader.Reader.isTarget64bit ? offset64 : offset32
            this.ParentObj := parentObject
            this.GetAddress := this.variableGetAddress
            this.List := new System.Object(offset32, offset64, parentObject)
            this._items := new System.Object(0x8, 0x10, this)
            this._size := new System.Int32(0xC, 0x18, this)
            this.ItemOffsetBase := MemoryReader.Reader.isTarget64bit ? 0x20 : 0x10
            this.ItemOffsetStep := MemoryReader.Reader.isTarget64bit ? 0x8 : 0x4
            this.ItemType := itemType
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this 
        }
        
        Size()
        {
            return this._size.GetValue()
        }

        GetItemOffset(index)
        {
            return this.ItemOffsetBase + (index * this.ItemOffsetStep)
        }

        Item[index]
        {
            get
            {
                return this.NewChild(this._items, this.ItemType, this.GetItemOffset(index))
            }
        }
    }

    class Dictionary extends System.Collection
    {
        __new(offset32, offset64, parentObject, keyType, valueType)
        {
            this.Offset := MemoryReader.Reader.isTarget64bit ? offset64 : offset32
            this.ParentObj := parentObject
            this.GetAddress := this.variableGetAddress
            this.Dict := new System.Object(offset32, offset64, parentObject)
            this.entries := new System.Object(0xC, 0x10, this)
            this.count := new System.Int32(0x20, 0x18, this)
            this.KeyOffsetBase := MemoryReader.Reader.isTarget64bit ? 0x28 : 0x18
            this.ValueOffsetBase := MemoryReader.Reader.isTarget64bit ? 0x30 : 0x1C
            this.OffsetStep := MemoryReader.Reader.isTarget64bit ? 0x18 : 0x10
            this.KeyType := keyType
            this.ValueType := valueType
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        Key[index]
        {
            get
            {
                return this.NewChild(this.entries, this.KeyType, this.GetKeyOffset(index))
            }
        }

        Value[index]
        {
            get
            {
                return this.NewChild(this.entries, this.ValueType, this.GetValueOffset(index))
            }
        }

        GetKeyOffset(index)
        {
            return this.KeyOffsetBase + (index * this.OffsetStep)
        }

        GetValueOffset(index)
        {
            return this.ValueOffsetBase + (index * this.OffsetStep)
        }

        GetIndexFromKey(key)
        {
            count := this.count.GetValue()
            if !count
                return -1
            i := 0
            loop %count%
            {
                if (key == this.Key[i])
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
                if (value == this.Value[i])
                    return i
                ++i
            }
            return -1
        }
    }

    class Value extends System.Object
    {
        prevValue := ""

        GetValue()
        {
            return MemoryReader.Reader.read(this.ParentObj.GetAddress() + this.Offset, this.Type)
        }

        SetValue(value)
        {
            return MemoryReader.Reader.write(this.ParentObj.GetAddress() + this.Offset, value, this.Type)
        }

        Value[]
        {
            get
            {
                g_Log.CreateEvent("Value.get")
                parentAddress := this.ParentObj.Address
                value := MemoryReader.Reader.read(parentAddress + this.Offset, this.Type)
                if (value != this.prevValue)
                {
                    g_Log.AddData("Read", parentAddress . "+" . this.Offset . "=" . value)
                    this.prevValue := value
                }
                g_Log.EndEvent()
                return value
            }

            ;return values: non zero == success, 0 == fail, null == invalid type
            set
            {
                g_Log.CreateEvent("Value.set")
                parentAddress := this.ParentObj.Address
                retValue := MemoryReader.Reader.write(parentAddress + this.Offset, value, this.Type)
                g_Log.AddData("Write", parentAddress . "+" this.Offset ":=" value)
                if retValue
                    g_Log.AddData("retValue", retValue)
                else if (retValue == 0)
                {
                    g_Log.AddData("ErrorLevel", ErrorLevel)
                    g_Log.AddData("A_LastError", A_LastError)
                }
                else
                    g_Log.AddData("type", this.Type)
                g_Log.EndEvent()
                return retValue
            }
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

    class String extends System.Object
    {
        __new(offset32, offset64, parentObj)
        {
            this.Offset := MemoryReader.Reader.isTarget64bit ? offset64 : offset32
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.Length := new System.Int32(0x8, 0x10, this)
            this.Value := {}
            this.Value.Offset := MemoryReader.Reader.isTarget64bit ? 0x14 : 0xC
            this.prevValue := ""
            this.CachedAddress := ""
            this.ConsecutiveReads := 0
            return this
        }

        GetValue()
        {
            baseAddress := this.GetAddress()
            return MemoryReader.Reader.readstring(baseAddress + this.Value.Offset, 0, "UTF-16")
        }

        SetValue(value)
        {
            length := StrLen(value)
            this.Length.SetValue(length)
            baseAddress := this.GetAddress()
            return MemoryReader.Reader.writestring(baseAddress = this.Value.Offset, value, "UTF-16")
        }

        String[]
        {
            get
            {
                g_Log.CreateEvent("String.get")
                baseAddress := this.Address
                value := MemoryReader.Reader.readstring(baseAddress + this.Value.Offset, 0, "UTF-16")
                if (value != this.prevValue)
                {
                    g_Log.AddData("Read", baseAddress . "+" . this.Value.Offset . "=" . value)
                    this.prevValue := value
                }
                g_Log.EndEvent()
                return value
            }

            ;return values: non zero == success, 0 == fail, null == invalid type
            set
            {
                g_Log.CreateEvent("String.set")
                length := StrLen(value)
                this.Length.Value := length
                baseAddress := this.Address
                retValue := MemoryReader.Reader.writestring(baseAddress = this.Value.Offset, value, "UTF-16")
                g_Log.AddData("Write", baseAddress . "+" this.Value.Offset ":=" value)
                if retValue
                    g_Log.AddData("retValue", retValue)
                else if (retValue == 0)
                {
                    g_Log.AddData("ErrorLevel", ErrorLevel)
                    g_Log.AddData("A_LastError", A_LastError)
                }
                else
                    g_Log.AddData("type", this.Type)
                g_Log.EndEvent()
                return retValue
            }
        }
    }

    class Enum extends System.Value
    {
        __new(offset32, offset64, parentObject)
        {
            this.isEnum := true ;this is hokey fix for tree view to differentiate enums from pointers, but I'm lazy right now.
            this.Offset := MemoryReader.Reader.isTarget64bit ? offset64 : offset32
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
            return MemoryReader.Reader.read(MemoryReader.ModuleBaseAddress + this.Offset, MemoryReader.Reader.ptrType)
        }
    }
}