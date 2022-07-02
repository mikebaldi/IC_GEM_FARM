;if !IsObject(_VirtualKeyInputs)
;    #Include %A_LineFile%\..\_VirtualKeyInputs.ahk
;if !IsObject(_MemoryHandler)
 ;   #Include %A_LineFile%\..\Memory\_MemoryHandler.ahk

class _HeroHandler
{
    __new(champID)
    {
        _VirtualKeyInputs.Init("ahk_exe IdleDragons.exe")
        _MemoryHandler.Refresh()
        heroes := _MemoryHandler.InitHeroes()
        this.ChampID := champID
        this.hero := heroes.Item[champID - 1]
        this.hero.UseCachedAddress(true)
        this.Name := this.hero.def.name.GetValue()
        this.Seat := this.hero.def.SeatID.GetValue()
        if !(this.Seat)
        {
            msgbox, % "Failed to read ChampID: " . champID . " seat. Existing app."
            ExitApp
        }
        this.FKey := "{F" . this.Seat . "}"
        this.hero.UseCachedAddress(false)
        this.Benched := this.hero.Benched
        this.Level := this.hero.Level
        ;loads champion specific items for extended classes
        this.Init()
        return this
    }

    Init()
    {
        ;this.ResetPrevValues()
    }

    LevelUp(Lvl := 0, timeout := 5000, keys*)
    {
        startTime := A_TickCount
        elapsedTime := 0
        this.hero.UseCachedAddress(true)
        var := [this.Fkey]
        size := keys.Count()
        loop %size%
            var.Push(keys[A_Index])
        _VirtualKeyInputs.Generic(var*)
        while ( this.Level.Value < Lvl AND ElapsedTime < timeout )
        {
            _VirtualKeyInputs.Generic(var*)
            ElapsedTime := A_TickCount - StartTime
        }
        this.hero.UseCachedAddress(false)
        return
    }

    SetMaxLvl()
    {
        ;assuming active instance is always first entry, this may not be the case, may have to compare address of each key to gameinstance.Item[0]
        upgrades := this.hero.allUpgradesOrdered.Value[0]
        ;assume address of upgrades list won't change during this look up.
        upgrades.UseCachedAddress(true)
        _size := upgrades.Size()
        index := _size - 1
        ;assume _items won't change during this look up.
        upgrades._items.UseCachedAddress(true)
        ;start at end of list and look for first upgrade with req lvl less than 9999
        while (index >= 0)
        {
            reqLvl := upgrades.Item[index].RequiredLevel.GetValue()
            if (reqLvl < 9999)
            {
                upgrades := ""
                upgrades._items.UseCachedAddress(false)
                upgrades.UseCachedAddress(false)
                this.MaxLvl := reqLvl
                return
            }
            --index
        }
        upgrades._items.UseCachedAddress(false)
        upgrades.UseCachedAddress(false)
        upgrades := ""
        this.MaxLvl := 9999
        return
    }
}