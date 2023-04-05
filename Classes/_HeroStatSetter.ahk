#Include %A_LineFile%\..\Memory\_MemoryHandler.ahk

temp := new _HeroStatSetter(18, 104, 106, 43, 96, 58, 77, 63, 8, 51, 71, 75)

class _HeroStatSetter
{
    __new(value, champIDs*)
    {
        ;check parameters are correct values
        if (value < 0 OR value > 2**31)
        {
            MsgBox, % "Invalid value parameter passed, exiting app. value: " . value
            ExitApp
        }
        count := champIDs.Count()
        if !count
        {
            MsgBox, No champion IDs passed, exiting app.
            ExitApp
        }

        ;get a reference of the heroes list
        System.Refresh()
        gameManager := new IdleGameManager
        heroes := gameManager.game.gameInstances.Item[0].HeroHandler.parent.heroes
        
        ;an array of the stat memory object names to iterate through
        stats := ["strs", "ints", "dexs", "chas", "cons", "wiss"]

        ;iterate through each champid and set all stats to value passed
        i := 1
        loop, % count
        {
            champID := champIDs[i++]
            if (champID < 0 OR champID > 300)
            {
                MsgBox, % "Invalid champion ID passed, app will continue to next champion. ChampID: " . champID
                continue
            }
            hero := heroes.Item[champID - 1]
            details := hero.def.characterDetails
            j := 1
            loop, 6
            {
                stat := stats[j++]
                _size := details[stat]._size.Value
                if !_size
                {
                    MsgBox, % "Failed to read Champ ID: " . champID . " size of list for stat: " . stat
                    continue
                }
                if (_size < 0 OR _size > 10)
                {
                    MsgBox, % "Unusual value read for Champ ID: " . champID . " size of list for stat: " . stat . ". Value Read: " . _size
                    continue
                }
                k := 0
                loop, % _size
                {
                    details[stat].Item[k++].Value := value
                }
            }
        }
        this := ""
    }
}