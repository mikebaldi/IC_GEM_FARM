#Include %A_LineFile%\..\_MemoryObjects.ahk
#Include %A_LineFile%\..\classMemory.ahk
#Include %A_LineFile%\..\Structures\IdleGameManager.ahk
#Include %A_LineFile%\..\Structures\ActiveEffectHandlers.ahk

class _MemoryHandler
{
    Structures := {}
    StructuresDictionary := {}

    Refresh()
    {
        ;create new instance of reader
        this.ClassMemory := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.ModuleBaseAddress := this.ClassMemory.getModuleBaseAddress("mono-2.0-bdwgc.dll")
        ;clear static addresses
        size := this.Structures.Count()
        loop %size%
        {
            this.Structures[A_Index].UseCachedAddress(false)
        }
    }

    ;Need to reconsider having all these inits in here. Getting huge and still lots could be added.
    CreateOrGetIdleGameManager()
    {
        if IsObject(this.IdleGameManager)
            return this.IdleGameManager
        this.IdleGameManager := new IdleGameManager
        this.AddToStructures("IdleGameManager", this.IdleGameManager)
        return this.IdleGameManager
    }

    CreateOrGetGameInstance()
    {
        if IsObject(this.GameInstance)
            return this.GameInstance
        if !(this.StructuresDictionary.HasKey("IdleGameManager"))
            this.CreateOrGetIdleGameManager()
        this.GameInstance := this.IdleGameManager.game.gameInstances.Item[0]
        this.AddToStructures("GameInstance", this.GameInstance)
        return this.GameInstance
    }

    CreateOrGetHeroes()
    {
        if IsObject(this.Heroes)
            return this.Heroes
        if !(this.StructuresDictionary.HasKey("GameInstance"))
            this.CreateOrGetGameInstance()
        this.Heroes := this.GameInstance.HeroHandler.parent.heroes
        this.AddToStructures("Heroes", this.Heroes)
        return this.Heroes
    }

    CreateOrGetUiController()
    {
        if IsObject(this.UiController)
            return this.UiController
        if !IsObject(this.IdleGameManager)
            this.CreateOrGetIdleGameManager()
        this.UiController := this.IdleGameManager.game.screenController.activeScreen.uiController
        this.AddtoStructures("UiController", this.UiController)
        return this.UiController
    }

    CreateOrGetActiveCampaignData()
    {
        if IsObject(this.ActiveCampaignData)
            return this.ActiveCampaignData
        if !(this.StructuresDictionary.HasKey("GameInstance"))
            this.CreateOrGetGameInstance()
        this.ActiveCampaignData := new _MemoryHandler.__ActiveCampaignData(this.GameInstance)
        this.AddToStructures("ActiveCampaignData", this.ActiveCampaignData)
        return this.ActiveCampaignData
    }

    class __ActiveCampaignData extends _MemoryHandler.__MemoryDict
    {
        __new(gameInstance)
        {
            this.ActiveCampaignData := gameInstance.ActiveCampaignData
            this.AdventureDef := this.ActiveCampaignData.adventureDef
            this.Add("ActiveCampaignData.adventureDef", this.AdventureDef)
            this.CurrentObjective := this.ActiveCampaignData.currentObjective.ID
            this.Add("ActiveCampaignData.currentObjective.ID", this.CurrentObjective)
            this.CurrentZone := this.ActiveCampaignData.currentAreaID
            this.Add("ActiveCampaignData.currentAreaID", this.CurrentZone)
            this.Gold := this.ActiveCampaignData.gold
            this.Add("ActiveCampaignData.gold", this.Gold)
            this.HighestZone := this.ActiveCampaignData.highestAvailableAreaID
            this.Add("ActiveCampaignData.highestAvailableAreaID", this.HighestZone)
            this.QuestRemaining := this.ActiveCampaignData.currentArea.QuestRemaining
            this.Add("ActiveCampaignData.currentArea.QuestRemaining", this.QuestRemaining)
            return this
        }

        UseCachedAddress(bool)
        {
            this.ActiveCampaignData.UseCachedAddress(bool)
        }
    }

    CreateOrGetAreaTransitioner()
    {
        if IsObject(this.AreaTransitioner)
            return this.AreaTransitioner
        if !IsObject(this.GameInstance)
            this.CreateOrGetGameInstance()
        this.AreaTransitioner := new _MemoryHandler.__AreaTransitioner(this.GameInstance)
        this.AddToStructures("AreaTransitioner", this.AreaTransitioner)
        return this.AreaTransitioner
    }

    class __AreaTransitioner extends _MemoryHandler.__MemoryDict
    {
        __new(gameInstance)
        {
            this.AreaTransitioner := gameInstance.Controller.areaTransitioner
            this.IsTransitioning := this.AreaTransitioner.IsTransitioning
            this.Add("AreaTransitioner.IsTransitioning", this.IsTransitioning)
            this.TransitionDirection := this.AreaTransitioner.transitionDirection
            this.Add("AreaTransitioner.transitionDirection", this.TransitionDirection)
            return this
        }

        UseCachedAddress(bool)
        {
            this.AreaTransitioner.UseCachedAddress(bool)
        }
    }

    CreateOrGetResetHandler()
    {
        if IsObject(this.ResetHandler)
            return this.ResetHandler
        if !IsObject(this.GameInstance)
            this.CreateOrGetGameInstance()
        this.ResetHandler := new _MemoryHandler.__ResetHandler(this.GameInstance)
        this.AddToStructures("ResetHandler", this.ResetHandler)
        return this.ResetHandler
    }

    class __ResetHandler extends _MemoryHandler.__MemoryDict
    {
        __new(gameInstance)
        {
            this.ResetHandler := gameInstance.ResetHandler
            this.Resetting := this.ResetHandler.resetting
            this.Add("ResetHandler.Resetting", this.Resetting)
            this.Tries := this.ResetHandler.tries
            this.Add("ResetHandler.Tries", this.Tries)
            return this
        }

        UseCachedAddress(bool)
        {
            this.ResetHandler.UseCachedAddress(bool)
        }
    }

    CreateOrGetTopBar()
    {
        if IsObject(this.TopBar)
            return this.TopBar
        if !IsObject(this.UiController)
            this.CreateOrGetUiController()
        this.TopBar := new _MemoryHandler.__TopBar(this.UiController)
        this.AddToStructures("TopBar", this.TopBar)
        return this.TopBar
    }

    class __TopBar extends _MemoryHandler.__MemoryDict
    {
        __new(uiController)
        {
            this.TopBar := uiController.topBar
            this.AutoProgressToggled := this.TopBar.objectiveProgressBox.areaBar.autoProgressButton.toggled
            this.Add("TopBar.AutoProgress.Toggled", this.AutoProgressToggled)
            return this
        }
    }

    ;appears to be unused
    CreateOrGetLoadingScreen()
    {
        if IsObject(this.LoadingScreen)
            return this.LoadingScreen
        if !(this.StructuresDictionary.HasKey("IdleGameManager"))
            this.CreateOrGetIdleGameManager()
        this.LoadingScreen := new _MemoryHandler.__LoadingScreen(this.IdleGameManager)
        this.AddToStructures("LoadingScreen", this.LoadingScreen)
        return this.LoadingScreen
    }

    class __LoadingScreen
    {
        __new(gameManager)
        {
            this.game := gameManager.game
            this.loadingScreen := gameManager.game.loadingScreen
            this.gameUser := gameManager.game.gameUser
            this.gameStarted := this.game.gameStarted
            this.userLoaded := this.gameUser.Loaded
            this.loadingDefinitions := this.loadingScreen.loadingDefinitions
            this.loadingGameUser := this.loadingScreen.loadingGameUser
            this.loadingProgress := this.loadingScreen.loadingProgress
            this.loadingText := this.loadingScreen.loadingText.lastSetText
            this.socialUserAuthenticationDone := this.loadingScreen.socialUserAuthenticationDone
            return this
        }

        UseCachedAddress(bool)
        {
            this.loadingScreen.UseCachedAddress(bool)
        }

        Reset()
        {
            this.game.gameStarted.prevValue := ""
            this.gameUser.Loaded.prevValue := ""
            this.loadingScreen.loadingDefinitions.prevValue := ""
            this.loadingScreen.loadingGameUser.prevValue := ""
            this.loadingScreen.loadingProgress.prevValue := ""
            this.loadingScreen.loadingText.lastSetText.prevValue := ""
            this.loadingScreen.socialUserAuthenticationDone.prevValue := ""
        }
    }

    CreateOrGetUserData()
    {
        if IsObject(this.UserData)
            return this.UserData
        if !IsObject(this.GameInstance)
            this.CreateOrGetGameInstance()
        this.UserData := new _MemoryHandler.__UserData(this.GameInstance)
        this.UserData("UserData", this.UserData)
        return this.UserData
    }

    class __UserData
    {
        __new(gameInstance)
        {
            this.UserData := gameInstance.Controller.userData
            this.chestCounts := this.UserData.ChestHandler.chestCounts            
            this.Gems := this.UserData.redRubies
            this.GemsSpent := this.UserData.redRubiesSpent
            return this
        }

        UseCachedAddress(bool)
        {
            this.UserData.UseCachedAddress(bool)
        }

        ChestCount[id]
        {
            get
            {
                ;g_Log.CreateEvent("ChestCount ID: " . id)
                ;index := this.chestCounts.GetIndexFromKey(id)
                index := this.chestCounts.Keys.GetIndexByValueType(id)
                ;g_Log.AddData("index", index)
                if (index < 0)
                    value := 0
                else
                    value := this.chestCounts.Value[index].Value
                ;g_Log.AddData("count", value)
                ;g_Log.EndEvent()
                return value
            }
        }
    }

    AddToStructures(key, value)
    {
        this.Structures.Push(value)
        this.StructuresDictionary[key] := this.Structures.Count()
    }

    RemoveFromStructures(key)
    {
        if this.StructuresDictionary.HasKey(key)
            this.Structures.RemoveAt(this.StructuresDictionary.Delete(key))
    }

    DestroyInstance(key)
    {
        this[key] := ""
        this.RemoveFromStructures(key)
    }

    class __MemoryDict
    {
        Entries := {}

        Add(key, value)
        {
            if !(this.Entries.HasKey(key))
            {
                this.Entries[key] := value
                return true
            }
            return false
        }

        EnableLog(logObj)
        {
            for k, v in this.Entries
            {
                v.DoLog := true
                v.Log := logObj
                v.Desc := k
            }
            return
        }

        DisableLog()
        {
            for k, v in this.Entries
            {
                v.DoLog := false
                v.Log := ""
                v.Desc := ""
            }
            return
        }
    }
}