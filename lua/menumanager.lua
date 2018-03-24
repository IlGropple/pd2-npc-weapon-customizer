_G.NWC = {}
NWC.mod_path = ModPath
NWC.save_path = SavePath
NWC.is_client = Network:is_client()
NWC.tweak_setups = {}
NWC.dropable_mods = {}
NWC.settings = {
  add_animations = true,
  force_hq = false,
  keep_types = false,
  keep_sounds = false,
  weapons = {
    -- additional weapons can be added in the mod's save file (NWC_settings.txt)
    -- character_tweak_data_weapon_id = { id = "weapon_tweak_data_id" }
    beretta92 = { id = "beretta92_npc", name = "wpn_fps_pis_beretta_npc" },
    c45 = { id = "c45_npc", name = "wpn_fps_pis_g17_npc" },
    raging_bull = { id = "raging_bull_npc", name = "wpn_fps_pis_rage_npc" },
    m4 = { id = "m4_npc", name = "wpn_fps_ass_m4_npc" },
    ak47 = { id = "ak47_npc", name = "wpn_fps_ass_74_npc" },
    r870 = { id = "r870_npc", name = "wpn_fps_shot_r870_npc" },
    mossberg = { id = "mossberg_npc", name = "wpn_fps_shot_huntsman_npc" },
    mp5 = { id = "mp5_npc", name = "wpn_fps_smg_mp5_npc" },
    mp5_tactical = { id = "mp5_tactical_npc", name = "wpn_fps_smg_mp5_npc" },
    mp9 = { id = "mp9_npc", name = "wpn_fps_smg_mp9_npc" },
    mac11 = { id = "mac11_npc", name = "wpn_fps_smg_mac10_npc" },
    m14_sniper_npc = { id = "m14_sniper_npc", name = "wpn_fps_snp_msr_npc" },
    saiga = { id = "saiga_npc", name = "wpn_fps_shot_saiga_npc" },
    m249 = { id = "m249_npc", name = "wpn_fps_lmg_m249_npc" },
    benelli = { id = "benelli_npc", name = "wpn_fps_sho_ben_npc" },
    g36 = { id = "g36_npc", name = "wpn_fps_ass_g36_npc" },
    ump = { id = "ump_npc", name = "wpn_fps_smg_schakal_npc" },
    scar_murky = { id = "scar_npc", name = "wpn_fps_ass_scar_npc" },
    rpk_lmg = { id = "rpk_lmg_npc", name = "wpn_fps_lmg_rpk_npc" },
    svd_snp = { id = "svd_snp_npc", name = "wpn_fps_snp_siltstone_npc" },
    akmsu_smg = { id = "akmsu_smg_npc", name = "wpn_fps_smg_akmsu_npc" },
    asval_smg = { id = "asval_smg_npc", name = "wpn_fps_ass_asval_npc" },
    sr2_smg = { id = "sr2_smg_npc", name = "wpn_fps_smg_sr2_npc" },
    ak47_ass = { id = "ak47_ass_npc", name = "wpn_fps_ass_74_npc" },
    x_c45 = { id = "x_c45_npc", name = "wpn_fps_x_1911_npc" },
    sg417 = { id = "contraband_npc", name = "wpn_fps_ass_contraband_npc" },
    svdsil_snp = { id = "svdsil_snp_npc", name = "wpn_fps_snp_siltstone_npc" },
    mini = { id = "mini_npc", name = "wpn_fps_lmg_m134_npc" },
    heavy_zeal_sniper = { id = "heavy_snp_npc", name = "wpn_fps_snp_msr_npc" }
  }
}

function NWC:get_weapon_id_index(weapon)
  local index = 1
  for i, v in ipairs(tweak_data.character.weap_ids) do
    if v == weapon then
      index = i
      break
    end
  end
  return index
end

function NWC:get_weapon(weapon_id)
  local weap = self.settings.weapons[weapon_id]
  if not weap or not weap.id or not weap.name or not tweak_data.weapon.factory[weap.name] then
    return
  end
  if weap.random_mods then
    weap = deep_clone(weap)
    NWC:create_random_blueprint(weap)
  end
  return weap
end

function NWC:is_joker(unit)
  if not alive(unit) then
    return false
  end
  local u_key = unit:key()
  local gstate = managers.groupai:state()
  return gstate._police[u_key] and gstate._police[u_key].is_converted or false
end

function NWC:get_npc_version(weapon_id)
  local factory_id = weapon_id and managers.weapon_factory:get_factory_id_by_weapon_id(weapon_id)
  local tweak = factory_id and tweak_data.weapon.factory[factory_id .. "_npc"]
  return tweak and (not tweak.custom or DB:has(Idstring("unit"), tweak.unit:id())) and factory_id .. "_npc"
end

function NWC:create_random_blueprint(weapon)
  weapon.blueprint = weapon.blueprint or tweak_data.weapon.factory[weapon.name].default_blueprint
  if not self.dropable_mods[weapon.name] then
    local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(weapon.name:gsub("_npc$", ""))
    if not weapon_id then
      return
    end
    self.dropable_mods[weapon.name] = managers.blackmarket:get_dropable_mods_by_weapon_id(weapon_id)
  end
  for part_type, parts_data in pairs(self.dropable_mods[weapon.name]) do
    if math.random() < 1 then
      local part_data = table.random(parts_data)
      if part_data then
        managers.weapon_factory:change_part_blueprint_only(weapon.name, part_data[1], weapon.blueprint)
      end
    end
  end
end

function NWC:open_weapon_category_menu(category, weapon)
  local loadout = self.settings.weapons[weapon] or {}
  local new_node_data = {
    category = category,
    can_move_over_tabs = true,
    scroll_tab_anywhere = true,
    hide_detection_panel = true,
    custom_callback = {
      w_equip = callback(self, self, "select_weapon", weapon),
      w_unequip = callback(self, self, "select_weapon", weapon)
    },
    topic_id = "bm_menu_" .. category
  }
  new_node_data.selected_tab = self:create_pages(new_node_data, weapon, "weapon", tweak_data.gui.WEAPON_ROWS_PER_PAGE, tweak_data.gui.WEAPON_COLUMNS_PER_PAGE, tweak_data.gui.MAX_WEAPON_PAGES)
  managers.menu:open_node("blackmarket_node", {new_node_data})
end

function NWC:create_pages(new_node_data, weapon, identifier, rows, columns, max_pages)
  local category = new_node_data.category
  local loadout = self.settings.weapons[weapon] or {}
  rows = rows or 3
  columns = columns or 3
  max_pages = max_pages or 8
  local items_per_page = rows * columns
  local item_data = nil
  local selected_tab = 1
  for page = 1, max_pages, 1 do
    local index = 1
    local start_i = 1 + items_per_page * (page - 1)
    item_data = {}
    for i = start_i, items_per_page * page, 1 do
      item_data[index] = i
      index = index + 1
      if i == loadout.slot and category == loadout.category then
        selected_tab = page
      end
    end
    local name_id = managers.localization:to_upper_text("bm_menu_page", {page = tostring(page)})
    table.insert(new_node_data, {
      prev_node_data = false,
      allow_preview = true,
      name = category,
      category = category,
      start_i = start_i,
      name_localized = name_id,
      on_create_func = callback(self, self, "populate_weapons", weapon),
      on_create_data = item_data,
      identifier = BlackMarketGui.identifiers[identifier],
      override_slots = {
        columns,
        rows
      }
    })
  end
  return selected_tab
end

function NWC:populate_weapons(weapon, data, gui)
  gui:populate_weapon_category_new(data)
  local loadout = self.settings.weapons[weapon] or {}
  for k, v in ipairs(data) do
    local npc_version = v.empty_slot or NWC:get_npc_version(v.name)
    if npc_version then
      v.equipped = not v.locked_slot and not v.empty_slot and loadout.slot == v.slot and loadout.category == v.category and npc_version == loadout.name
      v.unlocked = true
      v.lock_texture = v.locked_slot and v.lock_texture
      v.lock_text = nil
      v.comparision_data = nil
      v.buttons = v.empty_slot and {v.locked_slot and "ew_unlock" or "ew_buy"} or {v.equipped and "w_unequip" or "w_equip", "w_mod", "w_preview", "w_sell"}
    else
      v.buttons = {}
      v.unlocked = false
      v.lock_texture = "guis/textures/pd2/lock_incompatible"
      v.lock_text = managers.localization:text("NWC_menu_locked_slot")
    end
  end
end

function NWC:select_weapon(weapon, data, gui)
  local loadout = self.settings.weapons[weapon] or {}
  if not data or data.equipped then
    loadout = nil
  else
    local crafted = managers.blackmarket:get_crafted_category_slot(data.category, data.slot)
    loadout.name = crafted.factory_id .. "_npc"
    loadout.blueprint = crafted.blueprint
    loadout.cosmetics = crafted.cosmetics and { id = crafted.cosmetics.id, quality = crafted.cosmetics.quality }
    loadout.slot = data.slot
    loadout.category = data.category
  end
  self.settings.weapons[weapon] = loadout
  return gui and gui:reload()
end

function NWC:show_weapon_selection(title, weapon)
  local menu_title = title
  local menu_message
  if self.settings.weapons[weapon] and self.settings.weapons[weapon].name then
    local weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(self.settings.weapons[weapon].name:gsub("_npc$", ""))
    local replacement = tweak_data.weapon[weapon_id] and managers.localization:text(tweak_data.weapon[weapon_id].name_id) or "unknown"
    menu_message = managers.localization:text("NWC_menu_weapon_message", { WEAPON = replacement })
  else
    menu_message = managers.localization:text("NWC_menu_weapon_message_default")
  end
  local menu_options = {
    {
      text = managers.localization:text("NWC_menu_select_from_primaries"),
      callback = function () self:open_weapon_category_menu("primaries", weapon) end
    },
    {
      text = managers.localization:text("NWC_menu_select_from_secondaries"),
      callback = function () self:open_weapon_category_menu("secondaries", weapon) end
    },
    {
      text = managers.localization:text("NWC_menu_use_default"),
      callback = function ()
        self.settings.weapons[weapon] = {
          random_mods = self.settings.weapons[weapon] and self.settings.weapons[weapon].random_mods
        }
      end
    },
    {--[[seperator]]},
    {
      text = managers.localization:text(self.settings.weapons[weapon] and self.settings.weapons[weapon].random_mods and "NWC_menu_disable_random_mods" or "NWC_menu_enable_random_mods"),
      callback = function ()
        self.settings.weapons[weapon] = self.settings.weapons[weapon] or {}
        self.settings.weapons[weapon].random_mods = not self.settings.weapons[weapon].random_mods
        self:show_weapon_selection(title, weapon)
      end
    },
    {--[[seperator]]},
    {
      text = managers.localization:text("menu_back"),
      is_cancel_button = true
    }
  }
  QuickMenu:new(menu_title, menu_message, menu_options, true)
end

function NWC:merge_tables(tbl1, tbl2)
  for k, v in pairs(tbl2) do
    if type(tbl1[k]) == "table" and type(v) == "table" then
      NWC:merge_tables(tbl1[k], v)
    else
      tbl1[k] = v
    end
  end
end

function NWC:save()
  local file = io.open(self.save_path .. "NWC_settings.txt", "w+")
  if file then
    file:write(json.encode(self.settings))
    file:close()
  end
end

function NWC:load()
  local file = io.open(self.save_path .. "NWC_settings.txt", "r")
  if file then
    local data = json.decode(file:read("*all")) or {}
    file:close()
    NWC:merge_tables(self.settings, data)
  end
end

Hooks:Add("LocalizationManagerPostInit", "LocalizationManagerPostInitNWC", function(loc)
  
  local system_language_key = SystemInfo:language():key()
  local system_is_english = system_language_key == Idstring("english"):key()
  local blt_language = BLT.Localization:get_language().language
  local language = "english"
  
  for _, filename in pairs(file.GetFiles(NWC.mod_path .. "loc/") or {}) do
    local str = filename:match("^(.*).txt$")
    if str then
      local system_match = not system_is_english and Idstring(str):key() == system_language_key
      local blt_match = system_is_english and str == blt_language
      local mod_match = false
      if system_match or blt_match or mod_match then
        language = str
        break
      end
    end
  end
  
  loc:load_localization_file(NWC.mod_path .. "loc/english.txt")
  loc:load_localization_file(NWC.mod_path .. "loc/" .. language .. ".txt")

end)

local menu_id_main = "NWCMenu"
local menu_id_weapons = "NWCMenuWeapons"
Hooks:Add("MenuManagerSetupCustomMenus", "MenuManagerSetupCustomMenusNWC", function(menu_manager, nodes)
  MenuHelper:NewMenu(menu_id_main)
  MenuHelper:NewMenu(menu_id_weapons)
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "MenuManagerPopulateCustomMenusNWC", function(menu_manager, nodes)

  NWC:load()

  MenuCallbackHandler.NWC_save = function ()
    NWC:save()
  end
  
  MenuCallbackHandler.NWC_toggle = function(self, item)
    NWC.settings[item:name()] = item:value() == "on"
  end
  
  MenuCallbackHandler.NWC_value = function(self, item)
    NWC.settings[item:name()] = item:value()
  end

  MenuHelper:AddToggle({
    id = "add_animations",
    title = "NWC_menu_add_animations",
    desc = "NWC_menu_add_animations_desc",
    callback = "NWC_toggle",
    value = NWC.settings.add_animations,
    menu_id = menu_id_main,
    priority = 100
  })
  
  MenuHelper:AddToggle({
    id = "force_hq",
    title = "NWC_menu_force_hq",
    desc = "NWC_menu_force_hq_desc",
    callback = "NWC_toggle",
    value = NWC.settings.force_hq,
    menu_id = menu_id_main,
    priority = 99
  })
  
  MenuHelper:AddToggle({
    id = "keep_types",
    title = "NWC_menu_keep_types",
    desc = "NWC_menu_keep_types_desc",
    callback = "NWC_toggle",
    value = NWC.settings.keep_types,
    menu_id = menu_id_main,
    priority = 98
  })
  
  MenuHelper:AddToggle({
    id = "keep_sounds",
    title = "NWC_menu_keep_sounds",
    desc = "NWC_menu_keep_sounds_desc",
    callback = "NWC_toggle",
    value = NWC.settings.keep_sounds,
    menu_id = menu_id_main,
    priority = 97
  })

  MenuHelper:AddDivider({
    id = "divider1",
    size = 16,
    menu_id = menu_id_main,
    priority = 90
  })
  
  local function weapon_name(name)
    local loc = managers.localization
    NWC._weapon_names = NWC._weapon_names or {
      beretta92 = loc:text("bm_w_b92fs"),
      c45 = loc:text("bm_w_glock_17"),
      raging_bull = loc:text("bm_w_raging_bull"),
      m4 = loc:text("bm_w_m4"),
      ak47 = loc:text("bm_w_ak74"),
      r870 = loc:text("bm_w_r870"),
      mossberg = loc:text("bm_w_huntsman"),
      mp5 = loc:text("bm_w_mp5"),
      mp5_tactical = loc:text("bm_w_mp5") .. " (Cloaker)",
      mp9 = loc:text("bm_w_mp9"),
      mac11 = loc:text("bm_w_mac10"),
      m14_sniper_npc = loc:text("bm_w_g3") .. " (Sniper)",
      saiga = loc:text("bm_w_saiga"),
      m249 = loc:text("bm_w_m249"),
      benelli = loc:text("bm_w_benelli"),
      g36 = loc:text("bm_w_g36"),
      ump = loc:text("bm_w_schakal"),
      scar_murky = loc:text("bm_w_scar"),
      rpk_lmg = loc:text("bm_w_rpk"),
      svd_snp = loc:text("bm_w_siltstone") .. " (Russian Sniper)",
      akmsu_smg = loc:text("bm_w_akmsu"),
      asval_smg = loc:text("bm_w_asval"),
      sr2_smg = loc:text("bm_w_sr2"),
      ak47_ass = loc:text("bm_w_ak74") .. " (Russian)",
      x_c45 = loc:text("bm_w_x_g17"),
      sg417 = loc:text("bm_w_contraband"),
      svdsil_snp = loc:text("bm_w_siltstone") .. " (Mobster Sniper)",
      mini = loc:text("bm_w_m134"),
      heavy_zeal_sniper = loc:text("bm_w_g3") .. " (ZEAL Sniper)"
    }
    return NWC._weapon_names[name] or name:pretty()
  end
  local priority = 50
  for _, name in ipairs(table.map_keys(NWC.settings.weapons, function (a, b) return weapon_name(a) < weapon_name(b) end)) do
    
    priority = priority - 1
    
    MenuCallbackHandler["NWC_setup_" .. name] = function (self)
      NWC:show_weapon_selection(weapon_name(name), name)
    end
    
    MenuHelper:AddButton({
      id = "weapon_" .. name,
      title = weapon_name(name),
      callback = "NWC_setup_" .. name,
      menu_id = menu_id_weapons,
      localized = false,
      priority = priority
    })
    
  end
  
end)

Hooks:Add("MenuManagerBuildCustomMenus", "MenuManagerBuildCustomMenusPlayerNWC", function(menu_manager, nodes)
  nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main, { back_callback = "NWC_save" })
  nodes[menu_id_weapons] = MenuHelper:BuildMenu(menu_id_weapons, { back_callback = "NWC_save" })
  MenuHelper:AddMenuItem(nodes["blt_options"], menu_id_main, "NWC_menu_main_name", "NWC_menu_main_desc")
  MenuHelper:AddMenuItem(nodes[menu_id_main], menu_id_weapons, "NWC_menu_weapons_name", "NWC_menu_weapons_desc")
end)

Hooks:Add("MenuManagerOnOpenMenu", "MenuManagerOnOpenMenuNWC", function ()
  for _, item in pairs(MenuHelper:GetMenu(menu_id_main)._items) do
    if item:name() == menu_id_weapons then
      item:set_enabled(not Utils:IsInGameState())
      break
    end
  end
end)