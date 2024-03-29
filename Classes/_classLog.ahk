;========================================
;Class for logging Idle Champions scripts
;========================================
/*  Usage:

    Parameters:

*/

class _classLog
{
    GetVersion()
    {
        return "v1.4, 11/22/21"
    }

    stack := {}

    __New()
    {
        ;this.CreateLogFile(fileName)
        ;this.CreateEvent(fileName)
        Return this
    }

    CreateLogFile(fileName, overwrite := true, dir := "")
    {
        if !dir
            dir := A_ScriptDir . "\LOG"
        if !FileExist( dir )
            FileCreateDir, %dir%
        if overwrite
        {
            this.fileName := "LOG\" . fileName . ".json"
            if FileExist(this.fileName)
                FileDelete, % this.fileName
        }
        else
        {
            this.fileName := "LOG\" . A_YYYY . "_" . A_MM . A_DD . "_" . fileName . "_1.json"
            i := 2
            while ( FileExist( this.fileName ) )
            {
                this.fileName := "LOG\" . A_YYYY . "_" . A_MM . A_DD . "_" . fileName . "_" . i . ".json"
                ++i
            }
        }
        FileAppend, [, % this.fileName
    }

    LogStack()
    {
        this.CurrentEvent.Stop()
        FileAppend, % JSON.stringify( this.stack ) . ",", % this.fileName
        this.stack := {}
    }

    EndLog()
    {
        FileAppend, % JSON.stringify( this.stack ) . "]", % this.fileName
        this := ""
    }

    AddToStack( obj )
    {
        index := this.stack.Count()
        if index != 0
            this.stack[ index ].eventLog.Push( obj )
        this.stack.Push( obj )
    }

    CreateEvent(description)
    {
        this.CurrentEvent := new _classLog.Event(description)
        this.AddToStack(this.CurrentEvent)
    }

    EndEvent()
    {
        this.CurrentEvent.Stop()
        if (this.stack.Count() > 1)
            this.stack.Pop()
        this.CurrentEvent := this.stack[this.stack.Count()]
    }

    AddData(description, value)
    {
        this.CurrentEvent.Add(new _classLog.Data(description, value))
    }

    AddDataSimple(value)
    {
        this.CurrentEvent.Add(value)
    }

    class Event
    {
        eventLog := {}

        __new(description)
        {
            this.event := {}
            this.event.description := description . ""
            this.event.duration := new _classLog.Duration()
            Return this
        }

        Add( value )
        {
            this.eventLog.Push( value )
        }

        Stop()
        {
            if !(this.eventLog.Count())
                this.Delete(eventLog)
            this.event.duration.Stop()
        }
    }

    class Duration
    {
        ms := -1

        __new()
        {
            this.startTickCount := A_TickCount + 0
            this.timeStamp := A_Now
            Return this
        }

        Stop()
        {
            this.ms := A_TickCount - this.startTickCount
            this.minutes := this.ms / 60000
        }
    }

    class Data
    {
        entry := {}

        __new(description, value)
        {
            this.entry.description := description . ""
            this.entry.tickCount := A_TickCount + 0
            this.entry.value := value
            Return this
        }
    }
}