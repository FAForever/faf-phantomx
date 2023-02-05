#****************************************************************************
#**
#**  File     :  /hook/lua/system/Blueprints.lua
#**  Author(s):  novaprim3
#**
#**  Summary  :  Multi-Phantom Mod for Forged Alliance
#**
#****************************************************************************

do
	local ParentModBlueprints = ModBlueprints
	function ModBlueprints(blueprints)
		ParentModBlueprints(blueprints)

		# Make factory lights stay green
		for i, bp in blueprints.Unit do
			if bp.Display and bp.Display.BlinkingLightsFx then
				if bp.Display.BlinkingLightsFx.Green then
					for color, path in bp.Display.BlinkingLightsFx do
						bp.Display.BlinkingLightsFx[color] = bp.Display.BlinkingLightsFx.Green
					end
				else
					bp.Display.BlinkingLights = null
					bp.Display.BlinkingLightsFx = null
				end
			end
		end
	end
end
