#Include %A_LineFile%\..\Memory\_MemoryHandler.ahk
#Include %A_LineFile%\..\Memory\_MemoryLogHandler.ahk
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
#Include %A_LineFile%\..\_QTHandler.ahk
#Include %A_LineFile%\..\_Contained.ahk

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
        this.Funcs := _IC_FuncLibrary.CreateOrGetInstance()
        this.RunCount := 0
        return this
    }

    ;may be obsolete with is on world map method
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

        this.ModronTargetArea := this.Funcs.GetModronTargetArea()
        g_Log.AddDataSimple("ModronTargetArea: " . this.ModronTargetArea)

        this.ClickLevel := this.ModronTargetArea + 20
        if (!(this.ClickLevel) OR this.ClickLevel == -1)
            this.ClickLevel := 2000
        g_Log.AddDataSimple("ClickLevel: " . this.ClickLevel)

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
            else if (this.Formation.Formation[i].ChampID == 102)
                this.Formation.Formation[i].MaxLvl := 250
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
        g_Log.AddData("Settings", this.Settings)
        this.QTHandler := new _QTHandler
        tempObj := {}
        loop, 50
        {
            tempObj[A_Index] := {}
            tempObj[A_Index].setBackground := this.QTHandler.List[A_Index].setBackground
            tempObj[A_Index].defaultID := this.QTHandler.List[A_Index].defaultID
        }
        g_Log.AddData("QTHandler.List", tempObj)
        tempObj := ""
        ;adds start up to log file
        g_Log.LogStack()
        ;start new log event
        g_Log.CreateEvent("Gem Farm-Partial")
        g_Log.AddData("gems", this.UserData.Gems)
        this.Reloaded := false


        loop
        {
            if !(this.Client.SafetyCheck())
            {
                this.Client.OpenIC(this.Settings.InstallPath)
                this.Client.LoadAdventure(this.Briv)
                this.Client.MemoryLog.ResetPrevValues()
                this.QTHandler.SetAreas()
                this.CurrentZonePrevTime := A_TickCount
            }
            
            if (this.Settings.SetTimeScale)
                this.Funcs.SetTimeScale(this.Settings.SetTimeScale)

            this.Funcs.SetClickLevel(this.ClickLevel)

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
            if (this.Funcs.IsOnWorldMap())
                this.Funcs.ResetFromWorldMap(this.CurrentObjective, this.ServerCalls, this.Client, this.Briv)
                ;g_Log.AddData("IsOnWorldMap", "true")
            this.Funcs.ToggleAutoProgress(1)
            this.Funcs.BypassBossBag()
            this.Formation.LevelFormation()
            this.Sentry.SetOneKill()
            this.QTHandler.SetBackgrounds()
            _VirtualKeyInputs.Priority("{Right}", "{q}")
            ;let the script catch up
            sleep, 10
        }
    }

    DoZoneOne()
    {
        g_Log.LogStack()
        this.RunCount += 1
        g_Log.CreateEvent("Gem Run " . this.RunCount)
        g_Log.AddData("gems", this.UserData.Gems)
        g_Log.CreateEvent(A_ThisFunc)
        this.Funcs.WaitForFirstGold()
        this.Funcs.ToggleAutoProgress(0)
        this.Briv.LevelUp(170,, "q")
        this.Sentry.LevelUp(225,, "q")
        this.QTHandler.SetAreas()
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
        g_Log.EndEvent()
    }
    
    StackFarmSetup()
    {
        g_Log.CreateEvent(A_ThisFunc)
        _VirtualKeyInputs.Priority("w")
        this.Funcs.WaitForTransition("w")
        this.Funcs.ToggleAutoProgress(0)
        this.Funcs.FallBackFromBossZone("w")
        startTime := A_TickCount
        elapsedTime := 0
        while(this.Funcs.IsCurrentFormation(this.Settings.StackFormation) AND elapsedTime < 5000)
        {
            _VirtualKeyInputs.Priority("w")
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        g_Log.EndEvent()
    }

    RestartStack()
    {
        g_Log.CreateEvent(A_ThisFunc)
        currentZone := this.CurrentZone
        g_Log.AddData("CurrentZone", currentZone)
        this.StackFarmSetup()
        this.UpdateChestData()
        this.Client.CloseIC()
        this.BuyOrOpenChests()
        this.Client.OpenIC(this.Settings.InstallPath)
        ;load adventure should be a ic func class method
        this.Client.LoadAdventure(this.Briv)
        this.Client.MemoryLog.ResetPrevValues()
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
        this.QTHandler.SetAreas()
        this.CurrentZonePrevTime := A_TickCount
        this.Funcs.ToggleAutoProgress(1)
        g_Log.EndEvent()
    }

    ModronReset()
    {
        g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (this.ResetHandler.Resetting.Value == 1 AND elapsedTime < 60000)
        {
            this.Client.MemoryLog.state.Value
            this.Client.MemoryLog.InstanceMode.Value
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
            this.Client.MemoryLog.ResetPrevValues()
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