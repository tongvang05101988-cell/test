-- Methane O1 bootstrap: safe run_on_actor with fallback
local function __methaneRun(body)
    local actor
    pcall(function()
        if type(getactors) == "function" then
            local list = getactors()
            if type(list) == "table" then
                actor = list[1]
            end
        end
    end)
    if actor ~= nil and type(run_on_actor) == "function" then
        return run_on_actor(actor, body)
    end
    -- No actor available — execute on current thread
    local fn, err = loadstring(body)
    if not fn then
        error("[Methane] load failed: " .. tostring(err), 0)
    end
    return fn()
end

__methaneRun([[

    -- ==================== SERVICE DEFINITIONS ====================
    local game = game or shared.game or (getfenv and getfenv(0).game)
    local Players           = game:GetService("Players")
    local UserInputService  = game:GetService("UserInputService")
    local TweenService      = game:GetService("TweenService")
    local RunService        = game:GetService("RunService")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Workspace         = game:GetService("Workspace")
    local Lighting          = game:GetService("Lighting")
    local GuiService        = game:GetService("GuiService")
    local TextService       = game:GetService("TextService")
    local HttpService       = game:GetService("HttpService")
    local LocalPlayer       = Players.LocalPlayer
    -- =============================================================

    local ESP = nil
    local playerToViewmodel = {}
    local GetTarget
    do
        --// Luraph Macros

        if LPH_OBFUSCATED == nil then -- Must wrap in an "if" statement: "The macro 'LPH_NO_VIRTUALIZE' cannot be assigned to. Check if LPH_OBFUSCATED is nil before assigning to macros."
    	LPH_NO_VIRTUALIZE = function(...)
    		return ...
    	end
        end

        --// Caching

        local game, workspace = game, workspace
        local assert, loadstring, select, next, type, typeof, pcall, setmetatable, tick, warn = assert, loadstring, select, next, type, typeof, pcall, setmetatable, tick, warn
        local mathfloor, mathabs, mathcos, mathsin, mathrad, mathdeg, mathmin, mathmax, mathclamp, mathrandom = math.floor, math.abs, math.cos, math.sin, math.rad, math.deg, math.min, math.max, math.clamp, math.random
        local stringformat, stringfind, stringchar = string.format, string.find, string.char
        local unpack = table.unpack
        local wait, spawn = task.wait, task.spawn
        local getgenv, getrawmetatable, gethiddenproperty, cloneref, clonefunction = getgenv, getrawmetatable, gethiddenproperty or function(self, Index)
    	return self[Index]
        end, cloneref or function(...)
    	return ...
        end, clonefunction or function(...)
    	return ...
        end

        --// Custom Drawing Library

        if not Drawing or not Drawing.new or not Drawing.Fonts then
            game.Players.LocalPlayer:Kick("please use an executor with a drawing library! we recommend synapse z, you can purchase keys at https://rbxkey.store/")
        end

        --// References


            local cloneref = cloneref or function(...)
    	return ...
            end

            local HttpService, ConfigLibrary = cloneref(game:GetService("HttpService")), {}

            ConfigLibrary.Encode = function(Table)
    	assert(Table, "ConfigLibrary.Encode => Parameter \"Table\" is missing!")
    	assert(type(Table) == "table", "ConfigLibrary.Encode => Parameter \"Table\" must be of type <table>. Type given: <"..type(Table)..">")

    	if Table and type(Table) == "table" then
    		return HttpService:JSONEncode(Table)
    	end
            end
            ConfigLibrary.Decode = function(Content)
    	assert(Content, "ConfigLibrary.Decode => Parameter \"Content\" is missing!")
    	assert(type(Content) == "string", "ConfigLibrary.Decode => Parameter \"Content\" must be of type <string>. Type given: <"..type(Content)..">")

    	return HttpService:JSONDecode(Content)
            end

            ConfigLibrary.Recursive = function(self, Table, Callback)
    	assert(Table, "ConfigLibrary.Recursive => Parameter \"Table\" is missing!")
    	assert(Callback, "ConfigLibrary.Recursive => Parameter \"Callback\" is missing!")
    	assert(type(Table) == "table", "ConfigLibrary.Recursive => Parameter \"Table\" must be of type <table>. Type given: <"..type(Table)..">")
    	assert(type(Callback) == "function", "ConfigLibrary.Recursive => Parameter \"Callback\" must be of type <string>. Type given: <"..type(Callback)..">")

    	for Index, Value in next, Table do
    		Callback(Index, Value)

    		if type(Value) == "table" then
    			self:Recursive(Value, Callback)
    		end
    	end
            end

            ConfigLibrary.EditValue = function(Value)
    	if typeof(Value) == "Color3" then
    		return "Color3_("..math.floor(Value.R * 255)..", "..math.floor(Value.G * 255)..", "..math.floor(Value.B * 255)..")"
    	elseif typeof(Value) == "Vector3" or typeof(Value) == "Vector2" or typeof(Value) == "CFrame" then
    		return typeof(Value).."_("..tostring(Value)..")"
    	elseif typeof(Value) == "EnumItem" then
    		return "EnumItem_("..string.match(tostring(Value), "Enum%.(.+)")..")"
    	end

    	return Value
            end

            ConfigLibrary.RestoreValue = function(Value)
    	if type(Value) == "string" then
    		local Type, Content = string.match(Value, "(%w+)_%((.+)%)")

    		if Type == "Color3" then
    			Content = string.split(Content, ", ")

    			for Index, _Value in next, Content do
    				Content[Index] = tonumber(_Value)
    			end

    			return Color3.fromRGB(table.unpack(Content))
    		elseif Type == "Vector3" or Type == "Vector2" or Type == "CFrame" then
    			Content = string.split(Content, ", ")

    			for Index, _Value in next, Content do
    				Content[Index] = tonumber(_Value)
    			end

    			return getfenv()[Type].new(table.unpack(Content))
    		elseif Type == "EnumItem" then
    			return loadstring("return Enum."..Content)()
    		end
    	end

    	return Value
            end

            ConfigLibrary.CloneTable = function(self, Object, Seen)
    	if type(Object) ~= "table" then return Object end
    	if Seen and Seen[Object] then return Seen[Object] end

    	local LocalSeen = Seen or {}
    	local Result = setmetatable({}, getmetatable(Object))

    	LocalSeen[Object] = Result

    	for Index, Value in next, Object do
    		Result[self:CloneTable(Index, LocalSeen)] = self:CloneTable(Value, LocalSeen)
    	end

    	return Result
            end

            ConfigLibrary.ConvertValues = function(self, Data, Method)
    	assert(Data, "ConfigLibrary.ConvertValues => Parameter \"Data\" is missing!")
    	assert(Method, "ConfigLibrary.ConvertValues => Parameter \"Method\" is missing!")
    	assert(type(Data) == "table", "ConfigLibrary.ConvertValues => Parameter \"Data\" must be of type <table>. Type given: <"..type(Data)..">")
    	assert(type(Method) == "string", "ConfigLibrary.ConvertValues => Parameter \"Method\" must be of type <string>. Type given: <"..type(Method)..">")

    	local Passed, Stack = {[Data] = true}, {Data}

    	repeat
    		local Current = table.remove(Stack) -- "Pop"

    		for Index, Value in next, Current do
    			if type(Value) == "table" and not Passed[Value] then
    				Passed[Value] = true
    				Stack[#Stack + 1] = Value -- "Push" to stack
    			else
    				Current[Index] = self[Method.."Value"](Value)
    			end
    		end
    	until #Stack == 0

    	return Data
            end

            ConfigLibrary.SaveConfig = function(self, Path, Data)
    	assert(Path, "ConfigLibrary.SaveConfig => Parameter \"Path\" is missing!")
    	assert(Data, "ConfigLibrary.SaveConfig => Parameter \"Data\" is missing!")
    	assert(type(Path) == "string", "ConfigLibrary.SaveConfig => Parameter \"Path\" must be of type <string>. Type given: <"..type(Path)..">")
    	assert(type(Data) == "table", "ConfigLibrary.SaveConfig => Parameter \"Data\" must be of type <table>. Type given: <"..type(Data)..">")

    	local Result = self.Encode(self:ConvertValues(self:CloneTable(Data), "Edit"))

    	if select(2, pcall(function() readfile(Path) end)) then
    		self.CreatePath(self, Path, Result)
    	end

    	writefile(Path, Result)
            end

            ConfigLibrary.LoadConfig = function(self, Path)
    	assert(Path, "ConfigLibrary.LoadConfig => Parameter \"Path\" is missing!")
    	assert(type(Path) == "string", "ConfigLibrary.LoadConfig => Parameter \"Path\" must be of type <string>. Type given: <"..type(Path)..">")

    	return self:ConvertValues(self.Decode(readfile(Path)), "Restore")
            end

            ConfigLibrary.CreatePath = function(self, Path, Content)
    	assert(Path, "ConfigLibrary.CreatePath => Parameter \"Path\" is missing!")
    	assert(type(Path) == "string", "ConfigLibrary.CreatePath => Parameter \"Path\" must be of type <string>. Type given: <"..type(Path)..">")

    	local Folders, Destination, File = string.split(Path, "/"), ""
    	File = Folders[#Folders]; table.remove(Folders)

    	for Index = 1, #Folders do
    		Destination = Destination..Folders[Index].."/"

    		if not isfolder(Destination) then
    			makefolder(Destination)
    		end
    	end

    	if not isfile(Destination..File) then
    		writefile(Destination..File, Content or "")
    	end
            end


        local Vector2new, Vector3new, Vector3zero, CFramenew, Instancenew = Vector2.new, Vector3.new, Vector3.zero, CFrame.new, Instance.new
        local Drawingnew, DrawingFonts = Drawing and Drawing.new, Drawing and Drawing.Fonts
        local Color3fromRGB, Color3fromHSV = Color3.fromRGB, Color3.fromHSV
        local WorldToViewportPoint, GetPlayers, GetMouseLocation

        local GameMetatable = getrawmetatable and getrawmetatable(game) or {
    	-- Auxillary functions - if the executor doesn't support "getrawmetatable".

    	__index = LPH_NO_VIRTUALIZE(function(self, Index)
    		return self[Index]
    	end),

    	__newindex = LPH_NO_VIRTUALIZE(function(self, Index, Value)
    		self[Index] = Value
    	end)
        }

        local __index = GameMetatable.__index
        local __newindex = GameMetatable.__newindex

        local getrenderproperty, setrenderproperty = getrenderproperty or __index, setrenderproperty or __newindex

        local _get, _set = LPH_NO_VIRTUALIZE(function(self, Index)
    	return self[Index]
        end), LPH_NO_VIRTUALIZE(function(self, Index, Value)
    	self[Index] = Value
        end)

        if identifyexecutor() == "Solara" then
    	local DrawQuad = loadstring(game.HttpGet(game, "https://raw.githubusercontent.com/Exunys/Custom-Quad-Render-Object/main/Main.lua"))() -- Custom Quad Drawing Object
    	local _Drawingnew = clonefunction(Drawing.new)

    	Drawingnew = LPH_NO_VIRTUALIZE(function(...)
    		return ({...})[1] == "Quad" and DrawQuad(...) or _Drawingnew(...)
    	end)
        end

        local _GetService = __index(game, "GetService")
        local FindFirstChild, WaitForChild = __index(game, "FindFirstChild"), __index(game, "WaitForChild")
        local IsA = __index(game, "IsA")

        local GetService = function(Service)
    	return cloneref(_GetService(game, Service))
        end

        local Workspace = GetService("Workspace")
        local Players = GetService("Players")
        local RunService = GetService("RunService")
        local UserInputService = GetService("UserInputService")
        local StateObject = require(cloneref(game:GetService("ReplicatedStorage")).Modules.StateObject)
        -- expose for gadget team-check (outside this do-block)
        getgenv()._StrideStateObject = StateObject

        local CurrentCamera = __index(Workspace, "CurrentCamera")
        local LocalPlayer = __index(Players, "LocalPlayer")

        local FindFirstChildOfClass = LPH_NO_VIRTUALIZE(function(self, ...)
    	return typeof(self) == "Instance" and self.FindFirstChildOfClass(self, ...)
        end)

        local Cache = {
    	WorldToViewportPoint = __index(CurrentCamera, "WorldToViewportPoint"),
    	GetPlayers = __index(Players, "GetPlayers"),
    	GetPlayerFromCharacter = __index(Players, "GetPlayerFromCharacter"),
    	GetMouseLocation = __index(UserInputService, "GetMouseLocation")
        }

                -- FP eye for ESP while 3rd person is active (orbit cam must NOT drive projection)
        getgenv().MethaneFpEyeCF = function()
            local cam = workspace.CurrentCamera
            if not cam then return nil end
            -- Must match the rendered view (incl. 3rd person) so ESP sticks
            return cam.CFrame, cam.FieldOfView
        end

        
        local function EspBindStep(fn)
            -- Use RunService directly — Connect helper is declared later in this scope
            local rs = RunService or game:GetService("RunService")
            return rs.RenderStepped:Connect(fn)
        end

WorldToViewportPoint = LPH_NO_VIRTUALIZE(function(worldPos, ...)
            -- Always project with the LIVE render camera so ESP sticks to on-screen models
            -- (including 3rd person orbit). Never use a virtual FP eye for Drawing ESP.
            local cam = workspace.CurrentCamera or CurrentCamera
            if not cam then
                return Vector3.new(0, 0, 0), false
            end
            return Cache.WorldToViewportPoint(cam, worldPos, ...)
        end)

        GetPlayers = LPH_NO_VIRTUALIZE(function()
    	return Cache.GetPlayers(Players)
        end)

        GetPlayerFromCharacter = LPH_NO_VIRTUALIZE(function(...)
    	return Cache.GetPlayerFromCharacter(Players, ...)
        end)

        GetMouseLocation = LPH_NO_VIRTUALIZE(function()
    	return Cache.GetMouseLocation(UserInputService)
        end)

        local IsDescendantOf = LPH_NO_VIRTUALIZE(function(self, ...)
    	return typeof(self) == "Instance" and __index(self, "IsDescendantOf")(self, ...)
        end)

        --// Optimized functions / methods

        local Connect, Disconnect = __index(game, "DescendantAdded").Connect

        do
    	local TemporaryConnection = Connect(__index(game, "DescendantAdded"), function() end)
    	Disconnect = TemporaryConnection.Disconnect
    	Disconnect(TemporaryConnection)
        end

        --// Variables

        local Inf, Nan, Loaded, Restarting, CrosshairParts = 1 / 0, 0 / 0, false, false, {}

        local ValidProperties = {
    	--Color = true,
    	Visible = true,
    	Outline = true,
    	Transparency = true,
    	Thickness = true,
    	Center = true,
    	Filled = true,
    	Radius = true,
    	NumSides = true,
    	Font = true
        }

        --// Core Parameters

        local FrameTick = tick()
        local Rainbow = Color3fromRGB(255, 255, 255)
        local CameraCFrame = __index(CurrentCamera, "CFrame")
        local CameraViewportSize = __index(CurrentCamera, "ViewportSize")

        --// Checking for multiple processes

        if ExunysDeveloperESP and ExunysDeveloperESP.Exit then
    	ExunysDeveloperESP:Exit()
        end

        --// Settings

        getgenv().ExunysDeveloperESP = {
    	DeveloperSettings = {
    		Path = "Exunys Developer/Exunys ESP/Configuration.cfg",
    		UnwrapOnCharacterAbsence = false,
    		DisableWarnings = false,
    		UpdateMode = "RenderStepped",
    		TeamCheckOption = "Team",
    		SkeletonR6HeightModifier = 0.35, -- 0.0 - 1.0
    		RainbowSpeed = 1, -- Bigger = Slower
    		WidthBoundary = 1.5, -- Smaller value = Bigger width
    		Throttle = false, -- Update tankier functions less frequently. Instead of 60 updates per second, it will be around 30-40 updates per second. Helps preserve FPS.
    		ThrottleStep = 2 -- 2 - 4 - Higher value = Less updates.
    	},

    	Settings = {
    		Enabled = true,
    		PartsOnly = false,
    		TeamCheck = false,
    		AliveCheck = true,
    		EnableTeamColors = false,
    		TeamColor = Color3fromRGB(170, 170, 255),
    		CachePositions = true,
    		EntityESP = false
    	},

    	Properties = {
    		ESP = {
    			Enabled = false,
    			RainbowColor = false,
    			RainbowOutlineColor = false,
    			Offset = 10,
    			RelativeFontSize = true, -- Font size changes depending on the player's distance. Looks better for longer distances.

    			Color = Color3fromRGB(255, 255, 255),
    			Transparency = 1,
    			Size = 14,
    			Font = DrawingFonts.Plex, -- Direct2D Fonts: {UI, System, Plex, Monospace}; ROBLOX Fonts: {Roboto, Legacy, SourceSans, RobotoMono}

    			OutlineColor = Color3fromRGB(0, 0, 0),
    			Outline = true,

    			DisplayDistance = true,
    			DisplayHealth = false,
    			DisplayName = true,
    			DisplayDisplayName = false,
    			DisplayTool = true
    		},

    		Tracer = {
    			Enabled = false,
    			RainbowColor = false,
    			RainbowOutlineColor = false,
    			Position = 1, -- 1 = Bottom; 2 = Center; 3 = Mouse

    			Transparency = 1,
    			Thickness = 1,
    			Color = Color3fromRGB(255, 255, 255),

    			OutlineColor = Color3fromRGB(0, 0, 0),
    			Outline = true
    		},

    		Box = {
    			Enabled = false,
    			RainbowColor = false,
    			RainbowOutlineColor = false,

    			Type = 3, -- 1 = Square; 2 = Quad; 3 = Corner
    			FillSquare = false,
    			FillColor = Color3fromRGB(255, 255, 255),
    			FillRainbowColor = false,
    			FillTransparency = 0.18,
    			LineSize = 14, -- For corner box option: Min = 2; Max = 20

    			Color = Color3fromRGB(255, 255, 255),
    			Transparency = 1,
    			Thickness = 1,

    			OutlineColor = Color3fromRGB(0, 0, 0),
    			Outline = true,
    			-- Gradient: top corners white, bottom corners soft blue
    			Gradient = false,
    			GradientTop = Color3fromRGB(255, 255, 255),
    			GradientBottom = Color3fromRGB(120, 170, 255),
    		},

    		HealthBar = {
    			Enabled = false,
    			RainbowOutlineColor = false,
    			Offset = 4,
    			Blue = 0,
    			Position = 3, -- 1 = Top; 2 = Bottom; 3 = Left; 4 = Right

    			Thickness = 2,
    			Transparency = 1,

    			OutlineColor = Color3fromRGB(0, 0, 0),
    			Outline = true,
    			-- Gradient always drawn along bar height (top=full green, bottom=low red)
    			GradientTop = Color3fromRGB(255, 255, 255),
    			GradientMid = Color3fromRGB(120, 170, 255),
    			GradientBottom = Color3fromRGB(120, 170, 255),
    			ShowText = true,
    			TextSize = 10,
    		},

    		Skeleton = {
    			Enabled = false,
    			RainbowColor = false,

    			Transparency = 1,
    			Thickness = 1,
    			Color = Color3fromRGB(255, 255, 255),

    			-- Gradient: top = white, bottom = soft blue (same palette as box)
    			Gradient = false,
    			GradientTop = Color3fromRGB(255, 255, 255),
    			GradientBottom = Color3fromRGB(120, 170, 255),
    		},

    		-- BoxHandleAdornment player chams (O1 viewmodel hitboxes)
    		Chams = {
    			Enabled = false,
    			Mode = "Fill", -- Fill | Flow | Flat
    			FillColor = Color3fromRGB(120, 170, 255),
    			FillColor2 = Color3fromRGB(255, 60, 60),
    			FillTransparency = 0.55,
    			OutlineTransparency = 0.15,
    			VisibleOnly = false,
    		},

    	},

    	UtilityAssets = {
    		WrappedObjects = {},
    		ServiceConnections = {}
    	}
        }

        local Environment, _warn = getgenv().ExunysDeveloperESP, clonefunction(warn); warn = function(...)
    	return not Environment.DeveloperSettings.DisableWarnings and _warn(...)
        end

        --// Functions

        local function Recursive(Table, Callback)
    	for Index, Value in next, Table do
    		Callback(Index, Value)

    		if type(Value) == "table" then
    			Recursive(Value, Callback)
    		end
    	end
        end

        local CoreFunctions; LPH_NO_VIRTUALIZE(function()
    	CoreFunctions = {
    		ConvertVector = function(Vector)
    			return Vector2new(Vector.X, Vector.Y)
    		end,

    		GetColorFromHealth = function(Health, MaxHealth, Blue)
    			return Color3fromRGB(255 - mathfloor(Health / MaxHealth * 255), mathfloor(Health / MaxHealth * 255), Blue or 0)
    		end,

    		GetRainbowColor = function()
    			local RainbowSpeed = Environment.DeveloperSettings.RainbowSpeed

    			return Color3fromHSV(FrameTick % RainbowSpeed / RainbowSpeed, 1, 1)
    		end,

    		GetLocalCharacterPosition = function()
    			local LocalCharacter = __index(LocalPlayer, "Character")
    			local LocalPlayerCheckPart = LocalCharacter and (__index(LocalCharacter, "PrimaryPart") or FindFirstChild(LocalCharacter, "Head"))

    			return LocalPlayerCheckPart and __index(LocalPlayerCheckPart, "Position") or CameraCFrame.Position
    		end,

    		GenerateHash = function(Bits)
    			local Result = ""

    			for _ = 1, Bits do
    				Result ..= ("EXUNYS_ESP")[mathrandom(1, 2) == 1 and "upper" or "lower"](stringchar(mathrandom(97, 122)))
    			end

    			return Result
    		end,

    		CalculateParameters = function(Object)
    			Object = type(Object) == "table" and Object.Object or Object

    			local Entry = type(Object) == "table" and Object or nil

    			if Entry then
    				Entry._Cache = Entry._Cache or {}
    				-- Never reuse cached screen pos while camera can move (3rd person)
    			end

    			local DeveloperSettings = Environment.DeveloperSettings
    			local WidthBoundary = DeveloperSettings.WidthBoundary

    			local IsAPlayer, Part = IsA(Object, "Player")

    			if IsAPlayer then
    				local vm = playerToViewmodel[Object]
    				if vm then
    					Part = (__index(vm, "PrimaryPart") or FindFirstChild(vm, "torso") or FindFirstChild(vm, "head"))
    				end
    			else
    				if IsA(Object, "Model") then
    					Part = __index(Object, "PrimaryPart")
    				else
    					Part = Object
    				end
    			end

    			if not Part or IsA(Part, "Player") or IsA(Part, "Model") or not IsDescendantOf(Part, Workspace) then
    				return nil, nil, false, nil, nil
    			end

    			local PartCFrame, PartPosition = __index(Part, "CFrame"), __index(Part, "Position")
    			local PartUpVector = PartCFrame.UpVector

    			local PartParent = __index(Part, "Parent")
    			local RigType = PartParent and FindFirstChild(PartParent, "Torso") and "R6" or "R15"

    			-- Live camera for projection only — height uses WORLD up so boxes don't slide with cam tilt
    			do
    				local camLive = workspace.CurrentCamera or CurrentCamera
    				if camLive then
    					CameraCFrame = __index(camLive, "CFrame")
    					CameraViewportSize = __index(camLive, "ViewportSize")
    				end
    			end

    			local worldUp = Vector3.new(0, 1, 0)
    			local topOff = (RigType == "R6") and 0.5 or 1.8
    			local botOff = (RigType == "R6") and 4 or 2.5
    			local Top, TopOnScreen = WorldToViewportPoint(PartPosition + worldUp * topOff)
    			local Bottom, BottomOnScreen = WorldToViewportPoint(PartPosition - worldUp * botOff)

    			local TopX, TopY = Top.X, Top.Y
    			local BottomX, BottomY = Bottom.X, Bottom.Y

    			local Width = mathmax(mathfloor(mathabs(TopX - BottomX)), 3)
    			local Height = mathmax(mathfloor(mathmax(mathabs(BottomY - TopY), Width / 2)), 3)
    			local BoxSize = Vector2new(mathfloor(mathmax(Height / (IsAPlayer and WidthBoundary or 1), Width)), Height)
    			local BoxPosition = Vector2new(mathfloor(TopX / 2 + BottomX / 2 - BoxSize.X / 2), mathfloor(mathmin(TopY, BottomY)))

    			if Entry then
    				local _Cache = Entry._Cache
    				_Cache.Tick = FrameTick
    				_Cache.Position = BoxPosition
    				_Cache.Size = BoxSize
    				_Cache.Visible = (TopOnScreen and BottomOnScreen)
    				_Cache.Top = Top
    				_Cache.Bottom = Bottom
    			end

    			return BoxPosition, BoxSize, (TopOnScreen and BottomOnScreen), Top, Bottom
    		end,

    		Calculate3DQuad = function(_CFrame, SizeVector, YVector)
    			YVector = YVector or SizeVector

    			return {

    				--// Quad 1 - Front

    				{
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, YVector.Y, SizeVector.Z).Position), -- Top Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, YVector.Y, SizeVector.Z).Position), -- Top Right
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, -YVector.Y, SizeVector.Z).Position), -- Bottom Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, -YVector.Y, SizeVector.Z).Position) -- Bottom Right
    				},


    				--// Quad 2 - Back

    				{
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, YVector.Y, -SizeVector.Z).Position), -- Top Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, YVector.Y, -SizeVector.Z).Position), -- Top Right
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, -YVector.Y, -SizeVector.Z).Position), -- Bottom Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, -YVector.Y, -SizeVector.Z).Position) -- Bottom Right
    				},

    				--// Quad 3 - Top

    				{
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, YVector.Y, SizeVector.Z).Position), -- Top Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, YVector.Y, SizeVector.Z).Position), -- Top Right
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, YVector.Y, -SizeVector.Z).Position), -- Bottom Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, YVector.Y, -SizeVector.Z).Position) -- Bottom Right
    				},

    				--// Quad 4 - Bottom

    				{
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, -YVector.Y, SizeVector.Z).Position), -- Top Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, -YVector.Y, SizeVector.Z).Position), -- Top Right
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, -YVector.Y, -SizeVector.Z).Position), -- Bottom Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, -YVector.Y, -SizeVector.Z).Position) -- Bottom Right
    				},

    				--// Quad 5 - Right

    				{
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, YVector.Y, SizeVector.Z).Position), -- Top Left
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, YVector.Y, -SizeVector.Z).Position), -- Top Right
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, -YVector.Y, SizeVector.Z).Position), -- Bottom Left
    					WorldToViewportPoint(_CFrame * CFramenew(SizeVector.X, -YVector.Y, -SizeVector.Z).Position) -- Bottom Right
    				},

    				--// Quad 6 - Left

    				{
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, YVector.Y, SizeVector.Z).Position), -- Top Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, YVector.Y, -SizeVector.Z).Position), -- Top Right
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, -YVector.Y, SizeVector.Z).Position), -- Bottom Left
    					WorldToViewportPoint(_CFrame * CFramenew(-SizeVector.X, -YVector.Y, -SizeVector.Z).Position) -- Bottom Right
    				}
    			}
    		end,

    		GetColor = function(Player, DefaultColor)
    			local Settings = Environment.Settings

    			return Settings.EnableTeamColors and Player:GetAttribute("Team") == LocalPlayer:GetAttribute("Team") and Settings.TeamColor or DefaultColor
    		end
    	}
        end)()

        local UpdatingFunctions; LPH_NO_VIRTUALIZE(function()
    	UpdatingFunctions = {
    		ESP = function(Entry, TopTextObject, BottomTextObject)
    			local Settings = Environment.Properties.ESP

    			local Position, Size, OnScreen, Top, Bottom = CoreFunctions.CalculateParameters(Entry)

    			setrenderproperty(TopTextObject, "Visible", OnScreen)
    			setrenderproperty(BottomTextObject, "Visible", OnScreen)

    			if OnScreen then
    				for Index, Value in next, Settings do
    					if ValidProperties[Index] then
    						setrenderproperty(TopTextObject, Index, Value)
    						setrenderproperty(BottomTextObject, Index, Value)
    					end
    				end

    				local FontSize = Settings.RelativeFontSize and mathclamp(mathabs((Top - Bottom).Y) - 3, 6, Settings.Size) or Settings.Size

    				setrenderproperty(TopTextObject, "Size", FontSize)
    				setrenderproperty(BottomTextObject, "Size", FontSize)

    				local GetColor = CoreFunctions.GetColor

    				local MainColor = GetColor(Entry.Object, Settings.RainbowColor and Rainbow or Settings.Color)
    				local OutlineColor = Settings.RainbowOutlineColor and Rainbow or Settings.OutlineColor

    				setrenderproperty(TopTextObject, "Color", MainColor)
    				setrenderproperty(TopTextObject, "OutlineColor", OutlineColor)
    				setrenderproperty(BottomTextObject, "Color", MainColor)
    				setrenderproperty(BottomTextObject, "OutlineColor", OutlineColor)

    				local Offset = mathclamp(Settings.Offset, 10, 30)
    				local LabelsXPosition = Position.X + (Size.X / 2)

    				local Player, IsAPlayer = Entry.Object, Entry.IsAPlayer
    				local Name, DisplayName = Entry.Name, Entry.DisplayName

    				local Character = IsAPlayer and __index(Player, "Character") or Player
    				local Humanoid = FindFirstChildOfClass(Character, "Humanoid")
    				local Health, MaxHealth = Humanoid and __index(Humanoid, "Health") or Nan, Humanoid and __index(Humanoid, "MaxHealth") or Nan

    				-- O1: weapon name from StateObject states.equipped (not Roblox Tool)
    				local Tool = nil
    				if Settings.DisplayTool and IsAPlayer then
    					pcall(function()
    						for _, characterObj in StateObject.get_all("Character") do
    							local owner = characterObj.owner and characterObj.owner:get()
    							if owner == Player then
    								local eq = characterObj.states and characterObj.states.equipped
    								if eq then
    									local val = type(eq) == "table" and eq.get and eq:get() or eq
    									if val and val ~= "" then
    										Tool = { _name = tostring(val) }
    									end
    								end
    								break
    							end
    						end
    					end)
    				end

    				local TopContent = ""

    				-- Username only (never display name / brackets)
    				if Settings.DisplayName or Settings.DisplayDisplayName then
    					TopContent = Name or DisplayName or ""
    				end

    				if Settings.DisplayHealth and IsAPlayer then
    					TopContent = stringformat("[%s / %s] %s", mathfloor(Health), MaxHealth, TopContent)
    				end

    				if Entry._LastTopText ~= TopContent then
    					Entry._LastTopText = TopContent
    					setrenderproperty(TopTextObject, "Text", TopContent)
    				end

    				Entry._DistFrame = (Entry._DistFrame or 0) + 1

    				if Entry._DistFrame % 3 == 0 then
    					local _posPart = nil
    					if IsAPlayer then
    						_posPart = __index(Character, "PrimaryPart") or FindFirstChild(Character, "Head") or FindFirstChild(Character, "HumanoidRootPart")
    					else
    						_posPart = Character
    					end
    					local PlayerPosition = (_posPart and __index(_posPart, "Position")) or Vector3zero
    					Entry._Distance = Settings.DisplayDistance and mathfloor((PlayerPosition - CoreFunctions.GetLocalCharacterPosition()).Magnitude)
    				end

    				local Distance = Entry._Distance

    				local BottomContent = Distance and stringformat("%s Studs", Distance) or ""

    				if Tool then
    					local ToolName = (type(Tool) == "table" and Tool._name) or nil
    					if not ToolName then pcall(function() ToolName = __index(Tool, "Name") end) end
    					ToolName = ToolName or tostring(Tool)
    					if ToolName and ToolName ~= "" then
    						BottomContent = BottomContent..((Distance and "\n" or "")..ToolName)
    					end
    				end

    				if Entry._LastBottomText ~= BottomContent then
    					Entry._LastBottomText = BottomContent
    					setrenderproperty(BottomTextObject, "Text", BottomContent)
    				end

    				if Entry.PositionChanged then
    					setrenderproperty(TopTextObject, "Position", Vector2new(LabelsXPosition, Top.Y - Offset * 2.05))
    					setrenderproperty(BottomTextObject, "Position", Vector2new(LabelsXPosition, Bottom.Y + Offset / 2))
    				end
    			end
    		end,

    		Tracer = function(Entry, TracerObject, TracerOutlineObject)
    			local Settings = Environment.Properties.Tracer

    			local Position, Size, OnScreen = CoreFunctions.CalculateParameters(Entry)

    			setrenderproperty(TracerObject, "Visible", OnScreen)
    			setrenderproperty(TracerOutlineObject, "Visible", OnScreen and Settings.Outline)

    			if OnScreen then
    				for Index, Value in next, Settings do
    					if ValidProperties[Index] then
    						setrenderproperty(TracerObject, Index, Value)
    					end
    				end

    				setrenderproperty(TracerObject, "Color", CoreFunctions.GetColor(Entry.Object, Settings.RainbowColor and Rainbow or Settings.Color))

    				if Settings.Position == 1 then
    					setrenderproperty(TracerObject, "From", Vector2new(CameraViewportSize.X / 2, CameraViewportSize.Y))
    				elseif Settings.Position == 2 then
    					setrenderproperty(TracerObject, "From", CameraViewportSize / 2)
    				elseif Settings.Position == 3 then
    					setrenderproperty(TracerObject, "From", GetMouseLocation())
    				else
    					Settings.Position = 1
    				end

    				if Entry.PositionChanged then
    					setrenderproperty(TracerObject, "To", Vector2new(Position.X + (Size.X / 2), Position.Y + Size.Y))
    				end

    				if Settings.Outline then
    					setrenderproperty(TracerOutlineObject, "Color", Settings.RainbowOutlineColor and Rainbow or Settings.OutlineColor)
    					setrenderproperty(TracerOutlineObject, "Thickness", Settings.Thickness + 1)
    					setrenderproperty(TracerOutlineObject, "Transparency", Settings.Transparency)

    					setrenderproperty(TracerOutlineObject, "From", getrenderproperty(TracerObject, "From"))

    					if not Entry.PositionChanged then
    						return
    					end

    					setrenderproperty(TracerOutlineObject, "To", getrenderproperty(TracerObject, "To"))
    				end
    			end
    		end,

    		Box = function(Entry, BoxParts, BoxOutlines, SquareBox, FillBox, Quads)
    			local Settings = Environment.Properties.Box
    			local DeveloperSettings = Environment.DeveloperSettings

    			local Position, Size, OnScreen = CoreFunctions.CalculateParameters(Entry)

    			local ConvertVector = CoreFunctions.ConvertVector

    			local Object = Entry.Object
    			local IsAPlayer = Entry.IsAPlayer

    			local Character = IsAPlayer and __index(Object, "Character") or __index(Object, "Parent")

    			if Character == Players then
    				return
    			end

    			local Primary = Character and (__index(Character, "PrimaryPart") or FindFirstChild(Character, "HumanoidRootPart"))

    			Primary = Primary or not IsAPlayer and Object

    			if not Primary and IsAPlayer then
    				local _vm = playerToViewmodel[Object]
    				Primary = _vm and (FindFirstChild(_vm, "torso") or FindFirstChild(_vm, "head"))
    			end

    			local Type, Fill = Settings.Type, Settings.FillSquare

    			local SquareBoxObject = SquareBox[1]
    			local SquareBoxOutline = SquareBox[2]

    			local Visibility, Visibility3D = function(Value)
    				for Index, _Value in next, BoxParts do
    					setrenderproperty(_Value, "Visible", Value and Type == 3)
    					setrenderproperty(BoxOutlines[Index], "Visible", Value and Settings.Outline and Type == 3)
    				end
    			end, function(Value)
    				for _, _Value in next, Quads do
    					_set(_Value, "Visible", Value and Type == 2)
    				end
    			end

    			if Type == 1 then
    				setrenderproperty(SquareBoxObject, "Visible", OnScreen and Type == 1)
    				setrenderproperty(SquareBoxOutline, "Visible", OnScreen and Settings.Outline and Type == 1)
    				Visibility(false)
    				Visibility3D(false)
    			elseif Type == 2 then
    				setrenderproperty(SquareBoxObject, "Visible", false)
    				setrenderproperty(SquareBoxOutline, "Visible", false)
    				Visibility(false)
    				Visibility3D(OnScreen and Type == 2)
    			elseif Type == 3 then
    				setrenderproperty(SquareBoxObject, "Visible", false)
    				setrenderproperty(SquareBoxOutline, "Visible", false)
    				Visibility(OnScreen and Type == 3)
    				Visibility3D(false)
    			end

    			setrenderproperty(FillBox, "Visible", Fill and OnScreen and Type ~= 2)

    			if not Primary then
    				setrenderproperty(FillBox, "Visible", false)
    				setrenderproperty(SquareBoxObject, "Visible", false)
    				setrenderproperty(SquareBoxOutline, "Visible", false)
    				Visibility(false)
    				Visibility3D(false)

    				return
    			end

    			local PrimaryCFrame, PrimarySize = __index(Primary, "CFrame"), __index(Primary, "Size")
    			local _3DSize = PrimarySize * Vector3new(1.05, 1.5, 0)
    			local Top, Bottom = WorldToViewportPoint((PrimaryCFrame * CFramenew(0, PrimarySize.Y / 2, 0)).Position), WorldToViewportPoint((PrimaryCFrame * CFramenew(0, -PrimarySize.Y / 2, 0)).Position)

    			local LineSize = mathclamp(mathabs((Top - Bottom).Y) - 3, 2, mathmax(Settings.LineSize, 20))

    			if getrenderproperty(BoxParts.TopLeft_Bottom, "Visible") or getrenderproperty(SquareBoxObject, "Visible") or getrenderproperty(Quads.Top, "Visible") then
    				if Fill and Type ~= 2 then
    					setrenderproperty(FillBox, "Transparency", Settings.FillTransparency)
    					setrenderproperty(FillBox, "Thickness", 0)
    					setrenderproperty(FillBox, "Color", CoreFunctions.GetColor(Entry.Object, Settings.FillRainbowColor and Rainbow or Settings.FillColor))

    					if not Entry.PositionChanged then
    						return
    					end

    					setrenderproperty(FillBox, "Position", Position)
    					setrenderproperty(FillBox, "Size", Size)
    				end

    				if Type == 1 then -- Square Box
    					for Index, Value in next, Settings do
    						if ValidProperties[Index] then
    							setrenderproperty(SquareBoxObject, Index, Value)
    						end
    					end

    					local _sqBaseColor = CoreFunctions.GetColor(Entry.Object, Settings.RainbowColor and Rainbow or Settings.Color)
    					if Settings.Gradient and Settings.GradientTop and Settings.GradientBottom then
    						local _gt = Settings.GradientTop
    						local _gb = Settings.GradientBottom
    						_sqBaseColor = Color3.new(_gt.R*0.5+_gb.R*0.5, _gt.G*0.5+_gb.G*0.5, _gt.B*0.5+_gb.B*0.5)
    					end
    					setrenderproperty(SquareBoxObject, "Color", _sqBaseColor)

    					if not Entry.PositionChanged then
    						return
    					end

    					setrenderproperty(SquareBoxObject, "Position", Position)
    					setrenderproperty(SquareBoxObject, "Size", Size)
    				elseif Type == 2 then -- 3D Box
    					if DeveloperSettings.Throttle then
    						Entry._Frame = (Entry._Frame or 0) + 1

    						if Entry._Frame % mathclamp(DeveloperSettings.ThrottleStep, 2, 4) ~= 0 then
    							return
    						end
    					end

    					for Index, Value in next, Settings do
    						for _, RenderObject in next, Quads do
    							if ValidProperties[Index] then
    								_set(RenderObject, Index, Value)
    							end
    						end
    					end

    					for _, Value in next, Quads do
    						_set(Value, "Fill", Fill)
    						_set(Value, "Color", CoreFunctions.GetColor(Entry.Object, Settings.RainbowColor and Rainbow or Settings.Color))
    					end

    					if not Entry.PositionChanged then
    						return
    					end

    					local Indexes, Positions = {1, 3, 4, 2}, CoreFunctions.Calculate3DQuad(PrimaryCFrame, PrimarySize, _3DSize)

    					for Index, RenderObject in next, Quads do
    						for _Index = 1, 4 do
                                local tmp = Indexes[_Index]
    							_set(RenderObject, "Point"..stringchar(_Index + 64), ConvertVector(Positions[Index][tmp]))
    						end
    					end
    				elseif Type == 3 then -- Corner Box
    					for Index, Value in next, Settings do
    						for _, RenderObject in next, BoxParts do
    							if ValidProperties[Index] then
    								setrenderproperty(RenderObject, Index, Value)
    							end
    						end
    					end

    					local _baseColor = CoreFunctions.GetColor(Entry.Object, Settings.RainbowColor and Rainbow or Settings.Color)
    					local _useGrad = Settings.Gradient and Settings.GradientTop and Settings.GradientBottom
    					local _topCol = _useGrad and CoreFunctions.GetColor(Entry.Object, Settings.GradientTop) or _baseColor
    					local _botCol = _useGrad and CoreFunctions.GetColor(Entry.Object, Settings.GradientBottom) or _baseColor
    					local _topCorners = {"TopLeft_Bottom", "TopLeft_Right", "TopRight_Bottom", "TopRight_Left"}
    					local _botCorners = {"BottomLeft_Top", "BottomLeft_Right", "BottomRight_Top", "BottomRight_Left"}
    					for _, n in next, _topCorners do
    						if BoxParts[n] then setrenderproperty(BoxParts[n], "Color", _topCol) end
    					end
    					for _, n in next, _botCorners do
    						if BoxParts[n] then setrenderproperty(BoxParts[n], "Color", _botCol) end
    					end

    					if not Entry.PositionChanged then
    						return
    					end

    					setrenderproperty(BoxParts.TopLeft_Bottom, "From", Position)
    					setrenderproperty(BoxParts.TopLeft_Bottom, "To", Vector2new(Position.X, Position.Y + LineSize + LineSize / 2))
    					setrenderproperty(BoxParts.TopLeft_Right, "From", Position)
    					setrenderproperty(BoxParts.TopLeft_Right, "To", Vector2new(Position.X + LineSize, Position.Y))
    					setrenderproperty(BoxParts.TopRight_Bottom, "From", Vector2new(Position.X + Size.X, Position.Y))
    					setrenderproperty(BoxParts.TopRight_Bottom, "To", Vector2new(Position.X + Size.X, Position.Y + LineSize + LineSize / 2))
    					setrenderproperty(BoxParts.TopRight_Left, "From", Vector2new(Position.X + Size.X, Position.Y))
    					setrenderproperty(BoxParts.TopRight_Left, "To", Vector2new(Position.X + Size.X - LineSize, Position.Y))
    					setrenderproperty(BoxParts.BottomLeft_Top, "From", Vector2new(Position.X, Position.Y + Size.Y - LineSize - LineSize / 2))
    					setrenderproperty(BoxParts.BottomLeft_Top, "To", Vector2new(Position.X, Position.Y + Size.Y))
    					setrenderproperty(BoxParts.BottomLeft_Right, "From", Vector2new(Position.X, Position.Y + Size.Y))
    					setrenderproperty(BoxParts.BottomLeft_Right, "To", Vector2new(Position.X + LineSize, Position.Y + Size.Y))
    					setrenderproperty(BoxParts.BottomRight_Top, "From", Vector2new(Position.X + Size.X, Position.Y + Size.Y - LineSize - LineSize / 2))
    					setrenderproperty(BoxParts.BottomRight_Top, "To", Vector2new(Position.X + Size.X, Position.Y + Size.Y))
    					setrenderproperty(BoxParts.BottomRight_Left, "From", Vector2new(Position.X + Size.X, Position.Y + Size.Y))
    					setrenderproperty(BoxParts.BottomRight_Left, "To", Vector2new(Position.X + Size.X - LineSize, Position.Y + Size.Y))
    				end

    				if Settings.Outline then
    					if Type == 1 then
    						setrenderproperty(SquareBoxOutline, "Color", Settings.RainbowOutlineColor and Rainbow or Settings.OutlineColor)

    						setrenderproperty(SquareBoxOutline, "Thickness", Settings.Thickness + 1)
    						setrenderproperty(SquareBoxOutline, "Transparency", Settings.Transparency)

    						if not Entry.PositionChanged then
    							return
    						end

    						setrenderproperty(SquareBoxOutline, "Position", Position)
    						setrenderproperty(SquareBoxOutline, "Size", Size)
    					elseif Type == 3 then
    						for Index, Value in next, BoxOutlines do
    							setrenderproperty(Value, "Color", Settings.RainbowOutlineColor and Rainbow or Settings.OutlineColor)

    							setrenderproperty(Value, "Thickness", Settings.Thickness + 2)
    							setrenderproperty(Value, "Transparency", Settings.Transparency)

    							if not Entry.PositionChanged then
    								return
    							end

    							setrenderproperty(Value, "From", getrenderproperty(BoxParts[Index], "From"))
    							setrenderproperty(Value, "To", getrenderproperty(BoxParts[Index], "To"))
    						end
    					end
    				end
    			end
    		end,

    		HealthBar = function(Entry, MainObject, OutlineObject, Humanoid)
    			local Settings = Environment.Properties.HealthBar
    			local Position, Size, OnScreen = CoreFunctions.CalculateParameters(Entry)
    			local HB = Entry.Visuals.HealthBar
    			local segs = HB and HB.Segs
    			local outline = OutlineObject or (HB and HB.Outline)
    			local textObj = HB and HB.Text

    			local function hideAll()
    				if MainObject then setrenderproperty(MainObject, "Visible", false) end
    				if outline then setrenderproperty(outline, "Visible", false) end
    				if segs then
    					for _, ln in next, segs do
    						pcall(setrenderproperty, ln, "Visible", false)
    					end
    				end
    				if textObj then setrenderproperty(textObj, "Visible", false) end
    			end

    			if not OnScreen or not Position or not Size then
    				hideAll()
    				return
    			end

    			-- resolve humanoid (O1: Player.Character)
    			if not Humanoid or typeof(Humanoid) ~= "Instance" then
    				local char = nil
    				if Entry.IsAPlayer then
    					char = __index(Entry.Object, "Character")
    				else
    					char = Entry.Object
    				end
    				Humanoid = char and FindFirstChildOfClass(char, "Humanoid")
    			end

    			local MaxHealth = Humanoid and __index(Humanoid, "MaxHealth") or 100
    			if type(MaxHealth) ~= "number" or MaxHealth <= 0 then MaxHealth = 100 end
    			local Health = Humanoid and mathclamp(__index(Humanoid, "Health"), 0, MaxHealth) or 0
    			local frac = mathclamp(Health / MaxHealth, 0, 1)

    			local Offset = mathclamp(Settings.Offset or 4, 4, 12)
    			local thick = mathmax(Settings.Thickness or 2, 1)
    			local _gTop = Settings.GradientTop or Color3fromRGB(80, 255, 120)
    			local _gMid = Settings.GradientMid or Color3fromRGB(255, 200, 0)
    			local _gBot = Settings.GradientBottom or Color3fromRGB(255, 60, 60)

    			-- height-based gradient: hFrac 0 = bottom (low/red), 1 = top (full/green)
    			-- ALWAYS uses position on bar, not single solid color from current HP
    			local function colorAt(hFrac)
    				hFrac = mathclamp(hFrac, 0, 1)
    				local a, b, s
    				if hFrac >= 0.5 then
    					a, b, s = _gMid, _gTop, (hFrac - 0.5) * 2
    				else
    					a, b, s = _gBot, _gMid, hFrac * 2
    				end
    				return Color3.new(a.R+(b.R-a.R)*s, a.G+(b.G-a.G)*s, a.B+(b.B-a.B)*s)
    			end

    			-- left side vertical bar (default Position 3)
    			local barX = Position.X - Offset
    			local barBottom = Position.Y + Size.Y
    			local barTop = Position.Y
    			local barH = mathmax(Size.Y, 1)

    			if Settings.Position == 4 then
    				barX = Position.X + Size.X + Offset
    			end

    			-- outline = full height track
    			if Settings.Outline and outline then
    				setrenderproperty(outline, "Visible", true)
    				setrenderproperty(outline, "Color", Settings.RainbowOutlineColor and Rainbow or Settings.OutlineColor)
    				setrenderproperty(outline, "Thickness", thick + 2)
    				setrenderproperty(outline, "Transparency", Settings.Transparency)
    				setrenderproperty(outline, "From", Vector2new(barX, barBottom + 1))
    				setrenderproperty(outline, "To", Vector2new(barX, barTop - 1))
    			elseif outline then
    				setrenderproperty(outline, "Visible", false)
    			end

    			-- hide legacy single main line (replaced by segments)
    			if MainObject then setrenderproperty(MainObject, "Visible", false) end

    			local SEG_N = segs and #segs or 0
    			if SEG_N < 1 then
    				-- fallback single line colored by ratio
    				if MainObject then
    					setrenderproperty(MainObject, "Visible", true)
    					setrenderproperty(MainObject, "Color", colorAt(frac))
    					setrenderproperty(MainObject, "Thickness", thick)
    					setrenderproperty(MainObject, "From", Vector2new(barX, barBottom))
    					setrenderproperty(MainObject, "To", Vector2new(barX, barBottom - barH * frac))
    				end
    			else
    				local filled = mathfloor(SEG_N * frac + 1e-6)
    				if frac > 0 and filled < 1 then filled = 1 end
    				if frac >= 0.999 then filled = SEG_N end
    				local segH = barH / SEG_N
    				for i = 1, SEG_N do
    					local ln = segs[i]
    					if not ln then continue end
    					if i <= filled then
    						-- i=1 bottom, i=SEG_N top of full bar
    						local hFrac = (i - 0.5) / SEG_N
    						local col = colorAt(hFrac)
    						local y1 = barBottom - (i - 1) * segH
    						local y0 = barBottom - i * segH
    						setrenderproperty(ln, "Visible", true)
    						setrenderproperty(ln, "Color", col)
    						setrenderproperty(ln, "Thickness", thick)
    						setrenderproperty(ln, "Transparency", Settings.Transparency)
    						setrenderproperty(ln, "From", Vector2new(barX, y1))
    						setrenderproperty(ln, "To", Vector2new(barX, y0))
    					else
    						setrenderproperty(ln, "Visible", false)
    					end
    				end
    			end

    			-- HP text left of bar, top-aligned, max 10px
    			if textObj and Settings.ShowText ~= false then
    				local label = tostring(mathfloor(Health + 0.5))
    				local ts = mathclamp(tonumber(Settings.TextSize) or 10, 6, 10)
    				setrenderproperty(textObj, "Text", label)
    				setrenderproperty(textObj, "Size", ts)
    				setrenderproperty(textObj, "Color", Color3fromRGB(255, 255, 255))
    				setrenderproperty(textObj, "Center", false)
    				setrenderproperty(textObj, "Outline", true)
    				setrenderproperty(textObj, "OutlineColor", Color3fromRGB(0, 0, 0))
    				pcall(setrenderproperty, textObj, "Font", DrawingFonts.Plex)
    				local textW = #label * (ts * 0.55)
    				-- left of bar, near top of bar
    				setrenderproperty(textObj, "Position", Vector2new(barX - textW - 3, barTop - 1))
    				setrenderproperty(textObj, "Visible", true)
    			elseif textObj then
    				setrenderproperty(textObj, "Visible", false)
    			end
    		end,

    		Skeleton = function(Entry)
    			local Settings = Environment.Properties.Skeleton
    			local DeveloperSettings = Environment.DeveloperSettings

    			local Head, Torso
    			local RigType = Entry.RigType

    			if Entry.IsAPlayer then
    				local vm = playerToViewmodel[Entry.Object]
    				if vm then
    					Head = FindFirstChild(vm, "head")
    					Torso = FindFirstChild(vm, "torso")
    				end
    			else
    				local Character = __index(Entry.Object, "Parent")
    				Head = Character and FindFirstChild(Character, "Head")
    				Torso = Character and (FindFirstChild(Character, "HumanoidRootPart") or FindFirstChild(Character, "Torso"))
    			end

    			local Limbs = {}
    			for Index, Value in next, Entry.Visuals.Skeleton do
    				Limbs[Index] = Value
    			end

    			local Visibility = function(Value)
    				for _, _Value in next, Limbs do
    					setrenderproperty(_Value, "Visible", Value)
    				end
    			end

    			if not Head or not Torso then return Visibility(false) end

    			if DeveloperSettings.Throttle then
    				Entry._Frame = (Entry._Frame or 0) + 1
    				if Entry._Frame % mathclamp(DeveloperSettings.ThrottleStep, 2, 4) ~= 0 then return end
    			end

    			local _skelPos, _skelSize, _skelOnScreen = CoreFunctions.CalculateParameters(Entry)
    			if _skelOnScreen then
    				-- Pre-compute gradient helpers for per-limb color lerp
    				local _skelUseGrad = Settings.Gradient and Settings.GradientTop and Settings.GradientBottom
    				local _skelGTop = _skelUseGrad and Settings.GradientTop or nil
    				local _skelGBot = _skelUseGrad and Settings.GradientBottom or nil
    				local _skelBaseCol = CoreFunctions.GetColor(Entry.Object, Settings.RainbowColor and Rainbow or Settings.Color)
    				local _skelTopY = _skelPos and _skelPos.Y or 0
    				local _skelBotY = (_skelPos and _skelSize) and (_skelPos.Y + _skelSize.Y) or (_skelTopY + 1)
    				local _skelSpan = mathmax(_skelBotY - _skelTopY, 1)
    				local function _skelLimbColor(yScreen)
    					if not _skelUseGrad then return _skelBaseCol end
    					local t = mathclamp((yScreen - _skelTopY) / _skelSpan, 0, 1)
    					return Color3.new(
    						_skelGTop.R + (_skelGBot.R - _skelGTop.R) * t,
    						_skelGTop.G + (_skelGBot.G - _skelGTop.G) * t,
    						_skelGTop.B + (_skelGBot.B - _skelGTop.B) * t
    					)
    				end
    				for _, RenderObject in next, Limbs do
    					setrenderproperty(RenderObject, "Visible", true)
    					for _Index, _Value in next, Settings do
    						if ValidProperties[_Index] then
    							setrenderproperty(RenderObject, _Index, _Value)
    						end
    					end
    					-- Use midpoint Y of the limb segment for gradient, fallback to base color
    					local _fromY = getrenderproperty(RenderObject, "From") and getrenderproperty(RenderObject, "From").Y or _skelTopY
    					local _toY = getrenderproperty(RenderObject, "To") and getrenderproperty(RenderObject, "To").Y or _skelBotY
    					local _midY = (_fromY + _toY) * 0.5
    					setrenderproperty(RenderObject, "Color", _skelLimbColor(_midY))
    				end

    				if not Entry.PositionChanged then return end

    				local ConvertVector = CoreFunctions.ConvertVector
    				local Head_P  = ConvertVector(WorldToViewportPoint(__index(Head,  "Position")))
    				local Torso_P = ConvertVector(WorldToViewportPoint(__index(Torso, "Position")))

    				if RigType == "Viewmodel" then
    					local vm = playerToViewmodel[Entry.Object]
    					if not vm then return Visibility(false) end
    					local function vp(name) local p = FindFirstChild(vm, name); return p and ConvertVector(WorldToViewportPoint(__index(p, "Position"))) end
    					local S1 = vp("shoulder1"); local S2 = vp("shoulder2")
    					local A1 = vp("arm1");      local A2 = vp("arm2")
    					local H1 = vp("hip1");      local H2 = vp("hip2")
    					local L1 = vp("leg1");      local L2 = vp("leg2")
    					setrenderproperty(Limbs.Spine, "From", Head_P);  setrenderproperty(Limbs.Spine, "To", Torso_P)
    					if S1 and A1 then setrenderproperty(Limbs.LeftArm_Upper,  "From", Torso_P); setrenderproperty(Limbs.LeftArm_Upper,  "To", S1); setrenderproperty(Limbs.LeftArm_Lower,  "From", S1); setrenderproperty(Limbs.LeftArm_Lower,  "To", A1) end
    					if S2 and A2 then setrenderproperty(Limbs.RightArm_Upper, "From", Torso_P); setrenderproperty(Limbs.RightArm_Upper, "To", S2); setrenderproperty(Limbs.RightArm_Lower, "From", S2); setrenderproperty(Limbs.RightArm_Lower, "To", A2) end
    					if H1 and L1 then setrenderproperty(Limbs.LeftLeg_Upper,  "From", Torso_P); setrenderproperty(Limbs.LeftLeg_Upper,  "To", H1); setrenderproperty(Limbs.LeftLeg_Lower,  "From", H1); setrenderproperty(Limbs.LeftLeg_Lower,  "To", L1) end
    					if H2 and L2 then setrenderproperty(Limbs.RightLeg_Upper, "From", Torso_P); setrenderproperty(Limbs.RightLeg_Upper, "To", H2); setrenderproperty(Limbs.RightLeg_Lower, "From", H2); setrenderproperty(Limbs.RightLeg_Lower, "To", L2) end
    				elseif RigType == "R6" then
    					local Character = __index(Entry.Object, "Character") or __index(Entry.Object, "Parent")
    					local HeightModifier = DeveloperSettings.SkeletonR6HeightModifier
    					local function bp(name) local p = FindFirstChild(Character, name); return p end
    					local Torso_  = bp("Torso"); local LA = bp("Left Arm"); local RA = bp("Right Arm"); local LL = bp("Left Leg"); local RL = bp("Right Leg")
    					if not (Torso_ and LA and RA and LL and RL) then return Visibility(false) end
    					local function limb(p, h) local cf = __index(p,"CFrame"); local s = __index(p,"Size").Y/2-h; return ConvertVector(WorldToViewportPoint((cf*CFramenew(0,s,0)).Position)), ConvertVector(WorldToViewportPoint((cf*CFramenew(0,-s,0)).Position)) end
    					local Ts, Te = limb(Torso_, HeightModifier+0.15)
    					local LAs, LAe = limb(LA, HeightModifier); local RAs, RAe = limb(RA, HeightModifier)
    					local LLs, LLe = limb(LL, HeightModifier); local RLs, RLe = limb(RL, HeightModifier)
    					setrenderproperty(Limbs.Spine_Start,"From",Head_P);  setrenderproperty(Limbs.Spine_Start,"To",Ts)
    					setrenderproperty(Limbs.Spine_End,  "From",Ts);      setrenderproperty(Limbs.Spine_End,  "To",Te)
    					setrenderproperty(Limbs.LeftArm_Start, "From",LAs);  setrenderproperty(Limbs.LeftArm_Start, "To",LAe); setrenderproperty(Limbs.LeftArm_End,"From",Ts); setrenderproperty(Limbs.LeftArm_End,"To",LAs)
    					setrenderproperty(Limbs.RightArm_Start,"From",RAs);  setrenderproperty(Limbs.RightArm_Start,"To",RAe); setrenderproperty(Limbs.RightArm_End,"From",Ts); setrenderproperty(Limbs.RightArm_End,"To",RAs)
    					setrenderproperty(Limbs.LeftLeg_Start, "From",LLs);  setrenderproperty(Limbs.LeftLeg_Start, "To",LLe); setrenderproperty(Limbs.LeftLeg_End,"From",Te); setrenderproperty(Limbs.LeftLeg_End,"To",LLs)
    					setrenderproperty(Limbs.RightLeg_Start,"From",RLs);  setrenderproperty(Limbs.RightLeg_Start,"To",RLe); setrenderproperty(Limbs.RightLeg_End,"From",Te); setrenderproperty(Limbs.RightLeg_End,"To",RLs)
    				else
    					Visibility(false)
    				end
    			else
    				Visibility(false)
    			end
    		end
    	}
        end)()

        local CreatingFunctions; LPH_NO_VIRTUALIZE(function()
    	CreatingFunctions = {
    		ESP = function(Entry)
    			local Allowed = Entry.Allowed

    			if type(Allowed) == "table" and type(Allowed.ESP) == "boolean" and not Allowed.ESP then
    				return
    			end

    			local Settings = Environment.Properties.ESP

    			local TopText = Drawingnew("Text")
    			local TopTextObject = TopText

    			setrenderproperty(TopTextObject, "ZIndex", 4)
    			setrenderproperty(TopTextObject, "Center", true)

    			local BottomText = Drawingnew("Text")
    			local BottomTextObject = BottomText

    			setrenderproperty(BottomTextObject, "ZIndex", 4)
    			setrenderproperty(BottomTextObject, "Center", true)

    			Entry.Visuals.ESP[1] = TopText
    			Entry.Visuals.ESP[2] = BottomText

    			Entry.Connections.ESP = EspBindStep( function()
    				local Primed, Ready = pcall(function()
    					return Environment.Settings.Enabled and Settings.Enabled and Entry.Checks.Ready
    				end)

    				if not Primed then
    					pcall(TopText.Remove, TopText)
    					pcall(BottomText.Remove, BottomText)

    					return Disconnect(Entry.Connections.ESP)
    				end

    				if Ready then
    					UpdatingFunctions.ESP(Entry, TopTextObject, BottomTextObject)
    				else
    					setrenderproperty(TopTextObject, "Visible", false)
    					setrenderproperty(BottomTextObject, "Visible", false)
    				end
    			end)
    		end,

    		Tracer = function(Entry)
    			local Allowed = Entry.Allowed

    			if type(Allowed) == "table" and type(Allowed.Tracer) == "boolean" and not Allowed.Tracer then
    				return
    			end

    			local Settings = Environment.Properties.Tracer

    			local TracerOutline = Drawingnew("Line")
    			local TracerOutlineObject = TracerOutline

    			local Tracer = Drawingnew("Line")
    			local TracerObject = Tracer

    			Entry.Visuals.Tracer[1] = Tracer
    			Entry.Visuals.Tracer[2] = TracerOutline

    			Entry.Connections.Tracer = EspBindStep( function()
    				local Primed, Ready = pcall(function()
    					return Environment.Settings.Enabled and Settings.Enabled and Entry.Checks.Ready
    				end)

    				if not Primed then
    					pcall(Tracer.Remove, Tracer)
    					pcall(TracerOutline.Remove, TracerOutline)

    					return Disconnect(Entry.Connections.Tracer)
    				end

    				if Ready then
    					UpdatingFunctions.Tracer(Entry, TracerObject, TracerOutlineObject)
    				else
    					setrenderproperty(TracerObject, "Visible", false)
    					setrenderproperty(TracerOutlineObject, "Visible", false)
    				end
    			end)
    		end,

    		Box = function(Entry)
    			local Allowed = Entry.Allowed

    			if type(Allowed) == "table" and type(Allowed.Box) == "boolean" and not Allowed.Box then
    				return
    			end

    			local Settings = Environment.Properties.Box

    			local _BoxOutlines = {
    				TopLeft_Bottom = Drawingnew("Line"),
    				TopLeft_Right = Drawingnew("Line"),
    				TopRight_Bottom = Drawingnew("Line"),
    				TopRight_Left = Drawingnew("Line"),
    				BottomLeft_Top = Drawingnew("Line"),
    				BottomLeft_Right = Drawingnew("Line"),
    				BottomRight_Top = Drawingnew("Line"),
    				BottomRight_Left = Drawingnew("Line")
    			}

    			local BoxOutlines = {}

    			local _Quads = {
    				Top = Drawingnew("Quad"),
    				Bottom = Drawingnew("Quad"),
    				Front = Drawingnew("Quad"),
    				Back = Drawingnew("Quad"),
    				Left = Drawingnew("Quad"),
    				Right = Drawingnew("Quad")
    			}

    			local Quads = {}

    			for Index, Value in next, _BoxOutlines do
    				BoxOutlines[Index] = Value
    			end

    			for Index, Value in next, _Quads do
    				Quads[Index] = Value
    			end

    			local _BoxParts, BoxParts = {}, {}

    			for Index, _ in next, BoxOutlines do
    				BoxParts[Index] = Drawingnew("Line")
    				_BoxParts[Index] = _BoxOutlines[Index]
    			end

    			local _SquareBoxOutline = Drawingnew("Square")
    			local _SquareBox = Drawingnew("Square")
    			local SquareBoxOutline = _SquareBoxOutline
    			local SquareBoxObject = _SquareBox

    			setrenderproperty(SquareBoxObject, "ZIndex", 4)
    			setrenderproperty(SquareBoxOutline, "ZIndex", 3)

    			local SquareBox, _FillBox = {SquareBoxObject, SquareBoxOutline}, Drawingnew("Square")
    			local FillBox = _FillBox

    			setrenderproperty(FillBox, "Filled", true)

    			Entry.Visuals.Box[1] = _BoxParts
    			Entry.Visuals.Box[2] = _BoxOutlines
    			Entry.Visuals.Box[3] = {_SquareBox, _SquareBoxOutline}
    			Entry.Visuals.Box[4] = _FillBox
    			Entry.Visuals.Box[5] = _Quads

    			Entry.Connections.Box = EspBindStep( function()
    				local Primed, Ready = pcall(function()
    					return Environment.Settings.Enabled and Settings.Enabled and Entry.Checks.Ready
    				end)

    				if not Primed then
    					for Index, Value in next, BoxParts do
    						pcall(Value.Remove, Value)
    						pcall(BoxOutlines[Index].Remove, BoxOutlines[Index])
    					end

    					for _, Value in next, Quads do
    						pcall(Value.Remove, Value)
    					end

    					pcall(SquareBox.Remove, SquareBox)
    					pcall(FillBox.Remove, FillBox)

    					return Disconnect(Entry.Connections.Box)
    				end

    				if Ready then
    					UpdatingFunctions.Box(Entry, BoxParts, BoxOutlines, SquareBox, FillBox, Quads)
    				else
    					setrenderproperty(SquareBoxObject, "Visible", false)
    					setrenderproperty(SquareBoxOutline, "Visible", false)
    					setrenderproperty(FillBox, "Visible", false)

    					for Index, Value in next, BoxParts do
    						setrenderproperty(Value, "Visible", false)
    						setrenderproperty(BoxOutlines[Index], "Visible", false)
    					end

    					for _, Value in next, Quads do
    						setrenderproperty(Value, "Visible", false)
    					end
    				end
    			end)
    		end,

    		HealthBar = function(Entry)
    			local Allowed = Entry.Allowed

    			if type(Allowed) == "table" and type(Allowed.HealthBar) == "boolean" and not Allowed.HealthBar then
    				return
    			end

    			local Settings = Environment.Properties.HealthBar

    			local Outline = Drawingnew("Line")
    			local Main = Drawingnew("Line") -- legacy fallback (kept hidden when segs used)
    			local SEG_N = 16
    			local Segs = {}
    			for i = 1, SEG_N do
    				Segs[i] = Drawingnew("Line")
    			end
    			local TextObj = Drawingnew("Text")
    			pcall(function()
    				TextObj.Center = false
    				TextObj.Outline = true
    				TextObj.Size = 10
    				TextObj.Visible = false
    			end)

    			Entry.Visuals.HealthBar[1] = Main
    			Entry.Visuals.HealthBar[2] = Outline
    			Entry.Visuals.HealthBar.Segs = Segs
    			Entry.Visuals.HealthBar.Outline = Outline
    			Entry.Visuals.HealthBar.Text = TextObj

    			Entry.Connections.HealthBar = EspBindStep( function()
    				local Primed, Ready = pcall(function()
    					return Environment.Settings.Enabled and Settings.Enabled and Entry.Checks.Ready
    				end)

    				if not Primed then
    					pcall(Main.Remove, Main)
    					pcall(Outline.Remove, Outline)
    					for _, ln in next, Segs do pcall(ln.Remove, ln) end
    					pcall(TextObj.Remove, TextObj)
    					return Disconnect(Entry.Connections.HealthBar)
    				end

    				if Ready then
    					UpdatingFunctions.HealthBar(Entry, Main, Outline, nil)
    				else
    					setrenderproperty(Main, "Visible", false)
    					setrenderproperty(Outline, "Visible", false)
    					for _, ln in next, Segs do pcall(setrenderproperty, ln, "Visible", false) end
    					pcall(setrenderproperty, TextObj, "Visible", false)
    				end
    			end)
    		end,

    		Skeleton = function(Entry)
    			local Allowed = Entry.Allowed
    			local Settings = Environment.Properties.Skeleton

    			if type(Allowed) == "table" and type(Allowed.Skeleton) == "boolean" and not Allowed.Skeleton then
    				return
    			end

    			local RigType = Entry.RigType

    			if RigType == "Viewmodel" then
    				Entry.Visuals.Skeleton = {
    					Spine        = Drawingnew("Line"),
    					LeftArm_Upper  = Drawingnew("Line"), LeftArm_Lower  = Drawingnew("Line"),
    					RightArm_Upper = Drawingnew("Line"), RightArm_Lower = Drawingnew("Line"),
    					LeftLeg_Upper  = Drawingnew("Line"), LeftLeg_Lower  = Drawingnew("Line"),
    					RightLeg_Upper = Drawingnew("Line"), RightLeg_Lower = Drawingnew("Line"),
    				}
    			elseif RigType == "R6" then
    				Entry.Visuals.Skeleton = {
    					Spine_Start = Drawingnew("Line"), Spine_End = Drawingnew("Line"),
    					LeftArm_Start = Drawingnew("Line"), LeftArm_End = Drawingnew("Line"),
    					RightArm_Start = Drawingnew("Line"), RightArm_End = Drawingnew("Line"),
    					LeftLeg_Start = Drawingnew("Line"), LeftLeg_End = Drawingnew("Line"),
    					RightLeg_Start = Drawingnew("Line"), RightLeg_End = Drawingnew("Line"),
    				}
    			else
    				return
    			end

    			local SkeletonEntry = Entry.Visuals.Skeleton

    			Entry.Connections.Skeleton = EspBindStep( function()
    				local Primed, Ready = pcall(function()
    					return Environment.Settings.Enabled and Settings.Enabled and Entry.Checks.Ready
    				end)

    				if not Primed then
    					for _, Value in next, SkeletonEntry do pcall(Value.Remove, Value) end
    					return Disconnect(Entry.Connections.Skeleton)
    				end

    				if Ready then
    					UpdatingFunctions.Skeleton(Entry)
    				else
    					for _, Value in next, SkeletonEntry do setrenderproperty(Value, "Visible", false) end
    				end
    			end)
    		end
    	}
        end)()

        local UtilityFunctions; LPH_NO_VIRTUALIZE(function()
    	UtilityFunctions = {
    		InitChecks = function(self, Entry)
    			local Settings = Environment.Settings
    			local DeveloperSettings = Environment.DeveloperSettings

    			local Player = Entry.Object
    			local Checks = Entry.Checks
    			local Hash = Entry.Hash
    			local IsAPlayer = Entry.IsAPlayer
    			local PartHasCharacter = Entry.PartHasCharacter
    			local RenderDistance = Entry.RenderDistance

    			if not IsAPlayer and not PartHasCharacter and not RenderDistance then
    				return
    			end

    			local Top = select(4, CoreFunctions.CalculateParameters(Entry))

    			Entry.OldPosition = Environment.Settings.CachePositions and Top and CoreFunctions.GetLocalCharacterPosition() - select(4, CoreFunctions.CalculateParameters(Entry))

    			Entry.Connections.UpdateChecks = EspBindStep( function()
    				if DeveloperSettings.Throttle then
    					Entry._Frame = (Entry._Frame or 0) + 1

    					if Entry._Frame % mathclamp(DeveloperSettings.ThrottleStep, 2, 4) ~= 0 then
    						return
    					end
    				end

    				Top = select(4, CoreFunctions.CalculateParameters(Entry))

    				if Top and Environment.Settings.CachePositions then
    					Entry.Position = CoreFunctions.GetLocalCharacterPosition() - Top
    					Entry.PositionChanged = Entry.OldPosition ~= Entry.Position
    					Entry.OldPosition = Entry.OldPosition == Entry.Position and Entry.OldPosition or Entry.Position
    				else
    					Entry.PositionChanged = true
    				end

    				RenderDistance = Entry.RenderDistance

    				if not Settings.Enabled then
    					Checks.Ready = false
    					Checks.Alive = false
    					Checks.Team = false

    					return
    				end

    				if not IsAPlayer and not PartHasCharacter then -- Part ESP
    					Checks.Ready = (__index(Player, "Position") - CoreFunctions.GetLocalCharacterPosition()).Magnitude <= RenderDistance; return
    				end

    				if not IsAPlayer then -- NPC
    					local PartHumanoid = FindFirstChildOfClass(__index(Player, "Parent"), "Humanoid")

    					Checks.Ready = PartHasCharacter and PartHumanoid and IsDescendantOf(Player, Workspace)

    					if not Checks.Ready then
    						return self.UnwrapObject(Hash)
    					end

    					local IsInDistance = (__index(Player, "Position") - CoreFunctions.GetLocalCharacterPosition()).Magnitude <= RenderDistance

    					if Settings.AliveCheck then
    						Checks.Alive = __index(PartHumanoid, "Health") > 0
    					end

    					Checks.Ready = Checks.Ready and Checks.Alive and IsInDistance and Environment.Settings.EntityESP

    					return
    				end

    				local vm = playerToViewmodel[Player]
    				local vmPart = vm and (FindFirstChild(vm, "torso") or FindFirstChild(vm, "head"))

    				local IsInDistance

    				if vm and vmPart then
    					Checks.Alive = true
    					Checks.Team = true

    					if Settings.AliveCheck then
    						local _char = __index(Player, "Character")
    						local _hum = _char and FindFirstChildOfClass(_char, "Humanoid")
    						Checks.Alive = not _hum or __index(_hum, "Health") > 0
    					end

    					if Settings.TeamCheck then
    						Checks.Team = Player:GetAttribute("Team") ~= LocalPlayer:GetAttribute("Team")
    					end

    					IsInDistance = (__index(vmPart, "Position") - CoreFunctions.GetLocalCharacterPosition()).Magnitude <= RenderDistance
    				else
    					Checks.Alive = false
    					Checks.Team = false

    					if DeveloperSettings.UnwrapOnCharacterAbsence then
    						self.UnwrapObject(Hash)
    					end
    				end

    				Checks.Ready = Checks.Alive and Checks.Team and not Settings.PartsOnly and IsInDistance

    				if Checks.Ready then
    					if Humanoid then
    						Entry.Humanoid = Humanoid
    					end

    					local Part = IsAPlayer and (FindFirstChild(Players, __index(Player, "Name")) and __index(Player, "Character"))
    					Part = IsAPlayer and (Part and (__index(Part, "PrimaryPart") or FindFirstChild(Part, "HumanoidRootPart"))) or Player

    					Entry.RigType = Humanoid and FindFirstChild(__index(Part, "Parent"), "Torso") and "R6" or "R15"
    					Entry.RigType = Entry.RigType == "N/A" and Humanoid and (__index(Humanoid, "RigType") == 0 and "R6" or "R15") or "N/A" -- Deprecated method (might be faulty sometimes)
    					Entry.RigType = Entry.RigType == "N/A" and Humanoid and (__index(Humanoid, "RigType") == Enum.HumanoidRigType.R6 and "R6" or "R15") or "N/A" -- Secondary check
    					if IsAPlayer and Entry.RigType == "N/A" and playerToViewmodel[Player] then
    						Entry.RigType = "Viewmodel"
    					end
    				end
    			end)
    		end,

    		GetObjectEntry = function(Object, Hash)
    			Hash = type(Object) == "string" and Object or Hash

    			for _, Value in next, Environment.UtilityAssets.WrappedObjects do
    				if Hash and Value.Hash == Hash or Value.Object == Object then
    					return Value
    				end
    			end
    		end,

    		WrapObject = function(self, Object, PseudoName, Allowed, RenderDistance)
    			assert(self, "EXUNYS_ESP > UtilityFunctions.WrapObject - Internal error, unassigned parameter \"self\".")

    			--// Because gethiddenproperty behaves differently on Xeno, this part breaks the code. This is the universal solution.

    			-- if pcall(gethiddenproperty, Object, "PrimaryPart") then
    			-- 	Object = __index(Object, "PrimaryPart")
    			-- end

    			do
    				local Signal = {pcall(gethiddenproperty, Object, "PrimaryPart")}

    				if Signal[1] and Signal[2] ~= nil and typeof(Signal[2]) ~= "number" then
    					Object = __index(Object, "PrimaryPart")
    				end
    			end

    			if not Object then
    				return
    			end

    			if Object == LocalPlayer then
    				return
    			end

    			local DeveloperSettings = Environment.DeveloperSettings
    			local WrappedObjects = Environment.UtilityAssets.WrappedObjects

    			for _, Value in next, WrappedObjects do
    				if Value.Object == Object then
    					return
    				end
    			end

    			local Entry = {
    				Hash = CoreFunctions.GenerateHash(0x100),

    				Object = Object,
    				Allowed = Allowed,
    				Name = PseudoName or __index(Object, "Name"),
    				DisplayName = PseudoName or __index(Object, (IsA(Object, "Player") and "Display" or "").."Name"),
    				RenderDistance = RenderDistance or Inf,

    				IsAPlayer = IsA(Object, "Player") or __index(Object, "ClassName") == "Player",
    				PartHasCharacter = false,
    				RigType = "N/A",
    				Humanoid = nil,

    				Checks = {
    					Alive = true,
    					Team = true,
    					Ready = false
    				},

    				Visuals = {
    					ESP = {},
    					Tracer = {},
    					Box = {},
    					HealthBar = {},
    					Skeleton = {},
    				},

    				Connections = {}
    			}

    			repeat
    				wait(0)
    			until Entry.IsAPlayer and FindFirstChildOfClass(__index(Entry.Object, "Character"), "Humanoid") or true

    			if not Entry.IsAPlayer then
    				if not pcall(function()
    						return __index(Entry.Object, "Position"), __index(Entry.Object, "CFrame")
    					end) then
    					-- warn("EXUNYS_ESP > UtilityFunctions.WrapObject - Attempted to wrap object of an unsupported class type: \""..(__index(Entry.Object, "ClassName") or "N / A").."\"")
    					return self.UnwrapObject(Entry.Hash)
    				end

    				Entry.Connections.UnwrapSignal = Connect(Entry.Object.Changed, function(Property)
    					if Property == "Parent" and not IsDescendantOf(__index(Entry.Object, Property), Workspace) then
    						self.UnwrapObject(nil, Entry.Hash)
    					end
    				end)
    			end

    			local Humanoid = Entry.IsAPlayer and FindFirstChildOfClass(__index(Entry.Object, "Character"), "Humanoid") or FindFirstChildOfClass(__index(Entry.Object, "Parent"), "Humanoid")

    			Entry.PartHasCharacter = not Entry.IsAPlayer and Humanoid
    			Entry.RigType = Humanoid and (__index(Humanoid, "RigType") == 0 and "R6" or "R15") or "N/A"
    			Entry.Humanoid = Humanoid

    			self:InitChecks(Entry)

    			spawn(function()
    				repeat
    					wait(0)
    				until Entry.Checks.Ready

    				CreatingFunctions.Box(Entry)
    				CreatingFunctions.Tracer(Entry)
    				CreatingFunctions.HealthBar(Entry)
    				CreatingFunctions.ESP(Entry)
    				CreatingFunctions.Skeleton(Entry)

    				--delay(1, CoreFunctions.ResetScreenDistortion, CoreFunctions)
    			end)

    			WrappedObjects[Entry.Hash] = Entry

    			Entry.Connections.PlayerUnwrapSignal = Connect(Entry.Object.Changed, function(Property)
    				if DeveloperSettings.UnwrapOnCharacterAbsence and Property == "Parent" and not IsDescendantOf(__index(Entry.Object, (Entry.IsAPlayer and "Character" or Property)), Workspace) then
    					self.UnwrapObject(nil, Entry.Hash)
    				end
    			end)

    			return Entry.Hash
    		end,

    		UnwrapObject = function(Object, Hash)
    			Hash = type(Object) == "string" and Object
    			Object = type(Object) == "string" and nil

    			for _, Value in next, Environment.UtilityAssets.WrappedObjects do
    				if Value.Object == Object or Value.Hash == Hash then
    					for _, _Value in next, Value.Connections do
    						pcall(Disconnect, _Value)
    					end

    					if Value.Visuals then
    						Recursive(Value.Visuals, function(_, _Value)
    							if type(_Value) == "table" and _Value then
    								pcall(_Value.Remove, _Value)
    							end
    						end)
    					end

    					Environment.UtilityAssets.WrappedObjects[Hash] = nil; break
    				end
    			end
    		end
    	}
        end)()

        local LoadESP; LPH_NO_VIRTUALIZE(function()
    	LoadESP = function()
    		local ServiceConnections = Environment.UtilityAssets.ServiceConnections

    		-- Late in the frame so 3rd person (and any other cam writes) already applied
    		local function _espRefreshCam()
    			FrameTick = tick()
    			pcall(function()
    				if CoreFunctions and type(CoreFunctions.GetRainbowColor) == "function" then
    					Rainbow = CoreFunctions.GetRainbowColor()
    				end
    			end)
    			local camNow = workspace.CurrentCamera or CurrentCamera
    			if camNow then
    				if type(__index) == "function" then
    					CameraCFrame = __index(camNow, "CFrame")
    					CameraViewportSize = __index(camNow, "ViewportSize")
    				else
    					CameraCFrame = camNow.CFrame
    					CameraViewportSize = camNow.ViewportSize
    				end
    			end
    		end
    		ServiceConnections.UpdateCoreParameters = EspBindStep(_espRefreshCam)

    		ServiceConnections.PlayerRemoving = Connect(__index(Players, "PlayerRemoving"), UtilityFunctions.UnwrapObject)

    		local lastStateObjectSync = 0
    		ServiceConnections.StateObjectSync = Connect(__index(RunService, "Heartbeat"), function()
    			local now = tick()
    			if now - lastStateObjectSync < 3 then return end
    			lastStateObjectSync = now

    			local newViewmodelMap = {}

    			for _, character in StateObject.get_all("Character") do
    				local Player = character.owner and character.owner:get()
    				if not Player or Player == LocalPlayer then continue end

    				local vm = character.values and character.values.viewmodels
    				if vm then newViewmodelMap[Player] = vm end

    				local alreadyWrapped = false
    				for _, v in next, Environment.UtilityAssets.WrappedObjects do
    					if v.Object == Player then
    						alreadyWrapped = true
    						break
    					end
    				end

    				if not alreadyWrapped then
    					UtilityFunctions:WrapObject(Player)
    				end
    			end

    			playerToViewmodel = newViewmodelMap
    			local _count = 0; for _ in pairs(newViewmodelMap) do _count += 1 end
    			--print("[ESP sync] playerToViewmodel refreshed, entries: " .. tostring(_count))
    			for player, vm in pairs(newViewmodelMap) do
    				--print("  [" .. tostring(player.Name) .. "] vm=" .. tostring(vm) .. " class=" .. tostring(typeof(vm)) .. " parent=" .. tostring(vm and vm.Parent))
    				if typeof(vm) == "Instance" then
    					for _, child in ipairs(vm:GetChildren()) do
    						--print("    child: " .. child.Name .. " [" .. child.ClassName .. "]")
    					end
    				end
    			end
    		end)

    		--// Wrap all players that currently have an active character via StateObject

    		--print("[ESP init] initial StateObject character scan:")
    		for _, character in StateObject.get_all("Character") do
    			local Player = character.owner and character.owner:get()
    			if Player and Player ~= LocalPlayer then
    				local vm = character.values and character.values.viewmodels
    				--print("  player=" .. tostring(Player and Player.Name) .. " vm=" .. tostring(vm) .. " class=" .. tostring(typeof(vm)) .. " parent=" .. tostring(vm and vm.Parent))
    				if vm and typeof(vm) == "Instance" then
    					for _, child in ipairs(vm:GetChildren()) do
    						--print("    child: " .. child.Name .. " [" .. child.ClassName .. "]")
    					end
    				end
    				if vm then playerToViewmodel[Player] = vm end
    				UtilityFunctions:WrapObject(Player)
    			end
    		end

    		--// Entity ESP

    		for _, Value in next, workspace:GetDescendants() do
    			if Value:IsA("Humanoid") then
    				local PotentialCharacter = Value.Parent:IsA("Model") and Value.Parent

    				if PotentialCharacter and not GetPlayerFromCharacter(PotentialCharacter) and FindFirstChild(PotentialCharacter, "Head") and (__index(PotentialCharacter, "PrimaryPart") or FindFirstChild(PotentialCharacter, "HumanoidRootPart")) then
    					UtilityFunctions:WrapObject(PotentialCharacter, PotentialCharacter.Name)
    				end
    			end
    		end

    		ServiceConnections.Entity_DescendantAdded = Connect(__index(workspace, "DescendantAdded"), function(Value)
    			if Value:IsA("Model") and Value:FindFirstChildOfClass("Humanoid") and not GetPlayerFromCharacter(Value) and (__index(Value, "PrimaryPart") or FindFirstChild(Value, "HumanoidRootPart")) then
    				UtilityFunctions:WrapObject(Value.Parent, Value.Parent.Name)
    			end
    		end)
    	end
        end)()

        setmetatable(Environment, {
    	__call = function()
    		if Loaded then
    			return
    		end

    		Loaded = true
    		return LoadESP()
    	end
        })

        pcall(spawn, function()
    	if Environment.Settings.LoadConfigOnLaunch then
    		repeat wait(0) until Environment.LoadConfiguration

    		Environment:LoadConfiguration()
    	end
        end)

        --// Interactive User Methods

        Environment.UnwrapPlayers = function() -- (<void>) => <boolean> Success Status
    	local UtilityAssets = Environment.UtilityAssets

    	local WrappedObjects = UtilityAssets.WrappedObjects
    	local ServiceConnections = UtilityAssets.ServiceConnections

    	for _, Entry in next, WrappedObjects do
    		pcall(UtilityFunctions.UnwrapObject, Entry.Hash)
    	end

    	for _, ConnectionIndex in next, {"PlayerRemoving", "PlayerAdded", "CharacterAdded"} do
    		pcall(Disconnect, ServiceConnections[ConnectionIndex])
    	end

    	return #WrappedObjects == 0
        end

        Environment.UnwrapAll = function(self) -- (self) => <boolean> Success Status
    	assert(self, "EXUNYS_ESP.UnwrapAll: Missing parameter #1 \"self\" <table>.")

    	self.UnwrapPlayers()

    	return #self.UtilityAssets.WrappedObjects == 0
        end

        Environment.Restart = function(self, RewriteEntries) -- (self[, <bool> Rewrite entries]) => <void>
    	assert(self, "EXUNYS_ESP.Restart: Missing parameter #1 \"self\" <table>.")

    	if Restarting then
    		return
    	end

    	Restarting = true

    	if RewriteEntries then
    		if self:UnwrapAll() then
    			self.Load()
    		end
    	else
    		local Objects = {}

    		for _, Value in next, self.UtilityAssets.WrappedObjects do
    			Objects[#Objects + 1] = {Value.Hash, Value.Object, Value.Name, Value.Allowed, Value.RenderDistance}
    		end

    		for _, Value in next, Objects do
    			self.UnwrapObject(Value[1])
    		end

    		wait(1)

    		for _, Value in next, Objects do
    			self.WrapObject(select(2, unpack(Value)))
    		end

    	end

    	Restarting = false
        end

        Environment.Exit = function(self) -- (self) => <void>
    	assert(self, "EXUNYS_ESP.Exit: Missing parameter #1 \"self\" <table>.")

    	if self:UnwrapAll() then
    		for _, Connection in next, self.UtilityAssets.ServiceConnections do
    			pcall(Disconnect, Connection)
    		end

    		for _, RenderObject in next, CrosshairParts do
    			pcall(RenderObject.Remove, RenderObject)
    		end

    		for _, Table in next, {CoreFunctions, UpdatingFunctions, CreatingFunctions, UtilityFunctions} do
    			for FunctionName, _ in next, Table do
    				Table[FunctionName] = nil
    			end

    			Table = nil
    		end

    		for Index, _ in next, Environment do
    			Environment[Index] = nil
    		end

    		LoadESP = nil; Recursive = nil; Loaded = false

    		if cleardrawcache then
    			cleardrawcache()
    		end

    		getgenv().ExunysDeveloperESP = nil; pcall(collectgarbage, "step", 200)
    	end
        end

        Environment.WrapObject = function(...) -- (<Instance> Object[, <string> Pseudo Name, <table> Allowed Visuals, <uint> Render Distance]) => <string> Hash
    	return UtilityFunctions:WrapObject(...)
        end

        Environment.UnwrapObject = UtilityFunctions.UnwrapObject -- (<Instance/string> Object/Hash[, <string> Hash]) => <void>

        Environment.WrapPlayers = LoadESP -- (<void>) => <void>

        Environment.GetEntry = UtilityFunctions.GetObjectEntry -- (<Instance> Object[, <string> Hash]) => <table> Entry

        Environment.Load = function() -- (<void>) => <void>
    	if Loaded then
    		return
    	end

    	LoadESP(); Loaded = true
        end

        Environment.UpdateConfiguration = function(DeveloperSettings, Settings, Properties) -- (<table> DeveloperSettings, <table> Settings, <table> Properties) => <table> New Environment
    	assert(DeveloperSettings, "EXUNYS_ESP.UpdateConfiguration: Missing parameter #1 \"DeveloperSettings\" <table>.")
    	assert(Settings, "EXUNYS_ESP.UpdateConfiguration: Missing parameter #2 \"Settings\" <table>.")
    	assert(Properties, "EXUNYS_ESP.UpdateConfiguration: Missing parameter #3 \"Properties\" <table>.")

    	getgenv().ExunysDeveloperESP.DeveloperSettings = DeveloperSettings
    	getgenv().ExunysDeveloperESP.Settings = Settings
    	getgenv().ExunysDeveloperESP.Properties = Properties

    	Environment = getgenv().ExunysDeveloperESP

    	return Environment
        end

        Environment.LoadConfiguration = function(self) -- (self) => <void>
    	assert(self, "EXUNYS_ESP.LoadConfiguration: Missing parameter #1 \"self\" <table>.")

    	local Path = self.DeveloperSettings.Path

    	if self:UnwrapAll() then
    		pcall(function()
    			local Configuration, Data = ConfigLibrary:LoadConfig(Path), {}

    			for _, Index in next, {"DeveloperSettings", "Settings", "Properties"} do
    				Data[#Data + 1] = ConfigLibrary:CloneTable(Configuration[Index])
    			end

    			self.UpdateConfiguration(unpack(Data))()
    		end)
    	end
        end

        Environment.SaveConfiguration = function(self) -- (self) => <void>
    	assert(self, "EXUNYS_ESP.SaveConfiguration: Missing parameter #1 \"self\" <table>.")

    	local DeveloperSettings = self.DeveloperSettings

    	ConfigLibrary:SaveConfig(DeveloperSettings.Path, {
    		DeveloperSettings = DeveloperSettings,
    		Settings = self.Settings,
    		Properties = self.Properties
    	})
        end

        ESP = Environment

    -- ==================== PLAYER CHAMS (BoxHandleAdornment on O1 viewmodels) ====================
    do
        local chamsStore = {} -- [vmModel] = { adorns = {}, wire = {} }
        -- O1 character.values.viewmodels bone names (from dumps)
        local CHAM_PARTS = {
            "head", "torso",
            "arm1", "arm2", "shoulder1", "shoulder2",
            "hip1", "hip2", "leg1", "leg2",
            "Head", "Torso", "UpperTorso", "LowerTorso",
            "LeftUpperArm", "LeftLowerArm", "LeftHand", "Left Arm",
            "RightUpperArm", "RightLowerArm", "RightHand", "Right Arm",
            "LeftUpperLeg", "LeftLowerLeg", "LeftFoot", "Left Leg",
            "RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg",
        }

        local function lerpColor(a, b, t)
            t = math.clamp(t or 0, 0, 1)
            return Color3.new(
                a.R + (b.R - a.R) * t,
                a.G + (b.G - a.G) * t,
                a.B + (b.B - a.B) * t
            )
        end

        local function destroyChams(key)
            local store = chamsStore[key]
            if not store then return end
            for _, ad in pairs(store.adorns or {}) do pcall(function() ad:Destroy() end) end
            for _, ad in pairs(store.wire or {}) do pcall(function() ad:Destroy() end) end
            if store.highlight then pcall(function() store.highlight:Destroy() end) end
            chamsStore[key] = nil
        end

        local function clearAllChams()
            for k in pairs(chamsStore) do destroyChams(k) end
        end
        getgenv()._MethaneClearPlayerChams = clearAllChams

        local function makeAdorn(part, color, trans, alwaysOnTop, scale)
            local ad = Instance.new("BoxHandleAdornment")
            ad.Name = "MethanePlayerCham"
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

        local function makeWire(part, color, trans)
            local sb = Instance.new("SelectionBox")
            sb.Name = "MethanePlayerWire"
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

        local function sameTeam(plr)
            if not plr or plr == LocalPlayer then return true end
            local ok, res = pcall(function()
                if ESP and ESP.Settings and ESP.Settings.TeamCheck then
                    local opt = ESP.DeveloperSettings and ESP.DeveloperSettings.TeamCheckOption or "Team"
                    if opt == "Team" then
                        return plr.Team ~= nil and LocalPlayer.Team ~= nil and plr.Team == LocalPlayer.Team
                    end
                end
                return false
            end)
            return ok and res == true
        end

        local function updateChamsFor(plr, vm, cam, cfg)
            if not vm or not vm.Parent then
                destroyChams(vm)
                return
            end
            if not cfg or not cfg.Enabled then
                destroyChams(vm)
                return
            end
            if ESP and ESP.Settings and ESP.Settings.Enabled == false then
                destroyChams(vm)
                return
            end
            if sameTeam(plr) and ESP and ESP.Settings and ESP.Settings.TeamCheck then
                destroyChams(vm)
                return
            end

            local chamType = tostring(cfg.Type or "BoxHandleAdornment")
            if chamType ~= "Highlight" then chamType = "BoxHandleAdornment" end
            local mode = cfg.Mode or "Fill"
            local col = cfg.FillColor or Color3.fromRGB(120, 170, 255)
            local col2 = cfg.FillColor2 or col
            local fillT = math.clamp(cfg.FillTransparency or 0.55, 0, 1)
            local olT = math.clamp(cfg.OutlineTransparency or 0.15, 0, 1)
            local visOnly = cfg.VisibleOnly == true
            local aot = not visOnly

            if visOnly and cam then
                local root = vm:FindFirstChild("torso") or vm:FindFirstChild("head") or vm.PrimaryPart
                if root and root:IsA("BasePart") then
                    local sp, on = cam:WorldToViewportPoint(root.Position)
                    if not on or sp.Z <= 0 then
                        destroyChams(vm)
                        return
                    end
                end
            end

            local store = chamsStore[vm]
            if not store then
                store = { adorns = {}, wire = {}, highlight = nil, lastType = nil }
                chamsStore[vm] = store
            end
            if store.lastType and store.lastType ~= chamType then
                for _, ad in pairs(store.adorns or {}) do pcall(function() ad:Destroy() end) end
                for _, ad in pairs(store.wire or {}) do pcall(function() ad:Destroy() end) end
                if store.highlight then pcall(function() store.highlight:Destroy() end) end
                store.adorns, store.wire, store.highlight = {}, {}, nil
            end
            store.lastType = chamType

            if chamType == "Highlight" then
                for _, ad in pairs(store.adorns or {}) do pcall(function() ad:Destroy() end) end
                for _, ad in pairs(store.wire or {}) do pcall(function() ad:Destroy() end) end
                store.adorns, store.wire = {}, {}
                local hl = store.highlight
                if not hl or hl.Parent == nil then
                    hl = Instance.new("Highlight")
                    hl.Name = "MethanePlayerChamHL"
                    hl.Parent = vm
                    store.highlight = hl
                end
                hl.Adornee = vm
                hl.FillColor = col
                hl.OutlineColor = col2 or col
                hl.FillTransparency = fillT
                hl.OutlineTransparency = olT
                hl.DepthMode = aot and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
                hl.Enabled = true
                return
            end

            if store.highlight then
                pcall(function() store.highlight:Destroy() end)
                store.highlight = nil
            end
            for _, ad in pairs(store.wire or {}) do pcall(function() ad:Destroy() end) end
            store.wire = {}

            local tclock = os.clock()
            local done = {}
            local rootPart = vm:FindFirstChild("torso") or vm:FindFirstChild("head") or vm.PrimaryPart

            local function partColor(part)
                if mode == "Flow" then
                    local h = 0.5
                    if rootPart and rootPart:IsA("BasePart") then
                        h = math.clamp((part.Position.Y - (rootPart.Position.Y - 2.5)) / 5, 0, 1)
                    end
                    local wave = (math.sin(tclock * 2 + h * 4) + 1) * 0.5
                    return lerpColor(col, col2, math.clamp(h * 0.7 + wave * 0.3, 0, 1))
                end
                return col
            end

            local function handlePart(part)
                if done[part] or not part:IsA("BasePart") then return end
                if part.Transparency >= 0.99 then return end
                if part.Size.Magnitude < 0.05 or part.Size.Magnitude > 40 then return end
                local n = string.lower(part.Name)
                if n == "humanoidrootpart" or n == "rootpart" then return end
                done[part] = true
                local useCol = partColor(part)
                local ft = fillT
                if mode == "Flat" then ft = math.clamp(fillT * 0.5, 0, 0.85) end

                local ad = store.adorns[part]
                if not ad or ad.Parent == nil then
                    ad = makeAdorn(part, useCol, ft, aot, 1.02)
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
                local part = vm:FindFirstChild(name)
                if part and part:IsA("BasePart") then
                    handlePart(part)
                end
            end
            -- also any other body-sized BaseParts under the viewmodel (attachments / gun held on body)
            pcall(function()
                for _, d in ipairs(vm:GetDescendants()) do
                    if d:IsA("BasePart") and not done[d] then
                        handlePart(d)
                    end
                end
            end)

            -- cleanup adorns for parts that went away
            for part, ad in pairs(store.adorns) do
                if not done[part] or not part.Parent then
                    pcall(function() ad:Destroy() end)
                    store.adorns[part] = nil
                    if store.wire[part] then
                        pcall(function() store.wire[part]:Destroy() end)
                        store.wire[part] = nil
                    end
                end
            end
        end

        local function tickChams()
            local cfg = ESP and ESP.Properties and ESP.Properties.Chams
            if not cfg or not cfg.Enabled or (ESP and ESP.Settings and ESP.Settings.Enabled == false) then
                clearAllChams()
                return
            end
            local cam = workspace.CurrentCamera
            local map = playerToViewmodel or {}
            local seen = {}
            for plr, vm in pairs(map) do
                if plr and plr ~= LocalPlayer and vm then
                    seen[vm] = true
                    pcall(updateChamsFor, plr, vm, cam, cfg)
                end
            end
            for key in pairs(chamsStore) do
                if not seen[key] then
                    destroyChams(key)
                end
            end
        end

        RunService.RenderStepped:Connect(function()
            pcall(tickChams)
        end)
    end

    end

    ESP.Load()


    -- Nested scope: own 200-local register budget (parent chunk is full)
    local function __vantaUiScope()


    

    -- ==================== VANTA UI (VVind) ====================
    -- Filesystem rebrand: NullUI → Vanta/UI
    do
        local function mapFsPath(path)
            path = tostring(path or "")
            if path == "NullUI" or path:sub(1, 7) == "NullUI/" or path:sub(1, 7) == "NullUI\\" then
                path = "Vanta/UI" .. path:sub(7)
            end
            path = path:gsub("[Aa]ssistant", "Chat")
            path = path:gsub("vanta%-universal%-assistant", "vanta-chat")
            return path
        end
        local function wrap1(fn)
            if type(fn) ~= "function" then return fn end
            return function(path, ...) return fn(mapFsPath(path), ...) end
        end
        if type(isfolder) == "function" then isfolder = wrap1(isfolder) end
        if type(makefolder) == "function" then makefolder = wrap1(makefolder) end
        if type(delfolder) == "function" then delfolder = wrap1(delfolder) end
        if type(isfile) == "function" then isfile = wrap1(isfile) end
        if type(readfile) == "function" then readfile = wrap1(readfile) end
        if type(writefile) == "function" then writefile = wrap1(writefile) end
        if type(appendfile) == "function" then appendfile = wrap1(appendfile) end
        if type(delfile) == "function" then delfile = wrap1(delfile) end
        if type(listfiles) == "function" then
            local _lf = listfiles
            listfiles = function(path) return _lf(mapFsPath(path)) end
        end
    end

    pcall(function()
        local function ensure(path)
            if isfolder and not isfolder(path) and makefolder then makefolder(path) end
        end
        ensure("Vanta"); ensure("Vanta/Configs"); ensure("Vanta/Icons"); ensure("Vanta/Cache")
        ensure("Vanta/UI"); ensure("Vanta/UI/Assets"); ensure("Vanta/UI/Configs")
        ensure("Vanta/op1")
    end)

    -- Methane UI (same library as Bloxstrike)
    local Library
    do
        local ok, lib = pcall(function()
            getgenv().MethaneLibrary = nil
            local src = game:HttpGet("https://raw.githubusercontent.com/iskasaputri020-wq/UI-LIB/refs/heads/main/library.lua")
            if type(src) ~= "string" or #src < 1000 then error("HttpGet failed") end
            -- SubPage debounce fix (same as Bloxstrike)
            src = src:gsub(
                [==[if Debounce then
                    -- still force visibility parent switch without waiting previous fade
                    if Bool then
                        Items["Page"].Instance.Visible = true
                        Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                    end
                    return
                end]==],
                [==[if Debounce then
                    Items["Page"].Instance.Visible = Bool == true
                    if Bool then
                        Items["Page"].Instance.Parent = Page.Page.Items["Columns"].Instance
                    else
                        Items["Page"].Instance.Parent = Library.UnusedHolder.Instance
                    end
                    return
                end]==]
            )
            -- Inject Auto Load into Settings → Configs (same place as Bloxstrike)
            do
                local needle = "Library:GetConfigsList(ConfigsDropdown)\n                end\n\n                local ShareSection = ConfigsSubPage:Section({ Name = \"Share\", Side = 2 })"
                local insert = table.concat({
                    "Library:GetConfigsList(ConfigsDropdown)",
                    "",
                    "                    local AutoloadLabel",
                    "                    local function refreshAutoloadLabel()",
                    "                        local folder = ConfigsFolder",
                    "                        local name = \"\"",
                    "                        pcall(function()",
                    "                            if isfile and isfile(folder .. \"autoload.txt\") then",
                    "                                name = tostring(readfile(folder .. \"autoload.txt\") or \"\"):gsub(\"%s+$\", \"\")",
                    "                            end",
                    "                        end)",
                    "                        local txt = (name ~= \"\" and (\"Auto Load: \" .. name) or \"Auto Load: (none)\")",
                    "                        pcall(function()",
                    "                            if AutoloadLabel then",
                    "                                if AutoloadLabel.SetText then AutoloadLabel:SetText(txt)",
                    "                                elseif AutoloadLabel.Set then AutoloadLabel:Set(txt)",
                    "                                elseif AutoloadLabel.SetName then AutoloadLabel:SetName(txt) end",
                    "                            end",
                    "                        end)",
                    "                    end",
                    "",
                    "                    ConfigsSection:Button({",
                    "                        Name = \"Set Auto Load\",",
                    "                        Callback = function()",
                    "                            if not ConfigSelected or ConfigSelected == \"\" then",
                    "                                Library:Notification(\"No config selected\", 3, Color3.fromRGB(255, 0, 0))",
                    "                                return",
                    "                            end",
                    "                            pcall(function()",
                    "                                writefile(ConfigsFolder .. \"autoload.txt\", tostring(ConfigSelected))",
                    "                            end)",
                    "                            refreshAutoloadLabel()",
                    "                            Library:Notification(\"Auto Load set: \" .. tostring(ConfigSelected), 3, Color3.fromRGB(0, 255, 0))",
                    "                        end",
                    "                    })",
                    "",
                    "                    ConfigsSection:Button({",
                    "                        Name = \"Remove Auto Load\",",
                    "                        Callback = function()",
                    "                            pcall(function()",
                    "                                if isfile and isfile(ConfigsFolder .. \"autoload.txt\") then",
                    "                                    if delfile then delfile(ConfigsFolder .. \"autoload.txt\")",
                    "                                    else writefile(ConfigsFolder .. \"autoload.txt\", \"\") end",
                    "                                end",
                    "                            end)",
                    "                            refreshAutoloadLabel()",
                    "                            Library:Notification(\"Auto Load removed\", 3, Color3.fromRGB(0, 255, 0))",
                    "                        end",
                    "                    })",
                    "",
                    "                    AutoloadLabel = ConfigsSection:Label({",
                    "                        Name = \"Auto Load: (none)\",",
                    "                    })",
                    "                    refreshAutoloadLabel()",
                    "                end",
                    "",
                    "                local ShareSection = ConfigsSubPage:Section({ Name = \"Share\", Side = 2 })",
                }, "\n")
                if type(src) == "string" and needle and insert then
                    local pos = string.find(src, needle, 1, true)
                    if pos then
                        src = string.sub(src, 1, pos - 1) .. insert .. string.sub(src, pos + #needle)
                    end
                end
            end
            local fn, err = loadstring(src)
            if not fn then error(tostring(err)) end
            return fn()
        end)
        if not (ok and lib) then
            error("[Methane] UI failed: " .. tostring(lib))
        end
        Library = lib
    end
    getgenv().MethaneLibrary = Library
    getgenv().Library = Library

    local ACCENT = (Library.Theme and Library.Theme.Accent) or Color3.fromRGB(152, 188, 255)

    local LOGO = "rbxassetid://72404794660074"

    -- VindUI removed — Methane UI; soft stubs for leftover cloud/chat calls
    local VindUI = setmetatable({}, {
        __index = function()
            return function() return nil end
        end,
    })
    VindUI.CreateAIAssistant = function() return { Ask = function() end, Stop = function() end, Reset = function() end } end
    VindUI.CloudService = function() return { List = function() return {} end } end
    VindUI.SetBlurEnabled = function() end
    VindUI.Notify = function(_, opts)
        pcall(function()
            if Library and Library.Notification then
                Library:Notification(tostring(opts and (opts.Title or opts.Text) or "Methane"), 2, ACCENT)
            end
        end)
    end

    -- Obsidian-compatible Toggles / Options used by existing feature code
    local Toggles = {}
    local Options = {}
    getgenv().Toggles = Toggles
    getgenv().Options = Options

    local function ensureOptionApi(opt)
        if type(opt) ~= "table" then return end
        opt._changed = opt._changed or {}
        if type(opt.OnChanged) ~= "function" then
            opt.OnChanged = function(self, fn)
                self._changed = self._changed or {}
                table.insert(self._changed, fn)
            end
        end
        if type(opt.SetValue) ~= "function" then
            opt.SetValue = function(self, v)
                self.Value = v
                for _, fn in ipairs(self._changed or {}) do pcall(fn, v) end
            end
        end
        if type(opt.GetState) ~= "function" then
            opt.GetState = function(self)
                local key = self.Value
                if type(key) == "string" then
                    local ok, k = pcall(function() return Enum.KeyCode[key] end)
                    if ok then key = k end
                end
                if typeof(key) ~= "EnumItem" then return false end
                local UIS = game:GetService("UserInputService")
                if self.Mode == "Hold" then return UIS:IsKeyDown(key) end
                return self._toggled == true
            end
        end
    end
    -- Patch Options so late :OnChanged never fails
    setmetatable(Options, {
        __index = function(t, k)
            local o = { Value = nil, Mode = "Toggle", _toggled = false, _changed = {} }
            ensureOptionApi(o)
            rawset(t, k, o)
            return o
        end,
        __newindex = function(t, k, v)
            if type(v) == "table" then ensureOptionApi(v) end
            rawset(t, k, v)
        end,
    })


    -- Keep Methane Library; attach Obsidian-compat Toggles/Options (do NOT overwrite Library)
    do
        local _unloadFns = {}
        Library.Toggles = Toggles
        Library.Options = Options
        Library.Unloaded = false
        Library.OnUnload = function(_, fn)
            if type(fn) == "function" then table.insert(_unloadFns, fn) end
        end
        local _oldUnload = Library.Unload or Library.Exit
        Library.Unload = function(self)
            self.Unloaded = true
            for _, fn in ipairs(_unloadFns) do pcall(fn) end
            if type(_oldUnload) == "function" then pcall(_oldUnload, self) end
        end
        Library.ToggleKeybind = Library.ToggleKeybind
        Library.Scheme = Library.Scheme or { AccentColor = ACCENT }
        Library.AccentColor = ACCENT
        if type(Library.Notify) ~= "function" then
            Library.Notify = function(_, opts)
                pcall(function()
                    local title = (type(opts) == "table" and (opts.Title or opts.Text)) or "Methane"
                    local desc = type(opts) == "table" and (opts.Description or opts.Text or "") or tostring(opts)
                    if Library.Notification then
                        Library:Notification(tostring(title) .. " — " .. tostring(desc), 3, ACCENT)
                    end
                end)
            end
        end
        pcall(function() Library.Brand = "methane" end)
        pcall(function() Library.GameName = "operationone" end)
        pcall(function() Library:EnsureConfigFolders() end)
        pcall(function() if Library.Theme then Library.Theme.Accent = ACCENT end end)
    end
    getgenv().Library = Library
    getgenv().ThemeManager = { SetLibrary = function() end, SetFolder = function() end, ApplyToTab = function() end }
    getgenv().SaveManager = {
        SetLibrary = function() end, IgnoreThemeSettings = function() end, SetIgnoreIndexes = function() end,
        SetFolder = function() end, BuildConfigSection = function() end, LoadAutoloadConfig = function() end,
    }

    local function ico(name)
        local id
        pcall(function() id = Library:ResolveIcon(tostring(name or "circle")) end)
        return (type(id) == "string" and id ~= "" and id) or "rbxassetid://0"
    end

    -- Methane-native wrapGroup (README API: Section:Toggle/Slider/Dropdown/Button/Label + Label:Colorpicker + Toggle:Keybind)
    local function wrapGroup(page)
        local G = {}
        local function needPage()
            return page
        end
        local function regToggle(id, default)
            Toggles[id] = Toggles[id] or { Value = default == true }
            Toggles[id].Value = default == true
            return Toggles[id]
        end

        function G:AddSection(name, _icon)
            pcall(function() page:AddSection(tostring(name or "Section")) end)
        end
        function G:AddDivider()
            pcall(function() if page.AddDivider then page:AddDivider() end end)
        end
        function G:AddLineText(text)
            -- stripped (no configure / helper labels)
        end
        function G:AddParagraph(opts)
            -- stripped
        end

        function G:AddLabel(text)
            local lab
            pcall(function() lab = page:AddLabel(tostring(text or "")) end)
            local chain = {}
            function chain:AddColorPicker(cid, copts)
                copts = copts or {}
                pcall(function()
                    page:AddColorPicker({
                        Text = tostring(text or copts.Text or cid),
                        Flag = cid,
                        Default = copts.Default or Color3.new(1, 1, 1),
                        Callback = function(col)
                            Options[cid] = Options[cid] or {}
                            Options[cid].Value = col
                            if copts.Callback then pcall(copts.Callback, col) end
                        end,
                    })
                end)
                Options[cid] = Options[cid] or { Value = (copts and copts.Default) or Color3.new(1,1,1) }
                return chain
            end
            function chain:AddKeyPicker(kid, kopts)
                kopts = kopts or {}
                pcall(function()
                    page:AddKeybind({
                        Text = kopts.Text or tostring(text or kid),
                        Flag = kid,
                        Default = kopts.Default or "None",
                        Mode = kopts.Mode or "Toggle",
                        Callback = function(v)
                            Options[kid] = Options[kid] or {}
                            Options[kid].Value = v
                            if kopts.Callback then pcall(kopts.Callback, v) end
                        end,
                    })
                end)
                return chain
            end
            return chain
        end

        function G:AddToggle(id, opts)
            opts = opts or {}
            local def = opts.Default == true
            regToggle(id, def)
            local tog
            pcall(function()
                tog = page:AddToggle({
                    Text = opts.Text or id,
                    Flag = id,
                    Default = def,
                    Risky = opts.Risky == true,
                    Callback = function(v)
                        Toggles[id].Value = v == true
                        Options[id] = Options[id] or { Value = v }
                        Options[id].Value = v
                        if opts.Callback then pcall(opts.Callback, v) end
                    end,
                })
            end)
            local chain = { _tog = tog }
            function chain:AddKeyPicker(kid, kopts)
                kopts = kopts or {}
                local mode = kopts.Mode or "Toggle"
                local def = kopts.Default or "None"
                local defEnum = def
                if type(def) == "string" and def ~= "None" and not def:find("MB") then
                    pcall(function() defEnum = Enum.KeyCode[def] or def end)
                end
                pcall(function()
                    if tog and type(tog.Keybind) == "function" then
                        tog:Keybind({
                            Name = kopts.Text or kid,
                            Flag = kid,
                            Mode = mode,
                            Default = defEnum,
                            Callback = function(v)
                                Options[kid] = Options[kid] or {}
                                if v ~= nil and v ~= true and v ~= false then
                                    Options[kid].Value = v
                                    Options[kid].Key = v
                                end
                                Options[kid].Mode = mode
                                if kopts.Callback then pcall(kopts.Callback, v) end
                            end,
                        })
                    else
                        page:AddKeybind({
                            Text = kopts.Text or "Key",
                            Flag = kid,
                            Default = def,
                            Mode = mode,
                            Callback = function(v)
                                Options[kid] = Options[kid] or {}
                                if v ~= nil and v ~= true and v ~= false then
                                    Options[kid].Value = v
                                    Options[kid].Key = v
                                end
                                Options[kid].Mode = mode
                                if kopts.Callback then pcall(kopts.Callback, v) end
                            end,
                        })
                    end
                end)
                Options[kid] = Options[kid] or { Value = def, Key = def, Mode = mode, _toggled = false }
                Options[kid].Mode = mode
                Options[kid].Value = def
                Options[kid].Key = def
                Options[kid]._toggled = Options[kid]._toggled or false
                Options[kid].GetState = function(self)
                    local key = self.Value or self.Key
                    if not key or key == "None" then return false end
                    local m = self.Mode or mode or "Toggle"
                    if m == "Toggle" then
                        return self._toggled == true
                    end
                    -- Hold / Always: physical key down
                    local ok, down = pcall(function()
                        local UIS = game:GetService("UserInputService")
                        if type(key) == "string" and key:find("MB") then
                            local map = { MB1 = Enum.UserInputType.MouseButton1, MB2 = Enum.UserInputType.MouseButton2 }
                            local uit = map[key]
                            if uit then return UIS:IsMouseButtonPressed(uit) end
                        end
                        local name = tostring(key):gsub("Enum%.KeyCode%.", "")
                        local kc = typeof(key) == "EnumItem" and key or Enum.KeyCode[name]
                        if kc then return UIS:IsKeyDown(kc) end
                        return false
                    end)
                    return ok and down == true
                end
                -- track for InputBegan flip (Toggle mode)
                getgenv()._MethaneKeyOpts = getgenv()._MethaneKeyOpts or {}
                getgenv()._MethaneKeyOpts[kid] = Options[kid]
                return chain
            end
            function chain:AddColorPicker(cid, copts)
                copts = copts or {}
                pcall(function()
                    page:AddColorPicker({
                        Text = copts.Text or (opts.Text or id) .. " Color",
                        Flag = cid,
                        Default = copts.Default or Color3.new(1, 1, 1),
                        Callback = function(col)
                            Options[cid] = Options[cid] or {}
                            Options[cid].Value = col
                            if copts.Callback then pcall(copts.Callback, col) end
                        end,
                    })
                end)
                Options[cid] = Options[cid] or { Value = (copts and copts.Default) or Color3.new(1,1,1) }
                return chain
            end
            return chain
        end

        function G:AddSlider(id, opts)
            opts = opts or {}
            local def = opts.Default or 0
            pcall(function()
                page:AddSlider({
                    Text = opts.Text or id,
                    Flag = id,
                    Default = def,
                    Min = opts.Min or 0,
                    Max = opts.Max or 100,
                    Increment = (opts.Rounding == 1 and 0.1) or (opts.Rounding == 2 and 0.01) or (opts.Rounding == 3 and 0.001) or 1,
                    Suffix = opts.Suffix or "",
                    Callback = function(v)
                        Options[id] = Options[id] or {}
                        Options[id].Value = v
                        if opts.Callback then pcall(opts.Callback, v) end
                    end,
                })
            end)
            Options[id] = { Value = def }
        end

        function G:AddDropdown(id, opts)
            opts = opts or {}
            local values = opts.Values or opts.Options or { "None" }
            local def = opts.Default
            if def == nil then def = values[1] end
            pcall(function()
                page:AddDropdown({
                    Text = opts.Text or id,
                    Flag = id,
                    Options = values,
                    Default = def,
                    Multi = opts.Multi == true,
                    Callback = function(v)
                        Options[id] = Options[id] or {}
                        Options[id].Value = v
                        if opts.Callback then pcall(opts.Callback, v) end
                    end,
                })
            end)
            Options[id] = { Value = def }
        end

        function G:AddButton(opts)
            opts = opts or {}
            pcall(function()
                page:AddButton({
                    Text = opts.Text or "Button",
                    Callback = opts.Func or opts.Callback or function() end,
                })
            end)
        end

        function G:AddColorPicker(id, opts)
            opts = opts or {}
            pcall(function()
                page:AddColorPicker({
                    Text = opts.Text or id,
                    Flag = id,
                    Default = opts.Default or Color3.new(1, 1, 1),
                    Callback = function(col)
                        Options[id] = Options[id] or {}
                        Options[id].Value = col
                        if opts.Callback then pcall(opts.Callback, col) end
                    end,
                })
            end)
            Options[id] = Options[id] or { Value = opts.Default or Color3.new(1,1,1) }
        end

        function G:AddKeyPicker(id, opts)
            opts = opts or {}
            pcall(function()
                page:AddKeybind({
                    Text = opts.Text or id,
                    Flag = id,
                    Default = opts.Default or "RightShift",
                    Mode = opts.Mode or "Toggle",
                    Callback = function(v)
                        Options[id] = Options[id] or {}
                        Options[id].Value = v
                        if opts.Callback then pcall(opts.Callback, v) end
                    end,
                })
            end)
            Options[id] = Options[id] or { Value = opts.Default or "RightShift" }
        end

        return G
    end

    -- Methane Window (same args as Bloxstrike)
    pcall(function() Library.Brand = "methane" end)
    pcall(function() Library.GameName = "operationone" end)
    local Window = Library:Window({
        Title = "Methane",
        ButtonName = "Operation One",
        BrandName = "Methane",
        BrandAlign = "Center",
        Logo = LOGO,
    })
    getgenv().MethaneOp1 = { Window = Window, Library = Library }

    -- Toggle-mode keybind state (Freecam / ESP / etc.)
    do
        local UIS = game:GetService("UserInputService")
        local function resolveKey(opt, kid)
            local candidates = {}
            if type(opt) == "table" then
                table.insert(candidates, opt.Key)
                table.insert(candidates, opt.Value)
            end
            pcall(function()
                local f = Library.Flags and Library.Flags[kid]
                if f ~= nil then
                    if type(f) == "table" then
                        table.insert(candidates, f.Key or f.Value or f.KeyCode)
                    else
                        table.insert(candidates, f)
                    end
                end
            end)
            for _, key in ipairs(candidates) do
                if key ~= nil and key ~= true and key ~= false and key ~= "None" and key ~= "" then
                    return key
                end
            end
            return nil
        end
        local function keyMatches(opt, input, kid)
            local key = resolveKey(opt, kid)
            if key == nil then return false end
            if type(key) == "number" then return false end
            if type(key) == "string" and key:find("MB") then
                local map = {
                    MB1 = Enum.UserInputType.MouseButton1,
                    MB2 = Enum.UserInputType.MouseButton2,
                    MB3 = Enum.UserInputType.MouseButton3,
                }
                return input.UserInputType == map[key]
            end
            if typeof(key) == "EnumItem" then
                if key.EnumType == Enum.KeyCode then return input.KeyCode == key end
                if key.EnumType == Enum.UserInputType then return input.UserInputType == key end
            end
            if type(key) == "string" then
                local name = key:gsub("Enum%.KeyCode%.", "")
                local ok, kc = pcall(function() return Enum.KeyCode[name] end)
                if ok and typeof(kc) == "EnumItem" then
                    return input.KeyCode == kc
                end
            end
            return false
        end
        -- keybind alone drives feature (does NOT touch Enabled toggles)
        getgenv()._MethaneFreecamKeyOn = false
        getgenv()._MethaneThirdPersonKeyOn = false
        UIS.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard
                and input.UserInputType ~= Enum.UserInputType.MouseButton1
                and input.UserInputType ~= Enum.UserInputType.MouseButton2
                and input.UserInputType ~= Enum.UserInputType.MouseButton3 then
                return
            end
            local opts = getgenv()._MethaneKeyOpts
            if type(opts) ~= "table" then return end
            for kid, opt in pairs(opts) do
                if (opt.Mode or "Toggle") ~= "Toggle" then continue end
                if not keyMatches(opt, input, kid) then continue end
                opt._toggled = not (opt._toggled == true)
                if kid == "FreecamKey" then
                    getgenv()._MethaneFreecamKeyOn = opt._toggled == true
                elseif kid == "ThirdPersonKey" then
                    local on = opt._toggled == true
                    getgenv()._MethaneThirdPersonKeyOn = on
                    pcall(function()
                        if type(settings) == "table" then
                            settings.ThirdPersonEnabled = on
                        end
                    end)
                    if not on then
                        pcall(function()
                            local stop = getgenv()._MethaneStopThirdPerson
                            if type(stop) == "function" then stop() end
                        end)
                    end
                end
            end
        end)
    end


    -- makeTab / makeSub adapters (same pattern as Bloxstrike)
    local function ico(n)
        local id
        pcall(function() id = Library:ResolveIcon(tostring(n or "circle")) end)
        return (type(id) == "string" and id ~= "" and id) or "rbxassetid://0"
    end
    local function makeTab(name)
        return Window:Page({ Name = name })
    end
    local function makeSub(page, name, iconName)
        local sub = page:SubPage({ Name = name, Icon = ico(iconName or "circle") })
        local side, current = 1, nil
        local api = {}
        local sectionsByName = {}
        local function ensure(secName)
            secName = tostring(secName or "Gun Mods")
            if sectionsByName[secName] then
                current = sectionsByName[secName]
                return current
            end
            local useSide = side
            current = sub:Section({ Name = secName, Side = useSide })
            sectionsByName[secName] = current
            side = (side == 1) and 2 or 1
            return current
        end
        function api:AddSection(n, _) return ensure(n) end
        function api:AddDivider() end
        function api:AddLineText(_) end
        function api:SelectSubTab(_) end
        local function need()
            if not current then ensure("Gun Mods") end
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
            return need():Button({ Name = opts.Text or opts.Name or "Button", Callback = opts.Callback or opts.Func or function() end })
        end
        function api:AddColorPicker(opts)
            opts = opts or {}
            local lab = need():Label({ Name = opts.Text or opts.Name or "Color" })
            return lab:Colorpicker({
                Flag = opts.Flag, Default = opts.Default or Color3.new(1,1,1),
                Callback = function(col, a) if opts.Callback then pcall(opts.Callback, col, a) end end,
            })
        end
        function api:AddKeybind(opts)
            opts = opts or {}
            return need():Keybind({
                Name = opts.Text or opts.Name or "Key", Flag = opts.Flag,
                Default = opts.Default or "None", Mode = opts.Mode or "Toggle",
                Callback = opts.Callback or function() end,
            })
        end
        function api:AddLabel(text)
            return need():Label({ Name = tostring(text or "") })
        end
        return api
    end

    local CombatTab = makeTab("Combat")
    local VisualsTab = makeTab("Visuals")
    local MiscTab = makeTab("Misc")

    -- Combat: Rage | Legit | Gun Mods (exploits live inside Gun Mods)
    local SilentAimSub = makeSub(CombatTab, "Rage", "flame")
    local LegitSub = makeSub(CombatTab, "Legit", "crosshair")
    local GunModsSub = makeSub(CombatTab, "Gun Mods", "swords")
    local ExploitsSub = GunModsSub -- exploits merged into gun mods

    -- Visuals: exactly 3 sub-tabs — Entities / World / Gadgets
    local VisESP = makeSub(VisualsTab, "Entities", "users")
    local VisWorld = makeSub(VisualsTab, "World", "globe")
    local VisGadgets = makeSub(VisualsTab, "Gadgets", "package")
    local VisGadgetSel = VisGadgets
    local VisGrenades = VisGadgets
    local VisGrenadeSel = VisGadgets

    -- Misc
    local MiscLocal = makeSub(MiscTab, "Local", "user")
    local MiscExtra = makeSub(MiscTab, "Extra", "wrench")

    -- CreateSettingsPage runs AFTER RegisterSettingsWidget (widgets must exist first)

    local Tabs = {
        Rage = wrapGroup(SilentAimSub),
        GunMods = wrapGroup(GunModsSub),
        Exploits = wrapGroup(ExploitsSub),
        Legit = wrapGroup(LegitSub),
        Visuals = wrapGroup(VisESP),
        Gadgets = wrapGroup(VisGadgets),
        GadgetMain = wrapGroup(VisGadgets),
        GadgetSelect = wrapGroup(VisGadgetSel),
        GrenadeMain = wrapGroup(VisGrenades),
        GrenadeSelect = wrapGroup(VisGrenadeSel),
        World = wrapGroup(VisWorld),
        WorldLighting = wrapGroup(VisWorld),
        WorldAtmosphere = wrapGroup(VisWorld),
        WorldAmbience = wrapGroup(VisWorld),
        WorldLocal = wrapGroup(MiscLocal),
        WorldExtra = wrapGroup(MiscExtra),
        -- Settings page is Window:CreateSettingsPage only (not a feature tab)
        Settings = wrapGroup(MiscExtra),
    }

    -- Widgets: Watermark + Keybind List + Target HUD (Settings → Widgets toggles)
    pcall(function()
        local wm = Library:Watermark({ Name = "METHANE.LUA" })
        if wm and wm.SetDynamicTextProvider then
            wm:SetDynamicTextProvider(function(fps)
                local ms = 0
                pcall(function()
                    ms = math.floor((LocalPlayer:GetNetworkPing() or 0) * 1000 + 0.5)
                end)
                if ms < 0 then ms = 0 end
                return string.format("METHANE.LUA | OPERATION ONE | %s FPS | %s MS", tostring(fps or 0), tostring(ms))
            end)
        end
        pcall(function() if wm.SetVisibility then wm:SetVisibility(false) end end)
        getgenv().MethaneWatermark = wm
        Library:RegisterSettingsWidget({
            Name = "Watermark",
            Default = false,
            Callback = function(v)
                local w = getgenv().MethaneWatermark
                if w and w.SetVisibility then
                    pcall(function() w:SetVisibility(v == true) end)
                end
            end,
        })
    end)
    pcall(function()
        local kbl = Library:KeybindList({ Name = "Keybinds" })
        if kbl and kbl.SetVisibility then
            pcall(function() kbl:SetVisibility(false) end)
        end
        getgenv().MethaneKeybindList = kbl
        Library:RegisterSettingsWidget({
            Name = "Keybind List",
            Default = false,
            Callback = function(v)
                local k = getgenv().MethaneKeybindList
                if k and k.SetVisibility then
                    pcall(function() k:SetVisibility(v == true) end)
                end
            end,
        })
    end)
    pcall(function()
        local ti = Library:TargetIndicator()
        getgenv().MethaneTargetIndicator = ti
        pcall(function() if ti.SetVisibility then ti:SetVisibility(false) end end)
        getgenv().MethaneTargetHudAllowed = false
        Library:RegisterSettingsWidget({
            Name = "Target HUD",
            Default = false,
            Callback = function(v)
                getgenv().MethaneTargetHudAllowed = (v == true)
                if not v then
                    pcall(function()
                        if ti.SetTarget then ti:SetTarget(nil) end
                        if ti.SetVisibility then ti:SetVisibility(false) end
                    end)
                end
            end,
        })
    end)
    pcall(function()
        Library:Notification("Methane | Operation One loaded", 3, ACCENT)
    end)

    -- ONE settings page — after all widgets registered so Widgets section fills
    pcall(function()
        if Window and Window.CreateSettingsPage then
            Window:CreateSettingsPage()
        end
    end)


    -- Autoload config (same pattern as Bloxstrike)
    task.spawn(function()
        task.wait(0.75)
        pcall(function()
            if not Library or not Library.LoadConfig then return end
            pcall(function() Library:EnsureConfigFolders() end)
            local folder = tostring(Library.Directory or "MethaneUI")
                .. tostring(Library.Folders and Library.Folders.Configs or "/methane/cfgs/operationone")
            if not folder:find("/$") and not folder:find("\$") then
                folder = folder .. "/"
            end
            if not isfile or not isfile(folder .. "autoload.txt") then return end
            local name = tostring(readfile(folder .. "autoload.txt") or ""):gsub("%s+$", "")
            if name == "" then return end
            local cfgPath = folder .. name
            if not name:find("%.json$") then cfgPath = folder .. name .. ".json" end
            if not isfile(cfgPath) then return end
            local content = readfile(cfgPath)
            if type(content) ~= "string" or content == "" then return end
            local ok = Library:LoadConfig(content)
            if ok then
                pcall(function()
                    if Library.Notification then
                        Library:Notification("Autoloaded: " .. name, 3, ACCENT)
                    end
                end)
            end
        end)
    end)

local settings = {
        SilentEnabled = false,
        SilentFovCircle = false,
        SilentFov = 200,
        SilentFovCircleColor = Color3.new(1,1,1),
        SilentHitChance = 100,
        SilentVisCheck = false,
        SilentTeamCheck = false,
        HitPart = "closest",
        RageAutoFire = false,
        RageForceHitbox = false,
        RageManipulation = false,
        RageManipIndicator = false,

        RageTargetHitbox = "Head",
        RageManipDistance = 3,
        SpeedBoostEnabled = false,
        SpeedBoostAmount = 0,
        SnaplineEnabled = false,
        SnaplineColor = Color3.new(1, 0, 0),
        RecoilUp = 1,
        RecoilSide = 1,
        Spread = 1,

        -- 3rd Person
        ThirdPersonEnabled = false,
        ThirdPersonDist = 10,

        -- Model Changer (Misc → Extra)
        ModelChanger = false,
        ModelPreset = "Triple T",
        ModelScale = 1,
        ModelHideBody = true,
    }

    -- First-person eye CFrame (used by ESP + rage when 3rd person is on)
    -- FIXED: always returns the physical head/HRP position as origin, never the
    -- orbit camera position. This keeps ESP boxes pinned to enemies regardless of
    -- where the camera is sitting behind the player.


    local function cfr(from, to)
        return CFrame.lookAt(from, to)
    end

    -- VisCheck: floor/roof penetration fix.
    -- Ragebot shoots through WALLS (intended) but NOT floors or roofs.
    -- Logic: cast a ray to the target, walk every hit along the path.
    -- If any hit part's surface normal points mostly UP or DOWN (Y > 0.6),
    -- it's a floor or roof — block the shot. Walls have near-zero Y normal,
    -- so they are ignored and the ray keeps going (wall-pen preserved).
    local _FLOOR_ROOF_Y_THRESHOLD = 0.6 -- normal Y dot product; 0.6 ≈ surfaces within ~53° of horizontal

    -- Names/keywords that identify floor/roof parts even if normal is ambiguous
    local _FLOOR_ROOF_KEYWORDS = {
        "floor", "roof", "ceiling", "ground", "base", "platform",
        "Foundation", "Floor", "Roof", "Ceiling", "Ground", "Base", "Platform"
    }

    local function _nameHasFloorRoofKeyword(name)
        local lower = name:lower()
        for _, kw in ipairs(_FLOOR_ROOF_KEYWORDS) do
            if lower:find(kw:lower(), 1, true) then
                return true
            end
        end
        return false
    end

    local function _isFloorOrRoof(hitInstance, hitNormal)
        -- Primary check: surface normal Y component — floors/roofs face up or down
        if hitNormal and math.abs(hitNormal.Y) >= _FLOOR_ROOF_Y_THRESHOLD then
            return true
        end
        -- Secondary check: part name contains floor/roof keywords
        if hitInstance and hitInstance.Name and _nameHasFloorRoofKeyword(hitInstance.Name) then
            return true
        end
        return false
    end

    local function isVisible(targetPart)
        -- Silent pen check (same idea as ragebot): soft walls ok, floor/hard block
        if not targetPart or typeof(targetPart) ~= "Instance" or targetPart.Parent == nil then
            return false
        end
        if not targetPart:IsA("BasePart") then return false end
        if targetPart.Transparency >= 0.99 then return false end

        local cam = workspace.CurrentCamera
        if not cam then return false end
        local char = LocalPlayer.Character
        if not char then return false end

        local origin = cam.CFrame.Position
        local targetPos = targetPart.Position
        if (targetPos - origin).Magnitude < 0.05 then return true end

        local exclude = { char }
        pcall(function()
            local vms = workspace:FindFirstChild("Viewmodels")
            if vms then table.insert(exclude, vms) end
            local mdl = targetPart:FindFirstAncestorOfClass("Model")
            if mdl then table.insert(exclude, mdl) end
        end)

        local penFn = getgenv()._MethaneRageCanPenetrate
        if type(penFn) == "function" then
            local ok, res = pcall(penFn, origin, targetPos, exclude)
            if ok then return res == true end
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = exclude
        params.IgnoreWater = true
        local dir = targetPos - origin
        local result = workspace:Raycast(origin, dir, params)
        if not result then return true end
        local upDot = math.abs(result.Normal:Dot(Vector3.yAxis))
        if upDot > 0.75 then return false end
        local inst = result.Instance
        if inst and (inst.Transparency > 0.25 or inst.CanCollide == false) then
            local step = result.Position + dir.Unit * 0.3
            local left = targetPos - step
            if left.Magnitude < 0.15 then return true end
            return workspace:Raycast(step, left, params) == nil
        end
        -- one soft-wall step for thin props
        local step = result.Position + dir.Unit * 0.35
        local left = targetPos - step
        if left.Magnitude < 0.15 then return true end
        local r2 = workspace:Raycast(step, left, params)
        return r2 == nil
    end

    -- ==================== SPEED BOOST ====================
    -- O1 applies speed via Character.states.speed_multiplier → u6() → Humanoid.WalkSpeed.
    -- LinearVelocity with Y forced to 0 caused stair float / stuck movement.
    -- Fix: prefer speed_multiplier (game path), soft XZ-only velocity assist, never touch Y.

    local _speedBoostLV    = nil
    local _speedBoostAtt   = nil
    local _speedBoostChar  = nil
    local _speedRS         = nil
    local _speedCharObj    = nil  -- StateObject Character for local player
    local _speedOrigMult   = nil

    local function _destroySpeedConstraint()
        pcall(function() if _speedBoostLV  then _speedBoostLV:Destroy()  end end)
        pcall(function() if _speedBoostAtt then _speedBoostAtt:Destroy() end end)
        _speedBoostLV   = nil
        _speedBoostAtt  = nil
        _speedBoostChar = nil
    end

    local function _findLocalCharacterSO()
        local found = nil
        pcall(function()
            local rs = (cloneref and cloneref(game:GetService("ReplicatedStorage"))) or game:GetService("ReplicatedStorage")
            local SO = require(rs.Modules.StateObject)
            for _, character in SO.get_all("Character") do
                local owner = character.owner and character.owner:get()
                if owner == LocalPlayer then
                    found = character
                    return
                end
            end
        end)
        return found
    end

    local function _setSpeedMultiplier(mult)
        local ch = _speedCharObj
        if not ch or not ch.states or not ch.states.speed_multiplier then
            ch = _findLocalCharacterSO()
            _speedCharObj = ch
        end
        if not ch or not ch.states or not ch.states.speed_multiplier then return false end
        pcall(function()
            if _speedOrigMult == nil then
                _speedOrigMult = ch.states.speed_multiplier:get() or 1
            end
            ch.states.speed_multiplier:set(mult)
        end)
        return true
    end

    local function _restoreSpeedMultiplier()
        if _speedOrigMult == nil then return end
        pcall(function()
            local ch = _speedCharObj or _findLocalCharacterSO()
            if ch and ch.states and ch.states.speed_multiplier then
                ch.states.speed_multiplier:set(_speedOrigMult)
            end
        end)
        _speedOrigMult = nil
    end

    local function _ensureSpeedConstraint(hrp, char)
        if _speedBoostChar ~= char or not _speedBoostLV or not _speedBoostLV.Parent then
            _destroySpeedConstraint()

            local att = Instance.new("Attachment")
            att.Name = "_MSpeedAtt"
            att.Parent = hrp

            local lv = Instance.new("LinearVelocity")
            lv.Name = "_MSpeedLV"
            lv.Attachment0 = att
            lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
            lv.RelativeTo = Enum.ActuatorRelativeTo.World
            lv.VectorVelocity = Vector3.zero
            -- Critical: do NOT fight gravity / stairs — zero force on Y
            pcall(function()
                lv.ForceLimitsEnabled = true
                lv.MaxAxesForce = Vector3.new(8e4, 0, 8e4)
            end)
            pcall(function()
                if lv.MaxAxesForce == nil then
                    lv.MaxForce = 8e4
                end
            end)
            lv.Parent = hrp

            _speedBoostAtt  = att
            _speedBoostLV   = lv
            _speedBoostChar = char
        end
    end

    local function _startSpeedBoost()
        if _speedRS then return end
        _speedRS = RunService.Heartbeat:Connect(function(dt)
            local lp = Players.LocalPlayer
            if not lp then return end
            local char = lp.Character
            if not char then
                _destroySpeedConstraint()
                _speedCharObj = nil
                return
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                _destroySpeedConstraint()
                return
            end

            if not settings.SpeedBoostEnabled then
                if _speedBoostLV and _speedBoostLV.Parent then
                    _speedBoostLV.VectorVelocity = Vector3.zero
                end
                _restoreSpeedMultiplier()
                return
            end

            local amount = tonumber(settings.SpeedBoostAmount) or 0
            if amount <= 0.01 then
                if _speedBoostLV and _speedBoostLV.Parent then
                    _speedBoostLV.VectorVelocity = Vector3.zero
                end
                _restoreSpeedMultiplier()
                return
            end

            -- Soft clamp: O1 server rejects big position deltas; keep boost modest
            amount = math.clamp(amount, 0, 2.25)

            -- Layer 1: game-native multiplier (feeds WalkSpeed via u6)
            -- amount is a multiplier (1 = normal, 1.5 = 50% faster)
            local mult = math.clamp(amount, 1, 2.0)
            if amount < 1 then mult = 1 end
            _setSpeedMultiplier(mult)

            -- Layer 2: small XZ assist only when actually moving on ground
            local moveDir = hum.MoveDirection
            local onGround = true
            pcall(function()
                local st = hum:GetState()
                if st == Enum.HumanoidStateType.Freefall
                    or st == Enum.HumanoidStateType.Jumping
                    or st == Enum.HumanoidStateType.Flying
                    or st == Enum.HumanoidStateType.FallingDown then
                    onGround = false
                end
            end)
            -- Floor ray (catches ledge drops before state updates)
            pcall(function()
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = { char }
                local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -3.5, 0), params)
                if not hit then onGround = false end
            end)
            -- Never apply vertical velocity from boost
            pcall(function()
                if _speedBoostLV then
                    local v = _speedBoostLV.VectorVelocity
                    if v.Y ~= 0 then
                        _speedBoostLV.VectorVelocity = Vector3.new(v.X, 0, v.Z)
                    end
                    pcall(function()
                        _speedBoostLV.MaxAxesForce = Vector3.new(8e4, 0, 8e4)
                    end)
                end
            end)

            -- Airborne / no input: fully release constraint so gravity is never damped
            if moveDir.Magnitude < 0.08 or not onGround then
                pcall(function()
                    if _speedBoostLV and _speedBoostLV.Parent then
                        _speedBoostLV.Enabled = false
                        _speedBoostLV.VectorVelocity = Vector3.zero
                    end
                end)
                -- Don't touch multiplier mid-air; leave walk state alone
                return
            end
            pcall(function()
                if _speedBoostLV and _speedBoostLV.Parent then
                    _speedBoostLV.Enabled = true
                end
            end)

            _ensureSpeedConstraint(hrp, char)
            if not _speedBoostLV then return end

            local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)
            if flatDir.Magnitude < 0.01 then
                _speedBoostLV.VectorVelocity = Vector3.zero
                return
            end
            flatDir = flatDir.Unit

            -- Assist only the EXTRA speed beyond WalkSpeed so we don't double-drive
            local base = hum.WalkSpeed
            if base < 1 then base = 12 end
            local extra = math.max(0, (amount - 1) * base * 0.35)
            if extra < 0.15 then
                _speedBoostLV.VectorVelocity = Vector3.zero
                return
            end

            -- Preserve Y: never write 0 into Y (stairs / fall)
            local yVel = hrp.AssemblyLinearVelocity.Y
            _speedBoostLV.VectorVelocity = Vector3.new(
                flatDir.X * (base + extra),
                yVel,
                flatDir.Z * (base + extra)
            )
        end)
    end

    local function _stopSpeedBoost()
        if _speedRS then
            pcall(function() _speedRS:Disconnect() end)
            _speedRS = nil
        end
        _restoreSpeedMultiplier()
        _destroySpeedConstraint()
    end

    _startSpeedBoost()
    -- ==================== END SPEED BOOST ====================


    -- same source as legit aim (playerToViewmodel). Standard Character HRP is unreliable in O1.
    local _SILENT_PARTS = { "head", "torso", "shoulder1", "shoulder2", "arm1", "arm2", "hip1", "hip2", "leg1", "leg2" }

    local function _silentIsEnemy(player)
        if not settings.SilentTeamCheck then return true end
        local ok = true
        pcall(function()
            local myTeam = LocalPlayer:GetAttribute("Team") or LocalPlayer:GetAttribute("TeamID")
            if not myTeam then return end
            local theirTeam = player:GetAttribute("Team") or player:GetAttribute("TeamID")
            if theirTeam ~= nil and myTeam == theirTeam then ok = false end
        end)
        return ok
    end

    local function resolveSilentPart(vm)
        local hp = settings.HitPart or "closest"
        if hp == "head" then
            return vm:FindFirstChild("head") or vm:FindFirstChild("Head")
        elseif hp == "torso" then
            return vm:FindFirstChild("torso") or vm:FindFirstChild("Torso") or vm:FindFirstChild("UpperTorso")
        end
        -- closest: prefer head then torso then any part
        return vm:FindFirstChild("head")
            or vm:FindFirstChild("torso")
            or vm:FindFirstChild("Head")
            or vm.PrimaryPart
            or vm:FindFirstChildWhichIsA("BasePart")
    end

    GetTarget = function()
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        local mousePos = UserInputService:GetMouseLocation()
        local fovRadius = settings.SilentFov or 200
        local closestDistance = math.huge
        local bestPart = nil

        -- Primary: O1 viewmodels
        local map = playerToViewmodel
        if type(map) == "table" then
            for player, vm in next, map do
                if not player or player == LocalPlayer then continue end
                if not vm or not vm.Parent then continue end
                if not _silentIsEnemy(player) then continue end

                local aimPart = resolveSilentPart(vm)
                if not aimPart then continue end

                local screenPos, onScreen = camera:WorldToViewportPoint(aimPart.Position)
                if not onScreen then continue end

                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance > fovRadius or distance >= closestDistance then continue end
                if settings.SilentVisCheck and not isVisible(aimPart) then continue end

                closestDistance = distance
                bestPart = aimPart
            end
        end

        -- Fallback: classic Character (if viewmodels empty)
        if not bestPart then
            for _, v in pairs(Players:GetPlayers()) do
                if v == LocalPlayer then continue end
                if not _silentIsEnemy(v) then continue end
                local char = v.Character
                if not char then continue end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then continue end
                local aim = resolveSilentPart(char) or hrp
                local screenPos, onScreen = camera:WorldToViewportPoint(aim.Position)
                if not onScreen then continue end
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if distance > fovRadius or distance >= closestDistance then continue end
                if settings.SilentVisCheck and not isVisible(aim) then continue end
                closestDistance = distance
                bestPart = aim
            end
        end

        return bestPart
    end

    local DS = { -- drone settings
        Enabled = true,
        ShowName = true,
        NameColor = Color3.new(1,1,1),
        NameSize = 8,
        NameOutline = true,
        NameOutlineColor = Color3.new(0,0,0),
        ShowDistance = true,
        DistanceColor = Color3.new(1,1,1),
        ShowBox = true,
        BoxColor = Color3.new(1,0,0),
        BoxThickness = 1,
        BoxOutline = true,
        BoxOutlineColor = Color3.new(0,0,0),
        BoxFill = false,
        BoxFillColor = Color3.new(1,1,1),
        BoxFillTransparency = 0.5
    }

    -- potentially could do AntiFlash (line 1462 character.luau)
    -- potentially could do quick vault? (line 1030 character.luau)

    -- phookfunction was MISSING in this build → "attempt to call a nil value" at silent-aim hook
    local function phookfunction(target, replacement)
        if typeof(target) ~= "function" then
            return nil
        end
        if type(hookfunction) ~= "function" then
            return nil
        end
        local ok, original = pcall(hookfunction, target, replacement)
        if not ok or typeof(original) ~= "function" then
            return nil
        end
        return original
    end

    local function wrapClosure(fn)
        if type(newcclosure) == "function" then
            local ok, wrapped = pcall(newcclosure, fn)
            if ok and typeof(wrapped) == "function" then
                return wrapped
            end
        end
        return fn
    end

    if type(math.map) ~= "function" then
        function math.map(x, inMin, inMax, outMin, outMax)
            if inMax == inMin then return outMin end
            return outMin + (outMax - outMin) * ((x - inMin) / (inMax - inMin))
        end
    end

    local function pgetupval(fn, index)
        if typeof(fn) ~= "function" or type(getupvalue) ~= "function" then return nil end
        local ok, value = pcall(getupvalue, fn, index)
        return ok and value or nil
    end

    local function pgetupvals(fn)
        if typeof(fn) ~= "function" or type(getupvalues) ~= "function" then return nil end
        local ok, values = pcall(getupvalues, fn)
        return ok and values or nil
    end

    -- Find Gun functions lazily (only when a feature that needs them is enabled)
    local recoil_func, shoot_func = nil, nil
    local gun_handler = nil
    local _gunFuncsResolved = false

    local function resolveGunFuncs()
        -- Allow retry until gun_handler is found (late inject / modules not ready)
        if _gunFuncsResolved and gun_handler then return end
        pcall(function()
            local _isl = (type(islclosure) == "function" and islclosure) or function() return true end
            local _ginfo = (debug and type(debug.getinfo) == "function" and debug.getinfo) or function() return {} end
            if type(getgc) == "function" then
                for _, v in pairs(getgc() or {}) do
                    pcall(function()
                        if typeof(v) ~= "function" or not _isl(v) then return end
                        local dbg = _ginfo(v)
                        if type(dbg) ~= "table" then return end
                        local name = dbg.name
                        local short = tostring(dbg.short_src or "")
                        if short:find("Gun") and name and tostring(name):find("recoil_function") then
                            recoil_func = v
                        elseif short:find("Gun") and name and tostring(name):find("send_shoot") then
                            shoot_func = v
                        end
                    end)
                end
            end
        end)
        pcall(function()
            local rs = (cloneref and cloneref(game:GetService("ReplicatedStorage"))) or game:GetService("ReplicatedStorage")
            local gunMod = rs:FindFirstChild("Modules")
            gunMod = gunMod and gunMod:FindFirstChild("Items")
            gunMod = gunMod and gunMod:FindFirstChild("Item")
            gunMod = gunMod and gunMod:FindFirstChild("Gun")
            if gunMod then
                gun_handler = require(gunMod)
            end
        end)
        if gun_handler then
            _gunFuncsResolved = true
        end
    end

    local function get_circular_spread(p277, p278)
        local a = math.random() * math.pi * 2
        local r = math.random() * p278
        return p277.RightVector * math.cos(a) * r + p277.UpVector * math.sin(a) * r
    end

    -- ---- Gun Mods (RCS + Spread): lazy install ----
    local _gunModsHooksInstalled = false
    local old_recoil, old_shoot = nil, nil


    -- Live gun-mod values (UI + hooks share via genv — survives scope isolation)
    getgenv()._VantaGunMods = getgenv()._VantaGunMods or {
        Spread = settings.Spread or 1,
        RecoilUp = settings.RecoilUp or 1,
        RecoilSide = settings.RecoilSide or 1,
    }

    local function _InstallGunModsHooks()
        if _gunModsHooksInstalled then return end
        _gunModsHooksInstalled = true
        resolveGunFuncs()

        if typeof(recoil_func) == "function" then
            -- Wrap state:get so every shot (including spray climb) reads scaled recoil.
            -- Do not set/restore per-shot — that killed sustained climb after the first kick.
            local function wrapRecoilGet(state, which)
                if not state or state._strideRcsWrap then return end
                local rawGet = state.get
                if typeof(rawGet) ~= "function" then return end
                state.get = function(self, ...)
                    local base = rawGet(self, ...)
                    if type(base) ~= "number" then return base end
                    local mul = 1
                    local gm = getgenv()._VantaGunMods or settings
                    if which == "up" then
                        mul = tonumber(gm.RecoilUp) or settings.RecoilUp or 1
                    else
                        mul = tonumber(gm.RecoilSide) or settings.RecoilSide or 1
                    end
                    if mul >= 0.999 then return base end
                    return base * mul
                end
                state._strideRcsWrap = true
            end

            old_recoil = phookfunction(recoil_func, wrapClosure(function(...)
                if typeof(old_recoil) ~= "function" then return end
                local weapon = (...)
                pcall(function()
                    if weapon and weapon.states then
                        wrapRecoilGet(weapon.states.recoil_up, "up")
                        wrapRecoilGet(weapon.states.recoil_side, "side")
                    end
                end)
                return old_recoil(...)
            end))
        end

        if typeof(shoot_func) == "function" then
            -- Same idea as recoil: scale spread via get() and run original shoot.
            local function wrapSpreadGet(state)
                if not state or state._strideSpreadWrap then return end
                local rawGet = state.get
                if typeof(rawGet) ~= "function" then return end
                state.get = function(self, ...)
                    local base = rawGet(self, ...)
                    if type(base) ~= "number" then return base end
                    local gm = getgenv()._VantaGunMods or settings
                    local mul = tonumber(gm.Spread) or settings.Spread or 1
                    if mul >= 0.999 then return base end
                    return base * mul
                end
                state._strideSpreadWrap = true
            end

            old_shoot = phookfunction(shoot_func, wrapClosure(function(...)
                if typeof(old_shoot) ~= "function" then return end
                local weapon = (...)
                pcall(function()
                    if weapon and weapon.states and weapon.states.spread then
                        wrapSpreadGet(weapon.states.spread)
                    end
                end)
                -- MUST return original result untouched (any wrap of ray_damage breaks guns)
                local a, b, c, d, e, f = old_shoot(...)
                pcall(function()
                    local fire = getgenv().MethaneFireTracerFromWeapon
                    if type(fire) == "function" then fire(weapon) end
                end)
                return a, b, c, d, e, f
            end))
        end

    end

    -- ---- Silent Aim: per-instance hook on active weapon objects ----
    -- gun_handler.get_shoot_look is an INSTANCE method, not a static module function.
    -- Hooking the module table does nothing — the game calls weaponObj:get_shoot_look().
    -- We watch gun_handler.active and hook each new weapon object the moment it becomes active.
    local _silentHookInstalled = false
    local _hookedWeapons = {}   -- [weaponObj] = original get_shoot_look
    local _silentRS = nil

    -- Shared target used by silent aim + snapline (same hitbox).
    local _activeSilentTarget = nil

    local function _validateSilentPart(part)
        if not part then return false end
        local ok = false
        pcall(function()
            if typeof(part) ~= "Instance" or not part:IsA("BasePart") or not part.Parent then return end
            if part.Transparency >= 0.99 then return end
            local plr = nil
            local mdl = part:FindFirstAncestorOfClass("Model")
            if mdl then plr = Players:GetPlayerFromCharacter(mdl) end
            if not plr then
                for p, vm in pairs(playerToViewmodel or {}) do
                    if vm and part:IsDescendantOf(vm) then plr = p break end
                end
            end
            if plr == LocalPlayer then return end
            if plr then
                local hp = 1
                local gh = getgenv().MethaneGetPlayerHp
                if type(gh) == "function" then
                    local h = gh(plr)
                    if type(h) == "number" then hp = h end
                else
                    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hp = hum.Health end
                end
                if type(hp) == "number" and hp <= 0 then return end
            end
            ok = true
        end)
        return ok
    end

    -- Target: resolve every shot (no target TTL — that broke rapid-fire).
    local function _getTargetNow()
        local t = GetTarget()
        if _validateSilentPart(t) then
            _activeSilentTarget = t
        else
            _activeSilentTarget = nil
        end
        getgenv()._MethaneSilentTarget = _activeSilentTarget
        getgenv()._MethaneGetSilentTarget = GetTarget
        return _activeSilentTarget
    end

    -- Hit chance: at 100% always hits. Below 100%, roll once per short window
    -- so a burst is consistent (legit-style) without starving individual bullets.
    local _lastChanceRoll     = true
    local _lastChanceRollTime = 0
    local _CHANCE_WINDOW      = 0.05

    local function _getChanceResult()
        local chance = math.clamp(math.floor(settings.SilentHitChance or 100), 0, 100)
        if chance >= 100 then
            return true
        end
        local now = os.clock()
        if (now - _lastChanceRollTime) >= _CHANCE_WINDOW then
            _lastChanceRoll     = math.random(1, 100) <= chance
            _lastChanceRollTime = now
        end
        return _lastChanceRoll
    end

    local _sharedShootLookHooked = false

    local function _silentLookAt(target)
        local cam = workspace.CurrentCamera
        if not cam or not target then return nil end
        local camPos = cam.CFrame.Position
        local pos = nil
        pcall(function() pos = target.Position end)
        if not pos then return nil end
        if (pos - camPos).Magnitude < 0.05 then return nil end
        local ok, result = pcall(function()
            return CFrame.lookAt(camPos, pos)
        end)
        return ok and result or nil
    end


    local function __initRagebot()
        -- ==================== RAGE (Manipulation master) ====================
        -- get_shoot_look redirect toward viewmodel parts (Astro/vaultcc + O1 Gun dump).
        -- Manipulation = master toggle for redirect + soft-wall virtual peek.
        -- AutoFire = input_shoot when killable. Without AutoFire, your shots still redirect.
        -- Force Hitbox = scan all bones, pick best penetrable/closest.
        -- Manip Distance = max lateral studs to sample for soft-wall path.
        -- Indicator = "True" / "False" text when a valid manip path exists this frame.

        -- Shared HP reader (available before HUD task) — used by rage dead-check + notifs
        local function rageGetHp(plr)
            local hp, maxHp = nil, nil
            if not plr then return 0, 100 end
            pcall(function()
                local a = plr:GetAttribute("Health") or plr:GetAttribute("HP") or plr:GetAttribute("health")
                local am = plr:GetAttribute("MaxHealth") or plr:GetAttribute("MaxHP")
                if type(a) == "number" then hp = a end
                if type(am) == "number" and am > 0 then maxHp = am end
            end)
            pcall(function()
                local char = plr.Character
                if not char then return end
                local a = char:GetAttribute("Health") or char:GetAttribute("HP") or char:GetAttribute("health")
                local am = char:GetAttribute("MaxHealth") or char:GetAttribute("MaxHP")
                if type(a) == "number" then hp = a end
                if type(am) == "number" and am > 0 then maxHp = am end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if hp == nil then hp = hum.Health end
                    if maxHp == nil then maxHp = hum.MaxHealth end
                    if hum.Health <= 0 then hp = 0 end
                    -- Only force 0 on true Dead state (Physics alone is normal movement in some O1 frames)
                    if hum:GetState() == Enum.HumanoidStateType.Dead then hp = 0 end
                end
            end)
            pcall(function()
                local cache = rawget(getgenv(), "_MethaneHpCache")
                if type(cache) == "table" and type(cache[plr]) == "number" then
                    if hp == nil or cache[plr] < (hp or 999) then hp = cache[plr] end
                end
            end)
            if maxHp == nil or maxHp <= 0 then maxHp = 100 end
            -- Do NOT invent full HP when unknown — return 0 only if proven dead, else -1 unknown
            if hp == nil then
                return -1, maxHp
            end
            return hp, maxHp
        end
        getgenv().MethaneGetPlayerHp = rageGetHp

        local RageState = {
            canManip = false,
            aimPart = nil,
            aimPos = nil,
            liveWeapon = nil,
            lastShot = 0,
            _hpCheckAt = 0,
            _hpCheckPlr = nil,
        }

        local RAGE_FOV = 1e9  -- 360 deg (no screen FOV gate)
        local RAGE_PARTS = { "head", "torso", "shoulder1", "shoulder2", "arm1", "arm2", "hip1", "hip2", "leg1", "leg2" }

        local function rageIsEnemy(plr)
            if not plr or plr == LocalPlayer then return false end
            -- HARD teamcheck: only shoot when we KNOW they are on the other team.
            -- Unknown team at round-start = do not shoot (stops team mag-dumps).
            local enemy = false
            pcall(function()
                local a = LocalPlayer:GetAttribute("Team")
                if a == nil then a = LocalPlayer:GetAttribute("TeamID") end
                if a == nil and LocalPlayer.Team then a = LocalPlayer.Team.Name end
                local b = plr:GetAttribute("Team")
                if b == nil then b = plr:GetAttribute("TeamID") end
                if b == nil and plr.Team then b = plr.Team.Name end
                if a ~= nil and b ~= nil then
                    enemy = (a ~= b)
                end
            end)
            return enemy
        end

        local _rageDeadUntil = {}
        local _rageLastHp = {} -- track HP drops for reliable corpse detect -- [Player] = os.clock expire
        getgenv()._MethaneRageDeadUntil = {}

        local function rageMarkDead(plr, sec)
            if not plr then return end
            local t = os.clock() + (tonumber(sec) or 5)
            _rageDeadUntil[plr] = t
            pcall(function()
                local bl = rawget(getgenv(), "_MethaneRageDeadUntil")
                if type(bl) ~= "table" then
                    bl = {}
                    getgenv()._MethaneRageDeadUntil = bl
                end
                bl[plr] = t
            end)
            if RageState and RageState.targetPlayer == plr then
                RageState.targetPlayer = nil
                RageState.canManip = false
                RageState.aimPart = nil
                RageState.aimPos = nil
                RageState.manipOrigin = nil
                RageState._afConfirmOk = false
            end
        end

        local function rageIsAlive(plr)
            if not plr or plr == LocalPlayer or not plr.Parent then return false end

            -- Sticky blacklist after confirmed death (O1 corpse/viewmodel lingers)
            local untilT = _rageDeadUntil[plr]
            pcall(function()
                local bl = rawget(getgenv(), "_MethaneRageDeadUntil")
                if type(bl) == "table" and type(bl[plr]) == "number" then
                    untilT = math.max(untilT or 0, bl[plr])
                    _rageDeadUntil[plr] = untilT
                end
            end)
            if untilT and os.clock() < untilT then return false end

            local hp = nil
            local hum = nil
            local char = nil

            pcall(function()
                char = plr.Character
            end)
            pcall(function()
                local h = rageGetHp(plr)
                if type(h) == "number" then hp = h end
            end)
            pcall(function()
                if char then
                    hum = char:FindFirstChildOfClass("Humanoid")
                end
            end)

            pcall(function()
                local a = plr:GetAttribute("Health") or plr:GetAttribute("HP")
                if type(a) == "number" then
                    if hp == nil or a < hp then hp = a end
                end
            end)
            pcall(function()
                if char then
                    local a = char:GetAttribute("Health") or char:GetAttribute("HP")
                    if type(a) == "number" then
                        if hp == nil or a < hp then hp = a end
                    end
                end
            end)
            pcall(function()
                if hum then
                    if hp == nil or hum.Health < (hp or 9999) then
                        hp = hum.Health
                    end
                    if hum.Health <= 0 then hp = 0 end
                    if hum:GetState() == Enum.HumanoidStateType.Dead then hp = 0 end
                end
            end)
            pcall(function()
                local cache = rawget(getgenv(), "_MethaneHpCache")
                if type(cache) == "table" and type(cache[plr]) == "number" then
                    if hp == nil or cache[plr] < hp then hp = cache[plr] end
                end
            end)
            pcall(function()
                local map = playerToViewmodel
                local vm = type(map) == "table" and map[plr] or nil
                if vm and vm.Parent then
                    local a = vm:GetAttribute("Health") or vm:GetAttribute("HP")
                    if type(a) == "number" then
                        if hp == nil or a < hp then hp = a end
                    end
                end
            end)

            local last = _rageLastHp[plr]
            if type(hp) == "number" and hp > 0 then
                _rageLastHp[plr] = hp
            end

            local dead = false
            if type(hp) == "number" and hp <= 0 then
                dead = true
            end
            if hum and hum.Health <= 0 then
                dead = true
            end
            if hum and hum:GetState() == Enum.HumanoidStateType.Dead then
                dead = true
            end
            if type(last) == "number" and last > 0 then
                if type(hp) == "number" and hp <= 0 then
                    dead = true
                end
                if (hp == nil or hp < 0) and hum and (hum.Health <= 0 or hum:GetState() == Enum.HumanoidStateType.Dead) then
                    dead = true
                end
            end

            pcall(function()
                local spec = plr:GetAttribute("Spectator") or plr:GetAttribute("Spectating") or plr:GetAttribute("IsSpectator")
                if spec == true or spec == 1 then dead = true end
            end)
            pcall(function()
                if char then
                    local aliveAttr = char:GetAttribute("Alive")
                    if aliveAttr == false then dead = true end
                end
            end)

            if dead then
                _rageLastHp[plr] = 0
                rageMarkDead(plr, 5)
                return false
            end
            return true
        end

        local function rageIsSpawnProtected(plr)
            if not plr then return false end
            local protected = false
            pcall(function()
                -- Primary: Character model attribute (confirmed in O1 dump)
                local char = plr.Character
                if char then
                    local v = char:GetAttribute("Protected")
                    if type(v) == "number" and v > 0 then protected = true; return end
                    if v == true then protected = true; return end
                end
                -- Fallback: viewmodel may carry the attribute in some O1 builds
                local map = playerToViewmodel
                if type(map) == "table" then
                    local vm = map[plr]
                    if vm then
                        local v = vm:GetAttribute("Protected")
                        if type(v) == "number" and v > 0 then protected = true; return end
                        if v == true then protected = true; return end
                    end
                end
                -- Last resort: direct player attribute (some servers sync it here)
                local v = plr:GetAttribute("Protected") or plr:GetAttribute("spawn_protected")
                if type(v) == "number" and v > 0 then protected = true end
                if v == true then protected = true end
            end)
            return protected
        end

        -- Soft = wallbangable (wood, thin, Soft attr). Hard = solid cover. Never shoot hard.
        -- 1:1 from O1 Util.base_penetrate (dump) + fence/grate soft-pass
        local _utilCanRay, _utilValidate = nil, nil
        pcall(function()
            local rs = (cloneref and cloneref(game:GetService("ReplicatedStorage"))) or game:GetService("ReplicatedStorage")
            local Util = require(rs.Modules.Util)
            if type(Util) == "table" then
                if type(Util.can_ray_penetrate) == "function" then _utilCanRay = Util.can_ray_penetrate end
                if type(Util.validate_position) == "function" then _utilValidate = Util.validate_position end
            end
        end)

        local function rageIsBodyOrVm(inst)
            if not inst then return false end
            local parent = inst.Parent
            if parent and parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return true end
            if parent and (parent.Name == "Viewmodel" or parent.Name == "LocalViewmodel") then return true end
            if inst:FindFirstAncestorOfClass("Accessory") then return true end
            return false
        end

        local function rageIsFenceLike(inst)
            local n = string.lower(tostring(inst.Name or ""))
            local pn = inst.Parent and string.lower(tostring(inst.Parent.Name or "")) or ""
            for _, k in ipairs({ "fence", "grate", "chain", "wire", "rail", "bars", "mesh", "lattice", "cage", "screen", "net" }) do
                if n:find(k, 1, true) or pn:find(k, 1, true) then return true end
            end
            -- thin sheet relative to other axes (classic fence panel)
            local dims = { inst.Size.X, inst.Size.Y, inst.Size.Z }
            table.sort(dims)
            if dims[1] <= 0.35 and dims[2] >= 1.2 then return true end
            return false
        end

        -- Returns true only when a bullet CAN pass through this surface.
        -- Fixed: wood/concrete/flat structural parts now hard-block (floors, roofs).
        -- Old code checked middle sorted dim >= 1.45; a 20x1x20 wooden floor has
        -- mid dim = 1.0 and incorrectly passed. Now material + geometry both checked.
        local HARD_MATERIALS = {
            [Enum.Material.Wood]          = true,
            [Enum.Material.WoodPlanks]    = true,
            [Enum.Material.Concrete]      = true,
            [Enum.Material.Brick]         = true,
            [Enum.Material.Cobblestone]   = true,
            [Enum.Material.Rock]          = true,
            [Enum.Material.Slate]         = true,
            [Enum.Material.SmoothPlastic] = true,
            [Enum.Material.Metal]         = true,
            [Enum.Material.DiamondPlate]  = true,
            [Enum.Material.CorrodedMetal] = true,
        }
        local function rageIsStructuralFlat(inst)
            -- Floor/roof/wall: one thin axis, at least one wide axis.
            -- Catches 20x1x20 wooden floors the old midDim>=1.45 check missed.
            local s = inst.Size
            local d = { s.X, s.Y, s.Z }
            table.sort(d)
            return d[1] <= 1.4 and d[3] >= 4.0
        end

        -- Hatch exception: small horizontal soft/thin parts (wood hatch) may pen;
        -- full floors/roofs (wide + mostly horizontal normal) always block.
        local function rageIsHatchLike(inst)
            if not inst then return false end
            local n = string.lower(tostring(inst.Name or ""))
            if n:find("hatch", 1, true) or n:find("trapdoor", 1, true)
                or n:find("trap_door", 1, true) or n:find("vent", 1, true)
                or n:find("grate", 1, true) then
                return true
            end
            local Parent = inst.Parent
            if inst:GetAttribute("Soft") or (Parent and Parent:GetAttribute("Soft")) then
                local s = inst.Size
                local horiz = math.max(s.X, s.Z)
                local thin = math.min(s.X, s.Y, s.Z)
                -- small footprint Soft panel ≈ hatch, not a full floor
                if horiz <= 8 and thin <= 0.6 then return true end
            end
            return false
        end

        local function rageIsFloorOrRoofHit(hit, from, to)
            local inst = hit and hit.Instance
            if not inst then return false end
            if rageIsBodyOrVm(inst) then return false end
            if rageIsHatchLike(inst) then return false end -- wood hatch / vent OK
            if not inst.CanCollide then return false end
            local normal = hit.Normal
            -- Must be a mostly horizontal surface (floor/ceiling), not a wall
            if not normal or math.abs(normal.Y) < 0.72 then
                return false
            end
            -- Only count if the hit sits between shooter and target height
            -- (stops false blocks when someone is simply above you in open air)
            if from and to and hit.Position then
                local minY = math.min(from.Y, to.Y) - 0.75
                local maxY = math.max(from.Y, to.Y) + 0.75
                if hit.Position.Y < minY or hit.Position.Y > maxY then
                    return false
                end
            end
            return true
        end

        local function rageBasePenetrate(hit)
            local Instance2 = hit.Instance
            if not Instance2 then return false end
            if rageIsBodyOrVm(Instance2) then return true end

            -- FLOOR / ROOF: never pen (except hatch — handled in rageIsFloorOrRoofHit)
            if rageIsFloorOrRoofHit(hit) then
                return false
            end

            local Parent = Instance2.Parent
            -- Soft attr penetrable (walls / thin props) — floors already rejected above
            if Instance2:GetAttribute("Soft") or (Parent and Parent:GetAttribute("Soft")) then
                return true
            end
            if rageIsFenceLike(Instance2) then return true end
            if Instance2.Transparency >= 0.35 then return true end
            if Instance2.Material == Enum.Material.Glass
                or Instance2.Material == Enum.Material.ForceField then
                return true
            end
            if not Instance2.CanCollide then return true end
            if Instance2:GetAttribute("Hard") or (Parent and Parent:GetAttribute("Hard")) then
                return false
            end
            if Instance2:HasTag("WallPart") or (Parent and Parent:HasTag("WallPart")) then
                return false
            end
            if HARD_MATERIALS[Instance2.Material] then
                if rageIsStructuralFlat(Instance2) then return false end
                local d2 = { Instance2.Size.X, Instance2.Size.Y, Instance2.Size.Z }
                table.sort(d2)
                if d2[2] >= 0.65 then return false end
            end
            local d3 = { Instance2.Size.X, Instance2.Size.Y, Instance2.Size.Z }
            table.sort(d3)
            if d3[2] >= 0.9 and Instance2.Transparency < 1 then return false end
            return true
        end

        local function ragePathHasFloorRoof(from, to, exclude)
            -- Walk ray; any floor/roof hit (non-hatch) blocks
            local dir = to - from
            local dist = dir.Magnitude
            if dist < 0.05 then return false end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = exclude or {}
            params.IgnoreWater = true
            local origin = from
            local remain = dir
            for _ = 1, 24 do
                local hit = workspace:Raycast(origin, remain, params)
                if not hit then return false end
                if (hit.Position - from).Magnitude >= dist - 0.08 then return false end
                if rageIsBodyOrVm(hit.Instance) then return false end
                if rageIsFloorOrRoofHit(hit, from, to) then
                    return true
                end
                pcall(function() params:AddToFilter(hit.Instance) end)
                local step = math.max((hit.Position - origin).Magnitude, 0.05) + 0.12
                if step >= remain.Magnitude then return false end
                origin = origin + remain.Unit * step
                remain = to - origin
            end
            return false
        end

        local function rageCanPenetrate(from, to, exclude)
            getgenv()._MethaneRageCanPenetrate = rageCanPenetrate
            -- HARD RULE: never treat path as clear if a floor/roof is in the way
            if ragePathHasFloorRoof(from, to, exclude) then
                return false
            end
            -- Prefer game Util for walls/soft when no floor/roof on path
            if _utilCanRay then
                local ok, result = pcall(_utilCanRay, from, to, exclude or {})
                if ok then
                    if result == 1 or result == true then return true end
                    if result == 0 or result == false or result == nil then return false end
                    return false
                end
            end
            local dir = to - from
            local dist = dir.Magnitude
            if dist < 0.05 then return true end
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = exclude or {}
            params.IgnoreWater = true
            local origin = from
            local remain = dir
            for _ = 1, 20 do
                local hit = workspace:Raycast(origin, remain, params)
                if not hit then return true end
                if (hit.Position - from).Magnitude >= dist - 0.08 then return true end
                if not rageBasePenetrate(hit) then return false end
                pcall(function() params:AddToFilter(hit.Instance) end)
                local step = math.max((hit.Position - origin).Magnitude, 0.05) + 0.1
                if step >= remain.Magnitude then return true end
                origin = origin + remain.Unit * step
                remain = to - origin
            end
            return false
        end

        local function rageExclude()
            local list = {}
            pcall(function()
                local ch = LocalPlayer.Character
                if ch then table.insert(list, ch) end
                local vms = workspace:FindFirstChild("Viewmodels")
                if vms then
                    local lv = vms:FindFirstChild("LocalViewmodel")
                    if lv then table.insert(list, lv) end
                end
            end)
            return list
        end

        local function ragePartFromVm(vm, prefer)
            if not vm then return nil end
            prefer = string.lower(tostring(prefer or "head"))
            if prefer == "head" then
                return vm:FindFirstChild("head") or vm:FindFirstChild("Head")
            end
            if prefer == "torso" then
                return vm:FindFirstChild("torso") or vm:FindFirstChild("Torso")
                    or vm:FindFirstChild("head") or vm:FindFirstChild("Head")
            end
            return vm:FindFirstChild("head") or vm:FindFirstChild("Head")
                or vm:FindFirstChild("torso") or vm:FindFirstChildWhichIsA("BasePart")
        end

        local function rageAllParts(vm)
            local out = {}
            for _, n in ipairs(RAGE_PARTS) do
                local part = vm:FindFirstChild(n)
                if part and part:IsA("BasePart") then table.insert(out, part) end
            end
            return out
        end

        local function rageResolveTarget()
            if not settings.RageManipulation then
                return nil, nil, false, nil, nil
            end
            local cam = workspace.CurrentCamera
            if not cam then return nil, nil, false, nil, nil end
            local camPos = cam.CFrame.Position
            pcall(function()
                local fn = getgenv().MethaneFpEyeCF
                if type(fn) == "function" then
                    local eyeCF = fn()
                    if typeof(eyeCF) == "CFrame" then
                        camPos = eyeCF.Position
                    end
                end
            end)
            local center = Vector2.new(cam.ViewportSize.X * 0.5, cam.ViewportSize.Y * 0.5)
            local exclude = rageExclude()
            local best, bestScore, bestPos, bestPlr, bestOrigin = nil, math.huge, nil, nil, nil

            -- O1 Util.validate_position HARD-CAPS origin shift to 3 studs (dump: ray min(3,mag)
            -- + Y clamp ±3). Slider can show 15 but the gun pipeline always clamps to 3.
            -- We sample peeks out to that real max so corners/doors work as well as O1 allows.
            local maxManip = 3 -- real O1 ceiling; settings.RageManipDistance is display-only beyond this

            local function rageValidateOrigin(desired)
                if _utilValidate then
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = exclude
                    params.IgnoreWater = true
                    local ok, res = pcall(_utilValidate, camPos, desired, params)
                    if ok and typeof(res) == "Vector3" then return res end
                end
                -- Match O1 Util.validate_position exactly
                local delta = desired - camPos
                local mag = delta.Magnitude
                if mag < 0.05 then return camPos end
                local y = desired.Y
                if camPos.Y - y > 3 then y = camPos.Y - 3
                elseif y - camPos.Y > 3 then y = camPos.Y + 3 end
                local a = Vector3.new(camPos.X, y, camPos.Z)
                local b = Vector3.new(desired.X, y, desired.Z)
                local look = CFrame.lookAt(a, b).LookVector
                local dist = (a - b).Magnitude
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                params.FilterDescendantsInstances = exclude
                params.IgnoreWater = true
                local hit = workspace:Raycast(a, look * math.min(3, dist), params)
                if hit then return hit.Position - look * 0.1 end
                if dist > 3 then return b - look * (dist - 3) end
                return b
            end

            local function consider(plr, part)
                if not part or not part.Parent or not part:IsA("BasePart") then return end
                if not plr or not rageIsEnemy(plr) then return end
                if not rageIsAlive(plr) then return end
                -- Spawn protection: skip players that are untargetable
                if rageIsSpawnProtected(plr) then return end
                local pos = part.Position
                local n = string.lower(part.Name)
                if n == "head" then
                    pos = pos + Vector3.new(0, part.Size.Y * 0.15, 0)
                end
                -- Floor/roof only rejected inside rageCanPenetrate / ragePathHasFloorRoof
                local worldDist = (pos - camPos).Magnitude
                if worldDist > 600 or worldDist < 0.5 then return end

                local headBonus = (n == "head" and -50) or (n == "torso" and -12) or 0

                -- 1) Cheap direct LOS: single raycast (not full multi-hit pen walk)
                local dir = pos - camPos
                local params = (rageGetRayParams and rageGetRayParams(exclude)) or (function()
                    local p = RaycastParams.new(); p.FilterType = Enum.RaycastFilterType.Exclude
                    p.FilterDescendantsInstances = exclude; p.IgnoreWater = true; return p end)()
                local hit = workspace:Raycast(camPos, dir, params)
                local directClear = false
                if not hit then
                    directClear = true
                elseif rageIsBodyOrVm(hit.Instance) then
                    directClear = true
                elseif hit.Normal and math.abs(hit.Normal.Y) >= 0.85 and hit.Instance.CanCollide then
                    -- only skip clear floor/roof slabs (was too aggressive in open areas)
                    local hitY = hit.Position.Y
                    local footY = camPos.Y - 4
                    local headY = camPos.Y + 3
                    if hitY < footY or hitY > headY then
                        return
                    end
                    -- mid-height flat (table/ledge): still try pen / origin scan below
                    directClear = false
                elseif rageBasePenetrate(hit) then
                    -- soft first hit: fall through to full canPenetrate only if needed
                    directClear = rageCanPenetrate(camPos, pos, exclude)
                else
                    -- hard first hit — try origin scan below
                    directClear = false
                end
                if directClear then
                    local score = worldDist + headBonus
                    if score < bestScore then
                        bestScore, best, bestPos, bestPlr, bestOrigin = score, part, pos, plr, camPos
                    end
                    return
                end

                -- 2) Blocked direct LOS — limited origin peeks (dense grid was FPS death in stacks)
                if maxManip < 0.25 then return end
                -- Skip expensive peeks if we already have a strong open lock
                if best and bestScore < 45 then return end

                local function tryOriginCandidate(tryOrig, distPenalty)
                    if (tryOrig - camPos).Magnitude < 0.12 then return end
                    if not rageCanPenetrate(tryOrig, pos, exclude) then return end
                    local score = worldDist + (tryOrig - camPos).Magnitude * distPenalty + headBonus
                    if score < bestScore then
                        bestScore, best, bestPos, bestPlr, bestOrigin = score, part, pos, plr, tryOrig
                    end
                end

                local toTarget = pos - camPos
                local fwdDir = toTarget.Unit
                for _, step in ipairs({ 1.5, 3.0 }) do
                    tryOriginCandidate(rageValidateOrigin(camPos + fwdDir * step), 0.15)
                end

                local right = cam.CFrame.RightVector
                local up = Vector3.yAxis
                -- 6 peeks max (was 16+) — enough for door jambs, cheap in stacks
                local lateral = {
                    right * 3, right * -3,
                    right * 2 + up * 0.8, right * -2 + up * 0.8,
                    up * 2.0, right * 2.5 + cam.CFrame.LookVector,
                }
                for _, off in ipairs(lateral) do
                    local mag = off.Magnitude
                    if mag > 0.05 then
                        tryOriginCandidate(
                            rageValidateOrigin(camPos + off.Unit * math.min(mag, maxManip)),
                            0.22
                        )
                    end
                end
            end

            local function partsForVm(vm)
                -- Always prefer single preferred part first (ForceHitbox still one head unless needed)
                local prefer = settings.RageTargetHitbox or "Head"
                local one = ragePartFromVm(vm, prefer) or ragePartFromVm(vm, "head")
                if one then return { one } end
                if settings.RageForceHitbox then
                    return rageAllParts(vm)
                end
                return {}
            end

            -- Build sorted-by-distance enemy list (cap work when stacked)
            local map = playerToViewmodel
            local candidates = {}
            if type(map) == "table" then
                for plr, vm in next, map do
                    if vm and vm.Parent and plr and plr ~= LocalPlayer and rageIsEnemy(plr) and rageIsAlive(plr) then
                        local anchor = vm:FindFirstChild("head") or vm:FindFirstChild("torso") or vm.PrimaryPart
                        if anchor and anchor:IsA("BasePart") then
                            local d = (anchor.Position - camPos).Magnitude
                            if d < 600 then
                                candidates[#candidates + 1] = { plr = plr, vm = vm, d = d }
                            end
                        end
                    end
                end
            end
            table.sort(candidates, function(a, b) return a.d < b.d end)

            -- Max 5 closest enemies per scan frame (stacks of 10+ were melting FPS)
            local limit = math.min(#candidates, 5)
            for i = 1, limit do
                local c = candidates[i]
                for _, part in ipairs(partsForVm(c.vm)) do
                    consider(c.plr, part)
                end
                -- Early out: solid open head lock — stop scanning the stack
                if best and bestScore < 40 and string.lower(tostring(best.Name)) == "head" then
                    break
                end
            end

            local can = best ~= nil and bestPos ~= nil
            return best, bestPos, can, bestPlr, bestOrigin
        end

        local function rageLookAt(pos)
            local cam = workspace.CurrentCamera
            if not cam or not pos then return nil end
            local origin = cam.CFrame.Position
            if (pos - origin).Magnitude < 0.05 then return nil end
            local ok, cf = pcall(CFrame.lookAt, origin, pos)
            return ok and cf or nil
        end

        local function rageFindWeapon()
            -- Cache live weapon ~4Hz — StateObject.get_all every frame was a major FPS hit
            local now = os.clock()
            if RageState.liveWeapon and type(RageState.liveWeapon) == "table" then
                local ok = false
                pcall(function() ok = typeof(RageState.liveWeapon.send_shoot) == "function" end)
                if ok and RageState._weaponCacheAt and (now - RageState._weaponCacheAt) < 0.25 then
                    return RageState.liveWeapon
                end
            end
            local found = nil
            pcall(function()
                local rs = game:GetService("ReplicatedStorage")
                local SO = require(rs.Modules.StateObject)
                for _, character in SO.get_all("Character") do
                    local owner = character.owner and character.owner:get()
                    if owner == LocalPlayer then
                        local eq = character.values and character.values.equipped
                        if type(eq) == "table" and typeof(eq.send_shoot) == "function" then
                            found = eq
                            return
                        end
                        pcall(function()
                            if eq and typeof(eq.get) == "function" then
                                local v = eq:get()
                                if type(v) == "table" and typeof(v.send_shoot) == "function" then
                                    found = v
                                end
                            end
                        end)
                    end
                end
            end)
            if found then
                RageState.liveWeapon = found
                RageState._weaponCacheAt = now
                return found
            end
            if RageState.liveWeapon and type(RageState.liveWeapon) == "table" then
                local w = RageState.liveWeapon
                local ok = false
                pcall(function() ok = typeof(w.send_shoot) == "function" end)
                if ok then return w end
            end
            return nil
        end

        local function rageIsLocalAlivePlaying()
            local ok = false
            pcall(function()
                local cam = workspace.CurrentCamera
                local char = LocalPlayer.Character
                if not cam or not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then return end
                local sub = cam.CameraSubject
                if sub and not sub:IsDescendantOf(char) and sub ~= hum then return end
                ok = true
            end)
            return ok
        end

        local function rageReleaseFire(weapon)
            if not _afHolding and not _afWeapon then return end
            _afHolding = false
            local w = weapon or _afWeapon
            _afWeapon = nil
            pcall(function()
                if w and typeof(w.input_shoot) == "function" then
                    w:input_shoot(false)
                end
            end)
            -- also release on current equipped in case weapon object changed
            pcall(function()
                local cur = rageFindWeapon()
                if cur and cur ~= w and typeof(cur.input_shoot) == "function" then
                    cur:input_shoot(false)
                end
            end)
        end

        local function rageTryReload(weapon)
            if not weapon then return end
            local mag = 1
            pcall(function()
                if weapon.states and weapon.states.mag then
                    mag = weapon.states.mag:get() or 0
                end
            end)
            if mag > 0 then return end
            pcall(function()
                if typeof(weapon.reload) == "function" then
                    weapon:reload(weapon.owner, true)
                end
            end)
        end

        local _reloadKickAt = 0
        local function rageTryAutoFire(weapon)
            if not settings.RageAutoFire or not settings.RageManipulation then
                rageReleaseFire(weapon)
                return
            end
            if not rageIsLocalAlivePlaying() then
                rageReleaseFire(weapon)
                return
            end
            -- Drop lock if left game or dead (HP <= 0)
            if RageState.targetPlayer and (
                not RageState.targetPlayer.Parent
                or not rageIsAlive(RageState.targetPlayer)
            ) then
                pcall(function()
                    if RageState.targetPlayer then rageMarkDead(RageState.targetPlayer, 5) end
                end)
                RageState.canManip = false
                RageState.targetPlayer = nil
                RageState.aimPart = nil
                RageState.aimPos = nil
                RageState._afConfirmOk = false
                rageReleaseFire(weapon)
                return
            end
            if not RageState.canManip or not RageState.aimPos or not RageState.aimPart then
                rageReleaseFire(weapon)
                return
            end
            -- Target part still exists
            local partOk = false
            pcall(function()
                if RageState.aimPart and RageState.aimPart.Parent then partOk = true end
            end)
            if not partOk then
                RageState.canManip = false
                RageState.targetPlayer = nil
                rageReleaseFire(weapon)
                return
            end
            -- Dead / despawned: stop immediately (don't keep dumping)
            local plr = RageState.targetPlayer
            if plr and not rageIsAlive(plr) then
                RageState.canManip = false
                RageState.aimPart = nil
                RageState.aimPos = nil
                RageState.targetPlayer = nil
                rageReleaseFire(weapon)
                return
            end

            if not getgenv()._MethaneLookRedirectInstalled then
                pcall(installLookRedirect)
            end
            weapon = rageFindWeapon()
            if not weapon or type(weapon) ~= "table" then
                rageReleaseFire(nil)
                return
            end

            if _afWeapon and _afWeapon ~= weapon then
                pcall(function()
                    if typeof(_afWeapon.input_shoot) == "function" then
                        _afWeapon:input_shoot(false)
                    end
                end)
                _afWeapon = nil
                _afHolding = false
            end

            -- Ammo / chamber / reload: NEVER hold fire while empty or reloading
            local mag, chambered, reloading = 0, true, false
            pcall(function()
                if weapon.states then
                    if weapon.states.mag then mag = weapon.states.mag:get() or 0 end
                    if weapon.states.chambered then
                        local c = weapon.states.chambered:get()
                        chambered = (c == true or c == 1)
                    end
                    if weapon.states.reload then
                        reloading = weapon.states.reload:get() == true
                    end
                end
                if weapon.reload_thread and weapon.reload_thread.running then reloading = true end
                if weapon.cock_thread and weapon.cock_thread.running then reloading = true end
            end)

            if reloading then
                rageReleaseFire(weapon)
                return
            end
            if mag <= 0 or not chambered then
                rageReleaseFire(weapon)
                -- kick reload once, don't spam
                if mag <= 0 and (os.clock() - _reloadKickAt) > 0.75 then
                    _reloadKickAt = os.clock()
                    pcall(function()
                        if typeof(weapon.reload) == "function" then
                            weapon:reload(weapon.owner, true)
                        end
                    end)
                end
                return
            end

            -- Extras: cheap, rate-limited (was every frame → FPS death)
            if _afWeapon ~= weapon or not _afHolding then
                pcall(function()
                    if type(rageLockWeaponStats) == "function" then rageLockWeaponStats(weapon) end
                    if type(rageHookRayDamage) == "function" then rageHookRayDamage(weapon) end
                end)
            end
            -- hitbox expand at most when lock target changes (handled in resolve switch)

            -- STRONG pre-fire: walk every surface to the aim point.
            -- Any non-pen hit (railing, hard prop, door) = do not shoot.
            -- Dead check again right here so we never dump a corpse.
            do
                local plr = RageState.targetPlayer
                if plr and not rageIsAlive(plr) then
                    RageState.canManip = false
                    RageState.aimPart = nil
                    RageState.aimPos = nil
                    RageState.targetPlayer = nil
                    RageState._afConfirmOk = false
                    rageReleaseFire(weapon)
                    return
                end
                local part = RageState.aimPart
                if not part or not part.Parent then
                    RageState._afConfirmOk = false
                    rageReleaseFire(weapon)
                    return
                end
            end

            RageState._afConfirmAt = RageState._afConfirmAt or 0
            RageState._afConfirmOk = RageState._afConfirmOk or false
            local now = os.clock()
            local fireConfirmed = false
            -- Short cache only if last confirm was true (0.03s); never cache a "blocked" as open
            if RageState._afConfirmOk and (now - RageState._afConfirmAt) < 0.2 then
                fireConfirmed = true
            else
                pcall(function()
                    local origin = RageState.manipOrigin
                    local cam = workspace.CurrentCamera
                    if not origin and cam then origin = cam.CFrame.Position end
                    local target = RageState.aimPos
                    -- Prefer live part position so aim isn't stale behind cover
                    local ap = RageState.aimPart
                    if ap and ap.Parent and ap:IsA("BasePart") then
                        target = ap.Position
                        if string.lower(ap.Name) == "head" then
                            target = target + Vector3.new(0, ap.Size.Y * 0.15, 0)
                        end
                        RageState.aimPos = target
                    end
                    if not origin or not target then return end
                    local dir = target - origin
                    local dist = dir.Magnitude
                    if dist < 0.3 then fireConfirmed = true; return end
                    if dist > 600 then return end

                    local exc = rageExclude()
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = exc
                    params.IgnoreWater = true

                    local cursor = origin
                    local remain = dir
                    local reached = false
                    for _ = 1, 8 do
                        local hit = workspace:Raycast(cursor, remain, params)
                        if not hit then
                            -- clear air the rest of the way → bullet reaches aim
                            reached = true
                            break
                        end
                        local traveled = (hit.Position - origin).Magnitude
                        -- Close enough to aim point = on/near target
                        if traveled >= dist - 0.35 then
                            reached = true
                            break
                        end
                        local inst = hit.Instance
                        if rageIsBodyOrVm(inst) then
                            reached = true
                            break
                        end
                        -- Floor/roof or non-pen (railing, hard metal, thick prop) → abort
                        if rageIsFloorOrRoofHit(hit, origin, target) then
                            reached = false
                            break
                        end
                        if not rageBasePenetrate(hit) then
                            -- HARD surface in the way — do not fire
                            reached = false
                            break
                        end
                        -- Soft/pen: skip through and keep walking
                        pcall(function() params:AddToFilter(inst) end)
                        local step = math.max((hit.Position - cursor).Magnitude, 0.05) + 0.08
                        if step >= remain.Magnitude then
                            reached = true
                            break
                        end
                        cursor = cursor + remain.Unit * step
                        remain = target - cursor
                    end
                    fireConfirmed = reached == true
                end)
                RageState._afConfirmOk = fireConfirmed
                RageState._afConfirmAt = now
            end

            if not fireConfirmed then
                rageReleaseFire(weapon)
                return
            end

            _afHolding = true
            _afWeapon = weapon
            pcall(function()
                if typeof(weapon.input_shoot) == "function" then
                    weapon:input_shoot(true)
                end
            end)
            -- Hit feedback for rage (does not depend on FPS shoot_func / camera hooks)
            pcall(function()
                if type(getgenv().MethaneOnRealShot) == "function" then
                    getgenv().MethaneOnRealShot()
                end
                local origin = RageState.manipOrigin
                local cam = workspace.CurrentCamera
                if not origin and cam then origin = cam.CFrame.Position end
                local target = RageState.aimPos
                if origin and target and type(getgenv().MethaneRegisterHitFeedback) == "function" then
                    getgenv().MethaneRegisterHitFeedback(RageState.targetPlayer, target, RageState.aimPart)
                end
            end)
        end

        local manipIndicatorLabel = nil
        local function rageEnsureIndicator()
            if manipIndicatorLabel and manipIndicatorLabel.Parent then return manipIndicatorLabel end
            pcall(function()
                local gui = Instance.new("ScreenGui")
                gui.Name = "MethaneManipIndicator"
                gui.ResetOnSpawn = false
                gui.IgnoreGuiInset = true
                pcall(function()
                    if gethui then gui.Parent = gethui() else gui.Parent = game:GetService("CoreGui") end
                end)
                if not gui.Parent then
                    gui.Parent = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
                end
                local lbl = Instance.new("TextLabel")
                lbl.Name = "ManipState"
                lbl.BackgroundTransparency = 1
                lbl.Size = UDim2.fromOffset(120, 24)
                lbl.Position = UDim2.new(0.5, -60, 0.12, 0)
                lbl.Font = Enum.Font.Code
                lbl.TextSize = 18
                lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                lbl.TextStrokeTransparency = 0.4
                lbl.Text = "False"
                lbl.Visible = false
                lbl.Parent = gui
                manipIndicatorLabel = lbl
            end)
            return manipIndicatorLabel
        end

        local function rageUpdateIndicator(can)
            -- Manipulation Indicator replaced by on-body Hit Logs (see Hit Logs toggle)
            if manipIndicatorLabel then
                pcall(function() manipIndicatorLabel.Visible = false end)
            end
        end

        local RunService = game:GetService("RunService")

        -- ===== Extra O1 methods (from Gun dump) =====
        -- 1) accuracy/spread lock (send_shoot uses accuracy.Value + states.spread)
        -- 2) ray_damage force-hit when client_sided_hitscan (send_shoot sends hit table to server)
        -- 3) light enemy viewmodel head expand (helps local ray_damage)
        local _spreadLocked = setmetatable({}, { __mode = "k" })
        local _rayHooked = setmetatable({}, { __mode = "k" })
        local _expandedParts = setmetatable({}, { __mode = "k" })

        local function rageLockWeaponStats(weapon)
            if not weapon then return end
            pcall(function()
                if weapon.accuracy then
                    weapon.accuracy.Value = 1
                end
                if weapon.states and weapon.states.spread and not _spreadLocked[weapon] then
                    local cur = weapon.states.spread:get()
                    _spreadLocked[weapon] = cur
                    pcall(function() weapon.states.spread:set(0) end)
                end
                -- Prefer client hitscan path when available so ray_damage results are used
                if weapon.client_sided_hitscan == false then
                    -- do not force permanently; only note — some guns are server hitscan by design
                end
            end)
        end

        local function rageHookRayDamage(weapon)
            if not weapon or type(weapon) ~= "table" then return end
            if _rayHooked[weapon] then return end
            local old = weapon.ray_damage
            if type(old) ~= "function" then return end
            _rayHooked[weapon] = old
            weapon.ray_damage = function(self, origin, direction, exclude, a, b)
                local results = old(self, origin, direction, exclude, a, b)
                local RS = rawget(getgenv(), "_MethaneRageState")
                if not (settings.RageManipulation and RS and RS.canManip and RS.aimPart and RS.aimPos) then
                    return results
                end
                -- If already hit our target humanoid/viewmodel, keep
                local hitTarget = false
                pcall(function()
                    if type(results) == "table" then
                        for _, pellet in ipairs(results) do
                            local list = pellet
                            if type(pellet) == "table" and pellet.Instance then
                                list = { pellet }
                            end
                            if type(list) == "table" then
                                for _, h in ipairs(list) do
                                    if h and h.HitHum then hitTarget = true; return end
                                    if h and h.Instance and RS.aimPart and (h.Instance == RS.aimPart or h.Instance:IsDescendantOf(RS.aimPart.Parent)) then
                                        hitTarget = true; return
                                    end
                                end
                            end
                        end
                    end
                end)
                if hitTarget then return results end
                -- Forge a head hit result for client_sided_hitscan path (server may re-validate)
                local forged = nil
                pcall(function()
                    local part = RS.aimPart
                    if not part or not part.Parent then return end
                    forged = {
                        {
                            Instance = part,
                            Position = RS.aimPos or part.Position,
                            Normal = Vector3.new(0, 1, 0),
                            Distance = (origin - (RS.aimPos or part.Position)).Magnitude,
                            Material = part.Material,
                            HitHum = true,
                        }
                    }
                end)
                if forged then
                    -- ray_damage returns list of pellet result lists
                    if type(results) == "table" and #results > 0 and type(results[1]) == "table" and results[1].Instance == nil then
                        results[1] = forged
                        return results
                    end
                    return { forged }
                end
                return results
            end
        end

        local function rageExpandTargetHitbox()
            local RS = RageState
            if not RS.canManip or not RS.aimPart then return end
            local part = RS.aimPart
            if _expandedParts[part] then return end
            pcall(function()
                if not part:IsA("BasePart") then return end
                _expandedParts[part] = part.Size
                -- modest expand — enough for local ray, not insane
                local s = part.Size
                part.Size = Vector3.new(
                    math.max(s.X, 1.2),
                    math.max(s.Y, 1.2),
                    math.max(s.Z, 1.2)
                )
            end)
        end

        local function rageRestoreHitboxes()
            for part, size in pairs(_expandedParts) do
                pcall(function()
                    if part and part.Parent then part.Size = size end
                end)
                _expandedParts[part] = nil
            end
            -- Reset the table itself so the weak-key GC doesn't leave stale entries
            -- that block expansion of the next target's parts
            _expandedParts = setmetatable({}, { __mode = "k" })
        end


        -- While locked: only re-check THIS player (no full lobby scan = FPS)
        local function rageValidateLocked()
            local plr = RageState.targetPlayer
            local part = RageState.aimPart
            if not plr or not plr.Parent or not rageIsAlive(plr) then
                return nil, nil, false, nil, nil
            end
            if not part or not part.Parent or not part:IsA("BasePart") then
                -- try re-resolve part on same player viewmodel
                local map = playerToViewmodel
                local vm = type(map) == "table" and map[plr] or nil
                if vm then
                    local prefer = settings.RageTargetHitbox or "Head"
                    part = ragePartFromVm(vm, prefer) or ragePartFromVm(vm, "head")
                end
                if not part or not part.Parent then
                    return nil, nil, false, nil, nil
                end
            end
            local cam = workspace.CurrentCamera
            if not cam then return nil, nil, false, nil, nil end
            local camPos = cam.CFrame.Position
            local pos = part.Position
            pcall(function()
                if string.lower(part.Name) == "head" then
                    pos = pos + Vector3.new(0, part.Size.Y * 0.15, 0)
                end
            end)
            local exclude = rageExclude()
            -- Cheap single ray + full pen only if first hit is soft
            local dir = pos - camPos
            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            params.FilterDescendantsInstances = exclude
            params.IgnoreWater = true
            local hit = workspace:Raycast(camPos, dir, params)
            local origin = camPos
            local ok = false
            if not hit then
                ok = true
            elseif rageIsBodyOrVm(hit.Instance) then
                ok = true
            elseif hit.Normal and math.abs(hit.Normal.Y) >= 0.72 and hit.Instance.CanCollide then
                ok = false
            elseif rageBasePenetrate(hit) then
                ok = rageCanPenetrate(camPos, pos, exclude)
            else
                -- hard wall: one origin peek attempt only (not full lobby grid)
                local maxManip = math.clamp(math.min(tonumber(settings.RageManipDistance) or 15, 3), 0, 3)
                if maxManip >= 0.25 then
                    local right = cam.CFrame.RightVector
                    local up = Vector3.yAxis
                    local peeks = {
                        right * 3, right * -3, right * 2, right * -2,
                        up * 2.2, up * -1.2,
                        right * 2.5 + up * 0.9, right * -2.5 + up * 0.9,
                        right * 2 + cam.CFrame.LookVector * 1.2,
                        right * -2 + cam.CFrame.LookVector * 1.2,
                    }
                    for _, off in ipairs(peeks) do
                        local tryO = camPos + off.Unit * math.min(off.Magnitude, maxManip)
                        tryO = -- stay within validate rules
                            (function()
                                local d = tryO - camPos
                                if d.Magnitude > 3 then tryO = camPos + d.Unit * 3 end
                                return tryO
                            end)()
                        if rageCanPenetrate(tryO, pos, exclude) then
                            origin = tryO
                            ok = true
                            break
                        end
                    end
                end
            end
            if not ok then
                return nil, nil, false, nil, nil
            end
            return part, pos, true, plr, origin
        end

        local _resolveAccum = 0
        local _resolveInterval = 0.12 -- ~8Hz full lobby scan when unlocked
        local _resolveIntervalLocked = 0.1 -- ~10Hz validate while locked
        local _rageRayParams = nil
        local function rageGetRayParams(exclude)
            if not _rageRayParams then
                _rageRayParams = RaycastParams.new()
                _rageRayParams.FilterType = Enum.RaycastFilterType.Exclude
                _rageRayParams.IgnoreWater = true
            end
            _rageRayParams.FilterDescendantsInstances = exclude or {}
            return _rageRayParams
        end
        RageState._rsConn = RunService.Heartbeat:Connect(function(dt)
            if not settings.RageManipulation then
                if RageState.canManip or RageState.targetPlayer or _afHolding then
                    RageState.canManip = false
                    RageState.aimPart = nil
                    RageState.aimPos = nil
                    RageState.targetPlayer = nil
                    RageState.manipOrigin = nil
                    pcall(rageRestoreHitboxes)
                    rageUpdateIndicator(false)
                    if _afHolding then
                        _afHolding = false
                        pcall(function()
                            local w = rageFindWeapon and rageFindWeapon()
                            if w and typeof(w.input_shoot) == "function" then
                                w:input_shoot(false)
                            end
                        end)
                    end
                end
                return
            end
            if not getgenv()._MethaneLookRedirectInstalled then
                -- rare reinstall only
                if not RageState._irAt or (os.clock() - RageState._irAt) > 2 then
                    RageState._irAt = os.clock()
                    pcall(installLookRedirect)
                end
            end

            -- EVERY frame: drop dead lock immediately (stops spray on corpses)
            if RageState.targetPlayer then
                if not rageIsAlive(RageState.targetPlayer) then
                    local deadPlr = RageState.targetPlayer
                    pcall(function() rageMarkDead(deadPlr, 5) end)
                    RageState.canManip = false
                    RageState.aimPart = nil
                    RageState.aimPos = nil
                    RageState.targetPlayer = nil
                    RageState.manipOrigin = nil
                    RageState._afConfirmOk = false
                    pcall(rageRestoreHitboxes)
                    pcall(rageReleaseFire)
                end
            end

            -- Throttle expensive hitbox/origin scan; keep last lock between scans
            -- IMPORTANT: do NOT full-scan every frame when unlocked (was melting FPS)
            _resolveAccum = _resolveAccum + (dt or 0.016)
            local interval = RageState.canManip and _resolveIntervalLocked or _resolveInterval
            local needScan = _resolveAccum >= interval
            if needScan then
                _resolveAccum = 0
                local part, pos, can, plr, origin
                if RageState.canManip and RageState.targetPlayer then
                    -- Only drop if player left or aim part fully destroyed
                    do
                        local plr = RageState.targetPlayer
                        local part = RageState.aimPart
                        if not plr or not plr.Parent then
                            RageState.targetPlayer = nil
                            RageState.canManip = false
                            RageState.aimPart = nil
                            RageState.aimPos = nil
                        elseif part and not part.Parent then
                            -- allow re-resolve same frame
                            RageState.aimPart = nil
                            RageState.canManip = false
                        end
                    end
                    if RageState.targetPlayer and not rageIsAlive(RageState.targetPlayer) then
                        RageState.targetPlayer = nil
                        RageState.canManip = false
                        RageState.aimPart = nil
                        RageState.aimPos = nil
                        part, pos, can, plr, origin = rageResolveTarget()
                    else
                        -- FOCUSED: only this target until dead / lost
                        part, pos, can, plr, origin = rageValidateLocked()
                        if not can then
                            RageState.targetPlayer = nil
                            RageState.canManip = false
                            RageState.aimPart = nil
                            RageState.aimPos = nil
                            -- Instant switch this frame
                            part, pos, can, plr, origin = rageResolveTarget()
                        end
                    end
                else
                    -- No lock: full lobby search
                    part, pos, can, plr, origin = rageResolveTarget()
                end
                if can and part and pos and plr and rageIsAlive(plr) then
                    -- Target switched: flush expanded hitboxes and stale ray hooks so the
                    -- old player's expanded parts don't persist and new target gets a clean hook.
                    if plr ~= RageState.targetPlayer then
                        pcall(rageRestoreHitboxes)
                        -- Unhook ray_damage from all previous weapon objects so the forged
                        -- result doesn't carry stale position data from the dead player's gun.
                        for w, old in pairs(_rayHooked) do
                            pcall(function()
                                if type(w) == "table" and type(old) == "function" then
                                    w.ray_damage = old
                                end
                            end)
                        end
                        _rayHooked = setmetatable({}, { __mode = "k" })
                    end
                    RageState.aimPart = part
                    -- Resolve aimPos directly from live part position — not stale pos from scan
                    -- This eliminates the one-tick lag on switch frame that sends bullets to old target
                    local freshPos = pos
                    pcall(function()
                        if part and part.Parent then
                            freshPos = part.Position
                            if string.lower(part.Name) == "head" then
                                freshPos = freshPos + Vector3.new(0, part.Size.Y * 0.15, 0)
                            end
                        end
                    end)
                    RageState.aimPos = freshPos
                    RageState.canManip = true
                    RageState.targetPlayer = plr
                    RageState.manipOrigin = origin
                    pcall(function() if type(rageExpandTargetHitbox) == "function" then rageExpandTargetHitbox() end end)
                else
                    -- No target: restore hitboxes and unhook ray hooks
                    if RageState.canManip then
                        pcall(rageRestoreHitboxes)
                        for w, old in pairs(_rayHooked) do
                            pcall(function()
                                if type(w) == "table" and type(old) == "function" then
                                    w.ray_damage = old
                                end
                            end)
                        end
                        _rayHooked = setmetatable({}, { __mode = "k" })
                    end
                    RageState.aimPart = nil
                    RageState.aimPos = nil
                    RageState.canManip = false
                    RageState.targetPlayer = nil
                    RageState.manipOrigin = nil
                end
                rageUpdateIndicator(RageState.canManip)
            elseif RageState.canManip and RageState.aimPart then
                -- refresh aim position from live part (smooth tracking, cheap)
                pcall(function()
                    if RageState.aimPart.Parent then
                        local p = RageState.aimPart.Position
                        local n = string.lower(RageState.aimPart.Name)
                        if n == "head" then
                            p = p + Vector3.new(0, RageState.aimPart.Size.Y * 0.15, 0)
                        end
                        RageState.aimPos = p
                    else
                        RageState.canManip = false
                    end
                end)
            end

            if settings.RageAutoFire then
                pcall(function() rageTryAutoFire() end)
            else
                pcall(function() rageReleaseFire() end)
            end
        end)

        getgenv()._MethaneRageState = RageState
        getgenv()._MethaneRageLookAt = rageLookAt

        -- Astro-style class method replace (phook alone often misses O1 instance __index path)
        local function installLookRedirect()
            getgenv()._MethaneInstallLookRedirect = installLookRedirect
            pcall(function()
                local rs = (cloneref and cloneref(game:GetService("ReplicatedStorage"))) or game:GetService("ReplicatedStorage")
                local gunMod = rs:FindFirstChild("Modules")
                gunMod = gunMod and gunMod:FindFirstChild("Items")
                gunMod = gunMod and gunMod:FindFirstChild("Item")
                gunMod = gunMod and gunMod:FindFirstChild("Gun")
                if not gunMod then return end
                local gh = require(gunMod)
                if type(gh) ~= "table" or type(gh.get_shoot_look) ~= "function" then return end

                -- Capture TRUE original exactly once. Never phook it (phook+call = stack overflow).
                local oldLook = getgenv()._MethaneOldShootLook
                if type(oldLook) ~= "function" then
                    oldLook = gh.get_shoot_look
                    -- If we somehow already wrapped, bail — do not recurse
                    if getgenv()._MethaneLookRedirectInstalled then return end
                    getgenv()._MethaneOldShootLook = oldLook
                end

                -- Already installed with same original — just ensure table points at wrapper
                if getgenv()._MethaneLookRedirectInstalled and getgenv()._MethaneRedirectedLook then
                    if gh.get_shoot_look ~= getgenv()._MethaneRedirectedLook then
                        gh.get_shoot_look = getgenv()._MethaneRedirectedLook
                    end
                    return
                end

                local function redirectedLook(self, ...)
                    if settings.RageManipulation then
                        local RS = rawget(getgenv(), "_MethaneRageState")
                        if RS and RS.canManip and RS.aimPos then
                            local origin = RS.manipOrigin
                            if not origin then
                                pcall(function()
                                    if self and self.shot and self.shot.CFrame then
                                        origin = self.shot.CFrame.Position
                                    end
                                end)
                            end
                            -- Prefer muzzle; never fall back to 3rd-person camera (breaks server ray)
                            if not origin then
                                pcall(function()
                                    local fn = getgenv().MethaneFpEyeCF
                                    if type(fn) == "function" then
                                        local eyeCF = fn()
                                        if typeof(eyeCF) == "CFrame" then origin = eyeCF.Position end
                                    end
                                end)
                            end
                            if not origin then
                                pcall(function()
                                    local ch = LocalPlayer.Character
                                    local h = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
                                    if h then origin = h.Position end
                                end)
                            end
                            if origin and (RS.aimPos - origin).Magnitude > 0.05 then
                                local ok, cf = pcall(CFrame.lookAt, origin, RS.aimPos)
                                if ok and cf then
                                    -- Return look only — mutating shot.CFrame desyncs hits vs server
                                    pcall(function()
                                        if self and self.accuracy and type(self.accuracy.Value) == "number" then
                                            self.accuracy.Value = 1
                                        end
                                    end)
                                    return cf
                                end
                            end
                        end
                    end
                    if settings.SilentEnabled then
                        local target = nil
                        pcall(function()
                            target = getgenv()._MethaneSilentTarget
                            if not (target and target.Parent) then
                                local gt = getgenv()._MethaneGetSilentTarget
                                if type(gt) == "function" then
                                    target = gt()
                                end
                            end
                            if not (target and target.Parent) and type(_getTargetNow) == "function" then
                                target = _getTargetNow()
                            end
                        end)
                        if target and typeof(target) == "Instance" and target:IsA("BasePart") and target.Parent then
                            local origin = nil
                            pcall(function()
                                if self and self.shot and self.shot.CFrame then
                                    origin = self.shot.CFrame.Position
                                end
                            end)
                            if not origin then
                                local cam = workspace.CurrentCamera
                                origin = cam and cam.CFrame.Position
                            end
                            if origin then
                                local ok, cf = pcall(CFrame.lookAt, origin, target.Position)
                                if ok and cf then return cf end
                            end
                        end
                    end
                    -- Call REAL original only — never the wrapper
                    if type(oldLook) == "function" then
                        local ok, res = pcall(oldLook, self, ...)
                        if ok then return res end
                    end
                    return CFrame.new()
                end

                getgenv()._MethaneRedirectedLook = redirectedLook
                gh.get_shoot_look = redirectedLook
                getgenv()._MethaneLookRedirectInstalled = true
                -- DO NOT phookfunction(oldLook) — that caused C stack overflow
            end)
        end
                installLookRedirect()
        task.spawn(function()
            for _ = 1, 30 do
                task.wait(0.5)
                if not getgenv()._MethaneLookRedirectInstalled then
                    installLookRedirect()
                else
                    break
                end
            end
        end)
    end
    __initRagebot()

    local function _hookWeaponInstance(weapon)
        -- Disabled: phookfunction on get_shoot_look caused C stack overflow with module redirect.
        -- Module-level gh.get_shoot_look assign in installLookRedirect is sufficient.
        return
    end

local function _hookSharedShootLook()
        -- Disabled: same stack-overflow risk as instance phook. Use installLookRedirect only.
        _sharedShootLookHooked = true
        return
    end

    local function _InstallSilentAimHook()
        resolveGunFuncs()
        if not gun_handler then
            task.delay(1, function()
                if (settings.SilentEnabled) and not _silentHookInstalled then
                    _InstallSilentAimHook()
                end
            end)
            return
        end
        if _silentHookInstalled then
            pcall(_hookSharedShootLook)
            return
        end
        _silentHookInstalled = true
        pcall(_hookSharedShootLook)
        -- FIX: gun_handler.active is nil — O1 Gun is a class metatable, not an instance registry.
        -- Hook via liveWeapon if already captured, otherwise Heartbeat will install on first frame.
        if _silentRS then pcall(function() _silentRS:Disconnect() end) end
        _silentRS = RunService.Heartbeat:Connect(function()
            if not settings.SilentEnabled then
                getgenv()._MethaneSilentTarget = nil
                return
            end
            pcall(_getTargetNow)
            -- Ensure module get_shoot_look redirect is live (shared with rage)
            pcall(function()
                local ir = rawget(getgenv(), "_MethaneInstallLookRedirect")
                if type(ir) == "function" then ir() end
            end)
        end)
    end



-- ==================== COMBAT · SILENT AIM / GUN MODS (real subtabs) ====================
    -- register free: was Tabs.Rage
    -- register free: was Tabs.GunMods

    -- ---- Silent Aim (Universal section format) ----
    pcall(function() Tabs.Rage:AddSection("Silent Aim", ico("crosshair")) end)
    Tabs.Rage:AddToggle('SilentEnabled', {
        Text = 'Enabled',
        Default = settings.SilentEnabled,
        Callback = function(v)
            settings.SilentEnabled = v
            if v then
                _InstallSilentAimHook()
                pcall(function()
                    local ir = rawget(getgenv(), "_MethaneInstallLookRedirect")
                    if type(ir) == "function" then ir() end
                end)
            end
        end
    }):AddKeyPicker('SilentKey', {
        Default = 'None',
        Text = 'Silent Key',
        Mode = 'Toggle',
    })

    Tabs.Rage:AddToggle('FovCircleEnabled', {
        Text = 'Show FOV',
        Default = settings.SilentFovCircle,
        Callback = function(v) settings.SilentFovCircle = v end
    })

    Tabs.Rage:AddDropdown('SilentChecks', {
        Text = 'Checks',
        Values = { 'Vis Check', 'Team Check' },
        Default = (function()
            local d = {}
            if settings.SilentVisCheck ~= false then table.insert(d, 'Vis Check') end
            if settings.SilentTeamCheck == true then table.insert(d, 'Team Check') end
            return d
        end)(),
        Multi = true,
        Callback = function(v)
            local set = {}
            if type(v) == "table" then
                for _, name in pairs(v) do
                    set[tostring(name)] = true
                end
            elseif type(v) == "string" and v ~= "" then
                set[v] = true
            end
            settings.SilentVisCheck = set['Vis Check'] == true
            settings.SilentTeamCheck = set['Team Check'] == true
        end
    })

    Tabs.Rage:AddDropdown('HitPartDropdown', {
        Text = 'Hit Part',
        Values = {'closest', 'head', 'torso'},
        Default = settings.HitPart or 'closest',
        Callback = function(v) settings.HitPart = v end
    })

    Tabs.Rage:AddSlider('HitChance', {
        Text = 'Hit Chance',
        Default = settings.SilentHitChance,
        Min = 1, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(v) settings.SilentHitChance = v end
    })

    Tabs.Rage:AddSlider('FovSize', {
        Text = 'FOV Size',
        Default = settings.SilentFov,
        Min = 5, Max = 1200, Rounding = 0, Suffix = 'px',
        Callback = function(v) settings.SilentFov = v end
    })

    Tabs.Rage:AddColorPicker('SilentFovColor', {
        Text = 'FOV Color',
        Default = settings.SilentFovCircleColor or Color3.new(1, 1, 1),
        Callback = function(v) settings.SilentFovCircleColor = v end
    })

    -- ---- Rage ----
    pcall(function() Tabs.Rage:AddSection("Rage", ico("skull")) end)

    Tabs.Rage:AddToggle('RageAutoFire', {
        Text = 'Auto Fire',
        Default = settings.RageAutoFire,
        Callback = function(v)
            settings.RageAutoFire = v
            if not v then
                pcall(function()
                    local RS = rawget(getgenv(), "_MethaneRageState")
                    -- release held fire
                    local w = nil
                    pcall(function()
                        if RS and RS.liveWeapon then w = RS.liveWeapon end
                    end)
                    if w and typeof(w.input_shoot) == "function" then
                        w:input_shoot(false)
                    end
                end)
            end
        end
    })

    Tabs.Rage:AddToggle('RageForceHitbox', {
        Text = 'Force Hitbox',
        Default = settings.RageForceHitbox,
        Callback = function(v) settings.RageForceHitbox = v end
    })

    Tabs.Rage:AddToggle('RageManipulation', {
        Text = 'Enable Ragebot',
        Default = settings.RageManipulation,
        Callback = function(v)
            settings.RageManipulation = v
            if v then
                pcall(_InstallSilentAimHook)
                pcall(function()
                    if type(getgenv()._MethaneInstallLookRedirect) == "function" then
                        getgenv()._MethaneInstallLookRedirect()
                    elseif getgenv()._MethaneRedirectedLook then
                        local rs = game:GetService("ReplicatedStorage")
                        local gh = require(rs.Modules.Items.Item.Gun)
                        if type(gh) == "table" then
                            gh.get_shoot_look = getgenv()._MethaneRedirectedLook
                        end
                    end
                    getgenv()._MethaneLookRedirectInstalled = true
                end)
            end
        end
    })

    -- Hit Logs toggle removed (logic remains internal / off by default)

    Tabs.Rage:AddDropdown('RageTargetHitbox', {
        Text = 'Hit Part',
        Values = { 'Head', 'Torso', 'Closest' },
        Default = settings.RageTargetHitbox or 'Head',
        Callback = function(v) settings.RageTargetHitbox = v end
    })

    Tabs.Rage:AddSlider('RageManipDistance', {
        Text = 'Manipulation Ticks',
        Default = 3,
        Min = 1, Max = 3, Rounding = 1,
        Tooltip = 'O1 hard-caps origin shift at 3 studs (validate_position). Higher does nothing.',
        Callback = function(v) settings.RageManipDistance = math.clamp(tonumber(v) or 3, 1, 3) end
    })


    -- ---- Speed Boost section ----
    pcall(function() Tabs.Rage:AddSection("Speed", ico("zap")) end)

    Tabs.Rage:AddToggle('SpeedBoostEnabled', {
        Text = 'Speed Spoof',
        Default = settings.SpeedBoostEnabled,
        Tooltip = 'Uses O1 speed_multiplier + soft XZ assist. Keep under ~2 to reduce rubberband.',
        Callback = function(v)
            settings.SpeedBoostEnabled = v
            if not v then
                -- Zero the LinearVelocity constraint immediately so no slide
                pcall(function()
                    if _speedBoostLV and _speedBoostLV.Parent then
                        _speedBoostLV.VectorVelocity = Vector3.zero
                    end
                end)
            end
        end
    })

    Tabs.Rage:AddSlider('SpeedBoostAmount', {
        Text = 'Spoofed Speed',
        Default = settings.SpeedBoostAmount or 0,
        Min = 0, Max = 5, Rounding = 2,
        Tooltip = 'Multiplier (1 = normal). Recommend 1.2–1.8. Stairs safe (Y not locked).',
        Callback = function(v)
            settings.SpeedBoostAmount = tonumber(v) or 0
        end
    })

    -- ---- Gun Mods subtab ----
    Tabs.GunMods:AddSlider('SpreadMultiplier', {
        Text = 'Spread',
        Default = math.floor((settings.Spread or 1) * 100),
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(v)
            v = tonumber(v) or 100
            settings.Spread = v / 100
            getgenv()._VantaGunMods = getgenv()._VantaGunMods or {}
            getgenv()._VantaGunMods.Spread = v / 100
            _InstallGunModsHooks()
        end
    })

    Tabs.GunMods:AddSlider('RecoilUp', {
        Text = 'Recoil Up',
        Default = math.floor((settings.RecoilUp or 1) * 100),
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(v)
            v = tonumber(v) or 100
            settings.RecoilUp = v / 100
            getgenv()._VantaGunMods = getgenv()._VantaGunMods or {}
            getgenv()._VantaGunMods.RecoilUp = v / 100
            _InstallGunModsHooks()
        end
    })

    Tabs.GunMods:AddSlider('RecoilSide', {
        Text = 'Recoil Side',
        Default = math.floor((settings.RecoilSide or 1) * 100),
        Min = 0, Max = 100, Rounding = 0, Suffix = '%',
        Callback = function(v)
            v = tonumber(v) or 100
            settings.RecoilSide = v / 100
            getgenv()._VantaGunMods = getgenv()._VantaGunMods or {}
            getgenv()._VantaGunMods.RecoilSide = v / 100
            _InstallGunModsHooks()
        end
    })

    task.defer(_InstallGunModsHooks)

    -- ==================== EXPLOITS (Rage tab, right side) ====================
    -- Rapid Fire + Force Auto: hook gun_handler.input_render (1:1 from beta).
    -- Fast Reload: StateObject.hook on weapon reload state (1:1 from beta).
    -- Both hooks are lazy — install on first enable only, gate on settings at runtime.

    -- Forward declarations — bodies defined after UI section below
    local _InstallRapidFireHook, _InstallFastReloadHooks

    -- Wire ExploitSettings keys directly into the existing `settings` table
    -- so the hooks below can read settings.RapidFire etc without a second table.
    settings.RapidFire          = false
    settings.RapidFireMultiplier = 3
    settings.ForceAuto          = false
    settings.FastLean           = false

    -- register free: was Tabs.Exploits
    pcall(function() Tabs.Exploits:AddSection("Gun Exploits", ico("zap")) end)

    -- ---- Rapid Fire ----
    Tabs.Exploits:AddToggle('RapidFireEnabled', {
        Text = 'Rapid Fire',
        Default = false,
        Tooltip = 'hes almost here...',
        Callback = function(v)
            settings.RapidFire = v
            if v then _InstallRapidFireHook() end
        end
    })
    Tabs.Exploits:AddSlider('RapidFireMultiplier', {
        Text = 'Fire Rate Multiplier',
        Default = 3,
        Min = 1, Max = 20, Rounding = 0, Suffix = 'x',
        Tooltip = 'hes getting closer...',
        Callback = function(v) settings.RapidFireMultiplier = v end
    })

    Tabs.Exploits:AddDivider()

    Tabs.Exploits:AddToggle('FastLeanEnabled', {
        Text = 'Fast Lean',
        Default = false,
        Tooltip = 'Hes hereee....',
        Callback = function(v)
            settings.FastLean = v
            if v then _InstallFastReloadHooks() end
        end
    })

    Tabs.Exploits:AddDivider()

    -- ---- Force Auto ----
    Tabs.Exploits:AddToggle('ForceAutoEnabled', {
        Text = 'Force Auto',
        Default = false,
        Tooltip = 'run.',
        Callback = function(v)
            settings.ForceAuto = v
            if v then _InstallRapidFireHook() end
        end
    })

    -- ==================== HIT SOUNDS / KILL SOUNDS / TRACERS / HITMARKS ====================
    Tabs.Exploits:AddDivider()
    pcall(function() Tabs.Exploits:AddSection("Hit Sounds") end)

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
            pcall(function() snd:Stop(); snd:Destroy() end)
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
    Tabs.Exploits:AddToggle('HitSoundEnabled', {
        Text = 'Enabled', Default = false,
        Callback = function(v) hitsound.enabled = v == true end,
    })
    Tabs.Exploits:AddDropdown('HitSoundType', {
        Text = 'Sound',
        Values = { "Skeet", "Rust", "Bell", "Cod", "Neverlose" },
        Default = "Skeet",
        Callback = function(v) hitsound.selected = tostring(v or "Skeet") end,
    })
    Tabs.Exploits:AddSlider('HitSoundVolume', {
        Text = 'Volume', Default = 1.2, Min = 0, Max = 3, Rounding = 2,
        Callback = function(v) hitsound.volume = tonumber(v) or 1.2 end,
    })
    Tabs.Exploits:AddButton({
        Text = 'Preview Sound',
        Func = function()
            PlayHitSound(HIT_SOUND_IDS[hitsound.selected] or HIT_SOUND_IDS.Skeet, true)
        end,
    })

    pcall(function() Tabs.Exploits:AddSection("Kill Sounds") end)
    local KILL_SOUND_IDS = {
        Skeet = "rbxassetid://4817809188",
        Rust = "rbxassetid://1255040462",
        Bell = "rbxassetid://6534947240",
        Cod = "rbxassetid://160432334",
        Neverlose = "rbxassetid://8726881116",
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
    Tabs.Exploits:AddToggle('KillSoundEnabled', {
        Text = 'Enabled', Default = false,
        Callback = function(v) killsound.enabled = v == true end,
    })
    Tabs.Exploits:AddDropdown('KillSoundType', {
        Text = 'Sound',
        Values = { "Skeet", "Rust", "Bell", "Cod", "Neverlose" },
        Default = "Neverlose",
        Callback = function(v) killsound.selected = tostring(v or "Neverlose") end,
    })
    Tabs.Exploits:AddSlider('KillSoundVolume', {
        Text = 'Volume', Default = 1.5, Min = 0, Max = 3, Rounding = 2,
        Callback = function(v) killsound.volume = tonumber(v) or 1.5 end,
    })
    Tabs.Exploits:AddButton({
        Text = 'Preview Kill Sound',
        Func = function()
            PlayKillSound(KILL_SOUND_IDS[killsound.selected] or KILL_SOUND_IDS.Neverlose, true)
        end,
    })

    pcall(function() Tabs.Exploits:AddSection("Bullet Tracers") end)
    local tracers = {
        enabled = false,
        style = "Regular",
        color = Color3.fromRGB(120, 200, 255),
        lifetime = 0.45,
        thickness = 0.10,
    }
    getgenv().MethaneTracers = tracers
    Tabs.Exploits:AddToggle('BulletTracers', {
        Text = 'Enabled', Default = false,
        Callback = function(v)
            tracers.enabled = v == true
            if v then pcall(function()
                if getgenv().MethaneEnsureTracerHooks then getgenv().MethaneEnsureTracerHooks() end
            end) end
        end,
    })
    Tabs.Exploits:AddDropdown('BulletTracerStyle', {
        Text = 'Style',
        Values = { "Regular", "Lightning", "Squiggly" },
        Default = "Regular",
        Callback = function(v) tracers.style = tostring(v or "Regular") end,
    })
    Tabs.Exploits:AddColorPicker('BulletTracerColor', {
        Text = 'Color', Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c) if typeof(c) == "Color3" then tracers.color = c end end,
    })
    Tabs.Exploits:AddSlider('BulletTracerLife', {
        Text = 'Lifetime', Default = 0.45, Min = 0.15, Max = 1.2, Rounding = 2, Suffix = 's',
        Callback = function(v) tracers.lifetime = tonumber(v) or 0.45 end,
    })
    Tabs.Exploits:AddSlider('BulletTracerThick', {
        Text = 'Thickness', Default = 0.10, Min = 0.03, Max = 0.30, Rounding = 2,
        Callback = function(v) tracers.thickness = tonumber(v) or 0.10 end,
    })

    pcall(function() Tabs.Exploits:AddSection("Hitmarkers") end)
    local hitmarks = {
        enabled = false,
        color1 = Color3.fromRGB(255, 255, 255),
        color2 = Color3.fromRGB(255, 105, 180),
        size = 42,
        lifetime = 0.45,
        rotate = true,
    }
    getgenv().MethaneHitmarks = hitmarks
    getgenv().MethaneHitLogsEnabled = settings.RageManipIndicator == true
    Tabs.Exploits:AddToggle('Hitmarks', {
        Text = 'Enabled', Default = false,
        Callback = function(v) hitmarks.enabled = v == true end,
    })
    Tabs.Exploits:AddColorPicker('HitmarkColor1', {
        Text = 'Color 1', Default = Color3.fromRGB(255, 255, 255),
        Callback = function(c) if typeof(c) == "Color3" then hitmarks.color1 = c end end,
    })
    Tabs.Exploits:AddColorPicker('HitmarkColor2', {
        Text = 'Color 2', Default = Color3.fromRGB(120, 170, 255),
        Callback = function(c) if typeof(c) == "Color3" then hitmarks.color2 = c end end,
    })
    Tabs.Exploits:AddSlider('HitmarkSize', {
        Text = 'Size', Default = 42, Min = 20, Max = 80, Rounding = 0, Suffix = 'px',
        Callback = function(v) hitmarks.size = tonumber(v) or 42 end,
    })
    Tabs.Exploits:AddSlider('HitmarkLife', {
        Text = 'Lifetime', Default = 0.45, Min = 0.15, Max = 1.2, Rounding = 2, Suffix = 's',
        Callback = function(v) hitmarks.lifetime = tonumber(v) or 0.45 end,
    })
    Tabs.Exploits:AddToggle('HitmarkRotate', {
        Text = 'Rotate', Default = false,
        Callback = function(v) hitmarks.rotate = v == true end,
    })

    -- Runtime: tracers + hitmarks + local-shot damage sounds
    do
        local Debris = game:GetService("Debris")
        local lastLocalShot = 0
        getgenv().MethaneIsLocalShot = function()
            return (tick() - lastLocalShot) < 0.28
        end
        local function noteLocalShot()
            lastLocalShot = tick()
        end

        -- ---- tracers (Bloxstrike-style neon segments, one path per real send_shoot) ----
        local activeTracers = {}
        local tracerFolder = nil
        local lastWeaponTracerAt = 0
        local lastTracerFire = 0

        local function ensureFolder()
            local cam = workspace.CurrentCamera
            if tracerFolder and tracerFolder.Parent then return tracerFolder end
            pcall(function()
                local old = workspace:FindFirstChild("MethaneTracers")
                if old then old:Destroy() end
                if cam then
                    local o2 = cam:FindFirstChild("MethaneTracers")
                    if o2 then o2:Destroy() end
                end
            end)
            tracerFolder = Instance.new("Folder")
            tracerFolder.Name = "MethaneTracers"
            -- parent to workspace so visible in O1 custom camera
            tracerFolder.Parent = workspace
            return tracerFolder
        end

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
            p.Transparency = math.clamp(alpha, 0.08, 1)
            local light = p:FindFirstChild("Glow")
            if light then
                local vis = 1 - math.clamp(alpha, 0, 1)
                light.Brightness = 1.1 * vis * vis
                light.Range = (5 + thick * 35) * vis
            end
        end

        local function edgeFactor(i, n)
            if n <= 1 then return 0.35 end
            local tt = (i - 0.5) / n
            return math.clamp(math.sin(tt * math.pi), 0, 1)
        end

        local function pathPoints(style, origin, hit, seed)
            local pts = {}
            local dir = hit - origin
            local len = dir.Magnitude
            if len < 0.5 then return { origin, hit }, nil, nil, dir.Unit end
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
                    local tt = i / n
                    local base = origin:Lerp(hit, tt)
                    local amp = (1 - tt * 0.55) * 0.85
                    table.insert(pts, base
                        + right * ((rng:NextNumber() - 0.5) * 2 * amp)
                        + up * ((rng:NextNumber() - 0.5) * 2 * amp))
                end
                table.insert(pts, hit)
            elseif style == "Squiggly" then
                table.insert(pts, origin)
                for i = 1, n - 1 do
                    local tt = i / n
                    local base = origin:Lerp(hit, tt)
                    table.insert(pts, base + right * (math.sin(tt * math.pi * 5) * 0.7 * (1 - tt * 0.2)))
                end
                table.insert(pts, hit)
            else
                pts = { origin, hit }
            end
            return pts, right, up, look
        end

        local function fireTracer(origin, hit, force)
            if not tracers.enabled then return end
            if typeof(origin) ~= "Vector3" or typeof(hit) ~= "Vector3" then return end
            if (hit - origin).Magnitude < 0.5 then return end
            local now = os.clock()
            -- force = multi-pellet same shot; otherwise block spam from double hooks
            if not force and (now - lastTracerFire) < 0.045 then return end
            lastTracerFire = now
            lastWeaponTracerAt = now

            local folder = ensureFolder()
            local col = tracers.color or Color3.fromRGB(120, 200, 255)
            local life = math.clamp(tracers.lifetime or 0.55, 0.12, 2)
            local thick = math.clamp(tracers.thickness or 0.12, 0.03, 0.4)
            local style = tostring(tracers.style or "Regular")
            local seed = math.floor(os.clock() * 10000) % 100000
            local basePts, right, up, look = pathPoints(style, origin, hit, seed)

            local segs = {}
            local segCount = math.max(1, #basePts - 1)
            if style == "Regular" then
                segCount = 12
            elseif style == "Squiggly" then
                segCount = math.max(segCount, 14)
            end
            for i = 1, segCount do
                table.insert(segs, makeSeg(folder, col, thick))
            end

            table.insert(activeTracers, {
                segs = segs, t0 = os.clock(), life = life,
                origin = origin, hit = hit, style = style,
                col = col, thick = thick, seed = seed,
                basePts = basePts, right = right, up = up, look = look,
            })
        end
        getgenv().MethaneFireTracer = fireTracer

        -- NO ray_damage hooks — wrapping it breaks O1 shooting. Tracers only via shoot_func after shot.
        getgenv().MethaneEnsureTracerHooks = function() end
        getgenv()._MethaneLastRayDamageTracer = 0

        -- O1 bullet dir from get_shoot_look + circular spread (does not touch ray_damage)
        local function _map(x, inMin, inMax, outMin, outMax)
            if inMax == inMin then return outMin end
            return outMin + (x - inMin) * (outMax - outMin) / (inMax - inMin)
        end
        local function _circularSpread(cf, radius)
            local a = math.random() * math.pi * 2
            local r = math.random() * (tonumber(radius) or 0)
            return cf.RightVector * math.cos(a) * r + cf.UpVector * math.sin(a) * r
        end

        local function fireTracerFromWeapon(weapon)
            -- Always resolve aim + local hit FX; tracers visual is optional
            local shootCf = nil
            pcall(function()
                if weapon and type(weapon.get_shoot_look) == "function" then
                    local cf = weapon:get_shoot_look()
                    if typeof(cf) == "CFrame" then shootCf = cf end
                end
            end)
            if not shootCf then
                local cam = workspace.CurrentCamera
                if not cam then return end
                shootCf = cam.CFrame
            end

            local origin = shootCf.Position
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                local best, score = nil, -1
                for _, d in ipairs(cam:GetDescendants()) do
                    local n = string.lower(d.Name)
                    if d:IsA("Attachment") and (n:find("muzzle") or n:find("barrel") or n == "tip" or n:find("flash")) then
                        local sc = n:find("muzzle") and 30 or 10
                        if sc > score then score = sc; best = d.WorldPosition end
                    end
                end
                if best then origin = best end
            end)

            local spreadBase = 0
            pcall(function()
                if weapon.states and weapon.states.spread and weapon.states.spread.get then
                    spreadBase = tonumber(weapon.states.spread:get()) or 0
                end
            end)
            local gm = getgenv()._VantaGunMods or {}
            local spreadRadius = spreadBase * 100 * (tonumber(gm.Spread) or 1)
            local accuracy = 1
            pcall(function()
                if weapon.accuracy then accuracy = tonumber(weapon.accuracy.Value) or 1 end
            end)
            local redDotMul = 1
            pcall(function()
                if weapon.red_dot and weapon.red_dot.Transparency == 1 then redDotMul = 0.5 end
            end)

            local aimCf = CFrame.new(origin) * (shootCf - shootCf.Position)
            local baseDir = aimCf.LookVector * 1000
            local spreadScale = (1 - accuracy * redDotMul)
            if spreadScale < 0 then spreadScale = 0 end
            local dir = baseDir + spreadScale * _circularSpread(aimCf, spreadRadius)
            if dir.Magnitude < 0.01 then dir = aimCf.LookVector * 1000 end

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local filter = {}
            pcall(function()
                if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
                local cam = workspace.CurrentCamera
                if cam then table.insert(filter, cam) end
                if tracerFolder then table.insert(filter, tracerFolder) end
                local vf = workspace:FindFirstChild("Viewmodels")
                if vf then table.insert(filter, vf) end
            end)
            params.FilterDescendantsInstances = filter
            local res = workspace:Raycast(origin, dir.Unit * 900, params)
            local hit = res and res.Position or (origin + dir.Unit * 450)
            if tracers.enabled then
                fireTracer(origin, hit, false)
            end
            noteLocalShot()
            -- hitmarks + local-only hitsounds always (not gated on tracers)
            pcall(function()
                local proc = getgenv().MethaneProcessLocalBullet
                if type(proc) == "function" then
                    proc(origin, dir)
                end
            end)
        end
        getgenv().MethaneFireTracerFromWeapon = fireTracerFromWeapon


        RunService.RenderStepped:Connect(function()
            if #activeTracers == 0 then return end
            local now = os.clock()
            local i = 1
            while i <= #activeTracers do
                local tr = activeTracers[i]
                local age = now - tr.t0
                if age >= tr.life then
                    for _, s in ipairs(tr.segs) do pcall(function() s:Destroy() end) end
                    table.remove(activeTracers, i)
                else
                    local u = age / tr.life
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
                            local alpha = baseAlpha + (1 - edge) * 0.4
                            if t1 > travel then
                                if t0 >= travel then
                                    seg.Transparency = 1
                                else
                                    local a = origin:Lerp(hit, t0)
                                    setSeg(seg, a, tip, thick, alpha)
                                end
                            else
                                local a = origin:Lerp(hit, t0)
                                local b = origin:Lerp(hit, t1)
                                setSeg(seg, a, b, thick, alpha)
                            end
                        end
                    else
                        local pts = tr.basePts
                        if style == "Squiggly" and tr.right then
                            pts = {}
                            local n = 14
                            for j = 0, n do
                                local tt = j / n
                                local base = origin:Lerp(hit, tt)
                                local wave = math.sin(tt * math.pi * 5 + age * 12) * 0.7 * (1 - tt * 0.2)
                                table.insert(pts, base + tr.right * wave)
                            end
                        end
                        local n = #tr.segs
                        local maxI = math.max(1, math.floor(travel * (#pts - 1)) + 1)
                        for si, seg in ipairs(tr.segs) do
                            local i0 = math.clamp(si, 1, #pts - 1)
                            local i1 = math.min(i0 + 1, #pts)
                            if i0 >= maxI then
                                seg.Transparency = 1
                            else
                                local edge = edgeFactor(si, n)
                                local alpha = baseAlpha + (1 - edge) * 0.35
                                setSeg(seg, pts[i0], pts[i1], thick, alpha)
                            end
                        end
                    end
                    i = i + 1
                end
            end
        end)

        -- Do NOT mark local shot on bare LMB — only real shoot_func (stops other players' damage triggering you)
        getgenv().MethaneOnRealShot = function()
            noteLocalShot()
        end

        -- ---- hitmarks (on YOUR bullet hit only) ----
        local hmFolder = nil
        local function ensureHmFolder()
            if hmFolder and hmFolder.Parent then return hmFolder end
            pcall(function()
                local old = workspace:FindFirstChild("MethaneHitmarks")
                if old then old:Destroy() end
            end)
            hmFolder = Instance.new("Folder")
            hmFolder.Name = "MethaneHitmarks"
            hmFolder.Parent = workspace
            return hmFolder
        end

        local function spawnHitLog(victim, hitPart, hitPos, dmg, partName, hpRemain)
            if not (getgenv().MethaneHitLogsEnabled or (settings and settings.RageManipIndicator)) then
                return
            end
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                -- Prefer world hit pos; fall back to aim part / viewport center
                local pos = hitPos
                if typeof(pos) ~= "Vector3" then
                    pcall(function()
                        if hitPart and hitPart:IsA("BasePart") then pos = hitPart.Position end
                    end)
                end
                if typeof(pos) ~= "Vector3" then
                    pos = cam.CFrame.Position + cam.CFrame.LookVector * 12
                end

                local sp = cam:WorldToViewportPoint(pos)
                -- same parent path as working screen hitmarks
                local parentGui = (gethui and gethui()) or game:GetService("CoreGui")
                local screen = parentGui:FindFirstChild("MethaneHitLogsGui")
                if not screen then
                    screen = Instance.new("ScreenGui")
                    screen.Name = "MethaneHitLogsGui"
                    screen.ResetOnSpawn = false
                    screen.IgnoreGuiInset = true
                    screen.DisplayOrder = 100
                    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
                    screen.Parent = parentGui
                end

                local name = (victim and victim.Name) or "Player"
                local dmgN = math.max(0, math.floor(tonumber(dmg) or 0))
                local dmgS = tostring(dmgN)
                local partS = tostring(partName or "Body")
                local hpS = (type(hpRemain) == "number") and tostring(math.floor(hpRemain + 0.5)) or "?"
                local green = "rgb(80,255,120)"
                local white = "rgb(255,255,255)"

                local frame = Instance.new("TextLabel")
                frame.Name = "HitLog"
                frame.BackgroundTransparency = 1
                frame.Size = UDim2.fromOffset(420, 28)
                frame.AnchorPoint = Vector2.new(0.5, 1)
                local vx = math.clamp(sp.X, 50, cam.ViewportSize.X - 50)
                local vy = math.clamp(sp.Y, 50, cam.ViewportSize.Y - 50)
                -- if behind camera, put near center-top like a feed entry
                if sp.Z < 0 then
                    vx = cam.ViewportSize.X * 0.5
                    vy = cam.ViewportSize.Y * 0.22
                end
                frame.Position = UDim2.fromOffset(vx, vy - 18)
                frame.Font = Enum.Font.GothamBold
                frame.TextSize = 18
                frame.TextColor3 = Color3.new(1, 1, 1)
                frame.TextStrokeTransparency = 0.35
                frame.TextStrokeColor3 = Color3.new(0, 0, 0)
                frame.TextXAlignment = Enum.TextXAlignment.Center
                frame.RichText = true
                frame.ZIndex = 50
                frame.Text = string.format(
                    '<font color="%s">Hit %s for </font><font color="%s">%s</font><font color="%s"> in the </font><font color="%s">%s</font><font color="%s"> (health remaining %s)</font>',
                    white, name, green, dmgS, white, green, partS, green, hpS
                )
                frame.Parent = screen

                task.spawn(function()
                    for i = 1, 22 do
                        task.wait(0.03)
                        if not frame.Parent then break end
                        frame.Position = frame.Position - UDim2.fromOffset(0, 1)
                        frame.TextTransparency = i / 26
                        frame.TextStrokeTransparency = 0.35 + i / 28
                    end
                    pcall(function() frame:Destroy() end)
                end)
                pcall(function() game:GetService("Debris"):AddItem(frame, 2.5) end)
            end)
        end
        getgenv().MethaneSpawnHitLog = spawnHitLog


local function spawnHitmark(worldPos, hitPart)
            if not hitmarks.enabled then return end
            if typeof(worldPos) ~= "Vector3" then return end
            pcall(function()
                local folder = ensureHmFolder()
                local life = math.clamp(hitmarks.lifetime or 0.45, 0.1, 2)
                local size = math.clamp(hitmarks.size or 42, 16, 120)
                local c1 = hitmarks.color1 or Color3.new(1, 1, 1)
                local c2 = hitmarks.color2 or Color3.fromRGB(255, 105, 180)

                -- Prefer welding to the actual hitbox so it sticks to the body
                local adornee = nil
                local offset = Vector3.zero
                if hitPart and typeof(hitPart) == "Instance" and hitPart:IsA("BasePart") then
                    adornee = hitPart
                    offset = hitPart.CFrame:PointToObjectSpace(worldPos)
                end

                local anchor = Instance.new("Part")
                anchor.Name = "HitmarkAnchor"
                anchor.Anchored = true
                anchor.CanCollide = false
                anchor.CanQuery = false
                anchor.CanTouch = false
                anchor.CastShadow = false
                anchor.Transparency = 1
                anchor.Size = Vector3.new(0.12, 0.12, 0.12)
                anchor.Position = worldPos
                anchor.Parent = folder

                local bb = Instance.new("BillboardGui")
                bb.Name = "Hitmark"
                bb.AlwaysOnTop = true
                bb.LightInfluence = 0
                bb.Size = UDim2.fromOffset(size, size)
                bb.StudsOffset = Vector3.zero
                if adornee then
                    bb.Adornee = adornee
                    bb.StudsOffsetWorldSpace = Vector3.zero
                    -- local offset on part
                    bb.StudsOffset = offset
                    bb.Parent = folder
                else
                    bb.Adornee = anchor
                    bb.Parent = anchor
                end

                local img = Instance.new("ImageLabel")
                img.BackgroundTransparency = 1
                img.Size = UDim2.fromScale(1, 1)
                img.Image = "rbxassetid://5544798810"
                img.ImageColor3 = c1
                img.ScaleType = Enum.ScaleType.Fit
                img.Parent = bb

                local t0 = os.clock()
                local rot = hitmarks.rotate ~= false
                local conn
                conn = RunService.RenderStepped:Connect(function()
                    local age = os.clock() - t0
                    if age >= life then
                        if conn then conn:Disconnect() end
                        pcall(function() anchor:Destroy() end)
                        pcall(function() if bb and bb.Parent then bb:Destroy() end end)
                        return
                    end
                    if adornee and (not adornee.Parent) then
                        -- part gone — freeze world position
                        if not anchor.Parent then return end
                    end
                    local a = age / life
                    img.ImageColor3 = c1:Lerp(c2, a)
                    img.ImageTransparency = a * a * 0.95
                    if rot then img.Rotation = age * 420 end
                    local s = size * (1 + a * 0.28)
                    bb.Size = UDim2.fromOffset(s, s)
                end)
                Debris:AddItem(anchor, life + 0.15)
                if bb.Parent == folder then
                    Debris:AddItem(bb, life + 0.15)
                end
            end)
        end
        getgenv().MethaneSpawnHitmark = spawnHitmark

        -- Resolve which player owns a hit instance (O1 viewmodels + normal characters)
        local function resolvePlayerFromPart(part)
            if not part or not part.Parent then return nil end
            local ok, plr = pcall(function()
                -- 1) ESP viewmodel map
                if type(playerToViewmodel) == "table" then
                    for p, vm in pairs(playerToViewmodel) do
                        if vm and (part:IsDescendantOf(vm) or part == vm) then
                            return p
                        end
                    end
                end
                -- 2) Workspace.Viewmodels (works even if ESP map empty)
                local folder = workspace:FindFirstChild("Viewmodels")
                if folder then
                    local localVm = folder:FindFirstChild("LocalViewmodel")
                    local cur = part
                    while cur and cur ~= workspace do
                        if cur.Parent == folder and cur ~= localVm then
                            if type(playerToViewmodel) == "table" then
                                for p, vm in pairs(playerToViewmodel) do
                                    if vm == cur then return p end
                                end
                            end
                            -- name match
                            for _, p in ipairs(Players:GetPlayers()) do
                                if p ~= LocalPlayer and (cur.Name == p.Name or cur.Name == tostring(p.UserId) or cur.Name == p.DisplayName) then
                                    return p
                                end
                            end
                            -- closest enemy to this viewmodel torso
                            local torso = cur:FindFirstChild("torso") or cur:FindFirstChild("head")
                            if torso and torso:IsA("BasePart") then
                                local best, bestD = nil, 8
                                for _, p in ipairs(Players:GetPlayers()) do
                                    if p ~= LocalPlayer and p.Character then
                                        local h = p.Character:FindFirstChild("HumanoidRootPart") or p.Character:FindFirstChild("Head")
                                        if h then
                                            local d = (h.Position - torso.Position).Magnitude
                                            if d < bestD then bestD = d; best = p end
                                        end
                                    end
                                end
                                if best then return best end
                            end
                        end
                        cur = cur.Parent
                    end
                end
                -- 3) ancestor Model → GetPlayerFromCharacter / name
                local cur = part
                while cur and cur ~= workspace do
                    if cur:IsA("Model") then
                        local fromChar = Players:GetPlayerFromCharacter(cur)
                        if fromChar and fromChar ~= LocalPlayer then return fromChar end
                        for _, p in ipairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer then
                                if cur.Name == p.Name or cur.Name == tostring(p.UserId) or cur.Name == p.DisplayName then
                                    return p
                                end
                            end
                        end
                    end
                    cur = cur.Parent
                end
                return nil
            end)
            return ok and plr or nil
        end

        -- Players WE actually hit recently (not the whole lobby)
        local myHits = {} -- [player] = expireClock
        local hpCache = {}
        local lastHitSoundAt = 0
        local lastKillSoundAt = 0

        local function markMyHit(plr)
            if not plr then return end
            myHits[plr] = os.clock() + 0.85
        end

        local function wasMyHit(plr)
            local exp = myHits[plr]
            return exp and os.clock() <= exp
        end

        -- Called from fireTracerFromWeapon with the real bullet origin/dir after spread
        local _lastProcBullet = 0
        local function processLocalBullet(origin, direction)
            if typeof(origin) ~= "Vector3" or typeof(direction) ~= "Vector3" then return end
            if direction.Magnitude < 0.01 then return end
            local nowp = os.clock()
            if (nowp - _lastProcBullet) < 0.02 then return end
            _lastProcBullet = nowp
            noteLocalShot()

            local params = RaycastParams.new()
            params.FilterType = Enum.RaycastFilterType.Exclude
            local filter = {}
            pcall(function()
                if LocalPlayer.Character then table.insert(filter, LocalPlayer.Character) end
                local cam = workspace.CurrentCamera
                if cam then table.insert(filter, cam) end
                if tracerFolder then table.insert(filter, tracerFolder) end
                local hm = workspace:FindFirstChild("MethaneHitmarks")
                if hm then table.insert(filter, hm) end
                local tf = workspace:FindFirstChild("MethaneTracers")
                if tf then table.insert(filter, tf) end
            end)
            params.FilterDescendantsInstances = filter
            params.IgnoreWater = true

            local castDir = direction.Unit * 900
            local res = workspace:Raycast(origin, castDir, params)
            if not res then
                return
            end

            local hitPart = res.Instance
            local hitPos = res.Position
            local victim = resolvePlayerFromPart(hitPart)

            -- only react to enemy player hitboxes
            if not victim or victim == LocalPlayer then
                return
            end

            markMyHit(victim)

            -- Damage / part for hit logs
            local partName = "Body"
            pcall(function()
                local n = string.lower(tostring(hitPart.Name or ""))
                if n:find("head") then partName = "Head"
                elseif n:find("torso") or n == "upper_torso" or n == "lower_torso" then partName = "Torso"
                elseif n:find("arm") or n:find("hand") or n:find("shoulder") then partName = "Arm"
                elseif n:find("leg") or n:find("foot") or n:find("hip") then partName = "Leg"
                else partName = hitPart.Name or "Body"
                end
            end)
            local hpBefore = hpCache[victim]
            local hpNow, hpMax = nil, 100
            pcall(function()
                local hum = victim.Character and victim.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hpNow = hum.Health
                    hpMax = hum.MaxHealth
                end
            end)
            -- O1 may not use Humanoid; try attributes
            pcall(function()
                if hpNow == nil then
                    hpNow = victim:GetAttribute("Health") or victim:GetAttribute("HP")
                end
            end)
            local dmg = 0
            if type(hpBefore) == "number" and type(hpNow) == "number" then
                dmg = math.max(0, math.floor(hpBefore - hpNow + 0.5))
            end
            if type(hpNow) == "number" then
                hpCache[victim] = hpNow
            end
            -- Mark dead / near-dead so rage stops spraying corpses
            pcall(function()
                local isDead = (type(hpNow) == "number" and hpNow <= 0)
                local nearDead = (type(hpNow) == "number" and hpNow <= 5)
                if isDead or nearDead then
                    local bl = rawget(getgenv(), "_MethaneRageDeadUntil")
                    if type(bl) ~= "table" then
                        bl = {}
                        getgenv()._MethaneRageDeadUntil = bl
                    end
                    bl[victim] = os.clock() + (isDead and 5.5 or 1.25)
                    if isDead then
                        pcall(function()
                            local RS = rawget(getgenv(), "_MethaneRageState")
                            if RS and RS.targetPlayer == victim then
                                RS.canManip = false
                                RS.targetPlayer = nil
                                RS.aimPart = nil
                                RS.aimPos = nil
                                RS.manipOrigin = nil
                                RS._afConfirmOk = false
                            end
                        end)
                    end
                    local RS = rawget(getgenv(), "_MethaneRageState")
                    if RS and RS.targetPlayer == victim then
                        RS.targetPlayer = nil
                        RS.canManip = false
                        RS.aimPart = nil
                        RS.aimPos = nil
                    end
                end
            end)

            -- On-body hit logs (optional legacy)
            pcall(function()
                if getgenv().MethaneHitLogsEnabled or settings.RageManipIndicator then
                    local spawnLog = getgenv().MethaneSpawnHitLog
                    if type(spawnLog) == "function" then
                        spawnLog(victim, hitPart, hitPos, dmg, partName, hpNow)
                    end
                end
            end)

            if hitmarks.enabled then
                spawnHitmark(hitPos, hitPart)
                -- FP-safe screen hitmark (world adornments often invisible in first person)
                pcall(function()
                    local cam = workspace.CurrentCamera
                    if not cam then return end
                    local sp = cam:WorldToViewportPoint(hitPos)
                    local parentGui = gethui and gethui() or game:GetService("CoreGui")
                    local sg = parentGui:FindFirstChild("MethaneHitmarkScreen")
                    if not sg then
                        sg = Instance.new("ScreenGui")
                        sg.Name = "MethaneHitmarkScreen"
                        sg.ResetOnSpawn = false
                        sg.IgnoreGuiInset = true
                        sg.DisplayOrder = 99
                        sg.Parent = parentGui
                    end
                    local size = math.clamp(hitmarks.size or 42, 16, 120)
                    local mark = Instance.new("Frame")
                    mark.BackgroundTransparency = 1
                    mark.Size = UDim2.fromOffset(size, size)
                    mark.AnchorPoint = Vector2.new(0.5, 0.5)
                    mark.Position = UDim2.fromOffset(sp.X, sp.Y)
                    mark.Parent = sg
                    -- cx/cy = pixel center of the mark frame (children positioned from top-left)
                    local cx, cy = size * 0.5, size * 0.5
                    local function arm(x1,y1,x2,y2,col)
                        local f = Instance.new("Frame")
                        f.BorderSizePixel = 0
                        f.BackgroundColor3 = col
                        f.Size = UDim2.fromOffset(math.max(2, math.abs(x2-x1)), math.max(2, math.abs(y2-y1)))
                        f.Position = UDim2.fromOffset(math.min(x1,x2) + cx, math.min(y1,y2) + cy)
                        f.Parent = mark
                    end
                    local c1 = hitmarks.color1 or Color3.new(1,1,1)
                    local s = size * 0.5   -- half-size so arms are correctly scaled around center
                    arm(-s*0.35,-s*0.35,-s*0.1,-s*0.1,c1)
                    arm(s*0.1,s*0.1,s*0.35,s*0.35,c1)
                    arm(-s*0.35,s*0.35,-s*0.1,s*0.1,c1)
                    arm(s*0.1,-s*0.1,s*0.35,-s*0.35,c1)
                    pcall(function() game:GetService("Debris"):AddItem(mark, hitmarks.lifetime or 0.45) end)
                end)
            end
            if hitsound.enabled then
                local now = os.clock()
                if (now - lastHitSoundAt) > 0.04 then
                    lastHitSoundAt = now
                    pcall(PlayHitSound)
                end
            end
        end

        -- Unified hit feedback (rage + legit). ESP-style: sound + screen mark on damage/hit.
        getgenv().MethaneRegisterHitFeedback = function(plr, hitPos, hitPart)
            pcall(function()
                if plr then markMyHit(plr) end
                noteLocalShot()
                if typeof(hitPos) == "Vector3" then
                    spawnHitmark(hitPos, hitPart)
                elseif hitPart and hitPart:IsA("BasePart") then
                    spawnHitmark(hitPart.Position, hitPart)
                end
                if hitsound.enabled then
                    local now = os.clock()
                    if (now - lastHitSoundAt) > 0.04 then
                        lastHitSoundAt = now
                        pcall(PlayHitSound)
                    end
                end
                if plr and type(getgenv().MethaneSpawnHitLog) == "function" then
                    pcall(getgenv().MethaneSpawnHitLog, plr, hitPart, hitPos, nil, hitPart and hitPart.Name, nil)
                end
            end)
        end

        getgenv().MethaneProcessLocalBullet = processLocalBullet

        -- ---- damage poll: hitsound/killsound when OUR shot caused HP drop ----
        local function readPlayerHp(plr)
            local hp = nil
            pcall(function()
                local char = plr.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then hp = hum.Health end
                    if type(hp) ~= "number" then
                        hp = char:GetAttribute("Health") or char:GetAttribute("HP") or char:GetAttribute("health")
                    end
                end
                if type(playerToViewmodel) == "table" then
                    local vm = playerToViewmodel[plr]
                    if vm then
                        local h = vm:FindFirstChildOfClass("Humanoid")
                        if h and (type(hp) ~= "number" or h.Health < hp) then hp = h.Health end
                        local a = vm:GetAttribute("Health") or vm:GetAttribute("HP")
                        if type(a) == "number" then hp = a end
                        for _, d in ipairs(vm:GetDescendants()) do
                            if d:IsA("Humanoid") then
                                if type(hp) ~= "number" or d.Health < hp then hp = d.Health end
                            end
                        end
                    end
                end
                -- workspace Viewmodels scan (ESP map may be empty)
                if type(hp) ~= "number" then
                    local folder = workspace:FindFirstChild("Viewmodels")
                    if folder then
                        for _, vm in ipairs(folder:GetChildren()) do
                            if vm.Name == "Viewmodel" then
                                local match = false
                                if type(playerToViewmodel) == "table" and playerToViewmodel[plr] == vm then match = true end
                                if not match and (vm.Name == plr.Name or vm:GetAttribute("UserId") == plr.UserId) then match = true end
                                if match then
                                    local h = vm:FindFirstChildOfClass("Humanoid")
                                    if h then hp = h.Health end
                                    local a = vm:GetAttribute("Health") or vm:GetAttribute("HP")
                                    if type(a) == "number" then hp = a end
                                end
                            end
                        end
                    end
                end
            end)
            return type(hp) == "number" and hp or nil
        end

        RunService.Heartbeat:Connect(function()
            if not killsound.enabled and not hitsound.enabled and not hitmarks.enabled then
                return
            end
            pcall(function()
                local localShot = (tick() - lastLocalShot) < 0.45
                local ragePlr = nil
                pcall(function()
                    local RS = rawget(getgenv(), "_MethaneRageState")
                    if RS and RS.canManip and RS.targetPlayer then ragePlr = RS.targetPlayer end
                end)
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr == LocalPlayer then continue end
                    local hp = readPlayerHp(plr)
                    if type(hp) ~= "number" then continue end
                    local prev = hpCache[plr]
                    hpCache[plr] = hp
                    if not prev then continue end

                    local ours = wasMyHit(plr) or (localShot and (plr == ragePlr or wasMyHit(plr)))
                    if not ours and localShot and plr == ragePlr then ours = true end
                    if not ours then continue end

                    if hp < prev - 0.2 then
                        -- confirmed damage from our shot window
                        pcall(function()
                            if hitmarks.enabled then
                                local pos = nil
                                local part = nil
                                if type(playerToViewmodel) == "table" and playerToViewmodel[plr] then
                                    local vm = playerToViewmodel[plr]
                                    part = vm:FindFirstChild("head") or vm:FindFirstChild("torso") or vm.PrimaryPart
                                    if part then pos = part.Position end
                                end
                                if pos then spawnHitmark(pos, part) end
                            end
                            if hitsound.enabled then
                                local now = os.clock()
                                if (now - lastHitSoundAt) > 0.035 then
                                    lastHitSoundAt = now
                                    pcall(PlayHitSound)
                                end
                            end
                            -- mark dead on confirmed lethal HP drop
                            if hp <= 0 and prev > 0 then
                                pcall(function()
                                    local bl = rawget(getgenv(), "_MethaneRageDeadUntil")
                                    if type(bl) ~= "table" then
                                        bl = {}
                                        getgenv()._MethaneRageDeadUntil = bl
                                    end
                                    bl[plr] = os.clock() + 3
                                    local RS = rawget(getgenv(), "_MethaneRageState")
                                    if RS and RS.targetPlayer == plr then
                                        RS.targetPlayer = nil
                                        RS.canManip = false
                                        RS.aimPart = nil
                                        RS.aimPos = nil
                                    end
                                end)
                            end
                        end)
                        if killsound.enabled and hp <= 0 and prev > 0 then
                            local now = os.clock()
                            if (now - lastKillSoundAt) > 0.1 then
                                lastKillSoundAt = now
                                pcall(PlayKillSound)
                            end
                        end
                    elseif prev > 0 and hp <= 0 then
                        if killsound.enabled then
                            local now = os.clock()
                            if (now - lastKillSoundAt) > 0.1 then
                                lastKillSoundAt = now
                                pcall(PlayKillSound)
                            end
                        end
                    end
                end
                -- cleanup expired hit marks
                local now = os.clock()
                for plr, exp in pairs(myHits) do
                    if now > exp then myHits[plr] = nil end
                end
            end)
        end)
        Players.PlayerRemoving:Connect(function(plr)
            hpCache[plr] = nil
            myHits[plr] = nil
        end)
    end

    -- ==================== RAPID FIRE + FORCE AUTO HOOK ====================
    -- 1:1 from beta. Hooks gun_handler.input_render once.
    -- self.automatic || settings.ForceAuto drives the auto loop.
    -- self.states.firerate:get() * RapidFireMultiplier drives the rate.

    local _rfHookInstalled = false
    local old_input_render = nil
    local _lastHookTry, _lastWeapHook = 0, 0

    _InstallRapidFireHook = function()
        if _rfHookInstalled then return end
        _rfHookInstalled = true
        resolveGunFuncs()
        if not gun_handler or typeof(gun_handler.input_render) ~= "function" then return end
        local input_render = gun_handler.input_render
        old_input_render = phookfunction(input_render, function(self, dt)
            old_input_render(self, dt)

            if self and type(self) == "table" then
                local RS = rawget(getgenv(), "_MethaneRageState")
                if RS then RS.liveWeapon = self end
                -- Throttle hook installs (was every input_render = FPS death)
                local nowH = os.clock()
                if (settings.SilentEnabled or settings.RageManipulation) then
                    if not _sharedShootLookHooked and (not _lastHookTry or nowH - _lastHookTry > 0.5) then
                        _lastHookTry = nowH
                        pcall(_hookSharedShootLook)
                        pcall(function()
                            local ir = rawget(getgenv(), "_MethaneInstallLookRedirect")
                            if type(ir) == "function" then ir() end
                        end)
                    end
                end
                if settings.RageManipulation and not _hookedWeapons[self] then
                    if not _lastWeapHook or nowH - _lastWeapHook > 0.25 then
                        _lastWeapHook = nowH
                        pcall(_hookWeaponInstance, self)
                    end
                end
            end

            if not (settings.RapidFire or settings.ForceAuto) then return end
            local player = self.owner
            if not player then return end
            local isAutomatic = self.automatic or settings.ForceAuto
            if isAutomatic and (self.shoot_hold or (self.burst_left and self.burst_left > 0))
                and (not self.safety:get() or self.accuracy.Value >= 1)
                and not (player.values.equip_debounce:get()
                    or (not settings.SprintOverride and player.states.running:get())) then
                local now = os.clock()
                local firerate = self.states.firerate:get()
                if settings.RapidFire and firerate > 0 then
                    firerate = firerate * settings.RapidFireMultiplier
                end
                if (firerate == 0 or now - self.last_shot > 1 / (firerate / 60))
                    and self.states.mag:get() > 0 and self.states.chambered:get() then
                    self.last_shot = now
                    pcall(function()
                        if self and typeof(self.send_shoot) == "function" then
                            self:send_shoot()
                        end
                    end)
                    pcall(function()
                        -- Always call so hitmarks + hitsounds fire regardless of tracers toggle
                        local f = getgenv().MethaneFireTracerFromWeapon
                        if type(f) == "function" then f(self) end
                    end)
                    if self.burst_left then self.burst_left = self.burst_left - 1 end
                end
            end
        end)
    end

    -- ==================== FAST RELOAD / ADS / LEAN HOOKS ====================
    -- Shared TweenInfo + task.wait hooks. Each toggle only speeds its own callers:
    --   Fast Reload → reload_*
    --   Fast ADS    → ads / aim / sight
    --   Fast Lean   → lean
    -- ~75% faster (duration * 0.25). Force-finish still only for reload.

    local _frHooksInstalled = false
    local _oldTweenInfoNew = nil
    local _oldTaskWait = nil
    local FR_MULT = 0.25

    -- Strict names only. Broad "lean" matching was speeding ALL gun/arm tweens.
    local RELOAD_EXACT = {
        reload_begin = true, reload_end = true, reload = true,
    }
    local LEAN_EXACT = {
        lean_begin = true, lean_end = true, lean_in = true, lean_out = true,
        lean_left = true, lean_right = true, lean_start = true, lean_stop = true,
        lean_return = true, lean_back = true, lean_center = true, lean_reset = true,
        lean_exit = true, lean_enter = true, unlean = true, lean_neutral = true,
        start_lean = true, stop_lean = true, begin_lean = true, end_lean = true,
        enter_lean = true, exit_lean = true, return_lean = true, lean_to_center = true,
        lean_recover = true, recover_lean = true,
    }
    local ADS_EXACT = {
        sights = true, update_sight_lens = true,
        ads_begin = true, ads_end = true, ads_in = true, ads_out = true,
        ads_start = true, ads_stop = true, enter_ads = true, exit_ads = true,
        start_ads = true, stop_ads = true, begin_ads = true, end_ads = true,
        toggle_ads = true, ads_toggle = true,
        aim_begin = true, aim_end = true, aim_in = true, aim_out = true,
        aim_start = true, aim_stop = true, start_aim = true, stop_aim = true,
        enter_aim = true, exit_aim = true, begin_aim = true, end_aim = true,
        aim_enter = true, aim_exit = true, toggle_aim = true,
    }


    local function _animKindFromStack()
        local gotReload, gotLean, gotAds = false, false, false
        local reloadName, leanName, adsName = nil, nil, nil

        for level = 2, 12 do
            local ok, name = pcall(function() return debug.info(level, "n") end)
            if ok and type(name) == "string" and name ~= "" then
                local lower = string.lower(name):gsub("^_", "")

                if RELOAD_EXACT[lower] or lower:match("^reload[_]?begin$") or lower:match("^reload[_]?end$") then
                    gotReload = true
                    reloadName = name
                elseif LEAN_EXACT[lower] or lower:match("^lean[_].+") then
                    -- lean_* prefix only (lean_return, lean_back, etc.) — not random *lean*
                    gotLean = true
                    leanName = name
                elseif ADS_EXACT[lower]
                    or lower == "sights"
                    or lower == "update_sight_lens"
                    or lower:match("^ads[_].+")
                    or lower:match("^aim[_].+")
                    or lower:match("^sight") then
                    gotAds = true
                    adsName = name
                end

            end
        end

        if gotReload then return "reload", reloadName end
        if gotLean then return "lean", leanName end
        if gotAds then return "ads", adsName end
        return nil, nil, nil
    end

    local function _kindEnabled(kind)
        if kind == "reload" then return false end -- removed
        if kind == "ads" then return false end -- removed
        if kind == "lean" then return settings.FastLean == true end
        return false
    end

    local function _trySetstackScaleFor(fnName)
        if typeof(getstack) ~= "function" or typeof(setstack) ~= "function" then
            return false
        end
        pcall(function()
            for level = 2, 12 do
                if debug.info(level, "n") == fnName then
                    for idx = 1, 16 do
                        local ok, val = pcall(getstack, level, idx)
                        if ok and typeof(val) == "number" and val >= 0.08 and val <= 12 then
                            pcall(setstack, level, idx, math.max(0.03, val * FR_MULT))
                        end
                    end
                    local t = getstack(level, 6)
                    if typeof(t) == "number" and t > 0 then
                        setstack(level, 6, math.max(0.03, t * FR_MULT))
                    end
                end
            end
        end)
        return true
    end

    local function _scaleAnimTween(...)
        local kind = _animKindFromStack()
        if kind and _kindEnabled(kind) then
            if kind == "reload" then
                _trySetstackScaleFor("reload_begin")
            elseif kind == "ads" then
                _trySetstackScaleFor("sights")
                _trySetstackScaleFor("update_sight_lens")
            end
            local args = { ... }
            if typeof(args[1]) == "number" and args[1] > 0 then
                args[1] = math.max(0.03, args[1] * FR_MULT)
                return _oldTweenInfoNew(table.unpack(args))
            end
        end
        return _oldTweenInfoNew(...)
    end

    local function _forceFinishReload(weaponObject)
        if not weaponObject or not weaponObject.states then return end
        pcall(function()
            local st = weaponObject.states
            -- Do NOT client-write mag/bullets (desync → 31/30, broken manual fire).
            -- FastReload only speeds animations via TweenInfo/task.wait hooks above.
            if st.chambered and not st.chambered:get() then
                if st.cock and st.cock.fire_instant then
                    st.cock:fire_instant()
                elseif st.chambered.set then
                    st.chambered:set(true)
                end
            end
            if st.reload then
                if st.reload.set then st.reload:set(false)
                elseif st.reload.fire then st.reload:fire(false) end
            end
            if weaponObject.reload_thread then
                pcall(function()
                    if weaponObject.reload_thread.cancel then
                        weaponObject.reload_thread:cancel()
                    end
                    weaponObject.reload_thread.running = false
                end)
            end
        end)
    end

    local function _applyFastReload(weaponObject)
        local reloadState = weaponObject.states and weaponObject.states.reload
        if not reloadState or not reloadState.hook then return end
        reloadState:hook(function(firing)
            if not firing then return end
            if not false then return end
            local owner = weaponObject.owner
            if not owner then return end
            local player = (type(owner) == "table" and owner.get) and owner:get() or owner
            if player ~= LocalPlayer then return end
            task.delay(0.15, function()
                if false then
                    _forceFinishReload(weaponObject)
                end
            end)
        end)
    end

    local function _hookGunTypeForFastReload(folder)
        if not folder then return end
        for _, child in pairs(folder:GetChildren()) do
            if child.Name ~= "Animations" and child.Name ~= "Sounds" then
                pcall(function()
                    local StateObject_fr = require(cloneref(game:GetService("ReplicatedStorage")).Modules.StateObject)
                    StateObject_fr.hook(child.Name, function(weaponObject)
                        _applyFastReload(weaponObject)
                    end)
                end)
            end
        end
    end

    _InstallFastReloadHooks = function()
        if _frHooksInstalled then return end
        _frHooksInstalled = true

        pcall(function()
            if typeof(hookfunction) == "function" then
                _oldTweenInfoNew = hookfunction(TweenInfo.new, function(...)
                    return _scaleAnimTween(...)
                end)
            elseif typeof(phookfunction) == "function" then
                _oldTweenInfoNew = phookfunction(TweenInfo.new, wrapClosure(function(...)
                    return _scaleAnimTween(...)
                end))
            end
        end)

        pcall(function()
            if typeof(hookfunction) == "function" and task and task.wait then
                _oldTaskWait = hookfunction(task.wait, function(t, ...)
                    if typeof(t) == "number" and t > 0.05 then
                        local kind = _animKindFromStack()
                        if kind and _kindEnabled(kind) then
                            local nt = math.max(0.03, t * FR_MULT)
                            return _oldTaskWait(nt, ...)
                        end
                    end
                    return _oldTaskWait(t, ...)
                end)
            end
        end)

        -- Fast ADS: Op1 often tweens Camera.FieldOfView / viewmodel CFrame without
        -- a function named aim/ads. Scale those TweenService:Create times only.
        pcall(function()
            local TS = game:GetService("TweenService")
            if typeof(hookfunction) ~= "function" then return end
            local oldCreate = nil
            oldCreate = hookfunction(TS.Create, function(self, instance, info, props)
                if false and typeof(props) == "table" and typeof(info) == "TweenInfo" then
                    local isAdsTween = false
                    if props.FieldOfView ~= nil then
                        isAdsTween = true
                    end
                    if props.CFrame ~= nil and typeof(instance) == "Instance" then
                        local n = string.lower(instance.Name or "")
                        local p = instance.Parent and string.lower(instance.Parent.Name or "") or ""
                        if n:find("viewmodel", 1, true) or p:find("viewmodel", 1, true)
                            or n:find("camera", 1, true) or n:find("aim", 1, true)
                            or n:find("ads", 1, true) or n == "offset" or n:find("offset", 1, true) then
                            isAdsTween = true
                        end
                    end
                    if isAdsTween and info.Time and info.Time > 0 then
                        local newInfo = TweenInfo.new(
                            math.max(0.03, info.Time * FR_MULT),
                            info.EasingStyle,
                            info.EasingDirection,
                            info.RepeatCount,
                            info.Reverses,
                            info.DelayTime
                        )
                        return oldCreate(self, instance, newInfo, props)
                    end
                end
                return oldCreate(self, instance, info, props)
            end)
        end)

        -- Weapon StateObject hooks only needed for Fast Reload force-finish
        pcall(function()
            local guns_fr = game.ReplicatedStorage.Modules.Items.Item.Gun
            if guns_fr:FindFirstChild("Automatic") then
                _hookGunTypeForFastReload(guns_fr.Automatic)
            end
            if guns_fr:FindFirstChild("Semi") then
                for _, subfolder in pairs(guns_fr.Semi:GetChildren()) do
                    if subfolder.Name ~= "Animations" and subfolder.Name ~= "Sounds" then
                        _hookGunTypeForFastReload(subfolder)
                    end
                end
            end
            for _, child in pairs(guns_fr:GetChildren()) do
                if child:IsA("Folder") and child.Name ~= "Automatic" and child.Name ~= "Semi"
                    and child.Name ~= "Animations" and child.Name ~= "Sounds" then
                    _hookGunTypeForFastReload(child)
                end
            end
        end)
    end

    -- ==================== LEGIT TAB ====================

    local _LegitUIS     = cloneref(game:GetService("UserInputService"))
    local _LegitPlayers = cloneref(game:GetService("Players"))
    local _LegitRS      = cloneref(game:GetService("RunService"))
    local _LegitLP      = _LegitPlayers.LocalPlayer

    local LegitSettings = {
        LegitEnabled     = false,
        LegitMode        = "Hold",
        LegitKey         = "E",
        LegitSmoothing   = 12,
        LegitFov         = 120,
        LegitFovVisible  = true,
        LegitFovColor    = Color3.new(1, 1, 1),
        LegitTeamCheck   = true,
        LegitHitPart     = "head",
        TriggerEnabled   = false,
        TriggerMode      = "Hold",
        TriggerKey       = "T",
        TriggerDelay     = 80,
        TriggerFov       = 25,
        TriggerTeamCheck = true,
    }

    local function _resolveKey(raw)
        if raw == nil then return nil end
        if typeof(raw) == "EnumItem" then return raw end
        if type(raw) == "string" then
            local stripped = raw:match("Enum%.KeyCode%.(.+)") or raw:match("Enum%.UserInputType%.(.+)") or raw
            local ok, result = pcall(function() return Enum.KeyCode[stripped] end)
            if ok and result and typeof(result) == "EnumItem" then return result end
            local ok2, result2 = pcall(function() return Enum.UserInputType[stripped] end)
            if ok2 and result2 and typeof(result2) == "EnumItem" then return result2 end
        end
        return nil
    end

    local function _isKeyDown(rawKey, optionKey)
        -- If an Options KeyPicker exists for this binding, use GetState() directly.
        -- This is what allows Linora (and config saves) to properly override the key.
        if optionKey and Options[optionKey] and type(Options[optionKey].GetState) == "function" then
            local ok, state = pcall(function() return Options[optionKey]:GetState() end)
            if ok then return state end
        end
        local key = _resolveKey(rawKey)
        if not key then return false end
        if typeof(key) == "EnumItem" and key.EnumType == Enum.UserInputType then
            local ok, down = pcall(function() return _LegitUIS:IsMouseButtonPressed(key) end)
            return ok and down
        end
        local ok, down = pcall(function() return _LegitUIS:IsKeyDown(key) end)
        return ok and down
    end

    local function _legitIsEnemy(playerInstance, teamCheckFlag)
        if not teamCheckFlag then return true end
        local ok = true
        pcall(function()
            local myTeam = _LegitLP:GetAttribute("Team")
            if not myTeam then return end
            local theirTeam = playerInstance:GetAttribute("Team")
            if theirTeam ~= nil and myTeam == theirTeam then ok = false end
        end)
        return ok
    end

    local _LEGIT_ALL_PARTS = {"head","torso","shoulder1","shoulder2","arm1","arm2","hip1","hip2","leg1","leg2"}

    local function _getLegitTarget()
        local cam = workspace.CurrentCamera
        if not cam then return nil end
        local vp = cam.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        local fov = LegitSettings.LegitFov
        local hitPart = LegitSettings.LegitHitPart
        local bestDist = math.huge
        local bestPart = nil

        for player, vm in next, playerToViewmodel or {} do
            if not player or player == _LegitLP then continue end
            if not vm or not vm.Parent then continue end
            local resolved = _LegitPlayers:FindFirstChild(player.Name)
            if not resolved then continue end
            if not _legitIsEnemy(resolved, LegitSettings.LegitTeamCheck) then continue end

            local partsToScan
            if hitPart == "head" or hitPart == "torso" then
                local p = vm:FindFirstChild(hitPart)
                if not p then continue end
                partsToScan = {p}
            else
                partsToScan = {}
                for _, name in ipairs(_LEGIT_ALL_PARTS) do
                    local p = vm:FindFirstChild(name)
                    if p then partsToScan[#partsToScan + 1] = p end
                end
            end

            for _, part in ipairs(partsToScan) do
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if not onScreen then continue end
                local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                if dist > fov then continue end
                if dist < bestDist then
                    bestDist = dist
                    bestPart = part
                end
            end
        end

        return bestPart
    end

    -- ==================== LEGIT · AIM ASSIST / TRIGGERBOT (Universal section format) ====================
    -- register free: was Tabs.Legit
    -- register free: was Tabs.Legit

    -- Aim Assist section
    pcall(function() Tabs.Legit:AddSection("Aim Assist", ico("crosshair")) end)
    Tabs.Legit:AddToggle("LegitEnabled", {
        Text = "Enabled",
        Default = LegitSettings.LegitEnabled,
        Callback = function(v) LegitSettings.LegitEnabled = v end,
    }):AddKeyPicker("LegitKey", {
        Default = "None",
        Text = "Aim Key",
        Mode = "Hold",
        Callback = function(v)
            if typeof(v) == "EnumItem" then LegitSettings.LegitKey = v.Name
            elseif type(v) == "string" then LegitSettings.LegitKey = v end
        end,
    })

    Tabs.Legit:AddDropdown("LegitMode", {
        Text = "Mode",
        Values = {"Hold", "Always"},
        Default = LegitSettings.LegitMode,
        Callback = function(v) LegitSettings.LegitMode = v end,
    })
    Tabs.Legit:AddSlider("LegitSmoothing", {
        Text = "Smoothing",
        Default = LegitSettings.LegitSmoothing,
        Min = 1, Max = 50, Rounding = 0,
        Callback = function(v) LegitSettings.LegitSmoothing = v end,
    })
    Tabs.Legit:AddDropdown("LegitHitPart", {
        Text = "Hit part",
        Values = {"head", "torso", "closest"},
        Default = LegitSettings.LegitHitPart,
        Callback = function(v) LegitSettings.LegitHitPart = v end,
    })
    Tabs.Legit:AddToggle("LegitFovVisible", {
        Text = "Show FOV",
        Default = LegitSettings.LegitFovVisible,
        Callback = function(v) LegitSettings.LegitFovVisible = v end,
    }):AddColorPicker("LegitFovColor", {
        Default = LegitSettings.LegitFovColor,
        Callback = function(v) LegitSettings.LegitFovColor = v end,
    })
    Tabs.Legit:AddSlider("LegitFov", {
        Text = "FOV Size",
        Default = LegitSettings.LegitFov,
        Min = 10, Max = 400, Rounding = 0, Suffix = "px",
        Callback = function(v) LegitSettings.LegitFov = v end,
    })
    Tabs.Legit:AddToggle("LegitTeamCheck", {
        Text = "Team Check",
        Default = LegitSettings.LegitTeamCheck,
        Callback = function(v) LegitSettings.LegitTeamCheck = v end,
    })

    pcall(function() Tabs.Legit:AddDivider() end)
    pcall(function() Tabs.Legit:AddSection("Triggerbot", ico("flame")) end)
    Tabs.Legit:AddToggle("TriggerEnabled", {
        Text = "Enabled",
        Default = LegitSettings.TriggerEnabled,
        Callback = function(v) LegitSettings.TriggerEnabled = v end,
    }):AddKeyPicker("TriggerKey", {
        Default = "None",
        Text = "Trigger Key",
        Mode = "Hold",
        Callback = function(v)
            if typeof(v) == "EnumItem" then LegitSettings.TriggerKey = v.Name
            elseif type(v) == "string" then LegitSettings.TriggerKey = v end
        end,
    })
    Tabs.Legit:AddDropdown("TriggerMode", {
        Text = "Mode",
        Values = {"Hold", "Always"},
        Default = LegitSettings.TriggerMode,
        Callback = function(v) LegitSettings.TriggerMode = v end,
    })

    Tabs.Legit:AddSlider('TriggerFov', {
        Text = 'FOV Size',
        Default = LegitSettings.TriggerFov,
        Min = 5, Max = 100, Rounding = 0, Suffix = 'px',
        Callback = function(v) LegitSettings.TriggerFov = v end
    })

    Tabs.Legit:AddSlider('TriggerDelay', {
        Text = 'Delay',
        Default = LegitSettings.TriggerDelay,
        Min = 0, Max = 300, Rounding = 0, Suffix = 'ms',
        Callback = function(v) LegitSettings.TriggerDelay = v end
    })

    Tabs.Legit:AddToggle('TriggerTeamCheck', {
        Text = 'Team Check',
        Default = LegitSettings.TriggerTeamCheck,
        Callback = function(v) LegitSettings.TriggerTeamCheck = v end
    })

    -- Legit FOV circle
    local LegitFovCircle     = Drawing.new('Circle')
    LegitFovCircle.Visible   = false
    LegitFovCircle.Thickness = 1
    LegitFovCircle.NumSides  = 64
    LegitFovCircle.Filled    = false

    -- Legit aim loop
    local _legit_frame_counter = 0
    local _triggerPending = false

    _LegitRS.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)

        LegitFovCircle.Visible  = LegitSettings.LegitEnabled and LegitSettings.LegitFovVisible
        LegitFovCircle.Radius   = LegitSettings.LegitFov
        LegitFovCircle.Color    = LegitSettings.LegitFovColor
        LegitFovCircle.Position = center

        if not LegitSettings.LegitEnabled then return end

        local active = LegitSettings.LegitMode == "Always" or _isKeyDown(LegitSettings.LegitKey, "LegitKey")
        if not active then return end

        _legit_frame_counter = _legit_frame_counter + 1
        if math.random() < 0.28 then return end
        if _legit_frame_counter % math.random(2, 4) == 0 then return end

        local target = _getLegitTarget()
        if not target then return end

        local sp, onScreen = cam:WorldToViewportPoint(target.Position)
        if not onScreen then return end

        local delta = Vector2.new(sp.X, sp.Y) - center
        local mag = delta.Magnitude
        local _frameDelta = 1.6 + math.random() * 0.8
        if mag < _frameDelta then return end

        local smooth = math.max(1, LegitSettings.LegitSmoothing)
        local jitter = 1 + (math.random() - 0.5) * 0.08
        mousemoverel((delta.X / smooth) * jitter, (delta.Y / smooth) * jitter)
    end)

    -- Triggerbot loop
    _LegitRS.Heartbeat:Connect(function()
        if not LegitSettings.TriggerEnabled then
            _triggerPending = false
            return
        end
        local trigActive = LegitSettings.TriggerMode == "Always" or _isKeyDown(LegitSettings.TriggerKey, "TriggerKey")
        if not trigActive then
            _triggerPending = false
            return
        end

        local cam = workspace.CurrentCamera
        if not cam then return end
        local vp = cam.ViewportSize
        local center = Vector2.new(vp.X / 2, vp.Y / 2)
        local triggered = false

        for player, vm in next, playerToViewmodel or {} do
            if not player or player == _LegitLP then continue end
            if not vm or not vm.Parent then continue end
            local resolved = _LegitPlayers:FindFirstChild(player.Name)
            if not resolved or not _legitIsEnemy(resolved, LegitSettings.TriggerTeamCheck) then continue end

            for _, partName in ipairs(_LEGIT_ALL_PARTS) do
                local part = vm:FindFirstChild(partName)
                if not part then continue end
                local sp, onScreen = cam:WorldToViewportPoint(part.Position)
                if not onScreen then continue end
                if (Vector2.new(sp.X, sp.Y) - center).Magnitude <= LegitSettings.TriggerFov then
                    triggered = true
                    break
                end
            end
            if triggered then break end
        end

        if triggered and not _triggerPending then
            _triggerPending = true
            local _baseDelay  = LegitSettings.TriggerDelay / 1000
            local _jitter     = _baseDelay * (0.10 + math.random() * 0.12)
            local _finalDelay = math.max(0.016, _baseDelay + (_jitter * (math.random(0,1) == 0 and 1 or -1)))
            task.delay(_finalDelay, function()
                _triggerPending = false
                if not LegitSettings.TriggerEnabled then return end
                if not (LegitSettings.TriggerMode == "Always" or _isKeyDown(LegitSettings.TriggerKey, "TriggerKey")) then return end
                mouse1press()
                task.wait(0.042 + math.random() * 0.038)
                mouse1release()
            end)
        elseif not triggered then
            _triggerPending = false
        end
    end)

    -- ==================== VISUALS TAB ====================
    -- Re-bind ESP from genv if actor/local scope dropped it
    ESP = ESP or getgenv().ExunysDeveloperESP
    if type(ESP) ~= "table" or type(ESP.Settings) ~= "table" then
        warn("[Vanta Op1] ESP not ready — Visuals controls will no-op until ESP loads")
        ESP = ESP or {}
        ESP.Settings = ESP.Settings or { Enabled = false, TeamCheck = false, AliveCheck = true }
        ESP.Properties = ESP.Properties or {
            ESP = { Enabled = false, DisplayName = false, DisplayDisplayName = false, DisplayDistance = false, DisplayHealth = false, DisplayTool = false },
            Box = { Enabled = false, Type = 3, Thickness = 1, Color = Color3.new(1,1,1), FillSquare = false, FillColor = Color3.new(1,1,1), FillTransparency = 0.18 },
            HealthBar = { Enabled = false },
            Skeleton = { Enabled = false },
            Tracer = { Enabled = false },
        }
    end

    -- Defaults: nothing enabled for ESP (preview starts empty)
    pcall(function()
        ESP.Settings.Enabled = false
        ESP.Properties.Box.Enabled = false
        ESP.Properties.ESP.Enabled = false
        ESP.Properties.ESP.DisplayDisplayName = false
        ESP.Properties.ESP.DisplayName = false
        ESP.Properties.ESP.DisplayDistance = false
        ESP.Properties.ESP.DisplayHealth = false
        ESP.Properties.ESP.DisplayTool = false
        ESP.Properties.HealthBar.Enabled = false
        ESP.Properties.Skeleton.Enabled = false
        ESP.Properties.Tracer.Enabled = false
        ESP.Properties.Box.FillSquare = false
    end)

    -- ==================== VISUALS / PLAYER ESP ====================

    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Master ESP", ico("eye")) end)
    Tabs.Visuals:AddToggle('ESPEnabled', {
        Text = 'Enabled',
        Default = ESP.Settings.Enabled,
        Callback = function(v) ESP.Settings.Enabled = v end,
    }):AddKeyPicker('ESPKey', {
        Default = 'None',
        Text = 'ESP Key',
        Mode = 'Toggle',
    })
    Tabs.Visuals:AddToggle('TeamCheck', {
        Text = 'Team check',
        Default = ESP.Settings.TeamCheck,
        Callback = function(v) ESP.Settings.TeamCheck = v end,
    })
    Tabs.Visuals:AddToggle('AliveCheck', {
        Text = 'Alive check',
        Default = ESP.Settings.AliveCheck ~= false,
        Callback = function(v) ESP.Settings.AliveCheck = v end,
    })

    pcall(function() Tabs.Visuals:AddDivider() end)
    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Box ESP", ico("square")) end)
    Tabs.Visuals:AddToggle('ESPBox', {
        Text = 'Enabled',
        Default = ESP.Properties.Box.Enabled,
        Callback = function(v) ESP.Properties.Box.Enabled = v end,
    }):AddColorPicker('ESPBoxColor', {
        Title = 'Color',
        Default = ESP.Properties.Box.Color,
        Callback = function(v) ESP.Properties.Box.Color = v end,
    })
    Tabs.Visuals:AddDropdown('BoxType', {
        Text = 'Type',
        Values = { 'Full', 'Corner', '3D' },
        Default = (ESP.Properties.Box.Type == 1 and 'Full') or (ESP.Properties.Box.Type == 3 and 'Corner') or (ESP.Properties.Box.Type == 2 and '3D') or 'Corner',
        Callback = function(v)
            if v == 'Full' then ESP.Properties.Box.Type = 1
            elseif v == '3D' then ESP.Properties.Box.Type = 2
            else ESP.Properties.Box.Type = 3 end
        end,
    })
    Tabs.Visuals:AddSlider('BoxThickness', {
        Text = 'Thickness',
        Default = ESP.Properties.Box.Thickness or 1,
        Min = 1, Max = 5, Rounding = 0,
        Callback = function(v) ESP.Properties.Box.Thickness = v end,
    })
    Tabs.Visuals:AddToggle('ESPChamsProxy', {
        Text = 'Fill',
        Default = ESP.Properties.Box.FillSquare,
        Callback = function(v) ESP.Properties.Box.FillSquare = v end,
    }):AddColorPicker('ESPFillColor', {
        Title = 'Fill Color',
        Default = ESP.Properties.Box.FillColor,
        Callback = function(v) ESP.Properties.Box.FillColor = v end,
    })
    Tabs.Visuals:AddSlider('ESPFillTransparency', {
        Text = 'Fill transparency',
        Default = ESP.Properties.Box.FillTransparency or 0.18,
        Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) ESP.Properties.Box.FillTransparency = v end,
    })
    Tabs.Visuals:AddToggle('BoxGradient', {
        Text = 'Gradient',
        Default = ESP.Properties.Box.Gradient == true,
        Callback = function(v) ESP.Properties.Box.Gradient = v end,
    })
    Tabs.Visuals:AddColorPicker('BoxGradientTop', { Text = 'Gradient top', 
        Default = ESP.Properties.Box.GradientTop or Color3.fromRGB(255, 255, 255),
        Callback = function(v) ESP.Properties.Box.GradientTop = v end,
    })
    Tabs.Visuals:AddColorPicker('BoxGradientBottom', { Text = 'Gradient bottom', 
        Default = ESP.Properties.Box.GradientBottom or Color3.fromRGB(120, 170, 255),
        Callback = function(v) ESP.Properties.Box.GradientBottom = v end,
    })

    pcall(function() Tabs.Visuals:AddDivider() end)
    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Healthbar", ico("heart")) end)
    Tabs.Visuals:AddToggle('ESPHealthBar', {
        Text = 'Enabled',
        Default = ESP.Properties.HealthBar.Enabled,
        Callback = function(v) ESP.Properties.HealthBar.Enabled = v end,
    })
    Tabs.Visuals:AddSlider('HealthBarThickness', {
        Text = 'Thickness',
        Default = ESP.Properties.HealthBar.Thickness or 2,
        Min = 1, Max = 6, Rounding = 0,
        Callback = function(v) ESP.Properties.HealthBar.Thickness = v end,
    })
    Tabs.Visuals:AddToggle('ESPHealthText', {
        Text = 'HP Text',
        Default = ESP.Properties.HealthBar.ShowText ~= false,
        Callback = function(v) ESP.Properties.HealthBar.ShowText = v == true end,
    })
    Tabs.Visuals:AddSlider('ESPHealthTextSize', {
        Text = 'HP Text Size',
        Default = math.clamp(ESP.Properties.HealthBar.TextSize or 10, 6, 10),
        Min = 6, Max = 10, Rounding = 0,
        Callback = function(v) ESP.Properties.HealthBar.TextSize = math.clamp(v, 6, 10) end,
    })
    Tabs.Visuals:AddColorPicker('HealthGradTop', { Text = 'Full', 
        Default = ESP.Properties.HealthBar.GradientTop or Color3.fromRGB(255, 255, 255),
        Callback = function(v) ESP.Properties.HealthBar.GradientTop = v end,
    })
    Tabs.Visuals:AddColorPicker('HealthGradMid', { Text = 'Mid', 
        Default = ESP.Properties.HealthBar.GradientMid or Color3.fromRGB(120, 170, 255),
        Callback = function(v) ESP.Properties.HealthBar.GradientMid = v end,
    })
    Tabs.Visuals:AddColorPicker('HealthGradBot', { Text = 'Low', 
        Default = ESP.Properties.HealthBar.GradientBottom or Color3.fromRGB(120, 170, 255),
        Callback = function(v) ESP.Properties.HealthBar.GradientBottom = v end,
    })

    pcall(function() Tabs.Visuals:AddDivider() end)
    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Skeleton", ico("bone")) end)
    Tabs.Visuals:AddToggle('ESPSkeleton', {
        Text = 'Enabled',
        Default = ESP.Properties.Skeleton.Enabled,
        Callback = function(v) ESP.Properties.Skeleton.Enabled = v end,
    }):AddColorPicker('ESPSkeletonColor', {
        Default = ESP.Properties.Skeleton.Color or Color3.new(1, 1, 1),
        Callback = function(v) ESP.Properties.Skeleton.Color = v end,
    })
    Tabs.Visuals:AddSlider('SkeletonThickness', {
        Text = 'Thickness',
        Default = ESP.Properties.Skeleton.Thickness or 1,
        Min = 1, Max = 5, Rounding = 0,
        Callback = function(v) ESP.Properties.Skeleton.Thickness = v end,
    })
    Tabs.Visuals:AddToggle('SkeletonGradient', {
        Text = 'Gradient',
        Default = ESP.Properties.Skeleton.Gradient == true,
        Callback = function(v) ESP.Properties.Skeleton.Gradient = v end,
    })
    Tabs.Visuals:AddColorPicker('SkeletonGradTop', { Text = 'Gradient top', 
        Default = ESP.Properties.Skeleton.GradientTop or Color3.fromRGB(255, 255, 255),
        Callback = function(v) ESP.Properties.Skeleton.GradientTop = v end,
    })
    Tabs.Visuals:AddColorPicker('SkeletonGradBot', { Text = 'Gradient bottom', 
        Default = ESP.Properties.Skeleton.GradientBottom or Color3.fromRGB(120, 170, 255),
        Callback = function(v) ESP.Properties.Skeleton.GradientBottom = v end,
    })

    pcall(function() Tabs.Visuals:AddDivider() end)
    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Chams", ico("box")) end)
    do
        ESP.Properties.Chams = ESP.Properties.Chams or {
            Enabled = false,
            Type = "BoxHandleAdornment",
            Mode = "Fill",
            FillColor = Color3.fromRGB(120, 170, 255),
            FillColor2 = Color3.fromRGB(255, 60, 60),
            FillTransparency = 0.55,
            OutlineTransparency = 0.15,
            VisibleOnly = false,
        }
        local C = ESP.Properties.Chams
        if C.Type ~= "Highlight" and C.Type ~= "BoxHandleAdornment" then
            C.Type = "BoxHandleAdornment"
        end
        Tabs.Visuals:AddToggle('ESPPlayerChams', {
            Text = 'Enabled',
            Default = C.Enabled == true,
            Callback = function(v)
                C.Enabled = v == true
                if not v and getgenv()._MethaneClearPlayerChams then
                    pcall(getgenv()._MethaneClearPlayerChams)
                end
            end,
        })
        Tabs.Visuals:AddDropdown('ESPPlayerChamsType', {
            Text = 'Type',
            Values = { 'BoxHandleAdornment', 'Highlight' },
            Default = (C.Type == 'Highlight') and 'Highlight' or 'BoxHandleAdornment',
            Callback = function(v)
                C.Type = tostring(v or 'BoxHandleAdornment')
                if getgenv()._MethaneClearPlayerChams then
                    pcall(getgenv()._MethaneClearPlayerChams)
                end
            end,
        })
        Tabs.Visuals:AddDropdown('ESPPlayerChamsMode', {
            Text = 'Mode',
            Values = { 'Fill', 'Flow', 'Flat' },
            Default = C.Mode or 'Fill',
            Callback = function(v) C.Mode = tostring(v or 'Fill') end,
        })
        Tabs.Visuals:AddColorPicker('ESPPlayerChamsCol', {
            Text = 'Fill Color',
            Default = C.FillColor or Color3.fromRGB(255, 255, 255),
            Callback = function(v) C.FillColor = v end,
        })
        Tabs.Visuals:AddColorPicker('ESPPlayerChamsCol2', {
            Text = 'Outline Color',
            Default = C.FillColor2 or Color3.fromRGB(120, 170, 255),
            Callback = function(v) C.FillColor2 = v end,
        })
        Tabs.Visuals:AddSlider('ESPPlayerChamsTrans', {
            Text = 'Fill Transparency',
            Default = C.FillTransparency or 0.55,
            Min = 0, Max = 1, Rounding = 2,
            Callback = function(v) C.FillTransparency = v end,
        })
        Tabs.Visuals:AddSlider('ESPPlayerChamsOutTrans', {
            Text = 'Outline Transparency',
            Default = C.OutlineTransparency or 0.15,
            Min = 0, Max = 1, Rounding = 2,
            Callback = function(v) C.OutlineTransparency = v end,
        })
        Tabs.Visuals:AddToggle('ESPPlayerChamsVis', {
            Text = 'Visible Only',
            Default = C.VisibleOnly == true,
            Callback = function(v) C.VisibleOnly = v == true end,
        })
    end

    pcall(function() Tabs.Visuals:AddDivider() end)
    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Tracers", ico("git-commit-horizontal")) end)
    Tabs.Visuals:AddToggle('ESPTracers', {
        Text = 'Enabled',
        Default = ESP.Properties.Tracer.Enabled,
        Callback = function(v) ESP.Properties.Tracer.Enabled = v end,
    }):AddColorPicker('ESPTracerColor', {
        Default = ESP.Properties.Tracer.Color,
        Callback = function(v) ESP.Properties.Tracer.Color = v end,
    })
    Tabs.Visuals:AddSlider('TracerThickness', {
        Text = 'Thickness',
        Default = ESP.Properties.Tracer.Thickness or 1,
        Min = 1, Max = 5, Rounding = 0,
        Callback = function(v) ESP.Properties.Tracer.Thickness = v end,
    })

    pcall(function() Tabs.Visuals:AddDivider() end)
    -- register free: was Tabs.Visuals
    pcall(function() Tabs.Visuals:AddSection("Flags", ico("flag")) end)
    Tabs.Visuals:AddToggle('ESPName', {
        Text = 'Username',
        Default = ESP.Properties.ESP.DisplayName or ESP.Properties.ESP.DisplayDisplayName,
        Callback = function(v)
            ESP.Properties.ESP.DisplayName = v
            ESP.Properties.ESP.DisplayDisplayName = v
            if v then ESP.Properties.ESP.Enabled = true end
        end,
    }):AddColorPicker('ESPNameColor', {
        Default = ESP.Properties.ESP.Color or Color3.new(1, 1, 1),
        Callback = function(v)
            ESP.Properties.ESP.Color = v
            if ESP.Properties.ESP then ESP.Properties.ESP.Color = v end
        end,
    })
    Tabs.Visuals:AddToggle('ESPDistance', {
        Text = 'Distance',
        Default = ESP.Properties.ESP.DisplayDistance,
        Callback = function(v)
            ESP.Properties.ESP.DisplayDistance = v
            if v then ESP.Properties.ESP.Enabled = true end
        end,
    }):AddColorPicker('ESPDistanceColor', {
        Default = ESP.Properties.ESP.DistanceColor or Color3.fromRGB(255, 255, 255),
        Callback = function(v)
            ESP.Properties.ESP.DistanceColor = v
        end,
    })
    Tabs.Visuals:AddToggle('ESPWeapon', {
        Text = 'Weapon',
        Default = ESP.Properties.ESP.DisplayTool,
        Callback = function(v)
            ESP.Properties.ESP.DisplayTool = v
            if v then ESP.Properties.ESP.Enabled = true end
        end,
    }):AddColorPicker('ESPWeaponColor', {
        Default = ESP.Properties.ESP.ToolColor or Color3.fromRGB(255, 255, 255),
        Callback = function(v)
            ESP.Properties.ESP.ToolColor = v
        end,
    })
    Tabs.Visuals:AddToggle('TextOutline', {
        Text = 'Text outline',
        Default = ESP.Properties.ESP.Outline ~= false,
        Callback = function(v) ESP.Properties.ESP.Outline = v end,
    }):AddColorPicker('ESPOutlineColor', {
        Default = ESP.Properties.ESP.OutlineColor or Color3.new(0, 0, 0),
        Callback = function(v)
            ESP.Properties.ESP.OutlineColor = v
        end,
    })
    Tabs.Visuals:AddSlider('TextSize', {
        Text = 'Text size',
        Default = ESP.Properties.ESP.Size or 14,
        Min = 10, Max = 24, Rounding = 0,
        Callback = function(v) ESP.Properties.ESP.Size = v end,
    })

    -- ==================== GADGETS TAB ====================

    local AntiSmoke = false

    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Players           = game:GetService('Players')
    local LocalPlayer       = Players.LocalPlayer
    local UIParent          = game:GetService('CoreGui')

    -- Per-gadget settings (each gadget has its own independent config)
    local GadgetSettings = {
        -- Gadgets
        SignalDisruptor     = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(150, 50, 255),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(150, 50, 255),  ChamsColor = Color3.fromRGB(150, 50, 255),  Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        BreachCharge        = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 100, 50),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 100, 50),   ChamsColor = Color3.fromRGB(255, 100, 50),   Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        HardBreachCharge    = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 100, 50),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 100, 50),   ChamsColor = Color3.fromRGB(255, 100, 50),   Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        BarbedWire          = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(150, 150, 150),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(150, 150, 150),  ChamsColor = Color3.fromRGB(150, 150, 150),  Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        DeployableShield    = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(100, 100, 100),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(100, 100, 100),  ChamsColor = Color3.fromRGB(100, 100, 100),  Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        RemoteC4            = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 0,   0),    IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 0, 0),      ChamsColor = Color3.fromRGB(255, 0, 0),      Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        Claymore            = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 50,  50),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 50, 50),    ChamsColor = Color3.fromRGB(255, 50, 50),    Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        NeedleMine          = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 170, 0),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 170, 0),    ChamsColor = Color3.fromRGB(255, 170, 0),    Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        ThermiteCharge      = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 50,  0),    IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 50, 0),     ChamsColor = Color3.fromRGB(255, 50, 0),     Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        ShockBattery        = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 255, 0),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 255, 0),    ChamsColor = Color3.fromRGB(255, 255, 0),    Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        DefaultCamera       = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(50,  150, 255),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(50, 150, 255),   ChamsColor = Color3.fromRGB(50, 150, 255),   Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        BulletproofCamera   = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(50,  150, 255),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(50, 150, 255),   ChamsColor = Color3.fromRGB(50, 150, 255),   Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        StickyCamera        = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(50,  150, 255),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(50, 150, 255),   ChamsColor = Color3.fromRGB(50, 150, 255),   Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        Defuser             = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 255, 0),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 255, 0),    ChamsColor = Color3.fromRGB(255, 255, 0),    Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        ProximityAlarm      = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 100, 100), IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 100, 100),  ChamsColor = Color3.fromRGB(255, 100, 100),  Thickness = 1, IsGrenade = false, GadgetDistance = 3000},
        -- Grenades
        ToxicCharge         = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(150, 255, 50),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(150, 255, 50),   ChamsColor = Color3.fromRGB(150, 255, 50),   Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
        FragGrenade         = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 0,   0),    IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 0, 0),      ChamsColor = Color3.fromRGB(255, 0, 0),      Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
        ImpactGrenade       = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 50,  50),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 50, 50),    ChamsColor = Color3.fromRGB(255, 50, 50),    Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
        SmokeGrenade        = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(180, 180, 180), IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(180, 180, 180),  ChamsColor = Color3.fromRGB(180, 180, 180),  Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
        IncendiaryGrenade   = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 120, 0),   IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(255, 120, 0),    ChamsColor = Color3.fromRGB(255, 120, 0),    Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
        StunGrenade         = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(255, 255, 255), IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(200, 200, 200),  ChamsColor = Color3.fromRGB(200, 200, 200),  Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
        EMPGrenade          = {Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false, Color = Color3.fromRGB(50,  150, 255),  IconColor = Color3.new(1,1,1), BackgroundColor = Color3.fromRGB(50, 150, 255),   ChamsColor = Color3.fromRGB(50, 150, 255),   Thickness = 1, IsGrenade = true, GadgetDistance = 3000},
    }

    local GadgetDisplayNames = {
        SignalDisruptor   = 'Signal Disruptor',
        BreachCharge      = 'Breach Charge',
        HardBreachCharge  = 'Hard Breach Charge',
        BarbedWire        = 'Barbed Wire',
        DeployableShield  = 'Deployable Shield',
        RemoteC4          = 'Remote C4',
        Claymore          = 'Claymore',
        NeedleMine        = 'Needle Mine',
        ThermiteCharge    = 'Thermite Charge',
        ShockBattery      = 'Shock Battery',
        DefaultCamera     = 'Default Camera',
        BulletproofCamera = 'Bulletproof Camera',
        StickyCamera      = 'Sticky Camera',
        Defuser           = 'Defuser',
        ProximityAlarm    = 'Proximity Alarm',
        Drone             = 'Drone',
        ToxicCharge       = 'Toxic Charge',
        FragGrenade       = 'Frag Grenade',
        ImpactGrenade     = 'Impact Grenade',
        SmokeGrenade      = 'Smoke Grenade',
        IncendiaryGrenade = 'Incendiary Grenade',
        StunGrenade       = 'Stun Grenade',
        EMPGrenade        = 'EMP Grenade',
    }

    -- Merge Drone
    GadgetSettings['Drone'] = {
        Enabled = true, ShowName = true, ShowDistance = true, ShowBox = true, ShowChams = false,
        Color = Color3.fromRGB(255, 80, 80), IconColor = Color3.new(1, 1, 1),
        BackgroundColor = Color3.fromRGB(255, 80, 80), ChamsColor = Color3.fromRGB(255, 80, 80), Thickness = 1,
        IsGrenade = false, GadgetDistance = 3000,
    }

    -- Global gadget config (mirrors old GadgetCfg for the shared settings groupboxes)
    local GadgetCfg = {
        ShowGadgets          = false,
        ShowGrenades         = false,
        GadgetDistance       = 3000,
        GrenadeDistance      = 3000,
        GadgetShowNames      = true,
        GrenadeShowNames     = true,
        GadgetShowDist       = true,
        GrenadeShowDist      = true,
        GadgetChams          = false,
        GrenadeChams         = false,
        GadgetNameColor      = Color3.new(1,1,1),
        GrenadeNameColor     = Color3.new(1,1,1),
        GadgetDistColor      = Color3.fromRGB(215,215,220),
        GrenadeDistColor     = Color3.fromRGB(215,215,220),
        TeamCheck            = false,
    }

    -- Sync GadgetCfg changes down to per-gadget GadgetSettings
    local function SyncGadgetCfgToSettings()
        for name, cfg in pairs(GadgetSettings) do
            local isGrenade = cfg.IsGrenade
            if isGrenade then
                cfg.ShowName       = GadgetCfg.GrenadeShowNames
                cfg.ShowDistance   = GadgetCfg.GrenadeShowDist
                cfg.ShowChams      = GadgetCfg.GrenadeChams
                cfg.GadgetDistance = GadgetCfg.GrenadeDistance
                cfg.Color          = GadgetCfg.GrenadeNameColor
            else
                cfg.ShowName       = GadgetCfg.GadgetShowNames
                cfg.ShowDistance   = GadgetCfg.GadgetShowDist
                cfg.ShowChams      = GadgetCfg.GadgetChams
                cfg.GadgetDistance = GadgetCfg.GadgetDistance
                cfg.Color          = GadgetCfg.GadgetNameColor
            end
        end
    end
    SyncGadgetCfgToSettings()

    -- Random instance names — new strings every session, no static fingerprint
    local _HS = game:GetService('HttpService')
    local function _rn() return _HS:GenerateGUID(false):sub(1, 8) end
    local _GN_Ping    = _rn()
    local _GN_TC      = _rn()
    local _GN_NL      = _rn()
    local _GN_DL      = _rn()
    local _GN_ChamSfx = _rn()
    local _GN_Gui     = _rn()
    local _GN_Vp      = _rn()

    local GadgetESPIcons    = {}
    local GadgetESPDefaultIcon = 'rbxassetid://119002926213252'
    local GadgetESPViewport = nil
    local GadgetESPTrackers = {}
    local GadgetESPAlive    = true

    local GadgetCameraNames = {
        DefaultCamera     = true,
        BulletproofCamera = true,
        StickyCamera      = true,
    }

    local function LoadGadgetIcons()
        table.clear(GadgetESPIcons)
        -- Scan Items.Item (same path the standalone GadgetESP uses — this is where all icons live)
        local Root = ReplicatedStorage:FindFirstChild('Modules')
        Root = Root and Root:FindFirstChild('Items')
        Root = Root and Root:FindFirstChild('Item')
        if Root then
            local Modules = Root:GetDescendants()
            for Index = 1, #Modules do
                local Module = Modules[Index]
                if Module:IsA('ModuleScript') then
                    pcall(function()
                        local Data = require(Module)
                        if type(Data) == 'table' and Data.icon then
                            GadgetESPIcons[Module.Name] = Data.icon
                        end
                    end)
                end
            end
        end
        GadgetESPIcons['Drone'] = 'rbxassetid://105322023029633'
    end

    local function EnsureGadgetViewport()
        if GadgetESPViewport and GadgetESPViewport.Parent then return end
        local lp = Players.LocalPlayer
        local pg = lp and (lp:FindFirstChildOfClass('PlayerGui') or lp:WaitForChild('PlayerGui', 5))
        if not pg then return end
        local Gui = Instance.new('ScreenGui')
        Gui.Name           = _GN_Gui
        Gui.ResetOnSpawn   = false
        Gui.IgnoreGuiInset = true
        Gui.DisplayOrder   = 99997
        Gui.Parent         = pg
        local Vp = Instance.new('ViewportFrame')
        Vp.Name                   = _GN_Vp
        Vp.Size                   = UDim2.new(1, 0, 1, 0)
        Vp.BackgroundTransparency = 1
        Vp.CurrentCamera          = workspace.CurrentCamera
        Vp.Parent                 = Gui
        GadgetESPViewport = Vp
    end

    local function CreateGadgetPing(Gadget)
        -- Use the game's own PingObject template — same as original vault approach
        local Effects     = ReplicatedStorage:FindFirstChild('Modules')
        Effects           = Effects and Effects:FindFirstChild('Effects')
        local PingTemplate = Effects and Effects:FindFirstChild('PingObject')
        if not PingTemplate then return nil, nil, nil, nil, nil end

        local Ping = PingTemplate:Clone()
        Ping.Name = _GN_Ping
        local _pingAnchor = Gadget:FindFirstChildOfClass('BasePart') or Gadget
        if Gadget.PrimaryPart then _pingAnchor = Gadget.PrimaryPart end
        local okParent = pcall(function() Ping.Parent = _pingAnchor end)
        if not okParent then
            pcall(function() Ping:Destroy() end)
            return nil, nil, nil, nil, nil
        end
        Ping.AlwaysOnTop      = true
        Ping.ClipsDescendants = false
        Ping.StudsOffset      = Vector3.new(0, 0.3, 0)
        Ping.Size             = UDim2.new(0, 120, 0, 70)
        -- Start hidden; render loop enables only when Show Gadgets/Grenades is on
        Ping.Enabled          = false

        local Arrow = Ping:FindFirstChild('Arrow')
        if Arrow then Arrow:Destroy() end

        local Circle = Ping:FindFirstChild('Frame')
        local Icon   = Circle and Circle:FindFirstChild('ImageLabel')
        if Circle then
            Circle.AnchorPoint      = Vector2.new(0.5, 0)
            Circle.Size             = UDim2.new(0, 30, 0, 30)
            Circle.Position         = UDim2.new(0.5, 0, 0, 0)
            Circle.ClipsDescendants = false
        end

        local ExistingTC = Ping:FindFirstChild('TextContainer')
        if ExistingTC then ExistingTC:Destroy() end

        task.wait()

        local TC = Instance.new('Frame')
        TC.Name                  = _GN_TC
        TC.BackgroundTransparency = 1
        TC.AnchorPoint           = Vector2.new(0.5, 0)
        TC.Position              = UDim2.new(0.5, 0, 0, 31)
        TC.Size                  = UDim2.new(1, 0, 0, 35)
        TC.ClipsDescendants      = false
        TC.Parent                = Ping

        local NameLabel = Instance.new('TextLabel')
        NameLabel.Name                  = _GN_NL
        NameLabel.BackgroundTransparency = 1
        NameLabel.Position              = UDim2.new(0, 0, 0, 0)
        NameLabel.Size                  = UDim2.new(1, 0, 0, 14)
        NameLabel.Font                  = Enum.Font.GothamMedium
        NameLabel.TextSize              = 12
        NameLabel.TextColor3            = Color3.new(1, 1, 1)
        NameLabel.TextStrokeTransparency = 0
        NameLabel.TextStrokeColor3      = Color3.new(0, 0, 0)
        NameLabel.TextXAlignment        = Enum.TextXAlignment.Center
        NameLabel.Parent                = TC

        local DistLabel = Instance.new('TextLabel')
        DistLabel.Name                  = _GN_DL
        DistLabel.BackgroundTransparency = 1
        DistLabel.Position              = UDim2.new(0, 0, 0, 14)
        DistLabel.Size                  = UDim2.new(1, 0, 0, 14)
        DistLabel.Font                  = Enum.Font.GothamMedium
        DistLabel.TextSize              = 11
        DistLabel.TextColor3            = Color3.fromRGB(215, 215, 220)
        DistLabel.TextStrokeTransparency = 0
        DistLabel.TextStrokeColor3      = Color3.new(0, 0, 0)
        DistLabel.TextXAlignment        = Enum.TextXAlignment.Center
        DistLabel.Parent                = TC

        return Ping, Circle, Icon, NameLabel, DistLabel
    end

    local function CreateGadgetCham(Gadget, cfg)
        -- Stride method: neon clone in ViewportFrame, anchored, no scripts/ping
        EnsureGadgetViewport()
        if not GadgetESPViewport then return nil end
        local ok, Clone = pcall(function() return Gadget:Clone() end)
        if not ok or not Clone then return nil end
        Clone.Name = Gadget.Name .. _GN_ChamSfx
        local ExistingPing = Clone:FindFirstChild(_GN_Ping)
        if ExistingPing then pcall(function() ExistingPing:Destroy() end) end
        local col = cfg.ChamsColor or cfg.Color or Color3.fromRGB(255, 0, 0)
        for _, Child in ipairs(Clone:GetDescendants()) do
            if Child:IsA('BasePart') then
                Child.Color = col
                Child.Material = Enum.Material.Neon
                Child.Anchored = true
                Child.CanCollide = false
                Child.CastShadow = false
                Child.Transparency = 0
            elseif Child:IsA('Script') or Child:IsA('LocalScript')
                or Child:IsA('Sound') or Child:IsA('ParticleEmitter')
                or Child:IsA('BillboardGui') or Child:IsA('Highlight') then
                pcall(function() Child:Destroy() end)
            end
        end
        pcall(function() Clone.Parent = GadgetESPViewport end)
        return Clone
    end

    local function ApplyGadgetPingStyle(tracker, cfg, gadgetName)
        local displayName = GadgetDisplayNames[gadgetName] or gadgetName
        if tracker.Circle then
            tracker.Circle.BackgroundColor3    = cfg.BackgroundColor
            tracker.Circle.BackgroundTransparency = 0.2
        end
        if tracker.Icon then
            tracker.Icon.Image             = GadgetESPIcons[gadgetName] or GadgetESPDefaultIcon
            tracker.Icon.ImageColor3       = Color3.new(1, 1, 1)
            tracker.Icon.ImageTransparency = 0
        end
        if tracker.NameLabel then
            tracker.NameLabel.Text    = cfg.ShowName and displayName or ''
            tracker.NameLabel.Visible = cfg.ShowName
            tracker.NameLabel.TextColor3 = cfg.Color
        end
        if tracker.DistLabel then
            tracker.DistLabel.Visible    = cfg.ShowDistance
            tracker.DistLabel.TextColor3 = cfg.IsGrenade and GadgetCfg.GrenadeDistColor or GadgetCfg.GadgetDistColor
        end
    end

    local function SuppressNativePings(Gadget, tracker)
        -- Hide the game's own camera/gadget BillboardGui pings so we don't double-draw
        tracker.SuppressedNative = tracker.SuppressedNative or {}
        for _, d in ipairs(Gadget:GetDescendants()) do
            if d:IsA('BillboardGui') and d.Name ~= _GN_Ping then
                local n = string.lower(d.Name)
                if n == 'pingobject' or n:find('ping', 1, true) or d:FindFirstChild('Frame') then
                    if tracker.SuppressedNative[d] == nil then
                        tracker.SuppressedNative[d] = d.Enabled
                    end
                    d.Enabled = false
                end
            end
        end
    end

    local function RestoreNativePings(tracker)
        if not tracker or not tracker.SuppressedNative then return end
        for gui, wasEnabled in pairs(tracker.SuppressedNative) do
            pcall(function()
                if gui and gui.Parent then
                    gui.Enabled = wasEnabled
                end
            end)
        end
        tracker.SuppressedNative = nil
    end

    local function AddGadgetTracker(Gadget)
        if not GadgetESPAlive then return end
        if not Gadget or not Gadget.Parent then return end
        if not Gadget:IsA('Model') then return end
        if not GadgetCameraNames[Gadget.Name] and Players:GetPlayerFromCharacter(Gadget) then return end
        local cfg = GadgetSettings[Gadget.Name]
        if not cfg then return end
        if not cfg.Enabled then return end
        if GadgetESPTrackers[Gadget] then return end
        -- Skip grenades while still held (parented under a character)
        if cfg.IsGrenade then
            local ancestor = Gadget.Parent
            while ancestor and ancestor ~= workspace do
                if Players:GetPlayerFromCharacter(ancestor) then return end
                ancestor = ancestor.Parent
            end
        end
        -- Remove any leftover ESP pings from a previous tracker (prevents doubles)
        for _, d in ipairs(Gadget:GetDescendants()) do
            if d:IsA('BillboardGui') and d.Name == _GN_Ping then
                pcall(function() d:Destroy() end)
            end
        end
        local Ping, Circle, Icon, NameLabel, DistLabel = CreateGadgetPing(Gadget)
        local ChamModel = (cfg.ShowChams and cfg.Enabled) and CreateGadgetCham(Gadget, cfg) or nil
        GadgetESPTrackers[Gadget] = {
            Ping      = Ping,
            Circle    = Circle,
            Icon      = Icon,
            NameLabel = NameLabel,
            DistLabel = DistLabel,
            ChamModel = ChamModel,
            SuppressedNative = {},
        }
        if Ping then
            Ping.Enabled = false -- gated by ShowGadgets / ShowGrenades in render loop
            ApplyGadgetPingStyle(GadgetESPTrackers[Gadget], cfg, Gadget.Name)
        end
        SuppressNativePings(Gadget, GadgetESPTrackers[Gadget])
    end

    local function RemoveGadgetTracker(Gadget)
        local tracker = GadgetESPTrackers[Gadget]
        if not tracker then return end
        RestoreNativePings(tracker)
        pcall(function() if tracker.Ping then tracker.Ping:Destroy() end end)
        pcall(function() if tracker.ChamModel then tracker.ChamModel:Destroy() end end)
        GadgetESPTrackers[Gadget] = nil
    end

    task.spawn(function()
        LoadGadgetIcons()
        EnsureGadgetViewport()
        local i = 0
        for _, v in ipairs(workspace:GetDescendants()) do
            if v:IsA('Model') and GadgetSettings[v.Name] then
                AddGadgetTracker(v)
                i += 1
                if i % 4 == 0 then task.wait() end
            end
        end
    end)

    local _gadgetSeen = {}
    workspace.DescendantAdded:Connect(function(child)
        if child:IsA('Model') and GadgetSettings[child.Name] then
            if _gadgetSeen[child] then return end
            _gadgetSeen[child] = true
            task.delay(0.05, function()
                AddGadgetTracker(child)
            end)
        end
    end)

    workspace.DescendantRemoving:Connect(function(child)
        local cfg = GadgetSettings[child.Name]
        if not cfg then return end
        -- Cameras + grenades often reparent (workspace <-> CurrentCamera / character).
        -- Only drop the tracker when the instance is truly destroyed (no Parent).
        local isCamera = GadgetCameraNames[child.Name] == true
        if cfg.IsGrenade or isCamera then
            task.defer(function()
                if not child or not child.Parent then
                    _gadgetSeen[child] = nil
                    if GadgetESPTrackers[child] then RemoveGadgetTracker(child) end
                end
            end)
        else
            task.defer(function()
                if not child or not child.Parent then
                    _gadgetSeen[child] = nil
                    if GadgetESPTrackers[child] then RemoveGadgetTracker(child) end
                end
            end)
        end
    end)
    -- ==================== END GADGET ESP CONTROLLER ====================

    -- ==================== FOV CIRCLE + RENDER LOOP ====================

    local FovCircle = Drawing.new('Circle')
    FovCircle.Visible   = settings.SilentEnabled and settings.SilentFovCircle
    FovCircle.Filled    = false
    FovCircle.Thickness = 1
    FovCircle.NumSides  = 64
    FovCircle.Color     = settings.SilentFovCircleColor

    local lp     = game:GetService('Players').LocalPlayer
    local espCam = workspace.CurrentCamera

    game:GetService('RunService').RenderStepped:Connect(function()
        if not espCam or not espCam.Parent then
            espCam = workspace.CurrentCamera
        end
        if espCam then
            FovCircle.Visible  = settings.SilentEnabled and settings.SilentFovCircle
            FovCircle.Radius   = settings.SilentFov
            FovCircle.Color    = settings.SilentFovCircleColor
            FovCircle.Position = UserInputService:GetMouseLocation()
        end

        -- ==================== GADGET ESP STEP ====================
        if GadgetESPViewport then
            GadgetESPViewport.CurrentCamera = workspace.CurrentCamera
        end

        local lpChr  = lp and lp.Character
        local lpRoot = lpChr and lpChr:FindFirstChild('HumanoidRootPart')
        local lpPos  = lpRoot and lpRoot.Position or Vector3.zero

        for Gadget, tracker in pairs(GadgetESPTrackers) do
            local cfg = GadgetSettings[Gadget.Name]
            -- Cameras live under CurrentCamera; other gadgets under workspace
            local stillAlive = false
            if Gadget and Gadget.Parent then
                if GadgetCameraNames[Gadget.Name] then
                    stillAlive = Gadget:IsDescendantOf(workspace)
                        or (workspace.CurrentCamera and Gadget:IsDescendantOf(workspace.CurrentCamera))
                else
                    stillAlive = Gadget:IsDescendantOf(workspace)
                    if stillAlive and workspace.CurrentCamera
                        and Gadget:IsDescendantOf(workspace.CurrentCamera) then
                        stillAlive = false
                    end
                end
            end
            if stillAlive and Gadget.Name:find('Broken') then
                stillAlive = false
            end

            if not stillAlive or not cfg then
                RemoveGadgetTracker(Gadget)
            else
                local skip = false
                if GadgetCfg.TeamCheck then
                    pcall(function()
                        local myTeam = lp and lp:GetAttribute('Team')
                        if not myTeam then return end

                        -- Resolve owner (Stride O1 method): attribute -> Owner child -> StateObject
                        local ownerName = Gadget:GetAttribute('Owner')

                        if not ownerName then
                            local ownerVal = Gadget:FindFirstChild('Owner')
                            if ownerVal then
                                if ownerVal:IsA('ObjectValue') and ownerVal.Value then
                                    ownerName = ownerVal.Value.Name
                                elseif ownerVal:IsA('StringValue') then
                                    ownerName = ownerVal.Value
                                else
                                    local ul = ownerVal:FindFirstChild('Username')
                                    if ul and ul.Text ~= '' then ownerName = ul.Text end
                                end
                            end
                        end

                        local SO = getgenv()._StrideStateObject
                        if not ownerName and SO and SO.get_all then
                            for _, characterObj in SO.get_all('Character') do
                                local ownerPlayer = characterObj.owner and characterObj.owner:get()
                                if not ownerPlayer or ownerPlayer == lp then continue end
                                local vm = characterObj.values and characterObj.values.viewmodels
                                if vm and Gadget:IsDescendantOf(vm) then
                                    ownerName = ownerPlayer.Name
                                    break
                                end
                                local charInst = characterObj.instance or (characterObj.values and characterObj.values.instance)
                                if charInst and Gadget:IsDescendantOf(charInst) then
                                    ownerName = ownerPlayer.Name
                                    break
                                end
                                local deployed = characterObj.values and characterObj.values.deployed
                                if deployed and type(deployed) == 'table' then
                                    for _, ref in pairs(deployed) do
                                        local refInst = type(ref) == 'table' and ref.get and ref:get() or ref
                                        if refInst == Gadget or (typeof(refInst) == 'Instance' and Gadget:IsDescendantOf(refInst)) then
                                            ownerName = ownerPlayer.Name
                                            break
                                        end
                                    end
                                    if ownerName then break end
                                end
                            end
                        end

                        if ownerName then
                            -- Hide own gadgets + same-team gadgets
                            if lp and (ownerName == lp.Name or ownerName == lp.DisplayName) then
                                skip = true
                            else
                                local ownerPlayer = Players:FindFirstChild(ownerName)
                                if ownerPlayer then
                                    if ownerPlayer == lp then
                                        skip = true
                                    else
                                        local theirTeam = ownerPlayer:GetAttribute('Team')
                                        if theirTeam ~= nil and myTeam == theirTeam then
                                            skip = true
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end

                -- Master show/hide gates from global GadgetCfg
                local isGrenade     = cfg.IsGrenade
                local masterEnabled = isGrenade and GadgetCfg.ShowGrenades or GadgetCfg.ShowGadgets
                local markerEnabled = cfg.Enabled and masterEnabled and not skip
                local chamsMaster   = isGrenade and GadgetCfg.GrenadeChams or GadgetCfg.GadgetChams
                local chamEnabled   = cfg.Enabled and masterEnabled and chamsMaster and not skip

                local distance = 0
                local pivotOk, pivot = pcall(function() return Gadget:GetPivot() end)
                if pivotOk then
                    distance = (lpPos - pivot.Position).Magnitude
                    if tracker.ChamModel then
                        pcall(function() tracker.ChamModel:PivotTo(pivot) end)
                    end
                end

                local distLimit = isGrenade and GadgetCfg.GrenadeDistance or GadgetCfg.GadgetDistance
                local inRange   = distance <= distLimit

                local markerVisible = markerEnabled and inRange
                local chamVisible   = chamEnabled and inRange

                if chamVisible and not tracker.ChamModel then
                    tracker.ChamModel = CreateGadgetCham(Gadget, cfg)
                    if tracker.ChamModel and pivotOk then
                        pcall(function() tracker.ChamModel:PivotTo(pivot) end)
                    end
                end
                if tracker.ChamModel then
                    pcall(function()
                        tracker.ChamModel.Parent = chamVisible and GadgetESPViewport or nil
                    end)
                end

                -- Keep native game pings suppressed while we own this tracker
                SuppressNativePings(Gadget, tracker)

                if tracker.Ping then
                    tracker.Ping.Enabled = markerVisible == true
                    if markerVisible then
                        -- Sync per-gadget display props from global cfg
                        local showName = isGrenade and GadgetCfg.GrenadeShowNames or GadgetCfg.GadgetShowNames
                        local showDist = isGrenade and GadgetCfg.GrenadeShowDist  or GadgetCfg.GadgetShowDist
                        local nameCol  = isGrenade and GadgetCfg.GrenadeNameColor or GadgetCfg.GadgetNameColor
                        cfg.ShowName     = showName
                        cfg.ShowDistance = showDist
                        cfg.Color        = nameCol
                        ApplyGadgetPingStyle(tracker, cfg, Gadget.Name)
                        if tracker.DistLabel and tracker.DistLabel.Visible then
                            tracker.DistLabel.Text = string.format('[%dm]', math.floor(distance * 0.28))
                        end
                    end
                end
            end
        end
        -- ==================== END GADGET ESP STEP ====================
    end)

    -- ==================== GADGETS (master + grenade + selection) ====================
    -- register free: was Tabs.Gadgets
    pcall(function() Tabs.Gadgets:AddSection("Gadget Options") end)
    Tabs.Gadgets:AddToggle('ShowGadgets', {
        Text = 'Enabled', Default = GadgetCfg.ShowGadgets,
        Callback = function(v) GadgetCfg.ShowGadgets = v end
    })
    Tabs.Gadgets:AddToggle('GadgetShowNames', {
        Text = 'Show Names', Default = GadgetCfg.GadgetShowNames,
        Callback = function(v) GadgetCfg.GadgetShowNames = v end
    }):AddColorPicker('GadgetNameColor', {
        Default = GadgetCfg.GadgetNameColor,
        Callback = function(v) GadgetCfg.GadgetNameColor = v end
    })
    Tabs.Gadgets:AddToggle('GadgetShowDist', {
        Text = 'Show Distance', Default = GadgetCfg.GadgetShowDist,
        Callback = function(v) GadgetCfg.GadgetShowDist = v end
    }):AddColorPicker('GadgetDistColor', {
        Default = GadgetCfg.GadgetDistColor,
        Callback = function(v) GadgetCfg.GadgetDistColor = v end
    })
    Tabs.Gadgets:AddToggle('GadgetChams', {
        Text = 'Chams', Default = GadgetCfg.GadgetChams,
        Callback = function(v)
            GadgetCfg.GadgetChams = v
            pcall(SyncGadgetCfgToSettings)
            for model, tracker in pairs(GadgetESPTrackers) do
                local cfg = GadgetSettings[model.Name]
                if not cfg or cfg.IsGrenade then continue end
                if v and cfg.Enabled and not tracker.ChamModel then
                    tracker.ChamModel = CreateGadgetCham(model, cfg)
                elseif not v and tracker.ChamModel then
                    pcall(function() tracker.ChamModel:Destroy() end)
                    tracker.ChamModel = nil
                end
            end
        end
    })
    Tabs.Gadgets:AddSlider('GadgetDistance', {
        Text = 'Max Distance', Default = GadgetCfg.GadgetDistance,
        Min = 50, Max = 5000, Rounding = 0, Suffix = 'm',
        Callback = function(v) GadgetCfg.GadgetDistance = v end
    })
    Tabs.Gadgets:AddToggle('GadgetCfgTeamCheck', {
        Text = 'Team Check', Default = GadgetCfg.TeamCheck,
        Callback = function(v) GadgetCfg.TeamCheck = v end
    })

    pcall(function() Tabs.Gadgets:AddSection("Grenade Options") end)
    Tabs.Gadgets:AddToggle('ShowGrenades', {
        Text = 'Enabled', Default = GadgetCfg.ShowGrenades,
        Callback = function(v) GadgetCfg.ShowGrenades = v end
    })
    Tabs.Gadgets:AddToggle('GrenadeShowNames', {
        Text = 'Show Names', Default = GadgetCfg.GrenadeShowNames,
        Callback = function(v) GadgetCfg.GrenadeShowNames = v end
    }):AddColorPicker('GrenadeNameColor', {
        Default = GadgetCfg.GrenadeNameColor,
        Callback = function(v) GadgetCfg.GrenadeNameColor = v end
    })
    Tabs.Gadgets:AddToggle('GrenadeShowDist', {
        Text = 'Show Distance', Default = GadgetCfg.GrenadeShowDist,
        Callback = function(v) GadgetCfg.GrenadeShowDist = v end
    }):AddColorPicker('GrenadeDistColor', {
        Default = GadgetCfg.GrenadeDistColor,
        Callback = function(v) GadgetCfg.GrenadeDistColor = v end
    })
    Tabs.Gadgets:AddToggle('GrenadeChams', {
        Text = 'Chams', Default = GadgetCfg.GrenadeChams,
        Callback = function(v)
            GadgetCfg.GrenadeChams = v
            pcall(SyncGadgetCfgToSettings)
            for model, tracker in pairs(GadgetESPTrackers) do
                local cfg = GadgetSettings[model.Name]
                if not cfg or not cfg.IsGrenade then continue end
                if v and cfg.Enabled and not tracker.ChamModel then
                    tracker.ChamModel = CreateGadgetCham(model, cfg)
                elseif not v and tracker.ChamModel then
                    pcall(function() tracker.ChamModel:Destroy() end)
                    tracker.ChamModel = nil
                end
            end
        end
    })
    Tabs.Gadgets:AddSlider('GrenadeDistance', {
        Text = 'Max Distance', Default = GadgetCfg.GrenadeDistance,
        Min = 50, Max = 5000, Rounding = 0, Suffix = 'm',
        Callback = function(v) GadgetCfg.GrenadeDistance = v end
    })

    pcall(function() Tabs.Gadgets:AddSection("Gadgets") end)
    local GadgetList = {
        { name = 'Drone',             key = 'Drone'             },
        { name = 'Default Camera',    key = 'DefaultCamera'     },
        { name = 'Bulletproof Cam',   key = 'BulletproofCamera' },
        { name = 'Sticky Camera',     key = 'StickyCamera'      },
        { name = 'Claymore',          key = 'Claymore'          },
        { name = 'Barbed Wire',       key = 'BarbedWire'        },
        { name = 'Shock Battery',     key = 'ShockBattery'      },
        { name = 'Breach Charge',     key = 'BreachCharge'      },
        { name = 'Hard Breach',       key = 'HardBreachCharge'  },
        { name = 'Thermite Charge',   key = 'ThermiteCharge'    },
        { name = 'Remote C4',         key = 'RemoteC4'          },
        { name = 'Defuser',           key = 'Defuser'           },
        { name = 'Proximity Alarm',   key = 'ProximityAlarm'    },
        { name = 'Signal Disruptor',  key = 'SignalDisruptor'   },
        { name = 'Deployable Shield', key = 'DeployableShield'  },
        { name = 'Needle Mine',       key = 'NeedleMine'        },
    }
    for _, entry in ipairs(GadgetList) do
        local k   = entry.key
        local cfg = GadgetSettings[k]
        if not cfg then continue end
        Tabs.Gadgets:AddToggle('GadgetEnable_' .. k, {
            Text = entry.name, Default = cfg.Enabled,
            Callback = function(v)
                cfg.Enabled = v
                if v then
                    for _, child in ipairs(workspace:GetDescendants()) do
                        if child.Name == k and child:IsA('Model') then AddGadgetTracker(child) end
                    end
                else
                    for model in pairs(GadgetESPTrackers) do
                        if model.Name == k then RemoveGadgetTracker(model) end
                    end
                end
            end
        }):AddColorPicker('GadgetBgColor_' .. k, {
            Default = cfg.BackgroundColor,
            Callback = function(v)
                cfg.BackgroundColor = v
                cfg.IconColor = Color3.new(1, 1, 1)
            end
        })
    end

    pcall(function() Tabs.Gadgets:AddSection("Grenades") end)
    local GrenadeList = {
        { name = 'Frag Grenade',       key = 'FragGrenade'       },
        { name = 'Impact Grenade',     key = 'ImpactGrenade'     },
        { name = 'Smoke Grenade',      key = 'SmokeGrenade'      },
        { name = 'Incendiary Grenade', key = 'IncendiaryGrenade' },
        { name = 'Stun Grenade',       key = 'StunGrenade'       },
        { name = 'EMP Grenade',        key = 'EMPGrenade'        },
        { name = 'Toxic Charge',       key = 'ToxicCharge'       },
    }
    for _, entry in ipairs(GrenadeList) do
        local k   = entry.key
        local cfg = GadgetSettings[k]
        if not cfg then continue end
        Tabs.Gadgets:AddToggle('GrenadeEnable_' .. k, {
            Text = entry.name, Default = cfg.Enabled,
            Callback = function(v)
                cfg.Enabled = v
                if v then
                    for _, child in ipairs(workspace:GetDescendants()) do
                        if child.Name == k and child:IsA('Model') then AddGadgetTracker(child) end
                    end
                else
                    for model in pairs(GadgetESPTrackers) do
                        if model.Name == k then RemoveGadgetTracker(model) end
                    end
                end
            end
        }):AddColorPicker('GrenadeBgColor_' .. k, {
            Default = cfg.BackgroundColor,
            Callback = function(v)
                cfg.BackgroundColor = v
                cfg.IconColor = Color3.new(1, 1, 1)
            end
        })
    end


    -- ==================== WORLD MODS (Fullbright + FPS Boost) ====================
    -- Client-only. Fullbright only writes Lighting on state change (not every frame).
    -- FPS Boost uses setrenderproperty when available (render-layer, does not replicate).
    local WorldMods = {
        Fullbright = false,
        FpsBoost   = false,
        -- Lighting changer
        LightingEnabled = false,
        ClockTime = 12,
        Brightness = 2,
        Ambient = Color3.fromRGB(178, 178, 178),
        OutdoorAmbient = Color3.fromRGB(178, 178, 178),
        -- Atmosphere
        AtmosphereEnabled = false,
        AtmoDensity = 0.3,
        AtmoOffset = 0.25,
        AtmoGlare = 0,
        AtmoHaze = 0,
        AtmoColor = Color3.fromRGB(200, 200, 200),
        -- Ambience (post-FX glow + tint; same force-every-frame method as old bloom)
        AmbienceEnabled = false,
        AmbienceColor = Color3.fromRGB(255, 255, 255),
        AmbienceIntensity = 1,
        AmbienceSize = 24,
        AmbienceThreshold = 2,
        AmbienceBrightness = 0.1,
        AmbienceContrast = 0.05,
        AmbienceSaturation = 0.05,
        -- Local
        FovEnabled = false,
        DesiredFov = 90,
        FreecamEnabled = false,
        FreecamSpeed = 50,
        SkyboxName = "Default",
        SkyboxEnabled = false,
    }
    getgenv()._MethaneWorldMods = WorldMods

    do -- Fullbright
        local Lighting = game:GetService('Lighting')
        local _origClock         = Lighting.ClockTime
        local _origBrightness    = Lighting.Brightness
        local _origAmbient       = Lighting.Ambient
        local _origOutdoor       = Lighting.OutdoorAmbient
        local _origFogEnd        = Lighting.FogEnd
        local _origFogStart      = Lighting.FogStart
        local _origFogColor      = Lighting.FogColor
        local _origGlobalShadows = Lighting.GlobalShadows
        local _fbActive = false

        local function setAtmosphereEnabled(enabled)
            pcall(function()
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA('Atmosphere') or v:IsA('BloomEffect')
                        or v:IsA('BlurEffect') or v:IsA('ColorCorrectionEffect')
                        or v:IsA('SunRaysEffect') or v:IsA('DepthOfFieldEffect') then
                        v.Enabled = enabled
                    end
                end
            end)
        end

        local function applyFullbright()
            pcall(function()
                Lighting.ClockTime      = 12
                Lighting.Brightness     = 2
                Lighting.Ambient        = Color3.fromRGB(178, 178, 178)
                Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)
                Lighting.FogEnd         = 100000
                Lighting.FogStart       = 100000
                Lighting.GlobalShadows  = false
            end)
            setAtmosphereEnabled(false)
        end

        local function restoreFullbright()
            pcall(function()
                Lighting.ClockTime      = _origClock
                Lighting.Brightness     = _origBrightness
                Lighting.Ambient        = _origAmbient
                Lighting.OutdoorAmbient = _origOutdoor
                Lighting.FogEnd         = _origFogEnd
                Lighting.FogStart       = _origFogStart
                Lighting.FogColor       = _origFogColor
                Lighting.GlobalShadows  = _origGlobalShadows
            end)
            setAtmosphereEnabled(true)
        end

        -- Only apply/restore on state change or when the map overwrites lighting
        game:GetService('RunService').Heartbeat:Connect(function()
            if WorldMods.Fullbright then
                if not _fbActive then
                    _fbActive = true
                    applyFullbright()
                elseif Lighting.ClockTime ~= 12 or Lighting.GlobalShadows ~= false then
                    applyFullbright()
                end
            else
                if _fbActive then
                    _fbActive = false
                    restoreFullbright()
                end
            end
        end)
    end

    local function __initFpsBoost()
        -- Client-side only: force Plastic + strip SurfaceAppearance / mesh textures.
        -- (setrenderproperty is Drawing-only and does NOT change BasePart.Material)

        local matCache = {}       -- [BasePart] = { Material, MaterialVariant, Reflectance, TextureID? }
        local saCache = {}        -- [SurfaceAppearance] = parent (or true)
        local particleCache = {}  -- effects / decals
        local _qualityOrig = nil
        local _shadowsOrig = nil
        local _techOrig = nil

        local function applyFpsBoost(part)
            if typeof(part) ~= "Instance" then return end
            if not part:IsA("BasePart") then return end
            if matCache[part] then return end

            local snap = {
                Material = part.Material,
                MaterialVariant = "",
                Reflectance = part.Reflectance,
            }
            pcall(function() snap.MaterialVariant = part.MaterialVariant end)
            if part:IsA("MeshPart") then
                pcall(function() snap.TextureID = part.TextureID end)
            end
            matCache[part] = snap

            pcall(function()
                part.Material = Enum.Material.Plastic
                part.MaterialVariant = ""
                part.Reflectance = 0
            end)
            if part:IsA("MeshPart") then
                pcall(function() part.TextureID = "" end)
            end

            -- SurfaceAppearance keeps textures even on Plastic — disable
            pcall(function()
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("SurfaceAppearance") and saCache[ch] == nil then
                        saCache[ch] = ch.Parent
                        ch.Parent = nil
                    end
                end
            end)
        end

        local function muteEffects(inst)
            if typeof(inst) ~= "Instance" then return end
            if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam")
                or inst:IsA("Fire") or inst:IsA("Smoke") or inst:IsA("Sparkles") then
                if particleCache[inst] == nil then
                    particleCache[inst] = inst.Enabled
                end
                pcall(function() inst.Enabled = false end)
            elseif inst:IsA("Decal") or inst:IsA("Texture") then
                if particleCache[inst] == nil then
                    particleCache[inst] = inst.Transparency
                end
                pcall(function() inst.Transparency = 1 end)
            elseif inst:IsA("SurfaceAppearance") then
                if saCache[inst] == nil then
                    saCache[inst] = inst.Parent
                    pcall(function() inst.Parent = nil end)
                end
            end
        end

        local function scanWorkspace()
            if not WorldMods.FpsBoost then return end
            local n = 0
            for _, v in ipairs(workspace:GetDescendants()) do
                pcall(applyFpsBoost, v)
                pcall(muteEffects, v)
                n = n + 1
                if n % 200 == 0 then task.wait() end
            end
            -- Also scan current Camera (viewmodels sometimes parent here briefly)
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then
                    for _, v in ipairs(cam:GetDescendants()) do
                        pcall(applyFpsBoost, v)
                        pcall(muteEffects, v)
                    end
                end
            end)
            pcall(function()
                if _qualityOrig == nil then
                    _qualityOrig = settings().Rendering.QualityLevel
                end
                settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            end)
            pcall(function()
                local Lighting = game:GetService("Lighting")
                if _shadowsOrig == nil then _shadowsOrig = Lighting.GlobalShadows end
                Lighting.GlobalShadows = false
                if _techOrig == nil then
                    pcall(function() _techOrig = Lighting.Technology end)
                end
                pcall(function()
                    Lighting.Technology = Enum.Technology.Voxel
                end)
            end)
        end

        local function restoreAll()
            for part, snap in pairs(matCache) do
                pcall(function()
                    if part and part.Parent then
                        part.Material = snap.Material
                        if snap.MaterialVariant ~= nil then
                            part.MaterialVariant = snap.MaterialVariant
                        end
                        if snap.Reflectance ~= nil then
                            part.Reflectance = snap.Reflectance
                        end
                        if part:IsA("MeshPart") and snap.TextureID ~= nil then
                            part.TextureID = snap.TextureID
                        end
                    end
                end)
            end
            table.clear(matCache)

            for sa, parent in pairs(saCache) do
                pcall(function()
                    if sa and parent then
                        sa.Parent = parent
                    end
                end)
            end
            table.clear(saCache)

            for inst, prev in pairs(particleCache) do
                pcall(function()
                    if not inst or not inst.Parent then return end
                    if inst:IsA("Decal") or inst:IsA("Texture") then
                        inst.Transparency = prev
                    else
                        inst.Enabled = prev
                    end
                end)
            end
            table.clear(particleCache)

            pcall(function()
                if _qualityOrig ~= nil then
                    settings().Rendering.QualityLevel = _qualityOrig
                    _qualityOrig = nil
                end
            end)
            pcall(function()
                local Lighting = game:GetService("Lighting")
                if _shadowsOrig ~= nil then
                    Lighting.GlobalShadows = _shadowsOrig
                    _shadowsOrig = nil
                end
                if _techOrig ~= nil then
                    Lighting.Technology = _techOrig
                    _techOrig = nil
                end
            end)
        end

        task.spawn(function()
            while true do
                task.wait(4)
                if WorldMods.FpsBoost then
                    scanWorkspace()
                end
            end
        end)

        workspace.DescendantAdded:Connect(function(inst)
            if WorldMods.FpsBoost then
                task.defer(function()
                    pcall(applyFpsBoost, inst)
                    pcall(muteEffects, inst)
                end)
            end
        end)

        getgenv()._StrideFpsBoostRestore = restoreAll
        getgenv()._StrideFpsBoostScan = scanWorkspace
    end
    __initFpsBoost()

    local function __initSkybox() -- Skybox (Lighting.Sky + hide/retexture 3D sky meshes)
        local Lighting = game:GetService("Lighting")
        local _skyOrig = nil          -- snapshot of original Sky faces
        local _skyInstOrig = nil      -- original Sky instance ref
        local _hidden3D = {}          -- [BasePart] = {LocalTransparencyModifier or Transparency, CanCollide}
        local _meshTexOrig = {}       -- [MeshPart] = TextureID

        -- Public presets. Tables may use one ID for all faces or per-face.
        local function faces(id)
            local u = "rbxassetid://" .. tostring(id)
            return { Bk = u, Dn = u, Ft = u, Lf = u, Rt = u, Up = u }
        end
        local function faces6(bk, dn, ft, lf, rt, up)
            return {
                Bk = "rbxassetid://" .. bk,
                Dn = "rbxassetid://" .. dn,
                Ft = "rbxassetid://" .. ft,
                Lf = "rbxassetid://" .. lf,
                Rt = "rbxassetid://" .. rt,
                Up = "rbxassetid://" .. up,
            }
        end

        local SKYBOX_PRESETS = {
            ["Default"] = nil, -- restore game sky
            -- Clear blue daytime (classic public 6-face set)
            ["Clear Blue"] = faces6(591058823, 591059876, 591058104, 591057861, 591058104, 591059991),
            ["Cloudy"] = faces(600830446),
            ["Night"] = faces6(12064107, 12064152, 12064121, 12063984, 12064115, 12064131),
            ["Space"] = faces6(149397692, 149397686, 149397697, 149397684, 149397688, 149397702),
            ["Nebula Purple"] = faces(159454299),
            ["Sunset"] = faces(150939022),
            ["Pink Sky"] = faces(271042516),
            ["Anime Boobies"] = faces(1071916213),
            ["Anime Girls"] = faces(1071950721),
            ["Vaporwave"] = faces(1417494030),
            -- Classic mountain/sky set (very old public IDs)
            ["Mountains"] = faces6(1012887, 1012890, 1012886, 1012889, 1012888, 1012891),
            ["Storm"] = faces(151165214),
            ["Empty Black"] = faces(2675785344),
        }

        local function snapshotSky(sky)
            if not sky then return nil end
            local s = {}
            for _, k in ipairs({"SkyboxBk","SkyboxDn","SkyboxFt","SkyboxLf","SkyboxRt","SkyboxUp",
                "CelestialBodiesShown","StarCount","SunAngularSize","MoonAngularSize",
                "SunTextureId","MoonTextureId"}) do
                pcall(function() s[k] = sky[k] end)
            end
            return s
        end

        local function applyFaces(sky, f)
            if not sky or not f then return end
            pcall(function()
                sky.SkyboxBk = f.Bk
                sky.SkyboxDn = f.Dn
                sky.SkyboxFt = f.Ft
                sky.SkyboxLf = f.Lf
                sky.SkyboxRt = f.Rt
                sky.SkyboxUp = f.Up
                sky.CelestialBodiesShown = false
                sky.StarCount = 0
            end)
        end

        local function ensureSky()
            -- Keep a single Sky under Lighting (destroy extras that can override)
            local sky = nil
            for _, ch in ipairs(Lighting:GetChildren()) do
                if ch:IsA("Sky") then
                    if not sky then
                        sky = ch
                    else
                        pcall(function() ch:Destroy() end)
                    end
                end
            end
            if not sky then
                sky = Instance.new("Sky")
                sky.Name = "StrideSky"
                sky.Parent = Lighting
            end
            return sky
        end

        local function hide3DSkyMeshes()
            local keywords = { "sky", "skybox", "skydome", "dome", "atmosphereball", "skysphere" }
            for _, inst in ipairs(workspace:GetDescendants()) do
                pcall(function()
                    if not inst:IsA("BasePart") then return end
                    local n = string.lower(inst.Name)
                    local hit = false
                    for _, kw in ipairs(keywords) do
                        if n == kw or n:find(kw, 1, true) then hit = true break end
                    end
                    -- large inverted/sphere meshes often used as 3D skies
                    if not hit and inst:IsA("MeshPart") then
                        local sz = inst.Size
                        if sz.X > 200 and sz.Y > 200 and sz.Z > 200 then
                            hit = true
                        end
                    end
                    if not hit then return end
                    if _hidden3D[inst] then return end
                    _hidden3D[inst] = {
                        Transparency = inst.Transparency,
                        LocalTransparencyModifier = inst.LocalTransparencyModifier,
                        CastShadow = inst.CastShadow,
                    }
                    inst.LocalTransparencyModifier = 1
                    inst.CastShadow = false
                    if inst:IsA("MeshPart") then
                        _meshTexOrig[inst] = inst.TextureID
                    end
                    for _, ch in ipairs(inst:GetChildren()) do
                        if ch:IsA("Decal") or ch:IsA("Texture") then
                            if _meshTexOrig[ch] == nil then
                                _meshTexOrig[ch] = ch.Transparency
                            end
                            ch.Transparency = 1
                        end
                    end
                end)
            end
        end

        local function restore3DSkyMeshes()
            for part, snap in pairs(_hidden3D) do
                pcall(function()
                    if part and part.Parent then
                        part.Transparency = snap.Transparency
                        part.LocalTransparencyModifier = snap.LocalTransparencyModifier or 0
                        part.CastShadow = snap.CastShadow
                    end
                end)
            end
            table.clear(_hidden3D)
            for inst, prev in pairs(_meshTexOrig) do
                pcall(function()
                    if not inst or not inst.Parent then return end
                    if inst:IsA("MeshPart") then
                        inst.TextureID = prev
                    elseif inst:IsA("Decal") or inst:IsA("Texture") then
                        inst.Transparency = prev
                    end
                end)
            end
            table.clear(_meshTexOrig)
        end

        local function restoreSkybox()
            local sky = ensureSky()
            if _skyOrig then
                for k, v in pairs(_skyOrig) do
                    pcall(function() sky[k] = v end)
                end
            end
            restore3DSkyMeshes()
        end

        local function applySkybox(name)
            name = name or WorldMods.SkyboxName or "Default"
            if name == "Default (Game)" then name = "Default" end
            WorldMods.SkyboxName = name

            local sky = ensureSky()
            if _skyOrig == nil then
                _skyOrig = snapshotSky(sky)
                _skyInstOrig = sky
            end

            if not WorldMods.SkyboxEnabled or name == "Default" or SKYBOX_PRESETS[name] == nil then
                restoreSkybox()
                return
            end

            local preset = SKYBOX_PRESETS[name]
            applyFaces(sky, preset)
            -- Re-parent last so this Sky wins over any game-added Sky
            pcall(function()
                sky.Parent = nil
                sky.Parent = Lighting
            end)
            hide3DSkyMeshes()
        end

        local function setSkyboxEnabled(on)
            WorldMods.SkyboxEnabled = on and true or false
            if WorldMods.SkyboxEnabled then
                applySkybox(WorldMods.SkyboxName)
            else
                restoreSkybox()
            end
        end

        workspace.DescendantAdded:Connect(function(inst)
            if not WorldMods.SkyboxEnabled then return end
            if not WorldMods.SkyboxName or WorldMods.SkyboxName == "Default" then return end
            if typeof(inst) ~= "Instance" or not inst:IsA("BasePart") then return end
            local n = string.lower(inst.Name)
            if not (n:find("sky", 1, true) or n:find("dome", 1, true)) then return end
            task.defer(function()
                pcall(hide3DSkyMeshes)
            end)
        end)

        getgenv()._StrideApplySkybox = applySkybox
        getgenv()._StrideSetSkyboxEnabled = setSkyboxEnabled
        getgenv()._StrideSkyboxNames = (function()
            local t = { "Default" }
            for k in pairs(SKYBOX_PRESETS) do
                if k ~= "Default" then table.insert(t, k) end
            end
            table.sort(t, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a < b
            end)
            return t
        end)()
    end
    __initSkybox()

    -- ==================== END WORLD MODS ====================

        -- ==================== WORLD TAB ====================

    -- Tabs.WorldLighting inlined
    -- register free: was Tabs.WorldLighting
    pcall(function() Tabs.WorldLighting:AddSection("Lighting", ico("sun")) end)
    Tabs.WorldLighting:AddToggle("LightingChanger", {
        Text = "Enabled",
        Default = false,
        Callback = function(v) WorldMods.LightingEnabled = v end,
    })
    Tabs.WorldLighting:AddToggle("AntiSmoke", {
        Text = "Anti smoke", Default = false,
        Callback = function(v) WorldMods.AntiSmoke = v end,
    })
    Tabs.WorldLighting:AddToggle("Fullbright", {
        Text = "Fullbright", Default = false,
        Callback = function(v) WorldMods.Fullbright = v end,
    })
    Tabs.WorldLighting:AddSlider("WMClockTime", {
        Text = "Clock time", Default = 12, Min = 0, Max = 24, Rounding = 1,
        Callback = function(v) WorldMods.ClockTime = v end,
    })
    Tabs.WorldLighting:AddSlider("WMBrightness", {
        Text = "Brightness", Default = 2, Min = 0, Max = 10, Rounding = 1,
        Callback = function(v) WorldMods.Brightness = v end,
    })
    Tabs.WorldLighting:AddLabel("Outdoor"):AddColorPicker("WMOutdoor", {
        Default = WorldMods.OutdoorAmbient or Color3.fromRGB(255, 255, 255),
        Callback = function(v) WorldMods.OutdoorAmbient = v end,
    })
    Tabs.WorldLighting:AddToggle("FpsBoost", {
        Text = "FPS boost", Default = false,
        Callback = function(v) WorldMods.FpsBoost = v end,
    })

    pcall(function() Tabs.WorldLighting:AddDivider() end)
    pcall(function() Tabs.WorldLighting:AddSection("Skybox", ico("image")) end)
    Tabs.WorldLighting:AddToggle("SkyboxEnabled", {
        Text = "Enabled", Default = false,
        Callback = function(v)
            if getgenv()._StrideSetSkyboxEnabled then
                getgenv()._StrideSetSkyboxEnabled(v)
            else
                WorldMods.SkyboxEnabled = v
            end
        end,
    })
    Tabs.WorldLighting:AddDropdown('SkyboxPreset', {
        Text = 'Skybox Preset',
        Values = (getgenv()._StrideSkyboxNames or { 'Default' }),
        Default = 'Default',
        Callback = function(v)
            if type(v) ~= 'string' or v == '' then
                v = 'Default'
            end
            WorldMods.SkyboxName = v
            pcall(function()
                if getgenv()._StrideApplySkybox then
                    getgenv()._StrideApplySkybox(v)
                end
            end)
        end,
    })
    pcall(function()
        task.defer(function()
            if Options.SkyboxPreset and Options.SkyboxPreset.SetValue then
                Options.SkyboxPreset:SetValue('Default')
            end
        end)
    end)

    -- Tabs.WorldAtmosphere inlined
    -- register free: was Tabs.WorldAtmosphere
    pcall(function() Tabs.WorldAtmosphere:AddSection("Atmosphere", ico("cloud")) end)
    Tabs.WorldAtmosphere:AddToggle("AtmosphereChanger", {
        Text = "Enabled", Default = false,
        Callback = function(v) WorldMods.AtmosphereEnabled = v end,
    })
    Tabs.WorldAtmosphere:AddSlider("AtmoDensity", {
        Text = "Density", Default = 0.3, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) WorldMods.AtmoDensity = v end,
    })
    Tabs.WorldAtmosphere:AddSlider("AtmoOffset", {
        Text = "Offset", Default = 0.25, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) WorldMods.AtmoOffset = v end,
    })
    Tabs.WorldAtmosphere:AddSlider("AtmoGlare", {
        Text = "Glare", Default = 0, Min = 0, Max = 10, Rounding = 1,
        Callback = function(v) WorldMods.AtmoGlare = v end,
    })
    Tabs.WorldAtmosphere:AddSlider("AtmoHaze", {
        Text = "Haze", Default = 0, Min = 0, Max = 10, Rounding = 1,
        Callback = function(v) WorldMods.AtmoHaze = v end,
    })
    Tabs.WorldAtmosphere:AddLabel("Color"):AddColorPicker("AtmoColor", {
        Default = WorldMods.AtmoColor,
        Callback = function(v) WorldMods.AtmoColor = v end,
    })

    -- Tabs.WorldAmbience inlined
    -- register free: was Tabs.WorldAmbience
    pcall(function() Tabs.WorldAmbience:AddSection("Ambience", ico("sparkles")) end)
    Tabs.WorldAmbience:AddToggle("AmbienceChanger", {
        Text = "Enabled", Default = false,
        Callback = function(v) WorldMods.AmbienceEnabled = v end,
    })
    Tabs.WorldAmbience:AddLabel("Color"):AddColorPicker("AmbienceColor", {
        Default = WorldMods.AmbienceColor,
        Callback = function(v) WorldMods.AmbienceColor = v end,
    })
    Tabs.WorldAmbience:AddSlider("AmbienceIntensity", {
        Text = "Glow intensity", Default = 1, Min = 0, Max = 5, Rounding = 1,
        Callback = function(v) WorldMods.AmbienceIntensity = v end,
    })
    Tabs.WorldAmbience:AddSlider("AmbienceSize", {
        Text = "Glow size", Default = 24, Min = 0, Max = 80, Rounding = 0,
        Callback = function(v) WorldMods.AmbienceSize = v end,
    })
    Tabs.WorldAmbience:AddSlider("AmbienceThreshold", {
        Text = "Glow threshold", Default = 2, Min = 0, Max = 10, Rounding = 1,
        Callback = function(v) WorldMods.AmbienceThreshold = v end,
    })
    Tabs.WorldAmbience:AddSlider("AmbienceBrightness", {
        Text = "Brightness", Default = 0.1, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) WorldMods.AmbienceBrightness = v end,
    })
    Tabs.WorldAmbience:AddSlider("AmbienceContrast", {
        Text = "Contrast", Default = 0.05, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) WorldMods.AmbienceContrast = v end,
    })
    Tabs.WorldAmbience:AddSlider("AmbienceSaturation", {
        Text = "Saturation", Default = 0.05, Min = -1, Max = 1, Rounding = 2,
        Callback = function(v) WorldMods.AmbienceSaturation = v end,
    })

        local LocalTab = Tabs.WorldLocal
    pcall(function() LocalTab:AddSection("FOV Changer", ico("scan")) end)
    LocalTab:AddToggle("FovChanger", {
        Text = "Enabled", Default = false,
        Callback = function(v) WorldMods.FovEnabled = v end,
    })
    LocalTab:AddSlider("DesiredFov", {
        Text = "FOV", Default = 90, Min = 30, Max = 120, Rounding = 0, Suffix = "°",
        Callback = function(v) WorldMods.DesiredFov = v end,
    })

    pcall(function() LocalTab:AddDivider() end)
    pcall(function() LocalTab:AddSection("Freecam", ico("video")) end)
    LocalTab:AddToggle("FreecamEnabled", {
        Text = "Enabled", Default = false,
        Callback = function(v) WorldMods.FreecamEnabled = v end,
    }):AddKeyPicker("FreecamKey", {
        Default = "None", Text = "Freecam Key", Mode = "Toggle",
    })
    LocalTab:AddSlider("FreecamSpeed", {
        Text = "Speed", Default = 50, Min = 10, Max = 200, Rounding = 0,
        Callback = function(v) WorldMods.FreecamSpeed = v end,
    })

    
    -- ==================== 3RD PERSON ====================
    pcall(function() LocalTab:AddDivider() end)
    pcall(function() LocalTab:AddSection("3rd Person", ico("user")) end)
    LocalTab:AddToggle('ThirdPersonEnabled', {
        Text = 'Enabled',
        Default = false,
        Callback = function(v)
            settings.ThirdPersonEnabled = v == true
            if not v then
                pcall(function()
                    local stop = getgenv()._MethaneStopThirdPerson
                    if type(stop) == "function" then stop() end
                end)
            end
        end
    }):AddKeyPicker('ThirdPersonKey', {
        Default = 'None', Text = '3rd Person', Mode = 'Toggle',
    })
    LocalTab:AddSlider('ThirdPersonDist', {
        Text = 'Camera Distance',
        Default = 10, Min = 3, Max = 30, Rounding = 0,
        Callback = function(v) settings.ThirdPersonDist = v end
    })

-- ==================== VIEWMODEL CHAMS (local FP arms + gun) ====================
    -- Finds O1 local viewmodels via StateObject.values.viewmodels + CurrentCamera.
    -- Hides original meshes and overlays BoxHandleAdornment (arms / weapon split).
    local ViewmodelChams = {
        ArmsEnabled = false,
        ArmsColor = Color3.fromRGB(255, 255, 255),
        ArmsMat = "ForceField",
        ArmsTrans = 0.3,
        WeaponEnabled = false,
        WeaponColor = Color3.fromRGB(255, 255, 255),
        WeaponMat = "ForceField",
        WeaponTrans = 0.3,
        ModelEnabled = false,
        ModelColor = Color3.fromRGB(255, 255, 255),
        ModelMat = "ForceField",
        ModelTrans = 0.3,
    }
    getgenv()._MethaneViewmodelChams = ViewmodelChams

    local MATS = { "ForceField", "Neon", "Glass", "SmoothPlastic", "Plastic", "Metal", "Foil", "Ice" }

    pcall(function() LocalTab:AddDivider() end)
    pcall(function() LocalTab:AddSection("Arm Chams") end)
    LocalTab:AddToggle("VmArmsEnabled", {
        Text = "Enabled", Default = false,
        Callback = function(v)
            ViewmodelChams.ArmsEnabled = v == true
            if not v and not ViewmodelChams.WeaponEnabled then
                pcall(function()
                    if getgenv()._MethaneRestoreVmChams then getgenv()._MethaneRestoreVmChams() end
                end)
            end
        end,
    })
    LocalTab:AddColorPicker("VmArmsColor", {
        Text = "Color",
        Default = ViewmodelChams.ArmsColor,
        Callback = function(v) ViewmodelChams.ArmsColor = v end,
    })
    LocalTab:AddDropdown("VmArmsMat", {
        Text = "Material",
        Values = MATS,
        Default = "ForceField",
        Callback = function(v) ViewmodelChams.ArmsMat = tostring(v or "ForceField") end,
    })
    LocalTab:AddSlider("VmArmsTrans", {
        Text = "Transparency", Default = 0.3, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) ViewmodelChams.ArmsTrans = v end,
    })

    pcall(function() LocalTab:AddSection("Weapon Chams") end)
    LocalTab:AddToggle("VmWeaponEnabled", {
        Text = "Enabled", Default = false,
        Callback = function(v)
            ViewmodelChams.WeaponEnabled = v == true
            if not v and not ViewmodelChams.ArmsEnabled then
                pcall(function()
                    if getgenv()._MethaneRestoreVmChams then getgenv()._MethaneRestoreVmChams() end
                end)
            end
        end,
    })
    LocalTab:AddColorPicker("VmWeaponColor", {
        Text = "Color",
        Default = ViewmodelChams.WeaponColor,
        Callback = function(v) ViewmodelChams.WeaponColor = v end,
    })
    LocalTab:AddDropdown("VmWeaponMat", {
        Text = "Material",
        Values = MATS,
        Default = "ForceField",
        Callback = function(v) ViewmodelChams.WeaponMat = tostring(v or "ForceField") end,
    })
    LocalTab:AddSlider("VmWeaponTrans", {
        Text = "Transparency", Default = 0.3, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) ViewmodelChams.WeaponTrans = v end,
    })

    -- 3rd person full body chams
    pcall(function() LocalTab:AddSection("Model Chams") end)
    LocalTab:AddToggle("ModelChamsEnabled", {
        Text = "Enabled", Default = false,
        Callback = function(v)
            ViewmodelChams.ModelEnabled = v == true
            if not v then
                pcall(function()
                    if getgenv()._MethaneRestoreModelChams then getgenv()._MethaneRestoreModelChams() end
                end)
            end
        end,
    })
    LocalTab:AddColorPicker("ModelChamsColor", {
        Text = "Color",
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) ViewmodelChams.ModelColor = v end,
    })
    LocalTab:AddDropdown("ModelChamsMat", {
        Text = "Material",
        Values = MATS,
        Default = "ForceField",
        Callback = function(v) ViewmodelChams.ModelMat = tostring(v or "ForceField") end,
    })
    LocalTab:AddSlider("ModelChamsTrans", {
        Text = "Transparency", Default = 0.3, Min = 0, Max = 1, Rounding = 2,
        Callback = function(v) ViewmodelChams.ModelTrans = v end,
    })

    local function __initViewmodelChams()
        -- strong refs so restore always works (weak keys were dropping entries)
        local _orig = {}
        local _painted = {}

        local function matFromName(name)
            local ok, m = pcall(function() return Enum.Material[tostring(name or "ForceField")] end)
            if ok and m then return m end
            return Enum.Material.ForceField
        end

        local ARM_EXACT = {
            arm1 = true, arm2 = true, shoulder1 = true, shoulder2 = true,
            lefthand = true, righthand = true, leftarm = true, rightarm = true,
            leftupperarm = true, rightupperarm = true, leftlowerarm = true, rightlowerarm = true,
            ["left arm"] = true, ["right arm"] = true, ["left hand"] = true, ["right hand"] = true,
        }
        local function isArmName(n)
            n = string.lower(tostring(n or ""))
            if ARM_EXACT[n] then return true end
            -- never treat gun parts as arms (handle/handguard contain "hand")
            if n:find("handle", 1, true) or n:find("handguard", 1, true) or n:find("handheld", 1, true) then
                return false
            end
            if n:find("glove", 1, true) or n:find("finger", 1, true) or n:find("sleeve", 1, true) then
                return true
            end
            if n:find("shoulder", 1, true) then return true end
            if n:find("arm", 1, true) and not n:find("charm", 1, true) and not n:find("armor", 1, true) then
                return true
            end
            -- exact-ish hands only
            if n == "hand" or n:find("lefthand", 1, true) or n:find("righthand", 1, true)
                or n:find("left_hand", 1, true) or n:find("right_hand", 1, true)
                or n:find("left hand", 1, true) or n:find("right hand", 1, true) then
                return true
            end
            return false
        end
        local function isGunName(n)
            n = string.lower(tostring(n or ""))
            return n:find("weapon", 1, true) or n:find("gun", 1, true) or n:find("knife", 1, true)
                or n:find("blade", 1, true) or n:find("sight", 1, true) or n:find("mag", 1, true)
                or n:find("barrel", 1, true) or n:find("stock", 1, true) or n:find("receiver", 1, true)
                or n:find("muzzle", 1, true) or n:find("rail", 1, true) or n:find("grip", 1, true)
                or n:find("optic", 1, true) or n:find("scope", 1, true) or n:find("charm", 1, true)
                or n:find("attach", 1, true) or n:find("skin", 1, true) or n:find("camo", 1, true)
                or n:find("laser", 1, true) or n:find("flash", 1, true) or n:find("suppress", 1, true)
                or n:find("silencer", 1, true) or n:find("compensat", 1, true) or n:find("muzzlebrake", 1, true)
                or n:find("iron", 1, true) or n:find("mount", 1, true) or n:find("handle", 1, true)
                or n:find("handguard", 1, true) or n:find("bolt", 1, true) or n:find("slide", 1, true)
                or n:find("trigger", 1, true) or n:find("chamber", 1, true) or n:find("eject", 1, true)
                or n:find("finish", 1, true) or n:find("sticker", 1, true) or n:find("wrap", 1, true)
                or n:find("glass", 1, true) or n:find("lens", 1, true) or n:find("reticle", 1, true)
                or n:find("ammo", 1, true) or n:find("clip", 1, true) or n:find("drum", 1, true)
                or n:find("pistol", 1, true) or n:find("rifle", 1, true) or n:find("smg", 1, true)
                or n:find("shotgun", 1, true) or n:find("sniper", 1, true)
        end
        local function isBodyIgnore(n)
            n = string.lower(tostring(n or ""))
            return n == "head" or n == "torso" or n == "hip1" or n == "hip2"
                or n == "leg1" or n == "leg2" or n == "humanoidrootpart"
                or n:find("leg", 1, true) or n:find("foot", 1, true) or n:find("toe", 1, true)
        end

        local function classify(part, root)
            if not part or not part:IsA("BasePart") then return nil end
            -- part name first: attachments/skins/charms always weapon
            local pn = part.Name
            if isGunName(pn) then return "gun" end
            if isBodyIgnore(pn) then return nil end
            if isArmName(pn) then return "arm" end
            local cur = part.Parent
            while cur and cur ~= root do
                local n = cur.Name
                if isGunName(n) then return "gun" end
                if isBodyIgnore(n) then return nil end
                if isArmName(n) then return "arm" end
                cur = cur.Parent
            end
            -- default MeshParts under FP viewmodel are weapon geometry (skins/charms)
            return "gun"
        end

        local function destroyAdorns(part)
            pcall(function()
                for _, ch in ipairs(part:GetChildren()) do
                    if ch.Name == "_MethaneVmAdorn" or ch.Name == "_MethaneVmCham" then
                        ch:Destroy()
                    end
                end
            end)
        end

        -- capture virgin look once, before any of our edits
        local function storeOrig(part)
            if _orig[part] then return end
            local s = {
                Color = part.Color,
                Material = part.Material,
                MaterialVariant = "",
                Transparency = part.Transparency,
                LTM = 0,
                TextureID = nil,
                Reflectance = 0,
                surfaces = {},
                decals = {},
                meshes = {},
            }
            pcall(function() s.MaterialVariant = part.MaterialVariant end)
            pcall(function() s.LTM = part.LocalTransparencyModifier end)
            pcall(function() s.Reflectance = part.Reflectance end)
            pcall(function()
                if part:IsA("MeshPart") then s.TextureID = part.TextureID end
            end)
            pcall(function()
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("SurfaceAppearance") then
                        -- keep instance alive; reparent on restore
                        table.insert(s.surfaces, ch)
                    elseif ch:IsA("Decal") or ch:IsA("Texture") then
                        table.insert(s.decals, { obj = ch, Transparency = ch.Transparency })
                    elseif ch:IsA("SpecialMesh") then
                        table.insert(s.meshes, { obj = ch, TextureId = ch.TextureId })
                    end
                end
            end)
            _orig[part] = s
        end

        local function stripLooks(part, s)
            -- skins/attachments re-apply textures every frame — always clear them
            pcall(function()
                if part:IsA("MeshPart") then
                    part.TextureID = ""
                    pcall(function() part.MaterialVariant = "" end)
                    pcall(function() part.DoubleSided = true end)
                end
                pcall(function() part.MaterialVariant = "" end)
                pcall(function() part.Reflectance = 0 end)

                -- live children (SurfaceAppearance may be re-added by skin scripts)
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("SurfaceAppearance") then
                        if s and s.surfaces then
                            local already = false
                            for _, old in ipairs(s.surfaces) do
                                if old == ch then already = true break end
                            end
                            if not already then table.insert(s.surfaces, ch) end
                        end
                        pcall(function() ch.Parent = nil end)
                    elseif ch:IsA("Decal") or ch:IsA("Texture") then
                        pcall(function() ch.Transparency = 1 end)
                    elseif ch:IsA("SpecialMesh") then
                        pcall(function() ch.TextureId = "" end)
                    elseif ch:IsA("WrapLayer") or ch:IsA("WrapTarget") or ch:IsA("WrapDeformer") then
                        pcall(function() ch.Enabled = false end)
                    end
                end
                -- stored refs
                if s then
                    for _, ch in ipairs(s.surfaces or {}) do
                        pcall(function() if ch and ch.Parent then ch.Parent = nil end end)
                    end
                    for _, d in ipairs(s.decals or {}) do
                        pcall(function() if d.obj then d.obj.Transparency = 1 end end)
                    end
                    for _, m in ipairs(s.meshes or {}) do
                        pcall(function() if m.obj then m.obj.TextureId = "" end end)
                    end
                end
            end)
        end

        local function restorePart(part)
            if not part then return end
            destroyAdorns(part)
            local s = _orig[part]
            if not s then
                _painted[part] = nil
                return
            end
            pcall(function()
                part.Color = s.Color
                part.Material = s.Material
                pcall(function() part.MaterialVariant = s.MaterialVariant or "" end)
                part.Transparency = s.Transparency
                part.LocalTransparencyModifier = s.LTM or 0
                pcall(function() part.Reflectance = s.Reflectance or 0 end)
                if part:IsA("MeshPart") then
                    part.TextureID = s.TextureID or ""
                end
                for _, ch in ipairs(s.surfaces or {}) do
                    pcall(function()
                        if ch then ch.Parent = part end
                    end)
                end
                for _, d in ipairs(s.decals or {}) do
                    pcall(function()
                        if d.obj then d.obj.Transparency = d.Transparency end
                    end)
                end
                for _, m in ipairs(s.meshes or {}) do
                    pcall(function()
                        if m.obj then m.obj.TextureId = m.TextureId end
                    end)
                end
            end)
            _orig[part] = nil
            _painted[part] = nil
        end

        local function restoreAll()
            local parts = {}
            for part in pairs(_orig) do table.insert(parts, part) end
            for part in pairs(_painted) do table.insert(parts, part) end
            for _, part in ipairs(parts) do
                restorePart(part)
            end
            -- second pass next frame in case game overwrote mid-restore
            task.defer(function()
                for _, part in ipairs(parts) do
                    if part and part.Parent and _orig[part] then
                        restorePart(part)
                    end
                end
            end)
        end

        local function paint(part, col, matName, trans, kind)
            storeOrig(part)
            local s = _orig[part]
            destroyAdorns(part)
            local tt = math.clamp(tonumber(trans) or 0, 0, 0.92)
            -- WEAPON: non-destructive. Stripping TextureID/SurfaceAppearance breaks
            -- custom skins, scopes, and Unlock-All attachments (double-scope / no reload).
            -- ARMS: full strip is fine (no attachment system on arms).
            if kind == "gun" then
                pcall(function()
                    part.LocalTransparencyModifier = 0
                    part.Color = col
                    part.Material = matFromName(matName)
                    -- keep TextureID, SurfaceAppearance, MaterialVariant, mesh textures
                    if part.Transparency < 0.99 then
                        part.Transparency = math.min(part.Transparency, tt)
                    end
                end)
            else
                stripLooks(part, s)
                pcall(function()
                    part.LocalTransparencyModifier = 0
                    part.Color = col
                    part.Material = matFromName(matName)
                    pcall(function() part.MaterialVariant = "" end)
                    part.Transparency = tt
                    pcall(function() part.Reflectance = 0 end)
                    if part:IsA("MeshPart") then
                        part.TextureID = ""
                        pcall(function() part.DoubleSided = true end)
                    end
                end)
            end
            _painted[part] = kind or true
        end

        local function addRoot(list, inst)
            if not inst then return end
            for _, r in ipairs(list) do
                if r == inst then return end
            end
            table.insert(list, inst)
        end

        local function collectRoots()
            local roots = {}
            local cam = workspace.CurrentCamera
            if cam then
                for _, ch in ipairs(cam:GetChildren()) do
                    addRoot(roots, ch)
                end
            end
            for _, name in ipairs({
                "LocalViewmodel", "Viewmodel", "ViewModel", "FPViewmodel",
                "CameraViewmodel", "Arms", "ViewModels", "FirstPerson",
            }) do
                addRoot(roots, workspace:FindFirstChild(name))
                if cam then addRoot(roots, cam:FindFirstChild(name)) end
            end
            pcall(function()
                local SO = getgenv()._StrideStateObject
                if not SO then
                    SO = require(cloneref(game:GetService("ReplicatedStorage")).Modules.StateObject)
                    getgenv()._StrideStateObject = SO
                end
                if SO and SO.get_all then
                    for _, character in SO.get_all("Character") do
                        local owner = character.owner and character.owner:get()
                        if owner == LocalPlayer then
                            local vm = character.values and character.values.viewmodels
                            if vm then addRoot(roots, vm) end
                            local vals = character.values
                            if type(vals) == "table" then
                                for k, v in pairs(vals) do
                                    local kn = string.lower(tostring(k))
                                    if typeof(v) == "Instance" and (
                                        kn:find("view", 1, true) or kn:find("arm", 1, true)
                                        or kn:find("weapon", 1, true) or kn:find("gun", 1, true)
                                        or kn:find("hand", 1, true)
                                    ) then
                                        addRoot(roots, v)
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            pcall(function()
                local ch = LocalPlayer and LocalPlayer.Character
                if ch then addRoot(roots, ch) end
            end)
            -- Always include O1 LocalViewmodel + every child model (skins/attachments reparent here)
            pcall(function()
                local vms = workspace:FindFirstChild("Viewmodels")
                local lv = vms and vms:FindFirstChild("LocalViewmodel")
                if lv then
                    addRoot(roots, lv)
                    for _, ch in ipairs(lv:GetChildren()) do
                        addRoot(roots, ch)
                    end
                end
            end)
            return roots
        end

        local function iterParts(root, out)
            if not root then return end
            if root:IsA("BasePart") then table.insert(out, root) end
            local ok, descs = pcall(function() return root:GetDescendants() end)
            if not ok then return end
            for _, d in ipairs(descs) do
                if d:IsA("BasePart") then table.insert(out, d) end
            end
        end

        local function thirdPersonActiveVm()
            local on = false
            pcall(function()
                if type(settings) == "table" and settings.ThirdPersonEnabled == true then
                    on = true
                end
            end)
            if getgenv()._MethaneThirdPersonKeyOn == true then on = true end
            if getgenv()._MethaneTpActive == true then on = true end
            return on
        end

        local function hideCameraViewmodel()
            -- FP arms/gun under camera must not show over body model chams
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                for _, d in ipairs(cam:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.LocalTransparencyModifier = 1
                    elseif d:IsA("Decal") or d:IsA("Texture") then
                        d.Transparency = 1
                    end
                end
            end)
        end

        local function applyVmChams()
            local cfg = ViewmodelChams
            -- never paint FP viewmodel while 3rd person is on (avoids fighting model chams)
            if thirdPersonActiveVm() then
                restoreAll()
                hideCameraViewmodel()
                return
            end
            if not cfg.ArmsEnabled and not cfg.WeaponEnabled then
                restoreAll()
                return
            end

            local stillNeeded = {}
            for _, root in ipairs(collectRoots()) do
                local parts = {}
                iterParts(root, parts)
                for _, part in ipairs(parts) do
                    if part.Size.Magnitude > 100 then continue end
                    local kind = classify(part, root)
                    -- MeshParts under LocalViewmodel with no classify still get gun paint when weapons on
                    if kind == nil and cfg.WeaponEnabled and part:IsA("MeshPart") then
                        local underLv = false
                        pcall(function()
                            local lv = workspace:FindFirstChild("Viewmodels")
                            lv = lv and lv:FindFirstChild("LocalViewmodel")
                            if lv and part:IsDescendantOf(lv) then underLv = true end
                        end)
                        if underLv and not isBodyIgnore(part.Name) and not isArmName(part.Name) then
                            kind = "gun"
                        end
                    end
                    if kind == "arm" and cfg.ArmsEnabled then
                        paint(part, cfg.ArmsColor, cfg.ArmsMat, cfg.ArmsTrans, "arm")
                        stillNeeded[part] = true
                    elseif kind == "gun" and cfg.WeaponEnabled then
                        paint(part, cfg.WeaponColor, cfg.WeaponMat, cfg.WeaponTrans, "gun")
                        stillNeeded[part] = true
                    end
                end
            end
            local toRestore = {}
            for part in pairs(_painted) do
                if not stillNeeded[part] then
                    table.insert(toRestore, part)
                end
            end
            for _, part in ipairs(toRestore) do
                restorePart(part)
            end
        end

        local wasOn = false
        RunService.RenderStepped:Connect(function()
            -- Do not apply viewmodel chams until player is in-round.
            -- Painting viewmodel parts during the loadout screen breaks the
            -- gun/camera state when the round actually loads.
            local vms = workspace:FindFirstChild("Viewmodels")
            local lv = vms and vms:FindFirstChild("LocalViewmodel")
            if not lv then
                if wasOn then
                    wasOn = false
                    pcall(restoreAll)
                end
                return
            end

            -- FP viewmodel chams only in first person
            local on = (ViewmodelChams.ArmsEnabled == true or ViewmodelChams.WeaponEnabled == true)
                and not thirdPersonActiveVm()
            if thirdPersonActiveVm() then
                if wasOn then
                    wasOn = false
                    pcall(restoreAll)
                end
                hideCameraViewmodel()
                return
            end
            if on then
                wasOn = true
                pcall(applyVmChams)
            elseif wasOn then
                wasOn = false
                pcall(restoreAll)
                -- extra frames to beat game scripts that repaint
                task.defer(function() pcall(restoreAll) end)
                task.delay(0.05, function() pcall(restoreAll) end)
                task.delay(0.15, function() pcall(restoreAll) end)
            end
        end)

        -- also restore immediately when toggles turn off
        pcall(function()
            local prevA, prevW = false, false
            RunService.Heartbeat:Connect(function()
                local a = ViewmodelChams.ArmsEnabled == true
                local w = ViewmodelChams.WeaponEnabled == true
                if (prevA or prevW) and not a and not w then
                    pcall(restoreAll)
                end
                prevA, prevW = a, w
            end)
        end)

        pcall(function()
            local function hookCam(cam)
                if not cam then return end
                cam.ChildAdded:Connect(function()
                    task.defer(function()
                        if ViewmodelChams.ArmsEnabled or ViewmodelChams.WeaponEnabled then
                            pcall(applyVmChams)
                        end
                    end)
                end)
            end
            hookCam(workspace.CurrentCamera)
            workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
                hookCam(workspace.CurrentCamera)
            end)
        end)

        -- New attachments/skins under LocalViewmodel: drop stale orig snapshots so
        -- toggling chams off restores the CURRENT custom skin, not the default gun.
        pcall(function()
            local function watchLv(lv)
                if not lv or lv:GetAttribute("_MethaneVmChamWatch") then return end
                lv:SetAttribute("_MethaneVmChamWatch", true)
                lv.DescendantAdded:Connect(function(inst)
                    if not inst:IsA("BasePart") then return end
                    _orig[inst] = nil
                    _painted[inst] = nil
                    -- also forget parent gun meshes that often get re-textured
                    pcall(function()
                        local p = inst.Parent
                        for _ = 1, 4 do
                            if not p or p == lv then break end
                            if p:IsA("BasePart") then
                                _orig[p] = nil
                                _painted[p] = nil
                            end
                            p = p.Parent
                        end
                    end)
                end)
            end
            local function tryWatch()
                local vms = workspace:FindFirstChild("Viewmodels")
                local lv = vms and vms:FindFirstChild("LocalViewmodel")
                if lv then watchLv(lv) end
            end
            tryWatch()
            local vms = workspace:FindFirstChild("Viewmodels")
            if vms then
                vms.ChildAdded:Connect(function(ch)
                    if ch.Name == "LocalViewmodel" then
                        task.defer(function() watchLv(ch) end)
                    end
                end)
            end
            RunService.Heartbeat:Connect(function()
                -- cheap re-watch if folder recreated
                if math.random() > 0.98 then tryWatch() end
            end)
        end)

        getgenv()._MethaneApplyVmChams = applyVmChams
        getgenv()._MethaneRestoreVmChams = restoreAll
    end
    __initViewmodelChams()

    -- Model Chams: local 3rd-person body (O1 viewmodels + visible character meshes only)
    local function __initModelChams()
        local _orig = {}
        local _painted = {}

        local function matFromName(name)
            local ok, m = pcall(function() return Enum.Material[tostring(name or "ForceField")] end)
            if ok and m then return m end
            return Enum.Material.ForceField
        end

        local function storeOrig(part)
            if _orig[part] then return end
            local s = {
                Color = part.Color,
                Material = part.Material,
                MaterialVariant = "",
                Transparency = part.Transparency,
                LTM = 0,
                TextureID = nil,
                Reflectance = 0,
                surfaces = {},
                decals = {},
                meshes = {},
            }
            pcall(function() s.MaterialVariant = part.MaterialVariant end)
            pcall(function() s.LTM = part.LocalTransparencyModifier end)
            pcall(function() s.Reflectance = part.Reflectance end)
            pcall(function()
                if part:IsA("MeshPart") then s.TextureID = part.TextureID end
            end)
            pcall(function()
                for _, ch in ipairs(part:GetChildren()) do
                    if ch:IsA("SurfaceAppearance") then
                        table.insert(s.surfaces, ch)
                    elseif ch:IsA("Decal") or ch:IsA("Texture") then
                        table.insert(s.decals, { obj = ch, Transparency = ch.Transparency })
                    elseif ch:IsA("SpecialMesh") then
                        table.insert(s.meshes, { obj = ch, TextureId = ch.TextureId })
                    end
                end
            end)
            _orig[part] = s
        end

        local function stripLooks(part, s)
            pcall(function()
                if part:IsA("MeshPart") then part.TextureID = "" end
                for _, ch in ipairs(s.surfaces or {}) do
                    pcall(function() ch.Parent = nil end)
                end
                for _, d in ipairs(s.decals or {}) do
                    pcall(function() if d.obj then d.obj.Transparency = 1 end end)
                end
                for _, m in ipairs(s.meshes or {}) do
                    pcall(function() if m.obj then m.obj.TextureId = "" end end)
                end
            end)
        end

        local function restorePart(part)
            if not part then return end
            local s = _orig[part]
            if not s then
                _painted[part] = nil
                return
            end
            pcall(function()
                part.Color = s.Color
                part.Material = s.Material
                pcall(function() part.MaterialVariant = s.MaterialVariant or "" end)
                part.Transparency = s.Transparency
                part.LocalTransparencyModifier = s.LTM or 0
                pcall(function() part.Reflectance = s.Reflectance or 0 end)
                if part:IsA("MeshPart") then
                    part.TextureID = s.TextureID or ""
                end
                for _, ch in ipairs(s.surfaces or {}) do
                    pcall(function() if ch then ch.Parent = part end end)
                end
                for _, d in ipairs(s.decals or {}) do
                    pcall(function() if d.obj then d.obj.Transparency = d.Transparency end end)
                end
                for _, m in ipairs(s.meshes or {}) do
                    pcall(function() if m.obj then m.obj.TextureId = m.TextureId end end)
                end
            end)
            _orig[part] = nil
            _painted[part] = nil
        end

        local function restoreAll()
            local parts = {}
            for part in pairs(_orig) do table.insert(parts, part) end
            for part in pairs(_painted) do table.insert(parts, part) end
            for _, part in ipairs(parts) do
                restorePart(part)
            end
            task.defer(function()
                for _, part in ipairs(parts) do
                    if part and part.Parent and _orig[part] then restorePart(part) end
                end
            end)
        end

        local function paint(part, col, matName, trans)
            local first = _orig[part] == nil
            storeOrig(part)
            local s = _orig[part]
            if first and s then stripLooks(part, s) end
            local t = math.clamp(tonumber(trans) or 0, 0, 1)
            local baseT = s and s.Transparency or 0
            -- keep originally-hidden parts hidden; never force invisible hitboxes visible
            if baseT >= 0.99 then
                return
            end
            pcall(function()
                part.Color = col
                part.Material = matFromName(matName)
                pcall(function() part.MaterialVariant = "" end)
                part.Transparency = math.max(t, baseT)
                -- do not force LTM to 0 if the game had the part locally hidden
                local ltm = s and s.LTM or 0
                if ltm < 0.9 then
                    part.LocalTransparencyModifier = 0
                end
            end)
            _painted[part] = true
        end

        -- O1 body part names on values.viewmodels
        local BODY_NAMES = {
            head = true, torso = true,
            shoulder1 = true, shoulder2 = true,
            arm1 = true, arm2 = true,
            hip1 = true, hip2 = true,
            leg1 = true, leg2 = true,
        }
        local function isBodyPartName(n)
            n = string.lower(tostring(n or ""))
            if BODY_NAMES[n] then return true end
            if n:find("arm", 1, true) or n:find("hand", 1, true) or n:find("leg", 1, true)
                or n:find("foot", 1, true) or n:find("head", 1, true) or n:find("torso", 1, true)
                or n:find("upper", 1, true) or n:find("lower", 1, true) or n:find("hip", 1, true)
                or n:find("shoulder", 1, true) then
                return true
            end
            return false
        end

        local function shouldSkip(part)
            if not part or not part:IsA("BasePart") then return true end
            local n = string.lower(part.Name)
            if n == "humanoidrootpart" or n == "rootpart" or n == "handle" then return true end
            if part.Size.Magnitude > 40 then return true end
            if part.Size.Magnitude < 0.05 then return true end
            -- skip parts that are already fully invisible (hitboxes / FP hidden)
            if part.Transparency >= 0.99 then return true end
            pcall(function()
                if part.LocalTransparencyModifier >= 0.99 then
                    -- still allow if it's a known body mesh name (3rd person may use LTM)
                end
            end)
            return false
        end

        local function addRoot(list, inst)
            if not inst then return end
            for _, r in ipairs(list) do
                if r == inst then return end
            end
            table.insert(list, inst)
        end

        local function collectBodyRoots()
            local roots = {}
            -- 1) O1 StateObject local viewmodels = real 3rd person body
            pcall(function()
                local SO = getgenv()._StrideStateObject
                if not SO then
                    SO = require(cloneref(game:GetService("ReplicatedStorage")).Modules.StateObject)
                    getgenv()._StrideStateObject = SO
                end
                if SO and SO.get_all then
                    for _, character in SO.get_all("Character") do
                        local owner = character.owner and character.owner:get()
                        if owner == LocalPlayer then
                            local vm = character.values and character.values.viewmodels
                            if vm then addRoot(roots, vm) end
                        end
                    end
                end
            end)
            -- 2) LocalPlayer.Character as fallback (visible meshes only)
            pcall(function()
                local ch = LocalPlayer and LocalPlayer.Character
                if ch then addRoot(roots, ch) end
            end)
            return roots
        end

        local function isEligible(part, root)
            if not part or not part:IsA("BasePart") then return false end
            local n = string.lower(tostring(part.Name or ""))
            -- never paint physics root
            if n == "humanoidrootpart" or n == "rootpart" then return false end
            if part.Size.Magnitude > 80 or part.Size.Magnitude < 0.02 then return false end
            -- skip only fully invisible non-mesh hitboxes (skins may start near-transparent)
            if part.Transparency >= 0.99 and not part:IsA("MeshPart") then return false end
            -- paint everything visible under the body root (limbs + held gun meshes)
            if part:IsA("MeshPart") or part:IsA("UnionOperation") or part:IsA("Part") then
                return true
            end
            return true
        end

        local function thirdPersonActive()
            local on = false
            pcall(function()
                if type(settings) == "table" and settings.ThirdPersonEnabled == true then
                    on = true
                end
            end)
            if getgenv()._MethaneThirdPersonKeyOn == true then on = true end
            if getgenv()._MethaneTpActive == true then on = true end
            return on
        end

        local function applyModelChams()
            local cfg = ViewmodelChams
            -- Model chams only while 3rd person is active (same as Bloxstrike)
            -- so FP hand/gun viewmodel chams are never touched by body paint.
            if not cfg.ModelEnabled or not thirdPersonActive() then
                restoreAll()
                return
            end
            local still = {}
            for _, root in ipairs(collectBodyRoots()) do
                local list = {}
                if root:IsA("BasePart") then table.insert(list, root) end
                local ok, descs = pcall(function() return root:GetDescendants() end)
                if ok then
                    for _, d in ipairs(descs) do
                        if d:IsA("BasePart") then table.insert(list, d) end
                    end
                end
                for _, part in ipairs(list) do
                    if isEligible(part, root) then
                        paint(part, cfg.ModelColor, cfg.ModelMat, cfg.ModelTrans)
                        still[part] = true
                    end
                end
            end
            local toRestore = {}
            for part in pairs(_painted) do
                if not still[part] then table.insert(toRestore, part) end
            end
            for _, part in ipairs(toRestore) do
                restorePart(part)
            end
            -- kill leftover FP viewmodel under camera so it can't poke through body chams
            pcall(function()
                local cam = workspace.CurrentCamera
                if not cam then return end
                for _, d in ipairs(cam:GetDescendants()) do
                    if d:IsA("BasePart") then
                        d.LocalTransparencyModifier = 1
                    end
                end
            end)
        end

        local wasOn = false
        RunService.RenderStepped:Connect(function()
            -- Do not apply model chams until player is in-round.
            local vms = workspace:FindFirstChild("Viewmodels")
            local lv = vms and vms:FindFirstChild("LocalViewmodel")
            if not lv then
                if wasOn then
                    wasOn = false
                    pcall(restoreAll)
                end
                return
            end

            local on = ViewmodelChams.ModelEnabled == true and thirdPersonActive()
            if on then
                wasOn = true
                pcall(applyModelChams)
            elseif wasOn then
                wasOn = false
                pcall(restoreAll)
                task.defer(function() pcall(restoreAll) end)
                task.delay(0.05, function() pcall(restoreAll) end)
                task.delay(0.15, function() pcall(restoreAll) end)
            end
        end)

        getgenv()._MethaneApplyModelChams = applyModelChams
        getgenv()._MethaneRestoreModelChams = restoreAll
    end
    __initModelChams()

    -- ==================== UNLOCK ALL ====================
    -- Hardened architecture v2 — delay-ban resistant:
    --
    -- [1] Data.owned metatable — client-local __index intercept only.
    --     force_update("owned") never called — server ban path.
    --
    -- [2] Data.classes metatable — same approach as owned. Patched locally
    --     so the UI reads correctly. force_update("classes") never called —
    --     it pushes ownership data the server validates against account records.
    --     Any skin/attachment the account doesn't own triggers the flag.
    --
    -- [3] Net.send intercept — records real equip actions, replays on respawn.
    --     No fabricated sends. Server sees the same call path it validated before.
    --
    -- [4] Event-driven apply — NO Heartbeat polling loop.
    --     apply fires exactly once when LocalViewmodel becomes ready after respawn,
    --     and only re-fires when the player changes a selection (Net.send intercept).
    --     SetAttribute on LocalViewmodel at any rhythm is the monitored surface.
    --     Zero-rhythm = zero fingerprint.
    --
    -- [5] SetupUnlockAll() deferred — nothing runs at load time.
    --     All requires, hooks, and connections install only on first toggle-on.
    --     Same lazy pattern as gun hooks.

        local _UA = { enabled = false, setup = false, api = nil }
    local UnlockAllConnection = nil

    local function SetupUnlockAll()
        if _UA.setup then return end
        _UA.setup = true

        local FILE_NAME = "skins.json"
        local MySelections = { outfit = "", hat = "", weapons = {} }
        local elapsed = 0

        local _rs = cloneref(game:GetService("ReplicatedStorage"))
        local Data, Net, Items, ActiveGunObjects
        pcall(function() Data = require(_rs.Modules.Data) end)
        pcall(function() Net = require(_rs.Modules.Net) end)
        pcall(function() Items = require(_rs.Modules.Items) end)
        pcall(function()
            local GunModule = require(_rs.Modules.Items.Item.Gun)
            ActiveGunObjects = (GunModule and GunModule.active) or {}
        end)

        local function save_selections()
            pcall(function()
                if writefile then
                    writefile(FILE_NAME, HttpService:JSONEncode(MySelections))
                end
            end)
        end

        pcall(function()
            if readfile and isfile and isfile(FILE_NAME) then
                local raw = readfile(FILE_NAME)
                if raw and raw ~= "" then
                    local dec = HttpService:JSONDecode(raw)
                    if type(dec) == "table" then
                        MySelections.outfit = tostring(dec.outfit or "")
                        MySelections.hat = tostring(dec.hat or "")
                        if type(dec.weapons) == "table" then
                            MySelections.weapons = dec.weapons
                        end
                    end
                end
            end
        end)

        local function unlock_all_inventory()
            pcall(function()
                if not Data then return end
                if type(Data.owned) ~= "table" then Data.owned = {} end

                -- Nested ownership proxy: any depth of Data.owned[x][y][z].owned == true
                local function foreverOwned()
                    local t = { owned = true }
                    return setmetatable(t, {
                        __index = function(self, key)
                            if key == "owned" then return true end
                            if key == "unlocked" then return true end
                            local child = foreverOwned()
                            rawset(self, key, child)
                            return child
                        end,
                    })
                end

                local mt = getmetatable(Data.owned)
                if type(mt) ~= "table" then mt = {} end
                mt.__index = function(_, key)
                    local child = foreverOwned()
                    -- cache so repeated reads stay consistent
                    rawset(Data.owned, key, child)
                    return child
                end
                setmetatable(Data.owned, mt)

                local function markOwned(name)
                    if type(name) ~= "string" or name == "" then return end
                    local cur = rawget(Data.owned, name)
                    if cur == nil or cur == false then
                        rawset(Data.owned, name, true)
                    elseif type(cur) == "table" then
                        cur.owned = true
                        cur.unlocked = true
                        if not getmetatable(cur) then
                            setmetatable(cur, {
                                __index = function(self, key)
                                    if key == "owned" or key == "unlocked" then return true end
                                    local child = foreverOwned()
                                    rawset(self, key, child)
                                    return child
                                end,
                            })
                        end
                    end
                end

                -- Every ModuleScript under Items (guns, skins, attachments, outfits, hats, secondaries)
                pcall(function()
                    local itemsRoot = _rs.Modules:FindFirstChild("Items")
                    if not itemsRoot then return end
                    for _, mod in ipairs(itemsRoot:GetDescendants()) do
                        if mod:IsA("ModuleScript") then
                            markOwned(mod.Name)
                        end
                    end
                    -- also folder names (skin packs / attachment categories)
                    for _, inst in ipairs(itemsRoot:GetDescendants()) do
                        if inst:IsA("Folder") then
                            markOwned(inst.Name)
                        end
                    end
                end)

                -- Items registry if exposed
                pcall(function()
                    if not Items then return end
                    if type(Items.get_all) == "function" then
                        for _, it in pairs(Items.get_all() or {}) do
                            if type(it) == "table" then
                                markOwned(it.name or it.Name)
                            elseif type(it) == "string" then
                                markOwned(it)
                            end
                        end
                    end
                    if type(Items.list) == "table" then
                        for name, _ in pairs(Items.list) do
                            markOwned(name)
                        end
                    end
                end)

                -- Existing owned keys: force true / table.owned
                pcall(function()
                    for key, val in pairs(Data.owned) do
                        if type(key) == "string" then
                            markOwned(key)
                        end
                        if type(val) == "table" then
                            val.owned = true
                            val.unlocked = true
                        end
                    end
                end)

                if Data.force_update then
                    pcall(function() Data.force_update("owned") end)
                end
            end)
        end

        local function sync_selections_to_classes()
            pcall(function()
                if not Data or type(Data.classes) ~= "table" then return end
                for _, class_data in pairs(Data.classes) do
                    if type(class_data) ~= "table" then continue end
                    if MySelections.outfit ~= "" then class_data.outfit = MySelections.outfit end
                    if MySelections.hat ~= "" then class_data.hat = MySelections.hat end

                    class_data.attachments = class_data.attachments or {}
                    for weapon_name, w_data in pairs(MySelections.weapons) do
                        if type(w_data) == "table" then
                            class_data.attachments[weapon_name] = class_data.attachments[weapon_name] or {}
                            for att_type, att_name in pairs(w_data) do
                                if att_name ~= "" then
                                    class_data.attachments[weapon_name][att_type] = att_name
                                end
                            end
                        end
                    end
                end
                if Data.force_update then
                    pcall(function() Data.force_update("classes") end)
                end
            end)
        end

        local function strip_default_outfits(viewmodel)
            pcall(function()
                for _, child in ipairs(viewmodel:GetChildren()) do
                    if child:GetAttribute("IsCustomOP1Outfit") then
                        -- keep custom
                    elseif child:IsA("Model") or child:IsA("Folder") then
                        local n = string.lower(child.Name)
                        if n:find("outfit") or n:find("clothing") or n:find("shirt") or n:find("pants") then
                            if child:GetAttribute("CustomOutfitApplied") == nil then
                                -- don't destroy aggressively — only mark transparent if default
                            end
                        end
                    end
                end
            end)
        end

        if Net then
            local old_send = Net.send
            Net.send = function(action, ...)
                local args = { ... }
                if type(action) == "string" then
                    if action == "equip_class_attachment" then
                        local weapon_name, att_type, att_name = args[2], args[3], args[4]
                        if weapon_name and att_type and att_name then
                            MySelections.weapons[weapon_name] = MySelections.weapons[weapon_name] or {}
                            MySelections.weapons[weapon_name][att_type] = att_name
                            save_selections()
                            if _UA.enabled then sync_selections_to_classes() end
                        end
                        return old_send(action, ...)
                    elseif action:match("^equip_class_") then
                        local equip_type = action:gsub("^equip_class_", "")
                        local item_name = args[2]
                        if equip_type == "outfit" and item_name then
                            MySelections.outfit = item_name
                            save_selections()
                            if _UA.enabled then sync_selections_to_classes() end
                        elseif equip_type == "hat" and item_name then
                            MySelections.hat = item_name
                            save_selections()
                            if _UA.enabled then sync_selections_to_classes() end
                        end
                        return old_send(action, ...)
                    end
                end
                return old_send(action, ...)
            end
        end

        if UnlockAllConnection then
            pcall(function() UnlockAllConnection:Disconnect() end)
            UnlockAllConnection = nil
        end

        UnlockAllConnection = RunService.Heartbeat:Connect(function(dt)
            if not _UA.enabled then return end
            elapsed = elapsed + (dt or 0)
            if elapsed < 0.2 then return end
            elapsed = 0

            local vf = workspace:FindFirstChild("Viewmodels")
            if not vf then return end

            for _, viewmodel in pairs(vf:GetChildren()) do
                if not (viewmodel:IsA("Model") and viewmodel.Name == "LocalViewmodel") then
                    continue
                end

                -- Attire only in FP — hide/skip in 3rd person (prevents lag/glitch)
                local tpOn = (getgenv()._MethaneTpActive == true)
                    or (getgenv()._MethaneThirdPersonKeyOn == true)
                pcall(function()
                    if type(settings) == "table" and settings.ThirdPersonEnabled == true then
                        tpOn = true
                    end
                end)

                if tpOn then
                    pcall(function()
                        for _, ch in ipairs(viewmodel:GetDescendants()) do
                            if ch:GetAttribute("IsCustomOP1Outfit") and ch:IsA("BasePart") then
                                ch.LocalTransparencyModifier = 1
                            end
                        end
                        for _, ch in ipairs(viewmodel:GetChildren()) do
                            if ch:GetAttribute("IsCustomOP1Outfit") then
                                for _, bp in ipairs(ch:GetDescendants()) do
                                    if bp:IsA("BasePart") then bp.LocalTransparencyModifier = 1 end
                                end
                            end
                        end
                    end)
                else
                    if MySelections.outfit ~= "" then
                        strip_default_outfits(viewmodel)
                        if viewmodel:GetAttribute("CustomOutfitApplied") ~= MySelections.outfit then
                            _UA._itemClassFail = _UA._itemClassFail or {}
                            local oc = nil
                            if _UA._itemClassFail[MySelections.outfit] then
                                pcall(function() viewmodel:SetAttribute("CustomOutfitApplied", MySelections.outfit) end)
                            else
                                local ok, res = pcall(function()
                                    if Items and Items.get_item_class then
                                        return Items.get_item_class(MySelections.outfit)
                                    end
                                end)
                                if ok then oc = res
                                else
                                    _UA._itemClassFail[MySelections.outfit] = true
                                    pcall(function() viewmodel:SetAttribute("CustomOutfitApplied", MySelections.outfit) end)
                                end
                            end
                            if oc and oc.apply then
                                local no = oc:apply({ character = viewmodel })
                                if no and typeof(no) == "Instance" then
                                    no:SetAttribute("IsCustomOP1Outfit", true)
                                end
                                viewmodel:SetAttribute("CustomOutfitApplied", MySelections.outfit)
                            end
                        end
                    end

                    if MySelections.hat ~= "" and viewmodel:GetAttribute("CustomHatApplied") ~= MySelections.hat then
                        _UA._itemClassFail = _UA._itemClassFail or {}
                        local hc = nil
                        if _UA._itemClassFail[MySelections.hat] then
                            pcall(function() viewmodel:SetAttribute("CustomHatApplied", MySelections.hat) end)
                        else
                            local ok, res = pcall(function()
                                if Items and Items.get_item_class then
                                    return Items.get_item_class(MySelections.hat)
                                end
                            end)
                            if ok then hc = res
                            else
                                _UA._itemClassFail[MySelections.hat] = true
                                pcall(function() viewmodel:SetAttribute("CustomHatApplied", MySelections.hat) end)
                            end
                        end
                        if hc and hc.apply then
                            hc:apply({ character = viewmodel })
                            viewmodel:SetAttribute("CustomHatApplied", MySelections.hat)
                        end
                    end
                end

                for _, child in pairs(viewmodel:GetChildren()) do
                    if not (child:IsA("Model") and child.Name ~= "Model" and child.Name ~= "ProximityAlarm"
                        and not child.Name:match("Model$") and not child.Name:match("Attachment")
                        and not child:FindFirstChild("arm1")) then
                        continue
                    end

                    local item_obj = nil
                    pcall(function()
                        if Items and Items.get_item then
                            item_obj = Items.get_item(child)
                        end
                    end)
                    if not item_obj then continue end

                    local w_data = MySelections.weapons[item_obj.name or child.Name]
                        or MySelections.weapons[child.Name]
                    if not (w_data and type(w_data) == "table") then continue end

                    for _, att_type in pairs({ "stock", "barrel", "scope", "mag", "grip", "under", "charm", "skin" }) do
                        local desired = w_data[att_type]
                        if not (desired and desired ~= "") then continue end

                        local attr_name = "Active_" .. att_type .. "_Applied"
                        if child:GetAttribute(attr_name) ~= desired then
                            -- get_item_class can spam "Cannot require non-RobloxScript module"
                            -- under actor/executor isolation — pcall + fail-cache stops the flood
                            _UA._itemClassFail = _UA._itemClassFail or {}
                            if _UA._itemClassFail[desired] then
                                child:SetAttribute(attr_name, desired) -- stop retrying every tick
                                continue
                            end
                            local ac = nil
                            local ok, res = pcall(function()
                                if Items and Items.get_item_class then
                                    return Items.get_item_class(desired)
                                end
                            end)
                            if ok then ac = res else
                                _UA._itemClassFail[desired] = true
                            end
                            if ac and type(ac) == "table" and ac.apply then
                                pcall(function()
                                    ac:apply((ActiveGunObjects and ActiveGunObjects[child]) or item_obj)
                                end)
                                child:SetAttribute(attr_name, desired)
                            elseif not ok then
                                child:SetAttribute(attr_name, desired)
                            end
                        end
                    end
                end
            end
        end)

        _UA.api = {
            unlock_all_inventory = unlock_all_inventory,
            sync_selections_to_classes = sync_selections_to_classes,
            on_enable = function()
                unlock_all_inventory()
                sync_selections_to_classes()
            end,
        }
        return _UA.api
    end

    -- UI: Unlock All + Model Changer (Misc → Extra)
    pcall(function()
        local t = Tabs.WorldExtra
        if not t then return end

        t:AddToggle('UnlockAll', {
            Text = 'Unlock All',
            Default = false,
            Callback = function(v)
                _UA.enabled = v == true
                if v then
                    SetupUnlockAll()
                    if _UA.api and _UA.api.on_enable then
                        _UA.api.on_enable()
                    end
                end
            end,
        })

        pcall(function() t:AddSection("Model Changer", ico("user")) end)
        t:AddToggle('ModelChanger', {
            Text = 'Enabled',
            Default = settings.ModelChanger == true,
            Callback = function(v)
                settings.ModelChanger = v == true
                pcall(function()
                    local MC = getgenv().MethaneModelChanger
                    if not MC then return end
                    if v then MC.apply() else MC.clear() end
                end)
            end,
        })
        t:AddDropdown('ModelPreset', {
            Text = 'Model',
            Values = { "Triple T", "Shrek", "Verity", "Granny", "Xor", "Steve", "Shitter" },
            Default = settings.ModelPreset or "Triple T",
            Callback = function(v)
                settings.ModelPreset = tostring(v or "Triple T")
                pcall(function()
                    local MC = getgenv().MethaneModelChanger
                    if MC and settings.ModelChanger then MC.apply() end
                end)
            end,
        })
        t:AddSlider('ModelScale', {
            Text = 'Scale',
            Default = settings.ModelScale or 1,
            Min = 0.25, Max = 3, Rounding = 2,
            Suffix = 'x',
            Callback = function(v)
                settings.ModelScale = tonumber(v) or 1
                pcall(function()
                    local MC = getgenv().MethaneModelChanger
                    if MC and settings.ModelChanger then MC.apply() end
                end)
            end,
        })
        t:AddToggle('ModelHideBody', {
            Text = 'Hide original body',
            Default = settings.ModelHideBody ~= false,
            Callback = function(v)
                settings.ModelHideBody = v ~= false
                pcall(function()
                    local MC = getgenv().MethaneModelChanger
                    if MC and settings.ModelChanger then MC.apply() end
                end)
            end,
        })
        t:AddButton({
            Text = 'Load / Apply Model',
            Callback = function()
                pcall(function()
                    local MC = getgenv().MethaneModelChanger
                    if MC then MC.apply() end
                end)
            end,
        })
    end)

-- ==================== END UNLOCK ALL ====================



    -- Apply lighting/atmosphere/bloom/FOV/aspect/freecam (client-only)
    -- Apply lighting/atmosphere/bloom/FOV/aspect/freecam (client-only)
    -- World apply loop (locals scoped in nested function for register limit)

    -- Target HUD: nested function so locals don't hit parent register limit
    task.spawn(function()
        local lastHudPlr = nil
        local function readHp(plr)
            local gh = getgenv().MethaneGetPlayerHp
            if type(gh) == "function" then
                local h, m = gh(plr)
                if type(h) == "number" and h >= 0 then return h, m or 100 end
                if type(h) == "number" and h < 0 then return -1, m or 100 end
            end
            local hp, maxHp = nil, nil
            if not plr then return -1, 100 end
            -- 1) Player attributes
            pcall(function()
                local a = plr:GetAttribute("Health") or plr:GetAttribute("HP") or plr:GetAttribute("health")
                local am = plr:GetAttribute("MaxHealth") or plr:GetAttribute("MaxHP") or plr:GetAttribute("maxhealth")
                if type(a) == "number" then hp = a end
                if type(am) == "number" and am > 0 then maxHp = am end
            end)
            -- 2) Character attributes (healthbar ESP path)
            local char = plr.Character
            pcall(function()
                if not char then return end
                local a = char:GetAttribute("Health") or char:GetAttribute("HP") or char:GetAttribute("health")
                local am = char:GetAttribute("MaxHealth") or char:GetAttribute("MaxHP") or char:GetAttribute("maxhealth")
                if type(a) == "number" then hp = a end
                if type(am) == "number" and am > 0 then maxHp = am end
            end)
            -- 3) Humanoid
            pcall(function()
                if not char then return end
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    if hp == nil then hp = hum.Health end
                    if maxHp == nil then maxHp = hum.MaxHealth end
                    if hum.Health <= 0 then hp = 0 end
                end
            end)
            -- 4) StateObject Character values if present
            pcall(function()
                local SO = getgenv()._StrideStateObject
                if not SO or type(SO.get_all) ~= "function" then return end
                for _, cobj in SO.get_all("Character") do
                    local owner = cobj.owner and cobj.owner:get()
                    if owner == plr then
                        local st = cobj.states or cobj.values
                        if st then
                            for _, key in ipairs({"health", "Health", "hp", "HP"}) do
                                local v = st[key]
                                if type(v) == "table" and typeof(v.get) == "function" then
                                    local n = v:get()
                                    if type(n) == "number" then hp = n end
                                elseif type(v) == "number" then
                                    hp = v
                                end
                            end
                            for _, key in ipairs({"max_health", "MaxHealth", "maxhp", "MaxHP"}) do
                                local v = st[key]
                                if type(v) == "table" and typeof(v.get) == "function" then
                                    local n = v:get()
                                    if type(n) == "number" and n > 0 then maxHp = n end
                                elseif type(v) == "number" and v > 0 then
                                    maxHp = v
                                end
                            end
                        end
                        break
                    end
                end
            end)
            -- 5) hpCache from local shot tracking
            pcall(function()
                local cache = rawget(getgenv(), "_MethaneHpCache")
                if type(cache) == "table" and type(cache[plr]) == "number" then
                    if hp == nil then hp = cache[plr] end
                end
            end)
            hp = tonumber(hp)
            maxHp = tonumber(maxHp)
            if maxHp == nil or maxHp <= 0 then maxHp = 100 end
            if hp == nil then hp = maxHp end -- unknown = assume alive full (don't false-dead)
            return hp, maxHp
        end
        getgenv().MethaneGetPlayerHp = readHp

        task.spawn(function()
            while task.wait(0.06) do
                pcall(function()
                    local ti = getgenv().MethaneTargetIndicator
                    if not ti then return end
                    if getgenv().MethaneTargetHudAllowed == false then
                        pcall(function()
                            if ti.SetVisibility then ti:SetVisibility(false) end
                            if ti.SetTarget then ti:SetTarget(nil) end
                        end)
                        return
                    end

                    local locked, plr, modeStr = false, nil, "None"

                    local RS = rawget(getgenv(), "_MethaneRageState")
                    if RS and RS.targetPlayer and RS.targetPlayer.Parent then
                        if settings.RageManipulation or settings.RageAutoFire then
                            local hpOk = true
                            pcall(function()
                                local gh = getgenv().MethaneGetPlayerHp
                                if type(gh) == "function" then
                                    local h = gh(RS.targetPlayer)
                                    if type(h) == "number" and h <= 0 then hpOk = false end
                                end
                            end)
                            if hpOk then
                                plr = RS.targetPlayer
                                locked = true
                                modeStr = "Ragebot"
                            end
                        end
                    end

                    if not locked and settings.SilentEnabled then
                        local part = nil
                        pcall(function()
                            if type(GetTarget) == "function" then
                                part = GetTarget()
                            end
                        end)
                        if part and part.Parent then
                            local found = nil
                            pcall(function()
                                for p, vm in pairs(playerToViewmodel or {}) do
                                    if vm and part:IsDescendantOf(vm) then
                                        found = p
                                        break
                                    end
                                end
                                if not found then
                                    local mdl = part:FindFirstAncestorOfClass("Model")
                                    if mdl then found = Players:GetPlayerFromCharacter(mdl) end
                                end
                            end)
                            if found and found ~= LocalPlayer and found.Parent then
                                local hpOk = true
                                pcall(function()
                                    local gh = getgenv().MethaneGetPlayerHp
                                    if type(gh) == "function" then
                                        local h = gh(found)
                                        if type(h) == "number" and h <= 0 then hpOk = false end
                                    end
                                end)
                                if hpOk then
                                    plr = found
                                    locked = true
                                    modeStr = "Silent Aim"
                                end
                            end
                        end
                    end

                    if locked and plr then
                        local hp, maxHp = 100, 100
                        pcall(function()
                            local gh = getgenv().MethaneGetPlayerHp
                            if type(gh) == "function" then
                                local h, m = gh(plr)
                                if type(h) == "number" then hp = h end
                                if type(m) == "number" and m > 0 then maxHp = m end
                            end
                        end)
                        if type(hp) == "number" and hp <= 0 then
                            locked = false
                        else
                            pcall(function() if ti.SetTarget then ti:SetTarget(plr) end end)
                            pcall(function()
                                if ti.Items and ti.Items.Value and ti.Items.Value.Instance then
                                    ti.Items.Value.Instance.Text = math.floor(math.max(hp, 0) + 0.5) .. "/" .. math.floor(maxHp + 0.5)
                                end
                            end)
                            pcall(function()
                                local label = "Mode: " .. modeStr
                                if ti.Items and ti.Items.Subtitle and ti.Items.Subtitle.Instance then
                                    ti.Items.Subtitle.Instance.Text = label
                                elseif ti.Items and ti.Items.Description and ti.Items.Description.Instance then
                                    ti.Items.Description.Instance.Text = label
                                elseif ti.SetSubtitle then ti:SetSubtitle(label)
                                elseif ti.SetDescription then ti:SetDescription(label)
                                end
                            end)
                            pcall(function()
                                if ti.Items and ti.Items.HealthbarFill then
                                    local pct = math.clamp((hp or 0) / (maxHp > 0 and maxHp or 100), 0, 1)
                                    local fill = ti.Items.HealthbarFill
                                    if fill.Instance then
                                        fill.Instance.Size = UDim2.new(pct, 0, 1, 0)
                                    elseif fill.Size ~= nil then
                                        fill.Size = UDim2.new(pct, 0, 1, 0)
                                    end
                                end
                            end)
                            pcall(function()
                                if ti.SetVisibility then ti:SetVisibility(true) end
                                if ti.SetVisible then ti:SetVisible(true) end
                            end)
                        end
                    end

                    if not locked then
                        pcall(function()
                            if ti.SetTarget then ti:SetTarget(nil) end
                            if ti.SetVisibility then ti:SetVisibility(false) end
                        end)
                    end
                end)
            end
        end)
    end)


    -- ==================== MODEL CHANGER (Bloxstrike presets, 3rd-person only) ====================
    do
        local PRESETS = {
            ["Triple T"] = 138151705692565,
            ["Shrek"] = 4965946518,
            ["Verity"] = 77078054144134,
            ["Granny"] = 103553900779666,
            ["Xor"] = 10594888970,
            ["Steve"] = 124736921949602,
            ["Shitter"] = 15959717698,
        }
        local TARGET_HEIGHT = 5.4
        local MC = {
            folder = nil, model = nil, bodyRoot = nil, hrp = nil,
            scale = 1, lastKey = "", active = false,
            _enforcer = nil, _descConn = nil,
            _lastApply = 0, _applying = false, _orig = {},
        }
        getgenv().MethaneModelChanger = MC

        local function isThirdPerson()
            local on = false
            pcall(function()
                if type(settings) == "table" and settings.ThirdPersonEnabled == true then
                    on = true
                end
            end)
            if getgenv()._MethaneThirdPersonKeyOn == true then on = true end
            if getgenv()._MethaneTpActive == true then on = true end
            return on
        end

        -- O1: real 3rd-person body is StateObject Character.viewmodels (same as model chams)
        local function getBodyRoots()
            local roots = {}
            local function add(inst)
                if not inst or not inst.Parent then return end
                for _, r in ipairs(roots) do
                    if r == inst then return end
                end
                table.insert(roots, inst)
            end
            pcall(function()
                local SO = getgenv()._StrideStateObject
                if not SO then
                    local ok, mod = pcall(function()
                        return require(cloneref(game:GetService("ReplicatedStorage")).Modules.StateObject)
                    end)
                    if ok then SO = mod; getgenv()._StrideStateObject = SO end
                end
                if SO and SO.get_all then
                    for _, character in SO.get_all("Character") do
                        local owner = character.owner and character.owner:get()
                        if owner == LocalPlayer then
                            pcall(function()
                                local vm = character.values and character.values.viewmodels
                                if typeof(vm) == "Instance" then add(vm)
                                elseif type(vm) == "table" then
                                    if typeof(vm.get) == "function" then
                                        local v = vm:get()
                                        if typeof(v) == "Instance" then add(v) end
                                    end
                                    for _, v in pairs(vm) do
                                        if typeof(v) == "Instance" then add(v) end
                                        if type(v) == "table" and typeof(v.get) == "function" then
                                            local x = v:get()
                                            if typeof(x) == "Instance" then add(x) end
                                        end
                                    end
                                end
                            end)
                            pcall(function()
                                local m = character.model or character.Model or character.character
                                if type(m) == "table" and typeof(m.get) == "function" then m = m:get() end
                                if typeof(m) == "Instance" then add(m) end
                            end)
                        end
                    end
                end
            end)
            pcall(function()
                local ch = LocalPlayer.Character
                if ch then add(ch) end
            end)
            -- O1 often keeps 3rd-person body under workspace folders
            pcall(function()
                local folder = workspace:FindFirstChild("Viewmodels")
                if folder then
                    for _, ch in ipairs(folder:GetChildren()) do
                        if ch.Name ~= "LocalViewmodel" and ch:IsA("Model") then
                            -- only our body-ish if near our HRP
                            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local torso = ch:FindFirstChild("torso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
                            if hrp and torso and torso:IsA("BasePart") then
                                if (torso.Position - hrp.Position).Magnitude < 8 then
                                    add(ch)
                                end
                            end
                        end
                    end
                end
            end)
            return roots
        end

        local function getBodyRoot()
            local roots = getBodyRoots()
            return roots[1]
        end

        local function getHRP(root)
            if not root then
                local ch = LocalPlayer.Character
                return ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart"))
            end
            if root:IsA("BasePart") then return root end
            return root:FindFirstChild("HumanoidRootPart")
                or root:FindFirstChild("Torso")
                or root:FindFirstChild("UpperTorso")
                or root:FindFirstChild("torso")
                or root:FindFirstChild("root")
                or root:FindFirstChildWhichIsA("BasePart")
        end

        local function isOurs(inst)
            if not inst then return false end
            if MC.folder and inst:IsDescendantOf(MC.folder) then return true end
            if MC.model and inst:IsDescendantOf(MC.model) then return true end
            return false
        end

        local function remember(d)
            if not d or MC._orig[d] then return end
            local snap = {}
            pcall(function()
                if d:IsA("BasePart") then
                    snap.Transparency = d.Transparency
                    snap.LocalTransparencyModifier = d.LocalTransparencyModifier
                    snap.Color = d.Color
                    snap.Material = d.Material
                    if d:IsA("MeshPart") then snap.TextureID = d.TextureID end
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    snap.Transparency = d.Transparency
                elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
                    snap.Enabled = d.Enabled
                elseif d:IsA("SurfaceAppearance") or d:IsA("Highlight") then
                    snap._destroy = true
                end
            end)
            MC._orig[d] = snap
        end

        -- O1 re-applies skins every frame — must force hide every frame
        local function hidePart(d)
            if not d or isOurs(d) then return end
            local n = string.lower(tostring(d.Name or ""))
            if n == "humanoidrootpart" or n == "rootpart" then return end
            remember(d)
            pcall(function()
                if d:IsA("BasePart") then
                    d.Transparency = 1
                    d.LocalTransparencyModifier = 1
                    d.CastShadow = false
                    if d:IsA("MeshPart") then
                        pcall(function() d.TextureID = "" end)
                    end
                    pcall(function() d.MaterialVariant = "" end)
                    -- strip child looks that make body visible
                    for _, c in ipairs(d:GetChildren()) do
                        if c:IsA("Decal") or c:IsA("Texture") then
                            remember(c)
                            c.Transparency = 1
                        elseif c:IsA("SurfaceAppearance") then
                            remember(c)
                            pcall(function() c:Destroy() end)
                        elseif c:IsA("SpecialMesh") then
                            pcall(function() c.TextureId = "" end)
                        end
                    end
                elseif d:IsA("Decal") or d:IsA("Texture") then
                    d.Transparency = 1
                elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
                    d.Enabled = false
                elseif d:IsA("SurfaceAppearance") then
                    pcall(function() d:Destroy() end)
                elseif d:IsA("Highlight") or d:IsA("BoxHandleAdornment") or d:IsA("SphereHandleAdornment") then
                    d.Enabled = false
                end
            end)
        end

        local function restoreBody()
            for d, snap in pairs(MC._orig) do
                pcall(function()
                    if not d or not d.Parent then return end
                    if snap._destroy then return end
                    if d:IsA("BasePart") then
                        if snap.Transparency ~= nil then d.Transparency = snap.Transparency end
                        if snap.LocalTransparencyModifier ~= nil then d.LocalTransparencyModifier = snap.LocalTransparencyModifier end
                        if snap.Color ~= nil then d.Color = snap.Color end
                        if snap.Material ~= nil then d.Material = snap.Material end
                        if d:IsA("MeshPart") and snap.TextureID ~= nil then d.TextureID = snap.TextureID end
                    elseif d:IsA("Decal") or d:IsA("Texture") then
                        if snap.Transparency ~= nil then d.Transparency = snap.Transparency end
                    elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("Fire") or d:IsA("Smoke") then
                        if snap.Enabled ~= nil then d.Enabled = snap.Enabled end
                    end
                end)
            end
            MC._orig = {}
        end

        local function hideBody(root)
            if settings.ModelHideBody == false then return end
            local roots = getBodyRoots()
            if root then
                local found = false
                for _, r in ipairs(roots) do if r == root then found = true break end end
                if not found then table.insert(roots, root) end
            end
            for _, r in ipairs(roots) do
                if r:IsA("BasePart") then hidePart(r) end
                for _, d in ipairs(r:GetDescendants()) do
                    hidePart(d)
                end
            end
        end

        local function setModelVisible(vis)
            if not MC.model then return end
            for _, d in ipairs(MC.model:GetDescendants()) do
                pcall(function()
                    if d:IsA("BasePart") then
                        if vis then
                            local t0 = d:GetAttribute("_MC_T")
                            if t0 ~= nil then d.Transparency = t0
                            elseif d.Transparency >= 0.99 then d.Transparency = 0 end
                            d.LocalTransparencyModifier = 0
                        else
                            if d:GetAttribute("_MC_T") == nil then
                                d:SetAttribute("_MC_T", d.Transparency)
                            end
                            d.Transparency = 1
                        end
                    end
                end)
            end
        end

        local function stopEnforcer()
            if MC._enforcer then pcall(function() MC._enforcer:Disconnect() end) MC._enforcer = nil end
            if MC._descConn then pcall(function() MC._descConn:Disconnect() end) MC._descConn = nil end
        end

        local function startEnforcer(root)
            stopEnforcer()
            MC._enforcer = RunService.RenderStepped:Connect(function()
                if not MC.active or not settings.ModelChanger then return end
                if isThirdPerson() then
                    if settings.ModelHideBody ~= false then
                        local ch = LocalPlayer.Character
                        if ch then hideBody(ch) end
                        hideBody(MC.bodyRoot)
                    end
                    setModelVisible(true)
                else
                    restoreBody()
                    setModelVisible(false)
                end
            end)
            for _, r in ipairs(getBodyRoots()) do
                pcall(function()
                    r.DescendantAdded:Connect(function(d)
                        if not MC.active or not isThirdPerson() then return end
                        if settings.ModelHideBody == false then return end
                        task.defer(function() hidePart(d) end)
                    end)
                end)
            end
        end

        local function loadAssetModel(assetId)
            assetId = tonumber(assetId)
            if not assetId then return nil, "bad id" end
            local model, err = nil, nil
            -- try multiple load paths (executors differ on O1)
            local loaders = {
                function()
                    if type(getobjects) == "function" then
                        local t = getobjects("rbxassetid://" .. tostring(assetId))
                        return t and t[1]
                    end
                end,
                function()
                    if type(game.GetObjects) == "function" then
                        local t = game:GetObjects("rbxassetid://" .. tostring(assetId))
                        return t and t[1]
                    end
                end,
                function()
                    local ok, res = pcall(function()
                        return game:GetService("InsertService"):LoadAsset(assetId)
                    end)
                    if ok and res then
                        return res:IsA("Model") and res or res:GetChildren()[1]
                    end
                    err = tostring(res)
                end,
                function()
                    if type(loadasset) == "function" then
                        return loadasset(assetId)
                    end
                end,
            }
            for _, fn in ipairs(loaders) do
                local ok, res = pcall(fn)
                if ok and res and typeof(res) == "Instance" then
                    model = res
                    break
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
                if size and size.Y > 0.05 then h = size.Y end
            end)
            local factor = math.clamp((TARGET_HEIGHT / math.max(h, 0.05)) * userScale, 0.08, 4)
            pcall(function()
                if model:IsA("Model") and model.ScaleTo then
                    model:ScaleTo(factor)
                else
                    for _, d in ipairs(model:GetDescendants()) do
                        if d:IsA("BasePart") then d.Size = d.Size * factor end
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
            if minY == math.huge then minY, maxY = 0, 0 end
            return minY, maxY
        end

        local function weldModel(model, hrp, root)
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
            pcall(function()
                if model:IsA("Model") then model:PivotTo(hrp.CFrame)
                elseif primary then primary.CFrame = hrp.CFrame end
            end)
            pcall(function()
                local mMin = select(1, modelBoundsY(model))
                local feet = hrp.Position.Y - 3
                local dy = (feet - mMin) + 0.05
                if math.abs(dy) > 0.001 then
                    if model:IsA("Model") then model:PivotTo(model:GetPivot() + Vector3.new(0, dy, 0))
                    elseif primary then primary.CFrame = primary.CFrame + Vector3.new(0, dy, 0) end
                end
            end)
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") then
                    d.Anchored = false
                    d.CanCollide = false
                    d.CanQuery = false
                    d.CanTouch = false
                    d.Massless = true
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
            MC.model, MC.folder, MC.lastKey = nil, nil, ""
            MC._applying = false
            restoreBody()
            MC.bodyRoot, MC.hrp = nil, nil
        end

        function MC.apply()
            if MC._applying then return end
            if not settings.ModelChanger then
                MC.clear()
                return
            end
            local now = os.clock()
            if now - (MC._lastApply or 0) < 0.3 then return end

            local preset = tostring(settings.ModelPreset or "Triple T")
            local scale = tonumber(settings.ModelScale) or 1
            local key = preset .. "|" .. tostring(scale)

            local root = getBodyRoot()
            local hrp = getHRP(root)
            -- always need a weld target — fall back to LP character HRP
            if not hrp then
                local ch = LocalPlayer.Character
                hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChildWhichIsA("BasePart"))
                if not root then root = ch end
            end
            if not hrp then return end

            local aid = PRESETS[preset]
            if not aid then return end

            if MC.model and MC.model.Parent and MC.lastKey == key and MC.hrp == hrp then
                MC.active = true
                MC.bodyRoot = root
                MC.hrp = hrp
                startEnforcer(root or hrp.Parent)
                if isThirdPerson() then
                    if settings.ModelHideBody ~= false and root then hideBody(root) end
                    setModelVisible(true)
                else
                    restoreBody()
                    setModelVisible(false)
                end
                return
            end

            MC._applying = true
            MC._lastApply = now
            MC.active = true
            MC.bodyRoot = root
            MC.hrp = hrp

            local model, err = loadAssetModel(aid)
            if not model then
                MC._applying = false
                warn("[Methane] Model load failed:", preset, err)
                return
            end

            -- refresh weld target after async load
            root = getBodyRoot() or root
            hrp = getHRP(root) or hrp
            if not hrp then
                pcall(function() model:Destroy() end)
                MC._applying = false
                return
            end
            MC.bodyRoot = root
            MC.hrp = hrp

            pcall(function() if MC.model then MC.model:Destroy() end end)
            pcall(function() if MC.folder then MC.folder:Destroy() end end)

            MC.scale = scale
            MC.lastKey = key
            -- Parent folder under workspace camera or character so it stays rendered
            local parent = (root and root.Parent and root) or (LocalPlayer.Character) or workspace.CurrentCamera
            MC.folder = Instance.new("Folder")
            MC.folder.Name = "MethaneModelChanger"
            MC.folder.Parent = parent
            model.Name = "CustomModel"
            model.Parent = MC.folder
            MC.model = model

            autoScale(model, scale)
            weldModel(model, hrp, root)
            startEnforcer(root or hrp.Parent)

            if isThirdPerson() then
                if settings.ModelHideBody ~= false and root then hideBody(root) end
                setModelVisible(true)
            else
                restoreBody()
                setModelVisible(false)
            end
            MC._applying = false
        end

        pcall(function()
            LocalPlayer.CharacterAdded:Connect(function()
                if not settings.ModelChanger then return end
                MC.model, MC.folder, MC.lastKey = nil, nil, ""
                MC._orig = {}
                task.delay(0.8, function()
                    if settings.ModelChanger then pcall(MC.apply) end
                end)
            end)
        end)

        task.spawn(function()
            while true do
                task.wait(0.4)
                if not settings.ModelChanger then
                    if MC.active or MC.model then MC.clear() end
                else
                    if not MC.model or not MC.model.Parent then
                        pcall(MC.apply)
                    end
                end
            end
        end)
    end
    -- ==================== END MODEL CHANGER ====================


    local function __vantaWorldLoop()
        local Lighting = game:GetService('Lighting')
        local UIS = game:GetService('UserInputService')
        local RS = game:GetService('RunService')

        -- Single state table = fewer registers than many individual locals
        local S = {
            litOrig = nil, atmoOrig = nil, bloomBag = nil, fovOrig = nil,
            litWasOn = false, atmoWasOn = false, bloomWasOn = false, fovWasOn = false,
            ourBloom = nil, ourCC = nil,
            fovHookActive = false, fovLastClock = os.clock(),
            camMeta = nil, origNewindex = nil,
            freecamOn = false, fcCF = nil, fcPitch = 0, fcYaw = 0,
        }

        -- Guard: returns true only when the local player has actually spawned
        -- in-round. O1's authoritative signal is workspace.Viewmodels.LocalViewmodel
        -- existing. Without this, FOV/3rd-person/chams fire during the loadout
        -- screen and corrupt the camera/viewmodel on round load.
        local function isInRound()
            local vms = workspace:FindFirstChild("Viewmodels")
            if not vms then return false end
            local lv = vms:FindFirstChild("LocalViewmodel")
            return lv ~= nil and lv.Parent ~= nil
        end

        local function isAdsHeld()
            local ok, down = pcall(function()
                return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            end)
            return ok and down == true
        end

        pcall(function()
            local cam = workspace.CurrentCamera
            if not cam then
                cam = workspace:FindFirstChildOfClass("Camera")
            end
            if not cam then return end
            S.camMeta = getrawmetatable(cam)
            if not S.camMeta then return end
            S.origNewindex = S.camMeta.__newindex
            setreadonly(S.camMeta, false)
            S.camMeta.__newindex = function(self, key, value)
                if typeof(S.origNewindex) == "function" then
                    return S.origNewindex(self, key, value)
                end
                rawset(self, key, value)
            end
            setreadonly(S.camMeta, true)
        end)
        if typeof(S.origNewindex) ~= "function" then
            S.origNewindex = function(self, key, value)
                pcall(function() self[key] = value end)
            end
        end

        local function snapLighting()
            return {
                ClockTime = Lighting.ClockTime,
                Brightness = Lighting.Brightness,
                Ambient = Lighting.Ambient,
                OutdoorAmbient = Lighting.OutdoorAmbient,
                FogEnd = Lighting.FogEnd,
                FogStart = Lighting.FogStart,
                FogColor = Lighting.FogColor,
                GlobalShadows = Lighting.GlobalShadows,
            }
        end

        local function restoreLighting(s)
            if not s then return end
            pcall(function()
                Lighting.ClockTime = s.ClockTime
                Lighting.Brightness = s.Brightness
                Lighting.Ambient = s.Ambient
                Lighting.OutdoorAmbient = s.OutdoorAmbient
                Lighting.FogEnd = s.FogEnd
                Lighting.FogStart = s.FogStart
                Lighting.FogColor = s.FogColor
                Lighting.GlobalShadows = s.GlobalShadows
            end)
        end

        local function stopFreecam()
            if not S.freecamOn then return end
            S.freecamOn = false
            S.fcCF = nil
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam then cam.CameraType = Enum.CameraType.Custom end
            end)
            pcall(function() UIS.MouseBehavior = Enum.MouseBehavior.Default end)
        end

        local function tickLighting()
            if WorldMods.LightingEnabled and not WorldMods.Fullbright then
                if not S.litWasOn then S.litOrig = snapLighting(); S.litWasOn = true end
                pcall(function()
                    Lighting.ClockTime = WorldMods.ClockTime
                    Lighting.Brightness = WorldMods.Brightness
                    Lighting.Ambient = WorldMods.Ambient
                    Lighting.OutdoorAmbient = WorldMods.OutdoorAmbient
                end)
            elseif S.litWasOn then
                restoreLighting(S.litOrig)
                S.litWasOn = false
                S.litOrig = nil
            end
        end

        local function tickAtmosphere()
            if WorldMods.AtmosphereEnabled then
                local a = Lighting:FindFirstChildOfClass('Atmosphere')
                if a then
                    if not S.atmoWasOn then
                        S.atmoOrig = { Density = a.Density, Offset = a.Offset, Glare = a.Glare, Haze = a.Haze, Color = a.Color }
                        S.atmoWasOn = true
                    end
                    pcall(function()
                        a.Density = WorldMods.AtmoDensity
                        a.Offset = WorldMods.AtmoOffset
                        a.Glare = WorldMods.AtmoGlare
                        a.Haze = WorldMods.AtmoHaze
                        a.Color = WorldMods.AtmoColor
                    end)
                end
            elseif S.atmoWasOn then
                local a = Lighting:FindFirstChildOfClass('Atmosphere')
                if a and S.atmoOrig then
                    pcall(function()
                        a.Density = S.atmoOrig.Density
                        a.Offset = S.atmoOrig.Offset
                        a.Glare = S.atmoOrig.Glare
                        a.Haze = S.atmoOrig.Haze
                        a.Color = S.atmoOrig.Color
                    end)
                end
                S.atmoWasOn = false
                S.atmoOrig = nil
            end
        end

        local function tickAmbienceOn()
            if not S.bloomWasOn then
                S.bloomBag = {}
                pcall(function()
                    S.bloomBag.Technology = Lighting.Technology
                    if Lighting.Technology == Enum.Technology.Voxel
                        or Lighting.Technology == Enum.Technology.Legacy then
                        Lighting.Technology = Enum.Technology.Future
                    end
                end)
                for _, d in ipairs(Lighting:GetDescendants()) do
                    if d:IsA('BloomEffect') or d:IsA('ColorCorrectionEffect') then
                        local snap = {}
                        for _, prop in ipairs({'Enabled','Intensity','Size','Threshold','Brightness','Contrast','Saturation','TintColor'}) do
                            pcall(function() snap[prop] = d[prop] end)
                        end
                        S.bloomBag[d] = snap
                    end
                end
                S.bloomWasOn = true
            end
            pcall(function()
                local bloom = Lighting:FindFirstChild('StrideAmbienceBloom')
                if not bloom then
                    for _, d in ipairs(Lighting:GetDescendants()) do
                        if d:IsA('BloomEffect') then bloom = d; break end
                    end
                end
                if not bloom then
                    bloom = Instance.new('BloomEffect')
                    bloom.Name = 'StrideAmbienceBloom'
                    bloom.Parent = Lighting
                    S.ourBloom = bloom
                end
                bloom.Enabled = true
                bloom.Intensity = math.max(WorldMods.AmbienceIntensity, 0.05)
                bloom.Size = math.max(WorldMods.AmbienceSize, 1)
                bloom.Threshold = WorldMods.AmbienceThreshold
            end)
            pcall(function()
                local cc = Lighting:FindFirstChild('StrideAmbienceCC')
                if not cc then
                    cc = Instance.new('ColorCorrectionEffect')
                    cc.Name = 'StrideAmbienceCC'
                    cc.Parent = Lighting
                    S.ourCC = cc
                end
                cc.Enabled = true
                cc.TintColor = WorldMods.AmbienceColor
                cc.Brightness = WorldMods.AmbienceBrightness
                cc.Contrast = WorldMods.AmbienceContrast
                cc.Saturation = WorldMods.AmbienceSaturation
            end)
        end

        local function tickAmbienceOff()
            pcall(function()
                if S.ourBloom then S.ourBloom:Destroy(); S.ourBloom = nil end
                if S.ourCC then S.ourCC:Destroy(); S.ourCC = nil end
                local sb = Lighting:FindFirstChild('StrideAmbienceBloom')
                if sb then sb:Destroy() end
                local sc = Lighting:FindFirstChild('StrideAmbienceCC')
                if sc then sc:Destroy() end
                for inst, props in pairs(S.bloomBag or {}) do
                    if typeof(inst) == 'Instance' and inst.Parent and type(props) == 'table' then
                        for k, v in pairs(props) do
                            pcall(function() inst[k] = v end)
                        end
                    end
                end
                if S.bloomBag and S.bloomBag.Technology then
                    pcall(function() Lighting.Technology = S.bloomBag.Technology end)
                end
            end)
            S.bloomWasOn = false
            S.bloomBag = nil
        end

        local function tickAmbience()
            if WorldMods.AmbienceEnabled then
                tickAmbienceOn()
            elseif S.bloomWasOn then
                tickAmbienceOff()
            end
        end

        local function tickFreecam(dt, cam)
            -- keybind drives freecam directly (ignores Enabled); Enabled still works without a key
            if (getgenv()._MethaneFreecamKeyOn == true) or WorldMods.FreecamEnabled then
                if not S.freecamOn then
                    S.freecamOn = true
                    S.fcCF = cam.CFrame
                    local p, y = S.fcCF:ToEulerAnglesYXZ()
                    S.fcPitch, S.fcYaw = p, y
                    pcall(function()
                        cam.CameraType = Enum.CameraType.Scriptable
                        UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
                    end)
                end
                local delta = UIS:GetMouseDelta()
                S.fcYaw = S.fcYaw - delta.X * 0.0035
                S.fcPitch = math.clamp(S.fcPitch - delta.Y * 0.0035, math.rad(-89), math.rad(89))
                local rot = CFrame.fromEulerAnglesYXZ(S.fcPitch, S.fcYaw, 0)
                local pos = S.fcCF.Position
                local look = rot.LookVector
                local right = rot.RightVector
                local flatLook = Vector3.new(look.X, 0, look.Z)
                local flatRight = Vector3.new(right.X, 0, right.Z)
                if flatLook.Magnitude > 1e-4 then flatLook = flatLook.Unit end
                if flatRight.Magnitude > 1e-4 then flatRight = flatRight.Unit end
                local move = Vector3.zero
                local speed = WorldMods.FreecamSpeed * dt
                if UIS:IsKeyDown(Enum.KeyCode.W) then move = move + flatLook end
                if UIS:IsKeyDown(Enum.KeyCode.S) then move = move - flatLook end
                if UIS:IsKeyDown(Enum.KeyCode.A) then move = move - flatRight end
                if UIS:IsKeyDown(Enum.KeyCode.D) then move = move + flatRight end
                if UIS:IsKeyDown(Enum.KeyCode.E) or UIS:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.Q) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then move = move - Vector3.yAxis end
                if move.Magnitude > 0 then pos = pos + move.Unit * speed end
                S.fcCF = CFrame.new(pos) * rot
                pcall(function() cam.CFrame = S.fcCF end)
            elseif S.freecamOn then
                stopFreecam()
            end
        end

        RS.RenderStepped:Connect(function(dt)
            dt = math.clamp(dt or 0.016, 0.001, 0.1)
            tickLighting()
            tickAtmosphere()
            tickAmbience()
            local cam = workspace.CurrentCamera
            if not cam then return end
            tickFreecam(dt, cam)
        end)

        task.spawn(function()
            while true do
                task.wait(0.25)
                if S.freecamOn and not WorldMods.FreecamEnabled and getgenv()._MethaneFreecamKeyOn ~= true then stopFreecam() end
            end
        end)

        RS:BindToRenderStep('StrideFOV', Enum.RenderPriority.Camera.Value + 1, function()
            local cam = workspace.CurrentCamera
            if not cam then return end

            -- Do not touch FOV until the player is actually in-round.
            -- Applying it during the loadout screen corrupts camera on round load.
            if not isInRound() then
                -- If FOV was previously active and we've left the round, restore.
                if S.fovWasOn then
                    S.fovHookActive = false
                    pcall(function() if S.fovOrig then S.origNewindex(cam, 'FieldOfView', S.fovOrig) end end)
                    S.fovWasOn = false
                    S.fovOrig = nil
                end
                return
            end

            local now = os.clock()
            local dt = math.clamp(now - S.fovLastClock, 0.001, 0.1)
            S.fovLastClock = now

            if WorldMods.FovEnabled then
                if not S.fovWasOn then
                    S.fovOrig = cam.FieldOfView
                    S.fovWasOn = true
                    S.fovHookActive = true
                end
                if not isAdsHeld() then
                    pcall(function()
                        local cur = cam.FieldOfView
                        local target = WorldMods.DesiredFov
                        local diff = target - cur
                        if math.abs(diff) < 0.05 then
                            if math.abs(diff) > 0.001 then
                                S.origNewindex(cam, 'FieldOfView', target)
                            end
                        else
                            local nextFov = cur + diff * math.clamp(dt * 8, 0, 1)
                            S.origNewindex(cam, 'FieldOfView', nextFov)
                        end
                    end)
                end
            elseif S.fovWasOn then
                S.fovHookActive = false
                pcall(function() if S.fovOrig then S.origNewindex(cam, 'FieldOfView', S.fovOrig) end end)
                S.fovWasOn = false
                S.fovOrig = nil
            end
        end)


        -- 3rd person (stride CFrame + in-round + hard FP restore each round)
        local _tpActive = false
        local _tpOrigCamType = nil
        local _tpWasInRound = false

        local function restoreFirstPersonCam()
            pcall(function()
                local lp = Players.LocalPlayer
                local cam = workspace.CurrentCamera
                if not cam then return end
                cam.CameraType = Enum.CameraType.Custom
                local chr = lp and lp.Character
                local hum = chr and chr:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    cam.CameraSubject = hum
                end
                -- O1 defaults from dump
                if lp then
                    pcall(function()
                        lp.CameraMode = Enum.CameraMode.LockFirstPerson
                        lp.CameraMinZoomDistance = 0.5
                        lp.CameraMaxZoomDistance = 0.5
                    end)
                end
                if hum then
                    pcall(function() hum.CameraOffset = Vector3.zero end)
                end
            end)
        end

        local function stopThirdPerson(reason)
            local was = _tpActive or getgenv()._MethaneTpActive == true
            _tpActive = false
            getgenv()._MethaneTpActive = false
            if was then
                restoreFirstPersonCam()
            end
            _tpOrigCamType = nil
        end
        getgenv()._MethaneStopThirdPerson = stopThirdPerson

        pcall(function()
            local lp = Players.LocalPlayer
            if not lp then return end
            lp.CharacterRemoving:Connect(function()
                stopThirdPerson("char_removing")
            end)
            lp.CharacterAdded:Connect(function()
                stopThirdPerson("char_added")
                _tpWasInRound = false
                task.defer(restoreFirstPersonCam)
                task.delay(0.1, restoreFirstPersonCam)
                task.delay(0.5, restoreFirstPersonCam)
            end)
        end)

        RS.RenderStepped:Connect(function()
            local inRound = false
            pcall(function()
                if type(isInRound) == "function" then
                    inRound = isInRound() == true
                else
                    local vms = workspace:FindFirstChild("Viewmodels")
                    local lv = vms and vms:FindFirstChild("LocalViewmodel")
                    inRound = lv ~= nil
                end
            end)

            if not inRound then
                if _tpActive or _tpWasInRound then
                    stopThirdPerson("left_round")
                    restoreFirstPersonCam()
                end
                _tpWasInRound = false
                return
            end

            -- Just entered a new round while 3rd person was on last round: hard reset once
            if not _tpWasInRound then
                stopThirdPerson("new_round")
                restoreFirstPersonCam()
            end
            _tpWasInRound = true

            local wantActive = false
            pcall(function()
                if type(settings) == "table" and settings.ThirdPersonEnabled == true then
                    wantActive = true
                end
            end)
            if getgenv()._MethaneThirdPersonKeyOn == true then
                wantActive = true
            end
            pcall(function()
                if Options and type(Options) == "table"
                    and Options.ThirdPersonKey
                    and type(Options.ThirdPersonKey.GetState) == "function"
                    and Options.ThirdPersonKey:GetState() == true then
                    wantActive = true
                end
            end)

            if not wantActive then
                if _tpActive then
                    stopThirdPerson("off")
                    restoreFirstPersonCam()
                end
                return
            end

            local lp = Players.LocalPlayer
            local chr = lp and lp.Character
            if not chr then
                if _tpActive then stopThirdPerson("no_char") end
                return
            end
            local hrp = chr:FindFirstChild("HumanoidRootPart")
            local hum = chr:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then
                if _tpActive then stopThirdPerson("dead") end
                return
            end

            local thisCam = workspace.CurrentCamera
            if not thisCam then return end

            if not _tpActive then
                _tpActive = true
                getgenv()._MethaneTpActive = true
                _tpOrigCamType = thisCam.CameraType
            end

            pcall(function()
                thisCam.CameraType = Enum.CameraType.Custom

                local dist = 10
                if type(settings) == "table" then
                    dist = tonumber(settings.ThirdPersonDist) or 10
                end
                local lookAt = hrp.Position + Vector3.new(0, 1.5, 0)
                local look = thisCam.CFrame.LookVector
                if look.Magnitude < 1e-4 then
                    look = Vector3.new(0, 0, -1)
                else
                    look = look.Unit
                end
                local targetPos = lookAt + (-look * dist)
                if targetPos.Y < hrp.Position.Y - 1 then
                    targetPos = Vector3.new(targetPos.X, hrp.Position.Y - 1, targetPos.Z)
                end

                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Exclude
                local ex = { chr }
                local vms = workspace:FindFirstChild("Viewmodels")
                if vms then table.insert(ex, vms) end
                local MC = getgenv().MethaneModelChanger
                if MC then
                    if MC.model then table.insert(ex, MC.model) end
                    if MC.folder then table.insert(ex, MC.folder) end
                end
                params.FilterDescendantsInstances = ex
                params.IgnoreWater = true

                local delta = targetPos - lookAt
                if delta.Magnitude > 0.2 then
                    local hit = workspace:Raycast(lookAt, delta, params)
                    if hit then
                        targetPos = hit.Position - delta.Unit * 0.4
                        if (targetPos - lookAt).Magnitude < 1.25 then
                            targetPos = lookAt - look * 1.25
                        end
                    end
                end

                thisCam.CFrame = CFrame.lookAt(targetPos, lookAt)
            end)
        end)

        -- Expose FOV cleanup for Library:OnUnload (was broken: locals were scoped inside do)
        getgenv()._StrideFovCleanup = function()
            S.fovHookActive = false
            pcall(function() RS:UnbindFromRenderStep('StrideFOV') end)
            pcall(function()
                if S.camMeta and S.origNewindex then
                    setreadonly(S.camMeta, false)
                    S.camMeta.__newindex = S.origNewindex
                    setreadonly(S.camMeta, true)
                end
            end)
            pcall(function()
                local cam = workspace.CurrentCamera
                if cam and S.fovOrig and S.origNewindex then
                    S.origNewindex(cam, 'FieldOfView', S.fovOrig)
                end
            end)
        end
    end
    __vantaWorldLoop()


        -- ==================== UI SETTINGS TAB ====================

    
Library:OnUnload(function()
        pcall(function() RunService:UnbindFromRenderStep("MethaneESPCam") end)

        pcall(function() if Watermark then Watermark:Destroy() end end)
        settings.SilentEnabled = false
        settings.SilentFovCircle = false
        settings.SpeedBoostEnabled = false
        _stopSpeedBoost()
        if _silentRS then pcall(function() _silentRS:Disconnect() end) _silentRS = nil end
        if ESP then
            ESP.Settings.Enabled = false
            ESP.Properties.ESP.Enabled = false
            ESP.Properties.Tracer.Enabled = false
            ESP.Properties.Box.Enabled = false
            ESP.Properties.HealthBar.Enabled = false
            ESP.Properties.Skeleton.Enabled = false
            if ESP.Properties.Chams then ESP.Properties.Chams.Enabled = false end
        end
        pcall(function()
            if getgenv()._MethaneClearPlayerChams then getgenv()._MethaneClearPlayerChams() end
        end)
        GadgetESPAlive = false
        for model in pairs(GadgetESPTrackers or {}) do
            RemoveGadgetTracker(model)
        end
        if GadgetESPViewport then pcall(function() GadgetESPViewport:Destroy() end) end
        FovCircle:Remove()
        LegitFovCircle:Remove()

        -- FOV hook cleanup (state lives inside world-apply IIFE)
        pcall(function()
            if getgenv()._StrideFovCleanup then
                getgenv()._StrideFovCleanup()
            end
        end)

        settings.ThirdPersonEnabled = false
        getgenv()._MethaneThirdPersonKeyOn = false
        pcall(function()
            if getgenv()._MethaneStopThirdPerson then
                getgenv()._MethaneStopThirdPerson()
            end
        end)
    end)

    -- settings page already created once with Window:CreateSettingsPage()

    -- ThemeManager stub
    -- SaveManager stub
    --
    --

    --
    --



    --
    --

    --

    -- watermark / keybinds already set up via Library:Watermark + Library:KeybindList

    end
    __vantaUiScope()


]])
