local quaternion = require "lib.quaternions"

local cos = math.cos
local sin = math.sin
local pi = math.pi
local two_pi = 2*pi

path_utilities = {}

function path_utilities.generateHelix(radius,gap,loops,resolution)
	local helix = {}

	for t=0,two_pi*loops,two_pi/resolution do
		local coord = vector.new(radius*cos(t),radius*sin(t),gap*t)
		table.insert(helix,coord)
	end
	return helix
end

function path_utilities.recenterStartToOrigin(coords)
	local coord_i = coords[1]
	for i,coord in ipairs(coords) do
		coords[i] = coord-coord_i
	end
end

function path_utilities.offsetCoords(coords,offset)
	local coord_i = coords[1]
	for i,coord in ipairs(coords) do
		coords[i] = coord+offset
	end
end

function path_utilities.rotateCoordsByAxis(coords,axis,angle)
	local coord_i = coords[1]
	for i,coord in ipairs(coords) do
		coords[i] = quaternion.rotateVectorByAxis(coord,axis,angle)
	end
end

return path_utilities