--! #textdomain "wesnoth-loti"
local _ = wesnoth.textdomain "wesnoth-loti"
local helper = wesnoth.require "lua/helper.lua"
-- Abhorrent hack to prohibit ai sides to pick up items
local add_fixed = function(item_number, x, y, crafted_sort)
	local record = {
		type = item_number,
		x = x,
		y = y,
		turn = wesnoth.get_variable("turn_number")
	}
	if crafted_sort then
		record.sort = crafted_sort
	end

	local list = helper.get_variable_array("items")
	table.insert(list, record)
	helper.set_variable_array("items", list)

	-- Draw the image of this item on the ground,
	-- plus rare blinking animation (halo) on the same hex.
	wesnoth.wml_actions.item {
		x = x,
		y = y,
		image = loti.item.type[item_number].image,
		halo = loti.item.halo
	}

	-- Enable "pick item" event when some unit walks onto this hex.
	-- (see PLACE_ITEM_EVENT for WML version)
	wesnoth.add_event_handler {
		id = "ie" .. x .. y,
		name = "moveto",
		first_time_only = "no",
		wml.tag.filter {
			x = x,
			y = y,
			side = "1,2,3,4,5",
			wml.tag["not"] {
				wml.tag.filter_wml {
					wml.tag.variables {
						cant_pick = "yes"
					}
				}
			},
		},
		wml.tag.fire_event {
			name = "item_pick",
			wml.tag.primary_unit {
				x = x,
				y = y
			}
		}
	}
	wesnoth.fire_event("item drop", x, y)
end

function wesnoth.wml_actions.random_item_fixed(cfg)
	local item_types = nil
	local item_types_wml = helper.get_child(cfg, "types")
	if item_types_wml then
		item_types = {}
		for _, possibilities in pairs(item_types_wml) do
			local sort_group = {}
			for sort_subgroup in string.gmatch(possibilities, '([^,]+)') do
				table.insert(sort_group, sort_subgroup)
			end
			table.insert(item_types, sort_group)
		end
	end
	local group_name = cfg.group or "drop"
	local generated = loti.item.on_the_ground.generate(group_name, item_types)
	if cfg.variable then
		wesnoth.set_variable(cfg.variable, generated)
	else
		add_fixed(generated, cfg.x, cfg.y)
	end
end
