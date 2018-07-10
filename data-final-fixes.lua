local prefix = "config+"
local function get_setting(name)
	if not settings.startup[prefix..name] then error("unknown setting", 2) end
	return settings.startup[prefix..name].value
end
local d = data.raw

local function multiplyPower(power, multiplier)
	local energy = tonumber(string.match(power, "%d+"))
	return (energy * multiplier)..power:match("%a+")
end

local function mult(proto, property, settingname, digits, add, max)
	if not (proto and proto[property]) then return end
	if digits then
		local flooring = 10^digits
		proto[property] = math.floor(proto[property] * get_setting(settingname) * flooring) / flooring
	else
		proto[property] = math.floor(proto[property] * get_setting(settingname))
	end
	proto[property] = proto[property] + (add or 0)
	if max then log(proto[property].." - "..max) end
	if max and proto[property] > max then
		proto[property] = max
	end
end

-- Returns true when group not found to allow continuation
local function dogroup(group, bool, f, condition)
	if bool then
		for _, proto in pairs(group) do
			if not condition or condition(proto) then
				f(proto)
			end
		end
		return false
	end
	return true
end

-- Item Stack Size
local function items(item)
	item.stack_size = item.stack_size * get_setting("stack_multiplier")
	if item.subgroup == "raw-resource" then
		item.stack_size = item.stack_size * get_setting("resource_stack_multiplier")
	elseif item.subgroup == "raw-material" then
		item.stack_size = item.stack_size * get_setting("material_stack_multiplier")
	elseif item.subgroup == "intermediate-product" then
		item.stack_size = item.stack_size * get_setting("intermediate_stack_multiplier")
	end
end

-- Technology Cost
local function tech(tech)
	packs = tech.unit
	if not packs then return end
	if packs.count then
		packs.count = math.floor(tech.unit.count * get_setting("sciencecost"))
	elseif packs.count_formula then
		packs.count_formula = get_setting("sciencecost").."*("..packs.count_formula..")"
	end
end

-- Roboports
local charger_multiplier = get_setting("roboport_chargers")
local function roboport(port)
	mult(port, "logistics_radius", "roboport_range")
	mult(port, "construction_radius", "roboport_range")
	local chargers = {}
	if port.charging_offsets then
		local offsets = port.charging_offsets
		local offsetamount = #offsets
		for i=0, charger_multiplier-1 do
			for j=1, offsetamount do
				if #chargers < 255 then
					chargers[i*offsetamount + j] = offsets[j]
				end
			end
		end
		port.energy_source.input_flow_limit = multiplyPower(port.energy_source.input_flow_limit, charger_multiplier)
		port.charging_offsets = chargers
	end
end

-- recursively apply function "f" to "params" in "proto"
local function rec(proto, params, f)
	if #params == 0 then
		f(proto)
		return
	end
	-- check if table
	if #proto > 0 and not type(proto) == "string" then
		for _, element in pairs(proto) do
			rec(element, params, f)
		end
	else
		local param = params[#params]
		if not proto[param] then return end
		params[#params] = nil
		rec(proto[param], params, f)
	end
end

for groupname, group in pairs(d) do
	-- Robots
	if groupname:match("-robot$") then
		for _, proto in pairs(group) do
			mult(proto, "speed", "robot_speed", 4)
			if proto.max_energy and get_setting("robot_energy") ~= 1 and proto.max_energy ~= "" then
				proto.max_energy = multiplyPower(proto.max_energy, get_setting("robot_energy"))
			end
		end
	
	elseif dogroup(group, groupname=="technology", tech) and
	dogroup(group, groupname=="assembling-machine", function(proto) mult(proto, "crafting_speed", "assembling_speed", 2) end) and
	dogroup(group, groupname=="roboport", roboport) and
	dogroup(group, groupname=="electric-pole", function(pole) 
		mult(pole, "maximum_wire_distance", "powerpole_reach", nil, 1, 64)
		mult(pole, "supply_area_distance", "powerpole_area", nil, pole.supply_area_distance % 1, 64) 
	end) and
	dogroup(group, groupname=="mining-drill", function(drill) mult(drill, "mining_speed", "mining_speed", 1) end) and
	dogroup(group, groupname=="furnace", function(proto) mult(proto, "crafting_speed", "smelting_speed", 1) end) then
		for _, proto in pairs(group) do
			if proto.stack_size and proto.stack_size > 1 then
				items(proto)
			end
			-- Belts
			if groupname == "transport-belt" or groupname == "splitter" or groupname == "loader" then
				mult(proto, "speed", "beltspeed", 3)
			elseif groupname == "underground-belt" then
				mult(proto, "speed", "beltspeed", 3)
				mult(proto, "max_distance", "underground_length", nil, nil, 255)
			-- Inserters
			elseif groupname == "inserter" then
				mult(proto, "rotation_speed", "inserter_speed", 4)
				mult(proto, "extension_speed", "inserter_speed", 4)
			-- Turrets
			elseif groupname == "electric-turret" or groupname == "fluid-turret" or groupname == "ammo-turret" then
				mult(proto.attack_parameters, "range", "turret_range")
			-- Projectile damage
			elseif groupname == "projectile" or groupname == "ammo" then
				steps = {"damage", "target_effects", "action_delivery", "action"}
				if groupname == "ammo" then steps[5] = "ammo_type" end
				rec(proto, steps, function(d) mult(d, "amount", "projectile_damage", 1) end)
			-- Enemy HP
			elseif proto.subgroup == "enemies" and proto.max_health then
				mult(proto, "max_health", "enemyhp")
			end
		end
	end
end

