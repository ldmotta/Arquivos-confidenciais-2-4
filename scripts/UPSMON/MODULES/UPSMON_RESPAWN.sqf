UPSMON_Respawngrp = {
private ["_grp","_grpidx","_track","_orgpos","_respawn","_respawnmax","_surrended","_unittype","_membertypes","_rnd","_grp","_lead","_initstr","_targetpos","_spawned","_vehicletypes","_UCthis","_respawndelay"];

_UCthis = _this select 1;
_orgpos = _this select 2;
_surrended = _this select 3;
_grpidx = _this select 4;
_membertypes = _this select 5;
_vehicletypes = _this select 6;
_side = _this select 7;


_grp = _this select 0;
_removeunit = _grp getvariable ["UPSMON_Removegroup",false];
_side = side _grp;

_dist = 1000;
_respawnmax = 0;
_respawndelay = 0;

		
		if (UPSMON_Debug>0) then {hint format["%1 exiting mainloop",_grpidx]; diag_log format ["exit: %1 %2 %3 %4",_grp,units _grp,alive leader _grp,_removeunit];};	
		//Limpiamos variables globales de este grupo
		//UPSMON_targetsPos set [_grpid,[0,0]];
		if (_grp in UPSMON_NPCs) then {UPSMON_NPCs = UPSMON_NPCs - [_grp];};
		_reinforcement= if ("REINFORCEMENT" in _UCthis) then {"REINFORCEMENT"} else {"NOREINFORCEMENT"}; //rein_yes
		If (_reinforcement == "REINFORCEMENT") then 
		{
			switch (_side) do 
			{
				case West: {
					if (_grp in UPSMON_REINFORCEMENT_WEST_UNITS) then  {UPSMON_REINFORCEMENT_WEST_UNITS = UPSMON_REINFORCEMENT_WEST_UNITS - [_grp];};
				};
				case EAST: {
					if (_grp in UPSMON_REINFORCEMENT_EAST_UNITS) then  {UPSMON_REINFORCEMENT_EAST_UNITS = UPSMON_REINFORCEMENT_EAST_UNITS - [_grp];};
				};
				case resistance: {
					if (_grp in UPSMON_REINFORCEMENT_GUER_UNITS) then  {UPSMON_REINFORCEMENT_GUER_UNITS = UPSMON_REINFORCEMENT_GUER_UNITS - [_grp];};		
				};
			};
		};
		switch (_side) do 
		{
			case West: 
			{
				if (_grp in UPSMON_ARTILLERY_WEST_UNITS) then  {UPSMON_ARTILLERY_WEST_UNITS = UPSMON_ARTILLERY_WEST_UNITS - [_grp];};
			};
			case EAST: 
			{
				if (_grp in UPSMON_ARTILLERY_EAST_UNITS) then  {UPSMON_ARTILLERY_EAST_UNITS = UPSMON_ARTILLERY_EAST_UNITS - [_grp];};
			};
			case resistance: 
			{
				if (_grp in UPSMON_ARTILLERY_GUER_UNITS) then  {UPSMON_ARTILLERY_GUER_UNITS = UPSMON_ARTILLERY_GUER_UNITS - [_grp];};
			};
	
		};
		
		UPSMON_Exited=UPSMON_Exited+1;

		If (!_removeunit) then
		{
			// respawn
			_respawn = if ("RESPAWN" in _UCthis) then {true} else {false};
			_respawn = if ("RESPAWN:" in _UCthis) then {true} else {_respawn};
			diag_log format ["RESPAWN: %1",_respawn];
			If (_respawn) then {_respawnmax = ["RESPAWN:",_respawnmax,_UCthis] call UPSMON_getArg;};
			If ("RESPAWNPOS:" in _Ucthis) then {_orgpos = ["RESPAWNPOS:",_orgpos,_UCthis] call UPSMON_getArg;};
			If ("RESPAWNDELAY:" in _Ucthis) then {_respawndelay = ["RESPAWNDELAY:",_respawndelay,_UCthis] call UPSMON_getArg;};
		
			_custom = if ("CUSTOM" in _UCthis) then {true} else {false};

			sleep _respawndelay;
		
			//Verify if targets near respawn
			_mensnear = _orgpos nearentities [["CAManBase","TANK","CAR"],800];
			_enemySides = _side call BIS_fnc_enemySides;
			_enynear = false;
			{
				If (side _x in _enemySides) then {_enynear = true;}
			} foreach _mensnear;
		
			// if (UPSMON_Debug>0) then {player sidechat format["%1 _dist=%2",_grpidx,_dist]};	

			//does respawn of group =====================================================================================================
			if (_respawn && _respawnmax > 0 &&  !_surrended  && !_enynear) then {
				if (UPSMON_Debug>0) then {player sidechat format["%1 doing respawn",_grpidx]};	

				// copy group leader
				_unittype = (_membertypes select 0) select 0;
			
				// any init strings?
				_initstr = ["INIT:","",_UCthis] call UPSMON_getArg;
	
				// make the clones civilians
				// use random Civilian models for single unit groups
				//if ((_unittype=="Civilian") && (count _members==1)) then {_rnd=1+round(random 20); if (_rnd>1) then {_unittype=format["Civilian%1",_rnd]}};
			
				_grp=createGroup _side;
				_lead = _grp createUnit [_unittype, _orgpos, [], 0, "FORM"]; 
				If (_custom && vehicle _lead == _lead) then 
				{
					_equipment = (_membertypes select 0) select 1;
					[_lead,_equipment] call UPSMON_addequipment;
				};
			
				if (isMultiplayer) then 
				{
					[[netid _lead, _initstr], "UPSMON_fnc_setVehicleInit", true, true] spawn BIS_fnc_MP;
				} else 
				{
					_unitstr = "_lead";
					_index=[_initstr,"this",_unitstr] call UPSMON_Replace;
					call compile format ["%1",_index];
				};
			
				[_lead] join _grp;
				_grp selectLeader _lead;
				
				// copy team members (skip the leader)
				_i=0;
				{
					_i=_i+1;
					if (_i>1) then {
						_unittype = _x select 0;
						_newunit = _grp createUnit [_unittype, _orgpos, [], 0, "FORM"];
						If (_custom && vehicle _lead == _lead) then 
						{
							_equipment = _x select 1;
							[_newunit,_equipment] call UPSMON_addequipment;
						};
					
						if (isMultiplayer) then 
						{
							[[netid _newunit, _initstr], "UPSMON_fnc_setVehicleInit", true, true] spawn BIS_fnc_MP;
						} else 
						{
							_unitstr = "_newunit";
							_index=[_initstr,"this",_unitstr] call UPSMON_Replace;
							call compile format ["%1",_index];
						};
					
						[_newunit] join _grp;
						sleep 0.1;
					};
				} foreach _membertypes;
			
			
				if ( _lead == vehicle _lead) then {
						{
							if (alive _x && canmove _x) then {
								[_x] dofollow _lead;
							};
						sleep 0.1;
					} foreach units _lead;
				};
			
				{				
					_targetpos = _orgpos findEmptyPosition [10, 200];
					sleep .4;
					if (count _targetpos <= 0) then {_targetpos = _orgpos};
					//if (UPSMON_Debug>0) then {player globalchat format["%1 create vehicle _newpos %2 ",_x,_targetpos]};	
					_newunit = (_x select 0) createvehicle (_targetpos);
					_newunit setdir (_x select 1);
					_crew = _x select 2;
					if (count _crew > 0) then {_newunit = _grp createUnit [_crew select 0, _orgpos, [], 0, "FORM"]; _newunit moveindriver _newunit};
					if (count _crew > 1) then {_newunit = _grp createUnit [_crew select 1, _orgpos, [], 0, "FORM"]; _newunit moveingunner _newunit};
					if (count _crew > 2) then {_newunit = _grp createUnit [_crew select 2, _orgpos, [], 0, "FORM"]; _newunit moveincommander _newunit};	
				} foreach _vehicletypes;		
			
			
				//if (UPSMON_Debug>0) then {player globalchat format["%1 _vehicletypes: %2",_grpidx, _vehicletypes]};
			
				_spawned= if ("SPAWNED" in _UCthis) then {true} else {false};
				//Set new parameters
				if (!_spawned) then { 
				
					_UCthis = _UCthis + ["SPAWNED"]; 		
			
					if ((count _vehicletypes) > 0) then {
						_UCthis = _UCthis + ["VEHTYPE:"] + ["dummyveh"];	
					};
				};	
				
			
				_UCthis set [0,_lead];
				_respawnmax = _respawnmax - 1;
				_UCthis =  ["RESPAWN:",_respawnmax,_UCthis] call UPSMON_setArg;
				sleep 0.1;
				_UCthis =  ["VEHTYPE:",_vehicletypes,_UCthis] call UPSMON_setArg;
			
			
				// if (UPSMON_Debug>0) then {player globalchat format["%1 _UCthis: %2",_grpidx,_UCthis]};	
				//Exec UPSMON script			
				_UCthis spawn UPSMON;
				sleep 0.1;
			};	
		};
		
		_trackername=format["trk_%1",_grpidx];
		_destname=format["dest_%1",_grpidx];
		deletemarker _trackername;
		deletemarker _destname;		
		
		
		if (({alive _x} count units _grp) == 0 ) then {
			deleteGroup _grp;
		};
};