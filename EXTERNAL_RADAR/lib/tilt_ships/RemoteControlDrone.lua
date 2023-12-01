local DroneBaseClass = require "lib.tilt_ships.DroneBaseClass"

local RemoteControlDrone = DroneBaseClass:subclass()

--OVERRIDABLE FUNCTIONS--
function RemoteControlDrone:customRCProtocols(msg)
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

function RemoteControlDrone:getCustomSettings()
	return {}
end
--OVERRIDABLE FUNCTIONS--



function RemoteControlDrone:customProtocols(msg)
	local command = msg.cmd
	command = command and tonumber(command) or command
	case =
	{
		["run_mode"] = function (mode)
			self.rc_variables.run_mode = mode
		end,
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
			if (tostring(msg.drone_type) == tostring(self.ship_constants.DRONE_TYPE)) then
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


function RemoteControlDrone:init(configs)
	
	self.rc_variables = {
		run_mode = false,--pause flight behavior
		dynamic_positioning_mode = false,--deactivate to have drone act like stationary turret
		player_mounting_ship = false,--activate for aiming while "sitting" on a ship
		orbit_offset = vector.new(0,0,0),--flight formation around orbit_target
	}
	
	if (configs.rc_variables) then
		for key,value in pairs(configs.rc_variables) do
			self.rc_variables[key] = value
		end
	end
	RemoteControlDrone.superClass.init(self,configs)
end

function RemoteControlDrone:getSettings()
	
	local rcd_settings = {
		orbit_offset = self.rc_variables.orbit_offset,
		dynamic_positioning_mode = self.rc_variables.dynamic_positioning_mode,
		player_mounting_ship = self.rc_variables.player_mounting_ship,
		auto_aim = self:getAutoAim(),
		run_mode = self:getRunMode(),
		use_external_aim = self:isUsingExternalRadar(true),
		use_external_orbit = self:isUsingExternalRadar(false),
		aim_target_mode = self:getTargetMode(true),
		orbit_target_mode = self:getTargetMode(false),
		master_player = self.radars:getDesignatedMaster(true),
		master_ship = self.radars:getDesignatedMaster(false),
	}
	
	for key,value in pairs(self:getCustomSettings()) do
		rcd_settings[key] = value
	end
	
	return rcd_settings
end

function RemoteControlDrone:setSettings(new_settings)
	for var_name,new_setting in pairs(new_settings) do
		if (self.rc_variables[var_name] ~= nil) then
			self.rc_variables[var_name] = new_setting
		elseif (var_name == "auto_aim") then
			self:setAutoAim(new_setting)
		elseif (var_name == "use_external_aim") then
			self:useExternalRadar(true,new_setting)
		elseif (var_name == "use_external_orbit") then
			self:useExternalRadar(false,new_setting)
		elseif (var_name == "aim_target_mode") then
			self:setTargetMode(true,new_settings.aim_target_mode)
		elseif (var_name == "orbit_target_mode") then
			self:setTargetMode(false,new_settings.orbit_target_mode)
		elseif (var_name == "master_player") then
			self:setDesignatedMaster(true,new_settings.master_player)
		elseif (var_name == "master_ship") then
			self:setDesignatedMaster(false,new_settings.master_ship)
		end
	end
end

function RemoteControlDrone:setRunMode(mode)
	self.rc_variables.run_mode = mode
end

function RemoteControlDrone:getRunMode()
	if(self.radars.targeted_players_undetected) then
		return false
	end
	return self.rc_variables.run_mode
end

function RemoteControlDrone:transmitCurrentSettingsToController()
	local msg = {drone_ID=self.ship_constants.DRONE_ID,protocol="drone_settings_update",partial_profile={settings=self:getSettings(),drone_type = self.ship_constants.DRONE_TYPE}}
	self:transmitToController(msg)
end

function RemoteControlDrone:transmitToController(msg)
	self.modem.transmit(self.com_channels.DRONE_TO_REMOTE_CHANNEL, self.com_channels.REPLY_DUMP_CHANNEL, msg)
end

return RemoteControlDrone