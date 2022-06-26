class _SentryHandler extends _HeroHandler
{
    Init()
    {
        this.EchoHandler := new SentryEchoHandler
        this.ResolutionAmount := this.EchoHandler.baseResolutionAmount
        this.ResolutionChance := this.EchoHandler.baseResolutionChance
    }

    SetOneKill()
    {
        if (this.Level.Value < 225)
            return
        resAmount := this.ResolutionAmount.Value
        if (resAmount != "" AND resAmount != 100)
            this.ResolutionAmount.Value := 100
        resChance := this.ResolutionChance.Value
        if (resChance != "" AND resChance != 99)
            this.ResolutionChance.Value := 99
    }
}