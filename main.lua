-- Variables
local selectedPlayer = nil
local viewingPlayer = false
local walkSpeedValue = 16
local bringTargetActive = false
local smoothSilentAimEnabled = false -- renamed first aim lock
local advancedAimEnabled = false -- second aim lock
local aimLockSpeed = 0.25
local autoKillActive = false
local instantReloadActive = false
local noclipEnabled = false
local targetInfo = {Player=nil, Username=""}
local lastShoot = 0
local originalCanCollide = {}

-- Main Tab Toggles
MainTab:CreateToggle({Name = "Bring Target", CurrentValue=false, Callback=function(state) bringTargetActive = state end})
MainTab:CreateToggle({Name = "Smooth Silent Aim Lock", CurrentValue=false, Callback=function(state) smoothSilentAimEnabled = state end})
MainTab:CreateToggle({Name = "More Advanced Aim Lock", CurrentValue=false, Callback=function(state) advancedAimEnabled = state end})
MainTab:CreateToggle({Name = "AutoKill / Spam Gun", CurrentValue=false, Callback=function(state) autoKillActive = state end})
MainTab:CreateToggle({
	Name = "Instant Reload",
	CurrentValue=false,
	Callback=function(state) instantReloadActive = state end
})
MainTab:CreateToggle({
	Name = "Noclip",
	CurrentValue=false,
	Callback=function(state)
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
	end
})

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

	-- WalkSpeed always sync
	if humanoid then
		pcall(function() humanoid.WalkSpeed = walkSpeedValue end)
	end

	-- Noclip toggle
	if hrp then
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
				pcall(function() tool:Activate() tool:Deactivate() end)
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
			pcall(function() tool:Activate() tool:Deactivate() end)
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
				pcall(function() tool:Activate() tool:Deactivate() end)
			end
		end
	end

	-- Instant Reload / Auto Fire
	if instantReloadActive and tool then
		pcall(function()
			if tool:FindFirstChild("Ammo") then
				tool.Ammo.Value = tool.Ammo.MaxValue or 30
			end
			tool:Activate()
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
