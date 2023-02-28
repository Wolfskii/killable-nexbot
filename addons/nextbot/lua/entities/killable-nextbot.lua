AddCSLuaFile()

ENT.Base 			= "base_nextbot"
ENT.Spawnable		= true

function ENT:Initialize()
	self:SetModel( "models/player/zombie_classic.mdl" )
	self.health = 100

	if SERVER then
		self.loco:SetStepHeight( 18 )
	end

	self.loco:SetDeathDropHeight( 1000 )	

	self.loco:SetAcceleration( 900 )	
	self.loco:SetDeceleration( 1200 )	

	self.loco:SetJumpHeight( 58 )	

	self.loco:SetMaxYawRate( 360 )	
	self.loco:SetDesiredSpeed( 100 )	

	self.loco:SetGravity( 1 )		

	self:SetCollisionBounds( Vector(-16,-16,0), Vector(16,16,72) )

	self:SetHealth( self.health )

	self.loco:SetDeathDropHeight( 1000 )

	if SERVER then
		self:SetMaxHealth( self.health )
	end

	self.NextIdleSoundTime = CurTime() + math.random( 10, 20 )
end

function ENT:OnInjured( dmginfo )
	self.health = self.health - dmginfo:GetDamage()
	self:SetHealth( self.health )

	if self.health <= 0 then
		self:OnKilled()
	end
end

function ENT:OnKilled()
	self:BecomeRagdoll( dmginfo )
end

function ENT:RunBehaviour()
	while true do
		if self.enemy then
			self:ChaseEnemy()
		else
			self:SearchEnemy()
		end

		coroutine.yield()
	end
end

function ENT:SearchEnemy()
	local targets = ents.FindInSphere( self:GetPos(), self.SearchRadius )
	local enemy = nil
	local dist = self.LoseTargetDist

	for k, v in pairs( targets ) do
		if v:IsPlayer() and v:Alive() then
			local thisDist = self:GetPos():DistToSqr( v:GetPos() )

			if thisDist < dist then
				enemy = v
				dist = thisDist
			end
		end
	end

	if enemy then
		self.enemy = enemy
	end

	coroutine.wait( 1 )
end

function ENT:ChaseEnemy()
	self.loco:FaceTowards( self.enemy:GetPos() )

	if self:GetRangeTo( self.enemy:GetPos() ) > self.LoseTargetDist then
		self.enemy = nil
		return
	end

	if self:CanAttack( self.enemy ) then
		self:AttackEnemy()
	else
		self:MoveToEnemy()
	end
end

function ENT:MoveToEnemy()
	self.loco:FaceTowards( self.enemy:GetPos() )
	self.loco:SetDesiredSpeed( 200 )

	self:PlayIdleSound()

	local path = Path( "Follow" )
	path:SetMinLookAheadDistance( 300 )
	path:SetGoalTolerance( 20 )
	path:Compute( self, self.enemy:GetPos() )

	if not path:IsValid() then return end

	while path:IsValid() and self.enemy do
		if self:CanAttack( self.enemy ) then
			self:AttackEnemy()
			return
		end

		path:Update( self )

		if self:GetRangeTo( self.enemy:GetPos() ) < 200 then
			self.loco:SetDesiredSpeed( 0 )
		else
			self.loco:SetDesiredSpeed( 200 )
		end

		coroutine.yield()
	end
end

function ENT:CanAttack( ent )
    -- If the enemy is not a player or nextbot, then we can't attack it
    if not (ent:IsPlayer() or ent:GetClass():StartWith("nextbot")) then
        return false
    end

    -- If the enemy is dead or not valid, then we can't attack it
    if not IsValid(ent) or not ent:Alive() then
        return false
    end

    -- If the enemy is too far away, then we can't attack it
    if self:GetRangeTo(ent) > self.AttackRange then
        return false
    end

    -- If we're not facing the enemy, then we can't attack it
    local targetDir = (ent:GetPos() - self:GetPos()):GetNormalized()
    local facingDir = self:GetForward()
    if targetDir:Dot(facingDir) < 0.5 then
        return false
    end

    return true
end

function ENT:OnInjured( dmginfo )
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then
        self:OnKilled(dmginfo:GetAttacker(), dmginfo:GetInflictor())
    end
end

function ENT:OnKilled( attacker, inflictor )
    self:SetModel("models/XQM/Rails/gumball_1.mdl") -- change model on death
    self:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- disable collision
    self:BecomeRagdoll(dmginfo)
    timer.Simple(10, function() self:Remove() end) -- remove after some time
end

function ENT:RunBehaviour()
    while true do
        if not self.IsAlerted then -- if not alerted, patrol
            self:StartActivity(ACT_WALK)
            self.loco:SetDesiredSpeed(50)
            self:Patrol()
        else -- if alerted, chase and attack
            local enemy = self:GetEnemy()
            if not IsValid(enemy) then -- if enemy is not valid, search for one
                self:SearchEnemy()
            else
                if self:CanAttack(enemy) then -- if enemy is valid and within range, attack
                    self:StartActivity(ACT_MELEE_ATTACK1)
                    self.loco:SetDesiredSpeed(0)
                    self:FaceEnemy()
                    self:AttackEnemy()
                else -- if enemy is valid but not within range, chase
                    self:StartActivity(ACT_RUN)
                    self.loco:SetDesiredSpeed(200)
                    self:ChaseEnemy()
                end
            end
        end
        coroutine.yield()
    end
end
