SWEP.OpenBolt		= false
SWEP.UnlimitedAmmo	= false

function SWEP:GetReloadTimeModifier( )
	return 1.0
end

function SWEP:Reload()

	if( self:IsIronsighted() ) then
		self:SetIronsights( false )
	end

	if( self.UnlimitedAmmo == false and self.Owner:GetAmmoCount( self.Primary.Ammo ) <= 0 ) then
		return
	end
	
	if( ( self:Clip1() < self.Primary.ClipSize or (self.OpenBolt and self:Clip1() <= self.Primary.ClipSize) ) and !self.dt.reloadPrimary ) then
		self:StartReloadAt( 0 )
	end
	
	if( self.Akimbo.Enabled ) then
	
		if( ( self:Clip2() < self.Primary.ClipSize or (self.OpenBolt and self:Clip2() <= self.Primary.ClipSize) ) and !self.dt.reloadSecondary ) then
			self:StartReloadAt( 1 )
		end
	end
	
end

function SWEP:GetReloadTimerForIndex( idx )

	if( idx > 0 ) then
		return self:GetNextSecondaryFire()
	end
	
	return self:GetNextPrimaryFire()
	
end

function SWEP:StartReloadAt( idx )

	local reloadTimeMod = self:GetReloadTimeModifier()
	local reloadActivity = self:GetReloadActivity( idx )
	
	local reloadTimeTotal = self:SendWeaponAnimation( reloadActivity, idx, reloadTimeMod ) * reloadTimeMod
	
	if( idx == 0 ) then
		self:SetNextPrimaryFire( CurTime() + reloadTimeTotal )
		self.dt.reloadPrimary = true
	else
		self:SetNextSecondaryFire( CurTime() + reloadTimeTotal )
		self.dt.reloadSecondary = true
	end
	
end

function SWEP:FinishReload( idx )

	local magazineSize = self.Primary.ClipSize
	local currentMagazine = self:Clip1()
	
	if( idx > 0 ) then
		currentMagazine = self:Clip2()
	end
	
	local amountToLoad = magazineSize

	-- open bolt weapons get +1 if the current magazine has rounds left
	if(self.OpenBolt and currentMagazine > 0) then
		amountToLoad = magazineSize + 1
	end
	
	-- deal with limited ammo
	if(self.UnlimitedAmmo == false) then
		local ammoPool = self.Owner:GetAmmoCount(self.Primary.Ammo)
		amountToLoad = math.Clamp(amountToLoad, 0, ammoPool)
		
		self.Owner:RemoveAmmo(amountToLoad - currentMagazine, self.Primary.Ammo)
	end
		
	if( idx == 0 ) then
		self:SetClip1( amountToLoad )
		self.dt.reloadPrimary = false
	else
		self:SetClip2( amountToLoad )
		self.dt.reloadSecondary = false
	end
	
end

function SWEP:ReloadThink( idx )
	
	if( CurTime() > self:GetReloadTimerForIndex( idx ) ) then
		self:FinishReload( idx )
	end
	
end