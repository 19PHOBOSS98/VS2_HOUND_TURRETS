local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"

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


local HoundTurretDualRotary = HoundTurretBase:subclass()


--overridden functions--
function HoundTurretDualRotary:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1
	local seq_3 = step==2

	self:activateGun({"top",1,1},seq_1)
	self:activateGun({"top",2,1},seq_1)
	
	self:activateGun({"top",1,2},seq_2)
	self:activateGun({"top",2,2},seq_2)
	
	self:activateGun({"top",1,4},seq_3)
	self:activateGun({"top",2,4},seq_3)
end

function HoundTurretDualRotary:overrideShipFrameCustomThread()
	local htb = self
	function self.ShipFrame:customThread()
		sync_step = 0
		while self.run_firmware do
			if (htb.activate_weapons) then
				htb:alternateFire(sync_step)
				
				sync_step = math.fmod(sync_step+1,3)
			else
				htb:reset_guns()
			end
			os.sleep(htb.GUNS_COOLDOWN_DELAY)
		end
		htb:reset_guns()
	end
end

function HoundTurretDualRotary:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(143008.94760655132,2.2737367544323206E-13,0.0),
	y=vector.new(2.2737367544323206E-13,109380.0,2.2737367544323206E-13),
	z=vector.new(0.0,2.2737367544323206E-13,91948.94760655134)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(6.9925694632144065E-6,-1.45358037999924E-23,3.5944502047682913E-41),
	y=vector.new(-1.45358037999924E-23,9.142439202779302E-6,-2.2607654118535148E-23),
	z=vector.new(3.5944502047682877E-41,-2.260765411853514E-23,1.0875600276351072E-5)
	}
	--bare template--
	
	--steampunk skin, paste in firmwareScript.lua--
	--[[
	LOCAL_INERTIA_TENSOR = 
	{
		x=vector.new(293039.323259345,-9.094947017729282E-13,0.0),
		y=vector.new(-9.094947017729282E-13,207580.0,0.0),
		z=vector.new(0.0,0.0,212579.32325934505)
	}
	
	LOCAL_INV_INERTIA_TENSOR =
	{
		x=vector.new(3.4125112932880417E-6,1.4951637638432198E-23,-0.0),
		y=vector.new(1.4951637638432207E-23,4.817419789960497E-6,-0.0),
		z=vector.new(-0.0,-0.0,4.704126368772038E-6)
	}
	]]--
	--steampunk skin, paste in firmwareScript.lua--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretDualRotary.superClass.init(self,configs)

end

function HoundTurretDualRotary:overrideShipFrameCustomFlightLoopBehavior()
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
		
		if(not self.radars.targeted_players_undetected) then
			if (self.rc_variables.run_mode) then
				local target_aim = self.aimTargeting:getTargetSpatials()
				local target_orbit = self.orbitTargeting:getTargetSpatials()
				
				local target_aim_position = target_aim.position
				local target_aim_velocity = target_aim.velocity
				local target_aim_orientation = target_aim.orientation
				
				local target_orbit_position = target_orbit.position
				local target_orbit_orientation = target_orbit.orientation
				
				--Aiming
				local bullet_convergence_point = vector.new(0,1,0)
				if (self:getAutoAim()) then
					bullet_convergence_point = getTargetAimPos(target_aim_position,target_aim_velocity,self.ship_global_position,self.ship_global_velocity,htb.bullet_velocity_squared)
					
					--only fire when aim is close enough and if user says "fire"
					htb.activate_weapons = (self.rotation_error:length() < 0.5) and self.rc_variables.weapons_free  
					
					
				else	
				--Manual Aiming
					
					local aim_target_mode = self:getTargetMode(true)
					local orbit_target_mode = self:getTargetMode(false)
					
					local aim_z = vector.new()
					if (aim_target_mode == orbit_target_mode) then
						aim_z = target_orbit_orientation:localPositiveZ()
						bullet_convergence_point = target_orbit_position:add(aim_z:mul(htb.bulletRange:get()))
					else
						aim_z = target_aim_orientation:localPositiveZ()
						if (self.rc_variables.player_mounting_ship) then
							aim_z = target_orbit_orientation:rotateVector3(aim_z)
						end
						bullet_convergence_point = target_aim_position:add(aim_z:mul(htb.bulletRange:get()))
					end
					
					htb.activate_weapons = self.rc_variables.weapons_free
					
				end
				
				
				
				local aiming_vector = bullet_convergence_point:sub(self.ship_global_position):normalize()
				
				local aiming_left_vector = aiming_vector:cross(self.ship_constants.WORLD_UP_VECTOR):normalize()
				
				local gun_aim_vector = quaternion.fromRotation(self.target_rotation:localPositiveZ(), -45):rotateVector3(self.target_rotation:localPositiveY())
				
				self.target_rotation = quaternion.fromToRotation(gun_aim_vector,aiming_vector)*self.target_rotation
				
				local gun_left_vector = quaternion.fromRotation(self.target_rotation:localPositiveZ(), -45):rotateVector3(self.target_rotation:localPositiveX())
				
				self.target_rotation = quaternion.fromToRotation(gun_left_vector,aiming_left_vector)*self.target_rotation
				
							--positioning
				if (self.rc_variables.dynamic_positioning_mode) then
					if (self.rc_variables.hunt_mode) then
						self.target_global_position = adjustOrbitRadiusPosition(self.target_global_position,target_aim_position,15)
						--[[
						--position the drone behind target player's line of sight--
						local formation_position = aim_target.orientation:rotateVector3(vector.new(0,0,15))
						target_global_position = formation_position:add(aim_target.position)
						]]--
						
					else --guard_mode
						local formation_position = target_orbit_orientation:rotateVector3(self.rc_variables.orbit_offset)
						--self:debugProbe({target_orbit_position=target_orbit_position})
						self.target_global_position = formation_position:add(target_orbit_position)
					end
					
				end

				
				
			end
		else
			htb:reset_guns()
		end
		
	end

end
--overridden functions--


return HoundTurretDualRotary