AddCSLuaFile()

ENT.Base = "base_nextbot"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.Category = "My Addon"
ENT.PrintName = "Famous Person Nextbot"
ENT.Author = "Your Name"

ENT.Model = "models/props/cs_assault/Billboard.mdl"
ENT.SoundFile = "vo/npc/female01/hi01.wav"

ENT.HP = 100
ENT.MaxHP = 100
ENT.HBarHeight = 50
ENT.HBarOffset = Vector(0, 0, 80)

function ENT:Initialize()
    self:SetModel(self.Model)
    self:SetSolid(SOLID_BBOX)
    self:SetMoveType(MOVETYPE_STEP)
    self.loco:SetStepHeight(18)
    self.loco:SetJumpHeight(45)

    self:SetHealth(self.HP)
    self:SetMaxHealth(self.MaxHP)

    if SERVER then
        self.sound = CreateSound(self, self.SoundFile)
        self.sound:Play()
        self.sound:SetSoundLevel(75)
    end
end

function ENT:OnRemove()
    if SERVER then
        self.sound:Stop()
    end
end

function ENT:OnContact(ent)
    if ent:IsPlayer() then
        ent:TakeDamage(100, self, self)
    end
end

function ENT:OnInjured(dmg)
    self:SetHealth(self:Health() - dmg:GetDamage())

    if self:Health() <= 0 then
        self:OnKilled(dmg:GetAttacker(), dmg:GetInflictor())
    end
end

function ENT:OnKilled(attacker, inflictor)
    self:SetHealth(0)
    self:SetSolid(SOLID_NONE)
    self:BecomeRagdoll(DamageInfo())
    self.sound:Stop()
end

function ENT:FindEnemy()
    local enemies = ents.FindInSphere(self:GetPos(), 1000)
    local closestDist = math.huge
    local closestEnemy = nil

    for _, enemy in pairs(enemies) do
        if enemy:IsPlayer() and enemy:Alive() then
            local dist = self:GetPos():Distance(enemy:GetPos())
            if dist < closestDist then
                closestDist = dist
                closestEnemy = enemy
            end
        end
    end

    return closestEnemy
end

function ENT:ChaseEnemy(enemy)
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(20)
    path:Compute(self, enemy:GetPos())

    while path:IsValid() and enemy:Alive() do
        path:Update(self)
        if self.loco:IsStuck() then
            self:HandleStuck()
            return
        end

        if self:GetRangeToEntity(enemy) <= 70 then
            self:AttackEnemy(enemy)
            break
        end

        coroutine.yield()
    end
end

function ENT:AttackEnemy(enemy)
    self.loco:FaceTowards(enemy:GetPos())

    timer.Simple(1, function()
        if IsValid(self) and IsValid(enemy) and self:GetRangeToEntity(enemy) <= 70 then
            enemy:TakeDamage(10, self, self)
            self:AttackEnemy(enemy)
        end
    end)
end

function ENT:RunBehaviour()
    while true do
        local enemy = self:GetEnemy()
        if not IsValid(enemy) then
            enemy = self:FindEnemy()
            if not IsValid(enemy) then
                coroutine.yield()
                continue
            end
        end

        self:ResetSequence("Run")

        while IsValid(enemy) do
            self.loco:FaceTowards(enemy:GetPos())
            self.loco:SetDesiredSpeed(200)

            local dist = self:GetRangeToEntity(enemy)

            if dist < 70 then
                self:AttackEnemy(enemy)
                coroutine.yield()
                continue
            end

            self:ChaseEnemy(enemy)

            coroutine.yield()
        end

        coroutine.yield()
    end
end

function ENT:FindEnemy()
    local enemies = ents.FindByClass("npc_*")
    enemies = table.Add(enemies, player.GetAll())

    local closest = nil
    local minDist = math.huge

    for _, enemy in pairs(enemies) do
        if not IsValid(enemy) or not enemy:Alive() or enemy == self then
            continue
        end

        local dist = self:GetRangeToEntity(enemy)
        if dist < minDist then
            minDist = dist
            closest = enemy
        end
    end

    self:SetEnemy(closest)
    return closest
end

function ENT:ChaseEnemy(enemy)
    local path = Path("Follow")
    path:SetMinLookAheadDistance(300)
    path:SetGoalTolerance(20)
    path:Compute(self, enemy:GetPos())

    if not path:IsValid() then
        return "failed"
    end

    while path:IsValid() and IsValid(enemy) do
        if self:GetRangeToEntity(enemy) <= 70 then
            self:AttackEnemy(enemy)
            return
        end

        path:Update(self)
        coroutine.yield()
    end

    return "ok"
end

function ENT:AttackEnemy(enemy)
    self:ResetSequence("Melee")

    local dist = self:GetRangeToEntity(enemy)
    while dist < 70 do
        self.loco:SetDesiredSpeed(0)
        self:ResetSequence("Melee")
        self.loco:SetDesiredSpeed(200)
        dist = self:GetRangeToEntity(enemy)
        coroutine.yield()
    end
end
