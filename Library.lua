-- Velocity by Vhyse | v1.3

local Velocity = {
    -- Current Toggle States
    State = {
        Fly = false,
        Noclip = false,
        Bhop = false,
        CFrameWalk = false,
        TravelMode = false,
        IsTravelling = false,
        ModifySpeed = false,
        ModifyJump = false
    },
    
    -- Configurable Values
    Config = {
        FlySpeed = 50,
        BhopSpeed = 50,
        CFrameSpeed = 50,
        TravelSpeed = 100,
        WalkSpeed = 50,
        JumpHeight = 50
    },
    
    Connections = {},
    Binds = {},
    OriginalCollisions = {}
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========================================================================= --
--                            UNIVERSAL KEYBINDS                             --
-- ========================================================================= --
function Velocity:Bind(keyCode, callback)
    self.Binds[keyCode] = callback
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Velocity.Binds[input.KeyCode] then
        Velocity.Binds[input.KeyCode]()
    end
end)

-- ========================================================================= --
--                            UTILITY FUNCTIONS                              --
-- ========================================================================= --
local function GetCharacter()
    return LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
end

local function GetRootPart()
    return GetCharacter():FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    return GetCharacter():FindFirstChildOfClass("Humanoid")
end

-- ========================================================================= --
--                            DEATH / RESPAWN HOOK                           --
-- ========================================================================= --
-- Automatically re-applies physics-based toggles when the player respawns
LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.2) -- Give physics a moment to initialize
    
    -- Re-apply states to the new character
    if Velocity.State.Noclip then Velocity:ToggleNoclip(true) end
    if Velocity.State.Fly then Velocity:ToggleFly(true) end
    
    -- Note: WalkSpeed and JumpHeight re-apply automatically via the Heartbeat loop below!
end)

-- ========================================================================= --
--                            ADVANCED FEATURES                              --
-- ========================================================================= --

-- [ NOCLIP ] --
function Velocity:ToggleNoclip(state)
    self.State.Noclip = state
    
    if state then
        self.OriginalCollisions = {}
        for _, part in ipairs(GetCharacter():GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                table.insert(self.OriginalCollisions, part)
            end
        end

        if self.Connections.Noclip then self.Connections.Noclip:Disconnect() end
        self.Connections.Noclip = RunService.Stepped:Connect(function()
            for _, part in ipairs(self.OriginalCollisions) do
                if part and part.Parent then part.CanCollide = false end
            end
        end)
    else
        if self.Connections.Noclip then self.Connections.Noclip:Disconnect() end
        for _, part in ipairs(self.OriginalCollisions) do
            if part and part.Parent then part.CanCollide = true end
        end
    end
end

-- [ FLY ] --
function Velocity:ToggleFly(state)
    self.State.Fly = state
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    if state then
        local bv = Instance.new("BodyVelocity")
        bv.Name = "VelocityFly"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp
        
        -- Disable standard physics interactions to stop the falling animation
        hum.PlatformStand = true

        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        self.Connections.Fly = RunService.RenderStepped:Connect(function()
            local currentHrp = GetRootPart()
            local currentHum = GetHumanoid()
            if not currentHrp or not currentHum then return end
            
            -- Force PlatformStand continuously
            currentHum.PlatformStand = true

            local moveVector = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector -= Vector3.new(0, 1, 0) end

            if moveVector.Magnitude > 0 then moveVector = moveVector.Unit end
            
            local activeBv = currentHrp:FindFirstChild("VelocityFly")
            if activeBv then activeBv.Velocity = moveVector * self.Config.FlySpeed end
        end)
    else
        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        if hrp:FindFirstChild("VelocityFly") then hrp.VelocityFly:Destroy() end
        hum.PlatformStand = false -- Re-enable normal walking/physics
    end
end

-- [ THE MASTER PHYSICS LOOP (Speed, Jump, CFrame, Bhop) ] --
Velocity.Connections.PhysicsLoop = RunService.Heartbeat:Connect(function(deltaTime)
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    -- 1. FORCE STANDARD MODIFIERS (Anti-Override)
    if Velocity.State.ModifySpeed then
        hum.WalkSpeed = Velocity.Config.WalkSpeed
    end
    
    if Velocity.State.ModifyJump then
        hum.UseJumpPower = false
        hum.JumpHeight = Velocity.Config.JumpHeight
    end

    -- 2. ADVANCED MOVEMENT MATH
    local moveDir = hum.MoveDirection
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {GetCharacter()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    if moveDir.Magnitude > 0 then
        -- CFrame Walk
        if Velocity.State.CFrameWalk and not Velocity.State.Bhop then
            local speedDiff = Velocity.Config.CFrameSpeed - hum.WalkSpeed
            if speedDiff > 0 then
                local offset = moveDir * (speedDiff * deltaTime)
                local ray = Workspace:Raycast(hrp.Position, offset, rayParams)
                if not ray then hrp.CFrame += offset end 
            end
        end

        -- Bunny Hop
        if Velocity.State.Bhop then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                if hum.FloorMaterial ~= Enum.Material.Air then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                
                local speedDiff = Velocity.Config.BhopSpeed - hum.WalkSpeed
                if speedDiff > 0 then
                    local offset = moveDir * (speedDiff * deltaTime)
                    local ray = Workspace:Raycast(hrp.Position, offset, rayParams)
                    if not ray then hrp.CFrame += offset end
                end
            end
        end
    end
end)

-- [ CLICK TELEPORT / TRAVEL ] --
function Velocity:ExecuteClickAction()
    if self.State.IsTravelling then return end 
    local hrp = GetRootPart()
    if not hrp then return end

    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {GetCharacter()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
    
    if rayResult then
        local hitPos = rayResult.Position
        local targetCFrame = CFrame.new(hitPos + Vector3.new(0, 3, 0))

        if not self.State.TravelMode then
            -- Standard Direct TP 
            hrp.CFrame = targetCFrame
        else
            -- Travel Mode (Phases through walls)
            self.State.IsTravelling = true
            local distance = (hrp.Position - targetCFrame.Position).Magnitude
            local estimatedTime = distance / self.Config.TravelSpeed
            local maxAllowedTime = estimatedTime + 5 
            local startTime = os.clock()
            
            -- Hook into Stepped to force Noclip while travelling
            local travelNoclip = RunService.Stepped:Connect(function()
                for _, part in ipairs(GetCharacter():GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end)
            
            local travelConnection
            travelConnection = RunService.Heartbeat:Connect(function(deltaTime)
                local currentHrp = GetRootPart()
                if not currentHrp then 
                    travelConnection:Disconnect()
                    travelNoclip:Disconnect()
                    self.State.IsTravelling = false
                    return
                end

                local currentDist = (currentHrp.Position - targetCFrame.Position).Magnitude
                
                -- Destination Reached or Failsafe Triggered
                if (os.clock() - startTime) > maxAllowedTime or currentDist <= 2 then
                    travelConnection:Disconnect()
                    travelNoclip:Disconnect()
                    self.State.IsTravelling = false
                    return
                end
                
                -- Move smoothly
                local travelDir = (targetCFrame.Position - currentHrp.Position).Unit
                currentHrp.CFrame += travelDir * (self.Config.TravelSpeed * deltaTime)
            end)
        end
    end
end

return Velocity
