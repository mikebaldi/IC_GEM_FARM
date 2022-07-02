class _Contained
{
    Instance := ""

    CreateOrGetInstance()
    {
        if IsObject(this.Instance)
            return this.Instance
        className := this.__Class
        this.Instance := new %className%
        return this.Instance
    }
}