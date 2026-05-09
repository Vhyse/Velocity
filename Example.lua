-- ========================================================================= --
--                   VELOCITY v1.5 API SHOWCASE SCRIPT                       --
-- ========================================================================= --

-- [ 1. INITIALIZE THE ENGINE ]
-- Replace the URL with your raw GitHub link where you hosted Velocity.lua
local success, Velocity = pcall(function() 
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Vhyse/Velocity/refs/heads/main/Library.lua"))() 
end)

if not success then
    return warn("[ Velocity Showcase ] Critical Error: Failed to load the engine.")
end

-- [ 2. CONFIGURE SPEEDS & VALUES ]
-- You can change these on the fly at any time, but here are our defaults:
Velocity.Config.WalkSpeed = 75
Velocity.Config.JumpHeight = 100
Velocity.Config.FlySpeed = 150
Velocity.Config.CFrameSpeed = 120
Velocity.Config.TravelSpeed = 250

-- [ 3. STANDARD MODIFIERS ]
-- Let's turn on the basic speed and jump bypasses immediately upon injection.
Velocity:ToggleSpeedModifier(true)
Velocity:ToggleJumpModifier(true)
print("[ Velocity ] Speed and Jump modifiers are now ACTIVE.")

-- [ 4. BINDING ADVANCED PHYSICS ]
-- We will use Velocity's native :Bind() function to set up hotkeys.

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

-- [ 5. TELEPORTATION / TRAVEL ]
-- We will enable safe phasing so we don't hit anti-cheats, and bind it to 'T'.
Velocity.State.TravelMode = true 

Velocity:Bind(Enum.KeyCode.T, function()
    -- This function automatically calculates the mouse position and glides you there
    Velocity:ExecuteClickAction()
    print("[ Velocity ] Traveling to cursor position...")
end)

print("[ Velocity Showcase ] Successfully loaded. Press N, F, C, or T to test features.")
