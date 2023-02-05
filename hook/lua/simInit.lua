--****************************************************************************
--**
--**  File     :  /hook/lua/simInit.lua
--**  Author(s):  novaprim3
--**
--**  Summary  :  Multi-Phantom Mod for Forged Alliance
--**
--****************************************************************************
local modPath = 'Phantom-X'

function ShuffleStartPositions(syncNewPositions) -- Disable spawn shuffling and syncing since everyone starts allied
    syncStartPositions = false
end

local oldImport = import
function import(x)
    if x == '/lua/PhantomSim.lua' then
        return oldImport('/mods/faf-phantomx/lua/PhantomSim.lua')
    end
    return oldImport(x)
end

local ParentBeginSession = BeginSession
function BeginSession()
    
    ParentBeginSession()
    ForkThread(import('/mods/faf-phantomx/lua/PhantomSim.lua').PhantomMainThread)
    if( tonumber(ScenarioInfo.Options.Phantom_Meteor)) == 1 then
        ForkThread(import('/mods/faf-phantomx/modules/meteors.lua').MeteorsThread)
    end
    import('/lua/sim/score.lua').alliesScore = false
end
