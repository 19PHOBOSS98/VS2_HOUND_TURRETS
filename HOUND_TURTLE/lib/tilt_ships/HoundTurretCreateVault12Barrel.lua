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


local HoundTurretCreateVault12Barrel = HoundTurretBaseCreateVault:subclass()


--overridden functions--
function HoundTurretCreateVault12Barrel:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1

	self:activateGun({"front",1,4},seq_1)
	self:activateGun({"front",2,4},seq_1)
	self:activateGun({"front",3,4},seq_1)
	self:activateGun({"front",4,4},seq_1)
	self:activateGun({"front",5,4},seq_1)
	self:activateGun({"front",6,4},seq_1)
	self:activateGun({"front",7,4},seq_1)
	self:activateGun({"front",8,4},seq_1)
	
	self:activateGun({"front",1,2},seq_2)
	self:activateGun({"front",2,2},seq_2)
	self:activateGun({"front",3,2},seq_2)
	self:activateGun({"front",4,2},seq_2)
	self:activateGun({"front",5,2},seq_2)
	self:activateGun({"front",6,2},seq_2)
	self:activateGun({"front",7,2},seq_2)
	self:activateGun({"front",8,2},seq_2)
end

function HoundTurretCreateVault12Barrel:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	--it_hound_12b_vault.nbt--
	configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(120498.1260137242,-4.547473508864641E-13,-440.0),
	y=vector.new(-4.547473508864641E-13,48900.0,-2.2737367544323206E-13),
	z=vector.new(-440.0,-2.2737367544323206E-13,108838.1260137242)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(8.299006758523021E-6,7.733292058971292E-23,3.3550402855059036E-8),
	y=vector.new(7.733292058971291E-23,2.0449897750511246E-5,4.303450519205818E-23),
	z=vector.new(3.355040285505905E-8,4.3034505192058195E-23,9.188092434182086E-6)
	}
	--bare template--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretCreateVault12Barrel.superClass.init(self,configs)
end
--overridden functions--

return HoundTurretCreateVault12Barrel