private ["_grp","_lastcurrpos","_lastknown","_lastwptype","_lastpos","_flankdir","_lastmembers","_timeinfo","_alertpos","_fixedtargetPos","_timeontarget","_timeonalert","_timeonbld","_timeondefend","_react","_lastreact","_minreact","_membertypes","_vehiclestypes","_makenewtarget",
"_reinforcementsent","_reinforcement","_timeartillery","_timeinfo","_Ucthis","_fortifyorig","_fortify","_pause","_nomove","_onroad","_nosmoke","_nofollow","_shareinfo","_noveh","_noveh2","_radiorange","_orgMode","_orgSpeed","_orgpos","_orgformation"];

// ***********************************************************************************************************
// ************************************************ MAIN LOOP ************************************************
// ***********************************************************************************************************
	
while {true} do 
{
	_cycle = ((random 1) + 1);
	
	{
		_grp = _x;
		_exit = false;

		_lastcurrpos = (_grp getvariable "UPSMON_Lastinfos") select 0;
		_lastknown = (_grp getvariable "UPSMON_Lastinfos") select 3;
		_lastwptype = (_grp getvariable "UPSMON_Lastinfos") select 1;
		_lastpos = (_grp getvariable "UPSMON_Lastinfos") select 2;
		_flankdir = (_grp getvariable "UPSMON_Lastinfos") select 5;
		_lastmembers = (_grp getvariable "UPSMON_Lastinfos") select 6;
		_timeinfo = (_grp getvariable "UPSMON_Lastinfos") select 7;
		_alertpos = (_grp getvariable "UPSMON_Lastinfos") select 8;
		_fixedtargetPos = (_grp getvariable "UPSMON_Lastinfos") select 9;
		_timeontarget = (_grp getvariable "UPSMON_TIMEONTARGET") select 0;
		_timeonalert = (_grp getvariable "UPSMON_TIMEONTARGET") select 1;
		_timeonbld  = (_grp getvariable "UPSMON_TIMEONTARGET") select 2;
		_timeondefend  = (_grp getvariable "UPSMON_TIMEONTARGET") select 2;
		_react = (_grp getvariable "UPSMON_REACT") select 0;
		_lastreact = (_grp getvariable "UPSMON_REACT") select 1;
		_minreact = (_grp getvariable "UPSMON_REACT") select 2;
		_membertypes = (_grp getvariable "UPSMON_RESPAWNARRAY") select 0;
		_vehicletypes = (_grp getvariable "UPSMON_RESPAWNARRAY") select 1;
		_makenewtarget = _grp getvariable "UPSMON_makenewtarget";
		_reinforcementsent = (_grp getvariable "UPSMON_REINFORCEMENTSENT") select 0;
		_reinforcement = _grp getvariable "UPSMON_REINFORCEMENT";
		_timereinforcement =(_grp getvariable "UPSMON_REINFORCEMENTSENT") select 1;
		_timeartillery = _grp getvariable "UPSMON_TimeArtillery";
	
		_timeinfo = _timeinfo + _cycle;
		_timereinforcement = _timereinforcement + _cycle;
		_timeartillery = _timeartillery + _cycle;
		_react = _react + _cycle;
		_Ucthis = _grp getvariable "UPSMON_Ucthis";
		_colorstatus = (_grp getvariable "UPSMON_Grpstatus") select 1;
	
		_fortifyorig = (_grp getvariable "UPSMON_Fortify") select 0;
		_fortify = (_grp getvariable "UPSMON_Fortify") select 1;

		// wait at patrol end points
		_pause = if ("NOWAIT" in _UCthis) then {"NOWAIT"} else {"WAIT"};
		_nomove  = if ("NOMOVE" in _UCthis || _fortify) then {"NOMOVE"} else {"MOVE"};

		// create _targerpoint on the roads only (by this group)
		_onroad = if ("ONROAD" in _UCthis) then {true} else {false};
		// do not use smoke (by this group)
		_nosmoke = if ("NOSMOKE" in _UCthis) then {true} else {false};
	
		// don't follow outside of marker area
		_nofollow = if ("NOFOLLOW" in _UCthis) then {"NOFOLLOW"} else {"FOLLOW"};
		// share enemy info 
		_shareinfo = if ("NOSHARE" in _UCthis) then {"NOSHARE"} else {"SHARE"};	
	
		// do not search for vehicles (unless in fight and combat vehicles)
		_noveh = if ("NOVEH" in _UCthis || "NOVEH2" in _UCthis) then {true} else {false};	
		_noveh2 = if ("NOVEH2" in _UCthis) then {true} else {false};	// Ajout
		
		_radiorange = _grp getvariable "UPSMON_RadioRange";
		_orgMode = (_grp getvariable "UPSMON_Origin") select 0;
		_orgSpeed = (_grp getvariable "UPSMON_Origin") select 1;
		_orgpos = (_grp getvariable "UPSMON_Origin") select 2;
		_orgformation = (_grp getvariable "UPSMON_Origin") select 3;
		_members = (_grp getvariable "UPSMON_Origin") select 4;
	
		_nowp = (_grp getvariable "UPSMON_NOWP") select 0;
		_nowptype = (_grp getvariable "UPSMON_NOWP") select 1;
		
		_grpmission = (_grp getvariable "UPSMON_Grpstatus") select 0;
		_lastgrpmission = (_grp getvariable "UPSMON_Grpstatus") select 2;
		_grpid = _grp getVariable "UPSMON_grpid";
		_grpidx = format["%1",_grpid];
		_grpname = format["%1_%2",(side _grp),_grpidx];
		
		_rfid = _grp getvariable ["UPSMON_RFID",0];
		_targetpos = _grp getvariable "UPSMON_TargetPos";
		
		_side = side _grp;
		_surrended = false;
		if (({alive _x && !(captive _x)} count units _grp) == 0 ||  _grp getvariable ["UPSMON_Removegroup",false]) exitwith
		{
			[_grp,_Ucthis,_orgpos,_surrended,_grpidx,_membertypes,_vehicletypes,_side] call UPSMON_Respawngrp;
		}; 	

		//========================= Marker caracteristics =================================================
		_areamarker = _Ucthis select 1;
		//=================================================================================================
		
		_surrender = 0;
		_retreat = 0;
		
		//Sets min units alive for surrender
		if !( _side == civilian ) then 
		{ 
			_surrender = call (compile format ["UPSMON_%1_SURRENDER",_side]); 
			_retreat = call (compile format ["UPSMON_%1_SURRENDER",_side]); 
		};

		_rfidcalled = false;
		_linkdistance = 100;
		_fortify = false;
		_buildingdist = 25;
		_target = ObjNull;
		_newtarget=objnull;
		_newpos = false;
		_supressed = false;
		_unitsIn = [];
		_ratio = 1;
		_wptype="MOVE";
		_lastwptype = "MOVE";
		_wpformation = "VEE";
		_rstuckControl = 0;
		_flyInHeight = 50;
		_cargo = [];
		_landing=false;
		_safemode=["CARELESS","SAFE"];
		_opfknowval = 0;
		_targetsnear = false;
		_attackPos 	= [0,0];
		_targetdead = false;
		_newattackPos = [0,0];
		_wppos = [0,0];
		_fortifyorig= false;
		_deadBodiesreact = UPSMON_deadBodiesReact; 
		_nbrwoundedunit =0;
		_ambushed = false;
		_enemytanknear = objNull;
		_enemystaticnear = objNull;
		_enemyairnear = objnull;
		_assignedvehicle = [];
		_isSoldier = true;
		_sokilled = false;
		_sowounded = false;
		_gothit = false;
		_Supstate = random 100 < 40;
		_newpos = false;
		_closeenough = UPSMON_closeenough;
		_closenoughV = UPSMON_closeenoughV;
		_supressed = false;
		_dist = 1000;
		_targetdist = 10000;
		_traveldist = 0;
		_atcapacity = false;
		_aacapacity = false;
		_needsupport = false;
		_typeofgrp = ["infantry"];
		_hascapacity = true;
		_CombatMode = "YELLOW";
		_pursue = false;
		
		_npc = leader _grp;
		
		// did the leader die?
		_npc = [_npc,_grp] call UPSMON_getleader;							
		if (!alive _npc || isplayer _npc) exitwith {[_grp,_Ucthis,_orgpos,_surrended,_grpidx,_membertypes,_vehicletypes,_side] call UPSMON_Respawngrp;};			

		_speedmode = speedmode _npc;
		_behaviour = behaviour _npc;
		
		// suppress fight behaviour
		if ("NOAI" in _UCthis || side _npc == civilian) then {_isSoldier=false};
		
		If (UPSMON_Debug > 0) then {player sidechat format ["%1 begin check",_grpid];};
		

		// current position
		_currPos = getposATL _npc; _currX = _currPos select 0; _currY = _currPos select 1;
		// Variable check if Unit is HIT / WOUNDED / KILLED ===========================================================================
		// CHECK IF did anybody in the group got hit or die? 
	
		If (isNil "tpwcas_running") then 
		{
			If (isNil "bdetect_enable") then
			{ 
				if (_npc getVariable "Suppressed" == 1) then
				{
					_gothit = true;
					_supressed = true;
				};
				if (_grp in UPSMON_GOTHIT_ARRAY || _grp in UPSMON_GOTKILL_ARRAY) then
				{
					_gothit = true;
						
						if (group _npc in UPSMON_GOTHIT_ARRAY) then
						{
							_sowounded = true;
							_nbrwoundedunit = 0;
							{
								If (lifestate _x == "INJURED") then {_nbrwoundedunit = _nbrwoundedunit +1;};
							}Foreach units _npc;
						}
						else
						{
							_sokilled = true;
							UPSMON_GOTKILL_ARRAY = UPSMON_GOTKILL_ARRAY - [_grp];
						};
						
						UPSMON_GOTHIT_ARRAY = UPSMON_GOTHIT_ARRAY - [_grp];
					};
				}
				else
				{
					_Supstate = _npc getVariable ["bcombat_suppression_level", 0];
					if (_Supstate >= 20) then
					{
						_gothit = true;
						If (_Supstate >= 75) then {_supressed = true} else {_supressed = false};
					};
		
					if (_grp in UPSMON_GOTHIT_ARRAY || group _npc in UPSMON_GOTKILL_ARRAY) then
					{
						_gothit = true;
			
						if (_grp in UPSMON_GOTHIT_ARRAY) then
						{
							_sowounded = true;
							_nbrwoundedunit = 0;
							{
								If (lifestate _x == "INJURED") then {_nbrwoundedunit = _nbrwoundedunit +1;};
							}Foreach units _npc;
						}
						else
						{
							_sokilled = true;
							UPSMON_GOTKILL_ARRAY = UPSMON_GOTKILL_ARRAY - [_grp];
						};
						UPSMON_GOTHIT_ARRAY = UPSMON_GOTHIT_ARRAY - [_grp];
					};
				};
			
			} 
			else 
			{
				_Supstate = [_npc] call UPSMON_supstatestatus; 
				if (_Supstate >= 2) then
				{
					_gothit = true;
					_Supstate = [_npc] call UPSMON_supstatestatus;
					If (_Supstate == 3) then {_supressed = true} else {_supressed = false};
				};
		
				if (_grp in UPSMON_GOTHIT_ARRAY || group _npc in UPSMON_GOTKILL_ARRAY) then
				{
					_gothit = true;
					_Supstate = [_npc] call UPSMON_supstatestatus;
					If (_Supstate == 3) then {_supressed = true} else {_supressed = false};
			
					if (_grp in UPSMON_GOTHIT_ARRAY) then
					{
						_sowounded = true;
						_nbrwoundedunit = 0;
						{
							If (lifestate _x == "INJURED") then {_nbrwoundedunit = _nbrwoundedunit +1;};
						}Foreach units _npc;
					}
					else
					{
						_sokilled = true;
						UPSMON_GOTKILL_ARRAY = UPSMON_GOTKILL_ARRAY - [_grp];
					};
					UPSMON_GOTHIT_ARRAY = UPSMON_GOTHIT_ARRAY - [_grp];
				};
			};
		
		//Variables to see if the leader is in a vehicle
		_isman = "Man" countType [ vehicle _npc]>0;
		_incar = "LandVehicle" countType [vehicle (_npc)]>0;
		_inheli = "Air" countType [vehicle (_npc)]>0;
		_inboat = "Ship" countType [vehicle (_npc)]>0;
		_isdiver = ["diver", (typeOf (leader _npc))] call BIS_fnc_inString;

	
		If (count(waypoints _grp) != 0) then
		{
			_wppos = waypointPosition [_grp,count(waypoints group _npc)-1];
			_targetpos = _wppos;
			_wptype = waypointType [_grp,count(waypoints _grp)-1];
			_targetdist = [_currpos,_targetpos] call UPSMON_distancePosSqr;
			_traveldist = _targetdist;
		};

		// if the AI is a civilian we don't have to bother checking for enemy encounters
		if (_isSoldier) then 
		{
			_linkactivate = false;
			_pursue = false;
			_smokeunits = [];
			_smoke = false;
			_smokepos = [];
			_outbuilding = true;
			_haslos = false;
			
			_terrainscan = (getposATL _npc) call UPSMON_sample_terrain;
			_unitsneedammo = [_npc] call UPSMON_checkmunition;
			_grpcomposition = [_grp] call UPSMON_analysegrp;
			_teams = [_grp] call UPSMON_composeteam;
			_typeofgrp = _grpcomposition select 0;
			_capacityofgrp = _grpcomposition select 1;
			_assignedvehicle = _grpcomposition select 2;
			
			_assltteam = _teams select 0;
			_Supportteam = _teams select 1;
			_Atteam = _teams select 2;
			_AAteam = _teams select 3;
			
			_artillerysideunits = UPSMON_ARTILLERY_WEST_UNITS;
			_artillerysideFire = call (compile format ["UPSMON_ARTILLERY_%1_FIRE",_side]);
			switch (_side) do 
			{
				case West: 
				{
					_artillerysideunits = UPSMON_ARTILLERY_WEST_UNITS;
				};
				case EAST: 
				{
					_artillerysideunits = UPSMON_ARTILLERY_EAST_UNITS;
				};
				case resistance: 
				{
					_artillerysideunits = UPSMON_ARTILLERY_GUER_UNITS; 
				};
	
			};
			
			
			// set target tolerance high for choppers & planes
			if ("air" in _typeofgrp) then {_closeenough = UPSMON_closeenough * 2};
			
			//=====================================================================================================
			// REFINFORCEMENT = true
			//=====================================================================================================	
			//If the group is strengthened and the enemies have been detected are sent to target
			
			if (_reinforcement == "REINFORCEMENT" || _rfid > 0) then 
			{
				switch (_side) do 
				{
					case West: 
					{
						if (!(_grp in UPSMON_REINFORCEMENT_WEST_UNITS) && !_reinforcementsent && IsNull _target) then  {UPSMON_REINFORCEMENT_WEST_UNITS = UPSMON_REINFORCEMENT_WEST_UNITS + [_grp]};	
					};
					case EAST: 
					{
						if (!(_grp in UPSMON_REINFORCEMENT_EAST_UNITS) && !_reinforcementsent && IsNull _target) then  {UPSMON_REINFORCEMENT_EAST_UNITS = UPSMON_REINFORCEMENT_EAST_UNITS + [_grp]};
					};
					case resistance: 
					{
						if (!(_grp in UPSMON_REINFORCEMENT_GUER_UNITS) && !_reinforcementsent && IsNull _target) then  {UPSMON_REINFORCEMENT_GUER_UNITS = UPSMON_REINFORCEMENT_GUER_UNITS + [_grp]};		
					};
	
				};
			};			
			
			if (_rfid > 0 ) then 
			{
				_rfidcalled = false; // will be TRUE when variable in triger will be true.
				if !(isnil (compile format ["UPSMON_reinforcement%1",_rfid])) then {_rfidcalled= call (compile format ["UPSMON_reinforcement%1",_rfid])};													
			};
		
			//Reinforcement control
			if (_reinforcement == "REINFORCEMENT" || _rfid > 0) then 
			{
				// (global call  OR id call) AND !send yet
				if ( (UPSMON_reinforcement || _rfidcalled) && (!_reinforcementsent)) then 
				{				
					If (_rfidcalled) then 
					{
						_fixedtargetPos = call (compile format ["UPSMON_reinforcement%1_pos",_rfid]); // will be position os setfix target of sending reinforcement
						if (isnil "_fixedtargetPos") then 
						{
							_fixedtargetPos =[0,0];
						}else{
							_fixedtargetPos =  [abs(_fixedtargetPos select 0),abs(_fixedtargetPos select 1),0];
						};
					} 
					else 
					{
						_fixedtargetPos = _grp getvariable "UPSMON_PosToRenf";
					};
				
					If ((_fixedtargetPos select 0 != 0 && _fixedtargetPos select 1 != 0) && (_lastpos select 0 != _fixedtargetPos select 0 && _lastpos select 1 != _fixedtargetPos select 1)) then 
					{ 
						_reinforcementsent=true;
						_fortify = false;
						_minreact = UPSMON_minreact;			
						_react = _react + 100;					
						_nowp = false;
						_targetpos = _fixedtargetPos;
						_grpmission = "REINF";
						
						[_grp,_fixedtargetpos,_dist,_typeofgrp] call UPSMON_DOREINF;
					};
					//if (UPSMON_Debug>0) then {player sidechat format["%1 called for reinforcement %2",_grpidx,_fixedtargetPos]};	
				};
			};
		//----------- END REINFORCEMENT -------------

			
//*********************************************************************************************************************
// 											ACQUISITION OF TARGET 	
//*********************************************************************************************************************		
	
		_Enemies = [];
	
		_TargetSearch 	= [_grp,_shareinfo,_closeenough,_timeontarget,_timeinfo,_react] call UPSMON_TargetAcquisition;
		_Enemies 		= _TargetSearch select 0;
		_Allies 		= _TargetSearch select 1;
		_target 		= _TargetSearch select 2;
		_dist 			= _TargetSearch select 3;
		_opfknowval 	= _TargetSearch select 4;
		_targetsnear 	= _TargetSearch select 5;
		_attackPos 		= _TargetSearch select 6;
		_timeontarget 	= _TargetSearch select 7;
		_timeinfo 		= _TargetSearch select 8;
		_react			= _TargetSearch select 9;
		_accuracy		= _TargetSearch select 10;

		if (UPSMON_Debug>0) then {diag_log format ["group:%1 target:%2 dist:%3 opfknowval:%4 targetsnear:%5 attackPos:%6 timeinfo:%7",_grpidx,_target,_dist,_opfknowval,_targetsnear,_attackPos,_timeinfo];};
	
		//If knowledge of the target increases accelerate the reaction
		if (_opfknowval > _lastknown) then {
			_react = _react + 20;
		};
	
		if ((_sowounded || _gothit || _sokilled || _supressed) && (_grpmission != "RETREAT" || _grpmission != "AMBUSH" || _grpmission != "FORTIFY")) then 
		{ 
			if (!_supressed) then {_react = _react + 30};
			if (_nowp && _nowpType != 3) then 
			{
				_nowp = false;
			};
		};
		
		
		//Check _target and capacity of the group
		if ((!IsNull _target) && (_grpmission != "AMBUSH") && (_grpmission != "RETREAT")) then 
		{	
			
			_haslos = [_currpos,_attackPos] call UPSMON_los;
			if (_colorstatus != "YELLOW") then 
			{
				_timeontarget = time;
				_colorstatus = "YELLOW";
				_react= UPSMON_react;	
				if (UPSMON_Debug>0) then {player sidechat format["%1: Enemy detected %2",_grpidx, typeof _target]}; 	
				
				if (_nowp && _nowpType == 1) then {
					_nowp = false;
				};
			};	

			//Analyse Targets && Allies
			_Situation = [_grp,_Allies,_Enemies] call UPSMON_Checkratio;
			_ratio = _Situation select 0;
			_itarget = _Situation select 1;
			
			//If use statics are enabled leader searches for static weapons near or fire artillery.
			// Tanks enemies are contabiliced
			
			// Check if there are big targets (tank, APC, static or Air unit)
			_enemytanksnear = false;
			_enemyStaticsnear = false;
			_enemyAirsnear = false;
			_enemytankposition = [0,0];
			_enemyStaticposition = [0,0];
			_enemyAirposition = [0,0];
				
			{
				if ((typeof (vehicle (_x select 0))) iskindof "TANK" || (typeof (vehicle (_x select 0))) iskindof "Wheeled_APC")
					exitwith { _enemytanksnear = true; _enemytanknear = (_x select 0); _enemytankposition = (_x select 1);};
					
				if ((typeof (vehicle (_x select 0))) iskindof "StaticWeapon")
					exitwith { _enemyStaticsnear = true; _enemyStaticnear = (_x select 0);_enemyStaticposition = (_x select 1);};
					
				if ((typeof (vehicle (_x select 0))) iskindof "Air")
					exitwith {_enemyAirsnear = true; _enemyAirnear = (_x select 0);_enemyAirposition = (_x select 1);};	
			} foreach _itarget;
			
			// Check if group can defeat them
			If (_enemytanksnear) then
			{
				if (!(isnull _enemytanknear) && alive _enemytanknear) then
				{
					If ((typeof (vehicle _enemytanknear)) iskindof "TANK") then
					{
						If ("at2" in _capacityofgrp || "at3" in _capacityofgrp) then
						{
							_hascapacity = true;
							If (_enemytanknear != _target && !_targetsnear) then {_target = _enemytanknear; _attackPos = _enemytankposition; _dist = ([_currpos,_attackPos] call UPSMON_distancePosSqr);};
						}
						else
						{
							_hascapacity = false;
						};
						
						if (!_hascapacity && UPSMON_useMines && !_supressed) then
						{
							_ATmine = false;
							_Atunit = ObjNull;
							
							{If (alive _x && ("ATMine" in (magazines _x))) exitwith {_ATmine = true; _Atunit = _x;};} foreach units _grp;
							
							if (_ATmine) then
							{
								_friendlytanksnear = false;
								{
									if ("Tank" countType [vehicle (_x select 0)] > 0 || "Wheeled_APC" countType [vehicle (_x select 0)] >0) then
									{
										if (alive _x && canMove _x) then
										{
											If (_npc distance _x <= _closeenough + UPSMON_safedist) exitwith
											{
												_friendlytanksnear = true;
											};
										};
									};
								} foreach _Allies;
								
								if (!_friendlytanksnear && random(100)<40 ) then 
								{
									_dir1 = [_currPos,position _enemytanknear] call UPSMON_getDirPos;
									_mineposition = [position _npc,_dir1, 25] call UPSMON_GetPos2D;	
									_roads = _mineposition nearroads 50;
									if (count _roads > 0) then {_mineposition = position (_roads select 0);};
									[_npc,_mineposition] call UPSMON_CreateMine;													
								};	
							};
						};
					}
					else
					{
						If ("at2" in _capacityofgrp || "at3" in _capacityofgrp || "at1" in _capacityofgrp) then
						{
							_hascapacity = true;
							If (_enemytanknear != _target && !_targetsnear) then {_target = _enemytanknear; _attackPos = _enemytankposition; _dist = ([_currpos,_attackPos] call UPSMON_distancePosSqr);};
						}
						else
						{
							_hascapacity = false;
						};
					};
				};
				if (!_hascapacity) then
				{
					if (round([_currpos,_enemytankposition] call UPSMON_distancePosSqr) > 300) then
					{
						_hascapacity = true;
					};
				};
			};

			If (_enemyAirsnear) then
			{
				if (!(isnull _enemyAirnear) && alive _enemyAirnear) then
				{
					If ("aa2" in _capacityofgrp || "aa1" in _capacityofgrp) then
					{
						If (_enemyAirnear != _target && !_targetsnear) then 
						{
							_target = _enemyAirnear; 
							_attackPos = _enemyAirposition; 
							_dist = ([_currpos,_attackPos] call UPSMON_distancePosSqr);
							_cansee = [_currpos,_attackPos] call UPSMON_los;
							If (_cansee) then
							{
								if (count _AAteam > 0) then
								{
									{
										_x dotarget ObjNull;
										_x dotarget _target;
									} foreach _AAteam;
								};
							};
						};
					};
				};
			};
			if (UPSMON_Debug>0) then {diag_log format ["group:%1 hascapacity:%2 ratio:%3 react:%4 lastreact:%5 haslos:%6",_grpidx,_hascapacity,_ratio,_react,_lastreact,_haslos];};
//////////////////////////////////////////////////////////////////////////////////////////		
//////////// ARTI REACTION ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////
			// If the group is in inferiority call artillery
			_nbrTargets = [_target,50,_side] call UPSMON_checksizetargetgrp;
			_nbrTargets = count _nbrTargets;
			_outbuilding = [_target] call UPSMON_inbuilding;
	
			If (_artillerysideFire) then
			{
				If (_RadioRange > 0) then
				{
					If (count _artillerysideunits > 0) then
					{
						If (_timeartillery >= 30) then
						{
							If (!(_target iskindof "Air")) then
							{
								//!([_npc,_target,_dist,130] call UPSMON_Haslos)
								If (_accuracy > 150) then
								{
									If (UPSMON_Night) then
									{
										If (!(UPSMON_FlareInTheAir)) then
										{
											If (!("armed" in _typeofgrp)) then
											{
												// Ask for Flare if night and don't know enough about eny
												_timeartillery = 0;
												[_artillerysideunits,"FLARE",_RadioRange,_currpos,_attackpos,3,60] spawn UPSMON_Artyhq;
											};
										};
									};
								}
								else
								{
									_artitarget = _attackpos;
									if (_enemytanksnear
										&&!(isnull _enemytanknear)
										&& alive _enemytanknear
										&& ((speed _enemytanknear) <= 5)
										&& !_hascapacity) then
									{
										_artitarget = getposATL _enemytanknear;
									}
									else
									{
										If (_enemyStaticsnear 
											&& !(isnull _enemyStaticnear)
											&& alive _enemyStaticnear) then 
										{
											_artitarget = getposATL _enemyStaticnear;
										};
									};
									
									If (_dist >= 200) then
									{
										_timeartillery = 0;
										[_artillerysideunits,"HE",_RadioRange,_currpos,_artitarget,3,_accuracy] spawn UPSMON_Artyhq;								
									};
									
								};
							};
						};
					};
			
				};
			};	
			
//////////////////////////////////////////////////////////////////////////////////////////		
//////////// REINFORCEMENT ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////
			if (UPSMON_Debug>0) then {diag_log format["Artillery condition artillerysideFire: %1 RadioRange: %2 Knowval: %3 timeartillery: %4 nbrTargets: %5",_artillerysideFire,_RadioRange,_npc knowsabout _target,_timeartillery,_nbrTargets]};
	
				//if (UPSMON_Debug>0) then {diag_log format["Reinforcement condition Supressed: %1 Morale: %2 members: %3 unit: %4 Wounded: %5 Targets: %6 reinforcementSent : %7 Reinforcement: %8",_supressed,morale _npc,count _members, count (units _npc),_nbrwoundedunit,(_nbrTargets > (count units _npc) *2),_reinforcementsent,UPSMON_reinforcement]};
				If (!_reinforcementsent && UPSMON_reinforcement) then
				{
					If (!("air" in _typeofgrp) && !("ship" in _typeofgrp)) then
					{
						If (!_hascapacity || _ratio >= 1) then
						{
							if (UPSMON_Debug>0) then {diag_log format["%1 ask for reinforcement",_grpid]};
							[getposATL _npc,_attackpos,_radiorange,_side,_Enemies,_nbrTargets,_enemytanknear,_grp] spawn UPSMON_Askrenf;
							_reinforcementsent = true;
						};
					};
				};
				
//////////////////////////////////////////////////////////////////////////////////////////		
//////////// SURRENDER ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////
			
			//Checks if surrender is enabled
			If (UPSMON_SURRENDER) then
			{
				If (("Air" countType [vehicle (_target)]) == 0) then
				{
					If ("infantry" in _typeofgrp) then
					{
						If (alive _npc) then
						{
							If ((random 100) <= _surrender) then
							{
								If (_ratio > 2 && _haslos && _dist <= 100 && (({alive _x} count (units _grp)) == count ((_unitsneedammo) select 0) || _sowounded || _supressed)) then
								{
									_surrended = true;
								};
							};
						};
					};
				};
			};
	
			//If surrended exits from script
			if (_surrended) exitwith 
			{	
				{
					[_x] spawn UPSMON_surrended;
				} foreach units _grp;
				if (_grp in UPSMON_NPCs) then {UPSMON_NPCs = UPSMON_NPCs - [_grp]};
				if (UPSMON_Debug>0) then {diag_log format["%1: %2 SURRENDED",_grpidx,_side]};		
			};
			
		}; // Target and group Check
		
		//Ambush ==========================================================================================================
		if (_grpmission == "AMBUSH") then 
		{
			_nowp = true;
			_linkdistance = 1000;
			
			_linked = if ("LINKED:" in _UCthis) then {true} else {false};
			_linkdistance = ["LINKED:",_linkdistance,_UCthis] call UPSMON_getArg;
			_ambush2 = if ("AMBUSH2:" in _UCthis || "AMBUSH2" in _UCthis || "AMBUSHDIR2:" in _UCthis) then {true} else {false};
			_positionambushed = _grp getvariable "UPSMON_Positiontoambush";
			_ambushdistance = [_currpos,_positionambushed] call UPSMON_distancePosSqr;
			_targetdistance = 1000;
			_targetknowaboutyou = 0;
			
			if (!isnull _target) then {_targetdistance = [_currpos,getposATL _target] call UPSMON_distancePosSqr;_targetknowaboutyou = _target knowsabout _npc;}; 
			//Ambush enemy is nearly aproach
			//_ambushdist = 50;		
			// replaced _target by _NearestEnemy
		
			If (_linked) then 
			{
				{
					If (side _x == _side) then
					{
						If (round ([_currpos,getposATL (leader _x)] call UPSMON_distancePosSqr) <= _linkdistance) then
						{
							If (_x getvariable "UPSMON_AMBUSHFIRE") 
							exitwith {_linkactivate = true};
						};
					};
				} foreach UPSMON_NPCs
			};
			 
			_ambushwait = _grp getvariable ["UPSMON_Ambushwait",time];
			
			If ((_gothit || _linkactivate || _ambushwait < time)
				|| ((!isNull _target && "Air" countType [_target]<=0)
					&& ((_targetdistance <= _ambushdistance)
						||(round ([getposATL _target,_positionambushed] call UPSMON_distancePosSqr) < 10) 
						|| (_npc knowsabout _target > 3 && _ambush2)))) then
			{
				sleep ((random 0.5) + 1); // let the enemy then get in the area 
				
				if (UPSMON_Debug>0) then {diag_log format["%1: FIREEEEEEEEE!!! Gothit: %2 linkactivate: %3 Distance: %4 PositionToAmbush: %5 AmbushWait:%6 %7",_grpidx,_gothit,_linkactivate,(_targetdistance <= _ambushdistance),_target distance (_grp getvariable "UPSMON_Positiontoambush") < 20,_ambushwait <= 0,(_npc knowsabout _target > 3 && _ambush2)]};
			
				_npc setBehaviour "COMBAT";
				_npc setcombatmode "YELLOW";
				
				{
					If !(isNil "bdetect_enable") then {_x setVariable ["bcombat_task", nil];};
				} foreach units _grp;
				
				_grp setvariable ["UPSMON_AMBUSHFIRE",true];
				_alertpos = _grp getvariable "UPSMON_Positiontoambush";
				_nowp = false;
				_linkactivate = false;
								
				//No engage yet
				_grpmission = "DEFEND";
			};			
		}; 
		
		//END Ambush ==========================================================================================================	
		
		// FORTIFY ============================================================================================================
		if (_grpmission == "FORTIFY") then 
		{
			if (behaviour _npc in _safemode) then {_npc setbehaviour "AWARE"};
			If (!(IsNull _target) && !(_grp getvariable ["UPSMON_Checkbuild",false])) then
			{
				if (behaviour _npc != "COMBAT") then {_npc setbehaviour "COMBAT"};
				[_grp,_dist,_supressed] call UPSMON_unitdefend;
			};
		};
		// END FORTIFY ==========================================================================================================
		
		// RETREAT ==============================================================================================================
		If (_grpmission == "RETREAT") then
		{
			If (_targetdist <= 10) then
			{
				_grpmission = "DEFEND";				
			};
		};		
		// END RETREAT ==============================================================================================================
		
		
		//If no fixed target check if current target is available
		if (_fixedtargetPos select 0 != 0 && _fixedtargetPos select 1 != 0) then 
		{	
			//If fixed target check if close enough or near enemy and gothit
			if (([_currpos,_fixedtargetpos] call UPSMON_distancePosSqr) < 300 && _grpmission != "PATROLSRCH") then 
			{	
				_grpmission = "PATROLSRCH";
				_colorstatus = "BLUE";
				_alertpos = _targetpos;
				_timeonalert = time + UPSMON_alerttime;
				_timeontarget = time + 90;
			} else {
				if (_grpmission == "PATROL") then
				{
					_grpmission = "REINF";
				};
			};
		};	
		
		If (("static" in _typeofgrp || (_grp getVariable ["UPSMON_OnBattery",false])) && !_nowp) then
		{
			_grpmission = "DEFEND";
		};
		
//*********************************************************************************************************************
// 											COMBAT ORDERS	
//*********************************************************************************************************************	
		If (!_nowp && !(fleeing _npc) && _grpmission != "RETREAT") then
		{
			if (IsNull _target) then
			{	
				If (!("air" in _typeofgrp)) then
				{
					If (_sowounded || _gothit || _sokilled || _supressed) then
					{
						_colorstatus = "BLUE";
						_grpmission = "DEFEND";
						_alertpos = _currpos;
					};
				};
			

				If (_colorstatus != "GREEN") then
				{
					if (_lastreact <= time) then
					{
						if ((_lastgrpmission == "DEFEND" || _lastgrpmission == "ATTACK") && _grpmission != "PATROLSRCH") then
						{
							_makenewtarget = false;
							_grpmission = "PATROLSRCH";			
							_colorstatus = "BLUE";
							_timeonalert = time + UPSMON_alerttime;
						}
						else
						{
							if (time >= _timeonalert) then
							{
								_grpmission = "PATROL";
								_Behaviour = _orgMode;
								_colorstatus = "GREEN";
								_target = objnull;
								_timeonalert = time;
								_alertpos = [0,0];
							};
						};
					};
				};
				
			}
			else
			{
				
				if (_colorstatus != "YELLOW" ) then 
				{
					_timeontarget = time;
					_colorstatus = "YELLOW";
					_react= UPSMON_react;	
					if (UPSMON_Debug>0) then {player sidechat format["%1: Enemy detected %2",_grpidx, typeof _target]}; 	
				};	
				// If unit has target make them fight unless they have a nowp2 or 3 parameter or fortify and not flee
				if (!(fleeing _npc)) then 
				{
					
					if ((_react >= UPSMON_react && _lastreact <= time) || _lastgrpmission != "ATTACK" || count (waypoints _grp) == 0) then
					{
						if (UPSMON_Debug>0) then {diag_log format["%1: attack Target",_grpidx]};
						_grpmission = "ATTACK";
						_pursue = true;
					};
				};

				if (!("air" in _typeofgrp)) then
				{
					if (_supressed || !_hascapacity || _ratio > 1.2) then
					{
						if (UPSMON_Debug>0) then {diag_log format["UPSMON: gothit: group %1 supressed by fire so defend",_grpidx]};											
						_grpmission = "DEFEND";							
					}
					else
					{

						if (_haslos) then
						{
							If ((_grpcomposition select 3) <= _dist) then
							{
								if ("staticbag" in _capacityofgrp && !("static" in _typeofgrp) && !(_grp getvariable ["UPSMON_Mountstatic",false])) then
								{
									if (_dist > 300) then
									{
										_checkforstatic = [_grp] call UPSMON_GetStaticTeam; 
										_staticteam = _checkforstatic select 0;
										if (count _staticteam == 2) then
										{
											{
												If (alive _x && vehicle _x != _x && !((vehicle _x) getvariable ["UPSMON_disembarking",false])) then 
												{
													[vehicle _x] spawn UPSMON_dodisembark;
													_time = time + 90;
													waituntil {vehicle _x == _x || !alive _x || time >= _time};
												};
												If (!alive _x) exitwith {};
											} foreach _staticteam;
											_grpmission = "DEFEND";
											[_staticteam select 0,_staticteam select 1,_currpos,_attackpos] spawn UPSMON_Unpackbag;
										};
									};
								};
							};
						};					
					};
					
					if (_ratio > 3) then
					{
						if ((_dist > 150 && !_haslos) || _dist > 400) then
						{
							_grpmission = "RETREAT";
						};
					};
				};

				if ( _dist <= _closeenough ) then 
				{	
					if (_dist <= _closeenough/2) then
					{
						_minreact = UPSMON_minreact/1.5;
					}
					else
					{
						_minreact = UPSMON_minreact/0.5;
					};
				} 
				else	
				{	
					//In May distance of radio patrol act..
					if (( _dist <= 1000 )) then 
					{
						_minreact = UPSMON_minreact;
					} 
					else 
					{
						//Platoon very far from the goal if not move nomove role
						_minreact = UPSMON_minreact;						
												
					};	
				};
				
			}; // TArget Or Not Target
			
			
			if ("arti" in _typeofgrp) then
			{
				_support = _grp getVariable "UPSMON_ArtiOptions";
				If (!IsNull _target || (_gothit || _sowounded || _sokilled) && (_support select 0)) then
				{
					_support set [0,true];
					_grp setVariable ["UPSMON_ArtiOptions",_support];
					_grpmission = "DEFEND";
				}
				else
				{
					If (IsNull _target) then
					{
						If (!(_grp getVariable ["UPSMON_OnBattery",false]) && !(_support select 0)) then
						{
							_support set [0,false];
							_grp setVariable ["UPSMON_ArtiOptions",_support];
							_grpmission = "PATROL";
						};
					};
				};
			};
			
			If (!IsNull _target || _gothit) then 
			{
				If ((_terrainscan select 0) == "inhabited") then
				{
					If (behaviour _npc != "STEALTH") then {_npc setbehaviour "STEALTH"};
					If (speedmode _grp != "LIMITED") then {_grp setspeedmode "LIMITED"};
				};
				If ((_terrainscan select 0) == "meadow" && _dist > 300) then
				{
					If (behaviour _npc != "AWARE") then {_npc setbehaviour "AWARE"};
					If (speedmode _grp != "FULL") then {_grp setspeedmode "FULL"};
				};
				If (_dist < 200) then
				{
					If (behaviour _npc != "COMBAT" || behaviour _npc != "STEALTH") then {_npc setbehaviour "COMBAT"};
				};
			};
			
			// UPSMON GROUP DEFEND Their position
			if (_grpmission == "DEFEND" && (_lastgrpmission != "DEFEND")) then 
			{
				_react= 0;
				_lastreact = time + _minreact;
				if (UPSMON_Debug>0) then {diag_log format["UPSMON: Group %1 is in defense",_grpidx]};
				[_grp,_dist,_target,_grpid,_attackpos,_supressed,_terrainscan] spawn UPSMON_DODEFEND;
			};

			// UPSMON GROUP ATTACK AND PURSUE NEAREST TARGET
			if (_pursue && !(_grp getvariable ["UPSMON_searchingpos",false])) then 
			{		
				if (UPSMON_Debug>0) then {diag_log format["UPSMON: Group %1 is in pursue",_grpidx]};  	
				_react = 0;
				_lastreact = time + _minreact;
				_timeontarget = time + UPSMON_maxwaiting; 
				_grp setvariable ["UPSMON_Cover",false];
				// did the leader die?
				_npc = [_npc,_grp] call UPSMON_getleader;							
				if (!alive _npc || isplayer _npc  || _grp getvariable ["UPSMON_Removegroup",false]) exitwith {[_grp,_Ucthis,_orgpos,_surrended,_grpidx,_membertypes,_vehicletypes,_side] call UPSMON_Respawngrp;};
			
				[_grp,_attackPos,_dist,_grpid,_nofollow,_typeofgrp,_terrainscan,_areamarker,_side,_haslos] spawn UPSMON_DOATTACK;
				
				if ((_grpcomposition select 3) >= _dist && _haslos) then
				{
					if ((_terrainscan select 0) == "meadow") then
					{
						_smoke = true;
						_smokeunits = units _grp;				
					};
				};
				
				if (_wptype == "SAD") then
				{
					if (_dist <= 20 && (_terrainscan select 0) == "inhabited") then
					{
						if (_timeonbld < time) then
						{
							_grpmission = "PATROLINBLD";
						};
					};
				};
			};	
			
			If (_grpmission == "PATROLSRCH") then
			{
				_timeontarget = time + 90;
				If (time < _timeonalert) then
				{
					If ((_targetdist <= 5 || moveToFailed _npc || moveToCompleted _npc) || ((_targetdist <= (20 + ((GetposATL _npc) select 2))) && ("air" in _typeofgrp || "tank" in _typeofgrp || "car" in _typeofgrp))) then 
					{
						_grp setvariable ["UPSMON_Cover",false];
						if (behaviour _npc in _safemode) then
						{
							_npc setbehaviour "AWARE";
							_npc setspeedmode "NORMAL";
						};
						If (!(_grp getvariable ["UPSMON_searchingpos",false])) then 
						{
							If ((_terrainscan select 0) == "inhabited" && _lastgrpmission != "PATROLINBLD" && _timeonbld < time) then
							{
								_grpmission = "PATROLINBLD";
							}
							else
							{
								if (UPSMON_Debug>0) then {diag_log format["%1: Target lost in %2",_grpidx,_targetpos]};
								If (count (waypoints _grp) == 0 || _lastgrpmission == "PATROLINBLD") then
								{
									[_grp,_alertpos,_grpid,_nofollow,_typeofgrp,_areamarker,_side] spawn UPSMON_DORESEARCH;
								};
							};
						};
					};
				};
			};			

			If (_grpmission == "PATROLINBLD") then
			{
				If (count _assltteam > 0) then
				{
					If (IsNull _target) then {[_grp,_currpos,"HOLD","DIAMOND","NORMAL","AWARE","YELLOW",1] spawn UPSMON_DocreateWP;};
					_bats = [_npc,50,true,30,false,_assltteam] call UPSMON_moveNearestBuildings;
					if (count _bats > 0) then {_timeonbld = time + 120;};
				};
			};
	
///////////////////////////////////////////////	
//////////////////// RETREAT /////////////////////////
///////////////////////////////

			If ((random 100) <= _retreat) then
			{
				if (_grpmission == "RETREAT") then
				{
					If (!IsNull _target) then
					{
						If (_artillerysideFire) then
						{
							If (_RadioRange > 0) then
							{
								if (!(_target iskindof "Air")) then
								{
									If (count _artillerysideunits > 0) then
									{
										If (_dist >= 200) then
										{
											If (_timeartillery >= 30) then 
											{
												_timeartillery = 0;
												[_artillerysideunits,"WP",_RadioRange,_currpos,_attackpos,6,100] spawn UPSMON_Artyhq;
											};
										};
									};
								};
							};
						};		
					};
			
					if (!IsNull _target) then {_smokepos = _attackpos;};
					_smoke = true;
					_smokeunits = units _grp;
			
					_AttackPos2 = _AttackPos;
					If (IsNull _target) then {_AttackPos2 = [0,0];};
			
					[_grp,_AttackPos2] spawn UPSMON_DORETREAT;
				};	
			};
		
			// use smoke when hit or s/o killed	
			//If under attack or increasing knowledge speeds up the response and regain control of the AI
			if (!_nosmoke && random 100 < UPSMON_USE_SMOKE && _smoke) then 
			{	
				{						
					If (alive _x && ("SmokeShell" in (magazines _x)) && _x == vehicle _x) then
					{
						If (count _smokepos == 0) then {_smokepos = [_currpos,random 360,random 100 +50] call UPSMON_GetPos2D;};
						nul= [_x,_smokepos] spawn UPSMON_throw_grenade;
					};
				} foreach _smokeunits;
			};
		};
		
		If (count(waypoints _grp) != 0) then
		{
			_targetpos = waypointPosition [_grp,count(waypoints group _npc)-1];
			_wptype = waypointType [_grp,count(waypoints _grp)-1];
			_targetdist = [_currpos,_targetpos] call UPSMON_distancePosSqr;
			_traveldist = _targetdist;
		};
	}; // End Soldier
	
//*********************************************************************************************************************
// 											PATROL ORDERS	
//*********************************************************************************************************************	

		if (!_nowp && !(fleeing _npc)) then
		{
			//If in safe mode if find dead bodies change behaviour
			if ((_colorstatus == "GREEN") && _deadBodiesReact)then 
			{
				_unitsin = [_npc,_buildingdist] call UPSMON_deadbodies;
				//_firenear = _npc getvariable "UPS_hear" select 0;
				//|| _firenear
				if (count _unitsin > 0) then { 
					if (!_isSoldier) then 
					{
						_npc setSpeedMode "FULL";					
					} 
					else 
					{
						If (behaviour _npc in _safemode) then
						{
							_npc setBehaviour "AWARE";
							_grp setSpeedMode "LIMITED";
							if (UPSMON_Debug>0) then {player sidechat format["%1 dead bodies found! set %2",_grpidx,_Behaviour]};
						};
					}; 
				};
			};
			
			
			if (_grpmission != "DEFEND") then
			{	
				//Stuck control
				If (alive _npc) then
				{
					If (canmove _npc) then
					{
						If (_lastcurrpos select 0 == _currpos select 0 && _lastcurrpos select 1 == _currpos select 1) then
						{
							If (time > _timeontarget) then
							{
								If (!(_npc getvariable ["UPSMON_searchingpos",false])) then
								{
									If (!(_grp getVariable ["UPSMON_movetolanding",false])) then
									{
										If (!(_grp getvariable ["UPSMON_embarking",false])) then 
										{
											If (!((vehicle _npc) getvariable ["UPSMON_disembarking",false])) then
											{
												If (!("Air" countType [vehicle (_npc)]>0)) then
												{
													_rstuckControl = _rstuckControl + 2;
													
													If (_rstuckControl >= 4) then 
													{
														[_npc] call UPSMON_cancelstop;
														{if (alive _x && leader _x != _x) then {_x dofollow (leader _x)};} foreach units _grp;
																				
														_makenewtarget = true;
		
														if (UPSMON_Debug>0) then {player sidechat format["%1 stucked, moving",_grpidx]};	
														if (UPSMON_Debug>0) then {diag_log format["%1 stuck for %2 seconds - trying to move again",_grpidx, _timeontarget]};
														If (_rstuckControl >= 6) then
														{
															_rstuckControl = 0;
															If (vehicle _npc != _npc) then
															{
																_jumpers = crew (vehicle _npc);
																{
																	_x spawn UPSMON_doGetOut;	
																	sleep 0.5;
																} forEach _jumpers;
															}
															else
															{
																_npc Domove _targetpos;
																{if (alive _x && leader _x != _x) then {_x dofollow (leader _x)};} foreach units _grp;
															};
														};
													};
												};
											};
										};
									};
								};
							};
						};
					};
				};
			};
	
			if (_grpmission == "PATROL" && !(_grp getVariable ["UPSMON_OnBattery",false])) then 
			{
				_gothit = false;
				_timeonalert = 0;
				_speedmode = _orgSpeed;
				_behaviour = _orgMode;
				_wpformation = _orgformation;
				
				_reinforcementsent=false;
				If (_reinforcement == "REINFORCEMENT"|| _rfid > 0) then
				{
					_fixedtargetPos = [0,0];
					if (_rfid > 0) then 
					{
						call (compile format ["UPSMON_reinforcement%1_pos = [0,0]",_rfid]);
						call (compile format ["UPSMON_reinforcement%1 = false",_rfid]);
						if (UPSMON_Debug>0) then {player sidechat format["%1 reinforcement canceled",_grpidx]};	
					};
					_grp setvariable ["UPSMON_PosToRenf",[0,0]];
				};
				
				//(group _npc) enableAttack false;
				If (!(_grp getvariable ["UPSMON_searchingpos",false])) then
				{
					If (!([_targetpos,_areamarker] call UPSMON_pos_fnc_isBlacklisted)
						|| _targetdist <= 5 || moveToFailed _npc || moveToCompleted _npc || count(waypoints _grp) == 0 
						||((("tank" in _typeofgrp) || ("ship" in _typeofgrp) || ("apc" in _typeofgrp) ||("car" in _typeofgrp)) && _targetdist <= 25)
						|| ((_inheli && !(_grp getVariable ["UPSMON_movetolanding",false])) && (_targetdist <= (30 + (_currpos select 2))))) then
					{
						_makenewtarget=true;
					};
				};
				
				if (_makenewtarget) then
				{
					_gothit = false;
					_react = 0;		
					_lastreact = time;	
					_makenewtarget = false;				
					_timeontarget = time + 20; 
				
					[_grp,_wpformation,_speedmode,_areamarker,_dist,_onroad,_grpid,_Behaviour,_combatmode,_typeofgrp] spawn UPSMON_DOPATROL;
				};
			};
		
///////////////////////////////////////////////////////////////////////////
///////////					Disembarking 				//////////////////
//////////////////////////////////////////////////////////////////////////
			If (!((vehicle _npc) getvariable ["UPSMON_disembarking",false])) then
			{
				If (_issoldier && !(_grp getvariable ["UPSMON_searchingpos",false])) then
				{
					If (_targetpos select 0 != 0 && _targetpos select 1 != 0) then 
					{
						If (count _assignedvehicle > 0) then
						{
							//If (!((behaviour _npc) in _safemode) || _inothervehsquad) then
						
							//Check if vehicle is stucked or enemy unit near and has a cargo
							{
								_vehicle = vehicle _x;
								if (UPSMON_Debug>0) then {diag_log format ["%1 %2 %3 %4",_assignedvehicle,_vehicle iskindof "air",_vehicle iskindof "StaticWeapon",(_vehicle iskindof "MAN")];};
								if (!(_vehicle iskindof "AIR") && !(_vehicle iskindof "StaticWeapon") && !(_vehicle iskindof "MAN")) then
								{
									_get_out_dist = UPSMON_closeenoughV  * ((random .4) + 1);
									If (_vehicle iskindof "TANK" || _vehicle iskindof "Wheeled_APC_F" || !(IsNull (gunner _vehicle))) then {_get_out_dist = UPSMON_closeenough  * ((random .4) + 0.8);};
									_unitsincargo = [_vehicle] call UPSMON_FN_unitsInCargo;
									_disembarking = _vehicle getvariable ["UPSMON_disembarking",false];
									if (UPSMON_Debug>0) then {diag_log format ["time:%1 lasttime: %2 targetdist:%3 Cargo:%4 _get_out_dist:%5",time, _vehicle getvariable "UPSMON_disembarking",_targetdist,_unitsincargo,_get_out_dist];};
									
									If ((behaviour _npc) in _safemode) then {_targetdist = 10000};
									
									if (!(_disembarking)) then
									{
										if (!(canmove _vehicle) 
											|| !(alive (driver _vehicle))
											|| ((_dist <= _get_out_dist || _gothit || _targetdist <= (200 * ((random .4) + 1))) && count _unitsincargo > 0)) then
										{
											[_vehicle] spawn UPSMON_dodisembark;
										};
									};
								} foreach _assignedvehicle;
							};
						};
					};
				};
			};
			
///////////////////////////////////////////////////////////////////////////
///////////					Embarking 				     //////////////////
//////////////////////////////////////////////////////////////////////////
			If (!(_grp getvariable ["UPSMON_embarking",false])) then
			{
				If (!(_grp getvariable ["UPSMON_searchingpos",false])) then
				{
					If (!(_grp getVariable ["UPSMON_movetolanding",false])) then
					{
						_unitsinveh = units _grp;
						{If (alive _x && canmove _x && vehicle _x == _x) then {_unitsinveh = _unitsinveh - [_x];};} foreach units _grp;		
					
						If (count _unitsinveh < ({alive _x} count units _grp)) then
						{
							If (_dist > 800 && !_gothit) then 
							{
								If (_targetpos select 0 != 0 && _targetpos select 1 != 0) then
								{
									If (_traveldist >= UPSMON_searchVehicledist) then
									{
										if (count _assignedvehicle == 0) then
										{
											if (!_noveh) then 
											{
												if (!("tank" in _typeofgrp) && !("armed" in _typeofgrp) && !("apc" in _typeofgrp) && !("air" in _typeofgrp)) then
												{
													[_grp,_grpid,_targetpos] spawn UPSMON_DOfindvehicle;
												};
											};
										}
										else
										{
											If ("infantry" in _typeofgrp) then
											{
												[_grp,_grpid,_assignedvehicle] spawn UPSMON_getinassignedveh;
											};
										};
									};
								};
							}
							else
							{
								If (!_noveh2) then
								{
									[_grp,_grpid] spawn UPSMON_DOfindCombatvehicle;
								};
							};
						};
					};
				};
			};
		};// !NOWP
	
	
	
//*********************************************************************************************************************
// 											VARIABLES UPDATE 	
//*********************************************************************************************************************			
				
		if (({alive _x} count units _grp) == 0 ||  _grp getvariable ["UPSMON_Removegroup",false]) exitwith
		{
			[_grp,_Ucthis,_orgpos,_surrended,_grpidx,_membertypes,_vehicletypes,_side] call UPSMON_Respawngrp;
		}; 	
		
		// did the leader die?
		_npc = [_npc,_grp] call UPSMON_getleader;							
		if (!alive _npc || !canmove _npc || isplayer _npc ) exitwith {[_grp,_Ucthis,_orgpos,_surrended,_grpidx,_membertypes,_vehicletypes,_side] call UPSMON_Respawngrp;};			
			
			
		//If in hely calculations must done faster
		if (_inheli && _npc == (vehicle _npc)) then 
		{
			_flyInHeight = UPSMON_flyInHeight;
			If ((getPosATL (vehicle _npc)) select 2 < UPSMON_flyInHeight && !(_npc getvariable "UPSMON_DskHeli")) then {vehicle _npc flyInHeight _flyInHeight;};
			If (speedmode _grp != "FULL") then {_grp setspeedmode "FULL"};
		};
		
		_lastwptype = _wptype;
		_lastgrpmission = _grpmission;
		_lastcurrpos = _currPos;
		if (_alertpos select 0 == 0 && _alertpos select 1 == 0) then {_alertpos = _currPos;};	
		_lastattackpos = _attackPos;
		if (format ["%1",_attackPos] != "[0,0]") then {_lastattackpos = _currPos;};		
		//Is updated with the latest value, changing the target
		_lastknown = _opfknowval; 				
		
		//Refresh position vector
		_lastpos=_targetPos;

		_grp setvariable ["UPSMON_Lastinfos",[_lastcurrpos,_lastwptype,_lastpos,_lastknown,_target,_flankdir,units _npc,_timeinfo,_alertpos,_fixedtargetPos]];
		_grp setvariable ["UPSMON_TIMEONTARGET",[_timeontarget,_timeonalert,_timeonbld,_timeondefend]];
		_grp setvariable ["UPSMON_NOWP",[_nowp,_nowptype]];
		_grp setvariable ["UPSMON_Fortify",[_fortifyorig,_fortify]];
		_grp setvariable ["UPSMON_makenewtarget",_makenewtarget];
		_grp setvariable ["UPSMON_REINFORCEMENTSENT",[_reinforcementsent,_timereinforcement]];
		_grp setvariable ["UPSMON_TimeArtillery",_timeartillery];
		_grp setvariable ["UPSMON_Grpstatus",[_grpmission,_colorstatus,_lastgrpmission,[_react,_lastreact,_minreact],_target,_targetpos]];
		_grp setvariable ["UPSMON_REACT",[_react,_lastreact,_minreact]];		
		
		sleep 0.2;
	} count UPSMON_NPCs > 0;
	
	sleep _cycle;
	
}; //loop