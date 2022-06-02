#Include %A_LineFile%\..\IC_MemoryObjects_Class.ahk
#Include %A_LineFile%\..\classMemory.ahk
#Include %A_LineFile%\..\Structures\IdleGameManager.ahk
#Include %A_LineFile%\..\Structures\ActiveEffectHandlers.ahk

class MemoryReader
{
    Structures := {}
    StructuresDictionary := {}

    Refresh()
    {
        ;create new instance of reader
        this.Reader := new _ClassMemory("ahk_exe IdleDragons.exe", "", hProcessCopy)
        this.ModuleBaseAddress := this.Reader.getModuleBaseAddress("mono-2.0-bdwgc.dll")
        ;clear static addresses
        size := this.Structures.Count()
        loop %size%
        {
            this.Structures[A_Index].SetAddress(false)
        }
    }

    ;this shouldn't be here.
    CheckForIC()
    {
        while (Not WinExist( "ahk_exe IdleDragons.exe" ))
        {
            MsgBox, 5, Error, The script cannot detect Idle Champions game client. Restart Idle Champions and press retry or press cancel to exit the script.
            IfMsgBox, Retry
            {
                MemoryReader.Refresh()
                sleep, 500
            }
            else
                ExitApp
        }
    }

    ;Need to reconsider having all these inits in here. Getting huge and still lots could be added.

    InitIdleGameManager()
    {
        if IsObject(this.IdleGameManager)
            return this.IdleGameManager
        this.IdleGameManager := new IdleGameManager
        this.AddToStructures("IdleGameManager", this.IdleGameManager)
        return this.IdleGameManager
    }

    InitGameInstance()
    {
        if IsObject(this.GameInstance)
            return this.GameInstance
        if !(this.StructuresDictionary.HasKey("IdleGameManager"))
            this.InitIdleGameManager()
        this.GameInstance := this.IdleGameManager.game.gameInstances.Item[0]
        this.AddToStructures("GameInstance", this.GameInstance)
        return this.GameInstance
    }

    InitHeroes()
    {
        if IsObject(this.Heroes)
            return this.Heroes
        if !(this.StructuresDictionary.HasKey("GameInstance"))
            this.InitGameInstance()
        this.Heroes := this.GameInstance.HeroHandler.parent.heroes
        this.AddToStructures("Heroes", this.Heroes)
        return this.Heroes
    }

    InitActiveCampaignData()
    {
        if IsObject(this.ActiveCampaignData)
            return this.ActiveCampaignData
        if !(this.StructuresDictionary.HasKey("GameInstance"))
            this.InitGameInstance()
        this.ActiveCampaignData := new MemoryReader.__ActiveCampaignData(this.GameInstance)
        this.AddToStructures("ActiveCampaignData", this.ActiveCampaignData)
        return this.ActiveCampaignData
    }

    class __ActiveCampaignData
    {
        __new(gameInstance)
        {
            this.ActiveCampaignData := gameInstance.ActiveCampaignData
            this.CurrentObjective := this.ActiveCampaignData.currentObjective.ID.Value
            this.ActiveCampaignData.currentObjective.ID.label := "CurrentObjective"
            this.CurrentZone := this.ActiveCampaignData.currentAreaID.Value
            this.ActiveCampaignData.currentAreaID.label := "CurrentZone"
            this.Gold := this.ActiveCampaignData.gold.Value
            this.ActiveCampaignData.gold.label := "Gold"
            return this
        }

        SetAddress(bool)
        {
            this.ActiveCampaignData.SetAddress(bool)
        }

        Reset()
        {
            this.ActiveCampaignData.currentObjective.ID.prevValue := ""
            this.ActiveCampaignData.currentAreaID.prevValue := ""
            this.ActiveCampaignData.gold.prevValue := ""
        }
    }

    InitLoadingScreen()
    {
        if IsObject(this.LoadingScreen)
            return this.LoadingScreen
        if !(this.StructuresDictionary.HasKey("IdleGameManager"))
            this.InitIdleGameManager()
        this.LoadingScreen := new MemoryReader.__LoadingScreen(this.IdleGameManager)
        this.LoadingScreen("LoadingScreen", this.LoadingScreen)
        return this.LoadingScreen
    }

    class __LoadingScreen
    {
        __new(gameManager)
        {
            this.game := gameManager.game
            this.loadingScreen := gameManager.game.loadingScreen
            this.gameUser := gameManager.game.gameUser
            this.gameStarted := this.game.gameStarted.Value
            this.userLoaded := this.gameUser.Loaded.Value
            this.loadingDefinitions := this.loadingScreen.loadingDefinitions.Value
            this.loadingGameUser := this.loadingScreen.loadingGameUser.Value
            this.loadingProgress := this.loadingScreen.loadingProgress.Value
            this.loadingText := this.loadingScreen.loadingText.lastSetText.Value
            this.socialUserAuthenticationDone := this.loadingScreen.socialUserAuthenticationDone.Value
            return this
        }

        SetAddress(bool)
        {
            this.loadingScreen.SetAddress(bool)
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

    InitUserData()
    {
        if IsObject(this.UserData)
            return this.UserData
        if !(this.StructuresDictionary.HasKey("GameInstance"))
            this.InitGameInstance()
        this.UserData := new MemoryReader.__UserData(this.GameInstance)
        this.UserData("UserData", this.UserData)
        return this.UserData
    }

    class __UserData
    {
        __new(gameInstance)
        {
            this.UserData := gameInstance.Controller.userData
            this.chestCounts := this.UserData.ChestHandler.chestCounts            
            this.Gems := this.UserData.redRubies.Value
            this.GemsSpent := this.UserData.redRubiesSpent.Value
            return this
        }

        SetAddress(bool)
        {
            this.UserData.SetAddress(bool)
        }

        Reset()
        {
            this.UserData.redRubies.prevValue := ""
            this.UserData.redRubiesSpent.prevValue := ""
        }

        ChestCount[id]
        {
            get
            {
                index := this.chestCounts.GetIndexFromKey(id)
                if (index == -1)
                    value := 0
                else
                    value := this.chestCounts.Value[index].GetValue()
                string := "Chest" . id . "Count"
                if (value != this[string])
                {
                    g_Log.AddData(string, value)
                    this[string] := value
                }
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
}