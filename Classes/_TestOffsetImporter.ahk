;to be updated
;add handler for nullable types.
;GENERAL REGEX NOTES
;^ is for start of string. "^System" will look for System at the start of the string. "xSystem" would not match. "Systemx" would

;TO DO - FIX TYPE PARSER SO IT DOESNT ELIMINATE ARRAYS

#include _ExceptionHandler.ahk
#include json.ahk

test := new _MemoryStructureExporter("IdleGameManager")

; create an object to represent the export
; heirarchy:
; class name : class obj
; class obj contains class data: name as saved in the json, name to be used for the export, parent name as sved in the json,
;   parent name to be used for the export, a fields library, nested classes
; field name : field obj
; field obj contains field data: offset and type obj. type to be used for the export, and params, if any.

; as any data with type is read in it must be processed to be used in export and keep trackof what has been processed and what is to be processed.

; start by taking in a class
; look at the parent to find the static base object, should be system.object, but may not make it that far back.
; all parent types with no entry in the json should be treated as having a parent of system.object and essentially be added as blanks
; all types processed are added to dict 'to be added' using the json saved name
; also they are to be added to the dict that keeps track of modified types, dict<json name, modified name>
; 

class _MemoryStructureExporter
{
    exportFileName := "ScriptHubExport.json"
    structurePath := "\..\Memory\Structures\"
    ClassesToAdd := {} ; array of string names of classes to add
    ClassesAdded := {} ; dictionary<string, bool>, class name : has been added
    SystemClasses := {} ; dictionary<string, bool>, system class name : was encountered
    cleanClasses := {} ; dictionary<string, string>, clean class name : exported class name
    processedData := {}

    __new(klassName)
    {
        file := FileOpen(A_linefile . this.structurePath . this.exportFileName, "r")
        if !file
        {
            ExceptionHandler.ThrowFatalError("Could not find file.`nfile: " . this.exportFileName . "`nPath: " . A_linefile . this.structurePath, -2)
        }
        this.data := JSON.parse(file.Read())
        file.Close()       
        this.AddClass(klassName)
        while % this.ClassesToAdd.Count()
        {
            ; check to make sure class wasn't already added
            klass := this.ClassesToAdd.RemoveAt(1)
            if (this.ClassesAdded[klass])
            {
                continue
            }
            this.AddClass(klass)
        }
        type := klassName
        loop
        {
            parent := this.data.classes[type].Parent
            if (parent == "System.Object" OR parent == "")
            {
                this.StaticBase := type
                break
            }
            type := parent
        }
        
        fileName := A_LineFile . this.structurePath . type . "Test.JSON"
        FileDelete, %fileName%
        file := FileOpen(fileName, "w")
        string := JSON.stringify( this.processedData )
        file.Write(string)
        file.Close()
    }

    AddClass(klassName)
    {
        ; check if already added
        if (this.classesAdded[klassName])
        {
            return
        }
        obj := {}
        ; check the type is a format we can work with
        cleanKlassName := this.CleanClassName(klassName)
        ; do stuff to find shortname and add parents to struct
        if InStr(cleanKlassName, ".")
        {
            array := StrSplit(cleanKlassName, ".") ; can include empty entries, especially at end.
            loop % array.Count()
            {
                if (array[A_Index] == "")
                {
                    array.Delete(A_index)
                }
            }
            shortName := array[array.Count()]
            if !IsObject(this.processedData[array[1]])
            {
                this.processedData[array[1]] := {}
            }
            obj := this.processedData[array[1]]
            count := array.Count()
            i := 2
            loop % count - 1
            {
                if !IsObject(obj[array[i]])
                {
                    obj[array[i]] := {}
                }
                obj := obj[array[i]]
                i++
            }
        }
        else
        {
            shortName := cleanKlassName
            processedName := cleanKlassName
            this.processedData[shortName] := {}
            obj := this.processedData[shortName]
        }
        obj.Name := klassName
        obj.NameClean := cleanKlassName
        obj.NameShort := shortName
        ; check if klassName is in our data structure
        if !IsObject(this.data.classes[klassName])
        {
            obj.Parent := "System.Object"
            obj.ParentClean := "System.Object"
            obj.NotFoundInData := true
            obj.Fields := {}
        }
        else
        {
            obj.Parent := this.data.classes[klassName].Parent
            obj.ParentClean := this.CleanClassName(obj.Parent)
            obj.Fields := this.GetClassFields(klassName)
        }
        this.classesAdded[klassName] := true
        return
    }

    CleanClassName(klassName)
    {
        If (InStr(klassName, "System") == 1) ; the funky type[othertype] can sometimes have system types braced so look for system at begining only.
        {
            this.SystemClasses[klassName] := true
            return klassName
        }
        if !(this.classesAdded[klassName])
        {
            this.classesToAdd.Push(klassName)
        }
        ; <> and , should not be found in class name but lets check just to throw an error
        problemCharacters := ["<", ">"] ; cleaning params now so could have commas , ","]
        loop % problemCharacters.Count()
        {
            if InStr(klassName, problemCharacters[A_Index])
            {
                ExceptionHandler.ThrowFatalError("Found unexpected problem character in class name`nClass Name: " . klassName . "`nCharacter: " . problemCharacters[A_Index], -2)
            }
        }
        cleanKlassName := this.CleanString(klassName)
        ; if class name is cleaned, then add it to the clean classes dict
        if (klassName != cleanKlassName)
        {
            this.CleanClasses[cleanKlassName] := klassName
        }
        return cleanKlassName
    }

    CleanString(string)
    {
        ; strip out AHK escape key
        string := StrReplace(string, "``")
        string := StrReplace(string, "+", ".") ; + may work similar to dot, not really sure, but we will treat it as such.
        ; strip out [string], no memory object to handle that case
        foundPos := RegExMatch(string, "\[.+?\]") ; will only match the first [at least one character]
        if foundPos
        {
            string := SubStr(string, 1, foundPos - 1) ; this handles double nested goofy brace thing
        }
        return string
    }

    GetClassFields(klassName)
    {
        if !IsObject(this.data.classes[klassName].Fields)
        {
            return ""
        }
        exclusions := ["<", ">", "k__BackingField"]
        fields := {}
        for fieldName, fieldData in this.data.classes[klassName].Fields
        {
            if (Instr(fieldData.static, "true") OR fieldData.static == true) ; use in string function since it is not case sensitive
            {
                continue
            }
            name := fieldName
            loop % exclusions.Count()
            {
                name := StrReplace(name, exclusions[A_Index], "")
            }
            fieldData.typeClean := this.CleanTypeString(fieldData.type)
            fields[name] := fieldData
        }
        return fields
    }

    CleanTypeString(type)
    {
        ; str split will return the input string as item 1 of the array if no delimiters are found.
        obj := {}
        array := StrSplit(type, ["<", ">"])
        obj.type := array.RemoveAt(1)
        obj.typeClean := this.CleanClassName(obj.type)
        params := ""
        if (array.Count() > 0) ; means we did have <>
        {
            ; clean out empty entries where consecutive delimiters were found, usually just end
            loop % array.Count()
            {
                if (array[A_Index] == "")
                {
                    array.Delete(A_index)
                }
            }
            arrayCount := array.Count()
            ; clean the class names
            loop % arrayCount
            {
                array[A_Index] := this.CleanString(array[A_Index])
            }
            ; start at end to make our param string
            params := array[arrayCount] . "]"
            i := arrayCount - 1
            loop % arrayCount - 1 
            {
                string := array[i]
                if InStr(string, ",")
                {
                    string := StrReplace(string, ",", ",[",, 1) ; limiting to one just in case something unexpected happens but we should already be limiting to one with this code
                }
                else
                {
                    string := "[" . string
                }
                params := string . "," . params
                if (i > 0)
                {
                    params := params . "]"
                }
                i--
            }
            params := "[" . params
            params := StrReplace(params, ",", ", ") ; for readibility
        }
        obj.params := params
        return obj
    }

    StringifyData()
    {
        
    }

    ;old stuff below this point

    StringifyClass(data, indent)
    {
        string := ""
        for klassName, klass in data
        {
            if (klassName == "klass_data")
            {
                continue
            }
            ; declare class
            string .= this.Indent(indent) . "class " . klassName
            if (klass.klass_data.parent)
            {
                string .= " extends " . klass.klass_data.parent
            }
            string .= "`n" . this.Indent(indent) . "{`n"
            if IsObject(klass.klass_data.fields)
            {
                string .= this.StringifyFields(klass.klass_data.fields, indent + 1)
            }
            string .= this.StringifyClass(klass, indent + 1)
            string .= this.Indent(indent) . "}`n"
        }
        return string
    }

    StringifyClassold(klass, indent)
    {
        ; declare class
        string .= "class " . klass.klass_data.Name
        if (klass.klass_data.Parent)
        {
            string .= " extends " . klass.klass_data.parent
        }
        string .= "`n{`n"
        if IsObject(v.fields)
        {
            string .= this.StringifyFields(v.fields, indent + 1)
        }
    }

    StringifyFields(fields, indent)
    {
        string := ""
        for k, v in fields
        {
            params := ""
            if IsObject(v.type) ; this is kind of hokey, have to rethink this to eliminate if/else
            {
                type := v.type.type
                params .= ", "
                params .= v.type.params
            }
            else
            {
                type := v.type
            }
            string .= this.Indent(indent) . k . " := new " . type . "(" . v.offset . ", this" . params . ")`n"
        }
        return string
    }

    ClearClassesToAdd()
    {
        while % this.ClassesToAdd.Count()
        {
            ; check to make sure class wasn't already added
            type := this.ClassesToAdd.RemoveAt(1)
            if (this.ClassesAdded[type])
            {
                continue
            }
            this.AddClassToDataStruct(type)
        }
    }

    AddClassToDataStruct(type)
    {
        exportedType := type
        type := this.CleanType(type)
        this.ClassesAdded[type] := true
        ; create 'namespace' if necessary
        if InStr(type, ".")
        {
            array := StrSplit(type, ".")
            if !IsObject(this.DataStruct[array[1]])
            {
                this.DataStruct[array[1]] := {}
            }
            workingObj := this.DataStruct[array[1]]
            count := array.Count()
            i := 2
            loop % count - 1
            {
                if !IsObject(workingObj[array[i]])
                {
                    workingObj[array[i]] := {}
                }
                workingObj := workingObj[array[i]]
                i++
            }
            shortName := array[array.Count()]
            workingObj.klass_data := {}
            workingObj.klass_data.FullName := type
            workingObj.klass_data.Name := shortName
            workingObj.klass_data.ExportedType := exportedType
            parent := this.data.classes[exportedType].Parent
            workingObj.klass_data.Parent := parent ? parent:"System.Object"
            workingObj.klass_data.Fields := this.GetFields(exportedType)
        }
        else
        {
            this.DataStruct[type] := {}
            this.DataStruct[type].klass_data := {}
            this.DataStruct[type].klass_data.FullName := type
            this.DataStruct[type].klass_data.Name := type
            this.DataStruct[type].klass_data.ExportedType := exportedType
            parent := this.data.classes[exportedType].Parent
            this.DataStruct[type].klass_data.Parent := parent ? parent:"System.Object"
            this.DataStruct[type].klass_data.Fields := this.GetFields(exportedType)
        }
        return
    }

    GetFields(type)
    {
        if !IsObject(this.data.classes[type].Fields)
        {
            return ""
        }
        exclusions := ["<", ">", "k__BackingField"]
        fields := {}
        for fieldName, fieldData in this.data.classes[type].Fields
        {
            if (Instr(fieldData.static, "true") OR fieldData.static == true) ; use in string function since it is not case sensitive
            {
                continue
            }
            name := fieldName
            loop % exclusions.Count()
            {
                name := StrReplace(name, exclusions[A_Index], "")
            }
            fieldData.type := this.ParseType(fieldData.type)
            fields[name] := fieldData
        }
        return fields
    }

    CleanType(type)
    {
        If !(InStr(type, "[")) ; no clean up needed
        {
            return type
        }
        ; reg ex for `#[
        ; trim out everything after
        ; add T # times to create final
        ; keep original up to [
        ; create dict of modified original and final
        ; in other functions when looking up type if not found check for `#[ and compare to dict

        ; "CrusadersGame.Effects.EffectTriggerHandler`1[T]": {
        ;    "Parent": "CrusadersGame.Effects.EffectTriggerHandler`1[CrusadersGame.Effects.Empty]",

        ; arrays are ok we will add __Get(type := System.Array) to System.Object

        
        return type
    }

    ParseType(type)
    {
        ; if no <> then should not need parsing
        if (!InStr(type, "<"))
        {
            this.AddType(type)
            return type
        }
        ; add types to our dict to be processed
        array := StrSplit(type, ["<", ">"])
        for k, v in array
        {
            If InStr(v, ",")
            {
                array2 := StrSplit(v, ",")
                i := 1
                loop % array2.Count()
                {
                    this.AddType(array2[i++])
                }
            }
            else
            {
                this.AddType(v)
            }
        }
        ; modify to make easier to finish processing
        obj := {}
        obj.type := array[1]
        ; strip off the field type
        params := SubStr(type, InStr(type, "<") + 1, -1)
        ; convert <> to [] so this string can act as a variadic parameter
        params := StrReplace(params, "<", ", [")
        params := StrReplace(params, ">", "]")
        obj.params := params
        return obj
    }

    AddType(type)
    {
        if (type == "")
        {
            return
        }
        if (!InStr(type, "System") AND !(this.ClassesAdded[type]))
        {
            this.ClassesToAdd.Push(type)
            return
        }
        return
    }






    AddClass2(type, level)
    {
        if InStr(type, ".")
        {
            ; do stuff to handle nested classes
        }
        parent := this.data.classes[type].Parent
        string := this.Indent(level) . "class " . type . " extends " . parent . "`n"
        string .= this.Indent(level) . "{`n"
        for fieldName, fieldData in this.data.classes[type].Fields
        {
            if (Instr(fieldData.static, "true") OR fieldData.static == true) ; use in string function since it is not case sensitive
            {
                continue
            }
            fieldType := fieldData.type
            ;TODO parse field types
            string  .= this.Indent(level + 1) . fieldName . " := new " . fieldType . "(" . fieldData.offset . ", this)`n"
        }
        string .= this.Indent(level) . "}"

        if (parent != "System.Object")
        {
            this.AddType(parent)
        }
    }

    GetShortName(type)
    {
        shortName := type
        if InStr(type, ".")
        {
            array := StrSplit(type, ".")
            shortName := array[array.Length()]
        }
        if (this.data.classes[type].ShortName != shortName)
        {
            ExceptionHandler.ThrowFatalError("Could not find base class from given type and calculated short name.`ntype: " . type . "`nshort name: " . shortName, -2)
        }
    }

    SetStaticBase(type)
    {
        parent := this.data.classes[type].Parent
        this.AddType(parent)
        if (parent != "System.Object" AND parent != "")
        {
            this.SetStaticBase(parent)
        }
        else
        {
            this.StaticBase := type
        }
        return
    }

    Indent(times)
    {
        if !times
            return
        string := ""
        loop % times
        {
            string .= "`t"
        }
        return string
    }
}