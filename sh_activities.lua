function SWEP:GetDeployActivity()
	return ACT_VM_DRAW
end

function SWEP:GetPrimaryAttackActivity()
	return ACT_VM_PRIMARYATTACK
end

function SWEP:GetIdleActivity()
	return ACT_VM_IDLE
end

function SWEP:GetReloadActivity( idx )
	return ACT_VM_RELOAD
end

function SWEP:GetShootPlaybackRate()

	if( self:IsIronsighted() ) then
		return 3.0
	end
	
	return 1.0
end