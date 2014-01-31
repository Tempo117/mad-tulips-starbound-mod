function Set_Occupation(Occupation)
	if Occupation == nil then return nil end
	
	if     Occupation == "Engineer" then
		-- Engineer
		storage.Occupation = "Engineer";
		entity.say("Yes SIR! Working as " .. Occupation .."!")
		Set_Occupation_Cloth()
		return true
	elseif Occupation == "Medic" then
		-- Medic
		storage.Occupation = "Medic";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		Set_Occupation_Cloth()
		return true
	elseif Occupation == "Scientist" then
		-- Scientist
		storage.Occupation = "Scientist";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		Set_Occupation_Cloth()
		return true
	elseif Occupation == "Marine" then
		-- Marine
		storage.Occupation = "Marine";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		Set_Occupation_Cloth()
		return true
	elseif Occupation == "Deckhand" then
		-- None
		storage.Occupation = "Deckhand";
		entity.say("Working as a simple Deckhand, SIR!")
		Set_Occupation_Cloth()
		return true
	else
		entity.say("What kind of job is that!?, SIR!")
		return nil
	end
	
	return nil
end

function Set_Occupation_Cloth()
	if storage.Occupation == nil then return nil end
	if     storage.Occupation == "Engineer" then
		-- Engineer
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_engineer_chest", data ={ colorIndex = storage.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_engineer_pants", data ={ colorIndex = storage.colorIndex }})
		return true
	elseif storage.Occupation == "Medic" then
		-- Medic
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_medical_chest", data ={ colorIndex = storage.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_medical_pants", data ={ colorIndex = storage.colorIndex }})
		return true
	elseif storage.Occupation == "Scientist" then
		-- Scientist
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_science_chest", data ={ colorIndex = storage.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_science_pants", data ={ colorIndex = storage.colorIndex }})
		return true
	elseif storage.Occupation == "Marine" then
		-- Marine
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_marine_chest", data ={ colorIndex = storage.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_marine_pants", data ={ colorIndex = storage.colorIndex }})
		return true
	elseif storage.Occupation == "Deckhand" then
		-- None
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_deckhand_chest", data ={ colorIndex = storage.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_deckhand_pants", data ={ colorIndex = storage.colorIndex }})
		return true
	else
		entity.say("What kind of job is that!?, SIR!")
		return nil
	end
	
	return nil
end