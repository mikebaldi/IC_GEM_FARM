# _HeroHandler

A class for handling champions, primarily used by _FormationHandler class or as a base class for specific champion handlers.

### Uses

- [Classes\Memory\_MemoryHandler.AHK](Memory\_MemoryHandler.md)
- [Classes\Memory\_MemoryObjects.AHK](Memory\_MemoryObjects.md)
- [Classes\Memory\Structures\IdleGameManager.AHK](Memory\Structures\_IdleGameManager.md)
- [Classes\_VirtualKeyInputs.AHK](_VirtualKeyInputs.md)

### Fields

- Benched: A reference to an instance of CrusadersGame.GameScreen.Hero.Benched memory object for the given champion.
- ChampID: The given champion's ID.
- FKey: Fkey input to level the given champion.
- hero: A reference to an instance of CrusadersGame.GameScreen.Hero memory object for the given champion.
- Level: A reference to an instance of CrusadersGame.GameScreen.Hero.Level memory object for the given champion.
- MaxLvl: The given champion's maximum level, as read from memory. Can be set to last specialization choice.
- Name: The given champion's name, as read from memory.
- Seat: The given champion's seat, as read from memory.

### Methods

- new

    Creates a new instance of the class with all fields set.

    - Parameters

        - champID (integer): The id of the champion.
        - setMaxLvl (optional, boolean): Default value is false and will set MaxLvl field to last specialization choice. True will set MaxLvl field to last upgrade.

    - Returns

        - Instance of the class.

    - Notes

        - Error handling exists only for a failed memory read of the champion seat.
        - this.Init() is called for derived classes that desire adding additionaly code to the constructor.

- LevelUp

    Sends FKey and additional inputs if desired until a target level or timeout is reached.

    - Parameters
        - Lvl (optional): The target level desired. If nothing is passed, the target level is set as this.MaxLvl.
        - timeout (optiona): The time in miliseconds the method will attempt to reach the target level. Default value is 5000.
        - keys (variadic): One or more keys to input along with the Fkey to level. The Fkey should not be passed.

    - Returns

        Nothing

- SetMaxLvl

    Sets MaxLvl field to the final upgrade required level.

    - Parameters

        None
        
    - Returns

        Nothing

    - Notes
        - Primiarly used internally at construction of a new instance, but can be called any time.
        - Reads through a list of ordered upgrades from the end of the list ignoring values 9999 or higher.

- SetMaxLvlToLastSpec

    Sets MaxLvl field to the final specialization upgrade required level.

    - Parameters
    
        None
        
    - Returns

        Nothing

    - Notes
        - Primiarly used internally at construction of a new instance, but can be called any time.
        - Reads through a list of ordered upgrades from the end of the list ignoring upgrades without a specilization name.

            

