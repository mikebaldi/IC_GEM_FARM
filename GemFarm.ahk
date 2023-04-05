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
#Include %A_ScriptDir%\Classes\_GemFarm.ahk

settings := {}
settings.InstallPath := "C:\\Program Files (x86)\\Steam\\steamapps\\common\\IdleChampions\\"
settings.Exe := "IdleDragons.exe"
settings.StackZone := 1930
settings.TargetStacks := 27750
settings.MinGemCount := 0 ;min gem count when buying chests
settings.SetTimeScale := 10
settings.BuyGolds := true
settings.BuySilvers := false
settings.RestartStackTime := 0 ;milliseconds, 0 to disable restart stacking
settings.OpenChests := [1,2] ;chest ids to open
settings.AvoidBosses := true

g_GemFarm := new _GemFarmSimple(settings)

;OnExit("GemFarmExitApp")
g_GemFarm.GemFarm()

;GemFarmExitApp()
;{
;    g_Log.LogStack()
;}