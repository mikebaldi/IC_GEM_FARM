class _MemoryLogHandler extends _Contained
{
    __new()
    {
        this.dict := {}
        return this
    }

    Add(obj, name)
    {
        if (obj.isEnum)
            this.dict[name] := new _MemoryLogHandler._FieldEnum(obj, name)
        else
            this.dict[name] := new _MemoryLogHandler._Field(obj, name)
        this[name] := this.dict[name]
        return
    }

    Remove(name)
    {
        this.dict.Delete(name)
        this.Delete(name)
        return
    }

    ResetPrevValues()
    {
        for k, v in this.dict
        {
            v.ResetPrevValue()
        }
    }

    class _Field
    {
        __new(obj, fieldName)
        {
            this.obj := obj
            this.prevValue := ""
            this.Name := fieldName
            return this
        }

        ResetPrevValue()
        {
            this.prevValue := ""
        }

        Value[]
        {
            get
            {
                value := this.obj.GetValue()
                if (value != this.prevValue)
                {
                    this.prevValue := value
                    g_Log.AddData(this.Name, value)
                }
                return value
            }

            set
            {
                if !(this.obj.doLog)
                    return this.obj.SetValue(value)
                else
                    return this.obj.LogSetValue(value)
            }
        }
    }

    class _FieldEnum extends _MemoryLogHandler._Field
    {
        Value[]
        {
            get
            {
                value := this.obj.GetValue()
                if (value != this.prevValue)
                {
                    this.prevValue := value
                    g_Log.AddData(this.Name, value . "->" . this.obj.Enum[value])
                }
                return value
            }

            set
            {
                if !(this.obj.doLog)
                    return this.obj.SetValue(value)
                else
                    return this.obj.LogSetValue(value)
            }
        }
    }
}