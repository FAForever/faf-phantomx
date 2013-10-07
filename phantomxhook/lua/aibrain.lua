local PhantomCode = import('PhantomSim.lua')
local onDefeatRunTracking = {}

AIBrain.OnDefeat = function(self)
		##For Sorian AI
		if self.BrainType == 'AI' then
			SUtils.AISendChat('enemies', ArmyBrains[self:GetArmyIndex()].Nickname, 'ilost')
		end
		local per = ScenarioInfo.ArmySetup[self.Name].AIPersonality
		if string.find(per, 'sorian') then
			SUtils.GiveAwayMyCrap(self)
		end
		###end sorian AI bit
		
		SetArmyOutOfGame(self:GetArmyIndex())
		
		# seems that FA send the OnDeath twice : one when losing, the other when disconnecting. But we only want it one time !
		if IsFirstOnDefeatRun(self:GetArmyIndex()) then
			table.insert(onDefeatRunTracking, self:GetArmyIndex())
			self:AddArmyStat("FAFLose", -1)
		end
		
		
		local pType = 'innocent '
		if PhantomCode.IsPhantom(self:GetArmyIndex()) then
			pType = 'phantom '
		end
		
        local result = string.format("%s %i", pType.."defeat", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
		table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )
		
		SyncScoreTable()
		
		
        import('/lua/SimUtils.lua').UpdateUnitCap()
        import('/lua/SimPing.lua').OnArmyDefeat(self:GetArmyIndex())
        local function KillArmy()
			local allies = {}
			local selfIndex = self:GetArmyIndex()
            WaitSeconds(20)
			
			#this part determiens the share condition			
			local shareOption = ScenarioInfo.Options.Share or "no"
			##"no" means full share
			if shareOption == "no" then			
				##this part determines who the allies are 
				for index, brain in ArmyBrains do
					brain.index = index
					brain.score = brain:CalculateScore()
					if IsAlly(selfIndex, brain:GetArmyIndex()) and selfIndex != brain:GetArmyIndex() and not brain:IsDefeated() then
						table.insert(allies, brain)
					end
				end
				##This part determines which ally has the highest score and transfers ownership of all units to him
				if table.getn(allies) > 0 then
					table.sort(allies, function(a,b) return a.score > b.score end)
					for k,v in allies do				
						local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
						if units and table.getn(units) > 0 then
							TransferUnitsOwnership(units, v.index)
						end
					end
				end			
			##"yes" means share until death
			elseif shareOption == "yes" then
				import('/lua/SimUtils.lua').KillSharedUnits(self:GetArmyIndex())
				local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
				for index,unit in units do
					if unit.oldowner and unit.oldowner != self:GetArmyIndex() then
						TransferUnitsOwnership(unit, unit.oldowner)
					else
						unit:Kill()
					end
				end
			end

			local killacu = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
			if killacu and table.getn(killacu) > 0 then
				for index,unit in killacu do
					unit:Kill()
				end
			end
        end
        ForkThread(KillArmy)
		##For Sorian AI bit 2
		if self.BuilderManagers then
			self.ConditionsMonitor:Destroy()
            for k,v in self.BuilderManagers do
				v.EngineerManager:SetEnabled(false)
				v.FactoryManager:SetEnabled(false)
				v.PlatoonFormManager:SetEnabled(false)
				v.StrategyManager:SetEnabled(false)
				v.FactoryManager:Destroy()
                v.PlatoonFormManager:Destroy()
                v.EngineerManager:Destroy()
                v.StrategyManager:Destroy()
            end
        end
        if self.Trash then
            self.Trash:Destroy()
        end
		###end Sorian AI bit 2
    end

AIBrain.OnVictory = function(self)
		self:AddArmyStat("FAFWin", 5) 
		
		local pType = 'innocent '
		if PhantomCode.IsPhantom(self:GetArmyIndex()) then
			pType = 'phantom '
		end
		
	   	local result = string.format("%s %i", pType.."victory", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )
        
		SyncScoreTable()
    end

AIBrain.OnDraw = function(self)
		
		local pType = 'innocent '
		if PhantomCode.IsPhantom(self:GetArmyIndex()) then
			pType = 'phantom '
		end
		
    	local result = string.format("%s %i", pType.."draw", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert(Sync.GameResult, { self:GetArmyIndex(), result })
    end
    
function SyncScoreTable()
	# Score change...so, send the score of all other players!
	for index, brain in ArmyBrains do
		if brain and not brain:IsDefeated() then
			local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
			table.insert( Sync.GameResult, { index, result } )
		end
	end
end


function IsFirstOnDefeatRun(armyIdx)
	for index, army in onDefeatRunTracking do
		if army == armyIdx then
			return false
		end
	end
	return true
end