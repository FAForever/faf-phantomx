local PhantomOriginalDoGameResult = DoGameResult

function DoGameResult(armyIndex, result)
	local newResult = result
	local leadTag = ''
	
	local condPos = string.find(result, " ")
	if condPos != 0 then
		leadTag = string.sub(result, 1, condPos - 1)
	end
	
	if leadTag != 'score' then
		LOG("PHANTOMGAMERESULT : ", result)
		local condPos2 = string.find(result, " ")
		if condPos2 != 0 then
			newResult = string.sub(result, condPos2 + 1)
		end
	end
	PhantomOriginalDoGameResult(armyIndex, newResult)
end