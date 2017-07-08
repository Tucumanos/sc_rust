void print(string text) { g_Game.AlertMessage( at_console, text); }
void println(string text) { print(text + "\n"); }

class Color
{ 
	uint8 r, g, b, a;
	Color() { r = g = b = a = 0; }
	Color(uint8 r, uint8 g, uint8 b) { this.r = r; this.g = g; this.b = b; this.a = 255; }
	Color(uint8 r, uint8 g, uint8 b, uint8 a) { this.r = r; this.g = g; this.b = b; this.a = a; }
	Color(float r, float g, float b, float a) { this.r = uint8(r); this.g = uint8(g); this.b = uint8(b); this.a = uint8(a); }
	Color (Vector v) { this.r = uint8(v.x); this.g = uint8(v.y); this.b = uint8(v.z); this.a = 255; }
	string ToString() { return "" + r + " " + g + " " + b + " " + a; }
	Vector getRGB() { return Vector(r, g, b); }
}

Color RED    = Color(255,0,0);
Color GREEN  = Color(0,255,0);
Color BLUE   = Color(0,0,255);
Color YELLOW = Color(255,255,0);
Color ORANGE = Color(255,127,0);
Color PURPLE = Color(127,0,255);
Color PINK   = Color(255,0,127);
Color TEAL   = Color(0,255,255);
Color WHITE  = Color(255,255,255);
Color BLACK  = Color(0,0,0);
Color GRAY  = Color(127,127,127);

void te_beampoints(Vector start, Vector end, string sprite="sprites/laserbeam.spr", uint8 frameStart=0, uint8 frameRate=100, uint8 life=1, uint8 width=1, uint8 noise=0, Color c=GREEN, uint8 scroll=32, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);m.WriteByte(TE_BEAMPOINTS);m.WriteCoord(start.x);m.WriteCoord(start.y);m.WriteCoord(start.z);m.WriteCoord(end.x);m.WriteCoord(end.y);m.WriteCoord(end.z);m.WriteShort(g_EngineFuncs.ModelIndex(sprite));m.WriteByte(frameStart);m.WriteByte(frameRate);m.WriteByte(life);m.WriteByte(width);m.WriteByte(noise);m.WriteByte(c.r);m.WriteByte(c.g);m.WriteByte(c.b);m.WriteByte(c.a);m.WriteByte(scroll);m.End(); }
void te_smoke(Vector pos, string sprite="sprites/steam1.spr", int scale=10, int frameRate=15, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);m.WriteByte(TE_SMOKE);m.WriteCoord(pos.x);m.WriteCoord(pos.y);m.WriteCoord(pos.z);m.WriteShort(g_EngineFuncs.ModelIndex(sprite));m.WriteByte(scale);m.WriteByte(frameRate);m.End(); }
void te_projectile(Vector pos, Vector velocity, CBaseEntity@ owner=null, 
	string model="models/grenade.mdl", uint8 life=1, 
	NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null)
{
	int ownerId = owner is null ? 0 : owner.entindex();
	NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);
	m.WriteByte(TE_PROJECTILE);
	m.WriteCoord(pos.x);
	m.WriteCoord(pos.y);
	m.WriteCoord(pos.z);
	m.WriteCoord(velocity.x);
	m.WriteCoord(velocity.y);
	m.WriteCoord(velocity.z);
	m.WriteShort(g_EngineFuncs.ModelIndex(model));
	m.WriteByte(life);
	m.WriteByte(ownerId);
	m.End();
}


Vector2D getPerp(Vector2D v) {
	return Vector2D(-v.y, v.x);
}

bool vecEqual(Vector v1, Vector v2)
{
	return abs(v1.x - v2.x) < EPSILON and abs(v1.y - v2.y) < EPSILON and abs(v1.z - v2.z) < EPSILON;
}

// convert output from Vector.ToString() back into a Vector
Vector parseVector(string s) {
	array<string> values = s.Split(",");
	Vector v(0,0,0);
	if (values.length() > 0) v.x = atof( values[0] );
	if (values.length() > 1) v.y = atof( values[1] );
	if (values.length() > 2) v.z = atof( values[2] );
	return v;
}

array<float> rotationMatrix(Vector axis, float angle)
{
	axis = axis.Normalize();
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
 
	array<float> mat = {
		oc * axis.x * axis.x + c,          oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
		oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c,          oc * axis.y * axis.z - axis.x * s, 0.0,
		oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c,			 0.0,
		0.0,                               0.0,                               0.0,								 1.0
	};
	return mat;
}

// multiply a matrix with a vector (assumes w component of vector is 1.0f) 
Vector matMultVector(array<float> rotMat, Vector v)
{
	Vector outv;
	outv.x = rotMat[0]*v.x + rotMat[4]*v.y + rotMat[8]*v.z  + rotMat[12];
	outv.y = rotMat[1]*v.x + rotMat[5]*v.y + rotMat[9]*v.z  + rotMat[13];
	outv.z = rotMat[2]*v.x + rotMat[6]*v.y + rotMat[10]*v.z + rotMat[14];
	return outv;
}

CBaseEntity@ getPartAtPos(Vector pos, float dist=2)
{
	CBaseEntity@ ent = null;
	do {
		@ent = g_EntityFuncs.FindEntityInSphere(ent, pos, dist, "func_breakable_custom", "classname");
		if (ent !is null)
		{
			return ent;
		}
	} while (ent !is null);
	return null;
	/*
	// slower even without sqrt
	float d = dist*dist;
	for (uint i = 0; i < g_build_parts.length(); i++)
	{
		if (g_build_parts[i].ent)
		{
			CBaseEntity@ ent = g_build_parts[i].ent;
			
			if ((ent.pev.origin - pos).Length() < dist)
			{
				return ent;
			}
		}
	}
	return null;
	*/
}

func_breakable_custom@ castToPart(EHandle h_ent)
{
	return cast<func_breakable_custom@>(CastToScriptClass(h_ent.GetEntity()));
}

func_breakable_custom@ getBuildPartByID(int id)
{
	for (uint i = 0; i < g_build_parts.size(); i++)
	{
		func_breakable_custom@ part = cast<func_breakable_custom@>(CastToScriptClass(g_build_parts[i].GetEntity()));
		if (part.id == id)
		{
			return @part;
		}
	}
	return null;
}

array<EHandle> getPartsByID(int id)
{
	array<EHandle> ents;
	for (uint i = 0; i < g_build_parts.size(); i++)
	{	
		func_breakable_custom@ part = cast<func_breakable_custom@>(CastToScriptClass(g_build_parts[i].GetEntity()));
		if (part !is null and part.id == id) 
			ents.insertLast(g_build_parts[i]);
	}
	for (uint i = 0; i < g_build_items.size(); i++)
	{	
		CBaseEntity@ part = g_build_items[i].GetEntity();
		if (part !is null and part.pev.team == id) 
			ents.insertLast(g_build_items[i]);
	}
	return ents;
}

array<EHandle> getPartsByParent(int parent)
{
	array<EHandle> ents;
	for (uint i = 0; i < g_build_parts.size(); i++)
	{	
		func_breakable_custom@ part = cast<func_breakable_custom@>(CastToScriptClass(g_build_parts[i].GetEntity()));
		if (part !is null and part.parent == parent)
			ents.insertLast(g_build_parts[i]);
	}
	return ents;
}

string getModelName(CBaseEntity@ part)
{
	string model;
	g_part_models.get(string(part.pev.model), model);
	return model;
}

string getModelSize(CBaseEntity@ part)
{
	string modelName = getModelName(part);
	if (int(modelName.Find("_1x2")) > 0) return "_1x2";
	if (int(modelName.Find("_1x3")) > 0) return "_1x3";
	if (int(modelName.Find("_1x4")) > 0) return "_1x4";
	if (int(modelName.Find("_2x1")) > 0) return "_2x1";
	if (int(modelName.Find("_2x2")) > 0) return "_2x2";
	if (int(modelName.Find("_3x1")) > 0) return "_3x1";
	if (int(modelName.Find("_4x1")) > 0) return "_4x1";
	
	return "_1x1";
}

string getMaterialType(CBaseEntity@ ent)
{
	string material = "_twig";
	string modelName = getModelName(ent);
	if (int(modelName.Find("_wood")) > 0)
		material = "_wood";
	if (int(modelName.Find("_stone")) > 0)
		material = "_stone";
	if (int(modelName.Find("_metal")) > 0)
		material = "_metal";
	if (int(modelName.Find("_armor")) > 0)
		material = "_armor";
		
	return material;
}

int getModelSizei(CBaseEntity@ part)
{
	string modelName = getModelName(part);
	if (int(modelName.Find("_1x2")) > 0) return 2;
	if (int(modelName.Find("_1x3")) > 0) return 3;
	if (int(modelName.Find("_1x4")) > 0) return 4;
	if (int(modelName.Find("_2x1")) > 0) return 2;
	if (int(modelName.Find("_2x2")) > 0) return 4;
	if (int(modelName.Find("_3x1")) > 0) return 3;
	if (int(modelName.Find("_4x1")) > 0) return 4;
	return 1;
}

CBaseEntity@ respawnPart(int id)
{
	for (uint i = 0; i < g_build_parts.size(); i++)
	{	
		func_breakable_custom@ part = cast<func_breakable_custom@>(CastToScriptClass(g_build_parts[i].GetEntity()));
		if (part !is null and part.id == id) 
		{
			dictionary keys;
			keys["origin"] = part.pev.origin.ToString();
			keys["model"] = string(part.pev.model);
			keys["material"] = "1";
			keys["target"] = "break_part_script";
			keys["fireonbreak"] = "break_part_script";
			keys["rendermode"] = "" + part.pev.rendermode;
			keys["renderamt"] = "" + part.pev.renderamt;
			keys["id"] = "" + id;
			keys["parent"] = "" + part.parent;
			
			CBaseEntity@ ent = g_EntityFuncs.CreateEntity(part.pev.classname, keys, true);
			ent.pev.angles = part.pev.angles;
			ent.pev.team = part.pev.team;
			ent.pev.button = part.pev.button;
			ent.pev.body = part.pev.body;
			ent.pev.vuser1 = part.pev.vuser1;
			ent.pev.vuser2 = part.pev.vuser2;
			ent.pev.groupinfo = part.pev.groupinfo;
			ent.pev.noise1 = part.pev.noise1;
			ent.pev.noise2 = part.pev.noise2;
			ent.pev.noise3 = part.pev.noise3;
			ent.pev.health = part.pev.health;
			ent.pev.max_health = part.pev.max_health;
			ent.pev.colormap = part.pev.colormap;
			
			g_EntityFuncs.SetSize(ent.pev, ent.pev.mins, ent.pev.maxs); // fixes collision somehow :S
			
			g_EntityFuncs.Remove(g_build_parts[i]);
			g_build_parts[i] = ent;
			return @ent;
		}
	}
	return null;
}

// which type of part does this part attach to?
int socketType(int partType)
{				
	switch(partType)
	{
		case B_FOUNDATION: case B_FOUNDATION_STEPS: case B_FOUNDATION_TRI:
			return SOCKET_FOUNDATION;
			
		case B_WALL: case B_WINDOW: case B_DOORWAY: case B_LOW_WALL:
			return SOCKET_WALL;
		
		case B_STAIRS: case B_STAIRS_L:
			return SOCKET_MIDDLE;
		
		case B_WOOD_DOOR: case B_METAL_DOOR:
			return SOCKET_DOORWAY;
			
		case B_WOOD_BARS: case B_METAL_BARS: case B_WOOD_SHUTTERS:
			return SOCKET_WINDOW;
		
		case B_CODE_LOCK:
			return SOCKET_DOOR;
			
		case B_HIGH_WOOD_WALL: case B_HIGH_STONE_WALL:
			return SOCKET_HIGH_WALL;
	}
	return -1;
}

bool isFoundation(CBaseEntity@ ent)
{
	int type = ent.pev.colormap;
	return type == B_FOUNDATION or type == B_FOUNDATION_TRI;
}

bool isTriangular(CBaseEntity@ ent)
{
	int type = ent.pev.colormap;
	return (ent.pev.classname == "func_breakable_custom" or ent.pev.classname == "func_illusionary") and type == B_FOUNDATION_TRI or type == B_FLOOR_TRI;
}

bool isFloorPiece(CBaseEntity@ ent)
{
	int type = ent.pev.colormap;
	return type == B_FOUNDATION or type == B_FLOOR or type == B_FOUNDATION_TRI or type == B_FLOOR_TRI or
			(type == B_LADDER_HATCH and ent.pev.classname == "func_breakable_custom");
}

bool isFloorItem(CBaseEntity@ ent)
{
	return ent.pev.colormap == B_TOOL_CUPBOARD;
}

bool isUpgradable(CBaseEntity@ ent)
{
	int type = ent.pev.colormap;
	int socket = socketType(type);
	return ent.pev.classname == "func_breakable_custom" and socket != SOCKET_WINDOW and type != B_LADDER_HATCH and
			type != B_LADDER and socket != SOCKET_HIGH_WALL and !isFloorItem(ent);
}

bool canPlaceOnTerrain(int partType)
{
	return partType == B_HIGH_WOOD_WALL or partType == B_HIGH_STONE_WALL or partType == B_FOUNDATION;
}

void updateRoofWalls(CBaseEntity@ roof)
{
	if (roof is null)
		return;
	// put walls under roofs when there are no adjacent roofs and there is a wall underneath one/both edges
	string brushModel = roof.pev.model;
	g_EngineFuncs.MakeVectors(roof.pev.angles);
	Vector roofCheckR = roof.pev.origin + g_Engine.v_right*128;
	Vector roofCheckL = roof.pev.origin + g_Engine.v_right*-128;
	Vector wallCheckR = roof.pev.origin + g_Engine.v_right*64 + Vector(0,0,-192);
	Vector wallCheckL = roof.pev.origin + g_Engine.v_right*-64 + Vector(0,0,-192);
	
	CBaseEntity@ wallR = getPartAtPos(wallCheckR);
	bool hasWallR = wallR !is null and 
				(wallR.pev.colormap == B_WALL or wallR.pev.colormap == B_WINDOW or wallR.pev.colormap == B_DOORWAY);

	CBaseEntity@ wallL = getPartAtPos(wallCheckL);
	bool hasWallL = wallL !is null and 
				(wallL.pev.colormap == B_WALL or wallL.pev.colormap == B_WINDOW or wallL.pev.colormap == B_DOORWAY);

	CBaseEntity@ roofR = getPartAtPos(roofCheckR);
	bool hasRoofR = roofR !is null and roofR.pev.colormap == B_ROOF;
		
	CBaseEntity@ roofL = getPartAtPos(roofCheckL);
	bool hasRoofL = roofL !is null and roofL.pev.colormap == B_ROOF;
	
	string material = getMaterialType(roof);
	
	if (hasWallL and hasWallR and !hasRoofL and !hasRoofR) {
		CBaseEntity@ copy_ent = g_EntityFuncs.FindEntityByTargetname(null, "b_roof_wall_both" + material);
		brushModel = copy_ent.pev.model;
	} else if (hasWallL and !hasRoofL) {
		CBaseEntity@ copy_ent = g_EntityFuncs.FindEntityByTargetname(null, "b_roof_wall_left" + material);
		brushModel = copy_ent.pev.model;
	} else if (hasWallR and !hasRoofR) {
		CBaseEntity@ copy_ent = g_EntityFuncs.FindEntityByTargetname(null, "b_roof_wall_right" + material);
		brushModel = copy_ent.pev.model;
	} else {
		CBaseEntity@ copy_ent = g_EntityFuncs.FindEntityByTargetname(null, "b_roof" + material);
		brushModel = copy_ent.pev.model;
	}
	
	int oldcolormap = roof.pev.colormap;
	g_EntityFuncs.SetModel(roof, brushModel);
	roof.pev.colormap = oldcolormap;
}
	
bool forbiddenByCupboard(CBasePlayer@ plr, Vector buildPos)
{
	for (uint i = 0; i < g_tool_cupboards.length(); i++)
	{
		if (g_tool_cupboards[i])
		{
			CBaseEntity@ ent = g_tool_cupboards[i];
			if ((ent.pev.origin - buildPos).Length() < g_tool_cupboard_radius)
			{
				if (!getPlayerState(plr).isAuthed(ent))
					return true;
			}
		}
		else
		{
			g_tool_cupboards.removeAt(i);
			i--;
		}
	}
	return false;
}

TraceResult TraceLook(CBasePlayer@ plr, float dist=128, bool bigHull=false)
{
	Vector vecSrc = plr.GetGunPosition();
	Math.MakeVectors( plr.pev.v_angle ); // todo: monster angles
	
	TraceResult tr;
	Vector vecEnd = vecSrc + g_Engine.v_forward * dist;
	if (bigHull)
		g_Utility.TraceHull( vecSrc, vecEnd, dont_ignore_monsters, head_hull, plr.edict(), tr );
	else
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, plr.edict(), tr );
	return tr;
}

// actual center of the part, not the origin
Vector getCentroid(CBaseEntity@ ent)
{
	array<Vector2D> verts = getBoundingVerts2D(ent, Vector2D(0,0));
	Vector2D centroid2D;
	for (uint i = 0; i < verts.length(); i++)
	{
		centroid2D = centroid2D + verts[i];
	}
	centroid2D = centroid2D / verts.length();
	Vector centroid = Vector(centroid2D.x, centroid2D.y, 0);
	centroid.z = ent.pev.origin.z + ((ent.pev.mins.z + ent.pev.maxs.z) / 2);
	return centroid;
	
}

array<Vector2D> getBoundingVerts2D(CBaseEntity@ ent, Vector2D offset)
{
	Vector angles = ent.pev.angles;
	if (ent.pev.classname == "func_door_rotating")
		angles.y += 180;
		
	// counter-clockwise starting at back right vertex
	array<Vector2D> verts;
	g_EngineFuncs.MakeVectors(angles);
	Vector2D ori = Vector2D(ent.pev.origin.x + offset.x, ent.pev.origin.y + offset.y);
	Vector2D v_forward = Vector2D(g_Engine.v_forward.x, g_Engine.v_forward.y);
	Vector2D v_right = Vector2D(g_Engine.v_right.x, g_Engine.v_right.y);
	verts.insertLast(ori + v_right*-ent.pev.maxs.y + v_forward*ent.pev.mins.x);
	verts.insertLast(ori + v_right*-ent.pev.mins.y + v_forward*ent.pev.mins.x);
	if (isTriangular(ent))
	{
		string size = getModelSize(ent);
		if (size == "_1x1")
		{
			verts.insertLast(ori + v_forward*ent.pev.maxs.x + v_right*-(ent.pev.maxs.y + ent.pev.mins.y));
		}
		else if (size == "_2x2")
		{
			verts.insertLast(ori + v_forward*ent.pev.maxs.x + v_right*64);
		}
		else if (size == "_2x1")
		{
			verts[1] = ori + v_forward*ent.pev.mins.x + v_right*64;
			verts.insertLast(ori + v_forward*ent.pev.maxs.x + v_right*128);
			verts.insertLast(ori + v_forward*ent.pev.maxs.x);
		}
		else if (size == "_3x1")
		{
			verts[1] = ori + v_forward*ent.pev.mins.x + v_right*192;
			verts.insertLast(ori + v_forward*ent.pev.maxs.x + v_right*128);
			verts.insertLast(ori + v_forward*ent.pev.maxs.x);
		}
		else if (size == "_4x1")
		{
			verts[1] = ori + v_forward*ent.pev.mins.x + v_right*192;
			verts.insertLast(ori + v_forward*ent.pev.maxs.x + v_right*256);
			verts.insertLast(ori + v_forward*ent.pev.maxs.x);
		}
		else if (size == "_1x4")
		{
			verts[0] = ori + v_forward*ent.pev.mins.x + v_right*-192;
			verts[1] = ori + v_forward*ent.pev.mins.x + v_right*64;
			verts.insertLast(ori + v_forward*ent.pev.maxs.x);
			verts.insertLast(ori + v_forward*ent.pev.maxs.x + v_right*-256);
		}
	}
	else
	{
		verts.insertLast(ori + v_right*-ent.pev.mins.y + v_forward*ent.pev.maxs.x);
		verts.insertLast(ori + v_right*-ent.pev.maxs.y + v_forward*ent.pev.maxs.x);
	}
	return verts;
}

// collision between 2 oriented 2D boxes using the separating axis theorem 
float collisionSA(CBaseEntity@ b1, CBaseEntity@ b2)
{
	Vector2D b1Ori = Vector2D(b1.pev.origin.x, b1.pev.origin.y);
	Vector2D b2Ori = Vector2D(b2.pev.origin.x, b2.pev.origin.y);
	
	array<Vector2D> b1Verts = getBoundingVerts2D(b1, b1Ori*-1);
	array<Vector2D> b2Verts = getBoundingVerts2D(b2, b1Ori*-1);
	
	int b1NumVerts = b1Verts.length();
	int b2NumVerts = b2Verts.length();
	array<Vector2D> axes(b1NumVerts + b2NumVerts);
	int idx = 0;
	
	for (int i = 1; i < b1NumVerts; i++)
		axes[idx++] = getPerp(b1Verts[i] - b1Verts[i-1]);
	axes[idx++] = getPerp(b1Verts[0] - b1Verts[b1NumVerts-1]);

	for (int i = 1; i < b2NumVerts; i++)
		axes[idx++] = getPerp(b2Verts[i] - b2Verts[i-1]);
	axes[idx++] = getPerp(b2Verts[0] - b2Verts[b2NumVerts-1]);

	float minPen = 1E9; // minimum penetration vector;
	Vector2D fix; // vector for fixing the collision
	float ba1_min = 0;
	float ba1_max = 0;
	float ba2_min = 0;
	float ba2_max = 0;
	
	for (uint a = 0; a < axes.length(); a++)
	{
		fix = axes[a].Normalize();
		
		// project verts on this axis
		ba1_min = 1E9;
		ba1_max = -1E9;
		ba2_min = 1E9;
		ba2_max = -1E9;
		for (int i = 0; i < b1NumVerts; i++)
		{
			float dist = b1Verts[i].x*fix.x + b1Verts[i].y*fix.y; // relative to our origin
			ba1_min = Math.min(ba1_min, dist);
			ba1_max = Math.max(ba1_max, dist);
		}
		for (int i = 0; i < b2NumVerts; i++)
		{
			float dist = b2Verts[i].x*fix.x + b2Verts[i].y*fix.y;
			ba2_min = Math.min(ba2_min, dist);
			ba2_max = Math.max(ba2_max, dist);
		}
		
		if (ba1_min < ba2_max and ba2_min < ba1_max) // collision along this axis!
		{
			if (ba2_max-ba1_min > ba1_max-ba2_min)
			{
				float pen = ba2_min-ba1_max;
				if (abs(pen) < abs(minPen))
					minPen = pen;
			}
			else
			{
				float pen = ba2_max-ba1_min;
				if (abs(pen) < abs(minPen))
					minPen = pen;
			}
		}
		else
		{
			// this is the separating axis!
			return 0;
		}
	}
	
	float overlap = minPen / fix.Length();
	
	if (debug_mode and abs(overlap) > 9.9f)
	{
		for (uint i = 0; i < b1Verts.length(); i++)
			b1Verts[i] = b1Verts[i] + b1Ori;
		for (uint i = 0; i < b2Verts.length(); i++)
			b2Verts[i] = b2Verts[i] + b1Ori;
		
		Vector fix3 = Vector(fix.x, fix.y, 0);
		
		for (uint i = 0; i < b1Verts.length(); i++)
		{
			uint k = (i+1) % b1Verts.length();
			te_beampoints(Vector(b1Verts[i].x, b1Verts[i].y, b1.pev.origin.z + 64), Vector(b1Verts[k].x, b1Verts[k].y, b1.pev.origin.z + 64));
		}
		for (uint i = 0; i < b2Verts.length(); i++)
		{
			uint k = (i+1) % b2Verts.length();
			te_beampoints(Vector(b2Verts[i].x, b2Verts[i].y, b2.pev.origin.z + 64), Vector(b2Verts[k].x, b2Verts[k].y, b2.pev.origin.z + 64));
		}
		
		te_beampoints(b1.pev.origin + Vector(0,0,64), b1.pev.origin + Vector(0,0,64) + fix3.Normalize()*overlap);
		te_beampoints(b1.pev.origin, b2.pev.origin);
	}
	
	return overlap;
}

// special roof collision
bool objectThroughRoof(CBaseEntity@ roof, CBaseEntity@ obj)
{
	Vector pos = obj.pev.origin;
	Vector mins = obj.pev.mins;
	Vector maxs = obj.pev.maxs;
	
	g_EngineFuncs.MakeVectors(obj.pev.angles);
	
	array<Vector> verts;
	verts.insertLast(pos + g_Engine.v_forward*mins.x + g_Engine.v_right*mins.y + g_Engine.v_up*mins.z);
	verts.insertLast(pos + g_Engine.v_forward*mins.x + g_Engine.v_right*mins.y + g_Engine.v_up*maxs.z);
	verts.insertLast(pos + g_Engine.v_forward*mins.x + g_Engine.v_right*maxs.y + g_Engine.v_up*mins.z);
	verts.insertLast(pos + g_Engine.v_forward*mins.x + g_Engine.v_right*maxs.y + g_Engine.v_up*maxs.z);
	verts.insertLast(pos + g_Engine.v_forward*maxs.x + g_Engine.v_right*mins.y + g_Engine.v_up*mins.z);
	verts.insertLast(pos + g_Engine.v_forward*maxs.x + g_Engine.v_right*mins.y + g_Engine.v_up*maxs.z);
	verts.insertLast(pos + g_Engine.v_forward*maxs.x + g_Engine.v_right*maxs.y + g_Engine.v_up*mins.z);
	verts.insertLast(pos + g_Engine.v_forward*maxs.x + g_Engine.v_right*maxs.y + g_Engine.v_up*maxs.z);
	
	g_EngineFuncs.MakeVectors(roof.pev.angles);
	Vector plane = roof.pev.origin;
	Vector normal = (g_Engine.v_forward + g_Engine.v_up).Normalize(); // roof is at perfectly 45 deg angle
	
	te_beampoints(plane + normal*-64, plane + normal*64, "sprites/laserbeam.spr", 0, 100, 1, 1, 0, PURPLE);
	 
	int sign = 0;
	for (int i = 0; i < int(verts.length()); i++)
	{
		float dist = DotProduct(normal, verts[i] - plane);
		sign += dist >= 0 ? 1 : -1;
	}
		
	// were all points on one side of the plane?
	if (abs(sign) != int(verts.length()))
		return true;
		
	// now check against roof side walls, if any exist
	string model = getModelName(roof);
	if (model.Find("roof_wall_left") >= 0 or model.Find("roof_wall_both") >= 0)
	{
		plane = roof.pev.origin + g_Engine.v_right*64;
		normal = (g_Engine.v_right).Normalize();
		sign = 0;
		for (int i = 0; i < int(verts.length()); i++)
		{
			float dist = DotProduct(normal, verts[i] - plane);
			sign += dist >= 0 ? 1 : -1;
		}
		if (abs(sign) != int(verts.length()))
			return true;
	}
	if (model.Find("roof_wall_right") >= 0 or model.Find("roof_wall_both") >= 0)
	{
		plane = roof.pev.origin + g_Engine.v_right*-64;
		normal = (-g_Engine.v_right).Normalize();
		sign = 0;
		for (int i = 0; i < int(verts.length()); i++)
		{
			float dist = DotProduct(normal, verts[i] - plane);
			sign += dist >= 0 ? 1 : -1;
		}
		if (abs(sign) != int(verts.length()))
			return true;
	}
	
	return false;
}

// collision between 2 oriented 3D boxes. Only boxes rotated on the yaw axis are allowed
float collisionBoxesYaw(CBaseEntity@ b1, CBaseEntity@ b2) 
{
	// check vertical collision first
	float min1 = b1.pev.origin.z + b1.pev.mins.z;
	float min2 = b2.pev.origin.z + b2.pev.mins.z;
	float max1 = b1.pev.origin.z + b1.pev.maxs.z;
	float max2 = b2.pev.origin.z + b2.pev.maxs.z;
	
	if (b1.pev.colormap == B_LADDER_HATCH)
		min1 = b1.pev.origin.z - 4;
		
	if (b1.pev.colormap == B_ROOF and isFloorItem(b2))
		return objectThroughRoof(b1, b2) ? 1000 : 0;
	if (b2.pev.colormap == B_ROOF and isFloorItem(b1))
		return objectThroughRoof(b2, b1) ? 1000 : 0;
		
	if (b1.pev.colormap == B_ROOF)
	{
		min1 = b1.pev.origin.z - 60;
		max1 = b1.pev.origin.z + 60;
	}
	if (b2.pev.colormap == B_ROOF)
	{
		min2 = b2.pev.origin.z - 60;
		max2 = b2.pev.origin.z + 60;
	}
	
	if (max1 > min2 and min1 < max2)
	{
		float overlapXY = collisionSA(b1, b2);
		float overlapZ = Math.max(0, Math.min(max1, max2) - Math.max(min1, min2));
		// check 2D top-down collision
		return Math.min(abs(overlapZ), abs(overlapXY));
	}
	return 0;
}

// ported from HLSDK with minor adjustments
void AngularMove( CBaseEntity@ ent, Vector vecDestAngle, float flSpeed )
{	
	Vector m_vecFinalAngle = vecDestAngle;
	
	EHandle h_ent = ent;
	ent.pev.iuser1 = 1;

	// Already there?
	if (vecDestAngle == ent.pev.angles)
	{
		AngularMoveDone(h_ent, m_vecFinalAngle);
		return;
	}
	
	// set destdelta to the vector needed to move
	Vector vecDestDelta = vecDestAngle - ent.pev.angles;
	
	// divide by speed to get time to reach dest
	float flTravelTime = vecDestDelta.Length() / flSpeed;

	// set nextthink to trigger a call to AngularMoveDone when dest is reached
	g_Scheduler.SetTimeout("AngularMoveDone", flTravelTime, h_ent, m_vecFinalAngle);

	// scale the destdelta vector by the time spent traveling to get velocity
	ent.pev.avelocity = vecDestDelta / flTravelTime;
	ent.pev.fixangle = FAM_ADDAVELOCITY;
}

// ported from HLSDK with minor adjustments
void AngularMoveDone( EHandle h_ent, Vector finalAngle )
{
	if (h_ent)
	{
		CBaseEntity@ ent = h_ent;
		ent.pev.iuser1 = 0;
		ent.pev.angles = finalAngle;
		ent.pev.avelocity = g_vecZero;
	}
}

// Will create a new state if the requested one does not exit
PlayerState@ getPlayerState(CBasePlayer@ plr)
{
	string steamId = g_EngineFuncs.GetPlayerAuthId( plr.edict() );
	if (steamId == 'STEAM_ID_LAN') {
		steamId = plr.pev.netname;
	}
	
	if ( !player_states.exists(steamId) )
	{
		PlayerState state;
		state.plr = plr;
		player_states[steamId] = state;
	}
	return cast<PlayerState@>( player_states[steamId] );
}

PlayerState@ getPlayerStateBySteamID(string steamId, string netname)
{
	if (steamId == 'STEAM_ID_LAN') {
		steamId = netname;
	}
	
	if ( player_states.exists(steamId) )
	{
		return cast<PlayerState@>( player_states[steamId] );
	}
	return null;
}

void PrecacheSound(string snd)
{
	g_SoundSystem.PrecacheSound(snd);
	g_Game.PrecacheGeneric("sound/" + snd);
}