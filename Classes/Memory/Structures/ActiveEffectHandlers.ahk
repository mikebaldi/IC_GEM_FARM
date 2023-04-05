class BrivSteelbonesHandler extends ActiveEffectKeyHandler
{
    ChampID := 58
    UpgradeID := 3450
    EffectID := 567
    ;FB-CrusadersGame.Effects.BrivSteelbonesHandler
    effectKey := new CrusadersGame.Effects.EffectKey(64, this)
    steelbonesStacks := new CrusadersGame.Effects.EffectStacks(72, this)
    ;FE
}

class BrivUnnaturalHasteHandler extends ActiveEffectKeyHandler
{
    ChampID := 58
    UpgradeID := 3452
    EffectID := 569
    ;FB-CrusadersGame.Effects.BrivUnnaturalHasteHandler
    effectKey := new CrusadersGame.Effects.EffectKey(64, this)
    sprintStacks := new CrusadersGame.Effects.EffectStacks(72, this)
    areaSkipChance := new System.Single(120, this)
    areaSkipAmount := new System.Int32(124, this)
    ;FE
}


class HewMaanTeamworkHandler extends ActiveEffectKeyHandler
{
    ChampID := 75
    UpgradeID := 4829
    EffectID := 763
    ;FB-CrusadersGame.Effects.HewMaanTeamworkHandler
    teamworkEffectKey := new CrusadersGame.Effects.EffectKey(64, this)
    carefullyBalancedEffectKey := new CrusadersGame.Effects.EffectKey(168, this)
    ;FE

    effectKey := this.teamworkEffectKey
}

class SentryEchoHandler extends ActiveEffectKeyHandler
{
    ChampID := 52
    UpgradeID := 3140
    EffectID := 488
    ;FB-CrusadersGame.Effects.SentryEchoHandler
    effectKey := new CrusadersGame.Effects.EffectKey(112, this)
    baseResolutionAmount := new System.Double(208, this)
    baseResolutionChance := new System.Double(216, this)
    ;FE
}

class TimeScaleWhenNotAttackedHandler extends ActiveEffectKeyHandler
{
    ChampID := 47
    UpgradeID := 2774
    EffectID := 432
    ;FB-TimeScaleWhenNotAttackedHandler
    effectKey := new CrusadersGame.Effects.EffectKey(64, this)
    scaleActive := new System.Boolean(288, this)
    effectTime := new System.Double(296, this)
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
        if !heroes
        {
            gameManager := new IdleGameManager
            gameInstance := gameManager.game.gameInstances.Item[0]
            heroes := gameManager.game.gameInstances.Item[0].HeroHandler.parent.heroes
        }
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