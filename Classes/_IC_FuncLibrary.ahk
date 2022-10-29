class _IC_FuncLibrary extends _Contained
{
    __new()
    {
        this.IdleGameManager := _MemoryHandler.CreateOrGetIdleGameManager()
        this.GameInstance := _MemoryHandler.CreateOrGetGameInstance()
        this.ActiveCampaignData := _MemoryHandler.CreateOrGetActiveCampaignData()
        this.AreaTransitioner := _MemoryHandler.CreateOrGetAreaTransitioner()
        this.ResetHandler := _MemoryHandler.CreateOrGetResetHandler()
        this.TopBar := _MemoryHandler.CreateOrGetTopBar()
        this.ModronHandler := this.GameInstance.Controller.userData.ModronHandler
        this.SleepMS := 100
        return this
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
        ;g_Log.CreateEvent(A_ThisFunc)
        StartTime := A_TickCount
        ElapsedTime := 0
        while (!mod(this.ActiveCampaignData.CurrentZone.Value, 5) AND ElapsedTime < maxLoopTime)
        {
            _VirtualKeyInputs.Priority("{Left}")
            sleep, % this.SleepMS
            ElapsedTime := A_TickCount - StartTime
        }
        this.WaitForTransition(spam)
        ;g_Log.EndEvent()
        return true
    }

    ; not used, to be updated when used
    ; waitTime: max time in ms will wait to finish zone, lvlFormation: bool to call method, inputs: variadic param of inputs
    FinishZone(waitTime, lvlFormation, inputs*)
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (elapsedTime < waitTime AND this.ActiveCampaignData.QuestRemaining.Value > 0)
        {
            lvlFormation.LevelFormation()
            _VirtualKeyInputs.Priority(inputs*)
            sleep, % this.SleepMS
            elapsedTime := A_TickCount - startTime
        }
        ;g_Log.EndEvent()
        return
    }

    ModronSaveObj[]
    {
        get
        {
            this.ModronHandler.UseCachedAddress(true)
            if (this.cachedModronSaveObj.InstanceID.Value != 1)
            {
                _size := this.ModronHandler.modronSaves._size.Value
                index := 0
                loop, %_size%
                {
                    this.cachedModronSaveObj := this.ModronHandler.modronSaves.Item[index]
                    if (this.cachedModronSaveObj.InstanceID.Value == 1)
                        break
                    index++
                }
            }
            this.ModronHandler.UseCachedAddress(false)
            return this.cachedModronSaveObj
        }
    }

    SetModronTargetArea(value)
    {
        return this.ModronSaveObj.targetArea.Value := value
    }

    GetModrtonTargetArea()
    {
        return this.ModronSaveObj.targetArea.Value
    }

    GetModronTargetAreaOLD()
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        offlineHandlerTA := -1
        userDataTA := -1
        offlineHandlerTA := this.GameInstance.offlineProgressHandler.modronSave.targetArea.Value
        ;if (!offlineHandlerTA)
            ;g_Log.AddDataSimple("offlineHandlerTA read failed")
        modronHandler := this.GameInstance.Controller.userData.ModronHandler
        ;modronHandler.UseCachedAddress(true)
        _size := modronHandler.modronSaves._size.Value
        index := 0
        loop, %_size%
        {
            item := modronHandler.modronSaves.Item[index]
            if (item.InstanceID.Value == 1)
                userDataTA := item.targetArea.Value
            index++
        }
        ;if (!userDataTA)
            ;g_Log.AddDataSimple("userDataTA read failed")
        ;if (offlineHandlerTA != userDataTA)
            ;g_Log.AddDataSimple("userDataTA: " . userDataTA . ", offlineHandlerTA: " . offlineHandlerTA)
        ;g_Log.EndEvent()
        return offlineHandlerTA
    }

    IsCurrentFormation(formation)
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        ;g_Log.AddData("formation", formation)
        if(!IsObject(formation))
        {
            ;g_Log.EndEvent()
            return false
        }
        match := true
        this.GameInstance.Controller.formation.slots.UseCachedAddress(true)
        loop, % formation.Count()
        {
            heroID := this.GameInstance.Controller.formation.slots.Item[A_Index - 1].hero.def.ID.Value
            ;g_Log.AddData("heroID", heroID)
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
        ;g_Log.AddData("match", match)
        ;g_Log.EndEvent()
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
        ;g_Log.CreateEvent(A_ThisFunc)
        StartTime := A_TickCount
        ElapsedTime := 0
        _VirtualKeyInputs.Priority("q")
        while ( this.ActiveCampaignData.Gold.Value == 0 AND ElapsedTime < maxLoopTime )
        {
            _VirtualKeyInputs.Priority("q")
            sleep, % this.SleepMS
            ElapsedTime := A_TickCount - StartTime
        }
        ;g_Log.EndEvent()
        return ElapsedTime
    }

    WaitForTransition( spam := "", maxLoopTime := 5000 )
    {
        if !(this.AreaTransitioner.IsTransitioning.Value)
            return
        ;g_Log.CreateEvent(A_ThisFunc)
        StartTime := A_TickCount
        ElapsedTime := 0
        while (this.AreaTransitioner.IsTransitioning.Value == 1 and ElapsedTime < maxLoopTime)
        {
            _VirtualKeyInputs.Priority(spam*)
            sleep, % this.SleepMS
            ElapsedTime := A_TickCount - StartTime
        }
        ;g_Log.EndEvent()
        return
    }
}