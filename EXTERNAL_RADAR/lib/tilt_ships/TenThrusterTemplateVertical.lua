local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"

local RemoteControlDrone = require "lib.tilt_ships.RemoteControlDrone"

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

local TenThrusterTemplateVertical = RemoteControlDrone:subclass()

function TenThrusterTemplateVertical:getOffsetDefaultShipOrientation(default_ship_orientation)-----------------------
	return quaternion.fromRotation(default_ship_orientation:localPositiveY(), 45)*default_ship_orientation
end

function TenThrusterTemplateVertical:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	configs.ship_constants_config.DEFAULT_NEW_LOCAL_SHIP_ORIENTATION = quaternion.fromRotation(vector.new(0,1,0), 45)
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
		x=vector.new(50600.0,0.0,0.0),
		y=vector.new(0.0,3200.0,0.0),
		z=vector.new(0.0,0.0,50600.0)
	}
	
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or 
	{
		x=vector.new(1.9762845849802372E-5,-0.0,-0.0),
		y=vector.new(-0.0,3.125E-4,-0.0),
		z=vector.new(-0.0,-0.0,1.9762845849802372E-5)
	}
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	
	configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED = configs.ship_constants_config.MOD_CONFIGURED_THRUSTER_SPEED or 10000
	
	configs.ship_constants_config.THRUSTER_TIER = configs.ship_constants_config.THRUSTER_TIER or 2
	
	configs.ship_constants_config.PID_SETTINGS = configs.ship_constants_config.PID_SETTINGS or
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
	configs.ship_constants_config.INV_ACTIVE_THRUSTERS_PER_LINEAR_MOVEMENT = vector.new(1/4,1/1,1/4)
	configs.ship_constants_config.INV_ACTIVE_THRUSTERS_PER_ANGULAR_MOVEMENT = vector.new(1/4,1/4,1/4)
	
	configs.ship_constants_config.ANGLED_THRUST_COEFFICIENT = vector.new(
																		1/math.sin(math.pi/4),--lateral x-thrusters are at a 45 degree angle
																		1,--the ship is built vertical and the y-thrusters are aligned to the axis
																		1/math.sin(math.pi/4))--lateral z-thrusters are at a 45 degree angle
		
	configs.ship_constants_config.THRUSTER_SPATIALS = 
	{
		THRUSTER_POSITIONS = {
			X_AXIS = vector.new(1,2,0),--represents thrusters that rotate x-axis
			Y_AXIS = vector.new(1,2,0),--represents thrusters that rotate y-axis
			Z_AXIS = vector.new(1,2,0),--represents thrusters that rotate z-axis
		},
		THRUSTER_DIRECTION = {--in world space
			X_AXIS = vector.new(0,0,1),
			Y_AXIS = vector.new(0,0,1),
			Z_AXIS = vector.new(0,0,1)
		}
	}
	--these values are specific for the vertical 10-thruster template--

	

	TenThrusterTemplateVertical.superClass.init(self,configs)
end

function TenThrusterTemplateVertical:composeComponentMessage(linear,angular)
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
	
	return {cmd="move", 
	drone_designation=self.ship_constants.DRONE_ID,
	BOW={BOW_U,BOW_CCF,BOW_CCB,BOW_CL,BOW_CR},
	STERN={STERN_D,STERN_CCF,STERN_CCB,STERN_CL,STERN_CR}}
end


return TenThrusterTemplateVertical