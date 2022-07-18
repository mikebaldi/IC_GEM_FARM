class _ClientHandler2
{
    __new(exe, exePath)
    {
        this.WinTitle := "ahk_exe " . exe
        this.ExePath := exePath
        this.FullPath := exePath . exe
        this.PID := 0
        this.HWD := 0
        this.WinExistDelay := 5000
        return this
    }

    Close()
    {
        g_Log.CreateEvent(A_ThisFunc)
        if WinExist(this.WinTitle)
            SendMessage, 0x112, 0xF060,,, % this.WinTitle,,,, 10000 ; WinClose
        WinWaitClose, % this.WinTitle,, 10
        if WinExist(this.WinTitle)
            WinKill
        g_Log.EndEvent()
        return
    }

    DoesWinExist()
    {
        static lastRan := 0
        if (lastRan + this.WinExistDelay < A_TickCount)
        {
            lastRan := A_TickCount
            if (Not WinExist(this.WinTitle))
                return false
        }
        return true
    }

    Open()
    {
        g_Log.CreateEvent(A_ThisFunc)
        this.PID := 0
        this.HWD := 0
        attempts := 0
        while (!this.PID)
        {
            Run, % this.FullPath, % this.ExePath,, OutputVarPID
            this.PID := OutputVarPID
            WinWait, % "ahk_pid " . this.PID,,32000
            if ErrorLevel
            {
                g_Log.AddData("attempts", ++attempts)
                Process, Close, % this.PID
                this.PID := 0
            }
        }
        this.HWD := WinExist(this.WinTitle)
        g_Log.EndEvent()
        return
    }
}