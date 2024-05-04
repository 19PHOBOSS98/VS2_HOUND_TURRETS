--Uses new CC:VS ShipAPI
matrix = require "lib.matrix"

local ShipReader = require "lib.sensory.ShipReader"
local ShipReader2 = ShipReader:subclass()

function ShipReader2:init()
	ShipReader2.superClass.init(self)
end

function ShipReader2:getRotation(is_quaternion)
	local rot = ship.getQuaternion()
	return {w=rot.w,x=rot.x,y=rot.y,z=rot.z}
end

function ShipReader2:getWorldspacePosition()
	return ship.getWorldspacePosition()
end

function ShipReader2:getVelocity()
	return ship.getVelocity()
end

function ShipReader2:getShipID()
	return ship.getId()
end

function ShipReader2:getMass()
	return ship.getMass()
end

function ShipReader2:getShipYardCenterOfMass()
	local com = ship.getShipyardPosition()
	return vector.new(com.x,com.y,com.z)
end

function ShipReader2:getInertiaTensors()
	local moi = ship.getMomentOfInertiaTensor()
	local m = matrix(
			{	
				{moi[1.0][1.0],moi[1.0][2.0],moi[1.0][3.0]},
				{moi[2.0][1.0],moi[2.0][2.0],moi[2.0][3.0]},
				{moi[3.0][1.0],moi[3.0][2.0],moi[3.0][3.0]},
			})
	local inv_m = matrix.invert(m)
	local it = {
		x=vector.new(m[1][1],m[1][2],m[1][3]),
		y=vector.new(m[2][1],m[2][2],m[2][3]),
		z=vector.new(m[3][1],m[3][2],m[3][3])
	}
	local inv_it = {
		x=vector.new(inv_m[1][1],inv_m[1][2],inv_m[1][3]),
		y=vector.new(inv_m[2][1],inv_m[2][2],inv_m[2][3]),
		z=vector.new(inv_m[3][1],inv_m[3][2],inv_m[3][3])
	}
	return {it,inv_it}
end

function ShipReader2:getInertiaMatrix()
	local moi = ship.getMomentOfInertiaTensor()
	local it = matrix(
			{	
				{moi[1.0][1.0],moi[1.0][2.0],moi[1.0][3.0]},
				{moi[2.0][1.0],moi[2.0][2.0],moi[2.0][3.0]},
				{moi[3.0][1.0],moi[3.0][2.0],moi[3.0][3.0]},
			})
	local inv_it = matrix.invert(it)
	return {it,inv_it}
end

function ShipReader2:updateShipReader()
	--shipAPI updates ship spatials for us
end

return ShipReader2