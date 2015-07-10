-- Fix to prevent phantoms from getting bonus from mass and energy that is given to an innocent
function GiveResourcesToPlayer(data)
	SendChatToReplay(data)
	if data.From != -1 then
		if not OkayToMessWithArmy(data.From) then
			return
		end
		local fromBrain = GetArmyBrain(data.From)
		local toBrain = GetArmyBrain(data.To)
		if fromBrain:IsDefeated() or toBrain:IsDefeated() then
			return
		end
		local massTaken = fromBrain:TakeResource('Mass',data.Mass * fromBrain:GetEconomyStored('Mass'))
		local energyTaken = fromBrain:TakeResource('Energy',data.Energy * fromBrain:GetEconomyStored('Energy'))
		toBrain:GiveResource('Mass',massTaken)
		toBrain:GiveResource('Energy',energyTaken)
		import('/lua/PhantomSim.lua').HandleResourceTransfer(data.From, data.To, massTaken, energyTaken)
	end
end
