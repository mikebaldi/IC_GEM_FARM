#SingleInstance force
;put together with the help from many different people. thanks for all the help.
#HotkeyInterval 1000  ; The default value is 2000 (milliseconds).
#MaxHotkeysPerInterval 70 ; The default value is 70
#NoEnv ; Avoids checking empty variables to see if they are environment variables (recommended for all new scripts). Default behavior for AutoHotkey v2.
;=======================
;Script Optimization
;=======================
SetWorkingDir %A_ScriptDir%
SetWinDelay, 33 ; Sets the delay that will occur after each windowing command, such as WinActivate. (Default is 100)
SetControlDelay, 0 ; Sets the delay that will occur after each control-modifying command. -1 for no delay, 0 for smallest possible delay. The default delay is 20.
;SetKeyDelay, 0 ; Sets the delay that will occur after each keystroke sent by Send or ControlSend. [SetKeyDelay , Delay, PressDuration, Play]
SetBatchLines, -1 ; How fast a script will run (affects CPU utilization).(Default setting is 10ms - prevent the script from using any more than 50% of an idle CPU's time.
                  ; This allows scripts to run quickly while still maintaining a high level of cooperation with CPU sensitive tasks such as games and video capture/playback.
ListLines Off
Process, Priority,, Normal

CoordMode, Mouse, Client

#include %A_ScriptDir%\Classes\_Utilities.ahk
#Include %A_ScriptDir%\Classes\Memory\_MemoryHandler.ahk
#Include %A_ScriptDir%\Classes\_IC_FuncLibrary.ahk
#Include %A_ScriptDir%\Classes\_Contained.ahk
#Include %A_ScriptDir%\Classes\_VirtualKeyInputs.ahk
_VirtualKeyInputs.Init("ahk_exe IdleDragons.exe")

System.Refresh()
Funcs := _IC_FuncLibrary.CreateOrGetInstance()

loop
{
    System.Refresh()
    while (Funcs.ActiveCampaignData.ActiveCampaignData.currentAreaID.Value < 2001 AND Funcs.ActiveCampaignData.ActiveCampaignData.currentAreaID.Value > 0)
    {
        System.Refresh()
        Funcs.SetClickLevel(2500)
        Funcs.SetTimeScale(10)

        highest := Funcs.ActiveCampaignData.ActiveCampaignData.highestAvailableAreaID.Value
        current := Funcs.ActiveCampaignData.ActiveCampaignData.currentAreaID.Value
        qr := Funcs.ActiveCampaignData.QuestRemaining.Value

        if (qr > 0 AND highest != 2001)
            Funcs.ToggleAutoProgress(false)
        if (highest != 2001 and qr == 0)
            Funcs.ActiveCampaignData.ActiveCampaignData.highestAvailableAreaID.Value := 2001
        if (highest == 2001)
            Funcs.ToggleAutoProgress(true)

        sleep, 250
    }
}

