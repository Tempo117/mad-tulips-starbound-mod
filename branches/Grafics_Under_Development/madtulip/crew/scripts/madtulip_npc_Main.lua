init = function (args)
  -- madtulip:
  Init_Crew_Data()

  -- vanilla:
  self.timers = createTimers()

  local states = stateMachine.scanScripts(entity.configParameter("scripts"), "(%a+State)%.lua")
  self.state = stateMachine.create(states)

  self.state.enteringState = function(stateName)
--    debugLog("entering %s", stateName)
  end

  self.state.leavingState = function(stateName)
    self.state.moveStateToEnd(stateName)
    self.stateTargetId = nil
  end

  entity.setInteractive(true)

  self.pathing = {}

  self.noticePlayersRadius = entity.configParameter("noticePlayersRadius", -1)
  self.forgetPlayerTime = entity.configParameter("forgetPlayerTime", 3)

  local primaryItemType = itemType("primary"), false
  self.hasMeleeWeapon = primaryItemType == "sword"
  self.hasRangedWeapon = primaryItemType == "gun"

  local sheathedPrimaryItemType = itemType("sheathedprimary")
  self.hasSheathedMeleeWeapon = sheathedPrimaryItemType == "sword"
  self.hasSheathedRangedWeapon = sheathedPrimaryItemType == "gun"

  self.hasShield = itemType("alt") == "shield"
  self.hasSheathedShield = itemType("sheathedalt") == "shield"

  if storage.attackOnSightIds == nil then
    storage.attackOnSightIds = {}
  end

  if storage.spawnPosition == nil then
    local position = entity.position()

    -- NPCs aren't always placed right on the ground. They may need to be
    -- moved up or down a few blocks so their spawn position is actually on the
    -- ground
    local supportRegion = {
      math.floor(position[1] + 0.5) - 1, math.floor(position[2] + 0.5) - 3,
      math.floor(position[1] + 0.5) + 1, math.floor(position[2] + 0.5) - 2,
    }

    for i = 0, 3, 1 do
      if world.rectCollision(supportRegion, true) then
        supportRegion[2] = supportRegion[2] + 1
        supportRegion[4] = supportRegion[4] + 1
      else
        break
      end
    end

    for i = 0, 3, 1 do
      supportRegion[2] = supportRegion[2] - 1
      supportRegion[4] = supportRegion[4] - 1
      if world.rectCollision(supportRegion, false) then
        break
      end
    end

    storage.spawnPosition = { position[1], supportRegion[2] + 3.5 }
  end
end

function Init_Crew_Data()
	if storage.Occupation == nil then storage.Occupation = "Deckhand" end
	if storage.colorIndex == nil then storage.colorIndex = 1 end
	--if storage.shouldDie == nil then storage.shouldDie = false end
	
	Set_Occupation_Cloth()
	world.logInfo("------------ COMMENT main:madtulip_TS.update_Task_Scheduler(dt) back in after JUMP DEBUG -------------")
	Jump_Testing_Init()
end

function Jump_Testing_Init()
	self.Jump_Measurement_Timer = 0
end

main = function ()
  noticePlayers()
  
  local dt = entity.dt()

  -- NPC checks his surrounding for tasks (like someone bleeding or a fire)
  -- madtulip_TS.update_Task_Scheduler(dt)
  
  self.state.update(dt)
  self.timers.tick(dt)
  
  --Jump_Debug_Test(dt)
  move_debug_test ()
end

function round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function Entity_Jump(jump_time)
	if (self.Did_jump_recently == nil) then
		self.Did_jump_recently = true
		
		world.logInfo("JUMP START!")
		-- {{x = 0, y = 0},{x = 0, y = 1},{x = 0, y = 2}}
		local pos = entity.position()
		self.Jump_Measurement_Start_Pos = pos
		world.logInfo("{{x = " .. round(pos[1]) .. ", y = " .. round(pos[2]) .. "}")
		
		entity.move(10, true) -- run right
		entity.jump() -- jump
		self.Jump_Measurement_Timer = jump_time
	else
		self.Did_jump_recently = nil
	end
end

function Jump_Debug_Test(dt)
	if entity.isJumping() or (not entity.onGround()) then
		if (self.Jump_Measurement_Start_Pos) then -- this is defined at start of jump
			if self.Jump_Measurement_Timer > 0 then
				entity.holdJump() -- continue jump
			end
			self.Jump_Measurement_Timer = self.Jump_Measurement_Timer - dt
			entity.move(10, true) -- run right
			
			-- {{x = 0, y = 0},{x = 0, y = 1},{x = 0, y = 2}}
			local pos = entity.position()
			pos[1] = pos[1] - self.Jump_Measurement_Start_Pos[1]
			pos[2] = pos[2] - self.Jump_Measurement_Start_Pos[2]
			--world.logInfo(",{x = " .. round(pos[1]) .. ", y = " .. round(pos[2]) .. "}")
			world.logInfo(",{x = " .. math.floor(pos[1]) .. ", y = " .. math.floor(pos[2]) .. "}")
			world.logInfo(",{x = " .. math.ceil(pos[1]) .. ", y = " .. math.floor(pos[2]) .. "}")
			world.logInfo(",{x = " .. math.floor(pos[1]) .. ", y = " .. math.ceil(pos[2]) .. "}")
			world.logInfo(",{x = " .. math.ceil(pos[1]) .. ", y = " .. math.ceil(pos[2]) .. "}")
		end
	else
		Entity_Jump(0) -- entity.jump() fix
	end
end

function move_debug_test ()
	local pos = entity.position()
	if (self.move_test_run_once == nil) then
		world.logInfo("START MOVE{x = " .. pos[1] .. ", y = " .. pos[2] .. "}")
		self.move_test_target = pos
		self.move_test_target[1] = self.move_test_target[1] + 1.125
		
		entity.move(self.move_test_target[1] - pos[1], true) -- run right
		self.move_test_run_once = false
	end
	world.logInfo("MOVE{x = " .. pos[1] .. ", y = " .. pos[2] .. "}")
	entity.move(self.move_test_target[1] - pos[1], false) -- run right
end