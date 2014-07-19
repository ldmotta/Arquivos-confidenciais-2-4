UPSMON_SrchPtrlPos = {
	private ["_npc","_jumpers","_areamarker","_targetPos","_incar","_inheli","_inboat","_isdiver","_dist","_currPos","_result","_water","_mindist","_i"];
	
	_npc = _this select 0;
	_areamarker = _this select 1;
	_onroad = _this select 2;
	_typeofgrp = _this select 3;
	
	_currPos = getposATL _npc;
	_targetPos = [];
	_isMan = false;
	_dist = 1;
	_mindist = 10;
	_water = 0;
	
	if (!("ship" in _typeofgrp) && !("air" in _typeofgrp)&& !("car" in _typeofgrp) && !("tank" in _typeofgrp) ) then {_isMan = true;};
	
	{_x stop false;_x dofollow (leader _x)} foreach units _npc;	
	// find a new target that's not too close to the current position

	if (_isMan) then
	{
		//_targetPos = [_npc,_areamarker,_dist,5,1,0,false] call UPSMON_FindPos;
	}
	else // vehicle
	{
		If (("car" in _typeofgrp) || ("tank" in _typeofgrp)) then		
		{
			_dist = 10;
			_mindist = 30;
		}
		else // boat or plane
		{
			If ("air" in _typeofgrp) then
			{
				_water = 1;
				_dist = 0;
				_mindist = 70;
			}
			else // boat
			{
				_water = 2;
				_dist = 0;
				_mindist = 30;
			};
		};
	};
	
	_i = 0;
	
	while {count _targetPos == 0 && _i < 50} do 
	{
		_i = _i + 1;
		_targetPosTemp = [_areamarker,_water,[],_dist] call UPSMON_pos;
		if (_onroad && !("ship" in _typeofgrp) && !("air" in _typeofgrp)) then
		{
			_nearRoads = _targetPosTemp nearRoads 300;
			If (count _nearRoads > 0) then {If ([position (_nearRoads select 0),_areamarker] call UPSMON_pos_fnc_isBlacklisted) then {_targetpostemp = position (_nearRoads select 0);};};
		};
		If (("car" in _typeofgrp) || ("tank" in _typeofgrp)) then
		{
			if ((!_onroad || (_onroad && count (_targetPosTemp nearRoads 50) == 0))) then
			{
				_terrainscan = _targetPosTemp call UPSMON_sample_terrain;
				If ((_terrainscan select 0) == "meadow") then
				{
					If ((([_currpos,_targetPosTemp] call UPSMON_distancePosSqr) >= _mindist)) then {_targetpos = _targetPosTemp;};
				};
			};
		}
		else
		{
			If ("ship" in _typeofgrp && (surfaceIsWater _targetPosTemp)) then
			{
				If ((([_currpos,_targetPosTemp] call UPSMON_distancePosSqr) >= _mindist)) then {_targetpos = _targetPosTemp;};
			} 
			else
			{
				If ((([_currpos,_targetPosTemp] call UPSMON_distancePosSqr) >= _mindist)) then {_targetpos = _targetPosTemp;};
			};
		};
	};
	
	If (count _targetPos == 0) then {_targetPos = _currPos;};
	
	_result = _targetPos;
	_result

};


UPSMON_SrchFlankPos = 
{
	private ["_npcpos","_dir2","_targetPos","_side","_typeofgroup","_dist","_flankAngle","_flankdist","_roadchk","_distmin","_pool","_targetPosTemp","_terrainscan","_los_ok","_i","_final"];
	_npcpos = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_side = _this select 3;
	_typeofgrp = _this select 4;
	_grpid = _this select 5;
	_dist = [_npcpos,_targetpos] call UPSMON_distancePosSqr; 
	
	_flankAngle = 45;
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.2)+1)*(_dist/1.5);
	//_dist = [0,200];
	_distmin = 1;
	_roadchk = [0,50];
	If ("car" in _typeofgrp || "tank" in _typeofgrp) then 
	{
		_roadchk = [1,50];
		_distmin = 10;
		_flankdist = ((random 0.2)+1)*(_dist/2);
		//_dist = [0,500];
	};
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if ((_flankdist) >= _dist) then {_dist/1.5} else {_flankdist};
	
	_pool = [];
	
	
	for "_i" from 1 to 20 do
	{
		_targetPosTemp = [_targetPos,[_flankdist,_flankdist + (_flankdist -_dist)],[_dir2 +70,_dir2+270],0,_roadchk,_distmin] call UPSMON_pos;
		if (!surfaceIsWater _targetPosTemp) then {_pool set [(count _pool),[_targetPosTemp select 0,_targetPosTemp select 1,0]]}
	};	
	
	{
		_pos = _x;
		_pos set [(count _pos),0];
		If ("car" in _typeofgrp || "tank" in _typeofgrp) then 
		{
			If (isOnRoad [_pos select 0, _pos select 1]) then
			{ 
				_pos set [3,(_pos select 3) +100];
			};
			_value = [[_pos select 0, _pos select 1,0],1,1] call UPSMON_TerraCognita;
			_meadow = _value select 3;
			_terr = _meadow * 100;
			_elev = getTerrainHeightASL [_pos select 0,_pos select 1];
			_pos set [3,(_pos select 3) + _terr + _elev];
		}
		else
		{
			_value = [[_pos select 0, _pos select 1,0],1,1] call UPSMON_TerraCognita;
			_urban = _value select 0;
			_forest = _value select 1;
			_terr = (_urban + _forest) * 100;
			_elev = getTerrainHeightASL [_pos select 0,_pos select 1];
			_pos set [3,(_pos select 3) +_terr + _elev];
		};
		
		_los_ok = [_targetPos,[_pos select 0,_pos select 1,0]] call UPSMON_LOS;
		If (_los_ok) then {_pos set [3,(_pos select 3) + 100];};
		
		_i = 0;
		
		{
			_grp = _x;
			if (!isnil "_grp") then 
			{
				_posgrp = _grp getvariable ["UPSMON_targetpos",[0,0]];
				if ( _i != _grpid && !isnull(_grp) && side _grp == _side &&  {_posgrp select 0 != 0 && _posgrp select 1 != 0} ) then 
				{
					_dist1 = [_posgrp,[_pos select 0,_pos select 1,0]] call UPSMON_distancePosSqr;
					_dist2 = [getposATL (leader _grp),[_pos select 0,_pos select 1,0]] call UPSMON_distancePosSqr;
					if (_dist1 > 100) then 
					{					
						_pos set [3,(_pos select 3) + 50];
					};
					if (_dist2 > 100) then 
					{					
						_pos set [3,(_pos select 3) + 50];
					};
				};
			}; 
		_i = _i + 1;		
		} foreach UPSMON_NPCs;
		sleep 0.01;
	} foreach _pool;

	_pool = [_pool] call UPSMON_ValueOrd;
	_final = [];
	{
		_final set [(count _final),[_x select 0,_x select 1,0]]
	} foreach _pool;

	//_final = [_final, [], { _npcpos distance _x }, "ASCEND"] call BIS_fnc_sortBy;
	If (count _final > 0) then {_targetpos = _final select 0;};
	
	_array = _targetPos;
	_array
};

UPSMON_SrchFlankPosforboat = 
{
	private ["_npcpos","_dir2","_targetPos","_flankdir","_side","_typeofgroup","_dist","_flankAngle","_flankdist","_pool","_targetPosTemp","_terrainscan","_los_ok","_i","_final"];
	_npcpos = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_side = _this select 3;
	_grpid = _this select 4;
	_dist = [_npcpos,_targetpos] call UPSMON_distancePosSqr; 
	
	_flankAngle = 45;
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.3)+0.5)*(_dist/2);
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if ((_flankdist) >= _dist) then {_dist*.65} else {_flankdist};

	_pool = [];
		
	for "_i" from 1 to 30 do
	{
		_targetPosTemp = [_targetPos,[_flankdist,_dist],[_dir2 + 70,_dir2 + 290],2,[0,50],1] call UPSMON_pos;
		if (surfaceIsWater _targetPosTemp) then {_pool set [(count _pool),[_targetPosTemp select 0,_targetPosTemp select 1,0]]}
	};	
	
	{
		_pos = _x;
		_pos set [(count _pos),0];
		_los_ok = [_targetPos,[_pos select 0,_pos select 1,0]] call UPSMON_LOS;
		If (_los_ok) then {_pos set [(count _pos),100];};
		_i = 0;
		
		{
			_grp = _x;
			if (!isnil "_grp") then 
			{
				_posgrp = _grp getvariable ["UPSMON_targetpos",[0,0]];
				if ( _i != _grpid && !isnull(_grp) && side _grp == _side &&  {_posgrp select 0 != 0 && _posgrp select 1 != 0} ) then 
				{
					_dist1 = [_posgrp,[_pos select 0,_pos select 1,0]] call UPSMON_distancePosSqr;
					_dist2 = [getposATL (leader _grp),[_pos select 0,_pos select 1,0]] call UPSMON_distancePosSqr;
					if (_dist1 > 100) then 
					{					
						_pos set [3,(_pos select 3) + 50];
					};
					if (_dist2 > 100) then 
					{					
						_pos set [3,(_pos select 3) + 50];
					};
				};
			}; 
		_i = _i + 1;		
		} foreach UPSMON_NPCs;
		sleep 0.02;
	} foreach _pool;
	
	_pool = [_pool] call UPSMON_ValueOrd;
	_final = [];
	{
		_final set [(count _final),[_x select 0,_x select 1,0]]
	} foreach _pool;
	
	If (count _final > 0) then {_targetpos = _final select 0;};
	
	_array = _targetPos;
	_array
};

UPSMON_SrchFlankPosforPlane = 
{
	private ["_npcpos","_dir2","_targetPos","_flankdir","_side","_typeofgroup","_dist","_flankAngle","_flankdist","_pool","_targetPosTemp","_terrainscan","_los_ok","_i","_final"];
	_npcpos = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_side = _this select 3;
	_grpid = _this select 4;
	_dist = [_npcpos,_targetpos] call UPSMON_distancePosSqr; 
	
	_flankAngle = 45;
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.3)+1)*(_dist/2);
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if ((_flankdist) >= _dist) then {_dist*.65} else {_flankdist};

	_pool = [];
		
	for "_i" from 1 to 20 do
	{
		_targetPosTemp = [_targetPos,[_flankdist,_dist],[_dir2 + 70,_dir2 + 290],1,[0,50],1] call UPSMON_pos;
		_pool set [(count _pool),[_targetPosTemp select 0,_targetPosTemp select 1,0]];
	};	
	
	{
		_i = 0;
		_pos = _x;
		_pos set [(count _pos),0];
		{
			if (!isnil "_pos") then 
			{
				_grp = _x;
				_posgrp = _grp getvariable ["UPSMON_targetpos",[0,0]];
				if ( _i != _grpid && !isnull(_grp) && side _grp == _side &&  { _posgrp select 0 != 0 && _posgrp select 1 != 0} ) then 
				{
					_dist1 = [_posgrp,[_pos select 0,_pos select 1,0]] call UPSMON_distancePosSqr;
					_dist2 = [getposATL (leader _grp),[_pos select 0,_pos select 1,0]] call UPSMON_distancePosSqr;
					if (_dist1 > 100) then 
					{					
						_pos set [3,(_pos select 3) + 50];
					};
					if (_dist2 > 100) then 
					{					
						_pos set [3,(_pos select 3) + 50];
					};
				};
			}; 
		_i = _i + 1;		
		} foreach UPSMON_NPCs;
		sleep 0.02;
	} foreach _pool;
	
	_pool = [_pool] call UPSMON_ValueOrd;
	_final = [];
	{
		_final set [(count _final),[_x select 0,_x select 1,0]]
	} foreach _pool;
	
	If (count _final > 0) then {_targetpos = _final select 0;};
	
	_array = _targetPos;
	_array
};


UPSMON_SrchRetreatPos = 
{
	private ["_npc","_dist","_dir2","_exp","_avoidPos","_bestplaces","_roadcheckpos"];
	_npc = _this select 0;
	_direction = _this select 1;
	_dist = _this select 2;
	
	_currpos = getposATL _npc;
	_water = 0;
	_avoidPos = [];
	_i = 0;
	
	_inboat = "Ship" countType [vehicle (_npc)]>0;
	_isdiver = ["diver", (typeOf (leader _npc))] call BIS_fnc_inString;
	
	_exp = "(50 * trees) + (2 * forest) + (5 * houses) - (1000 * Sea)";
	If (("LandVehicle" countType [vehicle (_npc)]>0) || ("Air" countType [vehicle (_npc)]>0)) then {_exp = "(50 * trees) - (100 * houses) - (100 * forest) - (100 * hills) - (1000 * Sea)";};
	If (_inboat || _isdiver) then {_exp = "(1000 * Sea)";_water = 1;};
	
	while {count _avoidPos == 0 && _i < 50} do 
	{
		_i = _i +1;
		// avoidance position (right or left of unit)
		_avoidPostemp = [_currpos,[_dist,_dist + 100],_direction,_water,[0,100],1] call UPSMON_pos;	

		_bestplaces = selectBestPlaces [_avoidPostemp,10,_exp,5,1];
		If (count (_bestplaces select 0) > 0) then {_avoidPos =_avoidPostemp};
	};
	
	If (count _avoidPos == 0) then {_avoidPos = _currpos};
	_avoidPos;
};