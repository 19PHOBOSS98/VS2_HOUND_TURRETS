flight_utilities = {}

function flight_utilities.adjustOrbitRadiusPosition(target_g_pos,orbit_target_pos,radius)--flightUtilities
	local radius_vector = (target_g_pos:sub(orbit_target_pos)):normalize()*radius
	return orbit_target_pos:add(radius_vector)
end

function flight_utilities.getLocalPositionError(trg_g_pos,current_g_pos,current_rot)--flightUtilities
	local trg_l_pos = trg_g_pos - current_g_pos
	trg_l_pos = current_rot:inv():rotateVector3(trg_l_pos) --target position in the ship's perspective
	return trg_l_pos
end

function flight_utilities.getQuaternionRotationError(target_rot,current_rot)--flightUtilities
	local rotation_difference = target_rot * current_rot:inv()
	local error_magnitude = rotation_difference:rotationAngle()
	local rotation_axis = rotation_difference:rotationAxis()
	local local_rotation = current_rot:inv():rotateVector3(rotation_axis) --have to reorient target rotation axis to the ship's perspective
	return local_rotation:mul(error_magnitude)
end

return flight_utilities
