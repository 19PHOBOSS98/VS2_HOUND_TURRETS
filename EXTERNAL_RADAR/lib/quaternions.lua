--Thanks to ColonelThirtyTwo--
--https://gist.github.com/ColonelThirtyTwo/1735522 --
-- faster access to some math library functions

local utilities = require "lib.utilities"

local abs   = math.abs
local Round = math.Round
local sqrt  = math.sqrt
local exp   = math.exp
local log   = math.log
local sin   = math.sin
local cos   = math.cos
local sinh  = math.sinh
local cosh  = math.cosh
local acos  = math.acos
local asin  = math.asin
local atan  = math.atan

local deg2rad = math.pi/180
local rad2deg = 180/math.pi

local delta = 0.0000001000000

local clamp = utilities.clamp

Quaternion = {}
Quaternion.__index = Quaternion

function Quaternion.new(q,r,s,t)
	--print("newQuat",q,r,s,t)
	return setmetatable({q,r,s,t},Quaternion)
end
local quat_new = Quaternion.new

local function qmul(lhs, rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
	return quat_new(
		lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
		lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
		lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
		lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
	)
end
Quaternion.__mul = qmul

local function qexp(q)
	local m = sqrt(q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	local u1, u2, u3 = 0, 0, 0
	if m ~= 0 then
		u1 = q[2]*sin(m)/m
		u2 = q[3]*sin(m)/m
		u3 = q[4]*sin(m)/m
	end
	local r = exp(q[1])
	return quat_new(r*cos(m), r*u1, r*u2, r*u3)
end

local function qlog(q)
	local l = sqrt(q[1]*q[1] + q[2]*q[2] + q[3]*q[3] + q[4]*q[4])
	if l == 0 then return { -1e+100, 0, 0, 0 } end
	local u2, u3, u4 = q[2]/l, q[3]/l, q[4]/l -- u1 is never used
	local a = acos(u[1])
	local m = sqrt(u2*u2 + u3*u3 + u4*u4)
	if abs(m) > delta then
		return quat_new( log(l), a*u2/m, a*u3/m, a*u4/m )
	else
		return quat_new( log(l), 0, 0, 0 )  --when m is 0, u[2], u[3] and u[4] are 0 too
	end
end
Quaternion.log = qlog

--- Converts <ang> to a quaternion
--[[
function Quaternion.fromAngle(ang)
	local p, y, r = ang.p, ang.y, ang.r
	p = p*deg2rad*0.5
	y = y*deg2rad*0.5
	r = r*deg2rad*0.5
	local qr = {cos(r), sin(r), 0, 0}
	local qp = {cos(p), 0, sin(p), 0}
	local qy = {cos(y), 0, 0, sin(y)}
	return qmul(qy,qmul(qp,qr))
end
]]--
function Quaternion.fromAngle(ang)
	local p, y, r = ang.x, ang.y, ang.z
	p = p*0.5
	y = y*0.5
	r = r*0.5
	local qr = {cos(r), sin(r), 0, 0}
	local qp = {cos(p), 0, sin(p), 0}
	local qy = {cos(y), 0, 0, sin(y)}
	return qmul(qy,qmul(qp,qr))
end


function Quaternion.fromVectors(forward, up)
	local x = forward
	local z = up
	local y = z:cross(x):normalize() --up x forward = left
	
	local ang = x:Angle()
	if ang.p > 180 then ang.p = ang.p - 360 end
	if ang.y > 180 then ang.y = ang.y - 360 end
	
	local yyaw = vector.new(0,1,0)
	yyaw:Rotate(Angle(0,ang.y,0))
	
	local roll = acos(y:Dot(yyaw))*rad2deg
	
	local dot = y:Dot(z)
	if dot < 0 then roll = -roll end
	
	local p, y, r = ang.p, ang.y, roll
	p = p*deg2rad*0.5
	y = y*deg2rad*0.5
	r = r*deg2rad*0.5
	local qr = {cos(r), sin(r), 0, 0}
	local qp = {cos(p), 0, sin(p), 0}
	local qy = {cos(y), 0, 0, sin(y)}
	return qmul(qy,qmul(qp,qr))
end

--https://github.com/topameng/CsToLua/blob/master/tolua/Assets/Lua/Quaternion.lua--
local _next = { 2, 3, 1 }
function Quaternion.lookRotation(z, y)
	local forward = z
	local up = y
	local mag = forward:length()
	if mag < 1e-6 then
		error("error input forward to Quaternion.LookRotation" + tostring(forward))
		return nil
	end
	
	forward = forward:normalize()
	local right = up:cross(forward):normalize()
	up = forward:cross(right)
	right = up:cross(forward)
	
	local t = right.x + up.y + forward.z

	if t > 0 then
		local x,y,z,w
		t = t + 1
		local s = 0.5 / sqrt(t)
		w = s * t
		x = (up.z - forward.y) * s		
		y = (forward.x - right.z) * s
		z = (right.y - up.x) * s
		
		return quat_new(w, x, y, z):normalize()
	else
		local rot = 
		{ 					
			{right.x, up.x, forward.x},
			{right.y, up.y, forward.y},
			{right.z, up.z, forward.z},
		}
	
		local q = {0, 0, 0}
		local i = 1		
		
		if up.y > right.x then			
			i = 2			
		end
		
		if forward.z > rot[i][i] then
			i = 3			
		end
		
		local j = _next[i]
		local k = _next[j]
		
		local t = rot[i][i] - rot[j][j] - rot[k][k] + 1
		local s = 0.5 / sqrt(t)
		q[i] = s * t
		local w = (rot[k][j] - rot[j][k]) * s
		q[j] = (rot[j][i] + rot[i][j]) * s
		q[k] = (rot[k][i] + rot[i][k]) * s
		
		return quat_new(w, q[1], q[2], q[3]):normalize()		
	end
	
end
--https://github.com/topameng/CsToLua/blob/master/tolua/Assets/Lua/Quaternion.lua--


--- Returns quaternion for rotation about axis <axis> by angle <ang>. If ang is left out, then it is computed as the magnitude of <axis>
function Quaternion.fromRotation(axis, ang)
	if ang then
		axis:normalize()--PHOBOSS:computer craft class function
		local ang2 = ang*deg2rad*0.5
		return quat_new( cos(ang2), axis.x*sin(ang2), axis.y*sin(ang2), axis.z*sin(ang2) )
	else
		local angSquared = axis:LengthSqr()
		if angSquared == 0 then return quat_new( 1, 0, 0, 0 ) end
		local len = sqrt(angSquared)
		local ang = (len + 180) % 360 - 180
		local ang2 = ang*deg2rad*0.5
		local sang2len = sin(ang2) / len
		return quat_new( cos(ang2), rv1[1] * sang2len , rv1[2] * sang2len, rv1[3] * sang2len )
	end
end

function Quaternion:__neg()
	return quat_new( -self[1], -self[2], -self[3], -self[4] )
end

function Quaternion.__add(lhs, rhs)
	return quat_new( lhs[1] + rhs[1], lhs[2] + rhs[2], lhs[3] + rhs[3], lhs[4] + rhs[4] )
end

function Quaternion.__sub(lhs, rhs)
	return quat_new( lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4] )
end

function Quaternion.__mul(lhs, rhs)
	
	if type(rhs) == "number" then
		return quat_new( rhs * lhs[1], rhs * lhs[2], rhs * lhs[3], rhs * lhs[4] )
	elseif rhs.x then --PHOBOSS: computercraft "vector" object still is type:"table"
		local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
		local rhs2, rhs3, rhs4 = rhs.x, rhs.y, rhs.z
		return quat_new(
			-lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
			 lhs1 * rhs2 + lhs3 * rhs4 - lhs4 * rhs3,
			 lhs1 * rhs3 + lhs4 * rhs2 - lhs2 * rhs4,
			 lhs1 * rhs4 + lhs2 * rhs3 - lhs3 * rhs2
		)
	else
		local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
		local rhs1, rhs2, rhs3, rhs4 = rhs[1], rhs[2], rhs[3], rhs[4]
		return quat_new(
			lhs1 * rhs1 - lhs2 * rhs2 - lhs3 * rhs3 - lhs4 * rhs4,
			lhs1 * rhs2 + lhs2 * rhs1 + lhs3 * rhs4 - lhs4 * rhs3,
			lhs1 * rhs3 + lhs3 * rhs1 + lhs4 * rhs2 - lhs2 * rhs4,
			lhs1 * rhs4 + lhs4 * rhs1 + lhs2 * rhs3 - lhs3 * rhs2
		)
	end
end

function Quaternion.__div(lhs, rhs)
	local lhs1, lhs2, lhs3, lhs4 = lhs[1], lhs[2], lhs[3], lhs[4]
	return quat_new(
		lhs1/rhs,
		lhs2/rhs,
		lhs3/rhs,
		lhs4/rhs
	)
end

function Quaternion.__pow(lhs, rhs)
	local l = qlog(lhs)
	return qexp({ l[1]*rhs, l[2]*rhs, l[3]*rhs, l[4]*rhs })
end

function Quaternion.__eq(lhs, rhs)
	if getmetatable(lhs) ~= Quaternion or getmetatable(lhs) ~= getmetatable(rhs) then return false end
	local rvd1, rvd2, rvd3, rvd4 = lhs[1] - rhs[1], lhs[2] - rhs[2], lhs[3] - rhs[3], lhs[4] - rhs[4]
	return rvd1 <= delta and rvd1 >= -delta and
	   rvd2 <= delta and rvd2 >= -delta and
	   rvd3 <= delta and rvd3 >= -delta and
	   rvd4 <= delta and rvd4 >= -delta
end

--- Returns absolute value of self
function Quaternion:abs()
	return sqrt(self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4])
end

--- Returns the conjugate of self
function Quaternion:conj()
	return quat_new(self[1], -self[2], -self[3], -self[4])
end

--- Returns the inverse of self
function Quaternion:inv()
	local li = 1/(self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4])
	return quat_new( self[1]*li, -self[2]*li, -self[3]*li, -self[4]*li )--PHOBOSS: should be faster than dividing each
end

--- Raises Euler's constant e to the power self
function Quaternion:exp()
	return qexp(self)
end

--- Calculates natural logarithm of self
function Quaternion:log()
	return qlog(self)
end

--- Changes quaternion <self> so that the represented rotation is by an angle between 0 and 180 degrees (by coder0xff)
function Quaternion:mod()
	if self[1]<0 then return quat_new(-self[1], -self[2], -self[3], -self[4]) else return quat_new(self[1], self[2], self[3], self[4]) end
end

--- Performs spherical linear interpolation between <q0> and <q1>. Returns <q0> for <t>=0, <q1> for <t>=1
--[[function Quaternion.slerp(q0, q1, t)
	local dot = q0[1]*q1[1] + q0[2]*q1[2] + q0[3]*q1[3] + q0[4]*q1[4]
	local q11
	if dot<0 then
		q11 = {-q1[1], -q1[2], -q1[3], -q1[4]}
	else
		q11 = { q1[1], q1[2], q1[3], q1[4] }  -- dunno if just q11 = q1 works
	end
	
	local l = q0[1]*q0[1] + q0[2]*q0[2] + q0[3]*q0[3] + q0[4]*q0[4]
	if l==0 then return { 0, 0, 0, 0 } end
	local invq0 = { q0[1]/l, -q0[2]/l, -q0[3]/l, -q0[4]/l }
	local logq = qlog(qmul(invq0,q11))
	local q = qexp( { logq[1]*t, logq[2]*t, logq[3]*t, logq[4]*t } )
	return qmul(q0,q)
end
]]--

--- Returns the difference between two quaternions
function Quaternion.diff(q1,q2)
	local diff = quat_new(0,0,0,0)
	
	--diff * q1 = q2
	diff = q2 * q1:inv()
	
	diff:normalize()
	return diff
end

--https://github.com/topameng/CsToLua/blob/master/tolua/Assets/Lua/Quaternion.lua--
function Quaternion.Dot(a, b)
	return a[2] * b[2] + a[3] * b[3] + a[4] * b[4] + a[1] * b[1]
end

function Quaternion.Lerp(q1, q2, t)
	t = clamp(t, 0, 1)
	local q = quat_new(0,0,0,0)	
	
	if Quaternion.Dot(q1, q2) < 0 then
		q[2] = q1[2] + t * (-q2[2] -q1[2])
		q[3] = q1[3] + t * (-q2[3] -q1[3])
		q[4] = q1[4] + t * (-q2[4] -q1[4])
		q[1] = q1[1] + t * (-q2[1] -q1[1])
	else
		q[2] = q1[2] + (q2[2] - q1[2]) * t
		q[3] = q1[3] + (q2[3] - q1[3]) * t
		q[4] = q1[4] + (q2[4] - q1[4]) * t
		q[1] = q1[1] + (q2[1] - q1[1]) * t
	end	
	
	q:normalize()
	return q
end

function Quaternion.slerp(from, to, t)
	t = clamp(t, 0, 1)
	local cosAngle = Quaternion.Dot(from, to)
	if cosAngle < 0 then    
        cosAngle = -cosAngle
        to = quat_new(-to[1], -to[2], -to[3], -to[4])
    end
	
	local t1, t2
    
    if cosAngle < 0.95 then    
	    local angle 	= acos(cosAngle)
		local sinAngle 	= sin(angle)
        local invSinAngle = 1 / sinAngle
        t1 = sin((1 - t) * angle) * invSinAngle
        t2 = sin(t * angle) * invSinAngle    
		local quat = quat_new(from[1] * t1 + to[1] * t2, from[2] * t1 + to[2] * t2, from[3] * t1 + to[3] * t2, from[4] * t1 + to[4] * t2)
		return quat
    else    
		return Quaternion.Lerp(from, to, t)
    end
end
--https://github.com/topameng/CsToLua/blob/master/tolua/Assets/Lua/Quaternion.lua--

--[[
PHOBOSS: these functions have been converted to follow Minecraft Coordinate Convention:
+x == East
+y == Up
+z == South
]]--

function Quaternion:normalize()
	local inv_length = 1/sqrt(self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4])
	return quat_new(self[1]*inv_length,self[2]*inv_length,self[3]*inv_length,self[4]*inv_length)
end

--returns quaternion representing rotation from v0 to v1
function Quaternion.fromToRotation(v0, v1)
	--print("v0: "..v0:tostring())
	--print("v1: "..v1:tostring())
	local dp = v0:dot(v1)
	--print("dp: "..dp)
	local cp = vector.new(0,0,0)
	if (dp<-0.9999999) then
		cp = v0:cross(vector.new(0,1,0))
		return Quaternion.fromRotation(cp, 180):normalize()
	elseif(dp>0.9999999) then
		return quat_new(1,0,0,0)
	end
	cp = v0:cross(v1)
	local qw = sqrt(v0:dot(v0) * v1:dot(v1)) + dp
	return quat_new(qw,cp.x,cp.y,cp.z):normalize()
end

--- Returns basis vector pointing local minecraftPositiveX for <self>
function Quaternion:localPositiveX()
	local this1, this2, this3, this4 = self[1], self[2], self[3], self[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return vector.new(
		this1 * this1 + this2 * this2 - this3 * this3 - this4 * this4,
		t3 * this2 + t4 * this1,
		t4 * this2 - t3 * this1
	)
end

--- Returns basis vector pointing local minecraftPositiveY for <self>
function Quaternion:localPositiveY()
	local this1, this2, this3, this4 = self[1], self[2], self[3], self[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return vector.new(
		- t4 * this1 + t2 * this3,
		- this2 * this2 + this1 * this1 - this4 * this4 + this3 * this3,
		t2 * this1 + t3 * this4
	)
end

--- Returns basis vector pointing local minecraftPositiveZ for <self>
function Quaternion:localPositiveZ()
	local this1, this2, this3, this4 = self[1], self[2], self[3], self[4]
	local t2, t3, t4 = this2 * 2, this3 * 2, this4 * 2
	return vector.new(
		t3 * this1 + t2 * this4,
		t3 * this4 - t2 * this1,
		this1 * this1 - this2 * this2 - this3 * this3 + this4 * this4
	)
end

--[[
PHOBOSS: these functions have been converted to follow Minecraft Coordinate Convention:
+x == East
+y == Up
+z == South
]]--
--PHOBOSS: had to add these--
function Quaternion:rotateVector3(vec)
	local rotated_vector = Quaternion.__mul(self,vec)
	rotated_vector = Quaternion.__mul(rotated_vector,self:inv())
	--print("rotated_vector: "..rotated_vector[2].." "..rotated_vector[3].." "..rotated_vector[4])
	rotated_vector = vector.new(rotated_vector[2],rotated_vector[3],rotated_vector[4])
	--print("rotated_vector: "..rotated_vector:tostring())
	return rotated_vector
end

function Quaternion.rotateVectorByAxis(vec,axis,angle)
	local rotation_axis_offset = Quaternion.fromRotation(axis, angle)
	local rotated_vector = rotation_axis_offset:rotateVector3(vec)
	return rotated_vector
end

--thanks to acreol, https://devforum.roblox.com/t/vector3slerpv2t-unclamped/296542--
function Quaternion.slerpVector(vec0,vec1,weight)

	if weight==0 then return vec0
	elseif weight==1 then return vec1
	elseif vec0 == vec1 then return vec0
	else
		local cross = vec0:cross(vec1)
		local angle = asin(cross:length())*weight
		return Quaternion.rotateVectorByAxis(vec0,cross:normalize(),angle)
	end
end
--thanks to acreol, https://devforum.roblox.com/t/vector3slerpv2t-unclamped/296542--

--FOR VS2-COMPUTERS UPDATE: INERTIA TENSORS --
--https://gamedev.stackexchange.com/questions/140860/transform-inertia-tensor-using-quaternion--
--[[
	tensor = {
	x = vector.new(x,y,z),
	y = vector.new(x,y,z),
	z = vector.new(x,y,z),
	}
]]--
function Quaternion.rotateTensor(tensor,new_rotation)
	c1 = vector.new(tensor.x.x,tensor.y.x,tensor.z.x);
	c2 = vector.new(tensor.x.y,tensor.y.y,tensor.z.y);
	c3 = vector.new(tensor.x.z,tensor.y.z,tensor.z.z);
	
	cc1 = new_rotation:inv():rotateVector3(c1);
	cc2 = new_rotation:inv():rotateVector3(c2);
	cc3 = new_rotation:inv():rotateVector3(c3);
	
	rr1 = vector.new(cc1.x,cc2.x,cc3.x);
	rr2 = vector.new(cc1.y,cc2.y,cc3.y);
	rr3 = vector.new(cc1.z,cc2.z,cc3.z);
	
	rrr1 = new_rotation:inv():rotateVector3(rr1);
	rrr2 = new_rotation:inv():rotateVector3(rr2);
	rrr3 = new_rotation:inv():rotateVector3(rr3);
	
	ccc1 = vector.new(rrr1.x,rrr2.x,rrr3.x);
	ccc2 = vector.new(rrr1.y,rrr2.y,rrr3.y);
	ccc3 = vector.new(rrr1.z,rrr2.z,rrr3.z);
	
	return {
		x=vector.new(rrr1.x,rrr2.x,rrr3.x),
		y=vector.new(rrr1.y,rrr2.y,rrr3.y),
		z=vector.new(rrr1.z,rrr2.z,rrr3.z)
	}
end
--FOR VS2-COMPUTERS UPDATE: INERTIA TENSORS --



--PHOBOSS:--

--- Returns the angle of rotation in degrees
function Quaternion:rotationAngle()
	local l2 = self[1]*self[1] + self[2]*self[2] + self[3]*self[3] + self[4]*self[4]
	if l2 == 0 then return 0 end
	local l = sqrt(l2)
	local ang = 2*acos(self[1]/l)*rad2deg  --this returns angle from 0 to 360
	if ang > 180 then ang = ang - 360 end  --make it -180 - 180
	return ang
end

--- Returns the axis of rotation
function Quaternion:rotationAxis()
	local m2 = self[2] * self[2] + self[3] * self[3] + self[4] * self[4]
	if m2 == 0 then return vector.new( 0, 0, 1 ) end
	local mi = 1/sqrt(m2)
	return vector.new( self[2] * mi, self[3] * mi, self[4] * mi) --PHOBOSS: should be faster than dividing each
end

--- Returns angle represented by <self>
function Quaternion:toAngle()
	local l = sqrt(self[1]*self[1]+self[2]*self[2]+self[3]*self[3]+self[4]*self[4])
	local q1, q2, q3, q4 = self[1]/l, self[2]/l, self[3]/l, self[4]/l
	
	local x = vector.new(q1*q1 + q2*q2 - q3*q3 - q4*q4,
		2*q3*q2 + 2*q4*q1,
		2*q4*q2 - 2*q3*q1)
		
	local y = vector.new(2*q2*q3 - 2*q4*q1,
		q1*q1 - q2*q2 + q3*q3 - q4*q4,
		2*q2*q1 + 2*q3*q4)
		
	local ang = x:Angle()
	if ang.p > 180 then ang.p = ang.p - 360 end
	if ang.y > 180 then ang.y = ang.y - 360 end
	
	local yyaw = vector.new(0,1,0)
	yyaw:Rotate(Angle(0,ang.y,0))
	
	local roll = acos(y:Dot(yyaw))*rad2deg
	
	local dot = q2*q1 + q3*q4
	if dot < 0 then roll = -roll end
	
	return Angle(ang.p, ang.y, roll)
end

function Quaternion:__concat()
	return string.format("<%d,%d,%d,%d>",self[1],self[2],self[3],self[4])
end

function Quaternion:tostring()
	return string.format("<%d,%d,%d,%d>",self[1],self[2],self[3],self[4])
end

return Quaternion