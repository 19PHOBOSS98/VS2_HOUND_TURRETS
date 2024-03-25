# VS2_HOUND_TURRETS


Using the latest version of "Some-Peripherals" make sure the Radar range is set to no less than "1" over at the config file(saves/your_world_save_folder/serverconfig/some_peripherals-SERVER.toml/SomePeripheralsConfig.RadarSettings/max_ship_search_radius & max_entity_search_radius)

start world
Place hound_turret schematic in world
shipify structure
replace each autocannon
prepare 2 Ender Pocket Computers (these will be our Controller & Debugger)
replace the glass on the hound turret with an Ender Turtle
place all the necessary scripts into their respective computer folder

```
setup hound turret settings:
	DroneID
	Channels
	DEFAULT MASTER PLAYER
	DEFAULT MASTER SHIP
setup swarm_controller:
	DroneID list
	Channels
	DEFAULT MASTER PLAYER
	DEFAULT MASTER SHIP
setup debugger:
	DroneID
	Channels
```

right-click your range_goggles (from some-peripherals) on the hound's goggle_link_port (bloue block with a "G" on it) for auto range finding

put on the range_goggles

start swarm_controller on your pocket controller and navigate to your hound turret's "RANGE" finding mode and set it to "AUTO"

