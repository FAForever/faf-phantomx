local POriginalOnGameOver = OnGameOver
function OnGameOver()
   POriginalOnGameOver()
    --Re-enable diplomacy tab after death.
    --This way, players will be able to re-ally
    for i, tab in controls.tabs do
        if tab.Data.content == 'diplomacy' and SessionIsMultiplayer() then
            tab:Enable()
        end
    end
end