#Include %A_LineFile%\..\Memory\_MemoryHandler.ahk
#Include %A_LineFile%\..\_VirtualKeyInputs.ahk
_VirtualKeyInputs.Init("ahk_exe IdleDragons.exe")
#Include %A_LineFile%\..\_FormationHandler.ahk
#Include %A_LineFile%\..\_FormationSavesHandler.ahk
#Include %A_LineFile%\..\_HeroHandler.ahk
#Include %A_LineFile%\..\_BrivHandler.ahk
#Include %A_LineFile%\..\_SentryHandler.ahk
#Include %A_LineFile%\..\_ClientHandler.ahk
#Include %A_LineFile%\..\_IC_FuncLibrary.ahk
#Include %A_LineFile%\..\_ServerCalls.ahk

class _GemFarmFinal
{
    __new(settings)
    {
        If !IsObject(settings)
        {
            g_Log.AddData("Failed to load settings", true)
            msgbox, Failed to Load Settings, exiting app.
            ExitApp
        }
        this.Settings := settings
        this.Client := new _ClientHandler
        this.Briv := new _BrivHandler(58)
        this.Funcs := new _IC_FuncLibrary
        this.RunCount := 0
        return this
    }

    CurrentZone[]
    {
        get
        {
            value := this.ActiveCampaignData.CurrentZone.Value
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

        while (Not WinExist( "ahk_exe IdleDragons.exe" ))
        {
            MsgBox, 5,, Cannot detect Idle Champions window.
            IfMsgBox, Cancel
                ExitApp
        }

        this.ServerCalls := new _ServerCalls
        g_Log.AddData("ServerCalls", this.ServerCalls)

        _MemoryHandler.Refresh()
        this.IdleGameManager := _MemoryHandler.InitIdleGameManager()
        this.GameInstance := _MemoryHandler.InitGameInstance()
        this.ResetHandler := _MemoryHandler.InitResetHandler()
        this.ActiveCampaignData := _MemoryHandler.InitActiveCampaignData()
        this.UserData := _MemoryHandler.InitUserData()

        this.CurrentObjective := this.ActiveCampaignData.CurrentObjective.Value
        g_Log.AddDataSimple("CurrentObjective: " . this.CurrentObjective)

        ;read in formations
        formationSaves := new _FormationSavesHandler
        while !(formationSaves.RebuildSavesList())
        {
            MsgBox, 5,, No saved formations found.
            IfMsgBox, Cancel
                ExitApp
        }
        formation := formationSaves.GetFormationByFavorite(1)
        this.Settings.StackFormation := formationSaves.GetFormationByFavorite(2)
        if (formation == -1 OR this.Settings.StackFormation == -1)
        {
            MsgBox, Formation saves list has no entries.
            ExitApp
        }
        else if (formation == -2 OR this.Settings.StackFormation == -2)
        {
            MsgBox, Favorite formation not found in saves list.
            ExitApp
        }
        formationSaves := ""

        ;build fkey input data
        this.Formation := new _FormationHandler
        this.Formation.SetFormation(formation)
        formation := ""
        tempObj := {}
        size := this.Formation.Formation.Count()
        i := 1
        loop %size%
        {
            ;set max levels on sentry(52), widdle(91), to stop at speed unlocks to minimize key inputs
            ; should probably build setting max level for speed champs into the formation handler
            if (this.Formation.Formation[i].ChampID == 52)
            {
                this.useSentry := true
                this.Formation.Formation[i].MaxLvl := 225
                this.Sentry := new _SentryHandler(52)
            } 
            else if (this.Formation.Formation[i].ChampID == 91)
                this.Formation.Formation[i].MaxLvl := 310
            ;build a temp object to log the formation handler formation
            tempObj[i] := {}
            for k, v in this.Formation.Formation[i]
            {
                if !IsObject(v)
                    tempObj[i][k] := v
            }
            ++i
        }
        g_Log.AddData("Formation Data", tempObj)
        tempObj := ""
        g_Log.AddData("Settings", this.Settings)
        ;adds start up to log file
        g_Log.LogStack()
        ;start new log event
        g_Log.CreateEvent("Gem Farm-Partial")
        this.Reloaded := false

        loop
        {
            if !(this.Client.SafetyCheck())
            {
                this.Client.OpenIC(this.Settings.InstallPath)
                this.Client.LoadAdventure(this.Briv)
                this.CurrentZonePrevTime := A_TickCount
            }

            ;if (this.Settings.SetTimeScale AND this.IdlegameManager.TimeScale.GetValue() != this.Settings.SetTimeScale)
            ;    this.IdleGameManager.TimeScale.SetValue(this.settings.SetTimeScale)
            
            if (this.Settings.SetTimeScale)
                this.Funcs.SetTimeScale(this.Settings.SetTimeScale)

            ;to update this to be based on modron reset value
            this.Funcs.SetClickLevel(2000)

            if (this.CurrentZone > this.Settings.StackZone AND this.Briv.Stacks < this.Settings.TargetStacks)
                this.RestartStack()
            
            if (this.Briv.HasteStacks < 50)
            {
                if (this.Briv.Stacks > this.Settings.TargetStacks)
                    this.Briv.ForceConvertStacks()
                else
                    this.Briv.HasteStacks := this.Settings.TargetStacks
            }

            if (this.ResetHandler.Resetting.Value == 1)
                this.ModronReset()

            if (this.CurrentZone == 1)
            {
                this.DoZoneOne()
                this.CurrentZonePrev := 1
            }
            ;this.CheckIfStuck()
            this.Funcs.ToggleAutoProgress(1)
            this.Funcs.BypassBossBag()
            this.Formation.LevelFormation()
            this.Sentry.SetOneKill()
            _VirtualKeyInputs.Priority("{Right}", "{q}")

            ; to add: qt handler

            ;let the script catch up
            sleep, 10
        }
    }

    DoZoneOne()
    {
        g_Log.LogStack()
        this.RunCount += 1
        g_Log.CreateEvent("Gem Run " . this.RunCount)
        this.Funcs.WaitForFirstGold()
        this.Funcs.ToggleAutoProgress(0)
        this.Briv.LevelUp(170,, "q")
        this.Sentry.LevelUp(225,, "q")
        this.Funcs.FinishZone(30000, this.Formation, "q")
        this.Funcs.ToggleAutoProgress(1)
        startTime := A_TickCount
        elapsedTime := 0
        while (this.CurrentZone == 1 AND elapsedTime < 60000)
        {
            _VirtualKeyInputs.Priority("{Right}", "{q}")
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
    }

    RestartStack()
    {
        g_Log.CreateEvent(A_ThisFunc)
        currentZone := this.CurrentZone
        g_Log.AddData("CurrentZone", currentZone)
        this.Briv.StackFarmSetup(this.Settings, this.Funcs)
        this.UpdateChestData()
        this.Client.CloseIC()
        this.BuyOrOpenChests()
        this.Client.OpenIC(this.Settings.InstallPath)
        ;load adventure should be a ic func class method
        this.Client.LoadAdventure(this.Briv)
        ;correct a roll back
        if (currentZone > this.ActiveCampaignData.HighestZone.Value)
        {
            this.Funcs.FallBackFromZone()
            this.Funcs.WaitForTransition()
            i := 0
            this.ActiveCampaignData.HighestZone.Value := currentZone
            while (i < 5 AND currentZone != this.ActiveCampaignData.HighestZone.Value)
            {
                this.ActiveCampaignData.HighestZone.Value := currentZone
                ++i
                sleep, 100
            }
        }
        if (this.Briv.SBStacks < this.Settings.TargetStacks)
        {
            this.Briv.SBStacks := this.Settings.TargetStacks
            i := 0
            while (i < 5 AND this.Briv.SBStacks != this.Settings.TargetStack)
            {
                this.Briv.SBStacks := this.Settings.TargetStacks
                ++i
                sleep, 100
            }
        }
        this.CurrentZonePrevTime := A_TickCount
        this.Funcs.ToggleAutoProgress(1)
        g_Log.EndEvent()
    }

    ;writing 3 (static/qt) to transition direction doesn't work.
    ForceQT()
    {
        g_Log.CreateEvent(A_ThisFunc)
        areas := this.ActiveCampaignData.adventureDef.areas
        areas.SetAddress(true)
        _size := areas.Size()
        ;to do create a list of objects one time at init, isntead of everytime this is called
        ;initial list creation should also pull a background def id, maybe most common?
        i := 0
        loop %_size%
        {
            area := areas.Item[i]
            area.backgroundDef.ID.SetValue(9)
            area.backgroundDef.IsFixed.SetValue(1)
            area.isFixed.SetValue(1)
            ++i
        }
        areas := ""
        g_Log.EndEvent()
        return
    }

    ;need to add better code in case a modron reset happens without being detected. might mean updating other functions.
    CheckifStuck()
    {
        if ((A_TickCount - this.CurrentZonePrevTime) > 60000)
        {
            g_Log.CreateEvent(A_ThisFunc)
            this.Client.CloseIC(A_ThisFunc)
            sleep, 1000
            this.Client.CloseIC( reason )
            sleep, 250
            this.Client.OpenIC(this.Settings.InstallPath)
            this.Client.LoadAdventure(this.Briv)
            this.CurrentZonePrevTime := A_TickCount
            g_Log.EndEvent()
        }
    }

    ModronReset()
    {
        g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (this.ResetHandler.Resetting.Value == 1 AND elapsedTime < 60000)
        {
            sleep, 250
            elapsedTime := A_TickCount - startTime
        }
        ;stuck resetting, restarting client
        if (elapsedTime > 60000)
        {
            g_Log.AddData("Stuck Resetting: elapsedTime", elapsedTime)
            this.Client.CloseIC("Stuck Resetting")
            sleep, 250
            this.Client.OpenIC()
            this.Client.LoadAdventure()
        }
        this.CurrentZonePrevTime := A_TickCount
        g_Log.EndEvent()
        return
    }

    UpdateChestData()
    {
        g_Log.CreateEvent(A_ThisFunc)
        this.Chests := {}
        this.Chests.Gems := this.UserData.Gems.Value
        g_Log.AddData("gems", this.Chests.Gems)
        this.Chests.Counts := {}
        for k, v in this.Settings.OpenChests.Chests
        {
            this.Chests.Counts[v] := this.UserData.ChestCount[v]
        }
        g_Log.AddData("Counts", this.Chests.Counts)
        g_Log.EndEvent()
        return
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
        gems := this.Chests.Gems - this.Settings[ "MinGemCount" ]
        g_Log.AddData("Start Gems", gems)
        restartTime := this.Settings.RestartStackTime
        checkAgain := false
        while (elapsedTime < restartTime)
        {
            if (this.Settings.BuySilvers AND gems > 5000 AND elapsedTime < (restartTime - purchaseTime))
            {
                g_Log.CreateEvent("BuySilvers")
                response := this.ServerCalls.callBuyChests(1, 100)
                if response
                    g_Log.AddData("response", response)
                if(response.okay AND response.success)
                {
                    gems := response.currency_remaining - this.Settings[ "MinGemCount" ]
                    if (gems > 5000)
                        checkAgain := true
                    this.Chests.Counts[1] := response.chest_count
                }
                else
                    checkAgain := false
                g_Log.EndEvent()
            }
            elapsedTime := A_TickCount - startTime
            if (this.Settings.BuyGolds AND gems > 50000 AND elapsedTime < (restartTime - purchaseTime))
            {
                g_Log.CreateEvent("BuyGolds")
                response := this.ServerCalls.callBuyChests(2, 100)
                if response
                    g_Log.AddData("response", response)
                if(response.okay AND response.success)
                {
                    gems := response.currency_remaining - this.Settings[ "MinGemCount" ]
                    if (gems > 50000)
                        checkAgain := true
                    this.Chests.Counts[2] := response.chest_count
                }
                else
                    checkAgain := false
                g_Log.EndEvent()
            }
            elapsedTime := A_TickCount - startTime
            for k, v in this.Chests.Counts
            {
                if (v > 98 AND elapsedTime < (restartTime - openChestTimeEst))
                {
                    g_Log.CreateEvent("OpenChestID" . k)
                    response := this.ServerCalls.callOpenChests(k, 99)
                    if response
                        g_Log.AddData("response", response)
                    if(response.success)
                    {
                        v := response.chests_remaining
                        checkAgain := true
                    }
                    else
                        checkAgain := false
                    g_Log.EndEvent()
                }
                elapsedTime := A_TickCount - startTime
            }
        }
        this.CurrentZonePrevTime := A_TickCount
        g_Log.EndEvent()
    }
}