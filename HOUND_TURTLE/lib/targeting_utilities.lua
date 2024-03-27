local utilities = require "lib.utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local quaternion = require "lib.quaternions"
local list_manager = require "lib.list_manager"

local mod = math.fmod
local max = math.max

local getPlayerHeadOrientation = player_spatial_utilities.getPlayerHeadOrientation
local quadraticSolver = utilities.quadraticSolver
local IndexedListScroller = list_manager.IndexedListScroller

local pvc = player_spatial_utilities.PlayerVelocityCalculator()

targeting_utilities = {}

function targeting_utilities.getTargetAimPos(target_g_pos,target_g_vel,gun_g_pos,gun_g_vel,bullet_vel_sqr)--TargetingUtilities
	local target_relative_pos = target_g_pos:sub(gun_g_pos)
	local target_relative_vel = target_g_vel:sub(gun_g_vel)
	local a = (target_relative_vel:dot(target_relative_vel))-(bullet_vel_sqr)
	local b = 2 * (target_relative_pos:dot(target_relative_vel))
	local c = target_relative_pos:dot(target_relative_pos)

	local d,t1,t2 = quadraticSolver(a,b,c)
	local t = nil
	local target_global_aim_pos = target_g_pos
	
	if (d>=0) then
		t = (((t1*t2)>0) and (t1>0)) and min(t1,t2) or max(t1,t2)
		target_global_aim_pos = target_g_pos:add(target_g_vel:mul(t))
	end
	return target_global_aim_pos
end

function targeting_utilities.TargetSpatialAttributes()
	return{
		target_spatial = {	orientation = quaternion.new(1,0,0,0), 
							position = vector.new(0,0,0), 
							velocity = vector.new(0,0,0)},
		
		updateTargetSpatials = function(self,trg)--TargetingUtilities
			if (trg) then
				local so = trg.orientation
				local sp = trg.position
				local sv = trg.velocity

				self.target_spatial.orientation = quaternion.new(so[1],so[2],so[3],so[4])
				self.target_spatial.position = vector.new(sp.x,sp.y,sp.z)
				self.target_spatial.velocity = vector.new(sv.x,sv.y,sv.z)
			end
		end
	}
end

function targeting_utilities.TargetingSystem(
	external_targeting_system_channel,
	targeting_mode,
	auto_aim_active,
	use_external_radar,
	radarSystems,
	drone_id,
	drone_type
	)
	return{
		external_targeting_system_channel = external_targeting_system_channel,
		
		targeting_mode = targeting_mode,
		
		auto_aim_active = auto_aim_active,
		
		use_external_radar = use_external_radar,
		
		current_target = targeting_utilities.TargetSpatialAttributes(),
		
		radarSystems = radarSystems,
		
		drone_id = drone_id,
		
		drone_type = drone_type,
		
		TARGET_MODE = {"PLAYER","SHIP","ENTITY"},
		
		listenToExternalRadar = function(self)
			if (self.use_external_radar) then
				local _, _, senderChannel, _, message, _ = os.pullEvent("modem_message")
				--print(senderChannel,external_targeting_system_channel)
				if (senderChannel == external_targeting_system_channel) then
					if (self.drone_id == message.DRONE_ID and self.drone_type == message.DRONE_TYPE and message.trg) then
						--print(textutils.serialize(message.trg))
						self.current_target:updateTargetSpatials(message.trg)
						
					end
				end
				
			end
		end,
		
		getTargetSpatials = function(self)
			if (not self.use_external_radar) then
				local spatial_attributes = self.radarSystems:getRadarTarget(self.targeting_mode,self.auto_aim_active)
				if(spatial_attributes == nil and self.targeting_mode == self.TARGET_MODE[2]) then
					self.targeting_mode = self.TARGET_MODE[1]
					spatial_attributes = self.radarSystems:getRadarTarget(self.targeting_mode,self.auto_aim_active)
					
				end
				self.current_target:updateTargetSpatials(spatial_attributes)
			end
			
			return self.current_target.target_spatial
		end,
		
		setAutoAimActive = function(self,lock_true,mode)
			if (lock_true) then
				self.auto_aim_active = true
			else
				self.auto_aim_active = mode
			end
		end,
		
		getAutoAimActive = function(self)
			return self.auto_aim_active
		end,
		
		useExternalRadar = function(self,mode)
			self.use_external_radar = mode
		end,
		
		isUsingExternalRadar = function(self)
			return self.use_external_radar
		end,
		
		setTargetMode = function(self,mode)
			self.targeting_mode = mode
		end,
		getTargetMode = function(self)
			return self.targeting_mode
		end
		
		
	}
end

return targeting_utilities