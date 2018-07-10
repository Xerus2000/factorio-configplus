local i = 0
local function setting(name, min, max, type, default)
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

setting("stack_multiplier")
setting("resource_stack_multiplier")
setting("material_stack_multiplier")
setting("intermediate_stack_multiplier")

setting("beltspeed")
setting("underground_length", 0.2)
setting("inserter_speed")

setting("robot_speed")
setting("robot_energy")
setting("roboport_range")
setting("roboport_chargers", 1, 100, "int")

setting("powerpole_reach")
setting("powerpole_area")

setting("mining_speed")
setting("assembling_speed")
setting("smelting_speed")

setting("sciencecost")

setting("turret_range")
setting("projectile_damage")
setting("enemyhp")
