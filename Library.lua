-- Velocity by Vhyse | v1.8

local Velocity = {
    -- Toggle States
    State = {
        Fly = false,
        Noclip = false,
        Bhop = false,
        CFrameWalk = false,
        TravelMode = false,
        IsTravelling = false,
        AbortTravel = false,
        ModifySpeed = false,
        ModifyJump = false
    },
    
    -- Active Configurations
    Config = {
        FlySpeed = 50,
        BhopSpeed = 50,
        CFrameSpeed = 50,
        TravelSpeed = 100,
        WalkSpeed = 50,
        JumpHeight = 50
    },
    
    -- Internal Memory
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
--                            UNIVERSAL KEYBINDS                             --
-- ========================================================================= --
function Velocity:Bind(keyCode, callback)
    self.Binds[keyCode] = callback
end

-- Stored in Connections so it can be destroyed during Unload
Velocity.Connections.InputListener = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Velocity.Binds[input.KeyCode] then
        Velocity.Binds[input.KeyCode]()
    end
end)

-- ========================================================================= --
--                            DEATH / RESPAWN HOOK                           --
-- ========================================================================= --
Velocity.Connections.RespawnHook = LocalPlayer.CharacterAdded:Connect(function(newChar)
    newChar:WaitForChild("HumanoidRootPart", 5)
    task.wait(0.2) 
    
    if Velocity.State.Noclip then Velocity:ToggleNoclip(true) end
    if Velocity.State.Fly then Velocity:ToggleFly(true) end
end)

-- ========================================================================= --
--                            STATE MODIFIERS                                --
-- ========================================================================= --
function Velocity:ToggleSpeedModifier(state)
    self.State.ModifySpeed = state
    if not state then
        local hum = GetHumanoid()
        if hum then hum.WalkSpeed = 16 end
    end
end

function Velocity:ToggleJumpModifier(state)
    self.State.ModifyJump = state
    if not state then
        local hum = GetHumanoid()
        if hum then 
            hum.UseJumpPower = true
            hum.JumpPower = 50 
            hum.JumpHeight = 7.2 
        end
    end
end

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

-- [ FLY (Upgraded Logic) ] --
function Velocity:ToggleFly(state)
    self.State.Fly = state
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    if state then
        -- Add BodyGyro for rotation locking
        local bg = Instance.new("BodyGyro")
        bg.Name = "VelocityFlyBG"
        bg.P = 9e4
        bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp

        -- Add BodyVelocity for movement
        local bv = Instance.new("BodyVelocity")
        bv.Name = "VelocityFlyBV"
        bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp

        -- Freeze animations/physics state
        hum.PlatformStand = true
        
        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        self.Connections.Fly = RunService.Heartbeat:Connect(function()
            local currentHrp = GetRootPart()
            if not currentHrp then return end
            
            local direction = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then direction = direction + Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then direction = direction - Vector3.new(0, 1, 0) end

            local activeBv = currentHrp:FindFirstChild("VelocityFlyBV")
            local activeBg = currentHrp:FindFirstChild("VelocityFlyBG")
            
            if activeBv and activeBg then 
                activeBv.Velocity = direction * self.Config.FlySpeed
                activeBg.CFrame = Camera.CFrame
            end
        end)
    else
        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        if hrp:FindFirstChild("VelocityFlyBV") then hrp.VelocityFlyBV:Destroy() end
        if hrp:FindFirstChild("VelocityFlyBG") then hrp.VelocityFlyBG:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end

-- [ MASTER PHYSICS LOOP ] --
Velocity.Connections.PhysicsLoop = RunService.Heartbeat:Connect(function(deltaTime)
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    if Velocity.State.ModifySpeed then hum.WalkSpeed = Velocity.Config.WalkSpeed end
    if Velocity.State.ModifyJump then 
        hum.UseJumpPower = false
        hum.JumpHeight = Velocity.Config.JumpHeight 
    end

    local moveDir = hum.MoveDirection
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {GetCharacter()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    if moveDir.Magnitude > 0 then
        if Velocity.State.CFrameWalk and not Velocity.State.Bhop then
            local speedDiff = Velocity.Config.CFrameSpeed - hum.WalkSpeed
            if speedDiff > 0 then
                local offset = moveDir * (speedDiff * deltaTime)
                local ray = Workspace:Raycast(hrp.Position, offset, rayParams)
                if not ray then hrp.CFrame += offset end 
            end
        end

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
    local hrp = GetRootPart()
    if not hrp then return end

    if self.State.IsTravelling then 
        self.State.AbortTravel = true
        return 
    end

    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {GetCharacter()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
    
    if rayResult then
        local hitPos = rayResult.Position
        local targetCFrame = CFrame.new(hitPos + Vector3.new(0, 3, 0))

        if not self.State.TravelMode then
            hrp.CFrame = targetCFrame
        else
            self.State.IsTravelling = true
            self.State.AbortTravel = false
            
            local distance = (hrp.Position - targetCFrame.Position).Magnitude
            local estimatedTime = distance / self.Config.TravelSpeed
            local maxAllowedTime = estimatedTime + 5 
            local startTime = os.clock()
            
            local travelCollisions = {}
            for _, part in ipairs(GetCharacter():GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    table.insert(travelCollisions, part)
                end
            end
            
            self.Connections.TravelNoclip = RunService.Stepped:Connect(function()
                for _, part in ipairs(travelCollisions) do
                    if part and part.Parent then part.CanCollide = false end
                end
            end)
            
            local function EndTravel()
                if self.Connections.TravelLoop then self.Connections.TravelLoop:Disconnect() end
                if self.Connections.TravelNoclip then self.Connections.TravelNoclip:Disconnect() end
                
                for _, part in ipairs(travelCollisions) do
                    if part and part.Parent then part.CanCollide = true end
                end
                
                self.State.IsTravelling = false
                self.State.AbortTravel = false
                
                local currentHrp = GetRootPart()
                if currentHrp then currentHrp.AssemblyLinearVelocity = Vector3.new(0,0,0) end
            end
            
            self.Connections.TravelLoop = RunService.Heartbeat:Connect(function(deltaTime)
                local currentHrp = GetRootPart()
                
                if not currentHrp or self.State.AbortTravel then 
                    EndTravel()
                    return
                end

                local currentDist = (currentHrp.Position - targetCFrame.Position).Magnitude
                
                if (os.clock() - startTime) > maxAllowedTime or currentDist <= 2 then
                    EndTravel()
                    return
                end
                
                local travelDir = (targetCFrame.Position - currentHrp.Position).Unit
                currentHrp.CFrame += travelDir * (self.Config.TravelSpeed * deltaTime)
                currentHrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            end)
        end
    end
end

-- ========================================================================= --
--                            DESTRUCTION API                                --
-- ========================================================================= --
function Velocity:Unload()
    -- 1. Disconnect all engine loops and events
    for name, connection in pairs(self.Connections) do
        if connection then connection:Disconnect() end
    end
    self.Connections = {}
    
    -- 2. Wipe custom keybinds
    self.Binds = {}
    
    -- 3. Restore Vanilla Character Physics
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.UseJumpPower = true
        hum.JumpPower = 50
        hum.JumpHeight = 7.2
        hum.PlatformStand = false -- Ensures they don't get stuck hovering
    end
    
    -- 4. Clean up map collisions (if Noclip or Travel was active)
    for _, part in ipairs(self.OriginalCollisions) do
        if part and part.Parent then part.CanCollide = true end
    end
    self.OriginalCollisions = {}
    
    -- 5. Destroy injected objects (Flight BodyVelocity & BodyGyro)
    local hrp = GetRootPart()
    if hrp then
        local activeBv = hrp:FindFirstChild("VelocityFlyBV")
        if activeBv then activeBv:Destroy() end
        local activeBg = hrp:FindFirstChild("VelocityFlyBG")
        if activeBg then activeBg:Destroy() end
        
        hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
    
    -- 6. Reset Internal State memory
    for key, _ in pairs(self.State) do
        self.State[key] = false
    end
end

return Velocity
