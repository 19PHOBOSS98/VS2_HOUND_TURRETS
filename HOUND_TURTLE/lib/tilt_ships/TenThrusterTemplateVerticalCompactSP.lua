local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"

local DroneBaseClassSP = require "lib.tilt_ships.DroneBaseClassSP"

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

local TenThrusterTemplateVerticalCompactSP = DroneBaseClassSP:subclass()

function TenThrusterTemplateVerticalCompactSP:getOffsetDefaultShipOrientation(default_ship_orientation)-----------------------
	return quaternion.fromRotation(default_ship_orientation:localPositiveY(), 45)*default_ship_orientation
end

function TenThrusterTemplateVerticalCompactSP:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	configs.ship_constants_config.DEFAULT_NEW_LOCAL_SHIP_ORIENTATION = quaternion.fromRotation(vector.new(0,1,0), 45)-----------------------
	
	configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED = configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED or 10000-----------------------
	
	configs.ship_constants_config.THRUSTER_TIER = configs.ship_constants_config.THRUSTER_TIER or 2-----------------------
	
	configs.ship_constants_config.PID_SETTINGS = configs.ship_constants_config.PID_SETTINGS or-----------------------
	{
		POS = {
			P = 5,
			I = 0,
			D = 4
		},
		ROT = {
			X = {
				P = 0.15,
				I = 0.08,
				D = 0.15
			},
			Y = {
				P = 0.15,
				I = 0.08,
				D = 0.15
			},
			Z = {
				P = 0.15,
				I = 0.08,
				D = 0.15
			}
		}
	}

	TenThrusterTemplateVerticalCompactSP.superClass.init(self,configs)
end

function TenThrusterTemplateVerticalCompactSP:composeComponentMessage(linear,angular)
	local BOW_U = redstone_power[1]
	local BOW_CCF = redstone_power[2]
	local BOW_CCB  = redstone_power[3]
	local BOW_CR  = redstone_power[4]
	local BOW_CL  = redstone_power[5]
	
	local STERN_D  = redstone_power[6]
	local STERN_CCF  = redstone_power[7]
	local STERN_CCB = redstone_power[8]
	local STERN_CR = redstone_power[9]
	local STERN_CL = redstone_power[10]
	
	return {
		BOW={BOW_U,BOW_CCF,BOW_CCB,BOW_CL,BOW_CR},
		STERN={STERN_D,STERN_CCF,STERN_CCB,STERN_CL,STERN_CR}
	}
end

local group_component_map = 
{
	BOW = 
		{
		"up",--ZU
		"south",--ZCCF
		"north",--ZCCB
		"east",--ZCL
		"west"--ZCR
		}
	,
	STERN = 
		{
		"down",--ZD
		"south",--ZCCF
		"north",--ZCCB
		"east",--ZCL
		"west"--ZCR
		}
}

TenThrusterTemplateVerticalCompactSP.RSIBow = peripheral.wrap("top")
TenThrusterTemplateVerticalCompactSP.RSIStern = peripheral.wrap("bottom")

function TenThrusterTemplateVerticalCompactSP:powerThrusters(group,component_values)
	if (group == "BOW") then
		self.RSIBow.setAnalogOutput(group_component_map.BOW[1], component_values[1])
		self.RSIBow.setAnalogOutput(group_component_map.BOW[2], component_values[2])
		self.RSIBow.setAnalogOutput(group_component_map.BOW[3], component_values[3])
		self.RSIBow.setAnalogOutput(group_component_map.BOW[4], component_values[4])
		self.RSIBow.setAnalogOutput(group_component_map.BOW[5], component_values[5])
	else
		self.RSIStern.setAnalogOutput(group_component_map.STERN[1], component_values[1])
		self.RSIStern.setAnalogOutput(group_component_map.STERN[2], component_values[2])
		self.RSIStern.setAnalogOutput(group_component_map.STERN[3], component_values[3])
		self.RSIStern.setAnalogOutput(group_component_map.STERN[4], component_values[4])
		self.RSIStern.setAnalogOutput(group_component_map.STERN[5], component_values[5])
	end
end

function TenThrusterTemplateVerticalCompactSP:communicateWithComponent(component_control_msg)	
	self:powerThrusters("BOW",component_control_msg.BOW)
	self:powerThrusters("STERN",component_control_msg.STERN)
end

function TenThrusterTemplateVerticalCompactSP:resetRedstone()
	self:communicateWithComponent({
		BOW={0,0,0,0,0},
		STERN={0,0,0,0,0}
	})	
	self:onResetRedstone()
end

return TenThrusterTemplateVerticalCompactSP