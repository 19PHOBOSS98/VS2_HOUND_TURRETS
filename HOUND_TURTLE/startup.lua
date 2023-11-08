while true do
	term.clear()
	term.setCursorPos(1,1)
	--[[local ship_radars = { peripheral.find("radar") }
	local ship_readers = { peripheral.find("ship_reader") }
	if (#ship_radars>0 and #ship_readers>0) then
		print("starting...")
		shell.run("firmwareScript.lua")
		break
	else
		print("install side components (ship-radar and ship-reader blocks)...")
	end]]--
	local radar = { peripheral.find("sp_radar") }
	local goggle_port = { peripheral.find("goggle_link_port") }
	if (#radar>0 and #goggle_port>0) then
		print("starting...")
		shell.run("firmwareScript.lua")
		break
	else
		print("install side components (radar and goggle_port blocks)...")
	end
	os.sleep(1)
end