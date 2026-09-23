--[[
  Methane | Football Fusion 3
  Top AC bypass REMOVED — old hooks were interfering with ClientMain and
  could contribute to suspicious-movement flags. Features run without
  global metamethod hooks. ClientMain-aware movement gates remain below.
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
	if path == "MethaneUI" or path:sub(1, 9) == "MethaneUI/" or path:sub(1, 9) == "MethaneUI\\" then
		return path
	end
	return path
end
do
	if type(isfolder) == "function" then local _ = isfolder; isfolder = function(p, ...) return _(mapFsPath(p), ...) end end
	if type(makefolder) == "function" then local _ = makefolder; makefolder = function(p, ...) return _(mapFsPath(p), ...) end end
	if type(isfile) == "function" then local _ = isfile; isfile = function(p, ...) return _(mapFsPath(p), ...) end end
	if type(readfile) == "function" then local _ = readfile; readfile = function(p, ...) return _(mapFsPath(p), ...) end end
	if type(writefile) == "function" then local _ = writefile; writefile = function(p, ...) return _(mapFsPath(p), ...) end end
end

pcall(function()
	if not isfolder("MethaneUI") then makefolder("MethaneUI") end
	if not isfolder("MethaneUI/methane") then makefolder("MethaneUI/methane") end
	if not isfolder("MethaneUI/methane/cfgs") then makefolder("MethaneUI/methane/cfgs") end
	if not isfolder("MethaneUI/methane/cfgs/ff3") then makefolder("MethaneUI/methane/cfgs/ff3") end
end)

local Players = game:GetService("Players")
local LP = Players.LocalPlayer
local LOGO = "rbxassetid://72404794660074"

local Library
do
	local ok, lib = pcall(function()
		getgenv().MethaneLibrary = nil
		local src = game:HttpGet("https://raw.githubusercontent.com/iskasaputri020-wq/UI-LIB/refs/heads/main/library.lua")
		if type(src) ~= "string" or #src < 1000 then error("HttpGet failed") end
		local fn, err = loadstring(src)
		if not fn then error(tostring(err)) end
		return fn()
	end)
	if not (ok and lib) then
		error("[Methane] UI failed: " .. tostring(lib))
	end
	Library = lib
	getgenv().MethaneLibrary = Library
end

pcall(function()
	Library.MenuKeybind = tostring(Enum.KeyCode.RightShift)
end)


-- Mouse unlock safety — force free cursor when menu is closed
task.spawn(function()
	local uis = game:GetService("UserInputService")
	local lastOpen = nil
	local function menuIsOpen()
		local open = false
		pcall(function()
			if Library then
				if Library.Open == true then open = true end
				if Library.Holder and Library.Holder.Instance then
					local h = Library.Holder.Instance
					if h.Visible == true and (h.AbsoluteSize.X > 0 or h.AbsoluteSize.Y > 0) then
						-- check main window visibility if present
						open = open or (Library.Open ~= false)
					end
				end
			end
		end)
		-- fallback: detect via RightShift toggle state stored globally
		if getgenv().MethaneMenuOpen == true then open = true end
		if getgenv().MethaneMenuOpen == false then open = false end
		return open
	end
	while true do
		task.wait(0.05)
		pcall(function()
			local open = menuIsOpen()
			if lastOpen == true and open == false then
				-- just closed: force unlock
				uis.MouseBehavior = Enum.MouseBehavior.Default
				uis.MouseIconEnabled = true
				pcall(function()
					if Library then Library.MouseStateBeforeOpen = nil end
				end)
			end
			lastOpen = open
			-- while closed, never leave icon disabled from menu
			if open == false then
				if uis.MouseIconEnabled == false and uis.MouseBehavior == Enum.MouseBehavior.Default then
					-- only force icon if behavior is default (not FPS lock from game)
					uis.MouseIconEnabled = true
				end
			end
		end)
	end
end)

-- Track menu open via RightShift (Library.MenuKeybind)
task.spawn(function()
	local uis = game:GetService("UserInputService")
	getgenv().MethaneMenuOpen = true -- starts open usually
	uis.InputBegan:Connect(function(input, gp)
		if input.KeyCode == Enum.KeyCode.RightShift then
			getgenv().MethaneMenuOpen = not getgenv().MethaneMenuOpen
			if getgenv().MethaneMenuOpen == false then
				task.defer(function()
					uis.MouseBehavior = Enum.MouseBehavior.Default
					uis.MouseIconEnabled = true
					pcall(function()
						if Library then Library.MouseStateBeforeOpen = nil end
					end)
				end)
			end
		end
	end)
end)

local Library_Window = Library:Window({
	Title = "Methane",
	ButtonName = "FF3",
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
		return string.format("METHANE.LUA | FF3 | %s FPS | %s MS | BUILD: v1.00", tostring(fps or 0), tostring(ms))
	end)
	pcall(function() WM:SetVisibility(true) end)
	getgenv().MethaneWatermark = WM
end)

pcall(function()
	local KL = Library:KeybindList({ Name = "Keybinds" })
	if KL and KL.SetVisibility then KL:SetVisibility(true) end
	getgenv().MethaneKeybindList = KL
end)

getgenv().MethaneFF3 = { Window = Library_Window, Library = Library }

-- Default library Settings page (Configs + Other) — same as Rivals / UI lib
pcall(function()
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
	Library:RegisterSettingsWidget({
		Name = "Keybind List",
		Default = true,
		Callback = function(v)
			local kl = getgenv().MethaneKeybindList
			if kl and kl.SetVisibility then
				pcall(function() kl:SetVisibility(v) end)
			end
		end,
	})
end)

getgenv().Library = Library

-- ============================================================================
-- ============================================================================
-- Methane UI structure
-- Main: Aimbot | Catching | Player | Visuals | Automatics | Settings
-- SubPages under each (Player holds Physics + Defense)
-- ============================================================================
local Flags = {}
local ConfigFolder = "MethaneUI/methane/cfgs/ff3"

local function makeSub(page, subName, icon)
	local sub = page:SubPage({
		Name = subName,
		Icon = icon or "rbxassetid://6031097226",
	})
	local current = nil
	local function need()
		if not current then
			current = sub:Section({ Name = "General", Side = 1 })
		end
		return current
	end

	local api = { _page = page, _sub = sub, _name = subName }

	function api:CreateDivider() end

	function api:CreateToggle(opts)
		opts = opts or {}
		local sec = need()
		local state = { Value = opts.Default == true }
		local tog = sec:Toggle({
			Name = opts.Name or "Toggle",
			Default = state.Value,
			Callback = function(v)
				state.Value = v and true or false
				if opts.Callback then pcall(opts.Callback, state.Value) end
			end,
		})
		function state:Set(v)
			state.Value = v and true or false
			pcall(function()
				if not tog then return end
				if tog.Set then tog:Set(state.Value)
				elseif tog.SetValue then tog:SetValue(state.Value)
				elseif tog.SetState then tog:SetState(state.Value) end
			end)
		end
		pcall(function()
			if tog and tog.Keybind and (opts.Keybind ~= nil) then
				tog:Keybind({
					Name = opts.Name or "Toggle",
					Default = opts.Keybind,
					Mode = "Toggle",
				})
			end
		end)
		Flags[opts.Name or ("tog_" .. tostring(#Flags + 1))] = state
		return state
	end

	function api:CreateSlider(opts)
		opts = opts or {}
		local sec = need()
		local state = { Value = opts.Default or opts.Min or 0 }
		-- Library Decimals = step size (0.01 = hundredths). Map Increment → step.
		local step = opts.Decimals or opts.Increment or 0
		if type(step) ~= "number" then step = 0 end
		local sld = sec:Slider({
			Name = opts.Name or "Slider",
			Min = opts.Min or 0,
			Max = opts.Max or 100,
			Default = state.Value,
			Decimals = step,
			Suffix = opts.Suffix or "",
			Callback = function(v)
				state.Value = v
				if opts.Callback then pcall(opts.Callback, v) end
			end,
		})
		function state:Set(v)
			state.Value = v
			pcall(function()
				if not sld then return end
				if sld.Set then sld:Set(v)
				elseif sld.SetValue then sld:SetValue(v) end
			end)
		end
		Flags[opts.Name or ("sld_" .. tostring(#Flags + 1))] = state
		return state
	end

	function api:CreateDropdown(opts)
		opts = opts or {}
		local sec = need()
		local state = { Value = opts.Default or (opts.Options and opts.Options[1]) }
		local dd = sec:Dropdown({
			Name = opts.Name or "Dropdown",
			Items = opts.Options or {},
			Default = state.Value,
			Callback = function(v)
				state.Value = v
				if opts.Callback then pcall(opts.Callback, v) end
			end,
		})
		function state:Set(v)
			state.Value = v
			pcall(function()
				if not dd then return end
				if dd.Set then dd:Set(v)
				elseif dd.SetValue then dd:SetValue(v) end
			end)
		end
		Flags[opts.Name or ("dd_" .. tostring(#Flags + 1))] = state
		return state
	end

	function api:UseSection(name, side)
		current = sub:Section({ Name = tostring(name or "General"), Side = side or 1 })
		return current
	end

	function api:CreateKeybind(opts)
		-- pure key picker via Label:Keybind (no enable toggle)
		opts = opts or {}
		local sec = need()
		local state = { Value = opts.Default }
		local kbObj = nil
		pcall(function()
			local lbl = sec:Label({ Name = opts.Name or "Keybind" })
			if lbl and lbl.Keybind then
				kbObj = lbl:Keybind({
					Name = opts.Name or "Key",
					Default = opts.Default,
					Mode = "Hold",
					Callback = function(key)
						if typeof(key) == "EnumItem" then
							state.Value = key
						elseif key == true or key == false then
							-- mode press callback ignore
						else
							state.Value = key
						end
					end,
				})
			end
		end)
		function state:Set(v)
			state.Value = v
			pcall(function()
				if kbObj and kbObj.Set then kbObj:Set(v) end
			end)
		end
		Flags[opts.Name or ("kb_" .. tostring(#Flags + 1))] = state
		return state
	end

	function api:CreateButton(opts)
		opts = opts or {}
		local sec = need()
		pcall(function()
			sec:Button({
				Name = opts.Name or "Button",
				Callback = opts.Callback or function() end,
			})
		end)
	end

	return api
end

-- Main pages (5 + Settings)
local PageAimbot = Library_Window:Page({ Name = "Aimbot" })
local PageCatching = Library_Window:Page({ Name = "Catching" })
local PagePlayer = Library_Window:Page({ Name = "Player" })
local PageVisuals = Library_Window:Page({ Name = "Visuals" })
local PageAutomatics = Library_Window:Page({ Name = "Misc" })
-- Sub-tabs mapped to original feature variables (logic unchanged)
local ThrowingTab = makeSub(PageAimbot, "QB Aimbot", "rbxassetid://6034684949")
local ThrowingSettingsTab = makeSub(PageAimbot, "Settings", "rbxassetid://6031280882")

local CatchingTab = makeSub(PageCatching, "Catching", "rbxassetid://6034227067")

local PlayerTab = makeSub(PagePlayer, "Movement", "rbxassetid://6031097226")
local PhysicsTab = makeSub(PagePlayer, "Physics", "rbxassetid://11537490966")
local DefenseTab = makeSub(PagePlayer, "Defense", "rbxassetid://14939023862")

local VisualTab = makeSub(PageVisuals, "Visuals", "rbxassetid://6031763426")

local AutomaticsTab = makeSub(PageAutomatics, "Misc", "rbxassetid://86084882582277")
local MiscTab = makeSub(PageAutomatics, "Extra", "rbxassetid://129082556946713")

-- Settings page last (after all other pages)
pcall(function()
	Library_Window:CreateSettingsPage()
end)


-- Settings: UI + Configs (same style as other Methane scripts)


-- ============================================================================
-- Feature logic (same as Akena — tab vars point at SubPages above)
-- ============================================================================

-- ========== QB Aimbot UI (custom QbAimbot.lua logic) ==========
ThrowingTab:UseSection("Master", 1)
enableQbAimbot = ThrowingTab:CreateToggle({
	Name = "Enable QB Aimbot",
	Default = false,
})
trajectoryToggle = ThrowingTab:CreateToggle({
	Name = "Trajectory",
	Default = true,
})

ThrowingTab:UseSection("QB Misc", 2)
autoAngle = ThrowingTab:CreateToggle({
	Name = "Auto Angle",
	Default = true,
})
autoPower = ThrowingTab:CreateToggle({
	Name = "Auto Power",
	Default = true,
})
antiOOB = ThrowingTab:CreateToggle({
	Name = "Anti OOB",
	Default = true,
})
antiOOBThreshold = ThrowingTab:CreateSlider({
	Name = "OOB Tolerance",
	Min = 0,
	Max = 5,
	Default = 1.5,
	Increment = 0.1,
	Suffix = "",
})

ThrowingTab:UseSection("QB Modes", 1)
power95Mode = ThrowingTab:CreateToggle({
	Name = "95 Power Mode",
	Default = false,
})
smartFIT = ThrowingTab:CreateToggle({
	Name = "SmartFIT",
	Default = false,
})

ThrowingTab:UseSection("QB Cards", 2)
hideCards = ThrowingTab:CreateToggle({
	Name = "Hide Cards",
	Default = false,
})


-- Settings sub: per-throw lead offsets + heights + keybinds
ThrowingSettingsTab:UseSection("Lead Customization", 1)
leadBullet = ThrowingSettingsTab:CreateSlider({
	Name = "Bullet Lead", Min = 0, Max = 40, Default = 3.2, Increment = 0.1, Suffix = "",
})
leadDime = ThrowingSettingsTab:CreateSlider({
	Name = "Dime Lead", Min = 0, Max = 40, Default = 16, Increment = 0.1, Suffix = "",
})
leadFade = ThrowingSettingsTab:CreateSlider({
	Name = "Fade Lead", Min = 0, Max = 40, Default = 13, Increment = 0.1, Suffix = "",
})
leadDive = ThrowingSettingsTab:CreateSlider({
	Name = "Dive Lead", Min = 0, Max = 40, Default = 23, Increment = 0.1, Suffix = "",
})
leadMag = ThrowingSettingsTab:CreateSlider({
	Name = "Mag Lead", Min = 0, Max = 40, Default = 25, Increment = 0.1, Suffix = "",
})
leadJump = ThrowingSettingsTab:CreateSlider({
	Name = "Jump Lead", Min = 0, Max = 40, Default = 14, Increment = 0.1, Suffix = "",
})
leadStill = ThrowingSettingsTab:CreateSlider({
	Name = "Still Lead", Min = 0, Max = 20, Default = 0.5, Increment = 0.1, Suffix = "",
})

ThrowingSettingsTab:UseSection("Dot Customization", 2)
heightChest = ThrowingSettingsTab:CreateSlider({
	Name = "Chest Height", Min = -5, Max = 10, Default = 0, Increment = 0.1, Suffix = "",
})
heightHead = ThrowingSettingsTab:CreateSlider({
	Name = "Head Height", Min = 0, Max = 12, Default = 4.5, Increment = 0.1, Suffix = "",
})

ThrowingSettingsTab:UseSection("Main Keybinds", 1)
toggleKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Toggle Aimbot", Default = Enum.KeyCode.G,
})
antiOOBKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Toggle Anti OOB", Default = Enum.KeyCode.H,
})
lockKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Lock Target (also M3)", Default = Enum.KeyCode.X,
})

ThrowingSettingsTab:UseSection("Manual Power/Angle", 2)
manualAngle = ThrowingSettingsTab:CreateSlider({
	Name = "Manual Angle",
	Min = 1,
	Max = 90,
	Default = 30,
	Increment = 1,
	Suffix = "°",
})
manualPower = ThrowingSettingsTab:CreateSlider({
	Name = "Manual Power",
	Min = 1,
	Max = 95,
	Default = 60,
	Increment = 1,
	Suffix = "",
})
angleUpKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Angle +5", Default = Enum.KeyCode.Q,
})
angleDownKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Angle -5", Default = Enum.KeyCode.E,
})
powerUpKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Power +5", Default = Enum.KeyCode.R,
})
powerDownKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Power -5", Default = Enum.KeyCode.F,
})

ThrowingSettingsTab:UseSection("Throw Mode Keybinds", 1)
cycleModeKeybind = ThrowingSettingsTab:CreateKeybind({
	Name = "Cycle Mode", Default = Enum.KeyCode.Z,
})
modeStillKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Still", Default = Enum.KeyCode.One,
})
modeBulletKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Bullet", Default = Enum.KeyCode.Two,
})
modeDimeKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Dime", Default = Enum.KeyCode.Three,
})
modeFadeKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Fade", Default = Enum.KeyCode.Four,
})
modeDiveKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Dive", Default = Enum.KeyCode.Five,
})
modeMagKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Mag", Default = Enum.KeyCode.Six,
})
modeJumpKey = ThrowingSettingsTab:CreateKeybind({
	Name = "Jump", Default = Enum.KeyCode.Seven,
})

-- Legacy aliases so any residual refs don't nil
throwAimbot = enableQbAimbot
autoChooseWr = enableQbAimbot
autoSelectThrowMode = enableQbAimbot
autoPower = autoPower
autoAngle = autoAngle
highPowerOnly = enableQbAimbot
antiDB = enableQbAimbot
antiDBThreshold = antiOOBThreshold
autoJuke = { Value = false, Set = function() end }
autoChangePowerUI = hideCards
autoJumpWhenThrow = { Value = false, Set = function() end }
autoThrowAfterSack = { Value = false, Set = function() end }
throwLeadOffset = leadBullet
throwHeightOffset = heightHead
dimeKeybind = cycleModeKeybind
magKeybind = cycleModeKeybind
diveKeybind = cycleModeKeybind
jumpKeybind = cycleModeKeybind
bulletKeybind = cycleModeKeybind
throwBallAwayKeybind = { Value = nil, Set = function() end }
increaseAngleKeybind = angleUpKeybind
decreaseAngleKeybind = angleDownKeybind

-- ========== Custom QB Aimbot engine ==========
do
	local env = getgenv and getgenv() or _G
	env.QB_GLOBAL = env.QB_GLOBAL or { Connections = {}, Visuals = {}, Highlight = nil, ScreenGui = nil }
	local Shared = env.QB_GLOBAL

	for _, c in ipairs(Shared.Connections) do
		pcall(function() if c and c.Disconnect then c:Disconnect() end end)
	end
	Shared.Connections = {}
	for _, v in ipairs(Shared.Visuals) do
		pcall(function() if v and v.Parent then v:Destroy() end end)
	end
	Shared.Visuals = {}
	if Shared.Highlight and Shared.Highlight.Parent then Shared.Highlight:Destroy() end
	Shared.Highlight = nil
	if Shared.ScreenGui and Shared.ScreenGui.Parent then Shared.ScreenGui:Destroy() end
	Shared.ScreenGui = nil

	local QB = {}
	QB.Version = "2.6"
	QB.FF2Grav = 28
	QB.state = false
	QB.AutoAngle = true
	QB.AutoPower = true
	QB.trajectoryEnabled = true
	QB.trajectoryColor = Color3.fromRGB(150, 50, 255)
	QB.trajectoryWidth = 0.5
	QB.AdvancedLead = false
	QB.ManualAngleDeg = 30
	QB.ManualPower = 60
	QB.MinPower = 1
	QB.MinAngle = 1
	QB.MaxPower = 95
	QB.MaxAngle = 90
	QB.AntiOOB = true
	QB.OOBTolerance = 1.5
	QB.Power95 = false
	QB.SmartFIT = false
	QB.TargetLocked = false
	QB.LockedTarget = nil
	QB.ClosestPlr = nil
	QB.ThrowingTab = { Direction = Vector3.new(0, 0, 0) }
	QB.Connections = Shared.Connections
	QB.Visuals = Shared.Visuals
	QB.InterceptionHighlightCache = {}

	QB.MasterLeads = {
		Modes = {
			Bullet = 3.2, Dime = 16, Fade = 13, Dive = 23, Mag = 25, Jump = 14, Still = 0.5,
		},
		Heights = { Chest = 0, HeadPlusTwo = 4.5 },
	}

	local function rebuildThrowTypes()
		local M = QB.MasterLeads.Modes
		QB.ThrowTypes = {
			Bullet = { Lead = M.Bullet, AngleCurve = function(dist)
				if dist < 15 then return { 4, 6, 8 } elseif dist < 35 then return { 5, 7, 10 } else return { 7, 10, 14 } end
			end },
			Dime = { Lead = M.Dime, AngleCurve = function(dist)
				if dist < 20 then return { 22, 28, 34 } elseif dist < 60 then return { 28, 34, 40 } else return { 32, 38, 45 } end
			end },
			Fade = { Lead = M.Fade, AngleCurve = function(dist)
				if dist < 20 then return { 45, 55, 60 } elseif dist < 60 then return { 50, 60, 65 } else return { 55, 65, 70 } end
			end },
			Dive = { Lead = M.Dive, AngleCurve = function(dist)
				if dist < 20 then return { 25, 32, 40 } elseif dist < 60 then return { 30, 38, 45 } else return { 34, 42, 48 } end
			end },
			Mag = { Lead = M.Mag, AngleCurve = function(dist)
				if dist < 20 then return { 30, 38, 45 } elseif dist < 70 then return { 35, 45, 55 } else return { 38, 48, 60 } end
			end },
			Jump = { Lead = M.Jump, AngleCurve = function(dist)
				if dist < 20 then return { 30, 38, 45 } elseif dist < 60 then return { 32, 42, 50 } else return { 35, 48, 55 } end
			end },
			Still = { Lead = M.Still, AngleCurve = function(dist) return { 12, 16, 20 } end },
		}
	end
	rebuildThrowTypes()

	local ThrowOrder = { "Bullet", "Dime", "Fade", "Dive", "Mag", "Jump", "Still" }
	local ThrowIndex = 1
	QB.CurrentThrowType = ThrowOrder[ThrowIndex]

	-- Sync UI -> QB every frame lightly
	local function syncFromUI()
		QB.state = enableQbAimbot.Value == true
		QB.AutoAngle = autoAngle.Value == true
		QB.AutoPower = autoPower.Value == true
		QB.AntiOOB = antiOOB.Value == true
		QB.OOBTolerance = tonumber(antiOOBThreshold.Value) or 1.5
		QB.trajectoryEnabled = trajectoryToggle.Value ~= false
		QB.AdvancedLead = false
		QB.ManualAngleDeg = tonumber(manualAngle.Value) or 30
		QB.ManualPower = tonumber(manualPower.Value) or 60
		QB.Power95 = power95Mode and power95Mode.Value == true
		QB.SmartFIT = smartFIT and smartFIT.Value == true
		QB.MasterLeads.Modes.Bullet = tonumber(leadBullet.Value) or 3.2
		QB.MasterLeads.Modes.Dime = tonumber(leadDime.Value) or 16
		QB.MasterLeads.Modes.Fade = tonumber(leadFade.Value) or 13
		QB.MasterLeads.Modes.Dive = tonumber(leadDive.Value) or 23
		QB.MasterLeads.Modes.Mag = tonumber(leadMag.Value) or 25
		QB.MasterLeads.Modes.Jump = tonumber(leadJump.Value) or 14
		QB.MasterLeads.Modes.Still = tonumber(leadStill.Value) or 0.5
		QB.MasterLeads.Heights.Chest = tonumber(heightChest.Value) or 0
		QB.MasterLeads.Heights.HeadPlusTwo = tonumber(heightHead.Value) or 4.5
		-- push leads into ThrowTypes
		for name, tt in pairs(QB.ThrowTypes) do
			if QB.MasterLeads.Modes[name] then
				tt.Lead = QB.MasterLeads.Modes[name]
			end
		end
		if QB.InfoFrame and QB.InfoFrame.Parent then
			local masterOn = enableQbAimbot and enableQbAimbot.Value == true
			QB.InfoFrame.Visible = masterOn and not (hideCards.Value == true)
		end
	end

	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local UserInputService = game:GetService("UserInputService")
	local RunService = game:GetService("RunService")
	local ContextActionService = game:GetService("ContextActionService")
	local LocalPlayer = Players.LocalPlayer
	while not LocalPlayer do
		task.wait()
		LocalPlayer = Players.LocalPlayer
	end
	local Char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local Humanoid = Char:WaitForChild("Humanoid")
	local HumanoidRootPart = Char:WaitForChild("HumanoidRootPart")
	local Animator = Humanoid:FindFirstChildOfClass("Animator") or Humanoid:WaitForChild("Animator")
	LocalPlayer.CharacterAdded:Connect(function(c) Char = c end)

	local hiddenUI
	pcall(function()
		hiddenUI = (gethui and gethui()) or game:GetService("CoreGui")
	end)
	if not hiddenUI then
		hiddenUI = LocalPlayer:WaitForChild("PlayerGui")
	end

	local function isPracticeMode()
		return game.PlaceId == 81310542478972 or game.PlaceId == 8206123457
	end

	local function isTeammate(target)
		if not target or not target:IsA("Player") then return false end
		local localTeam, targetTeam = LocalPlayer.Team, target.Team
		if not localTeam or not targetTeam then return false end
		return localTeam == targetTeam
	end

	local function IsA(obj, className)
		return obj ~= nil and typeof(obj) == "Instance" and obj:IsA(className)
	end

	local function ResolveHRP(obj)
		if IsA(obj, "Player") then
			local ch = obj.Character
			return ch and ch:FindFirstChild("HumanoidRootPart")
		end
		if IsA(obj, "Model") then
			return obj:FindFirstChild("HumanoidRootPart")
		end
		return nil
	end

	local function GetPing()
		local ok, v = pcall(function()
			return game:GetService("Stats").PerformanceStats.Ping:GetValue()
		end)
		return ok and v or 0
	end
	local function GetFPS()
		local ok, v = pcall(function()
			return game:GetService("Stats").Workspace.FPS:GetValue()
		end)
		return (ok and v and v > 0) and v or 60
	end

	local function clamp(v, mn, mx)
		if v < mn then return mn elseif v > mx then return mx end
		return v
	end

	-- Visuals
	local function createLandingPart()
		local p = Instance.new("Part")
		p.Size = Vector3.new(2, 2, 2)
		p.Shape = Enum.PartType.Ball
		p.Anchored = true
		p.CanCollide = false
		p.Color = QB.trajectoryColor
		p.Material = Enum.Material.Neon
		p.Transparency = 0.3
		p.Name = "LandingMarker"
		p.Parent = workspace.Terrain
		table.insert(QB.Visuals, p)
		return p
	end
	QB.LandingPart = createLandingPart()

	local BaseMarker = Instance.new("Part")
	BaseMarker.Size = Vector3.new(1.2, 1.2, 1.2)
	BaseMarker.Shape = Enum.PartType.Ball
	BaseMarker.Anchored = true
	BaseMarker.CanCollide = false
	BaseMarker.Material = Enum.Material.Neon
	BaseMarker.Color = Color3.fromRGB(180, 180, 180)
	BaseMarker.Transparency = 0.3
	BaseMarker.Parent = workspace
	table.insert(QB.Visuals, BaseMarker)

	local att0 = Instance.new("Attachment", workspace.Terrain)
	local att1 = Instance.new("Attachment", workspace.Terrain)
	local trajectoryBeam = Instance.new("Beam")
	trajectoryBeam.Attachment0 = att0
	trajectoryBeam.Attachment1 = att1
	trajectoryBeam.FaceCamera = true
	trajectoryBeam.Segments = 96
	trajectoryBeam.Width0 = 3.4
	trajectoryBeam.Width1 = 2.8
	trajectoryBeam.LightEmission = 1
	trajectoryBeam.LightInfluence = 0
	trajectoryBeam.Texture = "rbxassetid://446111271"
	trajectoryBeam.TextureSpeed = 0.15
	trajectoryBeam.TextureLength = 1.2
	trajectoryBeam.Parent = workspace.Terrain

	-- white DOTS along baseline path (SmartFIT adjustment) — real parts, not a beam
	local dAtt0 = Instance.new("Attachment", workspace.Terrain)
	local dAtt1 = Instance.new("Attachment", workspace.Terrain)
	local dottedBeam = Instance.new("Beam") -- kept disabled; dots used instead
	dottedBeam.Enabled = false
	dottedBeam.Parent = workspace.Terrain
	local baselineDots = {}
	local BASELINE_DOT_COUNT = 20
	local function hideBaselineDots()
		for i = 1, #baselineDots do
			local p = baselineDots[i]
			if p then
				p.Transparency = 1
				p.CFrame = CFrame.new(0, -5000, 0)
			end
		end
	end
	local function showBaselineDots(startPos, vel, g, tof)
		hideBaselineDots()
		if typeof(startPos) ~= "Vector3" or typeof(vel) ~= "Vector3" then return end
		tof = tonumber(tof) or 0
		if tof < 0.05 then return end
		g = tonumber(g) or QB.FF2Grav or 28
		local grav = Vector3.new(0, -g, 0)
		for i = 1, BASELINE_DOT_COUNT do
			local t = tof * (i / (BASELINE_DOT_COUNT + 1))
			local pos = startPos + vel * t + grav * (0.5 * t * t)
			local p = baselineDots[i]
			if not p or not p.Parent then
				p = Instance.new("Part")
				p.Name = "MethaneBaselineDot"
				p.Shape = Enum.PartType.Ball
				p.Size = Vector3.new(0.85, 0.85, 0.85)
				p.Material = Enum.Material.Neon
				p.Color = Color3.fromRGB(255, 255, 255)
				p.Anchored = true
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.CastShadow = false
				p.Parent = workspace.Terrain
				baselineDots[i] = p
				table.insert(QB.Visuals, p)
			end
			-- fade dots near start and end
			local edge = math.min(i, BASELINE_DOT_COUNT + 1 - i)
			local alpha = 0.05
			if edge <= 2 then
				alpha = 0.55
			elseif edge <= 4 then
				alpha = 0.25
			end
			p.Size = Vector3.new(0.9, 0.9, 0.9)
			p.Transparency = alpha
			p.CFrame = CFrame.new(pos)
		end
	end

	-- residual (post-throw arc, same thickness family as live trajectory)
	local rAtt0 = Instance.new("Attachment", workspace.Terrain)
	local rAtt1 = Instance.new("Attachment", workspace.Terrain)
	local residualBeam = Instance.new("Beam")
	residualBeam.Attachment0 = rAtt0
	residualBeam.Attachment1 = rAtt1
	residualBeam.FaceCamera = true
	residualBeam.Segments = 96
	residualBeam.Width0 = 1.6
	residualBeam.Width1 = 1.2
	residualBeam.LightEmission = 0.85
	residualBeam.LightInfluence = 0
	residualBeam.Texture = "rbxassetid://446111271"
	residualBeam.TextureLength = 1.2
	residualBeam.Enabled = false
	residualBeam.Parent = workspace.Terrain

	table.insert(QB.Visuals, att0)
	table.insert(QB.Visuals, att1)
	table.insert(QB.Visuals, trajectoryBeam)
	table.insert(QB.Visuals, dAtt0)
	table.insert(QB.Visuals, dAtt1)
	table.insert(QB.Visuals, dottedBeam)
	table.insert(QB.Visuals, rAtt0)
	table.insert(QB.Visuals, rAtt1)
	table.insert(QB.Visuals, residualBeam)

	local lastThrownTick = 0
	local lastThrowCurve = nil

	local function ProjectileBeam(g, v0, x0, t1)
		local c = 0.125
		local p3 = 0.5 * g * t1 * t1 + v0 * t1 + x0
		local p2 = p3 - (g * t1 * t1 + v0 * t1) / 3
		local p1 = (c * g * t1 * t1 + 0.5 * v0 * t1 + x0 - c * (x0 + p3)) / (3 * c) - p2
		local curve0 = (p1 - x0).Magnitude
		local curve1 = (p2 - p3).Magnitude
		local b = (x0 - p3).Unit
		local r1 = (p1 - x0).Unit
		local u1 = r1:Cross(b).Unit
		local r2 = (p2 - p3).Unit
		local u2 = r2:Cross(b).Unit
		b = u1:Cross(r1).Unit
		local cf1 = CFrame.new(x0.x, x0.y, x0.z, r1.x, u1.x, b.x, r1.y, u1.y, b.y, r1.z, u1.z, b.z)
		local cf2 = CFrame.new(p3.x, p3.y, p3.z, r2.x, u2.x, b.x, r2.y, u2.y, b.y, r2.z, u2.z, b.z)
		return curve0, -curve1, cf1, cf2
	end

	local function getAccent()
		local a = Library and Library.AccentColor
		if typeof(a) == "Color3" then return a end
		return Color3.fromRGB(0, 200, 255)
	end

	function QB.createTrajectoryVisualization(start, velocity, g, tof, baselineVel, baselineTof)
		if not QB.trajectoryEnabled or not QB.state then
			trajectoryBeam.Enabled = false
			dottedBeam.Enabled = false
			return
		end
		-- thick glowing accent arc (pre-throw aim path)
		local accent = getAccent()
		local bright = Color3.new(
			math.min(1, accent.R * 1.15 + 0.08),
			math.min(1, accent.G * 1.15 + 0.08),
			math.min(1, accent.B * 1.15 + 0.08)
		)
		local dim = Color3.new(accent.R * 0.55, accent.G * 0.55, accent.B * 0.55)
		trajectoryBeam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, dim),
			ColorSequenceKeypoint.new(0.08, bright),
			ColorSequenceKeypoint.new(0.5, bright),
			ColorSequenceKeypoint.new(0.92, bright),
			ColorSequenceKeypoint.new(1, dim),
		})
		trajectoryBeam.Width0 = 3.4
		trajectoryBeam.Width1 = 2.8
		trajectoryBeam.LightEmission = 1
		trajectoryBeam.LightInfluence = 0
		-- fade near thrower + near landing
		trajectoryBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.92),
			NumberSequenceKeypoint.new(0.08, 0.35),
			NumberSequenceKeypoint.new(0.18, 0.0),
			NumberSequenceKeypoint.new(0.82, 0.0),
			NumberSequenceKeypoint.new(0.92, 0.35),
			NumberSequenceKeypoint.new(1, 0.95),
		})
		local gVec = Vector3.new(0, -g, 0)
		local curve0, curve1, cf1, cf2 = ProjectileBeam(gVec, velocity, start, tof)
		att0.WorldCFrame = cf1
		att1.WorldCFrame = cf2
		trajectoryBeam.CurveSize0 = curve0
		trajectoryBeam.CurveSize1 = curve1
		-- if post-throw residual is active, keep showing it (don't fight the residual)
		if tick() - lastThrownTick < 2.2 then
			trajectoryBeam.Enabled = false
			return
		end

		trajectoryBeam.Enabled = true
		dottedBeam.Enabled = false

		hideBaselineDots()

		if QB.LandingPart then
			QB.LandingPart.Color = accent
			QB.LandingPart.Material = Enum.Material.Neon
			QB.LandingPart.Transparency = 0.15
		end
		if BaseMarker then
			BaseMarker.Color = accent
			BaseMarker.Material = Enum.Material.Neon
			BaseMarker.Transparency = 0.2
		end

		-- cache aim arc + optional baseline (non-SmartFIT) for dotted post-throw
		lastThrowCurve = {
			start = start, velocity = velocity, g = g, tof = tof,
			c0 = curve0, c1 = curve1, cf1 = cf1, cf2 = cf2,
			baselineVel = baselineVel, baselineTof = baselineTof,
		}
	end

	local function showPostThrowResidual()
		if not lastThrowCurve then return end
		local c = lastThrowCurve
		lastThrownTick = tick()
		local a = getAccent()
		-- residual = same thick glow as aim path, slightly softer (ball in air)
		residualBeam.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.new(a.R * 0.5, a.G * 0.5, a.B * 0.5)),
			ColorSequenceKeypoint.new(0.5, a),
			ColorSequenceKeypoint.new(1, Color3.new(a.R * 0.5, a.G * 0.5, a.B * 0.5)),
		})
		residualBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.25),
			NumberSequenceKeypoint.new(0.5, 0.08),
			NumberSequenceKeypoint.new(1, 0.45),
		})
		residualBeam.Width0 = 3.2
		residualBeam.Width1 = 2.6
		residualBeam.LightEmission = 1
		residualBeam.LightInfluence = 0
		residualBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.9),
			NumberSequenceKeypoint.new(0.12, 0.25),
			NumberSequenceKeypoint.new(0.5, 0.05),
			NumberSequenceKeypoint.new(0.88, 0.25),
			NumberSequenceKeypoint.new(1, 0.95),
		})
		rAtt0.WorldCFrame = c.cf1
		rAtt1.WorldCFrame = c.cf2
		residualBeam.CurveSize0 = c.c0
		residualBeam.CurveSize1 = c.c1
		residualBeam.Enabled = true
		trajectoryBeam.Enabled = false
		dottedBeam.Enabled = false

		hideBaselineDots()

		task.delay(2.2, function()
			if tick() - lastThrownTick >= 2.1 then
				residualBeam.Enabled = false
				dottedBeam.Enabled = false
				hideBaselineDots()
			end
		end)
	end

	local function hideLandingMarkers()
		trajectoryBeam.Enabled = false
		-- do NOT kill post-throw residual/dots while still showing
		if tick() - lastThrownTick > 2.3 then
			pcall(function() dottedBeam.Enabled = false end)
			pcall(function() residualBeam.Enabled = false end)
			pcall(hideBaselineDots)
		end
		if QB.LandingPart then
			QB.LandingPart.CFrame = CFrame.new(0, -5000, 0)
		end
		if BaseMarker then
			BaseMarker.CFrame = CFrame.new(0, -5000, 0)
		end
	end

	-- OOB
	local OOB_PARTS = {}
	local OOB_INITIALIZED = false
	local function initializeOOBParts()
		if OOB_INITIALIZED then return end
		local oobFolder
		pcall(function()
			if workspace:FindFirstChild("Models") and workspace.Models:FindFirstChild("Field") then
				local grass = workspace.Models.Field:FindFirstChild("Grass")
				oobFolder = grass and grass:FindFirstChild("Outside")
			end
		end)
		if oobFolder then
			for _, obj in ipairs(oobFolder:GetDescendants()) do
				if obj:IsA("BasePart") then table.insert(OOB_PARTS, obj) end
			end
		end
		OOB_INITIALIZED = true
	end

	local function IsPositionOOB(position)
		if #OOB_PARTS == 0 then return false end
		local xzPos = Vector3.new(position.X, 0, position.Z)
		for _, part in ipairs(OOB_PARTS) do
			if part and part.Parent then
				local cf, size = part.CFrame, part.Size
				local min = (cf * CFrame.new(-size.X / 2, 0, -size.Z / 2)).Position
				local max = (cf * CFrame.new(size.X / 2, 0, size.Z / 2)).Position
				local partMinXZ = Vector2.new(math.min(min.X, max.X), math.min(min.Z, max.Z))
				local partMaxXZ = Vector2.new(math.max(min.X, max.X), math.max(min.Z, max.Z))
				local posXZ = Vector2.new(xzPos.X, xzPos.Z)
				local tol = QB.OOBTolerance
				if posXZ.X >= partMinXZ.X - tol and posXZ.X <= partMaxXZ.X + tol
					and posXZ.Y >= partMinXZ.Y - tol and posXZ.Y <= partMaxXZ.Y + tol then
					return true
				end
			end
		end
		return false
	end

	local function ClampPositionToInBounds(pos)
		if not IsPositionOOB(pos) then return pos end
		-- pull toward center of field roughly
		return Vector3.new(pos.X * 0.85, pos.Y, pos.Z * 0.85)
	end

	local function CalculateRouteofPlayer(target)
		local hrp = ResolveHRP(target)
		if not hrp or not HumanoidRootPart then return "Still" end
		local hum = (target:IsA("Player") and target.Character and target.Character:FindFirstChild("Humanoid"))
			or target:FindFirstChild("Humanoid")
		if not hum then return "Still" end
		local moveDir = hum.MoveDirection
		if moveDir.Magnitude < 0.1 then return "Still" end
		moveDir = moveDir.Unit
		local qbToReceiver = (hrp.Position - HumanoidRootPart.Position).Unit
		local receiverToQB = -qbToReceiver
		local fieldForward = Vector3.new(0, 0, (hrp.Position.Z > HumanoidRootPart.Position.Z and 1 or -1))
		local streakAlignment = moveDir:Dot(fieldForward)
		local comebackAlignment = moveDir:Dot(receiverToQB)
		if comebackAlignment > 0.75 then return "Comeback"
		elseif math.abs(streakAlignment) < 0.5 then
			return (math.abs(streakAlignment) < 0.25) and "Slant" or "Post"
		elseif math.abs(streakAlignment) >= 0.8 then return "Straight"
		end
		return "Straight"
	end

	local function solveVForAngle(g, distance, dy, angleDeg)
		local angleRad = math.rad(angleDeg)
		local cosA = math.cos(angleRad)
		if cosA == 0 then return nil end
		local tanA = math.tan(angleRad)
		local denom = 2 * (cosA ^ 2) * (distance * tanA - dy)
		if denom <= 0 then return nil end
		local v2 = (g * distance * distance) / denom
		if v2 <= 0 then return nil end
		return math.sqrt(v2), angleRad
	end

	function QB.CalculateOptimalThrow(start, targetPos, targetVel, g, target)
		local delta = targetPos - start
		local flat = Vector3.new(delta.X, 0, delta.Z)
		local dist = flat.Magnitude
		if dist < 0.1 then dist = 0.1 end
		local dy = delta.Y
		local angleDeg = QB.AutoAngle and 30 or QB.ManualAngleDeg
		local power = QB.AutoPower and 70 or QB.ManualPower
		local baselineAngle, baselinePower = angleDeg, power

		-- baseline (throw-mode / manual) — used for SmartFIT dotted adjustment
		do
			local tt = QB.ThrowTypes[QB.CurrentThrowType]
			if QB.AutoAngle then
				local curve = tt and tt.AngleCurve(dist) or { 20, 30, 40 }
				local bestA, bestV, bestScore = curve[2] or 30, nil, math.huge
				for _, a in ipairs(curve) do
					local v = select(1, solveVForAngle(g, dist, dy, a))
					if v then
						local score = math.abs(v - 55)
						if score < bestScore then
							bestScore = score
							bestA = a
							bestV = v
						end
					end
				end
				baselineAngle = bestA
				if bestV and QB.AutoPower then
					baselinePower = clamp(bestV, QB.MinPower, QB.MaxPower)
				end
			else
				local v = select(1, solveVForAngle(g, dist, dy, baselineAngle))
				if v and QB.AutoPower then
					baselinePower = clamp(v, QB.MinPower, QB.MaxPower)
				end
			end
			if QB.Power95 and not QB.SmartFIT then
				baselinePower = 95
			end
		end

		if QB.SmartFIT then
			-- Coverage-aware SmartFIT:
			-- 1) Scan whole field for enemy DBs near the WR
			-- 2) Wide open → easy catch (normal power/angle, any mode range)
			-- 3) Covered → fit over the DB (higher arc, still catchable)
			local flatDirU = flat.Unit
			local OPEN_DIST = 14      -- DB farther than this from WR = open
			local COVER_DIST = 14     -- within this = contested
			local DB_JUMP = 8.5       -- vertical tip range

			local receiverPos = targetPos
			local nearestDB, nearestDBDist = nil, math.huge
			local defenders = {}
			pcall(function()
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr == LocalPlayer then continue end
					local enemy = true
					if isTeammate and isTeammate(plr) then
						enemy = false
					end
					if target and typeof(target) == "Instance" and target:IsA("Player") and plr == target then
						enemy = false
					end
					if not enemy then continue end
					local ch = plr.Character
					local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
					if not hrp then continue end
					defenders[#defenders + 1] = hrp
					local d = (Vector3.new(hrp.Position.X - receiverPos.X, 0, hrp.Position.Z - receiverPos.Z)).Magnitude
					if d < nearestDBDist then
						nearestDBDist = d
						nearestDB = hrp
					end
				end
				-- practice bots near the receiver only (avoid full-workspace scan)
				if isPracticeMode and isPracticeMode() then
					local folder = workspace:FindFirstChild("Bots") or workspace:FindFirstChild("NPCs")
					local roots = folder and folder:GetChildren() or {}
					if #roots == 0 then
						-- light fallback: characters under workspace with Humanoid, no player
						for _, obj in ipairs(workspace:GetChildren()) do
							if obj:IsA("Model") and obj:FindFirstChild("HumanoidRootPart") and obj:FindFirstChildOfClass("Humanoid") then
								if not Players:GetPlayerFromCharacter(obj) then
									roots[#roots + 1] = obj
								end
							end
						end
					end
					for _, obj in ipairs(roots) do
						local hrp = obj:FindFirstChild("HumanoidRootPart")
						if not hrp then continue end
						if target and typeof(target) == "Instance" and (target == obj or (target:IsA("Model") and target == obj)) then
							continue
						end
						local d = (Vector3.new(hrp.Position.X - receiverPos.X, 0, hrp.Position.Z - receiverPos.Z)).Magnitude
						if d > 40 then continue end
						defenders[#defenders + 1] = hrp
						if d < nearestDBDist then
							nearestDBDist = d
							nearestDB = hrp
						end
					end
				end
			end)

			local isOpen = (not nearestDB) or (nearestDBDist > OPEN_DIST)
			QB._smartCovered = not isOpen
			QB._smartDBDist = nearestDBDist < math.huge and nearestDBDist or nil

			local bestA, bestV, bestScore = baselineAngle, baselinePower, math.huge

			if isOpen then
				-- Wide open: soft floater for easiest catch (NOT high power)
				for a = 18, 52, 0.5 do
					local v = select(1, solveVForAngle(g, dist, dy, a))
					if v and v >= 28 and v <= 78 then
						local aRad = math.rad(a)
						local cosA = math.cos(aRad)
						if cosA > 0.1 then
							local tof = dist / (v * cosA)
							local peak = (v * math.sin(aRad)) ^ 2 / (2 * math.max(g, 1))
							local powerPenalty = 0
							if v > 70 then powerPenalty = (v - 70) * 1.8 end
							if v > 80 then powerPenalty = powerPenalty + (v - 80) * 4 end
							local score = math.abs(peak - 9) * 1.1
								+ math.abs(v - 55) * 0.25
								+ powerPenalty
								+ tof * 1.5
								+ (peak > 16 and (peak - 16) * 3 or 0)
								+ (peak < 4 and (4 - peak) * 12 or 0)
							if score < bestScore then
								bestScore = score
								bestA = a
								bestV = v
							end
						end
					end
				end
			else
				-- Covered: floater OVER the DB (lob fit, not 95 laser)
				for a = 26, 55, 0.5 do
					local v = select(1, solveVForAngle(g, dist, dy, a))
					if v and v >= 32 and v <= 82 then
						local aRad = math.rad(a)
						local cosA = math.cos(aRad)
						local sinA = math.sin(aRad)
						if cosA > 0.08 then
							local tof = dist / (v * cosA)
							local peak = (v * sinA) ^ 2 / (2 * math.max(g, 1))
							local interceptPenalty = 0
							for step = 1, 10 do
								local t = tof * (step / 11)
								local horiz = flatDirU * (v * cosA * t)
								local ballY = start.Y + v * sinA * t - 0.5 * g * t * t
								local bx, bz = start.X + horiz.X, start.Z + horiz.Z
								for di = 1, #defenders do
									local dpos = defenders[di].Position
									local flatSep = Vector3.new(bx - dpos.X, 0, bz - dpos.Z).Magnitude
									if flatSep < 8 then
										local heightAbove = ballY - dpos.Y
										if heightAbove < DB_JUMP then
											interceptPenalty = interceptPenalty + (DB_JUMP - heightAbove) * (1.2 + (8 - flatSep) * 0.5)
										end
									end
								end
							end
							local powerPenalty = 0
							if v > 72 then powerPenalty = (v - 72) * 2 end
							if v > 85 then powerPenalty = powerPenalty + (v - 85) * 5 end
							local skyPenalty = peak > 20 and (peak - 20) * 4 or 0
							local lowPenalty = peak < 7 and (7 - peak) * 10 or 0
							local score = interceptPenalty * 5
								+ skyPenalty
								+ lowPenalty
								+ powerPenalty
								+ math.abs(v - 58) * 0.2
								+ math.abs(peak - 12) * 0.8
								+ tof * 0.8
							if score < bestScore then
								bestScore = score
								bestA = a
								bestV = v
							end
						end
					end
				end
			end

			angleDeg = bestA
			power = bestV or power
			-- floaters only — hard cap, never 95
			if power > 82 then power = 82 end
			if power < 28 then power = 28 end
		else
			angleDeg = baselineAngle
			power = baselinePower
			if QB.Power95 then
				power = 95
				if QB.AutoAngle then
					local bestA, bestScore = angleDeg, math.huge
					for a = 5, 75, 0.5 do
						local v = select(1, solveVForAngle(g, dist, dy, a))
						if v then
							local score = math.abs(v - 95)
							if score < bestScore then
								bestScore = score
								bestA = a
							end
						end
					end
					angleDeg = bestA
				end
			end
		end

		power = clamp(power, QB.MinPower, QB.MaxPower)
		angleDeg = clamp(angleDeg, QB.MinAngle or 1, QB.MaxAngle or 89)

		local angleRad = math.rad(angleDeg)
		local flatDir = flat.Unit
		local direction = (flatDir * math.cos(angleRad) + Vector3.new(0, math.sin(angleRad), 0)).Unit
		local speed = power
		local velocity = direction * speed
		local tof = dist / math.max(speed * math.cos(angleRad), 1)

		-- baseline velocity for dotted adjustment line
		local bAngleRad = math.rad(baselineAngle)
		local bDir = (flatDir * math.cos(bAngleRad) + Vector3.new(0, math.sin(bAngleRad), 0)).Unit
		local bPower = clamp(baselinePower, QB.MinPower, QB.MaxPower)
		local baselineVel = bDir * bPower
		local baselineTof = dist / math.max(bPower * math.cos(bAngleRad), 1)

		QB._lastBaselineVel = baselineVel
		QB._lastBaselineTof = baselineTof

		return velocity, direction, power, tof, angleDeg
	end

	function QB.getAimTarget()
		-- prefer who mouse is aiming at (ray), then closest on-screen teammate
		local cam = workspace.CurrentCamera
		if not cam or not HumanoidRootPart then return nil end
		local mouse = LocalPlayer:GetMouse()
		local ray = cam:ScreenPointToRay(mouse.X, mouse.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { Char }
		params.IgnoreWater = true
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
		if hit and hit.Instance then
			local model = hit.Instance:FindFirstAncestorOfClass("Model")
			if model then
				local plr = Players:GetPlayerFromCharacter(model)
				if plr and plr ~= LocalPlayer then
					if isPracticeMode() or isTeammate(plr) then
						return plr
					end
				elseif model:FindFirstChild("Humanoid") and model:FindFirstChild("HumanoidRootPart") then
					if not Players:GetPlayerFromCharacter(model) then
						return model -- practice bot
					end
				end
			end
		end
		-- fallback: teammate closest to mouse screen position
		local best, bestDist = nil, math.huge
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and (isPracticeMode() or isTeammate(plr)) then
				local hrp = ResolveHRP(plr)
				if hrp then
					local sp, onScreen = cam:WorldToViewportPoint(hrp.Position)
					if onScreen then
						local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
						if d < bestDist then
							bestDist = d
							best = plr
						end
					end
				end
			end
		end
		if isPracticeMode() then
			for _, obj in ipairs(workspace:GetDescendants()) do
				if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
					if not Players:GetPlayerFromCharacter(obj) then
						local sp, onScreen = cam:WorldToViewportPoint(obj.HumanoidRootPart.Position)
						if onScreen then
							local d = (Vector2.new(sp.X, sp.Y) - Vector2.new(mouse.X, mouse.Y)).Magnitude
							if d < bestDist then
								bestDist = d
								best = obj
							end
						end
					end
				end
			end
		end
		return best
	end

	function QB.getNearestWR()
		return QB.getAimTarget()
	end

	function QB.updateHighlight(target, danger)
		if not target then
			if QB.currentHighlight then QB.currentHighlight.Enabled = false end
			return
		end
		local accent = (Library and Library.AccentColor) or Color3.fromRGB(0, 200, 255)
		if not QB.currentHighlight or not QB.currentHighlight.Parent then
			local hl = Instance.new("Highlight")
			hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
			hl.Parent = workspace
			QB.currentHighlight = hl
			table.insert(QB.Visuals, hl)
		end
		local hrp = ResolveHRP(target)
		if not hrp then QB.currentHighlight.Enabled = false return end
		local model = hrp:FindFirstAncestorOfClass("Model")
		if not model then QB.currentHighlight.Enabled = false return end
		QB.currentHighlight.Adornee = model
		QB.currentHighlight.FillColor = accent
		QB.currentHighlight.OutlineColor = accent
		QB.currentHighlight.FillTransparency = 0.75
		QB.currentHighlight.OutlineTransparency = 0.55
		QB.currentHighlight.Enabled = true
	end

	function QB.UpdateInterception(landingPos, tof, receiver)
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer and (not receiver or plr ~= receiver) then
				if isPracticeMode() or not isTeammate(plr) then
					local ch = plr.Character
					local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
					local hum = ch and ch:FindFirstChildOfClass("Humanoid")
					if hrp and hum then
						local dist = (hrp.Position - landingPos).Magnitude
						local speed = math.max(hum.WalkSpeed, 1)
						local eta = dist / speed - 0.31
						if eta <= (tof or 0) or dist < 3 then
							return "YES"
						end
					end
				end
			end
		end
		return "NO"
	end

	local function throwremote(RemoteEvent, start, trueEnd, power)
		RemoteEvent:FireServer(
			"Clicked",
			vector.create(start.X, start.Y, start.Z),
			vector.create(trueEnd.X, trueEnd.Y, trueEnd.Z),
			power,
			1
		)
	end

	local function throwfb()
		if not QB.state then return end
		if not isPracticeMode() then
			local statusFlag = ReplicatedStorage:FindFirstChild("Flags") and ReplicatedStorage.Flags:FindFirstChild("Status")
			if not statusFlag or statusFlag.Value ~= "InPlay" then return end
		end
		local Football = Char and Char:FindFirstChildOfClass("Tool")
		local targetPlayer = QB.ClosestPlr
		local targetHrp = ResolveHRP(targetPlayer)
		if not (Football and targetHrp) then return end
		if not isPracticeMode() and targetPlayer:IsA("Player") and not isTeammate(targetPlayer) then return end
		if not OOB_INITIALIZED then initializeOOBParts() end

		local start = Char.Head.Position
		local throwType = QB.CurrentThrowType
		local _, _, _, rawTOF = QB.CalculateOptimalThrow(start, targetHrp.Position, targetHrp.Velocity, QB.FF2Grav, targetPlayer)
		local velocity = targetHrp.Velocity
		local flatVel = Vector3.new(velocity.X, 0, velocity.Z)
		local moving = flatVel.Magnitude > 1.5
		local effectiveVelocity = moving and velocity or Vector3.zero
		local dir = moving and flatVel.Unit or Vector3.zero
		local timeComp = rawTOF + (QB.AdvancedLead and (GetPing() / 1000 + (1 / GetFPS())) or 0)
		local basePredicted = targetHrp.Position + effectiveVelocity * timeComp
		local tt = QB.ThrowTypes[throwType]
		local leadDist = moving and (tt and tt.Lead or 0) or (tt and tt.Lead or 0) * 0.2
		local route = CalculateRouteofPlayer(targetPlayer)
		local yOffset = QB.MasterLeads.Heights.HeadPlusTwo
		if not moving then
			yOffset = QB.MasterLeads.Heights.Chest
		elseif throwType == "Bullet" and (route == "Slant" or route == "Comeback") then
			yOffset = QB.MasterLeads.Heights.Chest
		end
		-- SmartFIT: high-ball catch point (above DB jump tips)
		-- only raise catch point when SmartFIT sees coverage
		if QB.SmartFIT and QB._smartCovered then
			yOffset = math.max(yOffset, QB.MasterLeads.Heights.HeadPlusTwo) + 2.0
		end
		local finalPredicted = basePredicted + dir * leadDist + Vector3.new(0, yOffset, 0)
		if QB.AntiOOB then
			finalPredicted = ClampPositionToInBounds(finalPredicted)
		end
		local velocity_final, direction, power, tof, angle = QB.CalculateOptimalThrow(start, finalPredicted, effectiveVelocity, QB.FF2Grav, targetPlayer)
		QB.ThrowingTab.Direction = direction
		local trueEnd = start + direction * 10000
		local RemoteEvent = Football:FindFirstChild("Handle") and Football.Handle:FindFirstChild("RemoteEvent")
		if RemoteEvent then
			throwremote(RemoteEvent, start, trueEnd, power)
		end
		-- always show post-throw lines (residual + SmartFIT dotted) after a throw attempt
		pcall(showPostThrowResidual)
	end

	local function setupAnimationThrow(character)
		local humanoid = character:WaitForChild("Humanoid")
		table.insert(QB.Connections, humanoid.AnimationPlayed:Connect(function(zz)
			pcall(function()
				if zz.Animation == ReplicatedStorage.Animations.Throw then
					task.wait(0.12)
					throwfb()
				end
			end)
		end))
	end
	if Char then setupAnimationThrow(Char) end
	table.insert(QB.Connections, LocalPlayer.CharacterAdded:Connect(function(c)
		Char = c
		HumanoidRootPart = c:WaitForChild("HumanoidRootPart")
		setupAnimationThrow(c)
	end))

	-- Cards HUD (Methane watermark-style bar + accent shimmer)
	do
		local Theme = (Library and Library.Theme) or {
			Background = Color3.fromRGB(16, 17, 20),
			Outline = Color3.fromRGB(36, 38, 45),
			Border = Color3.fromRGB(7, 8, 10),
			Accent = Color3.fromRGB(152, 188, 255),
			Text = Color3.fromRGB(180, 180, 180),
			["Light Border"] = Color3.fromRGB(12, 8, 12),
		}
		local function getAccent()
			return (Library and Library.AccentColor) or Theme.Accent
		end

		local ScreenGui = Instance.new("ScreenGui")
		ScreenGui.Name = "MethaneQBCards"
		ScreenGui.DisplayOrder = 100
		ScreenGui.ResetOnSpawn = false
		ScreenGui.IgnoreGuiInset = true
		ScreenGui.Parent = hiddenUI
		Shared.ScreenGui = ScreenGui
		table.insert(QB.Visuals, ScreenGui)

		local bar = Instance.new("Frame")
		bar.Name = "QBBar"
		bar.AnchorPoint = Vector2.new(0.5, 1)
		bar.Position = UDim2.new(0.5, 0, 1, -72)
		bar.Size = UDim2.new(0, 480, 0, 36)
		bar.BackgroundColor3 = Theme.Background
		bar.BorderSizePixel = 0
		bar.ClipsDescendants = false
		bar.Active = true
		bar.Parent = ScreenGui
		QB.InfoFrame = bar

		-- drag target HUD (works anytime, especially with menu open)
		do
			local dragging = false
			local dragStart = nil
			local startPos = nil
			bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					dragStart = input.Position
					startPos = bar.Position
					input.Changed:Connect(function()
						if input.UserInputState == Enum.UserInputState.End then
							dragging = false
						end
					end)
				end
			end)
			game:GetService("UserInputService").InputChanged:Connect(function(input)
				if not dragging then return end
				if input.UserInputType == Enum.UserInputType.MouseMovement
					or input.UserInputType == Enum.UserInputType.Touch then
					local delta = input.Position - dragStart
					bar.Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					)
				end
			end)
		end

		-- outline stroke (outer-ish)
		local strokeOutline = Instance.new("UIStroke")
		strokeOutline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		strokeOutline.LineJoinMode = Enum.LineJoinMode.Miter
		strokeOutline.Color = Theme.Outline
		strokeOutline.Thickness = 1
		strokeOutline.Parent = bar

		-- border stroke (dark inset feel)
		local strokeBorder = Instance.new("UIStroke")
		strokeBorder.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		strokeBorder.LineJoinMode = Enum.LineJoinMode.Miter
		strokeBorder.Color = Theme.Border
		strokeBorder.Thickness = 1
		strokeBorder.BorderOffset = UDim.new(0, 1)
		strokeBorder.Parent = bar

		-- dark liner under accent
		local darkLiner = Instance.new("Frame")
		darkLiner.Name = "DarkLiner"
		darkLiner.Position = UDim2.new(0, 0, 0, 1)
		darkLiner.Size = UDim2.new(1, 0, 0, 1)
		darkLiner.BorderSizePixel = 0
		darkLiner.BackgroundColor3 = Theme["Light Border"]
		darkLiner.ZIndex = 3
		darkLiner.Parent = bar

		-- accent liner (top) + flowing gradient like watermark
		local accentLiner = Instance.new("Frame")
		accentLiner.Name = "AccentLiner"
		accentLiner.Position = UDim2.new(0, 0, 0, 0)
		accentLiner.Size = UDim2.new(1, 0, 0, 1)
		accentLiner.BorderSizePixel = 0
		accentLiner.BackgroundColor3 = getAccent()
		accentLiner.ZIndex = 4
		accentLiner.Parent = bar

		local accentGrad = Instance.new("UIGradient")
		accentGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.5, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		accentGrad.Offset = Vector2.new(0, 0)
		accentGrad.Parent = accentLiner

		-- content row
		local content = Instance.new("Frame")
		content.Name = "Content"
		content.BackgroundTransparency = 1
		content.Position = UDim2.new(0, 0, 0, 2)
		content.Size = UDim2.new(1, 0, 1, -2)
		content.Parent = bar

		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.SortOrder = Enum.SortOrder.LayoutOrder
		layout.Padding = UDim.new(0, 0)
		layout.Parent = content

		QB.Labels = {}

		local COLS = {
			{ key = "Player", label = "Target", width = 130 },
			{ key = "Angle", label = "Angle", width = 70 },
			{ key = "Power", label = "Power", width = 70 },
			{ key = "Type", label = "Mode", width = 80 },
			{ key = "OOB", label = "OOB", width = 70 },
		}

		for i, col in ipairs(COLS) do
			if i > 1 then
				local sep = Instance.new("Frame")
				sep.BackgroundTransparency = 1
				sep.Size = UDim2.new(0, 10, 1, 0)
				sep.LayoutOrder = (i - 1) * 2
				sep.Parent = content
				local line = Instance.new("Frame")
				line.AnchorPoint = Vector2.new(0.5, 0.5)
				line.Position = UDim2.new(0.5, 0, 0.5, 0)
				line.Size = UDim2.new(0, 1, 0, 20)
				line.BackgroundColor3 = Theme.Outline
				line.BorderSizePixel = 0
				line.Parent = sep
			end

			local cell = Instance.new("Frame")
			cell.BackgroundTransparency = 1
			cell.Size = UDim2.new(0, col.width, 1, 0)
			cell.LayoutOrder = i * 2 - 1
			cell.Parent = content

			local value = Instance.new("TextLabel")
			value.Name = "Value"
			value.BackgroundTransparency = 1
			value.Size = UDim2.new(1, 0, 0, 16)
			value.Position = UDim2.new(0, 0, 0, 4)
			value.Font = Enum.Font.Code
			value.TextSize = 13
			value.TextColor3 = getAccent()
			value.Text = "--"
			value.TextXAlignment = Enum.TextXAlignment.Center
			value.TextYAlignment = Enum.TextYAlignment.Center
			value.TextTruncate = Enum.TextTruncate.AtEnd
			value.Parent = cell

			local sub = Instance.new("TextLabel")
			sub.Name = "Sub"
			sub.BackgroundTransparency = 1
			sub.Size = UDim2.new(1, 0, 0, 12)
			sub.Position = UDim2.new(0, 0, 0, 20)
			sub.Font = Enum.Font.Code
			sub.TextSize = 10
			sub.TextColor3 = Theme.Text
			sub.Text = col.label
			sub.TextXAlignment = Enum.TextXAlignment.Center
			sub.TextYAlignment = Enum.TextYAlignment.Center
			sub.Parent = cell

			QB.Labels[col.key] = value
		end

		-- shimmer + accent sync (same timing as watermark ~1.2s cycle)
		local shimmerPhase = 0
		local lastShimmer = tick()
		task.spawn(function()
			while bar and bar.Parent do
				local now = tick()
				if now - lastShimmer >= (1 / 30) then
					shimmerPhase = (shimmerPhase + (now - lastShimmer) * (1 / 1.2)) % 1
					lastShimmer = now
					accentGrad.Offset = Vector2.new((shimmerPhase * 2) - 1, 0)
					local a = getAccent()
					accentLiner.BackgroundColor3 = a
					for _, lbl in pairs(QB.Labels) do
						if lbl and lbl.Parent then
							lbl.TextColor3 = a
						end
					end
				end
				task.wait()
			end
		end)
	end

	local lastTextValues = {}
	local function setLabelText(labelName, text)
		if lastTextValues[labelName] == text then return end
		lastTextValues[labelName] = text
		if QB.Labels[labelName] then QB.Labels[labelName].Text = text end
	end

	local function cycleThrowType(dir)
		ThrowIndex = ThrowIndex + dir
		if ThrowIndex < 1 then ThrowIndex = #ThrowOrder
		elseif ThrowIndex > #ThrowOrder then ThrowIndex = 1 end
		QB.CurrentThrowType = ThrowOrder[ThrowIndex]
	end

		local function resolveKey(flag)
		if not flag then return nil end
		local v = flag.Value
		if typeof(v) == "EnumItem" then return v end
		if type(v) == "table" and v.Value ~= nil then
			return resolveKey(v)
		end
		if type(v) == "string" then
			local name = tostring(v):gsub("Enum.KeyCode.", ""):gsub("KeyCode%.", "")
			local ok, item = pcall(function() return Enum.KeyCode[name] end)
			if ok and item then return item end
		end
		return nil
	end

	local function keyMatches(input, flag)
		local k = resolveKey(flag)
		return k ~= nil and input.KeyCode == k
	end

	local function setThrowMode(name)
		for idx, n in ipairs(ThrowOrder) do
			if n == name then
				ThrowIndex = idx
				QB.CurrentThrowType = name
				return true
			end
		end
		return false
	end

	table.insert(QB.Connections, UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.UserInputType == Enum.UserInputType.MouseButton3 then
			if QB.TargetLocked then
				QB.TargetLocked = false
				QB.LockedTarget = nil
			else
				local cand = QB.getAimTarget and QB.getAimTarget() or QB.getNearestWR()
				if cand then
					QB.TargetLocked = true
					QB.LockedTarget = cand
				end
			end
			return
		end
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end

		-- throw modes from keypickers
		if keyMatches(input, cycleModeKeybind) then
			cycleThrowType(1)
			return
		elseif keyMatches(input, modeStillKey) then
			setThrowMode("Still")
			return
		elseif keyMatches(input, modeBulletKey) then
			setThrowMode("Bullet")
			return
		elseif keyMatches(input, modeDimeKey) then
			setThrowMode("Dime")
			return
		elseif keyMatches(input, modeFadeKey) then
			setThrowMode("Fade")
			return
		elseif keyMatches(input, modeDiveKey) then
			setThrowMode("Dive")
			return
		elseif keyMatches(input, modeMagKey) then
			setThrowMode("Mag")
			return
		elseif keyMatches(input, modeJumpKey) then
			setThrowMode("Jump")
			return
		end

		if keyMatches(input, toggleKeybind) then
			enableQbAimbot:Set(not enableQbAimbot.Value)
		elseif keyMatches(input, angleUpKeybind) then
			-- works even with auto on: temporarily adjusts manual + disables auto? keep manual always
			manualAngle:Set(clamp((manualAngle.Value or 30) + 5, 1, 90))
			if autoAngle and autoAngle.Set then autoAngle:Set(false) end
		elseif keyMatches(input, angleDownKeybind) then
			manualAngle:Set(clamp((manualAngle.Value or 30) - 5, 1, 90))
			if autoAngle and autoAngle.Set then autoAngle:Set(false) end
		elseif keyMatches(input, powerUpKeybind) then
			manualPower:Set(clamp((manualPower.Value or 60) + 5, 1, 95))
			if autoPower and autoPower.Set then autoPower:Set(false) end
		elseif keyMatches(input, powerDownKeybind) then
			manualPower:Set(clamp((manualPower.Value or 60) - 5, 1, 95))
			if autoPower and autoPower.Set then autoPower:Set(false) end
		elseif keyMatches(input, antiOOBKeybind) then
			antiOOB:Set(not antiOOB.Value)
		elseif keyMatches(input, lockKeybind) then
			if QB.TargetLocked then
				QB.TargetLocked = false
				QB.LockedTarget = nil
			else
				local cand = QB.getAimTarget and QB.getAimTarget() or QB.getNearestWR()
				if cand then
					QB.TargetLocked = true
					QB.LockedTarget = cand
				end
			end
		end
	end))

	table.insert(QB.Connections, RunService.Heartbeat:Connect(function()
		syncFromUI()
		if not Char or not Char.Parent then return end
		HumanoidRootPart = Char:FindFirstChild("HumanoidRootPart") or HumanoidRootPart

		local targetPlayer
		if QB.TargetLocked and ResolveHRP(QB.LockedTarget) then
			targetPlayer = QB.LockedTarget
		else
			targetPlayer = QB.getNearestWR()
			QB.TargetLocked = false
			QB.LockedTarget = nil
		end
		QB.ClosestPlr = targetPlayer

		local hasFootball = Char:FindFirstChildOfClass("Tool") ~= nil
		if QB.InfoFrame and QB.InfoFrame.Parent then
			local sg = QB.InfoFrame.Parent
			if sg:IsA("ScreenGui") then
				local masterOn = enableQbAimbot and enableQbAimbot.Value == true
				sg.Enabled = masterOn and hasFootball and not (hideCards.Value == true)
			end
		end

		if targetPlayer and hasFootball and QB.state then
			local targetHrp = ResolveHRP(targetPlayer)
			local shouldAim = isPracticeMode() or (targetPlayer:IsA("Player") and isTeammate(targetPlayer)) or (not targetPlayer:IsA("Player"))
			if targetHrp and shouldAim then
				QB.updateHighlight(targetPlayer, false)
				local start = Char.Head and Char.Head.Position or HumanoidRootPart.Position
				local velocity = targetHrp.Velocity
				local flatVel = Vector3.new(velocity.X, 0, velocity.Z)
				local moving = flatVel.Magnitude > 1.5
				local effectiveVelocity = moving and velocity or Vector3.zero
				local dir = moving and flatVel.Unit or Vector3.zero
				local _, _, _, rawTOF = QB.CalculateOptimalThrow(start, targetHrp.Position, effectiveVelocity, QB.FF2Grav, targetPlayer)
				local timeComp = rawTOF + (QB.AdvancedLead and (GetPing() / 1000 + 1 / GetFPS()) or 0)
				local tt = QB.ThrowTypes[QB.CurrentThrowType]
				local leadDist = moving and (tt and tt.Lead or 0) or 0
				local route = CalculateRouteofPlayer(targetPlayer)
				local yOffset = QB.MasterLeads.Heights.HeadPlusTwo
				if not moving then yOffset = QB.MasterLeads.Heights.Chest
				elseif QB.CurrentThrowType == "Bullet" and (route == "Slant" or route == "Comeback") then
					yOffset = QB.MasterLeads.Heights.Chest
				end
				if QB.SmartFIT and QB._smartCovered then
					yOffset = math.max(yOffset, QB.MasterLeads.Heights.HeadPlusTwo) + 2.0
				end
				local finalPredicted = targetHrp.Position + effectiveVelocity * timeComp + dir * leadDist + Vector3.new(0, yOffset, 0)
				if QB.AntiOOB then finalPredicted = ClampPositionToInBounds(finalPredicted) end
				if BaseMarker then BaseMarker.Position = finalPredicted end
				if QB.LandingPart then QB.LandingPart.Position = finalPredicted end
				local velocity_final, direction, power, tof, angle = QB.CalculateOptimalThrow(start, finalPredicted, effectiveVelocity, QB.FF2Grav, targetPlayer)
				local startAdjusted = start + direction * 3
				QB.createTrajectoryVisualization(startAdjusted, velocity_final, QB.FF2Grav, tof, QB._lastBaselineVel, QB._lastBaselineTof)
				local intercept = QB.UpdateInterception(finalPredicted, tof, targetPlayer)
				QB.updateHighlight(targetPlayer, intercept == "YES")
				local name = targetPlayer.Name or "Bot"
				if #name > 12 then name = name:sub(1, 10) .. ".." end
				setLabelText("Player", name)
				setLabelText("Power", tostring(math.floor(power)))
				setLabelText("Angle", tostring(math.floor(angle)) .. "°")
				setLabelText("Type", QB.CurrentThrowType or "None")
				if not OOB_INITIALIZED then initializeOOBParts() end
				setLabelText("OOB", IsPositionOOB(finalPredicted) and "OOB" or "SAFE")
			else
				QB.updateHighlight(nil)
				hideLandingMarkers()
			end
		else
			QB.updateHighlight(nil)
			hideLandingMarkers()
			setLabelText("Player", targetPlayer and (targetPlayer.Name or "Bot") or "None")
			setLabelText("Type", QB.CurrentThrowType or "None")
			setLabelText("Power", QB.state and "--" or tostring(math.floor(QB.ManualPower)))
			setLabelText("Angle", QB.state and "--" or tostring(math.floor(QB.ManualAngleDeg)) .. "°")
			setLabelText("OOB", "--")
		end
	end))

	getgenv().MethaneQB = QB
	getgenv().QB_Aimbot_Cleanup = function()
		for _, c in ipairs(QB.Connections) do pcall(function() c:Disconnect() end) end
		for _, v in ipairs(QB.Visuals) do pcall(function() if v and v.Parent then v:Destroy() end end) end
	end
end

-- Shared services for remaining Akena feature logic
local players = game:GetService("Players")
local player = players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local tweenService = game:GetService("TweenService")
local camera = workspace.CurrentCamera
local mouse = player and player:GetMouse()
local isPractice = (game.PlaceId == 81310542478972 or game.PlaceId == 8206123457)

CatchingTab:UseSection("Mag Scripts", 1)
footballMagnets = CatchingTab:CreateToggle({
    Name = 'Enable Mags',
    Default = false,
    Tip = 'Catch the ball from farther.',
})

showCatchHitbox = CatchingTab:CreateToggle({
    Name = 'Show Mags',
    Default = false,
    Tip = 'Displays the football magnets catch radius.',
})

magMethod = CatchingTab:CreateDropdown({
    Name = 'Mag Method',
    Options = {'Normal', 'CFrame'},
    Default = 'Normal',
    Tip = 'e',
})

magsType = CatchingTab:CreateDropdown({
    Name = 'Mag Type',
    Options = {'Custom', 'Blatant', 'League', 'Legit'},
    Default = 'Custom',
    Tip = 'Legit=half, League=/1.4, Blatant=x1.5, Custom=slider.',
})

magnetsRadius = CatchingTab:CreateSlider({
    Name = 'Mag Reach',
    Min = 0,
    Max = 25,
    Default = 13.5,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Base catch distance before type modifiers.',
})

magnetsDelay = CatchingTab:CreateSlider({
    Name = 'Mag Delay',
    Min = 0,
    Max = 1,
    Default = 0,
    Increment = 0.01,
    Suffix = 's',
    Tip = 'Tween/delay before Akena Normal mags fire.',
})

local player = game:GetService('Players').LocalPlayer
local tweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

-- Akena-style radius part (accent color)
local part = Instance.new('Part')
part.Name = 'MethaneMagRadius'
part.Color = (Library and Library.AccentColor) or Color3.fromRGB(152, 188, 255)
part.Shape = Enum.PartType.Ball
part.Material = Enum.Material.ForceField
part.CastShadow = false
part.Anchored = true
part.CanCollide = false
part.CanQuery = false
part.CanTouch = false
part.Transparency = 0.25
part.Size = Vector3.new(1, 1, 1)

local function getAccent()
	return (Library and Library.AccentColor) or Color3.fromRGB(152, 188, 255)
end

local function findClosestBall()
	local character = player.Character
	if not character then return end
	local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
	if not humanoidRootPart then return end
	local dist = math.huge
	local ball = nil

	local function checkPart(v)
		if not v:IsA('BasePart') then return end
		if v.Name ~= 'Football' then return end
		-- skip parts that are inside the local character (held ball)
		if v:IsDescendantOf(character) then return end
		local distance = (v.Position - humanoidRootPart.Position).Magnitude
		if distance < dist then
			dist = distance
			ball = v
		end
	end

	for _, v in next, workspace:GetChildren() do
		-- Direct BasePart named Football
		checkPart(v)
		-- Football inside a Model (FF3 wraps the ball in a Model on some servers)
		if v:IsA('Model') and v.Name == 'Football' then
			for _, p in next, v:GetChildren() do
				checkPart(p)
			end
		end
	end

	return ball
end

local function selectedRange()
	local range = tonumber(magnetsRadius.Value) or 0
	local mode = tostring(magsType.Value or 'Custom'):lower()
	if mode == 'legit' then
		return range / 2
	elseif mode == 'league' then
		return range / 1.4
	elseif mode == 'blatant' then
		return range * 1.5
	end
	return range
end

local function getCatchParts(character)
	local parts = {}
	for _, v in next, character:GetChildren() do
		if v:IsA('BasePart') and string.find(string.lower(v.Name), 'catch', 1, true) then
			parts[#parts + 1] = v
		end
	end
	return parts
end

-- Akena Normal + CFrame loop (always runs so hitbox can show)
task.spawn(function()
	while true do
		task.wait()

		local character = player.Character
		if not character then
			part.Parent = nil
			continue
		end

		local humanoid = character:FindFirstChildOfClass('Humanoid')
		if not humanoid then
			part.Parent = nil
			continue
		end

		local ball = findClosestBall()
		local range = selectedRange()

		-- Hitbox (accent) — show whenever radius toggle is on and we have a ball + range
		if footballMagnets.Value and showCatchHitbox.Value and ball and range > 0 then
			part.Size = Vector3.new(range, range, range)
			part.CFrame = CFrame.new(ball.Position)
			part.Material = Enum.Material.ForceField
			part.Color = getAccent()
			part.Transparency = 0.25
			part.Parent = workspace.Terrain
		else
			part.Parent = nil
		end

		if not footballMagnets.Value then continue end
		if not ball then continue end
		if range <= 0 then continue end

		local method = tostring(magMethod.Value or 'Normal')
		local catchParts = getCatchParts(character)
		if #catchParts == 0 then continue end

		if method == 'CFrame' then
			-- Safer: do NOT set ball.CFrame (server-owned). Pull catch parts slightly + touch only.
			local closestPart = nil
			local closestDist = math.huge
			for _, cp in ipairs(catchParts) do
				local d = (ball.Position - cp.Position).Magnitude
				if d < closestDist then
					closestDist = d
					closestPart = cp
				end
			end

			if closestPart and closestDist < range then
				pcall(function()
					-- micro-offset catch part toward ball (not ball toward player)
					if closestDist > 0.5 then
						local dir = (ball.Position - closestPart.Position)
						if dir.Magnitude > 0 then
							closestPart.CFrame = closestPart.CFrame + dir.Unit * math.min(0.35, closestDist * 0.25)
						end
					end
				end)
				pcall(function()
					for _, cp in ipairs(catchParts) do
						firetouchinterest(cp, ball, 0)
						firetouchinterest(cp, ball, 1)
					end
				end)
			end
		else
			-- Normal: move catch hitbox to ball position, fire touch on all parts
			local delay = tonumber(magnetsDelay.Value) or 0
			local hitParts = {}
			for _, v in next, catchParts do
				local distance = (ball.Position - v.Position).Magnitude
				if distance < range then
					hitParts[#hitParts + 1] = v
				end
			end

			if #hitParts > 0 then
				for _, v in ipairs(hitParts) do
					pcall(function()
						if delay > 0 then
							tweenService:Create(v, TweenInfo.new(delay), { Position = ball.Position }):Play()
						else
							v.Position = ball.Position
						end
					end)
				end
				-- Fire all catch parts after position update
				pcall(function()
					for _, v in ipairs(catchParts) do
						firetouchinterest(v, ball, 0)
						firetouchinterest(v, ball, 1)
					end
				end)
			end
		end
	end
end)

CatchingTab:UseSection("Mag Enhancer", 1)
magEnhancer = CatchingTab:CreateToggle({
    Name = 'ME Enable',
    Default = false,
    Tip = 'Enhances catches on footballs already within range.',
})

magEnhancerRadius = CatchingTab:CreateSlider({
    Name = 'Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum distance the enhancer can assist catches.',
})

magEnhancerMaxAngle = CatchingTab:CreateSlider({
    Name = 'Angle',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum catch angle the enhancer can assist.',
})

task.spawn(function()
    while true do
        task.wait(0.1)

        if not magEnhancer.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local verticalDistance = ball.Position.Y - humanoidRootPart.Position.Y

        if verticalDistance > magEnhancerMaxAngle.Value then
            continue
        end

        local lookVector = humanoidRootPart.CFrame.LookVector
        local direction = (ball.Position - humanoidRootPart.Position).Unit
        local dot = lookVector:Dot(direction)

        local allCatchParts = {}
        local triggered = false
        for _, v in next, character:GetChildren() do
            if not v:IsA('BasePart') then continue end
            if not v.Name:lower():find('catch') then continue end
            allCatchParts[#allCatchParts + 1] = v

            local distance = (ball.Position - v.Position).Magnitude
            if dot > 0 and distance <= magEnhancerRadius.Value then
                pcall(function() v.Position = ball.Position end)
                triggered = true
            end
        end
        -- Fire all catch parts once if any were in range
        if triggered then
            pcall(function()
                for _, v in ipairs(allCatchParts) do
                    firetouchinterest(v, ball, 0)
                    firetouchinterest(v, ball, 1)
                end
            end)
        end
    end
end)
    
CatchingTab:UseSection("Pull Vector", 2)
pullVector = CatchingTab:CreateToggle({
    Name = 'Enable PV',
    Default = false,
    Tip = 'Pulls nearby footballs toward your catch position.',
})

pullVectorRadius = CatchingTab:CreateSlider({
    Name = 'Distance',
    Min = 0,
    Max = 45,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum distance footballs can be pulled from.',
})

pullVectorPower = CatchingTab:CreateSlider({
    Name = 'Strength',
    Min = 0,
    Max = 5,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Controls how strongly footballs are pulled toward you.',
})

task.spawn(function()
    while true do
        task.wait()

        if not pullVector.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local distance = (ball.Position - humanoidRootPart.Position).Magnitude
        if distance > pullVectorRadius.Value then continue end

        local direction = (ball.Position - humanoidRootPart.Position).Unit
        humanoidRootPart.AssemblyLinearVelocity = direction * (pullVectorPower.Value * 25)
    end
end)

CatchingTab:UseSection("Arm Size", 2)
increaseArmSize = CatchingTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Increases arm size to improve catch reach.',
})

armSizeValue = CatchingTab:CreateSlider({
    Name = 'size',
    Min = 2,
    Max = 25,
    Default = 2,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the size applied to both arms.',
})

task.spawn(function()
    while true do
        task.wait()

        local character = player.Character
        if not character then continue end

        for _, v in next, character:GetChildren() do
            if not v:IsA('BasePart') then continue end
            if not v.Name:lower():find('t arm') then continue end

            v.Size = Vector3.new(v.Size.X, increaseArmSize.Value and armSizeValue.Value or 2, v.Size.Z)
        end
    end
end)
    

-- ═══════════════════════════════════════════════════════════
-- FF3 movement state (from ClientMain via CharacterSoundEvent)
-- Legitimate WalkSpeeds: mode1=14, mode2=17, mode3=20, QB=19.87
-- Never push horiz speed above current ClientMain WalkSpeed.
-- ═══════════════════════════════════════════════════════════
do
    local RS = game:GetService("ReplicatedStorage")
    getgenv()._FF3Move = getgenv()._FF3Move or {
        canMove = true,
        canChangeSpeed = true,
        mode = 3,
        lastWS = 20,
        _spoofJumpY = 50,
        _jumpUntil = 0,
    }
    local st = getgenv()._FF3Move
    task.spawn(function()
        local rem = RS:WaitForChild("Remotes", 15)
        if not rem then return end
        local ev = rem:WaitForChild("CharacterSoundEvent", 15)
        if not ev then return end
        ev.OnClientEvent:Connect(function(a, b, ...)
            if a ~= "ClientMain" then return end
            if b == "canMove" then
                st.canMove = true
            elseif b == "cantMove" then
                st.canMove = false
            elseif b == "canChangeSpeed" then
                st.canChangeSpeed = true
            elseif b == "cantChangeSpeed" then
                st.canChangeSpeed = false
            elseif b == "blockBegin" or b == "blockBegin2" or b == "blockBegin3" then
                st.canChangeSpeed = false
            elseif b == "blockEnd" or b == "blockEnd2" then
                st.canChangeSpeed = true
            end
        end)
    end)
end

PlayerTab:UseSection("Speed", 1)
customWalkSpeed = PlayerTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Overrides your character movement speed.',
})

walkSpeedValue = PlayerTab:CreateSlider({
    Name = 'amount',
    Min = 1,
    Max = 5,
    Default = 1,
    Increment = 1,
    Suffix = '',
    Tip = 'Boost 1-5 fills toward ClientMain WalkSpeed (14/17/20). Does NOT overspeed. CFrame = risky.',
})

walkspeedType = PlayerTab:CreateDropdown({
    Name = 'boost type',
    Options = {'Normal', 'CFrame'},
    Default = 'Normal',
    Tip = 'Normal = soft velocity assist (recommended). CFrame = higher detect risk.',
})

do
    local _RunService = game:GetService("RunService")
    local cfConn = nil

    local function startCFLoop()
        if cfConn then cfConn:Disconnect() end

        local _lastSpeedApply = 0
        cfConn = _RunService.Heartbeat:Connect(function(dt)
            if not customWalkSpeed.Value then return end

            local st = rawget(getgenv(), "_FF3Move")
            -- Respect ClientMain movement locks (block, cantMove, cantChangeSpeed)
            if st then
                if st.canMove == false or st.canChangeSpeed == false then return end
            end

            local character = player.Character
            if not character then return end

            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if not humanoid then return end
            if humanoid.PlatformStand then return end
            local assignedWS = humanoid.WalkSpeed
            if assignedWS <= 0 then return end

            local root = character:FindFirstChild("HumanoidRootPart")
            if not root then return end

            -- sanitize NaN (instant suspicious-movement flag)
            local vel = root.AssemblyLinearVelocity
            if vel.X ~= vel.X or vel.Y ~= vel.Y or vel.Z ~= vel.Z then
                root.AssemblyLinearVelocity = Vector3.zero
                return
            end

            local direction = Vector3.new(humanoid.MoveDirection.X, 0, humanoid.MoveDirection.Z)
            if direction.Magnitude <= 0.05 then return end

            local boost = math.clamp(tonumber(walkSpeedValue.Value) or 1, 1, 5)
            local isCF = walkspeedType.Value == "CFrame"

            -- ClientMain legit caps: 14 / 17 / 20 / 19.87 — NEVER exceed assigned WalkSpeed
            -- Soft boost only fills toward assignedWS (helps sticky movement), does not overspeed
            local maxAllowed = math.min(assignedWS, 20)
            -- tiny optional headroom only at boost 5 and only if assigned is full 20
            if boost >= 5 and assignedWS >= 19.5 then
                maxAllowed = math.min(assignedWS * 1.02, 20.2)
            end

            if not isCF then
                local now = tick()
                if (now - _lastSpeedApply) < 0.06 then return end
                _lastSpeedApply = now

                local horiz = Vector3.new(vel.X, 0, vel.Z)
                local curSpeed = horiz.Magnitude
                if curSpeed >= maxAllowed * 0.97 then return end

                local unit = direction.Unit
                local target = maxAllowed * (0.85 + (boost - 1) / 4 * 0.15) -- boost1=85% … boost5=100% of allowed
                target = math.min(target, maxAllowed)
                local blend = 0.25
                local desired = unit * target
                local newHoriz = horiz:Lerp(desired, blend)
                -- final clamp
                if newHoriz.Magnitude > maxAllowed then
                    newHoriz = newHoriz.Unit * maxAllowed
                end
                root.AssemblyLinearVelocity = Vector3.new(newHoriz.X, vel.Y, newHoriz.Z)
                return
            end

            -- CFrame mode remains high-risk; still hard-capped to assignedWS
            local state = humanoid:GetState()
            if state ~= Enum.HumanoidStateType.Running
                and state ~= Enum.HumanoidStateType.RunningNoPhysics then
                return
            end
            local cfSpeedSPS = math.min(maxAllowed * (0.7 + (boost - 1) / 4 * 0.25), maxAllowed)
            local step = direction.Unit * (cfSpeedSPS * math.min(dt, 1/30))
            if step.Magnitude < 1e-4 then return end
            root.CFrame = root.CFrame * CFrame.new(
                root.CFrame:VectorToObjectSpace(step)
            )
        end)
    end

    startCFLoop()
    player.CharacterAdded:Connect(function()
        task.wait(0.1)
        startCFLoop()
    end)
end

PlayerTab:UseSection("Jump", 2)
customJumpPower = PlayerTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Overrides your character jump power.',
})

jumpPowerValue = PlayerTab:CreateSlider({
    Name = 'value',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Jump Y velocity up to 70. Client reads are spoofed; very high jumps can still flag server movement.',
})

-- ConsHub-style jump: Humanoid.Jumping signal + ADD (power-50), not every-frame force
do
    local jumpSettings = { enabled = false, power = 50 }

    -- keep in sync with UI
    task.spawn(function()
        while true do
            task.wait(0.1)
            jumpSettings.enabled = customJumpPower.Value == true
            jumpSettings.power = math.clamp(tonumber(jumpPowerValue.Value) or 50, 50, 70)
        end
    end)

    local function onCharacterMovement(character)
        local humanoid = character:WaitForChild("Humanoid", 8)
        local root = character:WaitForChild("HumanoidRootPart", 8)
        if not humanoid or not root then return end

        humanoid.Jumping:Connect(function()
            if not jumpSettings.enabled then return end
            if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then return end
            task.wait(0.05)
            if not root.Parent then return end
            -- ADD delta over default ~50 (ConsHub). Never absolute force every frame.
            local extra = jumpSettings.power - 50
            if extra > 0 then
                root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + Vector3.new(0, extra, 0)
            end
        end)
    end

    if player.Character then
        task.spawn(onCharacterMovement, player.Character)
    end
    player.CharacterAdded:Connect(onCharacterMovement)
end

    
PlayerTab:UseSection("Angle Enhancer", 1)
angleEnhancer = PlayerTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'ConsHub style: flick shift-lock OFF then jump within Max jump time for boost.',
})

angleEnhancerIndicator = PlayerTab:CreateToggle({
    Name = 'Indicator',
    Default = false,
    Tip = 'Showsa notification when an angle boost is triggered.',
})
    
    autoFlip = PlayerTab:CreateToggle({
    Name = 'Auto Flip',
    Default = false,
    Tip = 'Automatically adjusts player orientation before landing.',
})

angleEnhanceBoost = PlayerTab:CreateSlider({
    Name = 'Angle boost',
    Min = 50,
    Max = 70,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the vertical velocity applied during angle boost.',
})

angleEnhanceWindow = PlayerTab:CreateSlider({
    Name = 'Max jump time',
    Min = 0.05,
    Max = 1,
    Default = 0.25,
    Increment = 0.05,
    Suffix = 's',
    Tip = 'How long after shift-lock OFF the boost still arms a jump.',
})
    
-- ConsHub angle enhancer 1:1
-- Arm boost by toggling shift-lock OFF, then jump within 0.2s
local angleTick = os.clock()
local shiftLockEnabled = false
local lastEnabled = false
local angleEnhancerPower = 50

-- keep power synced from UI slider
task.spawn(function()
    while true do
        task.wait(0.1)
        angleEnhancerPower = math.clamp(tonumber(angleEnhanceBoost.Value) or 50, 50, 70)
    end
end)

local function hookAngleCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    local hrp = character:WaitForChild("HumanoidRootPart", 8)
    if not humanoid or not hrp then return end

    humanoid.Jumping:Connect(function()
        if not angleEnhancer.Value then return end
        if humanoid:GetState() ~= Enum.HumanoidStateType.Jumping then return end
        local window = 0.25
        pcall(function()
            window = math.clamp(tonumber(angleEnhanceWindow.Value) or 0.25, 0.05, 1)
        end)
        if os.clock() - angleTick > window then return end
        task.wait(0.05)
        if not hrp.Parent then return end
        local extra = angleEnhancerPower - 50
        if extra > 0 then
            hrp.AssemblyLinearVelocity = hrp.AssemblyLinearVelocity + Vector3.new(0, extra, 0)
        end
        if angleEnhancerIndicator.Value then
            local hint = Instance.new("Hint")
            hint.Text = "Angled!"
            hint.Parent = workspace.Terrain
            task.delay(1.2, function()
                if hint and hint.Parent then hint:Destroy() end
            end)
        end
    end)
end

if player.Character then
    task.spawn(hookAngleCharacter, player.Character)
end
player.CharacterAdded:Connect(hookAngleCharacter)

pcall(function()
    userInputService:GetPropertyChangedSignal("MouseBehavior"):Connect(function()
        shiftLockEnabled = (userInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
    end)
    shiftLockEnabled = (userInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
end)

task.spawn(function()
    while true do
        task.wait()
        local character = player.Character
        if not character then continue end
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not hrp or not humanoid then continue end

        -- ConsHub: when shift-lock turns OFF, arm the next jump
        if not shiftLockEnabled and lastEnabled then
            angleTick = os.clock()
        end
        lastEnabled = shiftLockEnabled
    end
end)

local runtime, jumptime, hittime = 0, 0, 0
local arm, vLine, used, prevPs = false, nil, false, false
local seq = 0
local pack = nil

local xz = function(v: Vector3)
	local f = Vector3.new(v.X, 0, v.Z)
	return f.Magnitude > 0.001 and f.Unit or nil
end

local reset = function()
	if not pack then return end
	for _, o in next, { pack.spin, pack.ra, pack.pivot, pack.ha } do
		if o then o:Destroy() end
	end
	pack = nil
end

local flip = function(root: BasePart, head: BasePart)
	reset()

	local m = math.max(root.AssemblyMass, 1)

	local ha = Instance.new("Attachment")
	ha.Parent = head

	local pivot = Instance.new("AlignPosition")
	pivot.Mode = Enum.PositionAlignmentMode.OneAttachment
	pivot.Attachment0 = ha
	pivot.Position = head.Position + Vector3.new(0, 0.15, 0)
	pivot.MaxForce = 180000
	pivot.Responsiveness = 120
	pivot.RigidityEnabled = false
	pivot.ApplyAtCenterOfMass = false
	pivot.Parent = head

	local ra = Instance.new("Attachment")
	ra.Parent = root

	local spin = Instance.new("AngularVelocity")
	spin.Attachment0 = ra
	spin.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	spin.AngularVelocity = Vector3.new(-9, 0, 0)
	spin.MaxTorque = 50000
	spin.Parent = root

	root:ApplyAngularImpulse(root.CFrame.RightVector * (-16 * m))

	pack = { ha = ha, pivot = pivot, ra = ra, spin = spin }
end

task.spawn(function()
	while true do
		task.wait()
	    
	    if not autoFlip.Value then continue end
	    
		local char = player.Character
		if not char then
			reset()
			arm, vLine, used, prevPs = false, nil, false, false
			continue
		end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")

		if not hum or not hrp or not head then continue end

		local now = tick()

		if hum:GetState() == Enum.HumanoidStateType.Running then runtime = now end
		if hum:GetState() == Enum.HumanoidStateType.Jumping then jumptime = now end

		local ps = hum.PlatformStand
		if ps ~= prevPs then
			if ps then
				arm = (now - runtime <= 0.5) and (now - jumptime <= 0.7)
				vLine = xz(hrp.AssemblyLinearVelocity) or xz(hrp.CFrame.LookVector)
				used = false
			else
				arm, vLine, used = false, nil, false
				seq += 1
				reset()
			end
			prevPs = ps
		end

		if not ps or not arm or pack then continue end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char }

		local result = workspace:Raycast(head.Position, Vector3.new(0, -3, 0), params)
		local ground = result and result.Instance ~= nil

		if used or not ground or now - hittime < 0.12 then continue end

		local dist = result and (head.Position - result.Position).Magnitude or math.huge
		if dist > 1.6 then continue end

		local move = xz(hrp.AssemblyLinearVelocity) or vLine
		local face = xz(hrp.CFrame.LookVector)

		if not move or not face or face:Dot(move) < 0.78 then continue end

		hittime = now
		used = true
		seq += 1
		local k = seq

		flip(hrp, head)

		task.delay(0.24, function()
			if k == seq then
				reset()
			end
		end)
	end
end)



    
local boundaries = {}

if not isPractice then
    pcall(function()
        local models = workspace:FindFirstChild("Models")
        local bounds = models and models:FindFirstChild("Boundaries")
        if bounds then
            for i, v in next, bounds:GetChildren() do
                boundaries[#boundaries + 1] = v
            end
        end
    end)
end

PhysicsTab:UseSection("Exploits", 1)
antiBoundaries = PhysicsTab:CreateToggle({
    Name = 'Anti Bounds',
    Default = false,
    Tip = 'Prevents players from triggering out-of-bounds zones.',
    Callback = function(v)
        for i, b in next, boundaries do
            if b then
                b.Parent = (not v) and (workspace:FindFirstChild("Models") and workspace.Models:FindFirstChild("Boundaries")) or nil
            end
        end
    end
})
    
    antiBench = PhysicsTab:CreateToggle({
    Name = 'Anti Bench',
    Default = false,
    Tip = 'Prevents automatic benching.',
})

task.spawn(function()
    while true do
        task.wait()

        if not antiBench.Value then continue end

        local playerGui = player:FindFirstChild('PlayerGui')
        if not playerGui then continue end

        local benchButton = playerGui:FindFirstChild('Benched', true)
        if not benchButton then continue end

        if benchButton.BackgroundColor3 == Color3.fromRGB(120, 120, 120) then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'ToggleBench')
        end
    end
end)
--[[
local scrambleWall = workspace:FindFirstChild('ScrambleWall')

antiQbBoundaries = PhysicsTab:CreateToggle({
    Name = 'Anti QB Boundaries',
    Default = false,
    Tip = 'Disables invisible QB boundary walls.',
    Callback = function(v)
        if not scrambleWall then return end
        scrambleWall.Parent = v and nil or workspace
    end
})
    ]]
PhysicsTab:UseSection("Extra", 2)
antiJam = PhysicsTab:CreateToggle({
    Name = 'Anti Jam',
    Default = false,
    Tip = 'Reduces player collision while moving.',
})

antiJumpCooldown = PhysicsTab:CreateToggle({
    Name = 'No Jump Cooldown',
    Default = false,
    Tip = 'Removes the delay between jumps.',
})

antiFreeze = PhysicsTab:CreateToggle({
    Name = 'Anti Freeze',
    Default = false,
    Tip = 'Prevents movement speed from being reduced.',
})

task.spawn(function()
    while true do
        task.wait()
        
        local _char = player.Character
        if not _char then continue end
        local _hum = _char:FindFirstChildOfClass('Humanoid')
        if not _hum then continue end

        if antiJumpCooldown.Value then
            _hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end

        if antiFreeze.Value then
            if _hum.WalkSpeed ~= 20 then
                _hum.WalkSpeed = 20
            end
        end

        for _, v in next, players:GetPlayers() do
            if v == player then continue end

            local character = v.Character
            if not character then continue end

            local hum = character:FindFirstChildOfClass('Humanoid')
            if not hum then continue end

            for _, part in next, character:GetChildren() do
                if not part:IsA('BasePart') then continue end
                if part.Name == 'Head' or part.Name == 'Torso' then
                    if hum:GetState() == Enum.HumanoidStateType.Running then
                        part.CanCollide = not antiJam.Value
                    else
                        part.CanCollide = true
                    end
                end
            end
        end
    end
end)

antiBlock = PhysicsTab:CreateToggle({
    Name = 'Anti Block',
    Default = false,
    Tip = 'Reduces player collision while moving.',
})
    
task.spawn(function()
    while true do
        task.wait()

        if not antiBlock.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        if not humanoid then continue end

        for _, v in next, character:GetDescendants() do
            if not v:IsA('BodyVelocity') then continue end
            -- if not v.Name:lower():find('ffmover') then continue end

            v.Velocity = Vector3.zero
            v.MaxForce = Vector3.zero
            humanoid.WalkSpeed = 20

            pcall(function()
                v:Destroy()
            end)
        end
    end
end)

PhysicsTab:UseSection("Quick TP", 1)
quickTP = PhysicsTab:CreateToggle({
    Name = 'Quick TP',
    Default = false,
    Tip = 'Teleports forward in the direction you are facing.',
})

quickTPPower = PhysicsTab:CreateSlider({
    Name = 'Quick TP Power',
    Min = 0,
    Max = 5,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the teleport distance.',
})

HideKeybind = PhysicsTab:CreateKeybind({
    Name = 'Quick TP Keybind',
    Default = Enum.KeyCode.Q,
    Tip = 'Key used to activate Quick TP.',
})

userInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not quickTP.Value then return end
    if input.KeyCode ~= HideKeybind.Value and input.UserInputType ~= Enum.UserInputType.Touch then return end

    local character = player.Character
    if not character then return end

    local hrp = character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    hrp.CFrame += hrp.CFrame.LookVector * quickTPPower.Value
end)
    
PhysicsTab:UseSection("Big Head", 2)
bigHead = PhysicsTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Increases the size of other players heads.',
})

bigHeadSize = PhysicsTab:CreateSlider({
    Name = 'Size',
    Min = 1,
    Max = 6,
    Default = 1,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the size applied to player heads.',
})

task.spawn(function()
    while true do
        task.wait()

        for _, v in next, players:GetPlayers() do
            if v == player then continue end

            local character = v.Character
            if not character then continue end

            local head = character:FindFirstChild('Head')
            if not head then continue end

            head.Size = Vector3.new(bigHead.Value and bigHeadSize.Value or 1, bigHead.Value and bigHeadSize.Value or 1, bigHead.Value and bigHeadSize.Value or 1)
        end
    end
end)
    
VisualTab:UseSection("Catching", 1)
jumpSpot = VisualTab:CreateToggle({
    Name = 'Jump spot',
    Default = false,
    Tip = 'Displays the predicted jump location of incoming footballs.',
})

workspace.ChildAdded:Connect(function(v)
    if not jumpSpot.Value then return end
    if not v:IsA('BasePart') or v.Name ~= 'Football' then return end

    task.wait()

    local position = v.Position
    local velocity = v.AssemblyLinearVelocity
    local gravity = Vector3.new(0, -28, 0)
    local deltaTime = 1 / 30

    local positions = {position}

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {v}
    raycastParams.IgnoreWater = true

    for _ = 1, 300 do
        local nextPosition = position + velocity * deltaTime + 0.5 * gravity * deltaTime ^ 2
        velocity += gravity * deltaTime

        if velocity.Y < 0 then
            local direction = nextPosition - position
            local result = workspace:Raycast(position, direction + Vector3.new(0, -14.4, 0), raycastParams)

            if result then
                nextPosition = result.Position
                table.insert(positions, nextPosition)
                break
            end
        end

        table.insert(positions, nextPosition)
        position = nextPosition
    end

    local optimalPoint = positions[#positions]
    
    local model = Instance.new('Model')
    model.Parent = workspace

    local baseY = optimalPoint.Y - 1.5
    local undergroundY = baseY - 6

    local gradientCylinder = Instance.new('MeshPart')
    gradientCylinder.MeshId = 'rbxassetid://8091779363'
    gradientCylinder.Material = Enum.Material.Plastic
    gradientCylinder.Size = Vector3.new(2, 4, 2)
    gradientCylinder.Rotation = Vector3.new(180, 0, 180)
    gradientCylinder.Transparency = 1
    gradientCylinder.Anchored = true
    gradientCylinder.CanCollide = false
    gradientCylinder.Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    gradientCylinder.Parent = model

    local faces = {
        Enum.NormalId.Front,
        Enum.NormalId.Back,
        Enum.NormalId.Left,
        Enum.NormalId.Right
    }

    for _, face in next, faces do
        local decal = Instance.new('Decal')
        decal.Face = face
        decal.Texture = 'rbxassetid://8097185954'
        decal.Transparency = 0
        decal.Color3 = Color3.fromRGB(255, 255, 255)
        decal.Parent = gradientCylinder
    end

    local glowCircle = Instance.new('MeshPart')
    glowCircle.MeshId = 'rbxassetid://8091848285'
    glowCircle.Material = Enum.Material.Neon
    glowCircle.Color = Color3.fromRGB(255, 255, 255)
    glowCircle.Size = Vector3.new(3.731, 0.031, 3.731)
    glowCircle.Rotation = Vector3.new(180, 0, 180)
    glowCircle.Transparency = 1
    glowCircle.Anchored = true
    glowCircle.CanCollide = false
    glowCircle.Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    glowCircle.Parent = model

    local emitter = Instance.new('ParticleEmitter')
    emitter.Texture = 'rbxasset://textures/particles/sparkles_main.dds'
    emitter.Rate = 5
    emitter.Speed = NumberRange.new(5, 5)
    emitter.Lifetime = NumberRange.new(0.5, 0.5)
    emitter.EmissionDirection = Enum.NormalId.Top
    emitter.TimeScale = 0.3
    emitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
    emitter.Parent = gradientCylinder

    local bottomPart = Instance.new('Part')
    bottomPart.Size = Vector3.new(0.311, 0.311, 0.311)
    bottomPart.Transparency = 1
    bottomPart.Material = Enum.Material.Plastic
    bottomPart.Anchored = true
    bottomPart.CanCollide = false
    bottomPart.Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    bottomPart.Parent = model

    local pointLight = Instance.new('PointLight')
    pointLight.Color = Color3.fromRGB(255, 255, 255)
    pointLight.Range = 12
    pointLight.Brightness = 2
    pointLight.Parent = bottomPart

    local tweenInfo = TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local upGoal = {
        Position = Vector3.new(optimalPoint.X, baseY, optimalPoint.Z)
    }

    local downGoal = {
        Position = Vector3.new(optimalPoint.X, undergroundY, optimalPoint.Z)
    }

    local upTweens = {
        tweenService:Create(gradientCylinder, tweenInfo, upGoal),
        tweenService:Create(glowCircle, tweenInfo, upGoal),
        tweenService:Create(bottomPart, tweenInfo, upGoal)
    }

    for _, t in next, upTweens do
        t:Play()
    end

    task.spawn(function()
        while v and v.Parent and v.AssemblyLinearVelocity.Magnitude > 1 do
            task.wait()
        end

        local downTweens = {
            tweenService:Create(gradientCylinder, tweenInfo, downGoal),
            tweenService:Create(glowCircle, tweenInfo, downGoal),
            tweenService:Create(bottomPart, tweenInfo, downGoal)
        }

        for _, t in next, downTweens do
            t:Play()
        end

        task.wait(0.4)

        if model.Parent then
            model:Destroy()
        end
    end)
end)
    
    throwSpot = VisualTab:CreateToggle({
    Name = 'Landing spot',
    Default = false,
    Tip = 'Shows the predicted landing point of thrown footballs.',
})
    
    workspace.ChildAdded:Connect(function(v)
        if not throwSpot.Value then return end
    if not v:IsA('BasePart') or v.Name ~= 'Football' then return end

    task.wait()

    local pos = v.Position
    local vel = v.AssemblyLinearVelocity
    local gravity = Vector3.new(0, -28, 0)

    local positions = {}
    local parts = {}

    local dt = 0.05
    local maxTime = 8

    local lastPos = pos
    local spawnY = pos.Y

    for t = 0, maxTime, dt do
        local projectilePos = pos + (vel * t) + (0.5 * gravity * t * t)

        table.insert(positions, projectilePos)

        if projectilePos.Y < spawnY then
            break
        end

        local ray = workspace:Raycast(lastPos, projectilePos - lastPos)
        if ray then
            positions[#positions] = ray.Position
            break
        end

        lastPos = projectilePos
    end

    local endPos = positions[#positions]
    if not endPos then return end

    local posPart = Instance.new('Part', workspace.Terrain)
    posPart.Anchored = true
    posPart.CanCollide = false
    posPart.CastShadow = false
    posPart.Size = Vector3.new(3, 3, 3)
    posPart.Shape = Enum.PartType.Ball
    posPart.Color = Color3.fromRGB(0, 0, 0)
    posPart.Position = endPos

    for i = 1, #positions - 1 do
        local p0 = positions[i]
        local p1 = positions[i + 1]

        local beamPart = Instance.new('Part', workspace.Terrain)
        beamPart.Anchored = true
        beamPart.CanCollide = false
        beamPart.CastShadow = false
        beamPart.Material = Enum.Material.Neon
        beamPart.Color = Color3.fromRGB(255, 255, 255)

        local dist = (p1 - p0).Magnitude

        beamPart.Size = Vector3.new(0.4, 0.4, dist)
        beamPart.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)

        table.insert(parts, beamPart)
    end

    task.spawn(function()
        local speed = math.max(vel.Magnitude, 1)
        local delayTime = math.clamp(300 / speed, 0.01, 0.04)

        for _, part in next, parts do
            task.wait(delayTime)

            if part.Parent then
                part:Destroy()
            end
        end

        if posPart.Parent then
            posPart:Destroy()
        end
    end)
end)
    
VisualTab:UseSection("Misc", 2)
VisualTab:CreateButton({
    Name = 'Unlock All Gamepass',
    Tip = 'Enables all gamepass-related checks locally.',
    Callback = function()
        local replicatedFirst = game:GetService('ReplicatedFirst')
        local module
        local success = pcall(function()
            module = require(replicatedFirst:FindFirstChild('LocalSave'))
        end)
        if not success or not module then return end
        module.PlayerOwnsPass = function(a, b)
            return true
        end
    end
})

local lighting = game:GetService('Lighting')

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

local function ApplySkyBox(name)
    name = name or "None"
    local preset = kSkyboxMap[name] or kSkyboxMap["None"]
    if not preset then return end
    for _, v in next, lighting:GetChildren() do
        if v:IsA("Sky") then
            v:Destroy()
        end
    end
    if name == "None" then
        return
    end
    local Sky = Instance.new("Sky")
    Sky.Name = "MethaneSky_" .. tostring(name)
    Sky.Parent = lighting
    Sky.SkyboxBk = preset.skybox_back or ""
    Sky.SkyboxDn = preset.skybox_down or ""
    Sky.SkyboxFt = preset.skybox_front or ""
    Sky.SkyboxLf = preset.skybox_left or ""
    Sky.SkyboxRt = preset.skybox_right or ""
    Sky.SkyboxUp = preset.skybox_up or ""
    pcall(function()
        Sky.SunTextureId = preset.sun_texture or "rbxasset://sky/sun.jpg"
        Sky.MoonTextureId = preset.moon_texture or "rbxasset://sky/moon.jpg"
    end)
end

local skyOptions = {}
for name in pairs(kSkyboxMap) do
    skyOptions[#skyOptions + 1] = name
end
table.sort(skyOptions)

skyboxDropdown = VisualTab:CreateDropdown({
    Name = 'Skybox',
    Options = skyOptions,
    Default = 'None',
    Tip = 'Applies a skybox preset (same as Methane Rivals).',
    Callback = function(v)
        pcall(ApplySkyBox, v)
    end,
})




VisualTab:UseSection("Performance", 1)

removeGloves = VisualTab:CreateToggle({
    Name = 'Remove Gloves',
    Default = false,
    Tip = 'Removes uniform gloves when enabled.',
})

do
    local gloveDebounce = false
    task.spawn(function()
        while true do
            task.wait(0.75)
            if gloveDebounce then continue end

            local character = player.Character
            if not character then continue end
            local uniform = character:FindFirstChild('Uniform')
            if not uniform then continue end

            local gloveVisible = nil
            for _, v in next, uniform:GetDescendants() do
                if not v:IsA('BasePart') then continue end
                if not v.Name:lower():find('glove') then continue end
                gloveVisible = v.Transparency == 0
                break
            end

            if gloveVisible == nil then continue end

            local shouldHide = removeGloves.Value and gloveVisible
            local shouldRestore = (not removeGloves.Value) and (not gloveVisible)

            if shouldHide or shouldRestore then
                gloveDebounce = true
                pcall(function()
                    replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'Customization', 'Toggle', 'LeftGlove')
                end)
                task.wait(0.1)
                pcall(function()
                    replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'Customization', 'Toggle', 'RightGlove')
                end)
                -- Wait for server state to propagate before checking again
                task.wait(1.0)
                gloveDebounce = false
            end
        end
    end)
end

noBallTrail = VisualTab:CreateToggle({
    Name = 'No Ball Trail',
    Default = false,
    Tip = 'Removes football trail effects.',
})

workspace.ChildAdded:Connect(function(v)
    if not noBallTrail.Value then return end
    if v:IsA('BasePart') and v.Name == 'Football' then
        local trail = v:FindFirstChildOfClass('Trail')
        if trail then
            trail:Destroy()
        end
    end
end)

local stadiumParts = {}
pcall(function()
    local stadium = workspace:FindFirstChild('Models') and workspace.Models:FindFirstChild('Stadium')
    if stadium then
        for _, v in next, stadium:GetDescendants() do
            if not v:IsA('BasePart') then continue end
            stadiumParts[#stadiumParts + 1] = {
                Part = v,
                Transparency = v.Transparency,
                CanCollide = v.CanCollide
            }
        end
    end
end)

hideStadium = VisualTab:CreateToggle({
    Name = 'Hide Stadium',
    Default = false,
    Tip = 'Hides visible stadium structures.',
    Callback = function(v)
        for _, p in next, stadiumParts do
            pcall(function()
                p.Part.Transparency = v and 1 or p.Transparency
                p.Part.CanCollide = v and false or p.CanCollide
            end)
        end
    end
})

fpsBoost = VisualTab:CreateToggle({
    Name = 'FPS Boost',
    Default = false,
    Tip = 'Sets materials to Plastic for higher FPS.',
})

footballHighlight = VisualTab:CreateToggle({
    Name = 'Football Highlight',
    Default = false,
    Tip = 'Outline highlight on football parts (ConsHub).',
})

-- Football highlight
do
    local function ensureHL(part)
        if not part or not part:IsA("BasePart") then return end
        if part:FindFirstChild("MethaneFootballHL") then return end
        local hl = Instance.new("Highlight")
        hl.Name = "MethaneFootballHL"
        hl.FillTransparency = 1
        hl.OutlineTransparency = 0
        hl.OutlineColor = Color3.fromRGB(0, 200, 255)
        hl.Adornee = part
        hl.Parent = part
    end
    task.spawn(function()
        while true do
            task.wait(0.35)
            if not footballHighlight.Value then
                for _, obj in ipairs(workspace:GetDescendants()) do
                    if obj:IsA("Highlight") and obj.Name == "MethaneFootballHL" then
                        pcall(function() obj:Destroy() end)
                    end
                end
                continue
            end
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj.Name == "Football" and obj:IsA("BasePart") then
                    ensureHL(obj)
                elseif obj:IsA("Tool") and obj.Name == "Football" then
                    local h = obj:FindFirstChildWhichIsA("BasePart")
                    if h then ensureHL(h) end
                end
            end
            for _, plr in ipairs(players:GetPlayers()) do
                local char = plr.Character
                if not char then continue end
                local fb = char:FindFirstChild("Football")
                if fb then
                    if fb:IsA("BasePart") then ensureHL(fb)
                    else
                        local p = fb:FindFirstChildWhichIsA("BasePart")
                        if p then ensureHL(p) end
                    end
                end
            end
        end
    end)
end

local _fpsMatCache = {}
local _fpsApplied = false
task.spawn(function()
    while true do
        task.wait(2.5)
        if not fpsBoost.Value then
            if next(_fpsMatCache) then
                for part, mat in pairs(_fpsMatCache) do
                    pcall(function()
                        if part and part.Parent then part.Material = mat end
                    end)
                end
                table.clear(_fpsMatCache)
                _fpsApplied = false
            end
            continue
        end
        -- only full scan occasionally; skip already-cached parts
        for _, v in ipairs(workspace:GetDescendants()) do
            if not v:IsA('BasePart') then continue end
            local n = v.Name
            if n == 'MethaneMagRadius' or n == 'MethaneBaselineDot' or (type(n) == 'string' and n:find('Methane') == 1) then
                continue
            end
            if v.Material == Enum.Material.ForceField then continue end
            if not _fpsMatCache[v] then
                _fpsMatCache[v] = v.Material
            end
            if v.Material ~= Enum.Material.Plastic then
                pcall(function() v.Material = Enum.Material.Plastic end)
            end
        end
        _fpsApplied = true
    end
end)

greyBall = VisualTab:CreateToggle({
    Name = 'Grey Ball',
    Default = false,
    Tip = 'Makes the football solid grey with no texture.',
})
local function applyGreyBall(ball)
    if not ball or not ball:IsA('BasePart') then return end
    pcall(function()
        ball.Color = Color3.fromRGB(140, 140, 140)
        ball.Material = Enum.Material.SmoothPlastic
        if ball:IsA('MeshPart') then ball.TextureID = '' end
        for _, d in ipairs(ball:GetDescendants()) do
            if d:IsA('Decal') or d:IsA('Texture') then d.Transparency = 1
            elseif d:IsA('SpecialMesh') then d.TextureId = '' end
        end
    end)
end
task.spawn(function()
    while true do
        task.wait(0.5)
        if not greyBall.Value then continue end
        for _, v in ipairs(workspace:GetChildren()) do
            if v.Name == 'Football' then
                if v:IsA('BasePart') then applyGreyBall(v)
                else
                    for _, p in ipairs(v:GetDescendants()) do
                        if p:IsA('BasePart') then applyGreyBall(p) end
                    end
                end
            end
        end
        local char = player.Character
        if char then
            local tool = char:FindFirstChild('Football')
            if tool then
                for _, p in ipairs(tool:GetDescendants()) do
                    if p:IsA('BasePart') then applyGreyBall(p) end
                end
            end
        end
    end
end)
workspace.ChildAdded:Connect(function(v)
    if not greyBall.Value then return end
    task.defer(function()
        if v.Name == 'Football' then
            if v:IsA('BasePart') then applyGreyBall(v)
            else
                for _, p in ipairs(v:GetDescendants()) do
                    if p:IsA('BasePart') then applyGreyBall(p) end
                end
            end
        end
    end)
end)


DefenseTab:UseSection("Swat Reach", 1)
swatReach = DefenseTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Extends swat range on nearby footballs.',
})

swatReachDistance = DefenseTab:CreateSlider({
    Name = 'Reach',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum swat distance.',
})

task.spawn(function()
    while true do
        task.wait()

        if not swatReach.Value then continue end

        local character = player.Character
        if not character then continue end

        local ball = findClosestBall()
        if not ball then continue end

        for _, v in next, character:GetChildren() do
            if v:IsA('BasePart') and v.Name:lower():find('catch') then
                local distance = (ball.Position - v.Position).Magnitude
                if distance < swatReachDistance.Value then
                    if v.Size.X > 2 then
                        firetouchinterest(v, ball, 0)
                        firetouchinterest(v, ball, 1)
                    end
                end
            end
        end
    end
end)

DefenseTab:UseSection("Tackle Reach", 2)
tackleReach = DefenseTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Extends tackle range against ball carriers.',
})

tackleAimbot = DefenseTab:CreateToggle({
    Name = 'click to tackle',
    Default = false,
    Tip = 'Click to instantly TP to the ball carrier within range and tackle.',
})

tackleAimbotRange = DefenseTab:CreateSlider({
    Name = 'distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the maximum targeting distance.',
})

-- Tackle reach: continuous remote fire while enabled
task.spawn(function()
    while true do
        task.wait()
        local character = player.Character
        if not character then continue end
        if not tackleReach.Value then continue end

        for _, v in next, players:GetPlayers() do
            if v ~= player and v.Team ~= player.Team and v.Character and v.Character:FindFirstChild('Football') then
                local bodyParts = {'Torso', 'Head', 'HumanoidRootPart', 'Left Arm', 'Left Leg', 'Right Arm', 'Right Leg'}
                local randomPart = bodyParts[math.random(1, #bodyParts)]
                replicatedStorage.Remotes.CharacterSoundEvent:FireServer('Game', 'TackleTouch', randomPart, randomPart)
            end
        end
    end
end)

-- Click to tackle: fires once per click, TPs to closest ball carrier in range
userInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not tackleAimbot.Value then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild('HumanoidRootPart')
    if not hrp then return end

    local closest = nil
    local closestDist = math.huge

    for _, v in next, players:GetPlayers() do
        if v == player then continue end
        if v.Team == player.Team then continue end
        if not v.Character then continue end
        if not v.Character:FindFirstChild('Football') then continue end
        local enemyHrp = v.Character:FindFirstChild('HumanoidRootPart')
        if not enemyHrp then continue end
        local d = (enemyHrp.Position - hrp.Position).Magnitude
        if d < tackleAimbotRange.Value and d < closestDist then
            closestDist = d
            closest = v
        end
    end

    if not closest then return end
    local targetHrp = closest.Character:FindFirstChild('HumanoidRootPart')
    if not targetHrp then return end

    hrp.CFrame = targetHrp.CFrame
end)

DefenseTab:UseSection("Auto Rush", 1)
autoRush = DefenseTab:CreateToggle({
    Name = 'Auto Rush',
    Default = false,
    Tip = 'ConsHub-style rush toward enemy ball carrier.',
})

autoRushPredict = DefenseTab:CreateToggle({
    Name = 'Prediction',
    Default = true,
    Tip = 'Lead the carrier with MoveDirection prediction + beam.',
})

walkToLine = DefenseTab:CreateToggle({
    Name = 'Walk To Line',
    Default = false,
    Tip = 'Moves the player to the line before play starts.',
})

autoRushReactionTime = DefenseTab:CreateSlider({
    Name = 'Reaction Time',
    Min = 0,
    Max = 1,
    Default = 0.3,
    Increment = 0.05,
    Suffix = 's',
    Tip = 'Position history delay used for prediction (ConsHub).',
})

do
    local rushLine, rushStart, rushEnd, endPart

    local function isEnemy(plr)
        if not player.Team or not plr.Team then return true end
        return plr.Team ~= player.Team
    end

    local function findPossessor()
        for _, plr in ipairs(players:GetPlayers()) do
            local char = plr.Character
            if char and isEnemy(plr) then
                if char:FindFirstChild("Football") or char:FindFirstChildWhichIsA("Tool") then
                    local tool = char:FindFirstChild("Football") or char:FindFirstChildWhichIsA("Tool")
                    if tool and (tool.Name == "Football" or tool:IsA("Tool")) then
                        if tool.Name == "Football" or (tool:IsA("Tool") and tool.Name:lower():find("foot")) then
                            return char
                        end
                    end
                    if char:FindFirstChild("Football") then
                        return char
                    end
                end
            end
        end
        -- fallback: any enemy with Football child
        for _, plr in ipairs(players:GetPlayers()) do
            local char = plr.Character
            if char and isEnemy(plr) and char:FindFirstChild("Football") then
                return char
            end
        end
        return nil
    end

    local function createPredictionLine()
        if rushLine then pcall(function() rushLine:Destroy() end) end
        if endPart then pcall(function() endPart:Destroy() end) end

        local part = Instance.new("Part")
        part.Anchored = true
        part.CanCollide = false
        part.Transparency = 1
        part.Size = Vector3.new(0.5, 0.5, 0.5)
        part.Name = "MethaneRushLine"

        local a1 = Instance.new("Attachment")
        a1.Parent = part
        local a2 = Instance.new("Attachment")
        a2.Parent = part

        local beam = Instance.new("Beam")
        beam.Attachment0 = a1
        beam.Attachment1 = a2
        beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 255))
        beam.Width0 = 0.4
        beam.Width1 = 0.4
        beam.FaceCamera = true
        beam.LightInfluence = 0
        beam.Transparency = NumberSequence.new(0)
        beam.Parent = a1

        part.Parent = workspace
        rushLine, rushStart, rushEnd = part, a1, a2

        endPart = Instance.new("Part")
        endPart.Anchored = true
        endPart.CanCollide = false
        endPart.Size = Vector3.new(2, 2, 2)
        endPart.Transparency = 0.3
        endPart.Color = Color3.fromRGB(0, 255, 255)
        endPart.Material = Enum.Material.Neon
        endPart.Name = "MethaneRushEnd"
        endPart.Parent = workspace
    end

    task.spawn(function()
        local log = {}
        while true do
            task.wait(1 / 30)

            if not autoRush.Value then
                log = {}
                if rushLine then rushLine.Parent = nil end
                if endPart then endPart.Parent = nil end
                continue
            end

            local character = player.Character
            if not character then continue end
            local hrp = character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then continue end

            -- Walk to line (kept)
            if walkToLine.Value then
                local flags = replicatedStorage:FindFirstChild("Flags")
                if flags and flags:FindFirstChild("PossessionTag") and flags:FindFirstChild("Status") then
                    if flags.PossessionTag.Value ~= player.Team.Name and flags.Status.Value == "PrePlay" then
                        local line = workspace:FindFirstChild("LineDown")
                        if line then
                            hum:MoveTo(line.Position)
                        end
                    end
                end
            end

            local possessor = findPossessor()
            if not possessor then
                log = {}
                if rushLine then rushLine.Parent = nil end
                if endPart then endPart.Parent = nil end
                continue
            end

            local possHRP = possessor:FindFirstChild("HumanoidRootPart")
            local possHum = possessor:FindFirstChildOfClass("Humanoid")
            if not possHRP then continue end

            local delay = math.clamp(tonumber(autoRushReactionTime.Value) or 0.3, 0, 1)
            local logIndex = math.max(#log - math.round(delay / (1 / 30)), 1)
            local delayedPos = log[logIndex]
            table.insert(log, possHRP.Position)
            if #log > 90 then table.remove(log, 1) end

            if not delayedPos then continue end

            local moveDir = Vector3.zero
            if possHum then moveDir = possHum.MoveDirection end
            local predictedPos = delayedPos + (moveDir * 20 * delay)

            if autoRushPredict.Value then
                hum:MoveTo(predictedPos)
                if not rushLine then createPredictionLine() end
                if rushLine then
                    rushLine.Position = predictedPos
                    rushStart.WorldPosition = hrp.Position
                    rushEnd.WorldPosition = predictedPos
                    rushLine.Parent = workspace
                end
                if endPart then
                    endPart.Position = predictedPos
                    endPart.Parent = workspace
                end
            else
                hum:MoveTo(delayedPos)
                if rushLine then rushLine.Parent = nil end
                if endPart then endPart.Parent = nil end
            end
        end
    end)
end

CatchingTab:UseSection("Auto Catch", 1)
autoCatch = CatchingTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Automatically catches nearby footballs.',
})

autoCatchRadius = CatchingTab:CreateSlider({
    Name = 'Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets how far the auto catch detection can reach.',
})

DefenseTab:UseSection("Auto Swat", 2)
autoSwat = DefenseTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Automatically reacts to nearby incoming balls.',
})

autoSwatRadius = DefenseTab:CreateSlider({
    Name = 'Distance',
    Min = 0,
    Max = 25,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets how far the auto swat detection can reach.',
})



task.spawn(function()
    while true do
        task.wait()

        if not autoCatch.Value and not autoSwat.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        local distance = (ball.Position - humanoidRootPart.Position).Magnitude

        if autoCatch.Value and distance <= autoCatchRadius.Value then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('PlayerActions', isPractice and 'catch ' or 'catch')
        end

        if autoSwat.Value and distance <= autoSwatRadius.Value then
            replicatedStorage.Remotes.CharacterSoundEvent:FireServer('PlayerActions', 'swat')
        end
    end
end)
    
AutomaticsTab:UseSection("Auto Win", 1)
autoCaptain = AutomaticsTab:CreateToggle({
    Name = 'Auto get cap',
    Default = false,
    Tip = 'Automatically moves toward the finish line during captain selection.',
})

task.spawn(function()
    while true do
        task.wait()

        if not autoCaptain.Value then continue end

        local character = player.Character
        if not character then continue end

        local hrp = character:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end

        for _, v in next, workspace.Models.LockerRoomA:GetChildren() do
            if v.Name:lower():find('finishline') and not player.Team then
                v:GetPropertyChangedSignal('CFrame'):Connect(function()
                    for i = 1, 4 do
                        task.wait()

                        hrp.CFrame = v.CFrame
                    end
                end)
            end
        end
    end
end)
    
CatchingTab:UseSection("Auto Reset", 1)
autoReset = CatchingTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Breaks character after catching the football (ConsHub).',
})

autoResetDelay = CatchingTab:CreateSlider({
    Name = 'Reset Delay',
    Min = 0,
    Max = 2,
    Default = 1,
    Increment = 0.1,
    Suffix = 's',
    Tip = 'Delay after possessing the ball before reset.',
})

do
    local _resetLock = false
    task.spawn(function()
        while true do
            task.wait(0.1)
            if not autoReset.Value then _resetLock = false continue end
            local char = player.Character
            if not char or _resetLock then continue end
            local tool = char:FindFirstChild("Football") or char:FindFirstChildOfClass("Tool")
            if tool and tool.Name == "Football" then
                _resetLock = true
                local delay = math.clamp(tonumber(autoResetDelay.Value) or 1, 0, 2)
                task.wait(delay)
                if autoReset.Value and char.Parent then
                    pcall(function() char:BreakJoints() end)
                end
                task.wait(1)
                _resetLock = false
            end
        end
    end)
end

CatchingTab:UseSection("Freeze Tech", 2)
autoFreeze = CatchingTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Anchors your character. Auto mode freezes on catch. Key mode holds while key is pressed.',
})

freezeMode = CatchingTab:CreateDropdown({
    Name = 'Freeze Mode',
    Options = {'Auto', 'On Key'},
    Default = 'Auto',
    Tip = 'Auto = freezes when you catch the ball. On Key = anchored while keybind is held.',
})

freezeDuration = CatchingTab:CreateSlider({
    Name = 'Duration',
    Min = 0,
    Max = 3,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'How long Auto mode stays frozen after catching. Ignored in On Key mode.',
})

freezeKeybind = CatchingTab:CreateKeybind({
    Name = 'Freeze Keybind',
    Default = Enum.KeyCode.V,
    Tip = 'Key to hold for On Key mode.',
})

do
    local _freezeActive = false
    local _keyFreezeConn = nil

    -- Auto mode: hook catch remote
    local _catchRemote = nil
    pcall(function()
        _catchRemote = replicatedStorage:WaitForChild('Remotes', 5)
            and replicatedStorage.Remotes:WaitForChild('CharacterSoundEvent', 5)
    end)

    local function doAutoFreeze()
        if not autoFreeze.Value then return end
        if tostring(freezeMode.Value) ~= 'Auto' then return end
        local character = player.Character
        if not character then return end
        local hrp = character:FindFirstChild('HumanoidRootPart')
        if not hrp then return end
        if _freezeActive then return end
        _freezeActive = true
        -- Do NOT use Anchored (server flags it). Soft-hold: zero horiz velocity briefly.
        local dur = math.clamp(tonumber(freezeDuration.Value) or 0.15, 0.05, 0.6)
        local holdUntil = tick() + dur
        local conn
        conn = game:GetService("RunService").Heartbeat:Connect(function()
            if not hrp or not hrp.Parent or tick() > holdUntil then
                if conn then conn:Disconnect() end
                _freezeActive = false
                return
            end
            local v = hrp.AssemblyLinearVelocity
            hrp.AssemblyLinearVelocity = Vector3.new(v.X * 0.15, math.min(v.Y, 0), v.Z * 0.15)
        end)
    end

    -- Watch for catch action fired through the remote
    task.spawn(function()
        if not _catchRemote then return end
        local orig
        pcall(function()
            orig = hookfunction(_catchRemote.FireServer, newcclosure(function(self, ...)
                local args = { ... }
                -- FireServer('PlayerActions', 'catch') or ('PlayerActions', 'catch ')
                if typeof(args[1]) == 'string' and args[1] == 'PlayerActions' then
                    local action = typeof(args[2]) == 'string' and args[2]:gsub('%s', '') or ''
                    if action == 'catch' then
                        task.defer(doAutoFreeze)
                    end
                end
                return orig(self, ...)
            end))
        end)
    end)

    -- On Key mode: anchor while held, release on InputEnded
    userInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if not autoFreeze.Value then return end
        if tostring(freezeMode.Value) ~= 'On Key' then return end
        local key = freezeKeybind.Value
        if not key then return end
        if input.KeyCode ~= key then return end

        local character = player.Character
        if not character then return end
        local hrp = character:FindFirstChild('HumanoidRootPart')
        if not hrp then return end
        _freezeActive = true
        -- soft freeze without Anchored
        if not _keyFreezeConn then
            _keyFreezeConn = game:GetService("RunService").Heartbeat:Connect(function()
                if not _freezeActive then return end
                local c = player.Character
                local r = c and c:FindFirstChild('HumanoidRootPart')
                if not r then return end
                local v = r.AssemblyLinearVelocity
                r.AssemblyLinearVelocity = Vector3.new(v.X * 0.1, math.min(v.Y, 0), v.Z * 0.1)
            end)
        end
    end)

    userInputService.InputEnded:Connect(function(input)
        if not autoFreeze.Value then return end
        if tostring(freezeMode.Value) ~= 'On Key' then return end
        local key = freezeKeybind.Value
        if not key then return end
        if input.KeyCode ~= key then return end
        _freezeActive = false
    end)

    player.CharacterAdded:Connect(function(char)
        _freezeActive = false
    end)
end

AutomaticsTab:UseSection("Auto QB", 1)
autoQb = AutomaticsTab:CreateToggle({
    Name = 'Auto QB',
    Default = false,
    Tip = 'Automatically positions your character for quarterback play.',
})

autoQbMethod = AutomaticsTab:CreateDropdown({
    Name = 'Auto QB Method',
    Options = {'Walk'},
    Default = 'Walk',
    Tip = 'Walk only — teleport method removed (flagged as suspicious movement).',
})

task.spawn(function()
    while true do
        task.wait()

        if not autoQb.Value then continue end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass('Humanoid')
        local humanoidRootPart = character:FindFirstChild('HumanoidRootPart')
        if not humanoid or not humanoidRootPart then continue end

        local ball = findClosestBall()
        if not ball then continue end

        if replicatedStorage:FindFirstChild('Flags')
            and replicatedStorage.Flags:FindFirstChild('PossessionTag')
            and replicatedStorage.Flags:FindFirstChild('Status')
            and replicatedStorage.Flags.PossessionTag.Value == player.Team.Name
            and replicatedStorage.Flags.Status.Value == 'PrePlay' then

            -- Teleport disabled (suspicious movement). Always walk.
            humanoid:MoveTo(ball.Position)
        else
            pcall(function()
                ball.CFrame = humanoidRootPart.CFrame
            end)
        end
    end
end)
    
CatchingTab:UseSection("Auto Boost", 2)
    autoBoost = CatchingTab:CreateToggle({
    Name = 'Enable',
    Default = false,
    Tip = 'Automatically assists aerial movement near incoming footballs.',
})

targetClosestPlayer = CatchingTab:CreateToggle({
    Name = 'Closest Player',
    Default = false,
    Tip = 'Prioritizes players closest to the football.',
})

boostStrength = CatchingTab:CreateSlider({
    Name = 'Strength',
    Min = 0,
    Max = 2,
    Default = 0.8,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Keep low — strong mid-air CFrame tweens get movement flagged.',
})

boostRadius = CatchingTab:CreateSlider({
    Name = 'radius',
    Min = 0,
    Max = 15,
    Default = 0,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Sets the activation distance for boosting.',
})

boostPower = CatchingTab:CreateSlider({
    Name = 'Power',
    Min = 50,
    Max = 60,
    Default = 50,
    Increment = 0.1,
    Suffix = '',
    Tip = 'Upward force after boost. Stay near 50 to avoid velocity flags.',
})

task.spawn(function()
    local activeTween

    while true do
        task.wait()

        if not autoBoost.Value then
            if activeTween then
                activeTween:Cancel()
                activeTween = nil
            end

            continue
        end

        local char = player.Character
        if not char then continue end

        local hum = char:FindFirstChildOfClass('Humanoid')
        if not hum then continue end

        local hrp = char:FindFirstChild('HumanoidRootPart')
        if not hrp then continue end

        if hum:GetState() == Enum.HumanoidStateType.Landed then
            if activeTween then
                activeTween:Cancel()
                activeTween = nil
            end

            continue
        end

        local myHead = char:FindFirstChild('Head')
        if not myHead then continue end

        local targetPlayer

        if targetClosestPlayer.Value then
            local nearestBall
            local nearestBallDist = math.huge

            for _, ball in next, workspace:GetChildren() do
                if not ball:IsA('BasePart') then continue end
                if not ball.Name:lower():find('ball') then continue end

                local dist = (ball.Position - myHead.Position).Magnitude

                if dist < nearestBallDist then
                    nearestBallDist = dist
                    nearestBall = ball
                end
            end

            if not nearestBall then continue end

            local closestDist = math.huge

            for _, v in next, players:GetPlayers() do
                if v == player then continue end

                local character = v.Character
                if not character then continue end

                local head = character:FindFirstChild('Head')
                if not head then continue end

                local dist = (head.Position - nearestBall.Position).Magnitude

                if dist < closestDist then
                    closestDist = dist
                    targetPlayer = v
                end
            end
        else
            local closestDist = math.huge

            for _, v in next, players:GetPlayers() do
                if v == player then continue end

                local character = v.Character
                if not character then continue end

                local head = character:FindFirstChild('Head')
                if not head then continue end

                local dist = (head.Position - myHead.Position).Magnitude

                if dist < closestDist then
                    closestDist = dist
                    targetPlayer = v
                end
            end
        end

        if not targetPlayer then continue end

        local character = targetPlayer.Character
        if not character then continue end

        local head = character:FindFirstChild('Head')
        if not head then continue end

        local targetHumanoid = character:FindFirstChildOfClass('Humanoid')
        if not targetHumanoid then continue end

        local myState = hum:GetState()
        local targetState = targetHumanoid:GetState()

        local distance = (head.Position - myHead.Position).Magnitude

        if distance > boostRadius.Value then
            continue
        end

        if myState ~= Enum.HumanoidStateType.Jumping
            and myState ~= Enum.HumanoidStateType.Freefall then
            continue
        end

        if targetState ~= Enum.HumanoidStateType.Jumping
            and targetState ~= Enum.HumanoidStateType.Freefall then
            continue
        end

        local speed = math.max(hum.WalkSpeed * boostStrength.Value, 1)
        local targetPos = head.Position

        local duration = math.max((hrp.Position - targetPos).Magnitude / speed, 0.01)

        if activeTween then
            activeTween:Cancel()
        end

        activeTween = tweenService:Create(
            hrp,
            TweenInfo.new(duration, Enum.EasingStyle.Linear),
            {
                CFrame = CFrame.new(targetPos)
            }
        )

        activeTween:Play()

        activeTween.Completed:Once(function(state)
            if state ~= Enum.PlaybackState.Completed then
                return
            end

            hrp.AssemblyLinearVelocity = Vector3.new(
                hrp.AssemblyLinearVelocity.X,
                boostPower.Value,
                hrp.AssemblyLinearVelocity.Z
            )
        end)
    end
end)

MiscTab:UseSection("Safety", 2)
antiAdmin = MiscTab:CreateToggle({
    Name = 'Anti Admin',
    Default = false,
    Tip = 'Automatically reacts when administrators are detected.',
    Keybind = nil,
})

task.spawn(function()
    while task.wait() do
        local playerGui = player:FindFirstChild("PlayerGui")
        if not playerGui then continue end
        
        local miscText = playerGui:FindFirstChild("MiscText")
        if not miscText then continue end
        
        local isVIP = miscText:FindFirstChild("IsVIP")
        if not isVIP then continue end
        
        if isVIP.Visible == true then continue end
        
        for _, admin in next, players:GetPlayers() do
            if admin == player then continue end
            
            local swagData = admin:FindFirstChild("SwagData")
            if not swagData then continue end
            
            local adminTag = swagData:FindFirstChild("Admin")
            if not adminTag then continue end
            
            if adminTag.Value ~= "" and antiAdmin.Value then
                player:Kick("[Cheeto Hub] Detected Admin\
Name: " .. admin.Name .. "\
ID: " .. admin.UserId)
            end
        end
    end
end)

MiscTab:UseSection("Replay", 1)
smoothReplay = MiscTab:CreateToggle({
		Name = 'Smooth Replay',
		Default = false,
		Tip = 'Smooths replay playback for improved visual quality.',
		Keybind = nil,
	})

	replayFPS = MiscTab:CreateSlider({
		Name = 'Replay Frame Per Second',
		Min = 9,
		Max = 120,
		Default = 9,
		Increment = 1,
		Tip = 'Sets the replay playback frame rate.',
	})
    
if not isPractice then

	local player = game:GetService('Players').LocalPlayer
	local replicatedStorage = game:GetService('ReplicatedStorage')
	local runService = game:GetService('RunService')

	local remote = replicatedStorage:WaitForChild('Remotes'):WaitForChild('CharacterSoundEvent')
	local heartbeat = runService.Heartbeat

	local transition = player:WaitForChild('PlayerGui'):WaitForChild('MainGui'):WaitForChild('Transition')

	local homeCamera = CFrame.Angles(-0.2617993877991494, 0, 0)
	local awayCamera = CFrame.Angles(0.2617993877991494, math.pi, 0)

	local cameraOffset = CFrame.new(0, 0, 19)

	local limbs = {
		'Torso',
		'Left Arm',
		'Right Arm',
		'Left Leg',
		'Right Leg',
		'Head'
	}

	task.spawn(function()
		while true do
			task.wait()

			local _ps = player:FindFirstChild('PlayerScripts')
			local replayScript = _ps and _ps:FindFirstChild('ClientReplay')
			if replayScript then
				replayScript.Enabled = not smoothReplay.Value
			end
		end
	end)

	local replay = function(data, characters)
		local replayBall = workspace:WaitForChild('ReplayBall')
		local camera = workspace.CurrentCamera

		camera.CameraType = Enum.CameraType.Scriptable
		camera.CameraSubject = replayBall

		local cameraRotation = data.changes[1].poss == 'h' and homeCamera or awayCamera

		local currentChange = 1
		local highestY = 18
		local cameraTilt = true

		local playback = 1
		local recordedFPS = data.fps

		local accumulator = 0
		local last = tick()

		local getFrame = function(index)
			local maxFrames = #data.ball
			if index < 1 then return 1 end
			if index > maxFrames then return maxFrames end
			return index
		end

		local interpolate = function(a, b, alpha)
			return a:Lerp(b, alpha)
		end

		while playback < #data.ball do
			if replicatedStorage.Flags.StatusTag.Value ~= 'REPLAY' then
				break
			end

			if camera.CameraType ~= Enum.CameraType.Scriptable then
				break
			end

			local replayFPSValue = replayFPS.Value
			local replayDelta = 1 / replayFPSValue

			local now = tick()
			accumulator += now - last
			last = now

			while accumulator >= replayDelta do
				playback += recordedFPS / replayFPSValue
				accumulator -= replayDelta
			end

			local frame1 = getFrame(math.floor(playback))
			local frame2 = getFrame(math.ceil(playback))
			local alpha = playback - frame1

			for _, character in next, characters do
				local characterData = data.limbs[character.Name]
				if not characterData then character.Parent = nil continue end

				local limbData = characterData[1]
				local accessoryData = characterData[2]

				if not limbData[1] then
					character.Parent = nil
					continue
				end

				local torso1 = limbData[1][2][frame1]
				local torso2 = limbData[1][2][frame2]

				if not torso1 or not torso2 then
					character.Parent = nil
					continue
				end

				local torso = interpolate(torso1, torso2, alpha)

				for i = 1, #limbs do
					local limbName = limbs[i]
					local limb = character:FindFirstChild(limbName)
					if not limb then continue end

					local replayLimb = limbData[i]
					if not replayLimb then continue end

					local cf1 = replayLimb[2][frame1]
					local cf2 = replayLimb[2][frame2]

					if i == 4 then
						if cf1 and cf2 then
							local angle = cf1 + ((cf2 - cf1) * alpha)

							limb.CFrame =
								torso *
								CFrame.new(-0.5, -1, 0) *
								CFrame.fromOrientation(angle, 0, 0) *
								CFrame.new(0, -1, 0)
						end
					elseif i == 5 then
						if cf1 and cf2 then
							local angle = cf1 + ((cf2 - cf1) * alpha)

							limb.CFrame =
								torso *
								CFrame.new(0.5, -1, 0) *
								CFrame.fromOrientation(angle, 0, 0) *
								CFrame.new(0, -1, 0)
						end
					else
						if cf1 and cf2 then
							limb.CFrame = interpolate(cf1, cf2, alpha)
						elseif i == 6 then
							limb.CFrame = torso * CFrame.new(0, 1.5, 0)
						end
					end
				end

				local uniform = character:FindFirstChild('Uniform')
				if accessoryData and uniform then
					for name, info in next, accessoryData do
						if uniform:FindFirstChild(name) and character:FindFirstChild(info[1]) then
							uniform[name].CFrame =
								character[info[1]].CFrame * info[2]
						end
					end
				end
			end

			local ball1 = data.ball[frame1]
			local ball2 = data.ball[frame2]

			if ball1 and ball2 then
				replayBall.CFrame = interpolate(ball1, ball2, alpha)
			end

			if highestY < replayBall.Position.Y then
				highestY = replayBall.Position.Y
			elseif highestY > 49 and cameraTilt then
				local x = select(1, cameraRotation:ToOrientation())

				cameraRotation *= CFrame.Angles(
					x * 3 * math.clamp((highestY - 50) / 99, 0, 1),
					0,
					0
				)

				cameraTilt = false
			end

			local targetCamera

			if highestY > 49 and cameraTilt then
				local x = select(1, cameraRotation:ToOrientation())

				targetCamera =
					CFrame.new(replayBall.Position) *
					cameraRotation *
					CFrame.Angles(
						x * 3 * math.clamp((highestY - 50) / 99, 0, 1),
						0,
						0
					) *
					cameraOffset
			else
				targetCamera =
					CFrame.new(replayBall.Position) *
					cameraRotation *
					cameraOffset
			end

			camera.CFrame = targetCamera

			local change = data.changes[currentChange]

			if change and change.frame <= frame1 then
				currentChange += 1

				if change.frame == frame1 then
					if change.poss and (frame1 > 9 and (change.turnover or highestY > 49)) then
						local nextRotation =
							change.poss == 'h' and homeCamera or awayCamera

						local duration =
							(change.turnover == true or replayBall.Position.Y >= 13)
							and 0.5
							or (highestY / 500)

						local elapsed = 0
						local startRotation = cameraRotation

						while elapsed < duration do
							elapsed += heartbeat:Wait()

							cameraRotation = startRotation:Lerp(
								nextRotation,
								math.clamp(elapsed / duration, 0, 1)
							)

							camera.CFrame =
								CFrame.new(replayBall.Position) *
								cameraRotation *
								cameraOffset
						end

						cameraRotation = nextRotation

					elseif change.freeze then
						task.wait(change.freeze)
					end
				end
			end

			heartbeat:Wait()
		end

		remote:FireServer('ReplayFinished')

		if replicatedStorage.Flags.StatusTag.Value == 'REPLAY' then
			replicatedStorage.Flags.StatusTag.Value = ''
		end

		task.wait(0.2)

		replayBall:Destroy()

		for _, character in next, characters do
			character:Destroy()
		end

		data.t = nil
		data.limbs = nil
		data.ball = nil

		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = player.Character.Humanoid
	end

	remote.OnClientEvent:Connect(function(action, ...)
		if action == 'ClientReplay' then
			while transition.Position.X.Scale > -2 and transition.Position.X.Scale < -0.5 do
				task.wait()
			end

			replay(...)
		end
	end)

end
