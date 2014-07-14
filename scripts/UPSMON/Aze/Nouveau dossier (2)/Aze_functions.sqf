MON_Bld_ruins = ["Land_Unfinished_Building_01_F","Land_Unfinished_Building_02_F","Land_d_Stone_HouseBig_V1_F","Land_d_Stone_Shed_V1_F","Land_u_House_Small_02_V1_F","Land_i_Stone_HouseBig_V1_F","Land_u_Addon_02_V1_F","Land_Cargo_Patrol_V1_F"];
MON_Bld_remove = ["Bridge_PathLod_base_F","Land_Slum_House03_F","Land_Bridge_01_PathLod_F","Land_Bridge_Asphalt_PathLod_F","Land_Bridge_Concrete_PathLod_F","Land_Bridge_HighWay_PathLod_F","Land_Bridge_01_F","Land_Bridge_Asphalt_F","Land_Bridge_Concrete_F","Land_Bridge_HighWay_F","Land_Canal_Wall_Stairs_F","Land_dp_bigTank_F"];

Aze_GothitParam = 
{
	private ["_npc","_gothit"];
	
	_npc = _this select 0;
	_gothit = false;
	
	If (!isNil "tpwcas_running") then 
	{
		if (group _npc in R_GOTHIT_ARRAY || group _npc in R_GOTKILL_ARRAY) then
		{
			_gothit = true;
		};
	}
	else
	{
		_Supstate = [_npc] call Aze_supstatestatus;
		if (group _npc in R_GOTHIT_ARRAY || group _npc in R_GOTKILL_ARRAY || _Supstate >= 2) then
		{
			_gothit = true;
		};
	};
	
	_gothit
};


////////////////////////////////////////////////////////////////// Artillery Module //////////////////////////////////////////////////////////////////
Aze_selectartillery = {

	private ["_support","_artiarray","_askMission","_RadioRange","_arti","_rounds","_artiarray","_artillerysideunits","_npc","_support","_artibusy"];
	
	_artillerysideunits = _this select 0;
	_askMission = _this select 1;
	_RadioRange = _this select 2;
	_npc = _this select 3;
	
	_arti = ObjNull;
	_rounds = 0;
	_artiarray = [_artillerysideunits, [], { _npc distance _x }, "ASCEND"] call BIS_fnc_sortBy;
	{
		_support = (vehicle _x) getVariable "ArtiOptions";
		_artibusy  = _support select 0;
		
		Switch (_askmission) do {
			case "HE": {
				_rounds = (_support select 1) select 2;
			};
		
			case "WP": {
				_rounds = (_support select 1) select 1;
			};
		
			case "FLARE": {
				_rounds = (_support select 1) select 0;
			};
	
		};
		
		If (!_artibusy && _x distance _npc <= _RadioRange && _rounds > 0) exitwith {_arti = _x;};
		if (KRON_UPS_Debug>0) then {player sidechat format ["Busy:%1 Distance:%2 RadioRange:%3 Rounds:%4",_artibusy,_x distance _npc,_RadioRange,_rounds];};
		
	} ForEach _artiarray;

	_arti
	
};
Aze_artilleryTarget = {
	// [_arti,"",_target] spawn Aze_artilleryTarget;
	
	private ["_support","_askBullet","_target","_arti","_missionabort","_rounds","_range","_area","_nbrbullet","_maxcadence","_mincadence","_askmission","_fire","_artibusy","_targetpos","_auxtarget","_npc"];
	_arti = _this select 0;
	
	_support = (vehicle _arti) getVariable "ArtiOptions";
	
	If (isnull (gunner _arti) 
	&& !(canmove (gunner _arti))) 
	exitwith 
	{
		if (KRON_UPS_Debug>0) then {player sidechat "ABORT: no gunner";};
	};
	
	// If (count _support <= 0 ) exitwith {if (KRON_UPS_Debug>0) then {player sidechat "ABORT: no support";};};
	
	
	_askMission = _this select 1;
	_target = _this select 2;

	
	_artibusy  = _support select 0;
	_rounds = _support select 1;					
	_area = _support select 2;	
	_maxcadence = _support select 3;	
	_mincadence = _support select 4;	

	_nbrbullet = 0;
	_askbullet = "";
	_missionabort = false;
	
	_npc = objNull;
	if (count _this > 3) then {_npc = _this select 3;}; 
	
	
	_side = side gunner _arti;
	_munradius = 150;	

	Switch (_askmission) do {
		case "HE": {
			If ((typeof (vehicle _arti)) in ["B_Mortar_01_F","O_Mortar_01_F","I_G_Mortar_01_F"]) then {_askbullet = "8Rnd_82mm_Mo_shells";};
			If ((typeof (vehicle _arti)) in ["B_MBT_01_arty_F","O_MBT_02_arty_F"]) then {_askbullet = "32Rnd_155mm_Mo_shells";_munradius = 300;};	
			_nbrbullet = _rounds select 2;
		};
		
		case "WP": {
			If ((typeof (vehicle _arti)) in ["B_Mortar_01_F","O_Mortar_01_F","I_G_Mortar_01_F"]) then {_askbullet = "8Rnd_82mm_Mo_Smoke_white";};
			If ((typeof (vehicle _arti)) in ["B_MBT_01_arty_F","O_MBT_02_arty_F"]) then {_askbullet = "6Rnd_155mm_Mo_smoke";};
			_nbrbullet = _rounds select 1;
		};
		
		case "FLARE": {
			If ((typeof (vehicle _arti)) in ["B_Mortar_01_F","O_Mortar_01_F","I_G_Mortar_01_F"]) then {_askbullet = "8Rnd_82mm_Mo_Flare_white";_nbrbullet = _rounds select 0;};
			If ((typeof (vehicle _arti)) in ["B_MBT_01_arty_F","O_MBT_02_arty_F"]) then {_nbrbullet = 0;};
		};
	
	};
	
	If(_artibusy 
	|| isNull _target 
	|| !alive _target 
	|| _nbrbullet <= 0) 
	exitwith 
	{
		if (KRON_UPS_Debug>0) then {player sidechat format ["ABORT: Arti: %1   Target: %2   Munition: %3",_artibusy,_target,_nbrbullet];};
	};
	

	
	if (!isnull _target  || alive _target) then 
	{
	
	
	switch (_side) do {
		case West: {
			KRON_UPS_ARTILLERY_WEST_UNITS = KRON_UPS_ARTILLERY_WEST_UNITS - [_arti];
		};
		case EAST: {
			KRON_UPS_ARTILLERY_EAST_UNITS = KRON_UPS_ARTILLERY_EAST_UNITS - [_arti];
		};
		case GUER: {
			KRON_UPS_ARTILLERY_GUER_UNITS = KRON_UPS_ARTILLERY_GUER_UNITS - [_arti];
		};
	
	};
		
		
	(vehicle _arti) setVariable ["ArtiOptions",[true,_rounds,_area,_maxcadence,_mincadence]];
	
	_auxtarget = _target;
	_targetPos = [];

	If ((_askbullet == "8Rnd_82mm_Mo_Smoke_white" || _askbullet == "6Rnd_155mm_Mo_smoke") 
	&& !IsNull _npc 
	&& alive _npc) 
	then 
	{ 
		_vcttarget = [_npc, _target] call BIS_fnc_dirTo;
		_dist = (_npc distance _target)/2;
		_targetPos = [position _npc,_vcttarget, _dist] call MON_GetPos2D;
	}
	else 
	{
		_targetPos = _auxtarget getvariable ("UPSMON_lastknownpos");
	};
	
	
		if (!isnil "_targetPos" || count _targetPos > 0) then 
		{
			//If target in range check no friendly squad near									
			if (alive _auxtarget 
			&& !(_auxtarget iskindof "Air") 
			&& (_targetPos inRangeOfArtillery [[_arti], _askbullet])) 
			then 
			{
			
				_target = _auxtarget;
				//Must check if no friendly squad near fire position
				If (_askbullet != "8Rnd_82mm_Mo_Flare_white") then
				{
					{	
						if (!isnull _x && _side == side _x) then 
						{																								
							if ((round([position _x,_targetPos] call KRON_distancePosSqr)) < (_munradius)) exitwith {_target = objnull;};
						};										
					} foreach KRON_NPCs;
				};
			};
		};
	
	If (!isNull _target || count _targetPos > 0) then 
	{
		//Fix current target
		_targetPos = [];	
		
		If (
		(_askbullet == "8Rnd_82mm_Mo_Smoke_white" || _askbullet == "6Rnd_155mm_Mo_smoke") 
		&& !IsNull _npc 
		&& alive _npc) 
		then 
		{ 
		_vcttarget = [_npc, _target] call BIS_fnc_dirTo;
		_dist = (_npc distance _target)/2;
		_targetPos = [position _npc,_vcttarget, _dist] call MON_GetPos2D;
		}
		else 
		{
		_targetPos = _auxtarget getvariable ("UPSMON_lastknownpos");
		};
		
		if (!isnil "_targetPos") then 
		{									
			// _arti removeAllEventHandlers "fired"; 
			// chatch the bullet in the air and delete it
			// _arti addeventhandler["fired", {deletevehicle (nearestobject[_this select 0, _this select 4])}];
			sleep 5;
			if (KRON_UPS_Debug>0) then {player sidechat "FIRE";};
			[_arti,_targetPos,_nbrbullet,_area,_maxcadence,_mincadence,_askbullet,_support] spawn Aze_artillerydofire;
		}
		else 
		{
			if (KRON_UPS_Debug>0) then {player sidechat "ABORT: no more target";}; 
			_missionabort = true;
		};
	
	}
	else
	{
		_missionabort = true
	};
	
	If (_missionabort) then
	{
	
		if (KRON_UPS_Debug>0) then {player sidechat "ABORT: no more target";};
		
			switch (_side) do {
		case West: {
			KRON_UPS_ARTILLERY_WEST_UNITS = KRON_UPS_ARTILLERY_WEST_UNITS + [_arti];
		};
		case EAST: {
			KRON_UPS_ARTILLERY_EAST_UNITS = KRON_UPS_ARTILLERY_EAST_UNITS + [_arti];
		};
		case GUER: {
			KRON_UPS_ARTILLERY_GUER_UNITS = KRON_UPS_ARTILLERY_GUER_UNITS + [_arti];
		};
	
		};
		
		(vehicle _arti) setVariable ["ArtiOptions",[false,_rounds,_area,_maxcadence,_mincadence]];
	};
};
};

Aze_artillerydofire = {
	 
		private ["_smoke1","_i","_area","_position","_maxcadence","_mincadence","_sleep","_nbrbullet","_rounds","_arti","_timeout","_bullet"];
		
		_arti = _this select 0;
		_position  = _this select 1;
		_nbrbullet = _this select 2;	
		_area = _this select 3;	
		_maxcadence = _this select 4;	
		_mincadence = _this select 5;	
		_bullet = _this select 6;
		_rounds = 0;
		_support = _this select 7;
		_supportrounds = _support select 1;
		_support2 = [];

		
		If (_bullet == "8Rnd_82mm_Mo_Flare_white")
		then {_rounds = 2; [] spawn Aze_Flaretime;} else {_rounds = 4;};
		
		If (_rounds > _nbrbullet) then {_rounds = _nbrbullet};
	
	
	Switch (_bullet) do {
		case "8Rnd_82mm_Mo_shells": {
			_support2 = [false,[_supportrounds select 0, _supportrounds select 1, (_supportrounds select 2) - _rounds],_support select 2, _support select 3,_support select 4];
			
		};
		
		case "32Rnd_155mm_Mo_shells": {
			_support2 = [false,[_supportrounds select 0, _supportrounds select 1, (_supportrounds select 2) - _rounds],_support select 2, _support select 3,_support select 4];
			
		};
		
		case "8Rnd_82mm_Mo_Smoke_white": {
			_support2 = [false,[_supportrounds select 0, (_supportrounds select 1) - _rounds, _supportrounds select 2],_support select 2, _support select 3,_support select 4];
			
		};
		
		case "6Rnd_155mm_Mo_smoke": {
			_support2 = [false,[_supportrounds select 0, (_supportrounds select 1) - _rounds, _supportrounds select 2],_support select 2, _support select 3,_support select 4];
			
		};
		
		case "8Rnd_82mm_Mo_Flare_white": {
			_support2 = [false,[(_supportrounds select 0) - _rounds, _supportrounds select 1, _supportrounds select 2],_support select 2, _support select 3,_support select 4];
		};
	
	};		
		
		_area2 = _area * 2;
		if (KRON_UPS_Debug>0) then { player globalchat format["artillery doing fire on %1",_position] };	
		
		for [{_i=0}, {_i<_rounds}, {_i=_i+1}] do 
		{ 		
			_sleep = random _maxcadence;			
			if (_sleep < _mincadence) then {_sleep = _mincadence};
			_com = effectiveCommander (vehicle _arti);
			sleep 2;
			_com commandArtilleryFire [[(_position select 0)+ random _area2 - _area, (_position select 1)+ random  _area2 - _area, 0], _bullet, 1];	
			sleep _sleep; 
			//Swap this
			_arti setVehicleAmmo 1;
		};
		
	sleep 15;
	_side = side gunner _arti;

		switch (_side) do {
		case West: {
			KRON_UPS_ARTILLERY_WEST_UNITS = KRON_UPS_ARTILLERY_WEST_UNITS + [_arti];
		};
		case EAST: {
			KRON_UPS_ARTILLERY_EAST_UNITS = KRON_UPS_ARTILLERY_EAST_UNITS + [_arti];
		};
		case GUER: {
			KRON_UPS_ARTILLERY_GUER_UNITS = KRON_UPS_ARTILLERY_GUER_UNITS + [_arti];
		};
	
		};
		
	(vehicle _arti) setVariable ["ArtiOptions",_support2];
};


Aze_Flaretime = {
	FlareInTheAir = true;
	sleep 120;
	FlareInTheAir = false;
	Publicvariable "FlareInTheAir";
};

////////////////////////////////////////////////////////////////// END Artillery Module //////////////////////////////////////////////////////////////////

Aze_supstatestatus = {
	private ["_npc","_azesupstate","_tpwcas_running"];
	
	_tpwcas_running = if (isNil "tpwcas_running") then {true} else {false};;

	_npc = _this select 0;
	_azesupstate = 0;

	if (_tpwcas_running) then
	{
		{
			If (_x getvariable "tpwcas_supstate" == 3) exitwith {_azesupstate = 3;};
			If (_x getvariable "tpwcas_supstate" == 2) exitwith {_azesupstate = 2;};
		} foreach units group _npc;
	};
	
	_azesupstate
};


///////////////////////////////////////////////// Dir to watch (Module Fortify) //////////////////////////////////////////////////////

Aze_UnitWatchDir = {

	private ["_see","_infront","_uposASL","_opp","_adj","_hyp","_eyes","_obstruction","_angle","_inbuilding"];
	
	_unit = _this select 0;
	_angle = _this select 1;
	_bld = _this select 2;
	_essai = 0;
	_see = false;
	_ouverture = false;
	_findoor = false;

	_inbuilding = [_unit] call Aze_inbuilding;
	
	If (!_inbuilding) then {
	
		// check window
		_windowposition = [_bld] call Aze_checkwindowposition;
		sleep 0.4;
		_watch = [];
		If (count _windowposition > 0) then 
		{
			{
				_x = [_x select 0,_x select 1,(getPosATL _unit) select 2];
				If ((_unit distance _x) <= 3) exitwith {_watch = _x;};
			} forEach _windowposition;
	
			if (count _watch > 0) then 
			{
		
				_posATL = getPosATL _unit;

				_abx = (_watch select 0) - (_posATL select 0);
				_aby = (_watch select 1) - (_posATL select 1);
				_abz = (_watch select 2) - (_posATL select 2);

				_vec = [_abx, _aby, _abz];

				// Main body of the function;

				_unit setVectorDir _vec;		
		
				sleep 0.2;
				_unit lookat ObjNull;
				_unit lookat _watch;
				_ouverture = true;
			
			
				// _ballCover = "Sign_Arrow_Large_Blue_F" createvehicle [0,0,0];
				// _ballCover setpos _watch;	
			};
		};
 
		// If no window found check for door
		If (!_ouverture) then
		{
			_doorposition = [_bld] call Aze_checkdoorposition;
			sleep 0.4;
			_watch = [];
			
			If (count _doorposition > 0) then 
		{
			{
				_x = [_x select 0,_x select 1,(getPosATL _unit) select 2];
				If ((_unit distance _x) <= 5) exitwith {_watch = _x;};
			} forEach _doorposition;
	
			if (count _watch > 0) then 
			{
				_posATL = getPosATL _unit;

				_abx = (_watch select 0) - (_posATL select 0);
				_aby = (_watch select 1) - (_posATL select 1);
				_abz = (_watch select 2) - (_posATL select 2);

				_vec = [_abx, _aby, _abz];

				// Main body of the function;

				_unit setVectorDir _vec;	
				sleep 0.2;
				_unit lookat ObjNull;
				_unit lookat _watch;
				

				// _ballCover = "Sign_Arrow_Large_RED_F" createvehicle [0,0,0];
				// _ballCover setpos _watch;	

				_ouverture = true;
				_findoor = true;
			};
		};	
	};
	};
	Sleep 2;
	// Check if window not blocking view or search direction for AI if he doesn't watch window or door.
	If (!(_findoor)) then 
	{
		_watchdir = [_unit, _bld] call BIS_fnc_DirTo;
		_watchdir = _watchdir + 180;
		//_watch = [getpos _unit,_watchdir,50] call MON_GetPos;
		//player sidechat format ["Watchdir %1",_watch];
		_unit setdir 0;
		_unit setdir _watchdir;
		_cansee = [_unit,getdir _unit,_bld] spawn Aze_WillSee;
	};	
};

Aze_checkdoorposition = {
	private [];
	_house = _this select 0;
	_anim_source_pos_arr = [];
	
	_cfgUserActions = (configFile >> "cfgVehicles" >> (typeOf _house) >> "UserActions");

	for "_i" from 0 to count _cfgUserActions - 1 do 
	{
		_cfg_entry = _cfgUserActions select _i;
    
		if (isClass _cfg_entry) then
		{
			_display_name = getText (_cfg_entry / "displayname");
			if (_display_name == "Open hatch" or {_display_name == "Open door"}) then
			{
				_selection_name = getText (_cfg_entry / "position");
				_model_pos = _house selectionPosition _selection_name;
				_world_pos = _house modelToWorld _model_pos;
				_anim_source_pos_arr = _anim_source_pos_arr + [_world_pos];
			};
		};
	};

	_anim_source_pos_arr
};

Aze_checkwindowposition = {
	private ["_model_pos","_world_pos","_armor","_cfg_entry","_veh","_house","_window_pos_arr","_cfgHitPoints","_cfgDestEff","_brokenGlass","_selection_name"];
	_house = _this select 0;
	_window_pos_arr = [];

	_cfgHitPoints = (configFile >> "cfgVehicles" >> (typeOf _house) >> "HitPoints");

	for "_i" from 0 to count _cfgHitPoints - 1 do 
	{
		_cfg_entry = _cfgHitPoints select _i;
    
		if (isClass _cfg_entry) then
		{
			_armor = getNumber (_cfg_entry / "armor");

			if (_armor < 0.5) then
			{
				_cfgDestEff = (_cfg_entry / "DestructionEffects");
				_brokenGlass = _cfgDestEff select 0;
				_selection_name = getText (_brokenGlass / "position");
				_model_pos = _house selectionPosition _selection_name;
				_world_pos = _house modelToWorld _model_pos;
				_window_pos_arr = _window_pos_arr + [_world_pos];
			};
		};
	}; 
	
	_window_pos_arr
};


Aze_WillSee = {
// garrison func from ....
	private ["_see","_infront","_opp","_adj","_hyp","_eyes","_obstruction","_angle"];

	_unit = _this select 0;
	_angle = _this select 1;
	_bld = _this select 2;
	_essai = 0;

	If (count _this > 3) then {_essai = _this select 3;};

	_eyes = eyepos _unit;

	_hyp = 10;
	_adj = _hyp * (cos _angle);
	_opp = sqrt ((_hyp*_hyp) - (_adj * _adj));

	
	_infront = if ((_angle) >=  180) then 
	{
		[(_eyes select 0) - _opp,(_eyes select 1) + _adj,(_eyes select 2)]
	} 
	else 
	{
		[(_eyes select 0) + _opp,(_eyes select 1) + _adj,(_eyes select 2)]
	};

	_obstruction = (lineintersectswith [_eyes,_infront,_unit]) select 0;


	_see = if (isnil("_obstruction")) then {true} else {false};

	If (!_see && _essai < 15) exitwith 
	{
		_essai = _essai + 1;
		_angle = random 360;
		[_unit,_angle,_bld,_essai] call Aze_WillSee;
	};

	If (_see) then 
	{
		_posATL = getPosATL _unit;

		_abx = (_infront select 0) - (_posATL select 0);
		_aby = (_infront select 1) - (_posATL select 1);
		_abz = (_infront select 2) - (_posATL select 2);

		_vec = [_abx, _aby, _abz];

		// Main body of the function;

		_unit setVectorDir _vec;
		sleep 0.02;
		_unit lookat ObjNull;
		_unit lookat [_infront select 0,_infront select 1, 1];
		
		// _ballCover = "Sign_Arrow_Large_GREEN_F" createvehicle [0,0,0];
		// _ballCover setpos [_infront select 0,_infront select 1, 1];
	};
};



Aze_Inbuilding = {
private ["_Inbuilding","_posunit","_unit","_abovehead","_roof"];
	_unit = _this select 0;

	_posunit = [(getposASL _unit) select 0,(getposASL _unit) select 1,((getposASL _unit) select 2) + 0.5];
	_abovehead = [_posunit select 0,_posunit select 1,(_posunit select 2) + 20];

	_roof = (lineintersectswith [_posunit,_abovehead,_unit]) select 0;

	_Inbuilding = if (isnil("roof")) then {false} else {true};

_Inbuilding
};


Aze_SortOutBldpos = {
	private ["_bld","_bldpos","_windowspos","_doorspos","_otherspos","_windowsposition","_doorsposition"];
	_bld = _this select 0;
	_bldpos = _this select 1;

	_windowspos = [];
	_doorspos = [];
	_otherspos = [];
	_allpos = [];
	_roofspos = [];

	if (!(typeof _bld in MON_Bld_ruins)) then {
	_windowsposition = [_bld] call Aze_checkwindowposition;
	_doorsposition = [_bld] call Aze_checkdoorposition;};

		sleep 0.1;
	{
		_bldpos1 = _x;
		_loop = true;
		if (!(typeof _bld in MON_Bld_ruins)) then 
		{
			If (count _windowsposition > 0) then 
			{
				{
					_windowpos1 = _x;
					If (_bldpos1 distance _windowpos1 <= 2) then {_windowspos = _windowspos + [_bldpos1]; _loop = false;};
				} foreach _windowsposition;
			};
			If (count _doorsposition > 0 && _loop) then 
			{
				{
					_doorpos1 = _x;
					If (_bldpos1 distance _doorpos1 <= 2) then {_doorspos = _doorspos + [_bldpos1]; _loop = false;};			
				} foreach _doorsposition;
		
			};
		} 
		else 
		{
			_pos1 = _bldpos1 select 2;
			If (_pos1 >= 3) then {_roofspos = _roofspos + [_bldpos1]; _loop = false;};
		};
		
		
		If (_loop) then {
		_otherspos = _otherspos + [_bldpos1];
		};
	
	} foreach _bldpos;
	
	if (KRON_UPS_Debug>0) then {
	if (count _windowspos > 0) then {
	{
	_ballCover = "Sign_Arrow_Large_BLUE_F" createvehicle [0,0,0];
 	_ballCover setpos _x;	
	} foreach _windowspos;
	};
	
	if (count _doorspos > 0) then {
	{
	_ballCover = "Sign_Arrow_Large_RED_F" createvehicle [0,0,0];
 	_ballCover setpos _x;	
	} foreach _doorspos;
	};
	
	if (count _otherspos > 0) then {
	{
	_ballCover = "Sign_Arrow_Large_GREEN_F" createvehicle [0,0,0];
	_ballCover setpos _x;	
	} foreach _otherspos;
	};
	};

		if (count _windowspos > 0) then 
	{
		_windowspos call BIS_fnc_arrayShuffle;
		sleep 0.1;
		_allpos = _allpos + _windowspos;
	};
	
	if (count _doorspos > 0) then 
	{
		_doorspos call BIS_fnc_arrayShuffle;
		sleep 0.1;
		_allpos = _allpos + _doorspos;
	};
		if (count _roofspos > 0) then 
	{
		_roofspos call BIS_fnc_arrayShuffle;
		sleep 0.1;
		_allpos = _allpos + _roofspos;
	};
		if (count _otherspos > 0) then 
	{
//		_otherspos call BIS_fnc_arrayShuffle;
		sleep 0.1;
		_allpos = _allpos + _otherspos;
	};
	
	

	// if (isNil (_bld getvariable "Aze_bldPos")) then {_bld setvariable ["Aze_bldPos",_allpos];};
	
	_allpos

};

Aze_SortOutBldpos2 = {
	private ["_bld","_bldpos","_initpos","_allpos"];
	_bld = _this select 0;
	_bldpos = _this select 1;
	_initpos = _this select 2;
	
	_downpos = [];
	_roofpos = [];
	_allpos = [];

		sleep 0.1;
	{
		_bldpos1 = _x;
		_pos1 = _bldpos1 select 2;

		If (_pos1 >= 2) then {_roofpos = _roofpos + [_bldpos1];};
		If (_pos1 < 2) then {_downpos = _downpos + [_bldpos1];};
			
	} foreach _bldpos;
		
		If (_initpos == "RANDOMUP") then {_allpos = _roofpos;};
		If (_initpos == "RANDOMDN") then {_allpos = _downpos;};
		If (_initpos == "ALL") then {_allpos = _roofpos + _downpos;};
		
		_allpos = _allpos call BIS_fnc_arrayShuffle;
		
	if (isNil (_bld getvariable "Aze_bldPos")) then {_bld setvariable ["Aze_bldPos",_allpos];};
	
	_allpos

};

//Function to move al units of squad to near buildings
//Parámeters: [_npc,(_patrol,_minfloors)]
//	<-	 _units: array of units
//	<-	 _blds: array of buildingsinfo [_bld,pos]
//	<-	 _patrol: wheter must patrol or not
//	->	_bldunitsin: array of units moved to builidings
MON_moveBuildings2 = {
	private ["_npc","_altura","_pos","_bld","_bldpos","_posinfo","_blds","_cntobjs1","_bldunitin","_blddist","_i","_patrol","_wait","_all","_minpos","_blds2"];
	_patrol = false;
	_wait = 60;
	_minpos  = 2;
	_all = true;


	_units = _this select 0;
	_blds = _this select 1;
	
	_altura = 0;
	_pos =0;
	_bld = objnull;
	_bldpos =[];
	_cntobjs1=0;
	_bldunitsin=[];
	_movein=[];
	_blds2 =[];

	//if (KRON_UPS_Debug>0) then {player globalchat format["MON_moveBuildings _units=%1 _blds=%2",count _units, count _blds];	};	
	if (KRON_UPS_Debug>0) then {diag_log format["MON_moveBuildings _units=%1 _blds=%2",count _units, count _blds];};	
	{
		_bld 		= _x select 0;
		_bldpos 	= _x select 1;
		
		if (KRON_UPS_Debug>0) then {diag_log format["_units=%1 _bld=%2 _bldpos=%3",count _units, _bld,_bldpos];};
		
		if ( count _bldpos >= _minpos ) then {
			_cntobjs1 = 2;		
			_movein = [];
			_i = 0;		
		if (count _bldpos == 2) then { _cntobjs1 =  1;};
		if (count _bldpos >= 5) then { _cntobjs1 =   round(random 1) + 2;};
		if (count _bldpos >= 8) then { _cntobjs1 =   round(random 3)  + 2;};				
				
		
			//Buscamos una unidad cercana para recorrerlo
			{							
				if (_x iskindof "Man" && unitReady _x && canmove _x && alive _x && vehicle _x == _x && _i < _cntobjs1) then{
					_movein = _movein + [_x];
					_i = _i + 1;						
				};
			} foreach  _units;		
			
			//if (KRON_UPS_Debug>0) then {player globalchat format["_units=%3 _bldunitsin %4 _movein=%1",_movein, typeof _bld, count _units, count _bldunitsin];}
			if (KRON_UPS_Debug>0) then {diag_log format["_units=%3 _bldunitsin %4 _movein=%1 %2 %5",_movein, typeof _bld, count _units, count _bldunitsin,_x];};	
						
			if (count _movein > 0) then 
			{
				_bldunitsin = _bldunitsin + _movein;	
				_units = _units - _bldunitsin;					

			
				{
					If (1 in _bldpos) then {_bldpos = _bldpos - [1];};
					_altura = _bldpos select 0;
					[_x,_bld,_altura] spawn MON_movetoBuilding2;
					_bldpos set [0,1];
					_bldpos = _bldpos - [0];
					sleep 0.3;
					_bldpos = _bldpos - [1];	
				}foreach _movein;
												
			};	
		};
		if (count _units == 0) exitwith {_bld setvariable ["Aze_bldPos",_x select 1];};
		if (KRON_UPS_Debug>0) then {diag_log format["_units=%1 _bld=%2 _bldpos=%3",count _units, _bld,_bldpos];};
	}foreach _blds;	
	
	_bld setvariable ["Aze_bldPos",_blds select 1];
	//If need to enter all units in building and rest try with a superior lvl
	if ( _all && count _units > 0 ) then {
		_blds2 = [];
		_minpos = _minpos;
		{
			if ( count (_x select 1) >= _minpos) then {
				_blds2 = _blds2 + [_x];
			};
		}foreach _blds;
		
		//if (KRON_UPS_Debug>0) then {player globalchat format["MON_moveBuildings exit _units=%1 _blds=%2",count _units, count _blds2];	};	
		//if (KRON_UPS_Debug>0) then {diag_log format["MON_moveBuildings exit _units=%1 _blds=%2",count _units, count _blds2];};			
		
		if (count _blds2 > 0 ) then {
			[_units, _blds2] spawn MON_moveBuildings2;	
		};
		_bldunitsin = _bldunitsin + _units;
	};
	sleep 5;
	(group (_units select 0)) setSpeedmode "LIMITED";
};

//Function to move a unit to a position in a building
//Parámeters: [_npc,(_patrol,_minfloors)]
//	<-	 _npc: soldier
//	<-	 _bld: building
//	<-	 _altura: building
//	<-	 _wait: time to wait in position
MON_movetoBuilding2 = {

	private ["_npc","_altura","_bld","_wait","_dist","_retry","_soldiers"];
	_wait = 60; // 60
	_timeout = 120; // 120
	_dist = 0;
	_retry = false;
	_retrynb = 0;
		
	_npc = _this select 0;
	_bld = _this select 1;
	_altura = _this select 2;
	
	if ((count _this) > 3) then {_retrynb = _this select 3; _retrynb = _retrynb + 1;};
	If (_retrynb > 2) exitwith {};

	//Si está en un vehiculo ignoramos la orden
	if (vehicle _npc != _npc || !alive _npc || !canmove _npc) exitwith{};
	
	//Si ya está en un edificio ignoramos la orden
	_inbuilding = _npc getvariable ("UPSMON_inbuilding");
	if ( isNil("_inbuilding") ) then {_inbuilding = false;};	
	if (_inbuilding)  exitwith{};
	
	diag_log format["%4|_bld=%1 | %2 | %3",typeof _bld, _npc, typeof _npc ,_altura];
	_oldposnpc = getpos _npc;
	_npc setpos _altura; 	
	_npc setVariable ["UPSMON_inbuilding", _inbuilding, false];		
	_npc setvariable ["UPSMON_buildingpos", nil, false];

	if (KRON_UPS_Debug>0) then {player globalchat format["%4|_bld=%1 | %2 | %3",typeof _bld, _npc, typeof _npc ,_altura];};	
	//if (KRON_UPS_Debug>0) then {diag_log format["%4|_bld=%1 | %2 | %3",typeof _bld, _npc, typeof _npc ,_altura];};
	
	waitUntil {(_npc distance _altura <= 1) || !alive _npc || !canmove _npc};
	
	if ((_npc distance _altura <= 1) && alive _npc && canmove _npc) then {			
		//_dist = [position _npc,_bld buildingPos _altura] call KRON_distancePosSqr;		
		_soldiers = [_npc,0.5] call MON_nearestSoldiers;			
		//If more soldiers in same floor see to keep or goout.
		if (count _soldiers > 0) then {					
			{
				if (!isnil{_x getvariable ("UPSMON_buildingpos")}) exitwith {_retry = true};								
			}foreach _soldiers;				
		};		
			
		if (!_retry) then {
			_npc setvariable ["UPSMON_buildingpos", _altura, false];	
			sleep 0.1;
			dostop _npc;
			sleep 0.1;
			[_npc,getdir _npc,_bld] call Aze_UnitWatchDir;
			sleep 1;
			if (!isNil "tpwcas_running") then {_npc setvariable ["tpwcas_cover", 2];};
		};	
	};
	
	if (_npc distance _altura > 1) then {_retry = true};
	if (!alive _npc || !canmove _npc) exitwith{};	
	_npc setVariable ["UPSMON_inbuilding", false, false];			
	
	//hint format ["Unit has moved to %1 %2  Retry: %4",_altura,_npc distance _altura <= 0.5,_retry];
	//Down one position.
	if (_retry ) then {	
		_altura = [];
		_allpos = [];
		if (isNil (_bld getvariable "Aze_bldPos")) then {_allpos = _bld getvariable "Aze_bldPos";};
		sleep 0.2;
		If (1 in _allpos) then {_allpos = _allpos - [1];};
		If (count _allpos > 0) then 
		{
			_altura = _allpos select 0;
			_allpos set [0,1];
			_allpos = _allpos - [0];
			sleep 0.3;
			_allpos = _allpos - [1];
			_bld setvariable ["Aze_bldPos",_allpos];
		};
		
		// diag_log format["%4|_bld=%1 | %2 | %3 | retry: %4",typeof _bld, _npc, typeof _npc ,_altura,_retry];
		if (count _altura != 0) then {[_npc,_bld,_altura,_retrynb] spawn MON_movetoBuilding2;};
	};
};

Aze_filterbuilding = {
    private []; 
    if ((typeof _this) in MON_Bld_remove) exitWith {false}; 
    if ([_this,2] call BIS_fnc_isBuildingEnterable) exitWith {true}; 
   
	false
}; 

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Aze_checkallied = {
private ["_npc","_mennear","_result","_pos","_radius"];

	_npc = _this select 0;
	_radius = _this select 1;
	_pos = _npc;
	
	if (count _this > 2) then {_pos = _this select 2;};
	
	_mennear = nearestobjects [_pos,["CAManBase"],_radius];
	_result = false;
	_allied = [];
	_eny = [];

	{
		If ((alive _x) && (side _x == side _npc) && !(_x in (units _npc))) then {_allied = _allied + [_x];};
		If ((alive _x) && (side _x != side _npc) && _npc knowsabout _x >= R_knowsAboutEnemy) then {_eny = _eny + [_x];}
	} foreach _mennear;
	

	_result = [_allied,_eny];
	_result
};

////////////////////////////////////////////////////////////////////// Target Module ////////////////////////////////////////////////////////

Aze_TargetAcquisition = {

	private ["_npc","_shareinfo","_closeenough","_NearestEnemy","_sharedenemy","_target","_targets","_dist","_opfknowval","_newtarget","_newattackPos","_targetsnear","_attackPos","_Enemies"];
	
	_npc = _this select 0;
	_shareinfo = _this select 1;
	_closeenough = _this select 2;
	_flankdir = _this select 3;

	
	_NearestEnemy = objNull;
	_target = objNull;
	_opfknowval = 0;
	_attackPos = [0,0];
	_Enemies = [];
	_targetsnear = false;
		
		
	// if (KRON_UPS_Debug>0) then {player globalchat format["targets from global upsmon: %1",_targets]};	//!R
		
	_Enemies = [_npc,_shareinfo] call Aze_findnearestenemy;
	If (count _Enemies > 0) then
	{
		_NearestEnemy = _Enemies select 0;
	};

		If (IsNull _NearestEnemy) then 
		{	
			//Reveal targets found by members to leader
			{
				_Enemies = [_x,"NOSHARE"] call Aze_findnearestenemy;
				
				If (count _Enemies > 0) then
				{
					_NearestEnemy = _Enemies select 0;
				};
				
				if ((!IsNull _NearestEnemy) && (_x knowsabout _NearestEnemy > R_knowsAboutEnemy) 
				&& (_npc knowsabout _NearestEnemy <= R_knowsAboutEnemy)) then 	
				{		
				
					if (_npc knowsabout _NearestEnemy <= R_knowsAboutEnemy ) then 	
					{		 
						_npc reveal [_NearestEnemy,1.5];	
					};
				

					_target = _NearestEnemy;
					_opfknowval = _npc knowsabout _target;
					_NearestEnemy setvariable ["UPSMON_lastknownpos", position _NearestEnemy, false];						
					if (KRON_UPS_Debug>0) then {player globalchat format["%1: %3 added to targets",_grpidx,typeof _x, typeof _target]}; 						
				};
			} foreach units (group _npc);
		}
		else
		{
			_target = _NearestEnemy;
			_opfknowval = _npc knowsabout _target;
			_NearestEnemy setvariable ["UPSMON_lastknownpos", position _NearestEnemy, false];
		};

		//Resets distance to target
		_dist = 10000;
		
		
		//Gets  current known position of target and distance
		if ( !isNull (_target) && alive _target ) then 
		{
			_newattackPos = _target getvariable ("UPSMON_lastknownpos");
			
			if ( !isnil "_newattackPos" ) then {
				_attackPos=_newattackPos;	
				//Gets distance to target known pos
				_dist = ([_currpos,_attackPos] call KRON_distancePosSqr);				
			};
		};
					
		If (_dist <= 300) then {_targetsnear = true;};
		
		_newtarget = _target;			
		_lastTarget = (_npc getvariable "UPS_Lastinfos") select 4;			
			//If you change the target changed direction flanking initialize
			if ( !isNull (_newtarget) && alive _newtarget && canmove _newtarget && (_newtarget != _lastTarget || isNull (_lastTarget)) ) then {
				_timeontarget = 0;
				_targetdead = false;
				_flankdir= if (random 100 <= 10) then {0} else {_flankdir};	
				_target = _newtarget;			
			};	

		_result = [_Enemies,_target,_dist,_opfknowval,_targetsnear,_attackPos,_timeontarget,_targetdead,_flankdir];
		
		_result
};

Aze_findnearestenemy = {
	private["_npc","_targets","_enemies","_enemySides","_side","_unit"];
	_npc = _this select 0;
	_shareinfo = _this select 1;
	_enemies = [];

	_targets = _npc nearTargets 400;
	
	_enemySides = _npc call BIS_fnc_enemySides;
	
	if (KRON_UPS_Debug>0) then {diag_log format ["Targets found by %1: %2",_npc,_targets];};
	
	{
		_unit = (_x select 4);
		_side = (_x select 2);

		if ((_side in _enemySides) && (count crew _unit > 0) && _npc knowsabout _unit >= R_knowsAboutEnemy) then
		{
			if ((side driver _unit) in _enemySides) then
			{
				_enemies set [count _enemies, _unit];
			};
		};
	} forEach _targets;

	If (count _enemies > 0) then
	{
		_enemies = [_enemies, [], { _npc distance _x }, "ASCEND"] call BIS_fnc_sortBy;
		If (_shareinfo=="SHARE") then 
		{
			{
				_alliednpc = _x;
				If (side _npc == side _alliednpc && _npc distance _alliednpc <= KRON_UPS_sharedist) then {{_enemy = _x; _alliednpc reveal [_enemy,1.5];} count _enemies > 0;};	
			} count KRON_NPCs > 0;
		};	
	};
	
	_enemies
};

