SWEP.ViewModelOffsets = {
							Ironsight = { pos = Vector( 0, 2, 0 ), ang = Angle( 0, 0, 0 ) },
							Sprint = { pos = Vector( 0, 0, 1.5 ), ang = Angle( -20, 0, 0 ) },
						}

function SWEP:SendWeaponAnimation( anim, idx, pbr )

	idx = idx or 0
	pbr = pbr or 1.0
	
	local owner = self:GetOwner()
		
	if( owner && owner:IsValid() && owner:IsPlayer() ) then
	
		local vm = owner:GetViewModel( idx )
	
		local idealSequence = self:SelectWeightedSequence( anim )
		local nextSequence = self:FindTransitionSequence( self:GetSequence(), idealSequence )
		
		vm:RemoveEffects( EF_NODRAW )
		vm:SetPlaybackRate( pbr )

		if( nextSequence > 0 ) then
			vm:SendViewModelMatchingSequence( nextSequence )
		else
			vm:SendViewModelMatchingSequence( idealSequence )
		end

		return vm:SequenceDuration( vm:GetSequence() )
	end	
end

function SWEP:GetViewModelOffsetFraction( otype )

	if( otype == "Ironsight" ) then
	
		local deltaIronsight = CurTime() - self.dt.ironsightTime
		
		if( self:IsIronsighted() or deltaIronsight <= self.IronsightTime ) then
			
			if( self:IsIronsighted() ) then
				return math.min( deltaIronsight / self.IronsightTime, 1.0 )
			else
				return math.Clamp( 1.0 - ( deltaIronsight / self.IronsightTime ), 0.0, 1.0 )
			end
		end
	end
	
	if( otype == "Sprint" ) then
		
		if( self:LoweredTime() > 0.0 ) then
		
			local timeSinceLower = CurTime() - self:LoweredTime()
			
			if( self:IsLowered() ) then
				return math.Clamp( timeSinceLower, 0, 0.25 ) * 4
			elseif( timeSinceLower <= 0.25 ) then
				return 1.0 - ( math.Clamp( timeSinceLower, 0, 0.25 ) * 4 )
			end
		end
	end
	
	return 0.0
end

function SWEP:GetViewModelPosition( pos, ang )

	self.SwayScale = self:GetSwayScale()
	self.BobScale = self:GetBobScale() 
	
	for k, v in pairs( self.ViewModelOffsets ) do
		local frac = self:GetViewModelOffsetFraction( k )
		
		if( frac > 0.0 ) then
			pos, ang = self:ApplyVecAngOffset( pos, ang, v.pos, v.ang, frac )
		end
	end

	return pos, ang
end

function SWEP:GetSwayScale()
	
	if( self:IsIronsighted() ) then
		return 0.01
	end
	
	return 1.0
end

function SWEP:GetBobScale()

	if( self:IsIronsighted() ) then
		return 0.01
	end
	
	return 1.0
end

function SWEP:ApplyVecAngOffset( pos, ang, destpos, destang, frac )

	ang:RotateAroundAxis( ang:Right(), 		destang.p * frac )
	ang:RotateAroundAxis( ang:Up(), 		destang.y * frac )
	ang:RotateAroundAxis( ang:Forward(), 	destang.r * frac )
	
	local Right 	= ang:Right()
	local Up 		= ang:Up()
	local Forward 	= ang:Forward()

	pos = pos + destpos.x * Right * frac
	pos = pos + destpos.y * Forward * frac
	pos = pos + destpos.z * Up * frac
	
	return pos, ang
end

function SWEP:ApplyViewModelTransformations( vm )

	vm:SetupBones()

	if( vm and ValidEntity( vm ) and self.Akimbo.ClearBones[ self.Akimbo.BoneProfile ] ) then
		for k, v in pairs( self.Akimbo.ClearBones[ self.Akimbo.BoneProfile ] ) do
			local handBone = vm:LookupBone( v )

			if( handBone and handBone > 0 ) then
				local mHand = vm:GetBoneMatrix( handBone )

				if( mHand ) then
					if( self.Akimbo.BoneTranslate ) then
						mHand:Translate(Vector(-4096,-8192,8192)) // out of sight, out of mind
					else
						mHand:Scale(Vector(0,0,0))
					end

					vm:SetBoneMatrix( handBone, mHand )
				end
			end
		end
	end

end

function SWEP:PreDrawTranslucentRenderables()
	if( CLIENT and self.Akimbo.Enabled and self.Akimbo.HideHandBones ) then
		self:ApplyViewModelTransformations( self.Owner:GetViewModel(0) )
		self:ApplyViewModelTransformations( self.Owner:GetViewModel(1) )
	end
end

function PDTR_CTFWeaponHook()

	local p = LocalPlayer()

	if( p and p:IsValid() ) then
		local aw = p:GetActiveWeapon()

		if( aw and aw:IsValid() ) then
			if( aw.PreDrawTranslucentRenderables ) then aw:PreDrawTranslucentRenderables() end
		end
	end

end
hook.Add( "PreDrawTranslucentRenderables", "PDTR_CTFWeaponHook", PDTR_CTFWeaponHook )
