class IC_GemFarm_Functions
{
    __new(settings)
    {
        this.Settings := settings
        ;1000 ms per sec, 60 sec per min, 60 min per hour, reload script every 12 hours
        ;reloading helps keep key inputs more reliable and faster
        this.ReloadTime := ( 1000 * 60 * 60 * 12 ) + A_TickCount
        MemoryReader.Refresh()
        ;this.IdleGameManager := MemoryReader.InitIdleGameManager()
        this.GameInstance := MemoryReader.InitGameInstance()
        this.Briv := new IC_BrivHandler_Class(58)
        this.ActiveCampaignData := MemoryReader.InitActiveCampaignData()
        this.Stats := this.GameInstance.Controller.userData.StatHandler
        this.UserData := MemoryReader.InitUserData()
        this.ResetPrevValues()
        this.ServerCall := new IC_ServerCalls_Class
        this.Resetting := this.GameInstance.Resethandler.resetting.Value
        return this
    }

    ResetPrevValues()
    {
        this.GameInstance.Resethandler.resetting.prevValue := ""
        this.CurrentZonePrev := ""
    }

    ;property of a property... ??? it is so we can separately track previous value for logging and previous value for if stuck.
    ;stuck is unique to gem farming
    CurrentZone[]
    {
        get
        {
            value := this.ActiveCampaignData.CurrentZone
            if (value > this.CurrentZonePrev)
            {
                this.CurrentZonePrev := value
                this.CurrentZonePrevTime := A_TickCount
            }
            return value
        }
    }

    GemFarm()
    {
        g_Log.CreateEvent("Startup")
        g_Log.AddData("Settings", this.Settings)

        while !(g_SF.SafetyCheck(true))
        {
            g_SF.OpenIC(this.Settings.InstallPath)
            g_SF.LoadAdventure(this.Briv)
        }

        MemoryReader.Refresh()

        this.CurrentObjective := this.ActiveCampaignData.CurrentObjective

        ;read in formations
        formationModron := g_SF.Memory.GetActiveModronFormation()
        g_Log.AddData("Modron Formation", ArrFnc.GetDecFormattedArrayString(formationModron))
        ;these are just to troubleshoot
        formationQ := g_SF.FindChampIDinSavedFormation( 1, "Speed", 1, 58 )
        g_Log.AddData("Q Formation", ArrFnc.GetDecFormattedArrayString(formationQ))
        formationW := g_SF.FindChampIDinSavedFormation( 2, "Stack Farm", 1, 58 )
        g_Log.AddData("W Formation", ArrFnc.GetDecFormattedArrayString(formationW))
        this.Settings.stackFormation := formationW
        formationE := g_SF.FindChampIDinSavedFormation( 3, "Speed No Briv", 0, 58 )
        g_Log.AddData("E Formation", ArrFnc.GetDecFormattedArrayString(formationE))

        ;build fkey input data
        if (this.Settings.UseFkeys)
        {
            g_Level.SetFormation(formationModron)
            tempObj := {}
            size := g_Level.Formation.Count()
            i := 1
            loop %size%
            {
                tempObj[i] := {}
                for k, v in g_Level.Formation[A_Index]
                {
                    if !IsObject(v)
                        tempObj[i][k] := v
                }
                ++i
            }
            g_Log.AddData("Formation Data", tempObj) ;JSON.Stringify(tempObj))
            tempObj := ""
        }

        ;set up shandie
        if (this.Settings.DashWait)
        {
            this.Shandie := new IC_ShandieHandler_Class(47)
        }

        ;adds start up to log file
        g_Log.LogStack()
        ;start new log event
        g_Log.CreateEvent("Gem Farm-Partial")

        loop
        {
            if !(g_SF.SafetyCheck())
            {
                g_SF.OpenIC(this.Settings.InstallPath)
                g_SF.LoadAdventure(this.Briv)
                this.CurrentZonePrevTime := A_TickCount
            }
            
            this.Briv.CancelJumpAnimation(this.Settings)

            this.CheckDoZoneOne()

            this.CheckStackFarm()

            this.CheckModronResetting()

            g_SF.ToggleAutoProgress(1)
            
            this.DoMoreStuff()

            this.CheckForceConvertStacks()

            ;not sure this is needed with force convert stacks
            ;this.CheckForceModronReset()

            this.CheckifStuck()

            if (this.Settings.UseFkeys)
                g_Level.LevelFormation()
        }
    }

    ;need to add better code in case a modron reset happens without being detected. might mean updating other functions.
    CheckifStuck()
    {
        if ((A_TickCount - this.CurrentZonePrevTime) > 60000)
        {
            g_Log.CreateEvent(A_ThisFunc)
            this.CloseIC(A_ThisFunc)
            sleep, 1000
            this.CloseIC( reason )
            this.ServerCall.CallEndAdventure()
            this.ServerCall.CallLoadAdventure( this.CurrentAdventure )
            g_SF.OpenIC(this.Settings.InstallPath)
            g_SF.LoadAdventure(this.Briv)
            this.CurrentZonePrevTime := A_TickCount
            g_Log.EndEvent()
        }
    }

    CheckForceModronReset()
    {

    }

    CheckForceConvertStacks()
    {
        if (this.Briv.HasteStacks < 50 AND this.Briv.Stacks > this.Settings.TargetStacks)
            this.Briv.ForceConvertStacks()
    }

    DoMoreStuff()
    {
        VirtualKeyInputs.Priority("{Right}")
        ;extend class and modify this method to add more functionality
    }

    CheckModronResetting()
    {
        if (this.Resetting)
            this.ModronReset()
    }

    ModronReset()
    {
        if (this.ReloadTime < A_TickCount)
        {
            g_Log.AddData("Reloading Script", "")
            g_Log.LogStack()
            Reload
        }
        g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (this.Resetting AND elapsedTime < 60000)
        {
            sleep, 250
            elapsedTime := A_TickCount - startTime
        }
        ;stuck resetting, restarting client
        if (elapsedTime > 60000)
        {
            g_Log.AddData("Stuck Resetting: elapsedTime", elapsedTime)
            g_SF.CloseIC("Stuck Resetting")
            sleep, 250
            g_SF.OpenIC()
            g_SF.LoadAdventure()
        }
        this.CurrentZonePrevTime := A_TickCount
        g_Log.EndEvent()
        return
    }

    CheckStackFarm()
    {
        if (this.CurrentZone > this.Settings.StackZone AND this.Briv.Stacks < this.Settings.TargetStacks)
        {
            if (this.Settings.DoChests)
                this.UpdateChestData()
            this.Briv.StackFarm(this.Settings, this)
            this.CurrentZonePrevTime := A_TickCount
        }
        else if (this.Briv.HasteStacks < 50 AND this.CurrentZone > this.Settings.MinStackZone AND this.Briv.Stacks < this.Settings.TargetStacks)
        {
            if (this.Settings.DoChests)
                this.UpdateChestData()
            this.Briv.StackFarm(this.Settings, this)
            this.CurrentZonePrevTime := A_TickCount
        }
    }

    UpdateChestData()
    {
        g_Log.CreateEvent(A_ThisFunc)
        this.Settings.Gems := this.UserData.Gems
        g_Log.AddData("gems", this.Settings.Gems)
        this.Settings.OpenChests.Counts := {}
        for k, v in this.Settings.OpenChests.Chests
        {
            this.Settings.OpenChests.Counts[v] := this.UserData.ChestCount[v]
        }
        g_Log.AddData("Counts", this.Settings.OpenChests.Counts)
        g_Log.EndEvent()
        return
    }

    CheckDoZoneOne()
    {
        if (this.CurrentZone == 1)
        {
            this.PrevZone := 1
            this.DoZoneOne()
        }
    }

    DoZoneOne()
    {
        ;log previous run, start new run
        g_Log.LogStack()
        g_Log.CreateEvent("Gem Farm")
        g_Log.CreateEvent(A_ThisFunc)
        ;make sure we can do something on zone 1, ie kill monster and get some gold
        startTime := A_TickCount
        elapsedTime := 0
        gold := this.ActiveCampaignData.Gold
        While (!gold AND elapsedTime < 60000)
        {
            VirtualKeyInputs.Priority("q")
            sleep, 100
            elapsedTime := A_TickCount - startTime
            gold := this.ActiveCampaignData.Gold
        }
        ;if after 60s still no gold, leave this func
        if !gold
        {
            g_Log.AddData("gold", gold)
            g_Log.EndEvent()
            return
        }
        ;level briv to unlock MetalBorn
        this.Briv.LevelUp(170,, "q")
        g_SF.ToggleAutoProgress(0)
        if (this.Settings.DashWait)
        {
            ;level shandie to unlock Dash
            this.Shandie.LevelUp(120,, "q")
            this.CheckDoDashWait()
        }
        ;finish zone one spamming inputs, so we don't end up just back in this function
        ;could use some toggle, but game screws up so toggle won't get flipped
        g_SF.FinishZone(30000, this.Settings.UseFkeys, "q")
        g_SF.ToggleAutoProgress(1)
        ;call briv swap
        this.Briv.CancelJumpAnimation(this.Settings)
        this.CurrentZonePrevTime := A_TickCount
        g_Log.EndEvent()
    }

    CheckDoDashWait()
    {
        if (this.Settings.DashWait AND !(this.Shandie.IsDashActive))
        {
            this.Shandie.DoDashWait("q", this.Settings.UseFkeys)
        }
    }  

    BuyOrOpenChests()
    {
        g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        var := ""
        var2 := ""
        openChestTimeEst := 7000 ; 7s
        purchaseTime := 100 ; .1s
        gems := this.Settings.Gems - this.Settings[ "MinGemCount" ]
        g_Log.AddData("Start Gems", gems)
        restartTime := this.Settings.RestartStackTime
        checkAgain := false
        while (elapsedTime < restartTime)
        {
            if (this.Settings.BuySilvers AND gems > 5000 AND elapsedTime < (restartTime - purchaseTime))
            {
                response := this.ServerCall.callBuyChests(1, 100)
                g_Log.AddData("BuySilvers", response)
                if(response.okay AND response.success)
                {
                    gems := response.currency_remaining - this.Settings[ "MinGemCount" ]
                    if (gems > 5000)
                        checkAgain := true
                    this.Settings.OpenChests.Counts[1] := response.chest_count
                }
            }
            elapsedTime := A_TickCount - startTime
            if (this.Settings.BuyGolds AND gems > 50000 AND elapsedTime < (restartTime - purchaseTime))
            {
                response := this.ServerCall.callBuyChests(2, 100)
                g_Log.AddData("BuyGolds", response)
                if(response.okay AND response.success)
                {
                    gems := response.currency_remaining - this.Settings[ "MinGemCount" ]
                    if (gems > 50000)
                        checkAgain := true
                    this.Settings.OpenChests.Counts[2] := response.chest_count
                }
            }
            elapsedTime := A_TickCount - startTime
            for k, v in this.Settings.OpenChests.Counts
            {
                if (v > 98 AND elapsedTime < (restartTime - openChestTimeEst))
                {
                    chestResults := this.ServerCall.callOpenChests(k, 99)
                    g_Log.AddData("Open Chest ID: " . k, response)
                    if(chestResults.success)
                        v := chestResults.chests_remaining
                    checkAgain := true
                }
                elapsedTime := A_TickCount - startTime
            }
        }
        this.CurrentZonePrevTime := A_TickCount
        g_Log.EndEvent()
    }
}