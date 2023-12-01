local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"
local TwelveThrusterTemplateVerticalCompact = require "lib.tilt_ships.TwelveThrusterTemplateVerticalCompact"

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


local HoundTurretQuadRotary = HoundTurretBase:subclass()


--overridden functions--
function HoundTurretQuadRotary:setShipFrameClass(configs) --override this to set ShipFrame Template
	self.ShipFrame = TwelveThrusterTemplateVerticalCompact(configs)
end

function HoundTurretQuadRotary:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1

	self:activateGun({"front",1,1},seq_1)
	self:activateGun({"front",2,1},seq_1)
	self:activateGun({"back",1,1},seq_1)
	self:activateGun({"back",2,1},seq_1)
	
	self:activateGun({"front",1,2},seq_2)
	self:activateGun({"front",2,2},seq_2)
	self:activateGun({"back",1,2},seq_2)
	self:activateGun({"back",2,2},seq_2)
end

function HoundTurretQuadRotary:overrideShipFrameCustomThread()
	local htb = self
	function self.ShipFrame:customThread()
		sync_step = 0
		while self.run_firmware do
			if (htb.activate_weapons) then
				htb:alternateFire(sync_step)
				
				sync_step = math.fmod(sync_step+1,2)
			else
				htb:reset_guns()
			end
			os.sleep(htb.GUNS_COOLDOWN_DELAY)
		end
		htb:reset_guns()
	end
end

function HoundTurretQuadRotary:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(162587.96838444512,4.547473508864641E-13,0.0),
	y=vector.new(4.547473508864641E-13,261200.0,1.1368683772161603E-13),
	z=vector.new(0.0,1.1368683772161603E-13,157787.96838444518)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(6.15051660917162E-6,-1.0708005875206713E-23,7.715159392195746E-42),
	y=vector.new(-1.0708005875206711E-23,3.828483920367534E-6,-2.7584373804355753E-24),
	z=vector.new(7.715159392195737E-42,-2.758437380435576E-24,6.3376188326573355E-6)
	}
	--bare template--
	
	--steampunk skin, paste in firmwareScript.lua--
	--[[
	LOCAL_INERTIA_TENSOR = 
	{
	x=vector.new(363679.29381836695,9.094947017729282E-13,0.0),
	y=vector.new(9.094947017729282E-13,421000.0,1.0231815394945443E-12),
	z=vector.new(0.0,1.0231815394945443E-12,358679.29381836683)
	},
	LOCAL_INV_INERTIA_TENSOR = 
	{
	x=vector.new(2.7496753788227273E-6,-5.9401785953319215E-24,1.694516852462093E-41),
	y=vector.new(-5.940178595331924E-24,2.375296912114014E-6,-6.775857968885637E-24),
	z=vector.new(1.6945168524620946E-41,-6.775857968885637E-24,2.788005935202923E-6)
	}
	]]--
	--steampunk skin, paste in firmwareScript.lua--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretQuadRotary.superClass.init(self,configs)
end
--overridden functions--

function HoundTurretQuadRotary:overrideShipFrameCustomFlightLoopBehavior()
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
					--self:debugProbe({rotation_error=self.rotation_error:length()})
					htb.activate_weapons = (self.rotation_error:length() < 10) and self.rc_variables.weapons_free  
					
					
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
				
				self.target_rotation = quaternion.fromToRotation(self.target_rotation:localPositiveY(),aiming_vector)*self.target_rotation
				
							--positioning
				if (self.rc_variables.dynamic_positioning_mode) then
					if (self.rc_variables.hunt_mode) then
						self.target_global_position = adjustOrbitRadiusPosition(self.target_global_position,target_aim_position,25)
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

return HoundTurretQuadRotary