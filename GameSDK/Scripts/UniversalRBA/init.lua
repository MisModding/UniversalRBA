Script.ReloadScript('scripts/UniversalRBA/common.lua')

--- initialise UniversalRBA (only Serverside)
ServerOnly(
    function()
        RegisterCallback(
            _G, 'OnInitAllLoaded', nil, function()
                Script.ReloadScript('scripts/UniversalRBA/LuaMod.lua')
                Script.LoadScriptFolder('scripts/UniversalRBA/modules')
                Script.LoadScriptFolder('scripts/UniversalRBA/classes')
                Script.ReloadScript('scripts/UniversalRBA/UniversalRBA.lua')
            end
        )
    end
)