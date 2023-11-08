local Object = require "lib.object.Object"

local ShipReader = Object:subclass()

function ShipReader:init()
	self.peripheral = peripheral.find("ship_reader")
	ShipReader.superClass.init(self)
end

function ShipReader:getRotation(is_quaternion)
	return self.peripheral.getRotation(is_quaternion)
end

function ShipReader:getWorldspacePosition()
	return self.peripheral.getWorldspacePosition()
end

function ShipReader:getShipID()
	return self.peripheral.getShipID()
end

function ShipReader:getMass()
	return self.peripheral.getMass()
end

function ShipReader:updateShipReader()
	
end


return ShipReader