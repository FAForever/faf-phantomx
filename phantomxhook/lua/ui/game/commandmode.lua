do

#local GameMain = import('/lua/ui/game/gamemain.lua')
#local Prefs = import('/lua/user/prefs.lua')

#local sessionInfo = SessionGetScenarioInfo()

local OldOnCommandIssued = OnCommandIssued

function OnCommandIssued(command)
	OldOnCommandIssued(command)
	#if import('/lua/MafiaSim.lua').allow_meteors then
		if command.CommandType=="Script" then
			LOG("hooked OnCommandIssued")
			LOG(repr(command))
			LOG("Position:")
			LOG(repr(command.Target.Position))
			LOG("Attempting to spawn meteors")
				
			local data = {dmg = 8000, splash = 8, count = 6, radius = 50, posX = command.Target.Position[1], posY = command.Target.Position[3], posZ = command.Target.Position[2]}
					
			SimCallback({Func = 'SpawnMeteors', Args = data})
				
			#ForkThread(function() import('/modules/mafia_meteors.lua').SetupMafiaMeteors(posX, posY, posZ, count, radius) end)         
		end
	#end
end

end