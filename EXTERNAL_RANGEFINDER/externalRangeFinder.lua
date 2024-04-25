local monitor = peripheral.find("monitor")
local modem = peripheral.find("modem")
local sp_goggles = peripheral.find("goggle_link_port")

local EXTERNAL_GOGGLE_PORT_CHANNEL = 1011
local REPLY_DUMP = 0000
function newLine()
	x,y = monitor.getCursorPos()
	monitor.setCursorPos(1,y+1)
end

term.clear()
term.setCursorPos(1,1)
monitor.clear()
monitor.setCursorPos(1,1)


local max_distance = 500
local euler_mode = false
local immediately_execute = true
local check_for_blocks_in_world = true

while true do
	monitor.clear()
	monitor.setCursorPos(1,1)
	term.clear()
	term.setCursorPos(1,1)
	local goggle_links = sp_goggles.getConnected()
	local count = 0
	for k, v in pairs(sp_goggles.getConnected()) do
		local item = v.raycast(max_distance, {0, 0, 1}, euler_mode, immediately_execute, check_for_blocks_in_world)
		if (item.distance) then
			modem.transmit(EXTERNAL_GOGGLE_PORT_CHANNEL,REPLY_DUMP,{range=item.distance})
		end
		print("item.distance: ",item.distance)
		monitor.write("item.distance: ")
		monitor.write(item.distance)
		newLine()
		count = count+1
	end
	newLine()
	monitor.write("goggle count: "..count)
	print("goggle count: "..count)
	os.sleep(0)
end

