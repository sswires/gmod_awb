include( "shared.lua" )

include( "cl_weaponhud.lua" )

-- mouse sensitivity should be lower for ironsighting
function SWEP:AdjustMouseSensitivity()
	if( self:IsIronsighted() ) then
		return 0.5
	end
	
	return 1.0
end

