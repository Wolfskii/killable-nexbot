AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = true

-- Initialize the NPC
function ENT:Initialize()
    self:SetModel("models/player/zombie_classic.mdl")
    self.health = 100

    -- Set the step height for the NPC's movement
    if SERVER then
        self.loco:SetStepHeight(18)
    end

    -- Set the maximum height from which the NPC can drop to its death
    self.loco:SetDeathDropHeight(1000)

    -- Set the acceleration and deceleration of the NPC's movement
    self.loco:SetAcceleration(900)
    self.loco:SetDeceleration(1200)

    -- Set the jump height of the NPC
    self.loco:SetJumpHeight(58)

    -- Set the maximum yaw rate of the NPC's movement
    self.loco:SetMaxYawRate(360)

    -- Set the desired speed of the NPC's movement
    self.loco:SetDesiredSpeed(100)

    -- Set the gravity of the NPC
    self.loco:SetGravity(1)

    -- Set the collision bounds of the NPC
    self:SetCollisionBounds(Vector(-16, -16, 0), Vector(16, 16, 72))

    -- Set the health of the NPC
    self:SetHealth(self.health)

    -- Set the maximum health of the NPC on the server
    if SERVER then
        self:SetMaxHealth(self.health)
    end

    -- Set the time until the NPC makes an idle sound
    self.NextIdleSoundTime = CurTime() + math.random(10, 20)
end

-- Handle what happens when the NPC is injured
function ENT:OnInjured(dmginfo)
    -- Decrement the NPC's health by the amount of damage inflicted
    self.health = self.health - dmginfo:GetDamage()
    self:SetHealth(self.health)

    -- If the NPC's health reaches zero or less, handle its death
    if self.health <= 0 then
        self:OnKilled()
    end
end

-- Handle what happens when the NPC is killed
function ENT:OnKilled()
    -- Create a ragdoll of the NPC
    self:BecomeRagdoll(dmginfo)
end

-- Handle the NPC's behavior
function ENT:RunBehaviour()
    -- Loop indefinitely
    while true do
        -- If the NPC has an enemy, chase it
        if self.enemy then
            self:ChaseEnemy()
        -- If the NPC doesn't have an enemy, search for one
        else
            self:SearchEnemy()
        end

        -- Yield control until the next frame
        coroutine.yield()
    end
end

-- Search for an enemy within the NPC's search radius
function ENT:SearchEnemy()
    -- Find all players within our vision cone
    local targets = ents.FindInCone(self:GetPos(), self:GetForward(), self.SearchDistance, self.SearchAngle)

    local nearestTarget = nil
    local nearestTargetDistance = math.huge

    for _, target in pairs(targets) do
        if target:IsPlayer() and target:Alive() then
            -- Calculate the distance to the target
            local distanceToTarget = self:GetPos():DistToSqr(target:GetPos())

            -- Check if the target is the nearest we've seen so far
            if distanceToTarget < nearestTargetDistance then
                nearestTarget = target
                nearestTargetDistance = distanceToTarget
            end
        end
    end

    if nearestTarget then
        self:SetEnemy(nearestTarget)
        self:AlertAllies(nearestTarget)

        -- Call OnFoundEnemy callback if it exists
        if self.OnFoundEnemy then
            self:OnFoundEnemy(nearestTarget)
        end
    end

    return nearestTarget
end

-- Add your bot to the NPC spawn tab
list.Set( "NPC", "my_nextbot", {
	Name = "My NextBot",
	Class = "my_nextbot",
	Category = "My NextBot Category"
})