GUIFunctions.AddTab("Memory Tree View")

Gui, ICScriptHub:Tab, Memory Tree View
Gui, ICScriptHub:Add, Button, x+15 y+15 w160 gLaunch_MemoryTreeView, Launch Tree View
string := "Known Issues:"
string .= "`n1. Text may flash on updates, particularly when more items are expanded."
string .= "`n2. When error 'TVdata missing key:' is thrown, collapse and expand parent item."
Gui, ICScriptHub:Add, Text, y+15 w450, % string

Launch_MemoryTreeView()
{
    ;scriptLocation := A_LineFile . "\..\Tree View.ahk"
    ;Run, %A_AhkPath% "%scriptLocation%"
    Run, %A_LineFile%\..\Tree View.ahk
}

;#include %A_LineFile%\..\..\..\SharedFunctions\ObjRegisterActive.ahk