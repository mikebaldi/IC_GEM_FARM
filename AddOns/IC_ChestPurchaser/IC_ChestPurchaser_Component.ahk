GUIFunctions.AddTab("Chests")

Gui, ICScriptHub:Tab, Chests
Gui, ICScriptHub:Add, Text, x15 y+15 w350, % "Note: Game needs to be open to read chests into lists."
Gui, ICScriptHub:Add, Text, x15 y+5 w350, % "Only buy or open chests while game is closed. (Yes, this is a hassle.)"
Gui, ICScriptHub:Add, Text, x15 y+5 w350, % "If drop down lists are empty, press the Load Chest Defines button"
Gui, ICScriptHub:Add, Text, x15 y+5 w350, % "If drop down lists are still empty, press the (Re)Build Chest Defines button then Load Chest Defines Button"
Gui, ICScriptHub:Add, Text, x15 y+15 w350 vChestLoaded, Chest data has not been loaded.
Gui, ICScriptHub:Add, Button, x15 y+15 vLoadChestDefines, Load Chest Defines
Gui, ICScriptHub:Add, Button, x15 y+15 vBuildChestDefines, (Re)Build Chest Defines
Gui, ICScriptHub:Add, GroupBox, x15 y+15 w425 h150 vGroupBoxChestPurchaseID, Buy Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 vChestPurchaseComboBoxID
Gui, ICScriptHub:Add, Picture, x+35 h18 w18 vButtonRefreshChestPurchaser, %g_ReloadButton%
Gui, ICScriptHub:Add, Edit, x30 y+15 w75 vChestPurchaseCountID, % "99"
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserBuyChests, Buy

GuiControlGet, xyVal, ICScriptHub:Pos, GroupBoxChestPurchaseID
xyValY += 150
Gui, ICScriptHub:Add, GroupBox, x15 y%xyValY% w425 h150 vGroupBoxChestOpenID, Open Chests: 
Gui, ICScriptHub:Add, ComboBox, xp+15 yp+15 w300 vChestOpenComboBoxID
Gui, ICScriptHub:Add, Edit, y+15 w75 vChestOpenCountID, % "99"
Gui, ICScriptHub:Add, Button, x+15 w75 vButtonChestPurchaserOpenChests, Open

buyChestsFunc := Func("IC_ChestPurchaser_Component.BuyChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserBuyChests, % buyChestsFunc
openChestsFunc := Func("IC_ChestPurchaser_Component.OpenChests")
GuiControl, ICScriptHub: +g, ButtonChestPurchaserOpenChests, % openChestsFunc
chestPurchaserReadChests := Func("IC_ChestPurchaser_Component.ReadChests")
GuiControl, ICScriptHub: +g, ButtonRefreshChestPurchaser, % chestPurchaserReadChests

loadChestDefsFunc := Func("IC_ChestPurchaser_Component.ReadChests")
GuiControl, ICScriptHub: +g, LoadChestDefines, % loadChestDefsFunc

buildChestDefsFunc := Func("IC_ChestPurchaser_Component.CreateChestDefines")
GuiControl, ICScriptHub: +g, BuildChestDefines, % buildChestDefsFunc

class IC_ChestPurchaser_Component
{
    CreateChestDefines()
    {
        idle := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        if !isObject(idle) 
        {
            msgbox failed to open a handle
            if (hProcessCopy = 0)
                msgbox Idle Champions isn't running (not found) or you passed an incorrect program identifier parameter. In some cases _ClassMemory.setSeDebugPrivilege() may be required. 
            else if (hProcessCopy = "")
                msgbox OpenProcess failed. If Idle Champions has admin rights, then the script also needs to be ran as admin. _ClassMemory.setSeDebugPrivilege() may also be required. Consult A_LastError for more information.
            ExitApp
        }
        CDpath := idle.GetModuleFileNameEx()
        foundPos := InStr(CDpath, "IdleDragons.exe")
        CDpath := SubStr(CDpath, 1, foundPos - 1) . "IdleDragons_Data\StreamingAssets\downloaded_files\cached_definitions.json"
        cachedDefs := g_SF.LoadObjectFromJSON(CDpath)
        g_SF.WriteObjectToJSON(A_LineFile . "\..\chest_type_defines.json", cachedDefs.chest_type_defines)
    }

    ReadChests()
    {
        GuiControl, ICScriptHub:, ChestLoaded, Chest data loading...
        chest_type_defines := g_SF.LoadObjectFromJSON(A_LineFile . "\..\chest_type_defines.json")
        size := chest_type_defines.Count()   
        if(!size)
            return
        loop, %size%
        {
            ;chestID := g_SF.Memory.GenericGetValue(g_SF.Memory.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesList.ID.GetGameObjectFromListValues(A_Index - 1))
            chestID := chest_type_defines[A_Index].id
            chestName := chest_type_defines[A_Index].name ;g_SF.Memory.GenericGetValue(g_SF.Memory.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesList.NameSingular.GetGameObjectFromListValues(A_Index - 1))
            comboBoxOptions .= chestID . " " . chestName . "|"
        }
        g_ServerCall := new IC_ServerCalls_Class()
        ;g_SF.ResetServerCall()
        GuiControl,ICScriptHub:, ChestOpenComboBoxID, %comboBoxOptions%
        GuiControl,ICScriptHub:, ChestPurchaseComboBoxID, %comboBoxOptions%
        GuiControl, ICScriptHub:, ChestLoaded, Chest data has been loaded.
    }

    BuyChests()
    {
        global
        Gui,ICScriptHub:Submit, NoHide
        splitArray := StrSplit(ChestPurchaseComboBoxID, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Buying " . ChestPurchaseCountID . " of " . chestName . " (ID: " . chestID . ")"
        buyCount := ChestPurchaseCountID
        while(buyCount > 0)
        {
            response := g_ServerCall.CallBuyChests( chestID, buyCount )
            if(!IsObject(response))
            {
                MsgBox % "Failed with response: " . response
                return
            }
            if (!response.okay)
            {
                MsgBox % "Failed because " . response.failure_reason . response.fail_message
                return 
            }
            if(chestID != 152 AND chestID != 153 AND chestID != 219  AND chestID != 311 )
                buyCount -= 100
            else
                buyCount -= 1
        }
        MsgBox % "Done"
    }

    OpenChests()
    {
        global
        Gui,ICScriptHub:Submit, NoHide
        splitArray := StrSplit(ChestOpenComboBoxID, " ",,2)
        chestID := splitArray[1]
        chestName := splitArray[2]
        MsgBox % "Opening " . ChestOpenCountID . " of " . chestName . " (ID: " . chestID . ") Make sure the game is closed before continuing."
        openCount := ChestOpenCountID
        while(openCount > 0)
        {
            response := g_ServerCall.CallOpenChests( chestID, openCount )
            if(!IsObject(response))
            {
                MsgBox % "Failed with response: " . response
                return
            }
            if (!response.success)
            {
                MsgBox % "Failed because " . response.failure_reason . response.fail_message
                return 
            }
            openCount -= 99
        }
        MsgBox % "Done"
    }
}