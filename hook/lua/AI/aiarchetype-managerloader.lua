local PhantomX_ExecutePlan = ExecutePlan

function ExecutePlan(aiBrain)
	PhantomX_ExecutePlan(aiBrain)
    aiBrain:SetResourceSharing(false)
end