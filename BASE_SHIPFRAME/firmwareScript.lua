local HoundTurretBaseCreateVault = require "lib.tilt_ships.HoundTurretBaseCreateVault"

local HoundTurretCreateVault8Barrel = require "lib.tilt_ships.HoundTurretCreateVault8Barrel"
local HoundTurretCreateVault12Barrel = require "lib.tilt_ships.HoundTurretCreateVault12Barrel"
local HoundTurretCreateVault16Barrel = require "lib.tilt_ships.HoundTurretCreateVault16Barrel"

local HoundTurretBaseInfiniteAmmo = require "lib.tilt_ships.HoundTurretBaseInfiniteAmmo"
local HoundTurretInfiniteAmmo8Barrel = require "lib.tilt_ships.HoundTurretInfiniteAmmo8Barrel"
local HoundTurretInfiniteAmmo12Barrel = require "lib.tilt_ships.HoundTurretInfiniteAmmo12Barrel"
local HoundTurretInfiniteAmmo16Barrel = require "lib.tilt_ships.HoundTurretInfiniteAmmo16Barrel"


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
		--[[PID_SETTINGS=
		{
			POS = {
				P = 5,
				I = 0,
				D = 4
			},
			ROT = {
				X = {
					P = 0.15,
					I = 0.15,
					D = 0.1
				},
				Y = {
					P = 0.15,
					I = 0.15,
					D = 0.1
				},
				Z = {
					P = 0.15,
					I = 0.15,
					D = 0.1
				}
			}
		},]]--
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


local drone = HoundTurretCreateVault16Barrel(instance_configs)
drone:run()
