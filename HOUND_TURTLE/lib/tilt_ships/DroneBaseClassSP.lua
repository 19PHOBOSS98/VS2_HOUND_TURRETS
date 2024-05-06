local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local pidcontrollers = require "lib.pidcontrollers"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local JSON = require "lib.JSON"
local matrix = require "lib.matrix"

local clamp = utilities.clamp
local PwmScalar = utilities.PwmScalar
local getQuaternionRotationError = flight_utilities.getQuaternionRotationError
local getLocalPositionError = flight_utilities.getLocalPositionError
local abs = math.abs
local max = math.max
local min = math.min


local SensorsSP = require "lib.sensory.SensorsSP"

local DroneBaseClass = require "lib.tilt_ships.DroneBaseClass"

local DroneBaseClassSP = DroneBaseClass:subclass()


function DroneBaseClassSP:initSensors(configs)
	self.sensors = SensorsSP(configs)
end

function DroneBaseClassSP:initSensorRadar(radar_config)
	radar_config.radar_range=radar_config.radar_range or 200
	self.sensors:initRadar(radar_config)
end

--pre-calculate thruster placement compensation:
function DroneBaseClassSP:getInertiaTensors()
	return self.sensors.shipReader:getInertiaMatrix()
end

function DroneBaseClassSP:rotateInertiaTensors()
	self.ship_constants.LOCAL_INERTIA_TENSOR = quaternion.rotateMatrix(
												self.ship_constants.LOCAL_INERTIA_TENSOR,
												self.ship_constants.DEFAULT_NEW_LOCAL_SHIP_ORIENTATION)

	self.ship_constants.LOCAL_INV_INERTIA_TENSOR = quaternion.rotateMatrix(
													self.ship_constants.LOCAL_INV_INERTIA_TENSOR,
													self.ship_constants.DEFAULT_NEW_LOCAL_SHIP_ORIENTATION)
end

function DroneBaseClassSP:getThrusterTableJSONFile()
	self.ship_constants = self.ship_constants or {}
	self.ship_constants.THRUSTER_TABLE_DIRECTORY = self.ship_constants.THRUSTER_TABLE_DIRECTORY or "./input_thruster_table/thruster_table.json"
	local h = fs.open(self.ship_constants.THRUSTER_TABLE_DIRECTORY,"r")
	serialized = h.readAll()
	obj = JSON:decode(serialized)
	h.close()
	return obj
end

function DroneBaseClassSP:buildJacobianTranspose(thruster_table)
	local thruster_constants = self.ship_constants.MOD_CONFIGURED_THRUSTER_SPEED*self.ship_constants.THRUSTER_TIER
	local inverse_new_default_ship_orientation = self.ship_constants.DEFAULT_NEW_LOCAL_SHIP_ORIENTATION:inv()
	local jacobian_transpose = {}

	for i,v in pairs(thruster_table) do
		local dir = v.direction
		dir = vector.new(dir.x,dir.y,dir.z)
		local r = v.radius
		r = vector.new(r.x,r.y,r.z)
		local new_dir = inverse_new_default_ship_orientation:rotateVector3(dir)
		local new_r = inverse_new_default_ship_orientation:rotateVector3(r)
		local force = new_dir*thruster_constants
		local torque = utilities.round_vector3(new_r:cross(new_dir)*thruster_constants)
		
		jacobian_transpose[i] = {
			max(0,force.x==0 and 0 or 1/force.x), --positive
			abs(min(0,force.x==0 and 0 or 1/force.x)),--negative
			max(0,force.y==0 and 0 or 1/force.y),
			abs(min(0,force.y==0 and 0 or 1/force.y)),
			max(0,force.z==0 and 0 or 1/force.z),
			abs(min(0,force.z==0 and 0 or 1/force.z)),
		
			max(0,torque.x==0 and 0 or 1/torque.x),
			abs(min(0,torque.x==0 and 0 or 1/torque.x)),
			max(0,torque.y==0 and 0 or 1/torque.y),
			abs(min(0,torque.y==0 and 0 or 1/torque.y)),
			max(0,torque.z==0 and 0 or 1/torque.z),
			abs(min(0,torque.z==0 and 0 or 1/torque.z)),
		}
	end

	-- local jacobian = matrix.transpose(jacobian_transpose)
	-- jacobian = matrix.replace( jacobian,function(e) return e>0 and 1 or 0 end)
	-- local count_matrix = matrix(10,1,1)
	-- local inv_thruster_count_per_movement = matrix.mul(jacobian,count_matrix)
	-- inv_thruster_count_per_movement = matrix.replace(inv_thruster_count_per_movement,function(e) return 1/e end)
	-- for i,v in ipairs(jacobian_transpose) do
	-- 	for ii,vv in ipairs(v) do
	-- 		jacobian_transpose[i][ii] = vv*inv_thruster_count_per_movement[ii][1]
	-- 	end
	-- end

	local total = {0,0,0,0,0,0,0,0,0,0,0,0}

	for i,v in ipairs(jacobian_transpose) do
		for ii,vv in ipairs(v) do
			if(jacobian_transpose[i][ii]~=0)then
				total[ii] = total[ii]+(1/jacobian_transpose[i][ii])
			end
		end
	end
	--the total force/torque is distributed depending on each thruster's contribution by percentage
	for i,v in ipairs(jacobian_transpose) do
		for ii,vv in ipairs(v) do
			if(jacobian_transpose[i][ii]~=0) then 
				local thruster_contribution_percentage = (1/jacobian_transpose[i][ii])/total[ii]
				jacobian_transpose[i][ii] = jacobian_transpose[i][ii]*thruster_contribution_percentage
			end
		end
	end

	return jacobian_transpose
end


--redstone:
function DroneBaseClassSP:initFlightConstants()
	
	local min_time_step = 0.05 --how fast the computer should continuously loop (the max is 0.05 for ComputerCraft)
	local ship_mass = self.sensors.shipReader:getMass()
	local gravity_acceleration_vector = vector.new(0,-9.8,0)
	
	local max_redstone = 15
	
	local thruster_table = self:getThrusterTableJSONFile()
	
	local JACOBIAN_TRANSPOSE = matrix(self:buildJacobianTranspose(thruster_table))
	
	local base_thruster_force = self.ship_constants.MOD_CONFIGURED_THRUSTER_SPEED*self.ship_constants.THRUSTER_TIER--thruster force when powered with a redstone power of 1(from VS2-Tournament code)
	
	local minimum_radius_vector = vector.new(99999999,99999999,99999999)
	local minimum_thruster_direction = vector.new(0,1,0)
	
	for i,v in pairs(thruster_table) do
		local thruster_radius = v.radius
		thruster_radius = vector.new(thruster_radius.x,thruster_radius.y,thruster_radius.z)
		if (thruster_radius:length() < minimum_radius_vector:length()) then
			minimum_radius_vector = thruster_radius
			minimum_thruster_direction = v.direction
			minimum_thruster_direction = vector.new(minimum_thruster_direction.x,minimum_thruster_direction.y,minimum_thruster_direction.z)
		end
	end
	
	local inverse_new_default_ship_orientation = self.ship_constants.DEFAULT_NEW_LOCAL_SHIP_ORIENTATION:inv()
	local new_min_dir = inverse_new_default_ship_orientation:rotateVector3(minimum_thruster_direction)
	local new_min_r = inverse_new_default_ship_orientation:rotateVector3(minimum_radius_vector)
	
	local max_thruster_force = max_redstone*base_thruster_force
	local max_linear_acceleration = max_thruster_force/ship_mass
	
	local torque_saturation = new_min_r:cross(new_min_dir) * max_thruster_force
	
	torque_saturation = utilities.abs_vector3(torque_saturation)	
	torque_saturation = matrix({{torque_saturation.x},{torque_saturation.y},{torque_saturation.z}})
	
	
	
	local max_angular_acceleration = matrix.mul(self.ship_constants.LOCAL_INV_INERTIA_TENSOR,torque_saturation)
	
	return min_time_step,ship_mass,gravity_acceleration_vector,JACOBIAN_TRANSPOSE,max_linear_acceleration,max_angular_acceleration
end

function DroneBaseClassSP:initPID(max_lin_acc,max_ang_acc)
	self.pos_PID = pidcontrollers.PID_Discrete_Vector(	self.ship_constants.PID_SETTINGS.POS.P,
											self.ship_constants.PID_SETTINGS.POS.I,
											self.ship_constants.PID_SETTINGS.POS.D,
											-max_lin_acc,max_lin_acc)

	self.rot_x_PID = pidcontrollers.PID_Discrete_Scalar(self.ship_constants.PID_SETTINGS.ROT.X.P,
													self.ship_constants.PID_SETTINGS.ROT.X.I,
													self.ship_constants.PID_SETTINGS.ROT.X.D,
													-max_ang_acc[1][1],max_ang_acc[1][1])
	self.rot_y_PID = pidcontrollers.PID_Discrete_Scalar(self.ship_constants.PID_SETTINGS.ROT.Y.P,
													self.ship_constants.PID_SETTINGS.ROT.Y.I,
													self.ship_constants.PID_SETTINGS.ROT.Y.D,
													-max_ang_acc[2][1],max_ang_acc[2][1])
	self.rot_z_PID = pidcontrollers.PID_Discrete_Scalar(self.ship_constants.PID_SETTINGS.ROT.Z.P,
													self.ship_constants.PID_SETTINGS.ROT.Z.I,
													self.ship_constants.PID_SETTINGS.ROT.Z.D,
													-max_ang_acc[3][1],max_ang_acc[3][1])

	-- self.pos_PID = pidcontrollers.PID_Continuous_Vector(	self.ship_constants.PID_SETTINGS.POS.P,
	-- 										self.ship_constants.PID_SETTINGS.POS.I,
	-- 										self.ship_constants.PID_SETTINGS.POS.D,
	-- 										-max_lin_acc,max_lin_acc)
	-- self.rot_x_PID = pidcontrollers.PID_Continuous_Scalar(self.ship_constants.PID_SETTINGS.ROT.X.P,
	-- 												self.ship_constants.PID_SETTINGS.ROT.X.I,
	-- 												self.ship_constants.PID_SETTINGS.ROT.X.D,
	-- 												-max_ang_acc[1][1],max_ang_acc[1][1])
	-- self.rot_y_PID = pidcontrollers.PID_Continuous_Scalar(self.ship_constants.PID_SETTINGS.ROT.Y.P,
	-- 												self.ship_constants.PID_SETTINGS.ROT.Y.I,
	-- 												self.ship_constants.PID_SETTINGS.ROT.Y.D,
	-- 												-max_ang_acc[2][1],max_ang_acc[2][1])
	-- self.rot_z_PID = pidcontrollers.PID_Continuous_Scalar(self.ship_constants.PID_SETTINGS.ROT.Z.P,
	-- 												self.ship_constants.PID_SETTINGS.ROT.Z.I,
	-- 												self.ship_constants.PID_SETTINGS.ROT.Z.D,
	-- 												-max_ang_acc[3][1],max_ang_acc[3][1])
end

function DroneBaseClassSP:calculateMovement()
	local min_time_step,
	ship_mass,
	gravity_acceleration_vector,
	JACOBIAN_TRANSPOSE,
	max_linear_acceleration,
	max_angular_acceleration = self:initFlightConstants()
	self:initPID(max_linear_acceleration,max_angular_acceleration)
	
	self.pwmMatrixList = utilities.PwmMatrixList(10)
	
	self:customPreFlightLoopBehavior()
	
	local customFlightVariables = self:customPreFlightLoopVariables()
	
	while self.run_firmware do
		self:customFlightLoopBehavior(customFlightVariables)

		self.ship_rotation = self.sensors.shipReader:getRotation(true)
		self.ship_rotation = quaternion.new(self.ship_rotation.w,self.ship_rotation.x,self.ship_rotation.y,self.ship_rotation.z)
		self.ship_rotation = self:getOffsetDefaultShipOrientation(self.ship_rotation)

		self.ship_global_position = self.sensors.shipReader:getWorldspacePosition()
		self.ship_global_position = vector.new(self.ship_global_position.x,self.ship_global_position.y,self.ship_global_position.z)
		
		--FOR ANGULAR MOVEMENT--
		self.rotation_error = getQuaternionRotationError(self.target_rotation,self.ship_rotation)
		--self:debugProbe({NEW_rotation_error=self.rotation_error})
		local pid_output_angular_acceleration = matrix(
		{
			{self.rot_x_PID:run(self.rotation_error.x)},
			{self.rot_y_PID:run(self.rotation_error.y)},
			{self.rot_z_PID:run(self.rotation_error.z)}
		})
		--self:debugProbe({xpidsampleint=self.rot_x_PID.sample_interval})
		--self:debugProbe({NEW_ang_acc_pid=pid_output_angular_acceleration})
		local net_torque = matrix.mul(self.ship_constants.LOCAL_INERTIA_TENSOR,pid_output_angular_acceleration)
		
		--self:debugProbe({net_torqueNew=net_torque})
		
		--FOR LINEAR MOVEMENT--
		self.position_error = getLocalPositionError(self.target_global_position,self.ship_global_position,self.ship_rotation)
		local pid_output_linear_acceleration = self.pos_PID:run(self.position_error)
		--self:debugProbe({position_error=self.position_error})
		--self:debugProbe({pid_output_linear_acceleration2=pid_output_linear_acceleration})
		
		local local_gravity_acceleration = self.ship_rotation:inv():rotateVector3(gravity_acceleration_vector)
		local net_linear_acceleration = pid_output_linear_acceleration:sub(local_gravity_acceleration)
		--self:debugProbe({net_linear_acceleration2=net_linear_acceleration})
		local net_force = net_linear_acceleration*ship_mass
		
		--self:debugProbe({net_linear_acceleration=net_linear_acceleration,net_force=net_force})
		
		local net = matrix(
		{
			{max(0,net_force.x)},--positive
			{abs(min(0,net_force.x))},--negative
			
			{max(0,net_force.y)},
			{abs(min(0,net_force.y))},
			
			{max(0,net_force.z)},
			{abs(min(0,net_force.z))},
			
			{max(0,net_torque[1][1])},
			{abs(min(0,net_torque[1][1]))},
			
			{max(0,net_torque[2][1])},
			{abs(min(0,net_torque[2][1]))},
			
			{max(0,net_torque[3][1])},
			{abs(min(0,net_torque[3][1]))}
		})
		
		local thruster_redstone_power = matrix.mul(JACOBIAN_TRANSPOSE,net)
		self:applyRedStonePower(thruster_redstone_power)
		sleep(min_time_step)
	end
end

function DroneBaseClassSP:applyRedStonePower(redstone_power)
	local pwm_redstone_power = self.pwmMatrixList:run(redstone_power)
	local component_control_msg = self:composeComponentMessage(pwm_redstone_power)
	self:communicateWithComponent(component_control_msg)
end

return DroneBaseClassSP