#Include %A_LineFile%\..\json.ahk

class _Utilities
{
    ;Gets data from JSON file
    LoadObjectFromJSON(FileName)
    {
        FileRead, oData, %FileName%
        return JSON.parse( oData )
    }

    ;Writes beautified json (object) to a file (FileName)
    WriteObjectToJSON(FileName, object, beautify := false )
    {
        objectJSON := JSON.stringify( object )
        if beautify
            objectJSON := JSON.Beautify( objectJSON )
        FileDelete, %FileName%
        FileAppend, %objectJSON%, %FileName%
        return
    }
}