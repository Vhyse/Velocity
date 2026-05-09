-- ========================================================================= --
--                   VELOCITY v1.6 API SHOWCASE SCRIPT                       --
-- ========================================================================= --

-- [ 1. INITIALIZE THE ENGINE ]
local success, Velocity = pcall(function() 
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vhyse/Velocity/refs/heads/main/Library.lua"))() 
end)

if not success then
    return warn("[ Velocity Showcase ] Critical Error: Failed to load the engine.")
end

-- [ 2. CONFIGURE SPEEDS & VALUES ]
-- Covers all 6 configurable values in the engine
Velocity.Config.WalkSpeed = 75
Velocity.Config.JumpHeight = 100
Velocity.Config.FlySpeed = 150
Velocity.Config.CFrameSpeed = 120
Velocity.Config.BhopSpeed = 130
Velocity.Config.TravelSpeed = 250

-- [ 3. STANDARD MODIFIERS ]
Velocity:ToggleSpeedModifier(true)
Velocity:ToggleJumpModifier(true)
print("[ Velocity ] Speed and Jump modifiers are now ACTIVE.")

-- [ 4. BINDING ADVANCED PHYSICS ]

-- Noclip (Toggle with 'N')
local noclipActive = false
Velocity:Bind(Enum.KeyCode.N, function()
    noclipActive = not noclipActive
    Velocity:ToggleNoclip(noclipActive)
    print("[ Velocity ] Noclip state: " .. tostring(noclipActive))
end)

-- Vector Flight (Toggle with 'F')
local flightActive = false
Velocity:Bind(Enum.KeyCode.F, function()
    flightActive = not flightActive
    Velocity:ToggleFly(flightActive)
    print("[ Velocity ] Flight state: " .. tostring(flightActive))
end)

-- CFrame Walk Bypass (Toggle with 'C')
local cframeActive = false
Velocity:Bind(Enum.KeyCode.C, function()
    cframeActive = not cframeActive
    Velocity.State.CFrameWalk = cframeActive
    print("[ Velocity ] CFrame Walk state: " .. tostring(cframeActive))
end)

-- Bunny Hop Bypass (Toggle with 'B') - ADDED
local bhopActive = false
Velocity:Bind(Enum.KeyCode.B, function()
    bhopActive = not bhopActive
    Velocity.State.Bhop = bhopActive
    print("[ Velocity ] Bunny Hop state: " .. tostring(bhopActive))
end)

-- [ 5. TELEPORTATION / TRAVEL ]
-- Toggle TravelMode (True = Phasing / False = Instant TP)
Velocity.State.TravelMode = true 

Velocity:Bind(Enum.KeyCode.T, function()
    Velocity:ExecuteClickAction()
    print("[ Velocity ] Traveling to cursor position...")
end)

print("[ Velocity Showcase ] Fully loaded. Binds: N (Noclip), F (Flight), C (CFrame), B (Bhop), T (Travel).")
