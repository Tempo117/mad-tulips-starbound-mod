function init()
	--data = {};
	
	data.active = false
	data.ranOut = false
	tech.setVisible(false)
end

function uninit()
	if data.active then
		deactivate()
        return 0
	end
end

function input(args)  
	-- default
	data.holdingJump = false;
	data.holdingLeft = false;
	data.holdingRight = false;
	data.holdingUp = false;
	data.holdingDown = false;
	
	-- Action check
	if args.moves["special"] == 1 then
		if data.active then
			return "mechDeactivate"
		else
			return "mechActivate"
		end
	end

	-- jump
	if args.moves["jump"] and tech.jumping() then data.holdingJump = true end
	--move left
	if args.moves["left"] then data.holdingLeft = true end
	--move right
	if args.moves["right"] then data.holdingRight = true end
	--move up
	if args.moves["up"] then data.holdingUp = true end
	--move down
	if args.moves["down"] then data.holdingDown = true end

	return nil
end

function update(args)
	-- Read object file Parameters
	data.mechCustomMovementParameters	= tech.parameter("mechCustomMovementParameters")
	data.parentOffset					= tech.parameter("parentOffset")
	data.mechCollisionTest				= tech.parameter("mechTransformCollisionTest")
	data.Hold_at_level_Force			= tech.parameter("Hold_at_level_Force")
	data.Left_Right_Speed				= tech.parameter("Left_Right_Speed")
	data.Left_Right_Force				= tech.parameter("Left_Right_Force")
	data.Up_Down_Speed					= tech.parameter("Up_Down_Speed")
	data.Up_Down_Force					= tech.parameter("Up_Down_Force")
		
	if not data.active and args.actions["mechActivate"] then
		-- Calculate new position
		tech.setAnimationState("movement", "idle")
		data.mechCollisionTest[1] = data.mechCollisionTest[1] + tech.position()[1]
		data.mechCollisionTest[2] = data.mechCollisionTest[2] + tech.position()[2]
		data.mechCollisionTest[3] = data.mechCollisionTest[3] + tech.position()[1]
		data.mechCollisionTest[4] = data.mechCollisionTest[4] + tech.position()[2]
		
		-- Check collision for activate
		if not world.rectCollision(data.mechCollisionTest) then
			activate()
		else
			-- Make some kind of error noise
		end
	end
	
	if data.active then		
		-- Deactivate?
		if args.actions["mechDeactivate"] then
			-- Deactivate mech
			deactivate()
            return 0
		end

		-- Calculate current angle and flip state
		local diff = world.distance(args.aimPosition, tech.position())
		local aimAngle = math.atan2(diff[2], diff[1])
		local flip = aimAngle > math.pi / 2 or aimAngle < -math.pi / 2		
		
		if    (data.holdingLeft and flip)
		   or (data.holdingRight and not flip) then
			if (data.holdingUp or data.holdingDown) then
				-- doing left right and up down movement
				tech.setParticleEmitterActive("move_LR_Particles", true)
				tech.setParticleEmitterActive("move_UD_Particles_L", true)
				tech.setParticleEmitterActive("move_UD_Particles_R", true)
				tech.setAnimationState("movement", "move_LRUD")
			else
				-- doing left right movement only
				tech.setParticleEmitterActive("move_LR_Particles", true)
				tech.setParticleEmitterActive("move_UD_Particles_L", false)
				tech.setParticleEmitterActive("move_UD_Particles_R", false)
				tech.setAnimationState("movement", "move_LR")
			end

		else
			if (data.holdingUp or data.holdingDown) then
				-- doing up down movement only
				tech.setParticleEmitterActive("move_LR_Particles", false)
				tech.setParticleEmitterActive("move_UD_Particles_L", true)
				tech.setParticleEmitterActive("move_UD_Particles_R", true)
				tech.setAnimationState("movement", "move_UD")
			else
				-- Idle movement
				tech.setParticleEmitterActive("move_LR_Particles", false)
				tech.setParticleEmitterActive("move_UD_Particles_L", false)
				tech.setParticleEmitterActive("move_UD_Particles_R", false)
				tech.setAnimationState("movement", "idle")
			end
		end

		-- Apply movement physics parameters
		tech.applyMovementParameters(data.mechCustomMovementParameters)

		-- Flip and offset player
		if flip then
			tech.setFlipped(true)
			local nudge = tech.stateNudge()
			tech.setParentOffset({-data.parentOffset[1] - nudge[1], data.parentOffset[2] + nudge[2]})
			tech.setParentFacingDirection(-1)
		else
			tech.setFlipped(false)
			local nudge = tech.stateNudge()
			tech.setParentOffset({data.parentOffset[1] + nudge[1], data.parentOffset[2] + nudge[2]})
			tech.setParentFacingDirection(1)
		end
		
		-- Setup movement vector
		local v_x = 0; local v_y = 0; local a_x = 0; local a_y = 0;
		-- Add keypress
		if data.holdingUp then
			v_y = data.Up_Down_Speed;
		end
		if data.holdingDown then
			v_y = -data.Up_Down_Speed;
		end
		if data.holdingLeft and flip then
			v_x = -data.Left_Right_Speed;
			a_x = data.Up_Down_Force;
		end
		if data.holdingRight and not flip then
			v_x = data.Left_Right_Speed;
			a_x = data.Up_Down_Force;
		end
		-- execute movement vector
		tech.xControl(v_x, a_x, false);
		tech.yControl(v_y, data.Hold_at_level_Force+a_y, false);
	end

  return 0
end

-- Activate mech
function activate()
	local mechTransformPositionChange = tech.parameter("mechTransformPositionChange")
	
	tech.burstParticleEmitter("mechActivateParticles")
	tech.translate(mechTransformPositionChange)
	tech.setVisible(true)
	tech.setParentAppearance("sit")
	tech.setToolUsageSuppressed(true)
	data.active = true
end

-- Deactivate mech
function deactivate()
	local mechTransformPositionChange = tech.parameter("mechTransformPositionChange")
	
	tech.setAnimationState("movement", "off")
	tech.burstParticleEmitter("mechDeactivateParticles")
	
	tech.translate({-mechTransformPositionChange[1], -mechTransformPositionChange[2]})
	tech.setVisible(false)
	tech.setParentAppearance("normal")
	tech.setToolUsageSuppressed(false)
	tech.setParentOffset({0, 0})
	tech.setParentFacingDirection(nil)
	data.active = false
	return 0
end
