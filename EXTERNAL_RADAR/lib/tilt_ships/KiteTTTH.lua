local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local TenThrusterTemplateHorizontal = require "lib.tilt_ships.TenThrusterTemplateHorizontal"

local Path = require "lib.paths.Path"

local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local min = math.min
local mod = math.fmod
local cos = math.cos
local sin = math.sin
local acos = math.acos
local pi = math.pi
local clamp = utilities.clamp
local sign = utilities.sign
local quadraticSolver = utilities.quadraticSolver
local getTargetAimPos = targeting_utilities.getTargetAimPos
local getQuaternionRotationError = flight_utilities.getQuaternionRotationError
local getLocalPositionError = flight_utilities.getLocalPositionError
local adjustOrbitRadiusPosition = flight_utilities.adjustOrbitRadiusPosition
local getPlayerLookVector = player_spatial_utilities.getPlayerLookVector
local getPlayerHeadOrientation = player_spatial_utilities.getPlayerHeadOrientation
local rotateVectorWithPlayerHead = player_spatial_utilities.rotateVectorWithPlayerHead
local PlayerVelocityCalculator = player_spatial_utilities.PlayerVelocityCalculator
local RadarSystems = targeting_utilities.RadarSystems
local TargetingSystem = targeting_utilities.TargetingSystem
local IntegerScroller = utilities.IntegerScroller
local IndexedListScroller = list_manager.IndexedListScroller

local KiteTTTH = TenThrusterTemplateHorizontal:subclass()

--overridden functions--
function KiteTTTH:getCustomSettings()
	return {
		rope_length = self:getRopeSlack(),
	}
end

function KiteTTTH:customRCProtocols(msg)
	local command = msg.cmd
	command = command and tonumber(command) or command
	case =
	{
	["override_rope_length"] = function (arguments)
		self:overrideRopeSlack(arguments.args)
	end,
	["set_rope_slack"] = function (dir)
		self:changeRopeSlack(dir)
	end,
	["set_settings"] = function (new_settings)
		self:setSettings(new_settings)
	end,
	["get_settings_info"] = function (args)
		self:transmitCurrentSettingsToController()
	end,
	["get_position_info"] = function (args)
		self:transmitCurrentPositionToController()
	end,
	["HUSH"] = function (args) --kill command
		self:resetRedstone()
		print("reseting redstone")
		self.run_firmware = false
	end,
	 default = function ( )
		print(textutils.serialize(command)) 
		print("customProtocols: default case executed")   
	end,
	}
	if case[command] then
	 case[command](msg.args)
	else
	 case["default"]()
	end
end

function KiteTTTH:customPreFlightLoopBehavior() end


function KiteTTTH:customFlightLoopBehavior()
	if (not self.radars.targeted_players_undetected) then
		local target_orbit = self.orbitTargeting.target.target_spatial
		self:debugProbe({orbit=self:getTargetMode(false)})
		if (self.rc_variables.run_mode) then
			local cur_player_sight_pos = target_orbit.orientation:localPositiveZ():add(target_orbit.position)
			local lead_vector = self.target_global_position:sub(self.ship_global_position):normalize()
			local turn_weight = clamp(self.position_error:length()/10,0,1)
			
			local forward_movement_vector = quaternion.slerpVector(self.ship_constants.WORLD_UP_VECTOR,lead_vector,turn_weight)
			self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveX(), forward_movement_vector:normalize())*self.target_rotation
			
			self.target_global_position = adjustOrbitRadiusPosition(cur_player_sight_pos,target_orbit.position,self.ropeSlack:get())
			local orbit_vector = self.target_global_position:sub(target_orbit.position)
			self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveZ(), orbit_vector:normalize())*self.target_rotation
		end
	end
end

function KiteTTTH:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}

	configs.ship_constants_config.DRONE_TYPE = configs.ship_constants_config.DRONE_TYPE or "KITE"
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	--ALTA--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
		x=vector.new(2224892.0495358976,-274292.0495358924,-9.094947017729282E-13),
		y=vector.new(-274292.0495358924,2224892.0495358976,-4.547473508864641E-13),
		z=vector.new(-9.094947017729282E-13,-4.547473508864641E-13,4351784.099071789)
	}
			
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
		x=vector.new(4.5639667859823465E-7,5.626609183137537E-8,1.0126357541287552E-25),
		y=vector.new(5.6266091831375346E-8,4.563966785982347E-7,5.945122438661804E-26),
		z=vector.new(1.0126357541287558E-25,5.945122438661799E-26,2.297908115922604E-7)
	}
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	
	configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED = configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED or 10000
			
	configs.ship_constants_config.THRUSTER_TIER = configs.ship_constants_config.THRUSTER_TIER or 1
			--these values are specific for the 10-thruster template--

	configs.ship_constants_config.PID_SETTINGS = configs.ship_constants_config.PID_SETTINGS or 
	{
		POS = {
			P = 5,
			I = 0,
			D = 4
		},
		ROT = {
			X = {
				P = 0.15,
				I = 0,
				D = 0.15
			},
			Y = {
				P = 0.15,
				I = 0,
				D = 0.15
			},
			Z = {
				P = 0.15,
				I = 0,
				D = 0.15
			}
		}
	}
	
	configs.radar_config = configs.radar_config or {}
	
	configs.radar_config.player_radar_box_size = 1000
	configs.radar_config.ship_radar_range = 500
	
	configs.rc_variables = configs.rc_variables or {}
	configs.rc_variables.orbit_offset = configs.rc_variables.orbit_offset or vector.new(0,0,0)
	
	self:initCustom()
	KiteTTTH.superClass.init(self,configs)
end
--overridden functions--

function KiteTTTH:initCustom(custom_config)
	self.ropeSlack = IntegerScroller(25,20,500)
	
	function KiteTTTH:changeRopeSlack(delta)
		self.ropeSlack:set(delta)
	end
	function KiteTTTH:getRopeSlack()
		return self.ropeSlack:get()
	end
	function KiteTTTH:overrideRopeSlack(new_value)
		self.ropeSlack:override(new_value)
	end
end

return KiteTTTH