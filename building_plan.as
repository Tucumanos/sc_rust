#include "utils"

float EPSILON = 0.03125f;
int BUILD_MATERIAL = I_WOOD; // material needed to build stuff
float ARMOR_VALUE = 10;

class BuildPartInfo
{
	int type;
	string copy_ent;
	string title;
	int cost; // material needed to build
	
	BuildPartInfo() {
		type = -1;
	}
	
	BuildPartInfo(int t, string tit, string copy, int matCost) {
		type = t;
		copy_ent = copy;
		title = tit;
		cost = matCost;
	}
}

class Item
{
	int type;
	int stackSize;
	bool isWeapon;
	bool isAmmo;
	string title;
	string desc;
	string classname;
	string ammoName;
	array<RawItem> costs;
	
	Item() {
		type = -1;
		stackSize = 1;
	}
	
	Item(int t, int stackSz, bool wep, bool ammo, string cname, string ammoName, string tit, RawItem@ cost1, 
		RawItem@ cost2, string description="") {
		type = t;
		stackSize = stackSz;
		title = tit;
		desc = description;
		isWeapon = wep;
		isAmmo = ammo;
		classname = cname;
		this.ammoName = ammoName;
		
		if (cost1 !is null)
			costs.insertLast(cost1);
		if (cost2 !is null)
			costs.insertLast(cost2);
	}
	
	string getCostText()
	{
		if (costs.size() == 0)
			return "";
		string ret = " (";
		
		for (uint i = 0; i < costs.size(); i++)
		{
			ret += "" + costs[i].amt + " " + g_items[costs[i].type].title;
			if (i != costs.size()-1)
				ret += " + "; 
		}
		ret += ")";
		return ret;
	}
}

enum build_types
{
	B_FOUNDATION = 0,
	B_FOUNDATION_TRI,
	B_WALL,
	B_DOORWAY,
	B_WINDOW,
	B_LOW_WALL,
	B_FLOOR,
	B_FLOOR_TRI,
	B_ROOF,
	B_STAIRS,
	B_STAIRS_L,
	B_FOUNDATION_STEPS,
	
	B_WOOD_DOOR,
	B_METAL_DOOR,
	B_WOOD_BARS,
	B_METAL_BARS,
	B_WOOD_SHUTTERS,
	B_CODE_LOCK,
	B_TOOL_CUPBOARD,
	B_HIGH_WOOD_WALL,
	B_HIGH_STONE_WALL,
	B_LADDER,
	B_LADDER_HATCH,
	B_SMALL_CHEST,
	B_LARGE_CHEST,
	B_FURNACE,
	B_BED,
	B_FIRE,
	E_BOAT_WOOD,
	E_BOAT_METAL,
	
	B_ITEM_TYPES,
	
	E_SUPPLY_CRATE,
};

int B_TYPES = B_FOUNDATION_STEPS+1;

// What to update when adding a new buildable item:
// building_plan.as -> build_types + item_types + g_part_info + g_items + getCraftText
// rust.as -> part_names
// utils.as -> isFloorItem
// items.as -> openPlayerMenu (if craftable)

enum item_types
{
	I_WOOD_DOOR = 0,
	I_METAL_DOOR,
	I_WOOD_BARS,
	I_METAL_BARS,
	I_WOOD_SHUTTERS,
	I_CODE_LOCK,
	I_TOOL_CUPBOARD,
	I_HIGH_WOOD_WALL,
	I_HIGH_STONE_WALL,
	I_LADDER,
	I_LADDER_HATCH,
	I_SMALL_CHEST,
	I_LARGE_CHEST,
	I_FURNACE,
	I_BED,
	I_FIRE,
	
	I_BOAT_WOOD,
	I_BOAT_METAL,
	
	I_HAMMER,
	I_BUILDING_PLAN,
	I_ROCK,
	I_STONE_HATCHET,
	I_STONE_PICKAXE,
	I_METAL_HATCHET,
	I_METAL_PICKAXE,
	I_CROWBAR,
	I_BOW,
	I_SYRINGE,
	I_ARMOR,
	I_FLAMETHROWER,
	I_RPG,
	I_GRENADE,
	I_SATCHEL,
	I_C4,
	I_DEAGLE,
	I_SHOTGUN,
	I_SNIPER,
	I_UZI,
	I_SAW,
	I_GUITAR,
	
	I_ARROW,
	I_FUEL,
	I_556,
	I_9MM,
	I_BUCKSHOT,
	I_ROCKET,
	
	I_WOOD,
	I_STONE,
	I_METAL,
	I_HQMETAL,
	I_METAL_ORE,
	I_HQMETAL_ORE,
	I_SCRAP,
	
	ITEM_TYPES,
};

enum socket_types
{
	SOCKET_FOUNDATION = 0,
	SOCKET_MIDDLE,
	SOCKET_WALL,
	SOCKET_DOORWAY,
	SOCKET_DOOR,
	SOCKET_WINDOW,
	SOCKET_HIGH_WALL,
};

enum builder_status
{
	STATUS_RAIDER = 0,
	STATUS_SETTLER,
	STATUS_OUTSKIRTS,
}

array<BuildPartInfo> g_part_info = {
	BuildPartInfo(B_FOUNDATION, "Square Foundation", "b_foundation", 50),
	BuildPartInfo(B_FOUNDATION_TRI, "Triangle Foundation", "b_foundation_tri", 25),
	BuildPartInfo(B_WALL, "Wall", "b_wall", 50),
	BuildPartInfo(B_DOORWAY, "Doorway", "b_doorway", 35),
	BuildPartInfo(B_WINDOW, "Window", "b_window", 35),
	BuildPartInfo(B_LOW_WALL, "Low Wall", "b_low_wall", 25),
	BuildPartInfo(B_FLOOR, "Square Floor", "b_floor", 25),
	BuildPartInfo(B_FLOOR_TRI, "Triangle Floor", "b_floor_tri", 15),
	BuildPartInfo(B_ROOF, "Roof", "b_roof", 50),
	BuildPartInfo(B_STAIRS, "Stairs (U-shape)", "b_stairs", 50),
	BuildPartInfo(B_STAIRS_L, "Stairs (L-shape)", "b_stairs_l", 50),
	BuildPartInfo(B_FOUNDATION_STEPS, "Foundation Steps", "b_foundation_steps", 25),
	
	BuildPartInfo(B_WOOD_DOOR, "Wood Door", "b_wood_door", 0),
	BuildPartInfo(B_METAL_DOOR, "Metal Door", "b_metal_door", 0),
	BuildPartInfo(B_WOOD_BARS, "Wood Window Bars", "b_wood_bars", 0),
	BuildPartInfo(B_METAL_BARS, "Metal Window Bars", "b_metal_bars", 0),
	BuildPartInfo(B_WOOD_SHUTTERS, "Wood Shutters", "b_wood_shutters", 0),
	BuildPartInfo(B_CODE_LOCK, "Code Lock", "b_code_lock", 0),
	BuildPartInfo(B_TOOL_CUPBOARD, "Tool Cupboard", "b_tool_cupboard", 0),
	BuildPartInfo(B_HIGH_WOOD_WALL, "High External Wood Wall", "b_high_wood_wall", 0),
	BuildPartInfo(B_HIGH_STONE_WALL, "High External Stone Wall", "b_high_stone_wall", 0),
	BuildPartInfo(B_LADDER, "Ladder", "b_ladder", 0),
	BuildPartInfo(B_LADDER_HATCH, "Ladder Hatch", "b_ladder_hatch", 0),
	BuildPartInfo(B_SMALL_CHEST, "Small Chest", "b_small_chest", 0),
	BuildPartInfo(B_LARGE_CHEST, "Large Chest", "b_large_chest", 0),
	BuildPartInfo(B_FURNACE, "Furnace", "b_furnace", 0),
	BuildPartInfo(B_BED, "Sleeping Bag", "b_bed", 0),
	BuildPartInfo(B_FIRE, "Camp Fire", "b_fire", 0),
	BuildPartInfo(E_BOAT_WOOD, "Wood Boat", "e_boat_wood", 0),
	BuildPartInfo(E_BOAT_METAL, "Metal Boat", "e_boat_metal", 0),
	
	BuildPartInfo(E_SUPPLY_CRATE, "Supply Crate", "e_supply_crate", 0),
};

array<Item> g_items = {	
	Item(I_WOOD_DOOR, 1, false, false, "b_wood_door", "", "Wood Door", RawItem(I_WOOD, 200), null, 
		"A hinged door which is made out of wood.\nCan be locked with a Code Lock."),
	Item(I_METAL_DOOR, 1, false, false, "b_metal_door", "", "Metal Door", RawItem(I_WOOD, 200), RawItem(I_METAL, 150), 
		"A hinged door which is made out of metal.\nCan be locked with a Code Lock."),
	Item(I_WOOD_BARS, 1, false, false, "b_wood_bars", "", "Wood Window Bars", RawItem(I_WOOD, 50), null, 
		"Prevents intruders from entering through your windows."),
	Item(I_METAL_BARS, 1, false, false, "b_metal_bars", "", "Metal Window Bars", RawItem(I_METAL, 25), null, 
		"Prevents intruders from entering through your windows."),
	Item(I_WOOD_SHUTTERS, 1, false, false, "b_wood_shutters", "", "Wood Shutters", RawItem(I_WOOD, 100), null, 
		"Gives you a little privacy."),
	Item(I_CODE_LOCK, 1, false, false, "b_code_lock", "", "Code Lock", RawItem(I_METAL, 100), null, 
		"An electronic lock. Lock and unlock with a four-digit code.\nHold your USE key while looking at the lock to activate it."),
	Item(I_TOOL_CUPBOARD, 1, false, false, "b_tool_cupboard", "", "Tool Cupboard", RawItem(I_WOOD, 1000), null, 
		"Prevents unauthorized players from building near you.\nPress USE to authorize yourself and hold USE to clear previous authorizations."),
	Item(I_HIGH_WOOD_WALL, 1, false, false, "b_high_wood_wall", "", "High External Wood Wall", RawItem(I_WOOD, 1500), null, 
		"Keep intruders off your property."),
	Item(I_HIGH_STONE_WALL, 1, false, false, "b_high_stone_wall", "", "High External Stone Wall", RawItem(I_STONE, 1500), null, 
		"Keep intruders off your property."),
	Item(I_LADDER, 1, false, false, "b_ladder", "", "Ladder", RawItem(I_WOOD, 300), RawItem(I_SCRAP, 10), 
		"More compact than stairs."),
	Item(I_LADDER_HATCH, 1, false, false, "b_ladder_hatch", "", "Ladder Hatch", RawItem(I_METAL, 300), RawItem(I_SCRAP, 15), 
		"Securely separate floors in your base.\nCan be locked with a Code Lock."),
	Item(I_SMALL_CHEST, 1, false, false, "b_small_chest", "", "Small Chest", RawItem(I_WOOD, 100), null, 
		"Stores up to " + CHEST_ITEM_MAX_SMALL + " items."),
	Item(I_LARGE_CHEST, 1, false, false, "b_large_chest", "", "Large Chest", RawItem(I_WOOD, 250), RawItem(I_METAL, 50),
		"Stores up to " + CHEST_ITEM_MAX_LARGE + " items."),
	Item(I_FURNACE, 1, false, false, "b_furnace", "", "Furnace", RawItem(I_STONE, 300), RawItem(I_FUEL, 50),
		"Add Wood and Ore to smelt Metal or HQ Metal."),
	Item(I_BED, 1, false, false, "b_bed", "", "Sleeping Bag", RawItem(I_WOOD, 100), null,
		"Creates a new respawn point for yourself."),
	Item(I_FIRE, 1, false, false, "b_fire", "", "Camp Fire", RawItem(I_WOOD, 100), null,
		"Provides light and health regeneration up to 50 HP.\nPress USE to toggle the fire on/off."),
		
	Item(I_BOAT_WOOD, 1, false, false, "e_boat_wood", "", "Wood Boat", RawItem(I_WOOD, 200), null,
		"Faster than swimming."),
	Item(I_BOAT_METAL, 1, false, false, "e_boat_metal", "", "Metal Boat", RawItem(I_METAL, 100), RawItem(I_SCRAP, 2),
		"Tough and speedy."),
		
	Item(I_HAMMER, 1, true, false, "weapon_hammer", "", "Hammer", RawItem(I_WOOD, 100), null,
		"Upgrade, repair, and merge base parts."),
	Item(I_BUILDING_PLAN, 1, true, false, "weapon_building_plan", "", "Building Plan",  RawItem(I_WOOD, 10), null,
		"Used to craft buildings."),
	Item(I_ROCK, 1, true, false, "weapon_rock", "", "Rock", RawItem(I_STONE, 10), null,
		"The most basic melee weapon and gathering tool."),
	Item(I_STONE_HATCHET, 1, true, false, "weapon_stone_hatchet", "", "Stone Hatchet", RawItem(I_WOOD, 200), RawItem(I_STONE, 100),
		"Used to chop trees."),
	Item(I_STONE_PICKAXE, 1, true, false, "weapon_stone_pickaxe", "", "Stone Pickaxe", RawItem(I_WOOD, 200), RawItem(I_STONE, 100),
		"Used to mine rocks."),
	Item(I_METAL_HATCHET, 1, true, false, "weapon_metal_hatchet", "", "Metal Hatchet", RawItem(I_WOOD, 100), RawItem(I_METAL, 75),
		"Effective tree chopper and melee weapon."),
	Item(I_METAL_PICKAXE, 1, true, false, "weapon_metal_pickaxe", "", "Metal Pickaxe", RawItem(I_WOOD, 100), RawItem(I_METAL, 125),
		"Effective rock miner and melee weapon."),
	Item(I_CROWBAR, 1, true, false, "weapon_custom_crowbar", "", "Crowbar", RawItem(I_METAL, 50), null,
		"Effective corpse harvesting tool and melee weapon."),
	Item(I_BOW, 1, true, false, "weapon_bow", "", "Hunting Bow", RawItem(I_WOOD, 200), null,
		"Hard to use with lag.\nRight-click to load and aim. Left-click to shoot."),
	Item(I_SYRINGE, 100, true, false, "weapon_syringe", "health", "Syringe", RawItem(I_FUEL, 10), RawItem(I_SCRAP, 1),
		"Right-click heals you, left-click heals a target."),
	Item(I_ARMOR, 10, false, false, "item_battery", "", "Armor Piece", RawItem(I_HQMETAL, 10), RawItem(I_SCRAP, 5),
		"Equip this to increase your current armor by " + ARMOR_VALUE + "."),
	Item(I_FLAMETHROWER, 1, true, false, "weapon_flamethrower", "", "Flame Thrower", RawItem(I_HQMETAL, 20), RawItem(I_SCRAP, 20),
		"Effective against wood and flesh. Does not damage stone or metal.\nUses Fuel as ammo."),
	Item(I_RPG, 1, true, false, "weapon_custom_rpg", "", "RPG", RawItem(I_HQMETAL, 80), RawItem(I_SCRAP, 10),
		"Rocket launcher. Effective against buildings.\nUses rockets as ammo."),
	Item(I_GRENADE, 10, true, false, "weapon_custom_grenade", "hand grenade", "Hand Grenade", RawItem(I_METAL, 100), null,
		"Effective against people, but doesn't do much damage to buildings."),
	Item(I_SATCHEL, 10, true, false, "weapon_satchel_charge", "satchel", "Satchel Charge", RawItem(I_METAL, 50), RawItem(I_SCRAP, 5),
		"Attaches to a surface and explodes in 5 seconds. Effective against buildings."),
	Item(I_C4, 10, true, false, "weapon_custom_c4", "c4", "C4", RawItem(I_METAL, 200), RawItem(I_SCRAP, 20),
		"Attaches to a surface and explodes in 10 seconds. Effective against buildings."),
	Item(I_DEAGLE, 1, true, false, "weapon_custom_deagle", "", "Desert Eagle", RawItem(I_HQMETAL, 10), RawItem(I_SCRAP, 10),
		"Powerful pistol with a laser sight.\nUses pistol ammo."),
	Item(I_SHOTGUN, 1, true, false, "weapon_custom_shotgun", "", "Shotgun", RawItem(I_HQMETAL, 15), RawItem(I_SCRAP, 15),
		"Most effective at close range.\nUses buckshot ammo."),
	Item(I_SNIPER, 1, true, false, "weapon_custom_sniper", "", "Sniper Rifle", RawItem(I_HQMETAL, 30), RawItem(I_SCRAP, 15),
		"Camp in your base with this.\nUses rifle ammo."),
	Item(I_UZI, 1, true, false, "weapon_custom_uzi", "", "Uzi", RawItem(I_HQMETAL, 40), RawItem(I_SCRAP, 5),
		"Rapid-fire weapon with moderate damage.\nUses pistol ammo."),
	Item(I_SAW, 1, true, false, "weapon_custom_saw", "", "M249 SAW", RawItem(I_HQMETAL, 50), RawItem(I_SCRAP, 10),
		"Powerful machine gun with a high firing rate and damage.\nUses rifle ammo."),
	Item(I_GUITAR, 1, true, false, "weapon_guitar", "", "Guitar", RawItem(I_WOOD, 100), RawItem(I_SCRAP, 2),
		"Left-click plays notes. Right-click plays songs.\nTertiary fire selects a song."),
	
	Item(I_ARROW, 50, false, true, "arrows", "", "Wooden Arrow", RawItem(I_WOOD, 50), null,
		"Used with the Hunting Bow."),
	Item(I_FUEL, 500, false, true, "fuel", "", "Fuel", null, null,
		"Crafting material and ammo for the Flame Thrower. Collected from monsters."),
	Item(I_556, 100, false, true, "556", "", "Rifle Ammo", RawItem(I_METAL, 10), RawItem(I_HQMETAL, 5),
		"Used with the Saw and Sniper Rifle."),
	Item(I_9MM, 100, false, true, "9mm", "", "Pistol Ammo", RawItem(I_METAL, 10), RawItem(I_HQMETAL, 5), 
		"Used with the Desert Eagle and Uzi."),
	Item(I_BUCKSHOT, 50, false, true, "buckshot", "", "Shotgun Shell", RawItem(I_METAL, 10), RawItem(I_HQMETAL, 5),
		"Used with the Shotgun."),
	Item(I_ROCKET, 5, false, true, "rockets", "", "Rocket", RawItem(I_HQMETAL, 20), RawItem(I_SCRAP, 5),
		"Used with the RPG."),
		
	Item(I_WOOD, 1000, false, false, "", "", "Wood", null, null,
		"Collected from trees and used to build bases and craft items."),
	Item(I_STONE, 1000, false, false, "", "", "Stone", null, null,
		"Collected from rocks and used to reinforce bases and craft items."),
	Item(I_METAL, 1000, false, false, "", "", "Metal", null, null,
		"Smelted from metal ore."),
	Item(I_HQMETAL, 100, false, false, "", "", "HQ Metal", null, null,
		"High quality metal smelted from HQ Metal Ore."),
	Item(I_METAL_ORE, 1000, false, false, "", "", "Metal Ore", null, null,
		"Collected from rocks. Smelt this in a furnace to produce Metal."),
	Item(I_HQMETAL_ORE, 100, false, false, "", "", "HQ Metal Ore", null, null,
		"Collected from rocks. Smelt this in a furnace to produce HQ Metal."),
	Item(I_SCRAP, 100, false, false, "", "", "Scrap", null, null,
		"Crafting material collected from barrels."),
};


class weapon_building_plan : ScriptBasePlayerWeaponEntity
{
	float m_flNextAnimTime;
	bool canShootAgain = false;
	EHandle h_buildEnt = null;
	EHandle h_buildEnt2 = null;
	EHandle h_attachEnt = null;
	bool active = false;
	bool validBuild = false;
	bool forbidden = false;
	int buildType = B_FOUNDATION;
	float nextCycle = 0;
	float nextAlternate = 0;
	float lastHudUpdate = 0;
	int nextSnd = 0;
	int zoneid = -1;
	bool alternateBuild = false;
	Vector lastLookOri;
	
	void Spawn()
	{		
		Precache();
		g_EntityFuncs.SetModel( self, "models/rust/w_blueprint.mdl" );

		//self.m_iDefaultAmmo = 0;
		//self.m_iClip = self.m_iDefaultAmmo;
		
		self.FallInit();
		SetThink( ThinkFunction( WeaponThink ) );
	}
	
	void Precache()
	{
		self.PrecacheCustomModels();
		PrecacheModel( "models/rust/w_blueprint.mdl" );
		PrecacheModel( "models/rust/p_blueprint.mdl" );
		PrecacheModel( "models/rust/v_blueprint.mdl" );
		
		PrecacheSound("rust/build1.ogg");
		PrecacheSound("rust/build2.ogg");
	}
	
	bool GetItemInfo( ItemInfo& out info )
	{				
		info.iMaxAmmo1 	= 20;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= 0;
		info.iSlot 		= 6;
		info.iPosition 	= 9;
		info.iFlags 	= 6;
		info.iWeight 	= 5;
		
		return true;
	}
	
	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( BaseClass.AddToPlayer( pPlayer ) == true and pPlayer !is null )
		{
			NetworkMessage message( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
				message.WriteLong( self.m_iId );
			message.End();
			return true;
		}
		
		return false;
	}
	
	bool Deploy()
	{
		bool bResult = self.DefaultDeploy( self.GetV_Model( "models/rust/v_blueprint.mdl" ), 
										   self.GetP_Model( "models/rust/p_blueprint.mdl" ), 0, "trip" );
		
		createBuildEnts();
		updateBuildPlaceholder(true);
		
		active = true;
		
		return true;
	}
	
	void createBuildEnts()
	{
		CBaseEntity@ buildEnt = h_buildEnt;
		CBaseEntity@ buildEnt2 = h_buildEnt2;
		if (h_buildEnt) {
			g_EntityFuncs.Remove(h_buildEnt);
			h_buildEnt = null;
		}
		if (h_buildEnt2) {
			g_EntityFuncs.Remove(h_buildEnt2);
			h_buildEnt2 = null;
		}
		
		TraceResult look = TraceLook(getPlayer(), 280);
		string suffix = alternateBuild ? "" : "_twig";
		
		dictionary keys;
		keys["origin"] = (look.vecEndPos + Vector(0,0,16)).ToString();
		keys["model"] = getModelFromName(g_part_info[buildType].copy_ent + suffix);
		keys["rendermode"] = "1";
		keys["renderamt"] = "128";
		keys["rendercolor"] = "0 255 255";
		keys["colormap"] = "" + buildType;
			
		@buildEnt = g_EntityFuncs.CreateEntity("func_illusionary", keys, true);	
		
		keys["rendermode"] = "2";
		@buildEnt2 = g_EntityFuncs.CreateEntity("func_illusionary", keys, true);	
		buildEnt2.pev.scale = 0.5f;
		
		buildEnt.pev.movetype = MOVETYPE_NONE;
		buildEnt.pev.solid = SOLID_TRIGGER;
		//g_EntityFuncs.SetOrigin(buildEnt, buildEnt.pev.origin);
		
		h_buildEnt = buildEnt;
		h_buildEnt2 = buildEnt2;
		
		// increment force_retouch
		//g_EntityFuncs.FireTargets("push", null, null, USE_TOGGLE);
		
		string cost = "\n\n(" + g_part_info[buildType].cost + " " + g_items[BUILD_MATERIAL].title + ")";
		if (buildType >= B_WOOD_DOOR or g_free_build)
			cost = "";
		
		g_PlayerFuncs.PrintKeyBindingString(getPlayer(), g_part_info[buildType].title + cost);
	}
	
	void Holster(int iSkipLocal = 0) 
	{
		active = false;
		if (h_buildEnt) {
			g_EntityFuncs.Remove(h_buildEnt);
			h_buildEnt = null;
		}
		if (h_buildEnt2) {
			g_EntityFuncs.Remove(h_buildEnt2);
			h_buildEnt2 = null;
		}
	}
	
	float WeaponTimeBase()
	{
		return g_Engine.time; //g_WeaponFuncs.WeaponTimeBase();
	}
	
	void updateBuildPlaceholder(bool force_update=false)
	{
		CBasePlayer@ plr = getPlayer();
		
		CBaseEntity@ buildEnt = h_buildEnt;
		CBaseEntity@ buildEnt2 = h_buildEnt2;
		
		// show building placeholder
		if (buildEnt is null)
			return;
		
		float buildDist = 160.0f;
		if (buildType >= B_WOOD_DOOR and buildType != B_HIGH_STONE_WALL and buildType != B_HIGH_WOOD_WALL
			and buildType != B_LADDER_HATCH)
			buildDist = 96.0f;
		if (isFloorItem(buildEnt) or buildType == B_FIRE)
			buildDist = 128.0f;
			
		bool buildingBoat = buildType == E_BOAT_WOOD or buildType == E_BOAT_METAL;
		if (buildingBoat)
			buildDist = 192.0f;
		float maxSnapDist = buildDist + 32.0f;
		TraceResult tr = TraceLook(plr, buildDist);
		
		Vector newOri = tr.vecEndPos;
		if (!force_update and (newOri - lastLookOri).Length() < EPSILON)
			return;
		lastLookOri = newOri;
		
		h_attachEnt = null;
		CBaseEntity@ attachEnt = h_attachEnt;
			
		float newYaw = plr.pev.angles.y;
		float newPitch = buildEnt.pev.angles.x;
		float newRot = buildEnt.pev.angles.z;
		CBaseEntity@ phit = g_EntityFuncs.Instance( tr.pHit );
		
		if (buildingBoat)
			newYaw -= 90;
		
		int partSocket = socketType(buildType);
		bool attaching = false;
		CBaseEntity@ skipCollide = null;
		
		validBuild = false;
		if (buildingBoat)
		{
			if (g_EngineFuncs.PointContents(tr.vecEndPos) == CONTENTS_WATER)
			{
				newOri.z = g_Utility.WaterLevel(tr.vecEndPos, tr.vecEndPos.z, tr.vecEndPos.z + 8192) - 12;
				validBuild = true;
			}
		}
		else if (partSocket == SOCKET_HIGH_WALL)
		{
			if (phit.pev.classname == "worldspawn" and tr.flFraction < 1.0f) {
				validBuild = true;
			}
		
			g_EngineFuncs.MakeVectors(buildEnt.pev.angles);
			
			Vector left = tr.vecEndPos - g_Engine.v_right*128;
			Vector right = tr.vecEndPos + g_Engine.v_right*128;
			
			CBaseEntity@ part = null;
			do {
				@part = g_EntityFuncs.FindEntityInSphere(part, tr.vecEndPos, 768.0f, "func_breakable_custom", "classname");
				if (part !is null)
				{			
					if (part is null or socketType(part.pev.colormap) != SOCKET_HIGH_WALL)
						continue;
						
					if ((part.pev.origin - buildEnt.pev.origin + Vector(0,0,120)).Length() > 500)
						continue;
					
					float attachDist = 64;
					g_EngineFuncs.MakeVectors(part.pev.angles);
					Vector attachLeft = part.pev.origin + g_Engine.v_right*-128 + Vector(0,0,-120);
					Vector attachRight = part.pev.origin + g_Engine.v_right*128 + Vector(0,0,-120);
					
					float ll = (attachLeft - left).Length();
					float lr = (attachLeft - right).Length();
					float rr = (attachRight - right).Length();
					float rl = (attachRight - left).Length();
					
					if (ll > attachDist and lr > attachDist and rr > attachDist and rl > attachDist)
						continue;
					
					if (attaching)
					{
						// can attach to two walls (bridging a gap)
						// just disable collision and let the player align it right
						// (but only if it's close enough to the end)
						@skipCollide = @part;
						break;
					}
					bool sameDir = false;
					if (ll < lr and ll < rr and ll < rl)
					{
						newOri = newOri + (attachLeft - left);
						attaching = true;
					}
					else if (lr < ll and lr < rr and lr < rl)
					{
						newOri = newOri + (attachLeft - right);
						attaching = true;
						sameDir = true;
					}
					else if (rr < ll and rr < lr and rr < rl)
					{
						newOri = newOri + (attachRight - right);
						attaching = true;
					}
					else if (rl < ll and rl < lr and rl < rr)
					{
						newOri = newOri + (attachRight - left);
						attaching = true;
						sameDir = true;
					}
					if (attaching)
					{
						float dot = DotProduct((attachLeft - attachRight).Normalize(), (left - right).Normalize());
						if (!sameDir)
							dot = -dot;
						
						if (dot > -0.55f)
						{
							TraceResult tr2;
							g_Utility.TraceLine( newOri, newOri + Vector(0,0,-16), dont_ignore_monsters, null, tr2 );
							CBaseEntity@ phit2 = g_EntityFuncs.Instance( tr2.pHit );
							
							validBuild = tr2.flFraction < 1.0f and phit2 !is null and phit2.pev.classname == "worldspawn";
							@phit = @part;
						}
						else
						{
							validBuild = false;
						}
					}
				}
			} while (part !is null);
			newOri.z += 120;
		}
		else if (partSocket == SOCKET_FOUNDATION or partSocket == SOCKET_WALL or buildType == B_FLOOR or 
				buildType == B_LADDER_HATCH or buildType == B_ROOF or partSocket == SOCKET_MIDDLE or
				partSocket == SOCKET_DOORWAY or partSocket == SOCKET_WINDOW or buildType == B_FLOOR_TRI)
		{
			g_EngineFuncs.MakeVectors(buildEnt.pev.angles);
			float bestDist = 9000;
			
			CBaseEntity@ part = null;
			do {
				@part = g_EntityFuncs.FindEntityInSphere(part, tr.vecEndPos, 256.0f, "func_breakable_custom", "classname");
				if (part !is null)
				{						
					int attachType = part.pev.colormap;
					int attachSocket = socketType(part.pev.colormap);
						
					if (partSocket == SOCKET_FOUNDATION and (part.pev.colormap != B_FOUNDATION and part.pev.colormap != B_FOUNDATION_TRI))
						continue;
					if ((partSocket == SOCKET_WALL or buildType == B_FLOOR or buildType == B_LADDER_HATCH or buildType == B_FLOOR_TRI) 
						and !isFloorPiece(part) and attachSocket != SOCKET_WALL)
						continue;
					if (buildType == B_ROOF and attachSocket != SOCKET_WALL)
						continue;
					if (partSocket == SOCKET_MIDDLE and !isFloorPiece(part))
						continue;
					if (partSocket == SOCKET_DOORWAY and attachType != B_DOORWAY)
						continue;
					if (partSocket == SOCKET_WINDOW and attachType != B_WINDOW)
						continue;
					if (part.pev.colormap == B_LADDER_HATCH and part.pev.targetname != "") // don't attach to door
						continue;
					
					float attachDist = 96;
					if (partSocket == SOCKET_DOORWAY or partSocket == SOCKET_WINDOW)
						attachDist = 200;
					g_EngineFuncs.MakeVectors(part.pev.angles);
					
					Vector attachOri = tr.vecEndPos;
					float attachYaw = part.pev.angles.y;
					float minDist = 0;
					
					if (isFloorPiece(part) and partSocket != SOCKET_MIDDLE and 
						!((buildType == B_FLOOR or buildType == B_LADDER_HATCH or buildType == B_FLOOR_TRI) and 
						isFoundation(part)))
					{
						if (isTriangular(part))
						{
							// Tri mathematical properties:
							// Height = 110.851
							// Center point = 64, 36.95
							// edge mid point (relative to origin) = -32, 18.476
							// Actual brush properties are different, but using floats instead of ints in the export fucks this up somehow
							Vector left = part.pev.origin + g_Engine.v_right*-32 + g_Engine.v_forward*18.476;
							Vector right = part.pev.origin + g_Engine.v_right*32 + g_Engine.v_forward*18.476;
							Vector back = part.pev.origin + g_Engine.v_forward*-36.95;
							
							float dl = (left - tr.vecEndPos).Length();
							float dr = (right - tr.vecEndPos).Length();
							float db = (back - tr.vecEndPos).Length();
							
							if (dl > attachDist and dr > attachDist and db > attachDist)
								continue;
							if (dl > bestDist and dr > bestDist and db > bestDist)
								continue;
								
							float oriDist = 73.9;
							if (partSocket == SOCKET_WALL)
								oriDist = 36.95;
							if (buildType == B_FOUNDATION or buildType == B_FOUNDATION_STEPS or buildType == B_FLOOR or buildType == B_LADDER_HATCH)
								oriDist = 64 + 36.95;
							attachYaw = part.pev.angles.y;
							minDist = dl;
							if (dl < dr and dl < db)
							{
								attachOri = part.pev.origin + (left - part.pev.origin).Normalize()*oriDist;
								attachYaw = part.pev.angles.y + (buildType == B_FOUNDATION_TRI ? -60 : 60);
								minDist = dl;
							}
							else if (dr < dl and dr < db)
							{
								attachOri = part.pev.origin + (right - part.pev.origin).Normalize()*oriDist;
								attachYaw = part.pev.angles.y + (buildType == B_FOUNDATION_TRI ? 60 : -60);
								minDist = dr;
							}
							else if (db < dl and db < dr)
							{
								attachOri = part.pev.origin + g_Engine.v_forward*-oriDist;
								attachYaw = Math.VecToAngles(part.pev.origin - back).y + 180;
								minDist = db;
							}
							if (buildType == B_FOUNDATION_STEPS) {
								attachYaw += 180;
							}

						}
						else
						{
							Vector left = part.pev.origin + g_Engine.v_right*-64;
							Vector right = part.pev.origin + g_Engine.v_right*64;
							Vector front = part.pev.origin + g_Engine.v_forward*64;
							Vector back = part.pev.origin + g_Engine.v_forward*-64;
							
							float dl = (left - tr.vecEndPos).Length();
							float dr = (right - tr.vecEndPos).Length();
							float df = (front - tr.vecEndPos).Length();
							float db = (back - tr.vecEndPos).Length();
							
							if (dl > attachDist and dr > attachDist and df > attachDist and db > attachDist)
								continue;
							if (dl > bestDist and dr > bestDist and df > bestDist and db > bestDist)
								continue;
								
							float oriDist = 128;
							if (partSocket == SOCKET_WALL)
								oriDist = 64;
							if (isTriangular(buildEnt))
								oriDist = 36.95 + 64;
							attachYaw = part.pev.angles.y;
							minDist = dl;
							if (dl < dr and dl < df and dl < db)
							{
								attachOri = part.pev.origin + g_Engine.v_right*-oriDist;
								attachYaw = Math.VecToAngles(part.pev.origin - left).y;
								minDist = dl;
							}
							else if (dr < dl and dr < df and dr < db)
							{
								attachOri = part.pev.origin + g_Engine.v_right*oriDist;
								attachYaw = Math.VecToAngles(part.pev.origin - right).y;
								minDist = dr;
							}
							else if (df < dl and df < dr and df < db)
							{
								attachOri = part.pev.origin + g_Engine.v_forward*oriDist;
								attachYaw = Math.VecToAngles(part.pev.origin - front).y;
								minDist = df;
							}
							else if (db < dl and db < dr and db < df)
							{
								attachOri = part.pev.origin + g_Engine.v_forward*-oriDist;
								attachYaw = Math.VecToAngles(part.pev.origin - back).y;
								minDist = db;
							}
								
							if (isTriangular(buildEnt)) {
								attachYaw += 180;
							}
						}
					}
					else if ((attachSocket == SOCKET_WALL and attachType != B_LOW_WALL) and (buildType == B_FLOOR or buildType == B_LADDER_HATCH or buildType == B_FLOOR_TRI))
					{
						Vector front = part.pev.origin + g_Engine.v_forward*4 + Vector(0,0,128);
						Vector back = part.pev.origin + g_Engine.v_forward*-4 + Vector(0,0,128);
						float df = (front - tr.vecEndPos).Length();
						float db = (back - tr.vecEndPos).Length();
						
						if (df > attachDist and db > attachDist)
							continue;
						if (df > bestDist and db > bestDist)
							continue;
							
						attachYaw = part.pev.angles.y;
						float oriDist = buildType == B_FLOOR_TRI ? 36.95 : 64;
						minDist = df;
						if (df < db)
						{
							attachOri = part.pev.origin + g_Engine.v_forward*oriDist + Vector(0,0,128);
							attachYaw = Math.VecToAngles(part.pev.origin - front).y;
							minDist = df;
						}
						else if (db < df)
						{
							attachOri = part.pev.origin + g_Engine.v_forward*-oriDist + Vector(0,0,128);
							attachYaw = Math.VecToAngles(part.pev.origin - back).y;
							minDist = db;
						}
						
						if (buildType == B_FLOOR_TRI)
							attachYaw += 180;
					}
					else if (partSocket == SOCKET_DOORWAY and attachType == B_DOORWAY)
					{
						Vector front = part.pev.origin + g_Engine.v_forward*32 + Vector(0,0,64);
						Vector back = part.pev.origin + g_Engine.v_forward*-32 + Vector(0,0,64);
						float df = (front - tr.vecEndPos).Length();
						float db = (back - tr.vecEndPos).Length();
						
						if (df > attachDist or db > attachDist)
							continue;
						if (df > bestDist or db > bestDist)
							continue;
							
						attachYaw = part.pev.angles.y;
						minDist = df;
						if (df > db)
						{
							attachOri = part.pev.origin + g_Engine.v_right*-32 + Vector(0,0,64);
							attachYaw = Math.VecToAngles(part.pev.origin - front).y;
							minDist = df;
						}
						else if (db > df)
						{
							attachOri = part.pev.origin + g_Engine.v_right*32 + Vector(0,0,64);
							attachYaw = Math.VecToAngles(part.pev.origin - back).y;
							minDist = db;
						}
					}
					else if (partSocket == SOCKET_WINDOW and attachType == B_WINDOW)
					{
						Vector front = part.pev.origin + g_Engine.v_forward*32 + Vector(0,0,64);
						Vector back = part.pev.origin + g_Engine.v_forward*-32 + Vector(0,0,64);
						float df = (front - tr.vecEndPos).Length();
						float db = (back - tr.vecEndPos).Length();
						
						if (df > attachDist or db > attachDist)
							continue;
						if (df > bestDist or db > bestDist)
							continue;
							
						float oriDist = buildType == B_WOOD_SHUTTERS ? 4 : 0;
						attachYaw = part.pev.angles.y;
						minDist = df;
						if (df > db)
						{
							attachOri = part.pev.origin + g_Engine.v_forward*-oriDist + Vector(0,0,64);
							attachYaw = Math.VecToAngles(part.pev.origin - front).y;
							minDist = df;
						}
						else if (db > df)
						{
							attachOri = part.pev.origin + g_Engine.v_forward*oriDist + Vector(0,0,64);
							attachYaw = Math.VecToAngles(part.pev.origin - back).y;
							minDist = db;
						}
					}
					else if (attachSocket == SOCKET_WALL and attachType != B_LOW_WALL and buildType != B_ROOF) // stacking walls
					{
						Vector up = part.pev.origin + Vector(0,0,128);
						float du = (up - tr.vecEndPos).Length();
						
						if (du > attachDist or du > bestDist)
							continue;
							
						attachOri = up;
						attachYaw = part.pev.angles.y;
						minDist = du;
					}
					else if (attachSocket == SOCKET_WALL and attachType != B_LOW_WALL and buildType == B_ROOF) // roof
					{
						Vector front = part.pev.origin + g_Engine.v_forward*16 + Vector(0,0,128);
						Vector back = part.pev.origin + g_Engine.v_forward*-16 + Vector(0,0,128);
						float df = (front - tr.vecEndPos).Length();
						float db = (back - tr.vecEndPos).Length();
						
						//attachDist = 112;
						
						if (df > attachDist or db > attachDist)
							continue;
						if (df > bestDist or db > bestDist)
							continue;
							
						attachYaw = part.pev.angles.y;
						minDist = df;
						if (df < db)
						{
							attachOri = part.pev.origin + g_Engine.v_forward*64 + Vector(0,0,192);
							attachYaw = Math.VecToAngles(part.pev.origin - front).y;
							minDist = df;
						}
						else if (db < df)
						{
							attachOri = part.pev.origin + g_Engine.v_forward*-64 + Vector(0,0,192);
							attachYaw = Math.VecToAngles(part.pev.origin - back).y;
							minDist = db;
						}
					}
					else if (partSocket == SOCKET_MIDDLE and attachType == B_FOUNDATION or attachType == B_FLOOR)
					{
						Vector up = part.pev.origin + Vector(0,0,64);
						float du = (up - tr.vecEndPos).Length();
						
						if (du > attachDist or du > bestDist)
							continue;
							
						attachOri = up;
						minDist = du;
					}
					else
						continue;
						
					if (buildType == B_LADDER_HATCH or partSocket == SOCKET_MIDDLE and isFloorPiece(part))
					{
						// orient stairs according to where the player is looking
						Vector floor_forward = g_Engine.v_forward;
						Vector floor_right = g_Engine.v_right;
						
						g_EngineFuncs.MakeVectors(plr.pev.angles);
						Vector plr_forward = g_Engine.v_forward;
						plr_forward.z = 0;
						plr_forward.Normalize();
						
						float fdot = DotProduct(plr_forward, floor_forward);
						float rdot = DotProduct(plr_forward, floor_right);
						
						if (buildType == B_LADDER_HATCH and attachSocket == SOCKET_WALL)
						{
							fdot = -fdot;
							rdot = -rdot;
						}
						
						if (abs(fdot) > abs(rdot)) {
							if (fdot > 0) {
								attachYaw += 0;
							} else {
								attachYaw += 180;
							}
						} else {
							if (rdot > 0) {
								attachYaw += 270;
							} else {
								attachYaw += 90;
							}
						}
					}
					
					if (getPartAtPos(attachOri) !is null)
						continue;
					if (partSocket == SOCKET_DOORWAY and getPartsByParent(part.pev.team).length() > 0)
						continue;
						
					if (buildType == B_FOUNDATION_TRI or buildType == B_FLOOR_TRI)
					{
						CBaseEntity@ ent = getPartAtPos(attachOri, 28);
						if (ent !is null and (ent.pev.colormap == B_FOUNDATION or ent.pev.colormap == B_FLOOR))
						{
							// triangle would be completely inside a square piece
							continue;
						}
					}
					if (buildType == B_FOUNDATION or buildType == B_FLOOR)
					{
						CBaseEntity@ ent = getPartAtPos(attachOri, 28);
						if (ent !is null and (ent.pev.colormap == B_FOUNDATION_TRI or ent.pev.colormap == B_FLOOR_TRI))
						{
							// square would be completely enclosing a tri piece
							continue;
						}
					}
					if (buildType == B_LADDER_HATCH)
					{
						CBaseEntity@ ent = getPartAtPos(attachOri + Vector(0,0,-64), 2);
						if (ent !is null and socketType(ent.pev.colormap) == SOCKET_MIDDLE)
						{
							// ladder hatch opens into stairs or something
							continue;
						}
					}
					
					if ((plr.pev.origin - attachOri).Length() > maxSnapDist)
						continue;
						
					bestDist = minDist;
					newOri = attachOri;
					attaching = true;
					validBuild = true;
					@phit = @part;
					
					if ((buildType == B_FOUNDATION or buildType == B_FLOOR) and (attachType == B_FOUNDATION or attachType == B_FLOOR))
						newYaw = part.pev.angles.y;
					else
						newYaw = attachYaw;
				}
			} while (part !is null);
			
			if (buildType == B_FOUNDATION or buildType == B_FOUNDATION_STEPS or buildType == B_FOUNDATION_TRI)
			{
				// check that all 4 corners of the foundation/steps touch the floor
				validBuild = buildType == B_FOUNDATION_STEPS ? attaching : true; // check all 4 points for contact with ground
			
				g_EngineFuncs.MakeVectors(buildEnt.pev.angles);
				array<Vector> posts;
				
				if (buildType == B_FOUNDATION_TRI)
				{
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_right*62 + g_Engine.v_forward*-35 + Vector(0,0,-1));
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_right*-62 + g_Engine.v_forward*-35 + Vector(0,0,-1));
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_forward*71 + Vector(0,0,-1));
				}
				else
				{
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_right*62 + g_Engine.v_forward*62 + Vector(0,0,-1));
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_right*62 + g_Engine.v_forward*-62 + Vector(0,0,-1));
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_right*-62 + g_Engine.v_forward*62 + Vector(0,0,-1));
					posts.insertLast(buildEnt.pev.origin + g_Engine.v_right*-62 + g_Engine.v_forward*-62 + Vector(0,0,-1));
				}
				
				bool allSolid = true;
				for (uint i = 0; i < posts.length(); i++)
				{
					TraceResult tr2;
					Vector vecEnd = posts[i] + Vector(0,0,-112);
					g_Utility.TraceLine( posts[i], vecEnd, dont_ignore_monsters, phit.edict(), tr2 );
					CBaseEntity@ phit2 = g_EntityFuncs.Instance( tr2.pHit );
					
					if (phit2 is null or phit2.pev.classname != "worldspawn" or tr2.flFraction >= 1.0f) {
						if (tr2.fAllSolid == 0)
						{
							validBuild = false;
							break;
						}
						continue;
					}
					allSolid = false;
					
					if (!attaching)
					{
						newOri.z = Math.max(newOri.z, (tr2.vecEndPos + tr2.vecPlaneNormal*8).z);
					}
				}
				
				if (allSolid)
					validBuild = false;
			}
		}
		else if (partSocket == -1 and !isFloorItem(buildEnt))
		{
			// place anywhere
			if (tr.flFraction < 1.0f and (phit.pev.classname == "worldspawn" or isFloorPiece(phit))) {
				if (tr.vecPlaneNormal.z > 0.7f and g_EngineFuncs.PointContents(tr.vecEndPos) == CONTENTS_EMPTY)
				{
					validBuild = true;
					Vector outAngles;
					g_EngineFuncs.VecToAngles(tr.vecPlaneNormal, outAngles);
					newYaw = outAngles.y;
					newPitch = -outAngles.x + 90;
					newRot = outAngles.z;
				}
			}
		}	
		
		bool attachableEnt = phit.pev.classname == "func_breakable_custom" or phit.pev.classname == "func_door_rotating";
		if (attachableEnt and !attaching) {
			int attachType = phit.pev.colormap;
			int attachSocket = socketType(attachType);
			
			if (isFloorPiece(phit) and isFloorItem(buildEnt))
			{
				validBuild = true;
				attaching = true;
			}
			else if (buildType == B_LADDER)
			{
				if (attachSocket == SOCKET_WALL)
				{
					g_EngineFuncs.MakeVectors(phit.pev.angles);
					float oldYaw = newYaw;
					newYaw = phit.pev.angles.y;
					if (vecEqual(tr.vecPlaneNormal, g_Engine.v_forward))
						newYaw += 180;
						
					newOri = newOri + tr.vecPlaneNormal*3;
					
					// check if the ladder is going to immediately break or not
					TraceResult tr2;
					Vector vecEnd = tr.vecEndPos + g_Engine.v_forward*4;
					g_Utility.TraceLine( tr.vecEndPos, vecEnd, ignore_monsters, null, tr2 );
					CBaseEntity@ phit2 = g_EntityFuncs.Instance( tr2.pHit );
					
					if (phit2 !is null and phit.pev.classname == "func_breakable_custom" and socketType(phit.pev.colormap) == SOCKET_WALL)
					{
						validBuild = true;
						attaching = true;
					}
					else
						newYaw = oldYaw;						
				}
			}
			else if (partSocket == SOCKET_DOOR)
			{
				g_EngineFuncs.MakeVectors(phit.pev.angles);
				// only allow attaching to the top when looking at the front/back of doorway
				if ((attachType == B_WOOD_DOOR or attachType == B_METAL_DOOR or attachType == B_LADDER_HATCH) and 
					phit.pev.targetname != "")
				{
					if (attachType == B_LADDER_HATCH and vecEqual(tr.vecPlaneNormal, g_Engine.v_up) or 
						vecEqual(tr.vecPlaneNormal, -g_Engine.v_up))
					{
						newOri = phit.pev.origin - g_Engine.v_forward*36 + Vector(0,0,-1);
						validBuild = true;
						attaching = true;
						newYaw = phit.pev.angles.y + 180;
						newPitch = 90;
						if (buildType == B_CODE_LOCK and phit.pev.button == 1)
							validBuild = false;
					}
					else if ((attachType == B_WOOD_DOOR or attachType == B_METAL_DOOR) and 
								vecEqual(tr.vecPlaneNormal, g_Engine.v_forward) or vecEqual(tr.vecPlaneNormal, -g_Engine.v_forward))
					{
						newOri = phit.pev.origin - g_Engine.v_right*32;
						validBuild = true;
						attaching = true;
						newYaw = phit.pev.angles.y;
						if (buildType == B_CODE_LOCK and phit.pev.button == 1)
							validBuild = false;
					}
					
				}
			}
		}
		
		if (attaching)
			h_attachEnt = @attachEnt = phit;
		
		buildEnt.pev.origin = buildEnt2.pev.origin = newOri;
		buildEnt.pev.angles.y = buildEnt2.pev.angles.y = newYaw;
		buildEnt.pev.angles.x = buildEnt2.pev.angles.x = newPitch;
		buildEnt.pev.angles.z = buildEnt2.pev.angles.z = newRot;
		g_EntityFuncs.SetOrigin(buildEnt, buildEnt.pev.origin); // fix collision
		
		// check collision
		if (validBuild)
		{
			CBaseEntity@ ent = null;
			do {
				@ent = g_EntityFuncs.FindEntityInSphere(ent, newOri, 192, "*", "classname");
				if (ent !is null)
				{
					if (ent.entindex() == buildEnt.entindex() or ent.entindex() == buildEnt2.entindex())
						continue;
					if (skipCollide !is null and skipCollide.entindex() == ent.entindex())
						continue;
					if (attachEnt !is null and ent.entindex() == attachEnt.entindex())
						continue;
					if (ent.pev.solid == SOLID_NOT)
						continue;
					//if (ent.pev.effects & EF_NODRAW != 0)
					if (ent.pev.solid == SOLID_TRIGGER and ent.pev.classname != "func_build_clip")
						continue;
					if (buildType == B_CODE_LOCK or buildType == B_LADDER)
						continue;

					string cname = string(ent.pev.classname);
					if ((cname == "func_breakable_custom" or cname == "func_door_rotating") && attaching) {
						// still a small chance a separate base perfectly aligns, letting
						// you build overlapping pieces, but that should be pretty rare.
						float diff = (ent.pev.origin - buildEnt.pev.origin).Length();

						if (diff < 1.0f) {
							validBuild = false; // socket already filled
							break;
						}
						if (buildType == B_WOOD_SHUTTERS and diff < 50.0f) {
							validBuild = false;
							break;
						}
					}
					float maxOverlap = ent.IsBSPModel() and !isFloorItem(buildEnt) ? 9.95f : 2.0f;
					float overlap = collisionBoxesYaw(buildEnt, ent);
					if (overlap > maxOverlap) {
						if (debug_mode)
							println("BLOCKED BY: " + cname + " overlap " + overlap);
						validBuild = false;
						break;
					} 
					else if (debug_mode && overlap > 0)
					{
						//println("OVERLAP BY: " + cname + " overlap " + overlap);
					}
				}
			} while (ent !is null);
		}
		
		// extra limitations in invasion mode
		if (g_invasion_mode and g_EngineFuncs.PointContents(newOri) != CONTENTS_EMPTY and !buildingBoat)
			validBuild = false;
		
		// only allow building in build zones
		if (!g_build_anywhere and !buildingBoat)
		{
			zoneid = getBuildZone(buildEnt);
			if (zoneid == -1)
				validBuild = false;
		}

		bool isCupboard = buildEnt.pev.colormap == B_TOOL_CUPBOARD;
		forbidden = forbiddenByCupboard(plr, buildEnt.pev.origin, isCupboard);	
		
		int c = 64 + int(g_brightness*191.0f);
		int c2 = 32 + int(g_brightness*96.0f);
		if (forbidden and validBuild) {
			buildEnt.pev.rendercolor = Vector(c, c, 0);
		} else if (validBuild) {
			buildEnt.pev.rendercolor = Vector(0, c, c);
		} else {
			buildEnt.pev.rendercolor = Vector(c, 0, 0);
		}
		buildEnt2.pev.renderamt = c2;
		//println(phit.pev.classname);
	}
	
	void WeaponThink()
	{
		if (active && self.m_hPlayer) 
		{
			CBasePlayer@ plr = getPlayer();
			
			if (plr.pev.button & 1 == 0) {
				canShootAgain = true;
			}
			
			if (lastHudUpdate < g_Engine.time + 0.05f)
			{
				lastHudUpdate = g_Engine.time;
				PlayerState@ state = getPlayerState(plr);
				
				HUDTextParams params;
				params.y = 0.88;
				params.effect = 0;
				params.r1 = 255;
				params.g1 = 255;
				params.b1 = 255;
				params.fadeinTime = 0;
				params.fadeoutTime = 0;
				params.holdTime = 0.2f;
				
				params.x = 0.1;
				params.channel = 2;
				
				if (!state.menuCam.IsValid())
				{
					if (!g_build_anywhere)
					{
						if (zoneid != -1)
						{
							BuildZone@ zone = getBuildZone(zoneid);
							string status;
							if (zoneid == state.home_zone or g_invasion_mode or g_creative_mode or g_shared_build_points_in_pvp_mode)
							{
								status = "Settler";
								params.r1 = 48;
								params.g1 = 255;
								params.b1 = 48;
							}
							else
							{
								status = "Raider";
								params.r1 = 255;
								params.g1 = 48;
								params.b1 = 48;
							}
							
							if (!g_invasion_mode and !g_creative_mode and !g_shared_build_points_in_pvp_mode)
								g_PlayerFuncs.HudMessage(plr, params, "Build Zone: " + g_zone_info.getZoneName(zoneid) + 
														 "\nSettlers: " + zone.numSettlers + " / " + zone.maxSettlers +
														 "\nStatus: " + status);
														 
							if (g_creative_mode or g_invasion_mode or g_shared_build_points_in_pvp_mode)
							{
								g_PlayerFuncs.HudMessage(plr, params, "Build Zone: " + g_zone_info.getZoneName(zoneid));
							}
						}
						else
						{
							g_PlayerFuncs.HudMessage(plr, params, "Build Zone: Outskirts\n(Building not allowed)");
						}
						
						if (!g_invasion_mode and !g_creative_mode and !g_shared_build_points_in_pvp_mode)
						{
							params.x = 0.8;
							params.channel = 0;
							int maxPoints = state.maxPoints(zoneid);
							g_PlayerFuncs.HudMessage(plr, params,	"Build Points:\n" + (maxPoints-state.getNumParts(zoneid)) + " / " + maxPoints);
						}
					}
					if (g_creative_mode or g_invasion_mode or g_shared_build_points_in_pvp_mode)
					{
						params.x = 0.8;
						params.channel = 0;
						int total = state.getNumParts((g_creative_mode or g_shared_build_points_in_pvp_mode) ? zoneid : -1337);
						int left = g_zone_info.partsPerZone - total;
						g_PlayerFuncs.HudMessage(plr, params, "Build Points:\n" + left + " / " + g_zone_info.partsPerZone);
						
					}
				}
			}	
			updateBuildPlaceholder();
		}
		pev.nextthink = g_Engine.time + 0.05f;
	}
	
	CBasePlayer@ getPlayer()
	{
		CBaseEntity@ e_plr = self.m_hPlayer;
		return cast<CBasePlayer@>(e_plr);
	}
	
	bool Build()
	{
		CBaseEntity@ buildEnt = h_buildEnt;
		CBaseEntity@ buildEnt2 = h_buildEnt2;
		CBaseEntity@ attachEnt = h_attachEnt;
		CBasePlayer@ plr = getPlayer();
		PlayerState@ state = getPlayerState(plr);
		
		updateBuildPlaceholder();
		
		bool buildingBoat = buildType == E_BOAT_WOOD or buildType == E_BOAT_METAL;
		
		if (buildType == B_LADDER or buildType == B_LADDER_HATCH)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "Ladders are disabled until\nthe crash bug in sven is fixed.");
			return false;
		}
		
		if (buildEnt !is null and forbidden)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "Building blocked by tool cupboard");
			return false;
		}
		
		if (g_invasion_mode and g_wave_in_progress)
		{
			g_PlayerFuncs.PrintKeyBindingString(plr, "Building not allowed during an invasion");
			return false;
		}
		
		if (buildEnt !is null && validBuild) 
		{
			int buildPointCost = 1;
			if (buildType == B_WOOD_SHUTTERS or buildType == B_LADDER_HATCH)
				buildPointCost = 2;
						
			if (g_invasion_mode)
			{
				func_build_zone@ zone = cast<func_build_zone@>(CastToScriptClass(g_invasion_zone.GetEntity()));
				if (zone.id != zoneid)
				{
					g_PlayerFuncs.PrintKeyBindingString(plr, "Can't build outside of start zone");
					return false;
				}
			}
			if (!g_build_anywhere)
			{
				if (zoneid == -1 and !buildingBoat)
				{
					g_PlayerFuncs.PrintKeyBindingString(plr, "Building not allowed in outskirts");
					return false;
				}
				if (state.home_zone == -1 and !g_invasion_mode and !g_creative_mode and !g_shared_build_points_in_pvp_mode)
				{
					BuildZone@ zone = getBuildZone(zoneid);
					int needSpace = state.team !is null ? state.team.members.size() : 1;
					if (zone.maxSettlers - zone.numSettlers >= needSpace)
					{
						zone.numSettlers += needSpace;
						state.home_zone = zoneid;
						
						string msg = "Zone " + zoneid + " is now your home. You can build a permanent base here.\n";
						if (state.team !is null)
						{
							state.team.sendMessage(msg);
							state.team.setHomeZone(zoneid);
						}
						else
							g_PlayerFuncs.SayText(plr, msg);
						
						int previousRaiderParts = state.getNumParts(zoneid);
						zone.addRaiderParts(-previousRaiderParts); // parts built by this player no longer count as raider parts
					}
					else
					{
						println("Too many settlers in zone");
						//g_PlayerFuncs.SayText(plr, "This zone has too many settlers.");
					}
				}
				int zonePartTotal = g_invasion_mode ? -1337 : zoneid;
				if (state.getNumParts(zonePartTotal) + buildPointCost > state.maxPoints(zonePartTotal) and !buildingBoat)
				{
					g_PlayerFuncs.PrintKeyBindingString(plr, "You're out of build points!\n\nFuse your parts (Hammer) for more points.");
					return false;
				}
				
				if (!g_free_build)
				{
					string cost = "";
					if (alternateBuild)
					{
						Item@ itemCost = getItemByClassname(g_part_info[buildType].copy_ent);
						if (getItemCount(plr, itemCost.type, false, true) > 0)
						{
							giveItem(plr, itemCost.type, -1);
							cost = "-1 " + itemCost.title;
						}
					}
					else
					{
						if (getItemCount(plr, BUILD_MATERIAL, false, true) < g_part_info[buildType].cost)
						{
							g_PlayerFuncs.PrintKeyBindingString(plr, "You need more " + g_items[BUILD_MATERIAL].title);
							return false;
						}
						cost = "-" + g_part_info[buildType].cost + " " + g_items[BUILD_MATERIAL].title;
					}
					
					HUDTextParams params;
					params.x = -1;
					params.y = -1;
					params.effect = 0;
					params.r1 = 255;
					params.g1 = 255;
					params.b1 = 255;
					params.fadeinTime = 0;
					params.fadeoutTime = 0.5f;
					params.holdTime = 0.5f;
					params.channel = 2;
				
					g_PlayerFuncs.HudMessage(plr, params, cost);
					giveItem(plr, BUILD_MATERIAL, -g_part_info[buildType].cost, false);
				}
				
				if (!buildingBoat)
				{
					if ((zoneid != state.home_zone and !g_invasion_mode) or g_creative_mode or g_shared_build_points_in_pvp_mode)
						getBuildZone(zoneid).addRaiderParts(buildPointCost);
				}
			}
		
			plr.SetAnimation( PLAYER_ATTACK1 );
			
			string brushModel = buildEnt.pev.model;
			int buildSocket = socketType(buildEnt.pev.colormap);
			int parent = -1;
			
			if (buildSocket == SOCKET_DOORWAY or buildType == B_WOOD_SHUTTERS or buildType == B_LADDER or 
				buildSocket == SOCKET_WINDOW or isFloorItem(buildEnt))
			{
				parent = attachEnt.pev.team;
			}
			
			string soundFile = nextSnd == 0 ? "rust/build1.ogg" : "rust/build2.ogg";
			nextSnd = 1 - nextSnd;
			
			
				
			if (buildType == B_WOOD_DOOR or buildType == B_METAL_DOOR or buildType == B_LADDER_HATCH)
				showTip(EHandle(plr), TIP_LOCK_DOOR);
			else if (buildType == B_LADDER_HATCH)
				showTip(EHandle(plr), TIP_LOCK_HATCH);
			else if (buildType == B_CODE_LOCK)
				showTip(EHandle(plr), TIP_CODE);
			else if (buildType == B_FURNACE)
				showTip(EHandle(plr), TIP_FURNACE);
			else if (buildType == B_TOOL_CUPBOARD)
				showTip(EHandle(plr), TIP_AUTH);
			else if (buildType == B_SMALL_CHEST or buildType == B_LARGE_CHEST)
				showTip(EHandle(plr), TIP_CHEST_ITEMS);
			else
			{
				if (Math.RandomLong(0, 20) == 0)
					showTip(EHandle(plr), TIP_HAMMER);
				if (state.tips & TIP_HAMMER != 0 and Math.RandomLong(0, 20) == 0)
					showTip(EHandle(plr), TIP_SLEEP);
				if (state.tips & TIP_CUPBOARD != 0 and Math.RandomLong(0, 40) == 0)
					showTip(EHandle(plr), TIP_CUPBOARD);
			}
			
			if (buildType == B_WOOD_DOOR) soundFile = "rust/door_wood_place.ogg";
			if (buildType == B_METAL_DOOR) soundFile = "rust/door_metal_place.ogg";
			if (buildType == B_WOOD_BARS) soundFile = "rust/bars_wood_place.ogg";
			if (buildType == B_METAL_BARS) soundFile = "rust/bars_metal_place.ogg";			
			if (buildType == B_CODE_LOCK) soundFile = "rust/code_lock_place.ogg";					
			if (buildType == B_TOOL_CUPBOARD) soundFile = "rust/tool_cupboard_place.ogg";					
			if (buildType == B_LADDER) soundFile = "rust/ladder_place.ogg";					
			if (buildType == B_LADDER_HATCH) soundFile = "rust/ladder_hatch_place.ogg";					
			if (buildType == B_HIGH_STONE_WALL) soundFile = "rust/high_wall_place_stone.ogg";					
			if (buildType == B_HIGH_WOOD_WALL) soundFile = "rust/high_wall_place_wood.ogg";					
			
			if (buildType == B_CODE_LOCK and attachEnt !is null)
			{
				// just change door model
				attachEnt.pev.button = 1; // indicates that the door has a lock
				lock_object(attachEnt, "", true);
				respawnPart(attachEnt.pev.team); // for some reason the wrong button textures is used at first
				
				g_SoundSystem.PlaySound(attachEnt.edict(), CHAN_STATIC, soundFile, 1.0f, 1.0f, 0, 90 + Math.RandomLong(0, 20));
				return true;
			}
		
			float health = 100;			
			switch(buildType)
			{
				case B_FIRE: 
				case E_BOAT_WOOD:
					health = 100; break;
				case B_BED: 
				case B_SMALL_CHEST: 
				case B_WOOD_SHUTTERS:
					health = 200; break;
				case E_BOAT_METAL:
					health = 500; break;
				case B_WOOD_DOOR: health = 1500; break;
				case B_METAL_DOOR: health = 3000; break;
				case B_WOOD_BARS: health = 1500; break;
				case B_METAL_BARS: health = 3000; break;
				case B_HIGH_WOOD_WALL: health = 4500; break;
				case B_HIGH_STONE_WALL: health = 7000; break;
				case B_LADDER_HATCH: health = 4000; break;
				default: health = 500;
			}
			if (buildType <= B_FOUNDATION_STEPS)
				health = 30; // twig materials
		
			Vector origin = buildEnt.pev.origin;				
			dictionary keys;
			string buildCname = buildingBoat ? "func_vehicle_custom" : "func_breakable_custom";
			keys["origin"] = origin.ToString();
			keys["angles"] = buildEnt.pev.angles.ToString();
			keys["model"] = brushModel;
			keys["colormap"] = "" + buildEnt.pev.colormap;
			keys["material"] = "1";
			keys["target"] = "break_part_script";
			keys["fireonbreak"] = "break_part_script";
			keys["zoneid"] = "" + zoneid;
			keys["health"] = "" + health;
			keys["max_health"] = "" + health;
			keys["rendermode"] = "4";
			keys["renderamt"] = "255";
			keys["id"] = "" + g_part_id;
			keys["parent"] = "" + parent;
			keys["frame"] = "2";
			//keys["effects"] = "512";
			
			if (buildingBoat)
			{
				keys["rendermode"] = "4";
				keys["renderamt"] = "255";
				keys["length"] = "270";
				keys["width"] = "64";
				keys["height"] = "40";
				keys["acceleration"] = "0.000001";
				keys["speed"] = "1200";
				keys["sounds"] = "6";
				keys["bank"] = "3";
				keys["material"] = "0";
				keys["volume"] = "7";
				if (buildType == E_BOAT_METAL)
				{
					keys["speed"] = "1600";
					keys["material"] = "2";
				}
				
				CBaseEntity@ boat = getBoatByOwner(plr);
				if (boat !is null) {
					g_PlayerFuncs.PrintKeyBindingString(plr, "You can only have one boat");
					boat.TakeDamage(plr.pev, plr.pev, boat.pev.health, DMG_GENERIC);
				}
				deleteExtraBoats();
			}
				
			if (buildSocket == SOCKET_DOORWAY or buildType == B_WOOD_SHUTTERS)
			{
				keys["distance"] = "9999";
				keys["speed"] = "0.00000001";
				keys["breakable"] = "1";
				keys["targetname"] = "locked" + g_part_id;
			}
			
			if (buildType == B_LADDER_HATCH)
				keys["model"] = getModelFromName("b_ladder_hatch_frame");
			
			g_EngineFuncs.MakeVectors(buildEnt.pev.angles);
			
			CBaseEntity@ ent = null;
			if (buildType == B_WOOD_SHUTTERS)
			{
				keys["origin"] = (buildEnt.pev.origin + g_Engine.v_right*47).ToString();
				keys["model"] = getModelFromName("b_wood_shutter_l");
				@ent = g_EntityFuncs.CreateEntity("func_breakable_custom", keys, true);	
				
				keys["origin"] = (buildEnt.pev.origin + g_Engine.v_right*-47).ToString();
				keys["model"] = getModelFromName("b_wood_shutter_l");
				keys["angles"] = (buildEnt.pev.angles + Vector(0,180,0)).ToString();
				CBaseEntity@ ent2 = g_EntityFuncs.CreateEntity("func_breakable_custom", keys, true);	
				
				ent.pev.vuser1 = ent.pev.angles;
				ent.pev.vuser2 = ent.pev.angles + Vector(0,-150,0);
				
				ent2.pev.vuser1 = ent2.pev.angles;
				ent2.pev.vuser2 = ent2.pev.angles + Vector(0,150,0);	
				
				g_SoundSystem.PlaySound(ent.edict(), CHAN_STATIC, "rust/shutters_wood_place.ogg", 1.0f, 1.0f, 0, 90 + Math.RandomLong(0, 20));
				
				g_build_parts.insertLast(EHandle(ent));
				g_build_parts.insertLast(EHandle(ent2));
				g_part_id++;
				
				state.addPart(ent, zoneid);
				state.addPart(ent2, zoneid);
			}
			else
			{				
				@ent = g_EntityFuncs.CreateEntity(buildCname, keys, true);
				EHandle h_ent = ent;
				
				// remove bushes
				CBaseEntity@ bush = null;
				do {
					@bush = g_EntityFuncs.FindEntityInSphere(bush, ent.pev.origin, 128.0f, "bush", "targetname");
					if (bush !is null)
					{
						g_EntityFuncs.Remove(bush);
					}
				} while (bush !is null);
				
				if (buildingBoat)
					g_boats.insertLast(h_ent);
				else
					g_build_parts.insertLast(h_ent);
				
				build_effect(ent.pev.origin);
				
				g_SoundSystem.PlaySound(ent.edict(), CHAN_STATIC, soundFile, 1.0f, 1.0f, 0, 90 + Math.RandomLong(0, 20));
				
				g_part_id++;
				state.addPart(ent, zoneid);
				
				if (buildType == B_TOOL_CUPBOARD) {
					g_tool_cupboards.insertLast(h_ent);
				}
				
				if (buildType == B_LADDER) {
					ent.pev.rendermode = kRenderTransAlpha;
					ent.pev.renderamt = 255;
					keys["model"] = getModelFromName("b_ladder_box");
					keys["parent"] = "" + (g_part_id - 1);
					
					CBaseEntity@ ent2 = g_EntityFuncs.CreateEntity("func_ladder", keys, true);
					ent2.pev.colormap = buildEnt.pev.colormap;
					ent2.pev.team = g_part_id - 1;
					g_build_items.insertLast(EHandle(ent2));
				}
				
				if (buildType == B_LADDER_HATCH) {
					keys["origin"] = (buildEnt.pev.origin + g_Engine.v_forward*32 + Vector(0,0,-4)).ToString();
					keys["model"] = getModelFromName("b_ladder_hatch_door");
					keys["distance"] = "9999";
					keys["speed"] = "0.00000001";
					keys["breakable"] = "1";
					keys["targetname"] = "locked" + g_part_id;
					keys["parent"] = "" + (g_part_id - 1);
					CBaseEntity@ ent2 = g_EntityFuncs.CreateEntity("func_breakable_custom", keys, true);	
					g_build_parts.insertLast(EHandle(ent2));
					
					ent2.pev.rendermode = kRenderTransAlpha;
					ent2.pev.renderamt = 255;
					
					ent2.pev.vuser1 = buildEnt.pev.angles;
					ent2.pev.vuser2 = buildEnt.pev.angles + Vector(-82,0,0);
					
					keys["origin"] = (buildEnt.pev.origin + g_Engine.v_forward*32).ToString();
					keys["model"] = getModelFromName("b_ladder_hatch_ladder");
					keys["targetname"] = "ladder_hatch" + (g_part_id - 1);
					keys["spawnflags"] = "1"; // start off
					CBaseEntity@ ent3 = g_EntityFuncs.CreateEntity("func_ladder", keys, true);	
					ent3.pev.team = g_part_id - 1;
					g_build_items.insertLast(EHandle(ent3));
					
					state.addPart(ent2, zoneid);
				}
				
				if (buildSocket == SOCKET_DOORWAY)
				{
					ent.pev.vuser1 = buildEnt.pev.angles;
					ent.pev.vuser2 = buildEnt.pev.angles + Vector(0,-95,0);
				}
				
				// conditional roof side wall
				bool wallSocket = buildEnt.pev.colormap == B_WALL or buildEnt.pev.colormap == B_WINDOW or buildEnt.pev.colormap == B_DOORWAY;
				if (buildEnt.pev.colormap == B_ROOF)
				{
					updateRoofWalls(ent);
					
					g_EngineFuncs.MakeVectors(buildEnt.pev.angles);
					Vector roofCheckR = buildEnt.pev.origin + g_Engine.v_right*128;
					Vector roofCheckL = buildEnt.pev.origin + -g_Engine.v_right*128;
					
					bool hasRoofL = false;
					bool hasRoofR = false;
					CBaseEntity@ roofR = getPartAtPos(roofCheckR);
					hasRoofR = roofR !is null and roofR.pev.colormap == B_ROOF;

					CBaseEntity@ roofL = getPartAtPos(roofCheckL);
					hasRoofL = roofL !is null and roofL.pev.colormap == B_ROOF;
					
					if (hasRoofL) {
						updateRoofWalls(roofL);
					}
					if (hasRoofR) {
						updateRoofWalls(roofR);
					}
					
				}
				else if (wallSocket)
				{
					g_EngineFuncs.MakeVectors(buildEnt.pev.angles);
					Vector roofCheckR = buildEnt.pev.origin + g_Engine.v_forward*64 + Vector(0,0,192);
					Vector roofCheckL = buildEnt.pev.origin + -g_Engine.v_forward*64 + Vector(0,0,192);
					
					bool hasRoofL = false;
					bool hasRoofR = false;
					CBaseEntity@ roofR = getPartAtPos(roofCheckR);
					hasRoofR = roofR !is null and roofR.pev.colormap == B_ROOF;

					CBaseEntity@ roofL = getPartAtPos(roofCheckL);
					hasRoofL = roofL !is null and roofL.pev.colormap == B_ROOF;
					
					if (hasRoofL) {
						updateRoofWalls(roofL);
					}
					if (hasRoofR) {
						updateRoofWalls(roofR);
					}
				}
			}
			return true;
		}
		return false;
	}
	
	bool HasAnyItems()
	{
		if (g_free_build)
			return true;
		CBasePlayer@ plr = getPlayer();
		for (int i = B_TYPES; i < B_ITEM_TYPES; i++)
		{
			Item@ item = getItemByClassname(g_part_info[i].copy_ent);
			if (getItemCount(plr, item.type, false, true) > 0)
				return true;
		}
		return false;
	}
	
	bool Cycle(int direction)
	{
		CBasePlayer@ plr = getPlayer();
		
		if (alternateBuild)
		{
			bool hasAnyItems = false;
			for (int i = 0; i < B_ITEM_TYPES-B_TYPES; i++)
			{
				buildType += direction;		
			
				if (buildType < B_TYPES) {
					buildType = B_ITEM_TYPES - 1;
				}
				else if (buildType >= B_ITEM_TYPES) {
					buildType = B_TYPES;
				}
				
				if (g_free_build)
					break;

				Item@ item = getItemByClassname(g_part_info[buildType].copy_ent);
				if (getItemCount(plr, item.type, false, true) > 0)
				{
					hasAnyItems = true;
					break;
				}
			}
			if (!hasAnyItems and !g_free_build)
				return false;
		}
		else
		{
			buildType += direction;
			if (buildType >= B_TYPES) {
				buildType = 0;
			}
			if (buildType < 0) {
				buildType = B_TYPES - 1;
			}
		}
		
		createBuildEnts();
		lastLookOri = Vector(0,0,0);
		updateBuildPlaceholder();
		return true;
	}
	
	void PrimaryAttack()  
	{
		CBasePlayer@ plr = getPlayer();
		if (canShootAgain) 
		{
			bool buildSuccess = Build();
			if (buildSuccess and !g_free_build and alternateBuild)
			{
				CheckItemMode(0);
			}
			if (!buildSuccess)
				g_SoundSystem.PlaySound(plr.edict(), CHAN_ITEM, "items/medshotno1.wav", 1.0f, 1.0f, 0, 130);
			canShootAgain = false;
		}
	}
	
	void SecondaryAttack() 
	{ 
		if (nextCycle < g_Engine.time) {
			Cycle(1);
			canShootAgain = false;
			nextCycle = g_Engine.time + 0.3f;
		}
	}
	
	void TertiaryAttack()  
	{ 
		if (nextCycle < g_Engine.time) {
			Cycle(-1);
			canShootAgain = false;
			nextCycle = g_Engine.time + 0.3f;
		}
	}
	
	bool CheckItemMode(int oldBuildType)
	{
		if (g_free_build)
			return true;
		CBasePlayer@ plr = getPlayer();
		if (!HasAnyItems()) // make sure we have any items
		{
			nextAlternate = 0;
			SwitchMode(oldBuildType);
			g_PlayerFuncs.PrintKeyBindingString(plr, "No items to place");
			return false;
		}
		else
		{
			Item@ item = getItemByClassname(g_part_info[buildType].copy_ent);
			if (getItemCount(plr, item.type, false, true) == 0)
				Cycle(1);
		}
		return true;
	}
	
	void SwitchMode(int initialType=0)
	{
		if (nextAlternate < g_Engine.time)
		{
			alternateBuild = !alternateBuild;
			nextAlternate = g_Engine.time + 0.3f;

			if (alternateBuild)
			{
				int oldBuildType = buildType;
				buildType = B_TYPES;
				if (!CheckItemMode(oldBuildType))
					return;
				createBuildEnts();
				updateBuildPlaceholder(true);
				g_PlayerFuncs.PrintKeyBindingString(getPlayer(), "Item Placement Mode");
			}
			else
			{
				buildType = initialType;
				createBuildEnts();
				updateBuildPlaceholder(true);
				g_PlayerFuncs.PrintKeyBindingString(getPlayer(), "Construction Mode");
			}
		}
	}
	
	void Reload()
	{
		SwitchMode();
	}

	void WeaponIdle()
	{		
		if( self.m_flTimeWeaponIdle > WeaponTimeBase())
			return;

		self.SendWeaponAnim( 0, 0, 0 );
		self.m_flTimeWeaponIdle = WeaponTimeBase() + 10; // how long till we do this again.
	}
}
