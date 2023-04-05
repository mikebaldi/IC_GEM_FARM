class IdleGameManager_Parent extends System.StaticBase
{
    Offset := 0x495A90
}

class IdleGameManager extends GameManager
{
    Offset := [0x495A90, 0xCB0]
    
    ;FB-IdleGameManager
    game := new CrusadersGame.Game(216, this)
    ;FE
    
    ;__new()
    ;{
    ;    this.Offset := 0xCB0
    ;    this.GetAddress := this.variableGetAddress
    ;    this.ParentObj := new IdleGameManager_Parent
    ;    return this
    ;}
}

;base class UnityEngine.MonoBehaviour
class GameManager extends System.Base
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
        Screen := new CrusadersGame.GameScreen.CrusadersGameScreen(16, this)
        Controller := new CrusadersGame.GameScreen.CrusadersGameController(24, this)
        ActiveCampaignData := new CrusadersGame.GameScreen.ActiveCampaignData(40, this)
        HeroHandler := new CrusadersGame.User.Instance.UserInstanceHeroHandler(48, this)
        ResetHandler := new CrusadersGame.User.Instance.UserInstanceResetHandler(64, this)
        StatHandler := new CrusadersGame.User.Instance.UserInstanceStatHandler(72, this)
        PatronHandler := new CrusadersGame.User.Instance.UserInstancePatronHandler(88, this)
        FormationSaveHandler := new CrusadersGame.User.UserInstanceFormationSaveHandler(104, this)
        ResetsSinceLastManual := new System.Int32(244, this)
        InstanceMode := new CrusadersGame.ChampionsGameInstance.GameInstanceMode(248, this)
        instanceLoadTimeSinceLastSave := new System.Int32(252, this)
        ClickLevel := new System.Int32(264, this)
        state := new CrusadersGame.ChampionsGameInstance.InstanceState(280, this)
        ;FE

        class GameInstanceMode extends System.Enum
        {
            Type := "System.Int32"
            Enum := {0:"Foreground", 1:"OfflineProgress", 2:"BackgroundProgress"}
            ;Enum := {0:"Foreground", 1:"CatchUp", 2:"OfflineProgress", 3:"BackgroundProgress"} ; pre v476
        }

        class InstanceState extends System.Enum
        {
            Type := "System.Int32"
            Enum := {0:"WaitingForBackgroundProgressToStart", 1:"Running", 2:"Loading", 3:"None", 4:"Cleared", 5:"WorldMap"}
            ;Enum := {0:"Running", 1:"Loading", 2:"WaitingForBGProgressStart", 3:"WaitingAfterBGProgress", 4:"None", 5:"Cleared", 6:"WorldMap"}
        }
    }

    class Defs
    {
        class AdventureDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.AdventureDef
            areas := new System.List(168, this, CrusadersGame.Defs.AreaDef)
            Repeatable := new System.Int32(204, this)
            ;FE
        }

        class AttackDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.AttackDef
            Name := new System.String(24, this)
            CooldownTimer := new System.Single(176, this)
            ;FE
        }

        class AreaDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.AreaDef
            Monsters := new System.List(32, this, System.Int32)
            Bosses := new System.List(40, this, [System.List, System.Int32])
            MonsterSpawners := new System.Dictionary(48, this, System.String, [System.Dictionary, System.String, System.Object])
            MonsterGenerators := new System.Dictionary(56, this, System.String, [System.Dictionary, System.String, System.Object])
            StaticMonsters := new System.Dictionary(72, this, System.String, [System.Dictionary, System.String, System.Object])
            backgroundDef := new CrusadersGame.Defs.BackgroundDef(144, this)
            BackgroundDefID := new System.Int32(204, this)
            isFixed := new System.Boolean(252, this) ;OR-TYPE
            ;FE

            ;to revisit when i want to figure out nullable type
            isFixed_hasValue := new System.Boolean(253, this)
            ;isFixed_hasValue_2byte := new System.Boolean(158, 0, this)
            ;isFixed_hasValue_3byte := new System.Boolean(159, 0, this)
        }

        class BackgroundDef extends UnityGameEngine.Data.DataDef
        {
            ;inherits id
            ;FB-CrusadersGame.Defs.BackGroundDef
            IsFixed := new System.Boolean(105, this)
            ;FE
        }

        class EffectDef extends UnityGameEngine.Data.DataDef
        {
            ;inherits id
        }

        class HeroDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.HeroDef
            characterDetails := new CrusadersGame.Defs.HeroDef.CharacterSheetDetails(24, this)
            name := new System.String(56, this)
            SeatID := new System.Int32(456, this)
            ;FE

            class CharacterSheetDetails extends System.Object
            {
                ;FB-CrusadersGame.Defs.HeroDef+CharacterSheetDetails
                strs := new System.List(0x50, this, System.Int32)
                ints := new System.List(0x58, this, System.Int32)
                dexs := new System.List(0x60, this, System.Int32)
                chas := new System.List(0x68, this, System.Int32)
                cons := new System.List(0x70, this, System.Int32)
                wiss := new System.List(0x78, this, System.Int32)
                ;FE
            }
        }

        class FormationSaveV2Def extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.FormationSaveV2Def
            Formation := new System.List(24, this, System.Int32)
            SaveID := new System.Int32(56, this)
            Name := new System.String(48, this)
            Favorite := new System.Int32(64, this)
            ;FE
        }

        class MonsterDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.MonsterDef
            Name := new System.String(24, this)
            availableAttacks := new System.List(32, this, CrusadersGame.Defs.MonsterDef.MonsterAttack)
            ;FE

            class MonsterAttack extends System.Object
            {
                ;FB-CrusadersGame.Defs.MonsterDef+MonsterAttack
                AttackDef := new CrusadersGame.Defs.AttackDef(0x10, this)
                ;FE
            }
        }

        class PatronDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.PatronDef
            Tier := new System.Int32(192, this)
            ;FE
        }

        class UpgradeDef extends UnityGameEngine.Data.DataDef
        {
            ;FB-CrusadersGame.Defs.UpgradeDef
            baseEffectString := new System.String(40, this)
            SpecializationName := new System.String(64, this)
            RequiredLevel := new System.Int32(132, this)
            RequiredUpgradeID := new System.Int32(140, this)
            typeUpgrade := new CrusadersGame.Defs.UpgradeDef.UpgradeType(120, this) ;OR-TYPE OR-NAME:type
            ;FE

            class UpgradeType extends System.Enum
            {
                Type := "System.Int32"
                Enum := {0:"SelfDPS", 1:"GlobalDPS", 2:"UnlockUltimate", 3:"UnlockAbility", 4:"UpgradeAbility", 5:"GoldFind", 6:"Specialization", 7:"IncreaseHealth", 8:"Taunt", 9:"DamageReduction", 10:"None"}
            }
        }
    }

    class Effects
    {
        class ActiveEffectKeyHandler extends System.Object
        {
            effectKey := new CrusadersGame.Effects.EffectKey(0, this)
        }


        class Effect extends System.Object
        {
            ;FB-CrusadersGame.Effects.Effect
            def := new CrusadersGame.Defs.EffectDef(16, this)
            effectKeyHandlers := new System.List(56, this, CrusadersGame.Effects.EffectKeyHandler)
            ;FE
        }


        class EffectKey extends System.Object
        {
            ;FB-CrusadersGame.Effects.EffectKey
            parentEffectKeyHandler := new CrusadersGame.Effects.EffectKeyHandler(16, this)
            ;FE
        }


        class EffectKeyCollection extends System.Object
        {
            ;FB-CrusadersGame.Effects.EffectKeyCollection
            effectKeysByKeyName := new System.Dictionary(88, this, System.String, [System.List, CrusadersGame.Effects.EffectKey])
            ;FE
        }


        class EffectKeyHandler extends System.Object
        {
            ;FB-CrusadersGame.Effects.EffectKeyHandler
            parent := new CrusadersGame.Effects.Effect(16, this)
            effectKeyParams := new CrusadersGame.Effects.EffectKeyParams(24, this)
            activeEffectHandlers := new System.List(304, this, CrusadersGame.Effects.ActiveEffectKeyHandler)
            ;FE
        }

        class EffectKeyParams extends System.Object
        {
            ;FB-CrusadersGame.Effects.EffectKeyParams
            cachedQuads := new System.Dictionary(24, this, System.String, Engine.Numeric.Quad)
            ;FE

            ;data := new System.Dictionary(0x10, this, System.String, Object) have to figure out how to deal with object type, but for now this data doesn't look useful enough.
        }

        class EffectStacks extends System.Object
        {
            ;FB-CrusadersGame.Effects.EffectStacks
            stackCount := new System.Double(152, this)
            ;FE
        }
    }

    class Game extends UnityGameEngine.GameBase
    {
        ;FB-CrusadersGame.Game
        loadingScreen := new CrusadersGame.LoadingScreen(88, this)
        gameUser := new UnityGameEngine.UserLogin.GameUser(168, this)
        gameInstances := new System.List(176, this, CrusadersGame.ChampionsGameInstance)
        gameStarted := new System.Boolean(256, this)
        ;FE
    }

    class GameScreen
    {
        class ActiveCampaignData extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.ActiveCampaignData
            adventureDef := new CrusadersGame.Defs.AdventureDef(16, this)
            currentObjective := new CrusadersGame.Defs.AdventureDef(24, this)
            currentArea := new CrusadersGame.GameScreen.AreaLevel(40, this)
            currentAreaID := new System.Int32(136, this)
            highestAvailableAreaID := new System.Int32(144, this)
            gold := new Engine.Numeric.Quad(592, this)
            ;FE
            goldQuad := new System.Quad(600, this)
        }

        class Area extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.Area
            activeMonsters := new System.List(72, this, CrusadersGame.GameScreen.Monster)
            Active := new System.Boolean(484, this)
            secondsSinceStarted := new System.Single(524, this)
            basicMonstersSpawnedThisArea := new System.Int32(584, this)
            ;FE
        }

        class AreaLevel extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.AreaLevel
            level := new System.Int32(84, this)
            QuestRemaining := new System.Int32(92, this)
            ;FE
        }

        class AreaTransitioner extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.AreaTransitioner
            IsTransitioning := new System.Boolean(56, this)
            transitionDirection := new CrusadersGame.GameScreen.AreaTransitioner.AreaTransitionDirection(60, this)
            ;FE

            class AreaTransitionDirection extends System.Enum
            {
                Type := "System.Int32"
                Enum := {0:"Forward", 1:"Backward", 2:"Static"}
            }
        }

        class CrusadersGameController extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.CrusadersGameController
            area := new CrusadersGame.GameScreen.Area(24, this)
            formation := new CrusadersGame.GameScreen.Formation(40, this)
            areaTransitioner := new CrusadersGame.GameScreen.AreaTransitioner(64, this)
            userData := new CrusadersGame.User.UserData(184, this)
            ;FE
        }

        class CrusadersGameScreen extends UnityGameEngine.GameScreenController.GameScreen
        {
            ;FB-CrusadersGame.GameScreen.CrusadersGameScreen
            uiController := new CrusadersGame.GameScreen.UIController(952, this)
            ;FE
        }

        class Formation extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.Formation
            slots := new System.List(40, this, CrusadersGame.GameScreen.FormationSlot)
            transitionOverrides := new System.Dictionary(184, this, CrusadersGame.GameScreen.Formations.FormationSlotRunHandler.TransitionDirection, [System.List, System.Action])
            transitionDir := new CrusadersGame.GameScreen.Formations.FormationSlotRunHandler.TransitionDirection(420, this)
            inAreaTransition := new System.Boolean(424, this)
            numAttackingMonstersReached := new System.Int32(432, this)
            numRangedAttackingMonsters := new System.Int32(436, this)
            ;FE
        }

        class Formations
        {
            class FormationSlotRunHandler
            {
                class TransitionDirection extends System.Enum
                {
                    Type := "System.Int32"
                    Enum := {0:"OnFromLeft", 1:"OnFromRight", 2:"OffToLeft", 3:"OffToRight"}
                }
            }
        }

        class FormationSlot extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.FormationSlot
            hero := new CrusadersGame.GameScreen.Hero(40, this)
            heroAlive := new System.Boolean(585, this)
            ;FE
        }


        class Hero extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.Hero
            def := new CrusadersGame.Defs.HeroDef(24, this)
            effects := new CrusadersGame.Effects.EffectKeyCollection(160, this)
            allUpgradesOrdered := new System.Dictionary(728, this, CrusadersGame.ChampionsGameInstance, [System.List, CrusadersGame.Defs.UpgradeDef])
            effectsByUpgradeId := new System.Dictionary(760, this, System.Int32, [System.List, CrusadersGame.Effects.Effect])
            Owned := new System.Boolean(800, this)
            slotID := new System.Int32(804, this)
            Benched := new System.Boolean(816, this)
            Level := new System.Int32(844, this)
            health := new System.Double(880, this)
            ;FE
        }

        class Monster extends UnityGameEngine.Display.Drawable
        {
            ;FB-CrusadersGame.GameScreen.Monster
            monsterDef := new CrusadersGame.Defs.MonsterDef(856, this)
            active := new System.Boolean(2649, this)
            ;FE
        }

        class OfflineProgressHandlerV2 extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.OfflineProgressHandlerV2
            CurrentState := new CrusadersGame.GameScreen.OfflineProgressHandlerV2.HandlerState(192, this)
            OfflineMode := new CrusadersGame.GameScreen.OfflineProgressHandlerV2.OfflineProgressMode(200, this)
            OfflineTimeRequested := new System.Int32(204, this)
            OfflineTimeSimulated := new System.Int32(208, this)
            CurrentStopReason := new CrusadersGame.GameScreen.OfflineProgressHandlerV2.StopReason(220, this)
            ;FE

            class HandlerState extends System.Enum
            {
                Type := "System.Int32"
                Enum := {0:"Inactive", 1:"Active", 2:"Stopping"}
            }

            class OfflineProgressMode extends System.Enum
            {
                Type := "System.Int32"
                Enum := {0:"OfflineProgress", 1:"BGProgress", -1:"None", 2:"PlaceHolder"}
            }

            class StopReason extends System.Enum
            {
                Type := "System.Int32"
                Enum := {0:"Cancel", 1:"CancelNoReload", 2:"Exception", 3:"NoAutoProgress", 4:"TooManyDead", 5:"WentBackwards", 6:"TooSlow", 7:"RanFullTime", 8:"Reset"}
            }
        }

        class UIComponents
        {
            class TopBar
            {
                ;class ObjectiveProgress
                ;{
                    class AreaLevelBar extends UnityGameEngine.Display.Drawable
                    {
                        ;FB-CrusadersGame.GameScreen.UIComponents.TopBar.ObjectiveProgress.AreaLevelBar
                        autoProgressButton := new UnityGameEngine.Display.DrawableButton(864, this)
                        ;FE
                    }

                    class ObjectiveProgressBox extends UnityGameEngine.Display.Drawable
                    {
                        ;FB-CrusadersGame.GameScreen.UIComponents.TopBar.ObjectiveProgress.ObjectiveProgressBox
                        areaBar := new CrusadersGame.GameScreen.UIComponents.TopBar.AreaLevelBar(912, this) ;OR-TYPE
                        ;FE
                    }
                ;}

                class TopBar extends UnityGameEngine.Display.Drawable
                {
                    ;FB-CrusadersGame.GameScreen.UIComponents.TopBar.TopBar
                    objectiveProgressBox := new CrusadersGame.GameScreen.UIComponents.TopBar.ObjectiveProgressBox(856, this) ;OR-TYPE
                    ;FE
                }
            }

            class UltimatesBar
            {
                class UltimatesBar extends UnityGameEngine.Display.Drawable
                {
                    ;FB-CrusadersGame.GameScreen.UIComponents.UltimatesBar.UltimatesBar
                    ultimateItems := new System.List(928, this, CrusadersGame.GameScreen.UIComponents.UltimatesBar.UltimatesBarItem)
                    ;FE
                }

                class UltimatesBarItem extends UnityGameEngine.Display.Drawable
                {
                    ;FB-CrusadersGame.GameScreen.UIComponents.UltimatesBar.UltimatesBarItem
                    hero := new CrusadersGame.GameScreen.Hero(912, this)
                    ;FE
                }
            }
        }


        class UIController extends System.Object
        {
            ;FB-CrusadersGame.GameScreen.UIController
            topBar := new CrusadersGame.GameScreen.UIComponents.TopBar.TopBar(24, this)
            ultimatesBar := new CrusadersGame.GameScreen.UIComponents.UltimatesBar.UltimatesBar(40, this)
            ;FE
        }
    }

    class LoadingScreen extends UnityGameEngine.GameScreenController.GameScreen
    {
        ;FB-CrusadersGame.LoadingScreen
        loadingText := new UnityGameEngine.Display.Drawable(872, this)
        loadingProgress := new System.Int32(1176, this)
        socialUserAuthenticationDone := new System.Boolean(1201, this)
        loadUserReady := new System.Boolean(1202, this)
        loadingGameUser := new System.Boolean(1203, this)
        loadingDefinitions := new System.Boolean(1207, this)
        loadingDefinitionsProgress := new System.Single(1220, this)
        ;FE
    }

    class User
    {
        class Instance
        {
            class UserInstanceDataHandler extends System.Object
            {

            }

            class UserInstanceHeroHandler extends CrusadersGame.User.Instance.UserInstanceDataHandler
            {
                ;FB-CrusadersGame.User.Instance.UserInstanceHeroHandler
                parent := new CrusadersGame.User.UserHeroHandler(72, this)
                ;FE
            }

            class UserInstancePatronHandler extends CrusadersGame.User.Instance.UserInstanceDataHandler
            {
                ;FB-CrusadersGame.User.Instance.UserInstancePatronHandler
                ActivePatron := new CrusadersGame.Defs.PatronDef(32, this)
                ;FE
            }

            class UserInstanceResetHandler extends CrusadersGame.User.Instance.UserInstanceDataHandler
            {
                ;FB-CrusadersGame.User.Instance.UserInstanceResetHandler
                resetting := new System.Boolean(56, this)
                tries := new System.Int32(60, this)
                ;FE
            }

            class UserInstanceStatHandler extends CrusadersGame.User.Instance.UserInstanceDataHandler
            {
                ;FB-CrusadersGame.User.Instance.UserInstanceStatHandler
                ActiveNerd0 := new System.Int32(600, this)
                ActiveNerd1 := new System.Int32(604, this)
                ActiveNerd2 := new System.Int32(608, this)
                DSpec1HeroId := new System.Int32(636, this)
                DSpec1SlotId := new System.Int32(640, this)

                ThisResetDamageDealt := new Engine.Numeric.Quad(0x130, this)
                ThisResetHighestDamageDealt := new Engine.Numeric.Quad(0x140, this)
                ;FE
            }
        }

        class UserChestHandler extends CrusadersGame.User.UserDataHandler
        {
            ;FB-CrusadersGame.User.UserChestHandler
            chestCounts := new System.Dictionary(24, this, System.Int32, System.Int32)
            ;FE
        }

        class UserData extends System.Object
        {
            ;FB-CrusadersGame.User.UserData
            HeroHandler := new CrusadersGame.User.UserHeroHandler(16, this)
            ChestHandler := new CrusadersGame.User.UserChestHandler(32, this)
            StatHandler := new CrusadersGame.User.UserStatHandler(48, this)
            ModronHandler := new CrusadersGame.User.UserModronHandler(216, this)
            redRubies := new System.Int32(620, this)
            redRubiesSpent := new System.Int32(624, this)
            inited := new System.Boolean(648, this)
            ActiveUserGameInstance := new System.Int32(668, this)
            ;FE
        }

        ;base object only includes parent (User), so recursive... maybe
        class UserHeroHandler extends System.Object
        {
            ;FB-CrusadersGame.User.UserHeroHandler
            heroes := new System.List(24, this, CrusadersGame.GameScreen.Hero)
            ;FE
        }
        
        class UserDataHandler extends System.Object
        {

        }

        class UserInstanceFormationSaveHandler extends CrusadersGame.User.UserDataHandler
        {
            ;FB-CrusadersGame.User.UserInstanceFormationSaveHandler
            formationSavesV2 := new System.List(48, this, CrusadersGame.Defs.FormationSaveV2Def)
            formationCampaignID := new System.Int32(120, this)
            ;FE
        }

        class UserModronHandler extends CrusadersGame.User.UserDataHandler
        {
            ;FB-CrusadersGame.User.UserModronHandler
            modronSaves := new System.List(32, this, CrusadersGame.User.UserModronHandler.ModronCoreData)
            ;FE

            class ModronCoreData extends System.Object
            {
                ;FB-CrusadersGame.User.UserModronHandler+ModronCoreData
                FormationSaves := new System.Dictionary(24, this, System.Int32, System.Int32)
                CoreID := new System.Int32(72, this)
                InstanceID := new System.Int32(76, this)
                ExpTotal := new System.Int32(80, this)
                targetArea := new System.Int32(84, this)
                ;FE
            }
        }

        class UserStatHandler extends CrusadersGame.User.UserDataHandler
        {
            ;FB-CrusadersGame.User.UserStatHandler
            BlackViperTotalGems := new System.Int32(672, this)
            BrivSteelbonesStacks := new System.Int32(768, this)
            BrivSprintStacks := new System.Int32(772, this)
            ;FE
        }
    }
}

class UnityGameEngine
{
    class Data
    {
        class DataDef extends System.Object
        {
            ;FB-UnityGameEngine.Data.DataDef
            ID := new System.Int32(16, this)
            ;FE
        }
    }

    class Display
    {
        class DrawableButton extends UnityGameEngine.Display.Drawable
        {
            ;FB-UnityGameEngine.Display.DrawableButton
            toggled := new System.Boolean(970, this)
            ;FE
        }


        class Drawable extends System.Object
        {
            ;FB-UnityGameEngine.Display.Drawable
            lastSetText := new System.String(104, this)
            ;FE
        }
    }

    class GameBase extends System.Object
    {
        ;FB-UnityGameEngine.GameBase
        screenController := new UnityGameEngine.GameScreenController.ScreenController(16, this)
        ;FE
    }

    class GameScreenController
    {
        class GameScreen extends System.Object
        {
            ;FB-UnityGameEngine.GameScreenController.GameScreen
            currentScreenWidth := new System.Int32(852, this)
            currentScreenHeight := new System.Int32(856, this)
            ;FE
        }

        class ScreenController extends System.Object
        {
            ;FB-UnityGameEngine.GameScreenController.ScreenController
            activeScreen := new CrusadersGame.GameScreen.CrusadersGameScreen(24, this)  ;OR-TYPE
            ;FE
        }
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

    class Utilities
    {
        class SimpleTimer extends System.Object
        {
            ;FB-UnityGameEngine.Utilities.SimpleTimer
            Name := new System.String(32, this)
            tSeconds := new System.Int32(80, this)
            Active := new System.Boolean(84, this)
            timeScale := new System.Single(88, this)
            duration := new System.Single(96, this)
            pauseCount := new System.Int32(108, this)
            ;FE
        }
    }
}