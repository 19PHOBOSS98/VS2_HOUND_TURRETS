local Object = require "lib.object.Object"

local list_manager = require "lib.list_manager"
local IndexedListScroller = list_manager.IndexedListScroller

local PlayerRadar = Object:subclass()

function PlayerRadar:init()
	self.peripheral = peripheral.find("playerDetector")
	PlayerRadar.superClass.init(self)
end

function PlayerRadar:getPlayerPos(name)
	return self.peripheral.getPlayerPos(name)
end

function PlayerRadar:getPlayersInCoords(pos1,pos2)
	return self.peripheral.getPlayersInCoords(pos1,pos2)
end

function PlayerRadar:Targeting(arguments)
	local pr = self
	
	return{
		ship_reader_component=arguments.ship_reader_component,
		designated_player_name = arguments.designated_player_name,
		player_name_whitelist = arguments.player_name_whitelist,
		
		listScroller = IndexedListScroller(),
		
		box_radar_area = vector.new(1,1,1):mul(arguments.player_radar_box_size/2),

		setBoxRadarAreaSize = function(self,size)
			self.box_radar_area = vector.new(1,1,1):mul(size/2)
		end,
		
		getTargetSpatials = function(self,name)
			return pr:getPlayerPos(name)
		end,
		
		getTargetList = function(self)
			if (pr.peripheral) then
				local center = self.ship_reader_component:getWorldspacePosition()
				center = vector.new(center.x,center.y,center.z)
				local pos1 = center:add(self.box_radar_area)
				local pos2 = center:sub(self.box_radar_area)
				return pr:getPlayersInCoords(pos1,pos2)
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
			if (pr.peripheral) then
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

return PlayerRadar