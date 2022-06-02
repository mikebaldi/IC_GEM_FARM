class IC_SharedFunctions_Class_MV2 extends IC_SharedFunctions_Class
{
    __new()
    {
        this.Memory := New IC_MemoryFunctions_Class
        this.GameManager := MemoryReader.InitGameManager()
        this.GameInstance := MemoryReader.InitGameInstance()
        this.loader := MemoryReader.InitLoadingScreen()
        this.PID := 0
    }

    ;i want to re evaluate the autoprogress togled prop
    ; IsToggled be 0 for off or 1 for on. ForceToggle always hits G. ForceState will press G until AutoProgress is read as on (<5s).
    ToggleAutoProgress( isToggled := 1, forceToggle := false, forceState := false )
    {
        startTime := A_TickCount
        if ( forceToggle )
            VirtualKeyInputs.Priority("g")
        if ( this.AutoProgressToggled != isToggled )
            VirtualKeyInputs.Priority("g")
        while ( forceState AND this.AutoProgressToggled != isToggled AND (A_TickCount - startTime) < 5001 )
            VirtualKeyInputs.Priority("g")
    }

    ; waitTime: max time in ms will wait to finish zone, lvlFormation: bool to call method, inputs: variadic param of inputs
    FinishZone(waitTime, lvlFormation, inputs*)
    {
        startTime := A_TickCount
        elapsedTime := 0
        isTransitioning := MemoryReader.GameInstance.Controller.areaTransitioner.IsTransitioning.GetValue()
        while (elapsedTime < waitTime AND !isTransitioning)
        {
            if lvlFormation
                lvlFormation := g_Level.LevelFormationSmart(inputs*)
            else if (inputs.Count())
                VirtualKeyInputs.Priority(inputs*)
            else
                sleep, 100
            elapsedTime := A_TickCount-startTime
            isTransitioning := MemoryReader.GameInstance.Controller.areaTransitioner.IsTransitioning.GetValue()
        }
        return
    }

    ; checks if idle champions is open, but limits the check to once every 5 seconds unless forceCheck param set to true
    SafetyCheck(forceCheck := false)
    {
        static lastRan := 0
        if (forceCheck OR (lastRan + 5000 < A_TickCount))
        {
            if (Not WinExist( "ahk_exe IdleDragons.exe" ))
                return false
        }
        return true
    }

    OpenIC(installPath)
    {
        g_Log.CreateEvent(A_ThisFunc)
        g_Log.AddData("installPath", installPath)
        programLoc := installPath . "IdleDragons.exe"
        g_Log.AddData("programLoc", programLoc)
        this.PID := 0
        this.HWD := 0
        attempts := 0
        while (!this.PID)
        {
            Run, %programLoc%, %installPath%,, OutputVarPID
            this.PID := OutputVarPID
            WinWait ahk_pid %OutputVarPID%,,32000
            if ErrorLevel
            {
                g_Log.AddData("attempts", ++attempts)
                Process, Close, %OutputVarPID%
                this.PID := 0
            }
        }
        this.HWD := WinExist( "ahk_exe IdleDragons.exe" )
        MemoryReader.Refresh()
        this.LoadGame()
        g_Log.EndEvent()
        return true
    }

    LoadGame()
    {
        g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (!this.loader.gameStarted AND elapsedTime < 60000)
        {
            if (this.SafetyCheck())
            {
                this.OpenIC()
                return
            }
            this.loader.userLoaded
            this.loader.loadingDefinitions
            this.loader.loadingGameUser
            this.loader.loadingProgress
            this.loader.loadingText
            this.loader.socialUserAuthenticationDone
            sleep, 100
            elapsedTime := A_TickCount - startTime
            g_Log.AddData("loader", loader)
        }
        if (elapsedTime > 60000)
        {
            this.CloseIC()
            this.OpenIC()
            g_Log.EndEvent()
            return
        }
        g_Log.EndEvent()
        return

        /*  game.LoadingScreen.BeginLoading() is called
                various checks for console/mobile platforms
                this.LoadGraphics() called
            
            which just calls this.LoadDefinitions()
                this.loadingDefinitions = true;
                this.SetLoadingText(this.selectingServerString);
                    will set this.loadingText.lastSetText = this.selectServerString = "Selecting Play Server"
                loads local and connects to network
                attempts 5 times before giving up, no instance of this class is created to read attempts :(
                    maybe look up how long each request will take does seem it can be stuck indefinitely here though
            
            uses call back this.ContinueDefinitions()
                this.SetLoadingText(this.loadingDefinitionsString);
                    loadingDefinitionsString = "Loading Game Definitions $prog";
                loads definitions with the whole progress bar thing, replacing $prog

            uses call back this.LoadGameUser()
                OfflineProgressHandler.SetupOfflineProgressionRules();
                this.loadUserReady = true;
                this.loadingGameUser = true;
                this.SetLoadingText(CrusadersGameDataSet.Instance.GetTextDefineByKey("connecting_to_server", "Connecting to Server"));
            
            appears to call this.UserLoggedIn(), maybe multiple times
                this.loadingGameUser = false;
                multiple try/catch
                if this.gameuser.loaded = false pops dialog box could not connect to platform

            appears to call this.LoadUser()
                this.loadingDefinitionsProgress = 40f;
                this.loadingDefinitions = false;
                string textDefineByKey = CrusadersGameDataSet.Instance.GetTextDefineByKey("loading_user_account", "Loading User Account");
                this.SetLoadingText(textDefineByKey);
                this.loadingProgress += 10;

            this.PreloadGraphics()
                this.SetLoadingText(CrusadersGameDataSet.Instance.GetTextDefineByKey("loading_background_graphics", "Loading: Background Graphics"));
			    this.loadingProgress += 10;

            this.PreloadNextGraphic()
                appears to call itself over and over if (this.preloadGraphicIDs.Count > 0)
                removing graphic at 0
                string text = this.graphicNames[0];
				this.loadingProgress += 10;
				this.SetLoadingText(CrusadersGameDataSet.Instance.GetTextDefineByKey("loading", "Loading") + ": " + text);
                checks to complete from splash screen or complete, splash screen waits then fades out and calls this.Complete()

            this.Complete
                this.SetLoadingText(CrusadersGameDataSet.Instance.GetTextDefineByKey("starting_game", "Starting Game!"));
                this.loadingProgress += 10;
                new SimpleTimer(0.5f, new SimpleTimerTick(this.MakeCallback), false, false);

                finally checks for terms of service.
        */
    }

    ;need to add safety check for monsters attacking and stopping formation loading
    ; a function to confirm an adventure is loaded and accepting inputs, param == instance of IC_HeroHandler_Class
    LoadAdventure(hero)
    {
        g_Log.CreateEvent(A_ThisFunc)
        starTime := A_TickCount
        elapsedTime := 0
        VirtualKeyInputs.Generic("e", hero.Fkey)
        while (!hero.Benched AND elapsedTime < 60000)
        {
            if (this.SafetyCheck())
            {
                this.OpenIC()
                return
            }
            VirtualKeyInputs.Generic("e", hero.Fkey)
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        if (elapsedTime > 60000)
        {
            g_SF.CloseIC()
            g_Log.AddData("elapsedTime: Benching", elapsedTime)
            g_Log.EndEvent()
            return
        }
        startTime := A_TickCount
        elapsedTime := 0
        VirtualKeyInputs.Generic("w", hero.Fkey)
        while (hero.Benched AND elapsedTime < 60000)
        {
            if (this.SafetyCheck())
            {
                this.OpenIC()
                return
            }
            VirtualKeyInputs.Generic("w", hero.Fkey)
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        if (elapsedTime > 60000)
        {
            g_SF.CloseIC()
            g_Log.AddData("elapsedTime: unBenching", elapsedTime)
            g_Log.EndEvent()
            return
        }
        g_Log.EndEvent()
        return
    }

    ;A function that closes IC. If IC takes longer than 60 seconds to save and close then the script will force it closed.
    CloseIC( string := "" )
    {
        g_Log.CreateEvent(A_ThisFunc)
        g_Log.AddData("string", string)
        if WinExist( "ahk_exe IdleDragons.exe" )
            SendMessage, 0x112, 0xF060,,, ahk_exe IdleDragons.exe,,,, 10000 ; WinClose
        StartTime := A_TickCount
        ElapsedTime := 0
        while ( WinExist( "ahk_exe IdleDragons.exe" ) AND ElapsedTime < 10000 )
            ElapsedTime := A_TickCount - StartTime
        while ( WinExist( "ahk_exe IdleDragons.exe" ) ) ; Kill after 10 seconds.
            WinKill
        g_Log.EndEvent()
        return
    }

    IsCurrentFormation(formation)
    {
        g_Log.CreateEvent(A_ThisFunc)
        if(!IsObject(formation))
        {
            g_Log.AddData("formation", formation)
            g_Log.EndEvent()
            return false
        }
        slots := MemoryReader.GameInstance.Controller.formation.slots
        slots.SetAddress(true)
        loop, % formation.Count()
        {
            if(formation[A_Index] != slots.Item[A_Index - 1].hero.def.ID.GetValue())
            {
                g_Log.AddData("match", false)
                g_Log.EndEvent()
                return false
            }
        }
        g_Log.AddData("match", true)
        g_Log.EndEvent()
        return true
    }

    ; Returns the formation array of the formation used in the currently active modron.
    GetActiveModronFormation()
    {
        formation := ""
        ; Find the Campaign ID (e.g. 1 is Sword Cost, 2 is Tomb, 1400001 is Sword Coast with Zariel Patron, etc. )
        formationCampaignID := this.GameInstance.FormationSaveHandler.formationCampaignID.Value
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
}