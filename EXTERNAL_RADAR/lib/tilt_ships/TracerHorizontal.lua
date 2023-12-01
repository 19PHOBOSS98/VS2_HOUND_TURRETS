local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"
local path_utilities = require "lib.path_utilities"

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
local quaternion = quaternions.Quaternion--want to learn more about quaternions? here's a simple tutorial video by sociamix that should get you started: https://youtu.be/1yoFjjJRnLY
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
local generateHelix = path_utilities.generateHelix
local recenterStartToOrigin = path_utilities.recenterStartToOrigin
local offsetCoords = path_utilities.offsetCoords

local TracerHorizontal = TenThrusterTemplateHorizontal:subclass()

--overridden functions--
function TracerHorizontal:customRCProtocols(msg)
	
	local command = msg.cmd
	command = command and tonumber(command) or command
	case =
	{
	["step_thru_path"] = function (dir)
		if (dir>4) then
			self.tracker:scrollUp()
		else
			self.tracker:scrollDown()
		end
	end,
	["walk"] = function (arguments)
		self:setisWalk(arguments)
	end,
	default = function ( )
		print(textutils.serialize(command)) 
		print("customRCProtocols: default case executed")   
	end,
	}
	if case[command] then
	 case[command](msg.args)
	else
	 case["default"]()
	end
end

function TracerHorizontal:customPreFlightLoopBehavior() end

function TracerHorizontal:customFlightLoopBehavior()
	--[[
	useful variables to work with:
		self.target_global_position
		self.target_rotation
		self.rotation_error
		self.position_error
	]]--
	--term.clear()
	--term.setCursorPos(1,1)
	if(not self.radars.targeted_players_undetected) then
		if (self.rc_variables.run_mode) then
			if (self.spline_coords) then
				local tangent = self.spline_coords[self.tracker:getCurrentIndex()].gradient:normalize()
				local normal = self.spline_coords[self.tracker:getCurrentIndex()].normal
				
				self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveY(), normal)*self.target_rotation
				self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveZ(), tangent)*self.target_rotation
				
				self.target_global_position = self.spline_coords[self.tracker:getCurrentIndex()].pos
				
				local current_time = os.clock()
				self.count = self.count+(current_time - self.prev_time)

				if (self.count > 0.1) then
					self.count = 0
					if (self.rc_variables.walk) then
						self.tracker:scrollUp()
					end
				end
				self.prev_time = current_time
			end
		end
	end
end

function TracerHorizontal:setisWalk(mode)
	self.rc_variables.walk = mode
end

function TracerHorizontal:init(instance_configs)
	local waypoints = {}

	--sample demo--
	local h = generateHelix(10,3,2,15)
	recenterStartToOrigin(h)
	offsetCoords(h,vector.new(659,24,-66))

	local waypoint_length = #waypoints
	for i,coord in ipairs(h) do
		waypoints[i+waypoint_length] = {pos = coord}
	end
	--sample demo--
	
	waypoints = instance_configs.waypoints or waypoints
	if (#waypoints>3) then
		local loop_path = true
		self.ship_path = Path(waypoints,loop_path)
		self.spline_coords = self.ship_path:getNormalizedCoordsWithGradientsAndNormals(0.7,loop_path)
		self.tracker = IndexedListScroller()
		self.tracker:updateListSize(#self.spline_coords)									
		self.count = 0
		self.prev_time = os.clock()
	end
	
	instance_configs.ship_constants_config = instance_configs.ship_constants_config or {}
	instance_configs.ship_constants_config.DRONE_TYPE = instance_configs.ship_constants_config.DRONE_TYPE or "TRACER"
	
	instance_configs.rc_variables = instance_configs.rc_variables or 
	{
		walk = false,
	}
	
	TracerHorizontal.superClass.init(self,instance_configs)
end
--overridden functions--

return TracerHorizontal