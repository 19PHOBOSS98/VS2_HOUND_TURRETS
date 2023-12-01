local list_manager = require "lib.list_manager"
local Object = require "lib.object.Object"

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
--[[
OneLoneCoder.com - Splines Part 2
"Bendier Wavier Curlier" - @Javidx9

License
~~~~~~~
Copyright (C) 2018  Javidx9
This program comes with ABSOLUTELY NO WARRANTY.
This is free software, and you are welcome to redistribute it
under certain conditions; See license for details. 
Original works located at:
https://www.github.com/onelonecoder
https://www.onelonecoder.com
https://www.youtube.com/javidx9

GNU GPLv3
https://github.com/OneLoneCoder/videos/blob/master/LICENSE

From Javidx9 :)
~~~~~~~~~~~~~~~
Hello! Ultimately I don't care what you use this for. It's intended to be 
educational, and perhaps to the oddly minded - a little bit of fun. 
Please hack this, change it and use it in any way you see fit. You acknowledge 
that I am not responsible for anything bad that happens as a result of 
your actions. However this code is protected by GNU GPLv3, see the license in the
github repo. This means you must attribute me if you use it. You can view this
license here: https://github.com/OneLoneCoder/videos/blob/master/LICENSE
Cheers!


Background
~~~~~~~~~~
Curvy things are always better. Splines are a nice way to approximate
curves and loops for games. This video is the first of two parts
demonstrating how Catmull-Rom splines can be implemented.

Use Z + X to select a point and move it with the arrow keys
Use A + S to move the agent around the spline loop

Author
~~~~~~
Twitter: @javidx9
Blog: www.onelonecoder.com

Video:
~~~~~~
https://youtu.be/9_aJGUTePYo
https://youtu.be/DzjtU4WLYNs

Last Updated: 25/09/2017

Rewritten in Lua by: 19PHOBOSS98
August 11, 2023
]]--

function SplinePoint(pos,len)
	return{
		pos = pos,
		length = len
	}
end

local Spline = Object:subclass()

function Spline:init(points_list)
	self.points = points_list or {}
	self.total_spline_length = 0
end

function Spline:recalculateSplineLengths(bLooped)
	local end_index = bLooped and #self.points or #self.points - 3
	self.total_spline_length = 0
	for i=0,end_index-1,1 do
		local length = self:calculateSegmentLength(i, bLooped)
		self.points[i+1].length = length
		self.total_spline_length = self.total_spline_length + length
	end
end

function Spline:getPointsIndex(t,bLooped)
	local  p0, p1, p2, p3
	if (not bLooped) then
		p1 = floor(t) + 1 + 1
		p2 = p1 + 1 
		p3 = p2 + 1 
		p0 = p1 - 1 
	else
		p1 = floor(t)+1
		p2 = loopScrollIndex((p1 + 1),#self.points)
		p3 = loopScrollIndex((p2 + 1),#self.points)
		p0 = loopScrollIndex((p1 - 1),#self.points)
	end
	return p0,p1,p2,p3
end

function Spline:calculateSegmentLength(node, bLooped)
	bLooped = bLooped or false
	local length = 0.0
	local step_size = 0.005

	local old_point
	local new_point
	old_point = self:getSplinePoint(node, bLooped)

	for t = 0, 1, step_size do
		new_point = self:getSplinePoint(node + t, bLooped)
		length = length+sqrt(	(new_point.pos.x - old_point.pos.x)*(new_point.pos.x - old_point.pos.x)+
								(new_point.pos.y - old_point.pos.y)*(new_point.pos.y - old_point.pos.y)+
								(new_point.pos.z - old_point.pos.z)*(new_point.pos.z - old_point.pos.z))
		old_point = new_point
	end

	return length;
end

function Spline:addSplineControlPoint(pos,bLooped)
	table.insert(self.points,{pos=pos})
	if (bLooped ~= nil) then
		self:recalculateSplineLengths(bLooped)
	end
end

function Spline:getNormalisedOffset(p)
	-- Which node is the base?
	local i = 0;
	while (p > self.points[i+1].length) do
		p = p - self.points[i+1].length;
		i = i + 1;
	end

	-- The fractional is the offset 
	return i + (p / self.points[i+1].length);
end

function Spline:getNormalizedSplinePoint(t,bLooped)
	local offset = self:getNormalisedOffset(t)
	local pos = self:getSplinePoint(offset,bLooped).pos
	return pos
end

function Spline:getSplinePointWithGradient(t,bLooped)
	local pos = self:getSplinePoint(t,bLooped).pos
	local gradient = self:getSplineGradient(t,bLooped)
	return {pos=pos,gradient=gradient}
end

function Spline:getNormalizedSplinePointWithGradient(t,bLooped)
	local offset = self:getNormalisedOffset(t)
	local pos = self:getSplinePoint(offset,bLooped).pos
	local gradient = self:getSplineGradient(offset,bLooped)
	return {pos=pos,gradient=gradient}
end

function Spline:getSplinePosGradientNormal(t,bLooped)
	local offset = self:getNormalisedOffset(t)
	local pos = self:getSplinePoint(offset,bLooped).pos
	local gradient = self:getSplineGradient(offset,bLooped)
	local normal = self:getSplineNormalVector(offset, bLooped)
	return {pos=pos,gradient=gradient,normal=normal}
end

--https://stackoverflow.com/questions/25453159/getting-consistent-normals-from-a-3d-cubic-bezier-path--
function Spline:getSplineNormalVector(t, bLooped)
	local tangent_1 = self:getSplineGradient(t, bLooped):normalize()
	local tangent_2 = self:getSplineSecondDerivative(t, bLooped) + tangent_1
	local binormal = tangent_1:cross(tangent_2)
	local normal = vector.new(0,1,0)
	if (binormal:length()==0) then
		return nil
	else
		binormal = binormal:normalize()
		normal = binormal:cross(tangent_1):normalize()
	end
	return normal
end

function Spline:getSplineSecondDerivative(t, bLooped)
	bLooped = bLooped or false
	local  p0, p1, p2, p3 = self:getPointsIndex(t,bLooped)

	t = t - floor(t)

	local tt = t * t
	local ttt = tt * t

	local q1 = -6.0 * t + 4.0
	local q2 = 18.0*t - 10.0
	local q3 = -18.0*t + 8.0
	local q4 = 6.0*t - 2.0

	local tx = 0.5 * (self.points[p0].pos.x * q1 + self.points[p1].pos.x * q2 + self.points[p2].pos.x * q3 + self.points[p3].pos.x * q4)
	local ty = 0.5 * (self.points[p0].pos.y * q1 + self.points[p1].pos.y * q2 + self.points[p2].pos.y * q3 + self.points[p3].pos.y * q4)
	local tz = 0.5 * (self.points[p0].pos.z * q1 + self.points[p1].pos.z * q2 + self.points[p2].pos.z * q3 + self.points[p3].pos.z * q4)
	
	return vector.new(tx,ty,tz)
end

function Spline:getSplineGradient(t, bLooped)
	bLooped = bLooped or false
	local  p0, p1, p2, p3 = self:getPointsIndex(t,bLooped)

	t = t - floor(t)

	local tt = t * t
	local ttt = tt * t

	local q1 = -3.0 * tt + 4.0*t - 1
	local q2 = 9.0*tt - 10.0*t
	local q3 = -9.0*tt + 8.0*t + 1.0
	local q4 = 3.0*tt - 2.0*t

	local tx = 0.5 * (self.points[p0].pos.x * q1 + self.points[p1].pos.x * q2 + self.points[p2].pos.x * q3 + self.points[p3].pos.x * q4)
	local ty = 0.5 * (self.points[p0].pos.y * q1 + self.points[p1].pos.y * q2 + self.points[p2].pos.y * q3 + self.points[p3].pos.y * q4)
	local tz = 0.5 * (self.points[p0].pos.z * q1 + self.points[p1].pos.z * q2 + self.points[p2].pos.z * q3 + self.points[p3].pos.z * q4)
	
	return vector.new(tx,ty,tz)
end

function Spline:getSplinePoint(t,bLooped)
	bLooped = bLooped or false
	local  p0, p1, p2, p3 = self:getPointsIndex(t,bLooped)
	t = t - floor(t)

	local tt = t * t
	local ttt = tt * t

	local q1 = -ttt + 2.0*tt - t
	local q2 = 3.0*ttt - 5.0*tt + 2.0
	local q3 = -3.0*ttt + 4.0*tt + t
	local q4 = ttt - tt
	
	local tx = 0.5 * (self.points[p0].pos.x * q1 + self.points[p1].pos.x * q2 + self.points[p2].pos.x * q3 + self.points[p3].pos.x * q4)
	local ty = 0.5 * (self.points[p0].pos.y * q1 + self.points[p1].pos.y * q2 + self.points[p2].pos.y * q3 + self.points[p3].pos.y * q4)
	local tz = 0.5 * (self.points[p0].pos.z * q1 + self.points[p1].pos.z * q2 + self.points[p2].pos.z * q3 + self.points[p3].pos.z * q4)

	return SplinePoint(vector.new(tx,ty,tz))
end

return Spline