local JSON = require "lib.JSON"

local Object = require "lib.object.Object"

local ThrusterTableBuilder = Object:subclass()

local thruster_direction = {
	["up"] = vector.new(0,1,0),
	["down"] = vector.new(0,-1,0),
	["north"] = vector.new(0,0,-1),
	["south"] = vector.new(0,0,1),
	["east"] = vector.new(1,0,0),
	["west"] = vector.new(-1,0,0),
}

function ThrusterTableBuilder:init(input_thrusters,directory)
	self.directory = directory or "./input_thruster_table/thruster_table.json"
	self.input_thrusters = input_thrusters --{{shipyard_pos, direction}}
	for i,v in pairs(self.input_thrusters) do
		v[2] = thruster_direction[v[2]]
	end
	
	ThrusterTableBuilder.superClass.init(self)
end

function ThrusterTableBuilder:saveThrusterTableJSONFile(t)
	local h = fs.open(self.directory,"w")
	h.writeLine(JSON:encode_pretty(t))
	h.flush()
	h.close()
end

function ThrusterTableBuilder:build(center_of_mass)
	self.thruster_table = {} --{{radius, direction}}
	for i,v in pairs(self.input_thrusters) do
		self.thruster_table[i] = {}
		centered_thruster_pos = v[1] + vector.new(0.5,0.5,0.5)
		radius = centered_thruster_pos-center_of_mass
		radius.x = math.floor(radius.x*100)/100
		radius.y = math.floor(radius.y*100)/100
		radius.z = math.floor(radius.z*100)/100
		self.thruster_table[i].radius = radius
		self.thruster_table[i].direction = v[2]
	end
	
	self:saveThrusterTableJSONFile(self.thruster_table)
end

return ThrusterTableBuilder