--[[
  Methane | Bloxstrike
  MethaneUI | logo rbxassetid://72404794660074
]]

do
	local ok = pcall(function()
		if game.IsLoaded and not game:IsLoaded() then game.Loaded:Wait() end
	end)
	if not ok then repeat task.wait() until game:IsLoaded() end
	pcall(function()
		local LP = game:GetService("Players").LocalPlayer
		if LP then pcall(function() LP:WaitForChild("PlayerGui", 15) end) end
	end)
	task.wait(0.15)
end
pcall(function() if setfpscap then setfpscap(0) end end)

local function mapFsPath(path)
	path = tostring(path or "")
	if path == "MethaneUI" or path:sub(1, 7) == "MethaneUI/" or path:sub(1, 7) == "MethaneUI\\" then
		path = "MethaneUI/UI" .. path:sub(7)
	end
	return path:gsub("[Aa]ssistant", "Chat")
end
do
	if type(isfolder) == "function" then local _=isfolder; isfolder=function(p,...) return _(mapFsPath(p),...) end end
	if type(makefolder) == "function" then local _=makefolder; makefolder=function(p,...) return _(mapFsPath(p),...) end end
	if type(isfile) == "function" then local _=isfile; isfile=function(p,...) return _(mapFsPath(p),...) end end
	if type(readfile) == "function" then local _=readfile; readfile=function(p,...) return _(mapFsPath(p),...) end end
	if type(writefile) == "function" then local _=writefile; writefile=function(p,...) return _(mapFsPath(p),...) end end
end

local Library
do
	local ok, lib = pcall(function()
		-- always re-load library so SubPage debounce patch is applied
		getgenv().MethaneLibrary = nil
		local src = game:HttpGet("https://raw.githubusercontent.com/iskasaputri020-wq/UI-LIB/refs/heads/main/library.lua")
		if type(src) ~= "string" or #src < 1000 then error("HttpGet failed") end
		src = src:gsub('Items = { "Neutral", "Enemy", "Friendly" }', 'Items = { "Neutral", "Priority", "Whitelist" }')
		src = src:gsub('Value == "Enemy"', 'Value == "Priority"')
		src = src:gsub('Value == "Friendly"', 'Value == "Whitelist"')
		src = src:gsub('for Index, Value in Players:GetPlayers() do', 'for Index, Value in ipairs(Players:GetPlayers()) do')
		src = src:gsub('for Index, Value in Playerlist.Players do', 'for Index, Value in pairs(Playerlist.Players) do')
		src = src:gsub(
			'Library:SafeCall(Playerlist.Callback, Playerlist.Selected)',
			'if Playerlist.Callback then Library:SafeCall(Playerlist.Callback, Playerlist.Selected) end'
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
			'for Index, Value in Playerlist.Players do\n                            if Value ~= PlayerData then\n                                Value.IsSelected = false\n                                Value:ToggleState("Inactive")\n                            end\n                        end',
			'-- multi-select'
		)
				-- Fix rapid SubPage switching blank content
		src = src:gsub(
			[[if Debounce then
                    -- still force visibility parent switch without waiting previous fade
                    if Bool then
                        Items["Page"].Instance.Visible = true
                        Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                    end
                    return
                end]],
			[[if Debounce then
                    Items["Page"].Instance.Visible = Bool == true
                    if Bool then
                        Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                    else
                        Items["Page"].Instance.Parent = Library.UnusedHolder.Instance
                    end
                    return
                end]]
		)
		src = src:gsub(
			[[Debounce = true

                Items["Page"]:FadeDescendants(Bool, function()
                    Debounce = false

                    if Items["Page"].Instance.Visible then
                        Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                    else
                        Items["Page"].Instance.Parent = Library.UnusedHolder.Instance
                    end
                end)]],
			[[Debounce = true
                Items["Page"].Instance.Visible = Bool == true
                if Bool then
                    Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                else
                    Items["Page"].Instance.Parent = Library.UnusedHolder.Instance
                end
                Items["Page"]:FadeDescendants(Bool, function()
                    Debounce = false
                    if Page.Active then
                        Items["Page"].Instance.Visible = true
                        Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                    else
                        Items["Page"].Instance.Visible = false
                        Items["Page"].Instance.Parent = Library.UnusedHolder.Instance
                    end
                end)]]
		)

				-- TargetIndicator: full SetTarget rewrite (Bloxstrike HP is attributes, not Humanoid)
		do
			local setTargetOld = [[function Indicator:SetTarget(Target)
                Indicator:ResetConnection()

                if not Target then
                    Items["Name"].Instance.Text = "No target selected"
                    Items["Avatar"].Instance.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                    Items["Value"].Instance.Text = "0/0"
                    Items["HealthbarFill"]:Tween({ Size = UDim2.new(0, 0, 1, 0) })
                    return false
                end

                local Name = Target.Name

                Items["Name"].Instance.Text = Name
                Items["Avatar"].Instance.Image = Players:GetUserThumbnailAsync(Target.UserId, Enum.ThumbnailType
                    .HeadShot, Enum.ThumbnailSize.Size420x420)

                local Character = Target.Character
                local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if not Humanoid then
                    Items["Value"].Instance.Text = "0/0"
                    Items["HealthbarFill"]:Tween({ Size = UDim2.new(0, 0, 1, 0) })
                    return false
                end

                BoundTarget = Target
                BoundHumanoid = Humanoid

                local function UpdateHealth(Health)
                    if BoundTarget ~= Target or BoundHumanoid ~= Humanoid then
                        return
                    end
                    local MaxHealth = Humanoid.MaxHealth
                    local SafeMaxHealth = math.max(MaxHealth, 1)
                    local SafeHealth = math.max(Health, 0)
                    local DisplayHealth = math.floor(SafeHealth + 0.5)
                    local DisplayMaxHealth = math.floor(math.max(MaxHealth, 0) + 0.5)

                    Items["Value"].Instance.Text = DisplayHealth .. "/" .. DisplayMaxHealth

                    local HealthPercent = math.clamp(SafeHealth / SafeMaxHealth, 0, 1)
                    Items["HealthbarFill"]:Tween({ Size = UDim2.new(HealthPercent, 0, 1, 0) })
                end

                UpdateHealth(Humanoid.Health)
                HealthConnection = Humanoid.HealthChanged:Connect(UpdateHealth)
                return true
            end]]

			local setTargetNew = [[function Indicator:SetTarget(Target)
                Indicator:ResetConnection()
                Indicator.Items = Items

                local function applyHP(h, m)
                    h = tonumber(h) or 0
                    m = tonumber(m) or 100
                    if m <= 0 then m = 100 end
                    local text = tostring(math.floor(h + 0.5)) .. "/" .. tostring(math.floor(m + 0.5))
                    local pct = math.clamp(h / m, 0, 1)
                    pcall(function()
                        Items["Value"].Instance.Text = text
                        Items["Value"].Instance.Visible = true
                        Items["HealthbarFill"].Instance.Size = UDim2.new(pct, 0, 1, 0)
                        Items["HealthbarFill"].Instance.BackgroundTransparency = 0
                        Items["HealthbarFill"].Instance.Visible = true
                    end)
                end

                function Indicator:SetHealth(h, m)
                    applyHP(h, m)
                end

                if not Target then
                    Items["Name"].Instance.Text = "No target selected"
                    Items["Avatar"].Instance.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
                    applyHP(0, 100)
                    return false
                end

                local Name = Target.Name or "Unknown"
                Items["Name"].Instance.Text = Name

                -- avatar async (do not yield SetTarget — prevents HUD flash)
                local uid = 0
                pcall(function() uid = Target.UserId end)
                if type(uid) == "number" and uid > 0 then
                    task.spawn(function()
                        local ok, img = pcall(function()
                            return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
                        end)
                        if ok and img and BoundTarget == Target then
                            pcall(function() Items["Avatar"].Instance.Image = img end)
                        end
                    end)
                end

                BoundTarget = Target
                local Character = nil
                pcall(function() Character = Target.Character end)
                if not Character and typeof(Target) == "Instance" and Target:IsA("Model") then
                    Character = Target
                end

                local function readHP()
                    local ch = Character
                    pcall(function()
                        if BoundTarget and BoundTarget.Character then ch = BoundTarget.Character end
                    end)
                    if not ch then return 0, 100 end
                    local hh = ch:GetAttribute("Health")
                    if type(hh) ~= "number" then hh = ch:GetAttribute("HP") end
                    local mm = ch:GetAttribute("MaxHealth")
                    if type(mm) ~= "number" then mm = ch:GetAttribute("MaxHP") end
                    if type(hh) == "number" then
                        if type(mm) ~= "number" or mm <= 0 then mm = 100 end
                        return hh, mm
                    end
                    local hum = ch:FindFirstChildOfClass("Humanoid")
                    if hum and hum.MaxHealth > 0 then
                        return hum.Health, hum.MaxHealth
                    end
                    return 0, 100
                end

                local function UpdateHealth()
                    if BoundTarget ~= Target then return end
                    applyHP(readHP())
                end

                UpdateHealth()
                BoundHumanoid = Character and Character:FindFirstChildOfClass("Humanoid")
                if BoundHumanoid then
                    HealthConnection = BoundHumanoid.HealthChanged:Connect(function()
                        UpdateHealth()
                    end)
                end
                pcall(function()
                    if Character then
                        Character:GetAttributeChangedSignal("Health"):Connect(UpdateHealth)
                        Character:GetAttributeChangedSignal("HP"):Connect(UpdateHealth)
                    end
                end)
                return true
            end]]

			if src:find("function Indicator:SetTarget%(Target%)", 1, false) then
				-- plain find + replace full function by matching start to "return true\n            end" after SetTarget
				local a, b = src:find("function Indicator:SetTarget%(Target%)")
				if a then
					local c = src:find("function Indicator:AddItem", a)
					if c then
						src = src:sub(1, a - 1) .. setTargetNew .. "\n\n            " .. src:sub(c)
					end
				end
			end
		end
		
		-- Auto-load buttons in Configs (same as Rivals)
		do
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
                            elseif lab.SetName then
                                lab:SetName(text)
                            elseif type(lab) == "table" and lab.Instance then
                                lab.Instance.Text = text
                            end
                        end)
                    end
                    pcall(function() getgenv().MethaneRefreshAutoloadLabel() end)
                end

                local ShareSection = ConfigsSubPage:Section({ Name = "Share", Side = 2 })
]=]
			local i1, i2 = string.find(src, anchor, 1, true)
			if i1 then
				src = string.sub(src, 1, i1 - 1) .. auto .. string.sub(src, i2 + 1)
			else
				-- alternate anchors
				local a2 = 'Library:GetConfigsList(ConfigsDropdown)'
				local j = string.find(src, a2, 1, true)
				if j then
					local k = string.find(src, 'ShareSection', j, true)
					if k then
						-- insert before Share if possible
						local insertAt = string.find(src, '\n', j + #a2)
					end
				end
			end
		end


		local fn, err = loadstring(src)


		if not fn then error(tostring(err)) end
		return fn()
	end)
	if not (ok and lib) then
		getgenv().MethaneLibrary = nil
		error("[Methane] UI failed: " .. tostring(lib))
	end
	Library = lib
end
getgenv().MethaneLibrary = Library
_G.Library = Library

local LOGO = "rbxassetid://72404794660074"
local Options, Toggles = {}, {}
getgenv().Options = Options
getgenv().Toggles = Toggles

local PlayerFlags = { whitelist = {}, priority = {} }
getgenv().MethanePlayerFlags = PlayerFlags
local function isWhitelisted(plr) return plr and PlayerFlags.whitelist[plr.UserId] == true end
local function isPrioritized(plr) return plr and PlayerFlags.priority[plr.UserId] == true end
local function syncPlayerFlagsFromList(playerlist)
	if not playerlist or type(playerlist.Players) ~= "table" then return end
	for k in pairs(PlayerFlags.whitelist) do PlayerFlags.whitelist[k] = nil end
	for k in pairs(PlayerFlags.priority) do PlayerFlags.priority[k] = nil end
	for _, data in pairs(playerlist.Players) do
		local plr = data and data.Player
		local st = tostring((data and data.Status) or "Neutral")
		if plr and plr.UserId then
			if st == "Whitelist" or st == "Friendly" then PlayerFlags.whitelist[plr.UserId] = true
			elseif st == "Priority" or st == "Enemy" then PlayerFlags.priority[plr.UserId] = true end
		end
	end
end

Library.Brand = "methane"
Library.GameName = "bloxstrike"
pcall(function() Library:EnsureConfigFolders() end)
pcall(function() Library.Theme.Accent = Color3.fromRGB(152, 188, 255) end)

local function ico(name)
	local id
	pcall(function() id = Library:ResolveIcon(tostring(name or "circle")) end)
	return (type(id) == "string" and id ~= "" and id) or "rbxassetid://0"
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local LP = Players.LocalPlayer
local LocalPlayer = LP

local Library_Window = Library:Window({
	Title = "Methane",
	ButtonName = "Bloxstrike",
	BrandName = "Methane",
	BrandAlign = "Center",
	Logo = LOGO,
})

pcall(function()
	local WM = Library:Watermark({ Name = "METHANE.LUA" })
	WM:SetDynamicTextProvider(function(fps)
		local ms = 0
		pcall(function() ms = math.floor((LP:GetNetworkPing() or 0) * 1000 + 0.5) end)
		if ms < 0 then ms = 0 end
		return string.format("METHANE.LUA | BLOXSTRIKE | %s FPS | %s MS | BUILD: v1.00", tostring(fps or 0), tostring(ms))
	end)
	pcall(function() WM:SetVisibility(true) end)
	getgenv().MethaneWatermark = WM
end)

getgenv().MethaneBloxstrike = { Window = Library_Window, Library = Library }
getgenv().Library = Library
-- KeybindList MUST exist before any Toggle:Keybind so entries register in the list
pcall(function()
	local MethaneKeybindList = Library:KeybindList({ Name = "Keybinds" })
	if MethaneKeybindList and MethaneKeybindList.SetVisibility then MethaneKeybindList:SetVisibility(true) end
	Library:RegisterSettingsWidget({ Name = "Keybind List", Default = true, Callback = function(v)
		if MethaneKeybindList then MethaneKeybindList:SetVisibility(v) end
	end })
	getgenv().MethaneKeybindList = MethaneKeybindList
end)
-- Vind/Obsidian-compat shim used by original logic
getgenv().VantaBloxstrike = getgenv().MethaneBloxstrike
getgenv().VantaNotify = function() end

local function makeTab(name) return Library_Window:Page({ Name = name }) end

local function makeSub(page, name, iconName)
	local sub = page:SubPage({ Name = name, Icon = ico(iconName or "circle") })
	local side, current = 1, nil
	local api = {}
	local function ensure(secName)
		if not current then
			current = sub:Section({ Name = tostring(secName or "General"), Side = 1 })
			side = 2
			return current
		end
		current = sub:Section({ Name = tostring(secName or "Section"), Side = side })
		side = (side == 1) and 2 or 1
		return current
	end
	function api:AddSection(n, _) return ensure(n) end
	function api:AddDivider() end
	function api:AddLineText(_) end
	function api:SelectSubTab(_) end
	local function need()
		if not current then ensure("General") end
		return current
	end
	function api:AddToggle(opts)
		opts = opts or {}
		return need():Toggle({
			Name = opts.Text or opts.Name or "Toggle", Flag = opts.Flag,
			Default = opts.Default == true, Risky = opts.Risky == true,
			Callback = opts.Callback or function() end,
		})
	end
	function api:AddSlider(opts)
		opts = opts or {}
		local inc = opts.Increment or 1
		local dec = 0
		if type(inc) == "number" then
			if inc <= 0.001 then dec = 0.001 elseif inc <= 0.01 then dec = 0.01 elseif inc <= 0.1 then dec = 0.1 end
		end
		return need():Slider({
			Name = opts.Text or opts.Name or "Slider", Flag = opts.Flag,
			Default = opts.Default or 0, Min = opts.Min or 0, Max = opts.Max or 100,
			Decimals = dec, Suffix = opts.Suffix or "", Callback = opts.Callback or function() end,
		})
	end
	function api:AddDropdown(opts)
		opts = opts or {}
		return need():Dropdown({
			Name = opts.Text or opts.Name or "Dropdown", Flag = opts.Flag,
			Items = opts.Options or opts.Items or { "(none)" }, Default = opts.Default,
			Multi = opts.Multi == true, Callback = opts.Callback or function() end,
		})
	end
	function api:AddButton(opts)
		opts = opts or {}
		return need():Button({ Name = opts.Text or opts.Name or "Button", Callback = opts.Callback or function() end })
	end
	function api:AddTextbox(opts)
		opts = opts or {}
		local box = need():Textbox({
			Name = opts.Text or opts.Name or "Text",
			Flag = opts.Flag,
			Default = opts.Default or "",
			Placeholder = opts.Placeholder or "...",
			Numeric = opts.Numeric == true,
			Finished = opts.Finished == true,
			Callback = opts.Callback or function() end,
		})
		-- mirror into Options so ov()/flagStr work
		pcall(function()
			if opts.Flag then
				Options[opts.Flag] = Options[opts.Flag] or {}
				Options[opts.Flag].Value = opts.Default or ""
				if box and type(box) == "table" then
					-- keep Value in sync if library exposes it
					local oldCb = opts.Callback or function() end
				end
			end
		end)
		return box
	end
	function api:AddColorPicker(opts)
		opts = opts or {}
		local lab = need():Label({ Name = opts.Text or opts.Name or "Color" })
		return lab:Colorpicker({
			Flag = opts.Flag, Default = opts.Default or Color3.new(1,1,1),
			Callback = function(c, a) if opts.Callback then pcall(opts.Callback, c, a) end end,
		})
	end
	function api:AddLabel(text) return need():Label({ Name = tostring(text or "") }) end
	return api
end

-- Flag helpers (Library.Flags + Options fallback) — used by original tv/ov
local function flagBool(flag, default)
	local f = Library.Flags and Library.Flags[flag]
	if f == nil then
		local o = Options[flag]
		if o and o.Value ~= nil then return o.Value == true end
		return default == true
	end
	if type(f) == "boolean" then return f end
	if type(f) == "table" and f.Value ~= nil then return f.Value == true end
	return default == true
end
local function flagNum(flag, default)
	local f = Library.Flags and Library.Flags[flag]
	if type(f) == "number" then return f end
	if type(f) == "table" and type(f.Value) == "number" then return f.Value end
	local o = Options[flag]
	if o and type(o.Value) == "number" then return o.Value end
	return default
end
local function flagStr(flag, default)
	local f = Library.Flags and Library.Flags[flag]
	if type(f) == "string" then return f end
	if type(f) == "table" then
		if type(f.Value) == "string" then return f.Value end
		if f[1] then return tostring(f[1]) end
	end
	local o = Options[flag]
	if o and o.Value ~= nil then return tostring(o.Value) end
	return default
end
local function flagColor(flag, default)
	local f = Library.Flags and Library.Flags[flag]
	if typeof(f) == "Color3" then return f end
	if type(f) == "table" and typeof(f.Color) == "Color3" then return f.Color end
	if type(f) == "table" and typeof(f.Value) == "Color3" then return f.Value end
	local o = Options[flag]
	if o and typeof(o.Value) == "Color3" then return o.Value end
	return default
end

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
			mute = true
			self.Value = v
			Options[flag] = Options[flag] or {}; Options[flag].Value = v
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

-- ============================================================
-- KEYBINDS
-- Library Toggle:Keybind = picker UI + KeybindList only
-- Actual on/off is OUR InputBegan (GPE ignored) → Toggle:Set
-- Never put the flip in Keybind Callback AND InputBegan (double-flip = no-op)
-- ============================================================
local KeyedToggles = {} -- flag -> { tog, kb, name }

local function normKey(s)
	s = tostring(s or "")
	s = s:gsub("^Enum%.", ""):gsub("^KeyCode%.", ""):gsub("^UserInputType%.", "")
	return s
end

local KEYBIND_LIST_NAMES = {
	SilentAim = "Silent Aim",
	Ragebot = "Ragebot",
	AntiAim = "Anti Aim",
	Aimbot = "Aimbot",
	Triggerbot = "Triggerbot",
	ESPMaster = "ESP",
	ESPBox = "Box ESP",
	ESPChams = "Chams",
	WorldThirdPerson = "3rd Person",
	MovBhop = "Bhop",
}

local function bindToggleKey(page, flag, text, default, cb, risky)
	local tog = bindToggle(page, flag, text, default, cb, risky)
	flag = tostring(flag)
	-- UI can say "Enabled"; list should show the feature name
	local listName = KEYBIND_LIST_NAMES[flag]
	if not listName then
		if text and text ~= "Enabled" and text ~= "Enable" then
			listName = tostring(text)
		else
			listName = flag
		end
	end
	local entry = { tog = tog, kb = nil, name = listName }
	KeyedToggles[flag] = entry

	local ok, err = pcall(function()
		assert(tog and type(tog.Keybind) == "function", "Toggle:Keybind missing")
		-- Default forces Mode=Toggle inside CreateKeybind
		-- Name is what KeybindList displays: "V - 3rd Person - Toggle"
		local kb = tog:Keybind({
			Name = listName,
			Flag = flag .. "Key",
			Mode = "Toggle",
			Default = Enum.KeyCode.E,
			Callback = function() end, -- intentional: flip is owned by InputBegan only
		})
		entry.kb = kb
		if kb then
			kb.Mode = "Toggle"
			pcall(function() if kb.SetMode then kb:SetMode("Toggle") end end)
			-- None until user picks (Backspace / rebind in UI)
			pcall(function()
				if kb.Set then kb:Set({ Mode = "Toggle", Key = "None", Toggled = false }) end
			end)
		end
	end)
	if not ok then
		warn("[Methane] Keybind attach failed:", flag, err)
	end
	return tog
end

do
	local UIS = game:GetService("UserInputService")

	-- Library KeybindList:SetStatus(Keybind.Toggled) — entry only visible when Toggled.
	-- Keep Toggled true whenever a real key is bound so the list always shows configured binds.
	local function forceListVisible(kb)
		if not kb then return end
		local key = kb.Key
		if not key or key == "" or key == "None" or key == "Unknown" then return end
		kb.Toggled = true
		pcall(function()
			if kb.Set then
				kb:Set({ Mode = kb.Mode or "Toggle", Key = key, Toggled = true })
			end
		end)
	end

	UIS.InputBegan:Connect(function(input, _gpe)
		if UIS:GetFocusedTextBox() then return end
		local pressedEnum = input.KeyCode
		if pressedEnum == Enum.KeyCode.Unknown then
			pressedEnum = input.UserInputType
		end
		local pressed = normKey(pressedEnum)
		if pressed == "" or pressed == "Unknown" then return end

		for flag, data in pairs(KeyedToggles) do
			local key = data.kb and data.kb.Key
			if (not key or key == "" or key == "None") and Library and Library.Flags then
				local f = Library.Flags[flag .. "Key"]
				if type(f) == "table" then key = f.Key end
			end
			if not key or key == "None" or key == "" or key == "Unknown" then
				continue
			end
			if normKey(key) == pressed then
				local tog = data.tog
				if tog and type(tog.Set) == "function" then
					tog:Set(not (tog.Value == true))
				end
				forceListVisible(data.kb)
			end
		end
	end)

	-- When user assigns a key in the picker, push it onto the list
	task.spawn(function()
		while true do
			task.wait(0.35)
			for flag, data in pairs(KeyedToggles) do
				pcall(function() forceListVisible(data.kb) end)
			end
		end
	end)
end

local function bindSlider(page, flag, text, default, min, max, rounding, cb, suffix)
	local inc = 1
	if rounding == 1 then inc = 0.1 elseif rounding == 2 then inc = 0.01 elseif rounding == 3 then inc = 0.001 end
	page:AddSlider({
		Text = text, Flag = flag, Default = default, Min = min, Max = max, Increment = inc, Suffix = suffix or "",
		Callback = function(v)
			Options[flag] = Options[flag] or {}; Options[flag].Value = v
			if cb then pcall(cb, v) end
		end,
	})
	Options[flag] = { Value = default }
end
local function bindDropdown(page, flag, text, values, default, cb)
	local ctrl
	pcall(function()
		ctrl = page:AddDropdown({
			Text = text, Flag = flag, Options = values, Default = default or values[1],
			Callback = function(v)
				Options[flag] = Options[flag] or {}; Options[flag].Value = v
				if Options[flag] then Options[flag].Value = v end
				if cb then pcall(cb, v) end
			end,
		})
	end)
	Options[flag] = {
		Value = default or values[1],
		Control = ctrl,
		SetValues = function(self, list)
			list = list or { "(none)" }
			self._values = list
			pcall(function()
				if ctrl then
					if ctrl.SetValues then ctrl:SetValues(list)
					elseif ctrl.SetOptions then ctrl:SetOptions(list)
					elseif ctrl.Refresh then ctrl:Refresh(list)
					elseif ctrl.Items ~= nil then
						-- library dropdown may use Items field
						pcall(function() ctrl:Set(list[1]) end)
					end
				end
			end)
		end,
		SetValue = function(self, v)
			self.Value = v
			pcall(function()
				if ctrl and ctrl.SetValue then ctrl:SetValue(v)
				elseif ctrl and ctrl.Set then ctrl:Set(v) end
			end)
		end,
	}
end
local function bindColor(page, flag, text, default, cb)
	page:AddColorPicker({
		Text = text, Flag = flag, Default = default or Color3.new(1,1,1),
		Callback = function(c)
			Options[flag] = Options[flag] or {}; Options[flag].Value = c
			if cb then pcall(cb, c) end
		end,
	})
	Options[flag] = { Value = default or Color3.new(1,1,1) }
end
local function bindButton(page, text, cb)
	if not page then return end
	pcall(function()
		page:AddButton({ Text = text, Callback = function() if cb then pcall(cb) end end })
	end)
end
local function bindTextbox(page, flag, text, default, cb, placeholder)
	if not page then return end
	default = tostring(default or "")
	Options[flag] = Options[flag] or { Value = default }
	Options[flag].Value = default
	pcall(function()
		page:AddTextbox({
			Text = text,
			Flag = flag,
			Default = default,
			Placeholder = placeholder or "…",
			Callback = function(v)
				Options[flag] = Options[flag] or {}
				Options[flag].Value = tostring(v or "")
				if cb then pcall(cb, Options[flag].Value) end
			end,
		})
	end)
end
local function bindKeyPicker(page, flag, text, defaultKey, mode)
	-- store hold-key state via dropdown of common keys
	local keys = { "None", "MB1", "MB2", "E", "Q", "F", "C", "V", "R", "LeftAlt", "LeftControl", "RightShift", "Space" }
	local map = {
		MB1 = Enum.UserInputType.MouseButton1, MB2 = Enum.UserInputType.MouseButton2,
		E = Enum.KeyCode.E, Q = Enum.KeyCode.Q, F = Enum.KeyCode.F, C = Enum.KeyCode.C,
		V = Enum.KeyCode.V, R = Enum.KeyCode.R, LeftAlt = Enum.KeyCode.LeftAlt,
		LeftControl = Enum.KeyCode.LeftControl, RightShift = Enum.KeyCode.RightShift, Space = Enum.KeyCode.Space,
	}
	defaultKey = defaultKey or "None"
	local state = { Key = defaultKey, Mode = mode or "Hold" }
	Options[flag] = {
		Value = defaultKey,
		GetState = function()
			if state.Key == "None" then return false end
			if state.Key == "MB1" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
			if state.Key == "MB2" then return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end
			local kc = map[state.Key]
			if kc and typeof(kc) == "EnumItem" and kc.EnumType == Enum.KeyCode then
				return UserInputService:IsKeyDown(kc)
			end
			return false
		end,
	}
	bindDropdown(page, flag, text, keys, defaultKey, function(v)
		state.Key = v; Options[flag].Value = v
	end)
end

local function tv(flag) return flagBool(flag, false) end
local function ov(flag, default)
	if type(default) == "number" then return flagNum(flag, default) end
	if typeof(default) == "Color3" then return flagColor(flag, default) end
	if type(default) == "boolean" then return flagBool(flag, default) end
	return flagStr(flag, default)
end

----------------------------------------------------------------
-- Pages (requested layout)
-- Combat: 3 subs — Rage | Legit | Gun Mods  (AA under Legit as section)
-- Visuals: 2 subs — ESP | World
-- Skinchanger / Movement own pages
----------------------------------------------------------------
local CombatTab = makeTab("Combat")
local VisualsTab = makeTab("Visuals")
local SkinTab = makeTab("Skins")
local MiscTab = makeTab("Misc")

local CombatRage = makeSub(CombatTab, "Rage", "flame")
local CombatLegit = makeSub(CombatTab, "Legit", "crosshair")
local CombatGunMods = makeSub(CombatTab, "Gun Mods", "swords")
-- Anti Aim lives as sections on Legit (3 combat tabs total)

local VisESP = makeSub(VisualsTab, "ESP", "eye")
local VisWorld = makeSub(VisualsTab, "World", "globe")
local VisSelf = makeSub(VisualsTab, "Self", "user")

local SkinMain = makeSub(SkinTab, "Skins", "sparkles")
local SkinModels = makeSub(SkinTab, "Models", "box")
local MiscWorld = makeSub(MiscTab, "World", "eye") -- weapon / bomb / grenade ESP first
local MovPlayer = makeSub(MiscTab, "Player", "user")

-- aliases used by original bind blocks
local CombatAA = CombatLegit
local EntMaster, EntBox, EntChams, EntSkeleton, EntHealth, EntTracer, EntFlags = VisESP, VisESP, VisESP, VisESP, VisESP, VisESP, VisESP
local WorldMain, WorldSky, WorldView, WorldESPTab, WorldExtra = VisWorld, VisWorld, VisSelf, VisWorld, VisSelf
local VisHands = VisSelf

local HitboxList = {
	"HumanoidRootPart","Head","LeftLowerArm","LowerTorso","RightHand","RightLowerArm",
	"LeftFoot","LeftHand","RightFoot","RightLowerLeg","LeftLowerLeg","RightUpperArm",
	"LeftUpperArm","UpperTorso","RightUpperLeg","LeftUpperLeg"
}

local getPlayersOnTeam = nil
pcall(function()
	getPlayersOnTeam = filtergc("function", { Name = "getPlayersOnTeam" }, true)
end)

-- Bloxstrike official HP API
local CharacterResolver = nil
local bloxGetHealth, bloxGetMaxHealth = nil, nil
pcall(function()
	local rs = game:GetService("ReplicatedStorage")
	local mod = rs:FindFirstChild("Components")
		and rs.Components:FindFirstChild("Common")
		and rs.Components.Common:FindFirstChild("CharacterResolver")
	if mod then
		CharacterResolver = require(mod)
	end
end)
pcall(function()
	if CharacterResolver then
		bloxGetHealth = CharacterResolver.getHealth or CharacterResolver.GetHealth
		bloxGetMaxHealth = CharacterResolver.getMaxHealth or CharacterResolver.GetMaxHealth
	end
end)
pcall(function()
	if not bloxGetHealth then
		bloxGetHealth = filtergc("function", { Name = "getHealth" }, true)
	end
	if not bloxGetMaxHealth then
		bloxGetMaxHealth = filtergc("function", { Name = "getMaxHealth" }, true)
	end
end)

local function readBloxHealth(charOrPlayer)
	local char = charOrPlayer
	if typeof(charOrPlayer) == "Instance" and charOrPlayer:IsA("Player") then
		char = charOrPlayer.Character
	end
	if not char then return 0, 100 end
	-- 1) CharacterResolver
	if type(bloxGetHealth) == "function" then
		local ok, h = pcall(bloxGetHealth, char)
		if not ok or type(h) ~= "number" then
			ok, h = pcall(bloxGetHealth, CharacterResolver, char)
		end
		local m = 100
		if type(bloxGetMaxHealth) == "function" then
			local ok2, mm = pcall(bloxGetMaxHealth, char)
			if not ok2 or type(mm) ~= "number" then
				ok2, mm = pcall(bloxGetMaxHealth, CharacterResolver, char)
			end
			if ok2 and type(mm) == "number" and mm > 0 then m = mm end
		end
		if ok and type(h) == "number" then return h, m end
	end
	-- 2) attributes (ESP path)
	local h = char:GetAttribute("Health")
	if type(h) ~= "number" then h = char:GetAttribute("HP") end
	local m = char:GetAttribute("MaxHealth")
	if type(m) ~= "number" then m = char:GetAttribute("MaxHP") end
	if type(h) == "number" then
		if type(m) ~= "number" or m <= 0 then m = 100 end
		return h, m
	end
	-- 3) humanoid last
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		local mh = hum.MaxHealth
		if type(mh) ~= "number" or mh <= 0 then mh = 100 end
		return hum.Health, mh
	end
	return 0, 100
end
local function IsEnemy(p)
	-- original naming: returns true when SAME team (used as team filter)
	if type(getPlayersOnTeam) ~= "function" then
		if p.Team and LP.Team then return p.Team == LP.Team end
		return false
	end
	local Counter = getPlayersOnTeam("Counter-Terrorists") or {}
	local Terr = getPlayersOnTeam("Terrorists") or {}
	if table.find(Terr, LocalPlayer) and table.find(Terr, p) then return true end
	if table.find(Counter, LocalPlayer) and table.find(Counter, p) then return true end
	return false
end

-- True only if player is on CT or T (in the round). Spectators / no-team / lobby = false.
local _teamListCache = { t = 0, ct = {}, terr = {} }
local _onTeamCache = {}
local function isOnPlayingTeam(p)
	if not p then return false end
	local now = os.clock()
	local cached = _onTeamCache[p]
	if cached and (now - cached.t) < 0.5 then return cached.ok end
	local ok = false
	if type(getPlayersOnTeam) == "function" then
		if (now - _teamListCache.t) > 0.5 then
			_teamListCache.t = now
			local a, ct = pcall(getPlayersOnTeam, "Counter-Terrorists")
			local b, terr = pcall(getPlayersOnTeam, "Terrorists")
			_teamListCache.ct = (a and ct) or {}
			_teamListCache.terr = (b and terr) or {}
		end
		if table.find(_teamListCache.ct, p) or table.find(_teamListCache.terr, p) then
			ok = true
		end
	else
		local team = p.Team
		if team then
			local n = tostring(team.Name or ""):lower()
			if n ~= "" and not n:find("spect", 1, true) and not n:find("neutral", 1, true) and n ~= "lobby" then
				ok = true
			end
		end
	end
	_onTeamCache[p] = { t = now, ok = ok }
	return ok
end

local _floatRayParams = RaycastParams.new()
_floatRayParams.FilterType = Enum.RaycastFilterType.Exclude
_floatRayParams.IgnoreWater = true

-- Spectator / lobby floaters sit high with no floor under them
local _floatCache = {}
local function isFloatingOutOfMap(char)
	if not char then return true end
	local now = os.clock()
	local c = _floatCache[char]
	if c and (now - c.t) < 0.5 then return c.floating end
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	if not root then
		_floatCache[char] = { t = now, floating = true }
		return true
	end
	local pos = root.Position
	if pos.Y > 250 or pos.Y < -100 then
		_floatCache[char] = { t = now, floating = true }
		return true
	end
	local exclude = { char }
	pcall(function()
		if LP.Character then exclude[2] = LP.Character end
		local cam = workspace.CurrentCamera
		if cam then exclude[#exclude + 1] = cam end
	end)
	_floatRayParams.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(pos + Vector3.new(0, 2, 0), Vector3.new(0, -120, 0), _floatRayParams)
	local floating = not hit
	_floatCache[char] = { t = now, floating = floating }
	return floating
end

local function isSpectatorPlayer(p)
	if not p then return true end
	if p:GetAttribute("IsSpectating") == true then return true end
	if p:GetAttribute("Spectating") == true then return true end
	if p:GetAttribute("IsSpectator") == true then return true end
	local char = p.Character
	if char then
		if char:GetAttribute("IsSpectating") == true then return true end
		if char:GetAttribute("Spectating") == true then return true end
	end
	return false
end

-- Shared gate for ESP + rage + silent + aimbot
local function isValidCombatTarget(p)
	if not p or p == LocalPlayer then return false end
	if isSpectatorPlayer(p) then return false end
	if not isOnPlayingTeam(p) then return false end
	local char = p.Character
	if not char or not char.Parent then return false end
	if not char:IsDescendantOf(workspace) then return false end
	-- viewmodels under camera are not players
	local cam = workspace.CurrentCamera
	if cam and char:IsDescendantOf(cam) then return false end
	if char:GetAttribute("Dead") == true then return false end
	if char:GetAttribute("Invincible") == true then return false end
	if isFloatingOutOfMap(char) then return false end
	local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
	if not root then return false end
	return true
end

----------------------------------------------------------------
-- COMBAT · Rage: Silent Aim + Ragebot
----------------------------------------------------------------
CombatRage:AddSection("Silent Aim")
bindToggleKey(CombatRage, "SilentAim", "Enabled", false, nil)
bindToggle(CombatRage, "SilentWallbang", "Magic Bullet", false)
bindToggle(CombatRage, "SilentUseFovCircle", "Show FOV", false)
bindSlider(CombatRage, "SilentFovCircleRadius", "FOV Radius", 50, 0, 1200, 0, nil, "px")
bindSlider(CombatRage, "SilentHitChance", "Hit Chance", 100, 0, 100, 0, nil, "%")
bindColor(CombatRage, "SilentFovColor", "FOV Color", Color3.fromRGB(255, 255, 255), nil)
bindDropdown(CombatRage, "SilentHitPart", "Hit Part", HitboxList, "Head")
bindToggle(CombatRage, "SilentTeamCheck", "Team Check", true)

CombatRage:AddSection("Ragebot")
bindToggleKey(CombatRage, "Ragebot", "Enabled", false, nil)
bindSlider(CombatRage, "RageDelay", "Delay", 0, 0, 1, 3, nil, "s")
bindDropdown(CombatRage, "RageHitPart", "Hit Part", HitboxList, "Head")
bindToggle(CombatRage, "RagebotVisibleCheck", "On Screen", false)
bindToggle(CombatRage, "RagebotTeamCheck", "Team Check", true)
bindToggle(CombatRage, "RagebotWallCheck", "Wall Check", false)

CombatRage:AddSection("Backtrack")
bindToggle(CombatRage, "Backtrack", "Enabled", false)
bindSlider(CombatRage, "BacktrackMs", "Backtrack MS", 200, 0, 400, 0, nil, "ms")
bindToggle(CombatRage, "BacktrackHighlight", "Show Backtrack", true)
bindColor(CombatRage, "BacktrackColor", "Color", Color3.fromRGB(0, 200, 255), nil)
bindSlider(CombatRage, "BacktrackTransparency", "Transparency", 0.55, 0.1, 0.9, 2, nil, "")

----------------------------------------------------------------
-- COMBAT · Legit: Aimbot + Trigger + Anti Aim
----------------------------------------------------------------
CombatLegit:AddSection("Aimbot")
bindToggleKey(CombatLegit, "Aimbot", "Enabled", false, nil)
bindKeyPicker(CombatLegit, "AimbotHoldkey", "Hold Key", "MB2", "Hold")
bindToggle(CombatLegit, "AimbotUseFovCircle", "Show FOV", false)
bindSlider(CombatLegit, "AimbotFovCircleRadius", "FOV Radius", 50, 0, 300, 0, nil, "px")
bindColor(CombatLegit, "AimbotFovColor", "FOV Color", Color3.fromRGB(255, 255, 255), nil)
bindDropdown(CombatLegit, "AimbotHitPart", "Hit Part", HitboxList, "Head")
bindToggle(CombatLegit, "AimbotTeamCheck", "Team Check", true)
bindToggle(CombatLegit, "AimbotWallCheck", "Wall Check", true)

CombatLegit:AddSection("Triggerbot")
bindToggleKey(CombatLegit, "Triggerbot", "Enabled", false, nil)
bindSlider(CombatLegit, "TriggerbotDelay", "Delay", 0.01, 0, 1, 3, nil, "s")


----------------------------------------------------------------
-- COMBAT · Gun Mods
----------------------------------------------------------------
CombatGunMods:AddSection("Gun Mods")
bindToggle(CombatGunMods, "Firerate", "Rapid Fire", false)
bindSlider(CombatGunMods, "FirerateSlider", "rate", 0.01, 0, 1, 3)
bindToggle(CombatGunMods, "ForceAuto", "Force Auto", false)
bindToggle(CombatGunMods, "NoRecoil", "No Recoil", false)
CombatGunMods:AddSlider({
	Text = "Rcs",
	Flag = "RecoilControl",
	Default = 100,
	Min = 0,
	Max = 100,
	Suffix = "%",
	Callback = function(v)
		Options.RecoilControl = Options.RecoilControl or {}
		Options.RecoilControl.Value = v
	end,
})
Options.RecoilControl = { Value = 100 }

bindToggle(CombatGunMods, "AutoReload", "Auto Reload", false)
bindToggle(CombatGunMods, "NoSpread", "No Spread", false)
CombatGunMods:AddSlider({
	Text = "Spread amount",
	Flag = "SpreadControl",
	Default = 100,
	Min = 0,
	Max = 100,
	Suffix = "%",
	Callback = function(v)
		Options.SpreadControl = Options.SpreadControl or {}
		Options.SpreadControl.Value = v
	end,
})
Options.SpreadControl = { Value = 100 }

CombatGunMods:AddSection("Hit Sounds")
local HIT_SOUND_IDS = {
	Skeet = "rbxassetid://4817809188",
	Rust = "rbxassetid://1255040462",
	Bell = "rbxassetid://6534947240",
	Cod = "rbxassetid://160432334",
	Neverlose = "rbxassetid://8726881116",
}
local hitsound = { enabled = false, selected = "Skeet", volume = 1.2 }
getgenv().MethaneHitSound = hitsound
local lastHitSoundTime = 0
local activeHitSounds = {}
local function stopHitSounds()
	for snd in pairs(activeHitSounds) do
		pcall(function()
			snd:Stop()
			snd:Destroy()
		end)
		activeHitSounds[snd] = nil
	end
end
local function PlayHitSound(forceId, isPreview)
	local now = tick()
	if not isPreview then
		if (now - lastHitSoundTime) < 0.05 then return end
		lastHitSoundTime = now
	end
	pcall(function()
		if isPreview then stopHitSounds() end
		local SoundService = game:GetService("SoundService")
		local Debris = game:GetService("Debris")
		local sndId = forceId or HIT_SOUND_IDS[hitsound.selected] or HIT_SOUND_IDS.Skeet
		local snd = Instance.new("Sound")
		snd.Name = isPreview and "MethaneHitPreview" or "MethaneHitSound"
		snd.SoundId = sndId
		snd.Volume = tonumber(hitsound.volume) or 1.2
		snd.PlaybackSpeed = 1
		snd.Parent = SoundService
		activeHitSounds[snd] = true
		snd.Ended:Connect(function()
			activeHitSounds[snd] = nil
			pcall(function() snd:Destroy() end)
		end)
		snd:Play()
		pcall(function() Debris:AddItem(snd, 2.5) end)
	end)
end
bindToggle(CombatGunMods, "HitSoundEnabled", "Enabled", false, function(v) hitsound.enabled = v == true end)
bindDropdown(CombatGunMods, "HitSoundType", "Sound", { "Skeet", "Rust", "Bell", "Cod", "Neverlose" }, "Skeet", function(v)
	hitsound.selected = tostring(v or "Skeet")
end)
bindSlider(CombatGunMods, "HitSoundVolume", "Volume", 1.2, 0, 3, 2, function(v) hitsound.volume = tonumber(v) or 1.2 end)
do
	local lastPreview = 0
	bindButton(CombatGunMods, "Preview Sound", function()
		local now = tick()
		if now - lastPreview < 0.35 then return end
		lastPreview = now
		PlayHitSound(HIT_SOUND_IDS[hitsound.selected] or HIT_SOUND_IDS.Skeet, true)
	end)
end

-- Bloxstrike: play on local damage confirmation (DamageIndicator + health drop)
task.spawn(function()
	local hooked = false
	for _ = 1, 30 do
		pcall(function()
			-- UI.CreateDamageIndicator.Connect / Listen
			for _, obj in next, getgc(true) do
				if type(obj) == "table" then
					local cdi = rawget(obj, "CreateDamageIndicator")
					if type(cdi) == "table" and not cdi._methaneHS then
						local function wrap(fnName)
							local fn = cdi[fnName]
							if type(fn) ~= "function" then return end
							cdi[fnName] = function(...)
								local args = { ... }
								-- Listen/Connect register callbacks — wrap the callback if provided
								if fnName == "Connect" or fnName == "Listen" then
									local cb = args[1]
									if type(cb) == "function" then
										args[1] = function(...)
											-- only local damage indicators (we fired recently)
											local okLocal = false
											pcall(function()
												okLocal = getgenv().MethaneIsLocalShot and getgenv().MethaneIsLocalShot() == true
											end)
											if okLocal and hitsound.enabled then pcall(PlayHitSound) end
											return cb(...)
										end
									end
									return fn(table.unpack(args))
								end
								-- Send* paths also mean we dealt/received indicator; gate to local via later health hook
								return fn(...)
							end
						end
						wrap("Connect")
						wrap("Listen")
						cdi._methaneHS = true
						hooked = true
					end
				end
			end
		end)
		if hooked then break end
		task.wait(0.5)
	end
end)

-- Hit + Kill: health drop / death while we recently attacked (still plays on lethal hit)
CombatGunMods:AddSection("Kill Sounds")
local KILL_SOUND_IDS = {
	Skeet = "rbxassetid://4817809188",
	Rust = "rbxassetid://1255040462",
	Bell = "rbxassetid://6534947240",
	Cod = "rbxassetid://160432334",
	Neverlose = "rbxassetid://8726881116",
	TF2 = "rbxassetid://3455144784",
}
local killsound = { enabled = false, selected = "Neverlose", volume = 1.5 }
getgenv().MethaneKillSound = killsound
local lastKillSoundTime = 0
local function PlayKillSound(forceId, isPreview)
	local now = tick()
	if not isPreview then
		if (now - lastKillSoundTime) < 0.08 then return end
		lastKillSoundTime = now
	end
	pcall(function()
		if isPreview then stopHitSounds() end
		local SoundService = game:GetService("SoundService")
		local Debris = game:GetService("Debris")
		local sndId = forceId or KILL_SOUND_IDS[killsound.selected] or KILL_SOUND_IDS.Neverlose
		local snd = Instance.new("Sound")
		snd.Name = isPreview and "MethaneKillPreview" or "MethaneKillSound"
		snd.SoundId = sndId
		snd.Volume = tonumber(killsound.volume) or 1.5
		snd.PlaybackSpeed = 1
		snd.Parent = SoundService
		activeHitSounds[snd] = true
		snd.Ended:Connect(function()
			activeHitSounds[snd] = nil
			pcall(function() snd:Destroy() end)
		end)
		snd:Play()
		pcall(function() Debris:AddItem(snd, 2.5) end)
	end)
end
bindToggle(CombatGunMods, "KillSoundEnabled", "Enabled", false, function(v) killsound.enabled = v == true end)
bindDropdown(CombatGunMods, "KillSoundType", "Sound", { "Skeet", "Rust", "Bell", "Cod", "Neverlose", "TF2" }, "Neverlose", function(v)
	killsound.selected = tostring(v or "Neverlose")
end)
bindSlider(CombatGunMods, "KillSoundVolume", "Volume", 1.5, 0, 3, 2, function(v) killsound.volume = tonumber(v) or 1.5 end)
do
	local lastPreview = 0
	bindButton(CombatGunMods, "Preview Kill Sound", function()
		local now = tick()
		if now - lastPreview < 0.35 then return end
		lastPreview = now
		PlayKillSound(KILL_SOUND_IDS[killsound.selected] or KILL_SOUND_IDS.Neverlose, true)
	end)
end

do
	-- Local-shot credit: only OUR bullets trigger hit/kill sounds
	local lastLocalShot = 0
	local shotTargets = {} -- [Player] = tick
	local healthCache = {}
	local deadSeen = {}
	local LOCAL_SHOT_WINDOW = 1.25 -- rage damage can lag a bit client-side

	local function readHpQuick(char)
		if not char then return nil end
		local h = char:GetAttribute("Health")
		if type(h) ~= "number" then h = char:GetAttribute("HP") end
		if type(h) ~= "number" then
			local hum = char:FindFirstChildOfClass("Humanoid")
			h = hum and hum.Health
		end
		return type(h) == "number" and h or nil
	end

	local function noteLocalShot(plr)
		lastLocalShot = tick()
		-- resolve player from part if needed
		if plr and typeof(plr) == "Instance" and not plr:IsA("Player") then
			local model = plr:FindFirstAncestorOfClass("Model") or plr.Parent
			plr = model and Players:GetPlayerFromCharacter(model) or nil
		end
		if plr and typeof(plr) == "Instance" and plr:IsA("Player") then
			shotTargets[plr] = lastLocalShot
			-- seed HP so next drop is detectable
			local hp = readHpQuick(plr.Character)
			if type(hp) == "number" then
				healthCache[plr] = hp
			end
		end
		-- also seed current rage/silent locks
		pcall(function()
			for _, key in ipairs({ "MethaneRageTarget", "MethaneSilentTarget" }) do
				local p2 = getgenv()[key]
				if typeof(p2) == "Instance" and p2:IsA("Player") then
					shotTargets[p2] = lastLocalShot
					local hp2 = readHpQuick(p2.Character)
					if type(hp2) == "number" then healthCache[p2] = hp2 end
				end
			end
		end)
	end
	getgenv().MethaneNoteLocalShot = noteLocalShot
	getgenv().MethaneIsLocalShot = function()
		return (tick() - lastLocalShot) <= LOCAL_SHOT_WINDOW
	end
	getgenv().MethaneIsOurTarget = function(plr)
		if not plr then return false end
		if typeof(plr) == "Instance" and not plr:IsA("Player") then
			local model = plr:FindFirstAncestorOfClass("Model") or plr.Parent
			plr = model and Players:GetPlayerFromCharacter(model)
		end
		if not plr then return false end
		local t = shotTargets[plr]
		if t and (tick() - t) <= LOCAL_SHOT_WINDOW then return true end
		return (tick() - lastLocalShot) <= LOCAL_SHOT_WINDOW
			and (getgenv().MethaneRageTarget == plr or getgenv().MethaneSilentTarget == plr)
	end

	-- M1
	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				local intent = getgenv().MethaneRageTarget or getgenv().MethaneSilentTarget
				noteLocalShot(intent)
			end
		end)
	end)

	RunService.Heartbeat:Connect(function()
		if not hitsound.enabled and not killsound.enabled then return end
		local now = tick()
		-- prune old credits
		for plr, t0 in pairs(shotTargets) do
			if now - t0 > LOCAL_SHOT_WINDOW then shotTargets[plr] = nil end
		end
		local anyRecent = (now - lastLocalShot) <= LOCAL_SHOT_WINDOW
		if not anyRecent then return end

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then continue end
			local ours = shotTargets[plr] and (now - shotTargets[plr]) <= LOCAL_SHOT_WINDOW
			-- also allow if they were current rage/silent lock when we shot
			if not ours then
				local rt = getgenv().MethaneRageTarget
				local st = getgenv().MethaneSilentTarget
				if (rt == plr or st == plr) and anyRecent then
					ours = true
				end
			end
			if not ours then
				-- still track HP so we don't false-credit later, but no sounds
				local char = plr.Character
				if char then
					local hp = char:GetAttribute("Health")
					if type(hp) ~= "number" then
						local hum = char:FindFirstChildOfClass("Humanoid")
						hp = hum and hum.Health
					end
					if type(hp) == "number" then healthCache[plr] = hp end
				else
					healthCache[plr] = nil
				end
				continue
			end

			local char = plr.Character
			if not char then
				if healthCache[plr] and healthCache[plr] > 0 and killsound.enabled and not deadSeen[plr] then
					deadSeen[plr] = true
					pcall(PlayKillSound)
				end
				healthCache[plr] = nil
				continue
			end
			local deadAttr = char:GetAttribute("Dead") == true
			local hp = char:GetAttribute("Health")
			if type(hp) ~= "number" then
				local hum = char:FindFirstChildOfClass("Humanoid")
				hp = hum and hum.Health
			end
			if type(hp) ~= "number" then hp = deadAttr and 0 or nil end
			if type(hp) ~= "number" then continue end
			local prev = healthCache[plr]
			healthCache[plr] = hp
			if prev and hp < prev - 0.5 then
				if hitsound.enabled then pcall(PlayHitSound) end
			end
			if killsound.enabled and not deadSeen[plr] then
				if (prev and prev > 0 and hp <= 0) or deadAttr then
					deadSeen[plr] = true
					pcall(PlayKillSound)
				end
			end
			if hp > 0 and not deadAttr then
				deadSeen[plr] = nil
			end
		end
	end)
end

----------------------------------------------------------------
-- Bullet tracers (animated, barrel-origin, real-shot hooks)
----------------------------------------------------------------
CombatGunMods:AddSection("Bullet Tracers")
local tracers = {
	enabled = false,
	style = "Regular",
	color = Color3.fromRGB(120, 200, 255),
	lifetime = 0.4,
	thickness = 0.08,
}
getgenv().MethaneTracers = tracers
bindToggle(CombatGunMods, "BulletTracers", "Enabled", false, function(v) tracers.enabled = v == true end)
bindDropdown(CombatGunMods, "BulletTracerStyle", "Style", {
	"Regular", "Lightning", "Squiggly",
}, "Regular", function(v) tracers.style = tostring(v or "Regular") end)
bindColor(CombatGunMods, "BulletTracerColor", "Color", Color3.fromRGB(120, 200, 255), function(c)
	if typeof(c) == "Color3" then tracers.color = c end
end)
bindSlider(CombatGunMods, "BulletTracerLife", "Lifetime", 0.4, 0.15, 1.2, 2, function(v)
	tracers.lifetime = tonumber(v) or 0.4
end, "s")
bindSlider(CombatGunMods, "BulletTracerThick", "Thickness", 0.08, 0.03, 0.25, 2, function(v)
	tracers.thickness = tonumber(v) or 0.08
end)

CombatGunMods:AddSection("Hitmarkers")
local hitmarks = {
	enabled = false,
	color1 = Color3.fromRGB(255, 255, 255),
	color2 = Color3.fromRGB(255, 105, 180),
	size = 42,
	lifetime = 0.45,
	rotate = true,
}
getgenv().MethaneHitmarks = hitmarks
bindToggle(CombatGunMods, "Hitmarks", "Enabled", false, function(v) hitmarks.enabled = v == true end)
bindColor(CombatGunMods, "HitmarkColor1", "Color 1", Color3.fromRGB(255, 255, 255), function(c)
	if typeof(c) == "Color3" then hitmarks.color1 = c end
end)
bindColor(CombatGunMods, "HitmarkColor2", "Color 2", Color3.fromRGB(255, 105, 180), function(c)
	if typeof(c) == "Color3" then hitmarks.color2 = c end
end)
bindSlider(CombatGunMods, "HitmarkSize", "Size", 42, 20, 80, 0, function(v)
	hitmarks.size = tonumber(v) or 42
end, "px")
bindSlider(CombatGunMods, "HitmarkLife", "Lifetime", 0.45, 0.15, 1.2, 2, function(v)
	hitmarks.lifetime = tonumber(v) or 0.45
end, "s")
bindToggle(CombatGunMods, "HitmarkRotate", "Rotate", true, function(v) hitmarks.rotate = v == true end)

----------------------------------------------------------------
-- Hit Log / Notifications (silent + rage)
----------------------------------------------------------------
CombatGunMods:AddSection("Notifications")
local hitlog = {
	hits = true,
	kills = true,
	misses = true,
	duration = 3,
}
getgenv().MethaneHitLog = hitlog
bindToggle(CombatGunMods, "HitLogHits", "Hit notifications", true, function(v) hitlog.hits = v == true end)
bindToggle(CombatGunMods, "HitLogKills", "Kill notifications", true, function(v) hitlog.kills = v == true end)
bindToggle(CombatGunMods, "HitLogMisses", "Miss notifications", true, function(v) hitlog.misses = v == true end)
bindSlider(CombatGunMods, "HitLogDuration", "Duration", 3, 1, 8, 1, function(v)
	hitlog.duration = tonumber(v) or 3
end, "s")

do
	local pending = {}
	local lastNotifyKey = {}
	local hpCache = {}

	local function accentCol()
		local c = nil
		pcall(function()
			c = Library and Library.Theme and Library.Theme.Accent
		end)
		if typeof(c) == "Color3" then return c end
		return Color3.fromRGB(140, 200, 255)
	end

	local function accentHex()
		local c = accentCol()
		return string.format("#%02X%02X%02X",
			math.floor(c.R * 255 + 0.5),
			math.floor(c.G * 255 + 0.5),
			math.floor(c.B * 255 + 0.5))
	end

	-- Library:Notification only colors the side liner; text is Theme.Text.
	-- Build rich-text notifs so player / part / damage use accent.
	local function notify(msg, col, key)
		key = key or tostring(msg)
		local now = os.clock()
		if lastNotifyKey[key] and (now - lastNotifyKey[key]) < 0.45 then
			return
		end
		lastNotifyKey[key] = now
		local dur = math.clamp(tonumber(hitlog.duration) or 3, 0.5, 12)
		local accent = accentCol()
		local hex = accentHex()

		pcall(function()
			local holder = Library.NotifHolder and Library.NotifHolder.Instance
			if not holder then
				if Library.Notification then
					Library:Notification(tostring(msg), dur, accent)
				end
				return
			end

			local frame = Instance.new("Frame")
			frame.Name = "MethaneHitLog"
			frame.AutomaticSize = Enum.AutomaticSize.X
			frame.Size = UDim2.new(0, 0, 0, 20)
			frame.BorderSizePixel = 0
			frame.BackgroundColor3 = (Library.Theme and Library.Theme.Section) or Color3.fromRGB(30, 30, 30)
			frame.Parent = holder

			local pad = Instance.new("UIPadding")
			pad.PaddingLeft = UDim.new(0, 8)
			pad.PaddingRight = UDim.new(0, 8)
			pad.Parent = frame

			local liner = Instance.new("Frame")
			liner.Size = UDim2.new(0, 1, 1, 0)
			liner.Position = UDim2.new(0, -8, 0, 0)
			liner.BorderSizePixel = 0
			liner.BackgroundColor3 = accent
			liner.Parent = frame

			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.AutomaticSize = Enum.AutomaticSize.X
			label.Size = UDim2.new(0, 0, 1, 0)
			label.Font = Enum.Font.Code
			label.TextSize = (Library.FontSize) or 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextYAlignment = Enum.TextYAlignment.Center
			label.TextColor3 = (Library.Theme and Library.Theme.Text) or Color3.fromRGB(220, 220, 220)
			label.RichText = true
			-- msg may already be rich; if plain, show as-is
			label.Text = tostring(msg)
			label.Parent = frame

			task.spawn(function()
				task.wait()
				local w = math.max(label.TextBounds.X + 16, 40)
				frame.Size = UDim2.new(0, w, 0, 20)
				task.wait(dur)
				pcall(function() frame:Destroy() end)
			end)
		end)
	end

	local function fmtHit(name, part, dmg)
		local hex = accentHex()
		return string.format('Hit <font color="%s">%s</font> in the <font color="%s">%s</font> for <font color="%s">%d</font>',
			hex, name, hex, part, hex, dmg)
	end
	local function fmtKill(name, part, dmg)
		local hex = accentHex()
		return string.format('Killed <font color="%s">%s</font> in the <font color="%s">%s</font> for <font color="%s">%d</font>',
			hex, name, hex, part, hex, dmg)
	end
	local function fmtMiss(name, reason)
		local hex = accentHex()
		return string.format('Missed <font color="%s">%s</font> (%s)', hex, name, reason)
	end

	local function bodyName(part)
		if not part then return "body" end
		local n = tostring(part.Name or "body")
		if n == "HumanoidRootPart" then return "body" end
		if n == "Head" then return "head" end
		if n:find("Torso") or n == "UpperTorso" or n == "LowerTorso" then return "torso" end
		return n:lower()
	end

	local function readHp(char)
		if not char then return nil end
		local h = char:GetAttribute("Health")
		if type(h) ~= "number" then h = char:GetAttribute("HP") end
		if type(h) ~= "number" then
			local hum = char:FindFirstChildOfClass("Humanoid")
			h = hum and hum.Health
		end
		return type(h) == "number" and h or nil
	end

	local function markShot(plr, part, mode)
		if not plr then return end
		local char = plr.Character
		pending[plr] = {
			t = os.clock(),
			part = part,
			mode = mode or "Combat",
			hp = char and readHp(char) or nil,
			resolved = false,
		}
		-- credit local shot for hit/kill sounds + logs
		pcall(function()
			if getgenv().MethaneNoteLocalShot then
				getgenv().MethaneNoteLocalShot(plr)
			end
		end)
	end
	getgenv().MethaneHitLogMarkShot = markShot

	local function currentIntent()
		local plr = getgenv().MethaneRageTarget
		if tv("Ragebot") and typeof(plr) == "Instance" and plr:IsA("Player") then
			local char = plr.Character
			local part = char and (char:FindFirstChild(ov("RageHitPart", "Head")) or char:FindFirstChild("Head"))
			return plr, part, "Ragebot"
		end
		plr = getgenv().MethaneSilentTarget
		if tv("SilentAim") and typeof(plr) == "Instance" and plr:IsA("Player") then
			local char = plr.Character
			local part = char and (char:FindFirstChild(ov("SilentHitPart", "Head")) or char:FindFirstChild("Head"))
			return plr, part, "Silent Aim"
		end
		return nil
	end

	pcall(function()
		game:GetService("UserInputService").InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
			if not (tv("Ragebot") or tv("SilentAim")) then return end
			local plr, part, mode = currentIntent()
			if plr then markShot(plr, part, mode) end
		end)
	end)

	RunService.Heartbeat:Connect(function()
		if not (hitlog.hits or hitlog.kills or hitlog.misses) then return end
		local now = os.clock()
		local intentPlr, intentPart, mode = currentIntent()

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == LocalPlayer then continue end
			local char = plr.Character
			if not char then hpCache[plr] = nil continue end
			local hp = readHp(char)
			if type(hp) ~= "number" then continue end
			local prev = hpCache[plr]
			hpCache[plr] = hp
			if prev and hp < prev - 0.4 then
				local localOk = false
				pcall(function()
					localOk = getgenv().MethaneIsLocalShot and getgenv().MethaneIsLocalShot() == true
				end)
				local ours = pending[plr] ~= nil or (localOk and intentPlr == plr)
				if ours and not pending[plr] and localOk then
					markShot(plr, intentPart or char:FindFirstChild("Head"), mode or "Combat")
					if pending[plr] then pending[plr].hp = prev end
				elseif pending[plr] and pending[plr].hp == nil then
					pending[plr].hp = prev
				end
			end
		end

		for plr, info in pairs(pending) do
			if not plr or not plr.Parent or info.resolved then
				pending[plr] = nil
				continue
			end
			local char = plr.Character
			local hp = char and readHp(char)
			local dead = char and (char:GetAttribute("Dead") == true or (type(hp) == "number" and hp <= 0))
			local age = now - (info.t or now)
			local name = plr.DisplayName or plr.Name
			local part = bodyName(info.part)

			if type(info.hp) == "number" and type(hp) == "number" and hp < info.hp - 0.4 then
				local dmg = math.max(1, math.floor((info.hp - hp) + 0.5))
				info.resolved = true
				pending[plr] = nil
				-- rage/silent: sounds from confirmed local damage
				if dead or hp <= 0 then
					pcall(function()
						if killsound and killsound.enabled then PlayKillSound() end
					end)
					if hitlog.kills then
						notify(fmtKill(name, part, dmg), nil, "k" .. plr.UserId)
					elseif hitlog.hits then
						notify(fmtHit(name, part, dmg), nil, "h" .. plr.UserId)
					end
				else
					pcall(function()
						if hitsound and hitsound.enabled then PlayHitSound() end
					end)
					if hitlog.hits then
						notify(fmtHit(name, part, dmg), nil, "h" .. plr.UserId)
					end
				end
			elseif dead and type(info.hp) == "number" and info.hp > 0 then
				info.resolved = true
				pending[plr] = nil
				pcall(function()
					if killsound and killsound.enabled then PlayKillSound() end
				end)
				if hitlog.kills then
					notify(fmtKill(name, part, math.max(1, math.floor(info.hp + 0.5))), nil, "k" .. plr.UserId)
				end
			elseif age > 0.55 then
				info.resolved = true
				pending[plr] = nil
				if hitlog.misses and (tv("Ragebot") or tv("SilentAim")) then
					local reason = (info.mode == "Silent Aim") and "prediction error" or "desync"
					notify(fmtMiss(name, reason), nil, "m" .. plr.UserId)
				end
			end
		end
	end)
end

do
	local Debris = game:GetService("Debris")
	local activeTracers = {} -- { parts = {}, t0, life, pts, style, col, thick }
	local tracerFolder = nil

	local function ensureFolder()
		local cam = workspace.CurrentCamera
		if tracerFolder and tracerFolder.Parent then return tracerFolder end
		tracerFolder = Instance.new("Folder")
		tracerFolder.Name = "MethaneTracers"
		tracerFolder.Parent = cam or workspace
		return tracerFolder
	end

	-- Soft neon segment — no outline/highlight, transparent + point light
	local function makeSeg(folder, col, thick)
		local p = Instance.new("Part")
		p.Name = "TracerSeg"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = col
		p.Transparency = 0.18
		p.Size = Vector3.new(thick, thick, 0.05)
		p.Parent = folder
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Color = col
		light.Brightness = 1.2
		light.Range = 8
		light.Shadows = false
		light.Parent = p
		return p
	end

	local function setSeg(p, a, b, thick, alpha)
		local dist = (b - a).Magnitude
		if dist < 0.02 then
			p.Transparency = 1
			return
		end
		local mid = (a + b) * 0.5
		p.Size = Vector3.new(thick, thick, dist)
		p.CFrame = CFrame.lookAt(mid, b)
		-- alpha 0 = solid-ish, 1 = invisible
		p.Transparency = math.clamp(alpha, 0.08, 1)
		local light = p:FindFirstChild("Glow")
		if light then
			local vis = 1 - math.clamp(alpha, 0, 1)
			light.Brightness = 1.1 * vis * vis
			light.Range = (5 + thick * 35) * vis
		end
	end

	-- stronger fade at barrel + tip (edgeFactor 0 at ends, 1 at center)
	local function edgeFactor(i, n)
		if n <= 1 then return 0.35 end
		local t = (i - 0.5) / n
		-- smooth ends: rise fast, hold, fall
		local e = math.sin(t * math.pi)
		return math.clamp(e, 0, 1)
	end

	local function pathPoints(style, origin, hit, seed)
		local pts = {}
		local dir = hit - origin
		local len = dir.Magnitude
		if len < 0.5 then
			return { origin, hit }
		end
		local look = dir.Unit
		local right = look:Cross(Vector3.yAxis)
		if right.Magnitude < 0.05 then right = look:Cross(Vector3.xAxis) end
		right = right.Unit
		local up = right:Cross(look).Unit
		local n = math.clamp(math.floor(len / 2.5), 6, 24)

		if style == "Lightning" then
			table.insert(pts, origin)
			local rng = Random.new(seed or math.floor(tick() * 1000))
			for i = 1, n - 1 do
				local t = i / n
				local base = origin:Lerp(hit, t)
				-- cleaner jagged: fewer big offsets, taper toward end
				local amp = (1 - t * 0.65) * 1.15
				local jx = (rng:NextNumber() - 0.5) * 2 * amp
				local jy = (rng:NextNumber() - 0.5) * 2 * amp
				table.insert(pts, base + right * jx + up * jy)
			end
			table.insert(pts, hit)
		elseif style == "Squiggly" then
			table.insert(pts, origin)
			for i = 1, n - 1 do
				local t = i / n
				local base = origin:Lerp(hit, t)
				-- smooth sine ribbon (animation phase applied later)
				local wave = math.sin(t * math.pi * 5) * 0.85 * (1 - t * 0.3)
				table.insert(pts, base + right * wave)
			end
			table.insert(pts, hit)
		else
			pts = { origin, hit }
		end
		return pts, right, up, look
	end

	local function fireTracer(origin, hit)
		if not tracers.enabled then return end
		if typeof(origin) ~= "Vector3" or typeof(hit) ~= "Vector3" then return end
		if (hit - origin).Magnitude < 0.5 then return end

		local folder = ensureFolder()
		local col = tracers.color or Color3.fromRGB(120, 200, 255)
		local life = math.clamp(tracers.lifetime or 0.4, 0.12, 2)
		local thick = math.clamp(tracers.thickness or 0.08, 0.02, 0.4)
		local style = tostring(tracers.style or "Regular")
		local seed = math.floor(os.clock() * 10000) % 100000
		local basePts, right, up, look = pathPoints(style, origin, hit, seed)

		-- segment pool along path
		local segs = {}
		local segCount = math.max(1, #basePts - 1)
		if style == "Regular" then
			segCount = 12 -- animate travel along straight line
		elseif style == "Squiggly" then
			segCount = math.max(segCount, 14)
		end
		for i = 1, segCount do
			table.insert(segs, makeSeg(folder, col, thick))
		end

		local entry = {
			segs = segs,
			t0 = os.clock(),
			life = life,
			origin = origin,
			hit = hit,
			style = style,
			col = col,
			thick = thick,
			seed = seed,
			basePts = basePts,
			right = right,
			up = up,
			look = look,
		}
		table.insert(activeTracers, entry)
	end

	-- animate all live tracers
	RunService.RenderStepped:Connect(function()
		if #activeTracers == 0 then return end
		local now = os.clock()
		local i = 1
		while i <= #activeTracers do
			local tr = activeTracers[i]
			local age = now - tr.t0
			local life = tr.life
			if age >= life then
				for _, s in ipairs(tr.segs) do pcall(function() s:Destroy() end) end
				table.remove(activeTracers, i)
				continue
			end
			local u = age / life -- 0 → 1
			-- travel progress then full-body fade
			local travel = math.clamp(u / 0.32, 0, 1)
			local fade = math.clamp((u - 0.35) / 0.65, 0, 1)
			local baseAlpha = 0.12 + fade * 0.78

			local origin, hit = tr.origin, tr.hit
			local style = tr.style
			local thick = tr.thick * (1 - fade * 0.4)

			if style == "Regular" then
				local tip = origin:Lerp(hit, travel)
				local n = #tr.segs
				for si, seg in ipairs(tr.segs) do
					local t0 = (si - 1) / n
					local t1 = si / n
					local edge = edgeFactor(si, n)
					-- ends much more transparent
					local alpha = baseAlpha + (1 - edge) * 0.4
					if t1 > travel then
						if t0 >= travel then
							seg.Transparency = 1
						else
							local a = origin:Lerp(hit, t0)
							setSeg(seg, a, tip, thick * (0.45 + edge * 0.55), alpha)
						end
					else
						local a = origin:Lerp(hit, t0)
						local b = origin:Lerp(hit, t1)
						setSeg(seg, a, b, thick * (0.45 + edge * 0.55), alpha)
					end
				end
			elseif style == "Lightning" then
				-- re-jitter slightly over time for live crackle
				local pts = { origin }
				local dir = hit - origin
				local len = dir.Magnitude
				local look = dir.Unit
				local right = tr.right or look:Cross(Vector3.yAxis).Unit
				local up = tr.up or right:Cross(look).Unit
				local n = math.max(2, #tr.segs)
				local phase = age * 18
				for j = 1, n - 1 do
					local t = j / n
					if t > travel then break end
					local base = origin:Lerp(hit, t)
					local amp = (1 - t * 0.6) * 1.05
					local jx = math.sin(phase + j * 2.1 + tr.seed) * amp
					local jy = math.cos(phase * 1.3 + j * 1.7 + tr.seed) * amp * 0.85
					table.insert(pts, base + right * jx + up * jy)
				end
				table.insert(pts, origin:Lerp(hit, math.min(travel, 1)))
				local pn = math.max(1, #pts - 1)
				for si, seg in ipairs(tr.segs) do
					if si < #pts then
						local edge = edgeFactor(si, pn)
						local alpha = baseAlpha + (1 - edge) * 0.4
						setSeg(seg, pts[si], pts[si + 1], thick * (0.45 + edge * 0.55), alpha)
					else
						seg.Transparency = 1
					end
				end
			elseif style == "Squiggly" then
				local dir = hit - origin
				local look = dir.Unit
				local right = tr.right or look:Cross(Vector3.yAxis).Unit
				local n = #tr.segs
				local phase = age * 10
				local pts = {}
				local steps = n + 1
				for j = 0, steps do
					local t = j / steps
					if t > travel then
						table.insert(pts, origin:Lerp(hit, travel) + right * (math.sin(travel * math.pi * 5 + phase) * 0.7 * (1 - travel * 0.3)))
						break
					end
					local base = origin:Lerp(hit, t)
					local wave = math.sin(t * math.pi * 5 + phase) * 0.85 * (1 - t * 0.3)
					table.insert(pts, base + right * wave)
				end
				local pn = math.max(1, #pts - 1)
				for si, seg in ipairs(tr.segs) do
					if si < #pts then
						local edge = edgeFactor(si, pn)
						local alpha = baseAlpha + (1 - edge) * 0.4
						setSeg(seg, pts[si], pts[si + 1], thick * (0.45 + edge * 0.55), alpha)
					else
						seg.Transparency = 1
					end
				end
			end
			i += 1
		end
	end)

	-- barrel / muzzle from FP viewmodel
	local function findMuzzle()
		local cam = workspace.CurrentCamera
		if not cam then return nil end
		-- 1) named muzzle attachments / parts on camera viewmodel
		local best = nil
		local bestScore = -1
		pcall(function()
			for _, d in ipairs(cam:GetDescendants()) do
				local n = string.lower(d.Name)
				if d:IsA("Attachment") and (n:find("muzzle", 1, true) or n:find("barrel", 1, true) or n:find("flash", 1, true) or n == "fire" or n == "tip") then
					local score = 10
					if n:find("muzzle", 1, true) then score = 30 end
					if score > bestScore then bestScore = score; best = d.WorldPosition end
				elseif d:IsA("BasePart") and (n:find("muzzle", 1, true) or n:find("barrel", 1, true) or n == "tip" or n == "flash") then
					local score = 8
					if n:find("muzzle", 1, true) then score = 25 end
					if score > bestScore then bestScore = score; best = d.Position end
				end
			end
		end)
		if best then return best end
		-- 2) furthest mesh in front of camera among viewmodel parts (barrel tip heuristic)
		pcall(function()
			local look = cam.CFrame.LookVector
			local camPos = cam.CFrame.Position
			local maxDot = -1
			for _, d in ipairs(cam:GetDescendants()) do
				if d:IsA("BasePart") and d.Transparency < 0.95 then
					local off = d.Position - camPos
					local dist = off.Magnitude
					if dist > 0.4 and dist < 8 then
						local dot = off.Unit:Dot(look)
						if dot > 0.55 and dist * dot > maxDot then
							maxDot = dist * dot
							best = d.Position + look * (d.Size.Magnitude * 0.15)
						end
					end
				end
			end
		end)
		if best then return best end
		-- 3) fallback slightly in front of camera lower-right (gun hold)
		return (cam.CFrame * CFrame.new(0.55, -0.35, -1.6)).Position
	end

	local function aimDirection()
		local cam = workspace.CurrentCamera
		if not cam then return Vector3.zAxis end
		return cam.CFrame.LookVector
	end

	local function castHit(origin, look)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local exclude = {}
		pcall(function()
			if LP.Character then table.insert(exclude, LP.Character) end
			local cam = workspace.CurrentCamera
			if cam then table.insert(exclude, cam) end
			if tracerFolder then table.insert(exclude, tracerFolder) end
		end)
		params.FilterDescendantsInstances = exclude
		local result = workspace:Raycast(origin, look * 900, params)
		if result then return result.Position end
		return origin + look * 450
	end

	local lastShot = 0
	local lastM1 = 0
	pcall(function()
		local UIS = game:GetService("UserInputService")
		UIS.InputBegan:Connect(function(input, gpe)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				lastM1 = tick()
			end
		end)
	end)
	local lastPacketTracer = 0
	getgenv().MethaneNotePacketTracer = function()
		lastPacketTracer = tick()
	end
	local function onRealShot(originOverride, hitOverride)
		if not tracers.enabled then return end
		-- ignore equip / inspect / random muzzle FX — only while (or just after) real M1
		if tick() - lastM1 > 0.25 then return end
		-- packet-based tracer already drew this shot
		if tick() - lastPacketTracer < 0.05 then return end
		local now = tick()
		if now - lastShot < 0.03 then return end
		lastShot = now
		local origin = originOverride or findMuzzle()
		if not origin then return end
		local look = aimDirection()
		local hit = hitOverride or castHit(origin, look)
		if (hit - origin):Dot(look) < 0 then
			hit = castHit(origin, look)
		end
		fireTracer(origin, hit)
	end

	-- LOCAL shots only: ShootWeapon.Send + local viewmodel muzzle under camera
	local function argsAreLocal(...)
		for i = 1, select("#", ...) do
			local a = select(i, ...)
			if a == LP or a == LocalPlayer then return true end
			if typeof(a) == "Instance" then
				if a == LP or a == LP.Character then return true end
				if a:IsA("Player") and a == LP then return true end
			elseif type(a) == "table" then
				if a.Player == LP or a.LocalPlayer == LP or a.IsLocal == true then return true end
				if a.Owner == LP or a.Character == LP.Character then return true end
			end
		end
		return false
	end

	task.spawn(function()
		for _ = 1, 40 do
			local hooked = false
			pcall(function()
				for _, obj in next, getgc(true) do
					if type(obj) ~= "table" then continue end
					local sw = rawget(obj, "ShootWeapon")
					if type(sw) == "table" and not sw._methaneTracer then
						-- ONLY local outbound Send (not Connect/Listen — those are everyone)
						for _, nm in ipairs({ "Send", "Fire" }) do
							local fn = sw[nm]
							if type(fn) == "function" then
								sw[nm] = function(...)
									pcall(onRealShot)
									return fn(...)
								end
							end
						end
						sw._methaneTracer = true
						hooked = true
					end
					local mf = rawget(obj, "CreateCharacterMuzzleFlash")
					if type(mf) == "table" and not mf._methaneTracer then
						-- local Send only
						for _, nm in ipairs({ "Send", "Fire" }) do
							local fn = mf[nm]
							if type(fn) == "function" then
								mf[nm] = function(...)
									-- if args include a player, require local
									local n = select("#", ...)
									if n == 0 or argsAreLocal(...) then
										pcall(onRealShot)
									end
									return fn(...)
								end
							end
						end
						mf._methaneTracer = true
						hooked = true
					end
				end
			end)
			if hooked then break end
			task.wait(0.4)
		end
	end)

	-- Local viewmodel only: flash/muzzle under CurrentCamera (our FP gun)
	pcall(function()
		local function hookCam(c)
			if not c then return end
			c.DescendantAdded:Connect(function(inst)
				if not tracers.enabled then return end
				-- must live under our camera (local viewmodel), not world
				if not inst:IsDescendantOf(c) then return end
				local n = string.lower(inst.Name)
				if n:find("flash", 1, true) or n:find("muzzle", 1, true) then
					task.defer(onRealShot)
				end
			end)
		end
		hookCam(workspace.CurrentCamera)
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			hookCam(workspace.CurrentCamera)
		end)
	end)

	getgenv().MethaneFireTracer = fireTracer

	-- Hitmarkers: world billboard at real bullet impact on enemy body
	local hmFolder = nil
	local function ensureHmFolder()
		if hmFolder and hmFolder.Parent then return hmFolder end
		hmFolder = Instance.new("Folder")
		hmFolder.Name = "MethaneHitmarks"
		hmFolder.Parent = workspace
		return hmFolder
	end

	local function hitIsEnemyBody(inst)
		if not inst or not inst:IsA("BasePart") then return false end
		local model = inst:FindFirstAncestorOfClass("Model")
		if not model then return false end
		local lpChar = nil
		pcall(function() lpChar = LP.Character end)
		if lpChar and (model == lpChar or inst:IsDescendantOf(lpChar)) then return false end
		-- Characters folder / player models
		local chars = workspace:FindFirstChild("Characters")
		if chars and model:IsDescendantOf(chars) then
			if model.Name == (LP and LP.Name) then return false end
			return true
		end
		local plr = Players:GetPlayerFromCharacter(model)
		if plr and plr ~= LP then return true end
		-- named hitboxes common in FPS
		local n = inst.Name:lower()
		if n:find("head") or n:find("torso") or n:find("arm") or n:find("leg") or n:find("root") or n:find("hitbox") then
			if model ~= workspace and model ~= workspace.Terrain then return true end
		end
		return false
	end

	local function spawnHitmark(worldPos, hitPart)
		if not hitmarks.enabled then return end
		if typeof(worldPos) ~= "Vector3" then return end
		local folder = ensureHmFolder()
		local life = math.clamp(hitmarks.lifetime or 0.45, 0.1, 2)
		local sz = math.clamp(hitmarks.size or 42, 16, 120)
		local c1 = hitmarks.color1 or Color3.fromRGB(255, 255, 255)
		local c2 = hitmarks.color2 or Color3.fromRGB(255, 105, 180)

		local anchor = Instance.new("Part")
		anchor.Name = "HitmarkAnchor"
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.CastShadow = false
		anchor.Transparency = 1
		anchor.Size = Vector3.new(0.15, 0.15, 0.15)
		anchor.CFrame = CFrame.new(worldPos)
		anchor.Parent = folder

		local bb = Instance.new("BillboardGui")
		bb.Name = "Hitmark"
		bb.AlwaysOnTop = true
		bb.LightInfluence = 0
		bb.Size = UDim2.fromOffset(sz, sz)
		bb.StudsOffset = Vector3.new(0, 0, 0)
		bb.MaxDistance = 800
		bb.Adornee = anchor
		bb.Parent = anchor

		local img = Instance.new("ImageLabel")
		img.Name = "Icon"
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Position = UDim2.fromScale(0, 0)
		img.Image = "rbxassetid://5544798810"
		img.ImageColor3 = Color3.new(1, 1, 1)
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = bb

		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, c1),
			ColorSequenceKeypoint.new(0.5, c1:Lerp(c2, 0.5)),
			ColorSequenceKeypoint.new(1, c2),
		})
		grad.Rotation = 45
		grad.Parent = img

		local t0 = os.clock()
		local conn
		conn = RunService.RenderStepped:Connect(function()
			local age = os.clock() - t0
			if age >= life or not anchor.Parent then
				if conn then conn:Disconnect() end
				pcall(function() anchor:Destroy() end)
				return
			end
			local u = age / life
			-- pop in then fade
			local scale = (u < 0.12) and (0.55 + u / 0.12 * 0.55) or (1 - (u - 0.12) / 0.88 * 0.25)
			bb.Size = UDim2.fromOffset(sz * scale, sz * scale)
			img.ImageTransparency = math.clamp((u - 0.35) / 0.65, 0, 1)
			if hitmarks.rotate then
				img.Rotation = age * 360 * 1.35
				grad.Rotation = 45 + age * 90
			end
			-- stick to part if still exists
			if hitPart and hitPart.Parent then
				-- keep world hit point; slight drift toward part center looks weird — stay fixed
			end
		end)
		Debris:AddItem(anchor, life + 0.1)
	end

	getgenv().MethaneSpawnHitmark = spawnHitmark
	getgenv().MethaneHitIsEnemy = hitIsEnemyBody
end

-- VISUALS · ESP (all player ESP on one sub-tab)
----------------------------------------------------------------
VisESP:AddSection("Master")
bindToggleKey(VisESP, "ESPMaster", "Enabled", false, function(v) if ESP then ESP.enabled = v end end)
bindToggle(VisESP, "ESPTeamCheck", "Team Check", false, function(v) if ESP then ESP.teamcheck = v end end)
bindSlider(VisESP, "ESPMaxDist", "Max Distance", 1500, 50, 5000, 0, function(v) if ESP then ESP.max_distance = v end end, "m")

VisESP:AddSection("Box")
bindToggleKey(VisESP, "ESPBox", "Enabled", false, function(v) if ESP and ESP.box then ESP.box.enabled = v end end)
bindDropdown(VisESP, "ESPBoxMode", "Mode", { "Full", "Corner" }, "Full", function(v) if ESP and ESP.box then ESP.box.mode = v end end)
bindSlider(VisESP, "ESPBoxThick", "Thickness", 1, 1, 6, 0, function(v) if ESP and ESP.box then ESP.box.thickness = v end end, "px")
bindToggle(VisESP, "ESPBoxOutline", "Outline", true, function(v) if ESP and ESP.box then ESP.box.outline = v end end)
bindColor(VisESP, "ESPBoxOutlineCol", "Outline Color", Color3.new(0,0,0), function(c) if ESP and ESP.box then ESP.box.outline_color = c end end)
bindColor(VisESP, "ESPBoxCol", "Color", Color3.new(1,1,1), function(c) if ESP and ESP.box then ESP.box.color = c end end)
bindColor(VisESP, "ESPBoxCol2", "Color 2", Color3.fromRGB(255,60,60), function(c) if ESP and ESP.box then ESP.box.color2 = c end end)
bindToggle(VisESP, "ESPBoxGrad", "Gradient", false, function(v) if ESP and ESP.box then ESP.box.gradient = v end end)
bindToggle(VisESP, "ESPBoxFill", "Fill", false, function(v) if ESP and ESP.box then ESP.box.fill = v end end)
bindColor(VisESP, "ESPBoxFillCol", "Fill Color", Color3.new(1,1,1), function(c) if ESP and ESP.box then ESP.box.fill_color = c end end)
bindSlider(VisESP, "ESPBoxFillTrans", "Fill Transparency", 0.7, 0, 1, 2, function(v) if ESP and ESP.box then ESP.box.fill_transparency = v end end)

VisESP:AddSection("Chams")
bindToggleKey(VisESP, "ESPChams", "Enabled", false, function(v) if ESP and ESP.chams then ESP.chams.enabled = v end end)
bindDropdown(VisESP, "ESPChamsMode", "Mode", { "Fill", "Flow", "Flat" }, "Fill", function(v) if ESP and ESP.chams then ESP.chams.mode = v end end)
bindColor(VisESP, "ESPChamsCol", "Fill Color", Color3.fromRGB(120,170,255), function(c) if ESP and ESP.chams then ESP.chams.fill_color = c end end)
bindColor(VisESP, "ESPChamsCol2", "Fill Color 2", Color3.fromRGB(255,60,60), function(c) if ESP and ESP.chams then ESP.chams.fill_color2 = c end end)
bindSlider(VisESP, "ESPChamsTrans", "Fill Transparency", 0.55, 0, 1, 2, function(v) if ESP and ESP.chams then ESP.chams.fill_transparency = v end end)
bindSlider(VisESP, "ESPChamsOutTrans", "Outline Transparency", 0.15, 0, 1, 2, function(v) if ESP and ESP.chams then ESP.chams.outline_transparency = v end end)
bindToggle(VisESP, "ESPChamsVis", "Visible Only", false, function(v) if ESP and ESP.chams then ESP.chams.visible_only = v end end)

VisESP:AddSection("Skeleton")
bindToggle(VisESP, "ESPSkeleton", "Enabled", false, function(v) if ESP and ESP.skeleton then ESP.skeleton.enabled = v end end)
bindColor(VisESP, "ESPSkelCol", "Color", Color3.new(1,1,1), function(c) if ESP and ESP.skeleton then ESP.skeleton.color = c end end)
bindToggle(VisESP, "ESPSkelGrad", "Gradient", false, function(v) if ESP and ESP.skeleton then ESP.skeleton.gradient = v end end)
bindToggle(VisESP, "ESPHeadDot", "Head Dot", false, function(v) if ESP and ESP.skeleton then ESP.skeleton.headdot = v end end)
bindColor(VisESP, "ESPHeadDotCol", "Head Dot Color", Color3.new(1,1,1), function(c) if ESP and ESP.skeleton then ESP.skeleton.headdot_color = c end end)

VisESP:AddSection("Health")
bindToggle(VisESP, "ESPHealth", "Enabled", false, function(v) if ESP and ESP.health then ESP.health.enabled = v end end)
bindColor(VisESP, "ESPHpCol1", "High", Color3.fromRGB(80,255,120), function(c) if ESP and ESP.health then ESP.health.color1 = c end end)
bindColor(VisESP, "ESPHpCol2", "Mid", Color3.fromRGB(255,220,60), function(c) if ESP and ESP.health then ESP.health.color2 = c end end)
bindColor(VisESP, "ESPHpCol3", "Low", Color3.fromRGB(255,60,60), function(c) if ESP and ESP.health then ESP.health.color3 = c end end)
bindToggle(VisESP, "ESPHpText", "HP Text", true, function(v) if ESP and ESP.health then ESP.health.text = v end end)
bindSlider(VisESP, "ESPHpTextSize", "HP Text Size", 11, 8, 20, 0, function(v) if ESP and ESP.health then ESP.health.text_size = v end end, "px")

VisESP:AddSection("Tracers")
bindToggle(VisESP, "ESPTracer", "Enabled", false, function(v) if ESP and ESP.tracer then ESP.tracer.enabled = v end end)
bindColor(VisESP, "ESPTracerCol", "Color", Color3.new(1,1,1), function(c) if ESP and ESP.tracer then ESP.tracer.color = c end end)
bindDropdown(VisESP, "ESPTracerOrigin", "Origin", { "Bottom", "Top", "Center", "Mouse" }, "Bottom", function(v) if ESP and ESP.tracer then ESP.tracer.origin = v end end)
bindToggle(VisESP, "ESPTracerOutline", "Outline", true, function(v) if ESP and ESP.tracer then ESP.tracer.outline = v end end)

VisESP:AddSection("Flags")
bindToggle(VisESP, "ESPName", "Username", false, function(v) if ESP and ESP.flags then ESP.flags.name = v end end)
bindColor(VisESP, "ESPNameCol", "Name Color", Color3.new(1,1,1), function(c) if ESP and ESP.flags then ESP.flags.name_color = c end end)
bindToggle(VisESP, "ESPDistance", "Distance", false, function(v) if ESP and ESP.flags then ESP.flags.distance = v end end)
bindColor(VisESP, "ESPDistCol", "Distance Color", Color3.fromRGB(200,200,200), function(c) if ESP and ESP.flags then ESP.flags.distance_color = c end end)
bindToggle(VisESP, "ESPWeapon", "Weapon", false, function(v) if ESP and ESP.flags then ESP.flags.weapon = v end end)
bindColor(VisESP, "ESPWepCol", "Weapon Color", Color3.new(1,1,1), function(c) if ESP and ESP.flags then ESP.flags.weapon_color = c end end)
bindToggle(VisESP, "ESPWeaponIcon", "Weapon Icon", false, function(v) if ESP and ESP.flags then ESP.flags.weapon_icon = v end end)
bindToggle(VisESP, "ESPKit", "Defuse Kit", false, function(v) if ESP and ESP.flags then ESP.flags.kit = v end end)
bindColor(VisESP, "ESPKitCol", "Kit Color", Color3.fromRGB(100,200,255), function(c) if ESP and ESP.flags then ESP.flags.kit_color = c end end)
bindToggle(VisESP, "ESPBomb", "Bomb / C4", false, function(v) if ESP and ESP.flags then ESP.flags.bomb = v end end)
bindColor(VisESP, "ESPBombCol", "Bomb Color", Color3.fromRGB(255,80,80), function(c) if ESP and ESP.flags then ESP.flags.bomb_color = c end end)
bindToggle(VisESP, "ESPDefusing", "Defusing", false, function(v) if ESP and ESP.flags then ESP.flags.defusing = v end end)
bindColor(VisESP, "ESPDefusingCol", "Defusing Color", Color3.fromRGB(255,200,80), function(c) if ESP and ESP.flags then ESP.flags.defusing_color = c end end)
bindToggle(VisESP, "ESPPlanting", "Planting", false, function(v) if ESP and ESP.flags then ESP.flags.planting = v end end)
bindColor(VisESP, "ESPPlantingCol", "Planting Color", Color3.fromRGB(255,160,60), function(c) if ESP and ESP.flags then ESP.flags.planting_color = c end end)
bindToggle(VisESP, "ESPMoney", "Money", false, function(v) if ESP and ESP.flags then ESP.flags.money = v end end)
bindColor(VisESP, "ESPMoneyCol", "Money Color", Color3.fromRGB(60,255,100), function(c) if ESP and ESP.flags then ESP.flags.money_color = c end end)
bindToggle(VisESP, "ESPMs", "MS / Ping", false, function(v) if ESP and ESP.flags then ESP.flags.ms = v end end)
bindColor(VisESP, "ESPMsCol", "MS Color", Color3.fromRGB(200,200,200), function(c) if ESP and ESP.flags then ESP.flags.ms_color = c end end)
bindToggle(VisESP, "ESPKd", "K/D", false, function(v) if ESP and ESP.flags then ESP.flags.kd = v end end)
bindColor(VisESP, "ESPKdCol", "K/D Color", Color3.fromRGB(90,140,255), function(c) if ESP and ESP.flags then ESP.flags.kd_color = c end end)
bindToggle(VisESP, "ESPFlash", "Flashed", false, function(v) if ESP and ESP.flags then ESP.flags.flashed = v end end)
bindColor(VisESP, "ESPFlashCol", "Flashed Color", Color3.fromRGB(255,255,100), function(c) if ESP and ESP.flags then ESP.flags.flashed_color = c end end)
bindToggle(VisESP, "ESPCrouch", "Crouched", false, function(v) if ESP and ESP.flags then ESP.flags.crouch = v end end)
bindColor(VisESP, "ESPCrouchCol", "Crouch Color", Color3.fromRGB(180,180,255), function(c) if ESP and ESP.flags then ESP.flags.crouch_color = c end end)

----------------------------------------------------------------
-- VISUALS · World (lighting, sky, view, world ESP, extra)
----------------------------------------------------------------
VisWorld:AddSection("Lighting")
bindToggle(VisWorld, "WorldFullbright", "Fullbright", false)
bindSlider(VisWorld, "WorldBrightness", "Brightness", 2, 0, 10, 1)
bindSlider(VisWorld, "WorldClock", "Clock Time", 14, 0, 24, 1)
bindSlider(VisWorld, "WorldExposure", "Exposure", 0, -5, 5, 2)

VisWorld:AddSection("Ambience")
bindToggle(VisWorld, "WorldAmbientEnabled", "Enabled", false)
bindColor(VisWorld, "WorldAmbient", "Ambient", Color3.fromRGB(128, 128, 128))
bindColor(VisWorld, "WorldOutdoorAmbient", "Outdoor Ambient", Color3.fromRGB(128, 128, 128))
bindColor(VisWorld, "WorldColorShiftTop", "Color Shift Top", Color3.fromRGB(0, 0, 0))
bindColor(VisWorld, "WorldColorShiftBot", "Color Shift Bottom", Color3.fromRGB(0, 0, 0))

VisWorld:AddSection("Color Correction")
bindToggle(VisWorld, "WorldCC", "Enabled", false)
bindSlider(VisWorld, "WorldCCBright", "Brightness", 0, -1, 1, 2)
bindSlider(VisWorld, "WorldCCContrast", "Contrast", 0, -1, 1, 2)
bindSlider(VisWorld, "WorldCCSat", "Saturation / Vibrance", 0, -1, 2, 2)
bindColor(VisWorld, "WorldCCTint", "Tint", Color3.fromRGB(255, 255, 255))

VisWorld:AddSection("Skybox")
bindToggle(VisWorld, "WorldSkybox", "Enabled", false)
bindDropdown(VisWorld, "WorldSkyboxPreset", "Preset", {
	"None", "Aurora", "Battlerock", "Beach Bowl", "Buoy Base", "Clockwork",
	"Dark Matter", "Flash Black", "Ghostly", "Good Egg", "Melty Molten",
	"Shiverburn", "Spin Dig", "Sweet Mystery", "Terrace Dome",
}, "None")
bindToggle(VisWorld, "WorldSkyRotate", "Auto Rotate", false)
bindSlider(VisWorld, "WorldSkyRotateSpeed", "Rotate Speed", 1, 0.1, 10, 1)

----------------------------------------------------------------
-- MISC · World (items / bomb / grenades)
----------------------------------------------------------------
MiscWorld:AddSection("Dropped Guns")
bindToggle(MiscWorld, "WESP_GunEnabled", "Enabled", false)
bindToggle(MiscWorld, "WESP_GunIcon", "Icons", true)
bindColor(MiscWorld, "WESP_GunIconCol", "Icon Color", Color3.fromRGB(255,255,255))
bindColor(MiscWorld, "WESP_GunShadowCol", "Dropshadow Color", Color3.fromRGB(0,0,0))
bindToggle(MiscWorld, "WESP_GunName", "Show Name", true)
bindColor(MiscWorld, "WESP_GunNameCol", "Name Color", Color3.fromRGB(255,255,255))
bindToggle(MiscWorld, "WESP_GunChams", "Chams", false)
bindColor(MiscWorld, "WESP_GunChamsCol", "Chams Color", Color3.fromRGB(255,255,255))
bindSlider(MiscWorld, "WESP_GunChamsTrans", "Chams Transparency", 0.45, 0, 1, 2)

MiscWorld:AddSection("Planted Bomb")
bindToggle(MiscWorld, "WESP_BombEnabled", "Enabled", false)
bindToggle(MiscWorld, "WESP_BombIcon", "Icons", true)
bindToggle(MiscWorld, "WESP_BombName", "Show Name", true)
bindColor(MiscWorld, "WESP_BombNameCol", "Name Color", Color3.fromRGB(255,255,255))
bindToggle(MiscWorld, "WESP_BombChams", "Chams", false)
bindColor(MiscWorld, "WESP_BombChamsCol", "Chams Color", Color3.fromRGB(255,255,255))
bindColor(MiscWorld, "WESP_BombUrgentCol", "Urgent Color", Color3.fromRGB(255,40,40))
bindSlider(MiscWorld, "WESP_BombChamsTrans", "Chams Transparency", 0.4, 0, 1, 2)

MiscWorld:AddSection("Grenades")
bindToggle(MiscWorld, "GrenadeEnabled", "Enabled", false)
bindToggle(MiscWorld, "GrenadePrediction", "Prediction", true)
bindToggle(MiscWorld, "GrenadeIcons", "Icons", true)
bindToggle(MiscWorld, "GrenadeNames", "Names", true)
bindToggle(MiscWorld, "GrenadeTrails", "Trails", false)
bindToggle(MiscWorld, "GrenadeBounces", "Bounces", false)
bindToggle(MiscWorld, "GrenadeEndpoint", "Landing", false)
bindToggle(MiscWorld, "GrenadeBox", "Box", false)
bindColor(MiscWorld, "GrenadePredColor1", "Prediction Color", Color3.fromRGB(115, 238, 159))
bindSlider(MiscWorld, "GrenadeHorizon", "Predict Length", 5, 1, 10, 1, nil, "s")
bindSlider(MiscWorld, "GrenadeRefresh", "Predict Refresh", 6, 2, 15, 0, nil, " /s")
bindSlider(MiscWorld, "GrenadeMaxDistance", "Max Distance", 1500, 100, 5000, 0, nil, " studs")
bindSlider(MiscWorld, "GrenadeThickness", "Line Thickness", 1.5, 0.5, 4, 1)
bindSlider(MiscWorld, "GrenadeOpacity", "Opacity", 100, 10, 100, 0, nil, "%")
bindSlider(MiscWorld, "GrenadeTrailTime", "Trail Time", 4, 1, 10, 1, nil, "s")

MiscWorld:AddSection("Grenade Types")
bindToggle(MiscWorld, "GrenadeHE", "HE Grenade", true)
bindColor(MiscWorld, "GrenadeHEColor", "HE Color", Color3.fromRGB(255, 90, 90))
bindToggle(MiscWorld, "GrenadeFlash", "Flashbang", true)
bindColor(MiscWorld, "GrenadeFlashColor", "Flash Color", Color3.fromRGB(245, 245, 120))
bindToggle(MiscWorld, "GrenadeDecoy", "Decoy Grenade", true)
bindColor(MiscWorld, "GrenadeDecoyColor", "Decoy Color", Color3.fromRGB(200, 200, 100))

MiscWorld:AddSection("Grenade Timers")
bindToggle(MiscWorld, "GrenadeTimers", "Enabled", true)
bindToggle(MiscWorld, "GrenadeSmoke", "Smoke Grenade", true)
bindColor(MiscWorld, "GrenadeSmokeColor", "Smoke Color", Color3.fromRGB(150, 150, 160))
bindToggle(MiscWorld, "GrenadeMolotov", "Molotov", true)
bindColor(MiscWorld, "GrenadeMolotovColor", "Molotov Color", Color3.fromRGB(255, 140, 40))
bindToggle(MiscWorld, "GrenadeIncendiary", "Incendiary", true)
bindColor(MiscWorld, "GrenadeIncendiaryColor", "Incendiary Color", Color3.fromRGB(255, 100, 40))

----------------------------------------------------------------
-- VISUALS · Self (viewmodel / camera / local)
----------------------------------------------------------------
VisSelf:AddSection("Camera")
bindToggle(VisSelf, "WorldFovEnabled", "FOV Changer", false)
bindSlider(VisSelf, "WorldFov", "FOV", 70, 10, 120, 0, nil, "°")
bindSlider(VisSelf, "WorldResolution", "Resolution", 1, 0.1, 1, 2)

VisSelf:AddSection("Third Person")
bindToggleKey(VisSelf, "WorldThirdPerson", "Enabled", false, function(v)
	pcall(function() if setThirdPerson then setThirdPerson(v) end end)
end)
bindSlider(VisSelf, "WorldThirdDist", "Distance", 8, 2, 20, 1, nil, "studs")

VisSelf:AddSection("Self Chams")
bindToggle(VisSelf, "WorldArmsEnabled", "Customize hands", false)
bindColor(VisSelf, "WorldArmsCol", "Color", Color3.fromRGB(120, 170, 255))
bindDropdown(VisSelf, "WorldArmsMat", "Material", { "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Metal", "Foil", "Ice" }, "ForceField")
bindSlider(VisSelf, "WorldArmsTrans", "Transparency", 0.3, 0, 1, 2)

VisSelf:AddSection("Gun Chams")
bindToggle(VisSelf, "WorldWeaponEnabled", "Customize weapon", false)
bindColor(VisSelf, "WorldWeaponCol", "Color", Color3.fromRGB(120, 170, 255))
bindDropdown(VisSelf, "WorldWeaponMat", "Material", { "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Metal", "Foil", "Ice" }, "ForceField")
bindSlider(VisSelf, "WorldWeaponTrans", "Transparency", 0.3, 0, 1, 2)

VisSelf:AddSection("Viewmodel position")
bindToggle(VisSelf, "WorldViewPosEnabled", "Custom viewmodel position", false)
bindToggle(VisSelf, "WorldViewPosScoped", "Default position while aiming", false)
bindSlider(VisSelf, "WorldViewX", "Horizontal offset", 0, -2, 2, 2, nil, " studs")
bindSlider(VisSelf, "WorldViewY", "Vertical offset", 0, -2, 2, 2, nil, " studs")
bindSlider(VisSelf, "WorldViewZ", "Depth offset", 0, -2, 2, 2, nil, " studs")
bindSlider(VisSelf, "WorldViewPitch", "Pitch", 0, -45, 45, 0, nil, "°")
bindSlider(VisSelf, "WorldViewYaw", "Yaw", 0, -45, 45, 0, nil, "°")
bindSlider(VisSelf, "WorldViewRoll", "Roll", 0, -90, 90, 0, nil, "°")

VisSelf:AddSection("Model Chams")
bindToggle(VisSelf, "WorldModelChams", "Enabled", false)
VisSelf:AddLabel("Third person body chams")
bindDropdown(VisSelf, "WorldModelChamsMat", "Material", { "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Metal", "Foil", "Ice" }, "ForceField")
bindColor(VisSelf, "WorldModelChamsCol", "Color", Color3.fromRGB(120, 170, 255))
bindSlider(VisSelf, "WorldModelChamsTrans", "Transparency", 0.3, 0, 1, 2)

VisSelf:AddSection("Extra")
bindToggle(VisSelf, "Antismoke", "No Smoke", false)
bindToggle(VisSelf, "AntiFlash", "No Flash", false)

SkinMain:AddSection("Weapon")
bindToggle(SkinMain, "SkinEnabled", "Enabled", false)
bindDropdown(SkinMain, "SkinWeapon", "Weapon", { "Original" }, "Original")
bindDropdown(SkinMain, "SkinFinish", "Skin", { "Original" }, "Original")
bindButton(SkinMain, "Refresh Catalog", function()
	pcall(function()
		if SkinChanger and SkinChanger.RefreshCatalog then
			SkinChanger:RefreshCatalog()
			if SkinChanger.Weapons then
				skinSetDropdown("SkinWeapon", SkinChanger.Weapons, SkinChanger.Weapons[1])
			end
			pcall(function() if SkinChanger.SyncFromWeapon then SkinChanger:SyncFromWeapon() end end)
			pcall(function() if SkinChanger.SyncKnife then SkinChanger:SyncKnife() end end)
		end
	end)
end)
bindButton(SkinMain, "Apply / Equip", function()
	pcall(function()
		if SkinChanger then
			if SkinChanger.Apply then SkinChanger:Apply() end
			if SkinChanger.EquipSelected then SkinChanger:EquipSelected() end
		end
	end)
end)
bindButton(SkinMain, "Save Loadout", function()
	pcall(function() if skinWriteLoadout then skinWriteLoadout() end end)
end)

SkinMain:AddSection("Knife")
bindToggle(SkinMain, "KnifeSkinEnabled", "Enabled", false)
bindDropdown(SkinMain, "SkinKnifeModel", "Model", { "Original" }, "Original")
bindDropdown(SkinMain, "SkinKnifeFinish", "Skin", { "Original" }, "Original")

SkinMain:AddSection("Gloves")
bindToggle(SkinMain, "GloveSkinEnabled", "Enabled", false)
bindDropdown(SkinMain, "SkinGloveModel", "Model", { "Original" }, "Original")
bindDropdown(SkinMain, "SkinGloveFinish", "Skin", { "Original" }, "Original")
bindButton(SkinMain, "Refresh Gloves", function()
	pcall(function()
		if SkinChanger and SkinChanger.RefreshCatalog then
			SkinChanger:RefreshCatalog()
			if SkinChanger.RefreshEditor then SkinChanger:RefreshEditor() end
		end
	end)
end)

SkinModels:AddSection("Model Changer")
bindToggle(SkinModels, "ModelChanger", "Enabled", false, function(v)
	pcall(function()
		if getgenv().MethaneModelChanger then
			if v then getgenv().MethaneModelChanger.apply() else getgenv().MethaneModelChanger.clear() end
		end
	end)
end)
bindDropdown(SkinModels, "ModelPreset", "Model", {
	"Triple T",
	"Shrek",
	"Verity",
	"Granny",
	"Xor",
	"Steve",
	"Shitter",
}, "Triple T", function()
	pcall(function()
		if getgenv().MethaneModelChanger and tv("ModelChanger") then
			getgenv().MethaneModelChanger.apply()
		end
	end)
end)
bindSlider(SkinModels, "ModelScale", "Scale", 1, 0.25, 3, 2, nil, "x")
bindToggle(SkinModels, "ModelHideBody", "Hide original body", true)
bindButton(SkinModels, "Load / Apply Model", function()
	pcall(function()
		if getgenv().MethaneModelChanger then
			getgenv().MethaneModelChanger.apply()
		end
	end)
end)

----------------------------------------------------------------
-- MOVEMENT
----------------------------------------------------------------
MovPlayer:AddSection("Movement")
bindToggleKey(MovPlayer, "MovBhop", "Bhop", false, nil)
bindToggle(MovPlayer, "MovAutoStrafe", "Autostrafe", false)
MovPlayer:AddSection("Anti Aim")
bindToggleKey(MovPlayer, "AntiAim", "Enabled", false, nil)
bindDropdown(MovPlayer, "AAPitch", "Pitch", { "Off", "Down", "Up", "Custom" }, "Off")
bindSlider(MovPlayer, "AAPitchCustom", "Custom Pitch", 0, -1, 1, 2)
bindToggle(MovPlayer, "AAJitter", "Jitter", false)
bindDropdown(MovPlayer, "AAJitterType", "Jitter Type", { "3-Way", "1-Way", "Up", "Down" }, "3-Way")
bindSlider(MovPlayer, "AAJitterSpeed", "Jitter Speed", 50, 1, 200, 0, nil, "ms")
bindSlider(MovPlayer, "AAJitterAngle", "Jitter Angle", 60, 0, 180, 0, nil, "°")
bindToggle(MovPlayer, "AASpin", "Spinbot", false)
bindSlider(MovPlayer, "AASpinSpeed", "Spin Speed", 360, 30, 1440, 0, nil, "°/s")
bindDropdown(MovPlayer, "AAYawMode", "Yaw Base", { "Off", "Backward", "Face Enemies", "Back to Enemies" }, "Off")
bindSlider(MovPlayer, "AAYawOffset", "Yaw Offset", 180, -180, 180, 0, nil, "°")

----------------------------------------------------------------
-- Widgets
----------------------------------------------------------------

-- ESP Preview removed

pcall(function()
	Library:RegisterSettingsWidget({ Name = "Watermark", Default = true, Callback = function(v)
		local wm = getgenv().MethaneWatermark
		if wm and wm.SetVisibility then wm:SetVisibility(v) end
	end })
end)
pcall(function()
	local MethanePlayerlist
	if Library.Playerlist then MethanePlayerlist = Library:Playerlist({ Name = "Player List" }) end
	if MethanePlayerlist then
		pcall(function() if MethanePlayerlist.SetText then MethanePlayerlist:SetText("Player List") end end)
		task.spawn(function()
			local lastFlag
			while true do
				task.wait(0.25)
				pcall(function()
					local flags = Library.Flags or {}
					local cur = flags.PlayerlistStatus
					if type(cur) == "table" then cur = cur.Value or cur[1] or cur end
					if cur ~= nil and tostring(cur) ~= tostring(lastFlag) then
						lastFlag = cur
						local st = tostring(cur)
						for _, pd in pairs(MethanePlayerlist.Players or {}) do
							if pd and pd.IsSelected then
								pcall(function() pd.Status = st end)
								pcall(function()
									if pd.Items and pd.Items.Status and pd.Items.Status.Instance then
										pd.Items.Status.Instance.Text = st
									end
								end)
							end
						end
						pcall(function()
							if MethanePlayerlist.Selected then MethanePlayerlist.Selected.Status = st end
						end)
					end
					pcall(function() syncPlayerFlagsFromList(MethanePlayerlist) end)
				end)
			end
		end)
		Players.PlayerRemoving:Connect(function(plr)
			PlayerFlags.whitelist[plr.UserId] = nil
			PlayerFlags.priority[plr.UserId] = nil
		end)
		Library:RegisterSettingsWidget({ Name = "Player List", Default = true, Callback = function(v)
			if MethanePlayerlist and MethanePlayerlist.SetVisibility then
				pcall(function() MethanePlayerlist:SetVisibility(v) end)
			end
		end })
		pcall(function() MethanePlayerlist:SetVisibility(true) end)
		getgenv().MethanePlayerlist = MethanePlayerlist
		-- Only show enemies (same teamcheck as ESP: IsEnemy == same team → hide)
		-- Enemy names red
		task.spawn(function()
			while true do
				task.wait(0.35)
				pcall(function()
					local pl = getgenv().MethanePlayerlist
					if not pl or type(pl.Players) ~= "table" then return end
					for _, pd in pairs(pl.Players) do
						local plr = pd and pd.Player
						if not plr then continue end
						local sameTeam = false
						pcall(function() sameTeam = IsEnemy(plr) == true end)
						local row = pd.Items and pd.Items.NewPlayer and pd.Items.NewPlayer.Instance
						if sameTeam then
							-- hide teammates
							pcall(function() if row then row.Visible = false end end)
						else
							pcall(function()
								if row then row.Visible = true end
								local col = Color3.fromRGB(255, 80, 80)
								if row then
									for _, d in ipairs(row:GetDescendants()) do
										if d:IsA("TextLabel") then
											d.TextColor3 = col
										end
									end
								end
							end)
						end
					end
				end)
			end
		end)

	end
end)
pcall(function()
	if type(Library.TargetIndicator) == "function" then
		local MethaneTargetHUD = Library:TargetIndicator()
		if MethaneTargetHUD and MethaneTargetHUD.SetVisibility then MethaneTargetHUD:SetVisibility(false) end
		Library:RegisterSettingsWidget({ Name = "Target HUD", Default = true, Callback = function(v)
			getgenv().MethaneTargetHUDEnabled = v == true
			if not v then
				pcall(function()
					if MethaneTargetHUD.SetTarget then MethaneTargetHUD:SetTarget(nil) end
					if MethaneTargetHUD.SetVisibility then MethaneTargetHUD:SetVisibility(false) end
				end)
			end
		end })
getgenv().MethaneTargetHUDEnabled = true
		getgenv().MethaneTargetHUD = MethaneTargetHUD
		task.spawn(function()
			local lastUid = nil
			local stickyPlr, stickySource, stickyUntil = nil, nil, 0
			local sourceLabel
			pcall(function()
				if MethaneTargetHUD.AddItem then
					sourceLabel = MethaneTargetHUD:AddItem("mode: —")
				end
			end)
			local function setSourceText(text)
				pcall(function()
					if sourceLabel and sourceLabel.Instance then
						sourceLabel.Instance.Text = text
					end
				end)
			end

			local function resolveHP(plr)
				local char = getgenv().MethaneCurrentTargetModel
					or getgenv().MethaneSilentTargetModel
					or getgenv().MethaneAimbotTargetModel
					or getgenv().MethaneRageTargetModel
				if not (typeof(char) == "Instance" and char:IsA("Model") and char.Parent) then
					char = plr and plr.Character
				end
				if not char then return 0, 100 end
				if type(readBloxHealth) == "function" then
					local ok, h, m = pcall(readBloxHealth, char)
					if ok and type(h) == "number" then
						return h, (type(m) == "number" and m > 0) and m or 100
					end
					ok, h, m = pcall(readBloxHealth, plr)
					if ok and type(h) == "number" then
						return h, (type(m) == "number" and m > 0) and m or 100
					end
				end
				local h = char:GetAttribute("Health")
				if type(h) ~= "number" then h = char:GetAttribute("HP") end
				local m = char:GetAttribute("MaxHealth")
				if type(m) ~= "number" then m = char:GetAttribute("MaxHP") end
				if type(h) == "number" then
					if type(m) ~= "number" or m <= 0 then m = 100 end
					return h, m
				end
				return 0, 100
			end

			-- ensure hidden until first real lock
			pcall(function()
				if MethaneTargetHUD.SetVisibility then MethaneTargetHUD:SetVisibility(false) end
			end)

			while true do
				task.wait(0.05)
				pcall(function()
					local hud = getgenv().MethaneTargetHUD
					if not hud then return end

					if not getgenv().MethaneTargetHUDEnabled then
						lastUid = nil
						stickyPlr = nil
						pcall(function()
							if hud.SetTarget then hud:SetTarget(nil) end
							if hud.SetVisibility then hud:SetVisibility(false) end
						end)
						return
					end

					local target, source = nil, nil
					if tv("Ragebot") and getgenv().MethaneRageTarget then
						target, source = getgenv().MethaneRageTarget, "Ragebot"
					elseif tv("SilentAim") and getgenv().MethaneSilentTarget then
						target, source = getgenv().MethaneSilentTarget, "Silent Aim"
					elseif tv("Aimbot") and getgenv().MethaneAimbotTarget then
						target, source = getgenv().MethaneAimbotTarget, "Aimbot"
					elseif getgenv().MethaneCurrentTarget then
						target, source = getgenv().MethaneCurrentTarget, "Combat"
					end

					if typeof(target) == "Instance" and target:IsA("BasePart") then
						local model = target:FindFirstAncestorOfClass("Model")
						target = (model and Players:GetPlayerFromCharacter(model)) or model or target
					end
					if typeof(target) == "Instance" and target:IsA("Model") then
						target = Players:GetPlayerFromCharacter(target) or target
					end

					local now = os.clock()
					if typeof(target) == "Instance" and target:IsA("Player") then
						stickyPlr, stickySource, stickyUntil = target, source, now + 0.4
					elseif stickyPlr and now < stickyUntil then
						target, source = stickyPlr, stickySource
					else
						stickyPlr, stickySource = nil, nil
						target = nil
					end

					if typeof(target) == "Instance" and target:IsA("Player") then
						local uid = target.UserId
						if uid ~= lastUid then
							lastUid = uid
							-- only rebind name/avatar when the player changes (stops flash)
							pcall(function()
								if hud.SetTarget then hud:SetTarget(target) end
							end)
							pcall(function()
								if hud.SetVisibility then hud:SetVisibility(true) end
							end)
						else
							-- keep visible, do not re-call SetTarget
							pcall(function()
								if hud.SetVisibility then hud:SetVisibility(true) end
							end)
						end
						setSourceText("mode: " .. tostring(source or "Combat"))
						local h, m = resolveHP(target)
						pcall(function()
							if hud.SetHealth then
								hud:SetHealth(h, m)
							end
						end)
						-- hard write Items if exposed
						pcall(function()
							if hud.Items and hud.Items.Value and hud.Items.Value.Instance then
								hud.Items.Value.Instance.Text = string.format("%d/%d", math.floor(h + 0.5), math.floor(m + 0.5))
							end
							if hud.Items and hud.Items.HealthbarFill and hud.Items.HealthbarFill.Instance then
								hud.Items.HealthbarFill.Instance.Size = UDim2.new(math.clamp(h / m, 0, 1), 0, 1, 0)
								hud.Items.HealthbarFill.Instance.BackgroundTransparency = 0
							end
						end)
					else
						if lastUid ~= nil then
							lastUid = nil
							pcall(function()
								if hud.SetTarget then hud:SetTarget(nil) end
								if hud.SetVisibility then hud:SetVisibility(false) end
							end)
							setSourceText("mode: —")
						else
							pcall(function()
								if hud.SetVisibility then hud:SetVisibility(false) end
							end)
						end
					end
				end)
			end
		end)

	end
end)

pcall(function() Library_Window:CreateSettingsPage() end)

-- Auto-load config on startup (same as Rivals)
task.spawn(function()
	task.wait(0.85)
	pcall(function()
		local folder = tostring(Library.Directory or "MethaneUI")
			.. tostring(Library.Folders and Library.Folders.Configs or "/methane/cfgs/bloxstrike")
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


----------------------------------------------------------------
-- ORIGINAL GAME LOGIC (ESP / AA / combat / skins / world / movement)
----------------------------------------------------------------
local hitboxsafe = true
local ESP = {
	enabled = false,
	teamcheck = false,
	max_distance = 1500,
	box = {
		enabled = false, mode = "Full", thickness = 1,
		outline = true, outline_color = Color3.new(0, 0, 0),
		gradient = false, color = Color3.new(1, 1, 1), color2 = Color3.fromRGB(255, 60, 60),
		fill = false, fill_color = Color3.fromRGB(255, 255, 255), fill_transparency = 0.7,
	},
	chams = {
		enabled = false,
		mode = "Fill",
		fill_color = Color3.fromRGB(120, 170, 255),
		fill_color2 = Color3.fromRGB(255, 80, 180),
		fill_transparency = 0.55,
		outline_transparency = 0.15,
		visible_only = false,
	},
	skeleton = {
		enabled = false, thickness = 1.5,
		gradient = false, color = Color3.new(1, 1, 1), color2 = Color3.fromRGB(255, 60, 60),
		headdot = false, headdot_size = 4, headdot_color = Color3.new(1, 1, 1),
	},
	health = {
		enabled = false, width = 2,
		text = true, text_size = 11,
		color1 = Color3.fromRGB(0, 255, 80),
		color2 = Color3.fromRGB(255, 220, 40),
		color3 = Color3.fromRGB(255, 40, 40),
	},
	tracer = {
		enabled = false, origin = "Bottom", thickness = 1,
		color = Color3.new(1, 1, 1), outline = true, outline_color = Color3.new(0, 0, 0),
	},
	flags = {
		name = false, name_color = Color3.new(1, 1, 1), name_size = 12,
		distance = false, distance_color = Color3.new(1, 1, 1), distance_size = 11,
		weapon = false, weapon_color = Color3.new(1, 1, 1), weapon_size = 11,
		kit = false, kit_color = Color3.fromRGB(80, 180, 255),
		bomb = false, bomb_color = Color3.fromRGB(255, 60, 60),
		defusing = false, defusing_color = Color3.fromRGB(80, 160, 255),
		planting = false, planting_color = Color3.fromRGB(255, 140, 40),
		money = false, money_color = Color3.fromRGB(60, 255, 100),
		ms = false, ms_color = Color3.fromRGB(200, 200, 200),
		kd = false, kd_color = Color3.fromRGB(90, 140, 255),
		flashed = false, flashed_color = Color3.fromRGB(255, 255, 100),
		crouch = false, crouch_color = Color3.fromRGB(180, 180, 255),
		right_size = 10,
	},
}
getgenv().VantaBloxESP = ESP

-- (ESP UI is on Visuals → ESP; original entity sub-tab binds removed)

-- ESP drawing
----------------------------------------------------------------
local SKELETON_BONES_R6 = {
	{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local SKELETON_BONES_R15 = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}

local ESPF = {}
function ESPF.lerpColor(a, b, t)
	return Color3.new(
		a.R + (b.R - a.R) * t,
		a.G + (b.G - a.G) * t,
		a.B + (b.B - a.B) * t
	)
end

function ESPF.healthGradient(frac)
	frac = math.clamp(frac, 0, 1)
	if frac > 0.5 then
		return ESPF.lerpColor(ESP.health.color2, ESP.health.color1, (frac - 0.5) * 2)
	end
	return ESPF.lerpColor(ESP.health.color3, ESP.health.color2, frac * 2)
end

function ESPF.newDraw(kind)
	local ok, o = pcall(Drawing.new, kind)
	if not (ok and o) then return nil end
	o.Visible = false
	o.Transparency = 1
	o.ZIndex = 2
	return o
end

local BOX_EDGE_N = 2 + 8 * 2 -- top/bottom + 8 segs per side
local HP_SEGS = 12

-- Shared ScreenGui for all ESP weapon icons (avoids per-entry ScreenGui creation)
local _espWeaponIconGui = nil
function ESPF.ensureEspWeaponIconGui()
	if _espWeaponIconGui and _espWeaponIconGui.Parent then return _espWeaponIconGui end
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local sg = Instance.new("ScreenGui")
	sg.Name = "MethaneESPWeaponIcons"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 49
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	_espWeaponIconGui = sg
	return sg
end

function ESPF.makeEntry()
	local e = {
		box_lines = {}, box_ol = {}, box_fill = ESPF.newDraw("Square"),
		skel = {}, headdot = ESPF.newDraw("Circle"),
		hp_bg = ESPF.newDraw("Square"), hp_segs = {}, hp_ol = {}, hp_text = ESPF.newDraw("Text"),
		name = ESPF.newDraw("Text"), dist = ESPF.newDraw("Text"), weapon = ESPF.newDraw("Text"),
		right_flags = {}, -- stacked right-side labels
		tr_ol = ESPF.newDraw("Line"), tr = ESPF.newDraw("Line"),
		-- weapon icon (ScreenGui ImageLabel; created on first use)
		wicon_img = nil,
		wicon_shadow = nil,
		_wicon_cached_name = nil, -- avoid redundant resolveItemIcon calls
	}
	for i = 1, BOX_EDGE_N do
		e.box_lines[i] = ESPF.newDraw("Line")
		e.box_ol[i] = ESPF.newDraw("Line")
	end
	for i = 1, 16 do e.skel[i] = ESPF.newDraw("Line") end
	for i = 1, HP_SEGS do
		local s = ESPF.newDraw("Square")
		if s then s.Filled = true; s.Thickness = 0 end
		e.hp_segs[i] = s
	end
	for i = 1, 4 do
		e.hp_ol[i] = ESPF.newDraw("Line")
	end
	if e.box_fill then e.box_fill.Filled = true; e.box_fill.Thickness = 0 end
	if e.hp_bg then e.hp_bg.Filled = true; e.hp_bg.Thickness = 0 end
	if e.headdot then e.headdot.Filled = true; e.headdot.NumSides = 16 end
	if e.hp_text then
		e.hp_text.Center = false
		e.hp_text.Outline = true
		e.hp_text.Font = 2 -- monospace-ish, clean
		e.hp_text.Size = 11
	end
	if e.name then
		e.name.Center = true
		e.name.Outline = true
		e.name.Font = 2
		e.name.Size = 12
	end
	if e.dist then
		e.dist.Center = true
		e.dist.Outline = true
		e.dist.Font = 2
		e.dist.Size = 11
	end
	if e.weapon then
		e.weapon.Center = true
		e.weapon.Outline = true
		e.weapon.Font = 2
		e.weapon.Size = 11
	end
	for i = 1, 10 do
		local tf = ESPF.newDraw("Text")
		if tf then
			tf.Center = false
			tf.Outline = true
			tf.Font = 2
			tf.Size = 11
			tf.Visible = false
		end
		e.right_flags[i] = tf
	end
	return e
end

local entries = {} -- [player] = entry

function ESPF.hideEntry(e)
	if not e then return end
	local function h(o)
		if not o then return end
		pcall(function() o.Visible = false end)
	end
	for _, o in pairs(e.box_lines or {}) do h(o) end
	for _, o in pairs(e.box_ol or {}) do h(o) end
	for _, o in pairs(e.skel or {}) do h(o) end
	h(e.box_fill); h(e.headdot); h(e.hp_bg); h(e.hp_text)
	for _, s in pairs(e.hp_segs or {}) do h(s) end
	for _, s in pairs(e.hp_ol or {}) do h(s) end
	h(e.name); h(e.dist); h(e.weapon)
	for _, rf in pairs(e.right_flags or {}) do h(rf) end
	h(e.tr); h(e.tr_ol)
	-- weapon icon + shadow
	pcall(function() if e.wicon_img    then e.wicon_img.Visible    = false end end)
	pcall(function() if e.wicon_shadow then e.wicon_shadow.Visible = false end end)
end

function ESPF.clearAllEntries()
	for p, e in pairs(entries or {}) do
		ESPF.hideEntry(e)
		entries[p] = nil
	end
end
----------------------------------------------------------------
-- Chams (simple BoxHandleAdornment)
----------------------------------------------------------------
local chamsStore = {} -- [character] = { adorns = {}, wire = {} }

local CHAM_PARTS = {
	"Head", "UpperTorso", "LowerTorso", "Torso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm",
	"RightUpperArm", "RightLowerArm", "RightHand", "Right Arm",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg",
	"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg",
}

function ESPF.destroyChams(character)
	if not character or type(chamsStore) ~= "table" then return end
	local store = chamsStore[character]
	if not store then return end
	for _, ad in pairs(store.adorns or {}) do pcall(function() ad:Destroy() end) end
	for _, ad in pairs(store.wire or {}) do pcall(function() ad:Destroy() end) end
	chamsStore[character] = nil
end

function ESPF.clearAllChams()
	if type(chamsStore) ~= "table" then return end
	for char in pairs(chamsStore) do
		ESPF.destroyChams(char)
	end
end

function ESPF.makeAdorn(part, color, trans, alwaysOnTop, scale)
	local ad = Instance.new("BoxHandleAdornment")
	ad.Name = "VantaCham"
	ad.Adornee = part
	ad.AlwaysOnTop = alwaysOnTop == true
	ad.ZIndex = (alwaysOnTop == true) and 10 or 5
	ad.Size = part.Size * (scale or 1.02)
	ad.Color3 = color
	ad.Transparency = math.clamp(trans or 0.5, 0, 1)
	ad.Visible = true
	ad.Parent = part
	return ad
end

function ESPF.makeWire(part, color, trans)
	local sb = Instance.new("SelectionBox")
	sb.Name = "VantaWire"
	sb.Adornee = part
	sb.Color3 = color
	sb.LineThickness = 0.03
	sb.Transparency = math.clamp(trans or 0, 0, 1)
	sb.SurfaceTransparency = 1
	sb.SurfaceColor3 = color
	sb.Visible = true
	sb.Parent = part
	return sb
end

function ESPF.updateChamsFor(character, cam)
	if not ESP.chams or not ESP.chams.enabled or not character or not character.Parent then
		ESPF.destroyChams(character)
		return
	end

	local mode = ESP.chams.mode or "Fill"
	local col = ESP.chams.fill_color or Color3.fromRGB(120, 170, 255)
	local col2 = ESP.chams.fill_color2 or col
	local fillT = math.clamp(ESP.chams.fill_transparency or 0.55, 0, 1)
	local olT = math.clamp(ESP.chams.outline_transparency or 0.15, 0, 1)
	local visOnly = ESP.chams.visible_only == true
	local aot = not visOnly

	if visOnly and cam then
		local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
		if root then
			local sp, on = cam:WorldToViewportPoint(root.Position)
			if not on or sp.Z <= 0 then
				ESPF.destroyChams(character)
				return
			end
		end
	end

	local store = chamsStore[character]
	if not store then
		store = { adorns = {}, wire = {} }
		chamsStore[character] = store
	end

	local tclock = os.clock()
	local done = {}

	local function partColor(part)
		if mode == "Flow" then
			local root = character:FindFirstChild("HumanoidRootPart")
			local h = 0.5
			if root then
				h = math.clamp((part.Position.Y - (root.Position.Y - 3)) / 6, 0, 1)
			end
			local wave = (math.sin(tclock * 2 + h * 4) + 1) * 0.5
			return ESPF.lerpColor(col, col2, math.clamp(h * 0.7 + wave * 0.3, 0, 1))
		end
		return col
	end

	local function handlePart(part)
		if done[part] then return end
		done[part] = true
		local useCol = partColor(part)
		local ft = fillT
		if mode == "Flat" then ft = math.clamp(fillT * 0.5, 0, 0.85) end
		local ad = store.adorns[part]
		if not ad or ad.Parent == nil then
			ad = ESPF.makeAdorn(part, useCol, ft, aot, 1.02)
			store.adorns[part] = ad
		end
		ad.Adornee = part
		ad.Color3 = useCol
		ad.Transparency = ft
		ad.Size = part.Size * 1.02
		ad.AlwaysOnTop = aot
		ad.Visible = true
	end

	for _, name in ipairs(CHAM_PARTS) do
		local part = character:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			handlePart(part)
		end
	end
	for _, part in ipairs(character:GetChildren()) do
		if part:IsA("BasePart") and not done[part] and part.Name ~= "HumanoidRootPart" then
			if part.Transparency < 1 and not tostring(part.Name):find("Handle") then
				handlePart(part)
			end
		end
	end
end

function ESPF.setLine(ln, a, b, col, thick, z)
	if not ln then return end
	ln.From = a
	ln.To = b
	ln.Color = col
	ln.Thickness = thick or 1
	if z ~= nil then pcall(function() ln.ZIndex = z end) end
	ln.Visible = true
end

function ESPF.drawFullBox(e, x, y, w, h, col, col2, thick, outline, olcol, useGrad)
	thick = math.max(thick or 1, 1)
	for i = 1, BOX_EDGE_N do
		if e.box_lines[i] then e.box_lines[i].Visible = false end
		if e.box_ol[i] then e.box_ol[i].Visible = false end
	end
	local tl = Vector2.new(x, y)
	local tr = Vector2.new(x + w, y)
	local bl = Vector2.new(x, y + h)
	local br = Vector2.new(x + w, y + h)
	local idx = 1
	if outline and e.box_ol[idx] then ESPF.setLine(e.box_ol[idx], tl, tr, olcol, thick + 1, 1) end
	ESPF.setLine(e.box_lines[idx], tl, tr, col, thick, 2)
	idx = idx + 1
	local botCol = useGrad and col2 or col
	if outline and e.box_ol[idx] then ESPF.setLine(e.box_ol[idx], bl, br, olcol, thick + 1, 1) end
	ESPF.setLine(e.box_lines[idx], bl, br, botCol, thick, 2)
	idx = idx + 1
	local segs = useGrad and 8 or 1
	for s = 0, segs - 1 do
		local t0 = s / segs
		local t1 = (s + 1) / segs
		local c = useGrad and ESPF.lerpColor(col, col2, (t0 + t1) * 0.5) or col
		local la = Vector2.new(x, y + h * t0)
		local lb = Vector2.new(x, y + h * t1)
		if outline and e.box_ol[idx] then ESPF.setLine(e.box_ol[idx], la, lb, olcol, thick + 1, 1) end
		ESPF.setLine(e.box_lines[idx], la, lb, c, thick, 2)
		idx = idx + 1
		local ra = Vector2.new(x + w, y + h * t0)
		local rb = Vector2.new(x + w, y + h * t1)
		if outline and e.box_ol[idx] then ESPF.setLine(e.box_ol[idx], ra, rb, olcol, thick + 1, 1) end
		ESPF.setLine(e.box_lines[idx], ra, rb, c, thick, 2)
		idx = idx + 1
	end
end

function ESPF.drawCornerBox(e, x, y, w, h, col, col2, thick, outline, olcol, useGrad)
	thick = math.max(thick or 1, 1)
	local len = math.clamp(math.min(w, h) * 0.25, 4, 16)
	local segs = {
		{Vector2.new(x,y), Vector2.new(x+len,y)}, {Vector2.new(x,y), Vector2.new(x,y+len)},
		{Vector2.new(x+w,y), Vector2.new(x+w-len,y)}, {Vector2.new(x+w,y), Vector2.new(x+w,y+len)},
		{Vector2.new(x,y+h), Vector2.new(x+len,y+h)}, {Vector2.new(x,y+h), Vector2.new(x,y+h-len)},
		{Vector2.new(x+w,y+h), Vector2.new(x+w-len,y+h)}, {Vector2.new(x+w,y+h), Vector2.new(x+w,y+h-len)},
	}
	for i = 1, 8 do
		local a, b = segs[i][1], segs[i][2]
		local c = useGrad and (i <= 4 and col or col2) or col
		if outline and e.box_ol[i] then ESPF.setLine(e.box_ol[i], a, b, olcol, thick + 1, 1)
		elseif e.box_ol[i] then e.box_ol[i].Visible = false end
		ESPF.setLine(e.box_lines[i], a, b, c, thick, 2)
	end
	for i = 9, BOX_EDGE_N do
		if e.box_lines[i] then e.box_lines[i].Visible = false end
		if e.box_ol[i] then e.box_ol[i].Visible = false end
	end
end

function ESPF.getBox(cam, character)
	-- original-style: all BasePart descendants, project 8 corners of each
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	local any = false
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			local cf, size = part.CFrame, part.Size
			local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
			for _, ox in ipairs({-hx, hx}) do
				for _, oy in ipairs({-hy, hy}) do
					for _, oz in ipairs({-hz, hz}) do
						local wp = cf:PointToWorldSpace(Vector3.new(ox, oy, oz))
						local sp, vis = cam:WorldToViewportPoint(wp)
						if sp.Z > 0 then
							any = true
							if sp.X < minX then minX = sp.X end
							if sp.Y < minY then minY = sp.Y end
							if sp.X > maxX then maxX = sp.X end
							if sp.Y > maxY then maxY = sp.Y end
						end
					end
				end
			end
		end
	end
	if not any then return nil end
	local w, h = maxX - minX, maxY - minY
	if w < 2 or h < 2 then return nil end
	-- partially off-screen still OK (original behavior)
	return minX, minY, w, h
end

function ESPF.isAlive(character)
	-- Bloxstrike: Dead/Invincible attributes + humanoid when present
	if not character or not character.Parent then return false end
	local deadAttr = character:GetAttribute("Dead")
	if deadAttr == true or deadAttr == 1 or deadAttr == "true" then return false end
	if character:GetAttribute("Invincible") == true then return false end
	local hum = character:FindFirstChildOfClass("Humanoid")
	if hum then
		if hum.Health <= 0 then return false end
		local ok, st = pcall(function() return hum:GetState() end)
		if ok and st == Enum.HumanoidStateType.Dead then return false end
	end
	return true
end

local _espSyncLast = 0
local function _espTb(flag, default)
	if Toggles[flag] and Toggles[flag].Value ~= nil then return Toggles[flag].Value == true end
	return tv(flag)
end
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	local myPos = cam.CFrame.Position
	local vs = cam.ViewportSize

	-- UI→ESP state sync ~8Hz (drawing still full-rate). Was dozens of toggle reads every frame.
	local _nowS = os.clock()
	local doSync = (_nowS - _espSyncLast) >= 0.12
	local tb = _espTb
	if doSync then
		_espSyncLast = _nowS
	ESP.enabled = tb("ESPMaster", false)
	ESP.teamcheck = tb("ESPTeamCheck", false)
	ESP.max_distance = ov("ESPMaxDist", ESP.max_distance or 1500)

	ESP.box.enabled = tb("ESPBox", false)
	ESP.box.mode = tostring(ov("ESPBoxMode", ESP.box.mode or "Full"))
	ESP.box.thickness = ov("ESPBoxThick", ESP.box.thickness or 1)
	ESP.box.outline = tb("ESPBoxOutline", true)
	ESP.box.gradient = tb("ESPBoxGrad", false)
	ESP.box.fill = tb("ESPBoxFill", false)
	ESP.box.color = ov("ESPBoxCol", ESP.box.color or Color3.new(1,1,1))
	ESP.box.color2 = ov("ESPBoxCol2", ESP.box.color2 or Color3.fromRGB(255,60,60))
	ESP.box.fill_color = ov("ESPBoxFillCol", ESP.box.fill_color or Color3.new(1,1,1))
	ESP.box.fill_transparency = ov("ESPBoxFillTrans", ESP.box.fill_transparency or 0.7)
	ESP.box.outline_color = ov("ESPBoxOutlineCol", ESP.box.outline_color or Color3.new(0,0,0))

	if ESP.chams then
		ESP.chams.enabled = tb("ESPChams", false)
		ESP.chams.fill_color = ov("ESPChamsCol", ESP.chams.fill_color or Color3.fromRGB(120,170,255))
		ESP.chams.fill_transparency = ov("ESPChamsTrans", ESP.chams.fill_transparency or 0.55)
		ESP.chams.outline_transparency = ov("ESPChamsOutTrans", ESP.chams.outline_transparency or 0.15)
		ESP.chams.visible_only = tb("ESPChamsVis", false)
		ESP.chams.mode = tostring(ov("ESPChamsMode", ESP.chams.mode or "Fill"))
		ESP.chams.fill_color2 = ov("ESPChamsCol2", ESP.chams.fill_color2 or Color3.fromRGB(255,60,60))
	end

	if ESP.skeleton then
		ESP.skeleton.enabled = tb("ESPSkeleton", false)
		ESP.skeleton.gradient = tb("ESPSkelGrad", false)
		ESP.skeleton.headdot = tb("ESPHeadDot", false)
		ESP.skeleton.color = ov("ESPSkelCol", ESP.skeleton.color or Color3.new(1,1,1))
		ESP.skeleton.headdot_color = ov("ESPHeadDotCol", ESP.skeleton.headdot_color or Color3.new(1,1,1))
	end

	if ESP.health then
		ESP.health.enabled = tb("ESPHealth", false)
		ESP.health.text = tb("ESPHpText", true)
		ESP.health.text_size = ov("ESPHpTextSize", ESP.health.text_size or 11)
		ESP.health.color1 = ov("ESPHpCol1", ESP.health.color1 or Color3.fromRGB(80,255,120))
		ESP.health.color2 = ov("ESPHpCol2", ESP.health.color2 or Color3.fromRGB(255,220,60))
		ESP.health.color3 = ov("ESPHpCol3", ESP.health.color3 or Color3.fromRGB(255,60,60))
	end

	if ESP.tracer then
		ESP.tracer.enabled = tb("ESPTracer", false)
		ESP.tracer.outline = tb("ESPTracerOutline", true)
		ESP.tracer.color = ov("ESPTracerCol", ESP.tracer.color or Color3.new(1,1,1))
		ESP.tracer.origin = tostring(ov("ESPTracerOrigin", ESP.tracer.origin or "Bottom"))
	end

	ESP.flags.name = tb("ESPName", false)
	ESP.flags.distance = tb("ESPDistance", false)
	ESP.flags.weapon = tb("ESPWeapon", false)
	ESP.flags.weapon_icon = tb("ESPWeaponIcon", false)
	ESP.flags.kit = tb("ESPKit", false)
	ESP.flags.bomb = tb("ESPBomb", false)
	ESP.flags.defusing = tb("ESPDefusing", false)
	ESP.flags.planting = tb("ESPPlanting", false)
	ESP.flags.money = tb("ESPMoney", false)
	ESP.flags.ms = tb("ESPMs", false)
	ESP.flags.kd = tb("ESPKd", false)
	ESP.flags.flashed = tb("ESPFlash", false)
	ESP.flags.crouch = tb("ESPCrouch", false)
	ESP.flags.name_color = ov("ESPNameCol", ESP.flags.name_color or Color3.new(1,1,1))
	ESP.flags.distance_color = ov("ESPDistCol", ESP.flags.distance_color or Color3.fromRGB(200,200,200))
	ESP.flags.weapon_color = ov("ESPWepCol", ESP.flags.weapon_color or Color3.new(1,1,1))
	ESP.flags.kit_color = ov("ESPKitCol", ESP.flags.kit_color or Color3.fromRGB(100,200,255))
	ESP.flags.bomb_color = ov("ESPBombCol", ESP.flags.bomb_color or Color3.fromRGB(255,80,80))
	ESP.flags.defusing_color = ov("ESPDefusingCol", ESP.flags.defusing_color or Color3.fromRGB(255,200,80))
	ESP.flags.planting_color = ov("ESPPlantingCol", ESP.flags.planting_color or Color3.fromRGB(255,160,60))
	ESP.flags.money_color = ov("ESPMoneyCol", ESP.flags.money_color or Color3.fromRGB(60,255,100))
	ESP.flags.ms_color = ov("ESPMsCol", ESP.flags.ms_color or Color3.fromRGB(200,200,200))
	ESP.flags.kd_color = ov("ESPKdCol", ESP.flags.kd_color or Color3.fromRGB(90,140,255))
	ESP.flags.flashed_color = ov("ESPFlashCol", ESP.flags.flashed_color or Color3.fromRGB(255,255,100))
	ESP.flags.crouch_color = ov("ESPCrouchCol", ESP.flags.crouch_color or Color3.fromRGB(180,180,255))
	end -- doSync (UI→ESP flag refresh)



	-- Helpers defined once (were previously recreated every RenderStepped → major GC/FPS hit)
	local H = getgenv()._MethaneEspHelpers
	if not H then
		H = {}
		getgenv()._MethaneEspHelpers = H

	function H.decodeAttr(v)
	if type(v) ~= "string" or v == "" then return nil end
	local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(v) end)
	if ok and type(data) == "table" then return data end
	return nil
end

	function H.getWeaponName(player)
	local data = H.decodeAttr(player:GetAttribute("CurrentEquipped"))
	if data then
		local n = data.Name or data.Weapon or data.weapon
		if type(n) == "string" and n ~= "" then return n end
	end
	local char = player.Character
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then return tool.Name end
	end
	return nil
end

	function H.playerHasC4(player)
	local s5 = H.decodeAttr(player:GetAttribute("Slot5"))
	if s5 and (s5.Weapon == "C4" or s5.Name == "C4" or s5.weapon == "C4") then return true end
	local eq = H.decodeAttr(player:GetAttribute("CurrentEquipped"))
	if eq and (eq.Weapon == "C4" or eq.Name == "C4") then return true end
	local char = player.Character
	if char then
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA("Tool") and (ch.Name == "C4" or ch.Name:find("C4")) then return true end
		end
	end
	return false
end

	function H.playerHasKit(player)
	for i = 1, 9 do
		local data = H.decodeAttr(player:GetAttribute("Slot" .. i))
		if data then
			local n = tostring(data.Name or data.Weapon or data.weapon or "")
			if n:lower():find("defuse") or n:lower():find("kit") then return true end
		end
	end
	local char = player.Character
	if char then
		for _, ch in ipairs(char:GetChildren()) do
			if ch:IsA("Tool") then
				local n = ch.Name:lower()
				if n:find("defuse") or n == "kit" then return true end
			end
		end
	end
	local bp = player:FindFirstChild("Backpack")
	if bp then
		for _, ch in ipairs(bp:GetChildren()) do
			if ch:IsA("Tool") then
				local n = ch.Name:lower()
				if n:find("defuse") or n == "kit" then return true end
			end
		end
	end
	return player:GetAttribute("HasDefuseKit") == true or player:GetAttribute("HasKit") == true
end

	function H.getMoney(player)
	for _, key in ipairs({"Money", "Cash", "Credits", "Balance", "money", "cash"}) do
		local v = player:GetAttribute(key)
		if typeof(v) == "number" and v >= 0 and v < 1e9 then return math.floor(v) end
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		for _, key in ipairs({"Money", "Cash", "Credits", "Balance"}) do
			local v = ls:FindFirstChild(key)
			if v and v:IsA("ValueBase") and typeof(v.Value) == "number" and v.Value >= 0 then
				return math.floor(v.Value)
			end
		end
	end
	return nil
end

	function H.sanitizeMs(n)
	if typeof(n) ~= "number" then return nil end
	if n ~= n or n == math.huge or n == -math.huge then return nil end -- nan/inf
	-- if value looks like seconds (0..5), convert
	if n >= 0 and n <= 5 then
		n = n * 1000
	end
	n = math.floor(n + 0.5)
	-- real ping range only (ignore spikes / garbage)
	if n < 5 or n > 800 then return nil end
	return n
end

	function H.getPingMs(player)
	for _, key in ipairs({"Ping", "MS", "Latency", "ping", "ms"}) do
		local v = H.sanitizeMs(player:GetAttribute(key))
		if v then return v end
	end
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		for _, key in ipairs({"Ping", "MS", "Latency"}) do
			local obj = ls:FindFirstChild(key)
			if obj and obj:IsA("ValueBase") then
				local v = H.sanitizeMs(obj.Value)
				if v then return v end
			end
		end
	end
	local ok, ping = pcall(function()
		if player.GetNetworkPing then return player:GetNetworkPing() end
	end)
	-- GetNetworkPing is seconds → sanitizeMs converts 0..5 to ms
	if ok and type(ping) == "number" then
		local v = H.sanitizeMs(ping)
		if v then return v end
	end
	return nil
end

	function H.getKD(player)
	local k = player:GetAttribute("Kills") or player:GetAttribute("KillsCount")
	local d = player:GetAttribute("Deaths") or player:GetAttribute("DeathsCount")
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		if k == nil then
			local kv = ls:FindFirstChild("Kills")
			if kv and kv:IsA("ValueBase") then k = kv.Value end
		end
		if d == nil then
			local dv = ls:FindFirstChild("Deaths")
			if dv and dv:IsA("ValueBase") then d = dv.Value end
		end
	end
	if typeof(k) ~= "number" then return nil end
	d = typeof(d) == "number" and d or 0
	if d <= 0 then return tostring(math.floor(k)) end
	local ratio = k / d
	if math.abs(ratio - math.floor(ratio + 1e-9)) < 1e-6 then
		return tostring(math.floor(ratio + 0.5))
	end
	-- one decimal if needed, strip trailing 0
	local s = string.format("%.2f", ratio)
	s = s:gsub("0+$", ""):gsub("%.$", "")
	return s
end

	function H.isFlashed(player, character)
	if player:GetAttribute("Flashed") == true then return true end
	if player:GetAttribute("IsFlashed") == true then return true end
	if character and character:GetAttribute("Flashed") == true then return true end
	local fd = player:GetAttribute("FlashDuration") or (character and character:GetAttribute("FlashDuration"))
	if typeof(fd) == "number" and fd > 0 then return true end
	return false
end

	end
	local decodeAttr = H.decodeAttr
	local getWeaponName = H.getWeaponName
	local playerHasC4 = H.playerHasC4
	local playerHasKit = H.playerHasKit
	local getMoney = H.getMoney
	local sanitizeMs = H.sanitizeMs
	local getPingMs = H.getPingMs
	local getKD = H.getKD
	local isFlashed = H.isFlashed

	if not ESP.enabled then
		ESPF.clearAllEntries()
		if ESPF.clearAllChams then ESPF.clearAllChams() end
		return
	end
	if Toggles.ESPChams then ESP.chams.enabled = Toggles.ESPChams.Value == true end

	local seen = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player == LocalPlayer then continue end
		if not player.Parent then continue end
		-- drop spectators / floaters / not on CT|T (always, not only teamcheck)
		if not isValidCombatTarget(player) then continue end

		local character = player.Character
		if not character or not character.Parent then continue end
		if not ESPF.isAlive(character) then continue end

		-- teamcheck: IsEnemy == true means SAME team in this game
		if ESP.teamcheck then
			local same = false
			pcall(function() same = IsEnemy(player) == true end)
			if same then continue end
		end

		local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
		if not root or not root.Parent then continue end

		local dist = (root.Position - myPos).Magnitude
		if dist > ESP.max_distance then continue end

		local bx, by, bw, bh = ESPF.getBox(cam, character)
		if not bx then continue end

		-- reject garbage boxes (floating after death / wrong model)
		local rootSp = cam:WorldToViewportPoint(root.Position)
		local cx, cy = bx + bw * 0.5, by + bh * 0.5
		local dx, dy = cx - rootSp.X, cy - rootSp.Y
		if (dx * dx + dy * dy) > (180 * 180) then continue end
		if bw > cam.ViewportSize.X * 0.85 or bh > cam.ViewportSize.Y * 0.85 then continue end
		if bw < 3 or bh < 3 then continue end

		-- character must still belong to this player
		if Players:GetPlayerFromCharacter(character) ~= player then continue end

		seen[player] = true
		local e = entries[player]
		if not e then e = ESPF.makeEntry(); entries[player] = e end

		-- chams on same validated living players as boxes
		pcall(function() ESPF.updateChamsFor(character, cam) end)

		local hum = character:FindFirstChildOfClass("Humanoid")

		-- BOX
		if ESP.box.enabled then
			if ESP.box.fill and e.box_fill then
				e.box_fill.Position = Vector2.new(bx, by)
				e.box_fill.Size = Vector2.new(bw, bh)
				e.box_fill.Color = ESP.box.fill_color
				e.box_fill.Transparency = ESP.box.fill_transparency or 0.7
				e.box_fill.Visible = true
			elseif e.box_fill then e.box_fill.Visible = false end

			if ESP.box.mode == "Corner" then
				ESPF.drawCornerBox(e, bx, by, bw, bh, ESP.box.color, ESP.box.color2, ESP.box.thickness,
					ESP.box.outline, ESP.box.outline_color, ESP.box.gradient)
			else
				ESPF.drawFullBox(e, bx, by, bw, bh, ESP.box.color, ESP.box.color2, ESP.box.thickness,
					ESP.box.outline, ESP.box.outline_color, ESP.box.gradient)
			end
		else
			if e.box_fill then e.box_fill.Visible = false end
			for _, o in pairs(e.box_lines) do if o then o.Visible = false end end
			for _, o in pairs(e.box_ol) do if o then o.Visible = false end end
		end

		-- SKELETON
		if ESP.skeleton.enabled then
			local bones = character:FindFirstChild("UpperTorso") and SKELETON_BONES_R15 or SKELETON_BONES_R6
			for i, pair in ipairs(bones) do
				local a = character:FindFirstChild(pair[1])
				local b = character:FindFirstChild(pair[2])
				local ln = e.skel[i]
				if ln and a and b then
					local sa, va = cam:WorldToViewportPoint(a.Position)
					local sb, vb = cam:WorldToViewportPoint(b.Position)
					if sa.Z > 0 and sb.Z > 0 then
						local col = ESP.skeleton.color
						if ESP.skeleton.gradient then
							col = ESPF.lerpColor(ESP.skeleton.color, ESP.skeleton.color2, (i - 1) / math.max(#bones - 1, 1))
						end
						ESPF.setLine(ln, Vector2.new(sa.X, sa.Y), Vector2.new(sb.X, sb.Y), col, ESP.skeleton.thickness)
					else ln.Visible = false end
				elseif ln then ln.Visible = false end
			end
			for i = #bones + 1, #e.skel do if e.skel[i] then e.skel[i].Visible = false end end
			if ESP.skeleton.headdot and e.headdot then
				local head = character:FindFirstChild("Head")
				if head then
					local sp = cam:WorldToViewportPoint(head.Position)
					if sp.Z > 0 then
						e.headdot.Position = Vector2.new(sp.X, sp.Y)
						e.headdot.Radius = ESP.skeleton.headdot_size
						e.headdot.Color = ESP.skeleton.headdot_color
						e.headdot.Visible = true
					else e.headdot.Visible = false end
				else e.headdot.Visible = false end
			elseif e.headdot then e.headdot.Visible = false end
		else
			for _, ln in pairs(e.skel) do if ln then ln.Visible = false end end
			if e.headdot then e.headdot.Visible = false end
		end

		-- HEALTHBAR — same resolver as TargetHUD (CharacterResolver / attributes / humanoid)
		local hp, maxHp = nil, 100
		if type(readBloxHealth) == "function" then
			hp, maxHp = readBloxHealth(character)
		elseif hum then
			hp, maxHp = hum.Health, math.max(hum.MaxHealth, 1)
		else
			hp = character:GetAttribute("Health") or character:GetAttribute("HP")
			maxHp = character:GetAttribute("MaxHealth") or character:GetAttribute("MaxHP") or 100
		end
		if ESP.health.enabled and hp ~= nil then
			local frac = math.clamp(tonumber(hp) / math.max(tonumber(maxHp) or 100, 1), 0, 1)
			local bw = math.max(ESP.health.width or 2, 1)
			-- tight to box left edge (CS-style)
			local barX = bx - bw - 3
			-- dark track (same idea as box fill under the outline)
			if e.hp_bg then
				e.hp_bg.Position = Vector2.new(barX, by)
				e.hp_bg.Size = Vector2.new(bw, bh)
				e.hp_bg.Color = Color3.fromRGB(15, 15, 15)
				e.hp_bg.Transparency = 0.2
				e.hp_bg.Filled = true
				e.hp_bg.Visible = true
			end
			-- outline = same method as box ESP (black line under, thickness + 1)
			local olCol = Color3.new(0, 0, 0)
			local olThick = 2 -- matches box outline (main 1 + 1)
			local tl = Vector2.new(barX, by)
			local tr = Vector2.new(barX + bw, by)
			local br = Vector2.new(barX + bw, by + bh)
			local bl = Vector2.new(barX, by + bh)
			if e.hp_ol then
				ESPF.setLine(e.hp_ol[1], tl, tr, olCol, olThick, 1)
				ESPF.setLine(e.hp_ol[2], tr, br, olCol, olThick, 1)
				ESPF.setLine(e.hp_ol[3], br, bl, olCol, olThick, 1)
				ESPF.setLine(e.hp_ol[4], bl, tl, olCol, olThick, 1)
			end
			local segs = HP_SEGS
			local filled = math.floor(segs * frac + 1e-6)
			if frac > 0 and filled < 1 then filled = 1 end
			if frac >= 0.999 then filled = segs end
			local segH = bh / segs
			-- sharp rectangular segments; color always gradient along bar height
			local inset = 1
			for i = 1, segs do
				local s = e.hp_segs[i]
				if not s then continue end
				if i <= filled then
					-- i=1 at bottom (low HP color), i=segs at top of filled (high)
					-- map so full bar shows green→yellow→red top to bottom style
					local hFrac = (i - 0.5) / segs -- 0 bottom .. 1 top of bar
					local col = ESPF.healthGradient(hFrac)
					local sy = by + bh - (i * segH)
					s.Position = Vector2.new(barX + inset, sy)
					-- integer-ish sizes to avoid soft edges
					s.Size = Vector2.new(math.max(math.floor(bw - inset * 2 + 0.5), 1), math.max(math.ceil(segH), 1))
					s.Color = col
					s.Filled = true
					s.Thickness = 0
					s.Visible = true
				else
					s.Visible = false
				end
			end
			if ESP.health.text and e.hp_text then
				local ts = ESP.health.text_size or 11
				local label = tostring(math.floor(tonumber(hp) + 0.5))
				e.hp_text.Text = label
				e.hp_text.Size = ts
				e.hp_text.Color = Color3.new(1, 1, 1)
				e.hp_text.Center = false
				e.hp_text.Outline = true
				e.hp_text.Font = 2
				-- top-left of bar, tight gap
				local textW = #label * (ts * 0.52)
				e.hp_text.Position = Vector2.new(barX - textW - 2, by - 1)
				e.hp_text.Visible = true
			elseif e.hp_text then e.hp_text.Visible = false end
		else
			if e.hp_bg then e.hp_bg.Visible = false end
			for _, s in pairs(e.hp_segs or {}) do if s then s.Visible = false end end
			for _, s in pairs(e.hp_ol or {}) do if s then s.Visible = false end end
			if e.hp_text then e.hp_text.Visible = false end
		end

		-- FLAGS (compact CS-style)
		local belowY = by + bh + 1
		if ESP.flags.name and e.name then
			e.name.Text = player.Name
			e.name.Size = ESP.flags.name_size or 12
			e.name.Color = ESP.flags.name_color
			e.name.Font = 2
			e.name.Outline = true
			e.name.Center = true
			e.name.Position = Vector2.new(bx + bw * 0.5, by - (ESP.flags.name_size or 12) - 1)
			e.name.Visible = true
		elseif e.name then e.name.Visible = false end

		if ESP.flags.distance and e.dist then
			e.dist.Text = string.format("%dm", math.floor(dist + 0.5))
			e.dist.Size = ESP.flags.distance_size or 11
			e.dist.Color = ESP.flags.distance_color
			e.dist.Font = 2
			e.dist.Outline = true
			e.dist.Center = true
			e.dist.Position = Vector2.new(bx + bw * 0.5, belowY)
			e.dist.Visible = true
			belowY = belowY + (ESP.flags.distance_size or 11) + 1
		elseif e.dist then e.dist.Visible = false end

		if ESP.flags.weapon and e.weapon then
			local wn = getWeaponName(player) or "Fists"
			e.weapon.Text = wn
			e.weapon.Size = ESP.flags.weapon_size or 11
			e.weapon.Color = ESP.flags.weapon_color
			e.weapon.Font = 2
			e.weapon.Outline = true
			e.weapon.Center = true
			e.weapon.Position = Vector2.new(bx + bw * 0.5, belowY)
			e.weapon.Visible = true
		elseif e.weapon then e.weapon.Visible = false end

		-- WEAPON ICON (small crisp icon below box — no shadow)
		do
			local showWIcon = ESP.flags.weapon_icon
			if showWIcon then
				local wn = getWeaponName(player)
				local iconId = nil
				if wn and wn ~= "" then
					if e._wicon_cached_name ~= wn then
						e._wicon_cached_name = wn
						e._wicon_cached_id = nil
						local ri = getgenv().MethaneResolveItemIcon
						if type(ri) == "function" then
							pcall(function() e._wicon_cached_id = ri(wn) end)
						end
					end
					iconId = e._wicon_cached_id
				end
				if iconId and iconId ~= "" then
					local sg = ESPF.ensureEspWeaponIconGui()
					if sg then
						local ICON_SZ = 28
						local ix = bx + bw * 0.5
						local iy = belowY + (ESP.flags.weapon and (ESP.flags.weapon_size or 11) + 2 or 0) + ICON_SZ * 0.5 + 1
						if not e.wicon_shadow or not e.wicon_shadow.Parent then
							local sh = Instance.new("ImageLabel")
							sh.Name = "WIconShadow"; sh.BackgroundTransparency = 1
							sh.AnchorPoint = Vector2.new(0.5, 0.5)
							sh.Size = UDim2.fromOffset(ICON_SZ + 3, ICON_SZ + 3)
							sh.ZIndex = 12
							sh.ScaleType = Enum.ScaleType.Fit
							pcall(function() sh.ResampleMode = Enum.ResamplerMode.Pixelated end)
							sh.Parent = sg; e.wicon_shadow = sh
						end
						if not e.wicon_img or not e.wicon_img.Parent then
							local im = Instance.new("ImageLabel")
							im.Name = "WIcon"; im.BackgroundTransparency = 1
							im.AnchorPoint = Vector2.new(0.5, 0.5)
							im.Size = UDim2.fromOffset(ICON_SZ, ICON_SZ); im.ZIndex = 13
							im.ScaleType = Enum.ScaleType.Fit
							pcall(function()
								im.ResampleMode = Enum.ResamplerMode.Pixelated
							end)
							im.Parent = sg; e.wicon_img = im
						end
						local vis = math.clamp(alpha or 1, 0.3, 1)
						local sh, im = e.wicon_shadow, e.wicon_img
						sh.Size = UDim2.fromOffset(ICON_SZ + 3, ICON_SZ + 3)
						im.Size = UDim2.fromOffset(ICON_SZ, ICON_SZ)
						sh.Image = iconId; im.Image = iconId
						sh.ImageColor3 = Color3.new(0, 0, 0)
						im.ImageColor3 = Color3.new(1, 1, 1)
						sh.Position = UDim2.fromOffset(ix + 1, iy + 1)
						im.Position = UDim2.fromOffset(ix, iy)
						sh.ImageTransparency = 1 - (vis * 0.28)
						im.ImageTransparency = 1 - vis
						sh.Visible = true; im.Visible = true
					end
				else
					pcall(function() if e.wicon_img then e.wicon_img.Visible = false end end)
					pcall(function() if e.wicon_shadow then e.wicon_shadow.Visible = false end end)
				end
			else
				pcall(function() if e.wicon_img then e.wicon_img.Visible = false end end)
				pcall(function() if e.wicon_shadow then e.wicon_shadow.Visible = false end end)
			end
		end

		-- RIGHT SIDE flags (top → bottom, always UPPERCASE)
		local rightLines = {}
		local rs = ESP.flags.right_size or 10
		-- slight shrink with distance so far targets stay compact
		if dist > 80 then
			rs = math.max(7, math.floor(rs * (80 / dist) ^ 0.35 + 0.5))
		end
		if ESP.flags.crouch and (player:GetAttribute("IsCrouching") == true or (character and character:GetAttribute("IsCrouching") == true)) then
			table.insert(rightLines, { text = "CROUCHED", col = ESP.flags.crouch_color })
		end
		if ESP.flags.kit and playerHasKit(player) then
			table.insert(rightLines, { text = "KIT", col = ESP.flags.kit_color })
		end
		if ESP.flags.bomb and playerHasC4(player) then
			table.insert(rightLines, { text = "BOMB", col = ESP.flags.bomb_color })
		end
		if ESP.flags.defusing and (player:GetAttribute("IsDefusingBomb") == true or player:GetAttribute("IsLocallyDefusingBomb") == true) then
			table.insert(rightLines, { text = "DEFUSING", col = ESP.flags.defusing_color })
		end
		if ESP.flags.planting and (player:GetAttribute("IsPlantingBomb") == true or (character and character:GetAttribute("IsPlantingBomb") == true)) then
			table.insert(rightLines, { text = "PLANTING", col = ESP.flags.planting_color })
		end
		if ESP.flags.money then
			local m = getMoney(player)
			if m ~= nil then
				table.insert(rightLines, { text = "$" .. tostring(m), col = ESP.flags.money_color })
			end
		end
		if ESP.flags.ms then
			local ping = getPingMs(player)
			if ping ~= nil then
				table.insert(rightLines, { text = tostring(ping) .. " MS", col = ESP.flags.ms_color })
			end
		end
		if ESP.flags.kd then
			local kd = getKD(player)
			if kd then
				table.insert(rightLines, { text = "KD " .. kd, col = ESP.flags.kd_color })
			end
		end
		if ESP.flags.flashed and isFlashed(player, character) then
			table.insert(rightLines, { text = "FLASHED", col = ESP.flags.flashed_color })
		end
		-- tight stack top-right (CS-style) — step less than font size so lines sit close
		local rx = bx + bw + 2
		local ry = by
		-- Drawing font height > glyph; step ~65% of size keeps readable gap without spread
		local step = math.max(8, math.floor(rs * 0.62 + 0.5))
		for i = 1, 10 do
			local tf = e.right_flags and e.right_flags[i]
			if not tf then continue end
			local line = rightLines[i]
			if line then
				tf.Text = line.text
				tf.Size = rs
				tf.Color = line.col or Color3.new(1,1,1)
				tf.Font = 2
				tf.Outline = true
				tf.Center = false
				tf.Position = Vector2.new(rx, ry)
				tf.Visible = true
				ry = ry + step
			else
				tf.Visible = false
			end
		end

		-- TRACERS
		if ESP.tracer.enabled then
			local from
			local o = ESP.tracer.origin
			if o == "Top" then from = Vector2.new(vs.X * 0.5, 0)
			elseif o == "Center" then from = Vector2.new(vs.X * 0.5, vs.Y * 0.5)
			elseif o == "Mouse" then
				local m = LocalPlayer:GetMouse()
				from = Vector2.new(m.X, m.Y + GuiService:GetGuiInset().Y)
			else from = Vector2.new(vs.X * 0.5, vs.Y)
			end
			local to = Vector2.new(bx + bw * 0.5, by + bh)
			if ESP.tracer.outline and e.tr_ol then
				ESPF.setLine(e.tr_ol, from, to, ESP.tracer.outline_color, ESP.tracer.thickness + 1, 1)
			elseif e.tr_ol then e.tr_ol.Visible = false end
			ESPF.setLine(e.tr, from, to, ESP.tracer.color, ESP.tracer.thickness, 2)
		else
			if e.tr then e.tr.Visible = false end
			if e.tr_ol then e.tr_ol.Visible = false end
		end
	end

	for player, e in pairs(entries) do
		if not seen[player] then
			ESPF.hideEntry(e)
			entries[player] = nil
			if player.Character then ESPF.destroyChams(player.Character) end
		end
	end
	if type(chamsStore) == "table" then
		for char in pairs(chamsStore) do
			local plr = Players:GetPlayerFromCharacter(char)
			if not plr or not seen[plr] then
				ESPF.destroyChams(char)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(p)
	local e = entries[p]
	if e then ESPF.hideEntry(e); entries[p] = nil end
end)

local function hookPlayerClear(p)
	if p == LocalPlayer then return end
	p.CharacterRemoving:Connect(function()
		local e = entries[p]
		if e then ESPF.hideEntry(e); entries[p] = nil end
	end)
	p.CharacterAdded:Connect(function(char)
		local e = entries[p]
		if e then ESPF.hideEntry(e) end
		task.defer(function()
			local hum = char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid", 3)
			if hum then
				hum.Died:Connect(function()
					local e2 = entries[p]
					if e2 then ESPF.hideEntry(e2); entries[p] = nil end
				end)
			end
			pcall(function()
				char:GetAttributeChangedSignal("Dead"):Connect(function()
					if char:GetAttribute("Dead") == true then
						local e2 = entries[p]
						if e2 then ESPF.hideEntry(e2); entries[p] = nil end
					end
				end)
			end)
		end)
	end)
	if p.Character then
		local char = p.Character
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Died:Connect(function()
				local e2 = entries[p]
				if e2 then ESPF.hideEntry(e2); entries[p] = nil end
			end)
		end
		pcall(function()
			char:GetAttributeChangedSignal("Dead"):Connect(function()
				if char:GetAttribute("Dead") == true then
					local e2 = entries[p]
					if e2 then ESPF.hideEntry(e2); entries[p] = nil end
				end
			end)
		end)
	end
end
for _, p in ipairs(Players:GetPlayers()) do hookPlayerClear(p) end
Players.PlayerAdded:Connect(hookPlayerClear)
-- wipe ESP on round / spectate character swaps
LocalPlayer.CharacterAdded:Connect(function()
	ESPF.clearAllEntries()
	ESPF.clearAllChams()
	if world then
		world._orig_model = {}
		world._model_char = nil
		world._orig_parts = world._orig_parts and {} or {}
		world._orig_parts = {}
	end
	task.delay(0.35, function()
		if not world then return end
		if tv("WorldModelChams") and world.third_person then
			pcall(WFX.applyModelChams)
		end
		if tv("WorldArmsEnabled") or tv("WorldWeaponEnabled") or world.third_person then
			pcall(WFX.applySelfChams)
		end
	end)
end)
LocalPlayer.CharacterRemoving:Connect(function()
	ESPF.clearAllEntries()
	ESPF.clearAllChams()
	if world then
		world._orig_model = {}
		world._model_char = nil
		world._orig_parts = {}
	end
end)


-- Combat FOV + targeting + hooks (original logic)
----------------------------------------------------------------
local function makeFovCircle(col)
	local ol = Drawing.new("Circle")
	ol.Visible = false
	ol.Filled = false
	ol.NumSides = 128
	ol.Thickness = 3
	ol.Color = Color3.new(0, 0, 0)
	ol.ZIndex = 1
	local c = Drawing.new("Circle")
	c.Visible = false
	c.Filled = false
	c.NumSides = 128
	c.Thickness = 1
	c.Color = col
	c.ZIndex = 2
	return ol, c
end

local SilentFovOl, SilentFovCircle = makeFovCircle(Color3.fromRGB(255, 255, 255))
local AimbotFovOl, AimbotFovCircle = makeFovCircle(Color3.fromRGB(255, 255, 255))

local SilentTarget, AimbotTarget, RageTarget = nil, nil, nil
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.IgnoreWater = true
-- Dedicated params for silent aim wall check — hoisted so FindAllTargets
-- doesn't allocate a new RaycastParams per player per frame (GC pressure).
local _silentWallRp = RaycastParams.new()
_silentWallRp.FilterType = Enum.RaycastFilterType.Exclude
_silentWallRp.IgnoreWater = true
_silentWallRp.RespectCanCollide = false
local frameCounter = 0
local _fatLast = 0       -- FindAllTargets throttle timestamp
local _ragePartSeen = {} -- reused table for partOrder dedup — cleared per-player, never re-allocated

-- Bac0n-style wallcheck: uses each gun's Properties.Penetration + Raycast.castThrough
-- so USP/pistols pen less than AWP/scout (game values), not a flat soft/hard list.
local GameRaycast, GameGetRayIgnore = nil, nil
pcall(function()
	local rs = game:GetService("ReplicatedStorage")
	GameRaycast = require(rs.Shared.Raycast)
end)
pcall(function()
	local rs = game:GetService("ReplicatedStorage")
	GameGetRayIgnore = require(rs.Components.Common.GetRayIgnore)
end)

local RAGE = {}
function RAGE.rageAimLook()
	local cam = Workspace.CurrentCamera
	if cam then return cam.CFrame.LookVector end
	local ch = LocalPlayer.Character
	local head = ch and ch:FindFirstChild("Head")
	if head then return head.CFrame.LookVector end
	return Vector3.new(0, 0, -1)
end

function RAGE.rageEyeOrigin()
	local ch = LocalPlayer.Character
	local head = ch and ch:FindFirstChild("Head")
	local look = RAGE.rageAimLook()
	local push = 0.45
	pcall(function()
		if Toggles and Toggles.WorldThirdPerson and Toggles.WorldThirdPerson.Value then
			push = 1.25
		end
	end)
	pcall(function()
		if world and world.third_person then push = 1.25 end
	end)
	if head then
		return head.Position + look * push
	end
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if hrp then
		return hrp.Position + Vector3.new(0, 1.5, 0) + look * push
	end
	local cam = Workspace.CurrentCamera
	return cam and cam.CFrame.Position or Vector3.zero
end

getgenv().MethaneRageEyeOrigin = RAGE.rageEyeOrigin
getgenv().MethaneRageAimLook = RAGE.rageAimLook

-- current gun penetration depth (studs) from live weapon data
function RAGE.currentWeaponPen()
	local pen, range, maxSurf = 0, 500, 8
	pcall(function()
		local w = Weapon
		if not w and type(getCurrentEquipped) == "function" then
			-- filled later; try genv
		end
		if type(w) ~= "table" then
			w = getgenv().MethaneWeapon
		end
		local props = nil
		if type(w) == "table" then
			if type(w.Bullet) == "table" and type(w.Bullet.Properties) == "table" then
				props = w.Bullet.Properties
			elseif type(w.Properties) == "table" then
				props = w.Properties
			end
		end
		if type(props) == "table" then
			pen = tonumber(props.Penetration) or 0
			range = tonumber(props.Range) or 500
		end
	end)
	-- sane floors so pistols still get a little, rifles more (if game returns 0)
	if pen <= 0 then
		-- name-based fallback when Properties missing
		local name = ""
		pcall(function()
			if Weapon and Weapon.Name then name = tostring(Weapon.Name) end
		end)
		name = string.lower(name)
		if name:find("awp", 1, true) or name:find("ssg", 1, true) or name:find("scout", 1, true) then
			pen = 120
		elseif name:find("ak", 1, true) or name:find("m4", 1, true) or name:find("galil", 1, true)
			or name:find("famas", 1, true) or name:find("aug", 1, true) or name:find("sg", 1, true) then
			pen = 70
		elseif name:find("deagle", 1, true) or name:find("desert", 1, true) or name:find("revolver", 1, true) then
			pen = 55
		elseif name:find("usp", 1, true) or name:find("glock", 1, true) or name:find("p250", 1, true)
			or name:find("five", 1, true) or name:find("tec", 1, true) or name:find("cz", 1, true) then
			pen = 18
		elseif name:find("nova", 1, true) or name:find("xm", 1, true) or name:find("shot", 1, true)
			or name:find("mag7", 1, true) or name:find("sawed", 1, true) then
			pen = 12
		else
			pen = 35
		end
	end
	return pen, range, maxSurf
end

-- per-frame caches (same answers within a frame, clears next frame)
local _rageCache = {
	frame = -1,
	eye = nil,
	ignore = nil,
	pen = nil,
	vis = {},
	hit = {},
}

function RAGE.rageCacheBegin()
	local f = frameCounter or 0
	if _rageCache.frame ~= f then
		_rageCache.frame = f
		_rageCache.eye = nil
		_rageCache.ignore = nil
		_rageCache.pen = nil
		table.clear(_rageCache.vis)
		table.clear(_rageCache.hit)
	end
end

function RAGE.rageEyeOriginCached()
	RAGE.rageCacheBegin()
	if _rageCache.eye ~= nil then return _rageCache.eye end
	_rageCache.eye = RAGE.rageEyeOrigin()
	return _rageCache.eye
end

function RAGE.rageRayIgnore()
	RAGE.rageCacheBegin()
	if _rageCache.ignore ~= nil then return _rageCache.ignore end
	local ignore = nil
	if type(GameGetRayIgnore) == "function" then
		pcall(function() ignore = GameGetRayIgnore() end)
	end
	if type(ignore) ~= "table" then
		ignore = {}
		if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
		if Workspace.CurrentCamera then table.insert(ignore, Workspace.CurrentCamera) end
	end
	_rageCache.ignore = ignore
	return ignore
end

function RAGE.currentWeaponPenCached()
	RAGE.rageCacheBegin()
	if _rageCache.pen ~= nil then
		return _rageCache.pen[1], _rageCache.pen[2], _rageCache.pen[3]
	end
	local a, b, c = RAGE.currentWeaponPen()
	_rageCache.pen = { a, b, c }
	return a, b, c
end

-- Strict LOS (no pen) — legit aimbot
function RAGE.isVisible(target)
	if not target then return false end
	RAGE.rageCacheBegin()
	local cached = _rageCache.vis[target]
	if cached ~= nil then return cached end
	local origin = RAGE.rageEyeOriginCached()
	local goal = target.Position
	local delta = goal - origin
	local dist = delta.Magnitude
	if dist < 0.05 then
		_rageCache.vis[target] = true
		return true
	end
	local dir = delta.Unit
	local result = false
	if GameRaycast and type(GameRaycast.cast) == "function" then
		local hit = nil
		pcall(function()
			hit = GameRaycast.cast(origin, dir * (dist + 0.05), nil, RAGE.rageRayIgnore())
		end)
		if not hit or not hit.instance then
			result = true
		else
			local model = hit.instance:FindFirstAncestorOfClass("Model")
			result = model and Players:GetPlayerFromCharacter(model) ~= nil
		end
	else
		rayParams.FilterDescendantsInstances = RAGE.rageRayIgnore()
		local ray = Workspace:Raycast(origin, dir * dist, rayParams)
		if not ray then
			result = true
		else
			local model = ray.Instance:FindFirstAncestorOfClass("Model")
			result = model and Players:GetPlayerFromCharacter(model) ~= nil
		end
	end
	_rageCache.vis[target] = result and true or false
	return result
end

-- Bac0n castWeaponShot-style: penetrate up to gun Penetration, see if we reach target char
-- sharedRp hoisted: was allocated fresh every RAGE.canRageHit call (every frame, every player).
-- One object, filter list updated in-place — no GC churn.
local _canRageHitRp = RaycastParams.new()
_canRageHitRp.FilterType = Enum.RaycastFilterType.Exclude
local _canRageHitGoals = {}  -- reused pen-target list, cleared per call
local _penFilter = {}        -- reused ignore+penetrated list for fallback pen loop
function RAGE.canRageHit(target)
	if not target then return false end
	RAGE.rageCacheBegin()
	local cached = _rageCache.hit[target]
	if cached ~= nil then return cached end

	local function finish(ok)
		_rageCache.hit[target] = ok and true or false
		return ok
	end

	local char = target:FindFirstAncestorOfClass("Model") or target.Parent
	if typeof(char) ~= "Instance" then char = nil end

	-- open LOS always ok
	if RAGE.isVisible(target) then return finish(true) end

	local origin = RAGE.rageEyeOriginCached()
	-- visible-first: return as soon as any body part has open LOS (same result, less work)
	-- _canRageHitGoals reused — cleared in-place, never re-allocated per call
	table.clear(_canRageHitGoals)
	local sharedRp = _canRageHitRp
	sharedRp.FilterDescendantsInstances = RAGE.rageRayIgnore()
	if char then
		for _, name in ipairs({ "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Torso" }) do
			local part = char:FindFirstChild(name)
			if part and part:IsA("BasePart") then
				local delta = part.Position - origin
				local dist = delta.Magnitude
				if dist < 0.05 then return finish(true) end
				local hit = workspace:Raycast(origin, delta.Unit * dist, sharedRp)
				if not hit then
					return finish(true)
				end
				local m = hit.Instance:FindFirstAncestorOfClass("Model")
				if m and Players:GetPlayerFromCharacter(m) then
					return finish(true)
				end
				_canRageHitGoals[#_canRageHitGoals + 1] = part.Position
			end
		end
	else
		_canRageHitGoals[1] = target.Position
	end
	local goals = _canRageHitGoals
	if #goals == 0 then goals = { target.Position } end

	local pen, range, maxSurf = RAGE.currentWeaponPenCached()
	if pen <= 0 then
		return false -- no pen gun + no LOS
	end

	local ignore = RAGE.rageRayIgnore()

	for _, goal in ipairs(goals) do
		local delta = goal - origin
		local dist = delta.Magnitude
		if dist < 0.05 then return true end
		if dist > range + 5 then continue end
		local dir = delta.Unit

		-- Prefer game castThrough (same as bac0n)
		local reached = false
		if GameRaycast and type(GameRaycast.castThrough) == "function" then
			pcall(function()
				-- first hit
				local first = GameRaycast.cast(origin, dir * math.min(dist + 0.05, range), nil, ignore)
				if not first or not first.instance then
					reached = true
					return
				end
				if char and first.instance:IsDescendantOf(char) then
					reached = true
					return
				end
				local hits = GameRaycast.castThrough(
					first.position - dir * 0.001,
					dir * (pen + 0.001),
					pen,
					ignore
				)
				if type(hits) ~= "table" then return end
				local surfaces = 0
				for index, hit in ipairs(hits) do
					if index > maxSurf * 2 then break end
					if not hit or not hit.instance then continue end
					local isExit = (index % 2 == 0)
					if not isExit then
						surfaces = surfaces + 1
						if surfaces > maxSurf then break end
					end
					if char and hit.instance:IsDescendantOf(char) and not isExit then
						reached = true
						return
					end
					-- close enough to goal after pen
					if hit.position and (hit.position - goal).Magnitude < 2.5 then
						reached = true
						return
					end
				end
			end)
			if reached then return true end
		else
			-- fallback: thickness budget = pen studs, material cost scale
			-- Reuse _penFilter — copy ignore once, append penetrated parts in-place.
			-- Old code did table.unpack(ignore) fresh every goal iteration.
			table.clear(_penFilter)
			for i = 1, #ignore do _penFilter[i] = ignore[i] end
			local traveled = 0
			local budget = pen
			rayParams.FilterDescendantsInstances = _penFilter
			for _ = 1, 8 do
				local remain = dist - traveled
				if remain <= 0.05 then return true end
				if budget <= 0 then break end
				local result = Workspace:Raycast(origin + dir * traveled, dir * (remain + 0.2), rayParams)
				if not result then return true end
				local hit = result.Instance
				if char and hit:IsDescendantOf(char) then return true end
				local model = hit:FindFirstAncestorOfClass("Model")
				if model and Players:GetPlayerFromCharacter(model) then return true end
				local thin = math.min(hit.Size.X, hit.Size.Y, hit.Size.Z)
				local cost = thin
				local mat = hit.Material
				if mat == Enum.Material.Glass or mat == Enum.Material.Wood or mat == Enum.Material.WoodPlanks then
					cost = thin * 0.35
				elseif mat == Enum.Material.Metal or mat == Enum.Material.DiamondPlate or mat == Enum.Material.CorrodedMetal then
					cost = thin * 2.2
				elseif mat == Enum.Material.Concrete or mat == Enum.Material.Brick or mat == Enum.Material.Rock then
					cost = thin * 1.6
				else
					cost = thin * 1.0
				end
				if cost > budget then break end
				budget = budget - cost
				_penFilter[#_penFilter + 1] = hit
				rayParams.FilterDescendantsInstances = _penFilter
				traveled = (result.Position - origin).Magnitude + 0.12
			end
		end
	end
	return finish(false)
end

local function tv(flag)
	return Toggles[flag] and Toggles[flag].Value
end
local function ov(flag, default)
	if Options[flag] and Options[flag].Value ~= nil then return Options[flag].Value end
	return default
end

----------------------------------------------------------------
task.spawn(function()
-- ANTI AIM (Bac0nHck-style SampleInput rewrite — proven on BloxStrike MovementV2)
----------------------------------------------------------------
local AA = {
	spin = 0,
	jitterSide = 1,
	jitterStep = 0,
	lastJitter = 0,
	_pitchJitter = 0,
	_lastSpinStep = 0,
	Started = nil,
	LastStep = -1,
	hooked = false,
	oldSample = nil,
	neckC0Default = CFrame.new(0, 0.75, 0),
}

local function aaNormAng(a)
	return (a + math.pi) % (math.pi * 2) - math.pi
end

local function aaGetCharClass()
	local ok, mod = pcall(function()
		return require(ReplicatedStorage.Classes.Character)
	end)
	if ok and type(mod) == "table" then return mod end
	return nil
end

local function aaClosestEnemyYaw(fromPos)
	local best, bestD = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == LocalPlayer then continue end
		local c = plr.Character
		if not c or c:GetAttribute("Dead") then continue end
		if IsEnemy(plr) then continue end
		local hrp = c:FindFirstChild("HumanoidRootPart")
		if not hrp then continue end
		local d = (hrp.Position - fromPos).Magnitude
		if d < bestD and d > 0.5 then
			local flat = Vector3.new(hrp.Position.X - fromPos.X, 0, hrp.Position.Z - fromPos.Z)
			if flat.Magnitude > 0.05 then
				bestD = d
				local _, y = CFrame.lookAt(Vector3.zero, flat):ToEulerAnglesYXZ()
				best = y
			end
		end
	end
	return best
end

local function aaApplyNeckPitch(pitch)
	pcall(function()
		local ch = LocalPlayer.Character
		if not ch then return end
		local neck = nil
		for _, d in ipairs(ch:GetDescendants()) do
			if d:IsA("Motor6D") and d.Name == "Neck" then
				neck = d
				break
			end
		end
		if not neck then return end
		if not tv("AntiAim") then
			neck.C0 = AA.neckC0Default
			return
		end
		local mode = tostring(ov("AAPitch", "Off"))
		if mode == "Off" then
			neck.C0 = AA.neckC0Default
			return
		end
		local p = typeof(pitch) == "number" and pitch or 0
		neck.C0 = AA.neckC0Default * CFrame.Angles(-p * math.rad(70), 0, 0)
	end)
end

-- Exact CorrectMove used by working BloxStrike AA (Bac0nHck):
-- delta = aaYaw - realYaw; Move' = rotate(Move, +delta)
local function aaFixMove(move, realYaw, aaYaw)
	if typeof(move) ~= "Vector2" then return move end
	if move.Magnitude > 1 then move = move.Unit end
	local delta = aaYaw - realYaw
	if math.abs(delta) < 1e-6 then return move end
	local c, s = math.cos(delta), math.sin(delta)
	return Vector2.new(move.X * c - move.Y * s, move.X * s + move.Y * c)
end

local function aaProcessSample(input, context)
	if type(input) ~= "table" then return input end
	if not tv("AntiAim") then
		aaApplyNeckPitch(0)
		return input
	end

	local realYaw = input.LookYaw
	if type(realYaw) ~= "number" then return input end
	local realPitch = input.VerticalLook
	if type(realPitch) ~= "number" then realPitch = 0 end

	-- tick clock from MovementV2 context when available
	local now = os.clock()
	if type(context) == "table" and type(context.ScheduledServerTime) == "number" then
		now = context.ScheduledServerTime
	end
	if not AA.Started or now < AA.Started then
		AA.Started = now
		AA.LastStep = -1
	end
	local elapsed = now - AA.Started

	-- pause AA yaw while attacking so bullets/knife follow crosshair
	local attacking = false
	pcall(function()
		attacking = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
			or UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
	end)
	if attacking then
		return input
	end

	local yaw = realYaw
	local pitch = realPitch

	-- Pitch modes (packet VerticalLook sign on this build)
	local pitchMode = tostring(ov("AAPitch", "Off"))
	if pitchMode == "Down" then
		pitch = 1
	elseif pitchMode == "Up" then
		pitch = -1
	elseif pitchMode == "Custom" then
		local c = ov("AAPitchCustom", 0)
		if type(c) == "number" then pitch = math.clamp(-c, -1, 1) end
	end

	-- Yaw base
	local yawMode = tostring(ov("AAYawMode", "Off"))
	local offsetDeg = ov("AAYawOffset", 180)
	if type(offsetDeg) ~= "number" then offsetDeg = 180 end

	if yawMode == "Backward" then
		yaw = realYaw + math.rad(offsetDeg)
	elseif yawMode == "Face Enemies" or yawMode == "Back to Enemies" then
		local origin = nil
		pcall(function()
			local ch = LocalPlayer.Character
			local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
			if hrp then origin = hrp.Position end
		end)
		if origin then
			local ey = aaClosestEnemyYaw(origin)
			if ey then
				yaw = (yawMode == "Face Enemies") and ey or aaNormAng(ey + math.pi)
			else
				yaw = realYaw + math.rad(offsetDeg)
			end
		else
			yaw = realYaw + math.rad(offsetDeg)
		end
	end

	-- Jitter / spin interval (ms) — default 50, Bac0n uses ~150 for stability
	local intervalMs = ov("AAJitterSpeed", 50)
	if type(intervalMs) ~= "number" then intervalMs = 50 end
	intervalMs = math.max(intervalMs, 20)
	local step = math.floor(elapsed / math.max(intervalMs / 1000, 0.02))
	local side = (step % 2 == 0) and -1 or 1

	if tv("AAJitter") then
		-- normalize dropdown value (spaces / case / table)
		local jtRaw = ov("AAJitterType", "3-Way")
		if type(jtRaw) == "table" then
			local picked = nil
			for k, v in pairs(jtRaw) do
				if v == true or v == 1 then picked = k break end
				if type(k) == "number" and type(v) == "string" then picked = v break end
			end
			jtRaw = picked or "3-Way"
		end
		local jt = string.lower(tostring(jtRaw or "3-way")):gsub("%s+", ""):gsub("%-", "")
		local ang = ov("AAJitterAngle", 60)
		if type(ang) ~= "number" then ang = 60 end

		if jt == "3way" then
			local phase = step % 3
			local mul = (phase == 0 and -1) or (phase == 1 and 0) or 1
			yaw = yaw + math.rad(ang) * mul
		elseif jt == "1way" then
			-- center ↔ +offset (same side only)
			local mul = (step % 2 == 0) and 0 or 1
			yaw = yaw + math.rad(ang) * mul
		elseif jt == "up" then
			-- full pitch flip up / level (server VerticalLook)
			pitch = (step % 2 == 0) and -1 or 0
		elseif jt == "down" then
			-- full pitch flip down / level
			pitch = (step % 2 == 0) and 1 or 0
		end
	end

	if tv("AASpin") then
		local spd = ov("AASpinSpeed", 360)
		if type(spd) ~= "number" then spd = 360 end
		-- continuous from elapsed (same as working Bac0n spin)
		yaw = yaw + math.rad((elapsed * spd) % 360)
	end

	yaw = aaNormAng(yaw)
	pitch = math.clamp(pitch, -1, 1)

	local move = input.Move
	if typeof(move) == "Vector2" then
		move = aaFixMove(move, realYaw, yaw)
	end

	local modified = table.clone(input)
	modified.Move = move
	modified.LookYaw = yaw
	modified.VerticalLook = pitch
	aaApplyNeckPitch(pitch)
	return modified
end

local function aaInstallHook()
	if AA.hooked then return true end
	local cls = aaGetCharClass()
	if not cls or type(cls.SampleInput) ~= "function" then return false end
	AA.oldSample = cls.SampleInput
	cls.SampleInput = function(character, context, ...)
		local input = AA.oldSample(character, context, ...)
		if not input then return input end
		if MOV and MOV.processSample then
			local okM, mid = pcall(MOV.processSample, character, context, input)
			if okM and mid then input = mid end
		end
		local ok, out = pcall(aaProcessSample, input, context)
		if ok and out ~= nil then return out end
		return input
	end
	AA.hooked = true
	return true
end

task.spawn(function()
	for _ = 1, 30 do
		if aaInstallHook() then break end
		task.wait(0.4)
	end
end)

----------------------------------------------------------------
-- MOVEMENT · Bac0n-style Character.SampleInput (Simulation.step is frozen/readonly)
-- Source: https://raw.githubusercontent.com/Bac0nHck/Scripts/refs/heads/main/BloxStrike.lua
-- Buttons Jump=1; JumpHeld from PreviousButtons; pulse Jump only on accepted gate
----------------------------------------------------------------
end)
task.spawn(function()

MOV = {
	GroundSince = nil,
	LastJumpDown = false,
	Character = nil,
	Buttons = nil,
	Ray = RaycastParams.new(),
}
MOV.Ray.FilterType = Enum.RaycastFilterType.Exclude
MOV.Ray.IgnoreWater = true

pcall(function()
	MOV.Buttons = require(ReplicatedStorage.MovementV2.Buttons)
end)

local function movHas(bits, flag)
	if MOV.Buttons then
		local ok, r = pcall(MOV.Buttons.has, bits or 0, flag)
		if ok then return r end
	end
	return bit32.band(bits or 0, flag or 0) ~= 0
end

local function movWith(bits, flag, on)
	if MOV.Buttons then
		local ok, r = pcall(MOV.Buttons.with, bits or 0, flag, on and true or false)
		if ok and r ~= nil then return r end
	end
	if on then return bit32.bor(bits or 0, flag or 0) end
	return bit32.band(bits or 0, bit32.bnot(flag or 0))
end

local function movJumpFlag()
	return (MOV.Buttons and MOV.Buttons.Jump) or 1
end

local function movSpace()
	local d = false
	pcall(function() d = UserInputService:IsKeyDown(Enum.KeyCode.Space) end)
	return d
end

local function movOnGround(character, context)
	local st = type(context) == "table" and context.State or nil
	if st and st.OnGround == true then return true end
	if st and st.OnGround == false then return false end
	-- RuntimeKinematics
	local ok, grounded = pcall(function()
		local rk = require(ReplicatedStorage.MovementV2.RuntimeKinematics)
		local g, known = rk.isOnGround(character and character.Character or LocalPlayer.Character)
		if known then return g end
		return nil
	end)
	if ok and grounded ~= nil then return grounded end
	local model = LocalPlayer.Character
	local hrp = model and model:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	MOV.Ray.FilterDescendantsInstances = { model }
	local hit = Workspace:Raycast(hrp.Position, Vector3.new(0, -3.4, 0), MOV.Ray)
	return hit ~= nil and hit.Normal.Y > 0.55
end

local function movKeyLocal()
	local x, y = 0, 0
	pcall(function()
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then y -= 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then y += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then x += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then x -= 1 end
	end)
	if x == 0 and y == 0 then return nil end
	local m = math.sqrt(x * x + y * y)
	return Vector2.new(x / m, y / m)
end

-- MovementV2: speed (BPASS v4 — correct architecture)
--
-- Why v1/v2/v3 all rubberband:
--   rawset(context.State, "BaseMoveSpeed", spd) works — local sim runs at our speed.
--   BUT Simulation.step line 171: output state copies p19.BaseMoveSpeed (our patched value)
--   into v44.BaseMoveSpeed, which StateCodec encodes into the state snapshot the client
--   sends. Server decodes that, sees BaseMoveSpeed != SpeedProfile value → rejects.
--   More critically: the server runs its own sim at SpeedProfile speed (vanilla) and
--   computes a different position than us. Every ~10 ticks it sends an OwnerSnapshot
--   (position correction). Reconciler.accept applies it, replays commands at vanilla
--   speed, snaps us back. That's the rubberband. The ramp doesn't help — server is
--   always vanilla, every correction wipes our prediction.
--
-- BPASS v4 — the correct two-part fix:
--   Part 1: Keep rawset patches on context.State so our LOCAL sim runs at target speed.
--           The client character visually moves at the right speed between corrections.
--   Part 2: Hook Reconciler.accept. When speed spoof is active, swallow the server's
--           position correction — keep our locally-predicted position, discard the
--           server's authoritative one. The server's replay runs from our position
--           with vanilla speed, then we re-apply our speed patch on top each tick.
--           Net effect: position advances at our speed, corrections never land.
--
-- PredictionRing.replacePrediction is the internal call that Reconciler.accept uses
-- to overwrite our predicted state with the server's corrected state. Hooking it
-- is cleaner than hooking accept() — it's called once per correction, takes the
-- exact predicted entry being replaced, and we can selectively pass through vs. block.

local MOV_BASE_SPEED = 18.75   -- vanilla from live dump

local function movSpeedTarget()
	return math.clamp(tonumber(ov("MovSpeedValue", 16)) or 16, 1, 100)
end

-- No-op stub — bhop path references this
local function movApplyStateSpeed(st, spd, moveVec, lookYaw) end

-- Patch all three speed fields on state so local sim runs at spd
local function movPatchState(state, spd)
	rawset(state, "BaseMoveSpeed",         spd)
	rawset(state, "WeaponMoveSpeed",       spd)
	rawset(state, "WeaponScopedMoveSpeed", spd)
end

-- BPASS: hook PredictionRing.replacePrediction to swallow server corrections.
-- Called once, installs permanently. Re-arms itself if the ring gets replaced.
MOV.ReconcilerHooked = false
MOV.LastKnownPosition = nil   -- our last good predicted position
MOV.LastKnownVelocity = nil

local function movInstallReconcilerHook()
	if MOV.ReconcilerHooked then return true end
	local ok = pcall(function()
		local Ring = require(ReplicatedStorage.MovementV2.Client.PredictionRing)
		if type(Ring) ~= "table" or type(Ring.replacePrediction) ~= "function" then return end
		local oldReplace = Ring.replacePrediction
		Ring.replacePrediction = function(self, commandNumber, newEntry, ...)
			-- Only intercept when speed spoof is active
			if false then -- speed spoof removed
				-- Keep track of our last good position from before the correction
				if MOV.LastKnownPosition ~= nil then
					-- Block the replacement: return without calling oldReplace.
					-- The ring keeps our predicted entry intact.
					-- The reconciler will proceed to replay commands on top of it,
					-- which re-applies our BaseMoveSpeed patches via processSample.
					return
				end
			end
			return oldReplace(self, commandNumber, newEntry, ...)
		end
		MOV.ReconcilerHooked = true
	end)
	return ok and MOV.ReconcilerHooked
end

-- Also hook Reconciler.accept as a fallback — some builds go through here directly
local function movInstallAcceptHook()
	local ok = pcall(function()
		local Reconciler = require(ReplicatedStorage.MovementV2.Client.Reconciler)
		if type(Reconciler) ~= "table" or type(Reconciler.accept) ~= "function" then return end
		local oldAccept = Reconciler.accept
		Reconciler.accept = function(self, serverTick, serverState, ...)
			if false then -- speed spoof removed
				-- Patch the server's corrected state: replace its position with ours
				-- so the replay starts from our position, not the server's.
				if MOV.LastKnownPosition ~= nil and type(serverState) == "table" then
					pcall(function()
						rawset(serverState, "Position", MOV.LastKnownPosition)
						rawset(serverState, "Velocity", MOV.LastKnownVelocity or serverState.Velocity)
					end)
				end
			end
			return oldAccept(self, serverTick, serverState, ...)
		end
	end)
end

task.spawn(function()
	for _ = 1, 40 do
		if movInstallReconcilerHook() then break end
		task.wait(0.3)
	end
	movInstallAcceptHook()
end)

function MOV.processSample(character, context, input)
	if type(input) ~= "table" then return input end
	local doBhop   = tv("MovBhop")
	local doStrafe = tv("MovAutoStrafe")
	local doSpeed  = false

	if not MOV.Buttons then
		pcall(function() MOV.Buttons = require(ReplicatedStorage.MovementV2.Buttons) end)
	end
	local jumpFlag = movJumpFlag()

	if not doBhop and not doStrafe and not doSpeed then
		-- Clear saved position when toggle goes off so next accept() correction lands clean
		MOV.LastKnownPosition = nil
		MOV.LastKnownVelocity = nil
		return input
	end

	if MOV.Character ~= character then
		MOV.Character         = character
		MOV.GroundSince       = nil
		MOV.LastJumpDown      = false
		MOV.LastKnownPosition = nil
		MOV.LastKnownVelocity = nil
		local prev = 0
		if type(context) == "table" and context.State then
			prev = context.State.PreviousButtons or 0
		end
		MOV.LastJumpDown = movHas(prev, jumpFlag)
	end

	local modified = table.clone(input)
	local now = os.clock()
	if type(context) == "table" and type(context.ScheduledServerTime) == "number" then
		now = context.ScheduledServerTime
	end

	-- Auto-strafe
	if doStrafe then
		local held = movKeyLocal()
		if held then
			local move = Vector2.new(
				math.clamp(held.X, -1, 1),
				math.clamp(held.Y, -1, 1)
			)
			if math.abs(move.X) > 0.05 then
				move = Vector2.new(move.X > 0 and 1 or -1, move.Y)
			end
			if math.abs(move.Y) > 0.05 then
				move = Vector2.new(move.X, move.Y > 0 and 1 or -1)
			end
			if move.Magnitude > 1 then move = move.Unit end
			modified.Move = move
			pcall(function()
				if character then
					character.PreviousFrameMoveVector = move
					character.CurrentFrameMoveVector  = move
					character.LatestMoveVector        = move
				end
			end)
		end
	end

	-- Speed spoof: patch state so local sim runs at target speed.
	-- Reconciler hook (above) prevents server corrections from snapping us back.
	if doSpeed and type(context) == "table" and type(context.State) == "table" then
		local spd = movSpeedTarget()
		pcall(movPatchState, context.State, spd)
		MOV._liveState = context.State
		MOV._liveSpeed = spd
		-- Save our current predicted position BEFORE this tick's sim runs.
		-- Reconciler hook uses this to reject the server's correction position.
		pcall(function()
			MOV.LastKnownPosition = context.State.Position
			MOV.LastKnownVelocity = context.State.Velocity
		end)
	end

	-- Bhop
	if doBhop then
		local onGround = movOnGround(character, context)
		local space = movSpace()
			or (character and character.JumpInputDown == true)
			or movHas(input.Buttons, jumpFlag)
		if not space then
			MOV.GroundSince  = nil
			MOV.LastJumpDown = movHas(input.Buttons, jumpFlag)
		else
			if onGround then
				MOV.GroundSince = MOV.GroundSince or now
			else
				MOV.GroundSince = nil
			end
			local jump = onGround and not MOV.LastJumpDown and MOV.GroundSince ~= nil
			modified.Buttons = movWith(input.Buttons or 0, jumpFlag, jump)
			MOV.LastJumpDown = jump
			if jump then
				pcall(function()
					if type(character.SetJumpInput) == "function" then
						character:SetJumpInput(nil)
					end
				end)
			end
		end
	end

	return modified
end




----------------------------------------------------------------
end)

task.spawn(function()
-- SKINCHANGER (Bac0nHck BloxStrike catalog/apply — ported)
----------------------------------------------------------------
local SkinChanger = {
	Ready = false,
	Loadout = {},
	Catalog = {},
	Weapons = {},
	Knives = {},
	KnifeSet = {},
	Gloves = {},
	GloveSet = {},
	Records = {},
	GloveRecords = {},
	NextUpdate = 0,
	Updating = false,
	Syncing = false,
	ModifiedKnife = nil,
	LastError = nil,
}
getgenv().VantaSkinChanger = SkinChanger

local SKIN_FILE = "MethaneUI/cache/bloxstrike_skins.json"
local wearOrder = { "Factory New", "Minimal Wear", "Field-Tested", "Well-Worn", "Battle-Scarred" }

local function skinDecode(value)
	if type(value) ~= "string" or value == "" then return nil end
	local ok, data = pcall(HttpService.JSONDecode, HttpService, value)
	if ok and type(data) == "table" then return data end
	return nil
end

local function skinWriteLoadout()
	local enc = ""
	pcall(function() enc = HttpService:JSONEncode(SkinChanger.Loadout) end)
	Options.SkinLoadout = Options.SkinLoadout or {}
	Options.SkinLoadout.Value = enc
	pcall(function()
		if isfolder and not isfolder("MethaneUI") then makefolder("MethaneUI") end
		if isfolder and not isfolder("MethaneUI/cache") then makefolder("MethaneUI/cache") end
		if writefile then writefile(SKIN_FILE, enc) end
	end)
end

local function skinReadLoadout()
	local raw = nil
	pcall(function()
		if isfile and isfile(SKIN_FILE) and readfile then
			raw = readfile(SKIN_FILE)
		end
	end)
	if type(raw) ~= "string" or raw == "" then return end
	local data = skinDecode(raw)
	if data then SkinChanger.Loadout = data end
end

local function skinMeshParts(model)
	local list = {}
	if not model then return list end
	pcall(function()
		if model.QueryDescendants then
			for _, p in ipairs(model:QueryDescendants("MeshPart")) do
				table.insert(list, p)
			end
		else
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("MeshPart") then table.insert(list, d) end
			end
		end
	end)
	return list
end

local function skinSetDropdown(flag, values, preferred)
	values = values or { "Original" }
	if #values == 0 then values = { "Original" } end
	local cur = preferred
	if not cur or not table.find(values, cur) then cur = values[1] end
	Options[flag] = Options[flag] or {}
	Options[flag].Value = cur
	-- Methane Options API
	pcall(function()
		local o = Options[flag]
		if o.SetValues then o:SetValues(values) end
		if o.SetValue then o:SetValue(cur) end
	end)
	-- Library.Flags path used by some dropdowns
	pcall(function()
		local c = Options[flag] and Options[flag].Control
		if not c then return end
		if c.SetValues then c:SetValues(values)
		elseif c.SetOptions then c:SetOptions(values)
		elseif c.Refresh then c:Refresh(values)
		elseif c.Items then
			-- try replace items table then set
			pcall(function()
				if type(c.Items) == "table" then
					table.clear(c.Items)
					for _, v in ipairs(values) do table.insert(c.Items, v) end
				end
			end)
		end
		if c.Set then c:Set(cur)
		elseif c.SetValue then c:SetValue(cur) end
	end)
	return values, cur
end

function SkinChanger:RefreshCatalog()
	local catalog, weapons, knives, knifeSet = {}, {}, {}, {}
	local gloves, gloveSet = {}, {}
	local library = self.Library
	if not library or not self.WeaponAssets or not self.Assets then return end
	for _, folder in ipairs(self.WeaponAssets:GetChildren()) do
		local skins = self.Assets:FindFirstChild(folder.Name)
		if not folder:IsA("Folder") or not folder:FindFirstChild("Camera") or not skins then continue end
		local items = {}
		local list = nil
		pcall(function() list = library.GetAllSkinsForWeapon(folder.Name) end)
		if type(list) ~= "table" then list = {} end
		for _, info in ipairs(list) do
			if type(info) == "table" and type(info.skin) == "string" then
				local asset = skins:FindFirstChild(info.skin)
				if asset and asset:FindFirstChild("Camera") then
					items[info.skin] = info
				end
			end
		end
		-- also pick up Camera skin folders not returned by API
		pcall(function()
			for _, child in ipairs(skins:GetChildren()) do
				if child:IsA("Folder") and child:FindFirstChild("Camera") and not items[child.Name] then
					items[child.Name] = { skin = child.Name, type = "Equipment" }
				end
			end
		end)
		local _, sample = next(items)
		if sample then
			catalog[folder.Name] = items
			local typ = tostring(sample.type or "")
			local nm = string.lower(folder.Name)
			local isGlove = typ == "Gloves" or typ == "Glove"
				or nm:find("glove", 1, true) or nm:find("handwrap", 1, true)
				or nm:find("hand wrap", 1, true) or nm:find("wraps", 1, true)
			local isGrenade = typ == "Grenade"
				or nm:find("grenade", 1, true) or nm:find("flash", 1, true)
				or nm:find("smoke", 1, true) or nm:find("molotov", 1, true)
				or nm:find("incendiary", 1, true) or nm:find("decoy", 1, true)
				or nm == "c4" or nm == "bomb"
			if isGlove then
				table.insert(gloves, folder.Name)
				gloveSet[folder.Name] = true
			elseif typ == "Melee" then
				table.insert(knives, folder.Name)
				knifeSet[folder.Name] = true
			elseif not isGrenade and typ ~= "Equipment" then
				table.insert(weapons, folder.Name)
			end
		end
	end
	-- Extra pass: glove folders under Assets.Skins only
	pcall(function()
		for _, folder in ipairs(self.Assets:GetChildren()) do
			if not folder:IsA("Folder") then continue end
			local nm = string.lower(folder.Name)
			local isGlove = nm:find("glove", 1, true) or nm:find("handwrap", 1, true)
				or nm:find("hand wrap", 1, true) or nm:find("wraps", 1, true)
			if not isGlove or catalog[folder.Name] then continue end
			local items = {}
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Folder") and child:FindFirstChild("Camera") then
					items[child.Name] = { skin = child.Name, type = "Gloves" }
				end
			end
			if next(items) then
				catalog[folder.Name] = items
				table.insert(gloves, folder.Name)
				gloveSet[folder.Name] = true
			end
		end
	end)
	table.sort(weapons)
	table.sort(knives)
	table.sort(gloves)
	self.Catalog, self.Weapons, self.Knives, self.KnifeSet = catalog, weapons, knives, knifeSet
	self.Gloves, self.GloveSet = gloves, gloveSet
	if self.RefreshEditor then self:RefreshEditor() end
end

function SkinChanger:TextureFolder(weapon, skin, wear)
	local info = self.Catalog[weapon] and self.Catalog[weapon][skin]
	if not info then return nil end
	local folder = self.Assets:FindFirstChild(weapon)
	folder = folder and folder:FindFirstChild(skin)
	folder = folder and folder:FindFirstChild("Camera")
	if not folder then return nil end
	local wearName = nil
	pcall(function() wearName = self.Library.GetWearNameForFloat(info, wear) end)
	local selected = wearName and folder:FindFirstChild(wearName)
	if selected then return selected, info, wearName end
	for _, name in ipairs(wearOrder) do
		selected = folder:FindFirstChild(name)
		if selected then return selected, info, name end
	end
	return nil
end

function SkinChanger:RestoreModel(model)
	local record = self.Records[model]
	if not record then return end
	for _, item in ipairs(record.Items) do
		local owned = item.Applied and item.Applied.Parent == item.Part
		pcall(function() item.Applied:Destroy() end)
		for _, original in ipairs(item.Originals or {}) do
			if owned and item.Part and item.Part.Parent and model.Parent then
				pcall(function() original.Parent = item.Part end)
			else
				pcall(function() original:Destroy() end)
			end
		end
	end
	self.Records[model] = nil
end

function SkinChanger:RestoreAll()
	for model in pairs(self.Records) do
		self:RestoreModel(model)
	end
	if self.RestoreGloves then self:RestoreGloves() end
	if self.RestoreKnife then self:RestoreKnife() end
end

local function skinIsArmPart(part, root)
	if not part then return false end
	local current = part
	while current and current ~= root do
		local n = tostring(current.Name)
		local lower = string.lower(n)
		if n == "Left Arm" or n == "Right Arm" or n == "LeftHand" or n == "RightHand"
			or n == "LeftUpperArm" or n == "RightUpperArm" or n == "LeftLowerArm" or n == "RightLowerArm"
			or lower:find("glove", 1, true) or lower:find("hand", 1, true) or lower:find("arm", 1, true)
			or lower:find("sleeve", 1, true) or lower:find("finger", 1, true) then
			return true
		end
		current = current.Parent
	end
	local pn = string.lower(tostring(part.Name))
	if pn:find("glove", 1, true) or pn:find("hand", 1, true) then return true end
	return false
end

function SkinChanger:RestoreGloves()
	for model, record in pairs(self.GloveRecords or {}) do
		pcall(function()
			for _, item in ipairs(record.Items or {}) do
				local owned = item.Applied and item.Applied.Parent == item.Part
				pcall(function() if item.Applied then item.Applied:Destroy() end end)
				for _, original in ipairs(item.Originals or {}) do
					if owned and item.Part and item.Part.Parent then
						pcall(function() original.Parent = item.Part end)
					else
						pcall(function() original:Destroy() end)
					end
				end
			end
		end)
		self.GloveRecords[model] = nil
	end
end

function SkinChanger:ApplyGloves(model, selection)
	if not model or not selection or not selection.Weapon or not selection.Skin then
		return false
	end
	if not self.GloveSet[selection.Weapon] then return false end
	local folder = self:TextureFolder(selection.Weapon, selection.Skin, selection.Float or 0)
	if not folder then return false end
	local key = selection.Weapon .. "\0" .. selection.Skin .. "\0" .. folder.Name
	self.GloveRecords = self.GloveRecords or {}
	local previous = self.GloveRecords[model]
	if previous and previous.Key == key then return true end
	if previous then
		for _, item in ipairs(previous.Items or {}) do
			pcall(function() if item.Applied then item.Applied:Destroy() end end)
			for _, original in ipairs(item.Originals or {}) do
				pcall(function()
					if item.Part and item.Part.Parent then original.Parent = item.Part end
				end)
			end
		end
		self.GloveRecords[model] = nil
	end
	local materials = {}
	local paintList = {}
	for _, paint in ipairs(folder:GetChildren()) do
		if paint:IsA("SurfaceAppearance") then
			materials[paint.Name] = paint
			table.insert(paintList, paint)
		end
	end
	local record = { Key = key, Items = {} }
	self.GloveRecords[model] = record
	local appliedCount = 0
	for _, part in ipairs(skinMeshParts(model)) do
		if not skinIsArmPart(part, model) then continue end
		local paint = materials[part.Name]
		if not paint then
			for name, pnt in pairs(materials) do
				if string.lower(part.Name):find(string.lower(name), 1, true)
					or string.lower(name):find(string.lower(part.Name), 1, true) then
					paint = pnt
					break
				end
			end
		end
		if not paint and #paintList > 0 then
			paint = paintList[1 + (appliedCount % #paintList)]
		end
		if not paint then continue end
		local applied = paint:Clone()
		local originals = {}
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("SurfaceAppearance") then
				table.insert(originals, child)
				child.Parent = nil
			end
		end
		table.insert(record.Items, { Part = part, Originals = originals, Applied = applied })
		applied.Parent = part
		appliedCount = appliedCount + 1
	end
	return appliedCount > 0
end

function SkinChanger:ConstructKnife(view, character, weapon)
	local readIdentity = getthreadidentity or getidentity
	local writeIdentity = setthreadidentity or setidentity
	local identity = readIdentity and writeIdentity and readIdentity()
	local success, failure = pcall(function()
		if identity then writeIdentity(2) end
		local getProperties = require(ReplicatedStorage.Components.Common.GetWeaponProperties)
		assert(getProperties(view.CameraModelWeapon or view.Weapon or weapon.Name), "Knife properties unavailable")
		view:construct(character, weapon)
	end)
	if identity then writeIdentity(identity) end
	if not success then error(failure, 0) end
end

function SkinChanger:RestoreKnife()
	local record = self.ModifiedKnife
	self.ModifiedKnife = nil
	if not record then return end
	local view, weapon = record.View, record.Weapon
	if not view or not weapon or view.IsDestroyed or weapon.IsDestroyed then return end
	view.CameraModelWeapon, view.Skin, view.Float = record.CameraModelWeapon, record.Skin, record.Float
	local character = weapon.Character or LocalPlayer.Character
	if character and character.Parent then
		pcall(function() self:ConstructKnife(view, character, weapon) end)
	end
end

function SkinChanger:ApplyKnife(weapon, selection)
	local view = weapon and weapon.Viewmodel
	if not view or not selection or not self.KnifeSet[selection.Weapon] then
		self:RestoreKnife()
		return
	end
	if self.ModifiedKnife and self.ModifiedKnife.View ~= view then self:RestoreKnife() end
	if not self.ModifiedKnife then
		self.ModifiedKnife = {
			View = view, Weapon = weapon,
			CameraModelWeapon = view.CameraModelWeapon, Skin = view.Skin, Float = view.Float,
		}
	end
	local changed = view.CameraModelWeapon ~= selection.Weapon
	view.CameraModelWeapon, view.Skin, view.Float = selection.Weapon, selection.Skin, selection.Float
	if changed then
		if view.Model then self:RestoreModel(view.Model) end
		local character = weapon.Character or LocalPlayer.Character
		if character and character.Parent then
			pcall(function() self:ConstructKnife(view, character, weapon) end)
		end
	end
end

function SkinChanger:ApplyModel(model, weapon, selection)
	local folder = self:TextureFolder(weapon, selection.Skin, selection.Float)
	if not folder then return false end
	local key = weapon .. "\0" .. selection.Skin .. "\0" .. folder.Name
	local previous = self.Records[model]
	if previous and previous.Key == key then return true end
	self:RestoreModel(model)
	local materials = {}
	for _, paint in ipairs(folder:GetChildren()) do
		if paint:IsA("SurfaceAppearance") then materials[paint.Name] = paint end
	end
	local record = { Key = key, Items = {} }
	self.Records[model] = record
	for _, part in ipairs(skinMeshParts(model)) do
		local paint = materials[part.Name]
		if not paint then continue end
		local applied = paint:Clone()
		local originals = {}
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("SurfaceAppearance") then
				table.insert(originals, child)
				child.Parent = nil
			end
		end
		table.insert(record.Items, { Part = part, Originals = originals, Applied = applied })
		applied.Parent = part
	end
	return #record.Items > 0
end

function SkinChanger:Update()
	local gunsOn = tv("SkinEnabled")
	local knifeOn = tv("KnifeSkinEnabled")
	local gloveOn = tv("GloveSkinEnabled")
	if not gunsOn and not knifeOn and not gloveOn then
		self:RestoreAll()
		return
	end
	if type(self.GetWeapon) ~= "function" then return end
	local weapon = nil
	pcall(function() weapon = self.GetWeapon() end)
	local view = weapon and weapon.Viewmodel
	if not weapon or weapon.Player ~= LocalPlayer or weapon.IsDestroyed or not view
		or LocalPlayer:GetAttribute("IsSpectating") == true then
		self:RestoreAll()
		return
	end
	local model = view.Model

	if gloveOn and model and model.Parent and self.Loadout.Gloves then
		self:ApplyGloves(model, self.Loadout.Gloves)
	elseif not gloveOn then
		self:RestoreGloves()
	end

	local isKnife = self.KnifeSet[weapon.Name] or (weapon.Properties and weapon.Properties.Class == "Melee")
	if isKnife then
		if knifeOn then
			self:ApplyKnife(weapon, self.Loadout.Knife)
		else
			self:RestoreKnife()
		end
		if model and model.Parent and knifeOn and self.Loadout.Knife then
			local name = view.CameraModelWeapon or view.Weapon or weapon.Name
			for previous in pairs(self.Records) do
				if previous ~= model then self:RestoreModel(previous) end
			end
			self:ApplyModel(model, name, self.Loadout.Knife)
		elseif not knifeOn then
			for previous in pairs(self.Records) do
				self:RestoreModel(previous)
			end
		end
		return
	end
	if not gunsOn then
		self:RestoreKnife()
		for previous in pairs(self.Records) do
			self:RestoreModel(previous)
		end
		return
	end
	self:RestoreKnife()
	if not model or not model.Parent then
		for previous in pairs(self.Records) do
			self:RestoreModel(previous)
		end
		return
	end
	local name = view.CameraModelWeapon or view.Weapon or weapon.Name
	local selection = self.Loadout[name]
	for previous in pairs(self.Records) do
		if previous ~= model or not selection then
			self:RestoreModel(previous)
		end
	end
	if selection then
		self:ApplyModel(model, name, selection)
	end
end

function SkinChanger:Store()
	skinWriteLoadout()
	self.NextUpdate = 0
end

function SkinChanger:Import(data)
	if type(data) == "string" then data = skinDecode(data) end
	if type(data) ~= "table" then return end
	local loadout = {}
	local names = {}
	for name in pairs(data) do
		if type(name) == "string" then table.insert(names, name) end
	end
	table.sort(names)
	for _, name in ipairs(names) do
		local selection = data[name]
		local weapon = type(selection) == "table" and (name == "Knife" and selection.Weapon or name)
		if type(selection) == "table" and self.Catalog[weapon] and self.Catalog[weapon][selection.Skin] then
			local wear = selection.Float
			if type(wear) ~= "number" or wear ~= wear or math.abs(wear) == math.huge then wear = 0 end
			if self.KnifeSet[weapon] then
				if name == "Knife" or not loadout.Knife then
					loadout.Knife = { Weapon = weapon, Skin = selection.Skin, Float = math.clamp(wear, 0, 1) }
				end
			elseif self.GloveSet and self.GloveSet[weapon] then
				if name == "Gloves" or not loadout.Gloves then
					loadout.Gloves = { Weapon = weapon, Skin = selection.Skin, Float = math.clamp(wear, 0, 1) }
				end
			elseif name ~= "Knife" and name ~= "Gloves" then
				loadout[name] = { Skin = selection.Skin, Float = math.clamp(wear, 0, 1) }
			end
		end
	end
	self.Loadout = loadout
	self:Store()
	if self.RefreshEditor then self:RefreshEditor() end
end

function SkinChanger:RefreshEditor()
	self.Syncing = true
	-- Guns
	local name = tostring(ov("SkinWeapon", ""))
	if not self.Catalog[name] and #self.Weapons > 0 then
		name = self.Weapons[1]
		Options.SkinWeapon = Options.SkinWeapon or {}
		Options.SkinWeapon.Value = name
	end
	local selected = self.Loadout[name]
	local values = {}
	for finish in pairs(self.Catalog[name] or {}) do
		table.insert(values, finish)
	end
	table.sort(values)
	table.insert(values, 1, "Original")
	skinSetDropdown("SkinFinish", values, selected and selected.Skin or "Original")
	if selected and type(selected.Float) == "number" then
		Options.SkinWear = Options.SkinWear or {}
		Options.SkinWear.Value = selected.Float
	end

	-- Knife section
	local knifeValues = { "Original" }
	for _, n in ipairs(self.Knives or {}) do table.insert(knifeValues, n) end
	local knifeSel = self.Loadout.Knife
	local knifeCur = (knifeSel and knifeSel.Weapon) or "Original"
	skinSetDropdown("SkinKnifeModel", knifeValues, knifeCur)
	local kWeapon = knifeCur
	local kValues = { "Original" }
	if kWeapon ~= "Original" then
		kValues = {}
		for finish in pairs(self.Catalog[kWeapon] or {}) do
			table.insert(kValues, finish)
		end
		table.sort(kValues)
		table.insert(kValues, 1, "Original")
	end
	skinSetDropdown("SkinKnifeFinish", kValues, knifeSel and knifeSel.Skin or "Original")
	if knifeSel and type(knifeSel.Float) == "number" then
		Options.SkinKnifeWear = Options.SkinKnifeWear or {}
		Options.SkinKnifeWear.Value = knifeSel.Float
	end

	local gloveValues = { "Original" }
	for _, n in ipairs(self.Gloves or {}) do table.insert(gloveValues, n) end
	local gloveSel = self.Loadout.Gloves
	local gloveCur = (gloveSel and gloveSel.Weapon) or "Original"
	skinSetDropdown("SkinGloveModel", gloveValues, gloveCur)
	local gWeapon = gloveCur
	local gValues = { "Original" }
	if gWeapon ~= "Original" then
		gValues = {}
		for finish in pairs(self.Catalog[gWeapon] or {}) do
			table.insert(gValues, finish)
		end
		table.sort(gValues)
		table.insert(gValues, 1, "Original")
	end
	skinSetDropdown("SkinGloveFinish", gValues, gloveSel and gloveSel.Skin or "Original")
	if gloveSel and type(gloveSel.Float) == "number" then
		Options.SkinGloveWear = Options.SkinGloveWear or {}
		Options.SkinGloveWear.Value = gloveSel.Float
	end
	self.Syncing = false
end

function SkinChanger:storeSelection()
	if self.Syncing or not self.Ready then return end
	local name = tostring(ov("SkinWeapon", ""))
	local finish = tostring(ov("SkinFinish", "Original"))
	if finish == "Original" or name == "" then
		if name ~= "" then self.Loadout[name] = nil end
	elseif self.Catalog[name] and self.Catalog[name][finish] then
		local wear = ov("SkinWear", 0)
		if type(wear) ~= "number" then wear = 0 end
		self.Loadout[name] = {
			Skin = finish,
			Float = math.clamp(wear, 0, 1),
		}
	else
		return
	end
	self:Store()
end

function SkinChanger:storeKnifeSelection()
	if self.Syncing or not self.Ready then return end
	local model = tostring(ov("SkinKnifeModel", "Original"))
	local finish = tostring(ov("SkinKnifeFinish", "Original"))
	if model == "Original" or finish == "Original" then
		self.Loadout.Knife = nil
	elseif self.KnifeSet[model] and self.Catalog[model] and self.Catalog[model][finish] then
		local wear = ov("SkinKnifeWear", 0)
		if type(wear) ~= "number" then wear = 0 end
		self.Loadout.Knife = {
			Weapon = model,
			Skin = finish,
			Float = math.clamp(wear, 0, 1),
		}
	else
		return
	end
	self:Store()
end

function SkinChanger:storeGloveSelection()
	if self.Syncing or not self.Ready then return end
	local model = tostring(ov("SkinGloveModel", "Original"))
	local finish = tostring(ov("SkinGloveFinish", "Original"))
	if model == "Original" or finish == "Original" then
		self.Loadout.Gloves = nil
		self:RestoreGloves()
	elseif self.GloveSet[model] and self.Catalog[model] and self.Catalog[model][finish] then
		local wear = ov("SkinGloveWear", 0)
		if type(wear) ~= "number" then wear = 0 end
		self.Loadout.Gloves = {
			Weapon = model,
			Skin = finish,
			Float = math.clamp(wear, 0, 1),
		}
	else
		return
	end
	self:Store()
	self.NextUpdate = 0
end

function SkinChanger:UseEquipped()
	if not self.Ready or type(self.GetWeapon) ~= "function" then return end
	local weapon = nil
	pcall(function() weapon = self.GetWeapon() end)
	local name = weapon and weapon.Name
	if type(name) == "string" and self.Catalog[name] then
		Options.SkinWeapon = Options.SkinWeapon or {}
		Options.SkinWeapon.Value = self.KnifeSet[name] and "Knife" or name
		self:RefreshEditor()
	else
		VantaNotify({ Title = "Skinchanger", Description = "Equip a weapon with available skins.", Time = 3 })
	end
end

function SkinChanger:ResetCurrent()
	local name = tostring(ov("SkinWeapon", "Knife"))
	if name == "Knife" then
		Options.SkinKnifeModel = Options.SkinKnifeModel or {}
		Options.SkinKnifeModel.Value = "Original"
		self.Loadout.Knife = nil
	else
		Options.SkinFinish = Options.SkinFinish or {}
		Options.SkinFinish.Value = "Original"
		self.Loadout[name] = nil
	end
	self:Store()
	self:RefreshEditor()
end

function SkinChanger:ResetAll()
	table.clear(self.Loadout)
	self:Store()
	self:RefreshEditor()
end

local function installSkinChanger()
	local ok, failure = pcall(function()
		SkinChanger.Library = require(ReplicatedStorage.Database.Components.Libraries.Skins)
		SkinChanger.Assets = ReplicatedStorage.Assets.Skins
		SkinChanger.WeaponAssets = ReplicatedStorage.Assets.Weapons
		SkinChanger.GetWeapon = require(ReplicatedStorage.Controllers.InventoryController).peekCurrentEquippedForMovement
		assert(type(SkinChanger.GetWeapon) == "function", "Weapon inventory unavailable")
	end)
	if not ok then
		SkinChanger.LastError = tostring(failure)
		warn("[Vanta Skin] ", SkinChanger.LastError)
		return false
	end
	skinReadLoadout()
	SkinChanger:RefreshCatalog()
	local weapons = SkinChanger.Weapons
	if #weapons == 0 then weapons = { "(none)" } end
	skinSetDropdown("SkinWeapon", weapons, weapons[1])
	SkinChanger.Ready = true
	SkinChanger:RefreshEditor()
	-- force Options values so UI reads them even if control refresh fails
	if Options.SkinWeapon then Options.SkinWeapon.Value = SkinChanger.Weapons[1] or "Knife" end
	return true
end

local _skinLast = { w = "", f = "", wear = -1, k = "", kf = "", kwear = -1, g = "", gf = "", gwear = -1 }
RunService.Heartbeat:Connect(function()
	if not SkinChanger.Ready then return end
	local w = tostring(ov("SkinWeapon", ""))
	local f = tostring(ov("SkinFinish", "Original"))
	local wear = ov("SkinWear", 0)
	if type(wear) ~= "number" then wear = 0 end
	local k = tostring(ov("SkinKnifeModel", "Original"))
	local kf = tostring(ov("SkinKnifeFinish", "Original"))
	local kwear = ov("SkinKnifeWear", 0)
	if type(kwear) ~= "number" then kwear = 0 end
	local g = tostring(ov("SkinGloveModel", "Original"))
	local gf = tostring(ov("SkinGloveFinish", "Original"))
	local gwear = ov("SkinGloveWear", 0)
	if type(gwear) ~= "number" then gwear = 0 end

	if w ~= _skinLast.w then
		_skinLast.w = w
		if not SkinChanger.Syncing then
			SkinChanger:RefreshEditor()
			SkinChanger.NextUpdate = 0
		end
	elseif f ~= _skinLast.f or math.abs(wear - _skinLast.wear) > 1e-4 then
		_skinLast.f = f
		_skinLast.wear = wear
		if not SkinChanger.Syncing then
			SkinChanger:storeSelection()
		end
	end

	if k ~= _skinLast.k then
		_skinLast.k = k
		if not SkinChanger.Syncing then
			if k == "Original" then
				SkinChanger.Loadout.Knife = nil
				SkinChanger:Store()
			elseif SkinChanger.KnifeSet[k] then
				local finishes = SkinChanger.Catalog[k]
				local finish = finishes and (finishes.Stock and "Stock" or next(finishes))
				SkinChanger.Loadout.Knife = { Weapon = k, Skin = finish, Float = 0 }
				SkinChanger:Store()
			end
			SkinChanger:RefreshEditor()
		end
	elseif kf ~= _skinLast.kf or math.abs(kwear - _skinLast.kwear) > 1e-4 then
		_skinLast.kf = kf
		_skinLast.kwear = kwear
		if not SkinChanger.Syncing then
			SkinChanger:storeKnifeSelection()
		end
	end

	if g ~= _skinLast.g then
		_skinLast.g = g
		if not SkinChanger.Syncing then
			if g == "Original" then
				SkinChanger.Loadout.Gloves = nil
				SkinChanger:RestoreGloves()
				SkinChanger:Store()
			elseif SkinChanger.GloveSet[g] then
				local finishes = SkinChanger.Catalog[g]
				local finish = finishes and (finishes.Stock and "Stock" or next(finishes))
				if type(finish) == "string" then
					SkinChanger.Loadout.Gloves = { Weapon = g, Skin = finish, Float = 0 }
					SkinChanger:Store()
				end
			end
			SkinChanger:RefreshEditor()
			SkinChanger.NextUpdate = 0
		end
	elseif gf ~= _skinLast.gf or math.abs(gwear - _skinLast.gwear) > 1e-4 then
		_skinLast.gf = gf
		_skinLast.gwear = gwear
		if not SkinChanger.Syncing then
			SkinChanger:storeGloveSelection()
		end
	end

	if SkinChanger.Updating or os.clock() < SkinChanger.NextUpdate then return end
	SkinChanger.NextUpdate = os.clock() + 0.2
	SkinChanger.Updating = true
	local success, err = pcall(function() SkinChanger:Update() end)
	SkinChanger.Updating = false
	if not success then
		SkinChanger.LastError = tostring(err)
		pcall(function() SkinChanger:RestoreAll() end)
	end
end)

task.spawn(function()
	for _ = 1, 40 do
		if installSkinChanger() then
			VantaNotify({
				Title = "Skinchanger",
				Description = string.format(
					"Catalog loaded (%d weapons, %d knives, %d gloves)",
					#SkinChanger.Weapons,
					#(SkinChanger.Knives or {}),
					#(SkinChanger.Gloves or {})
				),
				Time = 3,
			})
			break
		end
		task.wait(0.5)
	end
	if not SkinChanger.Ready then
		VantaNotify({
			Title = "Skinchanger",
			Description = "Failed: " .. tostring(SkinChanger.LastError),
			Type = "error",
			Time = 5,
		})
	end
end)

end)


----------------------------------------------------------------
-- Model Changer (local visual overlay + asset presets)
----------------------------------------------------------------
;(function()
	local PRESETS = {
		["Triple T"] = 138151705692565,
		["Shrek"] = 4965946518,
		["Verity"] = 77078054144134,
		["Granny"] = 103553900779666,
		["Xor"] = 10594888970,
		["Steve"] = 124736921949602,
		["Shitter"] = 15959717698,
	}
	-- normalize all presets to ~player height so Shrek/Verity match Granny scale
	local TARGET_HEIGHT = 5.4

	local MC = {
		folder = nil,
		model = nil,
		char = nil,
		scale = 1,
		lastKey = "",
		active = false,
		_enforcer = nil,
		_charConn = nil,
		_descConn = nil,
		_lastApply = 0,
		_applying = false,
	}
	getgenv().MethaneModelChanger = MC

	local function notify(msg, err)
		pcall(function()
			Library:Notification(tostring(msg), 3, err and Color3.fromRGB(255, 80, 80) or (Library.Theme and Library.Theme.Accent))
		end)
	end

	local function getChar()
		local c = LocalPlayer.Character
		if c and c.Parent then return c end
		local folder = Workspace:FindFirstChild("Characters")
		if folder then
			local m = folder:FindFirstChild(LocalPlayer.Name)
			if m then return m end
		end
		return nil
	end

	local function getHRP(char)
		if not char then return nil end
		return char:FindFirstChild("HumanoidRootPart")
			or char:FindFirstChild("Torso")
			or char:FindFirstChild("UpperTorso")
			or char:FindFirstChildWhichIsA("BasePart")
	end

	local function isOurs(inst)
		if not inst then return false end
		if MC.folder and inst:IsDescendantOf(MC.folder) then return true end
		if MC.model and inst:IsDescendantOf(MC.model) then return true end
		return false
	end

	local function hidePart(d)
		if not d or isOurs(d) then return end
		pcall(function()
			if d:IsA("BasePart") then
				d.Transparency = 1
				d.LocalTransparencyModifier = 1
			elseif d:IsA("Decal") or d:IsA("Texture") then
				d.Transparency = 1
			elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
				d.Enabled = false
			elseif d:IsA("Highlight") or d:IsA("BoxHandleAdornment") or d:IsA("SphereHandleAdornment") then
				d.Enabled = false
			end
		end)
	end

	local function hideBody(char)
		if not char then return end
		if tv("ModelHideBody") == false then return end
		for _, d in ipairs(char:GetDescendants()) do
			hidePart(d)
		end
	end

	local function stopEnforcer()
		if MC._enforcer then
			pcall(function() MC._enforcer:Disconnect() end)
			MC._enforcer = nil
		end
		if MC._descConn then
			pcall(function() MC._descConn:Disconnect() end)
			MC._descConn = nil
		end
	end

	local function startEnforcer(char)
		stopEnforcer()
		if not char then return end
		-- every frame: force-hide default body (stops flash on round reset)
		MC._enforcer = RunService.RenderStepped:Connect(function()
			if not MC.active or not tv("ModelChanger") then return end
			local c = MC.char
			if not c or not c.Parent then
				c = getChar()
				MC.char = c
			end
			if not c then return end
			for _, d in ipairs(c:GetDescendants()) do
				hidePart(d)
			end
		end)
		MC._descConn = char.DescendantAdded:Connect(function(d)
			if not MC.active then return end
			task.defer(function() hidePart(d) end)
		end)
	end

	local function loadAssetModel(assetId)
		assetId = tonumber(assetId)
		if not assetId then return nil, "bad id" end
		local model = nil
		local err = nil
		pcall(function()
			if type(getobjects) == "function" then
				local t = getobjects("rbxassetid://" .. tostring(assetId))
				model = t and t[1]
			end
		end)
		if not model then
			pcall(function()
				local t = game:GetObjects("rbxassetid://" .. tostring(assetId))
				model = t and t[1]
			end)
		end
		if not model then
			local ok, res = pcall(function()
				return game:GetService("InsertService"):LoadAsset(assetId)
			end)
			if ok and res then
				model = res:IsA("Model") and res or res:GetChildren()[1]
			else
				err = tostring(res)
			end
		end
		if not model then return nil, err or "load failed" end
		if model:IsA("Model") then return model end
		local wrap = Instance.new("Model")
		wrap.Name = "MethaneMC"
		model.Parent = wrap
		return wrap
	end

	local function autoScale(model, userScale)
		userScale = tonumber(userScale) or 1
		if userScale <= 0 then userScale = 1 end
		local h = TARGET_HEIGHT
		pcall(function()
			local size = model:GetExtentsSize()
			if size and size.Y > 0.05 then
				h = size.Y
			end
		end)
		local factor = (TARGET_HEIGHT / math.max(h, 0.05)) * userScale
		-- clamp extreme autoscales
		factor = math.clamp(factor, 0.08, 4)
		pcall(function()
			if model:IsA("Model") and model.ScaleTo then
				model:ScaleTo(factor)
			else
				for _, d in ipairs(model:GetDescendants()) do
					if d:IsA("BasePart") then
						d.Size = d.Size * factor
					end
				end
			end
		end)
		return factor
	end

	local function modelBoundsY(model)
		local minY, maxY = math.huge, -math.huge
		local any = false
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 0.99 then
				any = true
				local cf, size = d.CFrame, d.Size
				-- world-space vertical extents of the oriented box (approx via corners)
				local hx, hy, hz = size.X * 0.5, size.Y * 0.5, size.Z * 0.5
				for _, ox in ipairs({ -hx, hx }) do
					for _, oy in ipairs({ -hy, hy }) do
						for _, oz in ipairs({ -hz, hz }) do
							local wy = (cf * CFrame.new(ox, oy, oz)).Position.Y
							if wy < minY then minY = wy end
							if wy > maxY then maxY = wy end
						end
					end
				end
			end
		end
		if not any then
			pcall(function()
				local cf, size = model:GetBoundingBox()
				minY = cf.Position.Y - size.Y * 0.5
				maxY = cf.Position.Y + size.Y * 0.5
			end)
		end
		if minY == math.huge then minY, maxY = 0, 0 end
		return minY, maxY
	end

	local function charFeetY(char, hrp)
		-- prefer lowest visible body part on the real character (not our overlay)
		local minY = math.huge
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") and not isOurs(d) then
				local n = d.Name
				if n == "LeftFoot" or n == "RightFoot" or n == "Left Leg" or n == "Right Leg"
					or n == "LeftLowerLeg" or n == "RightLowerLeg" then
					local y = d.Position.Y - d.Size.Y * 0.5
					if y < minY then minY = y end
				end
			end
		end
		if minY < math.huge then return minY end
		-- fallback: HRP is ~hip; feet ~3 studs below on player-sized rigs
		return hrp.Position.Y - 3
	end

	local function weldModel(model, hrp, char)
		char = char or hrp.Parent
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("Script") or d:IsA("LocalScript") then
				pcall(function() d:Destroy() end)
			elseif d:IsA("Humanoid") then
				pcall(function()
					d.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
					d.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
					d.PlatformStand = true
				end)
			end
		end
		local primary = model.PrimaryPart
		if not primary then
			primary = model:FindFirstChild("HumanoidRootPart")
				or model:FindFirstChild("Torso")
				or model:FindFirstChild("UpperTorso")
				or model:FindFirstChildWhichIsA("BasePart")
			if primary and model:IsA("Model") then
				pcall(function() model.PrimaryPart = primary end)
			end
		end

		-- 1) align pivot to HRP
		pcall(function()
			if model:IsA("Model") then
				model:PivotTo(hrp.CFrame)
			elseif primary then
				primary.CFrame = hrp.CFrame
			end
		end)

		-- 2) lift so model feet sit on character feet (fixes Shrek/Verity buried in floor)
		pcall(function()
			local mMin = select(1, modelBoundsY(model))
			local feet = charFeetY(char, hrp)
			local dy = feet - mMin
			-- small pad so soles aren't under the floor mesh
			dy = dy + 0.05
			if math.abs(dy) > 0.001 then
				if model:IsA("Model") then
					model:PivotTo(model:GetPivot() + Vector3.new(0, dy, 0))
				elseif primary then
					primary.CFrame = primary.CFrame + Vector3.new(0, dy, 0)
				end
			end
		end)

		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				d.Anchored = false
				d.CanCollide = false
				d.CanQuery = false
				d.CanTouch = false
				d.Massless = true
				d.CastShadow = true
				local w = Instance.new("WeldConstraint")
				w.Part0 = hrp
				w.Part1 = d
				w.Parent = d
			end
		end
	end

	function MC.clear()
		MC.active = false
		stopEnforcer()
		pcall(function() if MC.model then MC.model:Destroy() end end)
		pcall(function() if MC.folder then MC.folder:Destroy() end end)
		MC.model, MC.folder, MC.char, MC.lastKey = nil, nil, nil, ""
		MC._applying = false
	end

	function MC.apply()
		if MC._applying then return end
		if not tv("ModelChanger") then
			MC.clear()
			return
		end
		local now = os.clock()
		if now - (MC._lastApply or 0) < 0.4 then return end

		local preset = tostring(ov("ModelPreset", "Triple T") or "Triple T")
		local scale = tonumber(ov("ModelScale", 1)) or 1
		local key = preset .. "|" .. tostring(scale)
		local char = getChar()
		local hrp = getHRP(char)
		if not char or not hrp then return end

		local aid = PRESETS[preset]
		if not aid then
			notify("Unknown model", true)
			return
		end

		-- already correct model on this character
		if MC.model and MC.model.Parent and MC.char == char and MC.lastKey == key then
			MC.active = true
			startEnforcer(char)
			hideBody(char)
			return
		end

		MC._applying = true
		MC._lastApply = now
		MC.active = true
		MC.char = char
		hideBody(char)
		startEnforcer(char)

		local model, err = loadAssetModel(aid)
		if not model then
			MC._applying = false
			notify("Load failed: " .. tostring(err), true)
			return
		end

		-- character may have swapped during load
		char = getChar()
		hrp = getHRP(char)
		if not char or not hrp then
			pcall(function() model:Destroy() end)
			MC._applying = false
			return
		end
		MC.char = char

		pcall(function() if MC.model then MC.model:Destroy() end end)
		pcall(function() if MC.folder then MC.folder:Destroy() end end)

		MC.scale = scale
		MC.lastKey = key
		MC.folder = Instance.new("Folder")
		MC.folder.Name = "MethaneModelChanger"
		MC.folder.Parent = char
		model.Name = "CustomModel"
		model.Parent = MC.folder
		MC.model = model

		autoScale(model, scale)
		weldModel(model, hrp, char)
		hideBody(char)
		startEnforcer(char)
		MC._applying = false
		notify("Model applied: " .. preset)
	end

	-- CharacterAdded (standard)
	pcall(function()
		LocalPlayer.CharacterAdded:Connect(function(char)
			if not tv("ModelChanger") then return end
			MC.active = true
			MC.char = char
			MC.model, MC.folder = nil, nil
			MC.lastKey = ""
			hideBody(char)
			startEnforcer(char)
			task.delay(0.6, function()
				if getChar() == char and tv("ModelChanger") then
					pcall(MC.apply)
				end
			end)
		end)
	end)

	-- Bloxstrike Characters folder respawn
	pcall(function()
		local folder = Workspace:FindFirstChild("Characters")
		if not folder then
			folder = Workspace:WaitForChild("Characters", 10)
		end
		if folder then
			folder.ChildAdded:Connect(function(ch)
				if ch.Name ~= LocalPlayer.Name then return end
				if not tv("ModelChanger") then return end
				MC.active = true
				MC.char = ch
				MC.model, MC.folder = nil, nil
				MC.lastKey = ""
				hideBody(ch)
				startEnforcer(ch)
				task.delay(0.6, function()
					if getChar() == ch and tv("ModelChanger") then
						pcall(MC.apply)
					end
				end)
			end)
		end
	end)

	-- light watchdog (no aggressive re-apply spam)
	task.spawn(function()
		while true do
			task.wait(0.75)
			if not tv("ModelChanger") then
				if MC.active or MC.model then MC.clear() end
				continue
			end
			local char = getChar()
			if not char then continue end
			if MC.char ~= char or not MC.model or not MC.model.Parent then
				pcall(MC.apply)
			else
				hideBody(char)
			end
		end
	end)
end)()



----------------------------------------------------------------
-- Backtrack: position history + adornment chams + rage aim lag
----------------------------------------------------------------
local Backtrack = {
	records = {}, -- [Player] = { { t = number, parts = { [name] = CFrame } }, ... }
	ghosts = {},  -- [Player] = { folder, parts = {}, adorns = {} }
	maxStore = 0.5, -- seconds kept
}
getgenv().MethaneBacktrack = Backtrack

local BT_PARTS = {
	"Head",
	"UpperTorso", "LowerTorso", "Torso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm",
	"RightUpperArm", "RightLowerArm", "RightHand", "Right Arm",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg",
	"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg",
}

local BT = {}
function BT.btClearGhost(plr)
	local g = Backtrack.ghosts[plr]
	if not g then return end
	pcall(function()
		if g.folder then g.folder:Destroy() end
	end)
	Backtrack.ghosts[plr] = nil
end

function BT.btEnsureGhost(plr)
	local g = Backtrack.ghosts[plr]
	if g and g.folder and g.folder.Parent then return g end
	BT.btClearGhost(plr)
	local folder = Instance.new("Folder")
	folder.Name = "MethaneBT_" .. tostring(plr.UserId)
	folder.Parent = Workspace.CurrentCamera or Workspace
	g = { folder = folder, parts = {}, adorns = {} }
	Backtrack.ghosts[plr] = g
	return g
end

function BT.btRecord()
	if not tv("Backtrack") then
		for plr in pairs(Backtrack.ghosts) do BT.btClearGhost(plr) end
		Backtrack.records = {}
		return
	end
	local now = os.clock()
	local keep = math.max((tonumber(ov("BacktrackMs", 200)) or 200) / 1000 + 0.12, 0.15)
	Backtrack.maxStore = keep
	local seen = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == LocalPlayer then continue end
		if not isValidCombatTarget(plr) then continue end
		-- teamcheck always on (IsEnemy true = same team in this script)
		local teamMate = false
		pcall(function() teamMate = (IsEnemy(plr) == true) end)
		if teamMate then continue end
		local char = plr.Character
		if not char or char:GetAttribute("Dead") == true then continue end
		seen[plr] = true
		local parts = {}
		for _, name in ipairs(BT_PARTS) do
			local p = char:FindFirstChild(name)
			if p and p:IsA("BasePart") then
				parts[name] = p.CFrame
			end
		end
		if not next(parts) then continue end
		local list = Backtrack.records[plr]
		if not list then
			list = {}
			Backtrack.records[plr] = list
		end
		list[#list + 1] = { t = now, parts = parts }
		-- prune
		local cutoff = now - keep
		while list[1] and list[1].t < cutoff do
			table.remove(list, 1)
		end
	end
	for plr in pairs(Backtrack.records) do
		if not seen[plr] then
			Backtrack.records[plr] = nil
			BT.btClearGhost(plr)
		end
	end
end

-- sample closest to (now - ms)
function BT.btSample(plr, ms)
	local list = Backtrack.records[plr]
	if not list or #list == 0 then return nil end
	ms = tonumber(ms) or 0
	if ms <= 0 then return list[#list] end
	local want = os.clock() - (ms / 1000)
	local best, bestDt = nil, math.huge
	for i = 1, #list do
		local rec = list[i]
		local dt = math.abs(rec.t - want)
		if dt < bestDt then
			bestDt = dt
			best = rec
		end
	end
	return best
end

function BT.btPos(plr, partName, ms)
	local rec = BT.btSample(plr, ms)
	if not rec or not rec.parts then return nil end
	local cf = rec.parts[partName] or rec.parts.Head or rec.parts.HumanoidRootPart
	return cf and cf.Position or nil, cf
end

-- adornment chams at historical pose
function BT.btUpdateHighlight()
	if not tv("Backtrack") or not tv("BacktrackHighlight") then
		for plr in pairs(Backtrack.ghosts) do BT.btClearGhost(plr) end
		return
	end
	local ms = tonumber(ov("BacktrackMs", 200)) or 200
	local col = ov("BacktrackColor", Color3.fromRGB(0, 200, 255))
	if typeof(col) ~= "Color3" then col = Color3.fromRGB(0, 200, 255) end
	local tr = tonumber(ov("BacktrackTransparency", 0.55)) or 0.55
	tr = math.clamp(tr, 0.05, 0.95)
	local seen = {}
	for plr, list in pairs(Backtrack.records) do
		if not plr.Parent then continue end
		-- teamcheck always on
		local teamMate = false
		pcall(function() teamMate = (IsEnemy(plr) == true) end)
		if teamMate then
			BT.btClearGhost(plr)
			continue
		end
		local rec = BT.btSample(plr, ms)
		if not rec or not rec.parts then continue end

		-- if standing still, BT overlaps live body → hide ghost so regular chams win
		local still = false
		pcall(function()
			local char = plr.Character
			local live = char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head"))
			local cf = rec.parts.HumanoidRootPart or rec.parts.Head or rec.parts.UpperTorso
			if live and cf and (live.Position - cf.Position).Magnitude < 0.45 then
				still = true
			end
		end)
		if still then
			BT.btClearGhost(plr)
			continue
		end

		seen[plr] = true
		local g = BT.btEnsureGhost(plr)
		for name, cf in pairs(rec.parts) do
			local part = g.parts[name]
			if not part or not part.Parent then
				part = Instance.new("Part")
				part.Name = name
				part.Anchored = true
				part.CanCollide = false
				part.CanQuery = false
				part.CanTouch = false
				part.CastShadow = false
				part.Material = Enum.Material.ForceField
				part.Transparency = 1
				part.Size = Vector3.new(1, 1, 1)
				part.Parent = g.folder
				g.parts[name] = part
				local ad = Instance.new("BoxHandleAdornment")
				ad.Name = "BTAdorn"
				ad.Adornee = part
				ad.AlwaysOnTop = true -- visible through walls
				ad.ZIndex = 2
				ad.Parent = part
				g.adorns[name] = ad
			end
			local ad = g.adorns[name]
			local size = Vector3.new(1, 1, 1)
			pcall(function()
				local live = plr.Character and plr.Character:FindFirstChild(name)
				if live and live:IsA("BasePart") then size = live.Size end
			end)
			part.Size = size
			part.CFrame = cf
			if ad then
				ad.Size = size
				ad.Color3 = col
				ad.Transparency = tr
				ad.AlwaysOnTop = true
				ad.ZIndex = 2
				ad.Visible = true
			end
		end
	end
	for plr in pairs(Backtrack.ghosts) do
		if not seen[plr] then BT.btClearGhost(plr) end
	end
end

do
	local btAcc = 0
	RunService.Heartbeat:Connect(function(dt)
		btAcc = btAcc + (dt or 0.016)
		if btAcc >= 0.033 then
			btAcc = 0
			pcall(BT.btRecord)
		end
		pcall(BT.btUpdateHighlight)
	end)
end

-- ============================================================
-- ANTI-AIM RESOLVER
-- Tracks per-player hit history across parts. On miss streak,
-- rotates candidate hitparts by visibility score to find the
-- real hitbox when target is running anti-aim.
-- ============================================================
local Resolver = {}
do
	-- resolver priority order: visible preferred, body fallback
	local RESOLVE_PARTS = {
		"Head", "UpperTorso", "LowerTorso", "HumanoidRootPart",
		"RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg",
	}
	-- per-player: { hits=0, misses=0, partIdx=1, lastSwitch=0, partScores={} }
	local playerState = {}

	local function getState(plr)
		if not playerState[plr] then
			playerState[plr] = { hits = 0, misses = 0, partIdx = 1, lastSwitch = 0, partScores = {} }
		end
		return playerState[plr]
	end

	-- call on confirmed hit
	function Resolver.noteHit(plr, partName)
		if not plr then return end
		local s = getState(plr)
		s.hits = s.hits + 1
		s.misses = 0
		local ps = s.partScores
		ps[partName] = (ps[partName] or 0) + 1
	end

	-- call on confirmed miss / no damage
	function Resolver.noteMiss(plr)
		if not plr then return end
		local s = getState(plr)
		s.misses = s.misses + 1
		-- after 2 consecutive misses, advance part candidate
		if s.misses >= 2 then
			s.misses = 0
			local now = os.clock()
			-- don't switch faster than once per 0.18s to avoid thrashing
			if (now - s.lastSwitch) >= 0.18 then
				s.lastSwitch = now
				s.partIdx = (s.partIdx % #RESOLVE_PARTS) + 1
			end
		end
	end

	-- returns the best hitpart name for a character, respecting user setting
	-- but overriding with resolver candidate when anti-aim is suspected
	function Resolver.bestPart(char, plr, userPart)
		if not char then return userPart or "Head" end
		local s = plr and getState(plr)

		-- if no miss streak, trust user selection
		if not s or s.misses < 2 then
			local p = char:FindFirstChild(userPart or "Head")
			if p then return userPart or "Head" end
			-- user part missing on this char — fall through to resolver
		end

		-- score all candidates by visibility + historical hit success
		local origin = RAGE.rageEyeOrigin and RAGE.rageEyeOrigin() or Vector3.zero
		local bestName, bestScore = "Head", -math.huge

		for i, name in ipairs(RESOLVE_PARTS) do
			local part = char:FindFirstChild(name)
			if not part then continue end
			local score = 0
			-- historical success weight
			score = score + ((s and s.partScores and s.partScores[name]) or 0) * 3
			-- prefer resolver candidate index
			if s and i == s.partIdx then score = score + 5 end
			-- visibility bonus: visible parts score much higher
			local vis = false
			pcall(function() vis = RAGE.isVisible(part) end)
			if vis then score = score + 10 end
			-- distance penalty: closer parts slightly preferred
			local dist = (part.Position - origin).Magnitude
			score = score - dist * 0.01

			if score > bestScore then
				bestScore = score
				bestName = name
			end
		end

		return bestName
	end

	-- expose so rageTryShoot can feed results back
	getgenv().MethaneResolver = Resolver

	-- clean up state for players who left
	task.spawn(function()
		while true do
			task.wait(5)
			for plr in pairs(playerState) do
				if not plr or not plr.Parent then
					playerState[plr] = nil
				end
			end
		end
	end)
end

local function scoreDist(plr, d)
	d = d or 0
	if isPrioritized and isPrioritized(plr) then
		return d - 1e9
	end
	return d
end

local function FindAllTargets()
	-- skip all work when no combat modules need targets
	local rageOn = tv("Ragebot")
	local silentOn = tv("SilentAim")
	local aimbotOn = tv("Aimbot")
	if not (rageOn or silentOn or aimbotOn) then
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local lchar = LocalPlayer.Character
	if not lchar then return end
	local lHead = lchar:FindFirstChild("Head")
	if not lHead then return end
	RAGE.rageCacheBegin()
	local lHeadPos = lHead.Position
	local screenCenter = cam.ViewportSize / 2

	local sDist, sClose = math.huge, nil
	local aDist, aClose = math.huge, nil
	local rDist, rClose = math.huge, nil
	local rClosePlayer = nil  -- track which player owns rClose for resolver

	-- cache toggles / part order once per scan
	local rageTeam = rageOn and tv("RagebotTeamCheck")
	local rageVis = rageOn and tv("RagebotVisibleCheck")
	local rageWall = rageOn and tv("RagebotWallCheck")
	local userPart = (rageOn and (ov("RageHitPart", "Head") or "Head")) or "Head"
	-- With wall check, only probe primary hitboxes (each may raycast). Limbs rarely win first.
	local partOrder
	if rageWall then
		partOrder = { userPart, "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Torso" }
	else
		partOrder = {
			userPart, "Head", "UpperTorso", "HumanoidRootPart", "LowerTorso", "Torso",
			"RightUpperArm", "LeftUpperArm", "RightUpperLeg", "LeftUpperLeg",
		}
	end
	local needScreen = silentOn or aimbotOn or rageVis

	for _, v in ipairs(Players:GetPlayers()) do
		if v == LocalPlayer then continue end
		if isWhitelisted and isWhitelisted(v) then continue end
		if not isValidCombatTarget(v) then continue end
		local char = v.Character
		if not char then continue end
		if char:GetAttribute("Dead") == true or char:GetAttribute("Invincible") == true then continue end
		if type(ESPF.isAlive) == "function" and not ESPF.isAlive(char) then continue end
		do
			local hp = char:GetAttribute("Health")
			if type(hp) ~= "number" then hp = char:GetAttribute("HP") end
			if type(hp) == "number" and hp <= 0 then continue end
		end

		local targetPart = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
		if not targetPart then continue end

		local screenPos, onScreen
		if needScreen then
			screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
		end

		local isTeam = nil
		local function getIsTeam()
			if isTeam == nil then isTeam = IsEnemy(v) end
			return isTeam
		end

		-- Rage: closest enemy + first hittable LIVE part (user part first, then body)
		-- Backtrack is NOT used for target selection — only optional on bullet position later
		if rageOn then
			local teamOk = true
			if rageTeam and getIsTeam() == true then
				teamOk = false
			end
			if teamOk then
				-- distance prune: skip RAGE.canRageHit when this player cannot beat current best
				local rough = scoreDist(v, (lHeadPos - targetPart.Position).Magnitude)
				if rough < rDist then
					local chosen = nil
					-- seen reused across players — clear in-place instead of allocating
					-- a fresh table every iteration (was a hidden per-frame GC source)
					table.clear(_ragePartSeen)
					for _, name in ipairs(partOrder) do
						if _ragePartSeen[name] then continue end
						_ragePartSeen[name] = true
						local p = char:FindFirstChild(name)
						if not (p and p:IsA("BasePart")) then continue end
						if rageVis then
							local _, onS = cam:WorldToViewportPoint(p.Position)
							if not onS then continue end
						end
						if rageWall then
							if not RAGE.canRageHit(p) then continue end
						end
						chosen = p
						break
					end
					if not chosen and not rageWall then
						chosen = char:FindFirstChild(userPart) or char:FindFirstChild("Head") or targetPart
					elseif not chosen then
						for _, name in ipairs(partOrder) do
							local p = char:FindFirstChild(name)
							if p and p:IsA("BasePart") and RAGE.canRageHit(p) then
								chosen = p
								break
							end
						end
					end
					if chosen then
						local rd = scoreDist(v, (lHeadPos - chosen.Position).Magnitude)
						if rd < rDist then
							rDist = rd
							rClose = chosen
							rClosePlayer = v
						end
					end
				end
			end
		end

		if silentOn then
			if not tv("SilentTeamCheck") or not getIsTeam() then
				local partName = ov("SilentHitPart", "Head") or "Head"
				local hitPart = char:FindFirstChild(partName) or char:FindFirstChild("Head") or targetPart
				if not hitPart then continue end

				-- LIVE position is always the baseline for FOV check and wall check.
				-- Backtrack is ONLY used as the bullet destination on shot — never for
				-- gating whether this player gets selected. The old code replaced aimPos
				-- with BT.btPos and then skipped the player when BT.btPos returned nil (no BT
				-- record yet), silently dropping every target when Backtrack is toggled on
				-- but hasn't accumulated history (first few seconds, or player just spawned).
				local livePos = hitPart.Position
				if typeof(livePos) ~= "Vector3" then continue end

				-- FOV check against live screen position
				local sp, onS = cam:WorldToViewportPoint(livePos)
				if not onS then continue end
				local sd = (Vector2.new(sp.X, sp.Y) - screenCenter).Magnitude
				local fovR = tv("SilentUseFovCircle") and (ov("SilentFovCircleRadius", 50)) or 999999
				if sd > fovR then continue end

				-- Wall check against live position.
				-- If backtrack has a record we also check that position — if EITHER is
				-- clear we accept the target (live peek OR ghost peek is a valid shot).
				if not tv("SilentWallbang") then
					local function rayVis(checkPos)
						local result = false
						pcall(function()
							local delta = checkPos - lHeadPos
							local dist = delta.Magnitude
							if dist < 0.05 then result = true return end
							local ignore = {}
							if LocalPlayer.Character then table.insert(ignore, LocalPlayer.Character) end
							if char then table.insert(ignore, char) end
							table.insert(ignore, cam)
							_silentWallRp.FilterDescendantsInstances = ignore
							local hit = Workspace:Raycast(lHeadPos, delta.Unit * dist, _silentWallRp)
							result = (hit == nil) or ((hit.Position - checkPos).Magnitude < 1.5)
						end)
						return result
					end

					local vis = rayVis(livePos)

					-- also check backtrack ghost position if available
					if not vis and tv("Backtrack") then
						local ms = tonumber(ov("BacktrackMs", 200)) or 200
						local bp = select(1, BT.btPos(v, partName, ms))
						if typeof(bp) ~= "Vector3" then bp = select(1, BT.btPos(v, "Head", ms)) end
						if typeof(bp) == "Vector3" then
							vis = rayVis(bp)
						end
					end

					if not vis then continue end
				end

				-- Score by screen distance to live position (what the player actually sees)
				local scored = scoreDist(v, sd)
				if scored < sDist then
					sDist = scored
					sClose = hitPart
				end
			end
		end

		if aimbotOn and onScreen then
			if not tv("AimbotTeamCheck") or not getIsTeam() then
				local ad = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
				local fovR = tv("AimbotUseFovCircle") and (ov("AimbotFovCircleRadius", 50)) or 999999
				if ad <= fovR then
					if not tv("AimbotWallCheck") or RAGE.isVisible(targetPart) then
						local scored = scoreDist(v, ad)
						if scored < aDist then
							aDist = scored
							aClose = char:FindFirstChild(ov("AimbotHitPart", "Head")) or targetPart
						end
					end
				end
			end
		end
	end

	SilentTarget = sClose
	AimbotTarget = aClose
	RageTarget = rClose
	getgenv().MethaneRageTargetPlayer = rClosePlayer  -- expose for resolver feedback

	getgenv().MethaneRageBacktrackPos = nil
	getgenv().MethaneSilentBacktrackPos = nil
	local ms = (tv("Backtrack") and (tonumber(ov("BacktrackMs", 200)) or 200)) or 0
	if rClose and ms > 0 then
		local plr = rClosePlayer
		if not plr then
			pcall(function()
				local m = rClose:FindFirstAncestorOfClass("Model")
				plr = m and Players:GetPlayerFromCharacter(m)
			end)
		end
		if plr then
			local partName = ov("RageHitPart", "Head") or "Head"
			local pos = select(1, BT.btPos(plr, partName, ms))
			if typeof(pos) == "Vector3" then
				getgenv().MethaneRageBacktrackPos = pos
			end
		end
	end
	if sClose then
		local plr = nil
		pcall(function()
			local m = sClose:FindFirstAncestorOfClass("Model")
			plr = m and Players:GetPlayerFromCharacter(m)
		end)
		if plr then
			local partName = ov("SilentHitPart", "Head") or "Head"
			-- Use backtrack position if available, otherwise fall back to the live
			-- part position. This ensures MethaneSilentBacktrackPos is always a valid
			-- Vector3 so the bullet hook (SendFunc) always has a destination to write.
			-- The old code only wrote when ms > 0 AND BT.btPos returned a value, meaning
			-- non-backtrack sessions left it nil and the shot went to the live part anyway
			-- which is correct — but this makes the fallback explicit and consistent.
			local hitPos = sClose.Position  -- live fallback
			if ms > 0 then
				local bp = select(1, BT.btPos(plr, partName, ms))
				if typeof(bp) ~= "Vector3" then bp = select(1, BT.btPos(plr, "Head", ms)) end
				if typeof(bp) == "Vector3" then hitPos = bp end
			end
			getgenv().MethaneSilentBacktrackPos = hitPos
		end
	end
	local function partToPlayer(part)
		if not part then return nil end
		local m = part:FindFirstAncestorOfClass("Model")
		if m then return Players:GetPlayerFromCharacter(m) end
		return nil
	end
	getgenv().MethaneSilentTarget = partToPlayer(sClose)
	getgenv().MethaneAimbotTarget = partToPlayer(aClose)
	getgenv().MethaneRageTarget = rClosePlayer or partToPlayer(rClose)
	getgenv().MethaneCurrentTarget = getgenv().MethaneRageTarget or getgenv().MethaneSilentTarget or getgenv().MethaneAimbotTarget
	local function partModel(part)
		return part and part:FindFirstAncestorOfClass("Model") or nil
	end
	getgenv().MethaneSilentTargetModel = partModel(sClose)
	getgenv().MethaneAimbotTargetModel = partModel(aClose)
	getgenv().MethaneRageTargetModel = partModel(rClose)
	getgenv().MethaneCurrentTargetModel = getgenv().MethaneRageTargetModel or getgenv().MethaneSilentTargetModel or getgenv().MethaneAimbotTargetModel
end

RunService.RenderStepped:Connect(function()
	frameCounter = frameCounter + 1
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local center = cam.ViewportSize / 2
	local sShow = tv("SilentAim") and tv("SilentUseFovCircle")
	local aShow = tv("Aimbot") and tv("AimbotUseFovCircle")
	local sR = ov("SilentFovCircleRadius", 50)
	local aR = ov("AimbotFovCircleRadius", 50)
	local sCol = ov("SilentFovColor", Color3.fromRGB(255, 255, 255))
	local aCol = ov("AimbotFovColor", Color3.fromRGB(255, 255, 255))
	if typeof(sCol) ~= "Color3" then sCol = Color3.fromRGB(255, 255, 255) end
	if typeof(aCol) ~= "Color3" then aCol = Color3.fromRGB(255, 255, 255) end

	SilentFovOl.Position = center
	SilentFovCircle.Position = center
	SilentFovOl.Radius = sR
	SilentFovCircle.Radius = sR
	SilentFovCircle.Color = sCol
	SilentFovOl.Visible = sShow
	SilentFovCircle.Visible = sShow

	AimbotFovOl.Position = center
	AimbotFovCircle.Position = center
	AimbotFovOl.Radius = aR
	AimbotFovCircle.Radius = aR
	AimbotFovCircle.Color = aCol
	AimbotFovOl.Visible = aShow
	AimbotFovCircle.Visible = aShow

	-- Throttle target scan:
	--  Silent/Aimbot FOV needs ~60Hz feel; Rage-only is fine at ~30Hz (shoots on Heartbeat).
	local now = os.clock()
	local needFast = tv("SilentAim") or tv("Aimbot")
	local interval = needFast and 0.016 or 0.033
	if now - (_fatLast or 0) >= interval then
		_fatLast = now
		FindAllTargets()
	end

end)

----------------------------------------------------------------
-- GC hooks: firerate / recoil / spread / flash / smoke / shoot
----------------------------------------------------------------
local original = {}
local firerateobjs = {}
local SendFunc = nil
local updateCam = nil
local getCurrentEquipped = nil

pcall(function()
	for _, obj in next, getgc(true) do
		if type(obj) == "table" and (rawget(obj, "FireRate") ~= nil or rawget(obj, "Automatic") ~= nil) then
			pcall(function()
				-- only weapon-ish tables
				if rawget(obj, "FireRate") ~= nil or rawget(obj, "Damage") ~= nil or rawget(obj, "Automatic") ~= nil then
					table.insert(original, {
						FireRate = rawget(obj, "FireRate"),
						Automatic = rawget(obj, "Automatic"),
					})
					table.insert(firerateobjs, obj)
				end
			end)
		end
		if type(obj) == "table" and rawget(obj, "setWeaponRecoil") then
			pcall(function()
				local oldSetWeaponRecoil
				oldSetWeaponRecoil = hookfunction(obj.setWeaponRecoil, function(config, ...)
					if tv("NoRecoil") then
						local pct = tonumber(ov("RecoilControl", 100)) or 100
						local remain = math.clamp((100 - pct) / 100, 0, 1)
						if remain <= 0.001 then return end
						if type(config) == "table" and type(config.Value) == "number" then
							local scaled = {}
							for k, v in pairs(config) do scaled[k] = v end
							scaled.Value = config.Value * remain
							return oldSetWeaponRecoil(scaled, ...)
						end
					end
					return oldSetWeaponRecoil(config, ...)
				end)
			end)
		end
		if type(obj) == "function" and debug.getinfo(obj).name == "calculateRecoilOffset" then
			pcall(function()
				local calculateRecoilOffset
				calculateRecoilOffset = hookfunction(obj, function(...)
					if tv("NoRecoil") then
						local pct = tonumber(ov("RecoilControl", 100)) or 100
						local remain = math.clamp((100 - pct) / 100, 0, 1)
						if remain <= 0.001 then return UDim2.new() end
						local r = calculateRecoilOffset(...)
						if typeof(r) == "UDim2" then
							return UDim2.new(r.X.Scale * remain, r.X.Offset * remain, r.Y.Scale * remain, r.Y.Offset * remain)
						end
						return r
					end
					return calculateRecoilOffset(...)
				end)
			end)
		end
		if type(obj) == "table" and rawget(obj, "weaponKick") then
			pcall(function()
				local oldweaponkick
				oldweaponkick = hookfunction(obj.weaponKick, function(p1, p2, ...)
					if tv("NoRecoil") then
						local pct = tonumber(ov("RecoilControl", 100)) or 100
						local remain = math.clamp((100 - pct) / 100, 0, 1)
						if remain <= 0.001 then return end
						local function scaleKV(t)
							if type(t) ~= "table" or type(t.Value) ~= "number" then return t end
							local out = {}
							for k, v in pairs(t) do out[k] = v end
							out.Value = t.Value * remain
							return out
						end
						p1, p2 = scaleKV(p1), scaleKV(p2)
					end
					return oldweaponkick(p1, p2, ...)
				end)
			end)
		end
		if type(obj) == "table" and rawget(obj, "getTrueSpread") then
			pcall(function()
				local oldgettruespread
				oldgettruespread = hookfunction(obj.getTrueSpread, function(p1, ...)
					if tv("NoSpread") then
						local pct = tonumber(ov("SpreadControl", 100)) or 100
						local remain = math.clamp((100 - pct) / 100, 0, 1)
						if remain <= 0.001 then return 0 end
						local s = oldgettruespread(p1, ...)
						if type(s) == "number" then return s * remain end
						return s
					end
					return oldgettruespread(p1, ...)
				end)
			end)
		end
		if type(obj) == "function" and debug.getinfo(obj).name == "Flash" then
			pcall(function()
				local oldflash
				oldflash = hookfunction(obj, function(...)
					if tv("Antiflashbang") or tv("AntiFlash") then return end
					return oldflash(...)
				end)
			end)
		end
		if type(obj) == "function" and debug.getinfo(obj).name == "CreateVoxel" then
			pcall(function()
				local up = debug.getupvalue(obj, 1)
				if tostring(up) == "Smoke" then
					local oldsmoke
					oldsmoke = hookfunction(obj, function(...)
						if tv("Antismoke") or tv("AntiSmoke") then return end
						return oldsmoke(...)
					end)
				end
			end)
		end
		if type(obj) == "table" and rawget(obj, "shoot") then
			if obj.shoot and typeof(obj.shoot) == "function" and #debug.getupvalues(obj.shoot) == 26 then
				pcall(function()
					local inv = debug.getupvalue(obj.shoot, 14).Inventory
					SendFunc = inv.ShootWeapon.Send
					if inv.ReloadWeapon and type(inv.ReloadWeapon.Send) == "function" then
						getgenv()._MethaneReloadSend = inv.ReloadWeapon.Send
					end
				end)
			end
		end
		if type(obj) == "table" and rawget(obj, "getCurrentEquipped") then
			pcall(function() getCurrentEquipped = obj.getCurrentEquipped end)
		end

	end
end)

pcall(function()
	updateCam = filtergc("table", { Keys = { "updateCamera" } }, true).updateCamera
end)

local function getEquipped()
	local success, result = pcall(function()
		return debug.getupvalue(getCurrentEquipped, 1).CurrentEquipped
	end)
	if not success then return nil end
	return result
end

local Weapon = nil
task.spawn(function()
	while task.wait(0.2) do
		pcall(function()
			if getCurrentEquipped then Weapon = getEquipped(); getgenv().MethaneWeapon = Weapon end
		end)
	end
end)

-- Auto Reload: call weapon reload when mag hits empty (no instant / no wait hooks)
do
	local lastAuto = 0
	local function callReload(w)
		if type(w) ~= "table" then return end
		for _, rk in ipairs({ "reload", "reloadWeapon", "Reload", "startReload", "StartReload" }) do
			local fn = rawget(w, rk)
			if type(fn) == "function" then
				pcall(fn, w)
				return true
			end
		end
		return false
	end

	task.spawn(function()
		local prev = nil
		while task.wait(0.1) do
			if not tv("AutoReload") then
				prev = nil
				continue
			end
			pcall(function()
				local w = Weapon or getgenv().MethaneWeapon
				if type(w) ~= "table" then return end
				local rnd = rawget(w, "Rounds")
				if type(rnd) ~= "number" then rnd = w.Rounds end
				if type(rnd) == "number" then
					if rnd <= 0 and (prev == nil or prev > 0) then
						local t = os.clock()
						if t - lastAuto > 0.2 then
							lastAuto = t
							callReload(w)
						end
					end
					prev = rnd
				end
			end)
		end
	end)

	getgenv().MethaneAutoReload = {
		Fire = function()
			callReload(Weapon or getgenv().MethaneWeapon)
		end,
	}
end

pcall(function()
	if not updateCam then return end
	local oldUpdateCam
	oldUpdateCam = hookfunction(updateCam, function(p1)
		if tv("Aimbot") and AimbotTarget and Options.AimbotHoldkey and Options.AimbotHoldkey.GetState and Options.AimbotHoldkey:GetState() then
			local ok, lookCF = pcall(function()
				return CFrame.lookAt(workspace.CurrentCamera.CFrame.Position, AimbotTarget.Position)
			end)
			if ok and lookCF then p1 = lookCF end
		end
		return oldUpdateCam(p1)
	end)
end)

pcall(function()
	local old56
	old56 = hookfunction(task.wait, function(t)
		if t == 5 then
			hitboxsafe = true
			t = 9e9
		end
		return old56(t)
	end)
end)

task.spawn(function()
	repeat task.wait() until hitboxsafe
	VantaNotify({ Title = "Success", Description = "Hitbox will now work", Time = 4 })
end)

-- Ragebot fire: fast retarget + resolver feedback on hit/miss
do
	local lastRageShot = 0
	local lastTargetChar = nil
	local lastTargetHp = nil
	local lastTargetPart = nil  -- track part name for resolver hit reporting
	-- cache: part -> ancestor Model, avoids repeated FindFirstAncestorOfClass every shot
	local charCache = {}
	local charCacheTimer = 0

	local function rageCharOf(part)
		if not part then return nil end
		local cached = charCache[part]
		if cached then
			-- invalidate if part left its model
			if cached.Parent == part.Parent then return cached end
			charCache[part] = nil
		end
		local m = part:FindFirstAncestorOfClass("Model")
		if m then charCache[part] = m end
		return m
	end

	local function rageTargetStillValid(part)
		if not part or not part.Parent then return false, nil, 0 end
		local char = rageCharOf(part)
		if not char or not char.Parent then return false, char, 0 end
		if char:GetAttribute("Dead") == true then return false, char, 0 end
		if char:GetAttribute("Invincible") == true then return false, char, 0 end
		if type(ESPF.isAlive) == "function" and not ESPF.isAlive(char) then return false, char, 0 end
		local hp = char:GetAttribute("Health")
		if type(hp) ~= "number" then hp = char:GetAttribute("HP") end
		if type(hp) ~= "number" then
			local hum = char:FindFirstChildOfClass("Humanoid")
			hp = hum and hum.Health
		end
		if type(hp) == "number" and hp <= 0 then return false, char, 0 end
		return true, char, tonumber(hp) or 100
	end

	local function rageRetarget()
		RageTarget = nil
		getgenv().MethaneRageTarget = nil
		getgenv().MethaneRageTargetModel = nil
		getgenv().MethaneRageTargetPlayer = nil
		-- Force next RenderStepped FindAllTargets call to run immediately (bypass throttle)
		-- instead of calling FindAllTargets() here mid-Heartbeat — avoids a double full scan
		-- on the same tick when a target dies or goes invalid.
		_fatLast = 0
	end

	-- periodic charCache flush so stale parts don't accumulate
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		if now - charCacheTimer > 3 then
			charCacheTimer = now
			charCache = {}
		end
	end)

	local function rageTryShoot()
		if not tv("Ragebot") then return end
		if not Weapon or not Weapon.IsEquipped then return end
		local rounds = Weapon.Rounds
		if type(rounds) == "number" and rounds <= 0 then return end

		local live = true
		pcall(function()
			local ch = LocalPlayer.Character
			if ch and (ch:GetAttribute("Dead") == true or ch:GetAttribute("Invincible") == true) then
				live = false
			end
		end)
		if not live then return end

		-- drop dead / invalid lock immediately and pick next
		local ok, char, hp = rageTargetStillValid(RageTarget)
		if not ok then
			if RageTarget ~= nil then
				rageRetarget()
			end
			ok, char, hp = rageTargetStillValid(RageTarget)
			if not ok then return end
		end

		-- body went 0hp since last shot — switch target before dumping more rounds
		if char and lastTargetChar == char and type(lastTargetHp) == "number" and type(hp) == "number" then
			if hp <= 0 or (lastTargetHp > 0 and hp <= 0) then
				-- feed resolver: this target died, last part was correct
				local rplr = getgenv().MethaneRageTargetPlayer
				if rplr and lastTargetPart then
					pcall(function() Resolver.noteHit(rplr, lastTargetPart) end)
				end
				rageRetarget()
				ok, char, hp = rageTargetStillValid(RageTarget)
				if not ok then return end
			end
		end

		local delay = tonumber(ov("RageDelay", 0)) or 0
		if delay < 0 then delay = 0 end
		local now = os.clock()
		if delay > 0 and (now - lastRageShot) < delay then
			return
		end
		-- tight floor: 0.004s — fires up to 2x faster than the old 0.008 floor,
		-- still prevents double-dump within the same Heartbeat tick (~0.016s at 60fps).
		if (now - lastRageShot) < 0.004 then
			return
		end

		-- snapshot hp before shot for resolver hit/miss detection
		local preHp = hp
		lastRageShot = now
		lastTargetChar = char
		lastTargetHp = hp
		lastTargetPart = RageTarget and RageTarget.Name or nil

		local rplr = getgenv().MethaneRageTargetPlayer
		if not rplr and char then
			pcall(function() rplr = Players:GetPlayerFromCharacter(char) end)
		end

		pcall(function()
			if rplr then
				if getgenv().MethaneNoteLocalShot then getgenv().MethaneNoteLocalShot(rplr) end
				if getgenv().MethaneHitLogMarkShot then
					getgenv().MethaneHitLogMarkShot(rplr, RageTarget, "Ragebot")
				end
			end
		end)
		pcall(function() Weapon:shoot() end)

		-- post-shot resolver feedback: did hp drop?
		task.defer(function()
			local still, ch2, hp2 = rageTargetStillValid(RageTarget)
			if not still then
				rageRetarget()
			else
				lastTargetHp = hp2
				-- detect miss: hp unchanged after shot → notify resolver to advance candidate
				if rplr and type(preHp) == "number" and type(hp2) == "number" then
					if hp2 >= preHp - 0.5 then
						-- no damage registered — miss, advance resolver
						pcall(function() Resolver.noteMiss(rplr) end)
					else
						-- confirmed damage — resolver note hit
						pcall(function() Resolver.noteHit(rplr, lastTargetPart or "Head") end)
					end
				end
			end
		end)
	end

	RunService.Heartbeat:Connect(function()
		rageTryShoot()
	end)
end

task.spawn(function()
	while true do
		task.wait(ov("TriggerbotDelay", 0.01))
		if tv("Triggerbot") then
			local mouse = LocalPlayer:GetMouse()
			if mouse and mouse.Target then
				local char = mouse.Target:FindFirstAncestorOfClass("Model")
				if char then
					local player = Players:GetPlayerFromCharacter(char)
					if player and not char:GetAttribute("Dead") and not char:GetAttribute("Invincible") then
						if IsEnemy(player) then
							if Weapon and Weapon.IsEquipped and Weapon.Rounds and Weapon.Rounds > 0 then
								pcall(function()
									if getgenv().MethaneNoteLocalShot then getgenv().MethaneNoteLocalShot(player) end
									if getgenv().MethaneHitLogMarkShot then
										local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
										getgenv().MethaneHitLogMarkShot(player, part, "Ragebot")
									end
								end)
								pcall(function() Weapon:shoot() end)
							end
						end
					end
				end
			end
		end
	end
end)

pcall(function()
	if not SendFunc then return end
	local oldshoot
	oldshoot = hookfunction(SendFunc, function(...)
		local args = { ... }
		if args[1] and args[1].Bullets and args[1].Bullets[1] then
			local bullet = args[1].Bullets[1]
			-- local outbound shot
			pcall(function()
				local plr = getgenv().MethaneRageTarget or getgenv().MethaneSilentTarget
				if getgenv().MethaneNoteLocalShot then getgenv().MethaneNoteLocalShot(plr) end
			end)
			if bullet.Hits and bullet.Hits[1] then
				local redirected = nil
				if tv("Ragebot") and RageTarget then
					bullet.Hits[1].Instance = RageTarget
					local livePos = RageTarget.Position
					local bp = getgenv().MethaneRageBacktrackPos
					local useBt = tv("Backtrack") and typeof(bp) == "Vector3"
					if not useBt and tv("Backtrack") then
						pcall(function()
							local plr = getgenv().MethaneRageTarget
							if plr then
								local partName = ov("RageHitPart", "Head") or "Head"
								local ms = tonumber(ov("BacktrackMs", 200)) or 200
								bp = select(1, BT.btPos(plr, partName, ms))
								if typeof(bp) == "Vector3" then useBt = true end
							end
						end)
					end
					local hitPos = (useBt and bp) or livePos
					bullet.Hits[1].Position = hitPos
					getgenv().MethaneRageHitPos = hitPos
					redirected = RageTarget
				end
				if tv("SilentAim") and SilentTarget then
					local hc = tonumber(ov("SilentHitChance", 100)) or 100
					if hc >= 100 or math.random(1, 100) <= hc then
						bullet.Hits[1].Instance = SilentTarget
						local livePos = SilentTarget.Position
						local bp = getgenv().MethaneSilentBacktrackPos
						-- Always prefer backtrack pose when enabled (not only when live is hidden)
						local useBt = tv("Backtrack") and typeof(bp) == "Vector3"
						if not useBt and typeof(bp) ~= "Vector3" and tv("Backtrack") then
							-- last-chance sample if genv pos missing this frame
							pcall(function()
								local plr = getgenv().MethaneSilentTarget
								if plr then
									local partName = ov("SilentHitPart", "Head") or "Head"
									local ms = tonumber(ov("BacktrackMs", 200)) or 200
									bp = select(1, BT.btPos(plr, partName, ms))
									if typeof(bp) == "Vector3" then useBt = true end
								end
							end)
						end
						local hitPos = (useBt and bp) or livePos
						bullet.Hits[1].Position = hitPos
						-- keep goal vector for direction rewrite below
						getgenv().MethaneSilentHitPos = hitPos
						redirected = SilentTarget
					end
				end
				-- 3rd person: game would use orbit cam as origin → force FP eye so hits register
				if redirected then
					pcall(function()
						local origin = nil
						if getgenv().MethaneRageEyeOrigin then
							origin = getgenv().MethaneRageEyeOrigin()
						end
						if typeof(origin) ~= "Vector3" then
							local ch = LocalPlayer.Character
							local head = ch and ch:FindFirstChild("Head")
							if head then origin = head.Position end
						end
						if typeof(origin) ~= "Vector3" then return end
						local goal = redirected.Position
						if tv("SilentAim") and typeof(getgenv().MethaneSilentHitPos) == "Vector3" then
							goal = getgenv().MethaneSilentHitPos
						elseif tv("Ragebot") and typeof(getgenv().MethaneRageHitPos) == "Vector3" then
							goal = getgenv().MethaneRageHitPos
						end
						local delta = goal - origin
						if delta.Magnitude < 0.05 then return end
						local dir = delta.Unit
						if bullet.Origin ~= nil then bullet.Origin = origin end
						if bullet.Start ~= nil then bullet.Start = origin end
						if rawget(bullet, "Position") ~= nil or bullet.Position ~= nil then
							pcall(function() bullet.Position = origin end)
						end
						if bullet.Direction ~= nil then bullet.Direction = dir end
						if typeof(bullet.Velocity) == "Vector3" then
							local spd = bullet.Velocity.Magnitude
							if spd < 10 then spd = 1500 end
							bullet.Velocity = dir * spd
						end
						-- some builds store eye/muzzle separately
						pcall(function()
							if bullet.MuzzlePosition ~= nil then bullet.MuzzlePosition = origin end
							if bullet.EyePosition ~= nil then bullet.EyePosition = origin end
							if bullet.From ~= nil then bullet.From = origin end
							if bullet.To ~= nil then bullet.To = goal end
						end)
					end)
				end
			end
			-- real bullet path (muzzle → actual hit position from packet)
			pcall(function()
				local hitPos, hitInst = nil, nil
				if bullet.Hits and bullet.Hits[1] then
					hitPos = bullet.Hits[1].Position
					hitInst = bullet.Hits[1].Instance
				end
				local origin = bullet.Origin or bullet.Start or bullet.Position
				if typeof(origin) ~= "Vector3" then
					local ft = getgenv().MethaneFireTracer
					-- use same muzzle finder as tracers via genv helper if present
					origin = nil
				end
				if typeof(origin) ~= "Vector3" then
					local cam = workspace.CurrentCamera
					if cam then
						-- prefer viewmodel muzzle under camera
						for _, d in ipairs(cam:GetDescendants()) do
							if d:IsA("Attachment") and (d.Name:lower():find("muzzle") or d.Name:lower():find("barrel")) then
								origin = d.WorldPosition
								break
							end
							if d:IsA("BasePart") and (d.Name:lower():find("muzzle") or d.Name:lower() == "fire") then
								origin = d.Position
								break
							end
						end
						if typeof(origin) ~= "Vector3" then
							origin = cam.CFrame.Position + cam.CFrame.LookVector * 1.2
						end
					end
				end
				if typeof(hitPos) ~= "Vector3" and typeof(origin) == "Vector3" then
					local dir = bullet.Direction or bullet.Velocity
					local cam2 = workspace.CurrentCamera
					if typeof(dir) == "Vector3" and dir.Magnitude > 0 then
						hitPos = origin + dir.Unit * 500
					elseif cam2 then
						hitPos = origin + cam2.CFrame.LookVector * 500
					end
				end
				if typeof(origin) == "Vector3" and typeof(hitPos) == "Vector3" then
					if getgenv().MethaneNotePacketTracer then
						getgenv().MethaneNotePacketTracer()
					end
					if getgenv().MethaneFireTracer then
						getgenv().MethaneFireTracer(origin, hitPos)
					end
				end
				-- hitmarker only on real body hits
				if hitInst and typeof(hitPos) == "Vector3" then
					local okEnemy = false
					if getgenv().MethaneHitIsEnemy then
						okEnemy = getgenv().MethaneHitIsEnemy(hitInst) == true
					end
					if okEnemy and getgenv().MethaneSpawnHitmark then
						getgenv().MethaneSpawnHitmark(hitPos, hitInst)
					end
				end
			end)
		end
		return oldshoot(unpack(args))
	end)
end)

task.spawn(function()
	while task.wait(0.05) do
		pcall(function()
			local doFr = tv("Firerate")
			local doAuto = tv("ForceAuto")
			for i, obj in ipairs(firerateobjs) do
				pcall(function()
					setreadonly(obj, false)
					if doFr and rawget(obj, "FireRate") ~= nil then
						rawset(obj, "FireRate", math.max(ov("FirerateSlider", 0.01), 0.01))
					elseif original[i] and original[i].FireRate ~= nil then
						rawset(obj, "FireRate", original[i].FireRate)
					end
					if doAuto and rawget(obj, "Automatic") ~= nil then
						rawset(obj, "Automatic", true)
					elseif original[i] and original[i].Automatic ~= nil then
						rawset(obj, "Automatic", original[i].Automatic)
					end
					setreadonly(obj, true)
				end)
			end
			-- live equipped weapon instance (semi pistols etc.)
			if Weapon then
				pcall(function()
					if doAuto then
						if Weapon.Automatic ~= nil then Weapon.Automatic = true end
						if type(Weapon) == "table" and rawget(Weapon, "Automatic") ~= nil then
							rawset(Weapon, "Automatic", true)
						end
					end
					if doFr and Weapon.FireRate ~= nil then
						Weapon.FireRate = math.max(ov("FirerateSlider", 0.01), 0.01)
					end
				end)
			end
		end)
	end
end)

----------------------------------------------------------------

----------------------------------------------------------------
-- WORLD systems (skybox / lighting / FOV / resolution / self chams)
----------------------------------------------------------------
local Lighting = game:GetService("Lighting")

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

local world = {
	skybox_enabled = false,
	skybox_value = "None",
	auto_rotate = false,
	auto_rotate_speed = 1,
	lighting_skybox = nil,
	auto_rotate_conn = nil,
	camera_fov = 70,
	fov_enabled = false,
	camera_resolution = 1,
	arms_enabled = false,
	arms_mat = "ForceField",
	arms_color = Color3.fromRGB(120, 170, 255),
	arms_trans = 0.3,
	weapon_enabled = false,
	weapon_mat = "ForceField",
	weapon_color = Color3.fromRGB(120, 170, 255),
	weapon_trans = 0.3,
	view_pos_enabled = false,
	view_pos_scoped = false,
	view_x = 0, view_y = 0, view_z = 0,
	view_pitch = 0, view_yaw = 0, view_roll = 0,
	_orig_parts = {},
	model_chams = false,
	model_mat = "ForceField",
	model_color = Color3.fromRGB(120, 170, 255),
	model_trans = 0.3,
	_orig_model = {},
	third_person = false,
	third_dist = 8,
	_cam_record = nil,
}

local WFX = {}
function WFX.SanitizeTextureId(id)
	if type(id) ~= "string" or id == "" then return "" end
	if id:find("rbxasset") then return id end
	return "rbxassetid://" .. tostring(id):gsub("%D", "")
end

WFX._skyHooked = false
function WFX.UpdateSkybox()
	if not world.skybox_enabled then
		return
	end
	-- game often destroys / replaces Sky when entering a match — always re-own it
	if not world.lighting_skybox or world.lighting_skybox.Parent == nil then
		for _, child in ipairs(Lighting:GetChildren()) do
			if child:IsA("Sky") then
				pcall(function() child:Destroy() end)
			end
		end
		world.lighting_skybox = Instance.new("Sky")
		world.lighting_skybox.Name = "VantaSky"
		world.lighting_skybox.Parent = Lighting
	end
	if not WFX._skyHooked then
		WFX._skyHooked = true
		Lighting.ChildAdded:Connect(function(child)
			if not world.skybox_enabled then return end
			if child:IsA("Sky") and child ~= world.lighting_skybox then
				task.defer(function()
					pcall(function() child:Destroy() end)
					if world.skybox_enabled then
						pcall(WFX.UpdateSkybox)
					end
				end)
			end
		end)
	end
	local preset = kSkyboxMap[world.skybox_value] or kSkyboxMap["None"]
	local function face(preset_val)
		return WFX.SanitizeTextureId(preset_val or "")
	end
	local sky = world.lighting_skybox
	if not sky or sky.Parent == nil then return end
	sky.SkyboxBk = face(preset.skybox_back)
	sky.SkyboxDn = face(preset.skybox_down)
	sky.SkyboxFt = face(preset.skybox_front)
	sky.SkyboxLf = face(preset.skybox_left)
	sky.SkyboxRt = face(preset.skybox_right)
	sky.SkyboxUp = face(preset.skybox_up)
	if preset.sun_texture then sky.SunTextureId = face(preset.sun_texture) end
	if preset.moon_texture then sky.MoonTextureId = face(preset.moon_texture) end
end

function WFX.SetSkyboxAutoRotate()
	if world.auto_rotate_conn then
		pcall(function() world.auto_rotate_conn:Disconnect() end)
		world.auto_rotate_conn = nil
	end
	if not world.skybox_enabled or not world.auto_rotate then return end
	if world.lighting_skybox == nil then WFX.UpdateSkybox() end
	world.auto_rotate_conn = RunService.Heartbeat:Connect(function(dt)
		if not world.lighting_skybox then return end
		local orient = world.lighting_skybox.SkyboxOrientation
		world.lighting_skybox.SkyboxOrientation = Vector3.new(0, orient.Y + dt * world.auto_rotate_speed * 10, 0)
	end)
end

WFX.world_cc = nil
WFX.lightingBackup = nil
WFX.ambientBackup = nil
WFX.fullbrightWasOn = false

function WFX.snapshotLighting()
	return {
		Brightness = Lighting.Brightness,
		ClockTime = Lighting.ClockTime,
		FogEnd = Lighting.FogEnd,
		FogStart = Lighting.FogStart,
		FogColor = Lighting.FogColor,
		GlobalShadows = Lighting.GlobalShadows,
		OutdoorAmbient = Lighting.OutdoorAmbient,
		Ambient = Lighting.Ambient,
		ColorShift_Top = Lighting.ColorShift_Top,
		ColorShift_Bottom = Lighting.ColorShift_Bottom,
		ExposureCompensation = Lighting.ExposureCompensation,
	}
end

function WFX.restoreLighting(snap)
	if not snap then return end
	pcall(function()
		Lighting.Brightness = snap.Brightness
		Lighting.ClockTime = snap.ClockTime
		Lighting.FogEnd = snap.FogEnd
		Lighting.FogStart = snap.FogStart
		Lighting.FogColor = snap.FogColor
		Lighting.GlobalShadows = snap.GlobalShadows
		Lighting.OutdoorAmbient = snap.OutdoorAmbient
		Lighting.Ambient = snap.Ambient
		Lighting.ColorShift_Top = snap.ColorShift_Top
		Lighting.ColorShift_Bottom = snap.ColorShift_Bottom
		Lighting.ExposureCompensation = snap.ExposureCompensation
	end)
end

function WFX.ensureCC()
	if WFX.world_cc and WFX.world_cc.Parent then return WFX.world_cc end
	WFX.world_cc = Lighting:FindFirstChild("VantaCC")
	if not WFX.world_cc then
		WFX.world_cc = Instance.new("ColorCorrectionEffect")
		WFX.world_cc.Name = "VantaCC"
		WFX.world_cc.Parent = Lighting
	end
	return WFX.world_cc
end

function WFX.matFromName(name)
	if type(name) ~= "string" or name == "" then
		return Enum.Material.ForceField
	end
	local ok, m = pcall(function() return Enum.Material[name] end)
	if ok and m then return m end
	return Enum.Material.ForceField
end

-- Bloxstrike FP viewmodel chams (Arms / Weapon hierarchy)
function WFX.categoryPart(part, root, weaponOnly)
	if not part or not part:IsA("BasePart") then return nil end
	if part.Transparency >= 1 then return nil end
	if weaponOnly then return "gun" end
	local current = part
	while current and current ~= root do
		local name = current.Name
		if name == "Left Arm" or name == "Right Arm" or name == "LeftHand" or name == "RightHand"
			or name == "LeftUpperArm" or name == "RightUpperArm" or name == "LeftLowerArm" or name == "RightLowerArm"
			or name == "Left Arm" or name == "Right Arm" then
			return "hand"
		end
		if name == "Weapon" or name == "WeaponL" or name == "WeaponR" or name == "Knife" or name == "Blade" then
			return "gun"
		end
		current = current.Parent
	end
	-- unnamed mesh on main model → treat as weapon body
	if part:IsA("MeshPart") or part:IsA("UnionOperation") then
		return "gun"
	end
	return "gun"
end

function WFX.stripLooks(part, store)
	pcall(function()
		if part:IsA("MeshPart") then
			store.TextureID = part.TextureID
			part.TextureID = ""
		end
		store.surfaces = store.surfaces or {}
		store.decals = store.decals or {}
		store.meshes = store.meshes or {}
		for _, ch in ipairs(part:GetChildren()) do
			if ch:IsA("SurfaceAppearance") then
				-- keep reference, reparent under part on restore
				table.insert(store.surfaces, ch)
				ch.Parent = nil
			elseif ch:IsA("Decal") or ch:IsA("Texture") then
				table.insert(store.decals, { obj = ch, Transparency = ch.Transparency })
				ch.Transparency = 1
			elseif ch:IsA("SpecialMesh") then
				table.insert(store.meshes, { obj = ch, TextureId = ch.TextureId })
				ch.TextureId = ""
			end
		end
	end)
end

function WFX.gatherFromModel(model, weaponOnly, out)
	if not model then return end
	pcall(function()
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				local kind = WFX.categoryPart(d, model, weaponOnly)
				if kind then
					table.insert(out, { part = d, kind = kind })
				end
			end
		end
	end)
end

WFX._vmCache, WFX._vmCacheAt = {}, 0
function WFX.invalidateViewmodelCache()
	WFX._vmCache, WFX._vmCacheAt = {}, 0
end
function WFX.findViewmodels()
	local now = os.clock()
	-- short cache; invalidated on camera/viewmodel changes
	if now - WFX._vmCacheAt < 0.05 and #WFX._vmCache > 0 then
		-- drop dead refs
		local alive = false
		for _, vm in ipairs(WFX._vmCache) do
			if vm and vm.Model and vm.Model.Parent then alive = true break end
		end
		if alive then return WFX._vmCache end
	end
	local list = {}
	pcall(function()
		if Weapon and Weapon.Viewmodel and Weapon.Viewmodel.Model then
			table.insert(list, Weapon.Viewmodel)
		end
	end)
	if #list == 0 then
		pcall(function()
			local cam = workspace.CurrentCamera
			if cam then
				for _, ch in ipairs(cam:GetChildren()) do
					if ch:IsA("Model") then
						table.insert(list, { Model = ch })
					end
				end
			end
		end)
	end
	-- rare fallback scan (max once per 2s if still empty)
	if #list == 0 and now - (WFX._vmCacheAt or 0) > 2 then
		pcall(function()
			for _, obj in next, getgc(false) do -- tables only, lighter
				if type(obj) == "table" then
					local model = rawget(obj, "Model")
					if model and typeof(model) == "Instance" and model:IsA("Model") and rawget(obj, "Player") == LocalPlayer then
						table.insert(list, obj)
						break
					end
				end
			end
		end)
	end
	WFX._vmCache = list
	WFX._vmCacheAt = now
	return list
end

function WFX.collectSelfParts()
	local parts = {}
	local seen = {}
	for _, vm in ipairs(WFX.findViewmodels()) do
		WFX.gatherFromModel(vm.Model, false, parts)
		WFX.gatherFromModel(vm.LargeWeaponModel, true, parts)
		WFX.gatherFromModel(vm.SmallWeaponModel, true, parts)
		-- some knives only on Model
	end
	-- dedupe
	local out = {}
	for _, e in ipairs(parts) do
		if e.part and not seen[e.part] then
			seen[e.part] = true
			table.insert(out, e)
		end
	end
	return out
end


-- Instant viewmodel chams: no vanilla flash on equip / new meshes
do
	local function tryChams()
		if not world then return end
		if world.third_person or world.arms_enabled or world.weapon_enabled then
			WFX.invalidateViewmodelCache()
			pcall(WFX.applySelfChams)
		end
	end
	local function hookCam(cam)
		if not cam then return end
		cam.ChildAdded:Connect(function(ch)
			task.defer(tryChams)
			pcall(function()
				if ch:IsA("Model") or ch:IsA("BasePart") then
					ch.DescendantAdded:Connect(function()
						task.defer(tryChams)
					end)
				end
			end)
		end)
		cam.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") or d:IsA("MeshPart") then
				-- paint this frame before render if possible
				if world and (world.arms_enabled or world.weapon_enabled or world.third_person) then
					pcall(WFX.applySelfChams)
				end
			end
		end)
	end
	pcall(function()
		hookCam(workspace.CurrentCamera)
		workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
			hookCam(workspace.CurrentCamera)
			tryChams()
		end)
	end)
	-- Pre-render pass so chams beat the first frame of a new viewmodel
	RunService.RenderStepped:Connect(function()
		if not world then return end
		if world.arms_enabled or world.weapon_enabled or world.third_person then
			pcall(WFX.applySelfChams)
		end
	end)
end

function WFX.restoreSelfChams()
	if not world or type(world._orig_parts) ~= "table" then return end
	for part, data in pairs(world._orig_parts) do
		pcall(function()
			if part and part.Parent then
				part.Material = data.Material
				pcall(function() part.MaterialVariant = data.MaterialVariant or "" end)
				part.Color = data.Color
				part.Transparency = data.Transparency
				part.LocalTransparencyModifier = 0
				if data.TextureID ~= nil and part:IsA("MeshPart") then
					part.TextureID = data.TextureID
				end
				if data.surfaces then
					for _, sa in ipairs(data.surfaces) do
						pcall(function()
							if sa then sa.Parent = part end
						end)
					end
				end
				if data.decals then
					for _, d in ipairs(data.decals) do
						pcall(function()
							if d.obj then d.obj.Transparency = d.Transparency end
						end)
					end
				end
				if data.meshes then
					for _, m in ipairs(data.meshes) do
						pcall(function()
							if m.obj then m.obj.TextureId = m.TextureId end
						end)
					end
				end
			end
		end)
	end
	world._orig_parts = {}
end

function WFX.applySelfChams()
	local parts = WFX.collectSelfParts()
	-- 3rd person: always fully hide viewmodel
	if world.third_person then
		for _, entry in ipairs(parts) do
			local part = entry.part
			if not part or not part.Parent then continue end
			if not world._orig_parts[part] then
				local store = {
					Material = part.Material,
					MaterialVariant = "",
					Color = part.Color,
					Transparency = part.Transparency,
					TextureID = nil,
					surfaces = {},
					decals = {},
					meshes = {},
				}
				pcall(function() store.MaterialVariant = part.MaterialVariant end)
				WFX.stripLooks(part, store)
				world._orig_parts[part] = store
			end
			pcall(function()
				part.Transparency = 1
				part.LocalTransparencyModifier = 1
			end)
		end
		return
	end

	local armsOn = world.arms_enabled == true
	local gunOn = world.weapon_enabled == true
	if not armsOn and not gunOn then
		WFX.restoreSelfChams()
		return
	end

	for _, entry in ipairs(parts) do
		local part = entry.part
		if not part or not part.Parent then continue end
		local kind = entry.kind or "gun"
		local use = (kind == "hand" and armsOn) or (kind == "gun" and gunOn)
		if not use then
			-- restore this part if we had painted it before
			local data = world._orig_parts[part]
			if data then
				pcall(function()
					part.Material = data.Material
					pcall(function() part.MaterialVariant = data.MaterialVariant or "" end)
					part.Color = data.Color
					part.Transparency = data.Transparency
					part.LocalTransparencyModifier = 0
					if data.TextureID ~= nil and part:IsA("MeshPart") then
						part.TextureID = data.TextureID
					end
					if data.surfaces then
						for _, sa in ipairs(data.surfaces) do
							pcall(function() sa.Parent = part end)
						end
					end
					if data.decals then
						for _, d in ipairs(data.decals) do
							pcall(function() d.obj.Transparency = d.Transparency end)
						end
					end
					if data.meshes then
						for _, m in ipairs(data.meshes) do
							pcall(function() m.obj.TextureId = m.TextureId end)
						end
					end
				end)
				world._orig_parts[part] = nil
			end
			continue
		end

		local matName = (kind == "hand") and world.arms_mat or world.weapon_mat
		local col = (kind == "hand") and world.arms_color or world.weapon_color
		local tr = (kind == "hand") and world.arms_trans or world.weapon_trans
		local mat = WFX.matFromName(matName)

		if not world._orig_parts[part] then
			local store = {
				Material = part.Material,
				MaterialVariant = "",
				Color = part.Color,
				Transparency = part.Transparency,
				TextureID = nil,
				surfaces = {},
				decals = {},
				meshes = {},
			}
			pcall(function() store.MaterialVariant = part.MaterialVariant end)
			WFX.stripLooks(part, store)
			world._orig_parts[part] = store
		end
		pcall(function()
			for _, ch in ipairs(part:GetChildren()) do
				if ch:IsA("SurfaceAppearance") then ch.Parent = nil end
			end
			if part:IsA("MeshPart") then part.TextureID = "" end
			part.Material = mat
			pcall(function() part.MaterialVariant = "" end)
			part.Color = col
			part.Transparency = tr
			part.LocalTransparencyModifier = 0
		end)
	end
end

----------------------------------------------------------------
-- Viewmodel position (Bac0n-style PivotTo offset)
----------------------------------------------------------------
function WFX.isViewAiming(view)
	local ok, aiming = pcall(function()
		return view and view.Bobble and view.Bobble.IsAiming == true
	end)
	return ok and aiming == true
end

function WFX.offsetViewmodel(view, camera)
	if not view or not view.Model or not view.Model.Parent or not camera then return end
	local original = view.Model:GetPivot()
	local offset = CFrame.new(world.view_x or 0, world.view_y or 0, world.view_z or 0)
		* CFrame.Angles(
			math.rad(world.view_pitch or 0),
			math.rad(world.view_yaw or 0),
			math.rad(world.view_roll or 0)
		)
	pcall(function()
		view.Model:PivotTo(camera.CFrame * offset * camera.CFrame:ToObjectSpace(original))
		if view.LargeWeaponModel and view.SmallWeaponModel then
			view.LargeWeaponModel:PivotTo(view.SmallWeaponModel:GetPivot())
		end
	end)
end

function WFX.applyViewPosition()
	if world.third_person then return end
	if not world.view_pos_enabled then return end
	local cam = workspace.CurrentCamera
	if not cam then return end
	for _, view in ipairs(WFX.findViewmodels()) do
		if world.view_pos_scoped and WFX.isViewAiming(view) then
			continue
		end
		WFX.offsetViewmodel(view, cam)
	end
end

-- Prefer hooking Viewmodel.render (same as Bac0n); fallback is RenderStepped in world loop
task.spawn(function()
	for _ = 1, 30 do
		local ok, viewmod = pcall(function()
			return require(ReplicatedStorage.Classes.WeaponComponent.Classes.Viewmodel)
		end)
		if ok and type(viewmod) == "table" and type(viewmod.render) == "function" then
			local old = viewmod.render
			viewmod.render = function(view, ...)
				local results = table.pack(old(view, ...))
				pcall(function()
					if world.view_pos_enabled and not world.third_person then
						if not (world.view_pos_scoped and WFX.isViewAiming(view)) then
							WFX.offsetViewmodel(view, workspace.CurrentCamera)
						end
					end
				end)
				return table.unpack(results, 1, results.n)
			end
			break
		end
		task.wait(0.5)
	end
end)

----------------------------------------------------------------
-- Third person + model chams
----------------------------------------------------------------
-- Third person + model chams
----------------------------------------------------------------

-- Third person: never free the mouse (LockCenter always)
-- DUMP BUGFIX: setMouseEnabled(p45) has NO self — calling fn(ctrl, false)
-- made p45 = ctrl (truthy) → free cursor. Always call fn(false) only.
-- camera helpers in own function scope (avoids main-chunk 200 local register limit)
;(function()
local tpActive = false
local tpModeConn, tpZoomConn = nil, nil
local tpSavedSubject = nil
local tpControllers = {}
local tpCtrlCached = false

function WFX.collectCameraControllers()
	if tpCtrlCached and #tpControllers > 0 then return tpControllers end
	table.clear(tpControllers)
	pcall(function()
		for _, obj in next, getgc(true) do
			if type(obj) == "table" then
				local a = rawget(obj, "setMouseEnabled")
				local b = rawget(obj, "setForceLockOverride")
				if type(a) == "function" and type(b) == "function" then
					table.insert(tpControllers, obj)
				end
			end
		end
	end)
	tpCtrlCached = #tpControllers > 0
	return tpControllers
end

-- dump APIs take plain args, NOT (self, ...)
function WFX.camApi(fnName, ...)
	local args = { ... }
	for _, ctrl in ipairs(tpControllers) do
		local fn = rawget(ctrl, fnName)
		if type(fn) == "function" then
			pcall(fn, table.unpack(args))
		end
	end
end

function WFX.lockMouseFps()
	-- Main menu guard: no character = player hasn't spawned into a match yet.
	-- Locking the mouse here breaks the menu UI — cursor disappears and you can't click Play.
	-- Skip the lock entirely; it's meaningless without a live character anyway.
	local char = LocalPlayer and LocalPlayer.Character
	if not char or not char.Parent then return end

	-- only lock — never pass true, never Default
	WFX.camApi("resetForceLockOverride")
	WFX.camApi("setMouseEnabled", false)
	WFX.camApi("setForceLockOverride", "VantaThirdPerson", false)
	pcall(function()
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end)
end

function WFX.findCameraPart()
	local cam = workspace.CurrentCamera
	if not cam then return nil end
	local p = cam:FindFirstChild("CameraPart")
	if p then return p end
	for _, d in ipairs(cam:GetDescendants()) do
		if d.Name == "CameraPart" then return d end
	end
	if tpSavedSubject and typeof(tpSavedSubject) == "Instance" and tpSavedSubject.Parent then
		return tpSavedSubject
	end
	return nil
end

function WFX.disconnectTp()
	if tpModeConn then pcall(function() tpModeConn:Disconnect() end) tpModeConn = nil end
	if tpZoomConn then pcall(function() tpZoomConn:Disconnect() end) tpZoomConn = nil end
	pcall(function() RunService:UnbindFromRenderStep("VantaThirdPerson") end)
	pcall(function() RunService:UnbindFromRenderStep("VantaFPRestore") end)
end

function WFX.forceFpsCameraNow()
	pcall(function()
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		LocalPlayer.CameraMinZoomDistance = 0.5
		LocalPlayer.CameraMaxZoomDistance = 0.5
		local cam = workspace.CurrentCamera
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			local part = WFX.findCameraPart()
			if part then cam.CameraSubject = part end
		end
	end)
	WFX.lockMouseFps()
end

function WFX.startFpRestoreWatchdog()
	pcall(function() RunService:UnbindFromRenderStep("VantaFPRestore") end)
	local untilT = os.clock() + 0.8
	local frames = 0
	RunService:BindToRenderStep("VantaFPRestore", Enum.RenderPriority.Last.Value, function()
		frames = frames + 1
		if (world and world.third_person) or os.clock() > untilT or frames > 50 then
			pcall(function() RunService:UnbindFromRenderStep("VantaFPRestore") end)
			return
		end
		pcall(function()
			if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter
				or UserInputService.MouseIconEnabled then
				WFX.lockMouseFps()
			end
			if LocalPlayer.CameraMode ~= Enum.CameraMode.LockFirstPerson then
				LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
				LocalPlayer.CameraMinZoomDistance = 0.5
				LocalPlayer.CameraMaxZoomDistance = 0.5
			end
			local cam = workspace.CurrentCamera
			if cam and cam.CameraSubject and cam.CameraSubject:IsA("Humanoid") then
				local part = WFX.findCameraPart()
				if part then cam.CameraSubject = part end
			end
		end)
	end)
end

function setThirdPerson(active)
	active = active == true
	if active then
		if tpActive then return end
		tpActive = true
		world.third_person = true
		pcall(function() RunService:UnbindFromRenderStep("VantaFPRestore") end)

		local cam = workspace.CurrentCamera
		local dist = ov("WorldThirdDist", 8)
		if type(dist) ~= "number" then dist = 8 end
		dist = math.clamp(dist, 2, 30)
		world.third_dist = dist

		tpSavedSubject = cam and cam.CameraSubject or nil
		world._cam_record = {
			Mode = LocalPlayer.CameraMode,
			Min = LocalPlayer.CameraMinZoomDistance,
			Max = LocalPlayer.CameraMaxZoomDistance,
			Subject = tpSavedSubject,
		}

		WFX.collectCameraControllers()
		WFX.lockMouseFps() -- stay locked while entering 3rd

		WFX.disconnectTp()
		tpModeConn = LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(function()
			if not world.third_person then return end
			if LocalPlayer.CameraMode == Enum.CameraMode.LockFirstPerson then
				local d = world.third_dist or 8
				LocalPlayer.CameraMode = Enum.CameraMode.Classic
				LocalPlayer.CameraMinZoomDistance = d
				LocalPlayer.CameraMaxZoomDistance = d
			end
		end)
		tpZoomConn = LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(function()
			if not world.third_person then return end
			local d = world.third_dist or 8
			if LocalPlayer.CameraMinZoomDistance ~= d then
				LocalPlayer.CameraMinZoomDistance = d
				LocalPlayer.CameraMaxZoomDistance = d
			end
		end)

		RunService:BindToRenderStep("VantaThirdPerson", Enum.RenderPriority.Last.Value, function()
			if not tpActive or not world.third_person then return end
			local d = ov("WorldThirdDist", 8)
			if type(d) ~= "number" then d = 8 end
			d = math.clamp(d, 2, 30)
			world.third_dist = d
			-- mouse always locked in 3rd (never free cursor)
			pcall(function()
				UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
				UserInputService.MouseIconEnabled = false
			end)
			world._tpMouseTick = (world._tpMouseTick or 0) + 1
			if world._tpMouseTick >= 30 then
				world._tpMouseTick = 0
				WFX.camApi("setMouseEnabled", false)
			end
			pcall(function()
				LocalPlayer.CameraMode = Enum.CameraMode.Classic
				LocalPlayer.CameraMinZoomDistance = d
				LocalPlayer.CameraMaxZoomDistance = d
				local c = workspace.CurrentCamera
				if c then
					local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
					if hum then c.CameraSubject = hum end
					if c.CameraType == Enum.CameraType.Scriptable then
						c.CameraType = Enum.CameraType.Custom
					end
				end
			end)
			local char = LocalPlayer.Character
			if char then
				for _, ch in ipairs(char:GetChildren()) do
					if ch:IsA("BasePart") then
						ch.LocalTransparencyModifier = 0
					else
						for _, p in ipairs(ch:GetChildren()) do
							if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
						end
					end
				end
			end
		end)
	else
		if not tpActive and not (world and world.third_person) then return end
		tpActive = false
		if world then world.third_person = false end
		WFX.disconnectTp()

		pcall(function()
			WFX.restoreModelChams()
			if world then world._model_char = nil world._orig_model = {} end
		end)
		pcall(function()
			WFX.restoreSelfChams()
			if tv("WorldArmsEnabled") or tv("WorldWeaponEnabled") then WFX.applySelfChams() end
		end)

		WFX.collectCameraControllers()
		WFX.forceFpsCameraNow()
		WFX.startFpRestoreWatchdog()
	end
end

end)()

-- WORLD loop (throttled — do not touch Lighting/getgc every frame)
-- task.spawn keeps locals off the main-chunk register limit (200)
task.spawn(function()

function WFX.restoreModelChams()
	if not world or type(world._orig_model) ~= "table" then return end
	for part, data in pairs(world._orig_model) do
		pcall(function()
			if part and part.Parent then
				part.Material = data.Material
				part.Color = data.Color
				part.Transparency = data.Transparency
				if data.TextureID ~= nil and part:IsA("MeshPart") then
					part.TextureID = data.TextureID
				end
				if data.surfaces then
					for _, sa in ipairs(data.surfaces) do
						pcall(function() if sa then sa.Parent = part end end)
					end
				end
			end
		end)
	end
	world._orig_model = {}
end

function WFX.applyModelChams()
	if not world.model_chams or not world.third_person then
		WFX.restoreModelChams()
		world._model_char = nil
		return
	end
	local char = LocalPlayer.Character
	if not char then return end
	-- new character / new round: drop old orig cache so materials re-bind
	if world._model_char ~= char then
		world._orig_model = {}
		world._model_char = char
	end
	local mat = WFX.matFromName(world.model_mat)
	local col = world.model_color
	local tr = world.model_trans
	for _, part in ipairs(char:GetDescendants()) do
		if not part:IsA("BasePart") then continue end
		if part.Name == "HumanoidRootPart" then continue end
		if part.Transparency >= 1 and not world._orig_model[part] then continue end
		if not world._orig_model[part] then
			local store = {
				Material = part.Material,
				Color = part.Color,
				Transparency = part.Transparency,
				TextureID = part:IsA("MeshPart") and part.TextureID or nil,
				surfaces = {},
			}
			pcall(function()
				for _, ch in ipairs(part:GetChildren()) do
					if ch:IsA("SurfaceAppearance") then
						table.insert(store.surfaces, ch)
						ch.Parent = nil
					end
				end
				if part:IsA("MeshPart") then part.TextureID = "" end
			end)
			world._orig_model[part] = store
		end
		pcall(function()
			part.Material = mat
			pcall(function() part.MaterialVariant = "" end)
			part.Color = col
			part.Transparency = tr
			part.LocalTransparencyModifier = 0
			if part:IsA("MeshPart") then part.TextureID = "" end
		end)
	end
end


	local lastSkyCheck = 0
	local lastChams = 0
	local lastLight = 0
	local lightDirty = true
	RunService.Heartbeat:Connect(function()
		local now = os.clock()
		world._tick = (world._tick or 0) + 1

		-- Lighting / ambience / CC at most ~10 Hz
		if now - lastLight > 0.1 then
			lastLight = now
			local fbOn = tv("WorldFullbright")
			if fbOn then
				if not WFX.fullbrightWasOn then
					WFX.lightingBackup = WFX.snapshotLighting()
					WFX.fullbrightWasOn = true
				end
				Lighting.Brightness = 2
				Lighting.ClockTime = 14
				Lighting.FogEnd = 9e9
				Lighting.FogStart = 0
				Lighting.GlobalShadows = false
				Lighting.Ambient = Color3.fromRGB(200, 200, 200)
				Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			else
				if WFX.fullbrightWasOn then
					WFX.restoreLighting(WFX.lightingBackup)
					WFX.lightingBackup = nil
					WFX.fullbrightWasOn = false
				end
				-- optional manual lighting (only when fullbright off)
				local br = ov("WorldBrightness", 2)
				local ct = ov("WorldClock", 14)
				local exp = ov("WorldExposure", 0)
				-- only push slider values if user moved them from defaults OR always apply clock/brightness as user controls
				if type(br) == "number" then Lighting.Brightness = br end
				if type(ct) == "number" then Lighting.ClockTime = ct end
				pcall(function() Lighting.ExposureCompensation = exp end)
				if tv("WorldAmbientEnabled") then
					if not WFX.ambientBackup then
						WFX.ambientBackup = {
							Ambient = Lighting.Ambient,
							OutdoorAmbient = Lighting.OutdoorAmbient,
							ColorShift_Top = Lighting.ColorShift_Top,
							ColorShift_Bottom = Lighting.ColorShift_Bottom,
						}
					end
					local a = ov("WorldAmbient", Color3.fromRGB(128, 128, 128))
					local o = ov("WorldOutdoorAmbient", Color3.fromRGB(128, 128, 128))
					local t1 = ov("WorldColorShiftTop", Color3.fromRGB(0, 0, 0))
					local t2 = ov("WorldColorShiftBot", Color3.fromRGB(0, 0, 0))
					if typeof(a) == "Color3" then Lighting.Ambient = a end
					if typeof(o) == "Color3" then Lighting.OutdoorAmbient = o end
					if typeof(t1) == "Color3" then Lighting.ColorShift_Top = t1 end
					if typeof(t2) == "Color3" then Lighting.ColorShift_Bottom = t2 end
				else
					if WFX.ambientBackup then
						pcall(function()
							Lighting.Ambient = WFX.ambientBackup.Ambient
							Lighting.OutdoorAmbient = WFX.ambientBackup.OutdoorAmbient
							Lighting.ColorShift_Top = WFX.ambientBackup.ColorShift_Top
							Lighting.ColorShift_Bottom = WFX.ambientBackup.ColorShift_Bottom
						end)
						WFX.ambientBackup = nil
					end
				end
			end
			local ccOn = tv("WorldCC")
			local cc = WFX.ensureCC()
			cc.Enabled = ccOn == true
			if ccOn then
				cc.Brightness = ov("WorldCCBright", 0)
				cc.Contrast = ov("WorldCCContrast", 0)
				cc.Saturation = ov("WorldCCSat", 0)
				local tint = ov("WorldCCTint", Color3.fromRGB(255, 255, 255))
				if typeof(tint) == "Color3" then cc.TintColor = tint end
			end
		end

		-- Skybox: only if enabled, check ~2 Hz
		local skyOn = tv("WorldSkybox")
		local skyPreset = tostring(ov("WorldSkyboxPreset", "None"))
		local skyChanged = (skyOn ~= world.skybox_enabled) or (skyPreset ~= world.skybox_value)
		world.skybox_enabled = skyOn == true
		world.skybox_value = skyPreset
		if skyOn then
			-- re-apply often so match/FP camera swaps cannot strip our Sky
			if skyChanged or now - lastSkyCheck > 0.15 then
				lastSkyCheck = now
				pcall(WFX.UpdateSkybox)
			end
		elseif skyChanged then
			-- turned off: leave current sky (game may replace); clear our ref so next enable recreates
			world.lighting_skybox = nil
		end
		local rot = tv("WorldSkyRotate")
		local rotSpd = ov("WorldSkyRotateSpeed", 1)
		if rot ~= world.auto_rotate or rotSpd ~= world.auto_rotate_speed then
			world.auto_rotate = rot
			world.auto_rotate_speed = type(rotSpd) == "number" and rotSpd or 1
			pcall(WFX.SetSkyboxAutoRotate)
		end

		-- Third person: sync UI toggle → state (camera handled in VantaThirdPerson bind)
		local wantThird = tv("WorldThirdPerson") == true
		if wantThird ~= world.third_person then
			setThirdPerson(wantThird)
		end

		-- Viewmodel: separate hands vs weapon + position
		world.arms_enabled = tv("WorldArmsEnabled") == true
		world.arms_mat = ov("WorldArmsMat", "ForceField")
		local ac = ov("WorldArmsCol", Color3.fromRGB(120, 170, 255))
		if typeof(ac) == "Color3" then world.arms_color = ac end
		world.arms_trans = ov("WorldArmsTrans", 0.3)

		world.weapon_enabled = tv("WorldWeaponEnabled") == true
		world.weapon_mat = ov("WorldWeaponMat", "ForceField")
		local wc = ov("WorldWeaponCol", Color3.fromRGB(120, 170, 255))
		if typeof(wc) == "Color3" then world.weapon_color = wc end
		world.weapon_trans = ov("WorldWeaponTrans", 0.3)

		world.view_pos_enabled = tv("WorldViewPosEnabled") == true
		world.view_pos_scoped = tv("WorldViewPosScoped") == true
		world.view_x = ov("WorldViewX", 0)
		world.view_y = ov("WorldViewY", 0)
		world.view_z = ov("WorldViewZ", 0)
		world.view_pitch = ov("WorldViewPitch", 0)
		world.view_yaw = ov("WorldViewYaw", 0)
		world.view_roll = ov("WorldViewRoll", 0)

		if world.third_person or world.arms_enabled or world.weapon_enabled then
			-- every frame while enabled so new viewmodel parts never flash vanilla
			world._lastSelfChams = now
			pcall(WFX.applySelfChams)
		elseif world and type(world._orig_parts) == "table" and next(world._orig_parts) then
			pcall(WFX.restoreSelfChams)
		end

		-- position fallback if Viewmodel.render hook not ready
		if world.view_pos_enabled and not world.third_person then
			pcall(WFX.applyViewPosition)
		end


		-- Model chams: only while 3rd person is active
		world.model_mat = ov("WorldModelChamsMat", "ForceField")
		local mc = ov("WorldModelChamsCol", Color3.fromRGB(120, 170, 255))
		if typeof(mc) == "Color3" then world.model_color = mc end
		world.model_trans = ov("WorldModelChamsTrans", 0.3)
		world.model_chams = (tv("WorldModelChams") == true) and (world.third_person == true)
		if world.model_chams then
			if now - (world._lastModelChams or 0) > 0.12 then
				world._lastModelChams = now
				pcall(WFX.applyModelChams)
			end
		elseif world and type(world._orig_model) == "table" and next(world._orig_model) then
			pcall(WFX.restoreModelChams)
		end
	end)

	-- FOV: late bind so it wins over game ADS camera
	pcall(function()
		RunService:UnbindFromRenderStep("VantaCamFOV")
	end)
	RunService:BindToRenderStep("VantaCamFOV", Enum.RenderPriority.Camera.Value + 5, function()
		if not tv("WorldFovEnabled") then return end
		local fov = ov("WorldFov", 70)
		if type(fov) ~= "number" then return end
		local cam = workspace.CurrentCamera
		if cam then
			cam.FieldOfView = fov
		end
	end)

	-- Resolution: original screen stretch (separate from FOV)
	local lastRes = 1
	local resCf = CFrame.new()
	RunService.RenderStepped:Connect(function()
		local res = ov("WorldResolution", 1)
		if type(res) ~= "number" then res = 1 end
		if res < 0.1 then res = 0.1 end
		if res > 1 then res = 1 end
		if res == 1 then
			lastRes = 1
			return
		end
		if res ~= lastRes then
			lastRes = res
			resCf = CFrame.new(0, 0, 0, 1, 0, 0, 0, res, 0, 0, 0, 1)
		end
		local cam = workspace.CurrentCamera
		if cam then
			cam.CFrame = cam.CFrame * resCf
		end
	end)
end)

----------------------------------------------------------------
task.spawn(function()
-- WORLD ESP — dropped guns (WeaponDropped) + planted bomb (Bomb)
-- Tags from CollectionService (BloxStrike standard)
----------------------------------------------------------------
local WorldESP = {
	entries = {}, -- [model] = { box, name, chams, kind }
}

local WESP = {}
function WESP.wespNewDraw(kind)
	local ok, o = pcall(Drawing.new, kind)
	if ok and o then return o end
	return nil
end

local _wespIconGui = nil
function WESP.ensureWespIconGui()
	if _wespIconGui and _wespIconGui.Parent then return _wespIconGui end
	local pg = LP:FindFirstChildOfClass("PlayerGui")
	if not pg then return nil end
	local sg = Instance.new("ScreenGui")
	sg.Name = "MethaneWorldESPIcons"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	sg.DisplayOrder = 48
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.Parent = pg
	_wespIconGui = sg
	return sg
end

function WESP.wespEnsure(model, kind)
	local e = WorldESP.entries[model]
	if e then
		e.kind = kind
		return e
	end
	e = {
		kind = kind,
		box_lines = {},
		box_ol = {},
		name = WESP.wespNewDraw("Text"),
		chams = nil,
		icon_img = nil,
		icon_shadow = nil,
		_icon_cached_name = nil,
		_icon_cached_id = nil,
	}
	for i = 1, 4 do
		e.box_lines[i] = WESP.wespNewDraw("Line")
		e.box_ol[i] = WESP.wespNewDraw("Line")
	end
	if e.name then
		e.name.Size = 13
		e.name.Center = true
		e.name.Outline = true
		e.name.OutlineColor = Color3.new(0, 0, 0)
		e.name.Visible = false
		pcall(function() e.name.Font = 2 end)
	end
	WorldESP.entries[model] = e
	-- destroy ESP elements the frame the weapon leaves Workspace (picked up / removed)
	pcall(function()
		model.AncestryChanged:Connect(function(_, newParent)
			if not newParent or not newParent:IsDescendantOf(game.Workspace) then
				WESP.wespDestroy(model)
				wespGuns[model]  = nil
				wespBombs[model] = nil
			end
		end)
	end)
	return e
end

function WESP.wespHide(e)
	if not e then return end
	for i = 1, 4 do
		if e.box_lines[i] then e.box_lines[i].Visible = false end
		if e.box_ol[i] then e.box_ol[i].Visible = false end
	end
	if e.name then e.name.Visible = false end
	pcall(function() if e.icon_img then e.icon_img.Visible = false end end)
	pcall(function() if e.icon_shadow then e.icon_shadow.Visible = false end end)
	if e.chams and e.chams.Parent then
		pcall(function() e.chams.Enabled = false end)
	end
end

function WESP.wespDestroy(model)
	local e = WorldESP.entries[model]
	if not e then return end
	WESP.wespHide(e)
	for i = 1, 4 do
		pcall(function() if e.box_lines[i] then e.box_lines[i]:Remove() end end)
		pcall(function() if e.box_ol[i] then e.box_ol[i]:Remove() end end)
	end
	pcall(function() if e.name then e.name:Remove() end end)
	pcall(function() if e.icon_img then e.icon_img:Destroy() end end)
	pcall(function() if e.icon_shadow then e.icon_shadow:Destroy() end end)
	pcall(function() if e.chams then e.chams:Destroy() end end)
	WorldESP.entries[model] = nil
end

function WESP.wespSetLine(ln, a, b, col, thick, z)
	if not ln then return end
	ln.From = a
	ln.To = b
	ln.Color = col
	ln.Thickness = thick or 1
	pcall(function() if z then ln.ZIndex = z end end)
	ln.Visible = true
end

-- Same full-box style as player ESP (black outline behind, clean edges)
function WESP.wespDrawBox(e, x, y, w, h, col, thick, outline)
	thick = math.max(thick or 1, 1)
	local olcol = Color3.new(0, 0, 0)
	local tl = Vector2.new(x, y)
	local tr = Vector2.new(x + w, y)
	local bl = Vector2.new(x, y + h)
	local br = Vector2.new(x + w, y + h)
	local edges = {
		{ tl, tr },
		{ tr, br },
		{ br, bl },
		{ bl, tl },
	}
	for i = 1, 4 do
		local a, b = edges[i][1], edges[i][2]
		if outline and e.box_ol[i] then
			WESP.wespSetLine(e.box_ol[i], a, b, olcol, thick + 1, 1)
		elseif e.box_ol[i] then
			e.box_ol[i].Visible = false
		end
		WESP.wespSetLine(e.box_lines[i], a, b, col, thick, 2)
	end
end

function WESP.wespGetPart(model)
	if not model then return nil end
	if model:IsA("BasePart") then return model end
	if model.PrimaryPart then return model.PrimaryPart end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

function WESP.wespBombLabel(model)
	local weapon = model:GetAttribute("Weapon")
	local label = "C4 | PLANTED"
	local urgent = false
	local explodeAt = model:GetAttribute("ExplodeTime") or model:GetAttribute("ExplosionTime")
		or model:GetAttribute("DetonateAt")
	local defused = model:GetAttribute("Defused") == true
	if defused then
		return "C4 | DEFUSED", false
	end
	if type(explodeAt) == "number" then
		local rem = explodeAt - workspace:GetServerTimeNow()
		if rem <= 0 then
			return "C4 | EXPLODING", true
		end
		label = string.format("C4 | %.1fs", rem)
		urgent = rem <= 10
	elseif type(weapon) == "string" and weapon ~= "" and weapon ~= "C4" then
		label = tostring(weapon) .. " | PLANTED"
	end
	return label, urgent
end

function WESP.wespGunLabel(model)
	local weapon = model:GetAttribute("Weapon") or model:GetAttribute("Name") or model.Name
	if type(weapon) ~= "string" or weapon == "" then weapon = "Weapon" end
	return tostring(weapon)
end

function WESP.wespApplyChams(e, model, col, trans)
	if not e then return end
	if not e.chams or not e.chams.Parent then
		local h = Instance.new("Highlight")
		h.Name = "VantaWorldESP"
		h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		h.FillTransparency = trans or 0.45
		h.OutlineTransparency = 0.2
		h.Parent = model
		e.chams = h
	end
	e.chams.FillColor = col
	e.chams.OutlineColor = col
	e.chams.FillTransparency = trans or 0.45
	e.chams.Enabled = true
end

-- opts: nameOn, chamsOn, chamsCol, chamsTrans, iconOn, iconCol, shadowCol, iconName
function WESP.wespDraw(model, kind, label, nameCol, opts)
	opts = opts or {}
	local part = WESP.wespGetPart(model)
	if not part then
		WESP.wespHide(WorldESP.entries[model])
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then return end
	local sp, onScreen = cam:WorldToViewportPoint(part.Position)
	if not onScreen or sp.Z <= 0 then
		WESP.wespHide(WorldESP.entries[model])
		return
	end

	local e = WESP.wespEnsure(model, kind)
	for i = 1, 4 do
		if e.box_lines[i] then e.box_lines[i].Visible = false end
		if e.box_ol[i] then e.box_ol[i].Visible = false end
	end

	local cx, cy = sp.X, sp.Y
	local nameOn = opts.nameOn
	local iconOn = opts.iconOn
	local ICON_SZ = 26

	if iconOn then
		local resolveName = opts.iconName or label
		if e._icon_cached_name ~= resolveName then
			e._icon_cached_name = resolveName
			e._icon_cached_id = nil
			local ri = getgenv().MethaneResolveItemIcon
			if type(ri) == "function" then
				pcall(function() e._icon_cached_id = ri(resolveName) end)
			end
			if not e._icon_cached_id then
				local map = getgenv().MethaneItemIcons
				if type(map) == "table" then
					e._icon_cached_id = map[resolveName] or map["Weapon_" .. tostring(resolveName)]
				end
			end
		end
		local iconId = e._icon_cached_id
		if iconId and iconId ~= "" then
			local sg = WESP.ensureWespIconGui()
			if sg then
				if not e.icon_shadow or not e.icon_shadow.Parent then
					local sh = Instance.new("ImageLabel")
					sh.Name = "WespIconShadow"
					sh.BackgroundTransparency = 1
					sh.AnchorPoint = Vector2.new(0.5, 0.5)
					sh.ZIndex = 1
					sh.ScaleType = Enum.ScaleType.Fit
					pcall(function() sh.ResampleMode = Enum.ResamplerMode.Pixelated end)
					sh.Parent = sg
					e.icon_shadow = sh
				end
				if not e.icon_img or not e.icon_img.Parent then
					local im = Instance.new("ImageLabel")
					im.Name = "WespIcon"
					im.BackgroundTransparency = 1
					im.AnchorPoint = Vector2.new(0.5, 0.5)
					im.ZIndex = 2
					im.ScaleType = Enum.ScaleType.Fit
					pcall(function() im.ResampleMode = Enum.ResamplerMode.Pixelated end)
					im.Parent = sg
					e.icon_img = im
				end
				local iconCol = opts.iconCol or Color3.new(1, 1, 1)
				local shadowCol = opts.shadowCol or Color3.new(0, 0, 0)
				local ix, iy = cx, cy
				if nameOn then iy = cy + 6 end
				local sh, im = e.icon_shadow, e.icon_img
				sh.Size = UDim2.fromOffset(ICON_SZ + 3, ICON_SZ + 3)
				im.Size = UDim2.fromOffset(ICON_SZ, ICON_SZ)
				sh.Image = iconId
				im.Image = iconId
				sh.ImageColor3 = shadowCol
				im.ImageColor3 = iconCol
				sh.Position = UDim2.fromOffset(ix + 1, iy + 1)
				im.Position = UDim2.fromOffset(ix, iy)
				sh.ImageTransparency = 0.72
				im.ImageTransparency = 0
				sh.Visible = true
				im.Visible = true
			end
		else
			pcall(function() if e.icon_img then e.icon_img.Visible = false end end)
			pcall(function() if e.icon_shadow then e.icon_shadow.Visible = false end end)
		end
	else
		pcall(function() if e.icon_img then e.icon_img.Visible = false end end)
		pcall(function() if e.icon_shadow then e.icon_shadow.Visible = false end end)
	end

	if nameOn and e.name then
		e.name.Visible = true
		e.name.Text = string.upper(tostring(label or ""))
		e.name.Color = nameCol or Color3.new(1, 1, 1)
		local nameY = cy - (iconOn and (ICON_SZ * 0.5 + 10) or 14)
		e.name.Position = Vector2.new(cx, nameY)
	elseif e.name then
		e.name.Visible = false
	end

	if opts.chamsOn then
		WESP.wespApplyChams(e, model, opts.chamsCol or Color3.new(1, 1, 1), opts.chamsTrans)
	elseif e.chams then
		pcall(function() e.chams.Enabled = false end)
	end
end

-- Cached tag sets — NO Workspace:GetDescendants (that was the empty-world FPS killer)
local wespGuns = {}  -- [model] = true
local wespBombs = {} -- [model] = true

function WESP.wespTrack(tag, map, model)
	if model then map[model] = true end
end
function WESP.wespUntrack(map, model)
	if model then map[model] = nil end
end

pcall(function()
	for _, m in ipairs(CollectionService:GetTagged("WeaponDropped")) do
		wespGuns[m] = true
	end
	for _, m in ipairs(CollectionService:GetTagged("Bomb")) do
		wespBombs[m] = true
	end
	CollectionService:GetInstanceAddedSignal("WeaponDropped"):Connect(function(m)
		wespGuns[m] = true
	end)
	CollectionService:GetInstanceRemovedSignal("WeaponDropped"):Connect(function(m)
		wespGuns[m] = nil
		WESP.wespDestroy(m)
	end)
	CollectionService:GetInstanceAddedSignal("Bomb"):Connect(function(m)
		wespBombs[m] = true
	end)
	CollectionService:GetInstanceRemovedSignal("Bomb"):Connect(function(m)
		wespBombs[m] = nil
		WESP.wespDestroy(m)
	end)
end)

local wespFrame = 0
RunService.RenderStepped:Connect(function()
	local gunOn = tv("WESP_GunEnabled")
	local bombOn = tv("WESP_BombEnabled")
	if not gunOn and not bombOn then
		if next(WorldESP.entries) then
			for _, e in pairs(WorldESP.entries) do
				WESP.wespHide(e)
			end
		end
		return
	end

	-- nothing tagged → zero work (was GetDescendants every frame before)
	if (not gunOn or not next(wespGuns)) and (not bombOn or not next(wespBombs)) then
		if next(WorldESP.entries) then
			for model, e in pairs(WorldESP.entries) do
				WESP.wespDestroy(model)
			end
		end
		return
	end

	wespFrame = wespFrame + 1
	-- draw every frame is fine for few items; skip color option lookups cost is tiny

	local seen = {}
	local white = Color3.fromRGB(255, 255, 255)

	if gunOn then
		local nameCol = ov("WESP_GunNameCol", white)
		if typeof(nameCol) ~= "Color3" then nameCol = white end
		local iconCol = ov("WESP_GunIconCol", white)
		if typeof(iconCol) ~= "Color3" then iconCol = white end
		local shadowCol = ov("WESP_GunShadowCol", Color3.new(0, 0, 0))
		if typeof(shadowCol) ~= "Color3" then shadowCol = Color3.new(0, 0, 0) end
		local cc = ov("WESP_GunChamsCol", white)
		if typeof(cc) ~= "Color3" then cc = white end
		local iconOn = tv("WESP_GunIcon") ~= false
		local nameOn = tv("WESP_GunName")
		local chamsOn = tv("WESP_GunChams")
		local chamsT = ov("WESP_GunChamsTrans", 0.45)
		for model in pairs(wespGuns) do
			if not model.Parent then
				wespGuns[model] = nil
				WESP.wespDestroy(model)
				continue
			end
			seen[model] = true
			local gunName = WESP.wespGunLabel(model)
			WESP.wespDraw(model, "gun", gunName, nameCol, {
				nameOn = nameOn,
				chamsOn = chamsOn,
				chamsCol = cc,
				chamsTrans = chamsT,
				iconOn = iconOn,
				iconCol = iconCol,
				shadowCol = shadowCol,
				iconName = gunName,
			})
		end
	end

	if bombOn then
		local nameCol = ov("WESP_BombNameCol", white)
		if typeof(nameCol) ~= "Color3" then nameCol = white end
		local cc = ov("WESP_BombChamsCol", white)
		if typeof(cc) ~= "Color3" then cc = white end
		local iconOn = tv("WESP_BombIcon") ~= false
		local nameOn = tv("WESP_BombName")
		local chamsOn = tv("WESP_BombChams")
		local chamsT = ov("WESP_BombChamsTrans", 0.4)
		local urgentRed = Color3.fromRGB(255, 40, 40)
		local urgentCol = ov("WESP_BombUrgentCol", urgentRed)
		if typeof(urgentCol) ~= "Color3" then urgentCol = urgentRed end
		for model in pairs(wespBombs) do
			if not model.Parent then
				wespBombs[model] = nil
				WESP.wespDestroy(model)
				continue
			end
			seen[model] = true
			local label, urgent = WESP.wespBombLabel(model)
			local bombIconCol = urgent and urgentCol or white
			WESP.wespDraw(model, "bomb", label, urgent and urgentCol or nameCol, {
				nameOn = nameOn,
				chamsOn = chamsOn,
				chamsCol = cc,
				chamsTrans = chamsT,
				iconOn = iconOn,
				iconCol = bombIconCol,
				shadowCol = Color3.fromRGB(220, 30, 30),
				iconName = "Bomb",
			})
		end
	end

	for model in pairs(WorldESP.entries) do
		if not seen[model] then
			WESP.wespDestroy(model)
		end
	end
end)

end)

----------------------------------------------------------------
-- GRENADES 1:1 Bac0n prediction / trails / markers + box
----------------------------------------------------------------
task.spawn(function()
	local Settings = {
		GrenadeEnabled = false,
		GrenadePreview = true,
		GrenadePreviewMode = "Auto",
		GrenadePrediction = true,
		GrenadeTrails = false,
		GrenadeBounces = false,
		GrenadeEndpoint = false,
		GrenadeNames = true,
		GrenadeIcons = true,
		GrenadeBox = false,
		GrenadeHE = true,
		GrenadeFlash = true,
		GrenadeSmoke = true,
		GrenadeMolotov = true,
		GrenadeIncendiary = true,
		GrenadeDecoy = true,
		GrenadeTimers = true,
		GrenadeMaxDistance = 1500,
		GrenadeHorizon = 5,
		GrenadeRefresh = 6,
		GrenadePreviewRefresh = 60,
		GrenadeTrailTime = 4,
		GrenadeThickness = 1.5,
		GrenadeOpacity = 100,
		GrenadeOutline = false,
		GrenadeMarkerSize = 4,
		GrenadePreviewColor = Color3.fromRGB(120, 200, 255),
		GrenadePredColor1 = Color3.fromRGB(120, 200, 255),
		GrenadePredColor2 = Color3.fromRGB(120, 200, 255),
		GrenadeHEColor = Color3.fromRGB(255, 90, 90),
		GrenadeFlashColor = Color3.fromRGB(245, 245, 120),
		GrenadeSmokeColor = Color3.fromRGB(150, 150, 160),
		GrenadeFireColor = Color3.fromRGB(255, 140, 40),
		GrenadeMolotovColor = Color3.fromRGB(255, 140, 40),
		GrenadeIncendiaryColor = Color3.fromRGB(255, 100, 40),
		GrenadeDecoyColor = Color3.fromRGB(207, 200, 100),
		OutlineColor = Color3.new(0, 0, 0),
		WorldTextSize = 13,
		TextSize = 13,
		TextFont = "UI",
		Outlines = true,
		HideWithMenu = false,
	}

	local function syncSettings()
		Settings.GrenadeEnabled = tv("GrenadeEnabled") == true
		Settings.GrenadePrediction = tv("GrenadePrediction") ~= false
		Settings.GrenadeTrails = tv("GrenadeTrails") ~= false
		Settings.GrenadeBounces = tv("GrenadeBounces") ~= false
		Settings.GrenadeEndpoint = tv("GrenadeEndpoint") ~= false
		Settings.GrenadeNames = tv("GrenadeNames") ~= false
		Settings.GrenadeIcons = tv("GrenadeIcons") ~= false
		Settings.GrenadeBox = tv("GrenadeBox") ~= false
		Settings.GrenadeOutline = tv("GrenadeOutline") == true
		Settings.GrenadeHE = tv("GrenadeHE") ~= false
		Settings.GrenadeFlash = tv("GrenadeFlash") ~= false
		Settings.GrenadeSmoke = tv("GrenadeSmoke") ~= false
		Settings.GrenadeMolotov = tv("GrenadeMolotov") ~= false
		Settings.GrenadeIncendiary = tv("GrenadeIncendiary") ~= false
		Settings.GrenadeDecoy = tv("GrenadeDecoy") ~= false
	Settings.GrenadeTimers = tv("GrenadeTimers") ~= false
		Settings.GrenadeHorizon = tonumber(ov("GrenadeHorizon", 5)) or 5
		Settings.GrenadeMaxDistance = tonumber(ov("GrenadeMaxDistance", 1500)) or 1500
		Settings.GrenadeThickness = tonumber(ov("GrenadeThickness", 1.5)) or 1.5
		Settings.GrenadeOpacity = tonumber(ov("GrenadeOpacity", 90)) or 90
		Settings.GrenadeTrailTime = tonumber(ov("GrenadeTrailTime", 4)) or 4
		Settings.GrenadeRefresh = tonumber(ov("GrenadeRefresh", 6)) or 6
		Settings.GrenadeHEColor = ov("GrenadeHEColor", Settings.GrenadeHEColor) or Settings.GrenadeHEColor
		Settings.GrenadeFlashColor = ov("GrenadeFlashColor", Settings.GrenadeFlashColor) or Settings.GrenadeFlashColor
		Settings.GrenadeSmokeColor = ov("GrenadeSmokeColor", Settings.GrenadeSmokeColor) or Settings.GrenadeSmokeColor
		Settings.GrenadeMolotovColor = ov("GrenadeMolotovColor", Settings.GrenadeMolotovColor or Settings.GrenadeFireColor) or Settings.GrenadeFireColor
		Settings.GrenadeIncendiaryColor = ov("GrenadeIncendiaryColor", Settings.GrenadeIncendiaryColor or Settings.GrenadeFireColor) or Settings.GrenadeFireColor
		Settings.GrenadeFireColor = Settings.GrenadeMolotovColor -- legacy alias
		Settings.GrenadeDecoyColor = ov("GrenadeDecoyColor", Settings.GrenadeDecoyColor) or Settings.GrenadeDecoyColor
		Settings.GrenadePredColor1 = ov("GrenadePredColor1", Settings.GrenadePredColor1) or Settings.GrenadePredColor1
		Settings.GrenadePredColor2 = Settings.GrenadePredColor1
		Settings.GrenadePreviewColor = Settings.GrenadePredColor1
		Settings.GrenadePreview = Settings.GrenadePrediction
	end

	local Grenades = {
		Ready = false,
		Entries = {},
		Previews = {},
		Jobs = {},
		Profiles = {},
		NextPreviewUpdate = 0,
	}

	local fuseTimes = { ["HE Grenade"] = 1.6, Flashbang = 1.5, Molotov = 2.4, ["Incendiary Grenade"] = 2.4 }
	local kinds = {
		["HE Grenade"] = { "GrenadeHE", "GrenadeHEColor" },
		Flashbang = { "GrenadeFlash", "GrenadeFlashColor" },
		["Smoke Grenade"] = { "GrenadeSmoke", "GrenadeSmokeColor" },
		Molotov = { "GrenadeMolotov", "GrenadeMolotovColor" },
		["Incendiary Grenade"] = { "GrenadeIncendiary", "GrenadeIncendiaryColor" },
		["Decoy Grenade"] = { "GrenadeDecoy", "GrenadeDecoyColor" },
	}

	
	-- Item icons (grenades / weapons) — filled by dumper or live scan
	-- How long each "active effect" grenade burns after landing (seconds)
	-- Smoke: 18s  |  Molotov / Incendiary: 7s
	local BURN_DURATION = {
		["Smoke Grenade"]      = 18,
		["Molotov"]            = 7,
		["Incendiary Grenade"] = 7,
	}

	-- Shared ScreenGui for all grenade timer bars + post-land icons
	local _nadeTimerGui = nil
	local function ensureNadeTimerGui()
		if _nadeTimerGui and _nadeTimerGui.Parent then return _nadeTimerGui end
		local pg = LP:FindFirstChildOfClass("PlayerGui")
		if not pg then return nil end
		local sg = Instance.new("ScreenGui")
		sg.Name = "MethaneGrenadeTimers"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.DisplayOrder = 51
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = pg
		_nadeTimerGui = sg
		return sg
	end

	local function hideNadeTimer(entry)
		pcall(function()
			if entry.TimerIcon then entry.TimerIcon.Visible = false end
			if entry.TimerBg then entry.TimerBg.Visible = false end
			if entry.TimerFill then entry.TimerFill.Visible = false end
			if entry.TimerBorder then entry.TimerBorder.Visible = false end
			if entry.TimerShadow1 then entry.TimerShadow1.Visible = false end
			if entry.TimerShadow2 then entry.TimerShadow2.Visible = false end
			if entry.TimerShadow3 then entry.TimerShadow3.Visible = false end
		end)
	end

	getgenv().MethaneItemIcons = getgenv().MethaneItemIcons or {}
	local function resolveItemIcon(itemName)
		if not itemName or itemName == "" then return nil end
		local map = getgenv().MethaneItemIcons
		if type(map) ~= "table" then
			map = {}
			getgenv().MethaneItemIcons = map
		end
		if type(map[itemName]) == "string" and map[itemName] ~= "" then
			return map[itemName]
		end
		-- Official game icons (Database.Custom.Weapons.Icon)
		local OFFICIAL = {
			["HE Grenade"] = "rbxassetid://111110976385167",
			["Flashbang"] = "rbxassetid://132038996524430",
			["Smoke Grenade"] = "rbxassetid://137305344844339",
			["Molotov"] = "rbxassetid://95390644612614",
			["Incendiary Grenade"] = "rbxassetid://81255981095065",
			["Decoy Grenade"] = "rbxassetid://81385239843859",
			["C4"] = "rbxassetid://109858795365969",
			["Bomb"] = "rbxassetid://109858795365969",
			["AK-47"] = "rbxassetid://83097083839889",
			["M4A4"] = "rbxassetid://93053662997899",
			["M4A1-S"] = "rbxassetid://113144230602399",
			["AWP"] = "rbxassetid://79794264811775",
			["Desert Eagle"] = "rbxassetid://122477921917392",
			["Glock-18"] = "rbxassetid://101406018897044",
			["USP-S"] = "rbxassetid://131658947857971",
			["P250"] = "rbxassetid://73666032770570",
			["Five-SeveN"] = "rbxassetid://90570942481875",
			["Tec-9"] = "rbxassetid://119232881698906",
			["Dual Berettas"] = "rbxassetid://111854065134079",
			["R8 Revolver"] = "rbxassetid://112745953600473",
			["P90"] = "rbxassetid://82724138944322",
			["MAC-10"] = "rbxassetid://83671879972945",
			["MP9"] = "rbxassetid://135384625641866",
			["FAMAS"] = "rbxassetid://125469152582044",
			["Galil AR"] = "rbxassetid://75166557697975",
			["AUG"] = "rbxassetid://119885531832389",
			["SG 553"] = "rbxassetid://133547075528778",
			["SSG 08"] = "rbxassetid://112132914334737",
			["Nova"] = "rbxassetid://127273982496076",
			["XM1014"] = "rbxassetid://115344320193773",
			["MAG-7"] = "rbxassetid://86291171438206",
			["Sawed-Off"] = "rbxassetid://117478678996500",
			["Negev"] = "rbxassetid://134163874921903",
			["Zeus x27"] = "rbxassetid://71464446190434",
			["Karambit"] = "rbxassetid://85121618781867",
			["Butterfly Knife"] = "rbxassetid://78088217065173",
			["CT Knife"] = "rbxassetid://115204080823353",
			["T Knife"] = "rbxassetid://140484419446969",
			["M9 Bayonet"] = "rbxassetid://92481124554479",
			["Flip Knife"] = "rbxassetid://103569239379116",
			["Gut Knife"] = "rbxassetid://91965772008164",
			["Stiletto Knife"] = "rbxassetid://71208637985987",
			["Skeleton Knife"] = "rbxassetid://73573766861663",
		}
		if OFFICIAL[itemName] then
			map[itemName] = OFFICIAL[itemName]
			return OFFICIAL[itemName]
		end
		local low = string.lower(itemName)
		for k, v in pairs(OFFICIAL) do
			if string.lower(k) == low then
				map[itemName] = v
				return v
			end
		end
		-- Live: Database.Custom.Weapons[name].Icon
		local found = nil
		pcall(function()
			local folder = game:GetService("ReplicatedStorage").Database.Custom.Weapons
			local mod = folder:FindFirstChild(itemName)
			if not mod then
				for _, ch in ipairs(folder:GetChildren()) do
					if string.lower(ch.Name) == low then mod = ch break end
				end
			end
			if not mod then return end
			local data = require(mod)
			if type(data) == "table" and type(data.Icon) == "string" and data.Icon ~= "" then
				found = data.Icon
			end
		end)
		if found then
			map[itemName] = found
			return found
		end
		return nil
	end

	getgenv().MethaneResolveItemIcon = resolveItemIcon

	-- Screen-space icon layer (Drawing.Image or PlayerGui ScreenGui — not Billboard)
	local _nadeIconGui = nil
	local function ensureNadeIconScreen()
		if _nadeIconGui and _nadeIconGui.Parent then return _nadeIconGui end
		local pg = LP:FindFirstChildOfClass("PlayerGui")
		if not pg then return nil end
		local sg = Instance.new("ScreenGui")
		sg.Name = "MethaneGrenadeIcons"
		sg.ResetOnSpawn = false
		sg.IgnoreGuiInset = true
		sg.DisplayOrder = 50
		sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		sg.Parent = pg
		_nadeIconGui = sg
		return sg
	end

	local function hideNadeIcon(entry)
		pcall(function()
			if entry.DrawIcon   then entry.DrawIcon.Visible   = false end
			if entry.DrawShadow then entry.DrawShadow.Visible = false end
			if entry.GuiIcon    then entry.GuiIcon.Visible    = false end
			-- legacy single shadow (may not exist on new entries)
			if entry.GuiShadow  then entry.GuiShadow.Visible  = false end
			-- new multi-layer blur shadows
			if entry.GuiShadow1 then entry.GuiShadow1.Visible = false end
			if entry.GuiShadow2 then entry.GuiShadow2.Visible = false end
			if entry.GuiShadow3 then entry.GuiShadow3.Visible = false end
		end)
	end

	local function drawNadeIcon(entry, worldPos, color, alpha, camera)
		if typeof(worldPos) ~= "Vector3" or not camera then
			hideNadeIcon(entry)
			return false
		end
		local sp, onScreen = camera:WorldToViewportPoint(worldPos)
		if not onScreen or sp.Z < 0.5 then
			hideNadeIcon(entry)
			return false
		end
		local iconId = entry._iconId
		if not iconId then
			iconId = resolveItemIcon(entry.Name)
			entry._iconId = iconId
		end
		if not iconId or iconId == "" then
			hideNadeIcon(entry)
			return false
		end
		local size = 22   -- match timer icons
		local x = sp.X
		local y = sp.Y - 18
		local col = color or Color3.fromRGB(255, 180, 60)
		local vis = math.clamp(tonumber(alpha) or 1, 0.45, 1)

		-- ScreenGui in PlayerGui (reliable on all executors; Drawing.Image often missing)
		local sg = ensureNadeIconScreen()
		if not sg then return false end

		-- Single tight faded dropshadow (tracer color) + crisp icon
		if not entry.GuiShadow1 or not entry.GuiShadow1.Parent then
			local sh = Instance.new("ImageLabel")
			sh.Name = "NadeIconShadow1"; sh.BackgroundTransparency = 1
			sh.AnchorPoint = Vector2.new(0.5, 0.5)
			sh.ZIndex = 1
			sh.Parent = sg; entry.GuiShadow1 = sh
		end
		-- hide legacy extra rings
		pcall(function()
			if entry.GuiShadow2 then entry.GuiShadow2.Visible = false end
			if entry.GuiShadow3 then entry.GuiShadow3.Visible = false end
		end)
		if not entry.GuiIcon or not entry.GuiIcon.Parent then
			local im = Instance.new("ImageLabel")
			im.Name = "NadeIcon"; im.BackgroundTransparency = 1
			im.AnchorPoint = Vector2.new(0.5, 0.5)
			im.ZIndex = 2
			pcall(function() im.ResampleMode = Enum.ResamplerMode.Default end)
			im.Parent = sg; entry.GuiIcon = im
		end
		local sh1, im = entry.GuiShadow1, entry.GuiIcon
		local pos = UDim2.fromOffset(x, y)
		-- shadow slightly larger + offset so it reads as a soft edge fade, not a second icon
		sh1.Size = UDim2.fromOffset(size + 3, size + 3)
		im.Size = UDim2.fromOffset(size, size)
		sh1.Image = iconId; im.Image = iconId
		sh1.ImageColor3 = col
		im.ImageColor3 = Color3.new(1, 1, 1)
		sh1.Position = UDim2.fromOffset(x + 1, y + 1)
		im.Position = pos
		sh1.ImageTransparency = 1 - (vis * 0.28)
		im.ImageTransparency = 1 - vis
		sh1.Visible = true; im.Visible = true
		return true
	end

	local function record(name)
		return { Name = name, Objects = {}, Strokes = {}, Markers = {}, History = {}, NextPrediction = 0 }
	end

	local function newDrawing(entry, kind, properties)
		local object = Drawing.new(kind)
		table.insert(entry.Objects, object)
		object.Visible = false
		object.Transparency = 1
		if properties then
			for key, value in pairs(properties) do
				object[key] = value
			end
		end
		return object
	end

	local function line(object, from, to, color, thickness, opacity)
		-- Drawing: Transparency 0 = solid, 1 = invisible
		local vis = math.clamp(tonumber(opacity) or 1, 0, 1)
		object.From, object.To = from, to
		object.Color = color
		object.Thickness = thickness
		object.Transparency = 1 - vis
		object.Visible = true
	end

	local function text(object, value, x, y, color, opacity, viewport, size, outlined)
		object.Text = value
		object.Size = size or 13
		object.Center = true
		object.Outline = outlined ~= false
		object.OutlineColor = Settings.OutlineColor or Color3.new(0, 0, 0)
		object.Color = color
		local vis = math.clamp(tonumber(opacity) or 1, 0, 1)
		object.Transparency = 1 - vis
		pcall(function() object.Font = 2 end)
		object.Position = Vector2.new(x, y)
		object.Visible = true
	end

	local function hide(entry)
		if entry.Shown then
			for _, object in ipairs(entry.Objects) do
				object.Visible = false
			end
			entry.Shown = false
		end
		-- hide neon part segments (bullet-tracer style)
		if entry.NeonSegs then
			for _, p in ipairs(entry.NeonSegs) do
				pcall(function() p.Transparency = 1 end)
				pcall(function()
					local l = p:FindFirstChild("Glow")
					if l then l.Brightness = 0 end
				end)
			end
		end
		if entry.NeonDots then
			for _, p in ipairs(entry.NeonDots) do
				pcall(function() p.Transparency = 1 end)
				pcall(function()
					local l = p:FindFirstChild("Glow")
					if l then l.Brightness = 0 end
				end)
			end
		end
		hideNadeIcon(entry)
	end

	-- Same neon material as bullet tracers (Part + Neon + PointLight)
	local _nadeFolder = nil
	local function ensureNadeFolder()
		local cam = workspace.CurrentCamera
		if _nadeFolder and _nadeFolder.Parent then return _nadeFolder end
		_nadeFolder = Instance.new("Folder")
		_nadeFolder.Name = "MethaneGrenadeTracers"
		_nadeFolder.Parent = cam or workspace
		return _nadeFolder
	end
	local function makeNadeSeg(col, thick)
		local p = Instance.new("Part")
		p.Name = "GNadeSeg"
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = col
		p.Transparency = 0.18
		p.Size = Vector3.new(thick, thick, 0.05)
		p.Parent = ensureNadeFolder()
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Color = col
		light.Brightness = 1.2
		light.Range = 8
		light.Shadows = false
		light.Parent = p
		return p
	end
	local function setNadeSeg(p, a, b, thick, alpha)
		if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then
			p.Transparency = 1
			return
		end
		local dist = (b - a).Magnitude
		if dist < 0.04 then
			p.Transparency = 1
			return
		end
		local mid = (a + b) * 0.5
		p.Size = Vector3.new(thick, thick, dist)
		p.CFrame = CFrame.lookAt(mid, b)
		p.Transparency = math.clamp(alpha, 0.08, 1)
		local light = p:FindFirstChild("Glow")
		if light then
			local vis = 1 - math.clamp(alpha, 0, 1)
			light.Brightness = 1.1 * vis * vis
			light.Range = (5 + thick * 35) * vis
			light.Color = p.Color
		end
	end
	local function makeNadeDot(col, size)
		local p = Instance.new("Part")
		p.Name = "GNadeDot"
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.Neon
		p.Color = col
		p.Transparency = 0.15
		p.Size = Vector3.new(size, size, size)
		p.Parent = ensureNadeFolder()
		local light = Instance.new("PointLight")
		light.Name = "Glow"
		light.Color = col
		light.Brightness = 1.4
		light.Range = 10
		light.Shadows = false
		light.Parent = p
		return p
	end

	local function Project(camera, a, b)
		if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return end
		-- Push points in front of the near plane so we never project "behind camera"
		-- (that is what draws lines from the top of the screen)
		local near = 1.25
		local function depth(p)
			return -camera.CFrame:PointToObjectSpace(p).Z
		end
		local za, zb = depth(a), depth(b)
		if za < near and zb < near then return end
		if za < near then
			local t = (near - za) / math.max(zb - za, 1e-4)
			a = a:Lerp(b, math.clamp(t, 0, 1))
			za = near
		end
		if zb < near then
			local t = (near - zb) / math.max(za - zb, 1e-4)
			b = b:Lerp(a, math.clamp(t, 0, 1))
			zb = near
		end
		local pa, oa = camera:WorldToViewportPoint(a)
		local pb, ob = camera:WorldToViewportPoint(b)
		if not oa or not ob then return end
		if pa.Z <= 0 or pb.Z <= 0 then return end
		local vs = camera.ViewportSize
		local function ok(p)
			return p.X > -80 and p.X < vs.X + 80 and p.Y > -80 and p.Y < vs.Y + 80
		end
		if not ok(pa) or not ok(pb) then return end
		return Vector2.new(pa.X, pa.Y), Vector2.new(pb.X, pb.Y)
	end

	local function matchCharacter(player)
		local character = player.Character
		local characters = workspace:FindFirstChild("Characters")
		if characters and character and character:IsDescendantOf(characters) then
			return character
		end
		return character
	end

	local function teamOf(player)
		local t
		pcall(function()
			t = player:GetAttribute("Team") or player:GetAttribute("TeamName")
		end)
		return t
	end

	local GetWeaponFn
	pcall(function()
		local inv = require(game:GetService("ReplicatedStorage").Controllers.InventoryController)
		GetWeaponFn = inv.peekCurrentEquippedForMovement
	end)

	local function getWeapon()
		if type(GetWeaponFn) == "function" then
			local ok, w = pcall(GetWeaponFn)
			if ok then return w end
		end
		return nil
	end

	function Grenades:Remove(entry)
		entry.Removed, entry.Job = true, nil
		for _, object in ipairs(entry.Objects) do
			pcall(function() object:Remove() end)
		end
		table.clear(entry.Objects)
		if entry.NeonSegs then
			for _, p in ipairs(entry.NeonSegs) do pcall(function() p:Destroy() end) end
			table.clear(entry.NeonSegs)
		end
		if entry.NeonDots then
			for _, p in ipairs(entry.NeonDots) do pcall(function() p:Destroy() end) end
			table.clear(entry.NeonDots)
		end
		entry._neonSegMap, entry._neonDotMap = nil, nil
		hideNadeIcon(entry)
		pcall(function() if entry.GuiIcon then entry.GuiIcon:Destroy() end end)
		pcall(function() if entry.GuiShadow then entry.GuiShadow:Destroy() end end)
		pcall(function() if entry.DrawIcon then entry.DrawIcon:Remove() end end)
		pcall(function() if entry.DrawShadow then entry.DrawShadow:Remove() end end)
		entry.GuiIcon, entry.GuiShadow, entry.DrawIcon, entry.DrawShadow, entry._iconId = nil, nil, nil, nil, nil
		pcall(function() if entry.IconPart then entry.IconPart:Destroy() end end)
		entry.IconPart, entry.IconGui = nil, nil
		-- timer layers
		pcall(function() if entry.TimerIcon then entry.TimerIcon:Destroy() end end)
		pcall(function() if entry.TimerBg then entry.TimerBg:Destroy() end end)
		pcall(function() if entry.TimerFill then entry.TimerFill:Destroy() end end)
		pcall(function() if entry.TimerBorder then entry.TimerBorder:Destroy() end end)
		pcall(function() if entry.TimerShadow1 then entry.TimerShadow1:Destroy() end end)
		pcall(function() if entry.TimerShadow2 then entry.TimerShadow2:Destroy() end end)
		pcall(function() if entry.TimerShadow3 then entry.TimerShadow3:Destroy() end end)
		entry.TimerIcon, entry.TimerBg, entry.TimerFill = nil, nil, nil
		entry.LandTime = nil
	end

	function Grenades:HideAll()
		for _, entry in pairs(self.Entries) do
			hide(entry)
			hideNadeTimer(entry)
		end
		for _, entry in pairs(self.Previews) do
			hide(entry)
			hideNadeTimer(entry)
		end
	end

	function Grenades:Refresh()
		self.NextPreviewUpdate = 0
		table.clear(self.Jobs)
		for _, entries in ipairs({ self.Entries, self.Previews }) do
			for _, entry in pairs(entries) do
				entry.Job, entry.Forecast, entry.NextPrediction = nil, nil, 0
				hide(entry)
			end
		end
		if not Settings.GrenadeEnabled then
			for model, entry in pairs(self.Entries) do
				self:Remove(entry)
				self.Entries[model] = nil
			end
		end
	end

	function Grenades:RestoreAll()
		self.Ready = false
		if self.Module and self.Module.simulate == self.Wrapper then
			self.Module.simulate = self.Original
		end
		for _, entries in ipairs({ self.Entries, self.Previews }) do
			for key, entry in pairs(entries) do
				self:Remove(entry)
				entries[key] = nil
			end
		end
		table.clear(self.Jobs)
	end

	function Grenades:AddHistory(entry, position, now, bounce)
		local last = entry.History[#entry.History]
		if last and not bounce and (now - last.Time < 0.075 or (last.Position - position).Magnitude < 0.03) then
			return
		end
		table.insert(entry.History, { Position = position, Time = now, Bounce = bounce })
		while #entry.History > 160 do
			table.remove(entry.History, 1)
		end
	end

	function Grenades:Capture(result, config, params)
		local model = params.FilterDescendantsInstances[1]
		if not model or not model:IsA("Model") or not model:HasTag("Grenade") then return end
		local name = model:GetAttribute("GrenadeName")
		if not kinds[name] then return end
		self.Profiles[name] = table.clone(config)
		-- Remember last real throw state so preview can mirror it next time
		pcall(function()
			if result and result.state then
				self.LastThrow = {
					name = name,
					position = result.state.position,
					velocity = result.state.velocity,
					config = table.clone(config),
				}
			end
		end)
		if not Settings.GrenadeEnabled then return end
		local entry = self.Entries[model]
		if not entry then
			entry = record(name)
			entry.Model = model
			self.Entries[model] = entry
		end
		local now = os.clock()
		entry.State, entry.Config, entry.Params = table.clone(result.state), table.clone(config), params
		entry.Position = result.state.position
		entry.Ended = nil
		for _, event in ipairs(result.events or {}) do
			if event.type == "bounce" then
				self:AddHistory(entry, event.position, now, true)
				entry.NextPrediction = 0
				entry.Job, entry.Forecast = nil, nil
			end
		end
		self:AddHistory(entry, entry.Position, now, false)
	end

	function Grenades:NewJob(entry, initial, config, params, now)
		local job = {
			Entry = entry,
			Current = table.clone(initial),
			Config = table.clone(config),
			Params = params,
			StartTime = initial.simulationTime,
			Horizon = Settings.GrenadeHorizon,
			Steps = 0,
			Created = now,
			Points = { { Position = initial.position, Time = initial.simulationTime } },
			Bounces = {},
			LastPointTime = initial.simulationTime,
		}
		if entry.Preview and entry.Position then
			job.Points[1].Position = entry.Position
		end
		entry.Job = job
		if not entry.Preview then
			entry.NextPrediction = now + 1 / Settings.GrenadeRefresh
			table.insert(self.Jobs, job)
		end
		return job
	end

	function Grenades:Advance(job)
		if job.Current.isAtRest then
			job.EndPosition, job.EndTime, job.Reason = job.Current.position, job.Current.simulationTime, "rest"
			job.Entry.Forecast, job.Entry.Job = job, nil
			return true
		end
		local state, event = self.Step(job.Current, job.Config, job.Params, self.StepTime)
		job.Current, job.Steps = state, job.Steps + 1
		if event and event.type == "bounce" then
			table.insert(job.Bounces, event.position)
		end
		local terminal = state.isAtRest
			or state.simulationTime - job.StartTime >= job.Horizon
			or job.Steps >= 1280
		if event or terminal or state.simulationTime - job.LastPointTime >= 0.0625 then
			table.insert(job.Points, { Position = state.position, Time = state.simulationTime })
			job.LastPointTime = state.simulationTime
		end
		if terminal then
			job.EndPosition, job.EndTime = state.position, state.simulationTime
			job.Reason = event and event.type or "limit"
			job.Entry.Forecast, job.Entry.Job = job, nil
		end
		return terminal
	end

	function Grenades:PreparePreview(camera, now)
		local weapon = getWeapon()
		local character = matchCharacter(LP)
		local active = Settings.GrenadePreview and character and weapon and not weapon.IsDestroyed
			and kinds[weapon.Name] and not weapon.ThrowFinished and Settings[kinds[weapon.Name][1]]
		local selected = Settings.GrenadePreviewMode
		if selected == "Auto" then
			selected = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and "Near" or "Far"
		end
		for _, mode in ipairs({ "Far", "Near" }) do
			local entry = self.Previews[mode]
			if not entry then
				entry = record("")
				entry.Preview = mode
				self.Previews[mode] = entry
			end
			entry.Active = active and (selected == mode or selected == "Both") or false
			if not entry.Active then
				hide(entry)
				entry.Job, entry.Forecast, entry.NextPrediction = nil, nil, 0
				continue
			end
			if entry.Weapon ~= weapon then
				entry.Weapon, entry.Name, entry.Job, entry.Forecast, entry.NextPrediction = weapon, weapon.Name, nil, nil, 0
			end
			-- always rebuild from current look (stale jobs = wrong path / top-of-screen junk)
			entry.Job = nil
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then
				continue
			end
			local config = self.Profiles[weapon.Name] and table.clone(self.Profiles[weapon.Name])
			if not config then
				local radius = 0.3
				pcall(function()
					local asset = self.Storage.Assets.Weapons:FindFirstChild(weapon.Name)
					local model = asset and asset:FindFirstChild("Character")
					if model then
						radius = model:GetExtentsSize().Magnitude * 0.5
					end
				end)
				local fire = weapon.Name == "Molotov" or weapon.Name == "Incendiary Grenade"
				config = self.Module.createConfig(radius, 1, mode == "Near", fuseTimes[weapon.Name], fire and 0.1 or nil, fire or nil)
			end
			local isNear = (mode == "Near")
			config.rangeScale = config.rangeScale or 1
			config.isNearThrow = isNear
			local camCF = camera.CFrame
			local look = camCF.LookVector
			-- Release point slightly in FRONT of camera so the first segment never starts behind the lens
			local base = camCF.Position + look * 0.35
			pcall(function()
				local head = character:FindFirstChild("Head")
				if head then
					base = head.Position + look * 0.5
				end
			end)
			local position, direction
			-- Prefer game module throw math (same as real throw)
			pcall(function()
				position, direction = self.Module.calculateThrowParameters(base, look, mode, config.rangeScale)
			end)
			if typeof(position) ~= "Vector3" then
				pcall(function()
					position, direction = self.Module.calculateThrowParameters(base, look, isNear, config.rangeScale)
				end)
			end
			if typeof(position) ~= "Vector3" then
				position = base + look * 0.75
			end
			if typeof(direction) ~= "Vector3" or direction.Magnitude < 0.05 then
				direction = look
			else
				direction = direction.Unit
			end
			-- Keep release in front of camera for drawing
			local camPos = camCF.Position
			if (position - camPos):Dot(look) < 0.4 then
				position = camPos + look * 1.0
			end
			local vel = Vector3.zero
			if self.GetVelocity then
				pcall(function()
					vel = self.GetVelocity(character) or Vector3.zero
				end)
			end
			local simTime = workspace:GetServerTimeNow()
			local initial
			pcall(function()
				initial = self.Module.createInitialState(position, direction, mode, vel, config.rangeScale, simTime)
			end)
			if type(initial) ~= "table" or typeof(initial.position) ~= "Vector3" then
				pcall(function()
					initial = self.Module.createInitialState(position, direction, isNear, vel, config.rangeScale, simTime)
				end)
			end
			if type(initial) ~= "table" or typeof(initial.position) ~= "Vector3" then
				initial = {
					position = position,
					velocity = direction * 30 + vel,
					simulationTime = simTime,
					isAtRest = false,
				}
			end
			-- Force draw origin to release point
			entry.Position = initial.position or position
			-- Match real throw speed from last hooked simulate() of this nade type
			pcall(function()
				local lt = self.LastThrow
				if lt and lt.name == weapon.Name and typeof(lt.velocity) == "Vector3" and lt.velocity.Magnitude > 1 then
					local spd = lt.velocity.Magnitude
					local dir = direction
					if typeof(initial.velocity) == "Vector3" and initial.velocity.Magnitude > 0.1 then
						dir = initial.velocity.Unit
					end
					-- keep horizontal aim, preserve hooked speed (fixes short/long arcs)
					initial.velocity = dir * spd
					if typeof(vel) == "Vector3" then
						initial.velocity = initial.velocity + vel * 0.35
					end
				end
			end)
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.IgnoreWater = true
			params.RespectCanCollide = true
			local ignore = { character, camera }
			local debris = workspace:FindFirstChild("Debris")
			if debris then table.insert(ignore, debris) end
			local viewmodels = workspace:FindFirstChild("Viewmodels") or workspace:FindFirstChild("ViewModels")
			if viewmodels then table.insert(ignore, viewmodels) end
			params.FilterDescendantsInstances = ignore
			pcall(function()
				params.CollisionGroup = teamOf(LP) == "Terrorists" and "TGrenade" or "CTGrenade"
			end)
			self:NewJob(entry, initial, config, params, now)
		end
	end

	function Grenades:UpdatePreview(camera, now)
		local nextUpdate, interval = self.NextPreviewUpdate or 0, 1 / math.max(Settings.GrenadePreviewRefresh, 20)
		if nextUpdate == 0 then
			nextUpdate = now
		end
		if now + 0.0001 < nextUpdate then
			return
		end
		self.NextPreviewUpdate = now + interval - math.max(0, now - nextUpdate) % interval
		self:PreparePreview(camera, now)
		-- finish preview sims fully so land point matches game physics
		for _, mode in ipairs({ "Far", "Near" }) do
			local entry = self.Previews[mode]
			if not (entry and entry.Active and entry.Job) then
				continue
			end
			local job = entry.Job
			local steps = 0
			local deadline = os.clock() + 0.012
			while entry.Job == job and steps < 2000 and os.clock() < deadline do
				if self:Advance(job) then
					break
				end
				steps = steps + 1
			end
			-- if still incomplete, keep last point as provisional end
			if entry.Job == job and job.Current and job.Current.position then
				job.EndPosition = job.Current.position
				if #job.Points > 0 then
					-- ensure first point is throw origin
					job.Points[1].Position = entry.Position or job.Points[1].Position
				end
				entry.Forecast = job
				entry.Job = nil
			end
		end
	end

	function Grenades:Update(now)
		local camera = workspace.CurrentCamera
		if not self.Ready or not camera then
			return
		end
		for model, entry in pairs(self.Entries) do
			if not model.Parent or model:GetAttribute("SimulationFinished") == true then
				if not entry.Ended then
					entry.Ended = now
					-- For burn-type grenades, stamp LandTime so the timer knows when the effect started
					if BURN_DURATION[entry.Name] and Settings.GrenadeTimers then
						entry.LandTime = entry.LandTime or now
					end
				end
				entry.Job, entry.Forecast = nil, nil
			end
			while entry.History[1] and now - entry.History[1].Time > Settings.GrenadeTrailTime do
				table.remove(entry.History, 1)
			end
			-- For burn grenades with an active timer, keep the entry alive for the full burn duration
			local burnDur = BURN_DURATION[entry.Name]
			local keepAlive = burnDur and entry.LandTime and Settings.GrenadeTimers
				and (now - entry.LandTime) < burnDur
			if entry.Ended and not keepAlive and now - entry.Ended > Settings.GrenadeTrailTime then
				self:Remove(entry)
				self.Entries[model] = nil
			end
		end
		if not Settings.GrenadeEnabled then
			self:HideAll()
			return
		end
		if Settings.GrenadePrediction then
			for _, entry in pairs(self.Entries) do
				if not entry.Ended and not entry.Job and now >= entry.NextPrediction and Settings[kinds[entry.Name][1]]
					and (entry.Position - camera.CFrame.Position).Magnitude <= Settings.GrenadeMaxDistance then
					self:NewJob(entry, entry.State, entry.Config, entry.Params, now)
				end
			end
		end
		local deadline, steps = os.clock() + 0.006, 0
		while #self.Jobs > 0 and steps < 800 and os.clock() < deadline do
			local job = self.Jobs[1]
			if now - job.Created > 0.5 and job.Entry.Job == job then
				job.Entry.Job = nil
			end
			if job.Entry.Removed or job.Entry.Job ~= job then
				table.remove(self.Jobs, 1)
				continue
			end
			local done = false
			for i = 1, 8 do
				done = self:Advance(job)
				steps = steps + 1
				if done then
					break
				end
			end
			table.remove(self.Jobs, 1)
			if not done then
				table.insert(self.Jobs, job)
			end
		end
	end

	function Grenades:Stroke(entry, key, index, camera, a, b, color, alpha)
		-- Pure 3D neon (same as bullet tracers). Never Drawing.Line — that glitches on-screen near camera.
		if typeof(a) ~= "Vector3" or typeof(b) ~= "Vector3" then return end
		local dist = (b - a).Magnitude
		if dist < 0.05 or dist > 250 then return end

		if camera then
			local camPos = camera.CFrame.Position
			local za = -camera.CFrame:PointToObjectSpace(a).Z
			local zb = -camera.CFrame:PointToObjectSpace(b).Z
			-- both behind near plane → skip
			if za < 1.2 and zb < 1.2 then return end
			-- clip endpoints that are behind near plane into the segment
			if za < 1.2 then
				local t = (1.2 - za) / math.max(zb - za, 1e-4)
				a = a:Lerp(b, math.clamp(t, 0, 1))
				za = 1.2
			end
			if zb < 1.2 then
				local t = (1.2 - zb) / math.max(za - zb, 1e-4)
				b = b:Lerp(a, math.clamp(t, 0, 1))
				zb = 1.2
			end
			dist = (b - a).Magnitude
			if dist < 0.05 then return end
			-- skip if the segment passes too close to the camera (causes giant smear across FOV)
			local ab = b - a
			local tClose = math.clamp((camPos - a):Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
			local closest = a + ab * tClose
			if (closest - camPos).Magnitude < 1.75 then return end
			-- also skip if either endpoint is extremely close
			if (a - camPos).Magnitude < 1.5 or (b - camPos).Magnitude < 1.5 then return end
		end

		pcall(function()
			local cam = workspace.CurrentCamera
			if cam and _nadeFolder and _nadeFolder.Parent ~= cam then
				_nadeFolder.Parent = cam
			end
		end)

		entry.NeonSegs = entry.NeonSegs or {}
		entry._neonSegMap = entry._neonSegMap or {}
		entry._neonUsed = entry._neonUsed or {}
		local mapKey = tostring(key) .. ":" .. tostring(index)
		entry._neonUsed[mapKey] = true
		local uiT = math.clamp(tonumber(Settings.GrenadeThickness) or 1.5, 0.5, 4)
		local thick = 0.04 + (uiT / 4) * 0.12
		local p = entry._neonSegMap[mapKey]
		if not p or not p.Parent then
			p = makeNadeSeg(color, thick)
			entry._neonSegMap[mapKey] = p
			table.insert(entry.NeonSegs, p)
		end
		p.Color = color
		local light = p:FindFirstChild("Glow")
		if light then light.Color = color end
		local vis = math.clamp(tonumber(alpha) or 1, 0.15, 1)
		local partAlpha = math.clamp(0.12 + (1 - vis) * 0.78, 0.08, 1)
		setNadeSeg(p, a, b, thick, partAlpha)
	end

	function Grenades:Marker(entry, index, camera, position, color, alpha, now)
		if typeof(position) ~= "Vector3" then return end
		-- skip if behind camera
		local d = -camera.CFrame:PointToObjectSpace(position).Z
		if d < 0.5 then return end
		entry.NeonDots = entry.NeonDots or {}
		entry._neonDotMap = entry._neonDotMap or {}
		local key = tostring(index)
		local p = entry._neonDotMap[key]
		local size = 0.22 + (math.max(tonumber(Settings.GrenadeMarkerSize) or 4, 2) / 10) * 0.15
		if not p or not p.Parent then
			p = makeNadeDot(color, size)
			entry._neonDotMap[key] = p
			table.insert(entry.NeonDots, p)
		end
		p.Color = color
		p.Size = Vector3.new(size, size, size)
		p.CFrame = CFrame.new(position)
		local vis = math.clamp(tonumber(alpha) or 1, 0.35, 1)
		p.Transparency = 0.12 + (1 - vis) * 0.7
		local light = p:FindFirstChild("Glow")
		if light then
			light.Color = color
			light.Brightness = 1.3 * vis
			light.Range = 8 * vis
		end
	end

	function Grenades:DrawBox(entry, camera, color, alpha)
		if not Settings.GrenadeBox or not entry.Position then
			return
		end
		local pos = entry.Position
		local size = 0.32
		local corners = {
			pos + Vector3.new(-size, -size, -size),
			pos + Vector3.new(size, -size, -size),
			pos + Vector3.new(size, size, -size),
			pos + Vector3.new(-size, size, -size),
			pos + Vector3.new(-size, -size, size),
			pos + Vector3.new(size, -size, size),
			pos + Vector3.new(size, size, size),
			pos + Vector3.new(-size, size, size),
		}
		local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
		local any = false
		for i = 1, 8 do
			local p = camera:WorldToViewportPoint(corners[i])
			if p.Z > 0 then
				any = true
				minX, maxX = math.min(minX, p.X), math.max(maxX, p.X)
				minY, maxY = math.min(minY, p.Y), math.max(maxY, p.Y)
			end
		end
		if not any then
			return
		end
		-- pad slightly so box isn't tight on the mesh
		minX, maxX = minX - 2, maxX + 2
		minY, maxY = minY - 2, maxY + 2
		local w, h = maxX - minX, maxY - minY
		if w < 4 or h < 4 then
			return
		end
		local len = math.clamp(math.min(w, h) * 0.28, 4, 14)
		if not entry.BoxLines then
			entry.BoxLines = {}
			entry.BoxOutlines = {}
			for i = 1, 8 do
				entry.BoxOutlines[i] = newDrawing(entry, "Line")
				entry.BoxLines[i] = newDrawing(entry, "Line")
			end
		end
		local segs = {
			{ Vector2.new(minX, minY), Vector2.new(minX + len, minY) },
			{ Vector2.new(minX, minY), Vector2.new(minX, minY + len) },
			{ Vector2.new(maxX, minY), Vector2.new(maxX - len, minY) },
			{ Vector2.new(maxX, minY), Vector2.new(maxX, minY + len) },
			{ Vector2.new(minX, maxY), Vector2.new(minX + len, maxY) },
			{ Vector2.new(minX, maxY), Vector2.new(minX, maxY - len) },
			{ Vector2.new(maxX, maxY), Vector2.new(maxX - len, maxY) },
			{ Vector2.new(maxX, maxY), Vector2.new(maxX, maxY - len) },
		}
		local thick = Settings.GrenadeThickness
		for i = 1, 8 do
			-- black outline under corner
			line(entry.BoxOutlines[i], segs[i][1], segs[i][2], Settings.OutlineColor, thick + 2, alpha)
			line(entry.BoxLines[i], segs[i][1], segs[i][2], color, thick, alpha)
		end
	end

	function Grenades:Draw(entry, camera, now)
		hide(entry)
		local kind = kinds[entry.Name]
		if not kind or not Settings[kind[1]] or not entry.Position then
			return
		end
		if entry.Preview and not entry.Active or (entry.Position - camera.CFrame.Position).Magnitude > Settings.GrenadeMaxDistance then
			return
		end
		local color = entry.Preview and Settings.GrenadePreviewColor or Settings[kind[2]]
		local alpha = Settings.GrenadeOpacity / 100
		if entry.Preview == "Near" then
			color = color:Lerp(Color3.fromRGB(95, 180, 255), 0.5)
		end
		entry.Shown = true
		entry._neonUsed = {}
		local forecast = entry.Forecast
		if forecast and (entry.Preview or Settings.GrenadePrediction) and type(forecast.Points) == "table" and #forecast.Points > 0 then
			local c1 = Settings.GrenadePredColor1 or color
			local c2 = Settings.GrenadePredColor2 or color
			if not entry.Preview then
				c1, c2 = color, color:Lerp(Color3.new(1, 1, 1), 0.25)
			end
			-- Path always starts at release / current nade world position (never behind camera)
			local previous = entry.Position
			if not entry.Preview and entry.State and typeof(entry.State.position) == "Vector3" then
				previous = entry.State.position
			end
			if typeof(previous) ~= "Vector3" and forecast.Points[1] then
				previous = forecast.Points[1].Position
			end
			-- Nudge first point in front of camera if needed
			pcall(function()
				local cam = camera.CFrame
				local look = cam.LookVector
				if typeof(previous) == "Vector3" and (previous - cam.Position):Dot(look) < 0.5 then
					previous = cam.Position + look * 1.2
				end
			end)
			local currentTime = not entry.Preview and entry.State and entry.State.simulationTime or -math.huge
			local pts = {}
			if typeof(previous) == "Vector3" then
				pts[1] = previous
			end
			for _, point in ipairs(forecast.Points) do
				if point.Time >= currentTime - 0.001 and typeof(point.Position) == "Vector3" then
					-- skip points still behind / too close to camera
					local d = -camera.CFrame:PointToObjectSpace(point.Position).Z
					if d >= 0.8 then
						-- avoid duplicate of origin
						if #pts == 0 or (pts[#pts] - point.Position).Magnitude > 0.08 then
							pts[#pts + 1] = point.Position
						end
					end
				end
			end
			if #pts < 2 and forecast.EndPosition and typeof(previous) == "Vector3" then
				pts = { previous, forecast.EndPosition }
			end
			local n = math.max(#pts - 1, 1)
			for i = 2, #pts do
				local tGrad = (i - 2) / n
				local segCol = c1:Lerp(c2, tGrad)
				self:Stroke(entry, "Prediction", i, camera, pts[i - 1], pts[i], segCol, alpha)
			end
			if Settings.GrenadeBounces then
				for i, point in ipairs(forecast.Bounces or {}) do
					local tGrad = i / math.max(#forecast.Bounces, 1)
					self:Marker(entry, i, camera, point, c1:Lerp(c2, tGrad), alpha, now)
				end
			end
			if Settings.GrenadeEndpoint and forecast.EndPosition then
				self:Marker(entry, 50, camera, forecast.EndPosition, c2, alpha, now)
			end
		end
		if not entry.Preview and Settings.GrenadeTrails then
			for i = 2, #entry.History do
				local a, b = entry.History[i - 1], entry.History[i]
				local faded = alpha * math.clamp(1 - (now - b.Time) / Settings.GrenadeTrailTime, 0, 1)
				self:Stroke(entry, "History", i, camera, a.Position, b.Position, color, faded)
			end
			if Settings.GrenadeBounces then
				local index = 60
				for _, point in ipairs(entry.History) do
					if point.Bounce then
						self:Marker(entry, index, camera, point.Position, color, alpha, now)
						index = index + 1
					end
				end
			end
		end
		if not entry.Preview then
			self:DrawBox(entry, camera, color, alpha)
		end
		-- Hide neon segs that were not redrawn this frame (stops leftover glitch lines)
		if entry._neonSegMap then
			for k, p in pairs(entry._neonSegMap) do
				if not (entry._neonUsed and entry._neonUsed[k]) then
					pcall(function()
						p.Transparency = 1
						local l = p:FindFirstChild("Glow")
						if l then l.Brightness = 0 end
					end)
				end
			end
		end
		-- World position of the *actual* grenade being followed (model), else sim position
		local followPos = entry.Position
		pcall(function()
			local m = entry.Model
			if m and m.Parent then
				local pp = m.PrimaryPart or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
				if pp then followPos = pp.Position end
			end
		end)

		-- Icons (toggle): follow live grenade while in-flight
		-- Timer phase: after landing, for smoke/fire grenades keep icon + drain bar alive
		local burnDur = BURN_DURATION[entry.Name]
		local inBurnPhase = burnDur and entry.LandTime and Settings.GrenadeTimers
			and (now - entry.LandTime) < burnDur

		if inBurnPhase then
			-- grenade has landed — use last known position (model gone, followPos = entry.Position)
			local landPos = entry.Position
			local elapsed = now - entry.LandTime
			local fraction = math.clamp(1 - elapsed / burnDur, 0, 1)  -- 1=full → 0=empty

			local sp, onScreen = camera:WorldToViewportPoint(landPos)
			if onScreen and sp.Z > 0.1 then
				local sg = ensureNadeTimerGui()
				if sg then
					local ICON_SZ = 22
					local ix, iy  = sp.X, sp.Y - 16

					local iconId = entry._iconId or resolveItemIcon(entry.Name)
					entry._iconId = iconId
					-- same multi-layer tracer-color dropshadow as in-flight icons
					local timerColor = color or Color3.fromRGB(255, 180, 60)
					pcall(function()
						local k2 = kinds[entry.Name]
						if k2 and Settings[k2[2]] then timerColor = Settings[k2[2]] end
					end)
					if iconId and iconId ~= "" then
						local function ensureSh(key, pad, z)
							local sh = entry[key]
							if not sh or not sh.Parent then
								sh = Instance.new("ImageLabel")
								sh.Name = key
								sh.BackgroundTransparency = 1
								sh.AnchorPoint = Vector2.new(0.5, 0.5)
								sh.ZIndex = z
								sh.Parent = sg
								entry[key] = sh
							end
							sh.Size = UDim2.fromOffset(ICON_SZ + pad, ICON_SZ + pad)
							sh.Image = iconId
							sh.ImageColor3 = timerColor
							sh.Position = UDim2.fromOffset(ix, iy)
							sh.Visible = true
							return sh
						end
						local s1 = ensureSh("TimerShadow1", 3, 49)
						s1.ImageTransparency = 0.72
						s1.Position = UDim2.fromOffset(ix + 1, iy + 1)
						pcall(function()
							if entry.TimerShadow2 then entry.TimerShadow2.Visible = false end
							if entry.TimerShadow3 then entry.TimerShadow3.Visible = false end
						end)
						if not entry.TimerIcon or not entry.TimerIcon.Parent then
							local im = Instance.new("ImageLabel")
							im.Name = "TimerIcon"; im.BackgroundTransparency = 1
							im.AnchorPoint = Vector2.new(0.5, 0.5)
							im.ZIndex = 51
							im.Parent = sg; entry.TimerIcon = im
						end
						local im = entry.TimerIcon
						im.Size = UDim2.fromOffset(ICON_SZ, ICON_SZ)
						im.Image = iconId
						im.ImageColor3 = Color3.new(1, 1, 1)
						im.ImageTransparency = 0
						im.Position = UDim2.fromOffset(ix, iy)
						im.Visible = true
					end

					-- Healthbar-style timer: skinny fill + solid black bg + black outline border
					local BAR_W, BAR_H, OUT = 26, 3, 1
					local barY = iy + ICON_SZ * 0.5 + 4
					local left = ix - BAR_W * 0.5
					-- outer black border
					if not entry.TimerBorder or not entry.TimerBorder.Parent then
						local bd = Instance.new("Frame")
						bd.Name = "TimerBorder"
						bd.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
						bd.BorderSizePixel = 0
						bd.AnchorPoint = Vector2.new(0, 0)
						bd.ZIndex = 50
						bd.Parent = sg
						entry.TimerBorder = bd
					end
					entry.TimerBorder.Size = UDim2.fromOffset(BAR_W + OUT * 2, BAR_H + OUT * 2)
					entry.TimerBorder.Position = UDim2.fromOffset(left - OUT, barY - OUT)
					entry.TimerBorder.Visible = true
					-- dark track (like ESP hp_bg)
					if not entry.TimerBg or not entry.TimerBg.Parent then
						local bg = Instance.new("Frame")
						bg.Name = "TimerBg"
						bg.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
						bg.BorderSizePixel = 0
						bg.AnchorPoint = Vector2.new(0, 0)
						bg.ZIndex = 51
						bg.Parent = sg
						entry.TimerBg = bg
					end
					entry.TimerBg.Size = UDim2.fromOffset(BAR_W, BAR_H)
					entry.TimerBg.Position = UDim2.fromOffset(left, barY)
					entry.TimerBg.Visible = true
					-- white fill drains left→right remaining
					if not entry.TimerFill or not entry.TimerFill.Parent then
						local fl = Instance.new("Frame")
						fl.Name = "TimerFill"
						fl.BackgroundColor3 = Color3.new(1, 1, 1)
						fl.BorderSizePixel = 0
						fl.AnchorPoint = Vector2.new(0, 0)
						fl.ZIndex = 52
						fl.Parent = sg
						entry.TimerFill = fl
					end
					entry.TimerFill.BackgroundColor3 = timerColor or Color3.new(1, 1, 1)
					local fillW = math.max(0, math.floor(BAR_W * fraction + 0.5))
					entry.TimerFill.Size = UDim2.fromOffset(fillW, BAR_H)
					entry.TimerFill.Position = UDim2.fromOffset(left, barY)
					entry.TimerFill.Visible = fillW > 0
				end
			else
				hideNadeTimer(entry)
			end
			-- hide the regular in-flight icon while timer is showing
			hideNadeIcon(entry)
		elseif Settings.GrenadeIcons and not entry.Ended and not entry.Preview then
			if typeof(followPos) == "Vector3" then
				drawNadeIcon(entry, followPos, color, alpha, camera)
			end
			hideNadeTimer(entry)
		else
			hideNadeIcon(entry)
			hideNadeTimer(entry)
		end

		-- Names BELOW icon, UPPERCASE, Font 2 (same as player ESP)
		if Settings.GrenadeNames and not entry.Ended and not entry.Preview then
			if typeof(followPos) == "Vector3" then
				local point, onScreen = camera:WorldToViewportPoint(followPos)
				if onScreen and point.Z > 0.1 then
					if not entry.Label then
						entry.Label = newDrawing(entry, "Text", { Center = true })
						pcall(function() entry.Label.Font = 2 end)
					end
					local yBelow = (Settings.GrenadeIcons and 20 or 14)
					local nm = string.upper(tostring(entry.Name or ""))
					text(entry.Label, nm, point.X, point.Y + yBelow, color, alpha, camera.ViewportSize, Settings.WorldTextSize or 13, true)
				elseif entry.Label then
					entry.Label.Visible = false
				end
			end
		elseif entry.Label then
			entry.Label.Visible = false
		end
	end

	function Grenades:Render(camera, now)
		if not self.Ready or not Settings.GrenadeEnabled then
			self:HideAll()
			return
		end
		self:UpdatePreview(camera, now)
		for _, entry in pairs(self.Entries) do
			self:Draw(entry, camera, now)
		end
		for _, entry in pairs(self.Previews) do
			self:Draw(entry, camera, now)
		end
	end

	local ok, failure = pcall(function()
		Grenades.Storage = game:GetService("ReplicatedStorage")
		local module = require(Grenades.Storage.Shared.GrenadeSimulator)
		pcall(function()
			Grenades.GetVelocity = require(Grenades.Storage.Components.Common.GetCharacterVelocity)
		end)
		Grenades.Module, Grenades.Original, Grenades.Step = module, module.simulate, module.step
		Grenades.StepTime = module.Constants and module.Constants.FIXED_TIMESTEP or (1 / 60)
		assert(type(Grenades.Original) == "function" and type(Grenades.Step) == "function", "Grenade physics is unavailable")
		Grenades.Wrapper = function(initial, config, params, delta)
			local result = Grenades.Original(initial, config, params, delta)
			if Grenades.Ready then
				local success, err = pcall(function()
					Grenades:Capture(result, config, params)
				end)
				if not success then
					Grenades.LastError = tostring(err)
				end
			end
			return result
		end
		module.simulate = Grenades.Wrapper
		Grenades.Ready = true
		RunService.Heartbeat:Connect(function()
			syncSettings()
			local success, err = pcall(function()
				Grenades:Update(os.clock())
			end)
			if not success then
				Grenades.LastError = tostring(err)
				Grenades:HideAll()
			end
		end)
		RunService.RenderStepped:Connect(function()
			if not Settings.GrenadeEnabled then
				return
			end
			local cam = workspace.CurrentCamera
			if not cam then
				return
			end
			pcall(function()
				Grenades:Render(cam, os.clock())
			end)
		end)
	end)
	if not ok then
		warn("[Methane] Grenades failed:", failure)
		Grenades.LastError = tostring(failure)
		Grenades:RestoreAll()
	end
end)

-- (legacy VindUI cloud/chat dock removed — not used on MethaneUI)
pcall(function()
	Library:Notification("successfully loaded..", 3, Library.Theme and Library.Theme.Accent)
end)

-- Mouse restore on UI close.
-- When the menu is toggled off (RightShift / keybind), the library hides its ScreenGui.
-- If we're in the main menu (no character), the cursor was never supposed to be locked —
-- but lockMouseFps may have fired before the character guard landed, or the ScreenGui
-- hide itself triggers a re-lock. Either way: watch the ScreenGui and restore on hide.
pcall(function()
	local function restoreMouseIfNeeded()
		local char = LocalPlayer and LocalPlayer.Character
		if char and char.Parent then return end  -- in-match: game owns the cursor, leave it
		pcall(function()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end)
	end

	-- Find the library's ScreenGui (first PlayerGui child that belongs to the lib)
	local function findLibGui()
		local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
		if not pg then return nil end
		-- MethaneUI uses a ScreenGui; find it by checking for our known containers
		for _, gui in ipairs(pg:GetChildren()) do
			if gui:IsA("ScreenGui") then
				-- library always has a Frame or similar at root level
				return gui
			end
		end
		return nil
	end

	local libGui = findLibGui()
	if libGui then
		libGui:GetPropertyChangedSignal("Enabled"):Connect(function()
			if not libGui.Enabled then
				restoreMouseIfNeeded()
			end
		end)
	end

	-- Belt-and-suspenders: also catch RightShift (the default menu toggle key)
	-- In case the GUI swap happens a frame after the keypress
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
			task.defer(restoreMouseIfNeeded)
		end
	end)

	-- Final safety net: poll at 2Hz when no character is loaded.
	-- Catches edge cases where neither the GUI signal nor the keypress fires in time.
	task.spawn(function()
		while true do
			task.wait(0.5)
			local char = LocalPlayer and LocalPlayer.Character
			if not char or not char.Parent then
				-- Main menu — make sure mouse is never locked
				pcall(function()
					if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
						or not UserInputService.MouseIconEnabled then
						UserInputService.MouseBehavior = Enum.MouseBehavior.Default
						UserInputService.MouseIconEnabled = true
					end
				end)
			end
		end
	end)
end)
