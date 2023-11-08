local quaternion = require "lib.quaternions"

player_spatial_utilities = {}

function player_spatial_utilities.getPlayerLookVector(player)--playerSpatialUtilities
	local player_global_look_vector = vector.new(0,0,1)
	player_global_look_vector = quaternion.fromRotation(vector.new(1,0,0), player.pitch):rotateVector3(player_global_look_vector)
	player_global_look_vector = quaternion.fromRotation(vector.new(0,1,0), -player.yaw):rotateVector3(player_global_look_vector)
	
	return player_global_look_vector:normalize()
end

function player_spatial_utilities.getPlayerHeadOrientation(player)--playerSpatialUtilities
	return quaternion.fromRotation(vector.new(0,1,0), -player.yaw)*quaternion.fromRotation(vector.new(1,0,0), player.pitch):normalize()
end

function player_spatial_utilities.rotateVectorWithPlayerHead(player,vec)--playerSpatialUtilities
	local new_vector = vec
	new_vector = quaternion.fromRotation(vector.new(1,0,0), player.pitch):rotateVector3(new_vector)
	new_vector = quaternion.fromRotation(vector.new(0,1,0), -player.yaw):rotateVector3(new_vector)
	
	return new_vector:normalize()
end

function player_spatial_utilities.PlayerVelocityCalculator()--playerSpatialUtilities
	return {
	previous_player_position=vector.new(0,0,0),
	previous_time = os.clock(),
	getVelocity = function(self,curr_p)
		local current_time = os.clock()
		local delta_time_inv = 1/(current_time-self.previous_time)
		self.previous_time = current_time
		local player_velocity = curr_p:sub(self.previous_player_position):mul(delta_time_inv)
		
		self.previous_player_position = curr_p
		
		return player_velocity
	end
	}
end

return player_spatial_utilities