local PhantomCode = import('/mods/faf-phantomx/lua/PhantomSim.lua')
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

        if math.floor(self:GetArmyStat("FAFLose",0.0).Value) != -1 then
            self:AddArmyStat("FAFLose", -1)
        end
        
        
        local pType = 'innocent '
        if PhantomCode.IsPhantom(self:GetArmyIndex()) then
            pType = 'phantom '
        end
        

        local result = string.format("%s %i", pType.."defeat", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert( Sync.GameResult, { self:GetArmyIndex(), result } )

        # Score change, we send the score of all other players, yes mam !
        for index, brain in ArmyBrains do
            if brain and not brain:IsDefeated() then
                local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
                table.insert( Sync.GameResult, { index, result } )
            end
        end

        import('/lua/SimUtils.lua').UpdateUnitCap(self:GetArmyIndex())
        import('/lua/SimPing.lua').OnArmyDefeat(self:GetArmyIndex())

        local function KillArmy()
            local allies = {}
            local selfIndex = self:GetArmyIndex()
            WaitSeconds(10)
            -- this part determiens the share condition
            local shareOption = ScenarioInfo.Options.Share or "no"
            -- "no" means full share
            if shareOption == "no" then
                -- this part determines who the allies are
                for index, brain in ArmyBrains do
                    brain.index = index
                    brain.score = brain:CalculateScore()
                    if IsAlly(selfIndex, brain:GetArmyIndex()) and selfIndex ~= brain:GetArmyIndex() and not brain:IsDefeated() then
                        table.insert(allies, brain)
                    end
                end
                -- This part determines which ally has the highest score and transfers ownership of all units to him
                if table.getn(allies) > 0 then
                    table.sort(allies, function(a,b) return a.score > b.score end)
                    for k,v in allies do
                        local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL - categories.COMMAND, false)
                        if units and table.getn(units) > 0 then
                            TransferUnitsOwnership(units, v.index)
                        end
                    end
                end
            -- "yes" means share until death
            elseif shareOption == "yes" then
                import('/lua/SimUtils.lua').KillSharedUnits(self:GetArmyIndex())
                local units = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
                -- return borrowed units to their real owners
                local borrowed = {}
                for index,unit in units do
                    local oldowner = unit.oldowner
                    if oldowner and oldowner ~= self:GetArmyIndex() then
                        if not borrowed[oldowner] and not GetArmyBrain(oldowner):IsDefeated() then
                            borrowed[oldowner] = {}
                        end

                        if borrowed[oldowner] then
                            table.insert(borrowed[unit.oldowner], unit)
                        end
                    end
                end

                for owner, units in borrowed do
                    TransferUnitsOwnership(units, owner)
                end
            end

            WaitSeconds(0.1)

            local tokill = self:GetListOfUnits(categories.ALLUNITS - categories.WALL, false)
            if tokill and table.getn(tokill) > 0 then
                for index, unit in tokill do
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

        # Score change, we send the score of all other players, yes mam !
        for index, brain in ArmyBrains do
            if brain and not brain:IsDefeated() then
                local result = string.format("%s %i", "score", math.floor(brain:GetArmyStat("FAFWin",0.0).Value + brain:GetArmyStat("FAFLose",0.0).Value) )
                table.insert( Sync.GameResult, { index, result } )
            end
        end


    end

AIBrain.OnDraw = function(self)
        
        local pType = 'innocent '
        if PhantomCode.IsPhantom(self:GetArmyIndex()) then
            pType = 'phantom '
        end
        
        local result = string.format("%s %i", pType.."draw", math.floor(self:GetArmyStat("FAFWin",0.0).Value + self:GetArmyStat("FAFLose",0.0).Value) )
        table.insert(Sync.GameResult, { self:GetArmyIndex(), result })
    end
    