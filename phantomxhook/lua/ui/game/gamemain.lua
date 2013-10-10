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
		
		if (tonumber(SessionGetScenarioInfo().Options.Mafia_Mod)) == 0 then
			import('/modules/phantom.lua').CreateModUI(isReplay, parent)
		else
			import('/_test_code/mafia_ui.lua').CreateModUI(isReplay, parent)
		end
		
		if (tonumber(SessionGetScenarioInfo().Options.TestNetLagReducer)) == 1 then
			import('/_test_code/NetLagControl.lua').CreateModUI(isReplay, parent)
		end
	end
end
