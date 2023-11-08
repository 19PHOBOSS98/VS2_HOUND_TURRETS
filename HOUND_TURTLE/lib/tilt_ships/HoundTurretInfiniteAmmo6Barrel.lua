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


local HoundTurretInfiniteAmmo6Barrel = HoundTurretBaseInfiniteAmmo:subclass()


--overridden functions--
function HoundTurretInfiniteAmmo6Barrel:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1
	--{hub_index, redstoneIntegrator_index, side_index}
	self:activateGun({"bottom",1,4},seq_1)
	self:activateGun({"bottom",2,4},seq_1)
	self:activateGun({"bottom",3,4},seq_1)
	self:activateGun({"bottom",4,4},seq_1)
	
	self:activateGun({"bottom",1,2},seq_2)
	self:activateGun({"bottom",2,2},seq_2)
	self:activateGun({"bottom",3,2},seq_2)
	self:activateGun({"bottom",4,2},seq_2)
end

function HoundTurretInfiniteAmmo6Barrel:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	--it_hound_6b_inf.nbt--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(31060.09254315713,-5.6843418860808015E-14,180.0),
	y=vector.new(-5.6843418860808015E-14,19540.0,0.0),
	z=vector.new(180.0,0.0,31560.09254315713)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(3.2196718415402425E-5,9.366282245804556E-23,-1.8363093539245627E-7),
	y=vector.new(9.366282245804558E-23,5.117707267144319E-5,-5.341970407530889E-25),
	z=vector.new(-1.836309353924565E-7,-5.3419704075309E-25,3.1686632483756695E-5)
	}
	--bare template--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretInfiniteAmmo6Barrel.superClass.init(self,configs)
end
--overridden functions--

return HoundTurretInfiniteAmmo6Barrel