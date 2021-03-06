--***************************************************************
--
-- tempomatMogli
-- 
-- version 1.92 by mogli (biedens)
-- 2015/03/16
--
--***************************************************************

local tempomatMogliVersion=1.300

-- allow modders to include this source file together with mogliBase.lua in their mods
if tempomatMogli == nil or tempomatMogli.version == nil or tempomatMogli.version < tempomatMogliVersion then
--***************************************************************
	--mogliBase20.newClass( "tempomatMogli", "tempomatMogli" )
	if _G[g_currentModName..".mogliBase"] == nil then
		source(Utils.getFilename("mogliBase.lua", g_currentModDirectory))
	end
	_G[g_currentModName..".mogliBase"].newClass( "tempomatMogli", "tempomatMogli" )
--***************************************************************
	
	tempomatMogli.version = tempomatMogliVersion
	
	--**********************************************************************************************************	
	-- tempomatMogli:load
	--**********************************************************************************************************	
	function tempomatMogli:load(xmlFile) 
		-- state
		self.tempomatMogli = {}
		tempomatMogli.registerState( self, "SpeedLimit2", 10 )
		tempomatMogli.registerState( self, "KeepSpeed",   false )
	
		self.tempomatMogliSetSpeedLimit  = tempomatMogli.tempomatMogliSetSpeedLimit 
		self.tempomatMogliGetSpeedLimit  = tempomatMogli.tempomatMogliGetSpeedLimit 
		self.tempomatMogliGetSpeedLimit2 = tempomatMogli.tempomatMogliGetSpeedLimit2
		self.tempomatMogliSwapSpeedLimit = tempomatMogli.tempomatMogliSwapSpeedLimit 
	end	
	
	--**********************************************************************************************************	
	-- tempomatMogli:update
	--**********************************************************************************************************	
	function tempomatMogli:update(dt)
		
	-- inputs	
		if self:getIsActiveForInput(false) then		
			if     tempomatMogli.mbHasInputEvent( "mrGearboxMogliCONFLICT_1" )
					or tempomatMogli.mbHasInputEvent( "mrGearboxMogliCONFLICT_2" )
					or tempomatMogli.mbHasInputEvent( "mrGearboxMogliCONFLICT_3" )
					or tempomatMogli.mbHasInputEvent( "mrGearboxMogliCONFLICT_4" ) then
				-- ignore
			elseif tempomatMogli.mbHasInputEvent( "mrGearboxMogliSETSPEED" ) then -- speed limiter
				self:tempomatMogliSetSpeedLimit()
			elseif tempomatMogli.mbHasInputEvent( "mrGearboxMogliSWAPSPEED" ) then -- speed limiter
				self:tempomatMogliSwapSpeedLimit()
			end
			tempomatMogli.mbSetState( self, "KeepSpeed", tempomatMogli.mbIsInputPressed( "mrGearboxMogliKEEPSPEED" ) )		
		else
			tempomatMogli.mbSetState( self, "KeepSpeed", false )		
		end
	end
	
	--**********************************************************************************************************	
	-- tempomatMogli:newUpdateVehiclePhysics
	--**********************************************************************************************************	
	function tempomatMogli:newUpdateVehiclePhysics( superFunc, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt, ... )
		if self.tempomatMogli == nil then
			return superFunc( self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt, ... )
		end
		
		local tempState   = self.cruiseControl.state
		local tempSpeed1 = self.motor.speedLimit
		local tempSpeed2 = self.cruiseControl.speed
		
		if     self.cruiseControl.state == Drivable.CRUISECONTROL_STATE_ACTIVE 
				or ( self.movingDirection   <= 0 
				 and ( self.mrGbMS == nil or not ( self.mrGbMS.IsOn ) ) ) then
			self.tempomatMogli.keepSpeedLimit = nil		
		elseif self.tempomatMogli.KeepSpeed then
			if     self.tempomatMogli.keepSpeedLimit == nil 
					or math.abs( axisForward )           >  0.3 then
				self.tempomatMogli.keepSpeedLimit = math.max( 2, self.lastSpeedReal*3600 - axisForward * dt * 5 * math.max( 0.001, self.lastSpeedReal - 0.002 ) )
			end
			self.cruiseControl.state = Drivable.CRUISECONTROL_STATE_ACTIVE
			self.motor.speedLimit    = self.tempomatMogli.keepSpeedLimit
			self.cruiseControl.speed = self.tempomatMogli.keepSpeedLimit
			axisForward              = 0
		elseif self.tempomatMogli.keepSpeedLimit ~= nil then
			self.tempomatMogli.keepSpeedLimit = nil		
		end
		
		superFunc( self, axisForward, axisForwardIsAnalog, axisSide, axisSideIsAnalog, dt, ... )
		
		self.cruiseControl.state = tempState
		self.motor.speedLimit    = tempSpeed1
		self.cruiseControl.speed = tempSpeed2
		
		return 
	end
	
	function tempomatMogli:newDrivableOnLeave( superFunc )
		local oldFunc
		
		if not ( self.deactivateOnLeave ) and self.cruiseControl.state ~= Drivable.CRUISECONTROL_STATE_OFF then
			oldFunc = self.setCruiseControlState
			self.setCruiseControlState = function (self, state, noEventSend) end
		end
		
		superFunc( self )
		
		if oldFunc ~= nil then
			self.setCruiseControlState = oldFunc
		end
	end
	
	Drivable.updateVehiclePhysics = Utils.overwrittenFunction( Drivable.updateVehiclePhysics, tempomatMogli.newUpdateVehiclePhysics )
	Drivable.onLeave              = Utils.overwrittenFunction( Drivable.onLeave,              tempomatMogli.newDrivableOnLeave )  
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliSetSpeedLimit( noEventSend )
		self:setCruiseControlMaxSpeed(self.lastSpeedReal*3600)
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliGetSpeedLimit( )
		return self.cruiseControl.speed
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSetSpeedLimit2
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliGetSpeedLimit2( )
		return self.tempomatMogli.SpeedLimit2
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:tempomatMogliSwapSpeedLimit
	--**********************************************************************************************************	
	function tempomatMogli:tempomatMogliSwapSpeedLimit( noEventSend )
		local speed1 = self.tempomatMogli.SpeedLimit2
		local speed2 = self.cruiseControl.speed
		self:setCruiseControlMaxSpeed(speed1)
		tempomatMogli.mbSetState( self, "SpeedLimit2", speed2, noEventSend ) 		
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:getSaveAttributesAndNodes
	--**********************************************************************************************************	
	function tempomatMogli:getSaveAttributesAndNodes(nodeIdent)
	
		local attributes = ""
	
		if self.tempomatMogli ~= nil then
			if self.tempomatMogli.SpeedLimit2 <= 9 or self.tempomatMogli.SpeedLimit2 >= 11 then
				attributes = attributes.." mrGbMSpeed2=\"" .. tostring( self.tempomatMogli.SpeedLimit2 ) .. "\""     
			end
		end 
		
		return attributes
	end 
	
	--**********************************************************************************************************	
	-- tempomatMogli:loadFromAttributesAndNodes
	--**********************************************************************************************************	
	function tempomatMogli:loadFromAttributesAndNodes(xmlFile, key, resetVehicles)
		local i
		
		if self.tempomatMogli ~= nil then
			i = getXMLInt(xmlFile, key .. "#mrGbMSpeed2" )
			if i ~= nil then
				self.tempomatMogli.SpeedLimit2 = i
			end
		end
		
		return BaseMission.VEHICLE_LOAD_OK
	end 

end