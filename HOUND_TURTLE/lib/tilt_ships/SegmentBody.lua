local quaternion = require "lib.quaternions"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local utilities = require "lib.utilities"
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

local SegmentBody = TenThrusterTemplateHorizontal:subclass()

--overridden functions--
function SegmentBody:customPreFlightLoopBehavior()
	self.saved_alignment_vectors = {self.ship_rotation:localPositiveZ()}
end

function SegmentBody:customFlightLoopBehavior()
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
			local leader = self.orbitTargeting.target.target_spatial
			local actual_leader_orientation = quaternion.fromRotation(leader.orientation:localPositiveZ(),45)*leader.orientation
			
			local new_leader_left_vector = actual_leader_orientation:localPositiveZ()

			
			
			local chain_link_pos = leader.position + actual_leader_orientation:localPositiveX() * -self.rc_variables.gap_length
			
			self.target_global_position = adjustOrbitRadiusPosition(self.target_global_position,chain_link_pos,self.rc_variables.gap_length)
			
			table.insert(self.saved_alignment_vectors,1,new_leader_left_vector)

			if (#self.saved_alignment_vectors>self.rc_variables.segment_delay) then
				table.remove(self.saved_alignment_vectors)
			end
			
			
			if (self.position_error:length()<5) then
				
				local leader_left_vector = self.saved_alignment_vectors[#self.saved_alignment_vectors]
				local movement_vector = (chain_link_pos - self.ship_global_position):normalize()
				self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveZ(), leader_left_vector)*self.target_rotation
				self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveX(), movement_vector)*self.target_rotation
			end
		end

	end
end

function SegmentBody:setSegmentDelay(new_value)
	self.rc_variables.segment_delay = tonumber(new_value)
	self.saved_alignment_vectors = {self.ship_rotation:localPositiveZ()}
end
function SegmentBody:setGapLength(new_value)
	self.rc_variables.gap_length = tonumber(new_value)
end

function SegmentBody:customRCProtocols(msg)
	
	local command = msg.cmd
	command = command and tonumber(command) or command
	case =
	{
	["segment_delay"] = function (arguments)
		self:setSegmentDelay(arguments)
	end,
	["gap_length"] = function (arguments)
		self:setGapLength(arguments)
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

function SegmentBody:getCustomSettings()
	return {
		segment_delay = self.rc_variables.segment_delay,			
		gap_length = self.rc_variables.gap_length,
		group_id = self.rc_variables.group_id,
		segment_number = self.rc_variables.segment_number,
	}
end

function SegmentBody:init(instance_configs)
	
	
	instance_configs.ship_constants_config = instance_configs.ship_constants_config or {}
	
	instance_configs.ship_constants_config.DRONE_TYPE = instance_configs.ship_constants_config.DRONE_TYPE or "SEGMENT"
	
	
	instance_configs.rc_variables = instance_configs.rc_variables or 
	{
		segment_delay = 30,			
		gap_length = 10,
		group_id = "groupA",
		segment_number = 0,
	}

	
	SegmentBody.superClass.init(self,instance_configs)
end
--overridden functions--

return SegmentBody