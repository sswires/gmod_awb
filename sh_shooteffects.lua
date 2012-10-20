-- firemode enum
FM_AUTOMATIC = 1
FM_SEMIAUTOMATIC = 2
FM_BURSTFIRE = 3

-- Bullet types (for the shell effect)
SHELL_9MM = 1
SHELL_57 = 2
SHELL_556 = 3
SHELL_762NATO = 4
SHELL_12GAUGE = 5
SHELL_338MAG = 6
SHELL_50CAL = 7

SWEP.CustomShellEject				= false

function SWEP:DoShootEffects( vmidx )

	-- effects
	if( SERVER or (CLIENT and IsFirstTimePredicted())) then
		if( self.CustomShellEject ) then
			self:EjectShell( self.ShellType, self.ShellAttach, vmidx )
		end
		
		self:BarrelSmoke( vmidx )
	end

end

function SWEP:EjectShell( shell_type, attachment, vmidx )	

	if( self.Owner and self.Owner:IsValid() and self.Owner:IsPlayer() ) then
	
		local vm = self.Owner:GetViewModel( vmidx or 0 )
		
		local rf = nil
		
		if( SERVER ) then
			rf = RecipientFilter()
			self:GetEffectPlayerFilter( rf )
		end
		
		local attachInfo = vm:GetAttachment( vm:LookupAttachment( self.ShellAttach ) )
		local ed = EffectData()
		ed:SetOrigin( attachInfo.Pos )
		ed:SetAngle( attachInfo.Ang )
		ed:SetEntity( vm )
		ed:SetAttachment( vm:LookupAttachment( self.ShellAttach ) )
		ed:SetScale( shell_type or SHELL_762NATO )
			
		util.Effect( "weapon_shell", ed, true, rf or true )
	end
	
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