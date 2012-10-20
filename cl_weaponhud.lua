SWEP.DrawCrosshair 	= false -- do not draw the default crosshair
SWEP.ZoomCrosshair	= true -- still show crosshair when aiming down sights
SWEP.CustomHud 		= true

-- client tweakables for custom xhair
crosshair_r 			= CreateClientConVar( "crosshair_r", 255, true, false )
crosshair_g 			= CreateClientConVar( "crosshair_g", 255, true, false )
crosshair_b 			= CreateClientConVar( "crosshair_b", 255, true, false )
crosshair_a 			= CreateClientConVar( "crosshair_a", 120, true, false )
crosshair_scale 		= CreateClientConVar( "crosshair_scale", 2, true, false )
crosshair 				= GetConVar( "crosshair" )
	
function SWEP:DrawHUD()
	if( self.CustomHud ) then
		self:DrawCustomCrosshair()
		self:DrawAmmoCounter()
	end
end

function SWEP:DrawCrosshairBit( x, y, width, height, alpha )

	surface.SetDrawColor( 0, 0, 0, alpha )
	surface.DrawRect( x, y, width, height )
	
	surface.SetDrawColor( crosshair_r:GetInt(), crosshair_g:GetInt(), crosshair_b:GetInt(), alpha )
	surface.DrawRect( x+1, y+1, width-2, height-2 )
	
end

function SWEP:DrawCustomCrosshair()

	if( crosshair:GetBool() == false or crosshair_a:GetInt() <= 0 ) then return end
	
	if( !self.LastCrosshairGap ) then
		self.LastCrosshairGap = 0
	end	
	
	if( self.ZoomCrosshair == false and self:IsIronsighted() and CurTime() > self.dt.ironsightTime + self.IronsightTime ) then return end
	
	local x = ScrW()/2
	local y = ScrH()/2
	
	local gap = math.Approach( self.LastCrosshairGap, ( (self.Primary.Cone * ( 260 * (ScrH()/720) ) ) * self:GetSpreadBias()) * crosshair_scale:GetFloat(), FrameTime() * 80 )
	gap = math.Clamp( gap, 0, (ScrH()/2)-100 )
	local length = ( gap + 13 ) * 0.6
	local alpha = crosshair_a:GetInt()
	
	if( gap > 40 * (ScrH()/720) ) then
		local overgap = gap - ( 40 * (ScrH()/720) )
		local newalpha = alpha - (overgap * 4)
		
		alpha = math.Clamp( newalpha, 0, 255 );
	end
	
	if( alpha > 0 ) then
		self:DrawCrosshairBit( x - gap - length + 1, y - 1, length, 3, alpha ) -- left
		self:DrawCrosshairBit( x + gap + 1, y - 1, length, 3, alpha ) -- right
		self:DrawCrosshairBit( x - 1, y - gap - length + 1, 3, length, alpha ) -- top 
		self:DrawCrosshairBit( x - 1, y + gap + 1, 3, length, alpha ) -- bottom
	end
	
	self.LastCrosshairGap = gap;

end

function SWEP:CustomAmmoDisplay()
	self.AmmoDisplay = self.AmmoDisplay or {} 
	self.AmmoDisplay.Draw = false
	
	return self.AmmoDisplay
end

function SWEP:DrawAmmoCounter()
    local screenScale = ( ScrH() / 720 )
    local ammoWidth = 120 * screenScale
    local blockHeight = 6 * screenScale
    local blockGap = 3 * screenScale
    
    if( self.Primary.ClipSize > 0 ) then
        local blockWidth = (ammoWidth / self.Primary.ClipSize) - ( blockGap / (self.Primary.ClipSize - 1) )
        local sourcePosX = ScrW() - 20 - ammoWidth - ( blockGap * self.Primary.ClipSize )
        local sourcePosY = ScrH() - 20 - blockHeight
        
        local secondaryPosY = sourcePosY - blockHeight - 7
        
        for i=0,self.Primary.ClipSize-1 do
            local blockColor = Color( 0, 0, 0, 150 )
            
            if( i < self:Clip1() ) then
                blockColor = Color( 255, 255, 255, 200 )
            end
            
            surface.SetDrawColor( 0, 0, 0, 75 )
            surface.DrawRect( sourcePosX + ( blockWidth * i ) + ( blockGap * i ) - 1, sourcePosY - 1, blockWidth + 2, blockHeight + 2 )
            
            surface.SetDrawColor( blockColor.r, blockColor.g, blockColor.b, blockColor.a )
            surface.DrawRect( sourcePosX + ( blockWidth * i ) + ( blockGap * i ), sourcePosY, blockWidth, blockHeight )
            
            if( self.Akimbo.Enabled ) then
                blockColor = Color( 0, 0, 0, 150 )
            
                if( i < self:Clip2() ) then
                    blockColor = Color( 255, 255, 255, 200 )
                end                
        
                surface.SetDrawColor( 0, 0, 0, 75 )
                surface.DrawRect( sourcePosX + ( blockWidth * i ) + ( blockGap * i ) - 1, secondaryPosY - 1, blockWidth + 2, blockHeight + 2 )
                
                surface.SetDrawColor( blockColor.r, blockColor.g, blockColor.b, blockColor.a )
                surface.DrawRect( sourcePosX + ( blockWidth * i ) + ( blockGap * i ), secondaryPosY, blockWidth, blockHeight )
            end
        end
    end
end