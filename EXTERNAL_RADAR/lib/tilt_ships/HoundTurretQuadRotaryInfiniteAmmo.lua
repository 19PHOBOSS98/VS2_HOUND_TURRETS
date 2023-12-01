local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretQuadRotary = require "lib.tilt_ships.HoundTurretQuadRotary"

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


local HoundTurretQuadRotaryInfiniteAmmo = HoundTurretQuadRotary:subclass()


--overridden functions--
function HoundTurretQuadRotaryInfiniteAmmo:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1

	self:activateGun({"front",1,4},seq_1)
	self:activateGun({"front",2,4},seq_1)
	self:activateGun({"front",3,4},seq_1)
	self:activateGun({"front",4,4},seq_1)
	
	self:activateGun({"front",1,2},seq_2)
	self:activateGun({"front",2,2},seq_2)
	self:activateGun({"front",3,2},seq_2)
	self:activateGun({"front",4,2},seq_2)
end

function HoundTurretQuadRotaryInfiniteAmmo:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(25252.312714215775,-3.923539403532816E-14,199.99999999999994),
	y=vector.new(-3.923539403532816E-14,21880.0,-2.0077746476250713E-13),
	z=vector.new(199.99999999999994,-2.0077746476250713E-13,20572.31271421576)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(3.960338265195211E-5,6.748408222128504E-23,-3.8501633921387613E-7),
	y=vector.new(6.748408222128504E-23,4.5703839122486285E-5,4.453949470712841E-22),
	z=vector.new(-3.850163392138756E-7,4.453949470712838E-22,4.861276498955685E-5)
	}
	--bare template--
	
	--steampunk skin, paste in firmwareScript.lua--
	--[[
	LOCAL_INERTIA_TENSOR = 
	{
	x=vector.new(237421.74031699382,-9.094947017729282E-13,200.0),
	y=vector.new(-9.094947017729282E-13,150280.0,0.0),
	z=vector.new(200.0,0.0,232741.74031699385)
	},
	LOCAL_INV_INERTIA_TENSOR = 
	{
	x=vector.new(4.211917251314582E-6,2.5490527178444295E-23,-3.619391386846177E-9),
	y=vector.new(2.5490527178444295E-23,6.654245408570668E-6,-2.1904560087697426E-26),
	z=vector.new(-3.6193913868461754E-9,-2.190456008769742E-26,4.296611009766784E-6)
	},
	]]--
	--steampunk skin, paste in firmwareScript.lua--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretQuadRotaryInfiniteAmmo.superClass.init(self,configs)
end
--overridden functions--

return HoundTurretQuadRotaryInfiniteAmmo