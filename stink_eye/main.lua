StinkEye = RegisterMod("The Stink Eye", 1)
CollectibleType.COLLECTIBLE_STINK_EYE = Isaac.GetItemIdByName("The Stink Eye")
local game = Game()
EffectVariant.STINK_EYE = Isaac.GetEntityVariantByName("StinkyTear")
local TEARS_ADD = 0.3 
local EXPIRE = 120
local BASE_CHANCE = 33 
local MAX_LUCK = 15 
local TEAR_COLOR = Color(0.772,1.3,0.2,1,0,0,0) --sets everything to a chartreuse green color
local LASER_COLOR = Color(0.772,2,0.5,1,0,1.3,0.2)
local SLOW_COLOR = Color (0.5,0.7,0.5,1,0,0,0)
local DESCRIPTION = "↑  +0.3 tears up#Chance to fire gaseous tears that spawn poisonous gas clouds#Spectral tears#Poison immunity"
local spawnType = {
	NORMAL = 0,
	LASER_END = 1,
	EPIC = 2
}
local cloudCount = 0

--NOTE: if you want to check if a tear has the effect, check the tear's data for data.Stink = 2

--known bugs:
-->firing shoop da woop while a stinkeye trisagion shot is on screen will cause the shoop laser to spawn gas on hit
-->lasers that fire outside the cardinal directions place gas in unexcepcted locations while holding brain worm

--External item descriptions compatibility
if EID then
	EID:addCollectible(CollectibleType.COLLECTIBLE_STINK_EYE,DESCRIPTION)
	EID:assignTransformation("collectible",CollectibleType.COLLECTIBLE_STINK_EYE,EID.TRANSFORMATION["BOB"])
end

--put encyclopedia compatibility here
if Encyclopedia then
	local WIKI = {
	DESCRIPTION = {
		{--Effects
			{ str = "Effect", fsize = 2, clr = 3, halign = 0},
			{ str = "+0.3 Tears Up (breaks the cap)"},
			{ str = "Grant's spectral tears, which go over ground obstacles."},
			{ str = "Tears have a chance of spawning a gas cloud when Isaac's tears land or hit."},
			{ str = "The cloud deals 5 damage per tick for 15 damage per second."},
			{ str = "The cloud lasts for 4 seconds."},
			{ str = "Enemies in the cloud get poisoned."},
			{ str = "Clouds will scale their size based on the player's damage."},
			{ str = "The chance to spawn a cloud is based on luck, with 0 luck giving a 33% chance, and 15 luck giving the maximum 50% chance."},
			{ str = "Grants a pseudo poison immunity"}
			
		},
		{--Synergies
			{ str = "Synergies", fsize = 2, clr = 3, halign = 0},
			{ str = "Piercing", fsize = 2},
			{ str = "Tears with the piercing effect spawn a cloud both when hitting the enemy and when landing"},
			{ str = "Splitting", fsize = 2},
			{ str = "Tears that split will sometimes split into stink eye tears. Tears that have the effect and split will all have the effect after splitting."},
			{ str = "Flat Stone", fsize = 2},
			{ str = "Tears will spawn gas clouds for each bounce."},
			{ str = "Dr. Fetus", fsize = 2},
			{ str = "The clouds' damage-based size scaling is tripled. Always has the tear effect."},
			{ str = "Technology", fsize = 2},
			{ str = "Lasers will spawn a cloud for each enemy hit, while also spawning a cloud at the tip of the laser."},
			{ str = "Brimstone/Revelations/ Technology 2/Montezuma's Revenge", fsize = 2},
			{ str = "Has a chance to spawn a cloud every tick of damage, on both enemies and at the tip of their beam."},
			{ str = "Maw of the Void/Tech X", fsize = 2},
			{ str = "Has a chance to spawn a cloud for every tick of damage done to an enemy."},
			{ str = "Ludovico Technique", fsize = 2},
			{ str = "Spawns a gas cloud every second. Does not spawn clouds on enemy contact."},
			{ str = "Trisagion", fsize = 2},
			{ str = "Spawns gas clouds frequently, creating a trail of gas that can easily fill the room."},
			{ str = "Mom's Knife", fsize = 2},
			{ str = "Has a chance to spawn a cloud for every tick of damage dealt to an enemy."},
			{ str = "Epic Fetus", fsize = 2},
			{ str = "The missile spawns gas upon hitting the ground. The clouds' size scaling is tripled. Always has the tear effect."},
			{ str = "Uranus", fsize = 2},
			{ str = "The gas cloud turns white, and slows enemies in addition to damaging them. Can freeze enemies solid."}
			--{ str = ""},

		},
		{--Trivia
			{ str = "Trivia", fsize = 2, clr = 3, halign = 0},
			{ str = "\"The stink eye\" refers to the disgusted look given by those annoyed by another."},
			{ str = "This item was originally planned to behave how trisagion synergy does now, spawning a trail of gas behind the tear. This was shelved due to performance issues."},
			{ str = "The item sprite was originally an edit of Mom's contacts. The costume has always been an edit of Mom's contacts."},
			{ str = "As far as I know, this is the only item to implement a synergy for the Mom's knife and flat stone combo."},
			{ str = "There is a max limit of 128 clouds on screen to prevent lag"}
		}
	}
}
	Encyclopedia.AddItem({ --note: reloading the mod will make another one appear. shouldn't be a problem otherwise
		ID = CollectibleType.COLLECTIBLE_STINK_EYE,
		WikiDesc = WIKI.DESCRIPTION,
		Pools = {
			Encyclopedia.ItemPools.POOL_TREASURE,
			Encyclopedia.ItemPools.POOL_ROTTEN_BEGGAR,
			Encyclopedia.ItemPools.POOL_GREED_TREASURE,
		},
	})
end
--thank you meowlala from github for this function
local function TEARFLAG(x)
    return x >= 64 and BitSet128(0,1<<(x - 64)) or BitSet128(1<<x,0)
end

--60fps funcs
function StinkEye:onPeffectUpdate(player)
	if player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) and player ~= nil then
		--when the player fires, determines if a tear should become a stinky tear
		for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_TEAR)) do
			makeTear(entity)

			local tear = entity:ToTear()
			local data = tear:GetData()

			if data.Stinky == 2 and player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) and not tear:HasTearFlags(TearFlags.TEAR_LASERSHOT)then -- ludo synergy. behaves differently, spawning gas periodically
				if tear.FrameCount % 60 == 0 then
					spawnCloud(player,entity,spawnType.NORMAL)
				end
			end

			
		end

		for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
			 --makes the tear effect visible 
			if entity.FrameCount == 1 and entity.Parent ~= nil and entity.Parent.Type == EntityType.ENTITY_TEAR and entity.Variant == EffectVariant.STINK_EYE then
				entity:SetColor(Color(0.8,1,0.8,0.6,0,0,0),0,0,false,false)
			end

			if entity.Variant == EffectVariant.SMOKE_CLOUD then
				local cloud = entity:ToEffect()
				local data = cloud:GetData()
				--Makes Dr. Fetus shots use the gas cloud that we use, so that the Uranus synergy works
				if cloud.SpawnerType == EntityType.ENTITY_PLAYER and player:HasWeaponType(WeaponType.WEAPON_BOMBS) then
					if data.coldCloud == nil and cloud.Velocity.X == 0 and cloud.SubType == 0 then
						spawnCloud(player,cloud,spawnType.EPIC)
						cloud:Remove()
					end
				end 
				--stinkeye clouds only
				if data ~= nil and data.StinkEye == true then
					-- check to see if the cloud has disappeared, so that cloud count can go down

					if cloud.FrameCount > EXPIRE then --cloud is kill
						if cloudCount > 0 then
							
							cloudCount = cloudCount - 1
						else
							cloudCount = 0
						end

				--uranus synergy
					elseif cloud.FrameCount <= (EXPIRE-1) and data.coldCloud == 1 then
						for _, enemy in ipairs(Isaac.FindInRadius(cloud.Position,(47*cloud.SpriteScale.X),EntityPartition.ENEMY)) do
							if not enemy:HasEntityFlags(EntityFlag.FLAG_ICE) then
								enemy:AddEntityFlags(EntityFlag.FLAG_ICE)
							end
							if not enemy:HasEntityFlags(EntityFlag.FLAG_SLOW) then
								enemy:AddSlowing(EntityRef(player),60,0.5,SLOW_COLOR)
							end
						end
					end
				end

			end
		end
		--laser ludo synergy
		for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_LASER)) do
			local laser = entity:ToLaser()
			local data = laser:GetData()
			if data.Stinky == 2 and player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) then
				if laser.FrameCount % 30 == 0 then
					spawnCloud(player,entity,spawnType.NORMAL)
				end
			end
		end
	end
end


StinkEye:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE,StinkEye.onPeffectUpdate)
--30 fps funcs
function StinkEye:onUpdate()
	--check for tears
	for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_TEAR)) do

		local tear = entity:ToTear()
		local player = getSpawner(tear)
		local data = tear:GetData()
		if player ~= nil and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then
			-- sets tear color
			if not (player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) and tear:HasTearFlags(TearFlags.TEAR_LASERSHOT))then
				if data.Stinky == 2 or player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) then
					tear:SetColor(Color(TEAR_COLOR.R,TEAR_COLOR.G,TEAR_COLOR.B,0.5,TEAR_COLOR.RO,TEAR_COLOR.GO,TEAR_COLOR.BO),0,0,false,false) -- we do all of this so that the ludo tear doesn't flicker.
				else
					tear:SetColor(Color(tear:GetColor().R,tear:GetColor().G,tear:GetColor().B,0.5,tear:GetColor().RO,tear:GetColor().GO,tear:GetColor().BO),0,0,false,false)
				end
			end
				
			--check's to see if a tear comes from a split tear, tells the game to make those tears stinky tears if they came from a stinky tear (which should be that color)
			if (tear:GetColor().R == TEAR_COLOR.R or tear:GetColor().R == LASER_COLOR.R ) and tear.FrameCount == 0 and data.Stinky ~= 2 and not tear:HasTearFlags(TearFlags.TEAR_LASERSHOT) then
				data.Stinky = 1
				makeTear(entity) 
			end
		end

		if tear:HasTearFlags(TearFlags.TEAR_HYDROBOUNCE) and data.Stinky == 2 then --flat stone synergy
			local gBounced = 0
			if tear.Height >= -5.0 then
				gBounced = 1
			end
			if gBounced == 1 and tear.FrameCount ~= 0 then
				spawnCloud(player,tear,spawnType.NORMAL)
			end
		end
	end
	--check for lasers
	for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_LASER)) do
		
		local laser = entity:ToLaser()
		local player = getSpawner(laser)
		local data = laser:GetData()

		--makes bouncing lasers carry the effect through the whole laser
		if player ~= nil and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) and laser.Visible == true then
			if player ~= nil and laser.BounceLaser ~= nil then
				local bounceData = laser.BounceLaser:GetData()
				if bounceData.Stinky ~= 2 and data.Stinky == 2 then
					bounceData.Stinky = 2
				elseif bounceData.Stinky == 2 and data.Stinky ~= 2 then
					data.Stinky = 2
				end
			end
			
			--make split lasers share tear effect
			if player ~= nil and data.Stinky == 2 and laser.FrameCount == 0 then
				for _, ent in pairs (Isaac.FindByType(EntityType.ENTITY_LASER)) do
					--check to see if there is a laser and it is ours
					if ent.SpawnerType == EntityType.ENTITY_PLAYER and GetPtrHash(ent.SpawnerEntity) == GetPtrHash(player)then
						local strayLaser = ent:ToLaser()
						local strayData = strayLaser:GetData()
						--check the laser's data
						if strayLaser.Variant ~= 3 and strayLaser.Variant ~= 7 and strayLaser.Variant ~= 10  and strayLaser.SubType == LaserSubType.LASER_SUBTYPE_LINEAR and strayData.Stinky ~= 2 then
							--position & angle check to eliminate loki's horns & mutant spider type shenanigans
							if (laser.Position.X + laser.PositionOffset.X == strayLaser.Position.X + strayLaser.PositionOffset.X)or(laser.Position.Y + laser.PositionOffset.Y == strayLaser.Position.Y + strayLaser.PositionOffset.Y)and ((strayLaser.AngleDegrees <= laser.AngleDegrees+90.1 and strayLaser.AngleDegrees >= laser.AngleDegrees+89.9) or (strayLaser.AngleDegrees >= laser.AngleDegrees-90.1 and strayLaser.AngleDegrees <= laser.AngleDegrees-89.9) or (strayLaser.AngleDegrees <= laser.AngleDegrees+180.1 and strayLaser.AngleDegrees >= laser.AngleDegrees+179.9) or (strayLaser.AngleDegrees >= laser.AngleDegrees-180.1 and strayLaser.AngleDegrees <= laser.AngleDegrees-179.9)) then
								strayData.Stinky = 2
							end
						end
					end
				end
			end
			--sets the color of most lasers
			if player ~= nil and data.Colored == nil and not laser.OneHit and ( laser.SubType == LaserSubType.LASER_SUBTYPE_LINEAR or laser.SubType == LaserSubType.LASER_SUBTYPE_RING_PROJECTILE )and not player:HasCollectible(CollectibleType.COLLECTIBLE_CONTINUUM) and laser.Variant ~= 10 and laser.Variant ~= 7 and (laser.Variant ~= 3 or data.isTrisag == true) then --does not color continuum lasers, doing otherwise makes the laser flicker	
				laser:SetColor(Color(LASER_COLOR.R,LASER_COLOR.G,LASER_COLOR.B,0.5,LASER_COLOR.RO,LASER_COLOR.GO,LASER_COLOR.BO),0,0,false,false)
				if laser.Variant ~= 2 then --tech 2 lasers need to keep being recolored
					data.Colored = 1
				end	
			end
			--spawns a gascloud at the end of a laser when it hits a wall or rock
			--also sets the color for persistent lasers
			if player ~= nil then
				if laser.OneHit or (player:HasCollectible(CollectibleType.COLLECTIBLE_LUDOVICO_TECHNIQUE) and not laser:HasTearFlags(TearFlags.TEAR_LASERSHOT)) and laser.Variant ~= 10 and (laser.Variant ~= 3 or data.isTrisag == true) then --sets the color for tech2 lasers
					if data.Stinky == 2 then
						laser:SetColor(Color(LASER_COLOR.R,LASER_COLOR.G,LASER_COLOR.B,0.5,LASER_COLOR.RO,LASER_COLOR.GO,LASER_COLOR.BO),0,0,false,false) 
					end
				end
				if laser.OneHit and data.wallHit == nil and data.Stinky == 2 and not laser:IsCircleLaser() then --tech1 and tech.5
					--makes bouncy lasers work, idk why
					if laser.DisableFollowParent == true and laser.BounceLaser ~= nil then
						spawnCloud(player,laser,spawnType.LASER_END)
					else
						spawnCloud(player,laser,spawnType.LASER_END)
					end
					data.wallHit = 1 --If this isn't here, multiple gas clouds spawn from bouncy lasers
				elseif not laser:IsCircleLaser() and laser.Variant ~= 10 and laser.Variant ~= 7 and (laser.Variant ~= 3 or data.isTrisag == true) and not laser.OneHit then --tech 2, revelations and brim
					--determine rng for each tick
					data.stinkRoll = stinkRNG(player)

					if not laser:IsCircleLaser() and data.stinkRoll then
						if laser.FrameCount % 2 == 0 then
							spawnCloud(player,laser,spawnType.LASER_END)
						end
					end
				end
			end
		end
	end
	--knife + flat stone synergy
	for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_KNIFE)) do
		local knife = entity:ToKnife()
		local player = getSpawner(knife)
		
		local data = knife:GetData()
		if player ~= nil and knife:HasTearFlags(TearFlags.TEAR_HYDROBOUNCE) and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then
			local gBounced = 0
			for _, ent in pairs (Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
				--checks to see if the splash effect has existed for more than 2 frames, and flags the knife if so
				if ent.Variant == 14 and ent.FrameCount <= 1 then 
					gBounced = 1
				else
					gBounced = 0
				end

				if gBounced == 1 and knife:IsFlying() then
					spawnCloud(player,knife,spawnType.NORMAL)
					
				end
			end
		end
	end 
	--handles effect-based tear effects
	for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_EFFECT)) do
		--handles epic fetus rockets
		if entity.Variant == EffectVariant.ROCKET then
			local rocket = entity:ToEffect()
			local player = getSpawner(rocket)
			--checks the "height" of the rocket
			if rocket.PositionOffset.Y == -100 and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then
				spawnCloud(player,rocket,spawnType.EPIC)
			end
		end
		--forgotten's brimstone synergy
		if entity.Variant == EffectVariant.BRIMSTONE_BALL then
			local brim = entity:ToEffect()
			local player = getSpawner(brim)
			if player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then
				if brim.FrameCount <= 1 then
					brim:SetColor(Color(LASER_COLOR.R,LASER_COLOR.G,LASER_COLOR.B,0.5,LASER_COLOR.RO,LASER_COLOR.GO,LASER_COLOR.BO),0,0,false,false)
				end
				if brim.FrameCount % 10 == 0 then
					spawnCloud(player,brim,spawnType.NORMAL)
				end
			end
		end
		-- manages the sprite of the tear effect
		if entity.Parent ~= nil and entity.Parent.Type == EntityType.ENTITY_TEAR then
			local gas = entity:ToEffect()
			local gasTear = entity.Parent:ToTear()
			local player = getSpawner(gasTear)
			--this is so anti-grav tears don't look weird

			if gas.Velocity.X == 0 and gas.Velocity.Y == 0 then

				if gas.FrameCount == 0 then
					gas.SpriteRotation = gasTear.ContinueVelocity:GetAngleDegrees()

				end
			else
				--rotate effect based on direction & fall speed (not exactly 1 to 1 with the game, but good enough)
				if gasTear.Velocity.X > 0 then
					gas.SpriteRotation = gas.Velocity:GetAngleDegrees() + (gasTear.FallingSpeed * 4.5 * ((gasTear.Velocity.X)/(gasTear.Velocity.X+math.abs(gasTear.Velocity.Y))) * (math.abs(gasTear.Velocity.X)/gasTear.Velocity.X))
				elseif gasTear.Velocity.X == 0 then
					gas.SpriteRotation = gas.Velocity:GetAngleDegrees() + (gasTear.FallingSpeed * 4.5) --ludo acts weird because of a divide by 0 error if this condition isn't here
				elseif gasTear.Velocity.X < 0 then
					gas.SpriteRotation = gas.Velocity:GetAngleDegrees() + (gasTear.FallingSpeed * 4.5 * ((gasTear.Velocity.X)/(gasTear.Velocity.X-math.abs(gasTear.Velocity.Y))) * (math.abs(gasTear.Velocity.X)/gasTear.Velocity.X))
				end
			end 
			--dynamically scale effect with tear size
			gas.SpriteScale = Vector(0.5,0.5) * gasTear.Scale 
		end
	end
	
end
StinkEye:AddCallback(ModCallbacks.MC_POST_UPDATE,StinkEye.onUpdate)
--attack variant specific callbacks--
--for tears
function StinkEye:onTearUpdate(tear)
	local data = tear:GetData()
	if data.Stinky == nil then
		local player = getSpawner(tear)
		--determine if tear will have the effect
		if player ~= nil then 
			if tear:HasTearFlags(TearFlags.TEAR_LASERSHOT) == true and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) and stinkRNG(player) and data.Stinky == nil then
				data.Stinky = 2
			elseif tear:HasTearFlags(TearFlags.TEAR_LASERSHOT) == false and tear.Variant ~= TearVariant.FIRE and tear.Variant ~= TearVariant.ERASER and tear.Variant ~= TearVariant.GRIDENT and tear.Variant ~= TearVariant.CHAOS_CARD and tear.Variant ~= TearVariant.BOBS_HEAD  and ((player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE))or (player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) and stinkRNG(player))) and data.Stinky == nil then
				data.Stinky = 1
			else
				data.Stinky = 0
			end
		else
			data.Stinky = 0
		end
		--end
	end
end
--for single-tick lasers. Multi-tick lasers roll for each tick of damage
--done on init since update runs after the entitytakedamage callback, which needs to be run after initialization.
function StinkEye:onLaserInit(laser)
	local data = laser:GetData()
	data.isTrisag = false
	for _, tear in pairs (Isaac.FindByType(EntityType.ENTITY_TEAR)) do --account for weird behavior from trisagion lasers
		if tear.Position:Distance(laser.Position) <=1 then
			data.isTrisag = true
		end 
	end
	if data.Stinky == nil and laser.Variant ~= 7 and (laser.Variant ~= 3 or data.isTrisag == true) and laser.Variant ~= 10  then --ignore tractor beam, shoop, trisagion, and jacob's ladder type lasers
		local player = getSpawner(laser)
		-- rng calc
		if player ~= nil and  (player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) or (player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) == true and stinkRNG(player) and data.Stinky == nil)) then
			data.Stinky = 2
		else
			data.Stinky = 0
		end
	end
end

function StinkEye:onLaserUpdate(laser)
	local  data = laser:GetData()
	local player = getSpawner(laser)
	if player ~= nil and player.TearFlags ~= laser.TearFlags then
		data.Stinky = 0
	end
end
--for knives and other melee weapons, add the tear effect
function StinkEye:onKnifeUpdate(entityKnife)
	local data = entityKnife:GetData()
	local player = getSpawner(entityKnife)

	if player ~= nil and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then
		--color the knife
		entityKnife:SetColor(Color(TEAR_COLOR.R,TEAR_COLOR.G,TEAR_COLOR.B,0.5,TEAR_COLOR.RO,TEAR_COLOR.GO,TEAR_COLOR.BO),0,0,false,false)
		-- rng calc
		if player ~= nil and (player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) or (player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) == true and stinkRNG(player))) then
			data.Stinky = 2
		else
			data.Stinky = 0
		end
	end
end
--for dr. fetus. Applies game's built in interaction
function StinkEye:onBombUpdate(bomb)

	player = getSpawner(bomb)
	if bomb.Type == EntityType.ENTITY_BOMBDROP and player ~= nil and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) == true then
		if bomb.IsFetus == true then
			bomb:AddTearFlags(TearFlags.TEAR_POISON)
			bomb:SetColor(Color(bomb:GetColor().R,bomb:GetColor().G,bomb:GetColor().B,0.5,bomb:GetColor().RO,bomb:GetColor().GO,bomb:GetColor().BO),0,0,false,false)
		end
	end
end

StinkEye:AddCallback(ModCallbacks.MC_POST_TEAR_UPDATE,StinkEye.onTearUpdate)
StinkEye:AddCallback(ModCallbacks.MC_POST_LASER_INIT,StinkEye.onLaserInit)
StinkEye:AddCallback(ModCallbacks.MC_POST_KNIFE_UPDATE,StinkEye.onKnifeUpdate)
StinkEye:AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE,StinkEye.onBombUpdate)

--for normal tears, spawn clouds when tears land or hit something
function StinkEye:onTearRemove(entity)
	if entity.Type == EntityType.ENTITY_TEAR then
		local data = entity:GetData() 
		if entity.SpawnerEntity ~= nil then
			local spawner = entity.SpawnerEntity
			if spawner:ToPlayer() ~=nil then
				player = spawner:ToPlayer()
			elseif spawner:ToFamiliar() ~=nil then
				player = spawner:ToFamiliar().Player
			end
			if data.Stinky == 2 and not entity:ToTear():HasTearFlags(TearFlags.TEAR_LASERSHOT) then
				spawnCloud(player,entity,spawnType.NORMAL)
			end
		end
		--gets rid of the tear effect. down here and not in the above check because T. lilith and T.laz mess with it.
		if data.Stinky == 2 and not entity:ToTear():HasTearFlags(TearFlags.TEAR_LASERSHOT) then
			data.SmokeBall:Remove()
		end
	end
end
--Piercing tears interaction
function StinkEye:onTearHit(tear,victim)
	local player = getSpawner(tear)
	local data = tear:GetData()
	if data.Stinky == 2 and tear:HasTearFlags(TearFlags.TEAR_PIERCING) and not player:HasWeaponType(WeaponType.WEAPON_LUDOVICO_TECHNIQUE) and data.Pierced == nil then
		spawnCloud(player,tear,spawnType.NORMAL)
		data.Pierced = 1
	end
	if tear.FrameCount % 30 == 0 then
		data.Pierced = nil
	end
	return nil
end

--for lasers, spawn clouds on hit at hit location
function StinkEye:onLaserDamage(tookDmg,dmgAmount,dmgFlags,dmgSource)
	if tookDmg:IsVulnerableEnemy()  then
		if dmgSource.Type == EntityType.ENTITY_PLAYER or dmgSource.Type == EntityType.ENTITY_FAMILIAR then
			if dmgSource.Type == EntityType.ENTITY_PLAYER then
				local player = dmgSource.Entity:ToPlayer()
			elseif dmgSource.Type == EntityType.ENTITY_FAMILIAR then
				local player = dmgSource.Entity:ToFamiliar().Player
			else
				local player = nil
			end
			local laser = nil
			local data = nil
			for _, entity in pairs (Isaac.FindByType(EntityType.ENTITY_LASER)) do
				if player ~= nil and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE)  then
					local laser = entity:ToLaser()
					local data = laser:GetData()
					if laser.Visible == true then
						if laser.OneHit then --tech1 and tech.5
							if data ~= nil and data.Stinky == 2 then
								spawnCloud(player,tookDmg,spawnType.NORMAL)
							end
						else --tech 2 and brim 
							--check roll from update func
							if data.stinkRoll ~= nil and data.stinkRoll then
								spawnCloud(player,tookDmg,spawnType.NORMAL)
							elseif laser:IsCircleLaser() and stinkRNG(player) then
								spawnCloud(player,tookDmg,spawnType.NORMAL)
							end
						end
					end
				end
			end
		end
	end
	return nil
end
--for knives, spawn clouds when damaging enemies
function StinkEye:onKnifeDamage(tookDmg,dmgAmount,dmgFlags,dmgSource)
	if tookDmg:IsVulnerableEnemy() then
		if dmgSource.Type == EntityType.ENTITY_KNIFE then
			knife = dmgSource.Entity:ToKnife()
			local data = knife:GetData()
			local player = nil
			player = getSpawner(knife)
			if player ~= nil and player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) and knife.FrameCount % 2 == 0 and data ~= nil and data.Stinky == 2 then
				spawnCloud(player,tookDmg,spawnType.NORMAL)
			end
		end
	end
	return nil
end

StinkEye:AddCallback(ModCallbacks.MC_POST_ENTITY_REMOVE,StinkEye.onTearRemove)
StinkEye:AddCallback(ModCallbacks.MC_PRE_TEAR_COLLISION,StinkEye.onTearHit)
StinkEye:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,StinkEye.onLaserDamage)
StinkEye:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,StinkEye.onKnifeDamage)

--negates poison damage(poison clouds, mushroom clouds). does NOT work with holy mantle (unsupported?)
function StinkEye:onPoisonIgnore(tookDmg,dmgAmount,dmgFlags,dmgSource,dmgType)
	if tookDmg.Type == EntityType.ENTITY_PLAYER and (dmgSource.Variant == EffectVariant.SMOKE_CLOUD or (dmgSource.Type == 0 and dmgSource.Variant == 0 and dmgFlags == 0 and dmgType == 30))then
		local player = tookDmg:ToPlayer()

		if player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then 
			return false
		else
			return nil
		end
	else
		return nil
	end
end


StinkEye:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG,StinkEye.onPoisonIgnore)

--resets cloud count to zero when leaving a room
function StinkEye:leaveRoom()
	cloudCount = 0
end

StinkEye:AddCallback(ModCallbacks.MC_POST_NEW_ROOM,StinkEye.leaveRoom)

--updates your tears stat
function StinkEye:onCache(player,cacheFlag)
	if cacheFlag == CacheFlag.CACHE_FIREDELAY then
 		--adds a flat tears up that goes past the tears cap and ignores multipliers, a 0.3 tear delay down
 		tears = tearMod(TEARS_ADD,player)
		player.MaxFireDelay = math.max(((30/((30/(player.MaxFireDelay + 1))+(player:GetCollectibleNum(CollectibleType.COLLECTIBLE_STINK_EYE)*tears)))-1),-0.999)

		
	end
	if cacheFlag == CacheFlag.CACHE_TEARFLAG then
		if player:HasCollectible(CollectibleType.COLLECTIBLE_STINK_EYE) then
			player.TearFlags = player.TearFlags|TearFlags.TEAR_SPECTRAL
		end
	end
end

StinkEye:AddCallback(ModCallbacks.MC_EVALUATE_CACHE, StinkEye.onCache)

--local functions
--poison cloud spawning fuction
function spawnCloud(player,entity,spawn)
	local puff = nil
	local gasCloud = nil
	local dmg = player.Damage

	if cloudCount < 128 then
		--normal spawning behavior
		if spawn == spawnType.NORMAL then 
			local randOffset = Vector( math.random(50)-25, math.random(50)-25) --sets the spawn offset for the clouds
			--spawns the cloud and a spawn-in effect
			puff = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, Vector(entity.Position.X+randOffset.X,entity.Position.Y+randOffset.Y), Vector(0,0), player):ToEffect()
			gasCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, Vector(entity.Position.X+randOffset.X,entity.Position.Y+randOffset.Y), Vector(0,0), player):ToEffect()
		--laser spawning
		elseif spawn == spawnType.LASER_END then
			local laser = entity:ToLaser()
			--get the laser tip through raytracing (built-in laser endpoint var does not function correctly)
			--check if the laser has limited length
			local maxDistance = 10000 --arbitrarily large number
			if laser.MaxDistance > 0 then
				maxDistance = laser.MaxDistance
			end
			--originally written for grident collision, but homing lasers were beyond my comprehension, so I just added a spectral flag and moved on
			local angle = laser.AngleDegrees
			local pointA = laser.Position--laser spawn point
			local collide = 0
			local pointB = pointA--hopefully, this is the laser endpoint
			local timeLimit = 0 --we set a limit on how many times the loop can iterate below to optimize performance
			local x = 0
			local y = 0
			--vars for synergies
			local turnt = false
			local flipped = false
			local closeDistance = 15
			--move the point along
			while collide ~= 1 and timeLimit < 200 do	
				
				--my reflection
				if player.TearFlags & TearFlags.TEAR_BOOMERANG == TearFlags.TEAR_BOOMERANG and flipped == false then
					angle = angle + 180
					flipped = true
					closeDistance = 0
				end
				--brainworm
				if (player.TearFlags & TEARFLAG(71) == TEARFLAG(71)) and turnt == false then
					for _, enemy in ipairs (Isaac.FindInRadius(pointB,1250,EntityPartition.ENEMY)) do --find nearest enemy
						--determine the proper way to change the angle based on where the laser, player, and enemy are.
						if enemy:IsVulnerableEnemy() then
							if (math.abs(player.Position.X - enemy.Position.X) > closeDistance and math.abs(player.Position.Y - enemy.Position.Y) > 120) or (math.abs(player.Position.X - enemy.Position.X) > 120 and math.abs(player.Position.Y - enemy.Position.Y) > closeDistance) then
								--horizontal lasers
								if pointB.X+15 >= enemy.Position.X and pointB.X-15 <= enemy.Position.X and not (player.Position.X+15 >= enemy.Position.X and player.Position.X-15 <= enemy.Position.X) then
									if pointB.Y >= enemy.Position.Y then
										if player.Position.X > enemy.Position.X then
											angle = angle + 90
											turnt = true
										elseif player.Position.X <= enemy.Position.X then
											angle = angle - 90
											turnt = true
											
										end
									elseif pointB.Y < enemy.Position.Y then
										if player.Position.X > enemy.Position.X then
											angle = angle - 90
											turnt = true
										elseif player.Position.X <= enemy.Position.X then
											angle = angle + 90
											turnt = true

										end
									end
								--vertical lasers
								elseif pointB.Y+15 >= enemy.Position.Y and pointB.Y-15 <= enemy.Position.Y and not (player.Position.Y+15 >= enemy.Position.Y and player.Position.Y-15 <= enemy.Position.Y) and math.abs(player.Position.Y-enemy.Position.Y) >=110 then
									if pointB.X >= enemy.Position.X then
										if player.Position.Y > enemy.Position.Y then
											angle = angle - 90
											turnt = true
										elseif player.Position.Y <= enemy.Position.Y then
											angle = angle + 90
											turnt = true
										end
									elseif pointB.X < enemy.Position.X then
										if player.Position.Y > enemy.Position.Y then
											angle = angle + 90
											turnt = true
										elseif player.Position.Y <= enemy.Position.Y then
											angle = angle - 90
											turnt = true
										end
									end
								end
							end
						end
					end
				end

				x = pointB.X + (Vector.FromAngle(angle).X*10) --convert angle to vector to move along path at the correct angle
				y = pointB.Y + (Vector.FromAngle(angle).Y*10)
				--get the distance for azazel and other cases with limited laser length
				local dist = pointA:Distance(pointB)
				--collision check
				if (Game():GetRoom():GetGridCollisionAtPos(pointB) == GridCollisionClass.COLLISION_WALL or dist > maxDistance) then
					if timeLimit ~= 0 then
						collide = 1
					else
						--Account for bottom wall strangeness
						y = y-10
						pointB = Vector(x,y)
						timeLimit = timeLimit + 1
					end
				else
					pointB = Vector(x,y)
					timeLimit = timeLimit + 1
				end
			end
			local laserTip = pointB
			--spawns a gascloud at the tip of the laser's tip
			puff = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, laserTip, Vector(0,0), player):ToEffect()
			gasCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, laserTip, Vector(0,0), player):ToEffect()
		--epic fetus spawning, to account for damage scaling
		elseif spawn == spawnType.EPIC then
			puff = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, Vector(entity.Position.X,entity.Position.Y), Vector(0,0), player):ToEffect()
			gasCloud = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.SMOKE_CLOUD, 0, Vector(entity.Position.X,entity.Position.Y), Vector(0,0), player):ToEffect()
			dmg = dmg * 3
		end
		--configure the cloud
		if puff ~= nil and gasCloud ~= nil then
			--set the color annd scale of the spawn-in puff

			local cloudData = gasCloud:GetData()

			gasCloud:SetColor(Color(0,2,0,0,0,0,0),EXPIRE,0,false,false) --makes the cloud fade out
			-- change color and properties of cloud depending of player's items
			if (player.TearFlags & TEARFLAG(65) == TEARFLAG(65) ) then --icy cloud
				--gasColor = Color:SetColorize(,,,)
				puff:SetColor(Color(3.3,6,9,1,0,0,0),0,0,false,false)
				gasCloud:SetColor(Color(4,10,10,0,0,0,0),0,0,false,false)
				cloudData.coldCloud = 1
			else--standard cloud
				puff:SetColor(Color(0.1,1,0.1,1,0,0,0),0,0,false,false)
				gasCloud:SetColor(Color(0,1.7,0,0,0,0,0),0,0,false,false) --sets the color (again) so that the fadeout isn't broken
				cloudData.coldCloud = 0
			end
			puff.SpriteScale = Vector(math.min(1.5,math.max(0.6,0.075*dmg + 0.5)),math.min(1.5,math.max(0.6,0.075*dmg + 0.5)))

			gasCloud.SpriteScale = Vector(math.min(2,math.max(0.7,0.1*dmg + 0.5)),math.min(2,math.max(0.7,0.1*dmg + 0.5))) --scale's cloud with damage, maxing out size at 15 damage
			gasCloud:GetData().StinkEye = true --makes it the player's gas cloud
			gasCloud.CollisionDamage = 5 -- to match other gas clouds
			gasCloud:SetTimeout(EXPIRE) --makes the gas cloud disappear after 4 seconds 
			cloudCount = cloudCount + 1
			return gasCloud
		end	
	end
end
--adds the tear's trailing gas effect
function makeTear(entity)

	local data = entity:GetData()
	local spawner = getSpawner(entity)
	if data.Stinky == 1 then
		data.Stinky = 2
		local tear = entity:ToTear()
		--makes the tear effect
		local gasTear = Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.STINK_EYE, 0, tear.Position, Vector(0,0), tear):ToEffect()
		local origColor = tear:GetColor()
		--set color, but make alpha 0 so that a visual glitch doesn't occur. It's changed back to one in a different function
		gasTear:SetColor(Color(0.7,1,0.7,0,origColor.R,origColor.G,origColor.B),0,0,false,false)
		gasTear.DepthOffset = -1
		gasTear:FollowParent(tear)
		gasTear.Rotation = tear.Rotation
		data.SmokeBall = gasTear
	end
end

--function to get the damage source and assign it to player
function getSpawner(ent)
	local spawner = ent.SpawnerEntity
	if spawner ~= nil then 
		if spawner.Type == EntityType.ENTITY_PLAYER then
			player = spawner:ToPlayer()
		elseif spawner.Type == EntityType.ENTITY_FAMILIAR then --check if incubus-like
			if spawner.Variant == FamiliarVariant.INCUBUS or spawner.Variant == FamiliarVariant.FATES_REWARD or spawner.Variant == FamiliarVariant.TWISTED_BABY or spawner.Variant == FamiliarVariant.BLOOD_BABY or spawner.Variant == FamiliarVariant.UMBILICAL_BABY then
				player = spawner:ToFamiliar().Player
			else
				player = nil
			end
		else
			player = nil
		end
	end
	return player
end
--modify the tears stat based on items
function tearMod(tears,player)
	--character modifiers
	if player:GetPlayerType() == PlayerType.PLAYER_AZAZEL or player:GetPlayerType() == PlayerType.PLAYER_AZAZEL_B  then
		tears = tears * 0.33
	end

	if player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN or player:GetPlayerType() == PlayerType.PLAYER_THEFORGOTTEN_B then
		tears = tears * 0.5
	end
	if player:GetPlayerType() == PlayerType.PLAYER_EVE_B  then
		tears = tears * 0.66
	end
	--item modifiers
	local itemTable = {
		[CollectibleType.COLLECTIBLE_BRIMSTONE] = 1/3,
		[CollectibleType.COLLECTIBLE_DR_FETUS] = 0.4,
		[CollectibleType.COLLECTIBLE_EVES_MASCARA] = 0.66,
		[CollectibleType.COLLECTIBLE_HAEMOLACRIA] = 0.35,
		[CollectibleType.COLLECTIBLE_IPECAC] = 0.33,
		[CollectibleType.COLLECTIBLE_MONSTROS_LUNG]= 1/4.3,
		[CollectibleType.COLLECTIBLE_TECHNOLOGY_2] = 2/3
	}
	for x,y in pairs (itemTable) do
		if player:HasCollectible(x) then
			tears = tears * y
		end
	end
	--special case
	if player:HasCollectible(CollectibleType.COLLECTIBLE_POLYPHEMUS) or player:HasCollectible(CollectibleType.COLLECTIBLE_MUTANT_SPIDER) then
		tears = tears * 0.42
	elseif player:HasCollectible(CollectibleType.COLLECTIBLE_INNER_EYE) then
		tears = tears * 0.51
	end
	
	if player:HasCollectible(CollectibleType.COLLECTIBLE_SOY_MILK) then
		tears = tears * 5.5
	elseif player:HasCollectible(CollectibleType.COLLECTIBLE_ALMOND_MILK) then
		tears = tears * 4
	end
	
	--temp effects
	if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_BERSERK) then
		tears = tears * 0.5
	end

	--trinket modifiers
	if player:HasTrinket(TrinketType.TRINKET_CRACKED_CROWN) then
		tears = tears * 1.2
	end
	return tears
end
--calculates the chance a tear gets the tear effect
function stinkRNG (player)

	local roll = math.random(100)
	--account for teardrop charm
	local tDrop = 0
	if player ~= nil and player:HasTrinket(TrinketType.TRINKET_TEARDROP_CHARM) then
		tDrop = 3
	end
	--return true if roll is lower
 	return (roll <= math.min(player.Luck,MAX_LUCK)*(17/15) + BASE_CHANCE)
end

--eof