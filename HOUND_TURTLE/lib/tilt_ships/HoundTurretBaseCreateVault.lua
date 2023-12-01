local quaternion = require "lib.quaternions"
local utilities = require "lib.utilities"
local targeting_utilities = require "lib.targeting_utilities"
local player_spatial_utilities = require "lib.player_spatial_utilities"
local flight_utilities = require "lib.flight_utilities"
local list_manager = require "lib.list_manager"

local HoundTurretBase = require "lib.tilt_ships.HoundTurretBase"

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


local HoundTurretBaseCreateVault = HoundTurretBase:subclass()


--overridden functions--
function HoundTurretBaseCreateVault:CustomThreads()
	local htb = self
	
	local cannon_mounts = {peripheral.find("createbigcannons:cannon_mount")}
	
	local vault = {peripheral.find("create:item_vault")}
	--local vault = {peripheral.find("minecraft:chest")}
	vault = vault[1]
	
	local cannon_mount_max_ammo_capacity = 5
	local cannon_input_slot = 2
	local cannon_output_slot = 1
	
	local vault_name = peripheral.getName(vault)
	local cannon_mount_names = {}
	local cannon_names = {}
	for k,v in pairs(cannon_mounts) do
		cannon_mount_names[peripheral.getName(v)] = peripheral.getName(v)
	end
	for k,v in pairs(cannon_mount_names) do
		table.insert(cannon_names,v)
	end
	
	--leave the last vault slot empty when repleneshing ammo. It needs the space for spent cartidges
	
	local vault_max_slots = vault.size()
	self.ready_shell_index = vault_max_slots
	
	local threads = {
		function()--synchronize guns
			sync_step = 0
			while self.ShipFrame.run_firmware do
				
				if (htb.activate_weapons) then
					htb:alternateFire(sync_step)
					
					sync_step = math.fmod(sync_step+1,htb.ALTERNATING_FIRE_SEQUENCE_COUNT)
				else
					htb:reset_guns()
				end
				os.sleep(htb.GUNS_COOLDOWN_DELAY)
			end
			htb:reset_guns()
		end,
		
		function()--move indexes
			while self.ShipFrame.run_firmware do
				for i=1,2000,1 do
					local ready_index_details = vault.getItemDetail(self.ready_shell_index)
					if (ready_index_details) then
						if (ready_index_details.displayName ~= "Autocannon Cartridge") then
							self.ready_shell_index = self.ready_shell_index > 1 and self.ready_shell_index - 1 or vault_max_slots
						else
							break
						end
					else
						self.ready_shell_index = self.ready_shell_index > 1 and self.ready_shell_index - 1 or vault_max_slots
					end
				end
				os.sleep(0.0)
			end
		end,
	}
	
	for _,cannon_name in ipairs(cannon_names) do
		local emptyCannon = function()
			while self.ShipFrame.run_firmware do
				vault.pullItems(cannon_name,cannon_output_slot,64)--take empty shell casings
				vault.pushItems(cannon_name,self.ready_shell_index,cannon_mount_max_ammo_capacity,cannon_input_slot)--feed ammo
			end
		end
		table.insert(threads,emptyCannon)
	end

	return threads
end

function HoundTurretBaseCreateVault:init(instance_configs)
	HoundTurretBaseCreateVault.superClass.init(self,instance_configs)
end
--overridden functions--

function HoundTurretBaseCreateVault:getBulletCount()
	return self.bullet_count
end

return HoundTurretBaseCreateVault