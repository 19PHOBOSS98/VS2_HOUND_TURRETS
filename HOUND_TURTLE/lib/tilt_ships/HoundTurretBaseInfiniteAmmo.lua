local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"
local TenThrusterTemplateVerticalCompact = require "lib.tilt_ships.TenThrusterTemplateVerticalCompact"

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


local HoundTurretBaseInfiniteAmmo = HoundTurretBase:subclass()


--overridden functions--
function HoundTurretBaseInfiniteAmmo:setShipFrameClass(configs) --override this to set ShipFrame Template
	self.ShipFrame = TenThrusterTemplateVerticalCompact(configs)
end

function HoundTurretBaseInfiniteAmmo:alternateFire(step)
	local seq_1 = step==0
	local seq_2 = step==1
	--{hub_index, redstoneIntegrator_index, side_index}
	self:activateGun({"front",1,3},seq_1)
	self:activateGun({"front",2,3},seq_1)
	
	self:activateGun({"front",1,4},seq_2)
	self:activateGun({"front",2,4},seq_2)
end

function HoundTurretBaseInfiniteAmmo:init(instance_configs)
	local configs = instance_configs
	
	configs.ship_constants_config = configs.ship_constants_config or {}
	
	
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--
	--unrotated inertia tensors--
	
	--bare template--
	--it_hound_4b_inf.nbt--
	--[[configs.ship_constants_config.LOCAL_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INERTIA_TENSOR or
	{
	x=vector.new(28030.733960085767,2.2737367544323206E-13,-299.9999999999999),
	y=vector.new(2.2737367544323206E-13,14839.999999999998,2.8421709430404007E-14),
	z=vector.new(-299.9999999999999,2.8421709430404007E-14,21750.733960085767)
	}
	configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR = configs.ship_constants_config.LOCAL_INV_INERTIA_TENSOR or
	{
	x=vector.new(3.568039422202221E-5,-5.476259743494812E-22,4.92126761618689E-7),
	y=vector.new(-5.47625974349481E-22,6.738544474393532E-5,-9.560584605887562E-23),
	z=vector.new(4.921267616186892E-7,-9.560584605887565E-23,4.598224776524008E-5)
	}]]--
	--bare template--
	
	--Netherite Caged, paste in firmwareScript.lua--
	--hound_4b_caged.nbt--
	--[[
	LOCAL_INERTIA_TENSOR = 
	{
	x=vector.new(95477.12678267715,-2.2737367544323206E-13,-300.0),
	y=vector.new(-2.2737367544323206E-13,52200.0,-1.1368683772161603E-13),
	z=vector.new(-300.0,-1.1368683772161603E-13,89197.12678267717)
	},
	LOCAL_INV_INERTIA_TENSOR = 
	{
	x=vector.new(1.0473823436011874E-5,4.56987849928189E-23,3.522699826934104E-8),
	y=vector.new(4.569878499281891E-23,1.9157088122605363E-5,2.45705044900259E-23),
	z=vector.new(3.5226998269341027E-8,2.4570504490025896E-23,1.1211241933116742E-5)
	},
	]]--
	--Netherite Caged, paste in firmwareScript.lua--
	
	--unrotated inertia tensors--
	--REMOVE WHEN VS2-COMPUTERS UPDATE RELEASES--

	HoundTurretBaseInfiniteAmmo.superClass.init(self,configs)
end
--overridden functions--

return HoundTurretBaseInfiniteAmmo