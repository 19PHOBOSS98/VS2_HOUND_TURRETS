local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local pidcontrollers = require "lib.pidcontrollers"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"


local SensorsSP = require "lib.sensory.SensorsSP"

local DroneBaseClass = require "lib.tilt_ships.DroneBaseClass"


local DroneBaseClassSP = DroneBaseClass:subclass()


function DroneBaseClassSP:initSensors()
	self.sensors = SensorsSP()
end

return DroneBaseClassSP