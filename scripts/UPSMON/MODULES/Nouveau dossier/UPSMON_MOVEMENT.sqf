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
	
	
	// find a new target that's not too close to the current position

	if (_isMan) then
	{
		//_targetPos = [_npc,_areamarker,_dist,5,1,0,false] call UPSMON_FindPos;
	}
	else // vehicle
	{
		If (("car" in _typeofgrp) || ("tank" in _typeofgrp)) then		
		{
			_dist = 8;
			_mindist = 30;
		}
		else // boat or plane
		{
			If ("air" in _typeofgrp) then
			{
				_water = 1;
				_dist = 1;
				_mindist = 50;
			}
			else // boat
			{
				_water = 2;
				_dist = 1;
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
			_nearRoads = _targetPosTemp nearRoads 50;
			diag_log format ["%1",_nearRoads];
			If (count _nearRoads > 0) then {_targetpostemp = position (_nearRoads select 0);};
		};
		
		If ((_currpos distanceSqr _targetPosTemp >= _mindist)) then {_targetpos = _targetPosTemp;};
	};
	
	If (count _targetPos == 0) then {_targetPos = _currPos;};
	
	_result = _targetPos;
	_result

};


UPSMON_SrchFlankPos1 = 
{
	private ["_npc","_dir2","_targetPos","_flankdir","_loop","_flankdist","_exp","_frontPos","_bestplaces","_roadcheckpos","_newflankAngle","_dirf1","_dirf2","_flankPos","_flankPos2","_fldest","_fldest2","_fldestfront","_dist1","_dist2","_dist3","_targetpos","_targettext","_i","_prov"];
	_npc = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_flankdir = _this select 3;
	_dist = [getpos _npc,_targetpos] call UPSMON_distancePosSqr; 

	_loop = true;
	_pos = [0,0];
	_flankAngle = 45;
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.3)+0.7)*(_dist/2);
	
	_incar = "LandVehicle" countType [vehicle (_npc)]>0;
	_isdiver = ["diver", (typeOf (leader _npc))] call BIS_fnc_inString;
	
	If (_incar) then {_flankdist = ((random 0.5)+0.9)*(_dist/2);};
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if ((_flankdist) >= _dist) then {_dist*.65} else {_flankdist};
			
	_exp = "(70 * trees) + (5 * houses) -(1000 * Sea)";
	If (("LandVehicle" countType [vehicle (_npc)]>0)) then {_exp = "(100*meadow) + (trees) - (forest) - (1000 * Sea) - (2* houses)";};

	_orig = "Land_HelipadEmpty_F" createVehicleLocal _targetPos;
	_loglos = "logic" createVehicleLocal [0,0,0];
		
	//Calculamos posición de avance frontal			
	_frontPos = [_targetPos,_dir2, _flankdist] call UPSMON_GetPos2D;	
			
	_bestplaces = selectBestPlaces [_frontPos,60,_exp,20,5];
	
	If ((count _bestplaces) > 0) then 
	{
	
		_frontPos = (_bestplaces select 0) select 0;
		_orig = "Land_HelipadEmpty_F" createVehicleLocal _targetPos;
		_loglos = "logic" createVehicleLocal [0,0,0];
		
		while {_loop} do 
		{
			{
				_pos = _x select 0;
				_dest = "Land_HelipadEmpty_F" createVehicleLocal _pos;
				_los_ok = [_loglos,_orig,_dest,20, 0.5] call mando_check_los;

				sleep 0.1;
				deletevehicle _dest;
				if (_los_ok) exitwith {_loop = false;_frontPos = _pos};
			} foreach _bestplaces;
			_loop = false;
		};
		
	} else 
	{
		If (vehicle _npc iskindof "LandVehicle") then 
		{
			_roadcheckpos = _frontPos nearRoads 50;
			If (count _roadcheckpos > 0) then {_frontPos = _roadcheckpos select 0;};
		};
	};

	//Adaptamos el ángulo de flanqueo a la distancia		
	_newflankAngle = ((random(_flankAngle)+1) * 2 * (_flankdist / UPSMON_safedist )) + (_flankAngle/1.4) ;
	if (_newflankAngle > _flankAngle) then {_newflankAngle = _flankAngle};			
			
	//Calculamos posición de flanqueo 1 45º
	_dirf1 = (_dir2+_newflankAngle) mod 360;			
	_flankPos = [_targetPos,_dirf1, _flankdist] call UPSMON_GetPos2D;					
			
	_bestplaces = selectBestPlaces [_flankPos,_flankdist/2,_exp,20,1];
	If ((count _bestplaces) > 0) then 
	{
		_flankPos = (_bestplaces select 0) select 0;
		
		while {_loop} do 
		{
			{
				_pos = _x select 0;
				_dest = "Land_HelipadEmpty_F" createVehicleLocal _pos;
				_los_ok = [_loglos,_orig,_dest,20, 0.5] call mando_check_los;

				sleep 0.1;
				deletevehicle _dest;
				if (_los_ok) exitwith {_loop = false;_flankPos = _pos};
			} foreach _bestplaces;
			_loop = false;
		};
	} else 
	{
		If (vehicle _npc iskindof "LandVehicle") then 
		{
			_roadcheckpos = _flankPos nearRoads 50;
			If (count _roadcheckpos > 0) then {_flankPos = _roadcheckpos select 0;};
		};
	};
			
	//Calculamos posición de flanqueo 2 -45º			
	_dirf2 = (_dir2-_newflankAngle+360) mod 360;		
	_flankPos2 = [_targetPos,_dirf2, _flankdist] call UPSMON_GetPos2D;	
			
	_bestplaces = selectBestPlaces [_flankPos2,_flankdist/2,_exp,20,5];
	If ((count _bestplaces) > 0) then 
	{
		_flankPos2 = (_bestplaces select 0) select 0;
		
		while {_loop} do 
		{
			{
				_pos = _x select 0;
				_dest = "Land_HelipadEmpty_F" createVehicleLocal _pos;
				_los_ok = [_loglos,_orig,_dest,20, 0.5] call mando_check_los;

				sleep 0.1;
				deletevehicle _dest;
				if (_los_ok) exitwith {_loop = false;_flankPos2 = _pos};
			} foreach _bestplaces;
			_loop = false;
		};
		
	} else 
	{
		If (vehicle _npc iskindof "LandVehicle") then 
		{
			_roadcheckpos = _flankPos2 nearRoads 50;
			If (count _roadcheckpos > 0) then {_flankPos2 = _roadcheckpos select 0;};
		};
	};
			
	deletevehicle _loglos;
	deletevehicle _orig;					
						
	//Decidir por el mejor punto de flanqueo
	//Contamos las posiciones de destino de otros grupos más alejadas
	_fldest = 0;
	_fldest2 = 0;
	_fldestfront = 0;
	_i = 0;
			
	{			
		if (!isnil "x") then 
		{
			if ( _i != _grpid &&  { format ["%1", _x] != "[0,0]" } ) then 
			{
				_dist1 = [_x,_flankPos] call UPSMON_distancePosSqr;
				_dist2 = [_x,_flankPos2] call UPSMON_distancePosSqr;	
				_dist3 = [_x,_frontPos] call UPSMON_distancePosSqr;	
				if (_dist1 <= _flankdist/1.5 || { _dist2 <= _flankdist/1.5 } || { _dist3 <= _flankdist/1.5 } ) then 
				{					
					if (_dist1 < _dist2 && { _dist1 < _dist3 } ) then {_fldest = _fldest + 1;};
					if (_dist2 < _dist1 && { _dist2 < _dist3 } ) then {_fldest2 = _fldest2 + 1;};
					if (_dist3 < _dist1 && { _dist3 < _dist2 } ) then {_fldestfront = _fldestfront + 1;};						
				};
			};
		}; 
		_i = _i + 1;
			
		//sleep 0.01;
	} foreach UPSMON_targetsPos;	
			
			
	//We have the positions of other groups more distant
	_i = 0;
	{
		if (!isnil "_x") then 
		{
			if (_i != _grpid && !isnull(_x)) then 
			{
				_dist1 = [getpos(_x),_flankPos] call UPSMON_distancePosSqr;
				_dist2 = [getpos(_x),_flankPos2] call UPSMON_distancePosSqr;	
				_dist3 = [getpos(_x),_frontPos] call UPSMON_distancePosSqr;
				if (_dist1 <= _flankdist/1.5 || { _dist2 <= _flankdist/1.5 } || { _dist3 <= _flankdist/1.5 } ) then 
				{						
					if (_dist1 < _dist2 && { _dist1 < _dist3 } ) then {_fldest = _fldest + 1;};
					if (_dist2 < _dist1 && { _dist2 < _dist3 } ) then {_fldest2 = _fldest2 + 1;};
					if (_dist3 < _dist1 && { _dist3 < _dist2 } ) then {_fldestfront = _fldestfront + 1;};	
				};
			};
			_i = _i + 1;
		};
			//sleep 0.01;
	} foreach UPSMON_NPCs; 
						
			
			
	//La preferencia es la elección inicial de dirección
	switch (_flankdir) do 
	{
		case 1: 
				{_prov = 125};
		case 2: 
				{_prov = -25};
		default
				{_prov = 50};
	};						
			
			
	//Si es positivo significa que hay más destinos existentes lejanos a la posicion de flanqueo1, tomamos primariamente este
	if (_fldest<_fldest2) then {_prov = _prov + 50;};
	if (_fldest2<_fldest) then {_prov = _prov - 50;};		

	//Si la provablilidad es negativa indica que tomará el flank2 por lo tanto la provabilidad de coger 1 es 0
	if (_prov<0) then {_prov = 0;};
			
				
	//Evaluamos la dirección en base a la provablilidad calculada
	if ((random 100) <= _prov) then 
	{
		_flankdir =1;
		if ((surfaceIsWater _flankPos && { !(_inheli || _inboat || _isDiver) } ) ) then 
		{_flankPos = _flankPos2;} else {_flankPos = _flankPos}; 
		_targettext = "_flankPos";
	} else {
		_flankdir =2;
		if ((surfaceIsWater _flankPos2 && { !(_inheli || _inboat || _isDiver) } ) ) then 
		{_flankPos = _flankPos;} else {_flankPos = _flankPos2}; 
		_flankPos = _flankPos2; 
		_targettext = "_flankPos2";
	};			
			
					
	//Posición de ataque por defecto el flanco
	_targetPos = _flankPos;
	_targettext = "_flankPos";
			
		
	if ((surfaceIsWater _flankPos && { !(_inheli || _inboat || _isDiver) } ) ) then 
	{
	
		_targetPos2 = _targetPos isflatempty [0,10,1,0,0,false];
		If ((!surfaceIsWater _targetPos2) && count _isFlat > 0) then {_targetpos = ASLtoATL (_targetPos2);};

		_targettext = "_attackPos"; 
		_flankdir =0;
	}
	else 
	{
		if (_fldestfront < _fldest  && _fldestfront < _fldest2) then 
		{
			_targetPos = _frontPos;
			_targettext = "_frontPos"; 
		};
	};	
	

	_array = [] + [_targetPos];
	_array = _array + [_targettext];
	_array = _array + [_flankdir];

	_array
};

UPSMON_SrchFlankPosforboat = 
{
	private ["_npc","_dir2","_targetPos","_flankdir","_loop","_flankdist","_exp","_frontPos","_bestplaces","_roadcheckpos","_newflankAngle","_dirf1","_dirf2","_flankPos","_flankPos2","_fldest","_fldest2","_fldestfront","_dist1","_dist2","_dist3","_targetpos","_targettext","_i","_prov"];
	_npc = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_flankdir = _this select 3;
	_dist = [getpos _npc,_targetpos] call UPSMON_distancePosSqr; 
	_loop = true;
	_pos = [0,0];
	_flankAngle = 45;
	_continue = true;
	_targetpostemp = [];
	_targettext = "Frontpos";
	
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.7)+1.2)*UPSMON_safedist;
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if (_flankdist >= _dist) then {_dist*1.85} else {_flankdist};
	If (!surfaceIsWater _targetPos) then 
	{
		_isFlat = _targetPos isflatempty [100,0,1,100,1,true];
		If (count _isFlat == 0) then {_continue = false;} else {_targetpostemp = _isFlat select 0;};
	};

	If (_continue) then
	{
		//Calculamos posición de avance frontal			
		_frontPos = [_targetPos,_dir2, _flankdist] call UPSMON_GetPos2D;
	
		If (!surfaceIsWater _frontpos) then 
		{
			_isFlat = _frontPos isflatempty [100,0,1,100,1,true];
			If (count _isFlat > 0) then {_frontPos = _isFlat select 0;};
		};

		//Adaptamos el ángulo de flanqueo a la distancia		
		_newflankAngle = ((random(_flankAngle)+1) * 2 * (_flankdist / UPSMON_safedist )) + (_flankAngle/1.4) ;
		if (_newflankAngle > _flankAngle) then {_newflankAngle = _flankAngle};			
			
		//Calculamos posición de flanqueo 1 45º
		_dirf1 = (_dir2+_newflankAngle) mod 360;			
		_flankPos = [_targetPos,_dirf1, _flankdist] call UPSMON_GetPos2D;					
			
		If (!surfaceIsWater _flankPos) then 
		{
			_isFlat = _flankPos isflatempty [100,0,1,100,1,true];
			If (count _isFlat > 0) then {_flankPos = _isFlat select 0;};
		};
			
		//Calculamos posición de flanqueo 2 -45º			
		_dirf2 = (_dir2-_newflankAngle+360) mod 360;		
		_flankPos2 = [_targetPos,_dirf2, _flankdist] call UPSMON_GetPos2D;	
			
		If (!surfaceIsWater _flankPos2) then 
		{
			_isFlat = _flankPos2 isflatempty [100,0,1,100,1,true];
			If (count _isFlat > 0) then {_flankPos2 = _isFlat select 0;};
		};
						
						
		//Decidir por el mejor punto de flanqueo
		//Contamos las posiciones de destino de otros grupos más alejadas
		_fldest = 0;
		_fldest2 = 0;
		_fldestfront = 0;
		_i = 0;
						
		_prov = 50;
					
			
			
		//Si es positivo significa que hay más destinos existentes lejanos a la posicion de flanqueo1, tomamos primariamente este
		if (_fldest<_fldest2) then {_prov = _prov + 50;};
		if (_fldest2<_fldest) then {_prov = _prov - 50;};		

		//Si la provablilidad es negativa indica que tomará el flank2 por lo tanto la provabilidad de coger 1 es 0
		if (_prov<0) then {_prov = 0;};
			
				
		//Evaluamos la dirección en base a la provablilidad calculada
		if ((random 100) <= _prov) then 
		{
			_flankdir = 1;
			if (!surfaceIsWater _flankPos) then 
			{_flankPos = _flankPos2;} else {_flankPos = _flankPos}; 
			_targettext = "_flankPos";
		} else {
			_flankdir = 2;
			if (!surfaceIsWater _flankPos) then 
			{_flankPos = _flankPos;} else {_flankPos = _flankPos2}; 
			_targettext = "_flankPos2";
		};		
			
					
		//Posición de ataque por defecto el flanco
		_targetPos = _flankPos;
		_targettext = "_flankPos";
	
			
		if (!surfaceIsWater _flankPos) then 
		{
			_isFlat = _flankPos isflatempty [100,0,1,100,1,true];
			If ((surfaceIsWater (_isFlat select 0)) && count _isFlat > 0) then {_targetpos = _isFlat;};
			_targettext = "_attackPos"; 
			_flankdir =0;
		}
		else 
		{
			if (_fldestfront < _fldest  && _fldestfront < _fldest2) then 
			{
				_targetPos = _frontPos;
				_targettext = "_frontPos"; 
			};
		};	
	};

	_array = [] + [_targetPos];

	_array
};

UPSMON_SrchFlankPosforPlane = 
{
	private ["_npc","_dir2","_targetPos","_flankdir","_flankdist","_frontPos","_newflankAngle","_dirf1","_dirf2","_flankPos","_flankPos2","_fldest","_fldest2","_fldestfront","_dist1","_dist2","_dist3","_targetpos","_targettext","_i","_prov"];
	_npc = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_flankdir = _this select 3;
	_dist = [getposATL _npc,_targetpos] call UPSMON_distancePosSqr; 

	_flankAngle = 50;
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.7)+1.1)*UPSMON_safedist;
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if ((_flankdist) >= _dist) then {_dist*1.65} else {_flankdist};

	//Calculamos posición de avance frontal			
	_frontPos = [_targetPos,_dir2, _flankdist] call UPSMON_GetPos2D;	
	

	//Adaptamos el ángulo de flanqueo a la distancia		
	_newflankAngle = ((random(_flankAngle)+1) * 2 * (_flankdist / UPSMON_safedist )) + (_flankAngle/1.4) ;
	if (_newflankAngle > _flankAngle) then {_newflankAngle = _flankAngle};			
			
	//Calculamos posición de flanqueo 1 45º
	_dirf1 = (_dir2+_newflankAngle) mod 360;			
	_flankPos = [_targetPos,_dirf1, _flankdist] call UPSMON_GetPos2D;
			
	//Calculamos posición de flanqueo 2 -45º			
	_dirf2 = (_dir2-_newflankAngle+360) mod 360;		
	_flankPos2 = [_targetPos,_dirf2, _flankdist] call UPSMON_GetPos2D;
			
						
						
	//Decidir por el mejor punto de flanqueo
	//Contamos las posiciones de destino de otros grupos más alejadas
	_fldest = 0;
	_fldest2 = 0;
	_fldestfront = 0;
	_i = 0;
	_prov = 50;
			
	{			
		if (!isnil "x") then 
		{
			if ( _i != _grpid &&  { format ["%1", _x] != "[0,0]" } ) then 
			{
				_dist1 = [_x,_flankPos] call UPSMON_distancePosSqr;
				_dist2 = [_x,_flankPos2] call UPSMON_distancePosSqr;	
				_dist3 = [_x,_frontPos] call UPSMON_distancePosSqr;	
				if (_dist1 <= _flankdist/1.5 || { _dist2 <= _flankdist/1.5 } || { _dist3 <= _flankdist/1.5 } ) then 
				{					
					if (_dist1 < _dist2 && { _dist1 < _dist3 } ) then {_fldest = _fldest + 1;};
					if (_dist2 < _dist1 && { _dist2 < _dist3 } ) then {_fldest2 = _fldest2 + 1;};
					if (_dist3 < _dist1 && { _dist3 < _dist2 } ) then {_fldestfront = _fldestfront + 1;};						
				};
			};
		}; 
		_i = _i + 1;
			
		//sleep 0.01;
	} foreach UPSMON_targetsPos;	
			
			
	//We have the positions of other groups more distant
	_i = 0;
	{
		if (!isnil "_x") then 
		{
			if (_i != _grpid && !isnull(_x)) then 
			{
				_dist1 = [getpos(_x),_flankPos] call UPSMON_distancePosSqr;
				_dist2 = [getpos(_x),_flankPos2] call UPSMON_distancePosSqr;	
				_dist3 = [getpos(_x),_frontPos] call UPSMON_distancePosSqr;
				if (_dist1 <= _flankdist/1.5 || { _dist2 <= _flankdist/1.5 } || { _dist3 <= _flankdist/1.5 } ) then 
				{						
					if (_dist1 < _dist2 && { _dist1 < _dist3 } ) then {_fldest = _fldest + 1;};
					if (_dist2 < _dist1 && { _dist2 < _dist3 } ) then {_fldest2 = _fldest2 + 1;};
					if (_dist3 < _dist1 && { _dist3 < _dist2 } ) then {_fldestfront = _fldestfront + 1;};	
				};
			};
			_i = _i + 1;
		};
			//sleep 0.01;
	} foreach UPSMON_NPCs; 
						
			
			
	//La preferencia es la elección inicial de dirección
	switch (_flankdir) do 
	{
		case 1: 
				{_prov = 125};
		case 2: 
				{_prov = -25};
		default
				{_prov = 50};
	};						
			
			
	//Si es positivo significa que hay más destinos existentes lejanos a la posicion de flanqueo1, tomamos primariamente este
	if (_fldest<_fldest2) then {_prov = _prov + 50;};
	if (_fldest2<_fldest) then {_prov = _prov - 50;};		

	//Si la provablilidad es negativa indica que tomará el flank2 por lo tanto la provabilidad de coger 1 es 0
	if (_prov<0) then {_prov = 0;};
			
				
	//Evaluamos la dirección en base a la provablilidad calculada
	if ((random 100) <= _prov) then 
	{
		_flankdir =1; 
		_targettext = "_flankPos";
	} else {
		_flankdir =2;
		_flankPos = _flankPos2; 
		_targettext = "_flankPos2";
	};			
			
					
	//Posición de ataque por defecto el flanco
	_targetPos = _flankPos;
	_targettext = "_flankPos";
			
		
	if (_fldestfront < _fldest  && _fldestfront < _fldest2) then 
	{
		_targetPos = _frontPos;
		_targettext = "_frontPos"; 
	};

	_array = [] + [_targetPos];
	_array
};


UPSMON_SrchRetreatPos = {

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
	
	_exp = "(50 * trees) + (2 * forest) + (50 * houses) - (1000 * Sea)";
	If (("LandVehicle" countType [vehicle (_npc)]>0) || ("Air" countType [vehicle (_npc)]>0)) then {_exp = "(50 * trees) - (100 * houses) - (100 * forest) - (100 * hills) - (1000 * Sea)";};
	If (_inboat || _isdiver) then {_exp = "(1000 * Sea)";_water = 1;};
	
	while {count _avoidPos == 0 && _i < 50} do 
	{
		_i = _i +1;
		// avoidance position (right or left of unit)
		_avoidPostemp = [_currpos,[_dist,_dist + 100],_direction,_water,[0,100],1] call UPSMON_pos;	

		_bestplaces = selectBestPlaces [_avoidPostemp,5,_exp,1,1];
		If (count (_bestplaces select 0) > 0) then {_avoidPos =_avoidPostemp};
	};
	
	If (count _avoidPos == 0) then {_avoidPos = _currpos};
	_avoidPos;
};