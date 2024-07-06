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
function Path:getNormalizedCoordsWithGradientsAndNormals(resolution,bLooped)
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
		
		prev_normal = normal
		table.insert(coords,{pos=pos,gradient=gradient,normal=normal})
	end
	return coords
end

function Path:getRMF(resolution,bLooped)
	local frames = {}
	frames[1]=self:getFrenetFrame(0,bLooped)
	
	for t0=0,self.total_spline_length,resolution do
		local x0 = frames[#frames]
		local t1 = t0 + resolution
		if(t1>self.total_spline_length) then
			break
		end
		local x1 = self:getFrenetFrame(t1,bLooped)
		
		local v1 = x1.pos - (x0.pos);
		local c1 = v1:dot(v1);
		local riL = x0.rotationalAxis - (v1*( 2/c1 * v1:dot(x0.rotationalAxis) ));
		local tiL = x0.gradient - (v1*( 2/c1 * v1:dot(x0.gradient) ));

		v2 = x1.gradient - (tiL);
		c2 = v2:dot(v2);
		riN = riL - (v2*( 2/c2 * v2:dot(riL) ));
		siN = x1.gradient:cross(riN);
		x1.normal = siN;
		x1.rotationalAxis= riN;

		table.insert(frames,x1)
	end
	return frames
end

function Path:getFrenetFrame(t,bLooped)
	local offset = self:getNormalisedOffset(t)
	local pos = self:getSplinePoint(offset,bLooped).pos
	local tangent_1 = self:getSplineGradient(offset,bLooped):normalize()
	local tangent_2 = self:getSplineSecondDerivative(offset, bLooped) + tangent_1
	local rotationalAxis = tangent_1:cross(tangent_2):normalize()
	local normal = self:getSplineNormalVector(offset,bLooped)
	
	--return {pos=pos,gradient=tangent_1,normal=normal,rotationalAxis=rotationalAxis,t=offset}
	return {pos=pos,gradient=tangent_1,normal=normal,rotationalAxis=rotationalAxis}
end

return Path