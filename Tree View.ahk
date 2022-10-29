#SingleInstance, force
#include %A_ScriptDir%\Classes\_ExceptionHandler.ahk
#Include %A_ScriptDir%\Classes\Memory\_MemoryHandler.ahk
;to do - fix exception when child doesn't populate, collapse then expand again should do it.
;to do - auto read in structures
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

global g_TV

System.Refresh()
GuiControl, -Redraw, TreeViewID
objArray := [ new IdleGameManager, new BrivUnnaturalHasteHandler, new BrivSteelbonesHandler, new TimeScaleWhenNotAttackedhandler, new OminContractualObligationsHandler, new NerdWagonHandler, new SentryEchoHandler, new HewMaanTeamworkHandler ]
g_TV := new TV_MemoryView(objArray*)
TV_Modify(0, "Sort") 
GuiControl, +Redraw, TreeViewID

loop
{
    ;Critical, On
    GuiControl, -Redraw, TreeViewID
    System.Refresh()
    itemID := TV_GetChild(0)
    while itemID
    {
        g_TV.UpdateItem(itemID)
        g_TV.UpdateChildren(itemID)
        itemID := TV_GetNext(itemID)
    }
    GuiControl, +Redraw, TreeViewID
    ;Critical, Off
    sleep, 500
}

TV_Clicked()
{
    ;Critical, On
    GuiControl, -Redraw, TreeViewID
    if (A_EventInfo AND A_GuiControlEvent == "+")
        g_TV.ParentExpanded(A_EventInfo)
    GUIControl, MyGUI:, Test, % A_GuiControlEvent . " : " A_EventInfo
    GuiControl, +Redraw, TreeViewID
    ;Critical, Off
}

class TV_MemoryView
{
    __new(obj*)
    {
        this.TVdata := {}
        for k, v in obj
        {
            itemID := TV_Add("", 0)
            placeHolderID := TV_Add("", itemID)
            this.TVdata[itemID] := new TV_MemoryView._data._reference(itemID, v, v.__Class)
            this.TVdata[itemID].Refresh()
        }
    }

    ParentExpanded(parentItemID)
    {
        if !this.TVdata.HasKey(parentItemID)
        {
            ;may need to add TV_GetText(Outputvar, parentItemID) to this exception text to better understand
            ;ExceptionHandler.ThrowError("TVdata missing key: " . parentItemID, -1)
            ;collapse item recently expanded, collapse its parent, expand its parent, rerun parentexpanded to build new parent
            TV_Modify(parentItemID, "-Expand")
            superParentID := TV_GetParent(parentItemID)
            TV_Modify(superParentID, "-Expand")
            TV_Modify(superParentID, "Expand")
            this.ParentExpanded(superParentID)
            return
        }
        ;if the child is a place holder and didn't create an entry to TVdata then the children weren't created.
        ;or if something went wrong, just kill all children and start over.
        childID := TV_GetChild(parentItemID)
        if !this.TVdata.HasKey(childID)
        {
            while childID
            {
                TV_Delete(childID)
                this.TVdata.Delete(childID)
                ;children of children in tv data aren't also being deleted, probably not going to worry about that.
                childID := TV_GetNext(childID)
            }
            this.CreateChildren(parentItemID)
        }
        else if (this.TVdata[parentItemID].Key == "_items")
            return this.CreateItems(parentItemID)
        else if (this.TVdata[parentItemID].Key == "entries")
            return this.CreateEntries(parentItemID)
        ;children were created so just need to update.
        else
            return this.UpdateChildren(parentItemID)
    }

    UpdateChildren(parentID)
    {
        if !TV_Get(parentID, "Expanded")
            return
        childID := TV_GetChild(parentID)
        while childID
        {
            this.UpdateChildren(childID)
            this.UpdateItem(childID)
            childID := TV_GetNext(childID)
        }
    }

    CreateItems(itemID)
    {
        this.TVdata[itemID].Object.List.SetAddress(true)
        _size := this.TVdata[itemID].Object.ParentObj._size.Value ;.Size()
        index := 0
        while (_size > index)
        {
            ;at least one items hould already be created
            indexedChild := this.TVdata[itemID].Item[index]
            if (indexedChild != "")
                this.TVdata[indexedChild].Refresh()
            else
            {
                obj := this.TVdata[itemID].Object.ParentObj.Item[index]
                childID := this.CreateCollectionChild(itemID, obj, "Item[" . index . "]")
                this.TVdata[itemID].Item[index] := childID
                this.TVdata[childID].Refresh()
            }
            ++index
        }
        ;delete items no longer in memory so refreshing data is faster.
        ;need to modify in case size == 0 so we have at least one dummy child for expanding
        while (index < this.TVdata[itemID].Item.Count())
        {
            indexedChild := this.TVdata[itemID].Item[index]
            TV_Delete(indexedChild)
            this.TVdata[itemID].Item.Delete(index)
            ++index
        }
        this.TVdata[itemID].Object.List.SetAddress(false)
        return
    }

    CreateEntries(itemID)
    {
        this.TVdata[itemID].Object.Dict.SetAddress(true)
        tempObj := this.TVdata[itemID].Object
        count := this.TVdata[itemID].Object.ParentObj.count.GetValue()
        index := 0
        while (count > index)
        {
            indexedChild := this.TVdata[itemID].Collection.Key[index]
            if (indexedChild != "")
                this.TVdata[indexedChild].Refresh()
            else
            {
                obj := this.TVdata[itemID].Object.ParentObj.Key[index]
                childID := this.CreateCollectionChild(itemID, obj, "Key[" . index . "]")
                this.TVdata[itemID].Collection.Key[index] := childID
                this.TVdata[childID].Refresh()
            }
            indexedChild := this.TVdata[itemID].Collection.Value[index]
            if (indexedChild != "")
                this.TVdata[indexedChild].Refresh()
            else
            {
                obj := this.TVdata[itemID].Object.ParentObj.Value[index]
                childID := this.CreateCollectionChild(itemID, obj, "Value[" . index . "]")
                this.TVdata[itemID].Collection.Value[index] := childID
                this.TVdata[childID].Refresh()
            }
            ++index
        }
        ;delete items no longer in memory so refreshing data is faster.
        ;need to modify in case size == 0 so we have at least one dummy child for expanding
        while (index < this.TVdata[itemID].Item.Count())
        {
            indexedChild := this.TVdata[itemID].Collection.Key[index]
            TV_Delete(indexedChild)
            this.TVdata[itemID].Collection.Key.Delete(index)
            indexedChild := this.TVdata[itemID].Collection.Value[index]
            TV_Delete(indexedChild)
            this.TVdata[itemID].Collection.Value.Delete(index)
            ++index
        }
        this.TVdata[itemID].Object.Dict.SetAddress(false)
        return
    }

    CreateChildren(parentItemID)
    {
        parentObject := this.TVdata[parentItemID].Object
        For k, v in parentObject
        {
            if (!IsObject(v) OR k == "ParentObj" OR IsFunc(v))
            {
                continue
            }
            else if (v.__Class == "System.List")
            {
                listID := this.CreateListChild(parentItemID, v, k)
                this.TVdata[listID].Refresh()
            }
            ;else if (v.__Class == "System.Value")
            ;{
            ;    itemID := this.CreateNumericChild(parentItemID, v, k)
            ;    this.TVdata[itemID].Refresh()
            ;}
            else if (v.__Class == "System.String")
            {
                sringID := this.CreateStringChild(parentItemID, v, k)
                this.TVdata[stringID].Refresh()
            }
            else if (v.__Class == "System.Dictionary")
            {
                dictID := this.CreateDictChild(parentItemID, v, k)
                this.TVdata[dictID].Refresh()
            }
            else if (v.isEnum)
            {
                enumID := this.CreateEnumChild(parentItemID, v, k)
                this.TVdata[enumID].Refresh()
            }
            ;only numeric values should now have a type. enum is the only other
            else if (v.Type)
            {
                itemID := this.CreateNumericChild(parentItemID, v, k)
                this.TVdata[itemID].Refresh()
            }
            else
            {
                itemID := this.CreatePointerChild(parentItemID, v.Clone(), k)
                this.TVdata[itemID].Refresh()
            }
            ;TV_Modify(parentItemID, "Sort")
        }
    }

    CreateNumericChild(parentItemID, obj, key)
    {
        itemID := TV_ADD("", parentItemID)
        this.TVdata[itemID] := new TV_MemoryView._data._value(itemID, obj, key)
        return itemID
    }

    CreateEnumChild(parentItemID, obj, key)
    {
        itemID := TV_ADD("", parentItemID)
        this.TVdata[itemID] := new TV_MemoryView._data._enum(itemID, obj, key)
        return itemID
    }

    CreateStringChild(parentItemID, obj, key)
    {
        stringID := TV_ADD("", parentItemID)
        this.TVdata[stringID] := new TV_MemoryView._data._reference(stringID, obj, key)

        lengthID := TV_ADD("", stringID)
        this.TVdata[lengthID] := new TV_MemoryView._data._value(lengthID, obj.Length, "Length")

        valueID := TV_ADD("", stringID)
        this.TVdata[valueID] := new TV_MemoryView._data._string(valueID, obj, "Value")
        return stringID
    }

    CreatePointerChild(parentItemID, obj, key)
    {
        itemID := TV_ADD("", parentItemID)
        placeHolderID := TV_Add("", itemID)
        this.TVdata[itemID] := new TV_MemoryView._data._reference(itemID, obj, key)
        return itemID
    }
    
    CreateListChild(parentItemID, obj, key)
    {
        listID := TV_ADD("", parentItemID)
        this.TVdata[listID] := new TV_MemoryView._data._reference(listID, obj, key)

        _sizeID := TV_ADD("", listID)
        this.TVdata[_sizeID] := new TV_MemoryView._data._value(_sizeID, obj._size, "_size")

        _itemsID := TV_ADD("", listID)
        this.TVdata[_itemsID] := new TV_MemoryView._data._reference(_itemsID, obj._items, "_items")

        item0ID := this.CreateCollectionChild(_itemsID, obj.Item[0], "Item[0]")
        ;need a way to track item lists as it grows and shrinks
        this.TVdata[_itemsID].Item := {}
        this.TVdata[_itemsID].Item[0] := item0ID

        return listID
    }

    CreateCollectionChild(parentItemID, obj, key)
    {
        ;if (obj.__Class == "System.Value")
        ;    itemID := this.CreateNumericChild(parentItemID, obj, key)
        if (obj.__Class == "System.String")
            itemID := this.CreateStringChild(parentItemID, obj, key)
        else if (obj.__Class == "System.List")
            itemID := this.CreateListChild(parentItemID, obj, key)
        else if (obj.__Class == "System.Dictionary")
            itemID := this.CreateDictChild(parentItemID, obj, key)
        else if (obj.isEnum)
            itemID := this.CreateEnumChild(parentItemID, obj, key)
        ;only numeric should now have a type, enum is only other
        else if (obj.Type)
            itemID := this.CreateNumericChild(parentItemID, obj, key)
        else
            itemID := this.CreatePointerChild(parentItemID, obj, key)
        return itemID
    }

    CreateDictChild(parentItemID, obj, key)
    {
        dictID := TV_ADD("", parentItemID)
        this.TVdata[dictID] := new TV_MemoryView._data._reference(dictID, obj, key)

        countID := TV_ADD("", dictID)
        this.TVdata[countID] := new TV_MemoryView._data._value(countID, obj.count, "count")

        entriesID := TV_ADD("", dictID)
        this.TVdata[entriesID] := new TV_MemoryView._data._reference(entriesID, obj.entries, "entries")

        key0ID := this.CreateCollectionChild(entriesID, obj.Key[0], "Key[0]")
        value0ID := this.CreateCollectionChild(entriesID, obj.Value[0], "Value[0]")
        ;need a way to track item lists as it grows and shrinks
        this.TVdata[entriesID].Collection := {}
        this.TVdata[entriesID].Collection.Key := {}
        this.TVdata[entriesID].Collection.Key[0] := key0ID
        this.TVdata[entriesID].Collection.Value := {}
        this.TVdata[entriesID].Collection.Value[0] := key0ID

        return dictID
    }

    UpdateItem(itemID)
    {
        ;if !this.TVdata.HasKey(itemID)
            ;may need to add TV_GetText(Outputvar, parentItemID) to this exception text to better understand
            ;ExceptionHandler.ThrowError("TVdata missing key: " . itemID, -1)
        this.TVdata[itemID].Refresh()
    }

    ;types to hold our tree view data
    class _data
    {
        class _generic
        {
            __new(itemID, obj, key)
            {
                this.ItemId := itemID
                this.Key := key
                this.Object := obj
                this.TickCount_New := 0
                return this
            }

            Refresh()
            {
                string := Format("0x{:X}", this.Offset) . " - " . this.Key . " - "
                string .= Format("0x{:X}", this.BaseAddress + this.Offset)
                string .= " : " . this.Value
                if (A_TickCount - this.TickCount_New < 5000)
                    option := "Bold"
                else
                    option := "-Bold"
                TV_Modify(this.ItemID, option, string)
            }

            Offset[]
            {
                get
                {
                    return this.Object.Offset
                }
            }

            BaseAddress[]
            {
                get
                {
                    currentBaseAddress := this.GetBaseAddress()
                    if (currentBaseAddress != this.prevBaseAddress)
                    {
                        this.prevBaseAddress := currentBaseAddress
                        this.TickCount_New := A_TickCount
                    }
                    return currentBaseAddress
                }
            }

            GetBaseAddress()
            {
                return this.Object.ParentObj.GetAddress()
            }

            Value[]
            {
                get
                {
                    currentValue := this.GetValue()
                    if (currentValue != this.prevValue)
                    {
                        this.prevValue := currentValue
                        this.TickCount_New := A_TickCount
                    }
                    ;if this.isPointer
                    ;    currentValue := this.PointifyValue(currentValue)
                    return currentValue
                }
            }
        }

        class _value extends TV_MemoryView._data._generic
        {
            isPointer := false

            GetValue()
            {
                return this.Object.GetValue()
            }
        }

        class _enum extends TV_MemoryView._data._generic
        {
            isPointer := false

            GetValue()
            {
                return this.Object.GetValue() . " -> " . this.Object.GetEnumerable()
            }
        }

        class _string extends TV_MemoryView._data._value
        {
            Offset[]
            {
                get
                {
                    return this.Object.Value.Offset
                }
            }

            GetBaseAddress()
            {
                return this.Object.GetAddress()
            }
        }

        class _reference extends TV_MemoryView._data._generic
        {
            isPointer := true

            GetValue()
            {
                return "P-> " . Format("0x{:X}", this.Object.GetAddress()) ;this.Object.GetAddress()
            }

            PointifyValue(address)
            {
                return "P-> " . Format("0x{:X}", address)
            }
        }
    }
}