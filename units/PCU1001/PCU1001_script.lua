#****************************************************************************
#**
#**  File     :  /cdimage/units/UAB1105/UAB1105_script.lua
#**  Author(s):  Jessica St. Croix
#**
#**  Summary  :  Custom Phantom Meteor Unit
#**
#**  Copyright � 2005 Gas Powered Games, Inc.  All rights reserved.
#****************************************************************************
local AEnergyStorageUnit = import('/lua/aeonunits.lua').AEnergyStorageUnit
local TerranWeaponFile = import('/lua/terranweapons.lua')
local TIFCommanderDeathWeapon = TerranWeaponFile.TIFCommanderDeathWeapon

PCU1001 = Class(AEnergyStorageUnit) {
	
    Weapons = {
        DeathWeapon = Class(TIFCommanderDeathWeapon) {},
        },
    OnStopBeingBuilt = function(self,builder,layer)
        AEnergyStorageUnit.OnStopBeingBuilt(self,builder,layer)
    end,

}

TypeClass = PCU1001