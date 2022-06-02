class IC_Leveling_Class
{
    __new()
    {
        this.Heroes := MemoryReader.InitHeroes()
        return this
    }

    SetFormation(formation)
    {
        this.Formation := {}
        size := formation.Count()
        this.Heroes.SetAddress(true)
        loop, %size%
        {
            champID := formation[A_Index]
            ;empty slots are defined as -1
            if (champID > 0)
                hero := new IC_HeroHandler_Class(champID)
            else
                continue
            hero.SetMaxLvl()
            this.Formation.Push(hero)
        }
        this.Heroes.SetAddress(false)
    }

    ;levels all champions in this.Formation once if not max level. use this.SetFormation(formation) to define this.Formation
    LevelFormation()
    {
        size := this.Formation.Count()
        if !size
            return
        this.Heroes.SetAddress(true)
        loop %size%
        {
            hero := this.Formation[A_Index]
            if (hero.Level < hero.MaxLvl)
                VirtualKeyInputs.Priority(hero.FKey)
        }
        this.Heroes.SetAddress(false)
        return
    }
}