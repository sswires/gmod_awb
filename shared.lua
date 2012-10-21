-- includes
include( "sh_activities.lua" )
include( "sh_viewmodel.lua" )
include( "sh_weaponmechanics.lua" )
include( "sh_shooteffects.lua" )
include( "sh_reload.lua" )

-- variables
SWEP.Base							= "weapon_base"
SWEP.HoldType						= "ar2"

-- weapon stats
SWEP.Akimbo							= {}
SWEP.Akimbo.Enabled					= false
SWEP.Akimbo.FlipSecondaryViewModel 	= true
SWEP.Akimbo.HideHandBones			= true
SWEP.Akimbo.BoneProfile				= "css_lefthanded"
SWEP.Akimbo.ClearBones				= { css_lefthanded = { "v_weapon.Right_Hand", "v_weapon.R_wrist_helper", "v_weapon.Right_Arm", "v_weapon.Right_Thumb01","v_weapon.Right_Thumb02", "v_weapon.Right_Thumb03", "v_weapon.Right_Middle01", "v_weapon.Right_Middle02", "v_weapon.Right_Middle03", "v_weapon.Right_Ring01", "v_weapon.Right_Ring02", "v_weapon.Right_Ring03", "v_weapon.Right_Pinky01", "v_weapon.Right_Pinky02", "v_weapon.Right_Pinky03", "v_weapon.Right_Index01", "v_weapon.Right_Index02", "v_weapon.Right_Index03", "v_weapon.eff18", "v_weapon.Root23", "v_weapon.eff9", "v_weapon.Root24", "v_weapon.Root26", "v_weapon.Root27", "v_weapon.Root28", "v_weapon.Root98", "v_weapon.Root25", "v_weapon.Root36" }, hl2 = { "ValveBiped.Bip01_L_Hand" } }
SWEP.Akimbo.BoneTranslate			= true

SWEP.Primary.Damage					= 25
SWEP.Primary.Delay					= 0.2
SWEP.Primary.Recoil 				= 0.05
SWEP.Primary.Bullets				= 1
SWEP.Primary.Cone					= 0.0
SWEP.Primary.Sound					= Sound("Weapon_Pistol.Single")
SWEP.Primary.EmptySound				= Sound("Weapon_Pistol.Empty")

SWEP.HasIronsights					= false
SWEP.IronsightFOV					= 65
SWEP.IronsightAccuracy				= 0.5
SWEP.IronsightRecoil				= 0.7
SWEP.IronsightTime					= 0.2

SWEP.Secondary.Ammo					= "none"
SWEP.Secondary.ClipSize				= -1

-- Weapon effects
SWEP.ShellType						= 1
SWEP.ShellAttach					= 2
SWEP.MuzzleAttach					= 1

function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )

	if( self.Akimbo.Enabled ) then // automate some akimbo setup stuff
		self.Secondary.Ammo = self.Primary.Ammo
		self.Secondary.ClipSize = self.Primary.ClipSize
		self.Secondary.Automatic = self.Primary.Automatic

		self:SetClip2( self.Secondary.ClipSize )
	end

	if( self.CSMuzzleFlashes ) then
		self.ShellAttach = "2"
		self.MuzzleAttach = "1"
	end

end

function SWEP:SetupDataTables()
	self:DTVar( "Float", 0, "nextIdleTime" )
	self:DTVar( "Float", 1, "loweredTime" )
	self:DTVar( "Float", 2, "ironsightTime" )
	self:DTVar( "Float", 3, "lastShootTime" )
	
	self:DTVar( "Int", 0, "shotsFired" )
	
	self:DTVar( "Bool", 0, "reloadPrimary" )
	self:DTVar( "Bool", 1, "reloadSecondary" )
	self:DTVar( "Bool", 2, "lowered" )
	self:DTVar( "Bool", 3, "ironsighted" )
end

function SWEP:Deploy()

	self.dt.loweredTime = -1.0
	self.dt.lowered = false
	self.dt.reloadPrimary = false
	self.dt.reloadSecondary = false
	self.dt.ironsighted = false
	self.dt.lastShootTime = 0.0
	self.dt.shotsFired = 0
			
	if( self.Akimbo.Enabled ) then

		local vm = self.Owner:GetViewModel( 1 )
		vm:SetWeaponModel( self.ViewModel, self )

		self:SendWeaponAnimation( self:GetDeployActivity(), 1, 1.0 )

		if( self.Akimbo.FlipSecondaryViewModel ) then
			self.ViewModelFlip1 = !self.ViewModelFlip
		end

	end
	
	local vm = self.Owner:GetViewModel( 0 )
	vm:SetWeaponModel( self.ViewModel, self )

	local deployTime = self:SendWeaponAnimation( self:GetDeployActivity(), 0, 1.0 ) -- override 4x default
	local deployFinishes = CurTime() + deployTime

	self:SetNextPrimaryFire( deployFinishes )
	self:SetNextSecondaryFire( deployFinishes )

	return true
end

function SWEP:Holster()
	
	self:SetIronsights( false )
	
	local owner = self:GetOwner()
	
	if( owner && owner:IsValid() && owner:IsPlayer() ) then
		owner:GetViewModel( 1 ):AddEffects( EF_NODRAW )
	end	
	
	return true
end

function SWEP:OnEmpty(idx)
	self:EmitSound( self.Primary.EmptySound )
end

function SWEP:PrimaryAttack()

	self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
	
	if( self.dt.reloadPrimary or self:Clip1() <= 0 or !self:CanAttack() ) then
		if(self:Clip1() <= 0) then
			self:OnEmpty(0)
		end
		
		return
	end
	
	self:TakePrimaryAmmo( 1 )
	
	local idleTime = self:SendWeaponAnimation( self:GetPrimaryAttackActivity(), 0, self:GetShootPlaybackRate() )
	self.dt.nextIdleTime = CurTime() + idleTime

	self:EmitSound( self.Primary.Sound )
	
	self:ShootBullets( self.Primary.Damage, self.Primary.Bullets, self.Primary.Cone, 0 )
	self:AddViewKick()
	
	-- effects
	self:DoShootEffects( 0 )
end

function SWEP:SecondaryAttack()
	
	if( self.Akimbo.Enabled ) then

		self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
		
		if( self.dt.reloadSecondary or self:Clip2() <= 0 or !self:CanAttack() ) then
			if(self:Clip2() <= 0) then
				self:OnEmpty(1)
			end
			
			return
		end

		self:TakeSecondaryAmmo( 1 )
	
		local idleTime = self:SendWeaponAnimation( self:GetPrimaryAttackActivity(), 1, self:GetShootPlaybackRate() )
		self.dt.nextIdleTime = CurTime() + idleTime

		self:EmitSound( self.Primary.Sound )
		
		self:ShootBullets( self.Primary.Damage, self.Primary.Bullets, self.Primary.Cone, 1 )
		self:AddViewKick()
	
		-- effects
		self:DoShootEffects( 1 )
	else
		
		if( self.HasIronsights and self:CanAttack() ) then
			self:SetIronsights( !self.dt.ironsighted )
		end
	end
	
end

function SWEP:SetIronsights( b )
	self.dt.ironsighted = b
	self.dt.ironsightTime = CurTime()
	
	if( b ) then
		self.Owner:SetFOV( self.IronsightFOV, self.IronsightTime )
	else
		self.Owner:SetFOV( 0, self.IronsightTime )
	end
end

function SWEP:IsIronsighted()
	return self.dt.ironsighted
end

function SWEP:GetIronsightFraction()

	local deltaIronsight = CurTime() - self.dt.ironsightTime
	
	if( self:IsIronsighted() or deltaIronsight <= self.IronsightTime ) then
		
		if( self:IsIronsighted() ) then
			return math.min( deltaIronsight / self.IronsightTime, 1.0 )
		else
			return math.Clamp( 1.0 - ( deltaIronsight / self.IronsightTime ), 0.0, 1.0 )
		end
	end
	
	return 0.0
	
end

function SWEP:GetSprintFraction()

	if( self:LoweredTime() > 0.0 ) then
	
		local timeSinceLower = CurTime() - self:LoweredTime()
		
		if( self:IsLowered() ) then
			return math.Clamp( timeSinceLower, 0, 0.25 ) * 4
		elseif( timeSinceLower <= 0.25 ) then
			return 1.0 - ( math.Clamp( timeSinceLower, 0, 0.25 ) * 4 )
		end
	end
	
	return 0.0
end

function SWEP:CanAttack()

	if( self.Owner and self.Owner:IsPlayer() ) then
		if( self:IsLowered() or CurTime() - self.dt.loweredTime <= 0.25 ) then
			return false
		end
	end

	return true

end

function SWEP:WeaponIdle()

	if( self.dt.reloadPrimary or self.dt.reloadSecondary ) then return end
	
	local curTime = CurTime()
	local idleTime = 0

	if( curTime >= self.dt.nextIdleTime and curTime >= self:GetNextPrimaryFire() ) then
		idleTime = self:SendWeaponAnimation( self:GetIdleActivity(), 0 )
	end

	if( self.Akimbo.Enabled and curTime >= self.dt.nextIdleTime and CurTime() >= self:GetNextSecondaryFire() ) then
		idleTime = self:SendWeaponAnimation( self:GetIdleActivity(), 1 )
	end

	if( idleTime > 0 ) then
		self.dt.nextIdleTime = curTime + idleTime
	end

end

function SWEP:SetLowered( b )
	self.dt.lowered = b
	local lowerElapsed = CurTime() - self.dt.loweredTime
	
	if( lowerElapsed > 0.25 ) then
		self.dt.loweredTime = CurTime()
	end
	
	if( b and self:IsIronsighted() ) then
		self:SetIronsights( false )
	end
end

function SWEP:IsLowered()
	return self.dt.lowered
end

function SWEP:LoweredTime()
	return self.dt.loweredTime
end

function SWEP:LowerThink()

	local lower = false
	
	if( self.Owner and self.Owner:IsPlayer() ) then
	
		if( self.Owner:KeyDown( IN_SPEED ) and self.Owner:GetVelocity():Length() > self.Owner:GetWalkSpeed() ) then
			lower = true
		end
		
	end
	
	if( self:IsLowered() != lower ) then
		self:SetLowered( lower )
	end
	
end

function SWEP:Think()

	if( self.dt.reloadPrimary ) then
		self:ReloadThink( 0 )
	end
	
	if( self.Akimbo.Enabled and self.dt.reloadSecondary ) then
		self:ReloadThink( 1 )
	end
	
	-- remove spray penalty for next burst
	if( !self.Owner:KeyDown( IN_ATTACK ) ) then
		self.dt.shotsFired = 0
	end
	
	self:LowerThink()
	self:WeaponIdle()

end