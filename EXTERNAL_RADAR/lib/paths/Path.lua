local list_manager = require "lib.list_manager"
local Spline = require "lib.paths.Spline"

local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local min = math.min
local mod = math.fmod
local cos = math.cos
local sin = math.sin
local acos = math.acos
local floor = math.floor
local pi = math.pi
local loopScrollIndex = list_manager.loopScrollIndex

local Path = Spline:subclass()

function Path:init(points_list,bLooped)
	Path.superClass.init(self,points_list)
	self:recalculateSplineLengths(bLooped)
end

function Path:getCoords(resolution,bLooped)
	local end_index = bLooped and #self.points or #self.points - 3
	local coords = {}
	for t=0,end_index,resolution do
		table.insert(coords,self:getSplinePoint(t,bLooped).pos)
	end
	return coords
end

function Path:getNormalizedCoords(resolution,bLooped)
	local coords = {}
	for t=0,self.total_spline_length,resolution do
		table.insert(coords,self:getNormalizedSplinePoint(t,bLooped))
	end
	return coords
end

function Path:getCoordsWithGradients(resolution,bLooped)
	local end_index = bLooped and #self.points or #self.points - 3
	local coords = {}
	for t=0,end_index,resolution do
		table.insert(coords,self:getSplinePointWithGradient(t,bLooped))
	end
	return coords
end

function Path:getNormalizedCoordsWithGradients(resolution,bLooped)
	local coords = {}
	for t=0,self.total_spline_length,resolution do
		table.insert(coords,self:getNormalizedSplinePointWithGradient(t,bLooped))
	end
	return coords
end

--https://stackoverflow.com/questions/25453159/getting-consistent-normals-from-a-3d-cubic-bezier-path--
function Spline:getNormalizedCoordsWithGradientsAndNormals(resolution,bLooped)
	local coords = {}
	
	local prev_normal = vector.new(0,1,0)
	for t=0,self.total_spline_length,resolution do
		local offset = self:getNormalisedOffset(t)
		local pos = self:getSplinePoint(offset,bLooped).pos
		local gradient = self:getSplineGradient(offset,bLooped)
		local normal = self:getSplineNormalVector(offset,bLooped)
		if (normal == nil) then
			normal = prev_normal
		end
		
		prev_normal = normal --I should really be using a Rotation Minimising Frame algorithm ...but meh
		table.insert(coords,{pos=pos,gradient=gradient,normal=normal})
	end
	return coords
end

return Path