class ExceptionHandler
{
    ThrowFatalError(message, level)
    {
        try
            throw Exception(message, level)
        catch e
        {
            position := RegExMatch(e.File, "[^\\]+\.ahk", match)
            msgbox % "Error: " e.Message "`nLine# " e.Line "`nFile: " match "`nExiting App"
            ExitApp
        }
    }

    ThrowError(message, level)
    {
        try
            throw Exception(message, level)
        catch e
        {
            position := RegExMatch(e.File, "[^\\]+\.ahk", match)
            msgbox % "Error: " e.Message "`nLine# " e.Line "`nFile: " match "`nApp will attempt to continue."
        }
    }
}