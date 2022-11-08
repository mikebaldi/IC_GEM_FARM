class _AreaHandler
{
    __new()
    {
        this.ActiveCampaignData := _MemoryHandler.CreateOrGetActiveCampaignData()
        this.Areas := this.ActiveCampaignData.adventureDef.areas
        ;backgroundDefID := this.Areas.Item[0].BackgroundDefID.Value
        this.BackgroundDefID := 9 ;backgroundDefID ? backgroundDefID : 9 ;read zone one id, use or use cursed farmer
        area := mod(this.ActiveCampaignData.ActiveCampaignData.currentAreaID.Value, 50)
        this.SetMonsterDefID(this.Areas.Item[area - 1])
        this.BuildList()
        this.SetAreas()
        ;get monster list, is id
            ;scrap that method, use active monsters list instead of that hash set
            ;get monster attack as they spawn -> controller.area.standardmonsterspawner.spawnedMmonsters(hashet item 0).monsterdef.id for id then continue to .availableattacks.item0.id
            ;compare to attack id == 21
            ;if so use that monster
            ;if can't find that then set this.monsterdefid := first entry into monster list by id
        return this
    }

    BuildList()
    {
        this.List := {}
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            this.List.Push(new _AreaHandler._AreaHandler(this.Areas.Item[A_Index - 1]))
        }
        this.Areas.UseCachedAddress(false)
        return
    }

    SetAreas()
    {
        this.Areas.UseCachedAddress(true)
        loop, 50
        {
            this.List[A_Index].SetArea(this.BackgroundDefID, this.MonsterDefID)
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
            else if (this.List[A_Index].SetBackgroundDef(this.BackgroundDefID))
                this.BackgroundsSet[A_Index] := true
        }
        this.Areas.UseCachedAddress(false)
        return
    }

    SetMonsterDefID(area)
    {
        ;get list of monster id
        monsters := {}
        _size := area.Monsters._size.Value
        i := 0
        loop, %_size%
        {
            id := area.Monsters.Item[i].Value
            monsters[id] := id
            i++
        }
        ;search active monsters for a melee attack
        gameInstance := _MemoryHandler.CreateOrGetGameInstance()
        monsterDef := gameInstance.Controller.area.activeMonsters.Item[0].monsterDef
        while monsters.Count()
        {
            monsterDef.UseCachedAddress(true) ;this should let us continue to use themosnter def even when the item in the list changes before we finished.
            id := monsterDef.ID.Value
            if monsters.HasKey(id)
            {
                monsters.Delete(id)
                _size := monsterDef.availableAttacks._size.Value
                i := 0
                loop %_size%
                {
                    attackID := monsterDef.availableAttacks.Item[i].AttackDef.ID.Value
                    if (monsterDef.availableAttacks.Item[i].AttackDef.ID.Value == 21)
                    {
                        this.MonsterDefID := id ? id : area.Monsters.Item[0].Value ; reads above have some unreliability.
                        monsterDef.UseCachedAddress(false)
                        return
                    }
                    i++
                }
            }
        }
        this.MonsterDefID := id ? id : area.Monsters.Item[0].Value ; reads above have some unreliability.
        monsterDef.UseCachedAddress(false)
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

        SetArea(areaId, monsterId)
        {
            this.Area.isFixed.Value := 1
            this.Area.isFixed_hasValue.Value := 1
            this.SetBosses(monsterId)
            this.SetMonsters(monsterId)
            this.SetStaticMonsters(monsterId)
            if this.setBackground
                this.Area.BackgroundDefID.Value := areaId
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

        SetBosses(id)
        {
            _size := this.Area.Bosses._size.Value
            i := 0
            loop, %_size%
            {
                _size2 := this.Area.Bosses.Item[i]._size.Value
                j := 0
                loop, %_size2%
                {
                    this.Area.Bosses.Item[i].Item[j].Value := id
                    j++
                }
                i++
            }
            return
        }

        SetMonsters(id)
        {
            _size := this.Area.Monsters._size.Value
            i := 0
            loop, %_size%
            {
                this.Area.Monsters.Item[i].Value := id
                i++
            }
            return
        }

        SetStaticMonsters(id)
        {
            staticCount := this.Area.StaticMonsters.count.Value
            i := 0
            loop, %staticCount%
            {
                propCount := this.Area.StaticMonsters.Value[i].count.Value
                j := 0
                loop, %propCount%
                {
                    ;test := this.Area.StaticMonsters.Value[i].Key[j].Value
                    if (this.Area.StaticMonsters.Value[i].Key[j].Value == "monster_id")
                    {
                        ;test2 := this.Area.StaticMonsters.Value[i].Value[j].m_value.Value
                        this.Area.StaticMonsters.Value[i].Value[j].m_value.Value := id ;this appears to be a structure to int32
                    }
                    j++
                }
                i++
            }
            return
        }
    }
}