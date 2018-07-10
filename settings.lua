local i = 0
local function set(name, min, max, type, default)
	i = i+1
	data:extend {{
		type = type and type.."-setting" or "double-setting",
		name = "config+"..name,
		setting_type = "startup",
		default_value = 1,
		minimum_value = min or 0.1,
		maximum_value = max or 1000,
		order = string.format("a%02d", i)
	}}
end

set("stack_multiplier")
set("resource_stack_multiplier")
set("material_stack_multiplier")
set("intermediate_stack_multiplier")

set("beltspeed")
set("underground_length", 0.2)
set("inserter_speed")

set("robot_speed")
set("robot_energy")
set("roboport_range")
set("roboport_chargers", 1, 100, "int")

set("powerpole_reach")
set("powerpole_area")

set("mining_speed")
set("assembling_speed")
set("smelting_speed")

set("sciencecost")

set("turret_range")
set("projectile_damage")
set("enemyhp")
