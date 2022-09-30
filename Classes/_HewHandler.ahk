class _HewHandler extends _HeroHandler
{
    Init()
    {
        this.carefullyBalancedReqLvl := 200
        this.carefullyBalancedEffectID := 765
        this.teamWorkHandler := new HewMaanTeamworkHandler
        this.carefullyBalancedEffectKey := this.teamworkHandler.carefullyBalancedEffectKey
        this.carefullyBalancedCachedQuads := this.carefullyBalancedEffectKey.parentEffectKeyHandler.effectKeyParams.cachedQuads
        this.carefullyBalancedCachedQuadsIndex := -1
    }

    ;return value -1 means Hew is not high enough level
    ;return value -2 means function could not cached quad for amount key
    ;return value -3 means function confirmed value was already set correctly
    ;return value 1 means function set value and a formation swap is necessary to enact
    SetOneKill()
    {
        if (this.Level.Value < this.carefullyBalancedReqLvl)
            return -1

        this.hero.UseCachedAddress(true)
        if ((this.carefullyBalancedCachedQuadsIndex < 0) OR this.carefullyBalancedCachedQuads.Key[this.carefullyBalancedCachedQuadsIndex].Value != "amount")
        {
            this.carefullyBalancedCachedQuadsIndex := this.carefullyBalancedCachedQuads.Keys.GetIndexByValueType("amount")
            if (this.carefullyBalancedCachedQuadsIndex < 0)
            {
                this.hero.UseCachedAddress(false)
                return -2
            }
        }
        if (this.carefullyBalancedCachedQuads.Value[this.carefullyBalancedCachedQuadsIndex].Exponent.Value != -56)
        {
            this.carefullyBalancedCachedQuads.Value[this.carefullyBalancedCachedQuadsIndex].Exponent.Value := -56
            this.hero.UseCachedAddress(false)
            return 1
        }
        this.hero.UseCachedAddress(false)
        return -3
    }
}