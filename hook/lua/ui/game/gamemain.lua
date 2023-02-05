#****************************************************************************
#**
#**  File     :  /hook/lua/ui/game/gamemain.lua
#**  Author(s):  novaprim3
#**
#**  Summary  :  Multi-Phantom Mod for Forged Alliance
#**
#****************************************************************************
local modPath = 'Phantom-X'

local baseCreateUI = CreateUI 

function CreateUI(isReplay) 
    baseCreateUI(isReplay) 
    
    if not isReplay then
        local parent = import('/lua/ui/game/borders.lua').GetMapGroup()
        import('/mods/faf-phantomx/modules/phantom.lua').CreateModUI(isReplay, parent)
    end
end
