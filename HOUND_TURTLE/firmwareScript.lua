local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"


local Path = require "lib.paths.Path"
local path_utilities = require "lib.path_utilities"

local instance_configs = {
	radar_config = {
		designated_ship_id = "14",
		designated_player_name="PHO",
		ship_id_whitelist={},
		player_name_whitelist={},
	},
	ship_constants_config = {
		--DRONE_ID = 202,
		DRONE_ID = ship.getId(),
		THRUSTER_TIER = 5,
		THRUSTER_TABLE_DIRECTORY = "./input_thruster_table/thruster_table.json",
		PID_SETTINGS=
		{
			POS = {
				P = 0.7,
				I = 0.001,
				D = 1
			},
			ROT = {
				X = {
					P = 0.04,
					I = 0.001,
					D = 0.05
				},
				Y = {
					P = 0.04,
					I = 0.001,
					D = 0.05
				},
				Z = {
					P = 0.05,
					I = 0.001,
					D = 0.05
				}
			}
		},
	},
	channels_config = {
		DEBUG_TO_DRONE_CHANNEL = 9,
		DRONE_TO_DEBUG_CHANNEL = 10,
		
		REMOTE_TO_DRONE_CHANNEL = 7,
		DRONE_TO_REMOTE_CHANNEL = 8,
		
		DRONE_TO_COMPONENT_BROADCAST_CHANNEL = 800,
		COMPONENT_TO_DRONE_CHANNEL = 801,
		
		EXTERNAL_AIM_TARGETING_CHANNEL = 1009,
		EXTERNAL_ORBIT_TARGETING_CHANNEL = 1010,
		EXTERNAL_GOGGLE_PORT_CHANNEL = 1011,
		REPLY_DUMP_CHANNEL = 10000,
	},
	rc_variables = {
		orbit_offset = vector.new(5,5,5),
	},
	body_segment_custom_config = {
		segment_delay = 5,
		gap_length = 4,
	},
	hound_custom_config = {
		ALTERNATING_FIRE_SEQUENCE_COUNT = 2,
		--GUNS_COOLDOWN_DELAY = 0.2,
	},
}


repulsor = peripheral.find("opencu:repulsor")

repulsor.recalibrateByIdx(1)
repulsor.setRadius(5)
repulsor.setForce(1)
repulsor.setVector(0,140,0)

local drone = HoundTurretBase(instance_configs)

function drone:getProjectileSpeed()
	return 140
end

local laserOn = false
function activateLaser()
	if(not laserOn) then
		redstone.setOutput("right",false)
		redstone.setOutput("left",true)
		os.sleep(0.1)
		redstone.setOutput("left",false)
		laserOn = true
	end
end

function deactivateLaser()
	if(laserOn) then
		redstone.setOutput("left",false)
		redstone.setOutput("right",true)
		os.sleep(0.1)
		redstone.setOutput("right",false)
		laserOn = false
	end
end

function drone:onGunsActivation()
	repulsor.pulse(0,0,0)
	activateLaser()
end

function drone:onGunsDeactivation()
	deactivateLaser()
end

function drone:alternateFire(step)
	local seq_1 = step==0
	-- local seq_2 = step==1
	-- local seq_3 = step==2
	--{modem_block, redstoneIntegrator_side}
	
	-- self:activateAllGuns({"front","front"},seq_1)
	-- self:activateAllGuns({"front","right"},seq_1)
	-- self:activateAllGuns({"front","left"},seq_2)
	-- self:activateAllGuns({"front","top"},seq_3)

	self:activateAllGuns({"front","front"},seq_1)
	self:activateAllGuns({"front","right"},seq_1)
	self:activateAllGuns({"front","left"},seq_1)
	self:activateAllGuns({"front","top"},seq_1)
end

drone:run()