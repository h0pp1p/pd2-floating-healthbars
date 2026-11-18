if not FloatingHealthbars then

	dofile(ModPath .. "req/EnemyHealthBar.lua")

	FloatingHealthbars = {
		mod_path = ModPath,
		save_path = SavePath .. "floating_healthbars/",
		save_file = SavePath .. "floating_healthbars/settings.json",
		texture_path = "guis/textures/floating_healthbar",
		variants = {},
		fonts = {
			tweak_data.menu.pd2_medium_font,
			"fonts/font_eurostile_ext",
			"core/fonts/diesel",
			"core/fonts/system_font",
			"fonts/font_eroded"
		},
		settings = {
			last_used_preset = "",
			variant = "default",
			fill_direction = 1,
			fill_type = 1,
			scale_type = 1,
			max_scale_x = 1.5,
			max_scale_y = 1,
			max_scale_name_text = 1,
			max_scale_hp_text = 1,
			width_by_text = false,
			width = 128,
			height = 20,
			min_width = 0,
			max_width = 640,
			width_padding = 0,
			name_size = 18,
			name_x_offset = 0,
			name_y_offset = -0.9,
			hp_size = 16,
			hp_x_offset = 0,
			hp_y_offset = 0.9,
			allcaps = false,
			font = 1,
			outline = true,
			max_distance = 10000,
			max_distance_ads = 10000,
			vertical_offset = 30,
			enemies = true,
			friendlies = true,
			civilians = true,
			hostages = true,
			turrets = true,
			damaged_only = false,
			loud_only = false,
			bg_tint_color = "FFFFFF",
			fg_tint_color = "FFFFFF",
			hp_tint_color = "FFFFFF",
			name_text_color = "FFFFFF",
			hp_text_color = "FFFFFF"
		},
		presets = {},
		menu_items = {}
	}

	function FloatingHealthbars:character_slot_mask()
		local slots = {}
		if self.settings.enemies then
			table.insert(slots, 12)
			table.insert(slots, 13)
		end
		if self.settings.friendlies then
			table.insert(slots, 16)
		end
		if self.settings.civilians then
			table.insert(slots, 21)
		end
		if self.settings.hostages then
			table.insert(slots, 22)
		end
		if self.settings.turrets then
			table.insert(slots, 25)
			table.insert(slots, 26)
		end
		return World:make_slot_mask(unpack(slots)), #slots == 0
	end

	function FloatingHealthbars:update_healthbar(refresh)
		local ids_texture = Idstring("texture")
		local ids_path = Idstring(self.texture_path)

		if refresh or not DB:has(ids_texture, ids_path) then
			BLT.AssetManager:CreateEntry(ids_path, ids_texture, self.variants[self.settings.variant])
		end

		if refresh then
			Application:reload_textures({ ids_path })
		end
	end

	function FloatingHealthbars:load_preset()
		local function load(name)
			local preset = name and io.file_is_readable(self.presets[name]) and io.load_as_json(self.presets[name]) or self.default_settings

			for k, v in pairs(self.settings) do
				if type(preset[k]) == type(v) then
					self.settings[k] = preset[k]
					if self.menu_items[k] then
						self.menu_items[k]:set_value(type(preset[k]) == "boolean" and (preset[k] and "on" or "off") or preset[k])
						self.menu_items[k]:trigger()
					end
				end
			end

			self:update_healthbar()

			if managers.hud then
				managers.hud:reset_floating_healthbar()
			end

			self.settings.last_used_preset = name

			managers.system_menu:show({
				title = managers.localization:text("menu_floating_healthbars_preset_loaded"),
				text = managers.localization:text("menu_floating_healthbars_preset_loaded_desc", {
					PRESET = name or managers.localization:text("menu_floating_healthbars_preset_default")
				}),
				button_list = {
					{
						text = managers.localization:text("dialog_ok")
					}
				}
			})
		end

		local button_list = {
			{
				text = managers.localization:text("menu_floating_healthbars_preset_default"),
				callback_func = function() load(nil) end
			},
			{
				no_text = true,
				no_selection = true
			}
		}

		for _, preset_name in pairs(table.map_keys(FloatingHealthbars.presets)) do
			table.insert(button_list, {
				text = preset_name:upper(),
				callback_func = function() load(preset_name) end
			})
		end

		table.insert(button_list, {
			no_text = true,
			no_selection = true
		})

		table.insert(button_list, {
			text = managers.localization:text("dialog_cancel"),
			cancel_button = true
		})

		managers.system_menu:show({
			title = managers.localization:text("menu_floating_healthbars_load_preset"),
			button_list = button_list
		})
	end

	function FloatingHealthbars:save_preset()
		local function save(name)
			local preset = deep_clone(self.settings)
			preset.last_used_preset = nil
			preset.max_distance = nil
			preset.max_distance_ads = nil
			preset.vertical_offset = nil
			preset.enemies = nil
			preset.friendlies = nil
			preset.civilians = nil
			preset.hostages = nil
			preset.turrets = nil
			preset.damaged_only = nil
			preset.loud_only = nil

			self.presets[name] = self.save_path .. name .. ".json"
			io.save_as_json(preset, self.presets[name])

			self.settings.last_used_preset = name

			managers.system_menu:show({
				title = managers.localization:text("menu_floating_healthbars_preset_saved"),
				text = managers.localization:text("menu_floating_healthbars_preset_saved_desc", { PRESET = name }),
				button_list = {
					{
						text = managers.localization:text("dialog_ok")
					}
				}
			})
		end

		if not file.DirectoryExists(self.save_path) then
			file.CreateDirectory(self.save_path)
		end

		if InputDialog then
			InputDialog:new():show({
				title = managers.localization:to_upper_text("menu_floating_healthbars_save_preset"),
				text = self.settings.last_used_preset,
				yes = managers.localization:to_upper_text("dialog_ok"),
				no = managers.localization:to_upper_text("dialog_cancel"),
				callback = function(text) save(text and text ~= "" and text or "custom") end
			})
		else
			managers.system_menu:show({
				title = "No BeardLib",
				text = "BeardLib is not installed, the preset will be saved as 'custom.json'.",
				button_list = {
					{
						text = managers.localization:text("dialog_ok"),
						callback_func = function() save("custom") end
					},
					{
						text = managers.localization:text("dialog_cancel"),
						cancel_button = true
					}
				}
			})
		end
	end

	function FloatingHealthbars:init()
		self.default_settings = deep_clone(self.settings)

		if not file.DirectoryExists(self.save_path) then
			file.CreateDirectory(self.save_path)
		end

		if io.file_is_readable(self.save_file) then
			local data = io.load_as_json(self.save_file)
			for k, v in pairs(self.settings) do
				if type(data[k]) == type(v) then
					self.settings[k] = data[k]
				end
			end
		end

		local function add_variants(asset_path)
			for _, file in pairs(file.GetFiles(asset_path)) do
				local name, ext = file:match("^(.+)%.(.+)$")
				if ext == "dds" or ext == "texture" then
					self.variants[name] = asset_path .. file
				elseif ext == "json" and name ~= "settings" then
					self.presets[name] = asset_path .. file
				end
			end
		end

		add_variants(self.mod_path .. "assets/")
		add_variants(self.save_path)

		self:update_healthbar()
	end

	Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitFloatingHealthbars", function(loc)
		HopLib:load_localization(FloatingHealthbars.mod_path .. "loc/", loc)
	end)

	Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusFloatingHealthbars", function(_, nodes)

		local menu_id = "floating_healthbars"
		local menu_id_size = "floating_healthbars_size"
		local menu_id_text = "floating_healthbars_text"
		local menu_id_distance = "floating_healthbars_distance"
		local menu_id_units = "floating_healthbars_units"
		local menu_id_colors = "floating_healthbars_colors"

		local function add_item(item)
			FloatingHealthbars.menu_items[item:name()] = item
			return item
		end

		local function make_color_box(item)
			function item:_layout_gui(node, row_item, ...)
				self._node = node
				self._needs_realignment = true
				return MenuItemInput._layout_gui(self, node, row_item, ...)
			end

			function item:_layout(row_item, ...)
				self._row_item = row_item

				local padding = 2
				local size = row_item.gui_panel:h() - padding * 2

				if self._needs_realignment then
					self._align_left = self._align_left + size
					self._needs_realignment = false
				end

				row_item.color_box = row_item.color_box or row_item.gui_panel:rect()
				row_item.color_box:set_layer(row_item.caret:layer())
				row_item.color_box:set_size(size, size)
				row_item.color_box:set_position(self._align_left - size, padding)
				row_item.color_box:set_color(Color(self:value()))

				return MenuItemInput._layout(self, row_item, ...)
			end

			function item:set_value(...)
				MenuItemInput.set_value(self, ...)
				self:reload(self._row_item, self._node)
			end

			return item
		end

		MenuHelper:NewMenu(menu_id)
		MenuHelper:NewMenu(menu_id_size)
		MenuHelper:NewMenu(menu_id_text)
		MenuHelper:NewMenu(menu_id_distance)
		MenuHelper:NewMenu(menu_id_units)
		MenuHelper:NewMenu(menu_id_colors)

		function MenuCallbackHandler:floating_healthbars_value(item, ...)
			local value = item:value()
			FloatingHealthbars.settings[item:name()] = value
			FloatingHealthbars.menu_items.max_scale_x:set_enabled(FloatingHealthbars.settings.scale_type > 1)
			FloatingHealthbars.menu_items.max_scale_y:set_enabled(FloatingHealthbars.settings.scale_type > 1)
			FloatingHealthbars.menu_items.max_scale_name_text:set_enabled(FloatingHealthbars.settings.scale_type > 1)
			FloatingHealthbars.menu_items.max_scale_hp_text:set_enabled(FloatingHealthbars.settings.scale_type > 1)
			if managers.hud then
				managers.hud:reset_floating_healthbar()
			end
		end

		function MenuCallbackHandler:floating_healthbars_value_variant(item)
			self:floating_healthbars_value(item)
			FloatingHealthbars:update_healthbar(managers.hud and true)
		end

		function MenuCallbackHandler:floating_healthbars_value_color(item)
			local value = item:value():upper():gsub("[^A-F0-9]", ""):sub(1, 6)
			value = value .. string.rep("F", 6 - value:len())
			item:set_value(value)
			self:floating_healthbars_value(item)
		end

		function MenuCallbackHandler:floating_healthbars_toggle(item)
			FloatingHealthbars.settings[item:name()] = item:value() == "on"
			FloatingHealthbars.menu_items.width:set_enabled(not FloatingHealthbars.settings.width_by_text)
			FloatingHealthbars.menu_items.min_width:set_enabled(FloatingHealthbars.settings.width_by_text)
			FloatingHealthbars.menu_items.max_width:set_enabled(FloatingHealthbars.settings.width_by_text)
			FloatingHealthbars.menu_items.width_padding:set_enabled(FloatingHealthbars.settings.width_by_text)
			FloatingHealthbars.menu_items.max_scale_x:set_enabled(not FloatingHealthbars.settings.width_by_text)
			if managers.hud then
				managers.hud:reset_floating_healthbar()
			end
		end

		function MenuCallbackHandler:floating_healthbars_toggle_unit(item)
			self:floating_healthbars_toggle(item)
			if managers.hud then
				managers.hud:reset_floating_healthbar()
			end
		end

		function MenuCallbackHandler:floating_healthbars_load_preset()
			FloatingHealthbars:load_preset()
		end

		function MenuCallbackHandler:floating_healthbars_save_preset()
			FloatingHealthbars:save_preset()
		end

		function MenuCallbackHandler:floating_healthbars_save()
			io.save_as_json(FloatingHealthbars.settings, FloatingHealthbars.save_file)
		end

		local variants = table.map_keys(FloatingHealthbars.variants)
		local pretty_variants = {}
		for k, v in pairs(variants) do
			pretty_variants[k] = v:pretty(true)
		end
		add_item(MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "variant",
			title = "menu_floating_healthbars_variant",
			items = pretty_variants,
			item_values = variants,
			localized_items = false,
			value = FloatingHealthbars.settings.variant,
			callback = "floating_healthbars_value_variant",
			priority = 99
		}))

		add_item(MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "fill_direction",
			title = "menu_floating_healthbars_fill_direction",
			items = { "menu_floating_healthbars_left", "menu_floating_healthbars_right", "menu_floating_healthbars_center" },
			value = FloatingHealthbars.settings.fill_direction,
			callback = "floating_healthbars_value",
			priority = 98
		}))

		add_item(MenuHelper:AddMultipleChoice({
			menu_id = menu_id,
			id = "fill_type",
			title = "menu_floating_healthbars_fill_type",
			items = { "menu_floating_healthbars_stretched", "menu_floating_healthbars_cropped", "menu_floating_healthbars_tiled" },
			value = FloatingHealthbars.settings.fill_type,
			callback = "floating_healthbars_value",
			priority = 97
		}))

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 90
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "size",
			title = "menu_floating_healthbars_size",
			desc = "menu_floating_healthbars_size_desc",
			next_node = menu_id_size,
			priority = 89
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "text",
			title = "menu_floating_healthbars_text",
			desc = "menu_floating_healthbars_text_desc",
			next_node = menu_id_text,
			priority = 88
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "distance",
			title = "menu_floating_healthbars_distance",
			desc = "menu_floating_healthbars_distance_desc",
			next_node = menu_id_distance,
			priority = 87
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "units",
			title = "menu_floating_healthbars_units",
			desc = "menu_floating_healthbars_units_desc",
			next_node = menu_id_units,
			priority = 86
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "colors",
			title = "menu_floating_healthbars_colors",
			desc = "menu_floating_healthbars_colors_desc",
			next_node = menu_id_colors,
			priority = 85
		})

		MenuHelper:AddDivider({
			menu_id = menu_id,
			size = 16,
			priority = 80
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "load_preset",
			title = "menu_floating_healthbars_load_preset",
			desc = "menu_floating_healthbars_load_preset_desc",
			callback = "floating_healthbars_load_preset",
			priority = 79
		})

		MenuHelper:AddButton({
			menu_id = menu_id,
			id = "save_preset",
			title = "menu_floating_healthbars_save_preset",
			desc = "menu_floating_healthbars_save_preset_desc",
			callback = "floating_healthbars_save_preset",
			priority = 78
		})

		-- Size
		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_size,
			id = "width_by_text",
			title = "menu_floating_healthbars_width_by_text",
			desc = "menu_floating_healthbars_width_by_text_desc",
			value = FloatingHealthbars.settings.width_by_text,
			callback = "floating_healthbars_toggle",
			priority = 99
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "min_width",
			title = "menu_floating_healthbars_min_width",
			disabled = not FloatingHealthbars.settings.width_by_text,
			value = FloatingHealthbars.settings.min_width,
			min = 0,
			max = 640,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 98
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "max_width",
			title = "menu_floating_healthbars_max_width",
			disabled = not FloatingHealthbars.settings.width_by_text,
			value = FloatingHealthbars.settings.max_width,
			min = 0,
			max = 640,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 97
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "width_padding",
			title = "menu_floating_healthbars_width_padding",
			disabled = not FloatingHealthbars.settings.width_by_text,
			value = FloatingHealthbars.settings.width_padding,
			min = 0,
			max = 160,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 96
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "width",
			title = "menu_floating_healthbars_width",
			disabled = FloatingHealthbars.settings.width_by_text,
			value = FloatingHealthbars.settings.width,
			min = 2,
			max = 640,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 95
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "height",
			title = "menu_floating_healthbars_height",
			value = FloatingHealthbars.settings.height,
			min = 2,
			max = 64,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 94
		}))

		MenuHelper:AddDivider({
			menu_id = menu_id_size,
			size = 16,
			priority = 90
		})

		add_item(MenuHelper:AddMultipleChoice({
			menu_id = menu_id_size,
			id = "scale_type",
			title = "menu_floating_healthbars_scale_type",
			desc = "menu_floating_healthbars_scale_type_desc",
			items = { "menu_floating_healthbars_scale_none", "menu_floating_healthbars_scale_total_hp", "menu_floating_healthbars_scale_special" },
			value = FloatingHealthbars.settings.scale_type,
			callback = "floating_healthbars_value",
			priority = 89
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "max_scale_x",
			title = "menu_floating_healthbars_max_scale_x",
			desc = "menu_floating_healthbars_max_scale_x_desc",
			disabled = FloatingHealthbars.settings.scale_type == 1 or FloatingHealthbars.settings.width_by_text,
			value = FloatingHealthbars.settings.max_scale_x,
			min = 1,
			max = 5,
			step = 0.05,
			show_value = true,
			display_precision = 2,
			callback = "floating_healthbars_value",
			priority = 88
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "max_scale_y",
			title = "menu_floating_healthbars_max_scale_y",
			desc = "menu_floating_healthbars_max_scale_y_desc",
			disabled = FloatingHealthbars.settings.scale_type == 1,
			value = FloatingHealthbars.settings.max_scale_y,
			min = 1,
			max = 5,
			step = 0.05,
			show_value = true,
			display_precision = 2,
			callback = "floating_healthbars_value",
			priority = 87
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "max_scale_name_text",
			title = "menu_floating_healthbars_max_scale_name_text",
			desc = "menu_floating_healthbars_max_scale_name_text_desc",
			disabled = FloatingHealthbars.settings.scale_type == 1,
			value = FloatingHealthbars.settings.max_scale_name_text,
			min = 1,
			max = 5,
			step = 0.05,
			show_value = true,
			display_precision = 2,
			callback = "floating_healthbars_value",
			priority = 86
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_size,
			id = "max_scale_hp_text",
			title = "menu_floating_healthbars_max_scale_hp_text",
			desc = "menu_floating_healthbars_max_scale_hp_text_desc",
			disabled = FloatingHealthbars.settings.scale_type == 1,
			value = FloatingHealthbars.settings.max_scale_hp_text,
			min = 1,
			max = 5,
			step = 0.05,
			show_value = true,
			display_precision = 2,
			callback = "floating_healthbars_value",
			priority = 85
		}))

		-- Text
		add_item(MenuHelper:AddMultipleChoice({
			menu_id = menu_id_text,
			id = "font",
			title = "menu_floating_healthbars_font",
			items = table.remap(FloatingHealthbars.fonts, function(k) return k, "menu_floating_healthbars_font_" .. k end),
			value = FloatingHealthbars.settings.font,
			callback = "floating_healthbars_value",
			priority = 99
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_text,
			id = "allcaps",
			title = "menu_floating_healthbars_allcaps",
			value = FloatingHealthbars.settings.allcaps,
			callback = "floating_healthbars_toggle",
			priority = 98
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_text,
			id = "outline",
			title = "menu_floating_healthbars_outline",
			value = FloatingHealthbars.settings.outline,
			callback = "floating_healthbars_toggle",
			priority = 97
		}))

		MenuHelper:AddDivider({
			menu_id = menu_id_text,
			size = 16,
			priority = 90
		})

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_text,
			id = "name_size",
			title = "menu_floating_healthbars_name_size",
			value = FloatingHealthbars.settings.name_size,
			min = 0,
			max = 64,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 89
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_text,
			id = "name_x_offset",
			title = "menu_floating_healthbars_name_x_offset",
			desc = "menu_floating_healthbars_name_x_offset_desc",
			value = FloatingHealthbars.settings.name_x_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 88
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_text,
			id = "name_y_offset",
			title = "menu_floating_healthbars_name_y_offset",
			desc = "menu_floating_healthbars_name_y_offset_desc",
			value = FloatingHealthbars.settings.name_y_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 87
		}))

		MenuHelper:AddDivider({
			menu_id = menu_id_text,
			size = 16,
			priority = 80
		})

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_text,
			id = "hp_size",
			title = "menu_floating_healthbars_hp_size",
			value = FloatingHealthbars.settings.hp_size,
			min = 0,
			max = 64,
			step = 2,
			show_value = true,
			display_precision = 0,
			callback = "floating_healthbars_value",
			priority = 79
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_text,
			id = "hp_x_offset",
			title = "menu_floating_healthbars_hp_x_offset",
			desc = "menu_floating_healthbars_hp_x_offset_desc",
			value = FloatingHealthbars.settings.hp_x_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 78
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_text,
			id = "hp_y_offset",
			title = "menu_floating_healthbars_hp_y_offset",
			desc = "menu_floating_healthbars_hp_y_offset_desc",
			value = FloatingHealthbars.settings.hp_y_offset,
			min = -1,
			max = 1,
			step = 0.05,
			show_value = true,
			display_precision = 0,
			display_scale = 100,
			is_percentage = true,
			callback = "floating_healthbars_value",
			priority = 77
		}))

		-- Distance
		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_distance,
			id = "max_distance",
			title = "menu_floating_healthbars_max_distance",
			desc = "menu_floating_healthbars_max_distance_desc",
			value = FloatingHealthbars.settings.max_distance,
			min = 0,
			max = 10000,
			step = 100,
			show_value = true,
			display_precision = 1,
			display_scale = 0.01,
			callback = "floating_healthbars_value",
			priority = 99
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_distance,
			id = "max_distance_ads",
			title = "menu_floating_healthbars_max_distance_ads",
			desc = "menu_floating_healthbars_max_distance_ads_desc",
			value = FloatingHealthbars.settings.max_distance_ads,
			min = 0,
			max = 10000,
			step = 100,
			show_value = true,
			display_precision = 1,
			display_scale = 0.01,
			callback = "floating_healthbars_value",
			priority = 98
		}))

		add_item(MenuHelper:AddSlider({
			menu_id = menu_id_distance,
			id = "vertical_offset",
			title = "menu_floating_healthbars_vertical_offset",
			desc = "menu_floating_healthbars_vertical_offset_desc",
			value = FloatingHealthbars.settings.vertical_offset,
			min = -60,
			max = 60,
			step = 1,
			show_value = true,
			display_precision = 1,
			callback = "floating_healthbars_value",
			priority = 97
		}))

		-- Unit types
		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "enemies",
			title = "menu_floating_healthbars_enemies",
			value = FloatingHealthbars.settings.enemies,
			callback = "floating_healthbars_toggle_unit",
			priority = 99
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "friendlies",
			title = "menu_floating_healthbars_friendlies",
			value = FloatingHealthbars.settings.friendlies,
			callback = "floating_healthbars_toggle_unit",
			priority = 98
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "civilians",
			title = "menu_floating_healthbars_civilians",
			value = FloatingHealthbars.settings.civilians,
			callback = "floating_healthbars_toggle_unit",
			priority = 97
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "hostages",
			title = "menu_floating_healthbars_hostages",
			value = FloatingHealthbars.settings.hostages,
			callback = "floating_healthbars_toggle_unit",
			priority = 96
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "turrets",
			title = "menu_floating_healthbars_turrets",
			value = FloatingHealthbars.settings.turrets,
			callback = "floating_healthbars_toggle_unit",
			priority = 95
		}))

		MenuHelper:AddDivider({
			menu_id = menu_id_units,
			size = 16,
			priority = 90
		})

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "damaged_only",
			title = "menu_floating_healthbars_damaged_only",
			desc = "menu_floating_healthbars_damaged_only_desc",
			value = FloatingHealthbars.settings.damaged_only,
			callback = "floating_healthbars_toggle",
			priority = 89
		}))

		add_item(MenuHelper:AddToggle({
			menu_id = menu_id_units,
			id = "loud_only",
			title = "menu_floating_healthbars_loud_only",
			desc = "menu_floating_healthbars_loud_only_desc",
			value = FloatingHealthbars.settings.loud_only,
			callback = "floating_healthbars_toggle",
			priority = 88
		}))

		-- Colors
		make_color_box(add_item(MenuHelper:AddInput({
			menu_id = menu_id_colors,
			id = "bg_tint_color",
			title = "menu_floating_healthbars_bg_tint_color",
			desc = "menu_floating_healthbars_bg_tint_color_desc",
			value = FloatingHealthbars.settings.bg_tint_color,
			callback = "floating_healthbars_value_color",
			priority = 99
		})))

		make_color_box(add_item(MenuHelper:AddInput({
			menu_id = menu_id_colors,
			id = "fg_tint_color",
			title = "menu_floating_healthbars_fg_tint_color",
			desc = "menu_floating_healthbars_fg_tint_color_desc",
			value = FloatingHealthbars.settings.fg_tint_color,
			callback = "floating_healthbars_value_color",
			priority = 98
		})))

		make_color_box(add_item(MenuHelper:AddInput({
			menu_id = menu_id_colors,
			id = "hp_tint_color",
			title = "menu_floating_healthbars_hp_tint_color",
			desc = "menu_floating_healthbars_hp_tint_color_desc",
			value = FloatingHealthbars.settings.hp_tint_color,
			callback = "floating_healthbars_value_color",
			priority = 97
		})))

		MenuHelper:AddDivider({
			menu_id = menu_id_colors,
			size = 16,
			priority = 90
		})

		make_color_box(add_item(MenuHelper:AddInput({
			menu_id = menu_id_colors,
			id = "name_text_color",
			title = "menu_floating_healthbars_name_text_color",
			desc = "menu_floating_healthbars_name_text_color_desc",
			value = FloatingHealthbars.settings.name_text_color,
			callback = "floating_healthbars_value_color",
			priority = 89
		})))

		make_color_box(add_item(MenuHelper:AddInput({
			menu_id = menu_id_colors,
			id = "hp_text_color",
			title = "menu_floating_healthbars_hp_text_color",
			desc = "menu_floating_healthbars_hp_text_color_desc",
			value = FloatingHealthbars.settings.hp_text_color,
			callback = "floating_healthbars_value_color",
			priority = 88
		})))

		nodes[menu_id] = MenuHelper:BuildMenu(menu_id, { area_bg = "half", back_callback = "floating_healthbars_save" })
		nodes[menu_id_size] = MenuHelper:BuildMenu(menu_id_size, { area_bg = "half", back_callback = "floating_healthbars_save" })
		nodes[menu_id_text] = MenuHelper:BuildMenu(menu_id_text, { area_bg = "half", back_callback = "floating_healthbars_save" })
		nodes[menu_id_distance] = MenuHelper:BuildMenu(menu_id_distance, { area_bg = "half", back_callback = "floating_healthbars_save" })
		nodes[menu_id_units] = MenuHelper:BuildMenu(menu_id_units, { area_bg = "half", back_callback = "floating_healthbars_save" })
		nodes[menu_id_colors] = MenuHelper:BuildMenu(menu_id_colors, { area_bg = "half", back_callback = "floating_healthbars_save" })
		MenuHelper:AddMenuItem(nodes.blt_options, menu_id, "menu_floating_healthbars")
	end)

	FloatingHealthbars:init()

end

HopLib:run_required(FloatingHealthbars.mod_path .. "lua/")
