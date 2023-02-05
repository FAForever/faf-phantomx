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

actions.ShowHelp = function() import('/mods/faf-phantomx/modules/help_ui.lua').ShowPhantomXHelpDialog(GetFrame(0)) end
table.insert(menus.main.singlePlayer,  {action = 'ShowHelp', label = 'About Phantom-X', tooltip = ''})
table.insert(menus.main.replay,  {action = 'ShowHelp', label = 'About Phantom-X', tooltip = ''})
table.insert(menus.main.lan,  {action = 'ShowHelp', label = 'About Phantom-X', tooltip = ''})
table.insert(menus.main.gpgnet ,  {action = 'ShowHelp', label = 'About Phantom-X', tooltip = ''})
