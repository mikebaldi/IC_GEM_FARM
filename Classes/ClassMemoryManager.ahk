; A class to manage instance(s) of _ClassMemory and module base addresses.

; Dependencies:
#Include %A_LineFile%\..\classMemory.ahk
if (_ClassMemory.__Class != "_ClassMemory")
{
    msgbox "_ClassMemory" not correctly installed. Or the (global class) variable "_ClassMemory" has been overwritten. Exiting App.
    ExitApp
}

class _ClassMemoryManager
{
    ; Internal associative arrays to keep references of class memory instances and module base address values.
    instances := {}
    baseAddresses := {}

    ; Property that requires an exe name, returns an instance of class memory.
    ClassMemory[exeName]
    {
        get
        {
            if !(_ClassMemoryManager.instances.HasKey(exeName))
            {
                _ClassMemoryManager.OpenProcess(exeName)
            }
            return _ClassMemoryManager.instances[exeName]
        }
    }

    ; Property that requires exe name and module name, returns the module base address.
    BaseAddress[exeName, moduleName]
    {
        get
        {
            if !(_ClassMemoryManager.baseAddresses.HasKey(moduleName))
            {
                _ClassMemoryManager.RefreshModuleBaseAddress(exeName, moduleName)
            }
            return _ClassMemoryManager.baseAddresses[moduleName]
        }
    }

    ; A method that creates or refreshes an instance of class memory. This method must be called every time the exe is restarted.
    ; Also refreshes the module base address if one has been associated with the given exe name.
    ; This is done by calling the BaseAddress property or RefreshModuleBaseAddress method.
    OpenProcess(exeName, moduleName := "")
    {
        _ClassMemoryManager.handle := ""
        _ClassMemoryManager.instances[exeName] := new _ClassMemory("ahk_exe " . exeName, "", _ClassMemoryManager.handle)
        if (moduleName)
        {
            _ClassMemoryManager.RefreshModuleBaseAddress(exeName, moduleName)
        }
        return _ClassMemoryManager.handle
    }

    ; A method that refreshes the module base address. This method must be called every time the exe is restarted.
    ; OpenProcess method calls this method.
    RefreshModuleBaseAddress(exeName, moduleName)
    {
        _ClassMemoryManager.baseAddresses[moduleName] := _ClassMemoryManager.ClassMemory[exeName].getModuleBaseAddress(moduleName)
    }
}