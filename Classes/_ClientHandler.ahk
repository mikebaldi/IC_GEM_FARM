class _ClientHandler
{
    __new()
    {
        this.GameManager := _MemoryHandler.CreateOrGetIdleGameManager()
        this.GameInstance := _MemoryHandler.CreateOrGetGameInstance()
        this.Loader := _MemoryHandler.CreateOrGetLoadingScreen()
        this.MemoryLog := _MemoryLogHandler.CreateOrGetInstance()
        this.InitMemoryLog()
        this.PID := 0
        this.HWD := 0
        this.Funcs := new _IC_FuncLibrary ;.CreateOrGetInstance()
        return this
    }

    InitMemoryLog()
    {
        this.MemoryLog.Add(this.GameManager.game.gameStarted, "gameStarted")
        this.MemoryLog.Add(this.GameManager.game.gameUser.Loaded, "userLoaded")
        this.MemoryLog.Add(this.GameManager.game.loadingScreen.loadingDefinitions, "loadingDefinitions")
        this.MemoryLog.Add(this.GameManager.game.loadingScreen.loadingProgress, "loadingProgress")
        this.MemoryLog.Add(this.GameManager.game.loadingScreen.loadingText.lastSetText, "lastSetText")
        this.MemoryLog.Add(this.GameManager.game.loadingScreen.socialUserAuthenticationDone, "socialUserAuthenticationDone")
        this.MemoryLog.Add(this.GameInstance.state, "state")
        this.MemoryLog.Add(this.GameInstance.InstanceMode, "InstanceMode")
    }

    ;same as winexist, but only if hasn't done so in last 5000 ms
    SafetyCheck()
    {
        static lastRan := 0
        if (lastRan + 5000 < A_TickCount)
        {
            lastRan := A_TickCount
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
        _MemoryHandler.Refresh()
        this.LoadGame()
        g_Log.EndEvent()
        return true
    }

    LoadGame()
    {
        g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        i := 0
        ;while (!(this.GameManager.game.gameStarted.Value) AND elapsedTime < 60000)
        ;while (!(this.Loader.gameStarted.Value) AND elapsedTime < 60000)
        while (!(this.MemoryLog.gameStarted.Value) AND elapsedTime < 60000)
        {
            if !(this.SafetyCheck())
            {
                g_Log.AddData("Window Closed", true)
                this.OpenIC()
                g_Log.EndEvent()
                return
            }

            this.MemoryLog.userLoaded.Value
            this.MemoryLog.loadingDefinitions.Value
            this.MemoryLog.loadingGameUser.Value
            this.MemoryLog.loadingProgress.Value
            this.MemoryLog.loadingText.Value
            this.MemoryLog.socialUserAuthenticationDone.Value
            this.MemoryLog.state.Value
            this.MemoryLog.InstanceMode.Value
            if (this.Funcs.IsOnWorldMap())
                g_Log.AddData("IsOnWorldMap", "true")
            sleep, 100
            elapsedTime := A_TickCount - startTime
            ++i
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
        startTime := A_TickCount
        elapsedTime := 0
        _VirtualKeyInputs.Priority("e", hero.Fkey)
        ;benched := hero.Benched
        ;g_Log.AddData("benched, startup", benched)
        while (!(hero.Benched.Value) AND elapsedTime < 60000)
        {
            if !(this.SafetyCheck())
            {
                g_Log.AddData("Window Closed", true)
                ;this.OpenIC()
                g_Log.EndEvent()
                return
            }
            this.MemoryLog.state.Value
            this.MemoryLog.InstanceMode.Value
            _VirtualKeyInputs.Priority("e", hero.Fkey)
            if (this.Funcs.IsOnWorldMap())
                g_Log.AddData("IsOnWorldMap", "true")
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        g_Log.AddData("elapsedTime: Benching", elapsedTime)
        if (elapsedTime > 60000)
        {
            this.CloseIC()
            ;g_Log.AddData("elapsedTime: Benching", elapsedTime)
            g_Log.EndEvent()
            return
        }
        startTime := A_TickCount
        elapsedTime := 0
        _VirtualKeyInputs.Priority("w", hero.Fkey)
        while ((hero.Benched.Value) AND elapsedTime < 60000)
        {
            if !(this.SafetyCheck())
            {
                g_Log.AddData("Window Closed", true)
                ;this.OpenIC()
                g_Log.EndEvent()
                return
            }
            this.MemoryLog.state.Value
            this.MemoryLog.InstanceMode.Value
            _VirtualKeyInputs.Priority("w", hero.Fkey)
            if (this.Funcs.IsOnWorldMap())
                g_Log.AddData("IsOnWorldMap", "true")
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        g_Log.AddData("elapsedTime: unBenching", elapsedTime)
        if (elapsedTime > 60000)
        {
            this.CloseIC()
            ;g_Log.AddData("elapsedTime: unBenching", elapsedTime)
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
}