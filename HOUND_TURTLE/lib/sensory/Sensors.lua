local targeting_utilities = require "lib.targeting_utilities"
local quaternion = require "lib.quaternions"
local player_spatial_utilities = require "lib.player_spatial_utilities"



local ShipReader = require "lib.sensory.ShipReader"
local ShipRadar = require "lib.sensory.ShipRadar"
local PlayerRadar = require "lib.sensory.PlayerRadar"

local Object = require "lib.object.Object"

local RadarSystems = targeting_utilities.RadarSystems
local TargetingSystem = targeting_utilities.TargetingSystem

local getPlayerHeadOrientation = player_spatial_utilities.getPlayerHeadOrientation
local PlayerVelocityCalculator = player_spatial_utilities.PlayerVelocityCalculator

local Sensors = Object:subclass()


function Sensors:init()
	self.shipReader = ShipReader()
	self.shipRadar = ShipRadar()
	self.playerRadar = PlayerRadar()
	
	self.pvc = PlayerVelocityCalculator()
	self.mvc = PlayerVelocityCalculator()
	Sensors.superClass.init(self)
end

function Sensors:initRadar(radar_config)

	
	self.MY_SHIP_ID = self.shipReader:getShipID()
	local radar_arguments = {
	ship_radar_component=self.shipRadar,
	ship_reader_component=self.shipReader,
	player_radar_component=self.playerRadar,
	
	--if target_mode is "2" and hunt_mode is false, drone orbits this ship if detected
	designated_ship_id=tostring(radar_config.designated_ship_id),
	
	--if target_mode is "1" and hunt_mode is false, drone orbits this player if detected
	designated_player_name=radar_config.designated_player_name,
	
	--ships excluded from being aimed at
	ship_id_whitelist={
		[tostring(self.MY_SHIP_ID)]=true,
		[tostring(radar_config.designated_ship_id)]=true,
	},
	
	--players excluded from being aimed at
	player_name_whitelist={
		[tostring(radar_config.designated_player_name)]=true,
	},
	
	
	player_radar_box_size=radar_config.player_radar_box_size or 50,--player detector range is defined by a box area around the turret
	radar_range=radar_config.radar_range or 500
	}
	
	for id,validation in pairs(radar_config.ship_id_whitelist) do
		radar_arguments.ship_id_whitelist[id] = validation
	end
	
	for name,validation in pairs(radar_config.player_name_whitelist) do
		radar_arguments.player_name_whitelist[name] = validation
	end
	self.radars = self:RadarSystems(radar_arguments)
	self.aimTargeting = TargetingSystem(radar_config.EXTERNAL_AIM_TARGETING_CHANNEL,"PLAYER",false,false,self.radars,radar_config.DRONE_ID,radar_config.DRONE_TYPE)
	self.orbitTargeting = TargetingSystem(radar_config.EXTERNAL_ORBIT_TARGETING_CHANNEL,"PLAYER",false,false,self.radars,radar_config.DRONE_ID,radar_config.DRONE_TYPE)

	function Sensors:scrollUpShipTargets()
		self.radars:scrollUpShipTargets()
	end
	function Sensors:scrollDownShipTargets()
		self.radars:scrollDownShipTargets()
	end

	function Sensors:scrollUpPlayerTargets()
		self.radars:scrollUpPlayerTargets()
	end
	function Sensors:scrollDownPlayerTargets()
		self.radars:scrollDownPlayerTargets()
	end
end

function Sensors:getInertiaTensors()
	return	{
				{
					x=vector.new(0,0,0),
					y=vector.new(0,0,0),
					z=vector.new(0,0,0),
				},
				{
					x=vector.new(0,0,0),
					y=vector.new(0,0,0),
					z=vector.new(0,0,0),
				}
			}
end

function Sensors:RadarSystems(radar_arguments)
	local sens = self
	local radarSystem = {
		
		playerTargeting = sens.playerRadar:Targeting(radar_arguments),
		shipTargeting = sens.shipRadar:Targeting(radar_arguments),
		
		targeted_players_undetected = false,
		targeted_ships_undetected = false,
		
		targeting_table_update_threads = {},
		
		getRadarTarget = function(self,trg_mode,args)
			case =
				{
				["PLAYER"] = function (is_auto_aim)
								local player = self.playerTargeting:getTarget(is_auto_aim)
								
								if (player and next(player) ~= nil) then
									self.targeted_players_undetected = false
									local current_player_position = vector.new(	player.x,
																				player.y+player.eyeHeight,
																				player.z)
									
									return {orientation=getPlayerHeadOrientation(player),
											position=current_player_position,
											velocity=sens.pvc:getVelocity(current_player_position)}
								end								
								self.targeted_players_undetected = true
								return nil
							end,
				["SHIP"] = function (is_auto_aim)
								local ship = self.shipTargeting:getTarget(is_auto_aim)
								if (ship) then
									self.targeted_ships_undetected = false
									local target_rot = ship.rotation
									return {orientation=quaternion.new(target_rot.w,target_rot.x,target_rot.y,target_rot.z),
											position=ship.position,
											velocity=ship.velocity}
								end
								self.targeted_ships_undetected = true
								return nil
							end,
				["MOB"] = function (arguments)
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
			self.shipTargeting.listScroller:scrollUp()
		end,
		scrollDownShipTargets = function(self)
			self.shipTargeting.listScroller:scrollDown()
		end,
		scrollUpPlayerTargets = function(self)
			self.playerTargeting.listScroller:scrollUp()
		end,
		scrollDownPlayerTargets = function(self)
			self.playerTargeting.listScroller:scrollDown()
		end,
		setDesignatedMaster = function(self,is_player,designation)
			if (is_player) then
				self.playerTargeting:setDesignation(designation)
			else
				self.shipTargeting:setDesignation(designation)
			end
		end,
		getDesignatedMaster = function(self,is_player)
			if (is_player) then
				return self.playerTargeting:getDesignation()
			else
				return self.shipTargeting:getDesignation()
			end
		end,
		addToWhitelist = function(self,is_player,designation)
			if (is_player) then
				self.playerTargeting:addToWhitelist(designation)
			else
				self.shipTargeting:addToWhitelist(designation)
			end
		end,
		removeFromWhitelist = function(self,is_player,designation)
			if (is_player) then
				self.playerTargeting:removeFromWhitelist(designation)
			else
				self.shipTargeting:removeFromWhitelist(designation)
			end
		end,
		setWhitelist = function(self,is_playerWhiteList,list)
			if (is_playerWhiteList) then
				self.playerTargeting:setWhitelist(list)
			else
				self.shipTargeting:setWhitelist(list)
			end
		end
	}
	
	radarSystem.targeting_table_update_threads = {
		function() 
			radarSystem.playerTargeting:updateTargets() 
		end,
		function() 
			radarSystem.shipTargeting:updateTargets() 
		end,
	}
	
	return radarSystem
end


--RADAR SYSTEM FUNCTIONS--
function Sensors:useExternalRadar(is_aim,mode)
	--(turn these on and transmit target info yourselves from a ground radar station, or something... idk)
	if (is_aim) then
		self.aimTargeting:useExternalRadar(mode)--activate to use external radar system instead to get aim_target 
	else
		self.orbitTargeting:useExternalRadar(mode)--activate to use external radar system instead to get orbit_target
	end
end

function Sensors:isUsingExternalRadar(is_aim)
	if (is_aim) then
		return self.aimTargeting:isUsingExternalRadar()
	else
		return self.orbitTargeting:isUsingExternalRadar()
	end
end

function Sensors:setTargetMode(is_aim,target_mode)
	if (is_aim) then
		self.aimTargeting:setTargetMode(target_mode)--aim at either players or ships (etity radar has not yet been implemented)
	else
		self.orbitTargeting:setTargetMode(target_mode)--orbit either players or ships (etity radar has not yet been implemented)
	end
end

function Sensors:getTargetMode(is_aim)
	if (is_aim) then
		return self.aimTargeting:getTargetMode()
	else
		return self.orbitTargeting:getTargetMode()
	end
end

function Sensors:setDesignatedMaster(is_player,designation)
	if (not is_player and designation == tostring(self.MY_SHIP_ID)) then
		self:setTargetMode(false,"PLAYER")
	else
		self.radars:setDesignatedMaster(is_player,designation)
	end
end

function Sensors:getDesignatedMaster(is_player)
	return self.radars:getDesignatedMaster(is_player)
end


function Sensors:addToWhitelist(is_player,designation)
	self.radars:addToWhitelist(is_player,designation)
end

function Sensors:removeFromWhitelist(is_player,designation)
	self.radars:removeFromShipWhitelist(is_player,designation)
end

function Sensors:getAutoAim()
	return self.aimTargeting:getAutoAimActive()
end

function Sensors:setAutoAim(lock_true,mode)
	self.aimTargeting:setAutoAimActive(lock_true,mode)
end

function Sensors:targetedPlayersAreUndetected()
	return self.radars.targeted_players_undetected
end

function Sensors:customUpdateLoop()
	
end

function Sensors:getTargetingSystemThreads()
	
	local targeting_threads =  {
		function()
			self.shipReader:updateShipReader()
		end,
		function()
			self.aimTargeting:listenToExternalRadar()
		end,
		function()
			--[[local ori = self.shipReader:getRotation(true)
			local pos = self.shipReader:getWorldspacePosition()
			
			local trg_spatials = {	
				orientation = quaternion.new(ori.w,ori.x,ori.y,ori.z), 
				position = vector.new(pos.x,pos.y,pos.z), 
				velocity = vector.new(0,0,0)
			}
			self.orbitTargeting.current_target:updateTargetSpatials(trg_spatials)
			]]--
			self.orbitTargeting:listenToExternalRadar()
		end,
		function()
			self:customUpdateLoop()
		end
	}
	
	for _,thread in ipairs(self.radars.targeting_table_update_threads) do
		local func = function() thread() end
		table.insert(targeting_threads,func)
	end
		
	return targeting_threads
	
end
--RADAR SYSTEM FUNCTIONS--

return Sensors