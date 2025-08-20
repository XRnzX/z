-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local GroupService = game:GetService("GroupService")

-- Load Rayfield safely
local success, Rayfield = pcall(function()
	return loadstring(game:HttpGet("https://raw.githubusercontent.com/XRnzX/z/refs/heads/main/rayfield.lua"))()
end)
if not success or not Rayfield then
	warn("Failed to load Rayfield GUI")
	return
end

-- Window
local Window = Rayfield:CreateWindow({
	Name = "SSER Hub",
	LoadingTitle = "SSER Script Hub",
	LoadingSubtitle = "by saint.devv : VERSION 🔒 v1.3",
	ConfigurationSaving = {Enabled = true, FileName = "SSER Hub"},
	Discord = {Enabled = true, Invite = "discord.gg/rblxcondo", RememberJoins = true},
	KeySystem = true,
	KeySettings = {
		Title = "SSER Script Hub",
		Subtitle = "🔒 v1.3",
		Note = "Please join discord.gg/WpwZAB7M9n for key!",
		FileName = "Key",
		SaveKey = true,
		Key = {"PointyVG"}
	}
})

-- Tabs
local MainTab = Window:CreateTab("Main", 11570895459)
local PlayersTab = Window:CreateTab("Player", 7992557358)
local SettingsTab = Window:CreateTab("Settings", 7059346373)

-- Variables
local selectedPlayer = nil
local viewingPlayer = false
local walkSpeedValue = 16
local bringTargetActive = false
local smoothSilentAimEnabled = false
local advancedAimEnabled = false
local aimLockSpeed = 0.25
local autoKillActive = false
local instantReloadActive = false
local noclipEnabled = false
local targetInfo = {Player=nil, Username=""}
local lastShoot = 0
local originalCanCollide = {}
local modDetectionEnabled = false

-- Helper functions
local function applyWalkSpeed()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then humanoid.WalkSpeed = walkSpeedValue end
end

local function getPlayerFromName(name)
	name = name:lower()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Name:lower():find(name) or (plr.DisplayName:lower():find(name)) then
			return plr
		end
	end
	return nil
end

local function getNearestPlayer()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
	local closestDist = math.huge
	local closestHRP = nil
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (plr.Character.HumanoidRootPart.Position - char.HumanoidRootPart.Position).Magnitude
			if dist < closestDist then
				closestDist = dist
				closestHRP = plr.Character.HumanoidRootPart
			end
		end
	end
	return closestHRP
end

local function getFacingPlayer()
	local cam = Workspace.CurrentCamera
	if not cam or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return nil end
	local ray = Ray.new(cam.CFrame.Position, cam.CFrame.LookVector * 1000)
	local ignore = {LocalPlayer.Character}
	local hit, pos = Workspace:FindPartOnRayWithIgnoreList(ray, ignore)
	if hit and hit.Parent then
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if plr and plr ~= LocalPlayer then
			return plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
		end
	end
	return nil
end

local function safeActivateTool(tool)
	if tool and tool.Parent == LocalPlayer.Character then
		pcall(function() tool:Activate() tool:Deactivate() end)
	end
end

local function smoothLookAt(cam, targetPos, speed)
	if cam and targetPos then
		local cf = cam.CFrame
		local dir = (targetPos - cf.Position).Unit
		cam.CFrame = cf:Lerp(CFrame.new(cf.Position, cf.Position + dir), speed)
	end
end

-- Player Selection Input (Dropdown + Search)
local playerDropdown = PlayersTab:CreateDropdown({
	Name = "Select Player",
	Options = {},
	CurrentOption = "",
	Callback = function(option)
		selectedPlayer = getPlayerFromName(option)
	end
})

-- Textbox for searching player by display name or username
PlayersTab:CreateTextBox({
	Name = "Search Player",
	PlaceholderText = "Type DisplayName/Username",
	RemoveTextAfterFocusLost = false,
	Callback = function(value)
		selectedPlayer = getPlayerFromName(value)
		if selectedPlayer then
			playerDropdown:Refresh({selectedPlayer.Name}, selectedPlayer.Name)
		end
	end
})

-- Toggle to view selected player
PlayersTab:CreateToggle({
	Name = "View Selected Player",
	CurrentValue = false,
	Callback = function(state)
		viewingPlayer = state
		if not state then
			local cam = Workspace.CurrentCamera
			if cam then cam.CameraType = Enum.CameraType.Custom end
		end
	end
})

-- Main Tab Player Input for AutoKill/Bring
MainTab:CreateTextBox({
	Name = "Target Player",
	PlaceholderText = "Type DisplayName/Username",
	RemoveTextAfterFocusLost = false,
	Callback = function(value)
		targetInfo.Player = getPlayerFromName(value)
		targetInfo.Username = targetInfo.Player and targetInfo.Player.Name or ""
	end
})

-- Main Tab Toggles
MainTab:CreateToggle({Name = "Bring Target", CurrentValue=false, Callback=function(state) bringTargetActive = state end})
MainTab:CreateToggle({Name = "Smooth Silent Aim Lock", CurrentValue=false, Callback=function(state) smoothSilentAimEnabled = state end})
MainTab:CreateToggle({Name = "More Advanced Aim Lock", CurrentValue=false, Callback=function(state) advancedAimEnabled = state end})
MainTab:CreateToggle({Name = "AutoKill / Spam Gun", CurrentValue=false, Callback=function(state) autoKillActive = state end})
MainTab:CreateToggle({Name = "Instant Reload", CurrentValue=false, Callback=function(state) instantReloadActive = state end})
MainTab:CreateToggle({Name = "Noclip", CurrentValue=false, Callback=function(state)
	noclipEnabled = state
	local char = LocalPlayer.Character
	if char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				if state then
					originalCanCollide[part] = part.CanCollide
					part.CanCollide = false
				else
					if originalCanCollide[part] ~= nil then
						part.CanCollide = originalCanCollide[part]
					end
				end
			end
		end
	end
end})

-- Settings Tab
SettingsTab:CreateButton({
	Name = "Unload GUI",
	Callback = function()
		pcall(function() Window:Destroy() end)
	end
})

SettingsTab:CreateToggle({
	Name = "Mod Detection (Dahood Group)",
	CurrentValue = false,
	Callback = function(state)
		modDetectionEnabled = state
	end
})

-- Character Position Label
local charPosLabel = SettingsTab:CreateLabel("Character Position: Loading...")
RunService.RenderStepped:Connect(function()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local hrp = LocalPlayer.Character.HumanoidRootPart
		charPosLabel:Set("Character Position: "..math.floor(hrp.Position.X)..", "..math.floor(hrp.Position.Y)..", "..math.floor(hrp.Position.Z))
	end
end)

-- Credit Label
SettingsTab:CreateLabel("This menu was made by saint.devv")

-- Main Loop
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hrp = char.HumanoidRootPart
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local tool = char:FindFirstChildOfClass("Tool")
	local cam = Workspace.CurrentCamera
	if not cam then return end

	-- WalkSpeed
	if humanoid then pcall(function() humanoid.WalkSpeed = walkSpeedValue end) end

	-- Noclip
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if noclipEnabled then
				if originalCanCollide[part] == nil then originalCanCollide[part] = part.CanCollide end
				part.CanCollide = false
			else
				if originalCanCollide[part] ~= nil then part.CanCollide = originalCanCollide[part] end
			end
		end
	end

	-- Bring Target
	if bringTargetActive and targetInfo.Player and targetInfo.Player.Character and tool then
		local targetHRP = targetInfo.Player.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,20,0))
			cam.CFrame = CFrame.new(cam.CFrame.Position, targetHRP.Position + Vector3.new(0,1.5,0))
			if tick() - lastShoot > 0.05 then lastShoot = tick(); safeActivateTool(tool) end
		end
	end

	-- Smooth Silent Aim Lock
	if smoothSilentAimEnabled and tool then
		local targetHRP = getFacingPlayer()
		if targetHRP then smoothLookAt(cam, targetHRP.Position + Vector3.new(0,1.5,0), aimLockSpeed) end
	end

	-- More Advanced Aim Lock
	if advancedAimEnabled and tool then
		local nearestHRP = getNearestPlayer()
		if nearestHRP then
			cam.CFrame = CFrame.new(cam.CFrame.Position, nearestHRP.Position + Vector3.new(0,1.5,0))
			safeActivateTool(tool)
		end
	end

	-- AutoKill
	if autoKillActive and tool and targetInfo.Player and targetInfo.Player.Character then
		local targetHRP = targetInfo.Player.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,20,0))
			cam.CFrame = CFrame.new(cam.CFrame.Position, targetHRP.Position + Vector3.new(0,1.5,0))
			if tick() - lastShoot > 0.05 then lastShoot = tick(); safeActivateTool(tool) end
		end
	end

	-- Instant Reload
	if instantReloadActive and tool then
		pcall(function()
			if tool:FindFirstChild("Ammo") then tool.Ammo.Value = tool.Ammo.MaxValue or 30 end
			safeActivateTool(tool)
		end)
	end

	-- Live Player View
	if viewingPlayer and selectedPlayer and selectedPlayer.Character then
		local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,3,-6), targetHRP.Position + Vector3.new(0,2,0))
		end
	else
		if cam then cam.CameraType = Enum.CameraType.Custom end
	end

	-- Mod Detection
	if modDetectionEnabled then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= LocalPlayer then
				local ok, isInGroup = pcall(function()
					return plr:IsInGroup(4698921)
				end)
				if ok and isInGroup then
					local role = plr:GetRankInGroup(4698921)
					if role >= 200 then
						warn("Moderator/Admin detected: "..plr.Name)
					end
				end
			end
		end
	end
end)
