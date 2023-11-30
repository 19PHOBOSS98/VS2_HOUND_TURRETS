local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretBaseCreateVault = require "lib.tilt_ships.HoundTurretBaseCreateVault"

local sqrt = math.sqrt
local abs = math.abs
local max = math.max
local min = math.min
local mod = math.fmod
local cos = math.cos
local sin = math.sin
local acos = math.acos
local pi = math.pi
local clamp = utilities.clamp
local sign = utilities.sign

local quadraticSolver = utilities.quadraticSolver
local getTargetAimPos = targeting_utilities.getTargetAimPos
local getQuaternionRotationError = flight_utilities.getQuaternionRotationError
local getLocalPositionError = flight_utilities.getLocalPositionError
local adjustOrbitRadiusPosition = flight_utilities.adjustOrbitRadiusPosition
local getPlayerLookVector = player_spatial_utilities.getPlayerLookVector
local getPlayerHeadOrientation = player_spatial_utilities.getPlayerHeadOrientation
local rotateVectorWithPlayerHead = player_spatial_utilities.rotateVectorWithPlayerHead
local PlayerVelocityCalculator = player_spatial_utilities.PlayerVelocityCalculator
local RadarSystems = targeting_utilities.RadarSystems
local TargetingSystem = targeting_utilities.TargetingSystem
local IntegerScroller = utilities.IntegerScroller
local IndexedListScroller = list_manager.IndexedListScroller


local HoundTurretCreateVault16Barrel = HoundTurretBaseCreateVault:subclass()


--overridden functions--
function HoundTurretCreateVault16Barrel:alternateFire(step)
	--[[
		side_index:
		1="front"
		2="left"
		3="back"
		4="right"
	]]--
	local seq_1 = step==0
	local seq_2 = step==1
	--{hub_index, redstoneIntegrator_index, side_index}
	self:activateGun({"front",1,4},seq_1)
	self:activateGun({"front",2,4},seq_1)
	self:activateGun({"front",3,4},seq_1)
	self:activateGun({"front",4,4},seq_1)
	self:activateGun({"front",5,4},seq_1)
	self:activateGun({"front",6,4},seq_1)
	
	self:activateGun({"front",1,3},seq_2)
	self:activateGun({"front",2,3},seq_2)
	self:activateGun({"front",3,3},seq_2)
	self:activateGun({"front",4,3},seq_2)
	self:activateGun({"front",5,3},seq_2)
	self:activateGun({"front",6,3},seq_2)
	
	self:activateGun({"front",7,3},true)--constant fire
	self:activateGun({"front",8,3},true)
	self:activateGun({"front",9,3},true)
	self:activateGun({"front",10,3},true)
end
--overridden functions--

return HoundTurretCreateVault16Barrel