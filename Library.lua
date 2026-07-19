-- Velocity by Vhyse | v2.0

local Velocity = {
    State = {
        Fly = false,
        Noclip = false,
        Bhop = false,
        CFrameWalk = false,
        TravelMode = false,
        IsTravelling = false,
        AbortTravel = false,
        ModifySpeed = false,
        ModifyJump = false,
        AirJump = false
    },
    
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
    OriginalCollisions = {},
    RayParams = RaycastParams.new()
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

Velocity.RayParams.FilterType = Enum.RaycastFilterType.Exclude

local function GetCharacter()
    return LocalPlayer.Character
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end

function Velocity:Bind(keyCode, callback)
    self.Binds[keyCode] = callback
end

Velocity.Connections.InputListener = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if Velocity.Binds[input.KeyCode] then
        Velocity.Binds[input.KeyCode]()
    end
end)

Velocity.Connections.RespawnHook = LocalPlayer.CharacterAdded:Connect(function(newChar)
    Velocity.RayParams.FilterDescendantsInstances = {newChar}
    
    task.spawn(function()
        newChar:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.2) 
        
        if Velocity.State.Noclip then Velocity:ToggleNoclip(true) end
        if Velocity.State.Fly then Velocity:ToggleFly(true) end
    end)
end)

if LocalPlayer.Character then
    Velocity.RayParams.FilterDescendantsInstances = {LocalPlayer.Character}
end

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

function Velocity:ToggleAirJump(state)
    self.State.AirJump = state
    
    if state then
        if self.Connections.AirJump then self.Connections.AirJump:Disconnect() end
        self.Connections.AirJump = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            
            if input.KeyCode == Enum.KeyCode.Space then
                local hum = GetHumanoid()
                if hum and (hum:GetState() == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air) then
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        if self.Connections.AirJump then 
            self.Connections.AirJump:Disconnect() 
            self.Connections.AirJump = nil
        end
    end
end

function Velocity:ToggleNoclip(state)
    self.State.Noclip = state
    if state then
        table.clear(self.OriginalCollisions)
        local char = GetCharacter()
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    table.insert(self.OriginalCollisions, part)
                end
            end
        end
        if self.Connections.Noclip then self.Connections.Noclip:Disconnect() end
        self.Connections.Noclip = RunService.Stepped:Connect(function()
            for _, part in ipairs(self.OriginalCollisions) do
                if part.Parent then part.CanCollide = false end
            end
        end)
    else
        if self.Connections.Noclip then self.Connections.Noclip:Disconnect() end
        for _, part in ipairs(self.OriginalCollisions) do
            if part.Parent then part.CanCollide = true end
        end
        table.clear(self.OriginalCollisions)
    end
end

function Velocity:ToggleFly(state)
    self.State.Fly = state
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    
    if not hrp or not hum then return end

    if state then
        local att = hrp:FindFirstChild("VelocityFlyAtt") or Instance.new("Attachment")
        att.Name = "VelocityFlyAtt"
        att.Parent = hrp

        local ao = Instance.new("AlignOrientation")
        ao.Name = "VelocityFlyAO"
        ao.Attachment0 = att
        ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
        ao.RigidityEnabled = true
        ao.Parent = hrp

        local lv = Instance.new("LinearVelocity")
        lv.Name = "VelocityFlyLV"
        lv.Attachment0 = att
        lv.MaxForce = math.huge
        lv.VectorVelocity = Vector3.zero
        lv.RelativeTo = Enum.ActuatorRelativeTo.World
        lv.Parent = hrp

        hum.PlatformStand = true
        
        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        self.Connections.Fly = RunService.Heartbeat:Connect(function()
            local currentHrp = GetRootPart()
            if not currentHrp then return end
            
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then direction += Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then direction -= Vector3.yAxis end

            if direction.Magnitude > 0 then
                direction = direction.Unit
            end

            local activeLv = currentHrp:FindFirstChild("VelocityFlyLV")
            local activeAo = currentHrp:FindFirstChild("VelocityFlyAO")
            
            if activeLv and activeAo then 
                activeLv.VectorVelocity = direction * self.Config.FlySpeed
                activeAo.CFrame = Camera.CFrame
            end
        end)
    else
        if self.Connections.Fly then self.Connections.Fly:Disconnect() end
        if hrp:FindFirstChild("VelocityFlyLV") then hrp.VelocityFlyLV:Destroy() end
        if hrp:FindFirstChild("VelocityFlyAO") then hrp.VelocityFlyAO:Destroy() end
        if hrp:FindFirstChild("VelocityFlyAtt") then hrp.VelocityFlyAtt:Destroy() end
        if hum then hum.PlatformStand = false end
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
end

Velocity.Connections.PhysicsLoop = RunService.Heartbeat:Connect(function(deltaTime)
    local hrp = GetRootPart()
    local hum = GetHumanoid()
    if not hrp or not hum then return end

    if Velocity.State.ModifySpeed and hum.WalkSpeed ~= Velocity.Config.WalkSpeed then 
        hum.WalkSpeed = Velocity.Config.WalkSpeed 
    end
    
    if Velocity.State.ModifyJump and hum.JumpHeight ~= Velocity.Config.JumpHeight then 
        hum.UseJumpPower = false
        hum.JumpHeight = Velocity.Config.JumpHeight 
    end

    local moveDir = hum.MoveDirection

    if moveDir.Magnitude > 0 then
        if Velocity.State.CFrameWalk and not Velocity.State.Bhop then
            local speedDiff = Velocity.Config.CFrameSpeed - hum.WalkSpeed
            if speedDiff > 0 then
                local offset = moveDir * (speedDiff * deltaTime)
                local ray = Workspace:Raycast(hrp.Position, offset, Velocity.RayParams)
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
                    local ray = Workspace:Raycast(hrp.Position, offset, Velocity.RayParams)
                    if not ray then hrp.CFrame += offset end
                end
            end
        end
    end
end)

function Velocity:ExecuteClickAction()
    local hrp = GetRootPart()
    if not hrp then return end

    if self.State.IsTravelling then 
        self.State.AbortTravel = true
        return 
    end

    local unitRay = Camera:ScreenPointToRay(Mouse.X, Mouse.Y)
    local rayResult = Workspace:Raycast(unitRay.Origin, unitRay.Direction * 1000, self.RayParams)
    
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
            local char = GetCharacter()
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        table.insert(travelCollisions, part)
                    end
                end
            end
            
            self.Connections.TravelNoclip = RunService.Stepped:Connect(function()
                for _, part in ipairs(travelCollisions) do
                    if part.Parent then part.CanCollide = false end
                end
            end)
            
            local function EndTravel()
                if self.Connections.TravelLoop then self.Connections.TravelLoop:Disconnect() end
                if self.Connections.TravelNoclip then self.Connections.TravelNoclip:Disconnect() end
                
                for _, part in ipairs(travelCollisions) do
                    if part.Parent then part.CanCollide = true end
                end
                table.clear(travelCollisions)
                
                self.State.IsTravelling = false
                self.State.AbortTravel = false
                
                local currentHrp = GetRootPart()
                if currentHrp then currentHrp.AssemblyLinearVelocity = Vector3.zero end
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
                currentHrp.AssemblyLinearVelocity = Vector3.zero
            end)
        end
    end
end

function Velocity:Unload()
    for _, connection in pairs(self.Connections) do
        if typeof(connection) == "RBXScriptConnection" and connection.Connected then 
            connection:Disconnect() 
        end
    end
    table.clear(self.Connections)
    table.clear(self.Binds)
    
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.UseJumpPower = true
        hum.JumpPower = 50
        hum.JumpHeight = 7.2
        hum.PlatformStand = false 
    end
    
    for _, part in ipairs(self.OriginalCollisions) do
        if part.Parent then part.CanCollide = true end
    end
    table.clear(self.OriginalCollisions)
    
    local hrp = GetRootPart()
    if hrp then
        local activeLv = hrp:FindFirstChild("VelocityFlyLV")
        if activeLv then activeLv:Destroy() end
        local activeAo = hrp:FindFirstChild("VelocityFlyAO")
        if activeAo then activeAo:Destroy() end
        local activeAtt = hrp:FindFirstChild("VelocityFlyAtt")
        if activeAtt then activeAtt:Destroy() end
        
        hrp.AssemblyLinearVelocity = Vector3.zero
    end
    
    for key, _ in pairs(self.State) do
        self.State[key] = false
    end
end

return Velocity
