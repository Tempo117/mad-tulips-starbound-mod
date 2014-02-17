function init(args)
	world.logInfo("Init called")
	self.jumpHoldTimer = nil
end

function main()
	local dt = entity.dt()
	
	-- JUMP DEBUG	
	local run = true
	local Jump_Distance = 10
	local Move_Distance = 10
	
	--entity.say("Jumping!")
	
	-- Keep jumping
	world.logInfo("A0")
	if self.is_jumping or entity.isJumping() or (not entity.onGround() and self.jumpHoldTimer ~= nil) then
		world.logInfo("A1")
		if self.jumpHoldTimer ~= nil then
			world.logInfo("A2")
			entity.holdJump()
			
			self.jumpHoldTimer = self.jumpHoldTimer - dt
			if self.jumpHoldTimer <= 0 then
				world.logInfo("A3")
				self.jumpHoldTimer = nil
				self.is_jumping = false
			end
		end
		entity.move(Move_Distance, run)
		world.logInfo("A4")
		return true
	end
	self.jumpHoldTimer = nil

	world.logInfo("A5")
    entity.jump()
	self.is_jumping = true;
    self.jumpHoldTimer = Jump_Distance	

end
