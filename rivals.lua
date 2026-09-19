--[[
  Methane | Rivals
  MethaneUI | logo rbxassetid://72404794660074
]]

-- Wait until the place is fully loaded before anything else
do
	local ok = pcall(function()
		if game.IsLoaded and not game:IsLoaded() then
			game.Loaded:Wait()
		end
	end)
	if not ok then
		repeat task.wait() until game:IsLoaded()
	end
	-- extra settle so PlayerGui / character systems exist
	pcall(function()
		local LP = game:GetService("Players").LocalPlayer
		if LP then
			pcall(function()
				LP:WaitForChild("PlayerGui", 15)
			end)
		end
	end)
	task.wait(0.25)
end

-- AC bypass (runs first, then main script after 2s)
do
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local LocalPlayer = Players.LocalPlayer

	local hookmetamethod = hookmetamethod
	local getrawmetatable = getrawmetatable
	local setreadonly = setreadonly
	local checkcaller = checkcaller
	local getnamecallmethod = getnamecallmethod
	local getconnections = getconnections

	local mt = getrawmetatable(game)
	setreadonly(mt, false)

	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
	    local method = getnamecallmethod()
	    -- Kick block
	    if method == "Kick" then
	        if self == LocalPlayer then
	            return
	        end
	        return oldNamecall(self, ...)
	    end
	    -- only string-scan remotes (skip Index/etc entirely)
	    if method == "FireServer" or method == "InvokeServer" then
	        local ok, name = pcall(function()
	            return string.lower(self.Name)
	        end)
	        if ok and name then
	            if string.find(name, "exploit", 1, true)
	                or string.find(name, "cheat", 1, true)
	                or string.find(name, "detect", 1, true)
	                or string.find(name, "ban", 1, true)
	                or string.find(name, "flag", 1, true)
	                or string.find(name, "validate", 1, true)
	                or string.find(name, "integrity", 1, true)
	                or string.find(name, "security", 1, true)
	                or string.find(name, "anticheat", 1, true)
	                or string.find(name, "ac_", 1, true) then
	                return
	            end
	        end
	    end
	    return oldNamecall(self, ...)
	end)

	setreadonly(mt, true)

	local function nukeConnections()
	    if not getconnections then return end
	    pcall(function()
	        for _, conn in ipairs(getconnections(LocalPlayer.CharacterAdded)) do
	            if not checkcaller() then
	                conn:Disable()
	            end
	        end
	    end)
	    pcall(function()
	        for _, conn in ipairs(getconnections(LocalPlayer.PlayerGui.ChildAdded)) do
	            if not checkcaller() then
	                conn:Disable()
	            end
	        end
	    end)
	end
	nukeConnections()

	ReplicatedStorage.DescendantAdded:Connect(function(obj)
	    if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
	        local name = obj.Name:lower()
	        if name:find("exploit") or name:find("cheat") or
	           name:find("detect") or name:find("ban") or
	           name:find("flag") or name:find("validate") or
	           name:find("integrity") or name:find("security") or
	           name:find("anticheat") or name:find("ac_") then
	            pcall(function() obj:Destroy() end)
	        end
	    end
	end)

	LocalPlayer.CharacterAdded:Connect(function()
	    task.wait(0.5)
	    nukeConnections()
	end)

	local oldIndex
	oldIndex = hookmetamethod(game, "__index", function(self, key)
	    if checkcaller() and key == "Kick" and self == LocalPlayer then
	        return function() end
	    end
	    return oldIndex(self, key)
	end)
end

task.wait(2)

-- ==================== MAIN SCRIPT ====================
local function mapFsPath(path)
	path = tostring(path or "")
	if path == "MethaneUI" or path:sub(1, 7) == "MethaneUI/" or path:sub(1, 7) == "MethaneUI\\" then
		path = "MethaneUI/UI" .. path:sub(7)
	end
	path = path:gsub("[Aa]ssistant", "Chat")
	return path
end
do
	local function wrap1(fn)
		if type(fn) ~= "function" then return fn end
		return function(path, ...) return fn(mapFsPath(path), ...) end
	end
	for _, name in ipairs({"isfolder","makefolder","delfolder","isfile","readfile","writefile","appendfile","delfile"}) do
		local fn = rawget(getfenv(), name) or (getgenv() and getgenv()[name])
		-- executor globals are global; wrap if present
	end
	if type(isfolder) == "function" then local _=isfolder; isfolder=function(p,...) return _(mapFsPath(p),...) end end
	if type(makefolder) == "function" then local _=makefolder; makefolder=function(p,...) return _(mapFsPath(p),...) end end
	if type(isfile) == "function" then local _=isfile; isfile=function(p,...) return _(mapFsPath(p),...) end end
	if type(readfile) == "function" then local _=readfile; readfile=function(p,...) return _(mapFsPath(p),...) end end
	if type(writefile) == "function" then local _=writefile; writefile=function(p,...) return _(mapFsPath(p),...) end end
end

local Library
do
	local ok, lib = pcall(function()
		-- always re-fetch if previous session cached a bad load
		if getgenv().MethaneLibrary and type(getgenv().MethaneLibrary) == "table" and getgenv().MethaneLibrary.Window then
			return getgenv().MethaneLibrary
		end
		local src = game:HttpGet(
			"https://raw.githubusercontent.com/iskasaputri020-wq/UI-LIB/refs/heads/main/library.lua"
		)
		if type(src) ~= "string" or #src < 1000 then
			error("HttpGet failed or empty library")
		end
		-- Playerlist fixes: labels, ipairs, no dupes, multi status apply
		src = src:gsub(
			'Items = { "Neutral", "Enemy", "Friendly" }',
			'Items = { "Neutral", "Priority", "Whitelist" }'
		)
		src = src:gsub('Value == "Enemy"', 'Value == "Priority"')
		src = src:gsub('Value == "Friendly"', 'Value == "Whitelist"')
		src = src:gsub(
			'for Index, Value in Players:GetPlayers() do',
			'for Index, Value in ipairs(Players:GetPlayers()) do'
		)
		-- click name: pairs() required; SafeCall(nil Callback) was the nil-call spam
		src = src:gsub(
			'for Index, Value in Playerlist.Players do',
			'for Index, Value in pairs(Playerlist.Players) do'
		)
		src = src:gsub(
			'Library:SafeCall(Playerlist.Callback, Playerlist.Selected)',
			'if Playerlist.Callback then Library:SafeCall(Playerlist.Callback, Playerlist.Selected) end'
		)
		src = src:gsub(
			'Selected = nil,\n            }',
			'Selected = nil,\n                Callback = function() end,\n            }'
		)
		src = src:gsub(
			'Name = "Status",\n                Flag = "PlayerlistStatus"',
			'Name = "Priority Status",\n                Flag = "PlayerlistStatus"'
		)
		src = src:gsub(
			'function Playerlist:Add(Player)\n                local PlayerName = Player.Name',
			'function Playerlist:Add(Player)\n                if not Player or Player == Players.LocalPlayer then return end\n                if Playerlist.Players[Player.Name] then return end\n                local PlayerName = Player.Name'
		)
		src = src:gsub(
			'function Playerlist:Remove(Player)\n                if Playerlist.Players[Player.Name] then\n                    Playerlist.Players[Player.Name].Items.NewPlayer.Instance:Destroy()\n                end\n            end',
			'function Playerlist:Remove(Player)\n                if not Player then return end\n                local pd = Playerlist.Players[Player.Name]\n                if pd then\n                    pcall(function() if pd.Items and pd.Items.NewPlayer and pd.Items.NewPlayer.Instance then pd.Items.NewPlayer.Instance:Destroy() end end)\n                    Playerlist.Players[Player.Name] = nil\n                    if Playerlist.Selected == pd then Playerlist.Selected = nil end\n                end\n            end'
		)
		-- Multi-select: keep other rows selected
		src = src:gsub(
			'for Index, Value in Playerlist.Players do\n                            if Value ~= PlayerData then\n                                Value.IsSelected = false\n                                Value:ToggleState("Inactive")\n                            end\n                        end',
			'-- multi-select enabled (status applies to all IsSelected)'
		)

		-- Auto-load buttons after Save, before Share section (unique anchor)
		local anchor = 'Library:GetConfigsList(ConfigsDropdown)\n                end\n\n                local ShareSection = ConfigsSubPage:Section({ Name = "Share", Side = 2 })'
		local auto = [=[
Library:GetConfigsList(ConfigsDropdown)

                    ConfigsSection:Button({
                        Name = "Set Auto Load",
                        Callback = function()
                            if ConfigSelected then
                                writefile(ConfigsFolder .. "autoload.txt", tostring(ConfigSelected))
                                pcall(function()
                                    if getgenv().MethaneRefreshAutoloadLabel then
                                        getgenv().MethaneRefreshAutoloadLabel()
                                    end
                                end)
                                Library:Notification("Auto load set: " .. tostring(ConfigSelected), 3, Color3.fromRGB(0, 255, 0))
                            else
                                Library:Notification("No config selected", 3, Color3.fromRGB(255, 0, 0))
                            end
                        end
                    })

                    ConfigsSection:Button({
                        Name = "Clear Auto Load",
                        Callback = function()
                            pcall(function()
                                if isfile and isfile(ConfigsFolder .. "autoload.txt") and delfile then
                                    delfile(ConfigsFolder .. "autoload.txt")
                                end
                            end)
                            pcall(function()
                                if getgenv().MethaneRefreshAutoloadLabel then
                                    getgenv().MethaneRefreshAutoloadLabel()
                                end
                            end)
                            Library:Notification("Auto load cleared", 3, Color3.fromRGB(0, 255, 0))
                        end
                    })

                    local AutoLoadStatusLabel = ConfigsSection:Label({
                        Name = "Config Autoload: none"
                    })
                    getgenv().MethaneAutoloadLabel = AutoLoadStatusLabel
                    getgenv().MethaneRefreshAutoloadLabel = function()
                        local text = "Config Autoload: none"
                        pcall(function()
                            local f = ConfigsFolder .. "autoload.txt"
                            if isfile and isfile(f) then
                                local n = tostring(readfile(f) or "")
                                n = string.gsub(n, "^%s+", "")
                                n = string.gsub(n, "%s+$", "")
                                if n ~= "" then
                                    text = "Config Autoload: " .. n
                                end
                            end
                        end)
                        pcall(function()
                            local lab = getgenv().MethaneAutoloadLabel
                            if not lab then return end
                            if lab.SetText then
                                lab:SetText(text)
                            elseif lab.Items and lab.Items.Text and lab.Items.Text.Instance then
                                lab.Items.Text.Instance.Text = text
                            end
                        end)
                    end
                    pcall(function() getgenv().MethaneRefreshAutoloadLabel() end)
                end

                local ShareSection = ConfigsSubPage:Section({ Name = "Share", Side = 2 })
]=]
		do
			local i1, i2 = string.find(src, anchor, 1, true)
			if i1 then
				src = string.sub(src, 1, i1 - 1) .. auto .. string.sub(src, i2 + 1)
			else
				-- whitespace variance
				src = src:gsub(
					'Library:GetConfigsList%(ConfigsDropdown%)%s+end%s+local ShareSection = ConfigsSubPage:Section%(%{ Name = "Share", Side = 2 %}',
					auto
				)
			end
		end
		local fn, err = loadstring(src)
		if not fn then
			error("loadstring: " .. tostring(err))
		end
		return fn()
	end)
	if ok and lib then
		Library = lib
	else
		getgenv().MethaneLibrary = nil
		error("[Methane] failed to load UI library: " .. tostring(lib))
	end
end
getgenv().MethaneLibrary = Library
_G.Library = Library

local function VantaNotify(opts)
	-- silenced: only final load notification is shown
	return
end
getgenv().VantaNotify = VantaNotify

local ACCENT = Color3.fromRGB(152, 188, 255)
local LOGO = "rbxassetid://72404794660074"
local GAME_TAG = "rivals"
local LOADOUT_FILE = "Methane/Rivals/loadout.json"
local Options = {}
local Toggles = {}
getgenv().Options = Options
getgenv().Toggles = Toggles

-- Playerlist flags: Whitelist = never target, Priority = always prefer
local PlayerFlags = { whitelist = {}, priority = {} }
getgenv().MethanePlayerFlags = PlayerFlags

local function isWhitelisted(plr)
	return plr and PlayerFlags.whitelist[plr.UserId] == true
end
local function isPrioritized(plr)
	return plr and PlayerFlags.priority[plr.UserId] == true
end
local function syncPlayerFlagsFromList(playerlist)
	if not playerlist or type(playerlist.Players) ~= "table" then return end
	for k in pairs(PlayerFlags.whitelist) do PlayerFlags.whitelist[k] = nil end
	for k in pairs(PlayerFlags.priority) do PlayerFlags.priority[k] = nil end
	for _, data in pairs(playerlist.Players) do
		local plr = data and data.Player
		local st = tostring((data and data.Status) or "Neutral")
		if plr and plr.UserId then
			if st == "Whitelist" or st == "Friendly" then
				PlayerFlags.whitelist[plr.UserId] = true
			elseif st == "Priority" or st == "Enemy" then
				PlayerFlags.priority[plr.UserId] = true
			end
		end
	end
end

Library.Brand = "methane"
Library.GameName = "rivals"
pcall(function() Library:EnsureConfigFolders() end)

local function ico(name)
	name = tostring(name or "circle")
	local id = nil
	pcall(function() id = Library:ResolveIcon(name) end)
	if type(id) == "string" and id ~= "" then return id end
	return "rbxassetid://0"
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local COSMETIC_TYPES = { "Skin", "Wrap", "Charm", "Finisher" }
local COSMETIC_RARITIES = { "Common", "Rare", "Legendary", "Mythical", "Unique", "Unobtainable" }

local modules = {}
local function tryRequire(pathFn)
	local ok, res = pcall(pathFn)
	return ok and res or nil
end

local function loadModulesOnce()
	local mods = ReplicatedStorage:FindFirstChild("Modules") or ReplicatedStorage:WaitForChild("Modules", 30)
	if mods then
		if not modules.CosmeticLibrary then
			modules.CosmeticLibrary = tryRequire(function()
				return require(mods:WaitForChild("CosmeticLibrary", 15))
			end)
		end
		if not modules.ItemLibrary then
			modules.ItemLibrary = tryRequire(function()
				return require(mods:WaitForChild("ItemLibrary", 15))
			end)
		end
		if not modules.ShopLibrary then
			modules.ShopLibrary = tryRequire(function()
				return require(mods:WaitForChild("ShopLibrary", 10))
			end)
		end
		if not modules.EnumLibrary then
			modules.EnumLibrary = tryRequire(function()
				return require(mods:WaitForChild("EnumLibrary", 5))
			end)
		end
	end
	local ps = LP:FindFirstChild("PlayerScripts") or LP:WaitForChild("PlayerScripts", 30)
	local controllers = ps and (ps:FindFirstChild("Controllers") or ps:WaitForChild("Controllers", 15))
	if controllers and not modules.PlayerDataController then
		modules.PlayerDataController = tryRequire(function()
			return require(controllers:WaitForChild("PlayerDataController", 20))
		end)
	end
	return modules.CosmeticLibrary ~= nil
end

task.spawn(function()
	for _ = 1, 20 do
		if loadModulesOnce() then
			break
		end
		task.wait(1)
	end
end)

local function waitModules(timeout)
	local t0 = tick()
	while tick() - t0 < (timeout or 12) do
		if modules.CosmeticLibrary and modules.PlayerDataController then
			return true
		end
		task.wait(0.2)
	end
	return modules.CosmeticLibrary ~= nil and modules.PlayerDataController ~= nil
end

local skin = {
	fake_owned = {},
	fake_weapon_owned = {},
	equipped = {},
	unlock_type = "Skin",
	unlock_rarity = "Mythical",
	specific_type = "Skin",
	specific_name = "",
	specific_weapon = "",
	equip_type = "Skin",
	equip_name = "",
	equip_weapon = "Assault Rifle",
	equip_inverted = false,
	hooks_ready = false,
	constructing_weapon = nil,
	viewing_profile = nil,
	last_used_weapon = nil,
	placed_object_map = {},
}

local function deepCopyTable(t)
	if type(t) ~= "table" then
		return t
	end
	local n = {}
	for k, v in pairs(t) do
		n[k] = deepCopyTable(v)
	end
	return n
end

local function initInventoryFromGame()
	if not modules.PlayerDataController then
		return
	end
	pcall(function()
		if modules.PlayerDataController.WaitUntilLoaded then
			modules.PlayerDataController:WaitUntilLoaded()
		end
	end)
	local inv, wep
	pcall(function()
		inv = modules.PlayerDataController:Get("CosmeticInventory")
	end)
	pcall(function()
		wep = modules.PlayerDataController:Get("WeaponInventory")
	end)
	if type(inv) == "table" then
		-- merge real inv under fake map (keys that are true-owned)
		local copy = deepCopyTable(inv)
		for k, v in pairs(copy) do
			if skin.fake_owned[k] == nil then
				skin.fake_owned[k] = v
			end
		end
	end
	if type(wep) == "table" and (not skin.fake_weapon_owned or #skin.fake_weapon_owned == 0) then
		skin.fake_weapon_owned = deepCopyTable(wep)
	end
end

local function loadLoadoutFile()
	if not isfile or not readfile then
		return
	end
	pcall(function()
		if isfile(LOADOUT_FILE) then
			local data = HttpService:JSONDecode(readfile(LOADOUT_FILE))
			if type(data) == "table" then
				if type(data.fake_owned) == "table" then
					for k, v in pairs(data.fake_owned) do
						skin.fake_owned[k] = v
					end
				end
				if type(data.equipped) == "table" then
					skin.equipped = data.equipped
				end
				if type(data.fake_weapon_owned) == "table" then
					skin.fake_weapon_owned = data.fake_weapon_owned
				end
			end
		end
	end)
end

local function saveLoadoutFile()
	if not writefile then
		VantaNotify({ Title = "Loadout", Description = "writefile unavailable", Time = 3 })
		return false
	end
	local ok = pcall(function()
		pcall(function()
			if makefolder and not isfolder("Methane") then
				makefolder("Methane")
			end
		end)
		writefile(LOADOUT_FILE, HttpService:JSONEncode({
			fake_owned = skin.fake_owned,
			equipped = skin.equipped,
			fake_weapon_owned = skin.fake_weapon_owned,
			saved_at = os.time(),
		}))
	end)
	VantaNotify({
		Title = "Loadout",
		Description = ok and ("saved " .. LOADOUT_FILE) or "save failed",
		Time = 3,
	})
	return ok
end

local function CloneCosmetic(name, cosmetic_type, options)
	if not modules.CosmeticLibrary or not modules.CosmeticLibrary.Cosmetics then
		return nil
	end
	local base = modules.CosmeticLibrary.Cosmetics[name]
	if not base then
		return nil
	end
	local data = table.clone(base)
	data.Name = name
	data.Type = data.Type or cosmetic_type
	data.Seed = math.random(1, 1000000)
	if modules.EnumLibrary then
		pcall(function()
			local enum_id = modules.EnumLibrary:ToEnum(name)
			if enum_id then
				data.Enum, data.ObjectID = enum_id, enum_id
			end
		end)
	end
	if options then
		if options.inverted then
			data.Inverted = true
		end
		if options.favorites_only then
			data.OnlyUseFavorites = true
		end
	end
	return data
end

local function ResolveCosmetic(weaponName, cosmeticType)
	local equipped = skin.equipped[weaponName] and skin.equipped[weaponName][cosmeticType]
	if not equipped then
		return nil
	end
	if equipped.Name == "None" or equipped.Name == "NONE_COSMETIC" then
		return nil
	end
	return equipped
end

-- local equip — always OVERWRITES current Skin/Wrap/Charm/Finisher on that weapon
local function HandleEquip(weapon_name, cosmetic_type, cosmetic_name, options)
	options = options or {}
	if type(weapon_name) ~= "string" or weapon_name == "" then
		return false
	end
	if type(cosmetic_type) ~= "string" or cosmetic_type == "" then
		return false
	end

	skin.equipped[weapon_name] = skin.equipped[weapon_name] or {}

	-- hard clear previous for this slot so old skin cannot stick
	skin.equipped[weapon_name][cosmetic_type] = nil

	if not cosmetic_name or cosmetic_name == "" or cosmetic_name == "None" or cosmetic_name == "NONE_COSMETIC" then
		skin.equipped[weapon_name][cosmetic_type] = { Name = "NONE_COSMETIC", Type = cosmetic_type }
	else
		skin.fake_owned[cosmetic_name] = true
		local cloned = CloneCosmetic(cosmetic_name, cosmetic_type, {
			inverted = options.IsInverted,
			favorites_only = options.OnlyUseFavorites,
		})
		if cloned then
			-- force fields the game reads for "currently equipped"
			cloned.Name = cosmetic_name
			cloned.Type = cosmetic_type
			if options.IsInverted then
				cloned.Inverted = true
			end
			skin.equipped[weapon_name][cosmetic_type] = cloned
		else
			skin.equipped[weapon_name][cosmetic_type] = {
				Name = cosmetic_name,
				Type = cosmetic_type,
				Inverted = options.IsInverted and true or nil,
				Seed = math.random(1, 1000000),
			}
		end
	end

	pcall(function()
		if type(skin.fake_weapon_owned) ~= "table" then
			skin.fake_weapon_owned = {}
		end
		local found = false
		for _, weapon in pairs(skin.fake_weapon_owned) do
			if type(weapon) == "table" and weapon.Name == weapon_name then
				found = true
				local cos = skin.equipped[weapon_name][cosmetic_type]
				if cos and (cos.Name == "NONE_COSMETIC" or cos.Name == "None") then
					weapon[cosmetic_type] = nil
				else
					weapon[cosmetic_type] = cos
				end
			end
		end
		if not found then
			local entry = { Name = weapon_name, Level = 1, XP = 0, IsFavorited = false }
			local cos = skin.equipped[weapon_name][cosmetic_type]
			if cos and cos.Name ~= "NONE_COSMETIC" and cos.Name ~= "None" then
				entry[cosmetic_type] = cos
			end
			table.insert(skin.fake_weapon_owned, entry)
		end
	end)

	skin._wep_merged = false
	task.spawn(function()
		task.wait(0.1)
		pcall(function()
			if modules.PlayerDataController and modules.PlayerDataController.CurrentData then
				modules.PlayerDataController.CurrentData:Replicate("WeaponInventory")
			end
		end)
		pcall(function()
			if modules.PlayerDataController and modules.PlayerDataController.GetWeaponData then
				modules.PlayerDataController:GetWeaponData(weapon_name)
			end
		end)
	end)
	return true
end

-- dirty-flag merge so PDC.Get is not O(weapons*cosmetics) every call
local function ensureWeaponInventoryMerged()
	if skin._wep_merged then
		return skin.fake_weapon_owned
	end
	if type(skin.fake_weapon_owned) == "table" then
		for _, weapon in pairs(skin.fake_weapon_owned) do
			if type(weapon) == "table" and type(weapon.Name) == "string" then
				local eq = skin.equipped[weapon.Name]
				if type(eq) == "table" then
					for cos_type, cos_data in pairs(eq) do
						if type(cos_data) == "table" then
							if cos_data.Name == "NONE_COSMETIC" or cos_data.Name == "None" then
								weapon[cos_type] = nil
							else
								weapon[cos_type] = cos_data
							end
						end
					end
				end
			end
		end
	end
	skin._wep_merged = true
	return skin.fake_weapon_owned
end

local function markWeaponInventoryDirty()
	skin._wep_merged = false
end

--[[ LPH_NO_VIRTUALIZE ]] --[[ LPH_NO_OBFUSCATE ]]
local function installHooks()
	if skin.hooks_ready or not modules.CosmeticLibrary or not modules.PlayerDataController then
		return false
	end
	local CL = modules.CosmeticLibrary
	local PDC = modules.PlayerDataController

	local function isFake(name)
		return name and skin.fake_owned[name] ~= nil and skin.fake_owned[name] ~= false
	end

	if CL.OwnsCosmeticNormally then
		local old = CL.OwnsCosmeticNormally
		CL.OwnsCosmeticNormally = function(p1, p2, p3)
			if isFake(p3) then return true end
			return old(p1, p2, p3)
		end
	end
	if CL.OwnsCosmeticUniversally then
		local old = CL.OwnsCosmeticUniversally
		CL.OwnsCosmeticUniversally = function(p1, p2, p3)
			if isFake(p3) then return true end
			return old(p1, p2, p3)
		end
	end
	if CL.OwnsCosmeticForSomething then
		local old = CL.OwnsCosmeticForSomething
		CL.OwnsCosmeticForSomething = function(p1, p2, p3)
			if isFake(p3) then return true end
			return old(p1, p2, p3)
		end
	end
	if CL.OwnsCosmeticForWeapon then
		local old = CL.OwnsCosmeticForWeapon
		CL.OwnsCosmeticForWeapon = function(p1, p2, p3, p4)
			if isFake(p3) then return true end
			return old(p1, p2, p3, p4)
		end
	end
	if CL.OwnsCosmetic then
		local old = CL.OwnsCosmetic
		CL.OwnsCosmetic = function(self, inventory, name, weapon)
			if isFake(name) then return true end
			return old(self, inventory, name, weapon)
		end
	end

	if PDC.Get then
		local oldGet = PDC.Get
		PDC.Get = function(p1, ...)
			local key = ({ ... })[1]
			if key == "CosmeticInventory" then
				return skin.fake_owned
			end
			if key == "WeaponInventory" or key == "FreeWeaponUnlockCheck" then
				return ensureWeaponInventoryMerged()
			end
			if key == "UnclaimedRewards" then
				local inv = getgenv().AtomicRivalsInventory
				if inv and inv.fake_owned then
					return inv.fake_owned
				end
			end
			do
				local sp = getgenv().AtomicRivalsSpoofer
				if sp and sp.currency then
					local cur = sp.currency
					if key == "WeaponKeys" and cur.weapon_keys then return cur.weapon_keys_value end
					if key == "UnlockTokens" and cur.unlock_tokens then return cur.unlock_tokens_value end
					if key == "EventCurrency" and cur.event_currency then return cur.event_currency_value end
					if key == "Glory" and cur.glory then return cur.glory_value end
					if key == "SkinTickets" and cur.skin_tickets then return cur.skin_tickets_value end
				end
			end
			return oldGet(p1, ...)
		end
	end

	-- patch CurrentData.Get as well (source does this)
	--[[ LPH_NO_VIRTUALIZE ]]
	task.spawn(function()
		local t0 = tick()
		while tick() - t0 < 20 do
			local cd = PDC.CurrentData
			if cd and type(cd.Get) == "function" and not cd._atomicPatched then
				local old_get = cd.Get
				cd.Get = function(self, ...)
					local data = old_get(self, ...)
					local key = ({ ... })[1]
					if key == "CosmeticInventory" then
						return skin.fake_owned
					end
					if key == "WeaponInventory" or key == "FreeWeaponUnlockCheck" then
						return ensureWeaponInventoryMerged()
					end
					if key == "UnclaimedRewards" then
						local inv = getgenv().AtomicRivalsInventory
						if inv and inv.fake_owned then
							return inv.fake_owned
						end
					end
					do
						local sp = getgenv().AtomicRivalsSpoofer
						if sp then
							if sp.currency then
								local cur = sp.currency
								if key == "WeaponKeys" and cur.weapon_keys then return cur.weapon_keys_value end
								if key == "UnlockTokens" and cur.unlock_tokens then return cur.unlock_tokens_value end
								if key == "EventCurrency" and cur.event_currency then return cur.event_currency_value end
								if key == "Glory" and cur.glory then return cur.glory_value end
								if key == "SkinTickets" and cur.skin_tickets then return cur.skin_tickets_value end
							end
						end
					end
					return data
				end
				cd._atomicPatched = true
				break
			end
			task.wait(0.2)
		end
	end)

	if PDC.GetWeaponData then
		local oldWD = PDC.GetWeaponData
		PDC.GetWeaponData = function(p1, ...)
			local weapon_name = ({ ... })[1]
			local original_data, index = oldWD(p1, ...)
			local equipped_map = weapon_name and skin.equipped[weapon_name]

			local function applyEquipped(data)
				if not data or not equipped_map then
					return data
				end
				for cos_type, cos_data in pairs(equipped_map) do
					if type(cos_data) == "table" then
						if cos_data.Name == "NONE_COSMETIC" or cos_data.Name == "None" then
							data[cos_type] = nil
						else
							data[cos_type] = cos_data
						end
					end
				end
				return data
			end

			if original_data then
				return applyEquipped(original_data), index
			end

			if type(skin.fake_weapon_owned) == "table" then
				for _, weapon in pairs(skin.fake_weapon_owned) do
					if type(weapon) == "table" and weapon.Name == weapon_name then
						local fake_data = {
							Name = weapon_name,
							Level = 1,
							XP = 0,
							IsFavorited = false,
							Skin = nil,
						}
						return applyEquipped(fake_data), index
					end
				end
			end
			return original_data, index
		end
	end

	-- EquipCosmetic only. FireServer is SHARED across RemoteEvents — must check self
	-- or every shot / remote in the game gets blocked (ammo stuck, no register).
	pcall(function()
		local remote = ReplicatedStorage:FindFirstChild("Remotes")
			and ReplicatedStorage.Remotes:FindFirstChild("Data")
			and ReplicatedStorage.Remotes.Data:FindFirstChild("EquipCosmetic")
		if not remote then
			return
		end
		--[[ LPH_NO_VIRTUALIZE ]] --[[ LPH_NO_OBFUSCATE ]]
		if type(hookfunction) == "function" then
			local oldFire
			oldFire = hookfunction(remote.FireServer, newcclosure(function(self, ...)
				if self == remote then
					local a1, a2, a3, a4 = ...
					HandleEquip(a1, a2, a3, a4 or {})
					return
				end
				return oldFire(self, ...)
			end))
		end
		--[[ LPH_NO_VIRTUALIZE ]] --[[ LPH_NO_OBFUSCATE ]]
		if hookmetamethod and getnamecallmethod then
			local old
			old = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
				local method = getnamecallmethod()
				if method == "FireServer" and (self == remote or (typeof(self) == "Instance" and self.Name == "EquipCosmetic")) then
					local a1, a2, a3, a4 = ...
					HandleEquip(a1, a2, a3, a4 or {})
					return
				end
				return old(self, ...)
			end))
		end
	end)

	-- viewmodel image hook so skins show in weapon list
	if modules.ItemLibrary and modules.ItemLibrary.GetViewModelImageFromWeaponData then
		local getviewmodelimage_original = modules.ItemLibrary.GetViewModelImageFromWeaponData
		modules.ItemLibrary.GetViewModelImageFromWeaponData = function(p1, p2, p3)
			if not p2 then
				return getviewmodelimage_original(p1, p2, p3)
			end
			local weapon_name = p2.Name
			local resolved = ResolveCosmetic(weapon_name, "Skin")
			if resolved and resolved.Name and p1 and p1.ViewModels then
				local skin_info = p1.ViewModels[resolved.Name]
				if skin_info then
					return skin_info[p3 and "ImageHighResolution" or "Image"] or skin_info.Image
				end
			end
			return getviewmodelimage_original(p1, p2, p3)
		end
	end

	skin.hooks_ready = true
	return true
end

local function cosTable()
	return modules.CosmeticLibrary and modules.CosmeticLibrary.Cosmetics
end

local function GetCosmeticsByRarity(rarity)
	local results = {}
	local t = cosTable()
	if not t then return results end
	for name, cosmetic in pairs(t) do
		if cosmetic.Rarity == rarity then
			table.insert(results, name)
		end
	end
	return results
end

local function GetCosmeticsByType(type_name)
	local results = {}
	local t = cosTable()
	if not t then return results end
	for name, cosmetic in pairs(t) do
		if cosmetic.Type == type_name then
			table.insert(results, name)
		end
	end
	return results
end

local function GetAllCosmetics()
	local results = {}
	local t = cosTable()
	if not t then return results end
	for name in pairs(t) do
		table.insert(results, name)
	end
	return results
end

local function GetAllCosmeticsOfWeapon(weapon_name)
	local results = {}
	local t = cosTable()
	if not t then return results end
	for name, cosmetic in pairs(t) do
		if cosmetic.Type == "Skin" then
			if cosmetic.ItemName == weapon_name then
				table.insert(results, name)
			end
		else
			table.insert(results, name)
		end
	end
	return results
end

local function GetSpecificCosmetic(type_name, cos_name, weapon_name)
	local t = cosTable()
	if not t then return nil end
	for name, cosmetic in pairs(t) do
		if type_name == "Skin" then
			if name == cos_name and cosmetic.Type == type_name and cosmetic.ItemName == weapon_name then
				return name
			end
		else
			if name == cos_name and cosmetic.Type == type_name then
				return name
			end
		end
	end
	return nil
end

local function UnlockSelectedRarity()
	-- filter by BOTH selected type + rarity (UI has both dropdowns)
	local t = cosTable()
	if not t then
		return
	end
	local want_type = skin.unlock_type
	local want_rarity = skin.unlock_rarity
	for name, cosmetic in pairs(t) do
		if string.find(name, "MISSING_") then
			continue
		end
		if cosmetic.Rarity == want_rarity and cosmetic.Type == want_type then
			skin.fake_owned[name] = true
		end
	end
end

local function UnlockAllOfType()
	for _, cosmetic in ipairs(GetCosmeticsByType(skin.unlock_type)) do
		if not string.find(cosmetic, "MISSING_") then
			skin.fake_owned[cosmetic] = true
		end
	end
end

local function UnlockSpecific()
	local cosmetic = GetSpecificCosmetic(skin.specific_type, skin.specific_name, skin.specific_weapon)
	if cosmetic and not string.find(cosmetic, "MISSING_") then
		skin.fake_owned[cosmetic] = true
	end
end

local function UnlockAllForWeapon()
	for _, cosmetic in ipairs(GetAllCosmeticsOfWeapon(skin.specific_weapon)) do
		if not string.find(cosmetic, "MISSING_") then
			skin.fake_owned[cosmetic] = true
		end
	end
end

local function UnlockAll()
	for _, cosmetic in ipairs(GetAllCosmetics()) do
		if not string.find(cosmetic, "MISSING_") then
			skin.fake_owned[cosmetic] = true
		end
	end
end

local function UnlockAllWeapons()
	if not modules.ShopLibrary or not modules.ShopLibrary.GetReleasedOwnableWeapons then
		return
	end
	local owned = {}
	if type(skin.fake_weapon_owned) == "table" then
		for _, weapon_data in pairs(skin.fake_weapon_owned) do
			if type(weapon_data) == "table" and weapon_data.Name then
				owned[weapon_data.Name] = true
			end
		end
	end
	local ownables = modules.ShopLibrary:GetReleasedOwnableWeapons()
	for _, weapon_name in pairs(ownables) do
		if not owned[weapon_name] then
			skin._wep_merged = false
			table.insert(skin.fake_weapon_owned, {
				Name = weapon_name,
				Level = 1,
				XP = 0,
				IsFavorited = false,
				Skin = nil,
			})
		end
	end
end

-- Equip from our menu: local HandleEquip (source EquipApply fires remote which is intercepted)
local function EquipApply()
	local weapon_name = skin.equip_weapon
	local unlock_type = skin.equip_type
	local cosmetic_name = skin.equip_name
	local options = {}
	if unlock_type == "Wrap" then
		options.IsInverted = skin.equip_inverted and true or nil
	end
	if type(weapon_name) ~= "string" or weapon_name == "" then
		VantaNotify({ Title = "Equip", Description = "set a weapon name", Time = 3 })
		return
	end
	if cosmetic_name and cosmetic_name ~= "" then
		skin.fake_owned[cosmetic_name] = true
	end
	local name_to_send = (cosmetic_name ~= nil and cosmetic_name ~= "") and cosmetic_name or nil
	pcall(function()
		ReplicatedStorage.Remotes.Data.EquipCosmetic:FireServer(weapon_name, unlock_type, name_to_send, options)
	end)
	VantaNotify({
		Title = "Equip",
		Description = string.format("%s on %s → %s", tostring(unlock_type), tostring(weapon_name), tostring(cosmetic_name)),
		Time = 2,
	})
end

local function EquipApplyAll()
	local unlock_type = skin.equip_type
	local cosmetic_name = skin.equip_name
	if unlock_type == "Skin" then
		VantaNotify({ Title = "Equip", Description = "equip-all skips Skin (weapon-specific)", Time = 3 })
		return
	end
	if cosmetic_name and cosmetic_name ~= "" then
		skin.fake_owned[cosmetic_name] = true
	end
	local options = {}
	if unlock_type == "Wrap" then
		options.IsInverted = skin.equip_inverted and true or nil
	end
	local count = 0
	if modules.ItemLibrary and modules.ItemLibrary.Items then
		for weapon_name, weapon_data in pairs(modules.ItemLibrary.Items) do
			if unlock_type == "Finisher" and weapon_data and not weapon_data.CanEliminate then
				continue
			end
			if type(weapon_name) == "string" and weapon_name ~= "" then
				HandleEquip(weapon_name, unlock_type, cosmetic_name, options)
				count += 1
			end
		end
	end
	VantaNotify({ Title = "Equip", Description = "applied to " .. tostring(count) .. " weapons", Time = 3 })
end

--[[ LPH_NO_VIRTUALIZE ]]
local function installViewmodelHooks()
	-- full in-match / range visual apply (from rivals skinchanger source)
	task.spawn(function()
		task.wait(2)
		pcall(function()
			local clientItemPath = LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem
			local ClientItem = require(clientItemPath)
			if ClientItem._CreateViewModel then
				local orig = ClientItem._CreateViewModel
				ClientItem._CreateViewModel = function(self, viewmodelRef)
					local weaponName = self.Name
					local weaponPlayer = self.ClientFighter and self.ClientFighter.Player
					skin.constructing_weapon = (weaponPlayer == LP) and weaponName or nil

					if weaponPlayer == LP and skin.equipped[weaponName] and ResolveCosmetic(weaponName, "Skin") and viewmodelRef then
						pcall(function()
							local dataKey, skinKey, nameKey = self:ToEnum("Data"), self:ToEnum("Skin"), self:ToEnum("Name")
							if viewmodelRef[dataKey] then
								viewmodelRef[dataKey][skinKey] = ResolveCosmetic(weaponName, "Skin")
								viewmodelRef[dataKey][nameKey] = ResolveCosmetic(weaponName, "Skin").Name
							elseif viewmodelRef.Data then
								viewmodelRef.Data.Skin = ResolveCosmetic(weaponName, "Skin")
								viewmodelRef.Data.Name = ResolveCosmetic(weaponName, "Skin").Name
							end
						end)
					end

					local result = orig(self, viewmodelRef)
					skin.constructing_weapon = nil
					return result
				end
			end
		end)

		pcall(function()
			local viewModelModule = LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem:FindFirstChild("ClientViewModel")
			if not viewModelModule then
				return
			end
			local ClientViewModel = require(viewModelModule)
			if ClientViewModel.GetWrap then
				local orig = ClientViewModel.GetWrap
				ClientViewModel.GetWrap = function(self)
					local weaponName = self.ClientItem and self.ClientItem.Name
					local weaponPlayer = self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.Player
					if weaponName and weaponPlayer == LP and skin.equipped[weaponName] and ResolveCosmetic(weaponName, "Wrap") then
						return ResolveCosmetic(weaponName, "Wrap")
					end
					return orig(self)
				end
			end
			if ClientViewModel.new then
				local origNew = ClientViewModel.new
				ClientViewModel.new = function(replicatedData, clientItem)
					local weaponPlayer = clientItem.ClientFighter and clientItem.ClientFighter.Player
					local weaponName = skin.constructing_weapon or clientItem.Name

					if weaponPlayer == LP and skin.equipped[weaponName] then
						pcall(function()
							if not skin._rc then
								local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
								skin._rc = {
									cls = ReplicatedClass,
									Data = ReplicatedClass:ToEnum("Data"),
									Skin = ReplicatedClass:ToEnum("Skin"),
									Wrap = ReplicatedClass:ToEnum("Wrap"),
									Charm = ReplicatedClass:ToEnum("Charm"),
									ObjectID = ReplicatedClass:ToEnum("ObjectID"),
								}
							end
							local rc = skin._rc
							local dataKey = rc.Data
							replicatedData[dataKey] = replicatedData[dataKey] or {}
							local sk = ResolveCosmetic(weaponName, "Skin")
							if sk then replicatedData[dataKey][rc.Skin] = sk end
							local wp = ResolveCosmetic(weaponName, "Wrap")
							if wp then replicatedData[dataKey][rc.Wrap] = wp end
							local ch = ResolveCosmetic(weaponName, "Charm")
							if ch then replicatedData[dataKey][rc.Charm] = ch end
						end)
					end

					local result = origNew(replicatedData, clientItem)

					pcall(function()
						local objectID = nil
						pcall(function()
							local ReplicatedClass = require(ReplicatedStorage.Modules.ReplicatedClass)
							local dataKey = ReplicatedClass:ToEnum("Data")
							local objKey = ReplicatedClass:ToEnum("ObjectID")
							if replicatedData[dataKey] then
								objectID = replicatedData[dataKey][objKey]
							end
						end)
						if objectID == nil then
							pcall(function()
								objectID = result:Get("ObjectID") or result.ObjectID
							end)
						end
						if objectID and weaponPlayer == LP and skin.equipped[weaponName] then
							skin.placed_object_map = skin.placed_object_map or {}
							skin.placed_object_map[objectID] = weaponName
						end
					end)

					if weaponPlayer == LP and skin.equipped[weaponName] and ResolveCosmetic(weaponName, "Wrap") and result._UpdateWrap then
						task.spawn(function()
							result:_UpdateWrap()
							task.wait(0.1)
							if not result._destroyed then
								result:_UpdateWrap()
							end
						end)
					end
					return result
				end
			end
		end)

		pcall(function()
			local ViewProfile = require(LP.PlayerScripts.Modules.Pages.ViewProfile)
			if ViewProfile and ViewProfile.Fetch then
				local orig = ViewProfile.Fetch
				ViewProfile.Fetch = function(self, targetPlayer)
					skin.viewing_profile = targetPlayer
					return orig(self, targetPlayer)
				end
			end
		end)

		pcall(function()
			local ClientEntity = require(LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientEntity)
			if not ClientEntity or not ClientEntity.ReplicateFromServer then
				return
			end
			local orig = ClientEntity.ReplicateFromServer

			local function DecodeKillerArg(value)
				if value == nil then return nil end
				if typeof(value) == "Instance" then
					if value:IsA("Player") then return value.Name end
					return nil
				end
				if type(value) == "number" then
					return value == LP.UserId and LP.Name or nil
				end
				if type(value) == "string" then return value end
				if type(value) == "userdata" and modules.EnumLibrary and modules.EnumLibrary.FromEnum then
					local ok, decoded = pcall(function()
						return modules.EnumLibrary:FromEnum(value)
					end)
					if ok and decoded ~= nil then return tostring(decoded) end
					return tostring(value)
				end
				return tostring(value)
			end

			local function IsLocalPlayerKiller(args)
				local decoded = DecodeKillerArg(args[3])
				return decoded and decoded:lower() == LP.Name:lower()
			end

			local function ResolveFinisherWeapon()
				local primary = skin.last_used_weapon
				if primary and skin.equipped[primary] and ResolveCosmetic(primary, "Finisher") then
					return primary
				end
				for weaponName in pairs(skin.equipped) do
					if ResolveCosmetic(weaponName, "Finisher") then
						return weaponName
					end
				end
				return nil
			end

			local function ResolveFinisherEnum(finisherData)
				if not finisherData then return nil end
				if finisherData.Enum ~= nil then return finisherData.Enum end
				if modules.EnumLibrary and modules.EnumLibrary.ToEnum then
					local ok, result = pcall(function()
						return modules.EnumLibrary:ToEnum(finisherData.Name)
					end)
					if ok and result ~= nil then
						finisherData.Enum = result
						return result
					end
				end
				if finisherData.ObjectID ~= nil then
					finisherData.Enum = finisherData.ObjectID
					return finisherData.ObjectID
				end
				return nil
			end

			ClientEntity.ReplicateFromServer = function(self, action, ...)
				if action ~= "FinisherEffect" then
					return orig(self, action, ...)
				end
				local args = { ... }
				if not IsLocalPlayerKiller(args) then
					return orig(self, action, ...)
				end
				local weaponName = ResolveFinisherWeapon()
				if not weaponName then
					return orig(self, action, ...)
				end
				local finisherData = ResolveCosmetic(weaponName, "Finisher")
				local finisherEnum = ResolveFinisherEnum(finisherData)
				if finisherEnum == nil then
					return orig(self, action, ...)
				end
				if self.IsRendered and not self:IsRendered() then
					return
				end
				local ok, decoded = pcall(function()
					return self:FromEnum(finisherEnum)
				end)
				if not ok or decoded == nil then
					decoded = finisherData and finisherData.Name
				end
				if decoded == nil then
					return orig(self, action, ...)
				end
				pcall(function()
					self:_PlayFinisher(decoded, args[2], args[3], args[4])
				end)
			end
		end)

		pcall(function()
			-- FighterController GetWrap
			local fcMod = LP.PlayerScripts.Controllers:FindFirstChild("FighterController")
			if fcMod then
				pcall(function()
					modules.FighterController = modules.FighterController or require(fcMod)
				end)
			end
			if modules.FighterController and modules.FighterController.GetWrap then
				local orig_GetWrap = modules.FighterController.GetWrap
				modules.FighterController.GetWrap = function(self, objectID)
					local result = orig_GetWrap(self, objectID)
					if result then return result end
					if objectID and skin.placed_object_map then
						local weaponName = skin.placed_object_map[objectID]
						if weaponName and skin.equipped[weaponName] then
							local wrap = ResolveCosmetic(weaponName, "Wrap")
							if wrap then return wrap end
						end
					end
					return nil
				end
			end
		end)

		pcall(function()
			local JumpPads = require(LP.PlayerScripts.Modules.GameComponents.JumpPads)
			if not JumpPads or not JumpPads.CreateJumpPadVisual then
				return
			end
			local orig_CreateVisual = JumpPads.CreateJumpPadVisual
			JumpPads.CreateJumpPadVisual = function(self, name, size)
				if skin.equipped["Jump Pad"] then
					pcall(function()
						local s = ResolveCosmetic("Jump Pad", "Skin")
						if s and s.Name then
							name = s.Name
						end
					end)
				end
				return orig_CreateVisual(self, name, size)
			end
		end)

		VantaNotify({ Title = "Loading", Description = "ready...", Time = 3 })
	end)
end


task.spawn(function()
	if not waitModules(15) then
		VantaNotify({
			Title = "Cosmetics",
			Description = "modules not found — fully load rivals then re-exec",
			Time = 5,
		})
		return
	end
	initInventoryFromGame()
	loadLoadoutFile()
	if installHooks() then
		VantaNotify({ Title = "Loading", Description = "ready...", Time = 3 })
		installViewmodelHooks()
	end
end)


local _weaponListCache, _weaponListAt = nil, 0
local function getWeaponList()
	if _weaponListCache and (tick() - _weaponListAt) < 5 then
		return _weaponListCache
	end
	local names = {}
	local seen = {}
	if modules.ItemLibrary and modules.ItemLibrary.Items then
		for name in pairs(modules.ItemLibrary.Items) do
			if type(name) == "string" and name ~= "" and not seen[name] then
				seen[name] = true
				table.insert(names, name)
			end
		end
	end
	local ct = cosTable()
	if ct then
		for _, cos in pairs(ct) do
			if type(cos) == "table" and type(cos.ItemName) == "string" and cos.ItemName ~= "" and not seen[cos.ItemName] then
				seen[cos.ItemName] = true
				table.insert(names, cos.ItemName)
			end
		end
	end
	table.sort(names)
	if #names == 0 then
		return { "(waiting for modules)" }
	end
	_weaponListCache, _weaponListAt = names, tick()
	return names
end

local function getCosmeticNames(cos_type, weapon_name)
	local names = {}
	local ct = cosTable()
	if not ct then
		return { "(waiting for modules)" }
	end
	for name, cos in pairs(ct) do
		if type(name) ~= "string" or string.find(name, "MISSING_") then
			continue
		end
		if type(cos) ~= "table" or cos.Type ~= cos_type then
			continue
		end
		if cos_type == "Skin" then
			if weapon_name and weapon_name ~= "" and weapon_name ~= "(waiting for modules)" then
				if cos.ItemName ~= weapon_name then
					continue
				end
			end
		end
		table.insert(names, name)
	end
	table.sort(names)
	if #names == 0 then
		return { "(none)" }
	end
	return names
end

local function setDropdownValues(flag, values, preferred)
	local dd = Options and Options[flag]
	if not dd or type(values) ~= "table" or #values == 0 then
		return preferred
	end
	dd.Values = values
	dd.Options = values
	local pick = preferred
	local found = false
	if pick then
		for _, v in ipairs(values) do
			if v == pick then found = true break end
		end
	end
	if not found then pick = values[1] end
	dd.Value = pick
	pcall(function()
		local widget = dd._dd
		if not widget then return end
		if widget.SetOptions then widget:SetOptions(values)
		elseif widget.SetValues then widget:SetValues(values) end
		if widget.SetValueSilent then widget:SetValueSilent(pick)
		elseif widget.SetValue then
			local oldCb = widget.Callback
			widget.Callback = nil
			pcall(function() widget:SetValue(pick) end)
			widget.Callback = oldCb
		end
	end)
	return pick
end

local function refreshSpecDropdowns()
	local weapons = getWeaponList()
	local w = setDropdownValues("SpecWeapon", weapons, skin.specific_weapon)
	if w and w ~= "(waiting for modules)" then
		skin.specific_weapon = w
	end
	local cos = getCosmeticNames(skin.specific_type, skin.specific_weapon)
	local c = setDropdownValues("SpecName", cos, skin.specific_name)
	if c and c ~= "(none)" and c ~= "(waiting for modules)" then
		skin.specific_name = c
	else
		skin.specific_name = ""
	end
end

local function refreshEquipDropdowns()
	local weapons = getWeaponList()
	local w = setDropdownValues("EquipWeapon", weapons, skin.equip_weapon)
	if w and w ~= "(waiting for modules)" then
		skin.equip_weapon = w
	end
	local cos = getCosmeticNames(skin.equip_type, skin.equip_weapon)
	local c = setDropdownValues("EquipName", cos, skin.equip_name)
	if c and c ~= "(none)" and c ~= "(waiting for modules)" then
		skin.equip_name = c
	else
		skin.equip_name = ""
	end
end



-- ==================== WORLD (Aetherea visuals) ====================
local Lighting = game:GetService("Lighting")

local function safeRequire(inst)
	if not inst then return nil end
	local ok, mod = pcall(require, inst)
	if ok then return mod end
	return nil
end

task.spawn(function()
	pcall(function()
		local ps = LP:WaitForChild("PlayerScripts", 20)
		local controllers = ps and ps:WaitForChild("Controllers", 20)
		if controllers then
			local cam = controllers:FindFirstChild("CameraController")
			if cam and not modules.CameraController then
				modules.CameraController = safeRequire(cam)
			end
		end
	end)
	pcall(function()
		local path = LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter:FindFirstChild("Flashbang")
		if path and not modules.Flashbang then
			modules.Flashbang = safeRequire(path)
		end
	end)
	pcall(function()
		local path = LP.PlayerScripts.Modules:FindFirstChild("SmokeClouds")
		if path and not modules.SmokeClouds then
			modules.SmokeClouds = safeRequire(path)
		end
	end)
end)

local SKYBOX_LIST = {
	"None", "Aurora", "Battlerock", "Beach Bowl", "Buoy Base", "Clockwork",
	"Dark Matter", "Flash Black", "Ghostly", "Good Egg", "Melty Molten",
	"Shiverburn", "Spin Dig", "Sweet Mystery", "Terrace Dome",
}

local kSkyboxMap = {
	["None"] = {
		skybox_back = "rbxassetid://14147881792", skybox_down = "rbxassetid://14147882149",
		skybox_front = "rbxassetid://14147882761", skybox_left = "rbxassetid://14147883091",
		skybox_right = "rbxassetid://14147882405", skybox_up = "rbxassetid://14147881297",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Aurora"] = {
		skybox_back = "rbxassetid://116533337330584", skybox_down = "rbxassetid://80054106187171",
		skybox_front = "rbxassetid://94459139270943", skybox_left = "rbxassetid://116368999680791",
		skybox_right = "rbxassetid://125758104196312", skybox_up = "rbxassetid://107060226443967",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Battlerock"] = {
		skybox_back = "rbxassetid://131136284306917", skybox_down = "rbxassetid://89505977207531",
		skybox_front = "rbxassetid://140099243548102", skybox_left = "rbxassetid://121676169821100",
		skybox_right = "rbxassetid://97183886241447", skybox_up = "rbxassetid://107128620201556",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Beach Bowl"] = {
		skybox_back = "rbxassetid://81804134601271", skybox_down = "rbxassetid://92395364196932",
		skybox_front = "rbxassetid://81804134601271", skybox_left = "rbxassetid://81804134601271",
		skybox_right = "rbxassetid://81804134601271", skybox_up = "rbxassetid://119089964803065",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Buoy Base"] = {
		skybox_back = "rbxassetid://135017685421888", skybox_down = "rbxassetid://76610044495625",
		skybox_front = "rbxassetid://89675413438577", skybox_left = "rbxassetid://138307087837279",
		skybox_right = "rbxassetid://136723547010707", skybox_up = "rbxassetid://83404878914838",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Clockwork"] = {
		skybox_back = "rbxassetid://86284761193226", skybox_down = "rbxassetid://111425663631622",
		skybox_front = "rbxassetid://115606366886873", skybox_left = "rbxassetid://127287488325060",
		skybox_right = "rbxassetid://126844150113423", skybox_up = "rbxassetid://74510789204352",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Dark Matter"] = {
		skybox_back = "rbxassetid://97629693450922", skybox_down = "rbxassetid://97898396690232",
		skybox_front = "rbxassetid://134755033418084", skybox_left = "rbxassetid://118219143707956",
		skybox_right = "rbxassetid://114940065588775", skybox_up = "rbxassetid://95430908943263",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Flash Black"] = {
		skybox_back = "rbxassetid://78426835654353", skybox_down = "rbxassetid://6213218651",
		skybox_front = "rbxassetid://71970982976722", skybox_left = "rbxassetid://78426835654353",
		skybox_right = "rbxassetid://78426835654353", skybox_up = "rbxassetid://138004866371717",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Ghostly"] = {
		skybox_back = "rbxassetid://111506743048183", skybox_down = "rbxassetid://86198196348228",
		skybox_front = "rbxassetid://86265514167302", skybox_left = "rbxassetid://100257959405445",
		skybox_right = "rbxassetid://71935101953120", skybox_up = "rbxassetid://132011089223498",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Good Egg"] = {
		skybox_back = "rbxassetid://94681381933012", skybox_down = "rbxassetid://75843838469806",
		skybox_front = "rbxassetid://97891957473259", skybox_left = "rbxassetid://102971518965494",
		skybox_right = "rbxassetid://94588890960775", skybox_up = "rbxassetid://127368871569815",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Melty Molten"] = {
		skybox_back = "rbxassetid://131463907527649", skybox_down = "rbxassetid://116154164311420",
		skybox_front = "rbxassetid://113077689016278", skybox_left = "rbxassetid://79984367513909",
		skybox_right = "rbxassetid://82395195737484", skybox_up = "rbxassetid://117530106700350",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Shiverburn"] = {
		skybox_back = "rbxassetid://113636030839991", skybox_down = "rbxassetid://118027268179499",
		skybox_front = "rbxassetid://76405010847029", skybox_left = "rbxassetid://112044353352688",
		skybox_right = "rbxassetid://121078604572355", skybox_up = "rbxassetid://132486295432727",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Spin Dig"] = {
		skybox_back = "rbxassetid://124211111366754", skybox_down = "rbxassetid://120491795220431",
		skybox_front = "rbxassetid://130119279111055", skybox_left = "rbxassetid://70742671331562",
		skybox_right = "rbxassetid://76516826791940", skybox_up = "rbxassetid://100229310567751",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Sweet Mystery"] = {
		skybox_back = "rbxassetid://107264897520277", skybox_down = "rbxassetid://135637946277638",
		skybox_front = "rbxassetid://135705252786048", skybox_left = "rbxassetid://119667604517747",
		skybox_right = "rbxassetid://75904303027092", skybox_up = "rbxassetid://97011146822716",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
	["Terrace Dome"] = {
		skybox_back = "rbxassetid://98684100016510", skybox_down = "rbxassetid://108354040356521",
		skybox_front = "rbxassetid://95723629635852", skybox_left = "rbxassetid://106269064939837",
		skybox_right = "rbxassetid://136234415079744", skybox_up = "rbxassetid://75385962780878",
		sun_texture = "rbxasset://sky/sun.jpg", moon_texture = "rbxasset://sky/moon.jpg",
	},
}

local LIGHTING_STYLE_MAP = {
	Realistic = Enum.LightingStyle.Realistic,
	Soft = Enum.LightingStyle.Soft,
}

local world = {
	lighting_enabled = false,
	ambient_color = Lighting.Ambient,
	outdoor_ambient_color = Lighting.OutdoorAmbient,
	shift_top = Lighting.ColorShift_Top,
	shift_bottom = Lighting.ColorShift_Bottom,
	exposure = Lighting.ExposureCompensation,
	brightness = Lighting.Brightness,
	shadow_softness = Lighting.ShadowSoftness,
	diffuse_scale = Lighting.EnvironmentDiffuseScale,
	specular_scale = Lighting.EnvironmentSpecularScale,
	global_shadows = Lighting.GlobalShadows,
	lighting_style = "Realistic",
	atmosphere_enabled = false,
	density = 0.255,
	offset = 0.2,
	atm_color = Color3.fromRGB(140, 196, 231),
	decay = Color3.fromRGB(92, 60, 13),
	glare = 0,
	haze = 1.82,
	lighting_atmosphere = nil,
	cc_enabled = false,
	cc_brightness = 0,
	cc_contrast = 0,
	cc_saturation = 0,
	cc_tint = Color3.fromRGB(255, 255, 255),
	lighting_cc = nil,
	sunrays_enabled = false,
	sunrays_intensity = 0.25,
	sunrays_spread = 1,
	lighting_sunrays = nil,
	skybox_enabled = false,
	skybox_value = "None",
	skybox_back = "",
	skybox_down = "",
	skybox_front = "",
	skybox_left = "",
	skybox_right = "",
	skybox_up = "",
	sun_texture = "",
	moon_texture = "",
	star_count = 3000,
	sun_angular_size = 21,
	moon_angular_size = 11,
	clocktime = Lighting.ClockTime,
	auto_rotate = false,
	auto_rotate_speed = 1,
	auto_rotate_conn = nil,
	lighting_skybox = nil,
	camera_fov = 70,
	camera_resolution = 1,
	third_person = false,
	third_dist = 12,
	freecam = false,
	freecam_speed = 40,
	anti_flashbang = false,
	anti_smoke = false,
	_debounce = false,
	_orig = {
		Ambient = Lighting.Ambient,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		ColorShift_Top = Lighting.ColorShift_Top,
		ColorShift_Bottom = Lighting.ColorShift_Bottom,
		ExposureCompensation = Lighting.ExposureCompensation,
		Brightness = Lighting.Brightness,
		ShadowSoftness = Lighting.ShadowSoftness,
		EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
		EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
		GlobalShadows = Lighting.GlobalShadows,
		ClockTime = Lighting.ClockTime,
	},
}

local function SanitizeTextureId(id)
	if type(id) ~= "string" or id == "" then return "" end
	if string.sub(id, 1, 8) == "rbxasset" then return id end
	if string.match(id, "^%d+$") then return "rbxassetid://" .. id end
	return id
end

local function UpdateLightingOptions()
	if not world.lighting_enabled then return end
	world._debounce = true
	Lighting.Ambient = world.ambient_color
	Lighting.OutdoorAmbient = world.outdoor_ambient_color
	Lighting.ColorShift_Top = world.shift_top
	Lighting.ColorShift_Bottom = world.shift_bottom
	Lighting.ExposureCompensation = world.exposure
	Lighting.Brightness = world.brightness
	Lighting.ShadowSoftness = world.shadow_softness
	Lighting.EnvironmentDiffuseScale = world.diffuse_scale
	Lighting.EnvironmentSpecularScale = world.specular_scale
	Lighting.GlobalShadows = world.global_shadows
	pcall(function()
		Lighting.LightingStyle = LIGHTING_STYLE_MAP[world.lighting_style] or Enum.LightingStyle.Realistic
	end)
	world._debounce = false
end

local function RestoreLighting()
	local o = world._orig
	Lighting.Ambient = o.Ambient
	Lighting.OutdoorAmbient = o.OutdoorAmbient
	Lighting.ColorShift_Top = o.ColorShift_Top
	Lighting.ColorShift_Bottom = o.ColorShift_Bottom
	Lighting.ExposureCompensation = o.ExposureCompensation
	Lighting.Brightness = o.Brightness
	Lighting.ShadowSoftness = o.ShadowSoftness
	Lighting.EnvironmentDiffuseScale = o.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = o.EnvironmentSpecularScale
	Lighting.GlobalShadows = o.GlobalShadows
	Lighting.ClockTime = o.ClockTime
end

pcall(function()
	for _, property_name in ipairs({
		"Ambient", "OutdoorAmbient", "ColorShift_Top", "ColorShift_Bottom",
		"ExposureCompensation", "Brightness", "ShadowSoftness",
		"EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows", "LightingStyle",
	}) do
		Lighting:GetPropertyChangedSignal(property_name):Connect(function()
			if world._debounce or not world.lighting_enabled then return end
			UpdateLightingOptions()
		end)
	end
end)

local function UpdateAtmosphereOptions()
	if not world.atmosphere_enabled then
		if world.lighting_atmosphere then
			pcall(function() world.lighting_atmosphere:Destroy() end)
			world.lighting_atmosphere = nil
		end
		return
	end
	if world.lighting_atmosphere == nil then
		local original = Lighting:FindFirstChildOfClass("Atmosphere")
		if original then
			world.lighting_atmosphere = original:Clone()
			world.lighting_atmosphere.Parent = original.Parent
			original:Destroy()
		else
			world.lighting_atmosphere = Instance.new("Atmosphere")
			world.lighting_atmosphere.Parent = Lighting
		end
		Lighting.ChildAdded:Connect(function(child)
			if child:IsA("Atmosphere") and child ~= world.lighting_atmosphere then
				task.defer(function() child:Destroy() end)
			end
		end)
	end
	world.lighting_atmosphere.Density = world.density
	world.lighting_atmosphere.Offset = world.offset
	world.lighting_atmosphere.Color = world.atm_color
	world.lighting_atmosphere.Decay = world.decay
	world.lighting_atmosphere.Glare = world.glare
	world.lighting_atmosphere.Haze = world.haze
end

local function UpdateColorCorrectionOptions()
	if world.lighting_cc == nil then
		world.lighting_cc = Instance.new("ColorCorrectionEffect")
		world.lighting_cc.Parent = Lighting
	end
	world.lighting_cc.Enabled = world.cc_enabled
	world.lighting_cc.Brightness = world.cc_brightness
	world.lighting_cc.Contrast = world.cc_contrast
	world.lighting_cc.Saturation = world.cc_saturation
	world.lighting_cc.TintColor = world.cc_tint
end

local function UpdateSunRaysOptions()
	if world.lighting_sunrays == nil then
		local original = Lighting:FindFirstChildOfClass("SunRaysEffect")
		if original then
			world.lighting_sunrays = original:Clone()
			world.lighting_sunrays.Parent = original.Parent
			original:Destroy()
		else
			world.lighting_sunrays = Instance.new("SunRaysEffect")
			world.lighting_sunrays.Parent = Lighting
		end
		Lighting.ChildAdded:Connect(function(child)
			if child:IsA("SunRaysEffect") and child ~= world.lighting_sunrays then
				task.defer(function() child:Destroy() end)
			end
		end)
	end
	world.lighting_sunrays.Enabled = world.sunrays_enabled
	world.lighting_sunrays.Intensity = world.sunrays_intensity
	world.lighting_sunrays.Spread = world.sunrays_spread
end

local function UpdateSkybox()
	if not world.skybox_enabled then return end
	if world.lighting_skybox == nil then
		local original = Lighting:FindFirstChildOfClass("Sky")
		if original then
			world.lighting_skybox = original:Clone()
			world.lighting_skybox.Parent = original.Parent
			original:Destroy()
		else
			world.lighting_skybox = Instance.new("Sky")
			world.lighting_skybox.Parent = Lighting
		end
		Lighting.ChildAdded:Connect(function(child)
			if child:IsA("Sky") and child ~= world.lighting_skybox then
				task.defer(function() child:Destroy() end)
			end
		end)
	end
	local preset = kSkyboxMap[world.skybox_value] or kSkyboxMap["None"]
	local function face(custom, preset_val)
		local id = SanitizeTextureId(custom)
		if id ~= "" then return id end
		return SanitizeTextureId(preset_val or "")
	end
	world.lighting_skybox.SkyboxBk = face(world.skybox_back, preset.skybox_back)
	world.lighting_skybox.SkyboxDn = face(world.skybox_down, preset.skybox_down)
	world.lighting_skybox.SkyboxFt = face(world.skybox_front, preset.skybox_front)
	world.lighting_skybox.SkyboxLf = face(world.skybox_left, preset.skybox_left)
	world.lighting_skybox.SkyboxRt = face(world.skybox_right, preset.skybox_right)
	world.lighting_skybox.SkyboxUp = face(world.skybox_up, preset.skybox_up)
	world.lighting_skybox.SunTextureId = face(world.sun_texture, preset.sun_texture)
	world.lighting_skybox.MoonTextureId = face(world.moon_texture, preset.moon_texture)
	world.lighting_skybox.StarCount = world.star_count
	world.lighting_skybox.SunAngularSize = world.sun_angular_size
	world.lighting_skybox.MoonAngularSize = world.moon_angular_size
end

local function SetSkyboxAutoRotate()
	if world.auto_rotate_conn then
		pcall(function() world.auto_rotate_conn:Disconnect() end)
		world.auto_rotate_conn = nil
	end
	if not world.skybox_enabled or not world.auto_rotate then return end
	if world.lighting_skybox == nil then UpdateSkybox() end
	world.auto_rotate_conn = RunService.Heartbeat:Connect(function(dt)
		if not world.lighting_skybox then return end
		if not world.auto_rotate then return end
		local spd = tonumber(world.auto_rotate_speed) or 0
		if spd == 0 then return end
		local orient = world.lighting_skybox.SkyboxOrientation
		world.lighting_skybox.SkyboxOrientation = Vector3.new(0, orient.Y + dt * spd * 10, 0)
	end)
end

-- Camera loop: resolution stretch MUST be every frame when active.
-- FOV is applied only on slider change (callback) so we do not fight ADS/game FOV every frame.
do
	local last_res = 1
	local res_cf = CFrame.new()
	local res_active = false
	RunService.RenderStepped:Connect(function()
		local res = world.camera_resolution
		if type(res) ~= "number" or res == 1 then
			res_active = false
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		if res ~= last_res then
			last_res = res
			res_cf = CFrame.new(0, 0, 0, 1, 0, 0, 0, res, 0, 0, 0, 1)
		end
		res_active = true
		cam.CFrame = cam.CFrame * res_cf
	end)

	-- clock only when skybox on — Heartbeat is enough (not 60+ checks of FOV)
	RunService.Heartbeat:Connect(function()
		if not world.skybox_enabled then return end
		local ct = world.clocktime
		if Lighting.ClockTime ~= ct then
			Lighting.ClockTime = ct
		end
	end)
end

task.spawn(function()
	for _ = 1, 40 do
		if modules.Flashbang and modules.Flashbang.ReplicateFromServer then
			local orig = modules.Flashbang.ReplicateFromServer
			modules.Flashbang.ReplicateFromServer = function(p4, p5, ...)
				if world.anti_flashbang and p5 == "BlindEffect" then
					local flash_arg = ...
					pcall(function()
						if p4.IsRendered and p4:IsRendered() and p4._play_flash_sound_callback then
							p4._play_flash_sound_callback(flash_arg)
						end
					end)
					return
				end
				return orig(p4, p5, ...)
			end
			break
		end
		task.wait(0.5)
	end
end)

task.spawn(function()
	for _ = 1, 40 do
		if modules.SmokeClouds and modules.SmokeClouds._ObjectAdded then
			local orig = modules.SmokeClouds._ObjectAdded
			modules.SmokeClouds._ObjectAdded = function(p12, p13)
				local result = orig(p12, p13)
				if world.anti_smoke then
					pcall(function()
						if p12._smoke_clouds and p12._smoke_clouds[p13] and p12._smoke_clouds[p13].Model then
							p12._smoke_clouds[p13].Model:Destroy()
							p12._smoke_clouds[p13].Model = nil
						end
					end)
				end
				return result
			end
			break
		end
		task.wait(0.5)
	end
end)

getgenv().AtomicRivalsWorld = world


-- ==================== INVENTORY ====================
local LOOTBOX_NAMES = {
	"Skin Case", "Skin Case 2", "Skin Case 3",
	"Wrap Box", "Wrap Box 2", "Wrap Box 3",
	"Charm Capsule", "Finisher Pack", "Finisher Pack 2",
	"Spooky Skin Case", "Haunted Chest", "Festive Skin Case", "Jolly Chest",
	"Festive Wrap Box", "Festive Wrap Box 2", "Goodie Bag", "Prime Goodie Bag",
	"Weapon Crate", "Standard Weapon Crate", "Prime Weapon Crate", "Contraband Weapon Crate",
}


local inventory = {
	fake_owned = {},
	specific = { lootbox_name = "Skin Case", quantity = 1, weapon_name = "", new_entry = false },
	bulk = { quantity = 1 },
	delete = { backpack_entry = "", quantity = 1 },
	inject = {
		item_type = "Skin",
		weapon_name = "",
		cosmetic_name = "",
		stack_duplicates = false,
		quantity = 1,
	},
}

local function ensureInventoryList()
	if type(inventory.fake_owned) ~= "table" then inventory.fake_owned = {} end
	if next(inventory.fake_owned) ~= nil and inventory.fake_owned[1] == nil then
		local arr = {}
		for _, v in pairs(inventory.fake_owned) do
			if type(v) == "table" and v.Name then table.insert(arr, v) end
		end
		inventory.fake_owned = arr
	end
	return inventory.fake_owned
end

local function ReplicateInventory()
	pcall(function()
		if modules.PlayerDataController and modules.PlayerDataController.CurrentData then
			modules.PlayerDataController.CurrentData:Replicate("UnclaimedRewards")
		end
	end)
end

local function initInventoryBackpack()
	if not modules.PlayerDataController then return end
	pcall(function()
		if modules.PlayerDataController.WaitUntilLoaded then
			modules.PlayerDataController:WaitUntilLoaded()
		end
	end)
	local data
	pcall(function() data = modules.PlayerDataController:Get("UnclaimedRewards") end)
	if type(data) == "table" then
		inventory.fake_owned = deepCopyTable(data)
		ensureInventoryList()
	end
end

local function AddToBackpack()
	local item_name = inventory.specific.lootbox_name
	local quantity = inventory.specific.quantity
	local weapon_name = inventory.specific.weapon_name
	local new_entry = inventory.specific.new_entry
	if not modules.CosmeticLibrary or not modules.CosmeticLibrary.Rewards or not modules.CosmeticLibrary.Rewards[item_name] then
		VantaNotify({ Title = "Inventory", Description = "modules not ready / invalid case", Time = 3 })
		return
	end
	if not weapon_name or weapon_name == "" then weapon_name = "IsRandom" end
	local reward_entry = { Name = item_name, Quantity = quantity or 1, Weapon = weapon_name, ExpireTime = nil }
	local list = ensureInventoryList()
	if new_entry then
		table.insert(list, reward_entry)
	else
		local found = false
		for _, entry in ipairs(list) do
			if entry.Name == reward_entry.Name and entry.Weapon == reward_entry.Weapon and (entry.Quantity or 1) < 99 then
				entry.Quantity = (entry.Quantity or 1) + (reward_entry.Quantity or 1)
				found = true
				break
			end
		end
		if not found then table.insert(list, reward_entry) end
	end
	ReplicateInventory()
	VantaNotify({ Title = "Inventory", Description = "added to backpack", Time = 2 })
end

local function AddAllCases()
	if not modules.CosmeticLibrary or not modules.CosmeticLibrary.Rewards then return end
	local list = ensureInventoryList()
	local quantity = inventory.bulk.quantity
	for name, info in pairs(modules.CosmeticLibrary.Rewards) do
		if type(info) == "table" and info.Type == "Lootbox" then
			table.insert(list, { Name = name, Quantity = quantity or 1, Weapon = "IsRandom", ExpireTime = nil })
		end
	end
	ReplicateInventory()
	VantaNotify({ Title = "Inventory", Description = "all cases added", Time = 2 })
end

local function GetBackpackEntries()
	local results, seen = {}, {}
	for _, info in ipairs(ensureInventoryList()) do
		if type(info) == "table" and info.Name and not seen[info.Name] then
			seen[info.Name] = true
			table.insert(results, info.Name)
		end
	end
	if #results == 0 then return { "(empty)" } end
	table.sort(results)
	return results
end

local function DeleteAllBackpack()
	inventory.fake_owned = {}
	ReplicateInventory()
end

local function DeleteQuantity()
	local name = inventory.delete.backpack_entry
	local quantity = inventory.delete.quantity or 1
	local list = ensureInventoryList()
	for i, info in ipairs(list) do
		if info.Name == name then
			if (info.Quantity or 1) > quantity then info.Quantity = (info.Quantity or 1) - quantity
			else table.remove(list, i) end
			break
		end
	end
	ReplicateInventory()
end

local function DeleteAllOfEntry()
	local name = inventory.delete.backpack_entry
	local list = ensureInventoryList()
	for i = #list, 1, -1 do
		if list[i].Name == name then table.remove(list, i) end
	end
	ReplicateInventory()
end

local function InjectIntoBackpack()
	local item_type = inventory.inject.item_type
	local cosmetic_name = inventory.inject.cosmetic_name
	local weapon_name = inventory.inject.weapon_name
	local quantity = inventory.inject.quantity or 1
	if not cosmetic_name or cosmetic_name == "" then
		VantaNotify({ Title = "Inventory", Description = "select a cosmetic", Time = 2 })
		return
	end
	local reward_entry
	if item_type == "Skin" then
		if not weapon_name or weapon_name == "" then
			VantaNotify({ Title = "Inventory", Description = "skin needs a weapon", Time = 2 })
			return
		end
		reward_entry = { Name = cosmetic_name, Quantity = quantity, Weapon = weapon_name }
	else
		reward_entry = { Name = cosmetic_name, Quantity = quantity }
	end
	skin.fake_owned[cosmetic_name] = true
	local list = ensureInventoryList()
	if not inventory.inject.stack_duplicates then
		table.insert(list, reward_entry)
	else
		local found = false
		for _, entry in ipairs(list) do
			if entry.Name == reward_entry.Name and entry.Weapon == reward_entry.Weapon and (entry.Quantity or 1) < 99 then
				entry.Quantity = (entry.Quantity or 1) + (reward_entry.Quantity or 1)
				found = true
				break
			end
		end
		if not found then table.insert(list, reward_entry) end
	end
	ReplicateInventory()
	VantaNotify({ Title = "Inventory", Description = "injected " .. tostring(cosmetic_name), Time = 2 })
end

task.spawn(function()
	if waitModules(15) then
		initInventoryBackpack()
	end
end)

getgenv().AtomicRivalsInventory = inventory


-- ==================== SPOOFER (Aetherea) ====================
local spoofer = {
	device = "Desktop",
	old_device = "Desktop",
	spoof_device = false,
	device_spam = false,
	spam_rate = 1,
	_device_cancel = 0,

	display_name_value = LP.DisplayName,
	username_value = LP.Name,
	display_name = false,
	username = false,
	name_spoof_conn = {},

	avatar_userid = LP.UserId,
	spoof_avatar = false,
	thumb_spoof_conn = {},

	anonymous_mode = false,
	fake_names = {},
	anon_connections = {},

	leaderboard = {
		elo_value = 0,
		streak_value = 0,
		kills_value = 0,
		wins_value = 0,
		level_value = 0,
		ELO = false,
		Streak = false,
		Kills = false,
		Wins = false,
		Level = false,
	},

	badges = {
		Premium = false,
		Verified = false,
		Influencer = false,
		Admin = false,
	},

	charm = {
		charm_rank = "Use Spoofed ELO",
		arch_rank = 1,
		s0_charm = false,
		s1_charm = false,
		s2_charm = false,
		s3_charm = false,
	},

	fake_gift_robux_spent = 0,
	fake_gift_rewards_claimed = {},
	fake_robux = false,
	robux_amount = 0,
	fake_gifting = false,

	currency = {
		weapon_keys = false,
		unlock_tokens = false,
		event_currency = false,
		glory = false,
		skin_tickets = false,
		weapon_keys_value = 0,
		unlock_tokens_value = 0,
		event_currency_value = 0,
		glory_value = 0,
		skin_tickets_value = 0,
	},

	-- simple client display spoofs (not in Aetherea spoofer tab but requested)
	ping_spoof = false,
	ping_value = 50,
	fps_spoof = false,
	fps_value = 240,
}

pcall(function()
	spoofer.leaderboard.streak_value = LP:GetAttribute("StatisticDuelsWinStreak") or 0
	spoofer.leaderboard.level_value = LP:GetAttribute("Level") or 0
end)

task.spawn(function()
	if waitModules(20) then
		pcall(function()
			spoofer.currency.weapon_keys_value = modules.PlayerDataController:Get("WeaponKeys") or 0
			spoofer.currency.unlock_tokens_value = modules.PlayerDataController:Get("UnlockTokens") or 0
			spoofer.currency.event_currency_value = modules.PlayerDataController:Get("EventCurrency") or 0
			spoofer.currency.glory_value = modules.PlayerDataController:Get("Glory") or 0
			spoofer.currency.skin_tickets_value = modules.PlayerDataController:Get("SkinTickets") or 0
		end)
		pcall(function()
			local mods = ReplicatedStorage:FindFirstChild("Modules")
			local sl = mods and mods:FindFirstChild("SeasonLibrary")
			if sl and not modules.SeasonLibrary then
				local ok, mod = pcall(require, sl)
				if ok then modules.SeasonLibrary = mod end
			end
		end)
		pcall(function()
			if modules.ControlsController and modules.ControlsController.CurrentControls then
				spoofer.old_device = tostring(modules.ControlsController.CurrentControls)
			end
		end)
	end
end)

-- Device spoof 1:1 Aetherea (remote only — do not touch ControlsController)
local device_cancel = 0

local CHARM_RANKS = {
	"Use Spoofed ELO", "Unranked",
	"Bronze 1", "Bronze 2", "Bronze 3",
	"Silver 1", "Silver 2", "Silver 3",
	"Gold 1", "Gold 2", "Gold 3",
	"Platinum 1", "Platinum 2", "Platinum 3",
	"Diamond 1", "Diamond 2", "Diamond 3",
	"Onyx 1", "Onyx 2", "Onyx 3",
	"Nemesis", "Archnemesis",
}
local CHARM_ELO_MAP = {
	["Unranked"] = -1,
	["Bronze 1"] = 0, ["Bronze 2"] = 200, ["Bronze 3"] = 400,
	["Silver 1"] = 600, ["Silver 2"] = 800, ["Silver 3"] = 1000,
	["Gold 1"] = 1200, ["Gold 2"] = 1400, ["Gold 3"] = 1600,
	["Platinum 1"] = 1800, ["Platinum 2"] = 2000, ["Platinum 3"] = 2200,
	["Diamond 1"] = 2400, ["Diamond 2"] = 2600, ["Diamond 3"] = 2800,
	["Onyx 1"] = 3000, ["Onyx 2"] = 3200, ["Onyx 3"] = 3400,
	["Nemesis"] = 3600, ["Archnemesis"] = 3600,
}
local SEASON_NAME_MAP = {
	[0] = "Zero", [1] = "Warp", [2] = "Polar", [3] = "Fame",
	["Zero"] = 0, ["Warp"] = 1, ["Polar"] = 2, ["Fame"] = 3,
}
local SEASON_TOGGLE_MAP = {
	[0] = "s0_charm", [1] = "s1_charm", [2] = "s2_charm", [3] = "s3_charm",
}

local function SetDevice(use_old)
	local map = {
		Desktop = "MouseKeyboard",
		Mobile = "Touch",
		Console = "Gamepad",
		VR = "VR",
	}
	local key = use_old and spoofer.old_device or spoofer.device
	local dev = map[key] or "MouseKeyboard"
	-- Aetherea: only FireServer, nothing else
	pcall(function()
		ReplicatedStorage.Remotes.Replication.Fighter.SetControls:FireServer(dev)
	end)
end

local function SpoofDevice()
	if spoofer.spoof_device then
		SetDevice(false)
	else
		SetDevice(true)
	end
end

local function DeviceSpam()
	device_cancel += 1
	local token = device_cancel
	if not spoofer.device_spam then
		-- stop spam → restore real device
		SetDevice(true)
		return
	end
	task.spawn(function()
		local list = { "Desktop", "Mobile", "Console", "VR" }
		while spoofer.device_spam and token == device_cancel do
			spoofer.device = list[math.random(1, #list)]
			SetDevice(false)
			task.wait(math.max(0.1, spoofer.spam_rate or 1))
		end
		SetDevice(true)
	end)
end

local function isOurUi(obj)
	local ok, root = pcall(function() return nil end)
	if ok and root and obj:IsDescendantOf(root) then return true end
	return false
end

local function FormatNumber(n)
	n = tonumber(n) or 0
	local s = tostring(math.floor(n))
	local k
	while true do
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then break end
	end
	return s
end

local function ApplyNameSpoof(obj)
	-- Aetherea ApplyNameSpoof 1:1 (profile Wins label + Level/Streak values)
	if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
		return
	end
	if isOurUi and isOurUi(obj) then return end
	pcall(function()
		local text = obj.Text
		if typeof(text) ~= "string" then return end

		if spoofer.display_name then
			if obj.Name == "DisplayName" or obj.Name == "HeaderText" or obj.Name == "Title"
				or (obj.Parent and obj.Parent.Name == "NameContainer" and obj.Name == "Name")
				or (obj.Parent and obj.Parent.Name == "Title" and obj.Name == "TitleText") then
				text = string.gsub(text, LP.DisplayName, spoofer.display_name_value)
			end
		end
		if spoofer.username then
			if obj.Name == "Username"
				or (obj.Parent and obj.Parent.Name == "NameContainer" and obj.Name == "Handle")
				or (obj.Parent and obj.Parent.Name == "Subtitle" and obj.Name == "SubtitleText") then
				text = string.gsub(text, LP.Name, spoofer.username_value)
			end
		end

		local lb = spoofer.leaderboard
		-- Profile wins: TextLabel named "Wins" (Aetherea)
		if lb.Wins and obj.Name == "Wins" then
			text = FormatNumber(lb.wins_value)
		end
		if lb.Kills and (obj.Name == "Kills" or obj.Name == "Eliminations") then
			text = FormatNumber(lb.kills_value)
		end
		if lb.Level and obj.Parent and obj.Parent.Name == "Level" and obj.Name == "Value" then
			text = FormatNumber(lb.level_value)
		end
		if lb.Streak and obj.Parent and obj.Parent.Name == "Streak" and obj.Name == "Value" then
			text = FormatNumber(lb.streak_value)
		end
		if lb.ELO and obj.Parent and (obj.Parent.Name == "ELO" or obj.Parent.Name == "Elo") and obj.Name == "Value" then
			text = FormatNumber(lb.elo_value)
		end
		-- also catch Value under Wins/Kills parents
		if lb.Wins and obj.Name == "Value" and obj.Parent and obj.Parent.Name == "Wins" then
			text = FormatNumber(lb.wins_value)
		end
		if lb.Kills and obj.Name == "Value" and obj.Parent and (obj.Parent.Name == "Kills" or obj.Parent.Name == "Eliminations") then
			text = FormatNumber(lb.kills_value)
		end

		if obj.Text ~= text then
			obj.Text = text
		end
	end)
end

local function RefreshAllNameSpoofs()
	local lb = spoofer.leaderboard
	if not (spoofer.display_name or spoofer.username or (lb and (lb.Wins or lb.Kills or lb.Level or lb.Streak or lb.ELO))) then
		return
	end
	for obj, _ in pairs(spoofer.name_spoof_conn) do
		pcall(ApplyNameSpoof, obj)
	end
	pcall(function()
		local reg = spoofer._registerName
		if type(reg) ~= "function" then return end
		local pg = LP:FindFirstChild("PlayerGui")
		if not pg then return end
		for _, obj in ipairs(pg:GetDescendants()) do
			reg(obj)
		end
	end)
end

local NAME_SPOOF_ALLOWED = {
	DisplayName = true, Username = true, Name = true, Handle = true,
	TitleText = true, SubtitleText = true, HeaderText = true, Title = true,
	Wins = true, Kills = true, Eliminations = true, Value = true,
}

local function nameSpoofActive()
	local lb = spoofer.leaderboard
	return spoofer.display_name
		or spoofer.username
		or (lb and (lb.Wins or lb.Kills or lb.Level or lb.Streak or lb.ELO))
		or false
end

-- only GUI text (PlayerGui / Billboard / Surface) — skip world BasePart noise
local function isGuiTextContext(obj)
	local p = obj and obj.Parent
	for _ = 1, 14 do
		if not p then return false end
		local c = p.ClassName
		if c == "BillboardGui" or c == "SurfaceGui" or c == "ScreenGui" or c == "PlayerGui" then
			return true
		end
		p = p.Parent
	end
	return false
end

local function RegisterNameObject(obj)
	if not obj then return end
	if not nameSpoofActive() then return end
	if not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
	if not NAME_SPOOF_ALLOWED[obj.Name] then return end
	if not isGuiTextContext(obj) then return end
	ApplyNameSpoof(obj)
	if spoofer.name_spoof_conn[obj] then return end
	spoofer.name_spoof_conn[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
		if nameSpoofActive() then
			ApplyNameSpoof(obj)
		end
	end)
	obj.Destroying:Connect(function()
		local c = spoofer.name_spoof_conn[obj]
		if c then
			c:Disconnect()
			spoofer.name_spoof_conn[obj] = nil
		end
	end)
end
spoofer._registerName = RegisterNameObject

-- Lazy name-spoof watchers: no workspace scan until a spoof is actually enabled
do
	local pg_conn, ws_conn
	local watching = false

	local function attachRoot(root, store_key)
		if not root then return nil end
		local queue, scheduled = {}, false
		local function flush()
			scheduled = false
			local batch = queue
			queue = {}
			if not nameSpoofActive() then return end
			for i = 1, #batch do
				RegisterNameObject(batch[i])
			end
		end
		for _, obj in ipairs(root:GetDescendants()) do
			RegisterNameObject(obj)
		end
		return root.DescendantAdded:Connect(function(obj)
			if not nameSpoofActive() then return end
			queue[#queue + 1] = obj
			if scheduled then return end
			scheduled = true
			task.defer(flush)
		end)
	end

	function spoofer._startNameWatch()
		if watching then
			-- still re-scan PlayerGui on enable
			pcall(function()
				local pg = LP:FindFirstChild("PlayerGui")
				if pg then
					for _, obj in ipairs(pg:GetDescendants()) do
						RegisterNameObject(obj)
					end
				end
			end)
			return
		end
		watching = true
		pcall(function()
			pg_conn = attachRoot(LP:FindFirstChild("PlayerGui"))
			-- workspace only while spoofing (lobby billboards); still gui-filtered inside Register
			ws_conn = attachRoot(workspace)
		end)
	end

	function spoofer._stopNameWatch()
		-- keep connections cheap: callbacks already no-op when inactive
		-- disconnect workspace to stop mass DescendantAdded from characters/effects
		if ws_conn then
			pcall(function() ws_conn:Disconnect() end)
			ws_conn = nil
		end
		-- leave PlayerGui conn; rare adds. Full stop if fully inactive
		if not nameSpoofActive() and pg_conn then
			pcall(function() pg_conn:Disconnect() end)
			pg_conn = nil
			watching = false
		end
	end

	-- do NOT scan workspace at startup (this was the 20-player lobby FPS killer)
	task.defer(function()
		task.wait(1)
		if nameSpoofActive() then
			spoofer._startNameWatch()
		end
	end)
end

local function ApplyThumbnailSpoof(obj)
	if not spoofer.spoof_avatar or not obj or not obj:IsA("ImageLabel") then return end
	local uid = spoofer.avatar_userid
	if not uid then return end
	local url = string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=150&h=150", tostring(uid))
	pcall(function()
		if obj.Name == "AvatarThumbnail" or obj.Name == "Headshot" or obj.Name == "ImageLabel" then
			if obj.Parent and (obj.Parent.Name == "Thumbnail" or obj.Name == "AvatarThumbnail" or obj.Name == "Headshot") then
				obj.Image = url
			end
		end
	end)
end

local function RegisterThumbObject(obj)
	if not spoofer.spoof_avatar then return end
	if not obj or not obj:IsA("ImageLabel") then return end
	if not isGuiTextContext(obj) then return end
	ApplyThumbnailSpoof(obj)
	if spoofer.thumb_spoof_conn[obj] then return end
	spoofer.thumb_spoof_conn[obj] = obj:GetPropertyChangedSignal("Image"):Connect(function()
		if spoofer.spoof_avatar then
			ApplyThumbnailSpoof(obj)
		end
	end)
	obj.Destroying:Connect(function()
		local c = spoofer.thumb_spoof_conn[obj]
		if c then
			c:Disconnect()
			spoofer.thumb_spoof_conn[obj] = nil
		end
	end)
end

do
	local pg_conn, ws_conn
	local watching = false

	local function attachRoot(root)
		if not root then return nil end
		local queue, scheduled = {}, false
		local function flush()
			scheduled = false
			local batch = queue
			queue = {}
			if not spoofer.spoof_avatar then return end
			for i = 1, #batch do
				RegisterThumbObject(batch[i])
			end
		end
		for _, obj in ipairs(root:GetDescendants()) do
			RegisterThumbObject(obj)
		end
		return root.DescendantAdded:Connect(function(obj)
			if not spoofer.spoof_avatar then return end
			queue[#queue + 1] = obj
			if scheduled then return end
			scheduled = true
			task.defer(flush)
		end)
	end

	function spoofer._startThumbWatch()
		if watching then
			pcall(function()
				local pg = LP:FindFirstChild("PlayerGui")
				if pg then
					for _, obj in ipairs(pg:GetDescendants()) do
						RegisterThumbObject(obj)
					end
				end
			end)
			return
		end
		watching = true
		pcall(function()
			pg_conn = attachRoot(LP:FindFirstChild("PlayerGui"))
			ws_conn = attachRoot(workspace)
		end)
	end

	function spoofer._stopThumbWatch()
		if ws_conn then
			pcall(function() ws_conn:Disconnect() end)
			ws_conn = nil
		end
		if not spoofer.spoof_avatar and pg_conn then
			pcall(function() pg_conn:Disconnect() end)
			pg_conn = nil
			watching = false
		end
	end
end

-- Leaderboard 1:1 Aetherea (LeaderboardController serials)
local lb_binds = {}
local function LbUnbind(idx)
	if lb_binds[idx] then
		pcall(function() lb_binds[idx]:Disconnect() end)
		lb_binds[idx] = nil
	end
end

local function LbBind(idx, signal, fn)
	LbUnbind(idx)
	if signal then
		lb_binds[idx] = signal:Connect(fn)
	end
end

local function InsertPlayerByValue(list, user_id, value)
	-- Aetherea 1:1: remove existing entry then insert sorted by value (highest first)
	if type(list) ~= "table" then return end
	value = tonumber(value) or 0
	for i = #list, 1, -1 do
		local e = list[i]
		if type(e) == "table" then
			local id = tonumber(e.key) or tonumber(e.Key) or e.UserId or e.UserID or e.PlayerId
			if id == user_id or tostring(e.key) == tostring(user_id) then
				table.remove(list, i)
			end
		end
	end
	local rank = 1
	for i, entry in ipairs(list) do
		local v = tonumber(entry.value) or tonumber(entry.Value) or 0
		if v >= value then
			rank = i + 1
		else
			break
		end
	end
	-- include common fields games expect
	table.insert(list, rank, {
		key = tostring(user_id),
		value = value,
		UserId = user_id,
		UserID = user_id,
		PlayerId = user_id,
	})
end

local function EnsureLeaderboardController()
	if modules.LeaderboardController then return true end
	pcall(function()
		local ps = LP:FindFirstChild("PlayerScripts")
		local controllers = ps and ps:FindFirstChild("Controllers")
		local lc = controllers and controllers:FindFirstChild("LeaderboardController")
		if lc then
			local ok, mod = pcall(require, lc)
			if ok then modules.LeaderboardController = mod end
		end
	end)
	return modules.LeaderboardController ~= nil
end

local function ResetLeaderboard(name, config_idx)
	if not EnsureLeaderboardController() then return end
	LbUnbind(config_idx)
	pcall(function()
		local serial = modules.LeaderboardController.LeaderboardSerials[name]
		if serial and serial.Players then
			local user_id = LP.UserId
			for i = #serial.Players, 1, -1 do
				local player = serial.Players[i]
				if type(player) == "table" then
					if player.UserId == user_id or player.UserID == user_id or player.PlayerId == user_id
						or tonumber(player.key) == user_id then
						table.remove(serial.Players, i)
					end
				end
			end
			if modules.LeaderboardController.Refreshed then
				modules.LeaderboardController.Refreshed:Fire(name)
			end
		end
	end)
end

local function ModifyLeaderboard(config_idx, name, value)
	if not EnsureLeaderboardController() then return end
	value = tonumber(value) or 0
	task.spawn(function()
		local tries = 0
		while tries < 20 do
			local serials = modules.LeaderboardController and modules.LeaderboardController.LeaderboardSerials
			local serial = serials and serials[name]
			if serial and serial.Players and #serial.Players > 0 then
				break
			end
			tries += 1
			task.wait(0.5)
		end
		local user_id = LP.UserId
		pcall(function()
			local serial = modules.LeaderboardController.LeaderboardSerials[name]
			if serial and serial.Players then
				InsertPlayerByValue(serial.Players, user_id, value)
				if modules.LeaderboardController.Refreshed then
					modules.LeaderboardController.Refreshed:Fire(name)
				end
			end
		end)
		pcall(function()
			local UpdateRemote = ReplicatedStorage.Remotes.Misc.UpdateLeaderboard
			if not UpdateRemote then return end
			LbBind(config_idx, UpdateRemote.OnClientEvent, function(data)
				local lb_name = data and data.Name
				if not lb_name or lb_name ~= name then return end
				if not spoofer.leaderboard[config_idx] then return end
				task.defer(function()
					pcall(function()
						local serial = modules.LeaderboardController.LeaderboardSerials[name]
						if serial and serial.Players then
							InsertPlayerByValue(serial.Players, user_id, value)
							if modules.LeaderboardController.Refreshed then
								modules.LeaderboardController.Refreshed:Fire(name)
							end
						end
					end)
				end)
			end)
		end)
	end)
end

local function UpdateLeaderboardAttributes()
	local lb = spoofer.leaderboard
	if lb.ELO or lb.Streak or lb.Kills or lb.Wins or lb.Level then
		pcall(function() spoofer._startNameWatch() end)
	end
	if lb.ELO then
		ModifyLeaderboard("ELO", "Highest ELO", lb.elo_value)
	else
		ResetLeaderboard("Highest ELO", "ELO")
	end
	if lb.Streak then
		ModifyLeaderboard("Streak", "Current Highest Win Streak", lb.streak_value)
		pcall(function()
			LP:SetAttribute("StatisticDuelsWinStreak", lb.streak_value)
		end)
	else
		ResetLeaderboard("Current Highest Win Streak", "Streak")
	end
	if lb.Kills then
		ModifyLeaderboard("Kills", "Most Eliminations", lb.kills_value)
	else
		ResetLeaderboard("Most Eliminations", "Kills")
	end
	if lb.Wins then
		ModifyLeaderboard("Wins", "Most Wins", lb.wins_value)
	else
		ResetLeaderboard("Most Wins", "Wins")
	end
	if lb.Level then
		ModifyLeaderboard("Level", "Highest Level", lb.level_value)
		pcall(function()
			LP:SetAttribute("Level", lb.level_value)
		end)
	else
		ResetLeaderboard("Highest Level", "Level")
	end
	RefreshAllNameSpoofs()
end

-- Badges 1:1 Aetherea
local function UpdateBadgesOptions()
	LP:SetAttribute("IsInfluencer", spoofer.badges.Influencer and true or false)
	LP:SetAttribute("IsRobloxEmployee", spoofer.badges.Admin and true or false)
end

--[[ LPH_NO_VIRTUALIZE ]] --[[ LPH_NO_OBFUSCATE ]]
do
	local old_index
	old_index = hookmetamethod(game, "__index", newcclosure(function(self, key)
		-- cheapest path first: only when a badge spoof is on
		local b = spoofer.badges
		if b.Premium or b.Verified then
			if self == LP then
				if key == "MembershipType" and b.Premium then
					return Enum.MembershipType.Premium
				end
				if key == "HasVerifiedBadge" and b.Verified then
					return true
				end
			end
		end
		return old_index(self, key)
	end))
end


-- Charm 1:1 Aetherea
--[[ LPH_NO_VIRTUALIZE ]]
local function SetupSeasonCharmHook()
	if not modules.SeasonLibrary or modules.SeasonLibrary._atomicCharmHooked then return end
	if type(modules.SeasonLibrary.FormatSeasonRankCharm) ~= "function" then return end
	local original_fsrc = modules.SeasonLibrary.FormatSeasonRankCharm
	modules.SeasonLibrary.FormatSeasonRankCharm = function(self, p2, p3, p4, p5)
		local season_num = SEASON_NAME_MAP[p3]
		local elo = CHARM_ELO_MAP[spoofer.charm.charm_rank]
		if spoofer.charm.charm_rank == "Use Spoofed ELO" then
			elo = spoofer.leaderboard.elo_value
		end
		if season_num and SEASON_TOGGLE_MAP[season_num] and spoofer.charm[SEASON_TOGGLE_MAP[season_num]] then
			p4 = elo or p4
			p5 = spoofer.charm.arch_rank
		end
		return original_fsrc(self, p2, p3, p4, p5)
	end
	modules.SeasonLibrary._atomicCharmHooked = true
end

local function UpdateCharmOptions()
	SetupSeasonCharmHook()
	task.spawn(function()
		task.wait(0.5)
		if not modules.SeasonLibrary then return end
		for _, descendant in ipairs(workspace:GetDescendants()) do
			if not descendant:IsA("Model") then continue end
			if not descendant:FindFirstChild("Extra") then continue end
			local name = descendant.Name
			if string.sub(name, 1, 7) ~= "Season " then continue end
			local season_num = tonumber(string.sub(name, 8))
			if not season_num or not SEASON_TOGGLE_MAP[season_num] then continue end
			if not spoofer.charm[SEASON_TOGGLE_MAP[season_num]] then continue end
			local season_name = SEASON_NAME_MAP[season_num]
			if not season_name then continue end
			local elo = CHARM_ELO_MAP[spoofer.charm.charm_rank]
			if spoofer.charm.charm_rank == "Use Spoofed ELO" then
				elo = spoofer.leaderboard.elo_value
			end
			pcall(function()
				modules.SeasonLibrary:FormatSeasonRankCharm(descendant, season_name, elo, spoofer.charm.arch_rank)
			end)
		end
	end)
end

task.spawn(function()
	for _ = 1, 40 do
		if modules.SeasonLibrary or (waitModules and waitModules(1)) then
			SetupSeasonCharmHook()
			if modules.SeasonLibrary then break end
		end
		task.wait(0.5)
	end
end)

local function UpdateCurrencyOptions()
	pcall(function()
		if modules.PlayerDataController and modules.PlayerDataController.CurrentData then
			local cd = modules.PlayerDataController.CurrentData
			if spoofer.currency.weapon_keys then cd:Replicate("WeaponKeys") end
			if spoofer.currency.unlock_tokens then cd:Replicate("UnlockTokens") end
			if spoofer.currency.event_currency then cd:Replicate("EventCurrency") end
			if spoofer.currency.glory then cd:Replicate("Glory") end
			if spoofer.currency.skin_tickets then cd:Replicate("SkinTickets") end
		end
	end)
end

-- extend existing Get hooks for currency (spoofer flags)
-- installed after cosmetics hooks via genv table
getgenv().AtomicRivalsSpoofer = spoofer




-- ==================== MISC (visuals — Aetherea crosshair) ====================
local misc = {
	crosshair = {
		enabled = false,
		fill_color = Color3.fromRGB(255, 255, 255),
		outline_color = Color3.fromRGB(0, 0, 0),
		rotation = 0,
		rotation_speed = 0.5,
		bounce = 0,
		bounce_speed = 0.1,
		offset = 5,
		length = 20,
		thickness = 2,
		lerp = 1,
	},
}

local function SolveLine(a, r)
	local rad = math.rad(a)
	return Vector2.new(math.sin(rad) * r, math.cos(rad) * r)
end

-- Drawing API crosshair (Aetherea)
pcall(function()
	if type(Drawing) ~= "table" or type(Drawing.new) ~= "function" then
		return
	end
	local lines = {}
	for i = 1, 8 do
		local ok, line = pcall(Drawing.new, "Line")
		if ok and line then
			lines[i] = line
			line.Visible = false
			line.ZIndex = 50
		end
	end
	if #lines < 8 then return end

	local angles = { 0, 90, 180, 270 }
	local current_pos = workspace.CurrentCamera and (workspace.CurrentCamera.ViewportSize / 2) or Vector2.new(0, 0)

	local _xh_hidden = false
	RunService.RenderStepped:Connect(function()
		local state = misc.crosshair
		if not state.enabled then
			if not _xh_hidden then
				for i = 1, 8 do lines[i].Visible = false end
				_xh_hidden = true
			end
			return
		end
		_xh_hidden = false

		local cam = workspace.CurrentCamera
		if not cam then
			for i = 1, 8 do lines[i].Visible = false end
			return
		end

		local target_pos = cam.ViewportSize / 2
		if state.lerp and state.lerp > 0 and state.lerp < 1 then
			current_pos = current_pos:Lerp(target_pos, math.clamp(state.lerp, 0.01, 1))
		else
			current_pos = target_pos
		end

		local t = os.clock()
		local length = state.length
		local thickness = state.thickness * 2
		local anim_speed = state.bounce_speed * 0.5
		local rot_speed = state.rotation_speed * 0.5
		local scale = 1

		if state.bounce_speed > 0 and state.bounce > 0 then
			local phase = t * anim_speed * math.pi * 2
			local alpha = (math.sin(phase) + 1) * 0.5
			length = state.length + alpha * state.bounce
		end

		local spinangle = state.rotation
		if state.rotation_speed > 0 then
			spinangle = (state.rotation + t * rot_speed * 360) % 360
		end

		for i = 1, 4 do
			local basea = angles[i] + spinangle
			local p1 = current_pos + SolveLine(basea, state.offset * scale)
			local p2 = current_pos + SolveLine(basea, (state.offset + length) * scale)

			local fill = lines[i + 4]
			fill.Visible = true
			fill.Color = state.fill_color
			fill.From = p1
			fill.To = p2
			fill.Thickness = thickness

			local outline = lines[i]
			outline.Visible = true
			outline.Color = state.outline_color
			outline.From = current_pos + SolveLine(basea, state.offset * scale - 1)
			outline.To = current_pos + SolveLine(basea, (state.offset + length) * scale + 1)
			outline.Thickness = thickness + 2
		end
	end)
end)

getgenv().AtomicRivalsMisc = misc

-- ==================== BIND HELPERS ====================
local function bindToggle(page, flag, text, default, cb, risky)
	local mute = false
	local tog = page:AddToggle({
		Text = text, Default = default == true, Flag = flag, Risky = risky == true,
		Callback = function(v)
			if mute then return end
			Options[flag] = Options[flag] or {}; Options[flag].Value = v
			if Toggles[flag] then Toggles[flag].Value = v end
			if cb then pcall(cb, v) end
		end,
	})
	Options[flag] = { Value = default == true }
	Toggles[flag] = {
		Value = default == true,
		SetValue = function(self, v)
			mute = true; self.Value = v; Options[flag].Value = v
			pcall(function()
				if tog then
					if tog.Set then tog:Set(v)
					elseif tog.SetValue then tog:SetValue(v) end
				end
			end)
			mute = false
		end,
	}
	return tog
end

-- Attach UI-lib keybind on a toggle; Mode Toggle just drives the toggle on/off
local function bindToggleKey(page, flag, text, default, cb, risky)
	local tog = bindToggle(page, flag, text, default, cb, risky)
	pcall(function()
		if not tog or type(tog.Keybind) ~= "function" then return end
		tog:Keybind({
			Flag = tostring(flag) .. "Key",
			Mode = "Toggle",
			Callback = function(state)
				local on = state
				if type(on) ~= "boolean" then
					on = not ((Toggles[flag] and Toggles[flag].Value) or false)
				end
				if tog.Set then
					tog:Set(on)
				elseif Toggles[flag] and Toggles[flag].SetValue then
					Toggles[flag]:SetValue(on)
				end
			end,
		})
	end)
	return tog
end

local function bindSlider(page, flag, text, default, min, max, rounding, cb, suffix)
	local inc = 1
	if rounding == 1 then inc = 0.1 elseif rounding == 2 then inc = 0.01 elseif rounding == 3 then inc = 0.001 end
	page:AddSlider({
		Text = text, Default = default, Min = min, Max = max, Increment = inc, Suffix = suffix, Flag = flag,
		Callback = function(v)
			v = tonumber(v) or default
			Options[flag] = Options[flag] or {}; Options[flag].Value = v
			if cb then pcall(cb, v) end
		end,
	})
	Options[flag] = { Value = default }
end

local function bindDropdown(page, flag, text, values, default, cb)
	values = values or { "(none)" }
	if type(default) == "number" then default = values[default] or values[1] end
	if not default or default == "" then default = values[1] end
	local dd = page:AddDropdown({
		Text = text, Options = values, Default = default, Flag = flag,
		Callback = function(v)
			Options[flag] = Options[flag] or {}
			Options[flag].Value = v
			Options[flag].Values = values
			if cb then pcall(cb, v) end
		end,
	})
	Options[flag] = {
		Value = default, Values = values, Options = values, _dd = dd,
		SetValues = function(self, vals)
			self.Values = vals or {}; self.Options = self.Values
		end,
		SetValue = function(self, val) self.Value = val end,
	}
	return dd
end

local function bindInput(page, flag, text, default, placeholder, cb)
	local opts = {
		Text = text, Default = tostring(default or ""), Placeholder = placeholder or "", Flag = flag,
		Callback = function(v)
			Options[flag] = Options[flag] or {}; Options[flag].Value = v
			if cb then pcall(cb, v) end
		end,
	}
	if page.AddTextbox then page:AddTextbox(opts)
	elseif page.AddInput then page:AddInput(opts)
	elseif page.AddTextBox then page:AddTextBox(opts) end
	Options[flag] = { Value = tostring(default or "") }
end

local function bindButton(page, text, fn)
	page:AddButton({ Text = text, Callback = function() pcall(fn) end })
end

local function bindColor(page, flag, text, default, cb)
	-- Methane UI: Label:Colorpicker via makeSub AddColorPicker
	pcall(function()
		if page.AddColorPicker then
			page:AddColorPicker({
				Text = tostring(text or "Color"),
				Flag = flag,
				Default = default or Color3.new(1, 1, 1),
				Callback = function(col, alpha)
					Options[flag] = Options[flag] or {}
					Options[flag].Value = col
					if cb then pcall(cb, col) end
				end,
			})
		end
	end)
	Options[flag] = Options[flag] or { Value = default or Color3.new(1, 1, 1) }
end

-- ==================== METHANE WINDOW + VIND-COMPAT SUBTABS ====================

Library.MenuKeybind = tostring(Enum.KeyCode.RightShift)

local Library_Window = Library:Window({
	Title = "Methane",
	ButtonName = "Rivals",
	BrandName = "Methane",
	BrandAlign = "Center",
	Logo = LOGO,
})

-- Watermark: METHANE.LUA | RIVALS | FPS | MS | BUILD
pcall(function()
	local WM = Library:Watermark({ Name = "METHANE.LUA" })
	WM:SetDynamicTextProvider(function(fps)
		local ms = 0
		pcall(function()
			ms = math.floor((LP:GetNetworkPing() or 0) * 1000 + 0.5)
		end)
		if ms < 0 then ms = 0 end
		return string.format("METHANE.LUA | RIVALS | %s FPS | %s MS | BUILD: v1.023", tostring(fps or 0), tostring(ms))
	end)
	pcall(function() WM:SetVisibility(true) end)
	getgenv().MethaneWatermark = WM
end)

getgenv().VantaRivals = { Window = Library_Window, Library = Library, Methane = true }
getgenv().Library = Library

local function makeTab(name)
	return Library_Window:Page({ Name = name })
end

-- Subtab adapter: NO empty header section. First AddSection becomes the real first section.
local function makeSub(page, name, iconName)
	local sub = page:SubPage({ Name = name, Icon = ico(iconName or "circle") })
	local side = 1
	local current = nil
	local api = {}

	local function ensureSection(secName)
		if not current then
			current = sub:Section({ Name = tostring(secName or "General"), Side = 1 })
			side = 2
			return current
		end
		current = sub:Section({ Name = tostring(secName or "Section"), Side = side })
		side = (side == 1) and 2 or 1
		return current
	end

	function api:AddSection(secName, _)
		return ensureSection(secName)
	end

	function api:AddDivider() end
	function api:AddLineText(_) end
	function api:SelectSubTab(_) end

	local function need()
		if not current then
			ensureSection("General")
		end
		return current
	end

	function api:AddToggle(opts)
		opts = opts or {}
		return need():Toggle({
			Name = opts.Text or opts.Name or "Toggle",
			Flag = opts.Flag,
			Default = opts.Default == true,
			Risky = opts.Risky == true,
			Callback = opts.Callback or function() end,
		})
	end

	function api:AddSlider(opts)
		opts = opts or {}
		local inc = opts.Increment or 1
		local decimals = 0
		if type(inc) == "number" then
			if inc <= 0.001 then decimals = 0.001
			elseif inc <= 0.01 then decimals = 0.01
			elseif inc <= 0.1 then decimals = 0.1
			else decimals = 0 end
		end
		return need():Slider({
			Name = opts.Text or opts.Name or "Slider",
			Flag = opts.Flag,
			Default = opts.Default or 0,
			Min = opts.Min or 0,
			Max = opts.Max or 100,
			Decimals = decimals,
			Suffix = opts.Suffix or "",
			Callback = opts.Callback or function() end,
		})
	end

	function api:AddDropdown(opts)
		opts = opts or {}
		return need():Dropdown({
			Name = opts.Text or opts.Name or "Dropdown",
			Flag = opts.Flag,
			Items = opts.Options or opts.Items or { "(none)" },
			Default = opts.Default,
			Multi = opts.Multi == true,
			Callback = opts.Callback or function() end,
		})
	end

	function api:AddTextbox(opts)
		opts = opts or {}
		return need():Textbox({
			Name = opts.Text or opts.Name or "Input",
			Flag = opts.Flag,
			Default = opts.Default or "",
			Placeholder = opts.Placeholder or "",
			Callback = opts.Callback or function() end,
		})
	end

	function api:AddInput(opts)
		return self:AddTextbox(opts)
	end

	function api:AddButton(opts)
		opts = opts or {}
		return need():Button({
			Name = opts.Text or opts.Name or "Button",
			Callback = opts.Callback or function() end,
		})
	end

	function api:AddColorPicker(opts)
		opts = opts or {}
		local lab = need():Label({ Name = opts.Text or opts.Name or "Color" })
		return lab:Colorpicker({
			Flag = opts.Flag,
			Default = opts.Default or Color3.new(1, 1, 1),
			Callback = function(col, alpha)
				if opts.Callback then pcall(opts.Callback, col, alpha) end
			end,
		})
	end

	function api:AddColorpicker(opts)
		return self:AddColorPicker(opts)
	end

	function api:AddLabel(text)
		return need():Label({ Name = tostring(text or "") })
	end

	return api
end

local CombatTab = makeTab("Combat")
local VisualsTab = makeTab("Visuals")
local MovementTab = makeTab("Movement")
local CosmeticsTab = makeTab("Skins")
local MiscTab = makeTab("Misc")

-- Combat
local CombatRage = makeSub(CombatTab, "Rage", "crosshair")
local CombatLegit = makeSub(CombatTab, "Legit", "focus")
local CombatGunMods = makeSub(CombatTab, "Gun Mods", "swords")

-- Movement
local MovePlayer = makeSub(MovementTab, "Player", "user")

-- Visuals
local VisPlayer = makeSub(VisualsTab, "Player", "eye")
local VisWorld = makeSub(VisualsTab, "World", "globe")

-- Skinchanger: 2 subtabs only
-- 1) Main = unlock / specific / apply / save loadout (sections)
-- 2) Inventory = single / bulk / delete / inject (sections)
local CosMain = makeSub(CosmeticsTab, "Main", "sparkles")
local CosInv = makeSub(CosmeticsTab, "Inventory", "package")

local CosUnlock = CosMain
local CosSpecific = CosMain
local CosApply = CosMain
local CosSave = CosMain

local InvSingle = CosInv
local InvBulk = CosInv
local InvDelete = CosInv
local InvInject = CosInv

-- World → Visuals/World
local WorldLighting = VisWorld
local WorldAtmo = VisWorld
local WorldSky = VisWorld
local WorldCam = VisWorld

-- Misc
local MiscSpoof = makeSub(MiscTab, "Spoofer", "user")
local MiscCross = makeSub(MiscTab, "Crosshair", "crosshair")
local SpoofPlatform = MiscSpoof
local SpoofPlayer = MiscSpoof
local SpoofLB = MiscSpoof
local SpoofCur = MiscSpoof
local SpoofBadge = MiscSpoof

local Home = CombatTab
local Welcome = MiscCross
local DiscordTab = MiscCross
local InventoryTab = CosmeticsTab

-- Home removed
-- COMBAT (placeholders — features next)
----------------------------------------------------------------



----------------------------------------------------------------
----------------------------------------------------------------
-- VISUALS · PLAYER ESP (Universal style on Rivals models)
-- AC-safe local Drawing only; no friendly-color split
----------------------------------------------------------------
;(function()
	local ESP = {
		visuals_enabled = false,
		teammates = false,
		max_distance = 1500,

		box = {
			enabled = false,
			mode = "Full", -- Full | Corner
			thickness = 1,
			fill = false,
			fill_color = Color3.fromRGB(255, 255, 255),
			fill_transparency = 0.55,
			gradient = false,
			color = Color3.fromRGB(255, 255, 255),
			color2 = Color3.fromRGB(255, 50, 50), -- red gradient end
			outline = true,
			outline_color = Color3.fromRGB(0, 0, 0),
		},
		skeleton = {
			enabled = false,
			thickness = 1.5,
			gradient = false,
			color = Color3.fromRGB(255, 255, 255),
			color2 = Color3.fromRGB(255, 50, 50),
			headdot = false,
			headdot_size = 4,
			headdot_color = Color3.fromRGB(255, 255, 255),
		},
		tracer = {
			enabled = false,
			origin = "Bottom",
			thickness = 1,
			color = Color3.fromRGB(255, 255, 255),
			outline = true,
			outline_color = Color3.fromRGB(0, 0, 0),
		},
		chams = {
			enabled = false,
			fill_color = Color3.fromRGB(255, 255, 255),
			outline_color = Color3.fromRGB(255, 255, 255),
			fill_transparency = 0.5,
			outline_transparency = 0,
			visible_only = false, -- Occluded vs AlwaysOnTop (Sense)
		},
		health = {
			enabled = false,
			text = true,
			width = 2,
			color_high = Color3.fromRGB(80, 255, 120),
			color_mid = Color3.fromRGB(255, 220, 60),
			color_low = Color3.fromRGB(255, 60, 60),
			text_color = Color3.fromRGB(255, 255, 255),
			segments = 12,
		},
		flags = {
			username = false,
			distance = false,
			weapon = false,
			username_color = Color3.fromRGB(255, 255, 255),
			distance_color = Color3.fromRGB(200, 200, 200),
			weapon_color = Color3.fromRGB(255, 255, 255),
		},
	}
	getgenv().VantaRivalsESP = ESP

	local entries = {}
	local render_conn = nil

	local function W2V(v3)
		local cam = workspace.CurrentCamera
		if not cam then return Vector3.zero, false end
		return cam:WorldToViewportPoint(v3)
	end

	local function isWorldVisible(worldPos, cam)
		cam = cam or workspace.CurrentCamera
		if not cam then return false end
		local sp, onScreen = cam:WorldToViewportPoint(worldPos)
		-- WorldToViewportPoint handles all perspective/FOV math internally —
		-- the LookVector dot check breaks in first-person because the camera
		-- CFrame origin is at the head joint, not the HRP, so we skip it.
		-- onScreen + Z > 0 is sufficient: Z > 0 means in front of the near plane.
		if not onScreen or sp.Z <= 0 then return false end
		local vs = cam.ViewportSize
		if sp.X < -vs.X or sp.Y < -vs.Y or sp.X > vs.X * 2 or sp.Y > vs.Y * 2 then return false end
		return true, sp
	end

	local function lerpColor(a, b, t)
		t = math.clamp(t, 0, 1)
		return Color3.new(
			a.R + (b.R - a.R) * t,
			a.G + (b.G - a.G) * t,
			a.B + (b.B - a.B) * t
		)
	end

	local function threeWayColor(low, mid, high, t)
		t = math.clamp(t, 0, 1)
		if t < 0.5 then
			return lerpColor(low, mid, t * 2)
		end
		return lerpColor(mid, high, (t - 0.5) * 2)
	end

	local function isFriendly(plr)
		local our = LP:GetAttribute("TeamID")
		local their = plr:GetAttribute("TeamID")
		if our ~= nil and their ~= nil then return their == our end
		if plr.Team and LP.Team then return plr.Team == LP.Team end
		return false
	end

	local function getWeaponName(plr)
		local ok, name = pcall(function()
			if modules.FighterController and modules.FighterController.GetFighter then
				local f = modules.FighterController:GetFighter(plr)
				if f and f.EquippedItem and f.EquippedItem.Name then
					return tostring(f.EquippedItem.Name)
				end
			end
			local char = plr.Character
			if char then
				local tool = char:FindFirstChildOfClass("Tool")
				if tool then return tool.Name end
			end
			return "None"
		end)
		return (ok and name) or "None"
	end

	local R15_BONES = {
		{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
		{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
		{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
		{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
		{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	}
	local R6_BONES = {
		{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
	}

	local function newLine()
		local ok, o = pcall(Drawing.new, "Line")
		if not (ok and o) then return nil end
		o.Visible = false
		o.Thickness = 1
		o.ZIndex = 2
		o.Transparency = 1
		return o
	end
	local function newSquare()
		local ok, o = pcall(Drawing.new, "Square")
		if not (ok and o) then return nil end
		o.Visible = false
		o.Filled = false
		o.Thickness = 1
		o.ZIndex = 2
		o.Transparency = 1
		return o
	end
	local function newText()
		local ok, o = pcall(Drawing.new, "Text")
		if not (ok and o) then return nil end
		o.Visible = false
		o.Center = true
		o.Outline = true
		o.Size = 13
		o.Font = 2
		o.ZIndex = 3
		o.Transparency = 1
		return o
	end
	local function newCircle()
		local ok, o = pcall(Drawing.new, "Circle")
		if not (ok and o) then return nil end
		o.Visible = false
		o.Filled = true
		o.Thickness = 1
		o.ZIndex = 3
		o.Transparency = 1
		return o
	end

	local function hideDraw(o)
		if o == nil then return end
		pcall(function()
			if o.Visible ~= nil then o.Visible = false end
		end)
	end

	local function makeEntry()
		local e = {
			-- box: 8 corner segs + outlines, up to 18 full edges + outlines, fill square
			corner = {}, cornerO = {},
			edge = {}, edgeO = {},
			fill = newSquare(),
			-- skeleton
			skel = {},
			headdot = newCircle(),
			-- tracer
			tr = newLine(), trO = newLine(),
			-- health: bg/outline lines + segment lines
			hp_bg = newLine(),
			hp_ol = newLine(),
			hp_seg = {},
			hp_text = newText(),
			-- flags
			name = newText(),
			weapon = newText(),
			distance = newText(),
			chams = nil,
		}
		for i = 1, 8 do e.corner[i] = newLine(); e.cornerO[i] = newLine() end
		for i = 1, 20 do e.edge[i] = newLine(); e.edgeO[i] = newLine() end
		for i = 1, 16 do e.skel[i] = newLine() end
		for i = 1, 16 do e.hp_seg[i] = newLine() end
		return e
	end

	local function hideEntry(e)
		if not e then return end
		hideDraw(e.fill); hideDraw(e.tr); hideDraw(e.trO)
		hideDraw(e.headdot); hideDraw(e.hp_bg); hideDraw(e.hp_ol); hideDraw(e.hp_text)
		hideDraw(e.name); hideDraw(e.weapon); hideDraw(e.distance)
		for _, d in pairs(e.corner or {}) do hideDraw(d) end
		for _, d in pairs(e.cornerO or {}) do hideDraw(d) end
		for _, d in pairs(e.edge or {}) do hideDraw(d) end
		for _, d in pairs(e.edgeO or {}) do hideDraw(d) end
		for _, d in pairs(e.skel or {}) do hideDraw(d) end
		for _, d in pairs(e.hp_seg or {}) do hideDraw(d) end
		if e.chams then pcall(function() e.chams.Enabled = false end) end
	end

	local function destroyEntry(e)
		if not e then return end
		if e.chams then pcall(function() e.chams:Destroy() end) end
		local function kill(o)
			pcall(function() if o and o.Remove then o:Remove() end end)
		end
		kill(e.fill); kill(e.tr); kill(e.trO); kill(e.headdot)
		kill(e.hp_bg); kill(e.hp_ol); kill(e.hp_text)
		kill(e.name); kill(e.weapon); kill(e.distance)
		for _, d in pairs(e.corner or {}) do kill(d) end
		for _, d in pairs(e.cornerO or {}) do kill(d) end
		for _, d in pairs(e.edge or {}) do kill(d) end
		for _, d in pairs(e.edgeO or {}) do kill(d) end
		for _, d in pairs(e.skel or {}) do kill(d) end
		for _, d in pairs(e.hp_seg or {}) do kill(d) end
	end

	local function setEdge(ln, ol, a, b, col, thick, useOutline, ocol)
		if not ln then return end
		if useOutline and ol then
			ol.From = a; ol.To = b
			ol.Color = ocol
			ol.Thickness = thick + 2
			ol.ZIndex = 2
			ol.Transparency = 1
			ol.Visible = true
		elseif ol then
			ol.Visible = false
		end
		ln.From = a; ln.To = b
		ln.Color = col
		ln.Thickness = thick
		ln.ZIndex = 3
		ln.Transparency = 1
		ln.Visible = true
	end

	local function drawCornerBox(e, x, y, w, h, colTop, colBot, thick, useOutline, ocol)
		local len = math.clamp(math.min(w, h) * 0.25, 4, 18)
		local segs = {
			{ Vector2.new(x, y), Vector2.new(x + len, y), colTop },
			{ Vector2.new(x, y), Vector2.new(x, y + len), colTop },
			{ Vector2.new(x + w, y), Vector2.new(x + w - len, y), colTop },
			{ Vector2.new(x + w, y), Vector2.new(x + w, y + len), colTop },
			{ Vector2.new(x, y + h), Vector2.new(x + len, y + h), colBot },
			{ Vector2.new(x, y + h), Vector2.new(x, y + h - len), colBot },
			{ Vector2.new(x + w, y + h), Vector2.new(x + w - len, y + h), colBot },
			{ Vector2.new(x + w, y + h), Vector2.new(x + w, y + h - len), colBot },
		}
		for i = 1, 8 do
			local a, b, col = segs[i][1], segs[i][2], segs[i][3]
			setEdge(e.corner[i], e.cornerO[i], a, b, col, thick, useOutline, ocol)
		end
		for i = 1, #e.edge do hideDraw(e.edge[i]); hideDraw(e.edgeO[i]) end
	end

	local function drawFullBox(e, x, y, w, h, colTop, colBot, thick, useOutline, ocol, gradient)
		for i = 1, 8 do hideDraw(e.corner[i]); hideDraw(e.cornerO[i]) end
		for i = 1, #e.edge do hideDraw(e.edge[i]); hideDraw(e.edgeO[i]) end
		local tl = Vector2.new(x, y)
		local tr = Vector2.new(x + w, y)
		local bl = Vector2.new(x, y + h)
		local br = Vector2.new(x + w, y + h)
		local idx = 1
		setEdge(e.edge[idx], e.edgeO[idx], tl, tr, colTop, thick, useOutline, ocol); idx = idx + 1
		setEdge(e.edge[idx], e.edgeO[idx], bl, br, gradient and colBot or colTop, thick, useOutline, ocol); idx = idx + 1
		local segs = gradient and 8 or 1
		for s = 0, segs - 1 do
			local t0 = s / segs
			local t1 = (s + 1) / segs
			local col = gradient and lerpColor(colTop, colBot, (t0 + t1) * 0.5) or colTop
			setEdge(e.edge[idx], e.edgeO[idx], Vector2.new(x, y + h * t0), Vector2.new(x, y + h * t1), col, thick, useOutline, ocol)
			idx = idx + 1
			setEdge(e.edge[idx], e.edgeO[idx], Vector2.new(x + w, y + h * t0), Vector2.new(x + w, y + h * t1), col, thick, useOutline, ocol)
			idx = idx + 1
		end
	end

	-- Sense/Aetherea chams: Highlight parented to CoreGui/gethui folder, Adornee = character
	local chamFolder
	pcall(function()
		local parent = (gethui and gethui()) or game:GetService("CoreGui")
		chamFolder = parent:FindFirstChild("VantaChamsFolder")
		if not chamFolder then
			chamFolder = Instance.new("Folder")
			chamFolder.Name = "VantaChamsFolder"
			chamFolder.Parent = parent
		end
	end)

	local function ensureChams(e, char)
		if not char then return end
		local fillCol = ESP.chams.fill_color
		local olCol = ESP.chams.outline_color
		local fillT = ESP.chams.fill_transparency
		local olT = ESP.chams.outline_transparency or 0
		local depth = ESP.chams.visible_only and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop

		if e.chams and e.chams.Parent then
			e.chams.Adornee = char
			e.chams.FillColor = fillCol
			e.chams.OutlineColor = olCol
			e.chams.FillTransparency = fillT
			e.chams.OutlineTransparency = olT
			e.chams.DepthMode = depth
			e.chams.Enabled = true
			return
		end
		if e.chams then pcall(function() e.chams:Destroy() end) end
		local h = Instance.new("Highlight")
		h.Name = "VantaChams"
		h.FillColor = fillCol
		h.OutlineColor = olCol
		h.FillTransparency = fillT
		h.OutlineTransparency = olT
		h.DepthMode = depth
		h.Adornee = char
		h.Enabled = true
		h.Parent = chamFolder or ((gethui and gethui()) or game:GetService("CoreGui"))
		e.chams = h
	end

	local function removeChams(e)
		if e and e.chams then
			pcall(function() e.chams:Destroy() end)
			e.chams = nil
		end
	end

	-- fast box: head + feet only (2 projections) — smooth at full rate with 10+ players
	local function getBox(char, cam, root)
		cam = cam or workspace.CurrentCamera
		if not cam then return end
		root = root or char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		local foot = char:FindFirstChild("LeftFoot")
			or char:FindFirstChild("RightFoot")
			or char:FindFirstChild("Left Leg")
			or char:FindFirstChild("Right Leg")
		if not head and not root then return end

		local topPos
		if head then
			topPos = head.Position + Vector3.new(0, head.Size.Y * 0.5, 0)
		else
			topPos = root.Position + Vector3.new(0, root.Size.Y * 0.5, 0)
		end
		local botPos
		if foot then
			botPos = foot.Position - Vector3.new(0, foot.Size.Y * 0.5, 0)
		elseif root then
			botPos = root.Position - Vector3.new(0, root.Size.Y * 0.5 + 1.5, 0)
		else
			return
		end

		local top, onT = cam:WorldToViewportPoint(topPos)
		local bot, onB = cam:WorldToViewportPoint(botPos)
		if (not onT and not onB) or top.Z <= 0 or bot.Z <= 0 then return end

		local h = math.abs(bot.Y - top.Y)
		if h < 4 then return end
		local w = h * 0.65
		local cx = (top.X + bot.X) * 0.5
		local minX, maxX = cx - w * 0.5, cx + w * 0.5
		local minY, maxY = math.min(top.Y, bot.Y), math.max(top.Y, bot.Y)
		local vs = cam.ViewportSize
		if cx < -50 or cx > vs.X + 50 then return end
		return minX, minY, maxX, maxY
	end

	local function isTargetAlive(plr, char, hum)
		if not char or not char.Parent then return false end
		if not hum or not hum.Parent then return false end
		if hum.Health <= 0 then return false end
		-- cheap attribute checks only (FighterController:GetFighter every ESP frame was a major cost)
		if plr:GetAttribute("Dead") == true then return false end
		if char:GetAttribute("Dead") == true then return false end
		if plr:GetAttribute("IsAlive") == false then return false end
		return true
	end

	local function updateOne(plr, e)
		local char = plr.Character
		if not char or not char.Parent then hideEntry(e); removeChams(e); e._char = nil; return end
		-- reuse cached hum/root while character unchanged
		local hum, root
		if e._char == char and e._hum and e._hum.Parent and e._root and e._root.Parent then
			hum, root = e._hum, e._root
		else
			hum = char:FindFirstChildOfClass("Humanoid")
			root = char:FindFirstChild("HumanoidRootPart")
				or char:FindFirstChild("UpperTorso")
				or char:FindFirstChild("Torso")
			e._char, e._hum, e._root = char, hum, root
		end
		if not isTargetAlive(plr, char, hum) or not root or not root.Parent then
			hideEntry(e); removeChams(e); return
		end

		local cam = workspace.CurrentCamera
		if not cam then hideEntry(e); removeChams(e); return end

		local dist = (cam.CFrame.Position - root.Position).Magnitude
		if dist > ESP.max_distance then hideEntry(e); removeChams(e); return end

		-- cheap on-screen check via root only (skip before box math)
		local rsp, ron = cam:WorldToViewportPoint(root.Position)
		if not ron or rsp.Z <= 0 then
			hideEntry(e); removeChams(e); return
		end

		if isFriendly(plr) and not ESP.teammates then
			hideEntry(e); removeChams(e); return
		end
		-- LOD flag: skip skeleton past mid range (saves FindFirstChild spam)
		e._far = dist > 250

		local minX, minY, maxX, maxY = getBox(char, cam, root)
		if not minX then hideEntry(e); removeChams(e); return end
		local w, h = maxX - minX, maxY - minY
		if w < 2 or h < 2 then hideEntry(e); removeChams(e); return end
		local x, y = minX, minY

		local colTop = ESP.box.color
		local colBot = ESP.box.gradient and ESP.box.color2 or ESP.box.color
		local thick = math.max(ESP.box.thickness, 1)

		-- BOX
		if ESP.box.enabled then
			if ESP.box.mode == "Corner" then
				drawCornerBox(e, x, y, w, h, colTop, colBot, thick, ESP.box.outline, ESP.box.outline_color)
			else
				drawFullBox(e, x, y, w, h, colTop, colBot, thick, ESP.box.outline, ESP.box.outline_color, ESP.box.gradient)
			end
			if e.fill then
				if ESP.box.fill then
					e.fill.Visible = true
					e.fill.Filled = true
					e.fill.Position = Vector2.new(x, y)
					e.fill.Size = Vector2.new(w, h)
					e.fill.Color = ESP.box.fill_color
					e.fill.Transparency = ESP.box.fill_transparency
					e.fill.ZIndex = 1
				else
					e.fill.Visible = false
				end
			end
		else
			for i = 1, 8 do hideDraw(e.corner[i]); hideDraw(e.cornerO[i]) end
			for i = 1, #e.edge do hideDraw(e.edge[i]); hideDraw(e.edgeO[i]) end
			hideDraw(e.fill)
		end

		-- TRACER (Universal style + outline)
		if ESP.tracer.enabled then
			local vs = cam.ViewportSize
			local from
			if ESP.tracer.origin == "Top" then
				from = Vector2.new(vs.X * 0.5, 0)
			elseif ESP.tracer.origin == "Mouse" then
				local m = LP:GetMouse()
				local inset = 0
				pcall(function() inset = game:GetService("GuiService"):GetGuiInset().Y end)
				from = Vector2.new(m.X, m.Y + inset)
			elseif ESP.tracer.origin == "Center" then
				from = Vector2.new(vs.X * 0.5, vs.Y * 0.5)
			else
				from = Vector2.new(vs.X * 0.5, vs.Y)
			end
			local to = Vector2.new(x + w * 0.5, y + h)
			local tthick = math.max(ESP.tracer.thickness, 1)
			if ESP.tracer.outline and e.trO then
				e.trO.From = from; e.trO.To = to
				e.trO.Color = ESP.tracer.outline_color
				e.trO.Thickness = tthick + 2
				e.trO.ZIndex = 2
				e.trO.Transparency = 1
				e.trO.Visible = true
			else
				hideDraw(e.trO)
			end
			if e.tr then
				e.tr.From = from; e.tr.To = to
				e.tr.Color = ESP.tracer.color
				e.tr.Thickness = tthick
				e.tr.ZIndex = 3
				e.tr.Transparency = 1
				e.tr.Visible = true
			end
		else
			hideDraw(e.tr); hideDraw(e.trO)
		end

		-- SKELETON + gradient
		if ESP.skeleton.enabled and not e._far then
			local bones = char:FindFirstChild("UpperTorso") and R15_BONES or R6_BONES
			local nBones = #bones
			for i, pair in ipairs(bones) do
				local a = char:FindFirstChild(pair[1])
				local b = char:FindFirstChild(pair[2])
				local line = e.skel[i]
				if line and a and b and a:IsA("BasePart") and b:IsA("BasePart") then
					local sa, ona = W2V(a.Position)
					local sb, onb = W2V(b.Position)
					if ona and onb and sa.Z > 0 and sb.Z > 0 then
						local col = ESP.skeleton.color
						if ESP.skeleton.gradient then
							col = lerpColor(ESP.skeleton.color, ESP.skeleton.color2, (i - 1) / math.max(nBones - 1, 1))
						end
						line.From = Vector2.new(sa.X, sa.Y)
						line.To = Vector2.new(sb.X, sb.Y)
						line.Color = col
						line.Thickness = ESP.skeleton.thickness
						line.Transparency = 1
						line.Visible = true
					else
						line.Visible = false
					end
				elseif line then
					line.Visible = false
				end
			end
			for i = nBones + 1, #e.skel do hideDraw(e.skel[i]) end
			if ESP.skeleton.headdot and e.headdot then
				local head = char:FindFirstChild("Head")
				if head then
					local hp, on = W2V(head.Position)
					if on and hp.Z > 0 then
						e.headdot.Position = Vector2.new(hp.X, hp.Y)
						e.headdot.Radius = ESP.skeleton.headdot_size
						e.headdot.Color = ESP.skeleton.headdot_color
						e.headdot.Filled = true
						e.headdot.Transparency = 1
						e.headdot.Visible = true
					else
						e.headdot.Visible = false
					end
				else
					e.headdot.Visible = false
				end
			else
				hideDraw(e.headdot)
			end
		else
			for i = 1, #e.skel do hideDraw(e.skel[i]) end
			hideDraw(e.headdot)
		end

		-- HEALTHBAR: always-shown 3-way gradient along bar (Universal segments via Lines)
		if ESP.health.enabled then
			local maxH = hum.MaxHealth
			if typeof(maxH) ~= "number" or maxH <= 0 then maxH = 100 end
			local hp = hum.Health
			if typeof(hp) ~= "number" or hp < 0 then hp = 0 end
			local frac = math.clamp(hp / maxH, 0, 1)
			local barW = math.max(ESP.health.width or 4, 2)
			local bx = x - barW - 5
			local by = y
			local bh = h
			local cx = bx + barW * 0.5
			local segs = math.clamp(ESP.health.segments or 12, 4, 16)
			if segs > #e.hp_seg then segs = #e.hp_seg end

			-- dark outline full height
			if e.hp_bg then
				e.hp_bg.From = Vector2.new(cx, by)
				e.hp_bg.To = Vector2.new(cx, by + bh)
				e.hp_bg.Thickness = barW + 2
				e.hp_bg.Color = Color3.fromRGB(0, 0, 0)
				e.hp_bg.Transparency = 1
				e.hp_bg.ZIndex = 4
				e.hp_bg.Visible = true
			end

			for i = 1, #e.hp_seg do hideDraw(e.hp_seg[i]) end
			local filled = math.floor(segs * frac + 1e-6)
			if frac > 0 and filled < 1 then filled = 1 end
			if frac >= 0.999 then filled = segs end

			-- segments from BOTTOM: color by absolute height t (0 bottom=low → 1 top=high) so gradient always shows
			for i = 1, filled do
				local seg = e.hp_seg[i]
				if not seg then break end
				local t0 = (i - 1) / segs
				local t1 = i / segs
				-- i=1 near bottom
				local y0 = by + bh - bh * t1
				local y1 = by + bh - bh * t0
				local midT = (t0 + t1) * 0.5 -- 0 at bottom
				local col = threeWayColor(ESP.health.color_low, ESP.health.color_mid, ESP.health.color_high, midT)
				seg.From = Vector2.new(cx, y0)
				seg.To = Vector2.new(cx, y1)
				seg.Thickness = barW
				seg.Color = col
				seg.Transparency = 1
				seg.ZIndex = 5
				seg.Visible = true
			end

			if ESP.health.text and e.hp_text then
				-- top-left of healthbar (Universal style)
				local label = tostring(math.floor(hp + 0.5))
				e.hp_text.Text = label
				e.hp_text.Size = 12
				e.hp_text.Center = true
				e.hp_text.Outline = true
				e.hp_text.Color = ESP.health.text_color
				e.hp_text.Transparency = 1
				e.hp_text.ZIndex = 6
				e.hp_text.Position = Vector2.new(bx - 10, by)
				e.hp_text.Visible = true
			else
				hideDraw(e.hp_text)
			end
		else
			hideDraw(e.hp_bg); hideDraw(e.hp_ol); hideDraw(e.hp_text)
			for i = 1, #e.hp_seg do hideDraw(e.hp_seg[i]) end
		end

		-- FLAGS
		if ESP.flags.username and e.name then
			e.name.Text = plr.Name
			e.name.Position = Vector2.new(x + w * 0.5, y - 14)
			e.name.Color = ESP.flags.username_color
			e.name.Size = 13
			e.name.Center = true
			e.name.Visible = true
		else
			hideDraw(e.name)
		end
		local flagY = y + h + 2
		if ESP.flags.distance and e.distance then
			e.distance.Text = string.format("[%dm]", math.floor(dist + 0.5))
			e.distance.Position = Vector2.new(x + w * 0.5, flagY)
			e.distance.Color = ESP.flags.distance_color
			e.distance.Size = 12
			e.distance.Center = true
			e.distance.Visible = true
			flagY = flagY + 14
		else
			hideDraw(e.distance)
		end
		if ESP.flags.weapon and e.weapon then
			e.weapon.Text = getWeaponName(plr)
			e.weapon.Position = Vector2.new(x + w * 0.5, flagY)
			e.weapon.Color = ESP.flags.weapon_color
			e.weapon.Size = 12
			e.weapon.Center = true
			e.weapon.Visible = true
		else
			hideDraw(e.weapon)
		end

		-- CHAMS
		if ESP.chams.enabled then
			ensureChams(e, char)
		else
			removeChams(e)
		end
	end

	local function stopESP()
		if render_conn then render_conn:Disconnect(); render_conn = nil end
		for _, e in pairs(entries) do hideEntry(e); removeChams(e) end
	end

	local function startESP()
		if render_conn then return end
		local cached_list = {}
		local list_refresh = 0
		render_conn = RunService.RenderStepped:Connect(function()
			if not ESP.visuals_enabled then stopESP(); return end
			local cam = workspace.CurrentCamera
			if not cam then return end
			local now = os.clock()
			-- refresh player list every 0.25s
			if now >= list_refresh then
				list_refresh = now + 0.25
				local raw = Players:GetPlayers()
				local n = 0
				local seen = {}
				for i = 1, #raw do
					local p = raw[i]
					if p ~= LP then
						n = n + 1
						cached_list[n] = p
						seen[p] = true
					end
				end
				for i = n + 1, #cached_list do cached_list[i] = nil end
				for plr, e in pairs(entries) do
					if not seen[plr] then
						hideEntry(e)
						removeChams(e)
						entries[plr] = nil
					end
				end
			end
			-- full-rate redraw for every player (smooth); cost lives in cheap getBox
			for i = 1, #cached_list do
				local plr = cached_list[i]
				if plr and plr.Parent then
					local e = entries[plr]
					if not e then
						e = makeEntry()
						entries[plr] = e
					end
					updateOne(plr, e)
				end
			end
		end)
	end

	function ESP.Apply()
		if ESP.visuals_enabled then startESP() else stopESP() end
	end

	local function wipePlayer(plr)
		local e = entries[plr]
		if e then hideEntry(e); removeChams(e) end
	end

	local function bindCharacter(plr, char)
		if not char then return end
		local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 2)
		if hum then
			hum.Died:Connect(function() wipePlayer(plr) end)
			pcall(function()
				hum.HealthChanged:Connect(function(h)
					if h <= 0 then wipePlayer(plr) end
				end)
			end)
		end
		char.AncestryChanged:Connect(function(_, parent)
			if not parent then wipePlayer(plr) end
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP then
			if plr.Character then bindCharacter(plr, plr.Character) end
			plr.CharacterAdded:Connect(function(char)
				wipePlayer(plr)
				task.defer(function() bindCharacter(plr, char) end)
			end)
			plr.CharacterRemoving:Connect(function() wipePlayer(plr) end)
		end
	end
	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			wipePlayer(plr)
			task.defer(function() bindCharacter(plr, char) end)
		end)
		plr.CharacterRemoving:Connect(function() wipePlayer(plr) end)
	end)
	Players.PlayerRemoving:Connect(function(plr)
		local e = entries[plr]
		if e then destroyEntry(e); entries[plr] = nil end
	end)

	-- ===== UI (no friendly colors) =====
	pcall(function() VisPlayer:AddSection("Master ESP", ico("eye")) end)
	bindToggleKey(VisPlayer, "ESPMaster", "Enabled", false, function(v)
		ESP.visuals_enabled = v; ESP.Apply()
	end)
	bindToggle(VisPlayer, "ESPTeammates", "Teammates", false, function(v) ESP.teammates = v end)
	bindSlider(VisPlayer, "ESPMaxDist", "Max Distance", 1500, 50, 5000, 0, function(v) ESP.max_distance = v end, "m")

	pcall(function() VisPlayer:AddDivider() end)
	pcall(function() VisPlayer:AddSection("Box", ico("box")) end)
	bindToggle(VisPlayer, "ESPBox", "Enabled", false, function(v) ESP.box.enabled = v end)
	pcall(function() VisPlayer:AddLineText("Configure Box") end)
	bindDropdown(VisPlayer, "ESPBoxMode", "Mode", { "Full", "Corner" }, "Full", function(v) ESP.box.mode = v end)
	bindSlider(VisPlayer, "ESPBoxThick", "Thickness", 1, 1, 6, 0, function(v) ESP.box.thickness = v end, "px")
	bindToggle(VisPlayer, "ESPBoxOutline", "Outline", true, function(v) ESP.box.outline = v end)
	bindColor(VisPlayer, "ESPBoxOutlineCol", "Outline Color", ESP.box.outline_color, function(c) ESP.box.outline_color = c end)
	bindToggle(VisPlayer, "ESPBoxGrad", "Gradient", false, function(v) ESP.box.gradient = v end)
	bindColor(VisPlayer, "ESPBoxCol", "Color", ESP.box.color, function(c) ESP.box.color = c end)
	bindColor(VisPlayer, "ESPBoxCol2", "Color 2", ESP.box.color2, function(c) ESP.box.color2 = c end)
	bindToggle(VisPlayer, "ESPBoxFill", "Fill", false, function(v) ESP.box.fill = v end)
	bindColor(VisPlayer, "ESPBoxFillCol", "Fill Color", ESP.box.fill_color, function(col) ESP.box.fill_color = col end)
	bindSlider(VisPlayer, "ESPBoxFillTrans", "Fill Transparency", 0.55, 0, 1, 2, function(v) ESP.box.fill_transparency = v end)

	pcall(function() VisPlayer:AddDivider() end)
	pcall(function() VisPlayer:AddSection("Skeleton", ico("user")) end)
	bindToggle(VisPlayer, "ESPSkeleton", "Enabled", false, function(v) ESP.skeleton.enabled = v end)
	pcall(function() VisPlayer:AddLineText("Configure Skeleton") end)
	bindSlider(VisPlayer, "ESPSkelThick", "Thickness", 1.5, 1, 6, 1, function(v) ESP.skeleton.thickness = v end, "px")
	bindToggle(VisPlayer, "ESPSkelGrad", "Gradient", false, function(v) ESP.skeleton.gradient = v end)
	bindColor(VisPlayer, "ESPSkelCol", "Color", ESP.skeleton.color, function(c) ESP.skeleton.color = c end)
	bindColor(VisPlayer, "ESPSkelCol2", "Color 2", ESP.skeleton.color2, function(c) ESP.skeleton.color2 = c end)
	bindToggle(VisPlayer, "ESPHeadDot", "Head Dot", false, function(v) ESP.skeleton.headdot = v end)
	bindSlider(VisPlayer, "ESPHeadDotSize", "Head Dot Size", 4, 1, 12, 0, function(v) ESP.skeleton.headdot_size = v end, "px")
	bindColor(VisPlayer, "ESPHeadDotCol", "Head Dot Color", ESP.skeleton.headdot_color, function(c) ESP.skeleton.headdot_color = c end)

	pcall(function() VisPlayer:AddDivider() end)
	pcall(function() VisPlayer:AddSection("Chams", ico("sparkles")) end)
	bindToggle(VisPlayer, "ESPChams", "Enabled", false, function(v) ESP.chams.enabled = v end)
	pcall(function() VisPlayer:AddLineText("Configure Chams") end)
	bindColor(VisPlayer, "ESPChamsFill", "Fill", ESP.chams.fill_color, function(c) ESP.chams.fill_color = c end)
	bindColor(VisPlayer, "ESPChamsOl", "Outline", ESP.chams.outline_color, function(c) ESP.chams.outline_color = c end)
	bindSlider(VisPlayer, "ESPChamsTrans", "Fill Transparency", 0.5, 0, 1, 2, function(v) ESP.chams.fill_transparency = v end)
	bindSlider(VisPlayer, "ESPChamsOlTrans", "Outline Transparency", 0, 0, 1, 2, function(v) ESP.chams.outline_transparency = v end)
	bindToggle(VisPlayer, "ESPChamsVisibleOnly", "Visible Only", false, function(v) ESP.chams.visible_only = v end)

	pcall(function() VisPlayer:AddDivider() end)
	pcall(function() VisPlayer:AddSection("Healthbar", ico("heart")) end)
	bindToggle(VisPlayer, "ESPHealth", "Enabled", false, function(v) ESP.health.enabled = v end)
	pcall(function() VisPlayer:AddLineText("Configure Health") end)
	bindSlider(VisPlayer, "ESPHpWidth", "Bar Width", 2, 1, 12, 0, function(v) ESP.health.width = v end, "px")
	bindToggle(VisPlayer, "ESPHpText", "HP Text", true, function(v) ESP.health.text = v end)
	bindColor(VisPlayer, "ESPHpHigh", "High", ESP.health.color_high, function(c) ESP.health.color_high = c end)
	bindColor(VisPlayer, "ESPHpMid", "Mid", ESP.health.color_mid, function(c) ESP.health.color_mid = c end)
	bindColor(VisPlayer, "ESPHpLow", "Low", ESP.health.color_low, function(c) ESP.health.color_low = c end)

	pcall(function() VisPlayer:AddDivider() end)
	pcall(function() VisPlayer:AddSection("Tracers", ico("crosshair")) end)
	bindToggle(VisPlayer, "ESPTracers", "Enabled", false, function(v) ESP.tracer.enabled = v end)
	pcall(function() VisPlayer:AddLineText("Configure Tracers") end)
	bindDropdown(VisPlayer, "ESPTracerOrigin", "Origin", { "Bottom", "Top", "Center", "Mouse" }, "Bottom", function(v) ESP.tracer.origin = v end)
	bindSlider(VisPlayer, "ESPTracerThick", "Thickness", 1, 1, 6, 0, function(v) ESP.tracer.thickness = v end, "px")
	bindToggle(VisPlayer, "ESPTracerOutline", "Outline", true, function(v) ESP.tracer.outline = v end)
	bindColor(VisPlayer, "ESPTracerCol", "Color", ESP.tracer.color, function(c) ESP.tracer.color = c end)
	bindColor(VisPlayer, "ESPTracerOlCol", "Outline Color", ESP.tracer.outline_color, function(c) ESP.tracer.outline_color = c end)

	pcall(function() VisPlayer:AddDivider() end)
	pcall(function() VisPlayer:AddSection("Flags", ico("list")) end)
	bindToggle(VisPlayer, "ESPName", "Username", false, function(v) ESP.flags.username = v end)
	bindColor(VisPlayer, "ESPNameCol", "Username Color", ESP.flags.username_color, function(c) ESP.flags.username_color = c end)
	pcall(function() VisPlayer:AddLineText("Distance") end)
	bindToggle(VisPlayer, "ESPDistance", "Distance", false, function(v) ESP.flags.distance = v end)
	bindColor(VisPlayer, "ESPDistCol", "Distance Color", ESP.flags.distance_color, function(c) ESP.flags.distance_color = c end)
	pcall(function() VisPlayer:AddLineText("Weapon") end)
	bindToggle(VisPlayer, "ESPWeapon", "Weapon", false, function(v) ESP.flags.weapon = v end)
	bindColor(VisPlayer, "ESPWepCol", "Weapon Color", ESP.flags.weapon_color, function(c) ESP.flags.weapon_color = c end)

	pcall(function() VisExtra:AddSection("Extra", ico("package")) end)
	pcall(function() VisExtra:AddLabel("Nothing here yet") end)
end)()


----------------------------------------------------------------
-- COMBAT · RAGE · SILENT AIM (Aetherea / Rivals Gun.StartShooting)
----------------------------------------------------------------
;(function()
	local SA = {
		enabled = false,
		hit_chance = 100,
		manipulation = false,
		show_fov = false,
		fov_radius = 100,
		fov_color = Color3.fromRGB(255, 255, 255),
		wallcheck = true,
		max_distance = 500,
		weight_ratio = 0.7,
		hitbox = "Closest Part", -- Head | UpperTorso | Closest Part
		target_part = nil,
		target_player = nil,
	}
	getgenv().VantaRivalsSilent = SA

	local function loadCombatModules()
		pcall(function()
			local mods = ReplicatedStorage:FindFirstChild("Modules")
			if mods then
				if not modules.Utility then
					modules.Utility = tryRequire(function() return require(mods:WaitForChild("Utility", 5)) end)
				end
			end
			local ps = LP:FindFirstChild("PlayerScripts")
			if not ps then return end
			local itemTypes = ps:FindFirstChild("Modules") and ps.Modules:FindFirstChild("ItemTypes")
			if itemTypes then
				if not modules.Gun then
					modules.Gun = tryRequire(function() return require(itemTypes:WaitForChild("Gun", 5)) end)
				end
				if not modules.Melee then
					modules.Melee = tryRequire(function() return require(itemTypes:WaitForChild("Melee", 5)) end)
				end
			end
			local controllers = ps:FindFirstChild("Controllers")
			if controllers and not modules.FighterController then
				modules.FighterController = tryRequire(function()
					return require(controllers:WaitForChild("FighterController", 5))
				end)
			end
		end)
	end
	loadCombatModules()
	task.spawn(function()
		for _ = 1, 15 do
			loadCombatModules()
			if modules.Gun and modules.Utility then break end
			task.wait(1)
		end
	end)

	local shot_offset_cf = CFrame.new(0.43, 0.25, 0.42)
	pcall(function()
		if modules.Utility and modules.Utility.EncodeCFrame then
			shot_offset_cf = modules.Utility:EncodeCFrame(CFrame.new(0.43, 0.25, 0.42))
		end
	end)
	local shot_key_0 = utf8.char(0)
	local shot_key_1 = utf8.char(1)
	local shot_key_2 = utf8.char(2)
	local shot_key_3 = utf8.char(3)

	local function encodeCF(cf)
		if modules.Utility and modules.Utility.EncodeCFrame then
			local ok, enc = pcall(function() return modules.Utility:EncodeCFrame(cf) end)
			if ok and enc then return enc end
		end
		return cf
	end

	local function BuildShotPayload(origin, target, part)
		local aim_cf = encodeCF(CFrame.new(origin, target))
		return {
			[shot_key_0] = aim_cf,
			[shot_key_1] = aim_cf,
			[shot_key_2] = part,
			[shot_key_3] = shot_offset_cf,
		}
	end

	-- FOV circle (Drawing)
	local fovCircle
	pcall(function()
		fovCircle = Drawing.new("Circle")
		fovCircle.Visible = false
		fovCircle.Thickness = 1
		fovCircle.NumSides = 32
		fovCircle.Filled = false
		fovCircle.Transparency = 1
		fovCircle.ZIndex = 10
		fovCircle.Color = SA.fov_color
	end)

	local raycast_params = RaycastParams.new()
	raycast_params.FilterType = Enum.RaycastFilterType.Exclude
	raycast_params.FilterDescendantsInstances = { LP.Character }
	LP.CharacterAdded:Connect(function(char)
		raycast_params.FilterDescendantsInstances = { char }
	end)

	local wallcheck_cache = {}
	local wallcheck_cache_ttl = 0.15

	local function WallCheck(character, part)
		if not SA.wallcheck then return true end
		if not part then return false end
		local char_cache = wallcheck_cache[character]
		if not char_cache then
			char_cache = {}
			wallcheck_cache[character] = char_cache
		end
		local now = os.clock()
		local cached = char_cache[part]
		if cached and (now - cached.time) < wallcheck_cache_ttl then
			return cached.value
		end
		local cam = workspace.CurrentCamera
		if not cam then return false end
		local origin = cam.CFrame.Position
		local result = workspace:Raycast(origin, part.Position - origin, raycast_params)
		local passed = not result or result.Instance:IsDescendantOf(character)
		char_cache[part] = { time = now, value = passed }
		return passed
	end

	local BODY_PARTS = {
		"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
		"LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
		"LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
		"Torso", "Left Arm", "Right Arm", "Left Leg", "Right Leg",
	}

	local function partsForMode()
		if SA.hitbox == "Head" then
			return { "Head" }
		elseif SA.hitbox == "UpperTorso" then
			return { "UpperTorso", "Torso" }
		end
		return BODY_PARTS -- Closest Part
	end

	local function isEnemy(plr)
		if not plr then return true end
		local our = LP:GetAttribute("TeamID")
		local their = plr:GetAttribute("TeamID")
		if our ~= nil and their ~= nil and their == our then return false end
		if plr.Team and LP.Team and plr.Team == LP.Team then return false end
		return true
	end

	local bot_cache, bot_cache_t = {}, 0
	local function getPracticeChars()
		local now = os.clock()
		if now - bot_cache_t < 0.75 then return bot_cache end
		bot_cache_t = now
		local list = {}
		local seen = {}
		local function consider(model)
			if not model or seen[model] or model == LP.Character then return end
			if Players:GetPlayerFromCharacter(model) then return end
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = model:FindFirstChild("HumanoidRootPart")
			if hum and root and hum.Health > 0 then
				seen[model] = true
				list[#list + 1] = model
			end
		end
		local roots = { workspace }
		for _, name in ipairs({ "Bots", "Dummies", "Practice", "Training", "NPCs", "Characters", "Entities" }) do
			local f = workspace:FindFirstChild(name)
			if f then roots[#roots + 1] = f end
		end
		for _, root in ipairs(roots) do
			for _, child in ipairs(root:GetChildren()) do
				if child:IsA("Model") then
					consider(child)
					for _, sub in ipairs(child:GetChildren()) do
						if sub:IsA("Model") then consider(sub) end
					end
				elseif child:IsA("Folder") then
					for _, sub in ipairs(child:GetChildren()) do
						if sub:IsA("Model") then consider(sub) end
					end
				end
			end
		end
		bot_cache = list
		return list
	end

	local function scoreCharacter(character, origin, center, radius_sq, want)
		local closest_part, closest = nil, math.huge
		local cam = workspace.CurrentCamera
		if not cam then return nil, math.huge end
		for _, name in ipairs(want) do
			local part = character:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				local world_dist = (part.Position - origin).Magnitude
				if world_dist <= SA.max_distance then
					local screen, visible = cam:WorldToViewportPoint(part.Position)
					if visible and screen.Z > 0 then
						local dx = screen.X - center.X
						local dy = screen.Y - center.Y
						local screen_dist = dx * dx + dy * dy
						if screen_dist <= radius_sq then
							local score = (screen_dist * SA.weight_ratio) + (world_dist * (1 - SA.weight_ratio))
							if score < closest then
								closest = score
								closest_part = part
							end
						end
					end
				end
			end
		end
		return closest_part, closest
	end

	local function FindBestTarget()
		local cam = workspace.CurrentCamera
		if not cam then return nil, nil end
		local origin = cam.CFrame.Position
		local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
		local radius_sq = SA.fov_radius * SA.fov_radius
		local want = partsForMode()
		local best_part, best_player, best_score = nil, nil, math.huge

		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LP and isEnemy(player) and not isWhitelisted(player) then
				local character = player.Character
				if character then
					local root = character:FindFirstChild("HumanoidRootPart")
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if root and humanoid and humanoid.Health > 0 then
						local closest_part, closest
						if isPrioritized(player) then
							-- Priority: ignore FOV; prefer this target even if "behind" another in FOV
							for _, name in ipairs(want) do
								local p = character:FindFirstChild(name)
								if p and p:IsA("BasePart") then
									local d = (p.Position - origin).Magnitude
									if d <= SA.max_distance and (not closest or d < closest) then
										closest = d * 0.0001
										closest_part = p
									end
								end
							end
							if not closest_part then
								closest_part = root
								closest = (root.Position - origin).Magnitude * 0.0001
							end
						else
							closest_part, closest = scoreCharacter(character, origin, center, radius_sq, want)
						end
						if closest_part and closest < best_score and WallCheck(character, closest_part) then
							best_score = closest
							best_player = player
							best_part = closest_part
						end
					end
				end
			end
		end

		for _, character in ipairs(getPracticeChars()) do
			local closest_part, closest = scoreCharacter(character, origin, center, radius_sq, want)
			-- practice bots: skip wallcheck (range props block rays)
			if closest_part and closest < best_score then
				best_score = closest
				best_player = nil
				best_part = closest_part
			end
		end

		return best_player, best_part
	end

	-- Manipulation offsets (Aetherea)
	local candidates = {
		Vector3.new(5, 3, 5), Vector3.new(-5, 3, 5),
		Vector3.new(5, 3, -5), Vector3.new(-5, 3, -5),
		Vector3.new(0, 5, 8), Vector3.new(0, 5, -8),
	}
	local overlap_params = OverlapParams.new()
	overlap_params.FilterType = Enum.RaycastFilterType.Exclude
	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	local valid_position_cache = {}
	local valid_position_cache_ttl = 0.5

	local function FindValidPosition(target)
		local char = LP.Character
		overlap_params.FilterDescendantsInstances = { char }
		ray_params.FilterDescendantsInstances = { char }
		local target_pos = target.Position
		local target_model = target.Parent
		for i = 1, #candidates do
			local offset = candidates[i]
			local pos = target_pos + offset
			local result = workspace:Raycast(pos, target_pos - pos, ray_params)
			if not result or result.Instance:IsDescendantOf(target_model) then
				local parts = workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(3, 6, 3), overlap_params)
				local blocked = false
				for j = 1, #parts do
					if parts[j].CanCollide then blocked = true; break end
				end
				if not blocked then return offset end
			end
		end
		return nil
	end

	local function GetCachedValidPosition(target)
		if not target or not target.Parent then return nil end
		local now = os.clock()
		local entry = valid_position_cache[target]
		if entry and now - entry.time < valid_position_cache_ttl then
			return entry.value
		end
		local value = FindValidPosition(target)
		valid_position_cache[target] = { value = value, time = now }
		return value
	end

	-- Target + FOV loop
	local next_search = 0
	-- Silent Aim only (triggerbot has its own crosshair raycast)
	RunService.RenderStepped:Connect(function()
		if not SA.enabled and not SA.show_fov then
			if SA.target_part then
				SA.target_part = nil
				SA.target_player = nil
			end
			if fovCircle then fovCircle.Visible = false end
			return
		end

		local cam = workspace.CurrentCamera
		if not cam then return end
		local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)

		if fovCircle then
			if SA.show_fov then
				fovCircle.Position = center
				fovCircle.Radius = SA.fov_radius
				fovCircle.Color = SA.fov_color
				fovCircle.Visible = true
			else
				fovCircle.Visible = false
			end
		end

		if not SA.enabled then
			SA.target_part = nil
			SA.target_player = nil
			return
		end

		local now = os.clock()
		if now < next_search then return end
		next_search = now + 0.03

		local plr, part = FindBestTarget()
		SA.target_player = plr
		SA.target_part = part
	end)

	-- Gun.StartShooting hook (core Aetherea silent)
	local gun_hooked = false
	local function tryHookGun()
		if gun_hooked then return end
		loadCombatModules()
		if not modules.Gun or not modules.Gun.StartShooting then return end
		gun_hooked = true
		local old_gun = modules.Gun.StartShooting
		modules.Gun.StartShooting = function(self, ...)
			local part = SA.target_part
			if not SA.enabled or not part or not self.ClientFighter or not self.ClientFighter.IsLocalPlayer then
				return old_gun(self, ...)
			end

			local results = { old_gun(self, ...) }
			if results[1] ~= true or results[2] ~= "StartShooting" then
				return unpack(results)
			end

			if math.random(1, 100) > SA.hit_chance then
				return unpack(results)
			end

			local root = LP.Character and LP.Character.PrimaryPart
			if not root then
				return unpack(results)
			end

			local origin = root.Position
			local target = part.Position

			if SA.manipulation then
				local offset = GetCachedValidPosition(part)
				if offset then
					origin = (part.CFrame * CFrame.new(offset)).Position
				end
			end

			results[3] = BuildShotPayload(origin, target, part)
			return unpack(results)
		end
	end

	task.spawn(function()
		for _ = 1, 30 do
			tryHookGun()
			if gun_hooked then break end
			task.wait(1)
		end
	end)

	-- UI · Rage tab
	pcall(function() CombatRage:AddSection("Silent Aim", ico("crosshair")) end)
	bindToggleKey(CombatRage, "SAEnabled", "Enabled", false, function(v)
		SA.enabled = v
		if v then tryHookGun() end
	end, true) -- Risky: red label
	pcall(function() CombatRage:AddLineText("Configure Silent Aim") end)
	bindToggle(CombatRage, "SAShowFOV", "Show FOV", false, function(v) SA.show_fov = v end)
	bindSlider(CombatRage, "SAFOV", "FOV Size", 100, 10, 800, 0, function(v) SA.fov_radius = v end, "px")
	bindColor(CombatRage, "SAFOVColor", "FOV Color", SA.fov_color, function(c) SA.fov_color = c end)
	bindDropdown(CombatRage, "SAHitbox", "Hit Part", { "Closest Part", "Head", "UpperTorso" }, "Closest Part", function(v)
		SA.hitbox = v
	end)
	bindSlider(CombatRage, "SAHitChance", "Hit Chance", 100, 0, 100, 0, function(v) SA.hit_chance = v end, "%")
	bindSlider(CombatRage, "SAMaxDist", "Max Distance", 500, 50, 2000, 0, function(v) SA.max_distance = v end, "m")
	bindToggle(CombatRage, "SAWallcheck", "Wallcheck", true, function(v) SA.wallcheck = v end)
	bindToggle(CombatRage, "SAManip", "Manipulation", false, function(v) SA.manipulation = v end)
end)()

----------------------------------------------------------------
-- COMBAT · LEGIT · AIMBOT / AIM ASSIST
----------------------------------------------------------------
;(function()
	local UIS = game:GetService("UserInputService")

	local SMOOTH_MODES = {
		"None", "Linear", "Exponential", "Dynamic",
		"SinEase", "SpringDamp", "Predictive", "Bezier",
	}

	local HITBOX_PARTS_AA = {
		Head             = { "Head" },
		UpperTorso       = { "UpperTorso", "Torso" },
		["Closest Part"] = {
			"Head","UpperTorso","LowerTorso","HumanoidRootPart",
			"LeftUpperArm","RightUpperArm","LeftLowerArm","RightLowerArm",
			"LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg",
			"Torso","Left Arm","Right Arm","Left Leg","Right Leg",
		},
	}

	local AA = {
		enabled        = false,
		hold_mode      = "Hold",
		hold_key       = Enum.KeyCode.C,
		hold_mouse     = nil,
		toggled        = false,

		fov_radius     = 120,
		show_fov       = false,
		fov_color      = Color3.fromRGB(255, 255, 255),
		max_distance   = 600,
		wallcheck      = true,
		teammates      = false,
		hitbox         = "Head",

		smooth_mode    = "Exponential",
		smooth_factor  = 0.10,
		linear_speed   = 8,
		spring_stiff   = 12,
		spring_damp    = 0.70,

		predict_scale  = 0.10,

		randomise      = false,
		rand_radius    = 0.05,
		bone_offset    = Vector3.new(0, 0, 0),

		_spring_vel    = Vector3.new(0,0,0),
		_spring_pos    = nil,
		_prev_target   = nil,
		_prev_target_t = 0,

		-- written by background thread, read by RenderStepped — no heavy work on render
		target_player  = nil,
		target_part    = nil,
	}
	getgenv().VantaRivalsAimbot = AA

	-- ===== raycast params =====
	local aa_rayparams = RaycastParams.new()
	aa_rayparams.FilterType = Enum.RaycastFilterType.Exclude
	aa_rayparams.FilterDescendantsInstances = { LP.Character }
	LP.CharacterAdded:Connect(function(c)
		aa_rayparams.FilterDescendantsInstances = { c }
	end)

	-- ===== bot cache — rebuilt every 3 seconds on Heartbeat, not every frame =====
	-- GetDescendants on a live workspace every 33ms was the FPS killer.
	-- Now we snapshot once and reuse the list. DescendantAdded keeps it warm.
	local aa_bot_cache    = {}   -- array of {hum, parts={name->BasePart}} for non-player models
	local aa_bot_dirty    = true
	local aa_bot_rebuild  = 0   -- next rebuild timestamp

	local function rebuildBotCache()
		local newCache = {}
		local seen     = {}
		local function considerModel(m)
			if not m or seen[m] then return end
			seen[m] = true
			if m == LP.Character then return end
			if Players:GetPlayerFromCharacter(m) then return end
			local hum = m:FindFirstChildOfClass("Humanoid")
			if not hum then return end
			local entry = { hum = hum, model = m, parts = {} }
			for _, child in ipairs(m:GetChildren()) do
				if child:IsA("BasePart") then
					entry.parts[child.Name] = child
				end
			end
			if next(entry.parts) then
				newCache[#newCache + 1] = entry
			end
		end
		-- only check direct children of workspace and known container folders
		for _, child in ipairs(workspace:GetChildren()) do
			if child:IsA("Model") then
				considerModel(child)
			elseif child:IsA("Folder") then
				for _, sub in ipairs(child:GetChildren()) do
					if sub:IsA("Model") then considerModel(sub) end
				end
			end
		end
		aa_bot_cache = newCache
		aa_bot_dirty = false
	end

	-- mark dirty when anything is added to workspace (cheap, no scan)
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Model") and not Players:GetPlayerFromCharacter(d) then
			aa_bot_dirty = true
		end
	end)
	workspace.DescendantRemoving:Connect(function(d)
		if d:IsA("Model") then aa_bot_dirty = true end
	end)

	-- ===== player part cache — avoids FindFirstChildOfClass every search tick =====
	-- Keyed by Player, holds a table of {hum, parts={name->BasePart}} for the current char.
	-- Rebuilt only on CharacterAdded. Dirt-cheap to iterate.
	local aa_plr_cache = {}  -- [Player] = { hum=Humanoid, parts={name->BasePart} }

	local function cacheCharacter(plr, char)
		if not char then aa_plr_cache[plr] = nil; return end
		local entry = { parts = {} }
		-- wait a tick so the character is fully replicated before we read it
		task.defer(function()
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum then aa_plr_cache[plr] = nil; return end
			entry.hum = hum
			for _, child in ipairs(char:GetChildren()) do
				if child:IsA("BasePart") then
					entry.parts[child.Name] = child
				end
			end
			aa_plr_cache[plr] = entry
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LP and plr.Character then
			cacheCharacter(plr, plr.Character)
		end
		plr.CharacterAdded:Connect(function(char)
			aa_plr_cache[plr] = nil
			cacheCharacter(plr, char)
		end)
		plr.CharacterRemoving:Connect(function()
			aa_plr_cache[plr] = nil
		end)
	end
	Players.PlayerAdded:Connect(function(plr)
		plr.CharacterAdded:Connect(function(char)
			aa_plr_cache[plr] = nil
			cacheCharacter(plr, char)
		end)
		plr.CharacterRemoving:Connect(function()
			aa_plr_cache[plr] = nil
		end)
	end)
	Players.PlayerRemoving:Connect(function(plr)
		aa_plr_cache[plr] = nil
	end)

	-- ===== helpers =====
	local function isEnemyAA(plr)
		if AA.teammates then return true end
		local our   = LP:GetAttribute("TeamID")
		local their = plr:GetAttribute("TeamID")
		if our ~= nil and their ~= nil then return their ~= our end
		if plr.Team and LP.Team then return plr.Team ~= LP.Team end
		return true
	end

	local function wallOkAA(partPos, model)
		if not AA.wallcheck then return true end
		local cam = workspace.CurrentCamera
		if not cam then return false end
		local origin = cam.CFrame.Position
		local result = workspace:Raycast(origin, partPos - origin, aa_rayparams)
		return not result or result.Instance:IsDescendantOf(model)
	end

	local function screenDist2AA(partPos, cam, cx, cy)
		local sp, on = cam:WorldToViewportPoint(partPos)
		if not on or sp.Z <= 0 then return math.huge end
		local dx = sp.X - cx
		local dy = sp.Y - cy
		return dx*dx + dy*dy
	end

	-- ===== target search — runs on Heartbeat (background), never on RenderStepped =====
	local function findTargetAA()
		local cam = workspace.CurrentCamera
		if not cam then return nil, nil end
		local origin = cam.CFrame.Position
		local vs     = cam.ViewportSize
		local cx, cy = vs.X*0.5, vs.Y*0.5
		local rsq    = AA.fov_radius * AA.fov_radius
		local maxd   = AA.max_distance
		local want   = HITBOX_PARTS_AA[AA.hitbox] or HITBOX_PARTS_AA["Head"]
		local best_p, best_plr, best_sd = nil, nil, math.huge

		-- real players — uses cached parts table, no FindFirstChild in hot path
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LP then continue end
			if not isEnemyAA(plr) then continue end
			local entry = aa_plr_cache[plr]
			if not entry or not entry.hum or entry.hum.Health <= 0 then continue end
			local partsMap = entry.parts
			for _, name in ipairs(want) do
				local part = partsMap[name]
				if not part or not part.Parent then continue end
				local pos = part.Position
				if (pos - origin).Magnitude > maxd then continue end
				local sd = screenDist2AA(pos, cam, cx, cy)
				if sd < rsq and sd < best_sd and wallOkAA(pos, part.Parent) then
					best_sd  = sd
					best_p   = part
					best_plr = plr
				end
			end
		end

		-- practice bots — uses the pre-built shallow cache, never GetDescendants
		local now = tick()
		if aa_bot_dirty or now >= aa_bot_rebuild then
			rebuildBotCache()
			aa_bot_rebuild = now + 3  -- full rebuild at most every 3 seconds
		end
		for _, entry in ipairs(aa_bot_cache) do
			if not entry.hum or not entry.hum.Parent or entry.hum.Health <= 0 then continue end
			local partsMap = entry.parts
			for _, name in ipairs(want) do
				local part = partsMap[name]
				if not part or not part.Parent then continue end
				local pos = part.Position
				if (pos - origin).Magnitude > maxd then continue end
				local sd = screenDist2AA(pos, cam, cx, cy)
				if sd < rsq and sd < best_sd then
					best_sd  = sd
					best_p   = part
					best_plr = nil
				end
			end
		end

		return best_plr, best_p
	end

	-- ===== hold detection =====
	local function isHoldDownAA()
		if AA.hold_mode == "Always" then return true end
		if AA.hold_mode == "Toggle" then return AA.toggled end
		if AA.hold_mouse then
			local ok, v = pcall(UIS.IsMouseButtonPressed, UIS, AA.hold_mouse)
			return ok and v
		end
		if AA.hold_key then
			local ok, v = pcall(UIS.IsKeyDown, UIS, AA.hold_key)
			return ok and v
		end
		return false
	end

	UIS.InputBegan:Connect(function(input, gpe)
		if gpe or not AA.enabled then return end
		if AA.hold_mode ~= "Toggle" then return end
		local kc = input.KeyCode
		local mt = input.UserInputType
		if (kc ~= Enum.KeyCode.Unknown and kc == AA.hold_key)
		or (mt ~= Enum.UserInputType.None and mt == AA.hold_mouse) then
			AA.toggled = not AA.toggled
		end
	end)

	-- ===== FOV circle =====
	local aaFovCircle
	pcall(function()
		aaFovCircle = Drawing.new("Circle")
		aaFovCircle.Visible      = false
		aaFovCircle.Thickness    = 1
		aaFovCircle.NumSides     = 32
		aaFovCircle.Filled       = false
		aaFovCircle.Transparency = 1
		aaFovCircle.ZIndex       = 10
		aaFovCircle.Color        = AA.fov_color
	end)

	-- ===== continuous acquire + aim (open-source style lock) =====
	-- Pattern from public Rivals / universal aimbots:
	-- WorldToViewportPoint → mouse delta → mousemoverel(dx/smooth, dy/smooth) every frame.
	-- Sticky lock while target stays valid + in FOV; re-pick when lost.

	local UIS_AA = game:GetService("UserInputService")
	local locked_plr = nil
	local locked_part = nil

	local function getAimPart(character)
		if not character then return nil end
		local want = HITBOX_PARTS_AA[AA.hitbox] or HITBOX_PARTS_AA["Head"]
		for _, name in ipairs(want) do
			local p = character:FindFirstChild(name)
			if p and p:IsA("BasePart") then return p end
		end
		return character:FindFirstChild("Head")
			or character:FindFirstChild("HumanoidRootPart")
			or character:FindFirstChild("UpperTorso")
			or character:FindFirstChild("Torso")
	end

	local function isTargetStillValid(plr, part)
		if not plr or not plr.Parent then return false end
		if isWhitelisted(plr) then return false end
		local char = plr.Character
		if not char or not char.Parent then return false end
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return false end
		if not part or not part.Parent or not part:IsDescendantOf(char) then return false end
		if not isEnemyAA(plr) then return false end
		local cam = workspace.CurrentCamera
		if not cam then return false end
		local sp, on = cam:WorldToViewportPoint(part.Position)
		if not on or sp.Z <= 0 then return false end
		local vs = cam.ViewportSize
		local cx, cy = vs.X * 0.5, vs.Y * 0.5
		local dx, dy = sp.X - cx, sp.Y - cy
		if (dx * dx + dy * dy) > (AA.fov_radius * AA.fov_radius) then return false end
		if AA.wallcheck and not wallOkAA(part.Position, char) then return false end
		local origin = cam.CFrame.Position
		if (part.Position - origin).Magnitude > AA.max_distance then return false end
		return true
	end

	local function pickClosest()
		local cam = workspace.CurrentCamera
		if not cam then return nil, nil end
		local origin = cam.CFrame.Position
		local vs = cam.ViewportSize
		local cx, cy = vs.X * 0.5, vs.Y * 0.5
		local rsq = AA.fov_radius * AA.fov_radius
		local best_plr, best_part, best_sd = nil, nil, math.huge

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LP then continue end
			if not isEnemyAA(plr) then continue end
			if isWhitelisted(plr) then continue end
			local char = plr.Character
			if not char then continue end
			local hum = char:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then continue end
			local part = getAimPart(char)
			if not part then continue end
			local dist = (part.Position - origin).Magnitude
			if dist > AA.max_distance then continue end
			local sp, on = cam:WorldToViewportPoint(part.Position)
			if not on or sp.Z <= 0 then continue end
			local dx, dy = sp.X - cx, sp.Y - cy
			local sd = dx * dx + dy * dy
			local prio = isPrioritized(plr)
			if not prio and sd > rsq then continue end
			if AA.wallcheck and not wallOkAA(part.Position, char) then continue end
			-- priority beats everyone else in range
			if prio then sd = dist * 0.0001 end
			if sd < best_sd then
				best_sd = sd
				best_plr = plr
				best_part = part
			end
		end

		-- practice bots
		local now = tick()
		if aa_bot_dirty or now >= aa_bot_rebuild then
			rebuildBotCache()
			aa_bot_rebuild = now + 3
		end
		for _, entry in ipairs(aa_bot_cache) do
			if not entry.hum or not entry.hum.Parent or entry.hum.Health <= 0 then continue end
			local part = getAimPart(entry.model)
			if not part then continue end
			if (part.Position - origin).Magnitude > AA.max_distance then continue end
			local sp, on = cam:WorldToViewportPoint(part.Position)
			if not on or sp.Z <= 0 then continue end
			local dx, dy = sp.X - cx, sp.Y - cy
			local sd = dx * dx + dy * dy
			if sd > rsq then continue end
			if sd < best_sd then
				best_sd = sd
				best_plr = nil
				best_part = part
			end
		end

		return best_plr, best_part
	end

	local function applyMove(part)
		local cam = workspace.CurrentCamera
		if not cam or not part then return end

		local aimPos = part.Position
		if AA.bone_offset then
			aimPos = aimPos + AA.bone_offset
		end
		if AA.randomise then
			local r = AA.rand_radius
			aimPos = aimPos + Vector3.new(
				(math.random(-1000, 1000) / 1000) * r,
				(math.random(-1000, 1000) / 1000) * r,
				(math.random(-1000, 1000) / 1000) * r
			)
		end
		if AA.smooth_mode == "Predictive" and AA.predict_scale > 0 then
			local now = tick()
			if AA._prev_target and (now - AA._prev_target_t) > 0 then
				local vel = (aimPos - AA._prev_target) / (now - AA._prev_target_t)
				aimPos = aimPos + vel * AA.predict_scale
			end
			AA._prev_target = part.Position
			AA._prev_target_t = now
		end

		local sp, onScreen = cam:WorldToViewportPoint(aimPos)
		if not onScreen or sp.Z <= 0 then return end

		local mouse = UIS_AA:GetMouseLocation()
		local dx = sp.X - mouse.X
		local dy = sp.Y - mouse.Y

		-- open-source smooth: divide pixel delta (1 = snap, higher = slower)
		-- map AA.smooth_factor [0..1] → divisor [1..12]
		local smooth = 1 + (AA.smooth_factor * 11)
		if AA.smooth_mode == "None" then
			smooth = 1
		elseif AA.smooth_mode == "Linear" then
			smooth = math.max(1, 12 - (AA.linear_speed / 10))
		end

		local mx = dx / smooth
		local my = dy / smooth
		-- never overshoot remaining distance
		if math.abs(mx) > math.abs(dx) then mx = dx end
		if math.abs(my) > math.abs(dy) then my = dy end

		if math.abs(mx) < 0.2 and math.abs(my) < 0.2 then return end
		if type(mousemoverel) == "function" then
			mousemoverel(mx, my)
		end
	end

	RunService.RenderStepped:Connect(function()
		if aaFovCircle then
			if AA.show_fov and AA.enabled then
				local cam = workspace.CurrentCamera
				if cam then
					aaFovCircle.Position = cam.ViewportSize * 0.5
					aaFovCircle.Radius = AA.fov_radius
					aaFovCircle.Color = AA.fov_color
					aaFovCircle.Visible = true
				end
			else
				aaFovCircle.Visible = false
			end
		end

		if not AA.enabled or not isHoldDownAA() then
			locked_plr = nil
			locked_part = nil
			AA.target_part = nil
			AA.target_player = nil
			AA._prev_target = nil
			return
		end

		-- sticky: keep same target while valid, else re-pick
		if locked_part and locked_plr then
			if not isTargetStillValid(locked_plr, locked_part) then
				locked_plr = nil
				locked_part = nil
			else
				-- refresh part in case hitbox preference changed
				local refreshed = getAimPart(locked_plr.Character)
				if refreshed then locked_part = refreshed end
			end
		elseif locked_part and not locked_plr then
			-- bot: just check part alive
			if not locked_part.Parent then
				locked_part = nil
			end
		end

		if not locked_part then
			local plr, part = pickClosest()
			locked_plr = plr
			locked_part = part
		end

		AA.target_player = locked_plr
		AA.target_part = locked_part

		if locked_part then
			applyMove(locked_part)
		end
	end)

	-- ===== UI =====
	local KEY_MAP_AA = {
		["C"]         = Enum.KeyCode.C,
		["V"]         = Enum.KeyCode.V,
		["Q"]         = Enum.KeyCode.Q,
		["E"]         = Enum.KeyCode.E,
		["F"]         = Enum.KeyCode.F,
		["R"]         = Enum.KeyCode.R,
		["T"]         = Enum.KeyCode.T,
		["X"]         = Enum.KeyCode.X,
		["Z"]         = Enum.KeyCode.Z,
		["Left Alt"]  = Enum.KeyCode.LeftAlt,
		["Left Ctrl"] = Enum.KeyCode.LeftControl,
		["CapsLock"]  = Enum.KeyCode.CapsLock,
	}

	pcall(function() CombatLegit:AddSection("Aim Assist", ico("crosshair")) end)

	bindToggle(CombatLegit, "AAEnabled", "Enabled", false, function(v)
		AA.enabled = v
		if not v then
			AA.toggled     = false
			AA._spring_pos = nil
			AA._spring_vel = Vector3.zero
			_aa_lerped_pos = nil
		end
	end)

	bindDropdown(CombatLegit, "AAHoldMode", "Activation", { "Hold", "Toggle", "Always" }, "Hold", function(v)
		AA.hold_mode = v
		AA.toggled   = false
	end)

	bindDropdown(CombatLegit, "AAHoldKey", "Activation Key", {
		"C","V","Q","E","F","R","T","X","Z",
		"Left Alt","Left Ctrl","CapsLock",
		"Right Mouse","Middle Mouse",
	}, "C", function(v)
		AA.hold_mouse = nil
		AA.hold_key   = nil
		if v == "Right Mouse" then
			AA.hold_mouse = Enum.UserInputType.MouseButton2
		elseif v == "Middle Mouse" then
			AA.hold_mouse = Enum.UserInputType.MouseButton3
		else
			AA.hold_key = KEY_MAP_AA[v] or Enum.KeyCode.C
		end
	end)

	pcall(function() CombatLegit:AddLineText("Configure Aimbot") end)

	pcall(function() CombatLegit:AddSection("Targeting", ico("crosshair")) end)

	bindDropdown(CombatLegit, "AAHitbox", "Hit Part", { "Head", "UpperTorso", "Closest Part" }, "Head", function(v)
		AA.hitbox = v
	end)

	bindSlider(CombatLegit, "AAFov", "FOV Radius", 120, 10, 900, 0, function(v)
		AA.fov_radius = v
	end, "px")

	bindToggle(CombatLegit, "AAShowFov", "Show FOV", false, function(v)
		AA.show_fov = v
	end)

	bindColor(CombatLegit, "AAFovColor", "FOV Color", AA.fov_color, function(c)
		AA.fov_color = c
		if aaFovCircle then aaFovCircle.Color = c end
	end)

	bindSlider(CombatLegit, "AAMaxDist", "Max Distance", 600, 50, 2000, 0, function(v)
		AA.max_distance = v
	end, "m")

	bindToggle(CombatLegit, "AAWallcheck", "Wallcheck", true, function(v)
		AA.wallcheck = v
	end)

	bindToggle(CombatLegit, "AATeammates", "Include Teammates", false, function(v)
		AA.teammates = v
	end)

	pcall(function() CombatLegit:AddDivider() end)
	pcall(function() CombatLegit:AddSection("Smoothing", ico("gauge")) end)

	bindDropdown(CombatLegit, "AASmoothMode", "Smooth Type", SMOOTH_MODES, "Exponential", function(v)
		AA.smooth_mode = v
		AA._spring_pos = nil
		AA._spring_vel = Vector3.zero
		_aa_lerped_pos = nil
	end)

	bindSlider(CombatLegit, "AASmoothFactor", "Smoothing", 10, 0, 100, 0, function(v)
		AA.smooth_factor = v / 100
	end, "%")

	bindSlider(CombatLegit, "AALinearSpeed", "Speed", 8, 1, 120, 0, function(v)
		AA.linear_speed = v
	end, "°/s")

	pcall(function() CombatLegit:AddLineText("Spring Settings (SpringDamp)") end)

	bindSlider(CombatLegit, "AASpringStiff", "Stiffness", 12, 1, 80, 0, function(v)
		AA.spring_stiff = v
		AA._spring_pos  = nil
		AA._spring_vel  = Vector3.zero
		_aa_lerped_pos  = nil
	end)

	bindSlider(CombatLegit, "AASpringDamp", "Damping", 70, 0, 100, 0, function(v)
		AA.spring_damp = v / 100
		AA._spring_pos = nil
		AA._spring_vel = Vector3.zero
		_aa_lerped_pos = nil
	end, "%")

	pcall(function() CombatLegit:AddDivider() end)
	pcall(function() CombatLegit:AddSection("Humanization", ico("refresh-cw")) end)

	bindToggle(CombatLegit, "AARandomise", "Enabled", false, function(v)
		AA.randomise = v
	end)

	bindSlider(CombatLegit, "AARandRadius", "Humanise Radius", 5, 0, 50, 0, function(v)
		AA.rand_radius = v / 100
	end, "")

	bindSlider(CombatLegit, "AAPredictScale", "Predictive Lead", 10, 0, 100, 0, function(v)
		AA.predict_scale  = v / 100
		AA._prev_target   = nil
		AA._prev_target_t = 0
	end, "%")

end)()

----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
----------------------------------------------------------------
-- COMBAT · LEGIT · TRIGGERBOT (fully separate from Silent Aim)
-- Crosshair-on-target only + always-on wallcheck
----------------------------------------------------------------
;(function()
	local UIS = game:GetService("UserInputService")

	-- divider between aimbot and triggerbot
	pcall(function() CombatLegit:AddDivider() end)

	local TB = {
		enabled = false,
		shoot_delay = 50,
		check_scoped = {},
		active = false,
		hold_mode = "Hold",
		hold_key = Enum.KeyCode.E,
		hold_mouse = nil,
		max_distance = 500,
		-- wallcheck always on (no toggle)
	}
	getgenv().VantaRivalsTriggerbot = TB

	local function setIdentity(n)
		pcall(function() if setthreadidentity then setthreadidentity(n) end end)
		pcall(function() if syn and syn.set_thread_identity then syn.set_thread_identity(n) end end)
	end

	local function loadMechanics()
		pcall(function()
			local ps = LP:FindFirstChild("PlayerScripts")
			if not ps then return end
			local controllers = ps:FindFirstChild("Controllers")
			if not controllers then return end
			if not modules.MechanicsController then
				modules.MechanicsController = tryRequire(function()
					return require(controllers:WaitForChild("MechanicsController", 3))
				end)
			end
			if not modules.FighterController then
				modules.FighterController = tryRequire(function()
					return require(controllers:WaitForChild("FighterController", 3))
				end)
			end
		end)
	end
	loadMechanics()
	task.spawn(function()
		for _ = 1, 25 do
			loadMechanics()
			if modules.MechanicsController then break end
			task.wait(0.5)
		end
	end)

	local function isHoldDown()
		if TB.hold_mode == "Always" then return true end
		if TB.hold_mouse then
			local ok, down = pcall(function() return UIS:IsMouseButtonPressed(TB.hold_mouse) end)
			return ok and down
		end
		if TB.hold_key then
			local ok, down = pcall(function() return UIS:IsKeyDown(TB.hold_key) end)
			return ok and down
		end
		return false
	end

	local ray_params = RaycastParams.new()
	ray_params.FilterType = Enum.RaycastFilterType.Exclude
	ray_params.IgnoreWater = true

	-- only fire when crosshair is ON the enemy (not FOV) — ray + tight screen pixel check
	local CROSSHAIR_PX = 6 -- max pixels from dead center

	local function getCrosshairTarget()
		local cam = workspace.CurrentCamera
		if not cam then return nil end
		local char = LP.Character
		ray_params.FilterDescendantsInstances = char and { char } or {}

		local vs = cam.ViewportSize
		local cx = vs.X * 0.5
		local cy = vs.Y * 0.5
		-- true crosshair: account for topbar inset when present
		pcall(function()
			local inset = game:GetService("GuiService"):GetGuiInset()
			if inset then
				cy = (vs.Y - inset.Y) * 0.5 + inset.Y * 0.5
			end
		end)

		local ray = cam:ViewportPointToRay(cx, cy)
		local result = workspace:Raycast(ray.Origin, ray.Direction * TB.max_distance, ray_params)
		if not result or not result.Instance then return nil end

		local inst = result.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		if not model or model == char then return nil end

		local hum = model:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then return nil end
		local root = model:FindFirstChild("HumanoidRootPart")
		if not root then return nil end

		-- wallcheck: first solid hit must belong to this character
		if not inst:IsDescendantOf(model) then return nil end

		local plr = Players:GetPlayerFromCharacter(model)
		if plr then
			if plr == LP then return nil end
			local our = LP:GetAttribute("TeamID")
			local their = plr:GetAttribute("TeamID")
			if our ~= nil and their ~= nil and their == our then return nil end
			if plr.Team and LP.Team and plr.Team == LP.Team then return nil end
		end

		-- strict: hit position must sit under the crosshair (not "near" in world FOV)
		local hitSp, onScreen = cam:WorldToViewportPoint(result.Position)
		if not onScreen or hitSp.Z <= 0 then return nil end
		local dx = hitSp.X - cx
		local dy = hitSp.Y - cy
		if (dx * dx + dy * dy) > (CROSSHAIR_PX * CROSSHAIR_PX) then
			return nil
		end

		return model, inst, plr
	end

	local function fireShot()
		loadMechanics()
		setIdentity(2)
		local ok = false
		pcall(function()
			if modules.MechanicsController and modules.MechanicsController.EquippedItemInput then
				modules.MechanicsController:EquippedItemInput("StartShooting")
				ok = true
			end
		end)
		if not ok then
			pcall(function()
				if mouse1click then mouse1click(); ok = true end
			end)
			pcall(function()
				if mouse1press then
					mouse1press()
					task.delay(0.05, function() pcall(mouse1release) end)
					ok = true
				end
			end)
		end
		setIdentity(8)
		return ok
	end

	local function stopShot()
		pcall(function()
			setIdentity(2)
			if modules.MechanicsController and modules.MechanicsController.EquippedItemInput then
				modules.MechanicsController:EquippedItemInput("FinishShooting")
			end
			setIdentity(8)
		end)
	end

	local last_shot = 0
	RunService.Heartbeat:Connect(function()
		if not TB.enabled then
			if TB.active then TB.active = false; stopShot() end
			return
		end
		if not isHoldDown() then
			if TB.active then TB.active = false; stopShot() end
			return
		end

		local model, part, plr = getCrosshairTarget()
		if not model then
			if TB.active then TB.active = false; stopShot() end
			return
		end

		loadMechanics()
		local fighter = nil
		pcall(function()
			if modules.FighterController and modules.FighterController.GetFighter then
				fighter = modules.FighterController:GetFighter(LP)
			end
		end)
		local equipped = fighter and fighter.EquippedItem
		if not equipped then return end

		if #TB.check_scoped > 0 then
			local name = tostring(equipped.Name or "")
			local needs = false
			for _, n in ipairs(TB.check_scoped) do
				if n == name then needs = true; break end
			end
			if needs then
				local aiming = false
				pcall(function() aiming = equipped:IsFullyAiming() == true end)
				if not aiming then
					if TB.active then TB.active = false; stopShot() end
					return
				end
			end
		end

		local now = os.clock()
		local delay_s = math.max((TB.shoot_delay or 0) / 1000, 0.02)
		if now - last_shot < delay_s then return end

		last_shot = now
		TB.active = true
		fireShot()
	end)

	local KEY_MAP = {
		["E"] = Enum.KeyCode.E, ["Q"] = Enum.KeyCode.Q, ["F"] = Enum.KeyCode.F,
		["C"] = Enum.KeyCode.C, ["V"] = Enum.KeyCode.V, ["R"] = Enum.KeyCode.R,
		["T"] = Enum.KeyCode.T, ["Left Alt"] = Enum.KeyCode.LeftAlt,
		["Left Ctrl"] = Enum.KeyCode.LeftControl,
	}

	pcall(function() CombatLegit:AddSection("Triggerbot", ico("crosshair")) end)
	bindToggle(CombatLegit, "TBEnabled", "Enabled", false, function(v)
		TB.enabled = v
		if not v then TB.active = false end
	end)
	pcall(function() CombatLegit:AddLineText("Configure Triggerbot") end)
	bindDropdown(CombatLegit, "TBHoldMode", "Activation", { "Hold", "Always" }, "Hold", function(v)
		TB.hold_mode = v
	end)
	bindDropdown(CombatLegit, "TBHoldKey", "Hold Key", {
		"E", "Q", "F", "C", "V", "R", "T", "Left Alt", "Left Ctrl", "Right Mouse", "Left Mouse"
	}, "E", function(v)
		TB.hold_mouse = nil
		TB.hold_key = nil
		if v == "Right Mouse" then
			TB.hold_mouse = Enum.UserInputType.MouseButton2
		elseif v == "Left Mouse" then
			TB.hold_mouse = Enum.UserInputType.MouseButton1
		else
			TB.hold_key = KEY_MAP[v] or Enum.KeyCode.E
		end
	end)
	bindSlider(CombatLegit, "TBDelay", "Shoot Delay", 50, 0, 500, 0, function(v) TB.shoot_delay = v end, "ms")
	bindSlider(CombatLegit, "TBMaxDist", "Max Distance", 500, 50, 2000, 0, function(v) TB.max_distance = v end, "m")
	bindDropdown(CombatLegit, "TBScoped", "Require Scope", { "None", "Sniper", "Crossbow", "Sniper+Crossbow" }, "None", function(v)
		if v == "None" then TB.check_scoped = {}
		elseif v == "Sniper" then TB.check_scoped = { "Sniper" }
		elseif v == "Crossbow" then TB.check_scoped = { "Crossbow" }
		else TB.check_scoped = { "Sniper", "Crossbow" }
		end
	end)
	pcall(function()
		CombatLegit:AddLabel("")
	end)
end)()



----------------------------------------------------------------
-- COMBAT · GUN MODS — Aetherea weapons logic 1:1 + rawset force
----------------------------------------------------------------
;(function()
	local GM = {
		no_recoil = false,
		no_spread = false,
		full_auto = false,
		firerate_boost = 0, -- 0 normal, 100 fastest
		bullet_tracers = false,
		tracer_color = Color3.fromRGB(181, 126, 220),
		tracer_lifetime = 0.45,
		tracer_budget = 16,
	}
	getgenv().VantaRivalsGunMods = GM

	local function loadGunModules()
		pcall(function()
			local ps = LP:FindFirstChild("PlayerScripts")
			if not ps then return end
			local controllers = ps:FindFirstChild("Controllers")
			if controllers then
				if not modules.FighterController then
					local fc = controllers:FindFirstChild("FighterController")
					if fc then
						modules.FighterController = tryRequire(function() return require(fc) end)
					end
				end
			end
			local itemTypes = ps:FindFirstChild("Modules") and ps.Modules:FindFirstChild("ItemTypes")
			if itemTypes and not modules.Gun then
				local g = itemTypes:FindFirstChild("Gun")
				if g then
					modules.Gun = tryRequire(function() return require(g) end)
				end
			end
		end)
	end
	loadGunModules()
	task.spawn(function()
		for _ = 1, 40 do
			loadGunModules()
			if modules.FighterController and modules.Gun then break end
			task.wait(0.4)
		end
	end)

	local unlocked_infos = setmetatable({}, { __mode = "k" })
	local function forceSet(tbl, key, value)
		if not tbl then return end
		if not unlocked_infos[tbl] then
			pcall(function()
				if setreadonly and isreadonly and isreadonly(tbl) then
					setreadonly(tbl, false)
				end
			end)
			unlocked_infos[tbl] = true
		end
		-- prefer rawset; fall back to index once
		local ok = pcall(rawset, tbl, key, value)
		if not ok then
			pcall(function() tbl[key] = value end)
		end
	end

	-- ===== Aetherea weapons Heartbeat 1:1 =====
	local old = {}
	local weapon_last_update = 0
	local weapon_update_interval = 0.03

	local function RestoreWeaponInfo(info, original)
		if not info or not original then return end
		forceSet(info, "ShootRecoil", original.ShootRecoil)
		forceSet(info, "ShootAccuracy", original.ShootAccuracy)
		forceSet(info, "ShootSpread", original.ShootSpread)
		forceSet(info, "QuickShotSpread", original.QuickShotSpread)
		forceSet(info, "ShootSpreadConsistent", original.ShootSpreadConsistent)
		forceSet(info, "AimSpreadMultiplier", original.AimSpreadMultiplier)
		forceSet(info, "ShootCooldown", original.ShootCooldown)
		pcall(function()
			if info.InputSpammingEnabled and original.StartShooting ~= nil then
				forceSet(info.InputSpammingEnabled, "StartShooting", original.StartShooting)
			end
		end)
	end

	local gm_was_applying = false
	RunService.Heartbeat:Connect(function()
		local any = GM.no_recoil or GM.no_spread or GM.full_auto or GM.firerate_boost > 0
		if not any then
			if gm_was_applying and modules.FighterController and modules.FighterController.GetFighter then
				local fighter
				pcall(function() fighter = modules.FighterController:GetFighter(LP) end)
				local item = fighter and fighter.EquippedItem
				local info = item and item.Info
				local original = item and old[item]
				if info and original then RestoreWeaponInfo(info, original) end
				gm_was_applying = false
			end
			return
		end
		gm_was_applying = true
		if not modules.FighterController or not modules.FighterController.GetFighter then
			return
		end
		local fighter
		pcall(function() fighter = modules.FighterController:GetFighter(LP) end)
		if not fighter then return end

		local equipped_item = fighter.EquippedItem
		if not equipped_item then return end

		local info = equipped_item.Info
		if not info then return end

		if not old[equipped_item] then
			local startShooting = nil
			pcall(function()
				if info.InputSpammingEnabled then
					startShooting = info.InputSpammingEnabled.StartShooting
				end
			end)
			old[equipped_item] = {
				ShootRecoil = info.ShootRecoil,
				ShootAccuracy = info.ShootAccuracy,
				ShootSpread = info.ShootSpread,
				QuickShotSpread = info.QuickShotSpread,
				ShootSpreadConsistent = info.ShootSpreadConsistent,
				AimSpreadMultiplier = info.AimSpreadMultiplier,
				StartShooting = startShooting,
				ShootCooldown = info.ShootCooldown,
			}
		end

		local original = old[equipped_item]
		local should_apply = GM.no_recoil
			or GM.no_spread
			or GM.full_auto
			or GM.firerate_boost > 0

		if not should_apply then
			RestoreWeaponInfo(info, original)
			return
		end

		-- Aetherea: throttle non-critical, but ShootRecoil always when no_recoil
		if GM.no_recoil then
			forceSet(info, "ShootRecoil", 0)
		end

		local now = os.clock()
		if now - weapon_last_update < weapon_update_interval then
			return
		end
		weapon_last_update = now

		if not GM.no_recoil then
			forceSet(info, "ShootRecoil", original.ShootRecoil)
		end

		if GM.no_spread then
			forceSet(info, "ShootAccuracy", 0)
			forceSet(info, "ShootSpread", 0)
			forceSet(info, "QuickShotSpread", 0)
			forceSet(info, "ShootSpreadConsistent", true)
			forceSet(info, "AimSpreadMultiplier", 0)
		else
			forceSet(info, "ShootAccuracy", original.ShootAccuracy)
			forceSet(info, "ShootSpread", original.ShootSpread)
			forceSet(info, "QuickShotSpread", original.QuickShotSpread)
			forceSet(info, "ShootSpreadConsistent", original.ShootSpreadConsistent)
			forceSet(info, "AimSpreadMultiplier", original.AimSpreadMultiplier)
		end

		if GM.full_auto then
			pcall(function()
				if info.InputSpammingEnabled then
					forceSet(info.InputSpammingEnabled, "StartShooting", 0)
				end
			end)
		else
			pcall(function()
				if info.InputSpammingEnabled and original.StartShooting ~= nil then
					forceSet(info.InputSpammingEnabled, "StartShooting", original.StartShooting)
				end
			end)
		end

		if GM.firerate_boost > 0 and original.ShootCooldown then
			local mult = math.clamp(1 - (GM.firerate_boost / 100), 0.05, 1)
			forceSet(info, "ShootCooldown", original.ShootCooldown * mult)
		else
			forceSet(info, "ShootCooldown", original.ShootCooldown)
		end
	end)

	-- pre-shot force: zero recoil on the gun instance right before StartShooting
	task.spawn(function()
		for _ = 1, 50 do
			loadGunModules()
			if modules.Gun and type(modules.Gun.StartShooting) == "function" and not modules.Gun._vantaGMHooked then
				local orig = modules.Gun.StartShooting
				modules.Gun.StartShooting = function(self, ...)
					if GM.no_recoil and self and self.Info then
						forceSet(self.Info, "ShootRecoil", 0)
					end
					if GM.no_spread and self and self.Info then
						forceSet(self.Info, "ShootAccuracy", 0)
						forceSet(self.Info, "ShootSpread", 0)
						forceSet(self.Info, "QuickShotSpread", 0)
						forceSet(self.Info, "AimSpreadMultiplier", 0)
					end
					return orig(self, ...)
				end
				modules.Gun._vantaGMHooked = true
				break
			end
			task.wait(0.4)
		end
	end)

	-- Aetherea visual: ClientViewModel.ApplyRecoil no-op (same as shoot animation disable)
	task.spawn(function()
		for _ = 1, 50 do
			pcall(function()
				local path = LP.PlayerScripts
					and LP.PlayerScripts:FindFirstChild("Modules")
					and LP.PlayerScripts.Modules:FindFirstChild("ClientReplicatedClasses")
					and LP.PlayerScripts.Modules.ClientReplicatedClasses:FindFirstChild("ClientFighter")
					and LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter:FindFirstChild("ClientItem")
				local vmModule = path and path:FindFirstChild("ClientViewModel")
				if not vmModule then return end
				local ClientViewModel = require(vmModule)
				if type(ClientViewModel.ApplyRecoil) == "function" and not ClientViewModel._vantaRecoilHooked then
					local orig = ClientViewModel.ApplyRecoil
					ClientViewModel.ApplyRecoil = function(p62, p63)
						if not p62.ClientItem or not p62.ClientItem.ClientFighter or not p62.ClientItem.ClientFighter.IsLocalPlayer or not p62:IsEquipped() then
							return orig(p62, p63)
						end
						if GM.no_recoil then
							return -- 1:1 Aetherea shoot-animation disable path
						end
						return orig(p62, p63)
					end
					ClientViewModel._vantaRecoilHooked = true
				end
			end)
			task.wait(0.4)
		end
	end)

	-- ===== Wildcat camera RCS =====
	-- Wildcat (Update 22) is the first gun with real camera recoil.
	-- ShootRecoil=0 is not enough — camera is shoved up per shot.
	-- While No Recoil is on + M1 held: measure look-Y rise and pull mouse down.
	local UIS_GM = game:GetService("UserInputService")
	local last_look_y = nil

	local function isFiringGM()
		local ok, down = pcall(function()
			return UIS_GM:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		end)
		return ok and down
	end

	RunService.RenderStepped:Connect(function()
		if not GM.no_recoil then
			last_look_y = nil
			return
		end
		if not isFiringGM() then
			last_look_y = nil
			return
		end

		local cam = workspace.CurrentCamera
		if not cam then return end

		local ly = cam.CFrame.LookVector.Y
		if last_look_y == nil then
			last_look_y = ly
			return
		end

		local dy = ly - last_look_y
		if dy > 0.00004 and type(mousemoverel) == "function" then
			local vs = cam.ViewportSize
			local fov = cam.FieldOfView or 70
			-- stronger scale for Wildcat's aggressive kick
			local px = dy * (vs.Y / math.rad(fov)) * 1.35
			px = math.clamp(px, 0, 40)
			mousemoverel(0, px)
		end

		-- re-sample after compensation so user mouse still works
		local cam2 = workspace.CurrentCamera
		last_look_y = cam2 and cam2.CFrame.LookVector.Y or ly
	end)

	-- also swallow ApplyRecoil harder (Wildcat may route through it)
	task.spawn(function()
		for _ = 1, 40 do
			pcall(function()
				local path = LP.PlayerScripts
					and LP.PlayerScripts:FindFirstChild("Modules")
					and LP.PlayerScripts.Modules:FindFirstChild("ClientReplicatedClasses")
					and LP.PlayerScripts.Modules.ClientReplicatedClasses:FindFirstChild("ClientFighter")
					and LP.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter:FindFirstChild("ClientItem")
				local vmModule = path and path:FindFirstChild("ClientViewModel")
				if not vmModule then return end
				local ClientViewModel = require(vmModule)
				if type(ClientViewModel.ApplyRecoil) == "function" and not ClientViewModel._vantaWildcatHook then
					local orig = ClientViewModel.ApplyRecoil
					ClientViewModel.ApplyRecoil = function(self, amount, ...)
						if GM.no_recoil then
							local ok, isLocal = pcall(function()
								return self.ClientItem and self.ClientItem.ClientFighter and self.ClientItem.ClientFighter.IsLocalPlayer
							end)
							if ok and isLocal then
								return -- kill visual/camera punch
							end
						end
						return orig(self, amount, ...)
					end
					ClientViewModel._vantaWildcatHook = true
				end
			end)
			task.wait(0.4)
		end
	end)

	-- ===== bullet tracers (Aetherea _Tracers) =====
	local trajectory_part_event = Instance.new("BindableEvent")
	local bullet_trail_active = 0
	local bullet_trail_last_emit = 0
	local bullet_trail_emit_interval = 0.01

	trajectory_part_event.Event:Connect(function(start_pos, end_pos)
		if not GM.bullet_tracers then return end
		local now = os.clock()
		if now - bullet_trail_last_emit < bullet_trail_emit_interval then return end
		bullet_trail_last_emit = now
		if bullet_trail_active >= GM.tracer_budget then return end
		local distance = (end_pos - start_pos).Magnitude
		if distance <= 0 then return end
		bullet_trail_active += 1
		local part = Instance.new("Part")
		part.Name = ""
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Color = GM.tracer_color
		part.Material = Enum.Material.ForceField
		part.Size = Vector3.new(0.1, 0.1, distance)
		part.CFrame = CFrame.new(start_pos, end_pos) * CFrame.new(0, 0, -distance / 2)
		part.Parent = workspace
		local tween = game:GetService("TweenService"):Create(
			part, TweenInfo.new(GM.tracer_lifetime, Enum.EasingStyle.Linear), { Transparency = 1 }
		)
		tween:Play()
		tween.Completed:Connect(function()
			bullet_trail_active = math.max(0, bullet_trail_active - 1)
			part:Destroy()
		end)
		task.delay(GM.tracer_lifetime, function()
			if part.Parent then
				bullet_trail_active = math.max(0, bullet_trail_active - 1)
				part:Destroy()
			end
		end)
	end)

	task.spawn(function()
		for _ = 1, 40 do
			loadGunModules()
			if modules.Gun and modules.Gun._Tracers and not modules.Gun._vantaTracerHooked then
				local orig_tracers = modules.Gun._Tracers
				modules.Gun._Tracers = function(p118, p119, p120)
					if GM.bullet_tracers and p119 and p119.IsLocal then
						pcall(function()
							local muzzle_pos
							if p118.ViewModel and p118.ViewModel.GetMuzzlePosition then
								muzzle_pos = p118.ViewModel:GetMuzzlePosition()
							end
							local result = p119.RaycastResults and p119.RaycastResults[1]
							if muzzle_pos and result and result.Position then
								trajectory_part_event:Fire(muzzle_pos, result.Position)
							end
						end)
					end
					return orig_tracers(p118, p119, p120)
				end
				modules.Gun._vantaTracerHooked = true
				break
			end
			task.wait(0.5)
		end
	end)

	-- ===== UI =====
	pcall(function() CombatGunMods:AddSection("Gun Mods", ico("crosshair")) end)
	bindToggle(CombatGunMods, "GMNoRecoil", "No Recoil", false, function(v)
		GM.no_recoil = v
	end)
	bindToggle(CombatGunMods, "GMNoSpread", "No Spread", false, function(v)
		GM.no_spread = v
	end)
	bindToggle(CombatGunMods, "GMFullAuto", "Full Auto", false, function(v)
		GM.full_auto = v
	end)
	bindSlider(CombatGunMods, "GMFirerate", "Firerate Boost", 0, 0, 100, 0, function(v)
		GM.firerate_boost = v
	end, "%")
	pcall(function()
		CombatGunMods:AddLabel("higher % = faster")
	end)

	pcall(function() CombatGunMods:AddDivider() end)
	pcall(function() CombatGunMods:AddSection("Hit Sounds", ico("volume-2")) end)
	local HIT_SOUND_IDS = {
		Skeet = "rbxassetid://4817809188",
		Rust  = "rbxassetid://1255040462",
	}
	local hitsound = { enabled = false, selected = "Skeet", volume = 1.2 }
	getgenv().MethaneHitSound = hitsound
	local lastHitSoundTime = 0
	local function PlayHitSound(forceId)
		local now = tick()
		if not forceId and (now - lastHitSoundTime) < 0.04 then return end
		if not forceId then lastHitSoundTime = now end
		pcall(function()
			local SoundService = game:GetService("SoundService")
			local Debris = game:GetService("Debris")
			local sndId = forceId or HIT_SOUND_IDS[hitsound.selected] or HIT_SOUND_IDS.Skeet
			local snd = Instance.new("Sound")
			snd.SoundId = sndId
			snd.Volume = tonumber(hitsound.volume) or 1.2
			snd.Parent = SoundService
			snd:Play()
			pcall(function() Debris:AddItem(snd, 1.5) end)
		end)
	end
	bindToggle(CombatGunMods, "HitSoundEnabled", "Enabled", false, function(v) hitsound.enabled = v end)
	bindDropdown(CombatGunMods, "HitSoundType", "Sound", { "Skeet", "Rust" }, "Skeet", function(v) hitsound.selected = v end)
	bindSlider(CombatGunMods, "HitSoundVolume", "Volume", 1.2, 0, 3, 2, function(v) hitsound.volume = v end)
	bindButton(CombatGunMods, "Preview Sound", function()
		PlayHitSound(HIT_SOUND_IDS[hitsound.selected] or HIT_SOUND_IDS.Skeet)
	end)

	pcall(function() CombatGunMods:AddDivider() end)
	pcall(function() CombatGunMods:AddSection("Bullet Tracers", ico("sparkles")) end)
	bindToggle(CombatGunMods, "GMTracers", "Enabled", false, function(v)
		local gm = getgenv().VantaRivalsGunMods
		if gm then gm.bullet_tracers = v end
	end)
	bindColor(CombatGunMods, "GMTracerColor", "Tracer Color", Color3.fromRGB(181, 126, 220), function(col)
		local gm = getgenv().VantaRivalsGunMods
		if gm then gm.tracer_color = col end
	end)
	bindSlider(CombatGunMods, "GMTracerLife", "Lifetime", 0.45, 0.1, 2, 2, function(v)
		local gm = getgenv().VantaRivalsGunMods
		if gm then gm.tracer_lifetime = v end
	end, "s")
	task.spawn(function()
		for _ = 1, 30 do
			local ok = pcall(function()
				local ps = LP:FindFirstChild("PlayerScripts")
				local mods = ps and ps:FindFirstChild("Modules")
				local crc = mods and mods:FindFirstChild("ClientReplicatedClasses")
				local cf = crc and crc:FindFirstChild("ClientFighter")
				local ciMod = cf and cf:FindFirstChild("ClientItem")
				if not ciMod then return end
				local ci = require(ciMod)
				if ci and type(ci._PlayHitmarkerQueue) == "function" and not ci._methaneHitSoundHooked then
					local orig = ci._PlayHitmarkerQueue
					ci._PlayHitmarkerQueue = function(self, ...)
						if hitsound.enabled then
							-- only when THIS is our local fighter's item
							local isLocal = false
							pcall(function()
								local f = self and (self.Fighter or self._fighter)
								if f == nil and self and self.Player then f = self.Player end
								if f == LP then isLocal = true end
								if self and self.Character and LP.Character and self.Character == LP.Character then
									isLocal = true
								end
								-- ClientItem on local player tools only
								if self and self.Owner == LP then isLocal = true end
								if self and self.LocalPlayer == true then isLocal = true end
							end)
							if isLocal then pcall(PlayHitSound) end
						end
						return orig(self, ...)
					end
					ci._methaneHitSoundHooked = true
				end
				-- MouseCrosshair.DamageEffect fires for local crosshair only — keep but gate on LP
				local ii = ciMod:FindFirstChild("ItemInterface")
				local mMod = ii and ii:FindFirstChild("Mouse")
				local mcMod = mMod and mMod:FindFirstChild("MouseCrosshair")
				if mcMod then
					local mc = require(mcMod)
					if mc and type(mc.DamageEffect) == "function" and not mc._methaneHitSoundHooked then
						local origDE = mc.DamageEffect
						mc.DamageEffect = function(self, ...)
							-- DamageEffect is client local crosshair path only
							if hitsound.enabled then pcall(PlayHitSound) end
							return origDE(self, ...)
						end
						mc._methaneHitSoundHooked = true
					end
				end
			end)
			if ok then break end
			task.wait(1)
		end
	end)

end)()


-- SKINCHANGER
pcall(function() CosUnlock:AddSection("Skinchanger", ico("sparkles")) end)
bindDropdown(CosUnlock, "UnlockType", "Cosmetic Type", COSMETIC_TYPES, "Skin", function(v) skin.unlock_type = v end)
bindDropdown(CosUnlock, "UnlockRarity", "Rarity", COSMETIC_RARITIES, "Mythical", function(v) skin.unlock_rarity = v end)
pcall(function() CosUnlock:AddLineText("Actions") end)
bindButton(CosUnlock, "Unlock selected", function() UnlockSelectedRarity() end)
bindButton(CosUnlock, "Unlock all selected", function() UnlockAllOfType() end)
bindButton(CosUnlock, "Unlock All Cosmetics", function() UnlockAll() end)
bindButton(CosUnlock, "Unlock All Weapons", function() UnlockAllWeapons() end)

pcall(function() CosSpecific:AddSection("Specific Unlock", ico("search")) end)
bindDropdown(CosSpecific, "SpecType", "Type", COSMETIC_TYPES, "Skin", function(v) skin.specific_type = v; pcall(refreshSpecDropdowns) end)
bindDropdown(CosSpecific, "SpecWeapon", "Weapon", { "(waiting for modules)" }, 1, function(v) skin.specific_weapon = v; pcall(refreshSpecDropdowns) end)
bindDropdown(CosSpecific, "SpecName", "Cosmetic", { "(waiting for modules)" }, 1, function(v)
	skin.specific_name = (v ~= "(none)" and v ~= "(waiting for modules)") and v or ""
end)
pcall(function() CosSpecific:AddLineText("Actions") end)
bindButton(CosSpecific, "Unlock Specific", function() UnlockSpecific() end)
bindButton(CosSpecific, "Unlock All for Weapon", function() UnlockAllForWeapon() end)
bindButton(CosSpecific, "Refresh Lists", function() refreshSpecDropdowns() end)

pcall(function() CosApply:AddSection("Apply", ico("check")) end)
bindDropdown(CosApply, "EquipType", "Type", COSMETIC_TYPES, "Skin", function(v) skin.equip_type = v; pcall(refreshEquipDropdowns) end)
bindDropdown(CosApply, "EquipWeapon", "Weapon", { "(waiting for modules)" }, 1, function(v) skin.equip_weapon = v; pcall(refreshEquipDropdowns) end)
bindDropdown(CosApply, "EquipName", "Cosmetic", { "(waiting for modules)" }, 1, function(v)
	skin.equip_name = (v ~= "(none)" and v ~= "(waiting for modules)") and v or ""
end)
bindToggle(CosApply, "EquipInverted", "Inverted (Wrap)", false, function(v) skin.equip_inverted = v end)
pcall(function() CosApply:AddLineText("Actions") end)
bindButton(CosApply, "Equip", function() EquipApply() end)
bindButton(CosApply, "Equip All Weapons", function() EquipApplyAll() end)
bindButton(CosApply, "Refresh Lists", function() refreshEquipDropdowns() end)

pcall(function() CosSave:AddSection("Save Loadout", ico("save")) end)
bindButton(CosSave, "Save", function() saveLoadoutFile() end)
bindButton(CosSave, "Reload", function() loadLoadoutFile() end)

-- INVENTORY
pcall(function() InvSingle:AddSection("Single", ico("package")) end)
bindDropdown(InvSingle, "InvCaseBox", "Case / Box", LOOTBOX_NAMES, "Skin Case", function(v) inventory.specific.lootbox_name = v end)
bindSlider(InvSingle, "InvQty", "Quantity", 1, 1, 99, 0, function(v) inventory.specific.quantity = v end)
bindDropdown(InvSingle, "InvWeapon", "For Weapon", { "(None)", "IsRandom" }, "(None)", function(v)
	inventory.specific.weapon_name = (v == "(None)") and "" or v
end)
bindToggle(InvSingle, "InvNewEntry", "New Entry", false, function(v) inventory.specific.new_entry = v end)
pcall(function() InvSingle:AddLineText("Actions") end)
bindButton(InvSingle, "Add to Backpack", function() AddToBackpack() end)

pcall(function() InvBulk:AddSection("Bulk", ico("boxes")) end)
bindSlider(InvBulk, "InvBulkQty", "Quantity", 1, 1, 99, 0, function(v) inventory.bulk.quantity = v end)
bindButton(InvBulk, "Add All Cases", function() AddAllCases() end)

pcall(function() InvDelete:AddSection("Delete", ico("trash-2")) end)
bindDropdown(InvDelete, "InvDeleteEntry", "Backpack Entry", { "(empty)" }, 1, function(v)
	if v ~= "(empty)" then inventory.delete.backpack_entry = v end
end)
bindSlider(InvDelete, "InvDeleteQty", "Quantity", 1, 1, 99, 0, function(v) inventory.delete.quantity = v end)
pcall(function() InvDelete:AddLineText("Actions") end)
bindButton(InvDelete, "Refresh List", function()
	local e = GetBackpackEntries(); setDropdownValues("InvDeleteEntry", e, e[1])
end)
bindButton(InvDelete, "Delete ALL Backpack", function() DeleteAllBackpack(); setDropdownValues("InvDeleteEntry", GetBackpackEntries(), nil) end)
bindButton(InvDelete, "Delete (Qty)", function() DeleteQuantity(); setDropdownValues("InvDeleteEntry", GetBackpackEntries(), nil) end)
bindButton(InvDelete, "Delete ALL of Entry", function() DeleteAllOfEntry(); setDropdownValues("InvDeleteEntry", GetBackpackEntries(), nil) end)

pcall(function() InvInject:AddSection("Inject", ico("plus")) end)
bindDropdown(InvInject, "InvInjectType", "Type", { "Skin", "Wrap", "Charm", "Finisher", "Emote" }, "Skin", function(v) inventory.inject.item_type = v end)
bindDropdown(InvInject, "InvInjectWeapon", "For Weapon", { "Universal", "IsRandom" }, "Universal", function(v)
	inventory.inject.weapon_name = (v == "Universal") and "" or v
end)
bindDropdown(InvInject, "InvInjectCosmetic", "Item", { "(waiting for modules)" }, 1, function(v)
	inventory.inject.cosmetic_name = (v and v ~= "(none)" and v ~= "(waiting for modules)") and v or ""
end)
bindSlider(InvInject, "InvInjectQty", "Quantity", 1, 1, 9999, 0, function(v) inventory.inject.quantity = v end)
bindToggle(InvInject, "InvStackDupes", "Stack duplicates", false, function(v) inventory.inject.stack_duplicates = v end)
bindButton(InvInject, "Inject", function() InjectIntoBackpack() end)

-- WORLD
pcall(function() WorldLighting:AddSection("Lighting", ico("sun")) end)
bindToggle(WorldLighting, "WorldLightingEnabled", "Enabled", false, function(v) world.lighting_enabled = v; pcall(UpdateLightingOptions) end)
pcall(function() WorldLighting:AddLineText("Configure Lighting") end)
bindColor(WorldLighting, "WorldAmbient", "Ambient", Lighting.Ambient, function(c)
	world.ambient_color = c; pcall(UpdateLightingOptions)
end)
bindColor(WorldLighting, "WorldOutdoorAmbient", "Outdoor Ambient", Lighting.OutdoorAmbient, function(c)
	world.outdoor_ambient_color = c; pcall(UpdateLightingOptions)
end)
bindColor(WorldLighting, "WorldShiftTop", "ColorShift Top", Lighting.ColorShift_Top, function(c)
	world.shift_top = c; pcall(UpdateLightingOptions)
end)
bindColor(WorldLighting, "WorldShiftBottom", "ColorShift Bottom", Lighting.ColorShift_Bottom, function(c)
	world.shift_bottom = c; pcall(UpdateLightingOptions)
end)
bindSlider(WorldLighting, "WorldBrightness", "Brightness", 2, 0, 10, 1, function(v) world.brightness = v; pcall(UpdateLightingOptions) end)
bindSlider(WorldLighting, "WorldExposure", "Exposure", 0, -5, 5, 2, function(v) world.exposure = v; pcall(UpdateLightingOptions) end)
bindSlider(WorldLighting, "WorldShadowSoftness", "Shadow Softness", 0.2, 0, 1, 2, function(v) world.shadow_softness = v; pcall(UpdateLightingOptions) end)
bindToggle(WorldLighting, "WorldGlobalShadows", "Global Shadows", true, function(v) world.global_shadows = v; pcall(UpdateLightingOptions) end)
bindToggle(WorldLighting, "WorldAntiSmoke", "Anti Smoke", false, function(v) world.anti_smoke = v end)
bindToggle(WorldLighting, "WorldAntiFlash", "Anti Flashbang", false, function(v) world.anti_flashbang = v end)

pcall(function() WorldAtmo:AddSection("Atmosphere", ico("cloud")) end)
bindToggle(WorldAtmo, "WorldAtmoEnabled", "Enabled", false, function(v) world.atmosphere_enabled = v; pcall(UpdateAtmosphereOptions) end)
pcall(function() WorldAtmo:AddLineText("Configure Atmosphere") end)
bindColor(WorldAtmo, "WorldAtmoColor", "Color", Color3.fromRGB(140, 196, 231), function(c)
	world.atm_color = c; pcall(UpdateAtmosphereOptions)
end)
bindColor(WorldAtmo, "WorldAtmoDecay", "Decay", Color3.fromRGB(92, 60, 13), function(c)
	world.decay = c; pcall(UpdateAtmosphereOptions)
end)
bindSlider(WorldAtmo, "WorldAtmoDensity", "Density", 0.255, 0, 1, 3, function(v) world.density = v; pcall(UpdateAtmosphereOptions) end)
bindSlider(WorldAtmo, "WorldAtmoOffset", "Offset", 0.2, 0, 1, 2, function(v) world.offset = v; pcall(UpdateAtmosphereOptions) end)
bindSlider(WorldAtmo, "WorldAtmoGlare", "Glare", 0, 0, 10, 1, function(v) world.glare = v; pcall(UpdateAtmosphereOptions) end)
bindSlider(WorldAtmo, "WorldAtmoHaze", "Haze", 1.82, 0, 10, 2, function(v) world.haze = v; pcall(UpdateAtmosphereOptions) end)

pcall(function() WorldAtmo:AddDivider() end)
pcall(function() WorldAtmo:AddSection("CC", ico("palette")) end)
bindToggle(WorldAtmo, "WorldCCEnabled", "Enabled", false, function(v)
	world.cc_enabled = v; pcall(UpdateColorCorrectionOptions)
end)
bindSlider(WorldAtmo, "WorldCCBrightness", "Brightness", 0, -1, 1, 2, function(v)
	world.cc_brightness = v; pcall(UpdateColorCorrectionOptions)
end)
bindSlider(WorldAtmo, "WorldCCContrast", "Contrast", 0, -1, 1, 2, function(v)
	world.cc_contrast = v; pcall(UpdateColorCorrectionOptions)
end)
bindSlider(WorldAtmo, "WorldCCSaturation", "Saturation", 0, -1, 1, 2, function(v)
	world.cc_saturation = v; pcall(UpdateColorCorrectionOptions)
end)
bindColor(WorldAtmo, "WorldCCTint", "Tint", Color3.fromRGB(255, 255, 255), function(c)
	world.cc_tint = c; pcall(UpdateColorCorrectionOptions)
end)

pcall(function() WorldAtmo:AddDivider() end)
pcall(function() WorldAtmo:AddSection("Sun Rays", ico("sun")) end)
bindToggle(WorldAtmo, "WorldSunRays", "Enabled", false, function(v) world.sunrays_enabled = v; pcall(UpdateSunRaysOptions) end)
bindSlider(WorldAtmo, "WorldSunRaysIntensity", "Intensity", 0.25, 0, 1, 2, function(v) world.sunrays_intensity = v; pcall(UpdateSunRaysOptions) end)

pcall(function() WorldSky:AddSection("Skybox", ico("image")) end)
bindToggle(WorldSky, "WorldSkyboxEnabled", "Enabled", false, function(v)
	world.skybox_enabled = v
	if v then pcall(UpdateSkybox); pcall(SetSkyboxAutoRotate) end
end)
pcall(function() WorldSky:AddLineText("Configure Skybox") end)
bindDropdown(WorldSky, "WorldSkyboxPreset", "Preset", SKYBOX_LIST, "None", function(v) world.skybox_value = v; pcall(UpdateSkybox) end)
bindSlider(WorldSky, "WorldClockTime", "ClockTime", 14, 0, 24, 2, function(v)
	world.clocktime = v
	if world.skybox_enabled then pcall(function() Lighting.ClockTime = v end) end
end)

pcall(function() WorldCam:AddSection("Viewmodel", ico("eye")) end)
bindSlider(WorldCam, "WorldCameraFov", "FOV", 70, 10, 120, 0, function(v)
	world.camera_fov = v
	pcall(function()
		if modules.CameraController and modules.CameraController._base_fov ~= nil then
			modules.CameraController._base_fov = v
		end
		if workspace.CurrentCamera then workspace.CurrentCamera.FieldOfView = v end
	end)
end, "°")
bindSlider(WorldCam, "WorldCameraResolution", "Resolution", 1, 0, 1, 2, function(v) world.camera_resolution = v end)

-- Third person + freecam (logic installed later)
pcall(function() WorldCam:AddDivider() end)
pcall(function() WorldCam:AddSection("Third Person", ico("user")) end)
bindToggleKey(WorldCam, "ViewThirdPerson", "Enabled", false, function(v)
	world.third_person = v
end)
bindSlider(WorldCam, "ViewThirdDist", "Distance", 12, 5, 30, 0, function(v)
	world.third_dist = v
end, "m")
pcall(function() WorldCam:AddSection("Freecam", ico("eye")) end)
bindToggleKey(WorldCam, "ViewFreecam", "Enabled", false, function(v)
	world.freecam = v
end)
bindSlider(WorldCam, "ViewFreecamSpeed", "Speed", 40, 10, 120, 0, function(v)
	world.freecam_speed = v
end, "m/s")



-- SPOOFER 1:1
pcall(function() SpoofPlatform:AddSection("Platform", ico("smartphone")) end)
bindDropdown(SpoofPlatform, "SpoofDevice", "Device", { "Desktop", "Mobile", "Console", "VR" }, "Desktop", function(v)
	spoofer.device = v
	if spoofer.spoof_device then SetDevice(false) end
end)
bindToggle(SpoofPlatform, "SpoofDeviceActive", "Spoof Device", false, function(v)
	spoofer.spoof_device = v
	if v then SetDevice(false); VantaNotify({ Title = "success", Description = "spoofed -> " .. tostring(spoofer.device), Time = 2 })
	else SetDevice(true); VantaNotify({ Title = "success", Description = "device reset", Time = 2 }) end
end)
bindToggle(SpoofPlatform, "SpoofDeviceSpam", "Device Spam", false, function(v)
	spoofer.device_spam = v; DeviceSpam()
end)
bindInput(SpoofPlatform, "SpoofSpamRate", "Spam Rate", "1", "0.1 - 5", function(v)
	spoofer.spam_rate = math.clamp(tonumber(v) or 1, 0.1, 5)
end)

pcall(function() SpoofPlayer:AddSection("Player", ico("user")) end)
bindInput(SpoofPlayer, "SpoofDisplayName", "Display Name", LP.DisplayName, "display name", function(v)
	spoofer.display_name_value = v
	if spoofer.display_name then RefreshAllNameSpoofs() end
end)
bindToggle(SpoofPlayer, "SpoofDisplayNameActive", "Spoof Display Name", false, function(v)
	spoofer.display_name = v
	if v then pcall(function() spoofer._startNameWatch() end) else pcall(function() spoofer._stopNameWatch() end) end
	RefreshAllNameSpoofs()
end)
bindInput(SpoofPlayer, "SpoofUsername", "Username", LP.Name, "username", function(v)
	spoofer.username_value = v
	if spoofer.username then RefreshAllNameSpoofs() end
end)
bindToggle(SpoofPlayer, "SpoofUsernameActive", "Spoof Username", false, function(v)
	spoofer.username = v
	if v then pcall(function() spoofer._startNameWatch() end) else pcall(function() spoofer._stopNameWatch() end) end
	RefreshAllNameSpoofs()
end)
bindInput(SpoofPlayer, "SpoofAvatarUserId", "Avatar UserId", tostring(LP.UserId), "userid", function(v)
	spoofer.avatar_userid = tonumber(v) or LP.UserId
end)
bindToggle(SpoofPlayer, "SpoofAvatarActive", "Spoof Avatar", false, function(v)
	spoofer.avatar = v
	spoofer.spoof_avatar = v
	if v then pcall(function() spoofer._startThumbWatch() end) else pcall(function() spoofer._stopThumbWatch() end) end
end)

pcall(function() SpoofLB:AddSection("Leaderboard", ico("list")) end)
bindInput(SpoofLB, "SpoofEloValue", "ELO", "0", "number", function(v)
	spoofer.leaderboard.elo_value = tonumber(v) or 0
	if spoofer.leaderboard.ELO then UpdateLeaderboardAttributes() end
end)
bindToggle(SpoofLB, "SpoofEloActive", "Spoof ELO", false, function(v)
	spoofer.leaderboard.ELO = v; UpdateLeaderboardAttributes()
end)
bindInput(SpoofLB, "SpoofStreakValue", "Streak", "0", "number", function(v)
	spoofer.leaderboard.streak_value = tonumber(v) or 0
	if spoofer.leaderboard.Streak then UpdateLeaderboardAttributes() end
end)
bindToggle(SpoofLB, "SpoofStreakActive", "Spoof Streak", false, function(v)
	spoofer.leaderboard.Streak = v; UpdateLeaderboardAttributes()
end)
bindInput(SpoofLB, "SpoofKillsValue", "Kills", "0", "number", function(v)
	spoofer.leaderboard.kills_value = tonumber(v) or 0
	if spoofer.leaderboard.Kills then UpdateLeaderboardAttributes() end
end)
bindToggle(SpoofLB, "SpoofKillsActive", "Spoof Kills", false, function(v)
	spoofer.leaderboard.Kills = v; UpdateLeaderboardAttributes()
end)
bindInput(SpoofLB, "SpoofWinsValue", "Wins", "0", "number", function(v)
	spoofer.leaderboard.wins_value = tonumber(v) or 0
	if spoofer.leaderboard.Wins then UpdateLeaderboardAttributes() end
end)
bindToggle(SpoofLB, "SpoofWinsActive", "Spoof Wins", false, function(v)
	spoofer.leaderboard.Wins = v; UpdateLeaderboardAttributes()
end)
bindInput(SpoofLB, "SpoofLevelValue", "Level", "0", "number", function(v)
	spoofer.leaderboard.level_value = tonumber(v) or 0
	if spoofer.leaderboard.Level then UpdateLeaderboardAttributes() end
end)
bindToggle(SpoofLB, "SpoofLevelActive", "Spoof Level", false, function(v)
	spoofer.leaderboard.Level = v; UpdateLeaderboardAttributes()
end)
bindButton(SpoofLB, "Clear Leaderboard Spoofs", function()
	local lb = spoofer.leaderboard
	lb.ELO, lb.Streak, lb.Kills, lb.Wins, lb.Level = false, false, false, false, false
	UpdateLeaderboardAttributes()
end)

pcall(function() SpoofCur:AddSection("Currency / Keys", ico("coins")) end)
bindInput(SpoofCur, "SpoofWeaponKeysValue", "Weapon Keys", "0", "number", function(v)
	spoofer.currency.weapon_keys_value = tonumber(v) or 0
	if spoofer.currency.weapon_keys then UpdateCurrencyOptions() end
end)
bindToggle(SpoofCur, "SpoofWeaponKeysActive", "Spoof Weapon Keys", false, function(v)
	spoofer.currency.weapon_keys = v; UpdateCurrencyOptions()
end)
bindInput(SpoofCur, "SpoofUnlockTokensValue", "Unlock Tokens", "0", "number", function(v)
	spoofer.currency.unlock_tokens_value = tonumber(v) or 0
	if spoofer.currency.unlock_tokens then UpdateCurrencyOptions() end
end)
bindToggle(SpoofCur, "SpoofUnlockTokensActive", "Spoof Unlock Tokens", false, function(v)
	spoofer.currency.unlock_tokens = v; UpdateCurrencyOptions()
end)
bindInput(SpoofCur, "SpoofSkinTicketsValue", "Skin Tickets", "0", "number", function(v)
	spoofer.currency.skin_tickets_value = tonumber(v) or 0
	if spoofer.currency.skin_tickets then UpdateCurrencyOptions() end
end)
bindToggle(SpoofCur, "SpoofSkinTicketsActive", "Spoof Skin Tickets", false, function(v)
	spoofer.currency.skin_tickets = v; UpdateCurrencyOptions()
end)
bindInput(SpoofCur, "SpoofGloryValue", "Glory", "0", "number", function(v)
	spoofer.currency.glory_value = tonumber(v) or 0
	if spoofer.currency.glory then UpdateCurrencyOptions() end
end)
bindToggle(SpoofCur, "SpoofGloryActive", "Spoof Glory", false, function(v)
	spoofer.currency.glory = v; UpdateCurrencyOptions()
end)
bindButton(SpoofCur, "Clear Currency Spoofs", function()
	local cur = spoofer.currency
	cur.weapon_keys, cur.unlock_tokens, cur.skin_tickets, cur.glory = false, false, false, false
	UpdateCurrencyOptions()
end)

pcall(function() SpoofBadge:AddSection("Badges", ico("award")) end)
bindToggle(SpoofBadge, "SpoofBadgePremium", "Premium", false, function(v) spoofer.badges.Premium = v; UpdateBadgesOptions() end)
bindToggle(SpoofBadge, "SpoofBadgeVerified", "Verified", false, function(v) spoofer.badges.Verified = v; UpdateBadgesOptions() end)
bindToggle(SpoofBadge, "SpoofBadgeInfluencer", "Influencer", false, function(v) spoofer.badges.Influencer = v; UpdateBadgesOptions() end)
bindToggle(SpoofBadge, "SpoofBadgeAdmin", "Admin", false, function(v) spoofer.badges.Admin = v; UpdateBadgesOptions() end)
pcall(function() SpoofBadge:AddDivider() end)
pcall(function() SpoofBadge:AddSection("Charm", ico("sparkles")) end)
bindDropdown(SpoofBadge, "SpoofCharmRank", "Charm Rank", CHARM_RANKS, "Use Spoofed ELO", function(v)
	spoofer.charm.charm_rank = v
	if spoofer.charm.s0_charm or spoofer.charm.s1_charm or spoofer.charm.s2_charm or spoofer.charm.s3_charm then UpdateCharmOptions() end
end)
bindInput(SpoofBadge, "SpoofArchRank", "Arch Rank", "1", "1-100", function(v)
	spoofer.charm.arch_rank = math.clamp(tonumber(v) or 1, 1, 100)
end)
bindToggle(SpoofBadge, "SpoofS0Charm", "Season 0 Charm", false, function(v) spoofer.charm.s0_charm = v; UpdateCharmOptions() end)
bindToggle(SpoofBadge, "SpoofS1Charm", "Season 1 Charm", false, function(v) spoofer.charm.s1_charm = v; UpdateCharmOptions() end)
bindToggle(SpoofBadge, "SpoofS2Charm", "Season 2 Charm", false, function(v) spoofer.charm.s2_charm = v; UpdateCharmOptions() end)
bindToggle(SpoofBadge, "SpoofS3Charm", "Season 3 Charm", false, function(v) spoofer.charm.s3_charm = v; UpdateCharmOptions() end)

-- MISC
pcall(function() MiscCross:AddSection("Crosshair", ico("crosshair")) end)
bindToggle(MiscCross, "MiscCrosshairEnabled", "Enabled", false, function(v)
	if misc and misc.crosshair then misc.crosshair.enabled = v end
end)
pcall(function() MiscCross:AddLineText("Configure Crosshair") end)
bindSlider(MiscCross, "MiscCrosshairOffset", "Offset", 5, 0, 50, 0, function(v) if misc.crosshair then misc.crosshair.offset = v end end)
bindSlider(MiscCross, "MiscCrosshairLength", "Length", 20, 1, 60, 0, function(v) if misc.crosshair then misc.crosshair.length = v end end)
bindSlider(MiscCross, "MiscCrosshairThickness", "Thickness", 2, 1, 10, 0, function(v) if misc.crosshair then misc.crosshair.thickness = v end end)

task.spawn(function()
	for i = 1, 25 do
		pcall(loadModulesOnce)
		local weapons = getWeaponList()
		if weapons[1] and weapons[1] ~= "(waiting for modules)" then
			pcall(refreshSpecDropdowns); pcall(refreshEquipDropdowns)
			return
		end
		task.wait(1)
	end
end)



-- Widgets: ESP Preview + Keybind List (default ON)
-- ESP overlays are drawn with Drawing API over the preview panel (Rivals-side only)
local MethaneKeybindList, MethaneESPPreview
pcall(function()
	MethaneKeybindList = Library:KeybindList({ Name = "Keybinds" })
	MethaneESPPreview = Library:ESPPreview({ Name = "ESP Preview" })
	if MethaneKeybindList and MethaneKeybindList.SetVisibility then
		MethaneKeybindList:SetVisibility(true)
	end
	if MethaneESPPreview and MethaneESPPreview.SetVisibility then
		MethaneESPPreview:SetVisibility(true)
	end
	Library:RegisterSettingsWidget({
		Name = "Keybind List",
		Default = true,
		Callback = function(v)
			if MethaneKeybindList then MethaneKeybindList:SetVisibility(v) end
		end,
	})
	Library:RegisterSettingsWidget({
		Name = "ESP Preview",
		Default = true,
		Callback = function(v)
			if MethaneESPPreview then MethaneESPPreview:SetVisibility(v) end
		end,
	})
	Library:RegisterSettingsWidget({
		Name = "Watermark",
		Default = true,
		Callback = function(v)
			local wm = getgenv().MethaneWatermark
			if wm and wm.SetVisibility then
				pcall(function() wm:SetVisibility(v) end)
			end
		end,
	})

	-- Player list (Friendly = whitelist, Enemy = prioritize)
	local MethanePlayerlist
	pcall(function()
		if Library.Playerlist then
			MethanePlayerlist = Library:Playerlist({ Name = "Player List" })
		end
	end)
	if MethanePlayerlist then
		-- Library already fills the list + PlayerAdded; do not Add again (duplicates)
		pcall(function()
			if MethanePlayerlist.SetText then
				MethanePlayerlist:SetText("Player List")
			end
		end)

		-- Priority Status dropdown → apply to every selected row, then sync aim flags
		task.spawn(function()
			local lastFlag
			while true do
				task.wait(0.25)
				pcall(function()
					local flags = Library.Flags or {}
					local cur = flags.PlayerlistStatus
					if type(cur) == "table" then
						cur = cur.Value or cur[1] or cur
					end
					if cur ~= nil and tostring(cur) ~= tostring(lastFlag) then
						lastFlag = cur
						local st = tostring(cur)
						for _, pd in pairs(MethanePlayerlist.Players or {}) do
							if pd and pd.IsSelected then
								pd.Status = st
								pcall(function()
									if pd.Items and pd.Items.Status and pd.Items.Status.Instance then
										pd.Items.Status.Instance.Text = st
									end
								end)
							end
						end
						if MethanePlayerlist.Selected then
							MethanePlayerlist.Selected.Status = st
						end
					end
					syncPlayerFlagsFromList(MethanePlayerlist)
				end)
			end
		end)

		Players.PlayerRemoving:Connect(function(plr)
			PlayerFlags.whitelist[plr.UserId] = nil
			PlayerFlags.priority[plr.UserId] = nil
		end)

		Library:RegisterSettingsWidget({
			Name = "Player List",
			Default = true,
			Callback = function(v)
				if MethanePlayerlist and MethanePlayerlist.SetVisibility then
					pcall(function() MethanePlayerlist:SetVisibility(v) end)
				end
			end,
		})
		getgenv().MethanePlayerlist = MethanePlayerlist
		if MethanePlayerlist.SetVisibility then
			pcall(function() MethanePlayerlist:SetVisibility(true) end)
		end
	end

	-- Target HUD (Library:TargetIndicator) — silent aim + aimbot
	local MethaneTargetHUD
	pcall(function()
		if type(Library.TargetIndicator) == "function" then
			MethaneTargetHUD = Library:TargetIndicator()
		end
	end)
	if MethaneTargetHUD then
		pcall(function()
			if MethaneTargetHUD.SetVisibility then
				MethaneTargetHUD:SetVisibility(false)
			end
		end)
		-- line under name: which system holds the lock
		local sourceLabel
		pcall(function()
			if MethaneTargetHUD.AddItem then
				sourceLabel = MethaneTargetHUD:AddItem("Source: —")
			end
		end)
		local function setSourceText(text)
			pcall(function()
				if sourceLabel and sourceLabel.Instance then
					sourceLabel.Instance.Text = text
				elseif sourceLabel and sourceLabel.Text then
					sourceLabel.Text = text
				end
			end)
		end
		getgenv().MethaneTargetHUD = MethaneTargetHUD
		getgenv().MethaneTargetHUDEnabled = false

		Library:RegisterSettingsWidget({
			Name = "Target HUD",
			Default = false,
			Callback = function(v)
				local on = v == true
				getgenv().MethaneTargetHUDEnabled = on
				local hud = getgenv().MethaneTargetHUD
				if not hud then return end
				pcall(function()
					if hud.SetVisibility then hud:SetVisibility(on) end
					if not on then
						if hud.SetTarget then hud:SetTarget(nil) end
						setSourceText("Source: —")
					end
				end)
			end,
		})

		local lastTarget = nil
		local lastSource = nil
		local lastSetAt = 0
		task.spawn(function()
			while true do
				task.wait(0.12)
				pcall(function()
					local hud = getgenv().MethaneTargetHUD
					if not hud then return end
					if not getgenv().MethaneTargetHUDEnabled then
						if lastTarget ~= nil or lastSource ~= nil then
							lastTarget, lastSource = nil, nil
							if hud.SetTarget then hud:SetTarget(nil) end
							setSourceText("Source: —")
						end
						return
					end
					local target, source = nil, nil
					local AA = getgenv().VantaRivalsAimbot
					local SA = getgenv().VantaRivalsSilent
					if AA and AA.enabled and typeof(AA.target_player) == "Instance" and AA.target_player.Parent then
						target = AA.target_player
						source = "Aimbot"
					elseif SA and SA.enabled and typeof(SA.target_player) == "Instance" and SA.target_player.Parent then
						target = SA.target_player
						source = "Silent Aim"
					end
					local now = os.clock()
					if target ~= lastTarget or source ~= lastSource then
						lastTarget, lastSource = target, source
						lastSetAt = now
						if hud.SetTarget then hud:SetTarget(target) end
						if target and source then
							setSourceText("mode: " .. source)
						else
							setSourceText("searching: find a target.. :3")
						end
					elseif target and (now - lastSetAt) > 2 then
						lastSetAt = now
						if hud.SetTarget then hud:SetTarget(target) end
						if source then setSourceText("mode: " .. source) end
					end
				end)
			end
		end)
	end

	getgenv().VantaRivals = getgenv().VantaRivals or {}
	getgenv().VantaRivals.ESPPreview = MethaneESPPreview
	getgenv().VantaRivals.KeybindList = MethaneKeybindList

	----------------------------------------------------------------
	-- ESP Preview: project viewport model (working fit) + live ESP style
	----------------------------------------------------------------
	local function newL()
		local ok, o = pcall(Drawing.new, "Line")
		if not (ok and o) then return nil end
		o.Visible = false; o.Thickness = 1; o.Transparency = 1; o.ZIndex = 2
		return o
	end
	local function newS()
		local ok, o = pcall(Drawing.new, "Square")
		if not (ok and o) then return nil end
		o.Visible = false; o.Filled = false; o.Thickness = 1; o.Transparency = 1; o.ZIndex = 2
		return o
	end
	local function newT()
		local ok, o = pcall(Drawing.new, "Text")
		if not (ok and o) then return nil end
		o.Visible = false; o.Center = true; o.Outline = true; o.Size = 13; o.Font = 2; o.Transparency = 1; o.ZIndex = 3
		return o
	end
	local function newC()
		local ok, o = pcall(Drawing.new, "Circle")
		if not (ok and o) then return nil end
		o.Visible = false; o.Filled = true; o.Thickness = 1; o.Transparency = 1; o.ZIndex = 3
		return o
	end
	local function hide(o)
		if o then pcall(function() o.Visible = false end) end
	end

	local function lerpColor(a, b, t)
		t = math.clamp(t, 0, 1)
		return Color3.new(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t)
	end
	local function threeWayColor(low, mid, high, t)
		t = math.clamp(t, 0, 1)
		if t < 0.5 then return lerpColor(low, mid, t * 2) end
		return lerpColor(mid, high, (t - 0.5) * 2)
	end

	-- same pools as live ESP entry shape (subset)
	local e = {
		edge = {}, edgeO = {},
		corner = {}, cornerO = {},
		fill = newS(),
		hp_bg = newL(),
		hp_seg = {},
		hp_text = newT(),
		name = newT(),
		dist = newT(),
		wep = newT(),
		head = newC(),
		tr = newL(),
		trO = newL(),
		skel = {},
	}
	for i = 1, 24 do e.edge[i] = newL(); e.edgeO[i] = newL() end
	for i = 1, 8 do e.corner[i] = newL(); e.cornerO[i] = newL() end
	for i = 1, 16 do e.skel[i] = newL(); e.hp_seg[i] = newL() end

	local function hideAll()
		hide(e.fill); hide(e.hp_bg); hide(e.hp_text)
		hide(e.name); hide(e.dist); hide(e.wep); hide(e.head)
		hide(e.tr); hide(e.trO)
		for i = 1, 24 do hide(e.edge[i]); hide(e.edgeO[i]) end
		for i = 1, 8 do hide(e.corner[i]); hide(e.cornerO[i]) end
		for i = 1, 16 do hide(e.skel[i]); hide(e.hp_seg[i]) end
	end

	-- live-style setEdge (outline UNDER color, +1.5 thick only)
	local function setEdge(line, outline, a, b, col, thick, useOutline, ocol)
		thick = math.max(thick or 1, 1)
		if useOutline and outline then
			outline.From = a; outline.To = b
			outline.Color = ocol or Color3.fromRGB(0, 0, 0)
			outline.Thickness = thick + 1.5
			outline.ZIndex = 1
			outline.Visible = true
		elseif outline then
			outline.Visible = false
		end
		if line then
			line.From = a; line.To = b
			line.Color = col
			line.Thickness = thick
			line.ZIndex = 2
			line.Visible = true
		end
	end

	local function drawCornerBox(x, y, w, h, colTop, colBot, thick, useOutline, ocol)
		local len = math.clamp(math.min(w, h) * 0.25, 4, 18)
		local segs = {
			{ Vector2.new(x, y), Vector2.new(x + len, y), colTop },
			{ Vector2.new(x, y), Vector2.new(x, y + len), colTop },
			{ Vector2.new(x + w, y), Vector2.new(x + w - len, y), colTop },
			{ Vector2.new(x + w, y), Vector2.new(x + w, y + len), colTop },
			{ Vector2.new(x, y + h), Vector2.new(x + len, y + h), colBot },
			{ Vector2.new(x, y + h), Vector2.new(x, y + h - len), colBot },
			{ Vector2.new(x + w, y + h), Vector2.new(x + w - len, y + h), colBot },
			{ Vector2.new(x + w, y + h), Vector2.new(x + w, y + h - len), colBot },
		}
		for i = 1, 8 do
			setEdge(e.corner[i], e.cornerO[i], segs[i][1], segs[i][2], segs[i][3], thick, useOutline, ocol)
		end
		for i = 1, 24 do hide(e.edge[i]); hide(e.edgeO[i]) end
	end

	local function drawFullBox(x, y, w, h, colTop, colBot, thick, useOutline, ocol, gradient)
		for i = 1, 8 do hide(e.corner[i]); hide(e.cornerO[i]) end
		for i = 1, 24 do hide(e.edge[i]); hide(e.edgeO[i]) end
		local idx = 1
		setEdge(e.edge[idx], e.edgeO[idx], Vector2.new(x, y), Vector2.new(x + w, y), colTop, thick, useOutline, ocol); idx += 1
		setEdge(e.edge[idx], e.edgeO[idx], Vector2.new(x, y + h), Vector2.new(x + w, y + h), gradient and colBot or colTop, thick, useOutline, ocol); idx += 1
		local segs = gradient and 8 or 1
		for s = 0, segs - 1 do
			local t0, t1 = s / segs, (s + 1) / segs
			local col = gradient and lerpColor(colTop, colBot, (t0 + t1) * 0.5) or colTop
			setEdge(e.edge[idx], e.edgeO[idx], Vector2.new(x, y + h * t0), Vector2.new(x, y + h * t1), col, thick, useOutline, ocol); idx += 1
			setEdge(e.edge[idx], e.edgeO[idx], Vector2.new(x + w, y + h * t0), Vector2.new(x + w, y + h * t1), col, thick, useOutline, ocol); idx += 1
		end
	end

	local cachedViewport, cachedModel, cachedCam, cachedPanel
	local GuiService = game:GetService("GuiService")
	local previewChams = nil

	local function findPreviewParts()
		if cachedViewport and cachedViewport.Parent and cachedModel and cachedModel.Parent then
			return cachedPanel, cachedViewport, cachedModel, cachedCam or cachedViewport.CurrentCamera
		end
		cachedViewport, cachedModel, cachedCam, cachedPanel = nil, nil, nil, nil
		local roots = {}
		pcall(function()
			if MethaneESPPreview and MethaneESPPreview.GetFrame then
				local fr = MethaneESPPreview:GetFrame()
				if fr then table.insert(roots, fr) end
			end
		end)
		pcall(function() if gethui then table.insert(roots, gethui()) end end)
		pcall(function() table.insert(roots, game:GetService("CoreGui")) end)
		for _, root in ipairs(roots) do
			if not root then continue end
			for _, d in ipairs(root:GetDescendants()) do
				if d:IsA("ViewportFrame") then
					for _, ch in ipairs(d:GetChildren()) do
						if ch:IsA("Model") and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")) then
							cachedViewport = d
							cachedModel = ch
							cachedCam = d.CurrentCamera
							local p = d.Parent
							for _ = 1, 6 do
								if p and p:IsA("Frame") and p.AbsoluteSize.X >= 180 then
									cachedPanel = p
									break
								end
								p = p and p.Parent
							end
							return cachedPanel, cachedViewport, cachedModel, cachedCam
						end
					end
				end
			end
		end
	end

	-- PREVIOUS working projection (do not change mapping)
	local function vpToScreen(viewport, cam, worldPos)
		local sp, onScreen = cam:WorldToViewportPoint(worldPos)
		local vps = cam.ViewportSize
		if vps.X < 1 or vps.Y < 1 then
			vps = viewport.AbsoluteSize
		end
		local abs = viewport.AbsolutePosition
		local inset = Vector2.zero
		pcall(function() inset = GuiService:GetGuiInset() end)
		local sx = abs.X + (sp.X / vps.X) * viewport.AbsoluteSize.X
		local sy = abs.Y + inset.Y + (sp.Y / vps.Y) * viewport.AbsoluteSize.Y
		return Vector2.new(sx, sy), onScreen and sp.Z > 0
	end

	local function previewBox(model, viewport, cam)
		local head = model:FindFirstChild("Head")
		local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("UpperTorso") or model:FindFirstChild("Torso")
		local foot = model:FindFirstChild("LeftFoot") or model:FindFirstChild("RightFoot")
			or model:FindFirstChild("Left Leg") or model:FindFirstChild("Right Leg")
		if not root and not head then return end
		local topPos = head and (head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.1, 0))
			or (root.Position + Vector3.new(0, 1.5, 0))
		local botPos = foot and (foot.Position - Vector3.new(0, foot.Size.Y * 0.5, 0))
			or (root.Position - Vector3.new(0, 3, 0))
		local top = vpToScreen(viewport, cam, topPos)
		local bot = vpToScreen(viewport, cam, botPos)
		if not top or not bot then return end
		local hh = math.abs(bot.Y - top.Y)
		if hh < 8 then return end
		local ww = hh * 0.65
		local cx = (top.X + bot.X) * 0.5
		return cx - ww * 0.5, math.min(top.Y, bot.Y), cx + ww * 0.5, math.max(top.Y, bot.Y), cx
	end

	local R15 = {
		{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
		{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
		{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
		{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
		{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
	}
	local R6 = {
		{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
	}

	local function isPreviewVisible()
		if Library and Library.WindowOpenState == false then
			return false
		end
		local panel, viewport = findPreviewParts()
		if not viewport then return false end
		if panel and panel.Visible == false then return false end
		if viewport.AbsoluteSize.X < 20 then return false end
		-- widget visibility
		local okVis = true
		pcall(function()
			if MethaneESPPreview and MethaneESPPreview.GetFrame then
				local fr = MethaneESPPreview:GetFrame()
				if fr and fr.Visible == false then okVis = false end
			end
		end)
		return okVis
	end

	local function drawPreviewESP()
		local ESP = getgenv().VantaRivalsESP
		if type(ESP) ~= "table" or not isPreviewVisible() then
			hideAll()
			if previewChams then pcall(function() previewChams.Enabled = false end) end
			return
		end

		local panel, viewport, model, cam = findPreviewParts()
		if not viewport or not model or not cam then
			hideAll()
			return
		end

		local minX, minY, maxX, maxY, cx = previewBox(model, viewport, cam)
		if not minX then hideAll() return end
		local w, h = maxX - minX, maxY - minY
		local x, y = minX, minY
		local thick = math.max((ESP.box and ESP.box.thickness) or 1, 1)
		local colTop = (ESP.box and ESP.box.color) or Color3.new(1, 1, 1)
		local colBot = (ESP.box and ESP.box.gradient and ESP.box.color2) or colTop
		local ocol = (ESP.box and ESP.box.outline_color) or Color3.fromRGB(0, 0, 0)
		local useOutline = ESP.box and ESP.box.outline == true
		local gradient = ESP.box and ESP.box.gradient == true

		if ESP.box and ESP.box.enabled then
			if (ESP.box.mode or "Full") == "Corner" then
				drawCornerBox(x, y, w, h, colTop, colBot, thick, useOutline, ocol)
			else
				drawFullBox(x, y, w, h, colTop, colBot, thick, useOutline, ocol, gradient)
			end
			if ESP.box.fill and e.fill then
				e.fill.Visible = true
				e.fill.Filled = true
				e.fill.Position = Vector2.new(x, y)
				e.fill.Size = Vector2.new(w, h)
				e.fill.Color = ESP.box.fill_color or Color3.new(1, 1, 1)
				e.fill.Transparency = typeof(ESP.box.fill_transparency) == "number" and ESP.box.fill_transparency or 0.55
				e.fill.ZIndex = 1
			else
				hide(e.fill)
			end
		else
			for i = 1, 8 do hide(e.corner[i]); hide(e.cornerO[i]) end
			for i = 1, 24 do hide(e.edge[i]); hide(e.edgeO[i]) end
			hide(e.fill)
		end

		-- skeleton (bone projection — previous working approach)
		local sk = ESP.skeleton or {}
		if sk.enabled then
			local bones = model:FindFirstChild("UpperTorso") and R15 or R6
			local skCol = sk.color or Color3.new(1, 1, 1)
			local skCol2 = sk.color2 or skCol
			local skT = math.max(sk.thickness or 1.5, 1)
			local idx = 0
			local n = #bones
			for bi, pair in ipairs(bones) do
				local a = model:FindFirstChild(pair[1])
				local b = model:FindFirstChild(pair[2])
				if a and b then
					local pa = vpToScreen(viewport, cam, a.Position)
					local pb = vpToScreen(viewport, cam, b.Position)
					if pa and pb then
						idx += 1
						local line = e.skel[idx]
						if line then
							line.From = pa; line.To = pb
							line.Color = sk.gradient and lerpColor(skCol, skCol2, bi / math.max(n, 1)) or skCol
							line.Thickness = skT
							line.ZIndex = 2
							line.Visible = true
						end
					end
				end
			end
			for i = idx + 1, 16 do hide(e.skel[i]) end
			if sk.headdot then
				local head = model:FindFirstChild("Head")
				if head and e.head then
					local hp = vpToScreen(viewport, cam, head.Position)
					if hp then
						e.head.Visible = true
						e.head.Position = hp
						e.head.Radius = math.max(sk.headdot_size or 4, 2)
						e.head.Color = sk.headdot_color or Color3.new(1, 1, 1)
					else hide(e.head) end
				else hide(e.head) end
			else hide(e.head) end
		else
			for i = 1, 16 do hide(e.skel[i]) end
			hide(e.head)
		end

		-- health (same as live ESP: Line segments, smooth 3-way gradient)
		local hp = ESP.health or {}
		for i = 1, 16 do hide(e.hp_seg[i]) end
		if hp.enabled then
			local barW = math.max(hp.width or 2, 2)
			local bx = x - barW - 5
			local by = y
			local bh = h
			local barCx = bx + barW * 0.5
			local segs = math.clamp(hp.segments or 12, 4, 16)
			if segs > #e.hp_seg then segs = #e.hp_seg end
			local frac = 1

			if e.hp_bg then
				e.hp_bg.From = Vector2.new(barCx, by)
				e.hp_bg.To = Vector2.new(barCx, by + bh)
				e.hp_bg.Thickness = barW + 2
				e.hp_bg.Color = Color3.fromRGB(0, 0, 0)
				e.hp_bg.Transparency = 1
				e.hp_bg.ZIndex = 1
				e.hp_bg.Visible = true
			end

			local filled = math.floor(segs * frac + 1e-6)
			if frac > 0 and filled < 1 then filled = 1 end
			if frac >= 0.999 then filled = segs end

			for i = 1, filled do
				local seg = e.hp_seg[i]
				if not seg then break end
				local t0 = (i - 1) / segs
				local t1 = i / segs
				local y0 = by + bh - bh * t1
				local y1 = by + bh - bh * t0
				local midT = (t0 + t1) * 0.5
				local col = threeWayColor(
					hp.color_low or Color3.fromRGB(255, 60, 60),
					hp.color_mid or Color3.fromRGB(255, 220, 60),
					hp.color_high or Color3.fromRGB(80, 255, 120),
					midT
				)
				seg.From = Vector2.new(barCx, y0)
				seg.To = Vector2.new(barCx, y1)
				seg.Thickness = barW
				seg.Color = col
				seg.Transparency = 1
				seg.ZIndex = 2
				seg.Visible = true
			end

			if hp.text and e.hp_text then
				-- further left so it never sits on the bar / box
				e.hp_text.Visible = true
				e.hp_text.Text = "100"
				e.hp_text.Size = 12
				e.hp_text.Center = true
				e.hp_text.Outline = true
				e.hp_text.Color = hp.text_color or Color3.new(1, 1, 1)
				e.hp_text.Transparency = 1
				e.hp_text.ZIndex = 3
				e.hp_text.Position = Vector2.new(bx - 14, by)
			else
				hide(e.hp_text)
			end
		else
			hide(e.hp_bg); hide(e.hp_text)
		end

		local flags = ESP.flags or {}
		local nameStr = "Preview"
		pcall(function() if LP then nameStr = LP.DisplayName or LP.Name end end)
		if flags.username and e.name then
			e.name.Visible = true
			e.name.Text = nameStr
			e.name.Color = flags.username_color or Color3.new(1, 1, 1)
			e.name.Position = Vector2.new(cx or (x + w * 0.5), y - 16)
		else hide(e.name) end
		if flags.distance and e.dist then
			e.dist.Visible = true
			e.dist.Text = "[12m]"
			e.dist.Color = flags.distance_color or Color3.fromRGB(200, 200, 200)
			e.dist.Position = Vector2.new(cx or (x + w * 0.5), y + h + 2)
		else hide(e.dist) end
		if flags.weapon and e.wep then
			e.wep.Visible = true
			e.wep.Text = "None"
			e.wep.Color = flags.weapon_color or Color3.new(1, 1, 1)
			e.wep.Position = Vector2.new(cx or (x + w * 0.5), y + h + (flags.distance and 16 or 2))
		else hide(e.wep) end

		local tr = ESP.tracer or {}
		if tr.enabled then
			local vabs = viewport.AbsolutePosition
			local vsize = viewport.AbsoluteSize
			local insetY = 0
			pcall(function() insetY = GuiService:GetGuiInset().Y end)
			local ox = vabs.X + vsize.X * 0.5
			local oy = vabs.Y + insetY + vsize.Y - 2
			if tr.origin == "Top" then oy = vabs.Y + insetY + 2
			elseif tr.origin == "Center" then oy = vabs.Y + insetY + vsize.Y * 0.5 end
			local foot = model:FindFirstChild("LeftFoot") or model:FindFirstChild("HumanoidRootPart")
			local to = foot and vpToScreen(viewport, cam, foot.Position) or Vector2.new(cx, y + h)
			local tthick = math.max(tr.thickness or 1, 1)
			if tr.outline and e.trO then
				e.trO.From = Vector2.new(ox, oy); e.trO.To = to
				e.trO.Color = tr.outline_color or Color3.fromRGB(0, 0, 0)
				e.trO.Thickness = tthick + 1.5
				e.trO.ZIndex = 1
				e.trO.Visible = true
			else hide(e.trO) end
			if e.tr then
				e.tr.From = Vector2.new(ox, oy); e.tr.To = to
				e.tr.Color = tr.color or Color3.new(1, 1, 1)
				e.tr.Thickness = tthick
				e.tr.ZIndex = 2
				e.tr.Visible = true
			end
		else
			hide(e.tr); hide(e.trO)
		end

		local chams = ESP.chams or {}
		if chams.enabled then
			if not previewChams or previewChams.Parent ~= model then
				if previewChams then pcall(function() previewChams:Destroy() end) end
				previewChams = Instance.new("Highlight")
				previewChams.Name = "MethanePreviewChams"
				previewChams.Parent = model
			end
			previewChams.Adornee = model
			previewChams.FillColor = chams.fill_color or Color3.new(1, 1, 1)
			previewChams.OutlineColor = chams.outline_color or Color3.new(1, 1, 1)
			previewChams.FillTransparency = typeof(chams.fill_transparency) == "number" and chams.fill_transparency or 0.5
			previewChams.OutlineTransparency = typeof(chams.outline_transparency) == "number" and chams.outline_transparency or 0
			previewChams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			previewChams.Enabled = true
		elseif previewChams then
			previewChams.Enabled = false
		end
	end

	game:GetService("RunService").RenderStepped:Connect(function()
		pcall(drawPreviewESP)
	end)

	pcall(function()
		if Library and Library.BindToWindowVisibility then
			Library:BindToWindowVisibility(function(isOpen)
				if not isOpen then
					hideAll()
					if previewChams then pcall(function() previewChams.Enabled = false end) end
				end
			end)
		end
	end)
end)

-- Settings page (configs + MTH share strings)
pcall(function()
	Library_Window:CreateSettingsPage()
end)

-- Auto-load selected config from previous "Set Auto Load"
task.spawn(function()
	task.wait(0.75) -- let all flags / UI finish binding
	pcall(function()
		local folder = tostring(Library.Directory or "MethaneUI")
			.. tostring(Library.Folders and Library.Folders.Configs or "/methane/cfgs/rivals")
			.. "/"
		if not isfile or not isfile(folder .. "autoload.txt") then return end
		local name = tostring(readfile(folder .. "autoload.txt") or "")
			:gsub("^%s+", ""):gsub("%s+$", "")
		if name == "" then return end
		local path = folder .. name .. ".json"
		if not isfile(path) then
			pcall(function()
				Library:Notification("Auto load missing: " .. name, 3, Color3.fromRGB(255, 0, 0))
			end)
			return
		end
		local content = readfile(path)
		local ok, err = Library:LoadConfig(content)
		if ok then
			pcall(function()
				if getgenv().MethaneRefreshAutoloadLabel then
					getgenv().MethaneRefreshAutoloadLabel()
				end
				Library:Notification("Auto-loaded: " .. name, 3, Color3.fromRGB(0, 255, 0))
			end)
		else
			pcall(function()
				Library:Notification("Auto load failed: " .. tostring(err), 3, Color3.fromRGB(255, 0, 0))
			end)
		end
	end)
end)

-- Mouse: menu open = hide system cursor + show custom; close = restore game mouse
do
	local UIS = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local savedMB, savedMI
	local cursorConn

	local function showCustomCursor()
		pcall(function()
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = false
			local cur = Library.MouseCursor and Library.MouseCursor.Instance
			if cur then
				cur.Visible = true
				cur.ZIndex = 2147483647
				if cur.Parent and cur.Parent:IsA("LayerCollector") then
					pcall(function() cur.Parent.DisplayOrder = 999999 end)
				end
			end
		end)
	end

	local function hideCustomCursor()
		pcall(function()
			local cur = Library.MouseCursor and Library.MouseCursor.Instance
			if cur then cur.Visible = false end
		end)
	end

	local function startCursorGuard()
		if cursorConn then return end
		cursorConn = RunService.RenderStepped:Connect(function()
			if not Library.WindowOpenState then return end
			-- force system cursor off every frame while menu is open
			pcall(function()
				if UIS.MouseIconEnabled then
					UIS.MouseIconEnabled = false
				end
				local cur = Library.MouseCursor and Library.MouseCursor.Instance
				if cur then
					if not cur.Visible then cur.Visible = true end
					local pos = UIS:GetMouseLocation()
					-- library also positions it; keep visible
					cur.ZIndex = 2147483647
				end
			end)
		end)
	end

	local function stopCursorGuard()
		if cursorConn then
			cursorConn:Disconnect()
			cursorConn = nil
		end
	end

	pcall(function()
		local oldSet = Library.SetWindowVisibilityState
		if type(oldSet) ~= "function" then return end
		Library.SetWindowVisibilityState = function(self, bool)
			if bool then
				pcall(function()
					savedMB = UIS.MouseBehavior
					savedMI = UIS.MouseIconEnabled
				end)
				local ok, res = pcall(oldSet, self, true)
				showCustomCursor()
				startCursorGuard()
				Library.MouseStateBeforeOpen = nil
				if ok then return res end
			else
				stopCursorGuard()
				local ok, res = pcall(oldSet, self, false)
				hideCustomCursor()
				pcall(function()
					if savedMB ~= nil then UIS.MouseBehavior = savedMB end
					if savedMI ~= nil then
						UIS.MouseIconEnabled = savedMI
					else
						UIS.MouseIconEnabled = false
					end
				end)
				Library.MouseStateBeforeOpen = nil
				if ok then return res end
			end
		end
	end)

	-- if menu already open on inject
	if Library.WindowOpenState then
		showCustomCursor()
		startCursorGuard()
	end
end

----------------------------------------------------------------
-- MOVEMENT + THIRD PERSON / FREECAM
----------------------------------------------------------------
do
	local UIS = game:GetService("UserInputService")
	local MOVE = {
		speed = false, speed_value = 49,
		fly = false, fly_speed = 50,
		inf_jump = false, bhop = false, noclip = false,
	}
	getgenv().MethaneMove = MOVE

	pcall(function() MovePlayer:AddSection("Walkspeed", ico("gauge")) end)
	bindToggleKey(MovePlayer, "MoveSpeed", "Enabled", false, function(v) MOVE.speed = v end)
	bindSlider(MovePlayer, "MoveSpeedValue", "Speed", 49, 16, 120, 0, function(v) MOVE.speed_value = v end, "m/s")
	pcall(function() MovePlayer:AddDivider() end)
	pcall(function() MovePlayer:AddSection("Jump", ico("arrow-up-from-line")) end)
	bindToggleKey(MovePlayer, "MoveInfJump", "Inf Jump", false, function(v) MOVE.inf_jump = v end)
	bindToggle(MovePlayer, "MoveBhop", "Bhop", false, function(v) MOVE.bhop = v end)
	pcall(function() MovePlayer:AddSection("Fly", ico("plane")) end)
	bindToggleKey(MovePlayer, "MoveFly", "Enabled", false, function(v) MOVE.fly = v end)
	bindSlider(MovePlayer, "MoveFlySpeed", "Fly Speed", 50, 20, 150, 0, function(v) MOVE.fly_speed = v end, "m/s")
	pcall(function() MovePlayer:AddDivider() end)
	pcall(function() MovePlayer:AddSection("Noclip", ico("ghost")) end)
	bindToggleKey(MovePlayer, "MoveNoclip", "Noclip", false, function(v) MOVE.noclip = v end)

	local lastInfJumpTime = 0
	UIS.JumpRequest:Connect(function()
		if not MOVE.inf_jump then return end
		local now = tick()
		if now - lastInfJumpTime < 0.25 then return end
		lastInfJumpTime = now
		local char = LP.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
	end)

	local flyBV, flyBG
	local lastBhopJumpTime = 0
	local lastNoclipParts = {}
	local freecamConn, freecamPart
	local freecamRotX, freecamRotY = 0, 0

	RunService.RenderStepped:Connect(function(dt)
		-- skip entirely when no movement feature is on
		if not (MOVE.speed or MOVE.fly or MOVE.inf_jump or MOVE.bhop or MOVE.noclip) then
			return
		end
		local char = LP.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local cam = workspace.CurrentCamera
		if not root or not hum then
			if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
			if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
			return
		end

		if MOVE.speed then
			local target = tonumber(MOVE.speed_value) or 32
			hum.WalkSpeed = target
			local moveDir = hum.MoveDirection
			if moveDir.Magnitude > 0.05 then
				local extra = math.max(0, target - 16)
				if extra > 0 then
					root.CFrame = root.CFrame + (moveDir.Unit * (extra * dt))
				end
			end
		end

		if MOVE.fly and cam then
			if not flyBV or flyBV.Parent ~= root then
				if flyBV then pcall(function() flyBV:Destroy() end) end
				flyBV = Instance.new("BodyVelocity")
				flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
				flyBV.Parent = root
			end
			if not flyBG or flyBG.Parent ~= root then
				if flyBG then pcall(function() flyBG:Destroy() end) end
				flyBG = Instance.new("BodyGyro")
				flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
				flyBG.P = 9e4
				flyBG.Parent = root
			end
			local camCF = cam.CFrame
			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + camCF.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - camCF.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - camCF.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + camCF.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
			flyBG.CFrame = camCF
			flyBV.Velocity = (dir.Magnitude > 0) and (dir.Unit * (tonumber(MOVE.fly_speed) or 50)) or Vector3.zero
		else
			if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
			if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
		end

		if MOVE.bhop and UIS:IsKeyDown(Enum.KeyCode.Space) then
			if hum.FloorMaterial ~= Enum.Material.Air then
				local now = tick()
				if now - lastBhopJumpTime > 0.08 then
					lastBhopJumpTime = now
					hum.Jump = true
				end
			end
		end

		-- Third person
		if world.third_person and cam and not world.freecam then
			pcall(function()
				cam.CameraType = Enum.CameraType.Custom
				local dist = tonumber(world.third_dist) or 12
				local look = cam.CFrame.LookVector
				local pos = root.Position - look * dist + Vector3.new(0, 2, 0)
				cam.CFrame = CFrame.new(pos, root.Position + Vector3.new(0, 1.5, 0))
			end)
		end
	end)

	RunService.Stepped:Connect(function()
		local char = LP.Character
		if not char then return end
		if MOVE.noclip then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					lastNoclipParts[part] = true
					part.CanCollide = false
				end
			end
		else
			for part in pairs(lastNoclipParts) do
				if part and part.Parent then pcall(function() part.CanCollide = true end) end
				lastNoclipParts[part] = nil
			end
		end
	end)

	-- Freecam loop
	local function stopFreecam()
		if freecamConn then freecamConn:Disconnect(); freecamConn = nil end
		if freecamPart then pcall(function() freecamPart:Destroy() end); freecamPart = nil end
		pcall(function()
			local cam = workspace.CurrentCamera
			if cam then cam.CameraType = Enum.CameraType.Custom end
		end)
	end
	local function startFreecam()
		stopFreecam()
		local cam = workspace.CurrentCamera
		if not cam then return end
		local pos = cam.CFrame.Position
		local look = cam.CFrame.LookVector
		freecamRotY = math.atan2(-look.X, -look.Z)
		freecamRotX = math.asin(math.clamp(look.Y, -1, 1))
		freecamPart = Instance.new("Part")
		freecamPart.Anchored = true
		freecamPart.CanCollide = false
		freecamPart.Transparency = 1
		freecamPart.Size = Vector3.new(1, 1, 1)
		freecamPart.CFrame = CFrame.new(pos)
		freecamPart.Parent = workspace
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CameraSubject = freecamPart
		freecamConn = RunService.RenderStepped:Connect(function(dt)
			if not world.freecam then
				stopFreecam()
				return
			end
			local cam2 = workspace.CurrentCamera
			if not cam2 or not freecamPart then return end
			local delta = UIS:GetMouseDelta()
			freecamRotY = freecamRotY - delta.X * 0.004
			freecamRotX = math.clamp(freecamRotX - delta.Y * 0.004, -1.4, 1.4)
			local cf = CFrame.new(freecamPart.Position) * CFrame.Angles(0, freecamRotY, 0) * CFrame.Angles(freecamRotX, 0, 0)
			local dir = Vector3.zero
			local spd = (tonumber(world.freecam_speed) or 40) * dt
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
			if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
			if dir.Magnitude > 0 then
				freecamPart.CFrame = CFrame.new(freecamPart.Position + dir.Unit * spd)
			end
			cam2.CFrame = CFrame.new(freecamPart.Position) * CFrame.Angles(0, freecamRotY, 0) * CFrame.Angles(freecamRotX, 0, 0)
		end)
	end

	-- watch freecam toggle
	task.spawn(function()
		local last = false
		while true do
			task.wait(0.1)
			local on = world.freecam == true
			if on and not last then startFreecam() end
			if not on and last then stopFreecam() end
			last = on
		end
	end)

	LP.CharacterAdded:Connect(function()
		if flyBV then pcall(function() flyBV:Destroy() end); flyBV = nil end
		if flyBG then pcall(function() flyBG:Destroy() end); flyBG = nil end
		(function(t) if type(t)=="table" then for k in pairs(t) do t[k]=nil end end end)(lastNoclipParts)
	end)
end

getgenv().AtomicRivals = { skin = skin, modules = modules }
pcall(function()
	Library:Notification("Rivals", 3, Library.Theme and Library.Theme.Accent)
	task.delay(0.4, function()
		pcall(function()
			Library:Notification("successfully loaded..", 3, Library.Theme and Library.Theme.Accent)
		end)
	end)
end)
