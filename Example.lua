-- ========================================================================= --
--                   VELOCITY v1.6 API SHOWCASE SCRIPT                       --
--                          (Full Keybind Update)                            --
-- ========================================================================= --

-- [ 1. INITIALIZE THE ENGINE ]
local success, Velocity = pcall(function() 
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vhyse/Velocity/refs/heads/main/Library.lua"))() 
end)

if not success then
    return warn("[ Velocity Showcase ] Critical Error: Failed to load the engine.")
end

-- [ 2. CONFIGURE SPEEDS & VALUES ]
Velocity.Config.WalkSpeed = 75
Velocity.Config.JumpHeight = 100
Velocity.Config.FlySpeed = 150
Velocity.Config.CFrameSpeed = 120
Velocity.Config.BhopSpeed = 130
Velocity.Config.TravelSpeed = 250

-- [ 3. BINDING ADVANCED PHYSICS ]

-- WalkSpeed Bypass (Toggle with 'Z')
Velocity:Bind(Enum.KeyCode.Z, function()
    local newState = not Velocity.State.ModifySpeed
    Velocity:ToggleSpeedModifier(newState)
    print("[ Velocity ] Speed Modifier state: " .. tostring(newState))
end)

-- JumpHeight Bypass (Toggle with 'X')
Velocity:Bind(Enum.KeyCode.X, function()
    local newState = not Velocity.State.ModifyJump
    Velocity:ToggleJumpModifier(newState)
    print("[ Velocity ] Jump Modifier state: " .. tostring(newState))
end)

-- Noclip (Toggle with 'N')
Velocity:Bind(Enum.KeyCode.N, function()
    local newState = not Velocity.State.Noclip
    Velocity:ToggleNoclip(newState)
    print("[ Velocity ] Noclip state: " .. tostring(newState))
end)

-- Vector Flight (Toggle with 'F')
Velocity:Bind(Enum.KeyCode.F, function()
    local newState = not Velocity.State.Fly
    Velocity:ToggleFly(newState)
    print("[ Velocity ] Flight state: " .. tostring(newState))
end)

-- CFrame Walk Bypass (Toggle with 'C')
Velocity:Bind(Enum.KeyCode.C, function()
    local newState = not Velocity.State.CFrameWalk
    Velocity.State.CFrameWalk = newState
    print("[ Velocity ] CFrame Walk state: " .. tostring(newState))
end)

-- Bunny Hop Bypass (Toggle with 'B')
Velocity:Bind(Enum.KeyCode.B, function()
    local newState = not Velocity.State.Bhop
    Velocity.State.Bhop = newState
    print("[ Velocity ] Bunny Hop state: " .. tostring(newState))
end)

-- [ 4. TELEPORTATION / TRAVEL ]
Velocity.State.TravelMode = true 

Velocity:Bind(Enum.KeyCode.T, function()
    Velocity:ExecuteClickAction()
    print("[ Velocity ] Traveling to cursor position...")
end)

-- [ 5. UNLOAD ENGINE ]
-- Press 'Delete' to wipe the engine from memory and restore vanilla physics
Velocity:Bind(Enum.KeyCode.Delete, function()
    Velocity:Unload()
    print("[ Velocity ] Engine completely unloaded. Vanilla physics restored.")
end)

print("[ Velocity Showcase ] Fully loaded.")
print("[ Binds ] Z (Speed), X (Jump), N (Noclip), F (Flight), C (CFrame), B (Bhop), T (Travel), DEL (Unload)")
