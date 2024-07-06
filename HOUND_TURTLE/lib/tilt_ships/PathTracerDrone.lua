local TenThrusterTemplateVerticalCompactSP = require "lib.tilt_ships.TenThrusterTemplateVerticalCompactSP"

local quaternion = require "lib.quaternions"

local Object = require "lib.object.Object"

local IndexedListScroller = list_manager.IndexedListScroller

local PathTracerDrone = Object:subclass()

--overridable functions--
function PathTracerDrone:setShipFrameClass(configs) --override this to set ShipFrame Template
	self.ShipFrame = TenThrusterTemplateVerticalCompactSP(configs)
end

function PathTracerDrone:setCustomTargetRotationPathing(rotation,tangent,normal)
	local new_rotation = quaternion.fromToRotation(rotation:localPositiveZ(), vector.new(0,1,0))*rotation
	new_rotation = quaternion.fromToRotation(new_rotation:localPositiveY(), tangent)*new_rotation
		return new_rotation
end
--overridable functions--

--custom--
--initialization:
function PathTracerDrone:initializeShipFrameClass(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	configs.ship_constants_config.DRONE_TYPE = "TRACER"
	
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
	
	
end


function PathTracerDrone:run()
	self.ShipFrame:run()
end



--custom--


--overridden functions--
function PathTracerDrone:overrideShipFrameCustomProtocols()
	local ptd = self
	function self.ShipFrame:customProtocols(msg)
		local command = msg.cmd
		command = command and tonumber(command) or command
		case =
		{
		["walk"] = function (arguments)
			--print("setting walk ",arguments)
			ptd:setWalk(arguments)
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

function PathTracerDrone:overrideShipFrameGetCustomSettings()
	local ptd = self
	function self.ShipFrame.remoteControlManager:getCustomSettings()
		return {
			walk = ptd:walk(),
		}
	end
end


function PathTracerDrone:overrideShipFrameCustomFlightLoopBehavior()
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
				
		--self:debugProbe({auto_aim=self:getAutoAim()})
		--self:debugProbe({"yet running..."})
		if (not self.remoteControlManager.rc_variables.run_mode) then
			return;
		end
		--self:debugProbe({walk=ptd:walk()})
		if (not ptd.SPLINE_COORDS) then
			return;
		end

		local tangent = ptd.SPLINE_COORDS[ptd.tracker:getCurrentIndex()].gradient:normalize()
		local normal = ptd.SPLINE_COORDS[ptd.tracker:getCurrentIndex()].normal

		--rotation
		--self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveX(), normal)*self.target_rotation
		--self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveZ(), vector.new(0,1,0))*self.target_rotation
		--self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveY(), tangent)*self.target_rotation
		self.target_rotation = ptd:setCustomTargetRotationPathing(self.target_rotation,tangent,normal)

		--position
		self.target_global_position = ptd.SPLINE_COORDS[ptd.tracker:getCurrentIndex()].pos
		--self:debugProbe({tracker_idx = ptd.tracker:getCurrentIndex()})
		local current_time = os.clock()
		ptd.count = ptd.count+(current_time - ptd.prev_time)

		if (ptd.count > ptd.STEP_SPEED) then
			ptd.count = 0
			if (ptd.rc_variables.walk) then
				ptd.tracker:scrollUp()
			end
		end

		ptd.prev_time = current_time
	end
end

function PathTracerDrone:setWalk(mode)
	self.rc_variables.walk = mode
end

function PathTracerDrone:walk()
	return self.rc_variables.walk
end

function PathTracerDrone:initCustom(custom_config)
	self.SPLINE_COORDS = custom_config.SPLINE_COORDS or {}
	self.STEP_SPEED = custom_config.STEP_SPEED or 0.1
	self.tracker = IndexedListScroller()
	self.tracker:updateListSize(#self.SPLINE_COORDS)
	self.count = 0
	self.prev_time = os.clock()
end

function PathTracerDrone:init(instance_configs)
	self:initializeShipFrameClass(instance_configs)
	
	self:overrideShipFrameCustomProtocols()
	self:overrideShipFrameGetCustomSettings()
	--self:overrideShipFrameOnResetRedstone()
	--self:addShipFrameCustomThread()
	--self:overrideShipFrameCustomPreFlightLoopBehavior()
	self:overrideShipFrameCustomFlightLoopBehavior()

	path_tracer_custom_config = instance_configs.path_tracer_custom_config or {}

	self.rc_variables = instance_configs.rc_variables

	self:initCustom(path_tracer_custom_config)
	PathTracerDrone.superClass.init(self)
end
--overridden functions--




return PathTracerDrone