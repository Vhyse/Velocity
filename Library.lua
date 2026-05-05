-- ========================================================================= --
--                         VELOCITY MOVEMENT ENGINE                          --
-- ========================================================================= --

local Velocity = {
    -- Current States
    State = {
        Fly = false,
        Noclip = false,
        Bhop = false,
        CFrameWalk = false,
        TravelMode = false,
        IsTravelling = false
    },
    
    -- Default Configurations
    Config = {
        FlySpeed = 50,
        BhopSpeed = 50,
        CFrameSpeed = 50,
        TravelSpeed = 100
    },
    
    -- Internal memory
    Connections = {},
    Binds = {},
    OriginalCollisions = {}
}

-- Services
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
-- Allows any script using Velocity to bind keys directly to functions
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
    local char = GetCharacter()
    return char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char:FindFirstChildOfClass("Humanoid")
end

-- ========================================================================= --
--                            BASIC MODIFIERS                                --
-- ========================================================================= --
function Velocity:SetWalkSpeed(value)
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = value end
end

function Velocity:SetJumpHeight(value)
    local hum = GetHumanoid()
    if hum then 
        hum.UseJumpPower = false
        hum.JumpHeight = value 
    end
end

-- ========================================================================= --
--                            ADVANCED FEATURES                              --
-- ========================================================================= --

-- [ NOCLIP ] --
function Velocity:ToggleNoclip(state)
    self.State.Noclip = state
    
    if state then
        -- Cache parts that actually have collision by default
        self.OriginalCollisions = {}
        for _, part in ipairs(GetCharacter():GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide then
                table.insert(self.OriginalCollisions, part)
            end
        end

        -- Bind to Stepped (fires right before physics simulation)
        self.Connections.Noclip = RunService.Stepped:Connect(function()
            for _, part in ipairs(self.OriginalCollisions) do
                if part and part.Parent then
                    part.CanCollide = false -- Forces it false, overriding game updates
                end
            end
        end)
    else
        if self.Connections.Noclip then self.Connections.Noclip:Disconnect() end
        -- Revert collisions
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
        -- Create BodyVelocity for smooth flight
        local bv = Instance.new("BodyVelocity")
        bv.Name = "VelocityFly"
        bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
        bv.Velocity = Vector3.new(0, 0, 0)
        bv.Parent = hrp

        -- Fly loop
        self.Connections.Fly = RunService.RenderStepped:Connect(function()
            local moveVector = Vector3.new(0, 0, 0)
            
            -- WASD standard movement relative to camera
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector += Camera.CFrame.RightVector end
            
            -- Q/E Vertical Movement
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then moveVector += Vector3.new(0, 1, 0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then moveVector -= Vector3.new(0, 1, 0) end

            if moveVector.Magnitude > 0 then moveVector = moveVector.Unit end
            bv.Velocity = moveVector * self.Config.FlySpeed
        end)
    else
        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        if hrp:FindFirstChild("VelocityFly") then hrp.VelocityFly:Destroy() end
    end
end

-- [ CFRAME WALK & BUNNY HOP ] --
-- Merged into one heartbeat loop to prevent math conflicts
Velocity.Connections.CFrameMath = RunService.Heartbeat:Connect(function(deltaTime)
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    local moveDir = hum.MoveDirection

    -- Raycast parameters to prevent wall clipping
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {GetCharacter()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    if moveDir.Magnitude > 0 then
        -- Handle CFrame Walk
        if Velocity.State.CFrameWalk and not Velocity.State.Bhop then
            local speedDiff = Velocity.Config.CFrameSpeed - hum.WalkSpeed
            if speedDiff > 0 then
                local offset = moveDir * (speedDiff * deltaTime)
                local ray = Workspace:Raycast(hrp.Position, offset, rayParams)
                if not ray then hrp.CFrame += offset end -- Only move if no wall is in front
            end
        end

        -- Handle Bunny Hop
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
    if self.State.IsTravelling then return end -- Prevent overlapping travels
    
    local hrp = GetRootPart()
    if not hrp then return end

    -- Raycast from Camera to Mouse to get the exact hit normal (surface direction)
    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {GetCharacter()}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local rayResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, rayParams)
    
    if rayResult then
        local hitPos = rayResult.Position
        local normal = rayResult.Normal

        -- Prevent teleporting ON TOP of walls by pushing the target position slightly away from the hit surface
        -- If normal is Y=1, we clicked a floor. If X or Z is 1, we clicked a wall.
        local safePos = hitPos + (normal * 3) + Vector3.new(0, 3, 0) -- 3 studs away from surface, 3 studs up to account for legs

        if not self.State.TravelMode then
            -- Standard Teleport
            hrp.CFrame = CFrame.new(safePos)
        else
            -- Travel Mode with Failsafe Math
            self.State.IsTravelling = true
            local distance = (hrp.Position - safePos).Magnitude
            local estimatedTime = distance / self.Config.TravelSpeed
            local maxAllowedTime = estimatedTime + 5 -- The +5 seconds failsafe
            
            local startTime = os.clock()
            local travelConnection
            
            travelConnection = RunService.Heartbeat:Connect(function(deltaTime)
                local currentDist = (hrp.Position - safePos).Magnitude
                
                -- Failsafe: Did we get stuck behind a wall?
                if (os.clock() - startTime) > maxAllowedTime then
                    travelConnection:Disconnect()
                    self.State.IsTravelling = false
                    warn("Velocity: Travel aborted. Stuck behind anti-cheat wall.")
                    return
                end
                
                -- Destination reached?
                if currentDist <= 2 then
                    travelConnection:Disconnect()
                    self.State.IsTravelling = false
                    return
                end
                
                -- Move character towards target
                local travelDir = (safePos - hrp.Position).Unit
                hrp.CFrame += travelDir * (self.Config.TravelSpeed * deltaTime)
                -- Optional: Freeze Y axis if you want grounded travel, or leave it for straight-line flying travel
            end)
        end
    end
end

return Velocity
