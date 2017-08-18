local PhantomCode = import('../PhantomSim.lua')
local oldUnit = Unit

Unit = Class(oldUnit) {
    OnKilled = function(self, instigator, type, overkillRatio)
        if EntityCategoryContains(categories.COMMAND, self) then
            if instigator and instigator:GetArmy() ~= self:GetArmy() then
                -- Determine player types for those involved
    	        local killerType = 'innocent'

                if PhantomCode.IsPhantom(instigator:GetArmy()) then
                    killerType = 'phantom'
                end

                local victimType = 'innocent'
                if PhantomCode.IsPhantom(self:GetArmy()) then
                    victimType = 'phantom'
                end

                local instigatorBrain = ArmyBrains[instigator:GetArmy()]
                if instigatorBrain and killerType == 'innocent' and victimType == 'innocent' then
                    instigatorBrain:AddArmyStat("FAFLose", -2)
                end
    	    end
        end
        oldUnit.OnKilled(self, instigator, type, overkillRatio)
    end,

    SendNotifyMessage = function(self, trigger, source) -- Disable Notify
    end,
}
