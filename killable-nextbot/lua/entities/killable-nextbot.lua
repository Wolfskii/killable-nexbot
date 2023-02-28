AddCSLuaFile()

-- https://wiki.facepunch.com/gmod/NextBot_NPC_Creation
-- https://www.youtube.com/watch?v=tda_7yimmNQ

ENT.Base = "base_nextbot"
ENT.Spawnable = true

-- Model for the NextBot
ENT.Model = "models/player/combine_soldier.mdl"

-- Health for the NextBot
ENT.Health = 100

-- Speed for the NextBot
ENT.Speed = 100

-- Damage for the NextBot's attack
ENT.Damage = 10

-- Name of the NextBot for the spawn menu
ENT.PrintName = "My NextBot"

-- Category for the spawn menu
ENT.Category = "My NextBot Category"

-- Initializes the NextBot
function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetHealth(self.Health)
    self:SetMaxHealth(self.Health)
    self:SetSpeed(self.Speed)
    self:SetDamage(self.Damage)
    self:SetSolid(SOLID_BBOX)
    self:SetCollisionGroup(COLLISION_GROUP_PLAYER)

    if SERVER then
        self:SetUseType(SIMPLE_USE)
    end

    self.loco:SetDeathDropHeight(1000) -- How far to fall before death

    self.NextIdleSoundTime = 0
end

-- Draws the health bar above the NextBot's head
function DrawHealthBar(ent, percent)
    local pos = ent:GetPos() + Vector(0, 0, 80)
    local ang = LocalPlayer():EyeAngles()
    ang:RotateAroundAxis(ang:Forward(), 90)
    ang:RotateAroundAxis(ang:Right(), 90)

    local width = 100
    local height = 10
    local border = 1

    -- Draw the background
    draw.RoundedBox(4, pos - ang:Up() * (height / 2) - ang:Right() * (width / 2), width, height, Color(50, 50, 50, 255))

    -- Draw the health bar
    draw.RoundedBox(4, pos - ang:Up() * (height / 2) - ang:Right() * (width / 2) + Vector(border, border, 0), (width - border * 2) * percent, height - border * 2, Color(255 - 255 * percent, 255 * percent, 0, 255))
end

-- Draws the NextBot
function ENT:Draw()
    self:DrawModel()

    -- Draw the health bar
    local percent = self:Health() / self:GetMaxHealth()
    DrawHealthBar(self, percent)
end

-- Moves the NextBot
function ENT:MoveToPos(pos)
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(20)
    path:Compute(self, pos)

    if not path:IsValid() then return "failed" end

    while path:IsValid() do
        if path:GetAge() > 1 then
            path:Compute(self, pos)
        end

        path:Update(self)

        coroutine.yield()
    end

    return "ok"
end

-- Called when the NextBot sees an enemy
function ENT:OnSeenEnemy(enemy)
    self:SetEnemy(enemy)

    self:StartActivity(ACT_RUN)
    self.loco:SetDesiredSpeed(self.Speed)

    coroutine.wrap(function()
        while self:HasEnemy() do
            self:ChaseEnemy()

            coroutine.yield()
        end

        self:StopMoving()
    end)()
end

-- Called when the NextBot loses sight of the enemy
function ENT:OnLostEnemy()
    self:SetEnemy(nil) -- Clear the enemy
end

function ENT:OnKilled(damageinfo)
    self:BecomeRagdoll(damageinfo) -- Create a ragdoll and remove the entity
end

-- Override the base entity functions to draw the health above the nextbot
function ENT:Draw()
    self:DrawModel() -- Draw the model
end

function ENT:DrawTranslucent()
    self:Draw() -- Draw the model
    self:DrawBar() -- Draw the health bar
end

function ENT:DrawBar()
    local pos = self:GetPos() -- Get the position of the nextbot
    pos.z = pos.z + 80 -- Offset the position to draw the health bar above the nextbot
    local maxHealth = self:GetMaxHealth() -- Get the maximum health of the nextbot
    local health = self:Health() -- Get the current health of the nextbot
    local width = 100 -- Set the width of the health bar
    local height = 10 -- Set the height of the health bar
    local border = 2 -- Set the width of the border of the health bar
    local bgPos = Vector(pos.x - width / 2, pos.y - height / 2, pos.z) -- Calculate the position of the background of the health bar
    local healthPos = Vector(pos.x - width / 2 + border, pos.y - height / 2 + border, pos.z) -- Calculate the position of the health bar

    -- Draw the background of the health bar
    surface.SetDrawColor(255, 0, 0, 255)
    surface.DrawOutlinedRect(bgPos.x, bgPos.y, width, height)

    -- Draw the health bar
    surface.SetDrawColor(0, 255, 0, 255)
    surface.DrawRect(healthPos.x, healthPos.y, width * (health / maxHealth) - border * 2, height - border * 2)
end

-- Add the nextbot to the NPC spawn menu
list.Set("NPC", "simple_nextbot", {
    Name = "Simple Bot",
    Class = "simple_nextbot",
    Category = "Nextbot"
})
