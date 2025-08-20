SSER | Exploit Utilities

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer

local Rayfield = loadstring(game:HttpGet("https://raw.githubusercontent.com/XRnzX/z/refs/heads/main/rayfield.lua"))()

local ErrorCodes = {
    [1001] = "Humanoid missing (character not fully loaded yet).",
    [1002] = "Character missing (wait for respawn).",
    [1003] = "HumanoidRootPart missing (not fully loaded).",
    [1100] = "WalkSpeed apply failed (nil Humanoid).",
    [2001] = "Camera target missing (player dead/not spawned).",
    [2002] = "View/Bring/AutoKill started without a selected player.",
    [3001] = "No gun/tool with Ammo found (equip a gun).",
    [3002] = "Tool activation failed (Activate/Deactivate error).",
    [3003] = "AutoKill missing something (your HRP, target HRP, or tool).",
    [3500] = "Carry/Bring failed to trigger (key send failed).",
    [4001] = "Teleport failed (no HRP).",
    [5001] = "Graphics toggle failed.",
    [6001] = "Unload UI failed.",
    [7001] = "Noclip apply failed.",
    [8001] = "Dropdown/selection invalid or missing data.",
    [9001] = "Unknown error (catch-all)."
}

local ErrorCount = {}
local MaxErrorPerType = 5
local ErrorResetTime = 10

local function NotifyError(code, context)
    ErrorCount[code] = (ErrorCount[code] or 0) + 1
    if ErrorCount[code] <= MaxErrorPerType then
        local msg = ErrorCodes[code] or ErrorCodes[9001]
        StarterGui:SetCore("SendNotification", {
            Title = "⚠️ SSER Error "..code,
            Text = msg .. (context and (" — "..context) or ""),
            Duration = 5
        })
        warn("[SSER Error "..code.."] "..msg..(context and (" — "..context) or ""))
        delay(ErrorResetTime, function()
            ErrorCount[code] = ErrorCount[code] - 1
            if ErrorCount[code] < 0 then ErrorCount[code] = 0 end
        end)
    end
end

local Window = Rayfield:CreateWindow({
    Name = "SSER Hub",
    LoadingTitle = "SSER Script Hub",
    LoadingSubtitle = "by saint.devv : VERSION 🔒 v1.4",
    ConfigurationSaving = {Enabled = true, FileName = "SSER Hub"},
    Discord = {Enabled = true, Invite = "discord.gg/rblxcondo", RememberJoins = true},
    KeySystem = true,
    KeySettings = {
        Title = "SSER Script Hub",
        Subtitle = "🔒 v1.4",
        Note = "Please join discord.gg/WpwZAB7M9n for key!",
        FileName = "Key",
        SaveKey = true,
        Key = {"PointyVG"}
    }
})

local walkSpeedValue = 16
local targetInfo = {Player=nil, Username=""}
local autoKillActive = false
local bringTargetActive = false
local aimLockEnabled = false
local instantReloadActive = false
local noclipEnabled = false
local aimLockSpeed = 0.25
local lastShoot = 0

local function getHumanoid(char)
    if not char then NotifyError(1002,"Character nil") return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then NotifyError(1001,"Humanoid missing") end
    return humanoid
end

local function getHRP(char)
    if not char then NotifyError(1002,"Character nil") return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then NotifyError(1003,"HRP missing") end
    return hrp
end

local function getFacingPlayer()
    local cam = Workspace.CurrentCamera
    if not cam then NotifyError(2001,"No camera") return nil end
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
        local success, err = pcall(function() tool:Activate() tool:Deactivate() end)
        if not success then NotifyError(3002, err) end
    else
        NotifyError(3001,"No tool equipped")
    end
end

local function instantReload(tool)
    if instantReloadActive and tool and tool:FindFirstChild("Ammo") then
        pcall(function() tool.Ammo.Value = tool.Ammo.MaxValue or 30 end)
    end
end

local MainTab = Window:CreateTab("Main",11570895459)
MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16,300},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = walkSpeedValue,
    Callback = function(val)
        walkSpeedValue = val
        local humanoid = getHumanoid(LocalPlayer.Character)
        if humanoid then humanoid.WalkSpeed = val else NotifyError(1100) end
    end
})

MainTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Callback = function(state)
        noclipEnabled = state
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = not state
                end
            end
        else
            NotifyError(7001,"Character nil")
        end
    end
})

LocalPlayer.CharacterAdded:Connect(function(char)
    local humanoid = char:WaitForChild("Humanoid",5) or getHumanoid(char)
    if humanoid then
        humanoid.WalkSpeed = walkSpeedValue
        if noclipEnabled then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    else
        NotifyError(1100)
    end
end)

local PlayerTab = Window:CreateTab("Player",7992557358)
PlayerTab:CreateInput({
    Name = "Quick Search Target",
    PlaceholderText = "Type username or display name...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        text = text:lower()
        local found = nil
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Name:lower():find(text) or (plr.DisplayName and plr.DisplayName:lower():find(text)) then
                found = plr
                break
            end
        end
        if found then
            targetInfo.Player = found
            targetInfo.Username = found.Name
            Rayfield:Notify({Title="Target Selected", Content=found.Name.." ("..found.DisplayName..")", Duration=3})
        else
            targetInfo.Player = nil
            Rayfield:Notify({Title="Error", Content="Player not found!", Duration=3})
        end
    end
})

PlayerTab:CreateToggle({Name="Bring Target", CurrentValue=false, Callback=function(state) bringTargetActive=state end})
PlayerTab:CreateToggle({Name="AutoKill / Spam Gun", CurrentValue=false, Callback=function(state) autoKillActive=state end})
PlayerTab:CreateToggle({Name="Aim Lock", CurrentValue=false, Callback=function(state) aimLockEnabled=state end})
PlayerTab:CreateToggle({Name="Instant Reload", CurrentValue=false, Callback=function(state) instantReloadActive=state end})

local PlacesTab = Window:CreateTab("Places",279461710)
local Locations = {
    ["Safe Zone"] = Vector3.new(-501.2,48.8,-211.1),
    ["Bank"] = Vector3.new(-410.2,22,-284.5)
}
for name,pos in pairs(Locations) do
    PlacesTab:CreateButton({
        Name = name,
        Callback = function()
            local hrp = getHRP(LocalPlayer.Character)
            if hrp then
                hrp.CFrame = CFrame.new(pos)
            else
                NotifyError(4001)
            end
        end
    })
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = getHRP(char)
    local humanoid = getHumanoid(char)
    local tool = char:FindFirstChildOfClass("Tool")
    local cam = Workspace.CurrentCamera

    if humanoid and humanoid.WalkSpeed ~= walkSpeedValue then humanoid.WalkSpeed = walkSpeedValue end

    if hrp then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = not noclipEnabled and true or false
            end
        end
    end

    if bringTargetActive then
        if not targetInfo.Player then NotifyError(2002,"Bring") return end
        local targetHRP = getHRP(targetInfo.Player.Character)
        if hrp and targetHRP then
            hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,5,0))
        else
            NotifyError(3003,"Bring missing HRP")
        end
    end

    if autoKillActive then
        if not targetInfo.Player then NotifyError(2002,"AutoKill") return end
        local targetHRP = getHRP(targetInfo.Player.Character)
        if hrp and targetHRP and tool then
            hrp.CFrame = CFrame.new(targetHRP.Position + Vector3.new(0,5,0))
            smoothLookAt(cam,targetHRP.Position + Vector3.new(0,1.5,0),aimLockSpeed)
            if tick() - lastShoot > 0.15 then
                lastShoot = tick()
                safeActivateTool(tool)
            end
        else
            NotifyError(3003,"AutoKill missing HRP or tool")
        end
    end

    if aimLockEnabled then
        local targetHRP = getFacingPlayer()
        if targetHRP then
            smoothLookAt(cam,targetHRP.Position + Vector3.new(0,1.5,0),aimLockSpeed)
        end
    end

    if tool then instantReload(tool) end
end)
