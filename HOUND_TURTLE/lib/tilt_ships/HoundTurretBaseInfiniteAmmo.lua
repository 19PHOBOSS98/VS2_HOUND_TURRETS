local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"

local HoundTurretBaseInfiniteAmmo = HoundTurretBase:subclass()

--overridden functions--
function HoundTurretBaseInfiniteAmmo:init(instance_configs)
	self.idk = "¯\_(ツ)_/¯"
	HoundTurretBaseInfiniteAmmo.superClass.init(self,instance_configs)
end
--overridden functions--

return HoundTurretBaseInfiniteAmmo