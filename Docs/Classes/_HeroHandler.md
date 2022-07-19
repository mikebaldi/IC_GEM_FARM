# _HeroHandler

A class for handling champions.

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
    - MaxLvl: The given champion's maximum level, as read from memory.
    - Name: The given champion's name, as read from memory.
    - Seat: The given champion's seat, as read from memory.

### Methods

- new

    Creates a new instance of the class.

    - Parameters

        - champID: The id of the champion.

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

    Sets this.MaxLvl.

    - Parameters

        None
        
    - Returns

        Nothing

    - Notes

        Reads through a list of ordered upgrades ignoring values 9999 or higher.

            

