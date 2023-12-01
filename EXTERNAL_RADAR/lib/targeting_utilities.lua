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



function targeting_utilities.OnBoardPlayerRadar(
ship_reader_component,
player_radar_component,
designated_player_name,
player_name_whitelist,
box_size)
	return{
		ship_reader_component=ship_reader_component,
		player_radar_component=player_radar_component,
		box_radar_area = vector.new(1,1,1):mul(box_size/2),
		designated_player_name = designated_player_name,
		player_name_whitelist = player_name_whitelist,
		listScroller = IndexedListScroller(),
		
		
		
		setBoxRadarAreaSize = function(self,size)
			self.box_radar_area = vector.new(1,1,1):mul(size/2)
		end,
		
		getTargetSpatials = function(self,name)
			return self.player_radar_component.getPlayerPos(name)
		end,
		
		getTargetList = function(self)
			if (self.player_radar_component) then
				local center = self.ship_reader_component.getWorldspacePosition()
				center = vector.new(center.x,center.y,center.z)
				local pos1 = center:add(self.box_radar_area)
				local pos2 = center:sub(self.box_radar_area)
				return self.player_radar_component.getPlayersInCoords(pos1,pos2)
				--return {"PHO","PRING","BING","GUS"}
			end
			return nil
		end,
		
		targets = {},
		
		current_target_player = {},
		
		updateTargets = function(self)
			self.targets = self:getTargetList(self)
			current_target_player = self:getTargetSpatials(self.designated_player_name)
		end,
		
		getTarget=function(self,is_auto_aim)
			if (peripheral.find("playerDetector")) then
				if (is_auto_aim) then
					local scanned_player_names = self.targets
					if (scanned_player_names) then
						local list_size = #scanned_player_names
						
						self.listScroller:updateListSize(list_size)
						
						if (list_size>1) then
							local name = self.listScroller:getCurrentItem(scanned_player_names)
							if (name) then
								local prev_name = name
								while (self.player_name_whitelist[name]) do
									self.listScroller:skip()
									name = self.listScroller:getCurrentItem(scanned_player_names)
									if (prev_name == name) then
										break
									end
								end
								return self.getTargetSpatials(self,name)
							end
						end
					end
				else
					return current_target_player
				end

			end
			return nil
		end,
		addToWhitelist = function(self,name)
			if (name) then
				if (name ~= "") then
					if (self.designated_player_name ~= name) then
						if (not self.player_name_whitelist[name]) then
							self.player_name_whitelist[name] = true
						end
					end
				end
			end
		end,
		removeFromWhitelist = function(self,name)
			if (self.designated_player_name ~= name) then
				if (self.player_name_whitelist[name]) then
					self.player_name_whitelist[name] = false
				end
			end
		end,
		setWhitelist = function(self,list)
			self.player_name_whitelist = list
		end,
		setDesignation = function(self,name)
			if (name) then
				if (name ~= "") then
					self.prev_designated_player_name = self.designated_player_name
					self.addToWhitelist(self,name)
					self.designated_player_name = name
				end
			end
		end,
		getDesignation = function(self)
			return self.designated_player_name
		end
	}
end




function targeting_utilities.OnBoardShipRadar(ship_radar_component,designated_ship_id,ship_id_whitelist,range)
	return{
		ship_radar_component = ship_radar_component,
		range = range,
		designated_ship_id = designated_ship_id,
		ship_id_whitelist = ship_id_whitelist,
		prev_designated_ship_id = designated_ship_id,
		listScroller = IndexedListScroller(),
		
		getTargetSpatials = function(self,target_list,target_ship_id)
			for i,trg in ipairs(target_list) do
				if (trg.id == target_ship_id) then
					return trg
				end
			end
		end,
		
		getTargetList = function(self)
			return self.ship_radar_component.scan(self.range)[1]
		end,
		
		targets = {},
		
		updateTargetList = function(self)
			self.targets = self:getTargetList(self)
		end,
		
		getTarget=function(self,is_auto_aim)
			if (peripheral.find("radar")) then
				local scanned_ship_targets = self.targets
				if (scanned_ship_targets) then
					local list_size = #scanned_ship_targets
					self.listScroller:updateListSize(list_size)
					if (list_size>1) then
						if (is_auto_aim) then
							local ship = self.listScroller:getCurrentItem(scanned_ship_targets)
							if (ship) then
								local ship_id = tostring(ship.id)
								local prev_ship_id = ship_id
								while (self.ship_id_whitelist[ship_id]) do
									
									self.listScroller:skip()
									ship = self.listScroller:getCurrentItem(scanned_ship_targets)
									ship_id = tostring(ship.id)
									if (ship_id == prev_ship_id) then
										break
									end
								end
								return self.listScroller:getCurrentItem(scanned_ship_targets)
							end
						else

							if (type(scanned_ship_targets) == "table") then
								for i,trg in ipairs(scanned_ship_targets) do
									if (tostring(trg.id) == tostring(self.designated_ship_id)) then
										return trg
									end
								end
							end
							self.designated_ship_id = self.prev_designated_ship_id
							return nil

							
						end
					end
				end
				return self.listScroller:getCurrentItem(scanned_ship_targets)
			end
			return nil
		end,
		addToWhitelist = function(self,id)
			if (id) then
				id = tostring(id)
				if (id ~= "") then
					if (tostring(self.designated_ship_id) ~= id) then
						if (not self.ship_id_whitelist[id]) then
							self.ship_id_whitelist[id] = true
						end
					end
				end
			end
		end,
		removeFromWhitelist = function(self,id)
			id = tostring(id)
			if (tostring(self.designated_ship_id) ~= id) then
				if (self.ship_id_whitelist[id]) then
					self.ship_id_whitelist[id] = false
				end
			end
		end,
		setWhitelist = function(self,list)
			self.ship_id_whitelist = list
		end,
		setDesignation = function(self,id)
			if (id) then
				id = tostring(id)
				if (id ~= "") then
					self.prev_designated_ship_id = self.designated_ship_id
					self.addToWhitelist(self,id)
					self.designated_ship_id = id
				end
			end
		end,
		getDesignation = function(self)
			return self.designated_ship_id
		end
	}
end




function targeting_utilities.RadarSystems(radar_arguments)
	return{
		onboardPlayerRadar = targeting_utilities.OnBoardPlayerRadar(radar_arguments.ship_reader_component,
												radar_arguments.player_radar_component,
												radar_arguments.designated_player_name,
												radar_arguments.player_name_whitelist,
												radar_arguments.player_radar_box_size),
												
		onboardShipRadar = targeting_utilities.OnBoardShipRadar(radar_arguments.ship_radar_component,
											radar_arguments.designated_ship_id,
											radar_arguments.ship_id_whitelist,
											radar_arguments.ship_radar_range),
		targeted_players_undetected = false,
		targeted_ships_undetected = false,
		
		updateTargetingTables = function(self)
			self.onboardPlayerRadar:updateTargets()
			self.onboardShipRadar:updateTargetList()
			--self.onboardEntityRadar:updateTargetList() --not implemented yet
		end,
		
		getRadarTarget = function(self,trg_mode,args)
			case =
				{
				["PLAYER"] = function (is_auto_aim)
								local player = self.onboardPlayerRadar:getTarget(is_auto_aim)
								
								if (player and next(player) ~= nil) then
									self.targeted_players_undetected = false
									local current_player_position = vector.new(	player.x,
																				player.y+player.eyeHeight,
																				player.z)
									
									return {orientation=getPlayerHeadOrientation(player),
											position=current_player_position,
											velocity=pvc:getPlayerVelocity(current_player_position)}
								end								
								self.targeted_players_undetected = true
								return nil
							end,
				["SHIP"] = function (is_auto_aim)
								local ship = self.onboardShipRadar:getTarget(is_auto_aim)
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
				["ENTITY"] = function (arguments)
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
			self.onboardShipRadar.listScroller:scrollUp()
		end,
		scrollDownShipTargets = function(self)
			self.onboardShipRadar.listScroller:scrollDown()
		end,
		scrollUpPlayerTargets = function(self)
			self.onboardPlayerRadar.listScroller:scrollUp()
		end,
		scrollDownPlayerTargets = function(self)
			self.onboardPlayerRadar.listScroller:scrollDown()
		end,
		setDesignatedMaster = function(self,is_player,designation)
			if (is_player) then
				self.onboardPlayerRadar:setDesignation(designation)
			else
				self.onboardShipRadar:setDesignation(designation)
			end
		end,
		getDesignatedMaster = function(self,is_player)
			if (is_player) then
				return self.onboardPlayerRadar:getDesignation()
			else
				return self.onboardShipRadar:getDesignation()
			end
		end,
		addToWhitelist = function(self,is_player,designation)
			if (is_player) then
				self.onboardPlayerRadar:addToWhitelist(designation)
			else
				self.onboardShipRadar:addToWhitelist(designation)
			end
		end,
		removeFromWhitelist = function(self,is_player,designation)
			if (is_player) then
				self.onboardPlayerRadar:removeFromWhitelist(designation)
			else
				self.onboardShipRadar:removeFromWhitelist(designation)
			end
		end,
		setWhitelist = function(self,is_playerWhiteList,list)
			if (is_playerWhiteList) then
				self.onboardPlayerRadar:setWhitelist(list)
			else
				self.onboardShipRadar:setWhitelist(list)
			end
		end
	}
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
	radarSystems)
	return{
		external_targeting_system_channel = external_targeting_system_channel,
		
		targeting_mode = targeting_mode,
		
		auto_aim_active = auto_aim_active,
		
		use_external_radar = use_external_radar,
		
		current_target = targeting_utilities.TargetSpatialAttributes(),
		
		radarSystems = radarSystems,
		
		TARGET_MODE = {"PLAYER","SHIP","ENTITY"},
		
		getTargetSpatials = function(self)
			if (self.use_external_radar) then
				local _, _, senderChannel, _, message, _ = os.pullEvent("modem_message")
				if (senderChannel == external_targeting_system_channel) then
					if (message.trg) then
						self.current_target:updateTargetSpatials(message.trg)
					end
				end
			else
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

	--[[
	local radar_arguments={	ship_radar_component,
							ship_reader_component,
							player_radar_component,
							designated_ship_id,
							designated_player_name,
							ship_id_whitelist,
							player_name_whitelist,
							player_radar_box_size,
							ship_radar_range}
	local radars = targeting_utilities.RadarSystems(radar_arguments)
	local aimTargeting = targeting_utilities.TargetingSystem(EXTERNAL_AIM_TARGETING_CHANNEL,aim_targeting_mode,auto_aim,true,false,radars)
	local orbitTargeting = targeting_utilities.TargetingSystem(EXTERNAL_ORBIT_TARGETING_CHANNEL,orbit_targeting_mode,auto_aim,false,false,radars)

	function updateTargetingSystem()
		while run_firmware do
			aimTargeting.updateTarget()
			orbitTargeting.updateTarget()
			os.sleep(0.05)
		end
	end
	
	
	aimTargeting.current_target.target_spatial
	]]--