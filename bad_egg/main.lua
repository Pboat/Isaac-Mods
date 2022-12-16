BadEgg = RegisterMod("Bad EGG",1)
CollectibleType.COLLECTIBLE_BAD_EGG = Isaac.GetItemIdByName("Bad EGG")
CollectibleType.COLLECTIBLE_BAD_EGG_G = Isaac.GetItemIdByName("bad egg")
CollectibleType.COLLECTIBLE_BAD_EGG_Y = Isaac.GetItemIdByName("D EGG")
CollectibleType.COLLECTIBLE_BAD_EGG_P = Isaac.GetItemIdByName("BadEGGgabag")
CollectibleType.COLLECTIBLE_BAD_EGG_R = Isaac.GetItemIdByName("egg")
local game = Game()
--put the items in a table for easier selection
local eggTable ={
	[1] = CollectibleType.COLLECTIBLE_BAD_EGG,
	[2] = CollectibleType.COLLECTIBLE_BAD_EGG_G,
	[3] = CollectibleType.COLLECTIBLE_BAD_EGG_Y,
	[4] = CollectibleType.COLLECTIBLE_BAD_EGG_P,
	[5] = CollectibleType.COLLECTIBLE_BAD_EGG_R
} 
--descriptive mod support
if EID then
	EID:addCollectible(CollectibleType.COLLECTIBLE_BAD_EGG,"Rerolls pedestal items into glitch items#\"Glitches\" into a different bad egg on use, changing the charge time")
	EID:addCollectible(CollectibleType.COLLECTIBLE_BAD_EGG_R,"???")
end

if Encyclopedia then
	local WIKI = {
		DESCRIPTION_NORMAL = {
			{--effects
				{ str = "Effect", fsize = 2, clr = 3, halign = 0},
				{ str = "On use, rerolls all pedestal items in the room into glitch items"},
				{ str = "Glitch items have random effects pulled from other existing items"},
				{ str = "Using the item will change the item into a different version of the egg."},
				{ str = "Each egg type has a different recharge time."},
				{ str = "The purple egg needs 6 rooms to recharge."},
				{ str = "The green egg needs 2 rooms to recharge."},
				{ str = "The yellow egg needs 3 rooms to recharge."},
				{ str = "The pink egg needs 4 rooms to recharge."},
				{ str = "The red egg needs 12 rooms to recharge."},
				{ str = "The red egg can !╜╜#@%╜$╜╜╜"} --╜ is just a random character that encyclopedia can't read, so it says [error] instead. this is intentional.

			},
			{--trivia
				{ str = "Trivia", fsize = 2, clr = 3, halign = 0},
				{ str = "The \"Bad Egg\" is based on a glitch pokemon that would spawn from generation 3 and onwards if the player hacked their game improperly."},
				{ str = "The colors of the eggs are based on the different kinds of eggs found in Pokemon Go. The charge time of each egg corresponds to the walk distance required for each type of egg."},
				{ str = "The flavor text for each egg (except the red one) is based on the egg flavor text for each stage of hatching in the 3rd generation games."},
				{ str = "The flavor text for the red egg comes from the secret Egg item from Deltarune."},
				{ str = "The red egg spawning ??? refers to what happens when the player forces the game to hatch a bad egg, hatching into a glitch pokemon named \"?\" before freezing the game."}
			}
		},
		DESCRIPTION_RED = {
			{
				{ str = "Effect", fsize = 2, clr = 3, halign = 0},
				{ str = "roll$s i$╜into gli╜ch item╜"},
				{ str = "!%$!$F!!$!$╜"},
				{ str = "     ╜╜ "},
				{ str = "#spawn [???].\""}
			}
		}	
	}
Encyclopedia.AddItem({ 
		ID = CollectibleType.COLLECTIBLE_BAD_EGG, --purple (base)
		WikiDesc = WIKI.DESCRIPTION_NORMAL,
		Pools = {
			Encyclopedia.ItemPools.POOL_SECRET,
			Encyclopedia.ItemPools.POOL_CURSE,
			Encyclopedia.ItemPools.POOL_GREED_SECRET,
			Encyclopedia.ItemPools.POOL_GREED_CURSE,
		},
	})
Encyclopedia.AddItem({ 
		ID = CollectibleType.COLLECTIBLE_BAD_EGG_R, --red
		WikiDesc = WIKI.DESCRIPTION_RED,
	})
--hide others
Encyclopedia.AddItem({ID = CollectibleType.COLLECTIBLE_BAD_EGG_G,Hide = true})
Encyclopedia.AddItem({ID = CollectibleType.COLLECTIBLE_BAD_EGG_Y,Hide = true})
Encyclopedia.AddItem({ID = CollectibleType.COLLECTIBLE_BAD_EGG_P,Hide = true})
end

--flag an item to be rerolled
function BadEgg:UseItem(item,rng,player,flags,slot,data)
	
	player:AnimateCollectible(item,"Pickup")
	for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
		pedestal = entity:ToPickup()
		if pedestal.Variant == PickupVariant.PICKUP_COLLECTIBLE and pedestal.SubType ~= 0 then
			local data = pedestal:GetData()
			data.Corrupt = 1 --idk why but it needs to be in a post_update callback to properly reroll into a glitch item, so I need 2 call backs to do this
		end
	end
	--transform room into error room backdrop
	Game():ShowHallucination(4,BackdropType.ERROR_ROOM)
	--spawn ??? if it's the red egg
	if player:GetActiveItem() == eggTable[5] and Game():GetNumPlayers() < 16 then --game crashes at over 64 players, so limit it
		--thanks to im_tem from the modding of isaac discord for this bit for spawning player familiars
		local pCount = Game():GetNumPlayers()
		Isaac.ExecuteCommand("addplayer".." "..PlayerType.PLAYER_XXX.. " " .. player.ControllerIndex)
		local blueBab = Isaac.GetPlayer(pCount)
		blueBab.Parent = player
		blueBab.Position = player.Position
		Game():GetHUD():AssignPlayerHUDs() --make it so ??? doesn't replace your hud with his
		blueBab:RemoveCollectible(CollectibleType.COLLECTIBLE_POOP) --remove poop because it activates alongside the player's item, which can be annoying
		blueBab:PlayExtraAnimation("Glitch")
		blueBab:SetColor(Color(rng:RandomInt(10)/10,rng:RandomInt(10)/10,rng:RandomInt(10)/10,1,0.1,0.1,0.1),0,0,false,false)--random color
	end
	--replace egg with another egg
	if player:GetActiveItem() ~= CollectibleType.COLLECTIBLE_VOID then
		local eggType = rng:RandomInt(9)--0 - 8
		local decearingEgg = eggTable[(math.floor(eggType/2)+1)]--make the red egg rarer than the others
		player:AddCollectible(decearingEgg,0,true,ActiveSlot.SLOT_PRIMARY,0)
	end
	return true
end
--add glitch flag and reroll it
function BadEgg:CheckItem()
	for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_PICKUP)) do
		local data = entity:GetData()
		if entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and data.Corrupt ~= nil then
			entity:ToPickup():AddEntityFlags(EntityFlag.FLAG_GLITCH)
			--reroll into bad egg, so that other items don't get taken out of the pool
			entity:ToPickup():Morph(EntityType.ENTITY_PICKUP,PickupVariant.PICKUP_COLLECTIBLE,CollectibleType.COLLECTIBLE_BAD_EGG,true)
		end
	end
end
--wisps func
function BadEgg:SpawnWisp(wisp)
	local player = wisp.SpawnerEntity:ToPlayer()
	local x = 1 --incremental counter
	--spawn wisp if they have one of the items
	repeat
		if player:HasCollectible(eggTable[x]) then
			if wisp.SubType == eggTable[x] then
				wisp.SubType = 324 --undefined wisps
			end
		end
		x = x + 1
	until (x>5)
end
--callbacks
BadEgg:AddCallback(ModCallbacks.MC_USE_ITEM,BadEgg.UseItem,CollectibleType.COLLECTIBLE_BAD_EGG)
BadEgg:AddCallback(ModCallbacks.MC_USE_ITEM,BadEgg.UseItem,CollectibleType.COLLECTIBLE_BAD_EGG_G)
BadEgg:AddCallback(ModCallbacks.MC_USE_ITEM,BadEgg.UseItem,CollectibleType.COLLECTIBLE_BAD_EGG_Y)
BadEgg:AddCallback(ModCallbacks.MC_USE_ITEM,BadEgg.UseItem,CollectibleType.COLLECTIBLE_BAD_EGG_P)
BadEgg:AddCallback(ModCallbacks.MC_USE_ITEM,BadEgg.UseItem,CollectibleType.COLLECTIBLE_BAD_EGG_R)
BadEgg:AddCallback(ModCallbacks.MC_POST_UPDATE,BadEgg.CheckItem)
BadEgg:AddCallback(ModCallbacks.MC_FAMILIAR_INIT,BadEgg.SpawnWisp,FamiliarVariant.WISP)