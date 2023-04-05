;_ServerCalls must be instantiated at least once before ResetFromWorldMap() is called

class _IC_ClientHandler extends _ClientHandler2
{
    CurrentObjective := 31

    IsAdventureRunning()
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        startTime := A_TickCount
        elapsedTime := 0
        while (!(this.IdleGameManager.game.gameStarted.Value) AND elapsedTime < 60000)
        {
            if !(this.DoesWinExist())
            {
                ;g_Log.AddData("Window Closed", true)
                ;g_Log.EndEvent()
                return -1
            }
            if (this.IsOnWorldMap())
            {
                ;g_Log.AddData("IsOnWorldMap", true)
                ;g_Log.EndEvent()
                return -2
            }
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        if (elapsedTime > 60000)
        {
            ;g_Log.EndEvent()
            return -3
        }
        startTime := A_TickCount
        elapsedTime := 0
        while ((this.GameInstance.state.Value != 1 OR this.GameInstance.InstanceMode.Value != 0) AND elapsedTime < 60000)
        {
            if !(this.DoesWinExist())
            {
                ;g_Log.AddData("Window Closed", true)
                ;g_Log.EndEvent()
                return -1
            }
            if (this.IsOnWorldMap())
            {
                ;g_Log.AddData("IsOnWorldMap", true)
                ;g_Log.EndEvent()
                return -2
            }
            sleep, 100
            elapsedTime := A_TickCount - startTime
        }
        if (elapsedTime > 60000)
        {
            ;g_Log.EndEvent()
            return -3
        }
        ;g_Log.EndEvent()
        return 1
    }

    IsOnWorldMap()
    {
        static lastRanTC := A_TickCount
        static onWorldMapTC := 0
        if ((lastRanTC + 5000) > A_TickCount)
            return false
        lastRanTC := A_TickCount
        ;when stuck on world map resetting always reads == 1
        ;if (this.ResetHandler.Resetting.Value != 1 AND this.GameInstance.state.Value == 6)
        if (this.GameInstance.state.Value == 6)
        {
            if !onWorldMapTC
                onWorldMapTC := A_TickCount
            else if ((onWorldMapTC + 30000) < A_TickCount)
            {
                onWorldMapTC := 0
                return true
            }
        }
        else
            onWorldMapTC := 0
        return false
    }

    OpenIC()
    {
        loop
        {
            this.Open()
            System.Refresh()
            flag := this.IsAdventureRunning()
            if (flag == 1)
                break
            else if (flag == -1)
                continue
            else if (flag == -2)
            {
                this.ResetFromWorldMap()
                continue
            }
            else if (flag == -3)
            {
                this.Close()
                continue
            }
        }
    }

    ResetFromWorldMap()
    {
        ;g_Log.CreateEvent(A_ThisFunc)
        this.Close()
        response := this.ServerCalls.CallLoadAdventure(this.CurrentObjective)
        ;g_Log.EndEvent()
        return
    }

    IdleGameManager[]
    {
        get
        {
            return _MemoryHandler.CreateOrGetIdleGameManager()
        }
    }

    GameInstance[]
    {
        get
        {
            return _MemoryHandler.CreateOrGetGameInstance()
        }
    }

    ServerCalls[]
    {
        get
        {
            return _ServerCalls.CreateOrGetInstance()
        }
    }
}