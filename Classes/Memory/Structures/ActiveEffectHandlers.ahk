class BrivSteelbonesHandler extends ActiveEffectKeyHandler
{
    ChampID := 58
    UpgradeID := 3450
    EffectID := 567
    ;FB-CrusadersGame.Effects.BrivSteelbonesHandler
    effectKey := new CrusadersGame.Effects.EffectKey(24, 48, this)
    steelbonesStacks := new CrusadersGame.Effects.EffectStacks(28, 56, this)
    ;FE
}

class BrivUnnaturalHasteHandler extends ActiveEffectKeyHandler
{
    ChampID := 58
    UpgradeID := 3452
    EffectID := 569
    ;FB-CrusadersGame.Effects.BrivUnnaturalHasteHandler
    effectKey := new CrusadersGame.Effects.EffectKey(24, 48, this)
    sprintStacks := new CrusadersGame.Effects.EffectStacks(28, 56, this)
    areaSkipChance := new System.Single(56, 104, this)
    areaSkipAmount := new System.Int32(60, 108, this)
    ;FE

    ;to be revisited, this field apperas to be remoed from structure
    ;stacksToConsume := new System.Int32(68, 116, this)
    ;Failed to find field name in export file. fieldName: <stacksToConsume>k__Backingfield
}

class HavilarImpHandler extends ActiveEffectKeyHandler
{
    ChampID := 56
    UpgradeID := 3431
    EffectID := 541
    ;FB-CrusadersGame.Effects.HavilarImpHandler
    effectKey := new CrusadersGame.Effects.EffectKey(24, 48, this)
    activeImps := new System.List(56, 112, this, System.Int32)
    currentOtherImpIndex := new System.Int32(296, 432, this)
    summonImpUltimate := new CrusadersGame.Defs.AttackDef(92, 184, this)
    sacrificeImpUltimate := new CrusadersGame.Defs.AttackDef(96, 192, this)
    ;FE
}

class OminContractualObligationsHandler extends ActiveEffectKeyHandler
{
    ChampID := 65
    UpgradeID := 4110
    EffectID := 649
    ;FB-CrusadersGame.Effects.OminContractualObligationsHandler
    effectKey := new CrusadersGame.Effects.EffectKey(28, 56, this)
    numContractsFufilled := new System.Int32(60, 120, this)
    secondsOnGoldFind := new System.Single(100, 156, this)
    ;FE
}

class NerdWagonHandler extends ActiveEffectKeyHandler
{
    ChampID := 87
    UpgradeID := 6152
    EffectID := 921
    ;FB-CrusadersGame.Effects.NerdWagonHandler
    effectKey := new CrusadersGame.Effects.EffectKey(24, 48, this)
    nerd0 := new CrusadersGame.Effects.NerdWagonHandler.Nerd(36, 72, this)
    nerd1 := new CrusadersGame.Effects.NerdWagonHandler.Nerd(40, 80, this)
    nerd2 := new CrusadersGame.Effects.NerdWagonHandler.Nerd(44, 88, this)
    ;FE

    class Nerd extends System.Object
    {
        type := new NerdWagonHandler.NerdType(0x10, 0x20, this)
    }

    class NerdType extends System.Enum
    {
        Type := "System.Int32"
        Enum := {0:"None", 1:"Fighter_Orange", 2:"Ranger_Red", 3:"Bard_Green", 4:"Cleric_Yellow", 5:"Rogue_Pink", 6:"Wizard_Purple"}
    }
}

class SentryEchoHandler extends ActiveEffectKeyHandler
{
    ChampID := 52
    UpgradeID := 3140
    EffectID := 488
    ;FB-CrusadersGame.Effects.SentryEchoHandler
    effectKey := new CrusadersGame.Effects.EffectKey(60, 0, this)
    baseResolutionAmount := new System.Double(112, 0, this)
    baseResolutionChance := new System.Double(120, 0, this)
    ;FE
}

class TimeScaleWhenNotAttackedHandler extends ActiveEffectKeyHandler
{
    ChampID := 47
    UpgradeID := 2774
    EffectID := 432
    ;FB-TimeScaleWhenNotAttackedHandler
    effectKey := new CrusadersGame.Effects.EffectKey(24, 48, this)
    scaleActive := new System.Boolean(224, 272, this)
    effectTime := new System.Double(232, 280, this)
    ;FE
}

class ActiveEffectKeyHandler extends System.Object
{
    __new()
    {
        this.Offset := 0
        this.GetAddress := this.variableGetAddress
        this.ParentObj := new ActiveEffectKeyHandler_Parent(_MemoryHandler.CreateOrGetHeroes(), this.ChampID, this.UpgradeID, this.EffectID, this)
        this.CachedAddress := ""
        this.ConsecutiveReads := 0
        return this
    }
    
    UseCachedAddress(setStatic, address)
    {
        if setStatic
        {
            this.CachedAddress := address
            this.GetAddress := this.staticGetAddress
        }
        else
            this.GetAddress := this.variableGetAddress
    }
}

class ActiveEffectKeyHandler_Parent extends System.Object
{
    __new(heroes, champID, upgradeID, effectID, child)
    {
        this.Hero := heroes.Item[champID - 1]
        this.UpgradeID := upgradeID
        this.EffectID := effectID
        this.Child := child
        this.GetAddress := this.variableGetAddress
        ;need to update this eventually
        this.LogGetAddress := this.variableGetAddress
        return this
    }

    variableGetAddress()
    {
        ;will read hero's address once then reuse that address for subsequent reads. this should probably be applied at each loop.
        this.Hero.UseCachedAddress(true)
        ;effectKeysByKeyName is Dict<string,List<CrusadersGame.Effects.EffectKey>>
        effectKeysByKeyName := this.Hero.effects.effectKeysByKeyName
        count := effectKeysByKeyname.count.GetValue()
        index := 0
        loop %count%
        {
            ;effectKeys is a list of EffectKey
            effectKeys := effectKeysByKeyName.Value[index]
            EK_size := effectKeys._size.Value ;.Size()
            EK_index := 0
            loop %EK_size%
            {
                parentEffectKeyHandler := effectKeys.Item[EK_index].parentEffectKeyHandler
                if (parentEffectKeyHandler.parent.def.ID := this.EffectID)
                {
                    ;activeEffecthandlers is list of CrusadersGame.Effects.ActiveEffectKeyHandler
                    ;these are the base type of our desired handlers, usually.
                    activeEffectHandlers := parentEffectKeyHandler.activeEffectHandlers
                    AEH_size := activeEffectHandlers._size.Value ;.Size()
                    AEH_index := 0
                    loop %AEH_size%
                    {
                        ;this effect key isnt in active effect handlers need to pass in effect handler to get these
                        activeEffectHandler := activeEffectHandlers.Item[AEH_index]
                        activeEffectHandlerAddress := activeEffectHandler.GetAddress()
                        this.Child.UseCachedAddress(true, activeEffectHandlerAddress)
                        id := this.Child.effectKey.parentEffectKeyHandler.parent.def.ID.GetValue()
                        if (id == this.EffectID)
                        {
                            this.Hero.UseCachedAddress(false)
                            this.Child.Offset := activeEffectHandler.Offset
                            this.Child.UseCachedAddress(false, 0)
                            return activeEffectHandlers._items.GetAddress()
                        }
                        ++AEH_index
                    }
                }
                ++EK_index
            }
            ++index
        }
        this.Hero.UseCachedAddress(false)
        return ""
    }
}
;Processing Time (minutes): 0.000000
;Processing Time (minutes): 0.000000
;Processing Time (minutes): 0.000000