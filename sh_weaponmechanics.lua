SWEP.Primary.ShotSpread						= {}
SWEP.Primary.ShotSpread.Clamp				= 4
SWEP.Primary.ShotSpread.Amount				= 0.05

SWEP.Primary.RecoilPenalty					= {}
SWEP.Primary.RecoilPenalty.AdditiveRatio	= 0.2
SWEP.Primary.RecoilPenalty.SprayClamp		= 3
SWEP.Primary.RecoilPenalty.SprayAmount		= 0.333

SWEP.Primary.RecoilHorizMin					= -0.01
SWEP.Primary.RecoilHorizMax					= 0.01

function SWEP:AddViewKick()
	local recoilAmount = self.Primary.Recoil
	
	if( self.dt.shotsFired > 0 ) then
		recoilAmount = recoilAmount + ( math.Clamp(self.dt.shotsFired, 0, self.Primary.RecoilPenalty.SprayClamp) * self.Primary.RecoilPenalty.SprayAmount )
	end

	local punchAng = ( self.Owner:GetPunchAngle() * self.Primary.RecoilPenalty.AdditiveRatio ) -- keep a bit of the current punch angle
	punchAng = punchAng + Angle( -(recoilAmount*self:GetVerticalKickMultiplier()), math.random(self.Primary.RecoilHorizMin, self.Primary.RecoilHorizMax) * self:GetHorizontalKickMultiplier(), 0 )

	self.Owner:ViewPunch( punchAng )
end

function SWEP:GetVerticalKickMultiplier()
	if(self:IsIronsighted()) then
		return self.IronsightRecoil
	end
	
	return 1.0
end

function SWEP:GetHorizontalKickMultiplier()
	return 1.0
end

function SWEP:GetShootDirection()
	return ( self.Owner:EyeAngles() + self.Owner:GetPunchAngle() ):Forward() -- shoot direction, we need to consider the punch angles as we maybe using ViewPunch for recoil
end

function SWEP:GetSpreadBias()
	
	if( self.Owner and self.Owner:IsPlayer() ) then
	
		local owner = self.Owner
		local spreadBias = 1.0
		
		if( owner:Crouching() ) then
			spreadBias = spreadBias * 0.75
		end
		
		if( self.dt.ironsighted ) then
			spreadBias = spreadBias * self.IronsightAccuracy
		end
		
		if( self.dt.shotsFired > 0 ) then
			spreadBias = spreadBias + ( math.Clamp(self.dt.shotsFired, 0, self.Primary.ShotSpread.Clamp) * self.Primary.ShotSpread.Amount )
		end
		
		spreadBias = spreadBias * math.max( (self.Owner:GetVelocity():Length() / self.Owner:GetWalkSpeed() ) * 2.0, 0.5 )

		return spreadBias
	end
	
	return 1.0
end

function SWEP:ShootBullets( damage, bullets, spread, vmidx )

	local vm = self.Owner:GetViewModel( vmidx or 0 )
	spread = spread * self:GetSpreadBias()
	
	local bullet = {}
	bullet.Num 		= numbullets
	bullet.Src 		= self.Owner:GetShootPos()	
	bullet.Dir 		= self:GetShootDirection()			
	bullet.Spread 	= Vector( spread, spread, 0 )		
	bullet.Tracer	= 0
	bullet.Force	= math.Round(damage * 2)							
	bullet.Damage	= math.Round(damage)
	bullet.AmmoType = "Pistol"
	bullet.TracerName 	= "Tracer"
	bullet.Callback = function ( attacker, tr, dmginfo )
		self.Weapon:BulletCallback( attacker, tr, dmginfo, 0 )
	end
	
	self.Owner:FireBullets( bullet )
	
	self.dt.lastShootTime = CurTime()
	self.dt.shotsFired = self.dt.shotsFired + 1
		
end

function SWEP:BulletCallback( attacker, tr, dmginfo, bounce )

	if( !self or !self.Weapon:IsValid() ) then return end
	
	self.Weapon:BulletPenetration( attacker, tr, dmginfo, bounce + 1 );
	
	return { damage = true, effect = true, effects = true };
	
end

function SWEP:GetPenetrationDistance( mat_type )

	if ( mat_type == MAT_PLASTIC || mat_type == MAT_WOOD || mat_type == MAT_FLESH || mat_type == MAT_ALIENFLESH || mat_type == MAT_GLASS ) then
		return 64
	end
	
	return 32
	
end

function SWEP:GetPenetrationDamageLoss( mat_type, distance, damage )

	if( mat_type == MAT_GLASS ) then
		return damage;
	elseif ( mat_type == MAT_PLASTIC || mat_type == MAT_WOOD || mat_type == MAT_FLESH || mat_type == MAT_ALIENFLESH || mat_type == MAT_GLASS ) then
		return damage - distance
	elseif( mat_type == MAT_DIRT ) then
		return damage - ( distance * 1.2 );
	end
	
	return damage - ( distance * 1.95 );
end

function SWEP:BulletPenetration( attacker, tr, dmginfo, bounce )

	if ( !self or !self.Weapon:IsValid() ) then return end
	
	-- Don't go through more than 3 times
	if ( bounce > 3 ) then return false end
	
	-- Direction (and length) that we are gonna penetrate
	local PeneDir = tr.Normal * self:GetPenetrationDistance( tr.MatType )
		
	local PeneTrace = {}
	   PeneTrace.endpos = tr.HitPos
	   PeneTrace.start = tr.HitPos + PeneDir
	   PeneTrace.mask = MASK_SHOT
	   PeneTrace.filter = { self.Owner }
	   
	local PeneTrace = util.TraceLine( PeneTrace ) 
	
	-- Bullet didn't penetrate.
	if ( PeneTrace.StartSolid || PeneTrace.Fraction >= 1.0 || tr.Fraction <= 0.0 ) then return false end
	
	local distance = ( PeneTrace.HitPos - tr.HitPos ):Length();
	local new_damage = self:GetPenetrationDamageLoss( tr.MatType, distance, dmginfo:GetDamage() );
	
	if( new_damage > 0 ) then
		local bullet = 
		{	
			Num 		= 1,
			Src 		= PeneTrace.HitPos,
			Dir 		= tr.Normal,	
			Spread 		= Vector( 0, 0, 0 ),
			Tracer		= 0,
			Force		= 5,
			Damage		= new_damage,
			AmmoType 	= "Pistol",
		}
		
		bullet.Callback = function( a, b, c ) if ( self.BulletCallback ) then return self:BulletCallback( a, b, c, bounce + 1 ) end end
		
		local effectdata = EffectData()
		effectdata:SetOrigin( PeneTrace.HitPos );
		effectdata:SetNormal( PeneTrace.Normal );
		util.Effect( "Impact", effectdata ) 
		
		timer.Simple( 0.05,
			function()
				attacker:FireBullets(bullet, true)
			end
		)
	end
end