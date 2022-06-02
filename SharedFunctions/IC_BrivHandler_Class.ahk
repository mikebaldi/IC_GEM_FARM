class IC_BrivHandler_Class extends IC_HeroHandler_Class
{
    Init()
    {
        this.ResetPrevValues()
        this.SteelbonesHandler := new BrivSteelbonesHandler
        this.UnnaturalHasteHandler := new BrivUnnaturalHasteHandler
        gameInstance := MemoryReader.InitGameInstance()
        this.BrivSprintStacks := gameInstance.Controller.userData.StatHandler.BrivSprintStacks
        this.BrivSteelbonesStacks := gameInstance.Controller.userData.StatHandler.BrivSteelBonesStacks
        ;used for briv swap
        this.ActionList := gameInstance.Controller.formation.transitionOverrides.Value[0]
        this.areaTransitioner := gameInstance.Controller.areaTransitioner
        this.formation := gameInstance.Controller.formation
    }

    StackFarm(settings, obj)
    {
        if settings.RestartStackTime
            this.StackRestart(settings, obj)
        else
            this.StackNormal(settings)
    }

    StackRestart(settings, obj)
    {
        g_Log.CreateEvent(A_ThisFunc)
        i := 0
        while (this.Stacks < settings.TargetStacks AND i < 10)
        {
            g_Log.CreateEvent("Stack Restart Attempt: " . ++i)
            this.StackFarmSetup(settings)
            sleep, 1000
            g_SF.CloseIC(A_ThisFunc)
            startTime := A_TickCount
            elapsedTime := 0
            if settings.DoChests
            {
                obj.BuyOrOpenChests()
            }
            elapsedTime := A_TickCount - startTime
            while ( elapsedTime < settings.RestartStackTime)
            {
                sleep, 100
                elapsedTime := A_TickCount - startTime
            }
            g_SF.OpenIC(settings.InstallPath)
            g_SF.LoadAdventure(this)
            g_Log.AddData("HasteStacks", this.HasteStacks)
            g_Log.AddData("SBStacks", this.SBStacks)
            currentZone := MemoryReader.GameInstance.ActiveCampaignData.currentAreaID.GetValue()
            if (currentZone < settings.StackZone)
            {
                g_Log.AddData("currentZone", currentZone)
                g_Log.EndEvent()
                g_Log.EndEvent()
                return
            }
            g_Log.AddData("currentZone", currentZone)
            g_Log.EndEvent()
        }
        VirtualKeyInputs.Priority("q")
        g_SF.ToggleAutoProgress(1)
        g_Log.EndEvent()
        return
    }

    StackNormal(settings)
    {
        return
    }

    StackFarmSetup(settings)
    {
        g_Log.CreateEvent(A_ThisFunc)
        VirtualKeyInputs.Priority("w")
        g_SF.WaitForTransition("w")
        g_SF.ToggleAutoProgress(0)
        g_SF.FallBackFromBossZone("w")
        startTime := A_TickCount
        elapsedTime := 0
        while(g_SF.IsCurrentFormation(settings.StackFormation) AND elapsedTime < 5000)
        {
            VirtualKeyInputs.Priority("w")
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        g_Log.EndEvent()
    }

    ; a method to swap formations and cancel briv's jump animation.
    CancelJumpAnimation(settings)
    {
        ;only send input messages if necessary
        benched := this.Benched
        ;check to bench briv
        if (!benched AND this.BenchConditions(settings))
        {
            VirtualKeyInputs.Priority("e")
        }
        ;check to unbench briv
        else if (benched AND this.UnBenchConditions(settings))
        {
            VirtualKeyInputs.Priority("q")
        }
        ; check to swap briv from favorite 2 to favorite 1 (W to Q)
        else if (!benched AND this.IsCurrentFormation(settings.stackFormation))
        {
            VirtualKeyInputs.Priority("q")
        }
    }

    ; True/False on whether Briv should be benched based on game conditions.
    BenchConditions(settings)
    {
        ;bench briv if jump animation override is added to list and it isn't a quick transition (reading ReadFormationTransitionDir makes sure QT isn't read too early)
        if (this.ActionList.Size() == 1 AND this.areaTransitioner.transitionDirection.GetValue() != 2 AND this.this.formation.transitionDir.GetValue() == 3 )
            return true

        return false
    }

    ; True/False on whether Briv should be unbenched based on game conditions.
    UnBenchConditions(settings)
    {
        ;unbench briv if 'Briv Jump Buffer' setting is disabled and transition direction is "OnFromLeft"
        if (this.areaTransitioner.transitionDirection.GetValue() == 0)
            return true

        return false
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
        ;should maybe use stathandler for faster reads
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