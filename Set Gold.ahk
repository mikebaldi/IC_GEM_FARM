#SingleInstance force
#Include %A_ScriptDir%\Classes\Memory\_MemoryHandler.ahk

; instructions: start an adventure. run this script. end the adventure
; note: exponent is base 2, not base 10
; 0.3010299956639812 factor to convert from base 2 to base 10
; but there are several digits in a 64 bit integer, which the significand is
; so up to around e18 to e20 will actually be a negative exponent

System.Refresh()
gameInstance := _MemoryHandler.CreateOrGetGameInstance()
gameInstance.StatHandler.GoldGained.Exponent.Value := 2000 ; works out to around e600 gold and around e175-180 favor