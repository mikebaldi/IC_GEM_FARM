# _HeroHandler

A class for handling champions, primarily used by _FormationHandler class or as a base class for specific champion handlers.

### Uses

- [Classes\Memory\\_MemoryHandler.AHK](Memory\_MemoryHandler.md)
- [Classes\Memory\\_MemoryObjects.AHK](Memory\_MemoryObjects.md)
- [Classes\Memory\Structures\IdleGameManager.AHK](Memory\Structures\_IdleGameManager.md)
- [Classes\\_VirtualKeyInputs.AHK](_VirtualKeyInputs.md)

### Fields

<details><summary>Benched</summary>

- A reference to an instance of CrusadersGame.GameScreen.Hero.Benched memory object for the given champion.
- Type: System.Boolean
</details>
<details><summary>ChampID</summary>

- The given champion's ID.
- Type: Integer
</details>
<details><summary>FKey</summary>

- Fkey input to level the given champion.
- Type: String
</details>
<details><summary>hero</summary>

- A reference to an instance of CrusadersGame.GameScreen.Hero memory object for the given champion.
- Type: System.Object
</details>
<details><summary>Level</summary>

- A reference to an instance of CrusadersGame.GameScreen.Hero.Level memory object for the given champion.
- Type: System.Int32
</details>
<details><summary>MaxLvl</summary>

- The given champion's maximum level, as read from memory. Can be set to last specialization choice.
- Type: Integer
</details>
<details><summary>Name</summary>

- The given champion's name, as read from memory.
- Type: String
</details>
<details><summary>Seat</summary>

- The given champion's seat, as read from memory.
- Type: System.Int32
</details>

### Methods

<details><summary>new</summary>
Creates a new instance of the class with all fields set.

- Parameters
    - champID (integer): The id of the champion.
    - setMaxLvl (optional, boolean): Default value is false and will set MaxLvl field to last specialization choice. True will set MaxLvl field to last upgrade.

- Returns
    - Instance of the class.

- Notes
    - Error handling exists only for a failed memory read of the champion seat.
    - this.Init() is called for derived classes that desire adding additionaly code to the constructor.
</details>

<details><summary>LevelUp</summary>
Sends FKey and additional inputs if desired until a target level or timeout is reached.

- Parameters
    - Lvl (optional): The target level desired. If nothing is passed, the target level is set as this.MaxLvl.
    - timeout (optiona): The time in miliseconds the method will attempt to reach the target level. Default value is 5000.
    - keys (variadic): One or more keys to input along with the Fkey to level. The Fkey should not be passed.

- Returns
    - Nothing
</details>

<details><summary>SetMaxLvl</summary>
Sets MaxLvl field to the final upgrade required level.

- Parameters
    - None
    
- Return
    - Nothing

- Notes
    - Primiarly used internally at construction of a new instance, but can be called any time.
    - Reads through a list of ordered upgrades from the end of the list ignoring values 9999 or higher.
</details>

<details><summary>SetMaxLvlToLastSpec</summary>
Sets MaxLvl field to the final specialization upgrade required level.

- Parameters
    - None
    
- Returns
    - Nothing

- Notes
    - Primiarly used internally at construction of a new instance, but can be called any time.
    - Reads through a list of ordered upgrades from the end of the list ignoring upgrades without a specilization name.
</details>

            

