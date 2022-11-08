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
            else if (this.Type[1].__Class == "System.Dictionary")
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
            this.OffsetStep := System.valueTypeBytes.HasKey(this.Type.Type) ? System.valueTypeBytes[this.Type.Type] : 0x8
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
            this.Keys := new System._KeyCollection(this.entries, keyType)
            keySize := System.valueTypeBytes.HasKey(keyType.Type) ? System.valueTypeBytes[keyType.Type] : 0x8
            this.Values := new System._ValueCollection(this.entries, valueType)
            valueSize := System.valueTypeBytes.HasKey(valueType.Type) ? System.valueTypeBytes[valueType.Type] : 0x8
            if (valueSize == 4 and keySize == 4)
            {
                this.Values.OffsetBase := 0x2C
                this.Values.OffsetStep := 0x10
                this.Keys.OffsetStep := 0x10
            }
            else
            {
                this.Values.OffsetBase := 0x30
                valueSize := this.Values.Type == Engine.Numeric.Quad ? 0x10 : 0x8
                this.Values.OffsetStep := 0x10 + valueSize
                this.Keys.OffsetStep := 0x10 + valueSize
            }
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
        static Type := "Char"
    }

    class UByte extends System.Value
    {
        static Type := "UChar"
    }

    class Short extends System.Value
    {
        static Type := "Short"
    }

    class UShort extends System.Value
    {
        static Type := "UShort"
    }

    class Int32 extends System.Value
    {
        static Type := "Int"
    }

    class UInt32 extends System.Value
    {
        static Type := "UInt"
    }

    class Int64 extends System.Value
    {
        static Type := "Int64"
    }

    class UInt64 extends System.Value
    {
        static Type := "Int64"
    }

    class Single extends System.Value
    {
        static Type := "Float"
    }

    class USingle extends System.Value
    {
        static Type := "UFloat"
    }

    class Double extends System.Value
    {
        static Type := "Double"

        ToString(value)
        {
            if (value == "0" OR value == "Infinity" OR value == "-Infinity" OR value == "NaN")
                return value
            else if (value > 100000)
                return format("{:.2e}", value)
            else
                return value
        }
    }

    class Boolean extends System.Value
    {
        static Type := "Char"
    }

    class Struct
    {
        class Int32 extends System.Object
        {
            m_value := new System.Int32(0x10, this)
        }
    }

    class Quad extends System.Object
    {
        specialStringTable := ["0", "Infinity", "-Infinity", "NaN"]
        static Type := "Quad"

        __new(offset, parentObj)
        {
            this.Offset := offset
            this.GetAddress := this.variableGetAddress
            this.ParentObj := parentObj
            this.SignificandBits := new System.UInt64(this.Offset, this.ParentObj)
            this.Exponent := new System.Int64(this.Offset + 8, this.ParentObj)
            return this
        }

        GetValue()
        {
            significandBits := this.SignificandBits.Value
            exponent := this.Exponent.Value
            
            if (exponent <= -9223372036854775805)
            {
                return this.specialStringTable[exponent - -9223372036854775808] ;to account for ahk array starting at 1, use long min + 1
            }

            ; the following is decompiled assembly c# dll converted to ahk. skipped over was the code for quad values that are in the range of double.
            SetFormat, Float, 0.15 ;maximum significant figures, 15. default is 6.
            string := ""
            num := significandBits & -9223372036854775808 ;sets first bit to sign and clears remaining, ahk uses signed int64
            num2 := (1086 - 61) << 52 ;moves exponent to next 11 bits, not sure why 1086 constant is needed. 61 is for the digits in significandBits
            num3 := (significandBits & 9223372036854775807) >> 11 ;clear first bit, then move rest over 11 bits
            num4 := num | num2 | num3 ;combine all to a single value
            ;next three setps convert the int64 bits to double. need to look into memory clean up for myVar
            VarSetCapacity(myVar, 8, 0) ;create a 64 bit variable
            NumPut(num4, MyVar, 0, "Int64")
            significandBitsDouble := NumGet(myVar,0,"Double") ;significandBits converted to a double

            if (significandBitsDouble < 0.0)
            {
                string .= "-"
                significandBitsDouble *= -1
            }
            exponent += 61 ;adding the digits from significandBits
            exponent *= 0.3010299956639812 ;factor to convert from base 2 to base 10
            exponentInt := floor(exponent)
            exponentDec := exponent - exponentInt
            significand := significandBitsDouble * (10**exponentDec)
            ;make sure signifand is single digit decimal still
            while (significand >= 10.0)
            {
                exponentInt++
                significand /= 10.0
            }
            while (significand < 1.0)
            {
                exponentInt--
                significand *= 10.0
            }
            significand := Round(significand, 3)
            string .= significand . "e" . exponentInt
            SetFormat, Float, 0.6
            return string
        }

        ;essentially does what other getvalue method does, just with less code, but potentially less accurate. with just 2 digits they appear to be same.
        GetValue2()
        {
            FirstEight := this.SignificandBits.Value
            SecondEight := this.Exponent.Value

            if (SecondEight <= -9223372036854775805)
            {
                return this.specialStringTable[SecondEight - -9223372036854775808] ;to account for ahk array starting at 1, use long min + 1
            }
            f := log( FirstEight + ( 2.0 ** 63 ) )
            decimated := ( log( 2 ) * SecondEight ) + f
            exponent := floor( decimated )
            significand := round( 10 ** ( decimated - exponent ), 2 )
            if(exponent < 4 AND exponent > -4)
                return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 0) . ""

            return significand . "e" . exponent
        }

        Value[]
        {
            get
            {
                return this.GetValue()
            }
        }
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
                                ,   "System.Int64": "Int64",   "System.UInt64": "Int64"
                                ,   "System.Single": "Float",  "System.USingle": "UFloat"
                                ,   "System.Double": "Double", "System.Boolean": "Char"}

    static valueTypeBytes :=    {"Char": 0x4, "UChar": 0x4, "Short": 0x4, "UShort": 0x4, "Int": 0x4, "UInt": 0x4, "Int64": 0x8, "UInt64": 0x8
                                ,"Float": 0x4, "UFloat": 0x4, "Double": 0x8, "Char": 0x4, "Quad": 0x10}

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

class Engine
{
    class Numeric
    {
        class Quad extends System.Object
        {
            specialStringTable := ["0", "Infinity", "-Infinity", "NaN"]
            static Type := "Quad"

            __new(offset, parentObj)
            {
                this.Offset := offset
                this.GetAddress := this.variableGetAddress
                this.ParentObj := parentObj
                this.SignificandBits := new System.UInt64(this.Offset, this.ParentObj)
                this.Exponent := new System.Int64(this.Offset + 8, this.ParentObj)
                return this
            }

            GetValue()
            {
                significandBits := this.SignificandBits.Value
                exponent := this.Exponent.Value
                
                if (exponent <= -9223372036854775805)
                {
                    return this.specialStringTable[exponent - -9223372036854775808] ;to account for ahk array starting at 1, use long min + 1
                }

                ; the following is decompiled assembly c# dll converted to ahk. skipped over was the code for quad values that are in the range of double.
                SetFormat, Float, 0.15 ;maximum significant figures, 15. default is 6.
                string := ""
                num := significandBits & -9223372036854775808 ;sets first bit to sign and clears remaining, ahk uses signed int64
                num2 := (1086 - 61) << 52 ;moves exponent to next 11 bits, not sure why 1086 constant is needed. 61 is for the digits in significandBits
                num3 := (significandBits & 9223372036854775807) >> 11 ;clear first bit, then move rest over 11 bits
                num4 := num | num2 | num3 ;combine all to a single value
                ;next three setps convert the int64 bits to double. need to look into memory clean up for myVar
                VarSetCapacity(myVar, 8, 0) ;create a 64 bit variable
                NumPut(num4, MyVar, 0, "Int64")
                significandBitsDouble := NumGet(myVar,0,"Double") ;significandBits converted to a double

                if (significandBitsDouble < 0.0)
                {
                    string .= "-"
                    significandBitsDouble *= -1
                }
                exponent += 61 ;adding the digits from significandBits
                exponent *= 0.3010299956639812 ;factor to convert from base 2 to base 10
                exponentInt := floor(exponent)
                exponentDec := exponent - exponentInt
                significand := significandBitsDouble * (10**exponentDec)
                ;make sure signifand is single digit decimal still
                while (significand >= 10.0)
                {
                    exponentInt++
                    significand /= 10.0
                }
                while (significand < 1.0)
                {
                    exponentInt--
                    significand *= 10.0
                }
                significand := Round(significand, 3)
                string .= significand . "e" . exponentInt
                SetFormat, Float, 0.6
                return string
            }

            ;essentially does what other getvalue method does, just with less code, but potentially less accurate. with just 2 digits they appear to be same.
            GetValue2()
            {
                FirstEight := this.SignificandBits.Value
                SecondEight := this.Exponent.Value

                if (SecondEight <= -9223372036854775805)
                {
                    return this.specialStringTable[SecondEight - -9223372036854775808] ;to account for ahk array starting at 1, use long min + 1
                }
                f := log( FirstEight + ( 2.0 ** 63 ) )
                decimated := ( log( 2 ) * SecondEight ) + f
                exponent := floor( decimated )
                significand := round( 10 ** ( decimated - exponent ), 2 )
                if(exponent < 4 AND exponent > -4)
                    return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 0) . ""

                return significand . "e" . exponent
            }

            Value[]
            {
                get
                {
                    return this.GetValue()
                }
            }
        }
    }
}