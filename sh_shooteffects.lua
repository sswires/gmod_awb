SWEP.CustomEffects			= false

function SWEP:DoShootEffects( vmidx )

	-- effects
	if( self.CustomEffects and (SERVER or (CLIENT and IsFirstTimePredicted())) ) then
		self:BarrelSmoke( vmidx )
	end
	
	self.Owner:SetAnimation( PLAYER_ATTACK1 )

end

function SWEP:BarrelSmoke( vmidx )

	local rf = nil
	
	if( SERVER ) then
		rf = RecipientFilter()
		self:GetEffectPlayerFilter( rf )
	end
		
	-- Make gunsmoke
	local effectdata = EffectData()
	local vm = self.Owner:GetViewModel( vmidx or 0 )
	
	if( CLIENT and self.Owner == LocalPlayer() ) then
		effectdata:SetEntity( vm )
	else
		effectdata:SetOrigin( self.Owner:GetShootPos() )
		effectdata:SetEntity( self.Weapon )
	end
		effectdata:SetStart( self.Owner:GetShootPos() )
		effectdata:SetNormal( self.Owner:GetAimVector() )
		effectdata:SetAttachment( self.MuzzleAttach )
		
	util.Effect( "gunsmoke", effectdata, true, rf or true )
	
end

function SWEP:GetEffectPlayerFilter( rf )

	if( CLIENT ) then
		if( self.Owner == LocalPlayer() ) then
			rf:AddPlayer( self.Owner )
		end
	else
		rf:AddPVS( self.Owner:GetPos() )
		rf:RemovePlayer( self.Owner )
	end
end

function SWEP:GetMuzzleEffectOrigin( vmidx, attach )

	attach = attach or self.MuzzleAttach
	
	if( CLIENT and self.Owner == LocalPlayer() ) then
		local vm = self.Owner:GetViewModel( vmidx or 0 )
		return vm:GetAttachment( vm:LookupAttachment( attach ) ).Pos
	end
	
	return self.Owner:GetShootPos()
end