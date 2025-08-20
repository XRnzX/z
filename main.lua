-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Rayfield GUI
local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/XRnzX/z/refs/heads/main/rayfield.lua"))()

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

-- WalkSpeed Slider
MainTab:CreateSlider({
	Name = "WalkSpeed",
	Range = {16, 200},
	Increment = 1,
	Suffix = "Speed",
	CurrentValue = walkSpeedValue,
	Callback = function(value)
		walkSpeedValue = value
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = value
		end
	end
})

-- Apply WalkSpeed on spawn
local function applyWalkSpeed()
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = walkSpeedValue
	end
end
LocalPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid")
	applyWalkSpeed()
end)

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

-- Search Target Input
MainTab:CreateInput({
	Name = "Search Target Player",
	PlaceholderText = "Start typing username or display name...",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		targetInfo.Player = nil
		text = text:lower()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Name:lower():sub(1,#text) == text or plr.DisplayName:lower():sub(1,#text) == text then
				targetInfo.Player = plr
				targetInfo.Username = plr.Name
				Rayfield:Notify({Title="Target Selected", Content=plr.Name.." ("..plr.DisplayName..")", Duration=3})
				break
			end
		end
		if not targetInfo.Player then
			Rayfield:Notify({Title="Error", Content="Player not found!", Duration=3})
		end
	end
})

-- Players Tab Input
PlayersTab:CreateInput({
	Name = "Search Player",
	PlaceholderText = "Start typing username or display name...",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		selectedPlayer = nil
		text = text:lower()
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.Name:lower():sub(1,#text) == text or plr.DisplayName:lower():sub(1,#text) == text then
				selectedPlayer = plr
				Rayfield:Notify({Title="Player Found", Content=plr.Name.." ("..plr.DisplayName..")", Duration=3})
				break
			end
		end
		if not selectedPlayer then
			Rayfield:Notify({Title="Error", Content="Player not found!", Duration=3})
		end
	end
})

-- View Buttons
PlayersTab:CreateButton({Name="View Player", Callback=function()
	if selectedPlayer and selectedPlayer.Character then
		viewingPlayer = true
		Rayfield:Notify({Title="Viewing Player", Content="Now watching "..selectedPlayer.Name, Duration=3})
	else
		Rayfield:Notify({Title="Error", Content="Select a valid player first!", Duration=3})
	end
end})
PlayersTab:CreateButton({Name="Stop Viewing", Callback=function()
	if viewingPlayer then
		viewingPlayer = false
		local cam = Workspace.CurrentCamera
		cam.CameraType = Enum.CameraType.Custom
		Rayfield:Notify({Title="Stopped Viewing", Content="Camera returned to normal", Duration=3})
	end
end})

-- Functions
local function getNearestPlayer()
	local closestDistance = math.huge
	local closestHRP = nil
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			local dist = (plr.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
			if dist < closestDistance then
				closestDistance = dist
				closestHRP = plr.Character.HumanoidRootPart
			end
		end
	end
	return closestHRP
end

local function getFacingPlayer()
	local cam = Workspace.CurrentCamera
	if not cam then return nil end
	local origin = cam.CFrame.Position
	local direction = cam.CFrame.LookVector * 1000
	local ray = Ray.new(origin, direction)
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
		pcall(function()
			tool:Activate()
			tool:Deactivate()
		end)
	end
end

local function smoothLookAt(camera, targetPos, speed)
	if camera and targetPos then
		local cf = camera.CFrame
		local dir = (targetPos - cf.Position).Unit
		camera.CFrame = cf:Lerp(CFrame.new(cf.Position, cf.Position + dir), speed)
	end
end

-- Main Loop
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local tool = char:FindFirstChildOfClass("Tool")
	local cam = Workspace.CurrentCamera

	if humanoid then
		pcall(function() humanoid.WalkSpeed = walkSpeedValue end)
	end

	-- Noclip
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") then
			if noclipEnabled then
				if originalCanCollide[part] == nil then
					originalCanCollide[part] = part.CanCollide
				end
				part.CanCollide = false
			else
				if originalCanCollide[part] ~= nil then
					part.CanCollide = originalCanCollide[part]
				end
			end
		end
	end

	-- Bring Target
	if bringTargetActive and targetInfo.Player and targetInfo.Player.Character and hrp then
		local targetHRP = targetInfo.Player.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,20,0))
			if cam then
				cam.CFrame = CFrame.new(cam.CFrame.Position, targetHRP.Position + Vector3.new(0,1.5,0))
			end
			if tool and tick() - lastShoot > 0.05 then
				lastShoot = tick()
				safeActivateTool(tool)
			end
		end
	end

	-- Smooth Silent Aim Lock
	if smoothSilentAimEnabled and hrp and tool and cam then
		local targetHRP = getFacingPlayer()
		if targetHRP then
			smoothLookAt(cam, targetHRP.Position + Vector3.new(0,1.5,0), aimLockSpeed)
		end
	end

	-- More Advanced Aim Lock
	if advancedAimEnabled and hrp and tool and cam then
		local nearestHRP = getNearestPlayer()
		if nearestHRP then
			cam.CFrame = CFrame.new(cam.CFrame.Position, nearestHRP.Position + Vector3.new(0,1.5,0))
			safeActivateTool(tool)
		end
	end

	-- AutoKill
	if autoKillActive and hrp and tool and cam then
		local nearest = getFacingPlayer()
		if nearest then
			hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,20,0))
			cam.CFrame = CFrame.new(cam.CFrame.Position, nearest.Position + Vector3.new(0,1.5,0))
			if tick() - lastShoot > 0.05 then
				lastShoot = tick()
				safeActivateTool(tool)
			end
		end
	end

	-- Instant Reload / Auto Fire
	if instantReloadActive and tool then
		pcall(function()
			if tool:FindFirstChild("Ammo") then
				tool.Ammo.Value = tool.Ammo.MaxValue or 30
			end
			safeActivateTool(tool)
		end)
	end

	-- Live Player View
	if viewingPlayer and selectedPlayer and selectedPlayer.Character and cam then
		local targetHRP = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
		if targetHRP then
			local backOffset = -6
			local heightOffset = 3
			local camPos = targetHRP.Position + Vector3.new(0, heightOffset, backOffset)
			cam.CameraType = Enum.CameraType.Scriptable
			cam.CFrame = CFrame.new(camPos, targetHRP.Position + Vector3.new(0,2,0))
		end
	end
end)
