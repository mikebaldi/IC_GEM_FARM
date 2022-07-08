class _QTHandler
{
    __new()
    {
        this.ActiveCampaignData := _MemoryHandler.CreateOrGetActiveCampaignData()
        this.Areas := this.ActiveCampaignData.adventureDef.areas
        this.ID := 67
        this.BuildList()
        this.SetAreas()
        return this
    }

    BuildList()
    {
        this.List := {}
        idCounts := {}
        maxCount := 0
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            this.List.Push(new _QTHandler._AreaHandler(this.Areas.Item[A_Index - 1]))
            id := this.Areas.Item[A_Index - 1].BackgroundDefID.Value
            if idCounts.HasKey(id)
                idCounts[id] += 1
            else
                idCounts[id] := 1
        }
        for k, v in idCounts
        {
            if (v > maxCount)
            {
                maxCount := v
                this.ID := k
            }
        }
        if !this.ID
            this.ID := 67 ;arbitrary pick
        ;temporary 'fix' so the script can reload without restarting game.
        ;even areas defined by CNE to have correct id will have their id written to, making for one set of redundant writes every run.
        ;loop, 50
        ;{
        ;    if (this.List[A_Index].defaultID == this.ID)
        ;        this.List[A_Index].setBackground := false
        ;}
        this.Areas.UseCachedAddress(false)
        return
    }

    SetAreas()
    {
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            this.List[A_Index].SetArea(this.ID)
        }
        this.Areas.UseCachedAddress(false)
        this.BackgroundsSet := {}
        return
    }

    SetBackgrounds()
    {
        if (this.BackgroundsSet.Count() == 50)
            return
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            if this.BackgroundsSet[A_Index]
                continue
            else if (this.List[A_Index].SetBackgroundDef(this.ID))
                this.BackgroundsSet[A_Index] := true
        }
        this.Areas.UseCachedAddress(false)
        return
    }

    class _AreaHandler
    {
        __new(area)
        {
            this.Area := area
            this.setBackground := true
            this.defaultID := this.Area.BackgroundDefID.Value
            return this
        }

        SetArea(id)
        {
            this.Area.isFixed.Value := 1
            this.Area.isFixed_hasValue.Value := 1
            if this.setBackground
                this.Area.BackgroundDefID.Value := id
            return
        }

        SetBackgroundDef(id)
        {
            if !(this.setBackground)
                return true
            else if !(this.Area.backgroundDef.ID.Value)
                return false
            else
                this.Area.backgroundDef.ID.Value := id
            return true
        }
    }
}