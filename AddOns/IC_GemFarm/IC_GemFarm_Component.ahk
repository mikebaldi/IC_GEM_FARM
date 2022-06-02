;abandoned, for now at least.
;just run the run file directly
GUIFunctions.AddTab("Gem Farm")

Gui, ICScriptHub:Tab, Gem Farm
Gui, ICScriptHub:Add, Button, x15 y+15 w160 gGemFarm_Run, Launch Gem Farm
string := "Gem Farm:"
string .= "`nA script to automate gem farming. Requires Modron Automation and Briv.`n"
string .= "`nInstructions:"
string .= "`n1. Enter settings below."
string .= "`n2. Press save."
string .= "`n3. Press Launch Gem Farm."
string .= "`n4. A separate script will launch and begin farming gems. Only close this script when you are done gem farming."
string .= "`n5. A selection of statistics will update approximately ever 5 seconds."
Gui, ICScriptHub:Add, Text, x15 y+15 w450, % string

global g_GemFarmSettings := g_SF.LoadObjectFromJSON( A_LineFile . "\..\Settings.json" )

;check if first run
If !IsObject( g_GemFarmSettings )
{
    g_GemFarmSettings := {}
}

Gui, ICScriptHub:Add, Text, x15 y+15 w450, Settings:

if ( g_GemFarmSettings.UseFkeys == "" )
    g_GemFarmSettings.UseFkeys := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Use Fkeys to level champions:
chk := g_GemFarmSettings.UseFkeys
Gui, ICScriptHub:Add, Checkbox, vGemFarmUseFkeys Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vGemFarmUseFkeysSaved w200, % g_GemFarmSettings.UseFkeys == 1 ? "Saved value: True":"Saved value: False"

if ( g_GemFarmSettings.DashWait == "" )
    g_GemFarmSettings.DashWait := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Wait for Dash:
chk := g_GemFarmSettings.DashWait
Gui, ICScriptHub:Add, Checkbox, vGemFarmDashWait Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vGemFarmDashWaitSaved w200, % g_GemFarmSettings.DashWait == 1 ? "Saved value: True":"Saved value: False"

Gui, ICScriptHub:Add, Edit, vGemFarmStackZone x15 y+5 w50, % g_GemFarmSettings[ "StackZone" ]
Gui, ICScriptHub:Add, Text, x+5, Farm SB stacks AFTER this zone
Gui, ICScriptHub:Add, Text, x15 y+5 vGemFarmStackZoneSaved w200, % "Saved value: " . g_GemFarmSettings[ "StackZone" ]

Gui, ICScriptHub:Add, Edit, vGemFarmMinStackZone x15 y+10 w50, % g_GemFarmSettings[ "MinStackZone" ]
Gui, ICScriptHub:Add, Text, x+5, Minimum zone Briv can farm SB stacks on
Gui, ICScriptHub:Add, Text, x15 y+5 vGemFarmMinStackZoneSaved w200, % "Saved value: " . g_GemFarmSettings[ "MinStackZone" ]

Gui, ICScriptHub:Add, Edit, vGemFarmTargetStacks x15 y+10 w50, % g_GemFarmSettings[ "TargetStacks" ]
Gui, ICScriptHub:Add, Text, x+5, Target Haste stacks for next run
Gui, ICScriptHub:Add, Text, x15 y+5 vGemFarmTargetStacksSaved w200, % "Saved value: " . g_GemFarmSettings[ "TargetStacks" ]

Gui, ICScriptHub:Add, Edit, vGemFarmRestartStackTime x15 y+10 w50, % g_GemFarmSettings[ "RestartStackTime" ]
Gui, ICScriptHub:Add, Text, x+5, `Time (ms) client remains closed to trigger Restart Stacking (0 disables)
Gui, ICScriptHub:Add, Text, x15 y+5 vGemFarmRestartStackTimeSaved w200, % "Saved value: " . g_GemFarmSettings[ "RestartStackTime" ]

if ( g_GemFarmSettings.BuySilvers == "" )
    g_GemFarmSettings.BuySilvers := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Buy Silver Chests
chk := g_GemFarmSettings.BuySilvers
Gui, ICScriptHub:Add, Checkbox, vGemFarmBuySilvers Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vGemFarmBuySilversSaved w200, % g_GemFarmSettings.BuySilvers == 1 ? "Saved value: True":"Saved value: False"

if ( g_GemFarmSettings.BuyGolds == "" )
    g_GemFarmSettings.BuyGolds := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Buy Gold Chests
chk := g_GemFarmSettings.BuyGolds
Gui, ICScriptHub:Add, Checkbox, vGemFarmBuyGolds Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vGemFarmBuyGoldsSaved w200, % g_GemFarmSettings.BuyGolds == 1 ? "Saved value: True":"Saved value: False"

if ( g_GemFarmSettings.OpenSilvers == "" )
    g_GemFarmSettings.OpenSilvers := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Open Silver Chests
chk := g_GemFarmSettings.OpenSilvers
Gui, ICScriptHub:Add, Checkbox, vGemFarmOpenSilvers Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vGemFarmOpenSilversSaved w200, % g_GemFarmSettings.OpenSilvers == 1 ? "Saved value: True":"Saved value: False"

if ( g_GemFarmSettings.OpenGolds == "" )
    g_GemFarmSettings.OpenGolds := 1
Gui, ICScriptHub:Add, Text, x15 y+15, Open Gold Chests
chk := g_GemFarmSettings.OpenGolds
Gui, ICScriptHub:Add, Checkbox, vGemFarmOpenGolds Checked%chk% x+5, True
Gui, ICScriptHub:Add, Text, x+5 vGemFarmOpenGoldsSaved w200, % g_GemFarmSettings.OpenGolds == 1 ? "Saved value: True":"Saved value: False"

Gui, ICScriptHub:Add, Text, x15 y+15 w200 vGemFarmStats, Stats: OFF
Gui, ICScriptHub:Add, Text, x15 y+10 w200 vGemFarmBPH, BPH:
Gui, ICScriptHub:Add, Text, x15 y+5 w200 vGemFarmGPH, GPH:
Gui, ICScriptHub:Add, Text, x15 y+5 w200 vGemFarmRunTime,

Gui, ICScriptHub:Add, Button, x15 y+15 w160 gGemFarm_ResetStats, Reset Stats

Gui, ICScriptHub:Add, Button, x15 y+15 w160 gGemFarm_EndStats, Toggle Stats On/Off

IC_GemFarm_Component.ProcessSettings(g_GemFarmSettings)
g_SF.WriteObjectToJSON( A_LineFile . "\..\Settings.json" , g_GemFarmSettings )

global g_GemFarmStats

GemFarm_Run()
{
    ;Run, %A_LineFile%\..\GemFarm.ahk
    g_GemFarmStats := new IC_GemFarm_Component
    g_GemFarmStats.UpdateStats()
}

GemFarm_ResetStats()
{
    g_GemFarmStats.gemsStart := g_GemFarmStats.Gems
    g_GemFarmStats.coreXPstart := g_GemFarmStats.CoreXP
    g_GemFarmStats.startTickCount := A_TickCount
}

GemFarm_EndStats()
{
    if (g_GemFarmStats.Update)
        g_GemFarmStats.Update := false
    else
        g_GemFarmStats.UpdateStats()
}

class IC_GemFarm_Component
{
    __new()
    {
        MemoryReader.CheckForIC()
        MemoryReader.Refresh()
        this.gameInstance := MemoryReader.InitGameInstance()
        this.gemsStart := this.Gems
        this.coreXPstart := this.CoreXP
        this.startTickCount := A_TickCount
        return this
    }

    ProcessSettings(settings)
    {
        if !IsObject(settings.OpenChests)
            settings.OpenChests := {}
        if !IsObject(settings.OpenChests.Chests)
            settings.OpenChests.Chests := {}
        settings.OpenChests.Active := false
        if (settings.OpenSilvers)
            settings.OpenChests.Chests[1] := 1
        else if (settings.OpenChests.Chests.HasKey(1))
            settings.OpenChests.Chests.Delete(1)
        if (settings.OpenGolds)
            settings.OpenChests.Chests[2] := 2
        else if (settings.OpenChests.Chests.HasKey(2))
            settings.OpenChests.Chests.Delete(2)
    }

    UpdateStats()
    {
        this.Update := true
        GuiControl, ICScriptHub:, GemFarmStats, Stats: ON
        while (this.Update)
        {
            MemoryReader.Refresh()
            GuiControl, ICScriptHub:, GemFarmBPH, % "Bosses Per Hour: " . this.BPH
            GuiControl, ICScriptHub:, GemFarmGPH, % "Gems Per Hour: " . this.GPH
            GuiControl, ICScriptHub:, GemFarmRunTime, % "Run Time (Hours): " Round(this.RunTime, 2)
            sleep, 5000
        }
        GuiControl, ICScriptHub:, GemFarmStats, Stats: OFF
    }

    RunTime[]
    {
        get
        {
            return (A_TickCount - this.startTickCount) / 3600000
        }
    }

    GPH[]
    {
        get
        {
            return Round( (this.Gems - this.gemsStart) / this.RunTime, 2)
        }
    }

    BPH[]
    {
        get
        {
            return Round( ( (this.CoreXP - this.coreXPStart) / this.RunTime ) / 5, 2)
        }
    }

    Gems[]
    {
        get
        {
            return this.gameInstance.Controller.userData.redRubies.GetValue()
        }
    }

    ActiveGameInstance[]
    {
        get
        {
            return this.gameInstance.Controller.userData.ActiveUserGameInstance.GetValue()
        }
    }

    CoreXP[]
    {
        get
        {
            modronHandler := this.gameInstance.Controller.userData.ModronHandler
            _size := modronHandler.modronSaves.Size()
            loop %_size%
            {
                core := modronHandler.modronSaves.Item[A_Index - 1]
                if (core.InstanceID.GetValue() == this.ActiveGameInstance)
                    return core.ExpTotal.GetValue()
            }
            return ""
        }
    }
}