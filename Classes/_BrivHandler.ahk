class _BrivHandler extends _HeroHandler
{
    Init()
    {
        this.ResetPrevValues()
        this.SteelbonesHandler := new BrivSteelbonesHandler
        this.UnnaturalHasteHandler := new BrivUnnaturalHasteHandler
        gameInstance := _MemoryHandler.CreateOrGetGameInstance()
        this.BrivSprintStacks := gameInstance.Controller.userData.StatHandler.BrivSprintStacks
        this.BrivSteelbonesStacks := gameInstance.Controller.userData.StatHandler.BrivSteelBonesStacks
    }

    ;use this function at your own risk, this functionality has been condemned by CNE
    ForceConvertStacks()
    {
        this.HasteStacks := this.Stacks
        this.SBStacks := 0
        return
    }

    ;use setters at your own risk, this functionality has been condemned by CNE
    HasteStacks[]
    {
        get
        {
            return this.BrivSprintStacks.Value
        }

        set
        {
            this.BrivSprintStacks.Value := value
            return this.UnnaturalHasteHandler.sprintStacks.stackCount.Value := value
        }
    }

    ;use setters at your own risk, this functionality has been condemned by CNE
    SBStacks[]
    {
        get
        {
            return this.BrivSteelbonesStacks.Value
        }

        set
        {
            this.BrivSteelbonesStacks.Value := value
            return this.SteelbonesHandler.steelbonesStacks.stackCount.Value := value
        }
    }

    Stacks[]
    {
        get
        {
            return this.HasteStacks + this.SBStacks
        }
    }
}