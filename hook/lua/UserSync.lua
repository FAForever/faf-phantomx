#****************************************************************************
#**
#**  File     :  /hook/lua/UserSync.lua
#**  Author(s):  novaprim3
#**
#**  Summary  :  Multi-Phantom Mod for Forged Alliance
#**
#****************************************************************************
local modPath = 'Phantom-X'

local baseOnSync = OnSync
#local sessionInfo = SessionGetScenarioInfo()

function OnSync()
    baseOnSync()

    # Sim to UI
    if Sync.pRevealed then
        import('/mods/faf-phantomx/modules/phantom.lua').SetPhantomsRevealed(Sync.pRevealed)
    end
    if Sync.pMeteorData then
        import('/mods/faf-phantomx/modules/meteor_ui.lua').SyncData(Sync.pMeteorData)
    end
    if Sync.PAssignment then
        import('/mods/faf-phantomx/modules/phantom.lua').SetAssignment(Sync.PAssignment)
    end
    if Sync.pData then
        import('/mods/faf-phantomx/modules/phantom.lua').SetPhantomData(Sync.pData)
    end
    if Sync.pStats then
        import('/mods/faf-phantomx/modules/phantom.lua').SetPhantomStats(Sync.pStats)
    end
    if Sync.pEco then
        import('/mods/faf-phantomx/modules/phantom.lua').SetPhantomEco(Sync.pEco)
    end
    if Sync.pAlert then
        import('/mods/faf-phantomx/modules/phantom.lua').ShowAlert(Sync.pAlert)
    end
    if Sync.pSkin then
        import('/mods/faf-phantomx/modules/phantom.lua').SetLayout()
    end
    if Sync.pVote then
        import('/mods/faf-phantomx/modules/phantom.lua').ShowPhantomVote()
    end
    if Sync.pVolunteer then
        import('/mods/faf-phantomx/modules/phantom.lua').ShowVolunteerVote()
    end
    if Sync.pEcoObfuscate then
        import('/mods/faf-phantomx/lua/ui/game/economy.lua').UpdatePhantomEco(Sync.pEcoObfuscate)
    end
    if Sync.pModifyAssignmentTime then
        import('/mods/faf-phantomx/modules/phantom.lua').UpdateAssignmentTime(Sync.pModifyAssignmentTime)
    end
end
