// =========================================================================================================
//  UPSMON - Urban Patrol Script  Mon
//  Version: A3 6.0.6.6 
//  Author: Monsada (chs.monsada@gmail.com) 
//
//		Wiki: http://dev-heaven.net/projects/upsmon/wiki
//		Forum: http://forums.bistudio.com/showthread.php?t=91696
//		Share your missions with upsmon: http://dev-heaven.net/projects/upsmon/boards/86
// ---------------------------------------------------------------------------------------------------------
//  Based on Urban Patrol Script  
//  Version: 2.0.3 
//  Author: Kronzky (www.kronzky.info / kronzky@gmail.com)
// ---------------------------------------------------------------------------------------------------------
//  Some little fixes: !Rafalsky (v5.0.8 - 5.0.9)
// ---------------------------------------------------------------------------------------------------------

//Adding eventhandlers -> moved down
//	"KRON_UPS_EAST_SURRENDED" addPublicVariableEventHandler { if (_this select 1) then { nul=[east] execvm "scripts\UPSMON\MON_surrended.sqf";};};
//	"KRON_UPS_WEST_SURRENDED" addPublicVariableEventHandler { if (_this select 1) then { nul=[west] execvm "scripts\UPSMON\MON_surrended.sqf";};};
//	"KRON_UPS_GUER_SURRENDED" addPublicVariableEventHandler { if (_this select 1) then { nul=[resistance] execvm "scripts\UPSMON\MON_surrended.sqf";};};
	//"MON_LOCAL_EXEC" addPublicVariableEventHandler { if (local ((_this select 1)select 0)) then { call ( compile format[(_this select 1)select 1,(_this select 1)select 0] );};};  // Not Used Anywhere ???

// only run on server (including SP, MP, Dedicated) and Headless Client 
if (!isServer && hasInterface ) exitWith {};

//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- 
//        These Variables should be checked and set as required, to make the mission runs properly.
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

// ACE Wounds System for AI (set TRUE to On, set FALSE to Off) ! 
//ace_sys_wounds_noai = false; // set it as required // Not used (yet?) in ArmA 3

//1=Enable or 0=disable debug. In debug could see a mark positioning de leader and another mark of the destination of movement, very useful for editing mission
KRON_UPS_Debug = 1;

//1=Enable or 0=disable. In game display global chat info about who just killed a civilian. 
//numbers of Civilians killed by players could be read from array 'KILLED_CIV_COUNTER' -> [Total, by West, by East, by Res, The killer]
R_WHO_IS_CIV_KILLER_INFO = 0;

// if you are spotted by AI group, how close the other AI group have to be to You , to be informed about your present position. over this, will lose target
KRON_UPS_sharedist = 700; // org value 800 => increased for ArmA3 map sizes for less predictable missions..

// If enabled AI communication between them with radio defined sharedist distance, 0/2 
// (must be set to 2 in order to use reinforcement !R)
KRON_UPS_comradio = 2;

//Sides that are enemies of resistance
KRON_UPS_Res_enemy = [];
_resEnemyWest = false;
_resEnemyEast = false;				
if ( (resistance getFriend WEST) < 0.6 ) then { _resEnemyWest = true }; // resistance is enemy of West
if ( (resistance getFriend EAST) < 0.6 ) then { _resEnemyEast = true }; // resistance is enemy of East

if ( _resEnemyWest && _resEnemyEast ) then { KRON_UPS_Res_enemy = [west, east] };
if ( _resEnemyWest && !_resEnemyEast ) then { KRON_UPS_Res_enemy = [west] };
if ( !_resEnemyWest && _resEnemyEast ) then { KRON_UPS_Res_enemy = [east] };
//if ( !_resEnemyWest && !_resEnemyEast ) then { KRON_UPS_Res_enemy = [] };

// Distance from destination for searching vehicles. (Search area is about 200m), 
// If your destination point is further than KRON_UPS_searchVehicledist, AI will try to find a vehicle to go there.
KRON_UPS_searchVehicledist = 600; // 700, 900  

//Enables or disables AI to use static weapons
KRON_UPS_useStatics = true;

//Enables or disables AI to put mines if armoured enemies near (use ambush2 if needed)
KRON_UPS_useMines = true; //ToDo verify this param

//Group formations
KRON_UPS_groupFormation	= ["COLUMN","STAG COLUMN","WEDGE","ECH LEFT","ECH RIGHT","VEE","LINE","FILE","DIAMOND"];	//Group formations

//------------------------------------------------------------------------------------------------------------------------------
//        These Variables can be changed if needed but it is not necessary.
//------------------------------------------------------------------------------------------------------------------------------

//% of chance to use smoke by team members when someone wounded or killed in the group in %(default 13 & 35).
// set both to 0 -> to switch off this function 
R_USE_SMOKE_wounded = 5; // org 13: decreased while AI is popping smoke a bit too often
R_USE_SMOKE_killed = 15;

//Height that heli will fly this input will be randomised in a 10%
KRON_UPS_flyInHeight = 70; //80;

//Autorise Surrender or not.
KRON_UPS_SURRENDER = false;
if ( KRON_UPS_SURRENDER ) then 
{
	//Adding eventhandlers
	"KRON_UPS_EAST_SURRENDED" addPublicVariableEventHandler { if (_this select 1) then { nul=[east] execvm "scripts\UPSMON\MON_surrended.sqf";};};
	"KRON_UPS_WEST_SURRENDED" addPublicVariableEventHandler { if (_this select 1) then { nul=[west] execvm "scripts\UPSMON\MON_surrended.sqf";};};
	"KRON_UPS_GUER_SURRENDED" addPublicVariableEventHandler { if (_this select 1) then { nul=[resistance] execvm "scripts\UPSMON\MON_surrended.sqf";};};
	
	KRON_UPS_EAST_SURRENDER = 70;
	KRON_UPS_WEST_SURRENDER = 70;
	KRON_UPS_GUER_SURRENDER = 70;
}
else
{
	KRON_UPS_EAST_SURRENDER = 0;
	KRON_UPS_WEST_SURRENDER = 0;
	KRON_UPS_GUER_SURRENDER = 0;
};

KRON_UPS_RETREAT = false;
if ( KRON_UPS_RETREAT ) then 
{

	KRON_UPS_EAST_RETREAT = 70;
	KRON_UPS_WEST_RETREAT = 70;
	KRON_UPS_GUER_RETREAT = 70;
}
else
{
	KRON_UPS_EAST_RETREAT = 0;
	KRON_UPS_WEST_RETREAT = 0;
	KRON_UPS_GUER_RETREAT = 0;
};

// knowsAbout 0.5 1.03 , 1.49 to add this enemy to "target list" (1-4) the higher number the less detect ability (original in 5.0.7 was 0.5)
// it does not mean the AI will not shoot at you. This means: what must be knowsAbout you to UPSMON adds you to the list of targets (UPSMON list of target) 
R_knowsAboutEnemy = 1.5;

// units will react (change the beahaviour) when dead bodies found 
R_deadBodiesReact = true;  // true OR false // modified so AI will react to dead bodies found

// ---------------------------------------------------------------------------------------------------------------------
//      Better do not change these variables if you aren't sure !R
// ---------------------------------------------------------------------------------------------------------------------

//Efective distance for doing perfect ambush (max distance is this x2)
KRON_UPS_ambushdist = 75; // decreased from 100 to 75, so max distance is 150 m

//Max distance to target for doing para-drop, will be randomised between 0 and 100% of this value.
KRON_UPS_paradropdist = 250;

//Frequency for doing calculations for each squad.
KRON_UPS_Cycle = 10; //org 20

//Time that lider wait until doing another movement, this time reduced dynamically under fire, and on new targets
KRON_UPS_react = 30;

//Min time to wait for doing another reaction
KRON_UPS_minreact = 20; // org 30

//Max waiting is the maximum time patrol groups will wait when arrived to target for doing another target.
KRON_UPS_maxwaiting = 30;

// how long AI units should be in alert mode after initially spotting an enemy
KRON_UPS_alerttime = 90;

// how far opfors should move away if they're under attack
KRON_UPS_safedist = 280; //org 300

// How far opfor disembark from non armoured vehicle
KRON_UPS_closeenoughV = 800;

// how close unit has to be to target to generate a new one target or to enter stealth mode
KRON_UPS_closeenough = 200;  // ToDo investigate effect of decrease of this value to e.g. 50 // 300

//Enable it to send reinforcements, better done it in a trigger inside your mission.
KRON_UPS_reinforcement = false; // ToDo Set to true if UPSMON reinf is going ot be used

//Artillery support, better control if set in trigger 
KRON_UPS_ARTILLERY_EAST_FIRE = false; //set to true for doing east to fire //ToDo verify if needed
KRON_UPS_ARTILLERY_WEST_FIRE = false; //set to true for doing west to fire
KRON_UPS_ARTILLERY_GUER_FIRE = false; //set to true for doing resistance to fire
KRON_UPS_Night = true;
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
//		Do not touch these variables !!!! !R	
//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------			
	// R_GOTHIT_ARRAY =[0];
	R_GOTHIT_ARRAY = [];
	R_GOTKILL_ARRAY = [];
	AcePresent = isClass(configFile/"CfgPatches"/"ace_main");
	UPSMON_Version = "UPSMON 6.0.6.6";
	KILLED_CIV_COUNTER = [0,0,0,0,0];
	KRON_UPS_flankAngle = 45; //Angulo de flanqueo
	KRON_UPS_INIT = 0;        //Variable que indica que ha sido inicializado
	KRON_UPS_EAST_SURRENDED = false;
	KRON_UPS_WEST_SURRENDED = false;
	KRON_UPS_GUER_SURRENDED = false;
	KRON_AllWest=[];	//All west AI 
	KRON_AllEast=[];	//All east AI 
	KRON_AllRes=[];		//All resistance AI 
	KRON_UPS_East_enemies = [];
	KRON_UPS_West_enemies = [];
	KRON_UPS_Guer_enemies = [];
	KRON_UPS_East_friends = [];
	KRON_UPS_West_friends = [];
	KRON_UPS_Guer_friends = [];
	KRON_targets0 =[];//objetivos west
	KRON_targets1 =[];//objetivos east
	KRON_targets2 =[];//resistence	
	KRON_targetsPos =[];//Posiciones de destino actuales.
	KRON_NPCs = []; //Lideres de los grupos actuales
	KRON_UPS_Instances=0; // -1; // => -1 would start group nr with 0 
	KRON_UPS_Total=0;
	KRON_UPS_Exited=0;
	KRON_UPS_East_Total = 0;
	KRON_UPS_West_Total = 0;
	KRON_UPS_Guer_Total = 0;	
	KRON_UPS_ARTILLERY_WEST_UNITS = [];
	KRON_UPS_ARTILLERY_EAST_UNITS = [];
	KRON_UPS_ARTILLERY_GUER_UNITS = [];	
	KRON_UPS_ARTILLERY_WEST_TARGET = objnull;
	KRON_UPS_ARTILLERY_EAST_TARGET = objnull;
	KRON_UPS_ARTILLERY_GUER_TARGET = objnull;
	KRON_UPS_REINFORCEMENT_WEST_UNITS = [];
	KRON_UPS_REINFORCEMENT_EAST_UNITS = [];
	KRON_UPS_REINFORCEMENT_GUER_UNITS = [];	
	FlareInTheAir = false;
	Publicvariable "FlareInTheAir";
	_sunangle = 0;
	KRON_UPS_TEMPLATES = [];
	KRON_UPS_MG_WEAPONS = ["LMG_Mk200_F","LMG_Mk200_MRCO_F","LMG_Mk200_pointer_F","LMG_Zafir_F","LMG_Zafir_pointer_F","arifle_MX_SW_F","arifle_MX_SW_Hamr_pointer_F","arifle_MX_SW_pointer_F"];
	// For future updates check this for weapons with > 100Rnd ammo:
	// http://browser.six-projects.net/cfg_weapons/classlist?utf8=%E2%9C%93&version=70&commit=Change&options[group_by]=weap_type&options[custom_type]=Rifle&options[faction]=
//----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------



	// ***************************************** SERVER INITIALIZATION *****************************************
	if (isNil("KRON_UPS_INIT") || KRON_UPS_INIT == 0) then {

		//Init library function, Required Version: 5.0 of mon_functions
		call compile preprocessFileLineNumbers "scripts\UPSMON\common\MON_functions.sqf";
		
		// Init Modules
		call compile preprocessFileLineNumbers "scripts\UPSMON\modules\UPS_clone.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\modules\UPS_respawn.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\modules\UPS_RENF.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\modules\UPS_Ambush.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\modules\UPS_Retreat.sqf";
		//call compile preprocessFileLineNumbers "scripts\UPSMON\modules\UPS_fortify.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\Aze\Aze_Equipment.sqf";
		[] execVM "scripts\UPSMON\modules\UPS_Track.sqf"
		
		//init !R functions
		call compile preprocessFileLineNumbers "scripts\UPSMON\!R\R_functions.sqf";
		
		//init Aze Functions
		call compile preprocessFileLineNumbers "scripts\UPSMON\Aze\Aze_functions.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\newfunc\func_getcover.sqf";
		call compile preprocessFileLineNumbers "scripts\UPSMON\Aze\Aze_Movement.sqf";
		
		//init SunAngle Functions
		call compile preprocessFileLineNumbers "scripts\SunAngle_fnc.sqf";
		
		// Init Mando function
		mando_check_los = compile (preprocessFileLineNumbers "scripts\mando_check_los.sqf");
		
		//if (isNil "RE") then {[] execVM "\ca\Modules\MP\data\scripts\MPframework.sqf"}; 
		
		//scripts initialization
		UPSMON = compile preprocessFile "scripts\UPSMON.sqf";	
		UPSMON_surrended = compile preprocessFile "scripts\UPSMON\MON_surrended.sqf";		
		//UPSMON_Mainloop = compile preprocessFile "scripts\UPSMON_MainLoop.sqf";
		[] execVM "scripts\UPSMON_MainLoop.sqf";
		
		// declaración de variables privadas
		private["_obj","_trg","_l","_pos"];

		// global functions
		KRON_randomPos = {private["_cx","_cy","_rx","_ry","_cd","_sd","_ad","_tx","_ty","_xout","_yout"];_cx=_this select 0; _cy=_this select 1; _rx=_this select 2; _ry=_this select 3; _cd=_this select 4; _sd=_this select 5; _ad=_this select 6; _tx=random (_rx*2)-_rx; _ty=random (_ry*2)-_ry; _xout=if (_ad!=0) then {_cx+ (_cd*_tx - _sd*_ty)} else {_cx+_tx}; _yout=if (_ad!=0) then {_cy+ (_sd*_tx + _cd*_ty)} else {_cy+_ty}; [_xout,_yout]};
		KRON_PosInfo = {private["_pos","_lst","_bld","_bldpos"];_pos=_this select 0; _lst=_pos nearObjects ["House",12]; if (count _lst==0) then {_bld=0;_bldpos=0} else {_bld=_lst select 0; _bldpos=[_bld] call KRON_BldPos}; [_bld,_bldpos]};
		KRON_PosInfo3 = {
			private["_pos","_lst","_bld","_bldpos"];
			_pos=_this select 0; 
			_lst= nearestObjects [_pos, [], 3];
			if (count _lst==0) then {_bld=objnull;_bldpos=0} else {_bld = nearestbuilding (_lst select 0); 
			_bldpos=[_bld] call KRON_BldPos2}; 
			[_bld,_bldpos]};
		KRON_BldPos = {private ["_bld","_bldpos","_posZ","_maxZ"];_bld=_this select 0;_maxZ=0;_bi=0;_bldpos=0;while {_bi>=0} do {if (((_bld BuildingPos _bi) select 0)==0) then {_bi=-99} else {_bz=((_bld BuildingPos _bi) select 2); if (((_bz)>4) && ((_bz>_maxZ) || ((_bz==_maxZ) && (random 1>.8)))) then {_maxZ=_bz; _bldpos=_bi}};_bi=_bi+1};_bldpos};
		KRON_BldPos2 = {private ["_bld","_bldpos"];
							_bld=_this select 0; _bldpos = 1;
							while {format ["%1", _bld buildingPos _bldpos] != "[0,0,0]"}  do {_bldpos = _bldpos + 1;};
						_bldpos = _bldpos - 1; _bldpos;};
		
		
		KRON_getDirPos = {private["_a","_b","_from","_to","_return"]; _from = _this select 0; _to = _this select 1; _return = 0; _a = ((_to select 0) - (_from select 0)); _b = ((_to select 1) - (_from select 1)); if (_a != 0 || _b != 0) then {_return = _a atan2 _b}; if ( _return < 0 ) then { _return = _return + 360 }; _return};
		KRON_distancePosSqr = {round(((((_this select 0) select 0)-((_this select 1) select 0))^2 + (((_this select 0) select 1)-((_this select 1) select 1))^2)^0.5)};

//		KRON_relPos = {private["_p","_d","_a","_x","_y","_xout","_yout"];_p=_this select 0; _x=_p select 0; _y=_p select 1; _d=_this select 1; _a=_this select 2; _xout=_x + sin(_a)*_d; _yout=_y + cos(_a)*_d;[_xout,_yout,0]};
		KRON_relPos = {private["_p","_d","_a","_xx","_yy","_xout","_yout"];_p=_this select 0; _xx=_p select 0; _yy=_p select 1; _d=_this select 1; _a=_this select 2; _xout=_xx + sin(_a)*_d; _yout=_yy + cos(_a)*_d;[_xout,_yout,0]}; 

		KRON_rotpoint = {private["_cp","_a","_tx","_ty","_cd","_sd","_cx","_cy","_xout","_yout"];_cp=_this select 0; _cx=_cp select 0; _cy=_cp select 1; _a=_this select 1; _cd=cos(_a*-1); _sd=sin(_a*-1); _tx=_this select 2; _ty=_this select 3; _xout=if (_a!=0) then {_cx+ (_cd*_tx - _sd*_ty)} else {_cx+_tx}; _yout=if (_a!=0) then {_cy+ (_sd*_tx + _cd*_ty)} else {_cy+_ty}; [_xout,_yout,0]};
		KRON_stayInside = {
			private["_np","_nx","_ny","_cp","_cx","_cy","_rx","_ry","_d","_tp","_tx","_ty","_fx","_fy"];
			_np=_this select 0;	_nx=_np select 0;	_ny=_np select 1;
			_cp=_this select 1;	_cx=_cp select 0;	_cy=_cp select 1;
			_rx=_this select 2;	_ry=_this select 3;	_d=_this select 4;
			_tp = [_cp,_d,(_nx-_cx),(_ny-_cy)] call KRON_rotpoint;
			_tx = _tp select 0; _fx=_tx;
			_ty = _tp select 1; _fy=_ty;
			if (_tx<(_cx-_rx)) then {_fx=_cx-_rx};
			if (_tx>(_cx+_rx)) then {_fx=_cx+_rx};
			if (_ty<(_cy-_ry)) then {_fy=_cy-_ry};
			if (_ty>(_cy+_ry)) then {_fy=_cy+_ry};
			if ((_fx!=_tx) || (_fy!=_ty)) then {_np = [_cp,_d*-1,(_fx-_cx),(_fy-_cy)] call KRON_rotpoint};
			_np;
		};
	// Misc
		KRON_UPSgetArg = {private["_cmd","_arg","_list","_a","_v"]; 
		_cmd=_this select 0; 
		_arg=_this select 1; 
		_list=_this select 2; 
		_a=-1; 
		{_a=_a+1; _v=format["%1",_list select _a]; 
		if (_v==_cmd) then {_arg=(_list select _a+1)}} foreach _list; _arg};
		KRON_UPSsetArg = {private["_cmd","_arg","_list","_a","_v"]; 
			_cmd=_this select 0; 
			_arg=_this select 1; 
			_list=_this select 2; 
			_a=-1; 
			{	
				_a=_a+1; 
				_v= format ["%1", _list select _a]; 
				if (_v==_cmd) then {
					_a=_a+1; 
					_list set [_a,_arg];
					};
			} foreach _list; 
			_list};
		KRON_deleteDead = {private["_u","_s"];_u=_this select 0; _s= _this select 1; _u removeAllEventHandlers "killed"; sleep _s; deletevehicle _u};

	// Set KRON_fnc_setVehicleInit. Replaces setVehicleInit.  This is taken from MCC Controls Mission with permission from shay_gman
	// moved to functions definition file			
		
	// ***********************************************************************************************************	
	//									  MAIN UPSMON SERVER FUNCTION 
	// ***********************************************************************************************************	
		MON_MAIN_server = 
		{		
			private["_obj","_trg","_l","_pos","_countWestSur","_countEastSur","_countResSur","_WestSur","_EastSur","_ResSur","_target","_targets","_targets0","_targets1","_targets2","_npc","_cycle"
				,"_side","_area","_knownpos","_sharedenemy","_enemyside","_timeout"];
			
			_cycle = 10; //Time to do a call to commander  // ToDo make server FPS agile
			_arti = objnull;
			_side = "";
			_range = 0;
			_rounds = 0;	
			_area = 0;	
			_maxcadence = 0;	
			_mincadence = 0;	
			_bullet = "";	
			_fire = false;
			_target = objnull;
			_knownpos =[0,0,0];
			_enemyside = [];

			_WestSur = KRON_UPS_WEST_SURRENDED;
			_EastSur = KRON_UPS_EAST_SURRENDED;
			_ResSur = KRON_UPS_GUER_SURRENDED;	
			
			
			//Main loop
			while {true} do 
			{	
				_Night = [] call UPS_SunAngle;
				KRON_UPS_Night = _Night;
				publicvariable "KRON_UPS_Night";
				
				_countWestSur = round ( KRON_UPS_West_Total * KRON_UPS_WEST_SURRENDER / 100);
				_countEastSur = round ( KRON_UPS_East_Total * KRON_UPS_EAST_SURRENDER / 100);
				_countResSur = round ( KRON_UPS_Guer_Total * KRON_UPS_GUER_SURRENDER / 100);
				
						
				sleep 0.5;	
				
				_sharedenemy = 0;	
				_targets0 = [];
				_targets1 = [];
				_targets2 = [];

				if (KRON_UPS_Debug>0) then { diag_log format ["KRON_NPCs: [%1]", KRON_NPCs]; };				
				
				
				//Share targets
				KRON_targets0 = _targets0;
				KRON_targets1 = _targets1;
				KRON_targets2 = _targets2;
				
				
				//Target debug console
				if (KRON_UPS_Debug>0) then {hintsilent parseText format["%1<br/>--------------------------<br/><t color='#33CC00'>West(A=%2 C=%3 T=%4)</t><br/><t color='#FF0000'>East(A=%5 C=%6 T=%7)</t><br/><t color='#00CCFF'>Res(A=%8 C=%9 T=%10)</t><br/>"
					,UPSMON_Version
					,KRON_UPS_West_Total, count KRON_AllWest, count KRON_targets0
					,KRON_UPS_East_Total, count KRON_AllEast, count KRON_targets1
					,KRON_UPS_Guer_Total, count KRON_AllRes, count KRON_targets2					]}; 	
				sleep 0.5;
				
				diag_log format ["KRON_Arti: [%1]", KRON_UPS_ARTILLERY_EAST_UNITS];
				
				// if (KRON_UPS_Debug>0) then {player globalchat format["Init_upsmon artillery=%1",count KRON_UPS_ARTILLERY_UNITS]};							
				sleep _cycle;			
			};
		};	
	};
	
	
// ***********************************************************************************************************	
//									  INITIALIZATION  OF UPSMON
// ***********************************************************************************************************		
	
	_l = allunits + vehicles;
	{
		if ((_x iskindof "AllVehicles") && (side _x != civilian)) then 
		{
			_s = side _x;
			switch (_s) do {
				case west: 
					{ KRON_AllWest=KRON_AllWest+[_x]; };
				case east: 
					{ KRON_AllEast=KRON_AllEast+[_x]; };
				case resistance: 
					{ KRON_AllRes=KRON_AllRes+[_x]; };
			};
		};
	} forEach _l;
	_l = nil;

	if (isNil("KRON_UPS_Debug")) then {KRON_UPS_Debug=0};

	KRON_UPS_East_enemies = KRON_AllWest;
	KRON_UPS_West_enemies = KRON_AllEast;
	
	// ToDo rewrite based on getFriend relationship
	if (east in KRON_UPS_Res_enemy ) then {	
		KRON_UPS_East_enemies = KRON_UPS_East_enemies+KRON_AllRes;
		KRON_UPS_Guer_enemies = KRON_AllEast;
	} else {
		KRON_UPS_East_friends = KRON_UPS_East_friends+KRON_AllRes;
		KRON_UPS_Guer_friends = KRON_AllEast;
	}; 
		
	if (west in KRON_UPS_Res_enemy ) then {
		KRON_UPS_West_enemies = KRON_UPS_West_enemies+KRON_AllRes;
		KRON_UPS_Guer_enemies = KRON_UPS_Guer_enemies+KRON_AllWest;
	} else {
		KRON_UPS_West_friends = KRON_UPS_West_friends+KRON_AllRes;
		KRON_UPS_Guer_friends = KRON_UPS_Guer_friends+KRON_AllWest;
	};

	KRON_UPS_West_Total = count KRON_AllWest;		
	KRON_UPS_East_Total = count KRON_AllEast;
	KRON_UPS_Guer_Total = count KRON_AllRes;		
	
	//Initialization done
	KRON_UPS_INIT=1;	

	
	//killciv EH
	_l = allunits;
	{
		if (side _x == civilian) then // ToDo verify what's the use..?
		{						
			_x AddEventHandler ["firedNear", {nul = _this spawn R_SN_EHFIREDNEAR}];
			sleep 0.01;					

			_x AddEventHandler ["killed", {nul = _this spawn R_SN_EHKILLEDCIV}];
			sleep 0.01;					
		};
	} forEach _l;
	_l = nil;
	
	
// ---------------------------------------------------------------------------------------------------------

//Executes de main process of server
[] SPAWN MON_MAIN_server;

diag_log "--------------------------------";
diag_log (format["UPSMON started"]);
if(true) exitWith {};
