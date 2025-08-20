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

-- Main Tab
local MainTab = Window:CreateTab("🎮 Main", 4483362458)

-- Variables
local walkSpeedValue = 16
local bringTargetActive = false
local aimLockEnabled = false
local aimLockSpeed = 0.25
local autoKillActive = false
local instantReloadActive = false
local noclipEnabled = false
local targetInfo = {Player=nil, Username=""}
local lastShoot = 0

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

-- Search Target
MainTab:CreateInput({
	Name = "Search Target Player",
	PlaceholderText = "Exact username...",
	RemoveTextAfterFocusLost = false,
	Callback = function(text)
		local player = Players:FindFirstChild(text)
		if player then
			targetInfo.Player = player
			targetInfo.Username = player.Name
			Rayfield:Notify({Title="Target Selected", Content=player.Name, Duration=3})
		else
			Rayfield:Notify({Title="Error", Content="Player not found!", Duration=3})
		end
	end
})

-- Toggles
MainTab:CreateToggle({Name = "Bring Target", CurrentValue=false, Callback=function(state) bringTargetActive = state end})
MainTab:CreateToggle({Name = "Aim Lock", CurrentValue=false, Callback=function(state) aimLockEnabled = state end})
MainTab:CreateToggle({Name = "AutoKill / Spam Gun", CurrentValue=false, Callback=function(state) autoKillActive = state end})
MainTab:CreateToggle({Name = "Instant Reload", CurrentValue=false, Callback=function(state) instantReloadActive = state end})
MainTab:CreateToggle({Name = "Noclip", CurrentValue=false, Callback=function(state) noclipEnabled = state end})

-- Functions
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

local function smoothLookAt(camera, targetPos, speed)
	if camera and targetPos then
		local cf = camera.CFrame
		local dir = (targetPos - cf.Position).Unit
		camera.CFrame = cf:Lerp(CFrame.new(cf.Position, cf.Position + dir), speed)
	end
end

local function safeActivateTool(tool)
	if tool and tool.Parent == LocalPlayer.Character then
		pcall(function()
			tool:Activate()
			tool:Deactivate()
		end)
	end
end

local function instantReload(tool)
	if instantReloadActive and tool and tool:FindFirstChild("Ammo") then
		pcall(function()
			local maxAmmo = tool.Ammo.MaxValue or 30
			tool.Ammo.Value = maxAmmo
		end)
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

	-- WalkSpeed Fix
	if humanoid and humanoid.WalkSpeed ~= walkSpeedValue then
		humanoid.WalkSpeed = walkSpeedValue
	end

	-- Noclip
	if noclipEnabled and hrp then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") and part.CanCollide then
				part.CanCollide = false
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
			if tool and tick() - lastShoot > 0.1 then
				lastShoot = tick()
				safeActivateTool(tool)
			end
		end
	end

	-- Smart Aim Lock
	if aimLockEnabled and hrp and tool and cam then
		local targetHRP = getFacingPlayer()
		if targetHRP then
			smoothLookAt(cam, targetHRP.Position + Vector3.new(0,1.5,0), aimLockSpeed)
		end
	end

	-- AutoKill / Spam Gun
	if autoKillActive and hrp and tool and cam then
		local nearest = getFacingPlayer() or nil
		if nearest then
			hrp.CFrame = CFrame.new(nearest.Position + Vector3.new(0,20,0))
			cam.CFrame = CFrame.new(cam.CFrame.Position, nearest.Position + Vector3.new(0,1.5,0))
			if tick() - lastShoot > 0.15 then
				lastShoot = tick()
				safeActivateTool(tool)
			end
		end
	end

	-- Instant Reload
	if tool then
		instantReload(tool)
	end
end)
