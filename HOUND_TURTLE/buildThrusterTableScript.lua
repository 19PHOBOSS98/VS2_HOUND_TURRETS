local ThrusterTableBuilder = require "lib.jacobian.ThrusterTableBuilder"
local ShipReaderSP = require "lib.sensory.ShipReaderSP"
local JSON = require "lib.JSON"
--[[
--ttthc_sp.nbt--
local thrusters = {
	{vector.new(-28620798,-52,12290056),"south"}, --BOW_F
	{vector.new(-28620798,-51,12290055),"west"}, --BOW_CCT
	{vector.new(-28620798,-53,12290055),"east"}, --BOW_CCB
	{vector.new(-28620799,-52,12290055),"up"}, --BOW_CR
	{vector.new(-28620797,-52,12290055),"down"}, --BOW_CL
	{vector.new(-28620798,-52,12290052),"north"}, --STERN_B
	{vector.new(-28620798,-51,12290053),"west"}, --STERN_CCT
	{vector.new(-28620798,-53,12290053),"east"}, --STERN_CCB
	{vector.new(-28620799,-52,12290053),"up"}, --STERN_CR
	{vector.new(-28620797,-52,12290053),"down"}, --STERN_CL
}
]]--

--ttthc_sp inverted--
local thrusters = {
	{vector.new(-28620798,-52,12290056),"north"},
	{vector.new(-28620798,-51,12290055),"east"},
	{vector.new(-28620798,-53,12290055),"west"},
	{vector.new(-28620799,-52,12290055),"down"},
	{vector.new(-28620797,-52,12290055),"up"},
	{vector.new(-28620798,-52,12290052),"south"},
	{vector.new(-28620798,-51,12290053),"east"},
	{vector.new(-28620798,-53,12290053),"west"},
	{vector.new(-28620799,-52,12290053),"down"},
	{vector.new(-28620797,-52,12290053),"up"},
}

local thrusterTableBuilder = ThrusterTableBuilder(thrusters,"./input_thruster_table/thruster_table.json")

local shipReaderSP = ShipReaderSP()
thrusterTableBuilder:build(shipReaderSP:getShipYardCenterOfMass())-- writes a thruster_table.json file