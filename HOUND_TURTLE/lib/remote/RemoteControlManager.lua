local Object = require "lib.object.Object"

local RemoteControlManager = Object:subclass()

--OVERRIDABLE FUNCTIONS--

function RemoteControlManager:customRCProtocols(msg)--
	local command = msg.cmd
	command = command and tonumber(command) or command
	case =
	{
	["custom actions here"] = function (args)
		--custom actions here
	end,
	 default = function ( )
		print(textutils.serialize(command)) 
		print("customRCProtocols: default case executed")   
	end,
	}
	if case[command] then
	 case[command](msg.args)
	else
	 case["default"]()
	end
end

function RemoteControlManager:getCustomSettings()
	return {}
end

function RemoteControlManager:getSettings()
	
	local rcd_settings = {
		orbit_offset = self.rc_variables.orbit_offset,
		dynamic_positioning_mode = self.rc_variables.dynamic_positioning_mode,
		player_mounting_ship = self.rc_variables.player_mounting_ship,
	}
	
	for key,value in pairs(self:getCustomSettings()) do
		rcd_settings[key] = value
	end
	
	return rcd_settings
end

function RemoteControlManager:setSettings(new_settings)
	for var_name,new_setting in pairs(new_settings) do
		if (self.rc_variables[var_name] ~= nil) then
			self.rc_variables[var_name] = new_setting
		end
	end
end

--OVERRIDABLE FUNCTIONS--



function RemoteControlManager:protocols(msg)
	local command = msg.cmd
	command = command and tonumber(command) or command
	case =
	{
		["dynamic_positioning_mode"] = function (mode)
			self.rc_variables.dynamic_positioning_mode = mode
		end,
		["player_mounting_ship"] = function (mode)
			self.rc_variables.player_mounting_ship = mode
		end,
		["orbit_offset"] = function (pos_vec)
			self.rc_variables.orbit_offset = pos_vec
		end,
		["set_settings"] = function (msg)
			if (tostring(msg.drone_type) == tostring(self.DRONE_TYPE)) then
				self:setSettings(msg.args)
			end
		end,
		["get_settings_info"] = function (args)
			self:transmitCurrentSettingsToController()
		end,
		 default = function ( )
			self:customRCProtocols(msg)
		end,
	}
	if case[command] then
	 case[command](msg.args)
	else
	 case["default"]()
	end
end

function RemoteControlManager:init(configs)--
	
	self.DRONE_ID = configs.ship_constants_config.DRONE_ID
	self.DRONE_TYPE = configs.ship_constants_config.DRONE_TYPE
	self.DRONE_TO_REMOTE_CHANNEL = configs.channels_config.DRONE_TO_REMOTE_CHANNEL
	self.REPLY_DUMP_CHANNEL = configs.channels_config.REPLY_DUMP_CHANNEL
	self.modem = configs.modem
	self.rc_variables = {
		dynamic_positioning_mode = false,--deactivate to have drone act like stationary turret
		player_mounting_ship = false,--activate for aiming while "sitting" on a ship
		orbit_offset = vector.new(0,0,0),--flight formation around orbit_target
	}
	
	if (configs.rc_variables) then
		for key,value in pairs(configs.rc_variables) do
			self.rc_variables[key] = value
		end
	end
	RemoteControlManager.superClass.init(self,configs)
end

function RemoteControlManager:transmitCurrentSettingsToController()
	local msg = {drone_ID=self.DRONE_ID,protocol="drone_settings_update",partial_profile={settings=self:getSettings(),drone_type=self.DRONE_TYPE}}
	self:transmitToController(msg)
end

function RemoteControlManager:transmitToController(msg)
	self.modem.transmit(self.DRONE_TO_REMOTE_CHANNEL, self.REPLY_DUMP_CHANNEL, msg)
end

return RemoteControlManager