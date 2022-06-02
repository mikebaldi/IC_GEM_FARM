class IC_HeroHandler_Class
{
    __new(champID)
    {
        MemoryReader.Refresh()
        heroes := MemoryReader.InitHeroes()
        this.hero := heroes.Item[champID - 1]
        this.hero.SetAddress(true)
        this.Name := this.hero.def.name.GetValue()
        this.Seat := this.hero.def.SeatID.GetValue()
        this.FKey := "{F" . this.Seat . "}"
        this.hero.SetAddress(false)
        this.Benched := this.hero.Benched.Value
        this.hero.Benched.label := this.Name . "Benched"
        this.Level := this.hero.Level.Value
        this.hero.Level.label := this.Name . "Level"
        this.Init()
    }

    Init()
    {
        this.ResetPrevValues()
    }

    ResetPrevValues()
    {
        this.hero.Benched.prevValue := ""
        this.hero.Level.prevValue := ""
    }

    LevelUp(Lvl := 0, timeout := 5000, keys*)
    {
        startTime := A_TickCount
        elapsedTime := 0
        this.hero.SetAddress(true)
        seat := hero.def.SeatID.GetValue()
        if ( seat < 0 OR seat == "")
            return
        var := [this.Fkey]
        size := keys.Count()
        loop %size%
            var.Push(keys[A_Index])
        VirtualKeyInputs.Generic(var*)
        while ( this.Level < Lvl AND ElapsedTime < timeout )
        {
            VirtualKeyInputs.Generic(var*)
            ElapsedTime := A_TickCount - StartTime
        }
        return
    }

    SetMaxLvl()
    {
        ;assuming active instance is always first entry, this may not be the case, may have to compare address of each key to gameinstance.Item[0]
        upgrades := this.hero.allUpgradesOrdered.Value[0]
        ;assume address of upgrades list won't change during this look up.
        upgrades.SetAddress(true)
        _size := upgrades.Size()
        index := _size - 1
        ;assume _items won't change during this look up.
        upgrades._items.SetAddress(true)
        ;start at end of list and look for first upgrade with req lvl less than 9999
        while (index >= 0)
        {
            reqLvl := upgrades.Item[index].RequiredLevel.GetValue()
            if (reqLvl < 9999)
            {
                upgrades := ""
                this.MaxLvl := reqLvl
                return
            }
            --index
        }
        upgrades := ""
        this.MaxLvl := 9999
        return
    }
}