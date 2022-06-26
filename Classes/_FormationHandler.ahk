class _FormationHandler
{
    __new()
    {
        this.Heroes := _MemoryHandler.InitHeroes()
        return this
    }

    SetFormation(formation)
    {
        this.Formation := {}
        size := formation.Count()
        this.Heroes.UseCachedAddress(true)
        loop, %size%
        {
            champID := formation[A_Index]
            ;empty slots are defined as -1
            if (champID > 0)
                hero := new _HeroHandler(champID)
            else
                continue
            hero.SetMaxLvl()
            this.Formation.Push(hero)
        }
        this.Heroes.UseCachedAddress(false)
    }

    ;levels all champions in this.Formation once if not max level. use this.SetFormation(formation) to define this.Formation
    LevelFormation()
    {
        size := this.Formation.Count()
        if !size
            return
        this.Heroes.UseCachedAddress(true)
        loop %size%
        {
            hero := this.Formation[A_Index]
            if (hero.Level.Value < hero.MaxLvl)
                _VirtualKeyInputs.Priority(hero.FKey)
        }
        this.Heroes.UseCachedAddress(false)
        return
    }
}