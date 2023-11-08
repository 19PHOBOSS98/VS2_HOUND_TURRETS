local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretBaseInfiniteAmmo = require "lib.tilt_ships.HoundTurretBaseInfiniteAmmo"

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


local HoundTurretInfiniteAmmo8Barrel = HoundTurretBaseInfiniteAmmo:subclass()


--overridden functions--
function HoundTurretInfiniteAmmo8Barrel:alternateFire(step)
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

function HoundTurretInfiniteAmmo8Barrel:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	--it_hound_8b_inf.nbt--
	--bare template--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(29189.344183819994,0.0,200.0),
	y=vector.new(0.0,22660.0,-2.8421709430404007E-14),
	z=vector.new(200.0,-2.8421709430404007E-14,23729.344183819994)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(3.426105591006253E-5,-3.6218903081060128E-25,-2.887652995772521E-7),
	y=vector.new(-3.621890308106016E-25,4.41306266548985E-5,5.286030139967415E-23),
	z=vector.new(-2.887652995772522E-7,5.286030139967413E-23,4.2144348588521514E-5)
	}
	--bare template--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretInfiniteAmmo8Barrel.superClass.init(self,configs)
end
--overridden functions--

return HoundTurretInfiniteAmmo8Barrel