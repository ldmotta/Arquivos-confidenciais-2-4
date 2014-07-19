UPSMON_DOATTACK = 
{
	private ["_grp","_npc","_attackPos","_dist","_gothit","_closeenough","_dir1","_dir2","_wptype","_wpformation","_result","_targetPos","_speedmode","_Behaviour","_grpid","_nofollow","_targetdist","_areamarker","_centerpos","_centerX","_centerY","_areadir","_areasize","_RangeX","_RangeY"];
	
	_grp = _this select 0;
	_attackPos = _this select 1;
	_dist = _this select 2;
	_grpid = _this select 3;
	_nofollow = _this select 4;
	_typeofgrp = _this select 5;
	_terrainscan = _this select 6;
	_areamarker = _this select 7;
	_side = _this select 8;
	_haslos = _this select 9;
	
	_npc = leader _grp;
	_currpos = getposATL _npc;
	_gothit = [_npc] call UPSMON_GothitParam;
	_water = 0;

	if((attackenabled _npc) && _dist > 50)then{_npc enableAttack false;};
	If (_dist <= 50) then {_npc enableAttack true;}; 
	
	{_x stop false;_x dofollow (leader _x)} foreach units _npc;		
	_closeenough = UPSMON_closeenough;	
	// get position of spotted unit in player group, and watch that spot
	if (UPSMON_Debug>0 ) then {[_attackPos,"ColorRed"] call fnc_createMarker;};										
			
	// angle from unit to target
	//_dir1 = [getposATL _npc,_attackPos] call UPSMON_getDirPos;
	_dir1 =[getposATL _npc, _attackPos] call BIS_fnc_DirTo;
	_dir2 = _dir1;	

						
	//Establish the type of waypoint
	//DESTROY has worse behavior with and sometimes do not move
	_wptype = "MOVE";
	_wpformation = "WEDGE";
	_CombatMode = "YELLOW";
	_radius = 1;
	_grp setvariable ["UPSMON_searchingpos",true];	
	
	_attackPos = [_attackPos select 0,_attackPos select 1,0];
	
	//Set speed and combat mode 
	_rnd = random 100;
	If (!("ship" in _typeofgrp) && !("air" in _typeofgrp)) then
	{
		If (!("infantry" in _typeofgrp)) then
		{
			If (_dist > _closeenough/2) then 
			{
				_targetPos = [_currpos,_dir2,_attackPos,_side,_typeofgrp,_grpid] call UPSMON_SrchFlankPos;
				
			}
			else
			{

				_targetPos = _attackPos;
				_wptype = "SAD";
				_radius = 200;
			
			};
		}
		else
		{
			If (_dist > _closeenough/2) then 
			{
				_targetPos = [_currpos,_dir2,_attackPos,_side,_typeofgrp,_grpid] call UPSMON_SrchFlankPos;
			}
			else
			{

				_targetPos = _attackPos;
				_wptype = "SAD";
				_radius = 50;
			
			};
		};
		
		if ( _dist <= _closeenough ) then 
		{	
			If (("infantry" in _typeofgrp) && "armed" in _typeofgrp) then
			{
				{
					if (alive _x && vehicle _x != _x && driver vehicle _x == _x) then {vehicle _x forcespeed 5.5};
				} foreach units _grp;
			};
			//If we are so close we prioritize discretion fire
			if ( _dist <= _closeenough/2 ) then 
			{	
				
				//Close combat modeo	
				_wpformation = "LINE";
				_speedmode = "LIMITED";
				If (("armed" in _typeofgrp) || ("tank" in _typeofgrp)) then {_wpformation = "VEE";};
			
				// _rnd < 80
				if (morale _npc > 0 && _gothit) then 
				{           
					_Behaviour =  "COMBAT";
					_CombatMode = "RED";
					
				} 
				else 
				{
					_Behaviour =  "STEALTH"; // ToDo check impact "STEALTH";
				};	
					
				 // MOVE
				
			} 
			else 
			{
				//If the troop has the role of not moving tend to keep the position	 
				_Behaviour =  "COMBAT";
				_speedmode = "NORMAL";
				If (("armed" in _typeofgrp) || ("tank" in _typeofgrp)) then {_wpformation = "WEDGE";_speedmode = "LIMITED";};							
			};								
		} 
	else	
	{	
		if (_dist <= 1000) then 
		{
			If (_haslos) then
			{
				_speedmode = "LIMITED";
				_Behaviour = "COMBAT";
			}
			else
			{
				_speedmode = "NORMAL";
				_Behaviour = "AWARE";
			};			
		} 
		else 
		{		
			//Platoon from the target must move fast and to the point
			_Behaviour =  "SAFE"; 
			_speedmode = "FULL";
			_wpformation = "COLUMN";
		};	
	};
	}
	else
	{
			If ("air" in _typeofgrp) then
			{
				_Behaviour =  "COMBAT";
				_speedmode = "FULL";
				_water = 1;
				if ( _dist <= 400 ) then 
				{
					_targetPos = _attackPos;
					_wptype = "SAD"; // MOVE
					_CombatMode = "RED";
					_radius = 300;
				}
				else
				{
						
					_targetPos = [_currpos,_dir2,_attackPos,_side,_grpid] call UPSMON_SrchFlankPosforPlane;
				};
			}
			else
			{
				_water = 2;
				_Behaviour =  "COMBAT";
				_speedmode = "FULL";
				if ( _dist <= 400 && surfaceiswater _targetPos) then 
				{
					_targetPos = _attackPos;
					_wptype = "SAD"; // MOVE
					_CombatMode = "RED";
				}
				else
				{
						
					_targetPos = [_currpos,_dir2,_attackPos,_side,_grpid] call UPSMON_SrchFlankPosforboat;
					If (!surfaceiswater _targetpos) then {_targetpos = _currpos;};

				};
			};
				
		};
	
		_targetPos = [_targetPos select 0,_targetPos select 1,0];			
		
		//Establecemos el target
		UPSMON_targetsPos set [_grpid,_targetPos];			
						
		if (_nofollow=="NOFOLLOW") then 
		{
			If !([_targetPos,_areamarker] call UPSMON_pos_fnc_isBlacklisted) then {_targetPos = [_areamarker,_water,[],5] call UPSMON_pos;};
			_wptype = "HOLD";
			_speedmode = "FULL";
			_Behaviour =  "AWARE"; 
		};
		
		If ((_terrainscan select 0) == "meadow") then
		{
			_speedmode = "FULL";
		};
		
		_grp setvariable ["UPSMON_targetPos",_targetPos];
		[_grp,_targetpos,_wptype,_wpformation,_speedmode,_Behaviour,_CombatMode,_radius] spawn UPSMON_DocreateWP;
		_grp setvariable ["UPSMON_searchingpos",false];	
};

UPSMON_DOPATROL = 
{
	private ["_grp","_wpformation","_speedmode","_areamarker","_wptype","_targetpos","_targetdist","_dist","_onroad","_Behaviour"]; 
	
	_grp = _this select 0;
	_wpformation = _this select 1;
	_speedmode = _this select 2;
	_areamarker = _this select 3;
	_dist = _this select 4;
	_onroad = _this select 5;
	_grpid = _this select 6;
	_Behaviour = _this select 7;
	_combatmode = _this select 8;
	_typeofgrp = _this select 9;
	
	_wptype = "MOVE";
	_grp setvariable ["UPSMON_searchingpos",true];
	_npc = leader _grp;
	_targetpos = [_npc,_areamarker,_onroad,_typeofgrp] call UPSMON_SrchPtrlPos;
	
	[_grp,_targetpos,_wptype,_wpformation,_speedmode,_Behaviour,_CombatMode,1] spawn UPSMON_DocreateWP;
	_grp setvariable ["UPSMON_targetPos",_targetPos];
	_grp setvariable ["UPSMON_searchingpos",false];
};

UPSMON_DODEFEND = 
{
	private ["_grp","_dist","_target","_grpid","_attackpos","_supressed","_terrainscan","_wptype","_wpformation","_speedmode","_Behaviour","_npc","_targetPos","_CombatMode","_unitsIn","_units","_blds","_lookpos","_dir1","_dir2"];
	
	_grp = _this select 0;
	_dist = _this select 1;
	_target = _this select 2;
	_grpid = _this select 3;
	_attackpos = _this select 4;
	_supressed = _this select 5;
	_terrainscan = _this select 6;
	
	_npc = leader _grp;
	_targetPos = getposATL _npc;
	_wptype = "HOLD";
	_wpformation = "LINE";
	_speedmode = "LIMITED";
	_Behaviour = "STEALTH";
	If (IsNull _target) then {_wpformation = "DIAMOND";};
	If (!_supressed) then {_Behaviour = "COMBAT";_speedmode = "NORMAL";};
	
	_CombatMode = "YELLOW";
	if ((_terrainscan select 0) == "meadow") then
	{
		
	};
	
	[_grp,_targetpos,_wptype,_wpformation,_speedmode,_Behaviour,_CombatMode,1] spawn UPSMON_DocreateWP;
	_grp setvariable ["UPSMON_targetPos",_targetPos];
	
	sleep 2;
	{	
		_x suppressfor 200;
	} foreach units _grp;
	
	If ((IsNull _target || _dist >= 400) && !_supressed && !(_grp getvariable ["UPSMON_Cover",false])) then 
	{
		_unitsIn = [_grpid,_npc,150] call UPSMON_GetIn_NearestStatic;
		_units = [];
		{if (alive _x && vehicle _x == _x) then {_units = _units + [_x]};} foreach units _grp;
		
		if ( count _unitsIn > 0 ) then {_units = _units - [_unitsIn];};
		_blds = [_npc,100,false,120,true] call UPSMON_moveNearestBuildings;
		If (count _blds == 0) then 
		{
			_lookpos = [getposATL _npc,getdir _npc, 100] call UPSMON_GetPos2D;
			if (!IsNull _target) then 
			{
				_lookpos = _attackPos;
			};
			
			[_targetPos,[_lookpos select 0,_lookpos select 1,0],100,false,_units] call UPSMON_fnc_find_cover;
		};
		_grp setvariable ["UPSMON_Cover",true];
	};
	
};

UPSMON_DORESEARCH = 
{
	private ["_grp","_attackPos","_grpid","_nofollow","_typeofgrp","_areamarker","_side","_speedmode","_Behaviour","_radius","_water","_npc","_currpos","_dist","_dir1","_dir2","_result","_targetPos","_wptype"];
	_grp = _this select 0;
	_attackPos = _this select 1;
	_grpid = _this select 2;
	_nofollow = _this select 3;
	_typeofgrp = _this select 4;
	_areamarker = _this select 5;
	_side = _this select 6;
	
	_speedmode = "NORMAL";	
	_Behaviour = "AWARE";
	_radius = 1;
	_water = 0;
	
	_npc = leader _grp;
	_currpos = getposATL _npc;
	_dist = [_currpos,_attackPos] call UPSMON_distancePosSqr; 
	
	_targetPos = _attackPos;
	_wptype = "MOVE";
	_grp setvariable ["UPSMON_searchingpos",true];
	
	{_x stop false;_x dofollow (leader _x)} foreach units _npc;											
			
	// angle from unit to target
	//_dir1 = [getposATL _npc,_attackPos] call UPSMON_getDirPos;
	_dir1 =[getposATL _npc, _attackPos] call BIS_fnc_DirTo;
	_dir2 = _dir1;
	
	_attackPos = [_attackPos select 0,_attackPos select 1,0];
	If (("ship" in _typeofgrp) || ("air" in _typeofgrp)) then
	{
		_speedmode = "FULL";
		if ("ship" in _typeofgrp) then
		{
			_water = 2;
			_targetPos = [_attackpos,[50,100],[0,360],2,[0,100],1] call UPSMON_pos;
			If (!surfaceiswater _targetpos) then {_targetpos = _currpos;};
			_targetPos = [_targetPos select 0,_targetPos select 1,0];
		}
		else
		{
			_water = 1;
			_targetPos = attackpos;
			_wptype = "SAD";
			_radius = 200;
			_targetPos = [_targetPos select 0,_targetPos select 1,50];
		};
	}
	else
	{
		If (_dist < 150) then
		{
			_targetPos = _attackpos;
			_radius = 80;
			_wptype = "SAD";
			_Behaviour =  "COMBAT";
			_speedmode = "LIMITED";
		}
		else
		{
			_targetPos = [_currpos,_dir2,_attackPos,_side,_typeofgrp,_grpid] call UPSMON_SrchFlankPos;
		};
	};
	
	
	if (_nofollow=="NOFOLLOW") then 
	{
		If !([_targetPos,_areamarker] call UPSMON_pos_fnc_isBlacklisted) then {_targetPos = [_areamarker,_water,[],5] call UPSMON_pos;};
		_wptype = "HOLD";
		_speedmode = "FULL";
		_Behaviour =  "AWARE"; 
	};
	
	_grp setvariable ["UPSMON_targetPos",_targetPos];
	[_grp,_targetpos,_wptype,"COLUMN",_speedmode,_Behaviour,"YELLOW",_radius] spawn UPSMON_DocreateWP;
	_grp setvariable ["UPSMON_searchingpos",false];	
};

UPSMON_DOREINF = 
{
	private ["_npc","_targetpos","_speedmode","_wptype","_wpformation","_typeofgrp"];
	
	_grp = _this select 0;
	_targetpos = _this select 1;
	_dist = _this select 2;
	_typeofgrp = _this select 3;
	
	{_x enableAI "TARGET"} foreach units _grp;
	_speedmode = "FULL";
	If (UPSMON_DEBUG > 0) then {[_targetpos,"ColorBlue"] call fnc_createMarker;};
	_wptype ="MOVE";
	_wpformation = "COLUMN";
	_behaviour = "SAFE";
	_combatmode = "WHITE";
	
	_grp setvariable ["UPSMON_searchingpos",true];
	[_grp,_targetpos,_wptype,_wpformation,_speedmode,_behaviour,_combatmode,1] spawn UPSMON_DocreateWP;
	_grp setvariable ["UPSMON_targetPos",_targetPos];
	_grp setvariable ["UPSMON_searchingpos",false];
};

UPSMON_DORETREAT = 
{
	private ["_grp","_npc","_target","_AttackPos","_dir1","_dir2","_targetPos","_artillerysideunits","_RadioRange","_array"]; 	
	_grp = _this select 0;
	_AttackPos = _this select 1;
	_dir = [];
	_npc = leader _grp;
	
	If (_AttackPos select 0 != 0 && _AttackPos select 1 != 0) then
	{
		// angle from unit to target
		_dir1 = [getposATL _npc,_AttackPos] call UPSMON_getDirPos;
		_dir2 = (_dir1+180) mod 360;
		_dir = [_dir2 +290,_dir2 +70];
	}
	else
	{
		_dir = [getposATL _npc,(_grp getvariable "UPSMON_Origin") select 2] call UPSMON_getDirPos;
	};
	_grp setvariable ["UPSMON_searchingpos",true];	
	_targetPos = [_npc,_dir,50] call UPSMON_SrchRetreatPos;
		
	_behaviour = "SAFE";
	_CombatMode = "BLUE";			
	if (UPSMON_Debug>0) then {player sidechat format["%1 All Retreat!!!",_npc]};
	_wptype = "MOVE";
	_wpformation = "LINE";
	_speedmode = "FULL";
	[_grp,_targetpos,_wptype,_wpformation,_speedmode,_behaviour,_CombatMode,1] spawn UPSMON_DocreateWP;
	{
		_Pos = [_targetpos,[5,20],[0,360]] call UPSMON_pos;
		_x Domove _Pos;
	} foreach units _grp;
	_grp setvariable ["UPSMON_targetPos",_targetPos];
	_grp setvariable ["UPSMON_searchingpos",false];	
};


UPSMON_DOfindvehicle = 
{
	private ["_grp","_npc","_unitsIn","_grpid","_targetpos","_timeout","_vehicle","_vehicles","_isFlat","_rnd","_flyInHeight","_paradrop","_centerX2","_centerpos2","_rangeX2","_areadir2","_sindir2","_cosdir2","_tries","_P","_targetPosTemp","_GetOutDist"];
	
	_grp = _this select 0;
	_grpid = _this select 1;
	_targetpos = _this select 2;
	
	_grp setvariable ["UPSMON_embarking",true];
	_grp setvariable ["UPSMON_searchingpos",true];	
	
	If (({alive _x} count units _grp) == 0) exitwith {_grp setvariable ["UPSMON_embarking",false];};
	_npc = leader _grp;
	_orgbehaviour = behaviour _npc;
	_grp setbehaviour "CAREFULL";
	_grp setspeedmode "FULL";
	_unitsIn = [_grpid,_npc] call UPSMON_GetIn_NearestVehicles;						
						
	if ( count _unitsIn > 0) then 
	{		
		_timeout = time + 60;
							
		_vehicle = objnull;
		_vehicles = [];
		
		{ 
			waitUntil { (vehicle _x != _x) || { time > _timeout } || { moveToFailed _x } || { !canMove _x } || { !canStand _x } || { !alive _x } }; 
								
			if ( vehicle _x != _x && (isnull _vehicle || _vehicle != vehicle _x)) then 
			{
				_vehicle = vehicle _x ;
				_vehicles = _vehicles + [_vehicle]
			};								
		} foreach _unitsIn;
		
		_targetpos = _grp getvariable ["UPSMON_Targetpos",_targetpos];
		
		If ("Ship" countType [vehicle (_npc)]>0) then 
		{
			_isFlat = _targetpos isflatempty [0,10,1,0,1,false];
			If (count _isFlat > 0) then {_targetpos = ASLtoATL _isFlat;};
		};
							
		If ("LandVehicle" countType [vehicle (_npc)]>0) then 
		{
			//check for roads
			_roads = _targetpos nearRoads 100;
			if (count _roads == 0) then
			{
				_isFlat = _targetpos isflatempty [10,10,0.7,10,0,false];
				If (count _isFlat > 0) then {_targetpos = ASLtoATL _isFlat;};
				//[_npc,_targetpos] spawn UPSMON_dotransport;
			}
			else
			{
				_targetpos = position (_roads select 0);
			};
			
		};
							
		if ( "Air" countType [vehicle (_npc)]>0) then 
		{											
			_rnd = (random 2) * 0.1;
			_flyInHeight = round(UPSMON_flyInHeight * (0.9 + _rnd));
			vehicle _npc flyInHeight _flyInHeight;
			_Ucthis = _grp getvariable "UPSMON_Ucthis";
			_paradrop = if ("LANDDROP" in _UCthis) then {false} else {true};
			_TargetPos2 = _targetpos;
			
			//If you just enter the helicopter landing site is defined					
			If (!_paradrop) then 
			{
				If (UPSMON_Debug > 0) then {player sidechat "LANDDROP started"};
	
				_tries=0;
				_P = true;
				while { _P && (_tries<50)} do 
				{
					_tries=_tries+1;
					_targetPosTemp = [_TargetPos2,[0,100],[0,360],0,[0,100],1] call UPSMON_pos;
		
					_isFlat = _targetPosTemp isflatempty [10,10,0.4,10,0,false];

					If (count _isFlat > 0) then {_targetpostemp = _isFlat;};
					If ((!surfaceIsWater _targetpostemp) && count _isFlat > 0) then {_P = false; _TargetPos2 = ASLtoATL (_targetPosTemp);};
					sleep 0.01;
				};
			};
										
			_GetOutDist = UPSMON_paradropdist * ((random 0.4) + 1);
			[vehicle _npc,_npc,_paradrop,_TargetPos2,_GetOutDist,_flyInHeight] spawn UPSMON_doParadrop;
			//Execute control stuck for helys
			
			//[vehicle _npc] spawn UPSMON_HeliStuckcontrol;
			//if (UPSMON_Debug>0 ) then {player sidechat format["%1: flyingheiht=%2 paradrop at dist=%3",_grpidx, _flyInHeight, _GetOutDist,_rnd]}; 
						
		};
	};
	_grp setbehaviour _orgbehaviour;
	[_grp,_targetpos,"MOVE","COLUMN","NORMAL","AWARE","YELLOW",1] spawn UPSMON_DocreateWP;
	_grp setvariable ["UPSMON_targetPos",_targetPos];
	_grp setvariable ["UPSMON_embarking",false];
	_grp setvariable ["UPSMON_searchingpos",false];	
};


UPSMON_DOfindCombatvehicle = 
{
	private ["_grp","_npc","_unitsIn","_grpid","_dist","_vehicle"];
	
	_grp = _this select 0;
	_grpid = _this select 1;
	_dist = 200;
	//Get in combat vehicles				
	_unitsIn = [];
	_npc = leader _grp;
	_orgbehaviour = behaviour _npc;
	_grp setbehaviour "SAFE";
	_grp setspeedmode "FULL";
	_grp setvariable ["UPSMON_embarking",true];
	_unitsIn = [_grpid,_npc,_dist,false] call UPSMON_GetIn_NearestCombat;	
	_timeout = time + 30;
				
	if ( count _unitsIn > 0) then 
	{							
		//if (UPSMON_Debug>0 ) then {player sidechat format["%1: Geting in combat vehicle targetdist=%2",_grpidx,_npc distance _target]}; 																												
						
		{ 
			waituntil {vehicle _x != _x || !canmove _x || !canstand _x || !alive _x || time > _timeout || movetofailed _x}; 
		}foreach _unitsIn;
						
		// did the leader die?
		If (({alive _x} count units _grp) == 0) exitwith {};								
						
		//Return to combat mode
		_timeout = time + 30;
		{ 
			waituntil {vehicle _x != _x || !canmove _x || !alive _x || time > _timeout || movetofailed _x}; 
		}foreach _unitsIn;
						
		{								
			if ( vehicle _x  iskindof "Air") then 
			{
				//moving hely for avoiding stuck
				if (driver vehicle _x == _x) then {
					_vehicle = vehicle (_x);									
					nul = [_vehicle,1000] spawn UPSMON_domove;	
					//Execute control stuck for helys
					[_vehicle] spawn UPSMON_HeliStuckcontrol;
					//if (UPSMON_Debug>0 ) then {diag_log format["UPSMON %1: Getting in combat vehicle - distance: %2 m",_grpidx,_npc distance _target]}; 	
				};									
			};
							
			if (driver vehicle _x == _x) then 
			{
				//Starts gunner control
				nul = [vehicle _x] spawn UPSMON_Gunnercontrol;								
			};
		} foreach _unitsIn;									
	};
	_grp setvariable ["UPSMON_embarking",false];
	_grp setbehaviour _orgbehaviour;
};

UPSMON_Dofindstatic = 
{
	private ["_npc","_unitsIn","_grpid","_buildingdist"];
	_npc = _this select 0;
	_grpid = _this select 1;
	_buildingdist = _this select 2;
	
//If use statics are enabled leader searches for static weapons near.
	_unitsIn = [_grpid,_npc,_buildingdist] call UPSMON_GetIn_NearestStatic;			
				
	if ( count _unitsIn > 0) then 
	{									
		_npc setspeedmode "FULL";					
		_timeout = time + 60;
					
		{ 
			waituntil {vehicle _x != _x || { time > _timeout } || { movetofailed _x } || { !canmove _x } || { !alive _x } }; 
		} foreach _unitsIn;
	};
					
};

UPSMON_dodisembark = 
{
	if (UPSMON_Debug>0) then { player globalchat format["Mon_disembark started"];};
	private["_transport","_npc","_getout" ,"_gunner","_targetpos","_helipos","_dist","_index","_grp","_wp","_targetPosWp","_targetP","_units","_crew","_timeout","_jumpers"];				

	_transport = _this select 0;
	_transport setvariable ["UPSMON_disembarking",true];
	
	if (!alive _transport) exitwith{};
	
		_dogetout = [_transport] call UPSMON_FN_unitsInCargo; // units cargo in the vehicle
		_driver = driver _transport;

		if ( count _dogetout > 0 ) then 
		{					
			// All units disembark if the vehicle is a Car
			if (isnull (gunner _transport)) then
			{
				//Stop the veh for 5.5 sek		
				Dostop _driver;					
				sleep 1.5; // give time to actualy stop
				
				{					
					unassignVehicle _transport;	
					_x action ["getOut", _transport];
					doGetOut _x;
					[_x] allowGetIn false;
					_x leaveVehicle _transport;
					sleep 0.2;
					_Pos = [getposATL _x,[5,30],[0,360]] call UPSMON_pos;
					_x domove _Pos;
				} foreach _dogetout;				

				//We removed the id to the vehicle so it can be reused
				_transport setVariable ["UPSMON_grpid", 0, false];	
				_transport setVariable ["UPSMON_cargo", [], false];	
						
				// [_npc,_x, _driver] spawn UPSMON_checkleaveVehicle; // if every one outside, make sure driver can walk
				unassignVehicle _driver;
				_driver action ["getOut", _transport];
				doGetOut _driver;
				[_driver] allowGetIn false;	
				_driver enableAI "MOVE";
				_driver stop false;
				_driver leaveVehicle _transport;
				sleep 0.01;		
			}
			else
			{
				//Stop the veh for 5.5 sek		
				Dostop _driver;		
				sleep 1.5; // give time to actualy stop
				
				{					
					unassignVehicle _transport;	
					_x action ["getOut", _transport];
					doGetOut _x;
					[_x] allowGetIn false;	
					_x stop false;
					sleep 0.1;
					_Pos = [getposATL _x,[5,20],[0,360]] call UPSMON_pos;
					_x domove _Pos;
				} foreach _dogetout;				

				//We removed the id to the vehicle so it can be reused
				_transport setVariable ["UPSMON_grpid", 0, false];	
				_transport setVariable ["UPSMON_cargo", [], false];	
				_driver stop false;	
				//[_npc,_transport, _driver] spawn UPSMON_checkleaveVehicle; // if every one outside, make sure driver can walk					
			};
		};
		_transport setvariable ["UPSMON_disembarking",false];

};

UPSMON_getinassignedveh = 
{
	private ["_grp","_grpid","_assignedvehicle","_unitsin","_vehicles","_Cargocount","_Gunnercount","_Commandercount","_Drivercount","_emptypositions","_timeout"];
	_grp = _this select 0;
	_grpid = _this select 1;
	_assignedvehicle = _this select 2;
	_npc = leader _grp;
	_orgbehaviour = behaviour _npc;
	_grp setvariable ["UPSMON_embarking",true];

	_unitsin = [];
	_vehicles = [];
	{If (alive _x && canmove _x && vehicle _x == _x) then {_unitsin = _unitsin + [_x];};} foreach units _grp;

	{
		_Cargocount = (_x) emptyPositions "Cargo";
		_Gunnercount = (_x) emptyPositions "Gunner"; 
		_Commandercount = (_x) emptyPositions "Commander"; 
		_Drivercount = (_x) emptyPositions "Driver"; 
		
		_emptypositions = _Cargocount + _Gunnercount + _Commandercount + _Drivercount;
		
		if (_emptypositions > 0 && canMove _x) then { _vehicles = _vehicles + [[vehicle _x,_emptypositions]];};
	} foreach _assignedvehicle;


	If (count _unitsin > 0 && count _vehicles > 0) then
	{
		_units = [_grpid, _unitsin, _vehicles, true] call UPSMON_selectvehicles;
		_unitsIn = _unitsIn - _units;	
		
			_timeout = time + 30;
			_grp setbehaviour "CARELESS";
			_grp setspeedmode "FULL";

			{ 
				waituntil {vehicle _x != _x || !canmove _x || !canstand _x || !alive _x || time > _timeout || movetofailed _x}; 
			}foreach _unitsIn;
						
			// did the leader die?
			If (({alive _x} count units _grp) == 0) exitwith {};								
						
			//Return to combat mode
			_grp setbehaviour _orgbehaviour;
			_timeout = time + 30;
			{ 
				waituntil {vehicle _x != _x || !canmove _x || !alive _x || time > _timeout || movetofailed _x}; 
			}foreach _unitsIn;
	};
	_grp setvariable ["UPSMON_embarking",false];
};