;to do, create code to pick the background def id to minimize number of writes and checks.
;low priority as seems to work pretty well
class _QTHandler
{
    __new()
    {
        this.ActiveCampaignData := _MemoryHandler.InitActiveCampaignData()
        this.Areas := this.ActiveCampaignData.adventureDef.areas
        this.ID := 67 ;arbitrarily chosen. maybe should create some sort of counter to minimize writes
        this.InitDefs()
        return this
    }

    ;clear stored background setting data and set all area defs isFixed to true
    InitDefs()
    {
        this.BackgroundsSet := {}
        this.PrevZone := this.ActiveCampaignData.CurrentZone.Value
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            this.Areas.Item[A_Index - 1].isFixed.Value := 1
            this.Areas.Item[A_Index - 1].isFixed_hasValue.Value := 1
            this.Areas.Item[A_Index - 1].BackgroundDefID.Value := this.ID
        }
        this.Areas.UseCachedAddress(false)
        return
    }

    SetBackGroundID()
    {
        if (this.BackgroundsSet.Count() == 50)
            return
        index := 0
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            id := this.Areas.Item[index].backgroundDef.ID.Value
            if (this.BackgroundsSet[index] OR !id)
            {
                index++
                continue
            }
            else if (id != this.ID)
                this.Areas.Item[index].backgroundDef.ID.Value := this.ID
            this.BackgroundsSet[index] := true
            index++
        }
        this.Areas.UseCachedAddress(false)
    }

    ;incrementally set backgrounds, only once we know we have completed them and moved on.
    SetBackGroundIDold()
    {
        ;all 50 backgrounds set, return
        if (this.BackgroundsSet.Count() == 50)
            return

        ;still on same zone, return
        currentZone := this.ActiveCampaignData.CurrentZone.Value
        if (currentZone <= this.PrevZone OR !currentZone)
            return
        ;set background id for the zone after the previous zone and the previous zone.
        index := Mod(this.PrevZone, 50)
        this.Areas.UseCachedAddress(true)
        loop, 2
        {
            if (this.BackgroundsSet[index])
            {
                index--
                continue
            }
            if (this.Areas.Item[index].backgroundDef.ID.Value != this.ID)
                this.Areas.Item[index].backgroundDef.ID.Value := this.ID
            this.BackgrounsSet[index] := true
            index--
        }
        this.Areas.UseCachedAddress(false)
        this.PrevZone := currentZone
        return
    }
}