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


local HoundTurretCreateVault6Barrel = HoundTurretBaseCreateVault:subclass()


--overridden functions--
function HoundTurretCreateVault6Barrel:alternateFire(step)
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

function HoundTurretCreateVault6Barrel:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	--it_hound_6b_vault.nbt--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(122986.67893848766,0.0,180.0),
	y=vector.new(0.0,31540.0,1.1368683772161603E-13),
	z=vector.new(180.0,1.1368683772161603E-13,117486.67893848763)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(8.130980126952528E-6,4.490299143342815E-26,-1.2457381858735989E-8),
	y=vector.new(4.490299143342803E-26,3.170577045022194E-5,-3.0680387726670394E-23),
	z=vector.new(-1.2457381858735987E-8,-3.0680387726670476E-23,8.511622350413909E-6)
	}
	--bare template--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretCreateVault6Barrel.superClass.init(self,configs)
end
--overridden functions--

return HoundTurretCreateVault6Barrel