local Object = require "lib.object.Object"
local list_manager = require "lib.list_manager"
local IndexedListScroller = list_manager.IndexedListScroller

local SomePeripheralsRadar = Object:subclass()

function SomePeripheralsRadar:init()
	self.peripheral = peripheral.find("sp_radar")
	SomePeripheralsRadar.superClass.init(self)
end

function SomePeripheralsRadar:scan(range)
	return self.peripheral.scan(range)
end

function SomePeripheralsRadar:Targeting(arguments)
	local spr = self
	return{
		range = arguments.radar_range,
		designated_ship_id = arguments.designated_ship_id,
		designated_player_name = arguments.designated_player_name,
		ship_id_whitelist = arguments.ship_id_whitelist,
		player_name_whitelist = arguments.player_name_whitelist,
		
		prev_designated_ship_id = designated_ship_id,
		shipListScroller = IndexedListScroller(),
		playerListScroller = IndexedListScroller(),
		mobListScroller = IndexedListScroller(),
		
		getTargetSpatials = function(self,target_list,target_ship_id)
			for i,trg in ipairs(target_list) do
				if (trg.id == target_ship_id) then
					return trg
				end
			end
		end,
		
		getTargetList = function(self)
			return spr:scan(self.range)
		end,
		
		ship_targets = {},
		player_targets = {},
		mob_targets = {},
		
		updateTargets = function(self)
			local targets = self:getTargetList(self)
			self.ship_targets = {}
			self.player_targets = {}
			self.mob_targets = {}
			for i=1,#targets,1 do
				if (targets[i].is_ship) then
					self.ship_targets = { unpack(targets, i) }
					break
				elseif (targets[i].is_entity) then
					if (targets[i].is_player) then
						table.insert(self.player_targets,targets[i])
					else
						
						table.insert(self.mob_targets,targets[i])
					end
				end
			end
		end,
		
		getShipTarget = function(self,is_auto_aim)
			if (spr.peripheral) then
				local scanned_targets = self.ship_targets
				if (scanned_targets) then
					local list_size = #scanned_targets
					self.shipListScroller:updateListSize(list_size)
					if (list_size>1) then
						if (is_auto_aim) then
							local target = self.shipListScroller:getCurrentItem(scanned_targets)
							if (target) then
								local ship_id = tostring(target.id)
								local prev_ship_id = ship_id
								while (self.ship_id_whitelist[ship_id]) do
									self.shipListScroller:skip()
									target = self.shipListScroller:getCurrentItem(scanned_targets)
									ship_id = tostring(target.id)
									if (ship_id == prev_ship_id) then
										break
									end
								end
								return self.shipListScroller:getCurrentItem(scanned_targets)
							end
						else

							if (type(scanned_targets) == "table") then
								for i,trg in ipairs(scanned_targets) do
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
				return self.shipListScroller:getCurrentItem(scanned_targets)
			end
			return nil
		end,
		
		getPlayerTarget = function(self,is_auto_aim)
			if (spr.peripheral) then
				local scanned_targets = self.player_targets
				if (scanned_targets) then
					local list_size = #scanned_targets
					self.playerListScroller:updateListSize(list_size)
					if (list_size>1) then
						if (is_auto_aim) then
							local target = self.playerListScroller:getCurrentItem(scanned_targets)
							if (target) then
								local name = tostring(target.nickname)
								local prev_name = name
								while (self.player_name_whitelist[name]) do
									
									self.playerListScroller:skip()
									target = self.playerListScroller:getCurrentItem(scanned_targets)
									name = tostring(target.nickname)
									if (name == prev_name) then
										break
									end
								end
								return self.playerListScroller:getCurrentItem(scanned_targets)
							end
						else--remove when using goggle link

							if (type(scanned_targets) == "table") then
								for i,trg in ipairs(scanned_targets) do
									if (tostring(trg.nickname) == tostring(self.designated_player_name)) then
										return trg
									end
								end
							end
							return nil

							
						end
					end
				end
				return self.playerListScroller:getCurrentItem(scanned_targets)
			end
			return nil
		end,
		
		getMobTarget = function(self)
			if (spr.peripheral) then
				local scanned_targets = self.mob_targets
				if (scanned_targets) then
					local list_size = #scanned_targets
					self.mobListScroller:updateListSize(list_size)
					if (list_size>1) then
						local ship = self.mobListScroller:getCurrentItem(scanned_targets)
						if (ship) then
							local ship_id = tostring(ship.id)
							local prev_ship_id = ship_id
							while (self.ship_id_whitelist[ship_id]) do
								self.mobListScroller:skip()
								ship = self.mobListScroller:getCurrentItem(scanned_targets)
								ship_id = tostring(ship.id)
								if (ship_id == prev_ship_id) then
									break
								end
							end
							return self.mobListScroller:getCurrentItem(scanned_targets)
						end
					end
				end
				return self.mobListScroller:getCurrentItem(scanned_targets)
			end
			return nil
		end,
		
		addToWhitelist = function(self,is_player,designation)
			if (is_player) then
				local name = designation
				if (name) then
					if (name ~= "") then
						if (self.designated_player_name ~= name) then
							if (not self.player_name_whitelist[name]) then
								self.player_name_whitelist[name] = true
							end
						end
					end
				end
			else
				local id = designation
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
			end
			
		end,
		
		removeFromWhitelist = function(self,is_player,designation)
			if (is_player) then
				local id = tostring(designation)
				if (tostring(self.designated_ship_id) ~= id) then
					if (self.ship_id_whitelist[id]) then
						self.ship_id_whitelist[id] = false
					end
				end
			else
				if (self.designated_player_name ~= designation) then
					if (self.player_name_whitelist[name]) then
						self.player_name_whitelist[name] = false
					end
				end
			end
			
		end,
		
		setWhitelist = function(self,is_playerWhiteList,list)
			if (is_playerWhiteList) then
				self.player_name_whitelist = list
			else
				self.ship_id_whitelist = list
			end
		end,
		
		setDesignation = function(self,is_player,designation)
			if (is_player) then
				local name = designation
				if (name) then
					if (name ~= "") then
						self.prev_designated_player_name = self.designated_player_name
						self.addToWhitelist(self,name)
						self.designated_player_name = name
					end
				end
			else
				local id = designation
				if (id) then
					id = tostring(id)
					if (id ~= "") then
						self.prev_designated_ship_id = self.designated_ship_id
						self.addToWhitelist(self,id)
						self.designated_ship_id = id
					end
				end
			end
			
		end,
		
		getDesignation = function(self,is_player)
			if (is_player) then
				return self.designated_player_name
			else
				return self.designated_ship_id
			end
		end
	}
end



return SomePeripheralsRadar