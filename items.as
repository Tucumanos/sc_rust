void inventoryCheck()
{
	for (uint i = 0; i < g_item_drops.size(); i++)
	{
		if (!g_item_drops[i].IsValid())
			continue;
		if (g_item_drops[i].GetEntity().pev.teleport_time < g_Engine.time)
		{
			CBaseEntity@ item = g_item_drops[i];
			item.pev.renderfx = -9999;
			remove_item_from_drops(item);
			g_EntityFuncs.Remove(item);
			i--;
		}
		else
			g_item_drops[i].GetEntity().pev.renderfx = 0;
	}
	for (uint i = 0; i < g_corpses.size(); i++)
	{
		if (!g_corpses[i].IsValid())
			continue;
		g_corpses[i].GetEntity().pev.renderfx = 0;
	}
	
	
	// check for dropped weapons
	CBaseEntity@ wep = null;
	do {
		@wep = g_EntityFuncs.FindEntityByClassname(wep, "weapon*");
		
		if (wep !is null and wep.pev.noise3 == "")
		{
			if (wep.pev.effects & EF_NODRAW == 0 and wep.pev.movetype != MOVETYPE_NONE)
			{			
				wep.pev.noise3 = "killme";
				g_Scheduler.SetTimeout("delay_remove_wep", g_item_time, EHandle(wep));
			}
		}
	} while(wep !is null);
	
	// thrown weapons
	@wep = null;
	do {
		@wep = g_EntityFuncs.FindEntityByClassname(wep, "custom_projectile");
		
		if (wep !is null and wep.pev.noise3 == "")
		{
			wep.pev.noise3 = "killme";
			g_Scheduler.SetTimeout("delay_remove_wep", g_item_time, EHandle(wep));
		}
	} while(wep !is null);
	
	// check for dropped ammo
	CBaseEntity@ ammo = null;
	do {
		@ammo = g_EntityFuncs.FindEntityByClassname(ammo, "ammo*");
		if (ammo !is null and ammo.pev.noise3 == "")
		{
			CBaseEntity@ owner = g_EntityFuncs.Instance(ammo.pev.owner);
			if (owner !is null and owner.IsPlayer())
			{
				CBasePlayer@ plr = cast<CBasePlayer@>(owner);
				PlayerState@ state = getPlayerState(plr);

				ammo.pev.noise3 = "killme";
				g_Scheduler.SetTimeout("delay_remove_wep", g_item_time, EHandle(ammo));			

			}
		}
	} while(ammo !is null);
	
	CBaseEntity@ e_plr = null;
	do {
		@e_plr = g_EntityFuncs.FindEntityByClassname(e_plr, "player");
		
		if (e_plr !is null)
		{
			if (e_plr.pev.deadflag > 0)
			{
				e_plr.pev.renderfx = 0;
				if (e_plr.pev.sequence != 13)
				{
					e_plr.pev.frame = 0;
					e_plr.pev.sequence = 13;
				}
			}
		
			CBasePlayer@ plr = cast<CBasePlayer@>(e_plr);
			PlayerState@ state = getPlayerState(plr);
			if (!state.inGame)
				continue;
			state.updateDroppedWeapons();
			
			state.oldDead = plr.pev.deadflag;
			
			bool viewingGui = state.menuCam.IsValid();
			
			if (plr.pev.deadflag > 0)
			{
				if (viewingGui) {
					exitMenu(state.menuCam, plr);
				}
				continue;
			}
			
			if (plr.FlashlightIsOn()) {
				exitMenu(state.menuCam, plr);
				openPlayerMenu(plr, "");
				plr.FlashlightTurnOff();
			}
			
			if (viewingGui) {
				CBaseEntity@ cam = state.menuCam;
				cam.pev.origin = plr.pev.origin + plr.pev.view_ofs;
				cam.pev.angles = plr.pev.v_angle;
			}
			
			if (g_Engine.time - state.lastDangerous > g_apache_forget_time)
				plr.SetClassification(CLASS_XRACE_PITDRONE);
				
			// check if player has armor or weapons (apache should target this player)
			if (!g_invasion_mode)
			{
				if (plr.pev.armorvalue > 10)
				{
					plr.SetClassification(CLASS_ALIEN_MILITARY);						
					state.lastDangerous = g_Engine.time;
				}
				else
				{
					for (uint i = 0; i < MAX_ITEM_TYPES; i++)
					{
						CBasePlayerItem@ item = plr.m_rgpPlayerItems(i);
						while (item !is null)
						{
							string cname = item.pev.classname;
							if (cname != "weapon_rock" and cname != "weapon_syringe" and cname != "weapon_stone_pickaxe" and
								cname != "weapon_stone_hatchet" and cname != "weapon_metal_hatchet" and
								cname != "weapon_metal_pickaxe" and cname != "weapon_custom_crowbar" and cname != "weapon_guitar"
								and cname != "weapon_hammer" and cname != "weapon_building_plan")	
							{
								//println("YOU ARE DANGEROUS BECAUSE " + cname);
								plr.SetClassification(CLASS_ALIEN_MILITARY);
								state.lastDangerous = g_Engine.time;
								break;
							}
							@item = cast<CBasePlayerItem@>(item.m_hNextItem.GetEntity());	
						}
					}
				}
			}
			
			TraceResult tr = TraceLook(plr, 96, true);
			CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
			
			// keep item list up-to-date (will be stale after firing weapon/reloading/etc.
			// TODO: This isn't perfect. "+attack;wait;-attack;retry" will give you free ammo sometimes
			// but increasing poll rate might be too cpu intensive...
			CBasePlayerWeapon@ activeWep = cast<CBasePlayerWeapon@>(plr.m_hActiveItem.GetEntity());
			if (activeWep !is null)
			{
				Item@ item = getItemByClassname(activeWep.pev.classname);
				if (item !is null)
					state.updateItemListQuick(item.type, activeWep.m_iClip);
			}
			state.oldAngles = plr.pev.v_angle;
			state.oldHealth = plr.pev.health;
			state.oldArmor = plr.pev.armorvalue;
			
			if (state.currentChest)
			{
				float touchDist = getUseDistance(state.currentChest.GetEntity());
				if ((state.currentChest.GetEntity().pev.origin - plr.pev.origin).Length() > touchDist)
				{
					state.currentChest = null;
					g_PlayerFuncs.PrintKeyBindingString(plr, "Objeto fuera de alcance");
					state.closeMenus();
				}
			}
			
			if (!viewingGui)
				drawMap(state);
			
			HUDTextParams params;
			params.effect = 0;
			params.fadeinTime = 0;
			params.fadeoutTime = 0;
			params.holdTime = 0.3f;
			params.r1 = 255;
			params.g1 = 255;
			params.b1 = 255;
			params.x = -1;
			params.y = 0.7;
			params.channel = 1;
			
			// highlight items on ground (and see what they are)
			CBaseEntity@ closestItem = getLookItem(plr, tr.vecEndPos);
			
			//println("CLOSE TO  " + g_item_drops.size());
			
			if (closestItem !is null)
			{
				closestItem.pev.renderfx = kRenderFxGlowShell;
				closestItem.pev.renderamt = 1;
				closestItem.pev.rendercolor = Vector(200, 200, 200);
				
				if (closestItem.IsPlayer() and (plr.pev.button & IN_USE) != 0)
				{
					CBasePlayer@ revPlr = cast<CBasePlayer@>(closestItem);
					if (state.reviving)
					{
						float time = g_Engine.time - state.reviveStart;
						float t = time / g_revive_time;
						string progress = "\n\n[";
						for (float i = 0; i < 1.0f; i += 0.03f)
						{
							progress += t > i ? "|||" : "__";
						}
						progress += "]";
						
						if (time > 0.5f)
						{
							if (!viewingGui) {
								g_PlayerFuncs.HudMessage(plr, params, "Reviviendo a " + revPlr.pev.netname + progress);
								g_PlayerFuncs.HudMessage(revPlr, params, "" + plr.pev.netname + " te esta reviviendo" + progress);
							}
						}
						
						if (time > g_revive_time)
						{
							closestItem.EndRevive(0);
							revive_finish(EHandle(closestItem));
						}
					}
					else
					{
						state.reviving = true;
						state.reviveStart = g_Engine.time;
					}
				}
				else
				{
					state.reviving = false;
					if (!viewingGui)
						g_PlayerFuncs.HudMessage(plr, params, getItemDisplayName(closestItem));
				}
				continue;
			}
			else
			{
				state.reviving = false;
			}
			
			if (phit is null or phit.pev.classname == "worldspawn" or phit.pev.colormap == -1)
				continue;
			
			if (!viewingGui)
				g_PlayerFuncs.HudMessage(plr, params, 
					string(prettyPartName(phit)) + "\n" + int(phit.pev.health) + " / " + int(phit.pev.max_health));
		}
	} while(e_plr !is null);

}

void delay_remove_wep(EHandle wep)
{
	if (wep)
	{
		CBaseEntity@ ent = wep;
		CBaseEntity@ owner = g_EntityFuncs.Instance( ent.pev.aiment );
		if (owner is null)
			g_EntityFuncs.Remove(wep);
	}
}

void item_dropped(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if (pCaller.pev.classname != "item_inventory" and !pActivator.IsPlayer())
		return;
		
	CBasePlayer@ plr = cast<CBasePlayer@>(pActivator);
	CItemInventory@ item = cast<CItemInventory@>(pCaller);
	if (item.pev.renderfx == -9999)
		return; // this was just a stackable item that was replaced with a larger stack, ignore it
	
	PlayerState@ state = getPlayerState(plr);
	/*
	if (state.droppedItems >= g_max_item_drops)
	{
		g_PlayerFuncs.PrintKeyBindingString(plr, "Can't drop more than " + g_max_item_drops + " item" + (g_max_item_drops > 1 ? "s" : ""));
		// timeout prevents repeating item_dropped over and over (SC bug)
		g_Scheduler.SetTimeout("undo_drop", 0.0f, EHandle(item), EHandle(plr)); 
		return;
	}
	*/
	state.updateItemList();
	
	item.pev.teleport_time = g_Engine.time + g_item_time;
	
	//state.droppedItems++;
	item.pev.noise1 = getPlayerUniqueId(plr);
	
	g_item_drops.insertLast(EHandle(item));
	item.pev.team = 0; // trigger item_collect callback
}

void remove_item_from_drops(CBaseEntity@ item)
{
	for (uint i = 0; i < g_item_drops.size(); i++)
	{
		if (!g_item_drops[i].IsValid() or g_item_drops[i].GetEntity().entindex() == item.entindex())
		{
			if (g_item_drops[i].IsValid())
			{
				CBasePlayer@ owner = getPlayerByName(null, g_item_drops[i].GetEntity().pev.noise1, true);
				//if (owner !is null)
				//	getPlayerState(owner).droppedItems--;
			}
			
			g_item_drops.removeAt(i);
			i--;
			break;
		}
	}
}

void item_collected(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if (pCaller.pev.classname != "item_inventory" or !pActivator.IsPlayer())
		return;
		
	CBasePlayer@ plr = cast<CBasePlayer@>(pActivator);
	int type = pCaller.pev.colormap-1;
	int amount = pCaller.pev.button;
	if (amount <= 0)
		amount = 1;
	
	if (pCaller.pev.team != 1)
	{
		g_PlayerFuncs.PrintKeyBindingString(plr, "" + amount + "x " + g_items[type].title);
		if (g_items[type].stackSize > 1)
		{
			Vector oldOri = pCaller.pev.origin;
			string oldOwner = pCaller.pev.noise1;
			int barf = combineItemStacks(plr, type);
			if (barf > 0)
			{
				CBaseEntity@ item = spawnItem(oldOri, type, barf);
				item.pev.noise1 = oldOwner;
				g_item_drops.insertLast(EHandle(item));
				if (debug_mode)
					println("Couldn't hold " + barf + " of that");
				return;
			}
		}
			
		remove_item_from_drops(pCaller);
	}
}

void item_cant_collect(CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue)
{
	if (!pActivator.IsPlayer())
		return;
	g_PlayerFuncs.PrintKeyBindingString(cast<CBasePlayer@>(pActivator), "Tu inventario esta lleno");
}

void delay_remove(EHandle ent)
{
	if (ent)
		g_EntityFuncs.Remove(ent);
}

void undo_drop(EHandle h_item, EHandle h_plr)
{
	if (h_item.IsValid() and h_plr.IsValid())
	{
		CBaseEntity@ item = h_item.GetEntity();
		CBasePlayer@ plr = cast<CBasePlayer@>(h_plr.GetEntity());
		int amt = item.pev.button > 0 ? item.pev.button : 1;
		giveItem(plr, item.pev.colormap-1, amt, false);
		g_EntityFuncs.Remove(item);
	}
}

CBaseEntity@ getLookItem(CBasePlayer@ plr, Vector lookPos)
{
	// highlight items on ground (and see what they are)
	float closestDist = 9e99;
	CBaseEntity@ closestItem = null;
	for (uint i = 0; i < g_item_drops.size(); i++)
	{
		if (!g_item_drops[i].IsValid())
			continue;
	
		CBaseEntity@ item = g_item_drops[i];				
		float dist = (item.pev.origin - lookPos).Length();
		if (dist < 32 and dist < closestDist)
		{
			@closestItem = @item;
			closestDist = dist;
		}
	}
	for (uint i = 0; i < g_corpses.size(); i++)
	{
		if (!g_corpses[i].IsValid())
			continue;
	
		CBaseEntity@ item = g_corpses[i];				
		float dist = (item.pev.origin - lookPos).Length();
		if (item.pev.effects != EF_NODRAW and dist < 32 and dist < closestDist)
		{
			@closestItem = @item;
			closestDist = dist;
		}
	}
	
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityByClassname(ent, "player");
		if (ent !is null and ent.pev.deadflag > 0 and (ent.pev.effects & EF_NODRAW) == 0)
		{
			float dist = (ent.pev.origin - lookPos).Length();
			if (dist < 32 and dist < closestDist)
			{
				@closestItem = @ent;
				closestDist = dist;
			}
		}
	} while (ent !is null);
	
	//println("CLOSE TO  " + g_item_drops.size());
	return closestItem;
}

int combineItemStacks(CBasePlayer@ plr, int addedType)
{
	InventoryList@ inv = plr.get_m_pInventory();
	
	dictionary totals;
	while(inv !is null)
	{
		CItemInventory@ item = cast<CItemInventory@>(inv.hItem.GetEntity());
		@inv = inv.pNext;
		if (item !is null)
		{
			int type = item.pev.colormap-1;
			if (g_items[type].stackSize > 1 and type >= 0 and item.pev.button != g_items[type].stackSize)
			{
				int newTotal = 0;
				if (totals.exists(type))
					totals.get(type, newTotal);
				newTotal += item.pev.button;
				totals[type] = newTotal;
				
				item.pev.renderfx = -9999;
				
				g_EntityFuncs.Remove(item);
			}
		}
	}
	
	int spaceLeft = getInventorySpace(plr);
	array<string>@ totalKeys = totals.getKeys();
	
	for (uint i = 0; i < totalKeys.length(); i++)
	{
		if (atoi(totalKeys[i]) == addedType)
		{
			// newly added item should be stacked last in case there is overflow
			// e.g. if you collect too much wood, you shouldn't drop your stack of stone
			totalKeys.removeAt(i);
			totalKeys.insertLast(addedType);
			break;
		}
	}
	
	for (uint i = 0; i < totalKeys.length(); i++)
	{
		int type = atoi(totalKeys[i]);
		int total = 0;
		totals.get(totalKeys[i], total);
		
		if (total < 0)
		{
			// remove stacks
			@inv = plr.get_m_pInventory();
			while(inv !is null and total < 0)
			{
				CItemInventory@ item = cast<CItemInventory@>(inv.hItem.GetEntity());
				@inv = inv.pNext;
				if (item !is null)
				{
					if (item.pev.colormap-1 == type)
					{
						if (item.pev.button > -total)
						{
							giveItem(plr, type, item.pev.button + total, false, false);
							total = 0;
						}
						else
							total += item.pev.button;
						
						item.pev.renderfx = -9999;
						g_Scheduler.SetTimeout("delay_remove", 0, EHandle(item));
					}
				}
			}
		}
		while (total > 0)
		{
			if (spaceLeft-- > 0)
				giveItem(plr, type, Math.min(total, g_items[type].stackSize), false, false);
			else
			{
				g_PlayerFuncs.PrintKeyBindingString(plr, "Tu inventario esta lleno");
				return total;
			}
			total -= g_items[type].stackSize;
		}
	}
	
	return 0;
}

CBaseEntity@ spawnItem(Vector origin, int type, int amt, bool isDrop=false)
{
	dictionary keys;
	keys["origin"] = origin.ToString();
	keys["model"] = "models/w_weaponbox.mdl";
	keys["weight"] = "0";
	keys["spawnflags"] = "" + (256 + 512 + 128);
	keys["solid"] = "0";
	keys["movetype"] = "5";
	keys["return_timelimit"] = "-1";
	keys["holder_can_drop"] = "1";
	keys["carried_hidden"] = "1";
	keys["target_on_drop"] = "item_dropped";
	keys["target_on_collect"] = "item_collected";
	keys["target_cant_collect"] = "item_cant_collect";
	keys["holder_keep_on_death"] = "1";
	keys["holder_keep_on_respawn"] = "1";
	
	if (type < 0 or type > ITEM_TYPES)
	{
		println("spawnItem: bad type " + type);
		return null;
	}
	Item@ item = g_items[type];
	
	keys["netname"] = item.title; // because m_szItemName doesn't work...
	keys["colormap"] = "" + (type+1); // +1 so that normal items don't appear as my custom ones
	keys["team"] = "0"; // so we ignore this in the item_collected callback
	
	keys["display_name"] = item.title;
	keys["description"] = item.desc;
	
	CBaseEntity@ lastSpawn = null;
	if (item.stackSize == 1)
	{
		if (item.isWeapon)
		{
			if (amt >= 1)
				keys["button"] = "" + amt;
			amt = 1;
			
		}
		for (int i = 0; i < amt; i++)
		{
			@lastSpawn = g_EntityFuncs.CreateEntity("item_inventory", keys, true);
			lastSpawn.pev.origin = origin;
		}
	}
	else
	{
		keys["button"] = "" + amt;
		keys["display_name"] = g_items[type].title + "  (" + prettyNumber(amt) + ")";
		
		@lastSpawn = g_EntityFuncs.CreateEntity("item_inventory", keys, true);
	}
	
	if (isDrop)
	{
		// prevent cleanup on this item (TODO: don't use random player)
		CBasePlayer@ plr = getAnyPlayer();
		@lastSpawn.pev.owner = @plr.edict();
		item_dropped(plr, lastSpawn, USE_TOGGLE, 0);
	}
	return lastSpawn;
}

int getSpawnFlagsForWeapon(string cname)
{
	array<string>@ keys = WeaponCustom::custom_weapons.getKeys();
	for (uint i = 0; i < keys.length(); i++)
	{
		WeaponCustom::weapon_custom@ wep = cast<WeaponCustom::weapon_custom@>( WeaponCustom::custom_weapons[keys[i]] );
		if (wep.weapon_classname == cname) {
			return wep.pev.spawnflags & 31; // flags that are only handled in the engine
		}
	}
	return 0;
}

// try to equip a weapon/item/ammo. Returns amount that couldn't be equipped
int equipItem(CBasePlayer@ plr, int type, int amt)
{
	if (type < 0 or type > ITEM_TYPES)
	{
		println("equipItem: bad type");
		return amt;
	}
	Item@ item = g_items[type];
	
	int barf = amt;
	if (item.isWeapon and item.stackSize > 1)
	{
		if (@plr.HasNamedPlayerItem(item.classname) == null)
		{
			plr.SetItemPickupTimes(0);
			plr.GiveNamedItem(item.classname, getSpawnFlagsForWeapon(item.classname));
		}
	
		int amtGiven = giveAmmo(plr, amt, item.ammoName);
		barf = amt - amtGiven;
		
		if (amtGiven > 0)
			g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1.0f, 1.0f, 0, 100);
	}
	else if (item.isWeapon and @plr.HasNamedPlayerItem(item.classname) == null)
	{
		plr.SetItemPickupTimes(0);
		plr.GiveNamedItem(item.classname, getSpawnFlagsForWeapon(item.classname));
		CBasePlayerWeapon@ wep = cast<CBasePlayerWeapon@>(@plr.HasNamedPlayerItem(item.classname));
		if (amt != -1)
			wep.m_iClip = amt;
		barf = -2;
	}
	else if (item.isAmmo)
	{
		int amtGiven = giveAmmo(plr, amt, item.classname);
		barf = amt - amtGiven;
		
		if (amtGiven > 0)
			g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1.0f, 1.0f, 0, 100);
	}
	else if (item.type == I_ARMOR)
	{
		bool equippedAny = false;
		while (plr.pev.armorvalue <= (100-ARMOR_VALUE) and amt > 0)
		{
			equippedAny = true;
			plr.pev.armorvalue += ARMOR_VALUE;
			amt -= 1;
		}
		if (equippedAny)
			g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/ammopickup2.wav", 1.0f, 1.0f, 0, 100);
		barf = amt;
		//else
		//	g_PlayerFuncs.PrintKeyBindingString(plr, "Maximum armor equipped");
	}
	
	getPlayerState(plr).updateItemList();
	return barf;
}

int pickupItem(CBasePlayer@ plr, CBaseEntity@ item)
{
	int type = item.pev.colormap-1;
	if (type < 0 or type > ITEM_TYPES)
	{
		println("pickupItem: bad type");
		return item.pev.button > 0 ? item.pev.button : 1;
	}
	Item@ itemDef = g_items[type];
	
	return giveItem(plr, type, item.pev.button, false, true, true);
}

// returns # of items that couldn't be stored (e.g. could stack 100 more but was given 300: return 200)
int giveItem(CBasePlayer@ plr, int type, int amt, bool drop=false, bool combineStacks=true, bool tryToEquip=false)
{
	dictionary keys;
	keys["origin"] = plr.pev.origin.ToString();
	keys["model"] = "models/w_weaponbox.mdl";
	keys["weight"] = "0";
	keys["spawnflags"] = "" + (256 + 512 + 128);
	keys["solid"] = "0";
	keys["movetype"] = "5";
	keys["return_timelimit"] = "-1";
	keys["holder_can_drop"] = "1";
	keys["carried_hidden"] = "1";
	keys["target_on_drop"] = "item_dropped";
	keys["target_on_collect"] = "item_collected";
	keys["target_cant_collect"] = "item_cant_collect";
	keys["holder_keep_on_death"] = "1";
	keys["holder_keep_on_respawn"] = "1";
	
	if (plr is null or !plr.IsAlive() or plr.pev.flags & FL_NOTARGET != 0)
		return amt;
	
	plr.SetItemPickupTimes(0);
	
	if (type < 0 or type > ITEM_TYPES)
	{
		println("giveItem: bad type");
		return amt;
	}
	Item@ item = g_items[type];
	
	if (tryToEquip)
	{
		int barf = equipItem(plr, type, amt);
		if ((item.isWeapon and item.stackSize == 1 and barf == -2) or (item.stackSize > 1 and barf == 0))
			return 0;
		amt = barf;
	}
	
	keys["button"] = "1"; // will be giving at least 1x of something
	keys["netname"] = g_items[type].title; // because m_szItemName doesn't work...
	keys["colormap"] = "" + (type+1); // +1 so that normal items don't appear as my custom ones
	keys["team"] = drop ? "0" : "1"; // so we ignore this in the item_collected callback
	
	keys["display_name"] = g_items[type].title;
	keys["description"] =  g_items[type].desc;
	
	//if (showText)
	//	g_PlayerFuncs.PrintKeyBindingString(plr, "" + amt + "x " + g_items[type].title);
	
	int dropSpeed = Math.RandomLong(250, 400);
	int spaceLeft = getInventorySpace(plr);
	
	if (item.stackSize == 1)
	{
		if (!item.isWeapon)
		{
			for (int i = 0; i < amt; i++)
			{
				if (spaceLeft-- <= 0 and !drop)
				{
					g_PlayerFuncs.PrintKeyBindingString(plr, "Tu inventario esta lleno");
					getPlayerState(plr).updateItemList();
					return amt - i;
				}
				CBaseEntity@ ent = g_EntityFuncs.CreateEntity("item_inventory", keys, true);
				if (drop)
				{
					g_EngineFuncs.MakeVectors(plr.pev.angles);
					ent.pev.velocity = g_Engine.v_forward*dropSpeed;
					ent.pev.origin = plr.pev.origin;
				}
				else
					ent.Use(@plr, @plr, USE_ON, 0.0F);
			}
			if (amt < 0)
			{
				// inventory items
				InventoryList@ inv = plr.get_m_pInventory();
				while(inv !is null and amt < 0)
				{
					CItemInventory@ citem = cast<CItemInventory@>(inv.hItem.GetEntity());
					if (citem !is null and citem.pev.colormap-1 == type)
					{
						citem.pev.renderfx = -9999;
						g_Scheduler.SetTimeout("delay_remove", 0, EHandle(citem));
						amt++;
					}
					@inv = inv.pNext;
				}
			}
		}
		else
		{
			keys["button"] = "" + amt; // now button = ammo in clip
			if (spaceLeft <= 0 and !drop)
			{
				g_PlayerFuncs.PrintKeyBindingString(plr, "Tu inventario esta lleno");
				getPlayerState(plr).updateItemList();
				return 1;
			}
			CBaseEntity@ ent = g_EntityFuncs.CreateEntity("item_inventory", keys, true);
			if (drop)
			{
				g_EngineFuncs.MakeVectors(plr.pev.angles);
				ent.pev.origin = plr.pev.origin;
				ent.pev.velocity = g_Engine.v_forward*dropSpeed;
			}
			else
				ent.Use(@plr, @plr, USE_ON, 0.0F);
		}
	}
	else
	{
		keys["button"] = "" + amt;
		keys["display_name"] = item.title + "  (" + prettyNumber(amt) + ")";
		
		CBaseEntity@ ent = g_EntityFuncs.CreateEntity("item_inventory", keys, true);
		if (drop)
		{
			g_EngineFuncs.MakeVectors(Vector(0, plr.pev.angles.y, 0));
			ent.pev.velocity = g_Engine.v_forward*dropSpeed;
			ent.pev.movetype = MOVETYPE_TOSS;
			item_dropped(plr, ent, USE_TOGGLE, 0);
		}
		else
			ent.Use(@plr, @plr, USE_ON, 0.0F);
		
		if (combineStacks)
		{
			int ret = combineItemStacks(plr, type);
			getPlayerState(plr).updateItemList();
			return ret;
		}
	}
	
	getPlayerState(plr).updateItemList();
	return 0;
}

array<string> getStackOptions(CBasePlayer@ plr, int itemId)
{
	array<string> options;
	Item@ invItem = g_items[itemId];
	
	string displayName = invItem.title;
	int amount = getItemCount(plr, itemId);
	int stackSize = Math.min(invItem.stackSize, amount);
	
	if (amount > 0)
		displayName += " (" + amount + ")";
	else
		return options;
	
	options.insertLast(displayName); // not an option but yolo
	
	for (int i = stackSize, k = 0; i >= Math.min(stackSize, 5) and k < 8; i /= 2, k++)
	{
		if (i != stackSize)
		{
			if (i > 10)
				i = (i / 10) * 10;
			else if (i < 10)
				i = 5;
		}
			
		string stackString = i;
		if (i < 10) stackString = "0" + stackString;
		if (i < 100) stackString = "0" + stackString;
		if (i < 1000) stackString = "0" + stackString;
		if (i < 10000) stackString = "0" + stackString;
		if (i < 100000) stackString = "0" + stackString;
		if (amount >= i and stackSize >= i) 
			options.insertLast(stackString);
	}
	if (stackSize != 1)
		options.insertLast("000001");
		
	return options;
}

// returns amount of the item given
int craftItem(CBasePlayer@ plr, int itemType)
{
	PlayerState@ state = getPlayerState(plr);
	int actuallyGiven = 0;
	if (itemType == I_LADDER or itemType == I_LADDER_HATCH)
	{
		g_PlayerFuncs.PrintKeyBindingString(plr, "Las escaleras estan deshabilitadas hasta\nque el crash bug en Sven sea arreglado.");
	}
	else if (itemType >= 0 and itemType < int(g_items.size()))
	{
		Item@ craftItem = g_items[itemType];
		
		bool canCraft = true;
		bool tipShown = false;
		string needMore = "";
		if (!g_free_build)
		{
			for (uint i = 0; i < craftItem.costs.size(); i++)
			{
				int costType = craftItem.costs[i].type;
				if (getItemCount(plr, costType, true, true) < craftItem.costs[i].amt)
				{
					if (!tipShown and (state.tips & TIP_METAL == 0) and (g_items[costType].type == I_METAL or g_items[costType].type == I_HQMETAL))
					{
						g_Scheduler.SetTimeout("showTip", 3.0f, EHandle(plr), int(TIP_METAL));
						tipShown = true;
					}
					else if (!tipShown and (state.tips & TIP_FUEL == 0) and g_items[costType].type == I_FUEL)
					{
						g_Scheduler.SetTimeout("showTip", 3.0f, EHandle(plr), int(TIP_FUEL));
						tipShown = true;
					}
					else if (!tipShown and (state.tips & TIP_SCRAP == 0) and g_items[costType].type == I_SCRAP)
					{
						g_Scheduler.SetTimeout("showTip", 3.0f, EHandle(plr), int(TIP_SCRAP));
						tipShown = true;
					}
						
					needMore = needMore.Length() > 0 ? needMore + " y " + g_items[costType].title : g_items[costType].title;
					canCraft = false;
				}
			}
		}
		if (canCraft)
		{
			if (craftItem.type <= I_BED)
				showTip(EHandle(plr), TIP_PLACE_ITEMS);
			if (craftItem.type == I_FLAMETHROWER)
				showTip(EHandle(plr), TIP_FLAMETHROWER);
				
			int amt = craftItem.isWeapon and craftItem.stackSize == 1 ? 0 : 1;
			if (craftItem.type == I_9MM) amt = 5;
			if (craftItem.type == I_556) amt = 5;
			if (craftItem.type == I_ARROW) amt = 5;
			if (!g_free_build)
			{
				for (uint i = 0; i < craftItem.costs.size(); i++)
				{
					if (debug_mode)
						println("Subtract cost: " + g_items[craftItem.costs[i].type].title + " " + (-craftItem.costs[i].amt));
					giveItem(plr, craftItem.costs[i].type, -craftItem.costs[i].amt);
				}
			}
			int barf = giveItem(plr, itemType, amt, false, true, true);
			actuallyGiven = amt - barf;
			if (barf == 0)
			{				
				if (craftItem.isWeapon)
					actuallyGiven = 1;
				g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "rust/build1.ogg", 1.0f, 1.0f, 0, Math.RandomLong(140, 160));
			}
			else
			{
				//println("Barfed " + barf + " of " + amt);
				g_PlayerFuncs.PrintKeyBindingString(plr, "Tu inventario esta lleno");
				g_Scheduler.SetTimeout("showTip", 3.0f, EHandle(plr), int(TIP_CHEST));
				// undo cost
				if (!g_free_build)
				{
					for (uint i = 0; i < craftItem.costs.size(); i++)
						giveItem(plr, craftItem.costs[i].type, craftItem.costs[i].amt);
				}
			}
		}
		else
			g_PlayerFuncs.PrintKeyBindingString(plr, "Necesitas mas " + needMore);			
	}
	return actuallyGiven;
}

// Player Menus
void playerMenuCallback(CTextMenu@ menu, CBasePlayer@ plr, int page, const CTextMenuItem@ item)
{
	if (item is null or plr is null or !plr.IsAlive())
		return;
	string action;
	item.m_pUserData.retrieve(action);
	PlayerState@ state = getPlayerState(plr);
	
	if (int(action.Find("-menu")) != -1)
	{
		g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr, action);
	}
	else if (action.Find("unequip-") == 0)
	{
		string name = action.SubString(8);
		if (name == "health")
			name = "weapon_syringe";
		if (name == "item_battery")
			name = "armor";
		
		CBasePlayerItem@ wep = plr.HasNamedPlayerItem(name);
		if (wep !is null)
		{
			CBasePlayerWeapon@ cwep = cast<CBasePlayerWeapon@>(wep);
			
			Item@ invItem = getItemByClassname(name);
			if (invItem !is null)
			{
				int clip = cwep.m_iClip;
				
				if (invItem.stackSize > 1)
					clip = plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex(invItem.ammoName));
				
				if (giveItem(plr, invItem.type, clip) == 0)
				{					
					plr.RemovePlayerItem(wep);
					if (!invItem.isAmmo and invItem.stackSize > 1)
						plr.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex(invItem.ammoName), 0);
					g_PlayerFuncs.PrintKeyBindingString(plr, invItem.title + " fue movido a tu inventario");
				}
			}
			else
				println("Unknown weapon: " + name);		
		}
		else if (name == "armor")
		{
			if (plr.pev.armorvalue >= ARMOR_VALUE and giveItem(plr, I_ARMOR, 1) == 0)
			{
				plr.pev.armorvalue -= ARMOR_VALUE;
				g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/ammopickup1.wav", 1.0f, 1.0f, 0, 100);
			}
		}
		else
		{
			int ammoIdx = g_PlayerFuncs.GetAmmoIndex(name);
			int ammo = plr.m_rgAmmo(ammoIdx);
			if (ammo > 0)
			{
				Item@ ammoItem = getItemByClassname(name);
				
				if (ammoItem !is null)
				{
					int ammoLeft = giveItem(plr, ammoItem.type, ammo);
					plr.m_rgAmmo(ammoIdx, ammoLeft);
				}
				else
					println("Unknown ammo: " + name);
			}
		}

		g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr, "unequip-menu");
	}
	else if (action.Find("equip-") == 0)
	{
		int itemId = atoi(action.SubString(6));
		Item@ invItem = g_items[itemId];
		
		if (invItem.stackSize > 1)
		{
			int amt = getItemCount(plr, invItem.type, false, true);
			int barf = equipItem(plr, invItem.type, amt);
			int given = amt-barf;
			if (given > 0)
				giveItem(plr, invItem.type, -given);
		}
		else if (invItem.isWeapon)
		{
			if (@plr.HasNamedPlayerItem(invItem.classname) is null)
			{
				CItemInventory@ wep = getInventoryItem(plr, invItem.type);
				if (equipItem(plr, invItem.type, wep.pev.button) == -2)
					g_Scheduler.SetTimeout("delay_remove", 0, EHandle(wep));
			}
			else
				g_PlayerFuncs.PrintKeyBindingString(plr, "Ya tienes uno equipado");
		}
		
		g_Scheduler.SetTimeout("openPlayerMenu", 0.05, @plr, "equip-menu");
	}
	else if (action.Find("unstack-") == 0)
	{
		g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr, action);
	}
	else if (action.Find("drop-") == 0)
	{
		int dropAmt = atoi(action.SubString(5,6));
		int dropType = atoi(action.SubString(12));
		
		if (dropType >= 0 and dropType < int(g_items.size()))
		{
			Item@ dropItem = g_items[dropType];
			
			int hasAmt = getItemCount(plr, dropItem.type, false);
			int giveInvAmt = Math.min(dropAmt, hasAmt);
			int dropLeft = dropAmt;
			
			int overflow = 0;
			if (giveInvAmt > 0)
			{
				giveItem(plr, dropType, -dropAmt); // decrease stack size
				dropLeft -= giveInvAmt;
			}
			
			bool noMoreAmmo = false;
			if (dropLeft > 0 and (dropItem.isAmmo or dropItem.stackSize > 1))
			{
				string cname = dropItem.isAmmo ? dropItem.classname : dropItem.ammoName;
				int ammoIdx = g_PlayerFuncs.GetAmmoIndex(cname);
				int ammo = plr.m_rgAmmo(ammoIdx);
				int giveAmmo = Math.min(ammo, dropLeft);
				
				noMoreAmmo = ammo <= giveAmmo;
				
				if (giveAmmo > 0)
				{
					plr.m_rgAmmo(ammoIdx, ammo - giveAmmo);
					dropLeft -= giveAmmo;
				}
			}
			
			giveItem(plr, dropType, dropAmt - dropLeft, true); // drop selected/max amount
			if (!dropItem.isAmmo and dropItem.stackSize > 1 and noMoreAmmo)
			{
				g_EntityFuncs.Remove(@plr.HasNamedPlayerItem(dropItem.classname));
			}
			
			g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr, "unstack-" + dropType);
		}
	}
	else if (action.Find("map-toggle") == 0)
	{
		state.map_enabled = !state.map_enabled;
		state.map_update = true;
		g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr, "");
	}
	else if (action.Find("map-mode") == 0)
	{
		state.map_enabled = true;
		state.map_size += 1;
		if (state.map_size > 1 and state.map_mode == 1)
		{
			state.map_size = 0;
			state.map_mode += 1;
		}
		if (state.map_size > 2)
		{
			state.map_mode += 1;
			if (state.map_mode > 2)
				state.map_mode = 1;
			state.map_size = 0;
		}
		state.map_update = true;
		g_Scheduler.SetTimeout("openPlayerMenu", 0, @plr, "");
	}
	
	menu.Unregister();
	@menu = null;
}

void openPlayerMenu(CBasePlayer@ plr, string subMenu)
{
	PlayerState@ state = getPlayerState(plr);
	state.initMenu(plr, playerMenuCallback);
	int menuTime = 60;
	
	if (subMenu == "craft-menu" or subMenu == "item-menu" or subMenu == "tool-menu" or 
		subMenu == "weapon-menu" or subMenu == "ammo-menu" or subMenu == "util-menu" or 
		subMenu == "resize-icons-menu" or subMenu == "resize-layout-menu")
	{
		int subIdx = state.lastCraftSubmenu;
		if (subMenu == "item-menu")
			subIdx = 0;
		if (subMenu == "tool-menu")
			subIdx = 1;
		if (subMenu == "util-menu")
			subIdx = 2;
		if (subMenu == "weapon-menu")
			subIdx = 3;
		if (subMenu == "ammo-menu")
			subIdx = 4;
			
		if (subMenu == "resize-icons-menu")
		{
			state.menuScale = (state.menuScale + 1) % 3;
		}
		if (subMenu == "resize-layout-menu")
		{
			state.gapScale = (state.gapScale + 1) % 3;
		}
		
		openCraftMenu(state, subIdx);
		menuTime = 255;
		state.menu.SetTitle("Acciones -> Craftear:\n");
		state.menu.AddItem("Items" + (subIdx == 0 ? " <--" : ""), any("item-menu"));
		state.menu.AddItem("Herramientas" + (subIdx == 1 ? " <--" : ""), any("tool-menu"));
		state.menu.AddItem("Utilidades" + (subIdx == 2 ? " <--" : ""), any("util-menu"));
		state.menu.AddItem("Armas" + (subIdx == 3 ? " <--" : ""), any("weapon-menu"));
		state.menu.AddItem("Municion" + (subIdx == 4 ? " <--" : ""), any("ammo-menu"));
		state.menu.AddItem("\n\n", any("craft-menu"));
		state.menu.AddItem("Tamano iconos", any("resize-icons-menu"));
		state.menu.AddItem("Tamano de cuadricula", any("resize-layout-menu"));
	}
	else if (subMenu == "equip-menu")
	{
		state.menu.SetTitle("Acciones -> Equipar:\n");
		
		array<Item@> all_items = getAllItems(plr);
		int options = 0;
		
		for (uint i = 0; i < all_items.size(); i++)
		{
			Item@ item = all_items[i];
			if (!item.isWeapon and !item.isAmmo and item.type != I_ARMOR)
				continue;
			int count = getItemCount(plr, item.type, false, true);
			if (count <= 0)
				continue;
				
			options++;
			string displayName = item.title;
			if (item.stackSize > 1)
				displayName += " (" + count + ")";
			state.menu.AddItem(displayName, any("equip-" + item.type));
		}
		
		if (options == 0)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "No tienes ningun item equipable");
			openPlayerMenu(plr, "");
			return;
		}
	}
	else if (subMenu == "unequip-menu")
	{
		state.menu.SetTitle("Acciones -> Desequipar:\n");
		
		array<Item@> all_items = getAllItems(plr);
		int options = 0;
		
		for (uint i = 0; i < all_items.size(); i++)
		{
			Item@ item = all_items[i];
			int count = getItemCount(plr, item.type, true, false);
			if (count <= 0)
				continue;
				
			options++;
			string displayName = item.title;
			if (item.stackSize > 1)
				displayName += " (" + count + ")";
			state.menu.AddItem(displayName, any("unequip-" + item.classname));
		}
		
		if (options == 0)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "No tienes ningun item equipado");
			openPlayerMenu(plr, "");
			return;
		}
	}
	else if (subMenu == "drop-stack-menu")
	{
		state.menu.SetTitle("Acciones -> Tirar items\n");
		
		array<Item@> all_items = getAllItems(plr);
		int options = 0;
		
		for (uint i = 0; i < all_items.size(); i++)
		{
			Item@ item = all_items[i];
			if (item.stackSize <= 1)
				continue;
			int count = getItemCount(plr, item.type, true, true);
			if (count <= 0)
				continue;
				
			options++;
			string displayName = item.title;
			if (item.stackSize > 1)
				displayName += " (" + count + ")";
			state.menu.AddItem(displayName, any("unstack-" + item.type));
		}
		
		if (options == 0)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "No tienes nada para tirar");
			openPlayerMenu(plr, "");
			return;
		}
	}
	else if (subMenu.Find("unstack-") == 0)
	{
		int itemId = atoi(subMenu.SubString(8));
		array<string> stackOptions = getStackOptions(plr, itemId);
		if (stackOptions.size() == 0)
		{
			openPlayerMenu(plr, "drop-stack-menu");
			return;
		}
		
		state.menu.SetTitle("Acciones -> Tirar " + stackOptions[0] + ":\n");
		for (uint i = 1; i < stackOptions.size(); i++)
		{
			int count = atoi(stackOptions[i]);
			state.menu.AddItem("Tirar " + prettyNumber(count), any("drop-" + stackOptions[i] + "-" + itemId));
		}
	}
	else
	{
		state.menu.SetTitle("Acciones:\n");
		state.menu.AddItem("Craftear", any("craft-menu"));
		state.menu.AddItem("Equipar", any("equip-menu"));
		state.menu.AddItem("Desequipar", any("unequip-menu"));
		state.menu.AddItem("Tirar items", any("drop-stack-menu"));
		state.menu.AddItem("Activar/desactivar mapa", any("map-toggle"));
		state.menu.AddItem("Escalar mapa", any("map-mode"));
	}
	
	state.openMenu(plr, menuTime);
}

void lootMenuCallback(CTextMenu@ menu, CBasePlayer@ plr, int page, const CTextMenuItem@ mitem)
{
	if (mitem is null or plr is null or !plr.IsAlive())
		return;
	string action;
	mitem.m_pUserData.retrieve(action);
	PlayerState@ state = getPlayerState(plr);
	CBaseEntity@ chest = state.currentChest;
	if (chest is null)
		return;
	func_breakable_custom@ c_chest = cast<func_breakable_custom@>(CastToScriptClass(chest));
	string chestName = chest.pev.colormap == B_FURNACE ? "Horno" : "Baul";
	
	string submenu = "";
	
	if (action == "do-give")
	{
		submenu = "give";
	}
	else if (action == "do-take")
	{
		submenu = "take";
	}
	else if (action.Find("givestack-") == 0)
	{
		int amt = atoi(action.SubString(10,6));
		int giveType = atoi(action.SubString(17));
		
		submenu = "givestack-" + giveType;
		
		if (giveType >= 0 and giveType < int(g_items.size()))
		{
			Item@ depositItem = g_items[giveType];
			
			int hasAmt = getItemCount(plr, depositItem.type, false);
			int giveInvAmt = Math.min(amt, hasAmt);
			
			int overflow = 0;
			if (giveInvAmt > 0)
			{			
				CBaseEntity@ newItem = spawnItem(chest.pev.origin, depositItem.type, giveInvAmt);
				newItem.pev.effects = EF_NODRAW;
				overflow = c_chest.depositItem(EHandle(newItem));
				giveInvAmt -= overflow;
				
				giveItem(plr, depositItem.type, -giveInvAmt);
			}
			
			if (overflow == 0 and depositItem.isAmmo or (depositItem.isWeapon and depositItem.stackSize > 1))
			{
				amt -= giveInvAmt; // now give from equipped ammo if not enough was in inventory
				
				string ammoName = depositItem.classname;
				if (!depositItem.isAmmo and depositItem.stackSize > 1)
					ammoName = depositItem.ammoName;
				int ammoIdx = g_PlayerFuncs.GetAmmoIndex(ammoName);
				int ammo = plr.m_rgAmmo(ammoIdx);
				int giveAmmo = Math.min(ammo, amt);
				
				if (giveAmmo > 0)
				{			
					CBaseEntity@ newItem = spawnItem(chest.pev.origin, depositItem.type, giveAmmo);
					newItem.pev.effects = EF_NODRAW;
					newItem.pev.renderfx = -9999;
					overflow = c_chest.depositItem(EHandle(newItem));
					giveAmmo -= overflow;
					
					giveItem(plr, depositItem.type, -giveAmmo);
					plr.m_rgAmmo(ammoIdx, ammo - giveAmmo);
				}
				
				if (giveAmmo >= ammo and depositItem.type == I_SYRINGE)
					g_EntityFuncs.Remove(plr.HasNamedPlayerItem("weapon_syringe"));
			}
			
			if (overflow == 0 and depositItem.type == I_ARMOR)
			{
				amt -= giveInvAmt;
				int givenArmor = Math.min(amt, int(plr.pev.armorvalue / ARMOR_VALUE));
				CBaseEntity@ newItem = spawnItem(chest.pev.origin, depositItem.type, givenArmor);
				newItem.pev.effects = EF_NODRAW;
				newItem.pev.renderfx = -9999;
				overflow = c_chest.depositItem(EHandle(newItem));
				givenArmor -= overflow;
				plr.pev.armorvalue -= givenArmor*ARMOR_VALUE;
				g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/ammopickup1.wav", 1.0f, 1.0f, 0, 100);
			}
			
			if (overflow > 0)
				g_PlayerFuncs.PrintKeyBindingString(plr, chestName + " esta lleno");
			
			if (overflow < amt)
			{
				g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "player/pl_jump2.wav", 1.0f, 1.0f, 0, Math.RandomLong(80,100));
				g_PlayerFuncs.PrintKeyBindingString(plr, depositItem.title + " (" + (amt - overflow) + ") fue depositado dentro del " 
																+ chestName + "\n\n" + chestName + " capacidad: " + 
																c_chest.items.size() + " / " + c_chest.capacity());
			}
		}
	}
	else if (action.Find("give-") == 0)
	{
		string itemName = action.SubString(5);
		int giveType = atoi(itemName);
		
		submenu = "give";
		
		if (giveType >= 0 and giveType < int(g_items.size()))
		{
			Item@ depositItem = g_items[giveType];
			
			if (depositItem.stackSize > 1)
				submenu = "givestack-" + depositItem.type;
			else if (c_chest.spaceLeft() > 0)
			{
				// currently held item/weapon/ammo
				CBasePlayerItem@ wep = plr.HasNamedPlayerItem(depositItem.classname);
				if (wep !is null)
				{
					int amt = depositItem.stackSize > 1 ? wep.pev.button : 1;
					CBaseEntity@ newItem = spawnItem(chest.pev.origin, depositItem.type, amt);
					newItem.pev.button = cast<CBasePlayerWeapon@>(wep).m_iClip;
					newItem.pev.effects = EF_NODRAW;
					c_chest.depositItem(EHandle(newItem));
					
					plr.RemovePlayerItem(wep);
					g_PlayerFuncs.PrintKeyBindingString(plr, depositItem.title + " fue depositado dentro del " + chestName + "\n\n" + 
															chestName + " capacidad: " + 
															c_chest.items.size() + " / " + c_chest.capacity());
				}
				else
				{
					InventoryList@ inv = plr.get_m_pInventory();
					while(inv !is null)
					{
						CItemInventory@ item = cast<CItemInventory@>(inv.hItem.GetEntity());
						if (item !is null and item.pev.colormap == giveType+1)
						{
							CBaseEntity@ newItem = spawnItem(chest.pev.origin, depositItem.type, 1);
							newItem.pev.effects = EF_NODRAW;
							newItem.pev.renderfx = -9999;
							c_chest.depositItem(EHandle(newItem));
							
							g_Scheduler.SetTimeout("delay_remove", 0, EHandle(item));
							break;
						}
						@inv = inv.pNext;
					}
				}
				g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "player/pl_jump2.wav", 1.0f, 1.0f, 0, Math.RandomLong(80,100));
			}
			else
				g_PlayerFuncs.PrintKeyBindingString(plr, chestName + " esta lleno");
		}			
	}
	else if (action.Find("loot-") == 0)
	{
		string itemDesc = action.SubString(5);
		
		int sep = int(itemDesc.Find(","));
		int type = atoi( itemDesc.SubString(0, sep) );
		int amt = atoi( itemDesc.SubString(sep+1) );
		
		bool found = false;
		if (chest.IsPlayer() and chest.pev.deadflag > 0)
		{
			Item@ gItem = getItemByClassname(itemDesc);
			if (gItem is null)
				println("No existe ningun elemento para el nombre de: " + itemDesc);
			CBasePlayer@ corpse = cast<CBasePlayer@>(chest);
			
			InventoryList@ inv = corpse.get_m_pInventory();
			while (inv !is null and gItem !is null and inv.hItem.IsValid())
			{
				CItemInventory@ item = cast<CItemInventory@>(inv.hItem.GetEntity());
				@inv = inv.pNext;
				if (item !is null and item.pev.colormap == gItem.type)
				{
					if (giveItem(plr, gItem.type, gItem.stackSize > 1 ? item.pev.button : 1) == 0)
					{
						item.pev.renderfx = -9999;
						g_Scheduler.SetTimeout("delay_remove", 0, EHandle(item));
					}
					
					found = true;
					break;
				}
			}
			
			if (!found)
			{
				CBasePlayerItem@ hasItem = corpse.HasNamedPlayerItem(itemDesc);
				if (hasItem !is null and gItem !is null)
				{
					if (plr.HasNamedPlayerItem(itemDesc) is null)
					{
						plr.SetItemPickupTimes(0);
						plr.GiveNamedItem(itemDesc);
						corpse.RemovePlayerItem(hasItem);
					}
					else if (giveItem(plr, gItem.type, 1) == 0)
						corpse.RemovePlayerItem(hasItem);
						
					found = true;
				}
			}
			
			if (!found)
			{
				int ammoIdx = g_PlayerFuncs.GetAmmoIndex(itemDesc);
				int ammo = corpse.m_rgAmmo(ammoIdx);
				if (ammo > 0)
				{
					int amtGiven = giveAmmo(plr, ammo, itemDesc);
					
					int ammoLeft = ammo - amtGiven;
					Item@ ammoItem = getItemByClassname(itemDesc);
					
					if (ammoItem !is null)
					{
						ammoLeft = giveItem(plr, ammoItem.type, ammoLeft);
						
						if (ammoLeft < ammo)
							g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/9mmclip1.wav", 1.0f, 1.0f, 0, 100);
						
						corpse.m_rgAmmo(ammoIdx, ammoLeft);
					}
					else
						println("Unknown ammo: " + itemDesc);
						
					found = true;
				}
			}
			
			if (found)
			{
				// update items in corpse
				for (uint i = 0; i < g_corpses.size(); i++)
				{
					if (!g_corpses[i])
						continue;
						
					player_corpse@ skeleton = cast<player_corpse@>(CastToScriptClass(g_corpses[i]));
					if (skeleton.owner.IsValid() and skeleton.owner.GetEntity().entindex() == corpse.entindex())
						skeleton.Update();
				}
			}
		}
		else if (chest.pev.classname == "player_corpse" or chest.pev.classname == "func_breakable_custom")
		{
			bool is_corpse = chest.pev.classname == "player_corpse";
			array<EHandle>@ items = is_corpse ? @cast<player_corpse@>(CastToScriptClass(chest)).items :
												@cast<func_breakable_custom@>(CastToScriptClass(chest)).items;
		
			for (uint i = 0; i < items.size(); i++)
			{
				if (!items[i])
					continue;
				CBaseEntity@ item = items[i];
				int takeType = item.pev.colormap-1;
				if (takeType < 0 or takeType >= int(g_items.size()))
					continue;
				int oldAmt = getItemCount(plr, type);
				Item@ takeItem = g_items[takeType];

				if (item.pev.colormap == type and item.pev.button == amt)
				{
					// try equipping immediately
					int amtLeft = pickupItem(plr, item);
						
					if (amtLeft > 0)
						item.pev.button = amtLeft;
					else
					{
						g_EntityFuncs.Remove(item);
						items.removeAt(i);
						i--;
						if (items.size() == 0 and chest.pev.colormap == E_SUPPLY_CRATE)
						{
							func_breakable_custom@ crate = cast<func_breakable_custom@>(CastToScriptClass(chest));
							crate.Destroy();
						}
					}
					
					found = true;
					break;
				}
			}
			
			submenu = "take";
		}
		if (!found)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "El item ya no existe");
		}
		else
		{
			g_SoundSystem.PlaySound(plr.edict(), CHAN_BODY, "player/pl_jump2.wav", 1.0f, 1.0f, 0, Math.RandomLong(120,140));
		}
	}
	
	g_Scheduler.SetTimeout("openLootMenu", 0.05, EHandle(plr), EHandle(chest), submenu);
}

void openLootMenu(EHandle h_plr, EHandle h_corpse, string submenu="")
{
	if (!h_corpse.IsValid() or !h_plr.IsValid())
	{
		println("Null player/corpse!");
		return;
	}
	
	CBasePlayer@ plr = cast<CBasePlayer@>(h_plr.GetEntity());
	CBaseEntity@ corpse = h_corpse;
	
	PlayerState@ state = getPlayerState(plr);
	state.initMenu(plr, lootMenuCallback);
	state.currentChest = corpse;
	
	string title = "Saquear el cuerpo de " + corpse.pev.netname + ":\n";
	
	int numItems = 0;
	if (corpse.IsPlayer())
	{
		CBasePlayer@ pcorpse = cast<CBasePlayer@>(corpse);
		
		array<Item@> all_items = getAllItems(pcorpse);
		
		for (uint i = 0; i < all_items.size(); i++)
		{
			Item@ item = all_items[i];
			int count = getItemCount(pcorpse, item.type, true, true);
			if (count <= 0)
				continue;
				
			numItems++;
			string displayName = item.title;
			if (item.stackSize > 1)
				displayName += " (" + count + ")";
			state.menu.AddItem(displayName, any("loot-" + item.classname));
		}
	}
	else if (corpse.pev.classname == "player_corpse")
	{
		player_corpse@ pcorpse = cast<player_corpse@>(CastToScriptClass(corpse));
		for (uint i = 0; i < pcorpse.items.size(); i++)
		{
			if (!pcorpse.items[i])
				continue;
				
			CBaseEntity@ item = pcorpse.items[i];
			state.menu.AddItem(getItemDisplayName(item), any("loot-" + item.pev.colormap + "," + item.pev.button));
		}
		numItems = pcorpse.items.size();
	}
	else if (corpse.IsBSPModel()) // chest
	{
		numItems++;
		
		switch(corpse.pev.colormap)
		{
			case B_SMALL_CHEST:
				title = "Baul chico:";
				break;
			case B_LARGE_CHEST:
				title = "Baul grande:";
				break;
			case B_FURNACE:
				title = "Horno:";
				break;
			case E_SUPPLY_CRATE:
				title = "Airdrop";
				break;
		}
		
		bool isAirdrop = corpse.pev.colormap == E_SUPPLY_CRATE;
		
		if (submenu == "give")
		{			
			title += " -> Depositar";
			bool isFurnace = corpse.pev.colormap == B_FURNACE;
		
			array<Item@> all_items = getAllItems(plr);
			int options = 0;
			
			for (uint i = 0; i < all_items.size(); i++)
			{
				Item@ item = all_items[i];
				if (isFurnace)
				{
					if (item.type != I_WOOD and item.type != I_METAL_ORE and item.type != I_HQMETAL_ORE)
						continue;
				}
				int count = getItemCount(plr, item.type, true, true);
				if (count <= 0)
					continue;
					
				options++;
				string displayName = item.title;
				if (item.stackSize > 1)
					displayName += " (" + count + ")";
				state.menu.AddItem(displayName, any("give-" + item.type));
			}
			
			if (options == 0)
				state.menu.AddItem("(No tienes ningun item para depositar)", any(""));
		}
		else if (submenu.Find("givestack-") == 0)
		{
			int itemId = atoi(submenu.SubString(10));
			array<string> stackOptions = getStackOptions(plr, itemId);
			if (stackOptions.size() == 0)
			{
				openLootMenu(EHandle(plr), EHandle(corpse), "give");
				return;
			}
			
			title += " -> Depositar " + stackOptions[0];
			for (uint i = 1; i < stackOptions.size(); i++)
			{
				int count = atoi(stackOptions[i]);
				state.menu.AddItem("Depositar " + prettyNumber(count), any("givestack-" + stackOptions[i] + "-" + itemId));
			}
		}
		else if (submenu == "take" or isAirdrop)
		{
			if (!isAirdrop)
				title += " -> Sacar";
			
			func_breakable_custom@ c_chest = cast<func_breakable_custom@>(CastToScriptClass(corpse));
			
			for (uint i = 0; i < c_chest.items.size(); i++)
			{
				CBaseEntity@ item = c_chest.items[i];
				state.menu.AddItem(getItemDisplayName(item), any("loot-" + item.pev.colormap + "," + item.pev.button));
			}
			
			if (c_chest.items.size() == 0)
				state.menu.AddItem("(vacio)", any(""));
		}
		else
		{
			state.menu.AddItem("Depositar", any("do-give"));
			state.menu.AddItem("Sacar", any("do-take"));
		}
		
	}
	
	state.menu.SetTitle(title + "\n");
	
	if (numItems == 0)
	{
		g_PlayerFuncs.PrintKeyBindingString(plr, "Nada mas para lotear");
		state.currentChest = null;
		return;
	}
	
	
	state.openMenu(plr);
}

// Usable items

void rotate_door(CBaseEntity@ door, bool playSound)
{	
	if (door.pev.iuser1 == 1) // currently moving?
		return;
		
	bool opening = door.pev.groupinfo == 0;
	Vector dest = opening ? door.pev.vuser2 : door.pev.vuser1;
	
	float speed = 280;
	
	string soundFile = "";
	if (door.pev.colormap == B_WOOD_DOOR) {
		soundFile = opening ? "rust/door_wood_open.ogg" : "rust/door_wood_close.ogg";
	}
	if (door.pev.colormap == B_METAL_DOOR or door.pev.colormap == B_LADDER_HATCH) {
		soundFile = opening ? "rust/door_metal_open.ogg" : "rust/door_metal_close.ogg";
	}
	if (door.pev.colormap == B_LADDER_HATCH) {
		soundFile = opening ? "rust/door_metal_open.ogg" : "rust/door_metal_close2.ogg";
		speed = 200;
	}
	if (door.pev.colormap == B_WOOD_SHUTTERS) {
		soundFile = opening ? "rust/shutters_wood_open.ogg" : "rust/shutters_wood_close.ogg";
		speed = 128;
	}
	
	if (playSound) {
		g_SoundSystem.PlaySound(door.edict(), CHAN_ITEM, soundFile, 1.0f, 1.0f, 0, 90 + Math.RandomLong(0, 20));
	}	
	
	if (dest != door.pev.angles) {
		AngularMove(door, dest, speed);
		
		if (door.pev.colormap == B_LADDER_HATCH) {
			CBaseEntity@ ladder = g_EntityFuncs.FindEntityByTargetname(null, "ladder_hatch" + door.pev.team);
			
			if (ladder !is null)
			{
				int oldcolormap = ladder.pev.colormap;
				ladder.Use(@ladder, @ladder, USE_TOGGLE, 0.0F);
				ladder.pev.colormap = oldcolormap;
			}
			else
				println("ladder_hatch" + door.pev.team + " no encontrado!");
			
		}
	}
	
	door.pev.groupinfo = 1 - door.pev.groupinfo;
}

void lock_object(CBaseEntity@ obj, string code, bool unlock)
{
	string newModel = "";
	if (obj.pev.colormap == B_WOOD_DOOR)
		newModel = "b_wood_door";
	if (obj.pev.colormap == B_METAL_DOOR)
		newModel = "b_metal_door";
	if (obj.pev.colormap == B_LADDER_HATCH)
		newModel = "b_ladder_hatch_door";
	newModel += unlock ? "_unlock" : "_lock"; // swapped for some reason
	
	if (code.Length() > 0)
		obj.pev.noise3 = code;
	
	if (newModel.Length() > 0)
	{
		int oldcolormap = obj.pev.colormap;
		g_EntityFuncs.SetModel(obj, getModelFromName(newModel));
		obj.pev.colormap = oldcolormap;
	}
	
	obj.pev.body = unlock ? 0 : 1;
}

void waitForCode(CBasePlayer@ plr)
{
	PlayerState@ state = getPlayerState(plr);
	if (state.codeTime > 0)
	{
		state.codeTime = 0;
		g_PlayerFuncs.PrintKeyBindingString(plr, "Tiempo caducado");
	}
}

void codeLockMenuCallback(CTextMenu@ menu, CBasePlayer@ plr, int page, const CTextMenuItem@ item)
{
	if (item is null)
		return;
	string action;
	item.m_pUserData.retrieve(action);
	PlayerState@ state = getPlayerState(plr);
	CBaseEntity@ lock = state.currentLock;

	if (action == "code" or action == "unlock-code") {
		state.codeTime = 1;
		string msg = "Escriba el codigo de 4 digitos numericos\nen el chat ahora.";
		PrintKeyBindingStringLong(plr, msg);
	}
	if (action == "unlock") {
		lock_object(state.currentLock, "", true);
		g_SoundSystem.PlaySound(lock.edict(), CHAN_ITEM, "rust/code_lock_beep.ogg", 1.0f, 1.0f, 0, 100);
	}
	if (action == "lock") {
		lock_object(state.currentLock, "", false);
		g_SoundSystem.PlaySound(lock.edict(), CHAN_ITEM, "rust/code_lock_beep.ogg", 1.0f, 1.0f, 0, 55);
	}
	if (action == "remove")
	{	
		string newModel = "";
		if (lock.pev.colormap == B_WOOD_DOOR)
			newModel = "b_wood_door";
		if (lock.pev.colormap == B_METAL_DOOR)
			newModel = "b_metal_door";
		if (lock.pev.colormap == B_LADDER_HATCH)
			newModel = "b_ladder_hatch_door";
		int oldcolormap = lock.pev.colormap;
		g_EntityFuncs.SetModel(lock, getModelFromName(newModel));
		lock.pev.colormap = oldcolormap;
		g_SoundSystem.PlaySound(lock.edict(), CHAN_ITEM, "rust/code_lock_place.ogg", 1.0f, 1.0f, 0, 100);		
		giveItem(@plr, I_CODE_LOCK, 1);
		
		lock.pev.button = 0;
		lock.pev.body = 0;
		lock.pev.noise3 = "";
	}
	
	menu.Unregister();
	@menu = null;
}

void openCodeLockMenu(CBasePlayer@ plr, CBaseEntity@ door)
{
	PlayerState@ state = getPlayerState(plr);
	state.initMenu(plr, codeLockMenuCallback);
	
	state.menu.SetTitle("Code Lock:\n\n");
	
	bool authed = state.isAuthed(door);
	
	if (door.pev.body == 1) // locked
	{
		if (authed)
		{
			state.menu.AddItem("Cambiar codigo\n", any("code"));
			state.menu.AddItem("Desbloquear\n", any("unlock"));
			state.menu.AddItem("Sacar Codelock\n", any("remove"));
		}
		else
		{
			state.menu.AddItem("Desbloquear con codigo\n", any("unlock-code"));
		}
		
	}
	else // unlocked
	{
		state.menu.AddItem("Cambiar codigo\n", any("code"));
		if (string(door.pev.noise3).Length() > 0) {
			state.menu.AddItem("Bloquear\n", any("lock"));
		}
		state.menu.AddItem("Sacar Codelock\n", any("remove"));
	}
	
	state.openMenu(plr);
}

HookReturnCode PlayerUse( CBasePlayer@ plr, uint& out )
{
	PlayerState@ state = getPlayerState(plr);
	bool useit = plr.m_afButtonReleased & IN_USE != 0 and state.useState < 50 and state.useState != -1;
	bool heldUse = state.useState == 50;
	
	if (plr.m_afButtonPressed & IN_USE != 0)
	{
		state.useState = 0;
	}
	else if (plr.pev.button & IN_USE != 0) 
	{
		if (state.useState >= 0)
			state.useState += 1;
		if (heldUse)
		{
			useit = true;
			state.useState = -1;
		}
	}
	if (useit)
	{
		TraceResult tr = TraceLook(plr, 256);
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		
		bool didAction = false;
		if (phit !is null and (phit.pev.classname == "func_door_rotating" or phit.pev.classname == "func_breakable_custom"))
		{
			didAction = true;
			int socket = socketType(phit.pev.colormap);
			if (socket == SOCKET_DOORWAY or (phit.pev.colormap == B_LADDER_HATCH and phit.pev.targetname != ""))
			{
				if (heldUse)
				{
					if (phit.pev.button != 0) // door has lock?
					{
						openCodeLockMenu(plr, phit);
						state.currentLock = phit;
					}
				}
				else
				{
					bool locked = phit.pev.button == 1 and phit.pev.body == 1;
					bool authed = state.isAuthed(phit);
					if (!locked or authed)
					{
						rotate_door(phit, true);
						if (locked) {
							g_SoundSystem.PlaySound(phit.edict(), CHAN_WEAPON, "rust/code_lock_beep.ogg", 1.0f, 1.0f, 0, 100);
						}
					}
					if (locked and !authed)
						g_SoundSystem.PlaySound(phit.edict(), CHAN_WEAPON, "rust/code_lock_denied.ogg", 1.0f, 1.0f, 0, 100);
				}
			}
			else if (phit.pev.colormap == B_FIRE)
			{
				func_breakable_custom@ fire = cast<func_breakable_custom@>(CastToScriptClass(phit));
				fire.FireToggle();
			}
			else if (phit.pev.colormap == B_WOOD_SHUTTERS)
			{
				rotate_door(phit, true);
				
				// open adjacent shutter
				g_EngineFuncs.MakeVectors(phit.pev.vuser1);
				CBaseEntity@ right = getPartAtPos(phit.pev.origin + g_Engine.v_right*94);
				if (right !is null and right.pev.colormap == B_WOOD_SHUTTERS) {
					rotate_door(right, false);
				}
				
				CBaseEntity@ left = getPartAtPos(phit.pev.origin + g_Engine.v_right*-94);
				if (left !is null and left.pev.colormap == B_WOOD_SHUTTERS) {
					rotate_door(left, false);
				}
			}
			else if (phit.pev.colormap == B_TOOL_CUPBOARD)
			{
				bool authed = state.isAuthed(phit);
				if (heldUse)
				{
					clearDoorAuths(phit);
					g_PlayerFuncs.PrintKeyBindingString(plr, "Lista de autorizacion borrada");
				}
				else if (authed)
				{
					// deauth
					for (uint k = 0; k < state.authedLocks.length(); k++)
					{
						if (!state.authedLocks[k] or state.authedLocks[k].GetEntity().entindex() == phit.entindex())
						{
							state.authedLocks.removeAt(k);
							k--;
						}
					}
					g_PlayerFuncs.PrintKeyBindingString(plr, "Ya no estas autorizado para construir");
				} 
				else 
				{
					EHandle h_phit = phit;
					state.authedLocks.insertLast(h_phit);
					g_PlayerFuncs.PrintKeyBindingString(plr, "Estas autorizado para construir");
				}
			}
			else if (phit.pev.colormap == B_LARGE_CHEST or phit.pev.colormap == B_SMALL_CHEST or phit.pev.colormap == B_FURNACE
					or phit.pev.colormap == E_SUPPLY_CRATE)
			{
				float usedDist = (phit.pev.origin - plr.pev.origin).Length();
				if (usedDist < getUseDistance(phit))
				{
					state.currentChest = phit;
					openLootMenu(EHandle(plr), EHandle(phit));
				}
			}
			else
				didAction = false;
		}
		if (!didAction)
		{			
			TraceResult tr2 = TraceLook(plr, 96, true);
			CBaseEntity@ lookItem = getLookItem(plr, tr2.vecEndPos);
			
			if (lookItem !is null)
			{
				if (lookItem.pev.classname == "item_inventory")
				{
					// I do my own pickup logic to bypass the 3 second drop wait in SC
					int barf = pickupItem(plr, lookItem);

					if (barf > 0)
					{
						lookItem.pev.button = barf;
						if (debug_mode)
							println("Couldn't hold " + barf + " of that");
					}
					else
					{
						item_collected(plr, lookItem, USE_TOGGLE, 0);
						lookItem.pev.renderfx = -9999;
						g_Scheduler.SetTimeout("delay_remove", 0, EHandle(lookItem));
					}
				}
				if (lookItem.pev.classname == "player_corpse" or lookItem.IsPlayer())
				{
					openLootMenu(EHandle(plr), EHandle(lookItem));
				}
			}
		}
	}
	return HOOK_CONTINUE;
}

void clearDoorAuths(CBaseEntity@ door)
{
	array<string>@ stateKeys = player_states.getKeys();
	for (uint i = 0; i < stateKeys.length(); i++)
	{
		PlayerState@ state = cast<PlayerState@>( player_states[stateKeys[i]] );
		for (uint k = 0; k < state.authedLocks.length(); k++)
		{
			if (!state.authedLocks[k] or state.authedLocks[k].GetEntity().entindex() == door.entindex())
			{
				state.authedLocks.removeAt(k);
				k--;
			}
		}
	}
}
