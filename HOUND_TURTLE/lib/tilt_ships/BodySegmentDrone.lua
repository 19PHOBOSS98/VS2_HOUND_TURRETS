local TenThrusterTemplateVerticalCompactSP = require "lib.tilt_ships.TenThrusterTemplateVerticalCompactSP"

local quaternion = require "lib.quaternions"

local Object = require "lib.object.Object"

local flight_utilities = require "lib.flight_utilities"

local BodySegmentDrone = Object:subclass()

--overridable functions--
function BodySegmentDrone:setShipFrameClass(configs) --override this to set ShipFrame Template
	self.ShipFrame = TenThrusterTemplateVerticalCompactSP(configs)
end
--overridable functions--

--custom--
--initialization:
function BodySegmentDrone:initializeShipFrameClass(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	configs.ship_constants_config.DRONE_TYPE = "SEGMENT"
	
	configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED = configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED or 10000
		
	configs.ship_constants_config.THRUSTER_TIER = configs.ship_constants_config.THRUSTER_TIER or 5

	configs.ship_constants_config.PID_SETTINGS = configs.ship_constants_config.PID_SETTINGS or
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
	}
	
	configs.radar_config = configs.radar_config or {}
	
	configs.radar_config.player_radar_box_size = configs.radar_config.player_radar_box_size or 50
	configs.radar_config.ship_radar_range = configs.radar_config.ship_radar_range or 500
	
	configs.rc_variables = configs.rc_variables or {}
	
	
	configs.rc_variables.run_mode = false

	self:setShipFrameClass(configs)
	--self.ShipFrame:setTargetMode(false,"SHIP")
	
end


function BodySegmentDrone:run()
	self.ShipFrame:run()
end

function BodySegmentDrone:setSegmentDelay(new_value)
	self.rc_variables.segment_delay = tonumber(new_value)
	self.saved_alignment_vectors = {self.ShipFrame.ship_rotation:localPositiveZ()}
end
function BodySegmentDrone:setGapLength(new_value)
	self.rc_variables.gap_length = tonumber(new_value)
end

--custom--


--overridden functions--
function BodySegmentDrone:overrideShipFrameCustomProtocols()
	local ptd = self
	function self.ShipFrame:customProtocols(msg)
		local command = msg.cmd
		command = command and tonumber(command) or command
		case =
		{
		["segment_delay"] = function (arguments)
			ptd:setSegmentDelay(arguments)
		end,
		["gap_length"] = function (arguments)
			ptd:setGapLength(arguments)
		end,
		["HUSH"] = function (args) --kill command
			self:resetRedstone()
			print("reseting redstone")
			self.run_firmware = false
		end,
		default = function ( )
			print(textutils.serialize(command)) 
			print("customHoundProtocols: default case executed")   
		end,
		}
		if case[command] then
		 case[command](msg.args)
		else
		 case["default"]()
		end
	end
end

function BodySegmentDrone:overrideShipFrameGetCustomSettings()
	local ptd = self
	function self.ShipFrame.remoteControlManager:getCustomSettings()
		return {
			segment_delay = ptd.rc_variables.segment_delay,
			gap_length = ptd.rc_variables.gap_length,
			group_id = ptd.rc_variables.group_id,
			segment_number = ptd.rc_variables.segment_number,
		}
	end
end

function BodySegmentDrone:overrideShipFrameCustomPreFlightLoopBehavior()
	local ptd = self
	function self.ShipFrame:customPreFlightLoopBehavior()
		ptd.saved_alignment_vectors = {self.ship_rotation:localPositiveZ()}
	end
end

function BodySegmentDrone:overrideShipFrameCustomFlightLoopBehavior()
	local ptd = self
	function self.ShipFrame:customFlightLoopBehavior()
		--[[
		useful variables to work with:
			self.target_global_position
			self.target_rotation
			self.rotation_error
			self.position_error
		]]--
		
		--term.clear()
		--term.setCursorPos(1,1)
				
		--self:debugProbe({"debugging drone: ",self.ship_constants.DRONE_ID})

		if (not self.remoteControlManager.rc_variables.run_mode) then
			return;
		end

		local leader = self.sensors.orbitTargeting:getTargetSpatials()
		local actual_leader_orientation = quaternion.fromRotation(leader.orientation:localPositiveZ(),45)*leader.orientation
		local new_leader_left_vector = actual_leader_orientation:localPositiveZ()
		
		local chain_link_pos = leader.position + actual_leader_orientation:localPositiveX() * -ptd.rc_variables.gap_length
		self.target_global_position = flight_utilities.adjustOrbitRadiusPosition(self.target_global_position,chain_link_pos,ptd.rc_variables.gap_length)

		table.insert(ptd.saved_alignment_vectors,1,new_leader_left_vector)

		if (#ptd.saved_alignment_vectors>ptd.rc_variables.segment_delay) then
			table.remove(ptd.saved_alignment_vectors)
		end

		if (self.position_error:length()<5) then
			local leader_left_vector = ptd.saved_alignment_vectors[#ptd.saved_alignment_vectors]
			local movement_vector = (chain_link_pos - self.ship_global_position):normalize()
			--self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveZ(), leader_left_vector)*self.target_rotation
			--self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveX(), movement_vector)*self.target_rotation
		end
	end
end


function BodySegmentDrone:initCustom(custom_config)
	self.rc_variables.segment_delay = custom_config.segment_delay or 30
	self.rc_variables.gap_length = custom_config.gap_length or 10
	self.rc_variables.group_id = custom_config.group_id or "groupA"
	self.rc_variables.segment_number = custom_config.segment_number or 0
end

function BodySegmentDrone:init(instance_configs)
	self:initializeShipFrameClass(instance_configs)
	
	self:overrideShipFrameCustomProtocols()
	self:overrideShipFrameGetCustomSettings()
	--self:overrideShipFrameOnResetRedstone()
	--self:addShipFrameCustomThread()
	self:overrideShipFrameCustomPreFlightLoopBehavior()
	self:overrideShipFrameCustomFlightLoopBehavior()

	body_segment_custom_config = instance_configs.body_segment_custom_config or {}

	self.rc_variables = instance_configs.rc_variables

	self:initCustom(body_segment_custom_config)
	BodySegmentDrone.superClass.init(self)
end
--overridden functions--




return BodySegmentDrone