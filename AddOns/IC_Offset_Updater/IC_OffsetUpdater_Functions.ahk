class UpdateMemoryStructures
{
    exportFileName := "ScriptHubExport.json"
    structureFiles := ["IdleGameManager.ahk", "ActiveEffectHandlers.ahk"]
    structurePath := "\..\..\..\SharedFunctions\MemoryRead2\Structures\"

    __new(platform)
    {
        this.StartTime := A_TickCount
        if (platform == "Steam")
        {
            this.isSteam := true
            this.exportFileName := "32-" . this.exportFileName
        }
        else if (platform == "EGS")
        {
            this.isSteam := false
            this.exportFileName := "64-" . this.exportFileName
        }
        else
            ExceptionHandler.ThrowFatalError("Parameter string must be 'Steam' or 'EGS'.`nInvalid Parameter: " . platform, -2)

        file := FileOpen(A_linefile . this.structurePath . this.exportFileName, "r")
        if !file
                ExceptionHandler.ThrowFatalError("Could not find file.`nfile: " . this.exportFileName . "`nPath: " . A_linefile . this.structurePath, -2)
        this.data := JSON.parse(file.Read())
        file.Close()
        this.UpdateStructureFiles2()
    }

    UpdateStructureFiles2()
    {
        count := this.structureFiles.Count()
        loop, %count%
        {
            fullFilePath := A_LineFile . this.structurePath . this.structureFiles[A_Index]
            file := FileOpen(fullFilePath, "r")
            structString := file.Read()
            file.Close()
            if !structString
            {
                ExceptionHandler.ThrowError("Could not find file.`nfile: " . fullFilePath, -2)
                continue
            }
            currentPos := InStr(structString, ";FB-")
            while currentPos
            {
                ;read class name
                classNamePos := RegExMatch(structString, ".+", className, currentPos + 4)
                ;log error if issues with class name
                if !classNamePos
                {
                    string := ";Failed to match a classname. currentPos: " . currentPos . "`n"
                    structString := RegExReplace(structString, "\n", string,,1, currentPos)
                    continue
                }
                if !(this.data.classes.HasKey(className))
                {
                    string := ";Failed to find class name in data file. Class Name: " . className . "`n"
                    structString := RegExReplace(structString, "\n", string,,1, currentPos)
                    continue
                }
                ;extract field block
                fieldPos := RegExMatch(structString, "s)(?<=;FB-).*?(?=;FE)", fieldBlock, currentPos)
                ;update field block
                structString := RegExReplace(structString, "s)(?<=;FB-).*?(?=;FE)", this.UpdateFieldBlock(fieldBlock, this.data.classes[className]),,1, currentPos)
                ;move to next field block
                currentPos := InStr(structString, ";FB-",, currentPos + 4)
            }
            fileName := RegExReplace(fullFilePath, "i).ahk", "-REV.ahk")
            FileDelete, %fileName%
            file := FileOpen(fileName, "w")
            elapsedTime := A_TickCount - this.StartTime
            elapsedMins := elapsedTime / 60000
            structString .= "`n;Processing Time (minutes): " . elapsedMins
            file.Write(structString)
            file.Close()
            this.StartTime := A_TickCount
        }
        msgbox, Offset Update Complete
    }

    UpdateFieldBlock(fieldBlock, klass)
    {
        currentPos := RegExMatch(fieldBlock, "s)(?<=\n).*?(?=\n)", currentLine)
        while currentPos
        {
            fieldBlock := RegExReplace(fieldBlock, "s)(?<=\n).*?(?=\n)", this.UpdateFieldLine(currentLine, klass.fields),,1, currentPos)
            currentPos := RegExMatch(fieldBlock, "s)(?<=\n).*?(?=\n)", currentLine, currentPos + 1)
        }
        return fieldBlock
    }

    UpdateFieldLine(line, fields)
    {
        ;get field name
        fieldNamePos := RegExMatch(line, "s)(?<=\s)\w*?(?= :=)", fieldName)
        if !(fields.HasKey(fieldName))
        {
            ;check if it is a backingfield
            fieldName := "<" . fieldName . ">k__Backingfield"
            if !(fields.HasKey(fieldName))
            {
                return line . " `;Failed to find field name in export file. fieldName: " . fieldName
            }
        }
        ;replace type
        if !(InStr(line, ";OR-TYPE"))
        {
            typePos := RegExMatch(line, "s)(?<=new ).*?(?=\()", type)
            line := this.UpdateFieldType(line, type, fields[fieldName].type)
        }
        ;replace offset
        if (this.isSteam)
            line := RegExReplace(line, "s)(?<=\().*?(?=,)", fields[fieldName].offset)
        else
            line := RegExReplace(line, "s)(?<=, ).*?(?=, this)", fields[fieldName].offset)
        return line
    }

    ;need to update this for dictionary
    UpdateFieldType(line, structType, fieldType)
    {
        ;update list types
        if RegExMatch(fieldType, "^System.Collections.Generic.List")
        {
            ;updates declaration
            line := RegExReplace(line, structType, "System.List")
            itemTypePos := RegExMatch(fieldType, "s)(?<=<).*?(?=>$)", itemType)
            ;updates parameters
            line := RegExReplace(line, "s)(?<=this).*?(?=\))", this.UpdateCollectionType(itemType))
        }
        ;update dict types
        else if RegExMatch(fieldType, "^System.Collections.Generic.Dict")
        {
            ;updates declaration
            line := RegExReplace(line, structType, "System.Dictionary")
            ;updates parameters
            keyTypePos := RegExMatch(fieldType, "s)(?<=<).*?(?=,)", keyType)
            valueTypePos := RegExMatch(fieldType, "s)(?<=,).*?(?=>$)", valueType)
            collectionTypeString := this.UpdateCollectionType(keyType) . this.UpdateCollectionType(valueType)
            ;updates parameters
            line := RegExReplace(line, "s)(?<=this).*?(?=\))", collectionTypeString)
        }
        ;update any other type that doesn't have <>
        else if !(InStr(type, "<"))
            line := RegExReplace(line, structType, fieldType)
        return line
    }

    UpdateCollectionType(type)
    {
        ;nothing special about type
        if !(InStr(type, "<"))
            return ", " . type
        ;type is a list
        else if RegExMatch(type, "^System.Collections.Generic.List")
        {
            itemTypePos := RegExMatch(type, "s)(?<=<).*?(?=>)", itemType)
            type := this.UpdateCollectionType(itemType)
            return ", [System.List" . type . "]"
        }
        ;type is dictionary
        else if RegExMatch(type, "^System.Collections.Generic.Dict")
        {
            collectionTypePos := RegExMatch(type, "s)(?<=<).*?(?=>)", collectionType)
            keyTypePos := RegExMatch(type, "s)(?<=<).*?(?=,)", keyType)
            valueTypePos := RegExMatch(type, "s)(?<=,).*?(?=>$)", valueType)
            collectionTypeString := this.UpdateCollectionType(keyType) . this.UpdateCollectionType(valueType)
            return ", [System.Dictionary" . collectionTypeString . "]"
        }
        return type
    }

    UpdateStructureFiles()
    {
        count := this.structureFiles.Count()
        loop, %count%
        {
            file := FileOpen(this.structureFiles[A_Index], "r")
            if !file
            {
                ;ExceptionHandler.ThrowError("Could not find file.`nfile: " . this.structureFiles[A_Index], -2)
                continue
            }
            structString := file.Read()
            file.Close()
            currentPos := 1
            while currentPos
            {
                fieldPos := RegExMatch(structString, "s)(?<=;FB-).*?(?=;FE)", fields, currentPos)
                if !fieldPos
                    break
                replacement := this.UpdateFields(fields)
                structString := RegExReplace(structString, fields, replacement)
                currentPos := InStr(structString, ";FB-",, fieldPos)
            }
        }
    }

    UpdateFields(fieldsString)
    {
        errorString := ""
        classNamePos := RegExMatch(fieldsString, ".+", className)
        if !classNamePos
        {
            ;ExceptionHandler.ThrowError("Failed to find class name in fields string`nfields string: " . fieldsString, -2)
            return ";Failed to find class name in fields:`n" . fieldsString
        }
        if !(this.data.classes.HasKey(className))
        {
            ;ExceptionHandler.ThrowError("Failed to find class name in data file.`nclassName: " . className, -2)
            return ";Failed to find class name in data file. Class Name: " . className . "`n" . fieldsString
        }
        klass := this.data.classes[className]
        currentPos := 1
        while currentPos
        {
            nextPos := RegExMatch(fieldsString, "s)(?<=\n).*?(?=\n)", currentLine, currentPos)
            if InStr(currentLine, ";OR")
            {
                isOverride := true
                ;override stuff
                nextPos := RegExMatch(fieldsString, "s)(?<=\n).*?(?=\n)", currentLine, currentPos)
            }
            fieldNamePos := RegExMatch(currentLine, "s)(?<=\s)\w*?(?= :=)", fieldName)
            if !fieldNamePos
                break
            if !(klass.fields.HasKey(fieldName))
            {
                ;ExceptionHandler.ThrowError("Failed to find field name in data file.`nField Name: " . fieldName, -2)
                errorString .= ";Failed to find field name in data file.`nField Name: " . fieldName
                continue
            }
            replacement := this.UpdateFieldLine(currentLine, klass.fields[fieldName])
            fieldsString := RegExReplace(fieldsString, currentLine, replacement)
            isOverride := false
        }
        return fieldString . errorString
    }

    ;enumerate through memory structure for begining of each branch.
    CheckStructure(obj)
    {
        ;no point in parsing the wrong type of object
        if (obj.__Class != "MemoryStructures")
            this.ThrowError(A_ThisFunc . ": Parameter 1 not type MemoryStructures", -2)
        for k, v in obj
        {
            if (v.__Class == "MemoryObject" AND !(v.ParentObj))
                this.CheckMonoData(v, "")
        }
    }

    ;enumerate through a branch and compare and update saved offset and type to exported mono data
    CheckMonoData(obj := "", field := "field name of beginning of branch")
    {
        ;you can still pass null, just a check to make sure something is passed
        ;in theory what is passed shouldn't have a ParentObj so should never parse
        if (field == "field name of beginning of branch")
            this.ThrowError(A_ThisFunc . ": Missing parameter 2", -2)
        ;no point in parsing the wrong type of object
        if (obj.__Class != "MemoryObject")
            this.ThrowError(A_ThisFunc . ": Parameter 1 not type MemoryObject", -2)
        ;get to end of branch then work backwards
        for k, v in obj
        {
            if (IsObject(v.ParentObj) AND k != "ParentObj")
                this.CheckMonoData(v, k)
        }
        ;made it back to begining of branch, can return
        if !(obj.ParentObj)
            return
        ;have to figure out this list/dict type stuff
        isListOrDict := this.IsListDictType(typeName)
        if isListOrDict
            this.GetListOrDictType(typeName, isListOrDict)
        ;locate our field in the mono data
        fieldPos := this.GetFieldPosMono(obj.ParentObj.Type, field)
        ;get offset value
        offsetPos := RegExMatch(this.MonoData, "[a-zA-Z0-9]+", offset, fieldPos - 4)
        offset := "0x" . offset
        if (offset != obj.Offset)
            this.UpdateOffset(obj, field, offset)
        ;get type
        typeNamePos := RegExMatch(this.MonoData,"\(.+\)", typeName, fieldPos + 3)
        typeName := Trim(typeName, "(type: ")
        typeName := Trim(typeName, ")")
        ;check if is generic system type to read, i.e. not a pointer
        ;have to think about changing this whole system of types kind of confusing to use classmemory type here
        ;could potentially change memory object class to be dfined as blank and this will pick up the type name.
        ;then a separate method can convert actual type to class memory type.
        ;if InStr(typeName, "System")
        ;{
        ;    typeName := this.NewSystemType(typeName)
        ;}
        if (typeName != obj.Type)
            this.UpdateType(obj, field, typeName)
        return
    }

    UpdateType(obj, field, typeName)
    {
        currentPos := this.GetParamsPosMemory(field)
        ;move to correct param
        currentPos := InStr(this.MemoryData, ",",, currentPos, 2)
        string := RegExReplace(this.MemoryData, obj.Type, typeName,, 1, currentPos)
        if (string == this.MemoryData)
            this.ThrowError(A_ThisFunc . ": Type failed to update`nType: " . typeName . "`nField: " . field, -2)
        else
            this.MemoryData := string
        this.dataModified := true
        return
    }

    NewSystemType(typeName)
    {
        ;static GenericTypeSize := [ "Char", "UChar", "Short", "UShort", "Int", "UInt", "Int64", "UInt64", "Float", "UFloat", "Double" ]
        static GenericTypeSize :=   {   "Byte": "Char",     "UByte": "UChar"
                                    ,   "Short": "Short",   "UShort": "UShort"
                                    ,   "Int32": "Int",     "UInt32": "UInt"
                                    ,   "Int64": "Int64",   "UInt64": "UInt64"
                                    ,   "Single": "Float",  "USingle": "UFloat"
                                    ,   "Double": "Double", "Boolean": "Char"}
        
        /* following block should be superflous if the regexmatch below works
        ;remove namespace from typeName
        isDot := InStr(typeName, ".")
        if isDot
        {
            length := StrLen(typeName)
            currentPos := 1
            i := 1
            while (isDot)
            {
                currentPos := isDot + 1
                isDot := InStr(typeName, ".",, currentPos)
            }
            typeName := SubStr(typeName, currentPos)
        }
        */

        ;returns position of final type if only letters and numbers (no dict or list), which is all we care about for generic types. saves type in typeNameGeneric
        typeNamePos := RegExMatch(typeName, "[a-zA-Z0-9]+\Z", typeNameGeneric)
        if typeNameGeneric
            size := GenericTypeSize[typeNameGeneric]
        if size
            return size
        else
            return typeName
    }

    UpdateOffset(obj, field, offset)
    {
        ;get to params
        currentPos := this.GetParamsPosMemory(field)
        ;if 64 bit move to comma
        if obj.Is64Bit
            currentPos := InStr(this.MemoryData, ",",, currentPos)
        offsetString := Format("0x{:x}", offset) . ","
        string := RegExReplace(this.MemoryData, "[a-zA-Z0-9]+,", offsetString,,1, currentPos)
        if (string == this.MemoryData)
            this.ThrowError(A_ThisFunc . ": Type failed to update`nType: " . typeName . "`nField: " . field, -2)
        else
            this.MemoryData := string
        this.dataModified := true
        return
    }

    GetParamsPosMemory(field)
    {
        ;example line from memory data: field := new MemoryObject(0x8, 0x10
        string := field . " := new MemoryObject("
        currentPos := InStr(this.MemoryData, string)
        if !currentPos
            this.ThrowError(A_ThisFunc . ": Failed to find field in memory data`nfield: " . field, -2)
        ;move to (
        currentPos += StrLen(string)
        return currentPos
    }

    GetFieldPosMono(typeName, field)
    {
        originalTypeName := typeName
        found := false
        while !found
        {
            ;check if we are stuck in this loop
            if (A_index > 10)
                this.ThrowError(A_ThisFunc . ": Failed to find field in mono data after 10 attempts`nfield: " . field . "`ntypeName: " . originalTypeName, -2)
            ;get to correct type in the mono data file
            typePos := this.GetTypePosMono(typeName, field)
            ;go past static fields to fields
            currentPos := InStr(this.MonoData, "fields",, typePos, 2)
            ;find position of methods, to later check if we went to far to find our field
            methodPos := InStr(this.MonoData, "methods",, currentPos)
            ;find our particular field
            fieldPos := InStr(this.MonoData, " : " . field,, currentPos)
            ;check that we didn't go past the end of the field list for our type and could find the field
            ;this should only trigger if the field is inherited from the base object
            if (fieldPos > methodPos OR !fieldPos)
            {
                ;we did so hopefully the field is in the base type
                typeName := this.GetBaseType(currentPos, typeName)
            }
            else
                found := true
        }
        return fieldPos
    }

    GetBaseType(currentPos, typeName)
    {
        ;move to base class
        currentPos := InStr(this.MonoData, "base class",, currentPos)
        ;move to base class namespace and name (typeName)
        currentPos := InStr(this.MonoData, " : ",, currentPos)
        baseTypeNamePos := RegExMatch(this.MonoData,".+", baseTypeName, currentPos + 3)
        if !baseTypeNamePos
            this.ThrowError(A_ThisFunc . ": Failed to find base type in mono data`ntypeName: " . typeName, -2)
        return baseTypeName
    }

    GetTypePosMono(typeName, field)
    {
        ;modify type string to work with RegEx
        typeNameMod := RegExReplace(typeName, "\.", "\.")
        ;get to location of type in mono data
        ;new line, two white spaces, a hex value w/o 0x prefix, whitespace, ":", whitespace, typename modified, white space
        typePos := RegExMatch(this.MonoData, "\R\s\s[a-zA-Z0-9]+\s:\s" . typeNameMod . "\s", typeMatch)
        if !typePos
            this.ThrowError(A_ThisFunc . ": Failed to match type in mono data`ntypeName: " . typeNameMod "`nfield: " . field, -2)
        return typePos
    }

    GetListorDictType(typeName, isListOrDict)
    {
        ;get past System.Collections.Generic.List/Dictionary<
        startPos := InStr(typeName, "<") + 1
        if (isListOrDict == "List")
        {
            return SubStr(typeName, startPos, StrLen(typeName) - 1)
        }
        ;move to value
        currentPos := InStr(typeName, ",",, startPos)
    }

    IsListDictType(typeName)
    {
        listPos := RegExMatch(typeName, "^System.Collections.Generic.List", dictMatch)
        if listPos
            return "List"
        dictPos := RegExMatch(typeName, "^System.Collections.Generic.Dictionary", dictMatch)
        if dictPos
            return "Dict"
        return false
    }

    ThrowError(message, level)
    {
        try
            throw Exception(message, level)
        catch e
        {
            position := RegExMatch(e.File, "[^\\]+\.ahk", match)
            msgbox % "Error: " e.Message "`nLine# " e.Line "`nFile: " match "`nExiting App"
            ExitApp
        }
    }
}

LoadObjectFromJSON( FileName )
{
    FileRead, oData, %FileName%
    return JSON.parse( oData )
}

WriteObjectToJSON( FileName, ByRef object )
{
    objectJSON := JSON.stringify( object )
    objectJSON := JSON.Beautify( objectJSON )
    FileDelete, %FileName%
    FileAppend, %objectJSON%, %FileName%
    return
}