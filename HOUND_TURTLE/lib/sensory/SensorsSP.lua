local targeting_utilities = require "lib.targeting_utilities"
local quaternion = require "lib.quaternions"
local player_spatial_utilities = require "lib.player_spatial_utilities"


--local ShipReader = require "lib.sensory.ShipReaderSP"
local ShipReader = require "lib.sensory.ShipReader2"
local SomePeripheralsRadar = require "lib.sensory.SomePeripheralsRadar"
local SomePeripheralsGoggle = require "lib.sensory.SomePeripheralsGoggle"

local Sensors = require "lib.sensory.Sensors"

local RadarSystems = targeting_utilities.RadarSystems
local TargetingSystem = targeting_utilities.TargetingSystem
local getPlayerHeadOrientation = player_spatial_utilities.getPlayerHeadOrientation

local SensorsSP = Sensors:subclass()


function SensorsSP:init(configs)
	SensorsSP.superClass.init(self)
	
	--self.shipReader = ShipReaderSP()
	self.shipReader = ShipReader()
	self.radar = SomePeripheralsRadar()
	self.goggle = SomePeripheralsGoggle(configs)

end

function SensorsSP:getInertiaTensors()
	return self.shipReader:getInertiaTensors()
end

function SensorsSP:customUpdateLoop()
	self.goggle:listenToExternalPort()
end

function SensorsSP:useExternalRangeGoggle(mode)
	self.goggle:useExternal(mode)
end

function SensorsSP:isUsingExternalRangeGoggle()
	return self.goggle:isUsingExternal()
end

function SensorsSP:getGoggleRange()
	return self.goggle:getDistance()
end

function SensorsSP:RadarSystems(radar_arguments)
	local sens = self
	local radarSystem = {
		
		targeting = sens.radar:Targeting(radar_arguments),
		
		targeted_ships_undetected = false,
		targeted_players_undetected = false,
		targeted_mobs_undetected = false,
		
		targeting_table_update_threads = {},		
		
		getRadarTarget = function(self,trg_mode,args)
			case =
				{
				["SHIP"] = function (is_auto_aim)
								local ship = self.targeting:getShipTarget(is_auto_aim)
								if (ship) then
									self.targeted_ships_undetected = false
									local target_rot = ship.rotation
									return {orientation=quaternion.new(target_rot.w,target_rot.x,target_rot.y,target_rot.z),
											position=ship.pos,
											velocity=ship.velocity}
								end
								self.targeted_ships_undetected = true
								return nil
							end,
							
				["PLAYER"] = function (is_auto_aim)
								player = self.targeting:getPlayerTarget(is_auto_aim)
								if (player) then
									self.targeted_players_undetected = false
									local eye_position = player.eye_pos
									local current_position = vector.new(eye_position[1],
																		eye_position[2],
																		eye_position[3])
									
				
									return {orientation=getPlayerHeadOrientation({yaw=player.yHeadRot,pitch=player.xRot}),
											position=current_position,
											velocity=sens.pvc:getVelocity(current_position)}
								end								
								self.targeted_players_undetected = true
								return nil
							end,
							
				["MOB"] = function (arguments)
								mob = self.targeting:getMobTarget()
								
								if (mob and next(mob) ~= nil) then
									self.targeted_mobs_undetected = false
									local eye_position = mob.eye_pos
									local current_position = vector.new(eye_position[1],
																		eye_position[2],
																		eye_position[3])
									
									local look_vector = vector.new(	mob.look_angle[1],
																	mob.look_angle[2],
																	mob.look_angle[3])
									
									return {orientation=quaternion.fromToRotation(vector.new(0,0,1),look_vector),
											position=current_position,
											velocity=sens.mvc:getVelocity(current_position)}
								end								
								self.targeted_mobs_undetected = true
								return nil
							end,
				
				 default = function (arguments)
							print("getRadarTarget: default case executed")   
							return nil
						end,
				}
				if case[trg_mode] then
					return case[trg_mode](args)
				else
					return case["default"](args)
				end
		end,
		scrollUpShipTargets = function(self)
			self.targeting.shipListScroller:scrollUp()
		end,
		scrollDownShipTargets = function(self)
			self.targeting.shipListScroller:scrollDown()
		end,
		scrollUpPlayerTargets = function(self)
			self.targeting.playerListScroller:scrollUp()
		end,
		scrollDownPlayerTargets = function(self)
			self.targeting.playerListScroller:scrollDown()
		end,
		
		setDesignatedMaster = function(self,is_player,designation)
			self.targeting:setDesignation(is_player,designation)
		end,
		getDesignatedMaster = function(self,is_player)
			return self.targeting:getDesignation(is_player)
		end,
		addToWhitelist = function(self,is_player,designation)
			self.targeting:addToWhitelist(is_player,designation)
		end,
		removeFromWhitelist = function(self,is_player,designation)
			self.targeting:removeFromWhitelist(is_player,designation)
		end,
		setWhitelist = function(self,is_playerWhiteList,list)
			self.targeting:setWhitelist(is_playerWhiteList,list)
		end
	}
	
	radarSystem.targeting_table_update_threads = radarSystem.targeting:getTargetUpdatingThreads()
	
	return radarSystem
end

return SensorsSP