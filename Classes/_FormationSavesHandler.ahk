class _FormationSavesHandler
{
    __new()
    {
        this.GameInstance := _MemoryHandler.InitGameInstance()
        this.FormationSaves := this.GameInstance.FormationSaveHandler.formationSavesV2
        this.Saves := {}
        return this
    }

    ;creates a list of formation saves for current instance and adventure for use in other functions.
    RebuildSavesList()
    {
        this.Saves := {}
        _size := this.FormationSaves._size.Value ;.Size()
        if !_size
            return 0
        i := 0
        loop %_size%
            this.Saves.Push(this.FormationSaves.Item[i++])
        return i
    }

    ;iterates through a list of formation saves (this.RebuildSavesList()) looking for the save with matching favorite
    ;favorite: 1 == q, 2 == w, 3 == e
    ;return on success, array of champID with id == -1 representing empty formation slot
    ;return on failure, integer -1 when formation saves list is not built
    ;return on failure, integer -2 when favorite not found in saves list
    GetFormationByFavorite(favorite)
    {
        count := this.Saves.Count()
        if !count
            return -1
        loop %count%
        {
            if (this.Saves[A_Index].Favorite.GetValue() == favorite)
            {
                formation := {}
                savesIndex := A_Index
                _size := this.Saves[savesIndex].Formation._size.Value ;.Size()
                i := 0
                loop %_size%
                    formation.Push(this.Saves[savesIndex].Formation.Item[i++].GetValue())
                return formation
            }
        }
        return -2
    }
}