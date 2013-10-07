#****************************************************************************
#**
#**  File     :  /hook/lua/simInit.lua
#**  Author(s):  novaprim3
#**
#**  Summary  :  Multi-Phantom Mod for Forged Alliance
#**
#****************************************************************************
local modPath = 'Phantom-X'

local ParentBeginSession = BeginSession
function BeginSession()
	ParentBeginSession()

	if (tonumber(ScenarioInfo.Options.Mafia_Mod))==1 then
		ForkThread(import('/lua/MafiaSim.lua').PhantomMainThread)
	else
		ForkThread(import('/lua/PhantomSim.lua').PhantomMainThread)
		
		if (tonumber(ScenarioInfo.Options.Phantom_Meteor))==1 then
			ForkThread(import('/modules/meteors.lua').MeteorsThread)
		end	
		
	end		
end
