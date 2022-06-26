class _IC_FuncLibrary
{
    __new()
    {
        this.IdleGameManager := _MemoryHandler.InitIdleGameManager()
        this.GameInstance := _MemoryHandler.InitGameInstance()
        this.ActiveCampaignData := _MemoryHandler.InitActiveCampaignData()
        this.AreaTransitioner := _MemoryHandler.InitAreaTransitioner()
        this.TopBar := _MemoryHandler.InitTopBar()
        this.SleepMS := 100
        this.BuildFormationSlots()
        return this
    }

    BuildFormationSlots()
    {
        this.FormationSlots := {}
        loop, 10
        {
            this.FormationSlots.Push(this.GameInstance.Controller.formation.slots.Item[A_Index - 1])
        }
        return
    }
    
    BypassBossBag()
    {
        if(!Mod(this.ActiveCampaignData.CurrentZone.Value, 5) AND Mod(this.ActiveCampaignData.HighestZone.Value, 5) AND !(this.AreaTransitioner.IsTransitioning.Value))
            this.ToggleAutoProgress(1,1)
        return
    }

    FallBackFromBossZone(spam := "", maxLoopTime := 5000)
    {
        if mod(this.ActiveCampaignData.CurrentZone.Value, 5)
            return false
        StartTime := A_TickCount
        ElapsedTime := 0
        while (!mod(this.ActiveCampaignData.CurrentZone.Value, 5) AND ElapsedTime < maxLoopTime)
        {
            _VirtualKeyInputs.Priority("{Left}")
            sleep, % this.SleepMS
            ElapsedTime := A_TickCount - StartTime
        }
        this.WaitForTransition(spam)
        return true
    }

    ; not used, to be updated when used
    ; waitTime: max time in ms will wait to finish zone, lvlFormation: bool to call method, inputs: variadic param of inputs
    FinishZone(waitTime, lvlFormation, inputs*)
    {
        startTime := A_TickCount
        elapsedTime := 0
        while (elapsedTime < waitTime AND this.ActiveCampaignData.QuestRemaining.Value > 0)
        {
            lvlFormation.LevelFormation()
            _VirtualKeyInputs.Priority(inputs*)
            sleep, % this.SleepMS
            elapsedTime := A_TickCount - startTime
        }
        return
    }

    IsCurrentFormation(formation)
    {
        g_Log.CreateEvent(A_ThisFunc)
        g_Log.AddData("formation", formation)
        if(!IsObject(formation))
        {
            g_Log.EndEvent()
            return false
        }
        match := true
        this.GameInstance.Controller.formation.slots.UseCachedAddress(true)
        loop, % formation.Count()
        {
            heroID := this.FormationSlots[A_Index].hero.def.ID.Value
            g_Log.AddData("heroID", heroID)
            if (formation[A_index] == -1 AND !heroID)
            {
                match := false
                break
            }
            else if(heroID AND formation[A_Index] != heroID)
            {
                match := false
                break
            }
        }
        this.GameInstance.Controller.formation.slots.UseCachedAddress(false)
        g_Log.AddData("match", match)
        g_Log.EndEvent()
        return match
    }

    SetClickLevel(value)
    {
        clickLevel := this.GameInstance.ClickLevel.Value
        if (clickLevel AND clickLevel < value)
            this.GameInstance.ClickLevel.Value := value
    }

    SetTimeScale(value)
    {
        timeScale := this.IdleGameManager.TimeScale.Value
        if (timeScale AND timeScale < value)
            this.IdleGameManager.TimeScale.Value := value
    }

    ToggleAutoProgress( isToggled := 1, forceToggle := false, forceState := false )
    {
        startTime := A_TickCount
        if (forceToggle)
            _VirtualKeyInputs.Priority("g")
        if (this.TopBar.AutoProgressToggled.Value != isToggled)
            _VirtualKeyInputs.Priority("g")
        while (forceState AND this.TopBar.AutoProgressToggled.Value != isToggled AND (A_TickCount - startTime) < 5001)
            _VirtualKeyInputs.Priority("g")
    }

    WaitForFirstGold( maxLoopTime := 30000 )
    {
        StartTime := A_TickCount
        ElapsedTime := 0
        _VirtualKeyInputs.Priority("q")
        while ( this.ActiveCampaignData.Gold.Value == 0 AND ElapsedTime < maxLoopTime )
        {
            _VirtualKeyInputs.Priority("q")
            sleep, % this.SleepMS
            ElapsedTime := A_TickCount - StartTime
        }
        return ElapsedTime
    }

    WaitForTransition( spam := "", maxLoopTime := 5000 )
    {
        if !(this.AreaTransitioner.IsTransitioning.Value)
            return
        StartTime := A_TickCount
        ElapsedTime := 0
        while (this.AreaTransitioner.IsTransitioning.Value == 1 and ElapsedTime < maxLoopTime)
        {
            _VirtualKeyInputs.Priority(spam*)
            sleep, % this.SleepMS
            ElapsedTime := A_TickCount - StartTime
        }
        return
    }
}