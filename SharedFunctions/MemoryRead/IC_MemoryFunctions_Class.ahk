;wrapper with memory reading functions sourced from: https://github.com/Kalamity/classMemory
#include %A_LineFile%\..\IC_GameManager_Class.ahk
#include %A_LineFile%\..\IC_GameSettings_Class.ahk
#include %A_LineFile%\..\IC_EngineSettings_Class.ahk
#include %A_LineFile%\..\IC_CrusadersGameDataSet_Class.ahk
#include %A_LineFile%\..\IC_DialogManager_Class.ahk

;Check if you have installed the class correctly.
if (_ClassMemory.__Class != "_ClassMemory")
{
    msgbox class memory not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten
    ExitApp
}

class IC_MemoryFunctions_Class
{
    
    ;Memory Structures
    GameManager := ""
    GameSettings := ""
    EngineSettings := ""
    CrusadersGameDataSet := ""
    Is64Bit := false

    __new()
    {
        this.GameManager := new IC_GameManager_Class
        this.GameSettings := new IC_GameSettings_Class
        this.EngineSettings := new IC_EngineSettings_Class
        this.CrusadersGameDataSet := new IC_CrusadersGameDataSet_Class
        this.DialogManager := new IC_DialogManager_Class
        this.idleGameManager := MemoryReader.InitGameManager()
        ;this.idleGameSettings := new GameSettings
        ;this.idleEngineSettings := new CoreEngineSettings

        this.gameInstance := MemoryReader.InitGameInstance()
        this.area := this.gameInstance.Controller.area
        this.areaTransitioner := this.gameInstance.Controller.areaTransitioner
        this.formation := this.gameInstance.Controller.formation
        this.userData := this.gameInstance.Controller.userData
        this.heroes := this.gameInstance.HeroHandler.parent.heroes
        this.ActiveCampaignData := this.gameInstance.ActiveCampaignData
        this.formationSavesV2 := this.gameInstance.FormationSaveHandler.formationSavesV2
        this.offlineProgressHandler := this.gameInstance.offlineProgressHandler
        this.ModronHandler := this.userData.ModronHandler
        this.uiController := this.gameInstance.Screen.uiController
        this.ultimatesBar := this.uiController.ultimatesBar
    }

    ;Updates installed after the date of this script may result in the pointer addresses no longer being accurate.
    GetVersion()
    {
        return "v1.10.1, 2022-03-15, IC v0.415.1+"
    }

    ;Open a process with sufficient access to read and write memory addresses (this is required before you can use the other functions)
    ;You only need to do this once. But if the process closes/restarts, then you will need to perform this step again. Refer to the notes section below.
    ;Also, if the target process is running as admin, then the script will also require admin rights!
    ;Automatically selects offsets used depending on if process is 64bit or not (epic or steam)
    OpenProcessReader()
    {
        MemoryReader.Refresh()

        this.GameManager.Refresh()
        if(!this.Is64Bit and this.GameManager.is64Bit())
        {
            this.GameManager := new IC_GameManagerEGS_Class
            this.GameSettings := new IC_GameSettingsEGS_Class
            this.EngineSettings := new IC_EngineSettingsEGS_Class
            this.CrusadersGameDataSet := new IC_CrusadersGameDataSetEGS_Class
            this.DialogManager := new IC_DialogManagerEGS_Class
            this.Is64Bit := true
        }
        else if (this.Is64Bit and !this.GameManager.is64Bit())
        {
            this.GameManager := new IC_GameManager_Class
            this.GameSettings := new IC_GameSettings_Class
            this.EngineSettings := new IC_EngineSettings_Class
            this.CrusadersGameDataSet := new IC_CrusadersGameDataSet_Class
            this.DialogManager := new IC_DialogManager_Class
            this.Is64Bit := false
        }
        else
        {
            this.GameSettings.Refresh()
            this.EngineSettings.Refresh()
            this.CrusadersGameDataSet.Refresh()
            this.DialogManager.Refresh()
        }
    }

    ;=====================
    ;General Purpose Calls
    ;=====================
    GenericGetValue(GameObject)
    {
        if(GameObject.ValueType == "UTF-16")
        {
            var := this.GameManager.Main.readstring(GameObject.baseAddress, bytes := 0, GameObject.ValueType, (GameObject.GetOffsets())*)
        }
        else if (GameObject.ValueType == "List") ; Temp solution?
        {
            var := this.GameManager.Main.read(GameObject.baseAddress, "Int", (GameObject.GetOffsets())*)
        }
        else
        {
            ; test := ArrFnc.GetHexFormattedArrayString(GameObject.GetOffsets()) ; Useful to test what the hex value offsets are to compare to CE
            var := this.GameManager.Main.read(GameObject.baseAddress, GameObject.ValueType, (GameObject.GetOffsets())*)
        }
        return var
    }

    ;=========================================
    ;General Game Values
    ;=========================================
    ; The following Read___ functions are shorthand for GenericGetValue(GameObjectStructure). 
    ; They are not necessary but they do increase readability of code and increase ease of use.

    ReadGameVersion()
    {
        if(this.GenericGetValue(this.GameSettings.GameSettings.PostFix)  != "")
            return this.GenericGetValue(this.GameSettings.GameSettings.Version) . this.GenericGetValue(this.GameSettings.GameSettings.PostFix) 
        else
            return this.GenericGetValue(this.GameSettings.GameSettings.Version)  
        ;if(this.idleGameSettings.PostFix.GetValue()  != "")
        ;    return this.idleGameSettings.MobileClientVersion.GetValue() . this.idleGameSettings.PostFix.GetValue()
        ;else
        ;    return this.idleGameSettings.MobileClientVersion.GetValue()
    }

    ReadGameStarted()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameStarted)
        return this.idleGameManager.game.gameStarted.GetValue()
    }

    ReadMonstersSpawned()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.BasicMonstersSpawned)
        return this.area.basicMonstersSapwnedThisArea.GetValue()
    }

    ReadActiveMonstersCount()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.activeMonstersListSize)
        return this.area.activeMonsters.Size()
    }

    ReadResetting()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.ResetHandler.Resetting)
        return this.gameInstance.ResetHandler.resetting.GetValue()
    }

    ReadTimeScaleMultiplier()
    {
        ;return this.GenericGetValue(this.GameManager.GameManager.TimeScale )
        return this.idleGameManager.TimeScale.GetValue()
    }

    ReadTimeScaleMultiplierByIndex(index := 0)
    {
        offset := Mod(index,2) ? 10
        if (this.Is64Bit)
            timeScaleObject := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries, "Float", [0x20 + 0x10 + (index * 0x18)]) ; 20 start, values at 50,68,3C..etc
        else
            timeScaleObject := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries, "Float", [0x10 + 0xC + (index * 0x10)]) ; 10 start, values at 1C,2C,3C..etc
        return Round(this.GenericGetValue(timeScaleObject), 2)
    }

    ;this read will only return a valid key if it is reading from TimeScaleWhenNotAttackedHandler object
    ReadTimeScaleMultipliersKeyByIndex(index := 0)
    {
        if (this.Is64Bit)
           key := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries,, [0x20 + 0x8 + (index * 0x18), 0x28, 0x10, 0x10, 0x18, 0x10]) ; 20 start -> handler, effectKey, parentEffectKeyHandler, parent, source, ID
        else
            key := New GameObjectStructure(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Entries,, [0x10 + 0x8 + (index * 0x10), 0x14, 0x8, 0x8, 0xC, 0x8]) ; 10 start, values at 18,28,38..etc to get to handler, effectKey, parentEffectKeyHandler, parent, source, ID
        return this.GenericGetValue(key)
    }

    ReadTimeScaleMultipliersCount()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.TimeScales.Multipliers.Count)
    }

    ReadUncappedTimeScaleMultiplier()
    {
        multiplierTotal := 1
        i := 0
        loop, % this.ReadTimeScaleMultipliersCount()
        {
            value := this.ReadTimeScaleMultiplierByIndex(i)
            multiplierTotal *= Max(1.0, value)
            i++
        }
        return multiplierTotal
    }

    ReadTransitioning()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.AreaTransitioner.IsTransitioning)
        return this.areaTransitioner.IsTransitioning.GetValue()
    }

    ReadTransitionDelay()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.AreaTransitioner.ScreenWipeEffect.DelayTimer.T)
    }

    ; 0 = right, 1 = left, 2 = static (instant)
    ReadTransitionDirection()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.AreaTransitioner.TransitionDirection)
        return this.areaTransitioner.transitionDirection.GetValue()
    }

    ; 0 = OnFromLeft, 1 = OnFromRight, 2 = OffToLeft, 3 = OffToRight
    ReadFormationTransitionDir()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.transitionDir)
        return this.formation.transitionDir.GetValue()
    }

    ReadSecondsSinceAreaStart()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.SecondsSinceStarted)
        return this.area.secondsSinceStarted.GetValue()
    }

    ReadAreaActive()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Area.Active)
        return this.area.Active.GetValue()
    }

    ReadUserIsInited()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.Inited)
        return this.userData.inited.GetValue()
    }

    ;=================
    ;Screen Resolution
    ;=================

    ReadScreenWidth()
    {
        ;return this.GenericGetValue(this.GameManager.Game.ActiveScreen.Width)
        return this.idleGameManager.game.screenController.activeScreen.currentScreenWidth.GetValue()
    }

    ReadScreenHeight()
    {
        ;return this.GenericGetValue(this.GameManager.Game.ActiveScreen.Height)
        return this.idleGameManager.game.screenController.activeScreen.currentScreenHeight.GetValue()
    }

    ;=========================================================
    ;herohandler - champion related information accessed by ID
    ;=========================================================

    ; -1 for 1->0 indexing conversion
    ReadChampUpgradeCountByID(ChampID:= 0)
    {
        
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.UpgradeCount.GetGameObjectFromListValues(ChampID - 1))
    }

    ReadChampHealthByID(ChampID := 0 )
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Health.GetGameObjectFromListValues(ChampID - 1))
        return this.heroes.Item[ChampID - 1].health.GetValue()
    }

    ReadChampSlotByID(ChampID := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Slot.GetGameObjectFromListValues(ChampID - 1))
        return this.heroes.Item[ChampID - 1].slotID.GetValue()
    }

    ReadChampBenchedByID(ChampID := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Benched.GetGameObjectFromListValues(ChampID - 1))
        return this.heroes.Item[ChampID - 1].Benched.GetValue()
    }

    ReadChampLvlByID(ChampID:= 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.Level.GetGameObjectFromListValues(ChampID - 1))
        return this.heroes.Item[ChampID - 1].Level.GetValue()
    }

    ReadChampSeatByID(ChampID := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def.Seat.GetGameObjectFromListValues(ChampID - 1))
        return this.heroes.Item[ChampID - 1].def.SeatID.GetValue()
    }

    ReadChampNameByID(ChampID := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.HeroHandler.HeroList.def.Name.GetGameObjectFromListValues(ChampID - 1))
        return this.heroes.Item[ChampID - 1].def.name.GetValue()
    }

    ;=============================
    ;ServerCall Related - userid, hash, etc.
    ;=============================

    ReadUserID()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings.UserID)
        ;return this.idleGameSettings.UserID.GetValue()
    }

    ReadUserHash()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings.Hash)
        ;return this.idleGameSettings.Hash.GetValue()
    }

    ReadInstanceID()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings._Instance.InstanceID)
        ;return this.idleGameSettings.Instance.instanceID.GetValue()
    }

    ReadWebRoot()
    {
        return this.GenericGetValue(this.Enginesettings.EngineSettings.WebRoot) 
        ;return this.idleEngineSettings.WebRoot.GetValue()
    }

    ReadPlatform()
    {
        return this.GenericGetValue(this.GameSettings.GameSettings.Platform)
        ;return this.idleGameSettings.Platform.GetValue()
    }

    ReadGameLocation()
    {
        return this.GameManager.Main.GetModuleFileNameEx()
    }

    GetWebRequestLogLocation()
    {
        gameLoc := this.ReadGameLocation()
        splitStringArray := StrSplit(gameLoc, "\")
        newString := ""
        i := 1
        size := splitStringArray.Count() - 1
        loop, %size%
        {
            newString := newString . splitStringArray[i] . "\"
            i++
        }
        newString := newString . "IdleDragons_Data\StreamingAssets\downloaded_files\webRequestLog.txt"
        return newString
    }    
    
    ;==================================================
    ;userData - gems, red rubies, SB/Haste stacks, etc.
    ;==================================================

    ReadGems()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.Gems)
        return this.userData.redRubies.GetValue()
    }

    ReadGemsSpent()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.GemsSpent)
        return this.userData.redRubiesSpent.GetValue()
    }

    ReadRedGems() ; BlackViper Red Gems
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.StatHandler.BlackViperTotalGems)
        return this.userData.StatHandler.BlackViperTotalGems.GetValue()
    }

    ReadSBStacks()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.StatHandler.BrivSteelbonesStacks)
        return this.userData.StatHandler.BrivSteelbonesStacks.GetValue()
    }

    ReadHasteStacks()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.StatHandler.BrivSprintStacks)
        return this.userData.StatHandler.BrivSprintStacks.GetValue()
    }

    ;======================================================================================
    ;ActiveCampaignData related fields - current zone, highest zone, monsters spawned, etc.
    ;======================================================================================

    ReadCurrentObjID()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.CurrentObjective.ID)
        return this.ActiveCampaignData.currentObjective.ID.GetValue()
    }

    ReadQuestRemaining()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.CurrentArea.QuestRemaining)
        return this.ActiveCampaignData.currentArea.QuestRemaining.GetValue()
    }

    ReadCurrentZone()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.CurrentAreaID)
        return this.ActiveCampaignData.currentAreaID.GetValue()
    }

    ReadHighestZone()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.HighestAvailableAreaID)
        return this.ActiveCampaignData.highestAvailableAreaID.GetValue()
    }

    ;======================================================================================
    ;Gold Related functions.
    ;======================================================================================
    
    ;reads the first 8 bytes of the quad value of gold
    ReadGoldFirst8Bytes()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
    }

    ;reads the last 8 bytes of the quad value of gold
    ReadGoldSecond8Bytes()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
    }

    ;Reads memory for gold and converts it to double then to a string. < e308 only.
    ReadGoldString()
    {
        ; Gold value must be < max double to work
        FirstEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
        SecondEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
        stringVar := this.ConvQuadToString(FirstEight, SecondEight)
        return stringVar 
    }

    ReadGoldString2()
    {
        FirstEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
        SecondEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
        stringVar := this.ConvQuadToString2(FirstEight, SecondEight)
        return stringVar 
    }

    ;Reads memory for gold and converts it to a string.
    ReadGoldString3()
    {
        FirstEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.Gold)
        SecondEight := this.GenericGetValue(this.GameManager.Game.GameInstance.ActiveCampaignData.GoldExp)
        stringVar := this.ConvQuadToString3(FirstEight, SecondEight)
        return stringVar 
    }

    ;===================================
    ;Formation save related memory reads
    ;===================================
    ;read the number of saved formations for the active campaign
    ReadFormationSavesSize()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesListSize)
        return this.formationSavesV2.Size()
    }

    ;reads if a formation save is a favorite
    ;0 = not a favorite, 1 = favorite slot 1 (q), 2 = 2 (w), 3 = 3 (e)
    ReadFormationFavoriteIDBySlot(slot := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Favorite.GetGameObjectFromListValues(slot))
        return this.formationSavesV2.Item[slot].Favorite.GetValue()
    }

    ReadFormationNameBySlot(slot := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.FormationName.GetGameObjectFromListValues(slot))
        return this.formationSavesV2.Item[slot].Name.GetValue()
    }

    ; Reads the SaveID for the FormationSaves index passed in.
    ReadFormationSaveIDBySlot(slot := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.SaveID.GetGameObjectFromListValues(slot))
        return this.formationSavesV2.Item[slot].SaveID.GetValue()
    }

    ; Reads the FormationCampaignID for the FormationSaves index passed in.
    ReadFormationCampaignID()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationCampaignID)
        return this.gameInstance.FormationSaveHandler.formationCampaignID.GetValue()
    }

    ;=========================================================================
    ;Formation related memory reads (not save, but the in adventure formation)
    ;=========================================================================
    
    ReadNumAttackingMonstersReached()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.numAttackingMonstersReached)
        return this.formation.numAttackingMonstersReached.GetValue()
    }

    ReadNumRangedAttackingMonsters()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.NumRangedAttackingMonsters)
        return this.formation.numRangedAttackingMonsters.GetValue()
    }

    ReadChampIDBySlot(slot := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationList.ChampID.GetGameObjectFromListValues(slot))
        return this.formation.slots.Item[slot].hero.def.ID.GetValue()
    }

    ReadHeroAliveBySlot(slot := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationList.HeroAlive.GetGameObjectFromListValues(slot))
        return this.formation.slots.Item[slot].heroAlive.GetValue()
    }

    ; should read 1 if briv jump animation override is loaded to list, 0 otherwise
    ReadTransitionOverrideSize()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.TransitionOverrides.ActionListSize)
        return this.formation.transitionOverrides.Value[0].Size()
    }

    ;==============================
    ;offlineprogress and modronsave
    ;==============================

    ReadMonstersSpawnedThisAreaOL()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.MonstersSpawnedThisArea)
        return this.offlineProgressHandler.monstersSpawnedThisArea.GetValue()
    }

    ReadCoreXP()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.ExpTotal)
        return this.offlineProgressHandler.modronSave.ExpTotal.GetValue()
    }

    ReadCoreTargetArea()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.ModronSave.TargetArea)
        return this.offlineProgressHandler.modronSave.targetArea.GetValue()
    }

    ReadActiveGameInstance()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ActiveUserGameInstance)
        return this.userData.ActiveUserGameInstance.GetValue()
    }

    GetCoreTargetAreaByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        ;saveSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize)
        saveSize := this.ModronHandler.modronSaves.Size()
        if (saveSize > 10) ;should never be 10 cores, but maybe. in case this read is bad and it looks at a pointer and ends up with a value in the billions
            saveSize := 10
        ;cycle through saved formations to find save slot of Favorite
        i := 0
        ;probably should set list base address before iterating through but with only 3 loops max going to hold off and revisit later
        loop, %saveSize%
        {
            ;if (this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID.GetGameObjectFromListValues(i)) == InstanceID)
            if (this.ModronHandler.modronSaves.Item[i].InstanceID.GetValue() == InstanceID)
            {
                ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.TargetArea.GetGameObjectFromListValues(i))
                return this.ModronHandler.modronSaves.Item[i].targetArea.GetValue()
            }
            ++i
        }
        return -1
    }

    GetCoreXPByInstance(InstanceID := 1)
    {
        ;reads memory for the number of cores        
        ;saveSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize)
        saveSize := this.ModronHandler.modronSaves.Size()
        if (saveSize > 10) ;should never be 10 cores, but maybe. in case this read is bad and it looks at a pointer and ends up with a value in the billions
            saveSize := 10
        ;cycle through saved formations to find save slot of Favorite
        i := 0
        ;probably should set list base address before iterating through but with only 3 loops max going to hold off and revisit later
        loop, %saveSize%
        {
            ;if (this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID.GetGameObjectFromListValues(i)) == InstanceID)
            if (this.ModronHandler.modronSaves.Item[i].InstanceID.GetValue() == InstanceID)
            {
                ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.ExpTotal.GetGameObjectFromListValues(i))
                return this.ModronHandler.modronSaves.Item[i].ExpTotal.GetValue()
            }
            ++i
        }
        return -1
    }  

    ;=================
    ; New
    ;=================
    ReadOfflineTime()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.InGameNumSecondsToProcess)
        return this.offlineProgressHandler.inGameNumSecondsToProcess.GetValue()
    }

    ReadOfflineDone()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.OfflineProgressHandler.FinishedOfflineProgress)
        return this.offlineProgressHandler.finishedOfflineProgressType.GetValue()
    }

    ReadResetsCount()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.ResetsSinceLastManual)
        return this.gameInstance.ResetsSinceLastManual.GetValue()
    }

    ;=================
    ;UI
    ;=================

    ReadAutoProgressToggled()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButtonToggled)
        return this.uiController.topBar.objectiveProgressBox.areaBar.autoProgressButton.toggled.GetValue()
    }

    ;reads the champ id associated with an ultimate button
    ReadUltimateButtonChampIDByItem(item := 0)
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsList.hero.def.ID.GetGameObjectFromListValues(item))
        return this.ultimatesBar.ultimateItems.Item[item].hero.def.ID.GetValue()
    }

    ReadUltimateButtonListSize()
    {
        ;return this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.ultimatesBar.ultimateItemsListSize)
        return this.ultimatesBar.ultimateItems.Size()
    }

    ;======================
    ; Retrieving Formations
    ;======================
    /*
        read the champions saved in a given formation save slot. returns an array of champ ID with -1 representing an empty formation slot
        when parameter ignoreEmptySlots is set to 1 or greater, empty slots (memory read value == -1) will not be added to the array
    */
    GetFormationSaveBySlot(slot := 0, ignoreEmptySlots := 0 )
    {
        Formation := Array()
        ;_size := this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.Size.GetGameObjectFromListValues(slot))
        _size := this.formationSavesV2.Item[slot].Formation.Size()
        if (_size > 10)
            _size := 10 ;in case there is a bad read, formations have max size of 10 currently
        index := 0
        loop, %_size%
        {
            ;heroLoc := this.GameManager.Is64Bit() ? ((A_Index - 1) / 2) : (A_Index - 1) ; -1 for 1->0 indexing conversion
            ;champID := this.GenericGetValue(this.GameManager.Game.GameInstance.FormationSaveHandler.FormationSavesList.Formation.FormationList.GetGameObjectFromListValues(slot, heroLoc))
            champID := this.formationSavesV2.Item[slot].Formation.Item[index].GetValue()
            if (!ignoreEmptySlots or champID != -1)
            {
                Formation.Push( champID )
            }
            ++index
        }
        return Formation
    }

    /*
        A function that looks for a saved formation matching a favorite. Returns -1 on failure.
        Optional Paramater Favorite, 0 = not a favorite, 1 = save slot 1 (Q), 2 = save slot 2 (W), 3 = save slot 3 (E)

        Requires #include classMemory.ahk and OpenProcessReader() is called each time client is restarted
    */
    GetSavedFormationSlotByFavorite(favorite := 1)
    {
        ;reads memory for the number of saved formations
        formationSavesSize := this.ReadFormationSavesSize() ;+ 1
        ;cycle through saved formations to find save slot of Favorite
        formationSaveSlot := -1
        i := 0
        loop, %formationSavesSize%
        {
            if (this.ReadFormationFavoriteIDBySlot(i) == favorite)
            {
                formationSaveSlot := i
                Break
            }
            ++i
        }
        return formationSaveSlot ; formationSaveSlot is ID which starts at 1, list index starts at 0, so we subtract 1
    }

    ;Returns the formation stored at the favorite value passed in.
    GetFormationByFavorite( favorite := 0 )
    {
        slot := this.GetSavedFormationSlotByFavorite(favorite)
        formation := this.GetFormationSaveBySlot(slot)
        return Formation
    }

    ; Returns an array containing the current formation. Note: Slots with no hero are converted from 0 to -1 to match other formation saves.
    GetCurrentFormation()
    {
        formation := Array()
        ;size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationListSize)
        size := this.formation.slots.Size()
        if(!size)
            return ""
        else if (size > 10)
            size := 10 ;in case there is a bad read, formations have max size of 10 currently
        loop, %size%
        {
            ;heroID := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.Formation.FormationList.ChampID.GetGameObjectFromListValues(A_index - 1))
            heroID := this.formation.slots.Item[A_Index - 1].hero.def.ID.GetValue()
            heroID := heroID > 0 ? heroID : -1
            formation.Push(heroID)
        }
        return formation
    }

    ;this function will likely be abandoned in favor of something that doesn't rely on ui
    ReadBoughtLastUpgrade( seat = 1)
    {
        ; The nextUpgrade pointer could be null if no upgrades are found.
        if(this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade.GetGameObjectFromListValues(seat - 1)))
        {
            val := this.GenericGetValue(this.GameManager.Game.GameInstance.Screen.uiController.bottomBar.heroPanel.activeBoxesList.nextupgrade.IsPurchased.GetGameObjectFromListValues(seat - 1))
            return val
        }
        else
        {
            return True
        }
    }

    ; Returns the formation array of the formation used in the currently active modron.
    GetActiveModronFormation()
    {
        formation := ""
        ; Find the Campaign ID (e.g. 1 is Sword Cost, 2 is Tomb, 1400001 is Sword Coast with Zariel Patron, etc. )
        formationCampaignID := this.ReadFormationCampaignID()
        ; Find the SaveID associated to the Campaign ID 
        formationSaveID := this.GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
        ; Find the list index (slot) of the formation with the correct SaveID
        ;formationSaveID := 132
        formationSavesSize := this.ReadFormationSavesSize()
        formationSaveSlot := -1
        loop, %formationSavesSize%
        {
            if (this.ReadFormationSaveIDBySlot(A_Index - 1) == formationSaveID)
            {
                formationSaveSlot := A_Index - 1
                Break
            }
        }
        ; Get the formation using the list index (slot)
        if(formationSaveSlot >= 0)
            formation := this.GetFormationSaveBySlot(formationSaveSlot)
        return formation
    }

    ; Uses FormationCampaignID to search the modron for the SaveID of the formation the active modron is using.
    GetModronFormationsSaveIDByFormationCampaignID(formationCampaignID)
    {
        ; note: current best interpretation of a <int,int> dictionary.
        formationSaveSlot := ""
        ; Find which modron core is being used
        modronSavesSlot := this.GetCurrentModronSaveSlot()
        ; Find SaveID for given formationCampaignID
        ;modronFormationsSavesSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionarySize.GetGameObjectFromListValues(modronSavesSlot))
        count := this.ModronHandler.modronSaves.Item[modronSavesSlot].FormationSaves.count.GetValue()
        if (count > 50)
            count := 50
        loop, %count% ;%modronFormationsSavesSize%
        {
            ; 64 bit starts values at offset 0x20, 32 bit at 0x10
            ;testIndex := this.Is64Bit ? (0x20 + (A_index - 1) * 0x10) : (0x10 + (A_Index - 1) * 0x10)
            ;testValueObject := new GameObjectStructure(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionary.GetGameObjectFromListValues(modronSavesSlot),,[testIndex])
            ;testValueObjectOffsets := ArrFnc.GetHexFormattedArrayString(testValueObject.GetOffsets())
            ;testValue := this.GenericGetValue(testValueObject)
            testValue := this.ModronHandler.modronSaves.Item[modronSavesSlot].FormationSaves.Key[A_Index - 1].GetValue()
            if (testValue == formationCampaignID)
            {
                ;testIndex := testIndex + 0xC ; same for 64/32 bit
                ;testValueObject := new GameObjectStructure(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.FormationSavesDictionary.GetGameObjectFromListValues(modronSavesSlot),,[testIndex])
                ;formationSaveSlot := this.GenericGetValue(testValueObject)
                formationSaveSlot := this.ModronHandler.modronSaves.Item[modronSavesSlot].FormationSaves.Value[A_Index - 1].GetValue()
                break
            }
        }
        return formationSaveSlot
    }

    ; Finds the index of the current modron in ModronHandlers
    GetCurrentModronSaveSlot()
    {
        ;modronSavesSlot := ""
        activeGameInstance := this.ReadActiveGameInstance()
        ;moronSavesSize := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesListSize)
        _size := this.ModronHandler.modronSaves.Size()
        loop, %_size% ;%moronSavesSize%
        {
            ;if (this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ModronHandler.ModronSavesList.InstanceID.GetGameObjectFromListValues(A_Index - 1)) == activeGameInstance)
            if (this.ModronHandler.modronSaves.Item[i].InstanceID.GetValue() == InstanceID)
            {
                ;modronSavesSlot := A_Index - 1
                return (A_Index - 1)
            }
        }
    }

    ;======================
    ; Inventory...
    ;======================
    ;to be updated to memv2 later
    GetInventoryBuffAmountByID(buffID)
    {
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize)
        if(!size)
            return ""
        index := this.BinarySearchList(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID, 1, size, buffID)
        if (index >= 0)
            return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.InventoryAmount.GetGameObjectFromListValues(index - 1))
        else
            return ""
    }

    GetInventoryBuffNameByID(buffID)
    {
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize)
        if(!size)
            return ""
        index := this.BinarySearchList(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.ID, 1, size, buffID)
        if (index >= 0)
            return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsList.NameSingular.GetGameObjectFromListValues(index - 1))
        else
            return ""
    }

    ReadInventoryItemsCount()
    {
        return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.BuffHandler.InventoryBuffsListSize)
    }

    /* Chests are stored in a dictionary under the "entries". It functions like a 32-Bit list but the ID is every 4th value. Item[0] = ID, item[1] = MAX, Item[2] = ID, Item[3] = count. They are each 4 bytes, not a pointer.
    */
    GetChestCountByID(chestID)
    {
        size := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionarySize)    
        if(!size)
            return "" 
        loop, %size%
        {
            ; Not using 64 bit list, but need +0x10 offset for where list starts
            testIndex := this.Is64Bit ? (A_index - 1) * 4 + 4 : testIndex := (A_Index - 1) * 4
            testValue := this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.GetGameObjectFromListValues(testIndex))
            ; Addresses are 64 bit but the dictionary entry offsets are 4 bytes instead of 8.
            testIndex := this.Is64Bit ? (A_index - 1) * 4 + 7 : (A_index - 1) * 4 + 3
            if(testValue == chestID)
                return this.GenericGetValue(this.GameManager.Game.GameInstance.Controller.UserData.ChestHandler.ChestCountsDictionary.GetGameObjectFromListValues(testIndex))
        }
        return "" 
    }

    GetChestNameByID(chestID)
    {
        size := this.GenericGetValue(this.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesListSize)    
        if(!size)
            return "" 
        index := this.BinarySearchList(this.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesList.ID, 1, size, chestID)
        if (index >= 0)
            return this.GenericGetValue(this.CrusadersGameDataSet.CrusadersGameDataSet.ChestDefinesList.NamePlural.GetGameObjectFromListValues(index - 1))
        else
            return ""
    }

    ;===================
    ;Currency Conversion
    ;===================

    ReadConversionCurrencyBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.DialogManager.DialogsList.CurrentCurrency.ID.GetGameObjectFromListValues(slot))
    }

    ReadDialogNameBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.DialogManager.DialogsList.ObjectName.GetGameObjectFromListValues(slot))
    }

    ReadForceConvertFavorBySlot(slot := 0)
    {
        return this.GenericGetValue(this.DialogManager.DialogManager.DialogsList.ForceConvertFavor.GetGameObjectFromListValues(slot))
    }

    GetBlessingsDialogSlot()
    {
        size := this.GenericGetValue(this.DialogManager.DialogManager.DialogsListSize)
        loop, %size%
        {
            name := this.GenericGetValue(this.DialogManager.DialogManager.DialogsList.ObjectName.GetGameObjectFromListValues(A_Index - 1))
            if (name == "BlessingsStoreDialog")
                return (A_Index - 1)
        }
        return ""
    }

    GetBlessingsCurrency()
    {
        return this.ReadConversionCurrencyBySlot(this.GetBlessingsDialogSlot())
    }

    GetForceConvertFavor()
    {
        ; slot := this.GetBlessingsDialogSlot()
        ; value := this.ReadForceConvertFavorBySlot(slot)
        return this.ReadForceConvertFavorBySlot(this.GetBlessingsDialogSlot())
    }

    ReadPatronID()
    {
        if (this.GenericGetValue(this.GameManager.Game.GameInstance.PatronHandler.ActivePatron))
            return  this.GenericGetValue(this.GameManager.Game.GameInstance.PatronHandler.ActivePatron.ID)
        return 0
    }

    ;==============
    ;Helper Methods
    ;==============

    ; maxes at max double
    ConvQuadToString(FirstEight, SecondEight)
    {
        var := (FirstEight + (2.0**63)) * (2.0**SecondEight)
        exponent := log(var)
        stringVar := Round(var, 0) . ""
        if(var >= 10000)
        {
            stringVar := Round((SubStr(var, 1 , 3) / 100), 2)  . "e" . Floor(exponent)  
        }
        return stringVar 
    }

    ; testing - not accurate at times?
    ConvQuadToString2( FirstEight, SecondEight )
    {
        a := log( 2.0 ** 63 )
        b := log( FirstEight )
        ;can't directly add a and b though probably could add FirstEight and max int64, but would lose precision maybe, but probably doesn't matter
        c := Floor( b ) - Floor( a )
        aRemainder := a - Floor( a )
        d := 10 ** aRemainder
        bRemainder := b - Floor( b )
        e := 10 ** bRemainder
        f := e / ( 10 ** c )
        f += d
        f := log( f )

        decimated := ( log( 2 ) * SecondEight / log( 10 ) ) + Floor( a ) + f

        significand := round( 10 ** ( decimated - floor( decimated ) ), 2 )
        exponent := floor( decimated )
        if(exponent < 4)
            return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 0) . ""
        return significand . "e" . exponent
    }

    ;and it turns out I went through a lot of extra steps
    ;testing - Converts 16 bit Quad value into a string representation.
    ConvQuadToString3( FirstEight, SecondEight )
    {
        f := log( FirstEight + ( 2.0 ** 63 ) )
        decimated := ( log( 2 ) * SecondEight / log( 10 ) ) + f

        significand := round( 10 ** ( decimated - floor( decimated ) ), 2 )
        exponent := floor( decimated )
        if(exponent < 4)
            return Round((FirstEight + (2.0**63)) * (2.0**SecondEight), 0) . ""
        return significand . "e" . exponent
    }

    BinarySearchList(gameObject, leftIndex, rightIndex, searchValue)
    {
        if(rightIndex < leftIndex)
        {
            return -1
        }
        else
        {
            middle := Ceil(leftIndex + ((rightIndex-leftIndex) / 2))
            IDValue := this.GenericGetValue(gameObject.GetGameObjectFromListValues(middle - 1))
            ; failed memory read
            if(IDValue == "")
                return -1
            ; if value found, return index
            else if (IDValue == searchValue)
                return middle
            ; else if value larger that middle value, check larger half
            else if (IDValue > searchValue)
                return this.BinarySearchList(gameObject, leftIndex, middle-1, searchValue)
            ; else if value smaller than middle value, check smaller half
            else
                return this.BinarySearchList(gameObject, middle+1, rightIndex, searchValue)
        }
    }

    #include *i IC_MemoryFunctions_Extended.ahk
}