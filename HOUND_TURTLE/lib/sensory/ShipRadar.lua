local Object = require "lib.object.Object"

local list_manager = require "lib.list_manager"
local IndexedListScroller = list_manager.IndexedListScroller

local ShipRadar = Object:subclass()

function ShipRadar:init()
	self.peripheral = peripheral.find("radar")
	ShipRadar.superClass.init(self)
end

function ShipRadar:scan(range)
	return self.peripheral.scan(range)[1]
end

function ShipRadar:Targeting(arguments)
	local sr = self
	return{
		range = arguments.radar_range,
		designated_ship_id = arguments.designated_ship_id,
		ship_id_whitelist = arguments.ship_id_whitelist,
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
			return sr:scan(self.range)
		end,
		
		targets = {},
		
		updateTargets = function(self)
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



return ShipRadar