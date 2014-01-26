function Set_Occupation(Occupation)
	if Occupation == nil then return nil end
	
	if     Occupation == "Engineer" then
		-- Engineer
		Data.Occupation = "Engineer";
		entity.say("Yes SIR! Working as " .. Occupation .."!")
		entity.setItemSlot("primary", "beamaxe")
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_engineer_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_engineer_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Medic" then
		-- Medic
		Data.Occupation = "Medic";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_medical_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_medical_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Scientist" then
		-- Scientist
		Data.Occupation = "Scientist";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_science_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_science_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Marine" then
		-- Marine
		Data.Occupation = "Marine";
		entity.say("Yes SIR! Working as " .. Occupation .. "!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_marine_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_marine_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	elseif Occupation == "Deckhand" then
		-- None
		Data.Occupation = "Deckhand";
		entity.say("Working as a simple Deckhand, SIR!")
		entity.setItemSlot("primary", nil)
		entity.setItemSlot("alt", nil)
		entity.setItemSlot("chest", {name = "madtulip_" .. entity.species() .. "_deckhand_chest", data ={ colorIndex = Data.colorIndex }})
		entity.setItemSlot("legs" , {name = "madtulip_" .. entity.species() .. "_deckhand_pants", data ={ colorIndex = Data.colorIndex }})
		return true
	else
		entity.say("What kind of job is that!?, SIR!")
		return nil
	end
	
	return nil
end