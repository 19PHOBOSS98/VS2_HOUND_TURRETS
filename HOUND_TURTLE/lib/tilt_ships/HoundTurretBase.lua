local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local TenThrusterTemplateVerticalCompactSP = require "lib.tilt_ships.TenThrusterTemplateVerticalCompactSP"
local Object = require "lib.object.Object"

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
local NonBlockingCooldownTimer = utilities.NonBlockingCooldownTimer
local IndexedListScroller = list_manager.IndexedListScroller


local HoundTurretBase = Object:subclass()

--overridable functions--
function HoundTurretBase:setShipFrameClass(configs) --override this to set ShipFrame Template
	self.ShipFrame = TenThrusterTemplateVerticalCompactSP(configs)
end

function HoundTurretBase:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1
	--{modem_block, redstoneIntegrator_side}
	self:activateAllGuns({"front","right"},seq_1)
	self:activateAllGuns({"front","back"},seq_2)
end

function HoundTurretBase:CustomThreads()
	local htb = self
	local threads = {
		function()--synchronize guns
			sync_step = 0
			while self.ShipFrame.run_firmware do
				
				if (htb.activate_weapons) then
					htb:alternateFire(sync_step)
					
					sync_step = math.fmod(sync_step+1,htb.ALTERNATING_FIRE_SEQUENCE_COUNT)
				else
					htb:reset_guns()
				end
				os.sleep(htb.GUNS_COOLDOWN_DELAY)
			end
			htb:reset_guns()
		end,
	}
	return threads
end

function HoundTurretBase:getProjectileSpeed()
	--based on create-big-cannons auto-cannons
	AUTOCANNON_BARREL_LENGTH = 7 --the recoil block counts as a barrel
	bulletSpeed = AUTOCANNON_BARREL_LENGTH/0.05 --blocks per sec
	return bulletSpeed
end

function HoundTurretBase:onGunsActivation() end

function HoundTurretBase:onGunsDeactivation() end

--overridable functions--

--custom--
--initialization:
function HoundTurretBase:initializeShipFrameClass(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	configs.ship_constants_config.DRONE_TYPE = "TURRET"
	
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
	
	configs.rc_variables.orbit_offset = configs.rc_variables.orbit_offset or vector.new(0,0,0)
	configs.rc_variables.run_mode = false
	configs.rc_variables.dynamic_positioning_mode = false
	configs.rc_variables.player_mounting_ship = false
	configs.rc_variables.weapons_free = false--activate to fire cannons
	configs.rc_variables.hunt_mode = false--activate for the drone to follow what it's aiming at, force-activates auto_aim if set to true
	configs.rc_variables.range_finding_mode = 3--1:manual ; 2:auto ; 3:auto-external
	self:setShipFrameClass(configs)
	
	
end

function HoundTurretBase:initCustom(custom_config)
	self:initializeGunPeripherals()
	self.ALTERNATING_FIRE_SEQUENCE_COUNT = custom_config.ALTERNATING_FIRE_SEQUENCE_COUNT or 2
	self.GUNS_COOLDOWN_DELAY = custom_config.GUNS_COOLDOWN_DELAY or 0.05 --in seconds
	self.activate_weapons = false

	self.PROJECTILE_SPEED = self.getProjectileSpeed()

	self.bulletRange = IntegerScroller(100,15,300)
	function HoundTurretBase:changeBulletRange(delta)
		self.bulletRange:set(delta)
	end
	function HoundTurretBase:getBulletRange()
		return self.bulletRange:get()
	end
	function HoundTurretBase:overrideBulletRange(new_value)
		self.bulletRange:override(new_value)
	end
end

function HoundTurretBase:initializeGunPeripherals()
	self.gun_component_map = {
		"front",
		"left",
		"back",
		"right"
	}
	
	self.hub1 = peripheral.find("peripheral_hub",function(name,object) return name == "top" end)
	self.hub2 = peripheral.find("peripheral_hub",function(name,object) return name == "bottom" end)
	self.hub3 = peripheral.find("peripheral_hub",function(name,object) return name == "front" end)
	self.hub4 = peripheral.find("peripheral_hub",function(name,object) return name == "back" end)
	self.gun_controllers_hub = {}
	
	if(self.hub1) then
		self.gun_controllers_hub["top"] = {peripheral.find("redstoneIntegrator",
											function(name,object) 
												for i,list_name in ipairs(self.hub1.getNamesRemote()) do
													if (list_name == name) then
														return true
													end
												end
												return false
											end)}
	end
	
	if(self.hub2) then
		self.gun_controllers_hub["bottom"] = {peripheral.find("redstoneIntegrator",
											function(name,object) 
												for i,list_name in ipairs(self.hub2.getNamesRemote()) do
													if (list_name == name) then
														return true
													end
												end
												return false
											end)}
	end
	
	if(self.hub3) then
		self.gun_controllers_hub["front"] = {peripheral.find("redstoneIntegrator",
											function(name,object) 
												for i,list_name in ipairs(self.hub3.getNamesRemote()) do
													if (list_name == name) then
														return true
													end
												end
												return false
											end)}
	end
	
	if(self.hub4) then
		self.gun_controllers_hub["back"] = {peripheral.find("redstoneIntegrator",
											function(name,object) 
												for i,list_name in ipairs(self.hub4.getNamesRemote()) do
													if (list_name == name) then
														return true
													end
												end
												return false
											end)}
	end
end

function HoundTurretBase:addShipFrameCustomThread()
	for k,thread in pairs(self:CustomThreads()) do
		table.insert(self.ShipFrame.threads,thread)
	end
end

function HoundTurretBase:run()
	self.ShipFrame:run()
end


--setters and getters:
function HoundTurretBase:setWeaponsFree(mode)
	self.ShipFrame.remoteControlManager.rc_variables.weapons_free = mode
end

function HoundTurretBase:setHuntMode(mode)
	self.ShipFrame.remoteControlManager.rc_variables.hunt_mode = mode
	self.ShipFrame:setAutoAim(self.ShipFrame:getAutoAim())
end

function HoundTurretBase:getHuntMode()
	return self.ShipFrame.remoteControlManager.rc_variables.hunt_mode
end

function HoundTurretBase:setRangeFindingMode(mode)
	self.ShipFrame.remoteControlManager.rc_variables.range_finding_mode = mode
	local external = mode==3
	self.ShipFrame.sensors:useExternalRangeGoggle(external)
end

function HoundTurretBase:getRangeFindingMode()
	return self.ShipFrame.remoteControlManager.rc_variables.range_finding_mode
end

function HoundTurretBase:getGoggleRange()
	return self.ShipFrame.sensors:getGoggleRange()
end

function HoundTurretBase:getManualRange(mode)
	if(mode==1) then
		return self:getBulletRange()
	else
		return self:getGoggleRange()
	end
end


--redstone:
function HoundTurretBase:reset_guns()
	for key,hub in pairs(self.gun_controllers_hub) do
		for i,cntr in ipairs(hub) do
			cntr.setOutput("north",false)
			cntr.setOutput("south",false)
			cntr.setOutput("east",false)
			cntr.setOutput("west",false)
		end
	end
	self:onGunsDeactivation()
end

function HoundTurretBase:activateGun(index,toggle)
	--index={modem_block, redstoneIntegrator_index, redstoneIntegrator_side}
	self.gun_controllers_hub[index[1]]
		[index[2]]
			.setOutput(
				index[3],toggle)
end

function HoundTurretBase:activateAllGuns(index,toggle)
	--index={modem_block, redstoneIntegrator_side}
	for _,gun in pairs(self.gun_controllers_hub[index[1]]) do
		gun.setOutput(index[2],toggle)
	end
	self:onGunsActivation()
end

--custom--


--overridden functions--
function HoundTurretBase:overrideShipFrameCustomProtocols()
	local htb = self
	function self.ShipFrame:customProtocols(msg)
		local command = msg.cmd
		command = command and tonumber(command) or command
		case =
		{
		["set_range_finding_mode"] = function (arguments)--1:manual ; 2:auto ; 3:auto-external
			htb:setRangeFindingMode(arguments.mode)
		end,
		["override_bullet_range"] = function (arguments)
			htb:overrideBulletRange(arguments.args)
		end,
		["scroll_bullet_range"] = function (arguments)
			htb:changeBulletRange(arguments.args)
		end,
		["hunt_mode"] = function (args)
			htb:setHuntMode(args)
		end,
		["burst_fire"] = function (arguments)
			htb:setWeaponsFree(arguments.mode)
		end,
		["weapons_free"] = function (arguments)
			htb:setWeaponsFree(arguments.args)
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

function HoundTurretBase:overrideShipFrameGetCustomSettings()
	local htb = self
	function self.ShipFrame.remoteControlManager:getCustomSettings()
		return {
			hunt_mode = htb:getHuntMode(),
			bullet_range = htb:getBulletRange(),
			range_finding_mode = htb:getRangeFindingMode(),
		}
	end
end

function HoundTurretBase:overrideShipFrameOnResetRedstone()
	local htb = self
	function self.ShipFrame:onResetRedstone()
		htb:reset_guns()
	end
end

function HoundTurretBase:overrideShipFrameCustomPreFlightLoopBehavior()
	local htb = self
	function self.ShipFrame:customPreFlightLoopBehavior()
		local bullet_velocity = htb.PROJECTILE_SPEED
		htb.bullet_velocity_squared = bullet_velocity*bullet_velocity
		htb:setHuntMode(self.remoteControlManager.rc_variables.hunt_mode)	--forces auto_aim to activate if hunt_mode is set to true on initialization
														--toggle it on runtime as you wish
	end
end

function HoundTurretBase:overrideShipFrameCustomFlightLoopBehavior()
	local htb = self
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
		
		if(self.sensors.radars.targeted_players_undetected) then
			htb:reset_guns()
		end
			
		if (self.remoteControlManager.rc_variables.run_mode) then
			local target_aim = self.sensors.aimTargeting:getTargetSpatials()
			local target_orbit = self.sensors.orbitTargeting:getTargetSpatials()
			
			local target_aim_position = target_aim.position
			local target_aim_velocity = target_aim.velocity
			local target_aim_orientation = target_aim.orientation
			
			local target_orbit_position = target_orbit.position
			local target_orbit_orientation = target_orbit.orientation
			
			
			--self:debugProbe({target_orbit_position=target_orbit_position,target_orbit_orientation=target_orbit_orientation})
			--Aiming
			local bullet_convergence_point = vector.new(0,1,0)
			if (self.sensors.aimTargeting:isUsingExternalRadar()) then
				bullet_convergence_point = getTargetAimPos(target_aim_position,target_aim_velocity,self.ship_global_position,self.ship_global_velocity,htb.bullet_velocity_squared)
				htb.activate_weapons = (self.rotation_error:length() < 10) and self.remoteControlManager.rc_variables.weapons_free
			else
				if (self:getAutoAim()) then
					bullet_convergence_point = getTargetAimPos(target_aim_position,target_aim_velocity,self.ship_global_position,self.ship_global_velocity,htb.bullet_velocity_squared)
					--only fire when aim is close enough and if user says "fire"
					htb.activate_weapons = (self.rotation_error:length() < 10) and self.remoteControlManager.rc_variables.weapons_free  
				else	
				--Manual Aiming
					
					local aim_target_mode = self:getTargetMode(true)
					local orbit_target_mode = self:getTargetMode(false)
					
					local aim_z = vector.new()
					
					local range = htb:getManualRange(htb:getRangeFindingMode())
					--self:debugProbe({range=range})
					if (aim_target_mode == orbit_target_mode) then
						--print("range: ",range)
						aim_z = target_orbit_orientation:localPositiveZ()
						
						bullet_convergence_point = target_orbit_position:add(aim_z:mul(range))
					else
						aim_z = target_aim_orientation:localPositiveZ()
						if (self.remoteControlManager.rc_variables.player_mounting_ship) then
							aim_z = target_orbit_orientation:rotateVector3(aim_z)
						end
						bullet_convergence_point = target_aim_position:add(aim_z:mul(range))
					end
					
					htb.activate_weapons = self.remoteControlManager.rc_variables.weapons_free
					
				end
			end
			
			local aiming_vector = bullet_convergence_point:sub(self.ship_global_position):normalize()

			self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveY(),aiming_vector)*self.target_rotation
			
			--positioning
			if (self.remoteControlManager.rc_variables.dynamic_positioning_mode) then
			--[[self:debugProbe({
					target_global_position=self.target_global_position,
					target_aim_position=target_aim_position})]]--
				if (self.remoteControlManager.rc_variables.hunt_mode) then
					
					
				
					self.target_global_position = adjustOrbitRadiusPosition(self.target_global_position,target_aim_position,25)
					
					
					--[[
					--position the drone behind target player's line of sight--
					local formation_position = aim_target.orientation:rotateVector3(vector.new(0,0,25))
					target_global_position = formation_position:add(aim_target.position)
					]]--
					
				else --guard_mode
					local formation_position = target_orbit_orientation:rotateVector3(self.remoteControlManager.rc_variables.orbit_offset)
					--self:debugProbe({target_orbit_position=target_orbit_position,target_aim_position=target_aim_position})
					self.target_global_position = formation_position:add(target_orbit_position)
				end
			end
		end

	end
end

function HoundTurretBase:init(instance_configs)
	self:initializeShipFrameClass(instance_configs)
	
	self:overrideShipFrameCustomProtocols()
	self:overrideShipFrameGetCustomSettings()
	self:overrideShipFrameOnResetRedstone()
	self:addShipFrameCustomThread()
	self:overrideShipFrameCustomPreFlightLoopBehavior()
	self:overrideShipFrameCustomFlightLoopBehavior()

	hound_custom_config = instance_configs.hound_custom_config or {}

	self:initCustom(hound_custom_config)
	HoundTurretBase.superClass.init(self)
end
--overridden functions--




return HoundTurretBase