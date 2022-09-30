class BrivSteelbonesHandler extends ActiveEffectKeyHandler
{
    ChampID := 58
    UpgradeID := 3450
    EffectID := 567
    ;FB-CrusadersGame.Effects.BrivSteelbonesHandler
    effectKey := new CrusadersGame.Effects.EffectKey(48, this)
    steelbonesStacks := new CrusadersGame.Effects.EffectStacks(56, this)
    ;FE
}

class BrivUnnaturalHasteHandler extends ActiveEffectKeyHandler
{
    ChampID := 58
    UpgradeID := 3452
    EffectID := 569
    ;FB-CrusadersGame.Effects.BrivUnnaturalHasteHandler
    effectKey := new CrusadersGame.Effects.EffectKey(48, this)
    sprintStacks := new CrusadersGame.Effects.EffectStacks(56, this)
    areaSkipChance := new System.Single(104, this)
    areaSkipAmount := new System.Int32(108, this)
    ;FE
}

class HavilarImpHandler extends ActiveEffectKeyHandler
{
    ChampID := 56
    UpgradeID := 3431
    EffectID := 541
    ;FB-CrusadersGame.Effects.HavilarImpHandler
    effectKey := new CrusadersGame.Effects.EffectKey(48, this)
    activeImps := new System.List(112, this, System.Int32)
    currentOtherImpIndex := new System.Int32(432, this)
    summonImpUltimate := new CrusadersGame.Defs.AttackDef(184, this)
    sacrificeImpUltimate := new CrusadersGame.Defs.AttackDef(192, this)
    ;FE
}

class HewMaanTeamworkHandler extends ActiveEffectKeyHandler
{
    ChampID := 75
    UpgradeID := 4829
    EffectID := 763
    ;FB-CrusadersGame.Effects.HewMaanTeamworkHandler
    teamworkEffectKey := new CrusadersGame.Effects.EffectKey(0x30, this)
    carefullyBalancedEffectKey := new CrusadersGame.Effects.EffectKey(0x98, this)
    ;FE

    effectKey := this.teamworkEffectKey
}

class OminContractualObligationsHandler extends ActiveEffectKeyHandler
{
    ChampID := 65
    UpgradeID := 4110
    EffectID := 649
    ;FB-CrusadersGame.Effects.OminContractualObligationsHandler
    effectKey := new CrusadersGame.Effects.EffectKey(48, this)
    buffTimer := new UnityGameEngine.Utilities.SimpleTimer(0x78, this)
    obligationsRequired := new System.Int32(0x8C, this)
    obligationsFufilled := new System.Int32(0x90, this)
    isGoldBuffApplied := new System.Boolean(0x98, this)
    ;FE
}

class NerdWagonHandler extends ActiveEffectKeyHandler
{
    ChampID := 87
    UpgradeID := 6152
    EffectID := 921
    ;FB-CrusadersGame.Effects.NerdWagonHandler
    effectKey := new CrusadersGame.Effects.EffectKey(48, this)
    nerd0 := new CrusadersGame.Effects.NerdWagonHandler.Nerd(72, this)
    nerd1 := new CrusadersGame.Effects.NerdWagonHandler.Nerd(80, this)
    nerd2 := new CrusadersGame.Effects.NerdWagonHandler.Nerd(88, this)
    ;FE

    class Nerd extends System.Object
    {
        type := new NerdWagonHandler.NerdType(0x20, this)
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
    effectKey := new CrusadersGame.Effects.EffectKey(96, this)
    baseResolutionAmount := new System.Double(192, this)
    baseResolutionChance := new System.Double(200, this)
    ;FE
}

class TimeScaleWhenNotAttackedHandler extends ActiveEffectKeyHandler
{
    ChampID := 47
    UpgradeID := 2774
    EffectID := 432
    ;FB-TimeScaleWhenNotAttackedHandler
    effectKey := new CrusadersGame.Effects.EffectKey(48, this)
    scaleActive := new System.Boolean(272, this)
    effectTime := new System.Double(280, this)
    ;FE
}

class ActiveEffectKeyHandler extends System.Object
{
    __new()
    {
        this.Offset := 0
        this.GetAddress := this.variableGetAddress
        this.CachedAddress := ""
        heroes := _MemoryHandler.CreateOrGetHeroes()
        this.Hero := heroes.Item[this.ChampID - 1]
        this.effectKeysByKeyName := this.Hero.effects.effectKeysByKeyName
        this.effectKeysByKeyNameIndex := -1
        this.effectKeysIndex := -1
        this.activeEffectHandlersIndex := -1
        return this
    }

    variableGetAddress()
    {
        this.Hero.UseCachedAddress(true)
        if (this.activeEffectHandlersIndex < 0 OR this.activeEffectHandler.effectKey.Offset == 0 OR this.activeEffectHandler.effectKey.parentEffectKeyHandler.parent.def.ID.Value != this.EffectID)
        {
            activeEffectHandlers := this.GetActiveEffectHandlersList()
            _size := activeEffectHandlers._size.Value
            this.activeEffectHandlersIndex := 0
            loop %_size%
            {
                this.activeEffectHandler := activeEffectHandlers.Item[this.activeEffectHandlersIndex]
                this.activeEffectHandler.effectKey.Offset := this.effectKey.Offset
                if (this.activeEffectHandler.effectKey.parentEffectKeyHandler.parent.def.ID.Value == this.EffectID)
                {
                    this.Offset := this.activeEffectHandler.Offset
                    address := this.activeEffectHandler.GetAddress()
                    this.Hero.UseCachedAddress(false)
                    return address
                }
                this.activeEffectHandlersIndex += 1
            }
        }
        else if (this.activeEffectHandler.effectKey.parentEffectKeyHandler.parent.def.ID.Value == this.EffectID)
        {
            address := this.activeEffectHandler.GetAddress()
            this.Hero.UseCachedAddress(false)
            return address
        }
        this.Hero.UseCachedAddress(false)
        this.activeEffectHandlersIndex := -1
        return ""
    }

    GetActiveEffectHandlersList()
    {
        this.Hero.UseCachedAddress(true)
        if (this.effectKeysByKeyNameIndex < 0 OR this.effectKeysIndex < 0 OR this.parentEffectKeyHandler.parent.def.ID.Value != this.EffectID)
        {
            count := this.effectKeysByKeyName.count.Value
            this.effectKeysByKeyNameIndex := 0
            loop %count%
            {
                ;effectKeys is a list of EffectKey
                effectKeys := this.effectKeysByKeyName.Value[this.effectKeysByKeyNameIndex]
                EK_size := effectKeys._size.Value ;.Size()
                this.EffectKeysIndex := 0
                loop %EK_size%
                {
                    this.parentEffectKeyHandler := effectKeys.Item[this.EffectKeysIndex].parentEffectKeyHandler
                    if (this.parentEffectKeyHandler.parent.def.ID.Value == this.EffectID)
                    {
                        this.ParentObj := this.parentEffectKeyHandler.activeEffectHandlers._items
                        this.Hero.UseCachedAddress(false)
                        return this.parentEffectKeyHandler.activeEffectHandlers
                    }
                    this.EffectKeysIndex += 1
                }
                this.effectKeysByKeyNameIndex += 1
            }
        }
        else if (this.parentEffectKeyHandler.parent.def.ID.Value == this.EffectID)
        {
            this.Hero.UseCachedAddress(false)
            return this.parentEffectKeyHandler.activeEffectHandlers
        }
        this.Hero.UseCachedAddress(false)
        this.effectKeysByKeyNameIndex := -1
        this.EffectKeysIndex := -1
        return ""
    }
}