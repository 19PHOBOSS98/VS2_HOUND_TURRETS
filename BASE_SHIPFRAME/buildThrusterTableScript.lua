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
--[[
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
}]]--

--[[
--ttthc_sp inverted lateral Z--
-- too easy to spin out of control. It would eventually come back but first it has to tour the 4th dimension
local thrusters = {
	{vector.new(-28620798,-52,12290056),"north"}, --BOW_F
	{vector.new(-28620798,-51,12290055),"west"}, --BOW_CCT
	{vector.new(-28620798,-53,12290055),"east"}, --BOW_CCB
	{vector.new(-28620799,-52,12290055),"up"}, --BOW_CR
	{vector.new(-28620797,-52,12290055),"down"}, --BOW_CL
	{vector.new(-28620798,-52,12290052),"south"}, --STERN_B
	{vector.new(-28620798,-51,12290053),"west"}, --STERN_CCT
	{vector.new(-28620798,-53,12290053),"east"}, --STERN_CCB
	{vector.new(-28620799,-52,12290053),"up"}, --STERN_CR
	{vector.new(-28620797,-52,12290053),"down"}, --STERN_CL
}]]--

--tttvc_sp.nbt & 12ttvc_sp.nbt--
local thrusters = {
	{vector.new(-28665858,-47,12290062),"up"}, --BOW_U
	{vector.new(-28665858,-48,12290063),"east"}, --BOW_CCF
	{vector.new(-28665858,-48,12290061),"west"}, --BOW_CCB
	{vector.new(-28665857,-48,12290062),"south"}, --BOW_CL
	{vector.new(-28665859,-48,12290062),"north"}, --BOW_CR
	{vector.new(-28665858,-51,12290062),"down"}, --STERN_D
	{vector.new(-28665858,-50,12290063),"east"}, --STERN_CCF
	{vector.new(-28665858,-50,12290061),"west"}, --STERN_CCB
	{vector.new(-28665857,-50,12290062),"south"}, --STERN_CL
	{vector.new(-28665859,-50,12290062),"north"}, --STERN_CR
}

local thrusterTableBuilder = ThrusterTableBuilder(thrusters,"./input_thruster_table/thruster_table.json")

local shipReaderSP = ShipReaderSP()
thrusterTableBuilder:build(shipReaderSP:getShipYardCenterOfMass())-- writes a thruster_table.json file