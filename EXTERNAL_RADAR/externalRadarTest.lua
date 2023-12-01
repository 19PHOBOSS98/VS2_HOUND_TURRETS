local quaternion = require "lib.quaternions"

local aim_target = {
					orientation=quaternion.new(1,0,0,0),
					position=vector.new(-100,150,-175),
					velocity=vector.new(0,0,0)
					}

local orb_target = {
					orientation=quaternion.new(1,0,0,0),
					position=vector.new(-120,130,-175),
					velocity=vector.new(0,0,0)
					}

local modem = peripheral.find("modem", function(name, object) return object.isWireless() end)
local EXTERNAL_AIM_TARGETING_CHANNEL = 1009
local EXTERNAL_ORBIT_TARGETING_CHANNEL = 1010
local REPLY_DUMP_CHANNEL = 10000

local drone = 421
local drone_type = "TURRET"

print("TRANSMITTING TARGETs..")

function updateDroneAim()
	while true do
		modem.transmit(EXTERNAL_AIM_TARGETING_CHANNEL, REPLY_DUMP_CHANNEL, {DRONE_ID=drone,DRONE_TYPE=drone_type,trg=aim_target})
		os.sleep(0)
	end
end

function updateDroneOrbit()
	while true do
		modem.transmit(EXTERNAL_ORBIT_TARGETING_CHANNEL, REPLY_DUMP_CHANNEL, {DRONE_ID=drone,DRONE_TYPE=drone_type,trg=orb_target})	
		os.sleep(0)
	end
end

--remember HUNT Mode forces Auto-Aim Mode to activate

parallel.waitForAny(updateDroneAim,updateDroneOrbit)
