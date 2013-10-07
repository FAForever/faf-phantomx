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
			import('/modules/phantom.lua').SetPhantomsRevealed(Sync.pRevealed)	
		end
        if Sync.pMeteorData then
            import('/modules/meteor_ui.lua').SyncData(Sync.pMeteorData)
        end
		if Sync.PAssignment then
			import('/modules/phantom.lua').SetAssignment(Sync.PAssignment)
		end
		if Sync.pData then
			import('/modules/phantom.lua').SetPhantomData(Sync.pData)
		end
		if Sync.pStats then
			import('/modules/phantom.lua').SetPhantomStats(Sync.pStats)
		end
		if Sync.pEco then
			import('/modules/phantom.lua').SetPhantomEco(Sync.pEco)
		end	
		if Sync.pAlert then
			import('/modules/phantom.lua').ShowAlert(Sync.pAlert)
		end
		if Sync.pSkin then
			import('/modules/phantom.lua').SetLayout()
		end
		if Sync.pVote then
			import('/modules/phantom.lua').ShowPhantomVote()
		end
		if Sync.pVolunteer then
			import('/modules/phantom.lua').ShowVolunteerVote()
		end	
		if Sync.pEcoObfuscate then
			import('/lua/ui/game/economy.lua').UpdatePhantomEco(Sync.pEcoObfuscate)
		end	
		if Sync.pModifyAssignmentTime then
			import('/modules/phantom.lua').UpdateAssignmentTime(Sync.pModifyAssignmentTime)
		end
	
	
		if Sync.mRevealed then
			LOG("UserSync: SetPhantomsRevealed()")
			import('/modules/mafia_ui.lua').SetPhantomsRevealed(Sync.mRevealed)	
		end
		if Sync.mAssignment then
			LOG("UserSync: SetAssignment()")
			import('/modules/mafia_ui.lua').SetAssignment(Sync.mAssignment)
		end
		if Sync.mData then
			LOG("UserSync: SetPhantomData()")
			import('/modules/mafia_ui.lua').SetPhantomData(Sync.mData)
		end
		if Sync.mStats then
			LOG("UserSync: SetPhantomStats()")
			import('/modules/mafia_ui.lua').SetPhantomStats(Sync.mStats)
		end
		if Sync.mSkin then
			LOG("UserSync: SetLAyout()")
			import('/modules/mafia_ui.lua').SetLayout()
		end
		if Sync.mVote then
			LOG("UserSync: ShowPhantomVote")
			import('/modules/mafia_ui.lua').ShowPhantomVote()
		end
		if Sync.mVolunteer then
			LOG("UserSync:  ShowVolunteerVote")
			import('/modules/mafia_ui.lua').ShowVolunteerVote()
		end	
		if Sync.mMeteors then
			LOG("UserSync:  ShowMeteorBtn")
			import('/modules/mafia_ui.lua').ShowMeteorBtn(Sync.mMeteors)
		end
		if Sync.mAlert then
			import('/modules/mafia_ui.lua').ShowAlert(Sync.mAlert)
		end
		
end
