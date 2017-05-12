skins.randomNoUEF ={
        default = "default",
        texturesPath = "/textures/ui/random",
        imagerMesh = "/meshes/game/map-border_squ_uef_mesh",
        imagerMeshHorz = "/meshes/game/map-border_hor_uef_mesh",
        bodyColor = "FFff0000",
        dialogCaptionColor = "FFffffff",
        dialogColumnColor = "FFff0000",
        dialogButtonColor = "FFff0000",
        dialogButtonFont = "Zeroes Three",
        factionTextColor = "FFff0000",
        factionBackColor = "FFffffff",
        highlightColor = "FF767676",
        disabledColor = "FF767676",
        tooltipBorderColor = "FF3b3b3b",
        tooltipTitleColor = "FF767676",
    }
    
local default = skins[skins.randomNoUEF.default]
while default do
    -- Copy the entire default chain into the toplevel skin.
    table.assimilate(skins.randomNoUEF, default)

    default = skins[default.default]
end
    
    
