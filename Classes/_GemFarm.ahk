#Include %A_LineFile%\..\Memory\_MemoryHandler.ahk
#Include %A_LineFile%\..\Memory\_MemoryLogHandler.ahk
#Include %A_LineFile%\..\_VirtualKeyInputs.ahk
_VirtualKeyInputs.Init("ahk_exe IdleDragons.exe")
#Include %A_LineFile%\..\_FormationHandler.ahk
#Include %A_LineFile%\..\_FormationSavesHandler.ahk
#Include %A_LineFile%\..\_HeroHandler.ahk
#Include %A_LineFile%\..\_BrivHandler.ahk
#Include %A_LineFile%\..\_SentryHandler.ahk
#Include %A_LineFile%\..\_HewHandler.ahk
#Include %A_LineFile%\..\_ClientHandler.ahk
#Include %A_LineFile%\..\_IC_ClientHandler.ahk
#Include %A_LineFile%\..\_IC_FuncLibrary.ahk
#Include %A_LineFile%\..\_ServerCalls.ahk
#Include %A_LineFile%\..\_QTHandler.ahk
#Include %A_LineFile%\..\_Contained.ahk
#include %A_LineFile%\..\_classLog.ahk

class _GemFarmSimple
{
    __new(settings)
    {
        If !IsObject(settings)
        {
            ;g_Log.AddData("Failed to load settings", true)
            msgbox, Failed to Load Settings, exiting app.
            ExitApp
        }
        this.Settings := settings
        this.Client := new _IC_ClientHandler(settings.Exe, settings.InstallPath)
        this.Briv := new _BrivHandler(58)
        this.Funcs := _IC_FuncLibrary.CreateOrGetInstance()
        return this
    }

    ;may be obsolete with is on world map method
    CurrentZone[]
    {
        get
        {
            value := this.ActiveCampaignData.CurrentZone.Value
            if (value > this.CurrentZonePrev OR value == 1)
            {
                this.CurrentZonePrev := value
                this.CurrentZonePrevTime := A_TickCount
            }
            return value
        }
    }

    GemFarm()
    {
        ; log start up data
        log := new _classLog
        log.CreateLogFile("GemFarm.Startup")
        log.CreateEvent("Startup")

        while (Not WinExist( "ahk_exe IdleDragons.exe" ))
        {
            MsgBox, 5,, Cannot detect Idle Champions window.
            IfMsgBox, Cancel
                ExitApp
        }

        this.ServerCalls := new _ServerCalls
        log.AddData("ServerCalls", this.ServerCalls)

        System.Refresh()
        this.IdleGameManager := _MemoryHandler.CreateOrGetIdleGameManager()
        this.GameInstance := _MemoryHandler.CreateOrGetGameInstance()
        this.ResetHandler := _MemoryHandler.CreateOrGetResetHandler()
        this.ActiveCampaignData := _MemoryHandler.CreateOrGetActiveCampaignData()
        this.UserData := _MemoryHandler.CreateOrGetUserData()

        currentObjective := this.ActiveCampaignData.CurrentObjective.Value
        if (currentObjective)
            this.Client.CurrentObjective := currentObjective
        log.AddDataSimple("CurrentObjective: " . currentObjective)

        this.ModronTargetArea := this.Funcs.GetModronTargetArea()
        log.AddDataSimple("ModronTargetArea: " . this.ModronTargetArea)

        this.ClickLevel := this.ModronTargetArea + 20
        if (!(this.ClickLevel) OR this.ClickLevel == -1)
            this.ClickLevel := 2000
        log.AddDataSimple("ClickLevel: " . this.ClickLevel)

        ;read in formations
        formationSaves := new _FormationSavesHandler
        while !(formationSaves.RebuildSavesList())
        {
            MsgBox, 5,, No saved formations found.
            IfMsgBox, Cancel
                ExitApp
        }
        formation := formationSaves.GetFormationByFavorite(1)
        ;eliminating reset stack farming
        ;this.Settings.StackFormation := formationSaves.GetFormationByFavorite(2)
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
        this.Formation.SetFormation(formation, 58)
        formation := ""
        tempObj := {}
        size := this.Formation.Formation.Count()
        i := 1
        ;enable sentry or hew handlers and create temp object for logging
        loop %size%
        {
            if (this.Formation.Formation[i].ChampID == 52)
            {
                this.useSentry := true
                this.Sentry := new _SentryHandler(52)
            }
            else if (this.Formation.Formation[i].ChampID == 75)
            {
                this.useHew := true
                this.Hew := new _HewHandler(75)
            }
            tempObj[i] := {}
            for k, v in this.Formation.Formation[i]
            {
                if !IsObject(v)
                    tempObj[i][k] := v
            }
            ++i
        }
        log.AddData("Formation Data", tempObj)
        log.AddData("Settings", this.Settings)
        this.QTHandler := new _QTHandler
        tempObj := {}
        loop, 50
        {
            tempObj[A_Index] := {}
            tempObj[A_Index].setBackground := this.QTHandler.List[A_Index].setBackground
            tempObj[A_Index].defaultID := this.QTHandler.List[A_Index].defaultID
        }
        log.AddData("QTHandler.List", tempObj)
        tempObj := ""
        ;adds start up to log file
        log.LogStack()
        log.EndLog()

        ; a variable to store tick count to periodically check if the client should be closed to buy or open chests.
        this.chestTickCount := A_TickCount

        loop
        {
            if !(this.Client.DoesWinExist())
            {
                this.Client.OpenIC()
                this.QTHandler.SetAreas()
                this.CurrentZonePrevTime := A_TickCount
            }
            
            if (this.Settings.SetTimeScale)
                this.Funcs.SetTimeScale(this.Settings.SetTimeScale)

            this.Funcs.SetClickLevel(this.ClickLevel)
            
            if (this.Briv.HasteStacks < 50)
            {
                this.Briv.HasteStacks := this.Settings.TargetStacks
            }

            if (this.Settings.AvoidBosses AND !Mod(this.CurrentZone, 5))
                _VirtualKeyInputs.Priority("{Right}", "{e}")
            else
                _VirtualKeyInputs.Priority("{Right}", "{q}")

            if (this.ResetHandler.Resetting.Value == 1)
                this.ModronReset()

            ; check to buy or open chests, about every 30 minutes
            if (A_TickCount - this.chestTickCount > 1800000)
            {
                this.UpdateChestData()
                gems := this.Gems - this.Settings.MinGemCount
                if ((this.Settings.BuySilvers AND gems > 5000) OR (this.Settings.BuyGolds AND gems > 50000))
                {
                    this.BuyOrOpenChests()
                }
                else
                {
                    loop, % this.chestCounts.Count()
                    {
                        if (this.chestCounts[A_Index] > 98)
                        {
                            this.BuyOrOpenChests()
                            break
                        }
                    }
                }
                this.chestTickCount := A_TickCount
            }

            if (this.CurrentZone == 1)
                this.DoZoneOne()

            if (this.Client.IsOnWorldMap())
                this.Client.ResetFromWorldMap()

            if (A_TickCount - this.CurrentZonePrevTime > 60000)
            {
                this.Client.Close()
                this.Client.OpenIC()
                this.QTHandler.SetAreas()
                this.CurrentZonePrevTime := A_TickCount
            }

            this.Funcs.ToggleAutoProgress(1)
            this.Funcs.BypassBossBag()
            this.Formation.LevelFormation()
            this.Sentry.SetOneKill()
            if (this.Hew.SetOneKill() == 1)
            {
                _VirtualKeyInputs.Priority("{Right}", "{w}")
                _VirtualKeyInputs.Priority("{Right}", "{q}")
            }
            this.QTHandler.SetBackgrounds()
            ;let the script catch up
            sleep, 10
        }
    }

    DoZoneOne()
    {
        if (this.Settings.SetTimeScale)
            this.Funcs.SetTimeScale(this.Settings.SetTimeScale)
        this.Funcs.WaitForFirstGold()
        this.Funcs.ToggleAutoProgress(0)
        if (this.Settings.SetTimeScale)
            this.Funcs.SetTimeScale(this.Settings.SetTimeScale)
        this.Briv.LevelUp(170,, "q")
        if this.UseHew
            this.Hew.LevelUp(200,, "q")
        if (this.Hew.SetOneKill() == 1)
        {
            _VirtualKeyInputs.Priority("{Right}", "{w}")
            _VirtualKeyInputs.Priority("{Right}", "{q}")
        }
        if this.UseSentry
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
    }

    ModronReset()
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (this.ResetHandler.Resetting.Value == 1 AND this.CurrentZone != 1 AND elapsedTime < 60000)
        {
            sleep, 250
            elapsedTime := A_TickCount - startTime
        }
        ;stuck resetting, restarting client
        if (elapsedTime > 60000)
        {
            ;g_Log.AddData("Stuck Resetting: elapsedTime", elapsedTime)
            this.Client.Close()
            sleep, 250
            this.Client.OpenIC()
        }
        this.CurrentZonePrevTime := A_TickCount
        ;g_Log.EndEvent()
        return
    }

    UpdateChestData()
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        this.Gems := this.UserData.Gems.Value
        ;g_Log.AddData("gems", this.Gems)
        this.chestsCounts := {}
        loop, % this.Settings.OpenChests.Count()
        {
            this.chestsCounts[this.Settings.OpenChests[A_Index]] := this.UserData.ChestCount[this.Settings.OpenChests[A_Index]]
        }
        ;g_Log.AddData("Counts", this.chestsCounts)
        ;g_Log.EndEvent()
        return
    }

    BuyOrOpenChests2()
    {
        local serverCallCount := 1
        
        this.Funcs.ToggleAutoProgress(0)
        this.Client.Close()
        log := new _classLog
        log.CreateLogFile("GemFarm.ServerCalls")
        log.CreateEvent(A_ThisFunc . ": " . serverCallCount++)
        gems := this.Gems - this.Settings.MinGemCount
        responses := {}
        if (this.Settings.BuySilvers AND gems > 5000)
        {
            attempt := 1
            while (gems > 5000)
            {
                response := this.ServerCalls.callBuyChests(1, 100)
                responses["Buy Silvers " . attempt] := response
                if (response.okay AND response.success)
                {
                    gems := response.currency_remaining - this.Settings.MinGemCount
                    this.chestsCounts[1] := response.chest_count
                    log.AddDataSimple("Buy Silver: " . attempt . ", currency_remaining: " . response.currency_remaining . ", chest_count: " . response.chest_count)
                }
                else
                {
                    log.AddDataSimple("Buy Silver: " . attempt . ", failed")
                    break
                }
                attempt++
            }
        }
        if (this.Settings.BuyGolds AND gems > 50000)
        {
            attempt := 1
            while (gems > 50000)
            {
                response := this.ServerCalls.callBuyChests(2, 100)
                responses["Buy Golds " . attempt] := response
                if (response.okay AND response.success)
                {
                    gems := response.currency_remaining - this.Settings.MinGemCount
                    this.chestsCounts[2] := response.chest_count
                    log.AddDataSimple("Buy Gold: " . attempt . ", currency_remaining: " . response.currency_remaining . ", chest_count: " . response.chest_count)
                }
                else
                {
                    log.AddDataSimple("Buy Gold: " . attempt . ", failed")
                    break
                }
                attempt++
            }
        }
        for chestID, chestCount in this.chestsCounts
        {
            attempt := 1
            while (chestCount > 98)
            {
                response := this.ServerCalls.callOpenChests(chestID, 99)
                responses["Open " . chestID . " Attempt " . attempt] := response
                if(response.success)
                {
                    chestCount := response.chests_remaining
                    log.AddDataSimple("Open " . chestID . ": " . attempt . ", chests_remaining: " . response.chests_remaining)
                }
                else
                {
                    log.AddDataSimple("Open " . chestID . ": " . attempt . ", failed")
                    break
                }
                attempt++
            }
        }
        log.AddData("Responses", responses)
        log.LogStack()
        log.EndLog()
        this.CurrentZonePrevTime := A_TickCount
        return
    }

    BuyOrOpenChests()
    {
        local serverCallCount := 0
        
        this.Funcs.ToggleAutoProgress(0)

        ; log server call data
        log := new _classLog
        log.CreateLogFile("GemFarm.ServerCalls")
        serverCallCount += 1
        log.CreateEvent(A_ThisFunc . ": " . serverCallCount)
        this.Client.Close()
        gems := this.Gems - this.Settings.MinGemCount
        log.AddData("Start Gems", gems)
        log.AddData("Start chestCounts", this.chestsCounts)
        checkAgain := true
        buySilversAttempt := 0
        buySilversSuccess := 0
        buyGoldsAttempt := 0
        buyGoldsSuccess := 0
        chestOpenAttempts := {}
        chestsOpened := {}
        responses := 1
        for k, v in this.chestsCounts
        {
            chestOpenAttempts[k] := 0
            chestsOpened[k] := 0
        }
        while (checkAgain)
        {
            checkAgain := false
            if (this.Settings.BuySilvers AND gems > 5000)
            {
                ++buySilversAttempt
                response := this.ServerCalls.callBuyChests(1, 100)
                log.AddData("Resonse Buy Silver " . buySilversAttempt, response)
                if(response.okay AND response.success)
                {
                    ++buySilversSuccess
                    gems := response.currency_remaining - this.Settings.MinGemCount
                    if (gems > 5000)
                        checkAgain := true
                    this.chestsCounts[1] := response.chest_count
                }
                else
                {
                    break
                }
            }
            if (this.Settings.BuyGolds AND gems > 50000)
            {
                ++buyGoldsAttempt
                response := this.ServerCalls.callBuyChests(2, 100)
                log.AddData("Resonse Buy Gold " . buyGoldsAttempt, response)
                if(response.okay AND response.success)
                {
                    ++buyGoldsSuccess
                    gems := response.currency_remaining - this.Settings.MinGemCount
                    if (gems > 50000)
                        checkAgain := true
                    this.chestsCounts[2] := response.chest_count
                }
                else
                {
                    break
                }
            }
            for chestID, chestCount in this.chestsCounts
            {
                if (chestCount > 98)
                {
                    chestOpenAttempts[chestID] := 1 + chestOpenAttempts[chestID]
                    response := this.ServerCalls.callOpenChests(chestID, 99)
                    log.AddData("Resonse Open " . chestID . " Attempt " . responses++, response)
                    if(response.success)
                    {
                        chestsOpened[chestID] += chestCount - response.chests_remaining ;99 + chestsOpened[chestID]
                        if (response.chests_remaining > 98)
                        {
                            chestCount := response.chests_remaining
                            checkAgain := true
                        }
                    }
                    else
                    {
                        break
                    }
                }
            }
        }
        log.AddDataSimple("Buy Silver Attempts: " . buySilversAttempt)
        log.AddDataSimple("Buy Silver Successes: " . buySilversSuccess)
        log.AddDataSimple("Buy Gold Attempts: " . buyGoldsAttempt)
        log.AddDataSimple("Buy Gold Successes: " . buyGoldsSuccess)
        log.AddData("Chest Open Attempts By ID", chestOpenAttempts)
        log.AddData("Chests Opened By ID", chestsOpened)
        log.LogStack()
        log.EndLog()
        this.CurrentZonePrevTime := A_TickCount
        return
    }
}