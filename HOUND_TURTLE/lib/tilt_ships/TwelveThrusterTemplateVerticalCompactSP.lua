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

local TwelveThrusterTemplateVerticalCompactSP = DroneBaseClassSP:subclass()

function TwelveThrusterTemplateVerticalCompactSP:getOffsetDefaultShipOrientation(default_ship_orientation)-----------------------
	return quaternion.fromRotation(default_ship_orientation:localPositiveY(), 45)*default_ship_orientation
end

function TwelveThrusterTemplateVerticalCompactSP:init(instance_configs)
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

	--these values are specific for the vertical 10-thruster template--
	configs.ship_constants_config.INV_ACTIVE_THRUSTERS_PER_LINEAR_MOVEMENT = vector.new(1/4,1/2,1/4)
	configs.ship_constants_config.INV_ACTIVE_THRUSTERS_PER_ANGULAR_MOVEMENT = vector.new(1/4,1/4,1/4)
	
	configs.ship_constants_config.ANGLED_THRUST_COEFFICIENT = vector.new(
																		1/math.sin(math.pi/4),--lateral x-thrusters are at a 45 degree angle
																		1,--the ship is built vertical and the y-thrusters are aligned to the axis
																		1/math.sin(math.pi/4))--lateral z-thrusters are at a 45 degree angle
		
	configs.ship_constants_config.THRUSTER_SPATIALS = 
	{
		THRUSTER_POSITIONS = {
			X_AXIS = vector.new(1,1,0),--represents thrusters that rotate x-axis
			Y_AXIS = vector.new(1,1,0),--represents thrusters that rotate y-axis
			Z_AXIS = vector.new(1,1,0),--represents thrusters that rotate z-axis
		},
		THRUSTER_DIRECTION = {--in world space
			X_AXIS = vector.new(0,0,1),
			Y_AXIS = vector.new(0,0,1),
			Z_AXIS = vector.new(0,0,1)
		}
	}
	--these values are specific for the vertical 10-thruster template--

	

	TwelveThrusterTemplateVerticalCompactSP.superClass.init(self,configs)
end

function TwelveThrusterTemplateVerticalCompactSP:composeComponentMessage(linear,angular)
	local ccf_common = linear.lin_z_p	+	linear.lin_x_p	+	angular.rot_y_p
	local ccb_common = linear.lin_z_n	+	linear.lin_x_n	+	angular.rot_y_p
	local cr_common = linear.lin_z_n	+	linear.lin_x_p	+	angular.rot_y_n
	local cl_common = linear.lin_z_p	+	linear.lin_x_n	+	angular.rot_y_n
	
	local rot_xn_zp = angular.rot_x_n + angular.rot_z_p
	local rot_xp_zn = angular.rot_x_p + angular.rot_z_n
	local rot_xn_zn = angular.rot_x_n + angular.rot_z_n
	local rot_xp_zp = angular.rot_x_p + angular.rot_z_p
	
	local BOW_U = clamp(linear.lin_y_p,0,15)
	local BOW_CCF = clamp(ccf_common+rot_xp_zn,0,15) --angular.rot_y_p + angular.rot_x_p + angular.rot_z_n + linear.lin_z_p	+ linear.lin_x_p
	local BOW_CCB  = clamp(ccb_common+rot_xn_zp,0,15)
	local BOW_CR  = clamp(cr_common+rot_xn_zn,0,15)
	local BOW_CL  = clamp(cl_common+rot_xp_zp,0,15)
	
	local STERN_D  = clamp(linear.lin_y_n,0,15)
	local STERN_CCF  = clamp(ccf_common+rot_xn_zp,0,15)
	local STERN_CCB = clamp(ccb_common+rot_xp_zn,0,15)
	local STERN_CR = clamp(cr_common+rot_xp_zp,0,15)
	local STERN_CL = clamp(cl_common+rot_xn_zn,0,15)
	
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

TwelveThrusterTemplateVerticalCompactSP.RSIBow = peripheral.wrap("top")
TwelveThrusterTemplateVerticalCompactSP.RSIStern = peripheral.wrap("bottom")

function TwelveThrusterTemplateVerticalCompactSP:powerThrusters(group,component_values)
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

function TwelveThrusterTemplateVerticalCompactSP:communicateWithComponent(component_control_msg)	
	self:powerThrusters("BOW",component_control_msg.BOW)
	self:powerThrusters("STERN",component_control_msg.STERN)
end

function TwelveThrusterTemplateVerticalCompactSP:resetRedstone()
	self:communicateWithComponent({
		BOW={0,0,0,0,0},
		STERN={0,0,0,0,0}
	})	
	self:onResetRedstone()
end

return TwelveThrusterTemplateVerticalCompactSP