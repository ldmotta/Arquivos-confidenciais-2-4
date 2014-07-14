// =========================================================================================================
//  UPSMON - Urban Patrol Script  
//  version 6.0.6.6  
//
//  Author: Monsada (chs.monsada@gmail.com) 
//		Comunidad Hispana de Simulación: 
//
//		Wiki: http://dev-heaven.net/projects/upsmon/wiki


// SERVER OR HEADLESS CLIENT CHECK
//if (!isServer) exitWith {};
if (!isServer && hasInterface ) exitWith {};

if (isNil("KRON_UPS_INIT")) then {
	KRON_UPS_INIT=0;
};

if (isNil("KRON_UPS_Night")) then {
	KRON_UPS_Night = false;
};

waitUntil {KRON_UPS_INIT==1};

// convert argument list to uppercase
	_UCthis = [];
	for [{_i=0},{_i<count _this},{_i=_i+1}] do {
			_e=_this select _i;
			if (typeName _e=="STRING") then {_e=toUpper(_e)};
			_UCthis set [_i,_e]
		};

	if ((count _this)<2) exitWith {
		if (format["%1",_this]!="INIT") then {hint "UPS: Unit and marker name have to be defined!"};
	};
	
// Postioning
private["_waiting","_newpos","_currPos","_orgPos","_targetPos","_attackPos", "_speedmode"];
private["_cntobjs1","_targettext"
		,"_target","_targets","_nomove"
		,"_grpidx","_grpid","_i","_unitpos","_Behaviour","_incar","_inheli" ,"_inboat"
		,"_vehicle","_CombatMode","_rnd","_index","_grp","_i"
		,"_dist1","_bld","_blddist","_bldunitin","_buildingdist"
		,"_enemytanks","_enemytanksnear","_friendlytanksnear","_enemytanknear","_wait","_countfriends","_side","_SURRENDER","_spawned"
		,"_nowp","_unitsIn","_friendside","_enemyside"
		,"_membertypes","_respawn","_respawnmax","_safemode","_vehicles","_template","_nowpType"
		,"_vehicletypes","_newunit","_isSoldier"
		,"_isdiver","_reinforcement","_rfid","_Patrlbld"];

_grpid =0;
_exit = false;
_vehicle = objnull;
_rnd = 0.0;
_index = 0;
_wp=[];
_wptype="HOLD";
_wpformation = "VEE";
_bld = objnull;
_Mines = 3; // org 1 - ToDo set to 4 ?
_enemytanks = [];
_friendlytanks =[];
_enemytanksnear = false;
_friendlytanksnear = false;
_enemytanknear = objnull;
_NearestEnemy = objnull;
_buildingdist = 25;
_wait=90;
_side="";
_friendside=[];
_enemyside=[];
_surrender = 0;
_retreat = 0;
_inheli = false;
_spawned = false;
_nowp = false;
_unitsIn = [];
_membertypes = [];
_vehicletypes =[];
_respawn = false;
_respawnmax = 10000;
_safemode=["CARELESS","SAFE"];
_vehicles = [];
// unit that's moving
_obj = leader (_this select 0); //group or leader

if ( isnil "_obj") exitwith 
{	
	hint format ["Object: %1",_obj];
	diag_log format ["UPSMON: Object for _npc: %1",_obj];
	};
_npc = _obj;


			
if (isnil "_lastcurrpos") then {_lastcurrpos = [0,0,0]};

// give this group a unique index
KRON_UPS_Instances = KRON_UPS_Instances + 1;
_grpid = KRON_UPS_Instances;
_grpidx = format["%1",_grpid];

_grpname = format["%1_%2",(side _npc),_grpidx];
_side = side _npc;


//To not run all at the same time we hope to have as many seconds as id's
_rnd = _grpid;
sleep _rnd ;

_bcombat_running = if (!isNil "bdetect_enable") then {true} else {false};

if (_bcombat_running) then {waitUntil { !(isNil "bdetect_init_done") };};

// == set "UPSMON_grpid" to units in the group and EH===============================  
	{
		_x setVariable ["UPSMON_grpid", _grpid, false];
		_x setVariable ["UPSMON_Ucthis", _Ucthis, false];
		
		sleep 0.05;
		
		
		if (side _x != civilian) then 
		{//soldiers 
			_x AddEventHandler ["hit", {nul = _this spawn R_SN_EHHIT}];	
			sleep 0.05;	
			_x AddEventHandler ["killed", {nul = _this spawn R_SN_EHKILLED}];	
			
		}
		else
		{//civ
			if (! isnil "_x") then {
				//_x removeAllEventHandlers "firedNear"; // removed while this may impact other mods !
				sleep 0.05;
				_x AddEventHandler ["firedNear", {nul = _this spawn R_SN_EHFIREDNEAR}];
				sleep 0.05;
				
				//_x removeAllEventHandlers "killed"; // removed while this may impact other mods !
				sleep 0.05;
				_x AddEventHandler ["killed", {nul = _this spawn R_SN_EHKILLEDCIV}];
				sleep 0.05;
			};
		};
	} foreach units _npc;


//if is vehicle will not be in units so must set manually

	if (isnil {_npc getVariable ("UPSMON_grpid")}) then {		
		_npc setVariable ["UPSMON_grpid", _grpid, false];		
		sleep 0.05;
		
		if (side _npc != civilian) then 
		{ //soldiers
			_npc AddEventHandler ["hit", {nul = _this spawn R_SN_EHHIT}];	
			sleep 0.05;
			_npc AddEventHandler ["killed", {nul = _this spawn R_SN_EHKILLED}];	
	
		}		
		else
		{ //civilian
		//	_npc removeAllEventHandlers "firedNear"; // removed while this may impact other mods !
		//	sleep 0.05;
			_npc AddEventHandler ["firedNear", {nul = _this spawn R_SN_EHFIREDNEAR}];
			sleep 0.05;	
			
			
			
		//	_npc removeAllEventHandlers "killed"; // removed while this may impact other mods !
			sleep 0.05;
			_npc AddEventHandler ["killed", {nul = _this spawn R_SN_EHKILLEDCIV}];
			sleep 0.05;
		};  //=> ; was missing here in previous version!
	};

	//the index will be _grpid  

	
if (KRON_UPS_Debug>0) then {player sidechat format["%1: New instance %2 %3 %4",_grpidx,_npc getVariable ("UPSMON_grpid")]}; 


	




// == get the name of area marker ==============================================
	_areamarker = _this select 1;
	if (isNil ("_areamarker")) exitWith {
		hint "UPS: Area marker not defined.\n(Typo, or name not enclosed in quotation marks?)";
	};	

	// remember center position of area marker
	_centerpos = getMarkerPos _areamarker;
	_centerX = abs(_centerpos select 0);
	_centerY = abs(_centerpos select 1);
	_centerpos = [_centerX,_centerY];

	// show/hide area marker 
	_showmarker = if ("SHOWMARKER" in _UCthis) then {"SHOWMARKER"} else {"HIDEMARKER"};
	if (_showmarker=="HIDEMARKER") then {
		//_areamarker setMarkerCondition "false"; // VBS2
		_areamarker setMarkerPos [-abs(_centerX),-abs(_centerY)];
	};

// is anybody alive in the group?
	_exit = true;

if (KRON_UPS_Debug>0) then {diag_log format["UPSMON - npc [%1] - typename [%2] - typeof [%3] - units [%4]",_npc, typename _npc, typeof _npc, units (group _npc)]; };	
	
	if ( !isNull _npc && { typeName _npc=="OBJECT" } ) then 
	{		
		if (!isNull group _npc) then 
		{
			_npc = ([_npc,units (group _npc)] call MON_getleader);
		}
		else 
		{
			_vehicles = [_npc,2] call MON_nearestSoldiers;
			if (count _vehicles>0) then {
				_npc = [_vehicles select 0,units (_vehicles select 0)] call MON_getleader;
			};
		};
	}
	else 
	{
		if (count _obj>0) then {
			_npc = [_obj,count _obj] call MON_getleader;			
		};
	};
	
	// set the leader in the vehilce
	if (!(_npc iskindof "Man")) then { 
		if (!isnull(commander _npc) ) then {
			_npc = commander _npc;
		}else{
			if (!isnull(driver _npc) ) then {
				_npc = driver _npc;
			}else{			
				_npc = gunner _npc;	
			};	
		};
		group _npc selectLeader _npc;
	};

// ===============================================	
	if (alive _npc) then {_exit = false;};	
	if (KRON_UPS_Debug>0 && _exit) then {player sidechat format["%1 There is no alive members %1 %2 %3",_grpidx,typename _npc,typeof _npc, count units _npc]};	

	
	// exit if something went wrong during initialization (or if unit is on roof)
	if (_exit) exitWith {
		if (KRON_UPS_DEBUG>0) then {hint "Initialization aborted"};
	};



// remember the original group members, so we can later find a new leader, in case he dies
	_members = units _npc;
	KRON_UPS_Total = KRON_UPS_Total + (count _members);

// respawn
	_respawn = if ("RESPAWN" in _UCthis) then {true} else {false};
	_respawn = if ("RESPAWN:" in _UCthis) then {true} else {false};
	_respawnmax = ["RESPAWN:",_respawnmax,_UCthis] call KRON_UPSgetArg;
	if (!_respawn) then {_respawnmax = 0};
//Custom loadout
	_custom = if ("CUSTOM" in _UCthis) then {true} else {false};
	

//Fills member soldier types
	_vehicles = [];
	{	
		if (vehicle _x != _x ) then {
			_vehicles = _vehicles - [vehicle _x];
			_vehicles = _vehicles + [vehicle _x];
		};
		_equipment = [];
		
		If (_custom && _respawn && vehicle _x == _x) then {_equipment = _x call Aze_getequipment};
		_membertypes = _membertypes + [[typeof _x,_equipment]];
	} foreach _members;

//Fills member vehicle types
	{
		_vehicletypes = _vehicletypes + [typeof _x];
	} foreach _vehicles;

// what type of "vehicle" is _npc ?
	_isman = "Man" countType [ vehicle _npc]>0;
	_iscar = "LandVehicle" countType [vehicle _npc]>0;
	_isboat = "Ship" countType [vehicle _npc]>0;
	_isplane = "Air" countType [vehicle _npc]>0;
	_isdiver = ["diver", (typeOf (leader _npc))] call BIS_fnc_inString;
	
	//diag_log format ["UPSMON diver: %1: %2", typeOf (leader _npc), ['diver', (typeOf (leader _npc))] call BIS_fnc_inString];

// we just have to brute-force it for now, and declare *everyone* an enemy who isn't a civilian // ToDo rewrite using getFriend
	_isSoldier = _side != civilian;

	_friends=[];
	_enemies=[];	
	_sharedenemy=0;

	if (_isSoldier) then {
		switch (_side) do {
		case west:
			{ 	_sharedenemy=0; 
				_friendside = [west];
				_enemyside = [east];				
			};
		case east:
			{  _sharedenemy=1; 
				_friendside = [east];
				_enemyside = [west];
			};
		case resistance:
			{ 
			 _sharedenemy=2; 
			 _enemyside = KRON_UPS_Res_enemy;
			 
				if (!(east in _enemyside)) then {	
					_friendside = [east];
				}; 
				if (!(west in _enemyside)) then {
					_friendside = [west];
				};			 
			};
		};
	};
	
	if (_side in KRON_UPS_Res_enemy) then {
		_enemyside = _enemyside + [resistance];
	}else {
		_friendside = _friendside + [resistance];	
	};
	sleep .05;

//Sets min units alive for surrender
if !( _side == civilian ) then 
{ 
	_surrender = call (compile format ["KRON_UPS_%1_SURRENDER",_side]); 
	_retreat = call (compile format ["KRON_UPS_%1_SURRENDER",_side]); 
};

	
	// Tanks friendlys are contabiliced
{
	if ( side _x in _friendside && ( _x iskindof "Tank"  || _x iskindof "Wheeled_APC" )) then {
		_friendlytanks = _friendlytanks + [_x];
	};
}foreach vehicles;	

// global unit variable to externally influence script 
//call compile format ["KRON_UPS_%1=1",_npcname];

// X/Y range of target area
_areasize = getMarkerSize _areamarker;
_rangeX = _areasize select 0;
_rangeY = _areasize select 1;
_area = abs((_rangeX * _rangeY) ^ 0.5);
// marker orientation (needed as negative value!)
_areadir = (markerDir _areamarker) * -1;


// store some trig calculations
_cosdir=cos(_areadir);
_sindir=sin(_areadir);


// remember the original mode & speed
_orgMode = "SAFE";
_orgSpeed = speedmode _npc;

// set first target to current position (so we'll generate a new one right away)
_currPos = getpos _npc;
_orgPos = _currPos;
_orgDir = getDir _npc;
_orgWatch=[_currPos,50,_orgDir] call KRON_relPos; 
_lastpos = _currPos;


_speedmode=_orgSpeed;
_cntobjs1 = 0;
_targettext ="";
_target = objnull;

_flankdir=0; //1 tendencia a flankpos1, 2 tendencia a flankpos2
_targets=[];
_fortify = false;
_buildingdist= 25;//Distance to search buildings near
_Behaviour = _orgMode; 
_grp = grpnull;
_grp = group _npc;
_template = 0;
_nowpType = 1;
_rfid = 0;
_reinforcement = false;
_RadioRange = 8000;

// remember the original mode & speed
_orgMode = "SAFE";
_orgSpeed = speedmode _npc;
_speedmode=_orgSpeed;

_waiting = 0;
_positiontoambush = [0,0,0];
_Patrlbld = false;


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ***************************************** optional arguments *****************************************************************//
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// set If enemy detected reinforcements will be sent REIN1
_rfid = ["REINFORCEMENT:",0,_UCthis] call KRON_UPSgetArg; // rein_#
_reinforcement= if ("REINFORCEMENT" in _UCthis) then {"REINFORCEMENT"} else {"NOREINFORCEMENT"}; //rein_yes
If (_reinforcement == "REINFORCEMENT") then {
	switch (_side) do {
		case West: {
		if (isnil "KRON_UPS_REINFORCEMENT_WEST_UNITS") then  {KRON_UPS_REINFORCEMENT_WEST_UNITS = []};
		KRON_UPS_REINFORCEMENT_WEST_UNITS = KRON_UPS_REINFORCEMENT_WEST_UNITS + [_npc];
		PublicVariable "KRON_UPS_REINFORCEMENT_WEST_UNITS";		
		};
		case EAST: {
		if (isnil "KRON_UPS_REINFORCEMENT_EAST_UNITS") then  {KRON_UPS_REINFORCEMENT_EAST_UNITS = []};
		KRON_UPS_REINFORCEMENT_EAST_UNITS = KRON_UPS_REINFORCEMENT_EAST_UNITS + [_npc];
		PublicVariable "KRON_UPS_REINFORCEMENT_EAST_UNITS";	
		};
		case GUER: {
		if (isnil "KRON_UPS_REINFORCEMENT_GUER_UNITS") then  {KRON_UPS_REINFORCEMENT_GUER_UNITS = []};
		KRON_UPS_REINFORCEMENT_GUER_UNITS = KRON_UPS_REINFORCEMENT_GUER_UNITS + [_npc];
		PublicVariable "KRON_UPS_REINFORCEMENT_GUER_UNITS";			
		};
	
	};
	{_x setvariable ["UPS_PosToRenf",[0,0]];} foreach units _npc;
};


//fortify group in near places
_fortify= if ("FORTIFY" in _UCthis) then {true} else {false};
_Patrlbld = if ("PATROLBLD" in _UCthis) then {true} else {false};
_Patrlbldorig = _Patrlbld;
_fortifyorig = if ("FORTIFY" in _UCthis) then {true} else {false};
if (_fortify) then 
{
	_nomove = "NOMOVE";
	_minreact = KRON_UPS_minreact * 3;
	_buildingdist = _buildingdist * 2;
	_waiting = 9999;								
};	

	
// don't make waypoints
_nowp = if ("NOWP" in _UCthis || "NOWP2" in _UCthis || "NOWP3" in _UCthis) then {true} else {false};
_nowpType = if ("NOWP2" in _UCthis) then {2} else {_nowpType}; _nowpType = if ("NOWP3" in _UCthis) then {3} else {_nowpType};
	
//Ambush squad will no move until in combat or so close enemy
_ambush= if (("AMBUSH" in _UCthis) || ("AMBUSHDIR:" in _UCthis) || ("AMBUSH2" in _UCthis) || ("AMBUSHDIR2:" in _UCthis)) then {true} else {false};
	
// Range of AI radio so AI can call Arty or Reinforcement
if ("RADIORANGE:" in _UCthis) then {_RadioRange = ["RADIORANGE:",_RadioRange,_UCthis] call KRON_UPSgetArg;}; // ajout

	
// set behaviour modes (or not)
if ("CARELESS" in _UCthis) then {_orgMode = "CARELESS"}; 
if ("SAFE" in _UCthis) then {_orgMode = "SAFE"};
if ("AWARE" in _UCthis) then {_orgMode = "AWARE"}; 
if ("COMBAT" in _UCthis) then {_orgMode = "COMBAT"}; 
if ("STEALTH" in _UCthis) then {_orgMode = "STEALTH"}; 
	
// set initial speed
_noslow = if ("NOSLOW" in _UCthis) then {"NOSLOW"} else {"SLOW"};
if (_noslow!="NOSLOW") then {
	_orgSpeed = "limited";
} else {	
	_orgSpeed = "FULL";	
}; 


// "area cleared" trigger activator
	_areatrigger = if ("TRIGGER" in _UCthis) then {"TRIGGER"} else {if ("NOTRIGGER" in _UCthis) then {"NOTRIGGER"} else {"SILENTTRIGGER"}};

	// suppress fight behaviour
	if ("NOAI" in _UCthis) then {_isSoldier=false};

	// adjust cycle delay 
	_cycle = KRON_UPS_Cycle;
	_currcycle=_cycle;

	//spawned for squads created in runtime
	_spawned= if ("SPAWNED" in _UCthis) then {true} else {false};
	if (_spawned) then {
		if (KRON_UPS_Debug>0) then {player sidechat format["%1: squad has been spawned, respawns %2",_grpidx,_respawnmax]}; 	
		switch (side _npc) do {
			case west:
			{ 	KRON_AllWest=KRON_AllWest + units _npc; 
			};
			case east:
			{  	KRON_AllEast=KRON_AllEast + units _npc; };
			case resistance:
			{  	
				KRON_AllRes=KRON_AllRes + units _npc; 
				if (east in KRON_UPS_Res_enemy ) then {	
					KRON_UPS_East_enemies = KRON_UPS_East_enemies+units _npc;
				} else {
					KRON_UPS_East_friends = KRON_UPS_East_friends+units _npc;
				}; 
				if (west in KRON_UPS_Res_enemy ) then {
					KRON_UPS_West_enemies = KRON_UPS_West_enemies+units _npc;
				} else {
					KRON_UPS_West_friends = KRON_UPS_West_friends+units _npc;
				};				
			};		
		};
		call (compile format ["KRON_UPS_%1_Total = KRON_UPS_%1_Total + count (units _npc)",side _npc]); 	
	
		_vehicletypes = ["VEHTYPE:",_vehicletypes,_UCthis] call KRON_UPSgetArg; 
	
	};

// set drop units at random positions
	_initpos = "ORIGINAL";
	if ("RANDOM" in _UCthis) then {_initpos = "RANDOM"};
	if ("RANDOMUP" in _UCthis) then {_initpos = "RANDOMUP"}; 
	if ("RANDOMDN" in _UCthis) then {_initpos = "RANDOMDN"};
	if ("RANDOMA" in _UCthis) then {_initpos = "RANDOMA"};
	// don't position groups or vehicles on rooftops
	if ((_initpos!="ORIGINAL") && (!_isman)) then {_initpos="RANDOMDN"};



//set Is a template for spawn module?
	_template = ["TEMPLATE:",_template,_UCthis] call KRON_UPSgetArg;
	//Fills template array for spawn
	if (_template > 0 && !_spawned) then {
		KRON_UPS_TEMPLATES = KRON_UPS_TEMPLATES + ( [[_template]+[_side]+[_membertypes]+[_vehicletypes]] );
		//if (KRON_UPS_Debug>0) then {diag_log format["%1 Adding TEMPLATE %2 _spawned %3",_grpidx,_template,_spawned]};	
		//if (KRON_UPS_Debug>0) then {player globalchat format["KRON_UPS_TEMPLATES %1",count KRON_UPS_TEMPLATES]};		
	};

// make start position random 
	if (_initpos!="ORIGINAL") then {
		// find a random position (try a max of 20 positions)
		_try=0;
		_bld=0;
		_bldpos= [];
		_nbbldpos=0;
		_bldpositions = [];
		_allpos = [];
		
		while {_try<20} do {
			_currPos=[_centerX,_centerY,_rangeX,_rangeY,_cosdir,_sindir,_areadir] call KRON_randomPos;
			If ((_initpos=="RANDOMUP") || (_initpos=="RANDOMDN") || (_initpos=="RANDOMA")) then
			{
			_OCercanos = [ (nearestObjects [[_centerX,_centerY,1], ["house","building"], _area]), { _x call Aze_filterbuilding } ] call BIS_fnc_conditionalSelect;
			_OCercanos = _OCercanos call BIS_fnc_arrayShuffle;
			
			{
				_bldpos = [_x, 70] call BIS_fnc_buildingPositions;
				sleep 0.2;
				_allpos = [_x,_bldpos,_initpos] call Aze_SortOutBldpos2; 
				_nbbldpos = count _allpos;
				_bldpositions = _bldpositions + [[_x,_allpos]];
				//player sidechat format["%1 cerca de edificio con %2 plantas %5",typeof _object,_bldpos];
				
			}foreach _OCercanos;
			
			};
			if (_nbbldpos > 0) then {_try=99};
			// _posinfo: [0,0]=no house near, [obj,-1]=house near, but no roof positions, [obj,pos]=house near, with roof pos
			if (_isplane || _isboat || _isDiver || !(surfaceiswater _currPos)) then {
				if (((_initpos=="RANDOM") || (_initpos=="RANDOMUP") || (_initpos=="RANDOMA")) && (_nbbldpos>0)) then {_try=99};
				if (((_initpos=="RANDOM") || (_initpos=="RANDOMDN") || (_initpos=="RANDOMA")) && (_nbbldpos==0)) then {_try=99};
			};
			_try=_try+1;
			sleep .01;
		};
		
		if (_nbbldpos==0) then 
		{
			{ //man
				if (vehicle _x == _x) then 
				{
					_targetpos = _currPos findEmptyPosition [5, 100];
					sleep .4;						
					if (count _targetpos <= 0) then {_targetpos = _currpos};
					_x setpos _targetpos;	
				};
			} foreach units _npc; 
			
			sleep .5;			
			{ // vehicles
				_targetpos = _currPos findEmptyPosition [20, 100];
				sleep .4;						
				if (count _targetpos <= 0) then {_targetpos = _currpos};
				_x setPos _targetpos;
			} foreach _vehicles;
		} 
		else 
		{
		// put the unit on top of a building
			
			[units _npc,_bldpositions] call MON_moveBuildings2; 
			_currPos = getPos _npc;
			_nowp=true; // don't move if on roof		
		};
	};
	
//////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// delete dead units ==============================================================================
	_deletedead = ["DELETE:",0,_UCthis] call KRON_UPSgetArg;
	if (_deletedead>0) then {
		{
			_x addEventHandler['killed',format["[_this select 0,%1] spawn KRON_deleteDead",_deletedead]];
			sleep 0.01;
		}forEach _members;
	};

// units that can be left for area to be "cleared" =============================================================================================
	_zoneempty = ["EMPTY:",0,_UCthis] call KRON_UPSgetArg;

// how many group clones? =========================================================================
// TBD: add to global side arrays?

	_mincopies = ["MIN:",0,_UCthis] call KRON_UPSgetArg;
	_maxcopies = ["MAX:",0,_UCthis] call KRON_UPSgetArg;
	if (_mincopies>_maxcopies) then {_maxcopies=_mincopies};
	if (_maxcopies>140) exitWith {hint "Cannot create more than 140 groups!"};
	
	if (_maxcopies>0) then 
	{
		_Ucthis = ["MIN:",0,_UCthis] call KRON_UPSgetArg;
		_Ucthis = ["MAX:",0,_Ucthis] call KRON_UPSsetArg;
		[_Ucthis,_mincopies,_maxcopies] call UPS_Clones;
	};
	

// create area trigger =========================================================================================================================
	if (_areatrigger!="NOTRIGGER") then {
		_trgside = switch (side _npc) do { case west: {"WEST"}; case east: {"EAST"}; case resistance: {"GUER"}; case civilian: {"CIV"};};
		//_trgside = switch (side _npc) do { case west: {"EAST"}; case east: {"WEST"}; case resistance: {"ANY"}; case civilian: {"ANY"};};
		_trgname="KRON_Trig_"+_trgside+"_"+_areamarker;
		_flgname="KRON_Cleared_"+_areamarker;
		// has the trigger been created already?
		KRON_TRGFlag=-1;
		call compile format["%1=false",_flgname];
		call compile format["KRON_TRGFlag='%1'",_trgname];
		if (isNil ("KRON_TRGFlag")) then 
//		if !(isNil {_trgname} ) then // ToDo if this code should replace 2 lines above
//		{
//			call compile format["{KRON_TRGFlag=%1};",_trgname];
//		};
//		if ( KRON_TRGFlag == -1 ) then 
		{
			// trigger doesn't exist yet, so create one (make it a bit bigger than the marker, to catch path finding 'excursions' and flanking moves)
			call compile format["%1=createTrigger['EmptyDetector',_centerpos]",_trgname];
			call compile format["%1 setTriggerArea[_rangeX*1.5,_rangeY*1.5,markerDir _areamarker,true]",_trgname];
			call compile format["%1 setTriggerActivation[_trgside,'PRESENT',true]",_trgname];
			call compile format["%1 setEffectCondition 'true'",_trgname];
			call compile format["%1 setTriggerTimeout [5,7,10,true]",_trgname];
			if (_areatrigger!="SILENTTRIGGER") then {
				call compile format["%1 setTriggerStatements['count thislist<=%6', 'titletext [''SECTOR <%2> LIMPIO'',''PLAIN''];''%2'' setmarkerpos [-%4,-%5];%3=true;', 'titletext [''SECTOR <%2> HA SIDO REOCUPADO'',''PLAIN''];''%2'' setmarkerpos [%4,%5];%3=false;']", _trgname,_areamarker,_flgname,_centerX,_centerY,_zoneempty];
				
			} else {
				call compile format["%1 setTriggerStatements['count thislist<=%3', '%2=true;', '%2=false;']", _trgname,_flgname,_zoneempty];
			};
		};
		sleep .05;
	};
_behaviour = _orgMode;
_npc setbehaviour _Behaviour;
_npc setspeedmode _speedmode;

//If a soldier has a useful building takes about ======================================================================================================================		
	if (_fortify) then 
	{			
		sleep 1;
		_unitsIn = [_grpid,_npc,150] call MON_GetIn_NearestStatic;		
		if ( count _unitsIn > 0 ) then { sleep 10};
		[_npc,_buildingdist,false,9999,true] call MON_moveNearestBuildings;
	};
	
	If (_ambush) then 
	{
		{
			_x setvariable ["UPS_AMBUSHFIRE",false];
			If !(isNil "bdetect_enable") then {_x setVariable ["bcombat_task", [ "", "mydummytask", 100, [] ] ];};
		} foreach units _npc;
		_nowp = true;	
		_positiontoambush = [_npc,_Ucthis] call Aze_SetAmbush;	
	};
	
	{
		_x setvariable ["UPS_Grpinfos",[side _npc,units _npc,group _npc]];
		_x setvariable ["UPS_Lastinfos",[[0,0,0],"HOLD",[0,0,0],0,objNull]];
		_x setvariable ["UPS_RadioRange",_RadioRange];
		_x setvariable ["UPS_Origin",[_orgMode,_orgSpeed,_orgpos]];
		_x setvariable ["UPS_NOWP",[_nowp,_nowptype]];
		_x setvariable ["UPS_Ambush",_ambush];
		_x setvariable ["UPS_Fortify",[_fortifyorig,_fortify]];
		_x setvariable ["UPS_REINFORCEMENT",_reinforcement];
		_x setvariable ["UPS_REINFORCEMENTSENT",false];
		_x setvariable ["UPS_RFID",_rfid];
		_x setvariable ["UPS_React",0];
		_x setvariable ["UPS_Waiting",_waiting];
		_x setvariable ["UPS_RESPAWNARRAY",[_membertypes,_vehicletypes]];
		_x setvariable ["TIMEONTARGET",0];
		_x setvariable ["UPS_makenewtarget",true];
		_x setvariable ["UPS_Positiontoambush",_positiontoambush];
		_x setvariable ["UPS_Deletegroup",false];
		_x setvariable ["UPS_GrpStatus","walk"];
	} foreach units _npc;
	
	//Assign the current leader of the group in the array of group leaders
	// KRON_NPCs set [_grpid,_npc];
	If (!(_npc in KRON_NPCs)) then {KRON_NPCs = KRON_NPCs + [_npc];};
