; Dependencies:
#Include %A_LineFile%\..\..\System.ahk
if (System.__Class != "System")
{
    msgbox "System" not correctly installed. Or the (global class) variable "System" has been overwritten. Exiting App.
    ExitApp
}

class _IdleGameManager extends GameManager
{
    ;FB-IdleGameManager
    game := new CrusadersGame.Game(216, this)
    ;FE
}

;base class UnityEngine.MonoBehaviour
class GameManager extends System.StaticBase
{
    ;FB-GameManager
    TimeScale := new System.Single(128, this)
    ;FE
}

class CrusadersGame
{
    class ChampionsGameInstance extends System.Object
    {
        ;FB-CrusadersGame.ChampionsGameInstance
        ClickLevel := new System.Int32(264, this)
        ;FE
    }

    class Game extends UnityGameEngine.GameBase
    {
        ;FB-CrusadersGame.Game
        gameUser := new UnityGameEngine.UserLogin.GameUser(168, this)
        gameInstances := new System.Collections.Generic.List(176, this, CrusadersGame.ChampionsGameInstance)
        gameStarted := new System.Boolean(256, this)
        ;FE
    }
}

class UnityGameEngine
{
    class GameBase extends System.Object
    {
        ;FB-UnityGameEngine.GameBase
        ;screenController := new UnityGameEngine.GameScreenController.ScreenController(16, this)
        ;FE
    }

    class UserLogin
    {
        class GameUser extends System.Object
        {
            ;FB-UnityGameEngine.UserLogin.GameUser
            Hash := new System.String(32, this)
            Loaded := new System.Boolean(84, this)
            ID := new System.Int32(88, this)
            ;FE
        }
    }
}