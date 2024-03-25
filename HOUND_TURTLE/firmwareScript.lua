local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"
local HoundTurretBaseInfiniteAmmo = require "lib.tilt_ships.HoundTurretBaseInfiniteAmmo"
local HoundTurretBaseCreateVault = require "lib.tilt_ships.HoundTurretBaseCreateVault"

local instance_configs = {
	radar_config = {
		designated_ship_id = "3",
		designated_player_name="PHO",
		ship_id_whitelist={},
		player_name_whitelist={},
	},
	ship_constants_config = {
		DRONE_ID = 101,
		THRUSTER_TIER = 5,
		THRUSTER_TABLE_DIRECTORY = "./input_thruster_table/thruster_table.json",
		--[[
		PID_SETTINGS=
		{
			POS = {
				P = 4,
				I = 0,
				D = 5
			},
			ROT = {
				X = {
					P = 0.15,
					I = 0.08,
					D = 0.15
				},
				Y = {
					P = 0.04,
					I = 0.05,
					D = 0.05
				},
				Z = {
					P = 0.15,
					I = 0.08,
					D = 0.15
				}
			}
		},
		]]--
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
		orbit_offset = vector.new(7,5,10),
	},
}


local drone = HoundTurretBase(instance_configs)
drone:run()
