-- SSER Roblox Utilities
local Players, RunService, Workspace = game:GetService("Players"), game:GetService("RunService"), game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

repeat wait() until LocalPlayer and LocalPlayer.Parent
if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then LocalPlayer.CharacterAdded:Wait() end

local success, Rayfield = pcall(function() 
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/XRnzX/z/refs/heads/main/rayfield.lua"))() 
end)
if not success then warn("Failed to load Rayfield!") return end

local walkSpeedValue = 16
local noclipEnabled = false
local targetInfo = {Player=nil, Username=""}
local autoKillActive, bringTargetActive, aimLockEnabled, instantReloadActive = false,false,false,false
local viewTargetEnabled = false
local lastViewedPlayer = nil
local lastShoot = 0


local function getHumanoid(char) return char and char:FindFirstChildOfClass("Humanoid") end
local function getHRP(char) return char and char:FindFirstChild("HumanoidRootPart") end
local function getFacingPlayer()
    local cam = Workspace.CurrentCamera
    if not cam then return nil end
    local origin,direction = cam.CFrame.Position, cam.CFrame.LookVector*1000
    local ray = Ray.new(origin,direction)
    local hit = Workspace:FindPartOnRayWithIgnoreList(ray,{LocalPlayer.Character})
    if hit and hit.Parent then
        local plr = Players:GetPlayerFromCharacter(hit.Parent)
        if plr and plr ~= LocalPlayer then
            return plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        end
    end
    return nil
end

-- Window & Tabs
local Window = Rayfield:CreateWindow({Name="SSER Hub",LoadingTitle="SSER Script Hub",LoadingSubtitle="by saint.devv : VERSION 🔒 v1.4"})
local MainTab=Window:CreateTab("Main",11570895459)
MainTab:CreateSlider({Name="WalkSpeed",Range={16,400},Increment=1,Suffix="Speed",CurrentValue=walkSpeedValue,Callback=function(val) 
    walkSpeedValue=val
end})
MainTab:CreateToggle({Name="Noclip",CurrentValue=false,Callback=function(state) 
    noclipEnabled=state
end})

local PlayerTab=Window:CreateTab("Player",7992557358)
local selectedPlayer = nil
PlayerTab:CreateInput({Name="Quick Search Target",PlaceholderText="Type username...",RemoveTextAfterFocusLost=false,Callback=function(text)
    text = text:lower()
    local found
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr.Name:lower():find(text) or (plr.DisplayName and plr.DisplayName:lower():find(text)) then found=plr break end
    end
    if found then
        selectedPlayer = found
        targetInfo.Player = found
        targetInfo.Username = found.Name
        Rayfield:Notify({Title="Target Selected",Content=found.Name,Duration=3})
    else
        selectedPlayer = nil
        targetInfo.Player = nil
        Rayfield:Notify({Title="Error",Content="Player not found!",Duration=3})
    end
end})
PlayerTab:CreateToggle({Name="Bring Target",CurrentValue=false,Callback=function(state) bringTargetActive=state end})
PlayerTab:CreateToggle({Name="AutoKill / Spam Gun",CurrentValue=false,Callback=function(state) autoKillActive=state end})
PlayerTab:CreateToggle({Name="View Target",CurrentValue=false,Callback=function(state)
    viewTargetEnabled = state
    local cam = Workspace.CurrentCamera
    if not state then
        cam.CameraSubject = getHumanoid(LocalPlayer.Character) or LocalPlayer.Character:FindFirstChild("Humanoid")
        lastViewedPlayer = nil
    else
        if selectedPlayer then
            local targetHumanoid = getHumanoid(selectedPlayer.Character)
            if targetHumanoid then
                cam.CameraSubject = targetHumanoid
                lastViewedPlayer = selectedPlayer
            else
                Rayfield:Notify({Title="Error", Content="Target has no Humanoid!", Duration=3})
                viewTargetEnabled = false
            end
        else
            Rayfield:Notify({Title="Error", Content="No target selected!", Duration=3})
            viewTargetEnabled = false
        end
    end
end})
PlayerTab:CreateToggle({Name="Aim Lock",CurrentValue=false,Callback=function(state) aimLockEnabled=state end})
PlayerTab:CreateToggle({Name="Instant Reload",CurrentValue=false,Callback=function(state) instantReloadActive=state end})

local PlacesTab=Window:CreateTab("Places",279461710)
local Locations={
    ["Safe Zone"]=Vector3.new(-501.2,48.8,-211.1),
    ["Bank"]=Vector3.new(-410.2,22,-284.5),
    ["Double Barrel"]=Vector3.new(-1042,21,-261)
}
for name,pos in pairs(Locations) do
    PlacesTab:CreateButton({Name=name,Callback=function()
        local hrp = getHRP(LocalPlayer.Character)
        if hrp then hrp.CFrame=CFrame.new(pos) end
    end})
end


local function applyWalkSpeed(hum)
    if hum then
        hum.WalkSpeed = walkSpeedValue
        hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
            if hum.WalkSpeed ~= walkSpeedValue then
                hum.WalkSpeed = walkSpeedValue
            end
        end)
    end
end


local function setupCharacter(char)
    local humanoid = getHumanoid(char)
    applyWalkSpeed(humanoid)
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            desc.CanCollide = not noclipEnabled and desc.CanCollide or false
        end
    end)
end
LocalPlayer.CharacterAdded:Connect(setupCharacter)
if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end

-- Main Loop
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = getHumanoid(char)
    local hrp = getHRP(char)

    -- Persistent WalkSpeed every frame
    if humanoid and humanoid.WalkSpeed ~= walkSpeedValue then
        humanoid.WalkSpeed = walkSpeedValue
    end


    for _,part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not noclipEnabled and true or false
        end
    end

    local cam = Workspace.CurrentCamera

    if bringTargetActive and targetInfo.Player then
        local targetHRP = getHRP(targetInfo.Player.Character)
        local safePos = Locations["Safe Zone"]
        if targetHRP and safePos then targetHRP.CFrame = CFrame.new(safePos + Vector3.new(0,5,0)) end
    end


    if autoKillActive and targetInfo.Player then
        local tool = char:FindFirstChildOfClass("Tool")
        local targetHRP = getHRP(targetInfo.Player.Character)
        if hrp and targetHRP and tool then
            hrp.CFrame = targetHRP.CFrame + Vector3.new(0,5,0)
            cam.CFrame = CFrame.new(cam.CFrame.Position,targetHRP.Position + Vector3.new(0,1.5,0))
            if tick()-lastShoot > 0.15 then lastShoot=tick() tool:Activate() tool:Deactivate() end
        end
    end

  
    if aimLockEnabled then
        local targetHRP = getFacingPlayer()
        if targetHRP then cam.CFrame = CFrame.new(cam.CFrame.Position,targetHRP.Position + Vector3.new(0,1.5,0)) end
    end


    local tool = char:FindFirstChildOfClass("Tool")
    if instantReloadActive and tool and tool:FindFirstChild("Ammo") then tool.Ammo.Value = tool.Ammo.MaxValue or 30 end


    if viewTargetEnabled and lastViewedPlayer then
        local targetHumanoid = getHumanoid(lastViewedPlayer.Character)
        if targetHumanoid then
            cam.CameraSubject = targetHumanoid
        else
            viewTargetEnabled = false
            cam.CameraSubject = getHumanoid(LocalPlayer.Character)
            lastViewedPlayer = nil
        end
    end
end)
