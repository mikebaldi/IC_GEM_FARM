#SingleInstance, force
#Include %A_ScriptDir%\Classes\IC\IdleGameManager.ahk
if (_IdleGameManager.__Class != "_IdleGameManager")
{
    msgbox "_IdleGameManager" not correctly installed. Or the (global class) variable "_IdleGameManager" has been overwritten. Exiting App.
    ExitApp
}

; TODO: Lots

Gui, MyGUI:New
Gui, MyGUI:Font, w700
Gui, MyGUI:Add, Text, x15 y15, Memory Tree View:
Gui, MyGUI:Font, w400
Gui, MyGUI:Add, TreeView, x15 y+15 w600 h800 vTreeViewID ReadOnly gTV_Clicked AltSubmit
Gui, MyGUI:Add, Text, x15 y+15 vTest w200,
Gui, MyGUI:Show

MyGUIGuiClose()
{
    MsgBox 4,, Are you sure you want to `exit?
    IfMsgBox Yes
        ExitApp
    IfMsgBox No
        return True
}


idleGameManager := new _IdleGameManager("IdleDragons.exe", "mono-2.0-bdwgc.dll", 0x495A90, 0xCB0)
handle := idleGameManager.s_OpenProcess()
global g_TV
g_TV := new _TreeView(idleGameManager)
GuiControl, -Redraw, TreeViewID
TV_Modify(0, "Sort") 
GuiControl, +Redraw, TreeViewID

loop
{
    GuiControl, -Redraw, TreeViewID
    handle := idleGameManager.s_OpenProcess()
    g_TV.Refresh()
    GuiControl, +Redraw, TreeViewID
    sleep, 500
}

TV_Clicked()
{
    GuiControl, -Redraw, TreeViewID
    if (A_EventInfo AND A_GuiControlEvent == "+")
        g_TV.ParentExpanded(A_EventInfo)
    GUIControl, MyGUI:, Test, % A_GuiControlEvent . " : " A_EventInfo
    GuiControl, +Redraw, TreeViewID
}

class _TreeView
{
    __new(obj*)
    {
        this.TVdata := {}
        for k, v in obj
        {
            itemID := TV_Add("", 0)
            this.TVdata[itemID] := new _TreeView.data(itemID, v, v.__Class, true)
            this.TVdata[itemID].Refresh()
        }
    }

    ParentExpanded(parentID)
    {
        if (this.TVdata[parentID].placeHolderID)
        {
            TV_Delete(this.TVdata[parentID].placeHolderID)
            this.TVdata[parentID].placeHolderID := 0
            this.CreateChildren(parentID)
        }
        this.UpdateChildren(parentID)    
    }

    UpdateChildren(parentID)
    {
        itemID := TV_GetChild(parentID)
        while itemID
        {
            this.TVdata[itemID].Refresh()
            this.UpdateChildren(itemID)
            itemID := TV_GetNext(itemID)
        }
    }

    CreateChildren(parentID)
    {
        fields := System.Reflection.GetFields(this.TVdata[parentID].Object)
        for k, v in fields
        {
            if !(System.classMemoryType[v.type]) ; a reference type
            {
                hasChildren := true
            }
            else
            {
                hasChildren := false
            }
            itemID := TV_Add("", parentID)
            this.TVdata[itemID] := new _TreeView.data(itemID, v.Field, v.Name, hasChildren)
        }
    }

    Refresh()
    {
        itemID := TV_GetChild(0)
        while itemID
        {
            this.TVdata[itemID].Refresh()
            this.UpdateChildren(itemID)
            itemID := TV_GetNext(itemID)
        }
    }

    class data
    {
        __new(itemID, obj, key, hasChildren)
        {
            this.ItemId := itemID
            this.Key := key
            this.Object := obj
            this.TickCount_New := 0
            this.hasChildren := hasChildren
            if (hasChildren)
            {
                this.placeHolderID := TV_Add("", itemID)
            }
            return this
        }

        __delete()
        {
            TV_Delete(this.ItemID)
            return
        }

        Refresh()
        {
            string := Format("0x{:X}", this.Object.s_offset) . " - " . this.Key . " - "
            string .= Format("0x{:X}", this.GetAddress() + this.Object.s_offset)
            value := this.GetValue()
            if !(this.Object.s_isGeneric)
            {
                value := Format("0x{:X}", value)
            }
            string .= " : " . value
            if (A_TickCount - this.TickCount_New < 5000)
                option := "Bold"
            else
                option := "-Bold"
            TV_Modify(this.ItemID, option, string)
        }

        GetAddress()
        {
            ; special case for base memory object, they don't have a parent :(
            if IsObject(this.Object.s_parent)
            {
                currentAddress := this.Object.s_parent.s_GetValue()
            }
            else
            {
                currentAddress := this.Object.s_readAddress()
            }
            if (currentAddress != this.prevAddress)
            {
                this.prevAddress := currentAddress
                this.TickCount_New := A_TickCount
            }
            return currentAddress
        }

        GetValue()
        {
            currentValue := this.Object.s_GetValue()
            if (currentValue != this.prevValue)
            {
                this.prevValue := currentValue
                this.TickCount_New := A_TickCount
            }
            return currentValue
        }
    }
}