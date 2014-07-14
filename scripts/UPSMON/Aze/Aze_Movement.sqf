
Aze_FlankPosition = {
	private ["_npc","_dir2","_targetPos","_flankdir","_loop","_flankdist","_exp","_frontPos","_bestplaces","_roadcheckpos","_newflankAngle","_dirf1","_dirf2","_flankPos","_flankPos2","_fldest","_fldest2","_fldestfront","_dist1","_dist2","_dist3","_targetpos","_targettext","_i","_prov"];
	_npc = _this select 0;
	_dir2 = _this select 1;
	_targetPos = _this select 2;
	_flankdir = _this select 3;

	_loop = true;
	_los_ok = false;
	_pos = [0,0];
	//Establecemos una distancia de flanqueo	
	_flankdist = ((random 0.5)+0.7)*KRON_UPS_safedist;
						
	//La distancia de flanqueo no puede ser superior a la distancia del objetivo o nos pordría pillar por la espalda
	_flankdist = if ((_flankdist*1.40) >= _dist) then {_dist*.65} else {_flankdist};
			
	_exp = "(1 + houses) * (1.5 + trees)* (1 - Sea)";
	if ("Air" countType [vehicle (_npc)]>0) then {_flankdist = _flankdist / 2;};
	If (("LandVehicle" countType [vehicle (_npc)]>0) || ("Air" countType [vehicle (_npc)]>0)) then {_exp = "(0.2 - trees) * (0.5 - houses) * (1 - forest) * (1 - hills) * (1 -Sea)";};


	//Calculamos posición de avance frontal			
	_frontPos = [_targetPos,_dir2, _flankdist] call MON_GetPos2D;	
			
	_bestplaces = selectBestPlaces [_frontPos,_flankdist/2,_exp,20,3];
	
	If ((count _bestplaces) > 0) then 
	{
	
		_frontPos = (_bestplaces select 0) select 0;
		_orig = "RoadCone_F" createVehicleLocal _targetPos;
		hideObject _orig;
		_loglos = "logic" createVehicleLocal [0,0,0];
		
		while {_loop} do 
		{
			{
				_pos = _x select 0;
				_dest = "RoadCone_F" createVehicleLocal _pos;
				hideObject _dest;
				_los_ok = [_loglos,_orig,_dest,20, 0.5] call mando_check_los;

				sleep 0.5;
				deletevehicle _orig;
				if (_los_ok) exitwith {_loop = false;_frontPos = _pos};
			} foreach _bestplaces;
			_loop = false;
		};
		
		deletevehicle _loglos;
		deletevehicle _orig;
		
	} else 
	{
		If (vehicle _npc iskindof "LandVehicle") then 
		{
			_roadcheckpos = _frontPos nearRoads 50;
			If (count _roadcheckpos > 0) then {_frontPos = _roadcheckpos select 0;};
		};
	};

	//Adaptamos el ángulo de flanqueo a la distancia		
	_newflankAngle = ((random(KRON_UPS_flankAngle)+1) * 2 * (_flankdist / KRON_UPS_safedist )) + (KRON_UPS_flankAngle/1.4) ;
	if (_newflankAngle > KRON_UPS_flankAngle) then {_newflankAngle = KRON_UPS_flankAngle};			
			
	//Calculamos posición de flanqueo 1 45º
	_dirf1 = (_dir2+_newflankAngle) mod 360;			
	_flankPos = [_targetPos,_dirf1, _flankdist] call MON_GetPos2D;					
			
	_bestplaces = selectBestPlaces [_flankPos,_flankdist/2,_exp,20,1];
	If ((count _bestplaces) > 0) then 
	{
		_flankPos = (_bestplaces select 0) select 0;
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
	_flankPos2 = [_targetPos,_dirf2, _flankdist] call MON_GetPos2D;	
			
	_bestplaces = selectBestPlaces [_flankPos2,_flankdist/2,_exp,20,5];
	If ((count _bestplaces) > 0) then 
	{
		_flankPos2 = (_bestplaces select 0) select 0;
	} else 
	{
		If (vehicle _npc iskindof "LandVehicle") then 
		{
			_roadcheckpos = _flankPos2 nearRoads 50;
			If (count _roadcheckpos > 0) then {_flankPos2 = _roadcheckpos select 0;};
		};
	};
			
	if (KRON_UPS_Debug>0) then 
	{
		"flank1" setMarkerPos _flankPos; 
		"flank2" setMarkerPos _flankPos2; 
		"target" setMarkerPos _attackPos;	
	};
						
						
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
				_dist1 = [_x,_flankPos] call KRON_distancePosSqr;
				_dist2 = [_x,_flankPos2] call KRON_distancePosSqr;	
				_dist3 = [_x,_frontPos] call KRON_distancePosSqr;	
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
	} foreach KRON_targetsPos;	
			
			
	//We have the positions of other groups more distant
	_i = 0;
	{
		if (!isnil "_x") then 
		{
			if (_i != _grpid && !isnull(_x)) then 
			{
				_dist1 = [getpos(_x),_flankPos] call KRON_distancePosSqr;
				_dist2 = [getpos(_x),_flankPos2] call KRON_distancePosSqr;	
				_dist3 = [getpos(_x),_frontPos] call KRON_distancePosSqr;
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
	} foreach KRON_NPCs;					
						
			
			
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
		_flankPos = _flankPos; _targettext = "_flankPos";
	} else {
		_flankdir =2;
		_flankPos = _flankPos2; _targettext = "_flankPos2";
	};			
			
					
	//Posición de ataque por defecto el flanco
	_targetPos = _flankPos;
	_targettext = "_flankPos";
			
			
	if ((surfaceIsWater _flankPos && { !(_isplane || _isboat || _isDiver) } ) ) then 
	{
		_targetPos = _attackPos;
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////// PATROL MODULE /////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


Aze_Patrol = {
	private ["_npc","_rlastPos","_rstuckControl","_jumpers","_areamarker","_centerpos","_centerX","_centerY","_areasize","_rangeX","_rangeY","_targetPos","_targettext","_tries","_loop2","_mindist","_incar","_inheli","_inboat","_isdiver","_targetPosTemp","_cosdir","_sindir"];
	
	_npc = _this select 0;
	_rlastPos = _this select 1;
	_rstuckControl = _this select 2;
	_areamarker = _this select 3;
	_mindist = _this select 4;
	_onroad = _this select 5;
	
	_currPos = getpos _npc;
	
	_incar = "LandVehicle" countType [vehicle (_npc)]>0;
	_inheli = "Air" countType [vehicle (_npc)]>0;
	_inboat = "Ship" countType [vehicle (_npc)]>0;
	_isdiver = ["diver", (typeOf (leader _npc))] call BIS_fnc_inString;
		
	//rStuckControl !R					
	if (_rlastPos select 0 == _currPos select 0 
	&& { _rlastPos select 1 == _currPos select 1 } ) then 
	{
		if (KRON_UPS_Debug>0) then {player sidechat format["%1 !RstuckControl try to move",_grpidx]};
						
		if (vehicle _npc != _npc) then 
		{
			_rstuckControl = _rstuckControl + 1;
							
			if (_rstuckControl > 1) then 
			{
				_jumpers = crew (vehicle _npc);
				{
					_x spawn MON_doGetOut;	
					sleep 0.5;
				} forEach _jumpers;
			} 
			else 
			{
				nul = [vehicle _npc, 25] spawn MON_domove;
			}
		}
		else 
		{
			nul = [_npc, 25] spawn MON_domove;
		};
	}
	else 
	{
		_rstuckControl = 0;
	};					
					
	
						
	// re-read marker position/size
	_centerpos = getMarkerPos _areamarker; _centerX = abs(_centerpos select 0); _centerY = abs(_centerpos select 1);
	_centerpos = [_centerX,_centerY];
	_areasize = getMarkerSize _areamarker; _rangeX = _areasize select 0; _rangeY = _areasize select 1;
	_areadir = (markerDir _areamarker) * -1;
	
	// store some trig calculations
	_cosdir=cos(_areadir);
	_sindir=sin(_areadir);
						
	// find a new target that's not too close to the current position
	_targetPos=_currPos; _targettext ="Patrol";
	_tries=0;
						
	while {((([_currPos,_targetPos] call KRON_distancePosSqr) < _mindist)) && (_tries<50)} do 
	{
		_tries=_tries+1;
		// generate new target position
		_targetPos = [_centerX,_centerY,_rangeX,_rangeY,_cosdir,_sindir,_areadir] call KRON_randomPos;

		_loop2=FALSE;
		// boat or plane
		// if (KRON_UPS_Debug>0) then {player sidechat format["%1, type: %2",_npc, typeOf _npc]}; sleep 4;
		// if (KRON_UPS_Debug>0) then {player sidechat format["%1 isplane",_inheli]}; sleep 4;
				
		if ((vehicle _npc iskindof "AIR") || _inboat || _isDiver) then 
		{
			// boat
			if (_inboat) then 
			{
				_tries2=0; 
						
				while {(!_loop2) && (_tries2 <50)} do 
				{
					_tries2=_tries2+1;
					_targetPosTemp = [_centerX,_centerY,_rangeX,_rangeY,_cosdir,_sindir,_areadir] call KRON_randomPos;
									
					if (surfaceIsWater _targetPosTemp) then 
					{
						_targetPos = _targetPosTemp; 
						_loop2 = TRUE;
						// if (KRON_UPS_Debug>0) then {player sidechat format["%1 Boat just got new targetPos",_grpidx]};
					};
					sleep 0.05;
				};								
								
				// plane or diver
			} 
			else 
			{
				_targetPos = [_centerX,_centerY,_rangeX,_rangeY,_cosdir,_sindir,_areadir] call KRON_randomPos;
				// if (KRON_UPS_Debug>0) then {player sidechat format["%1 Plane just got new targetPos",_grpidx]};										
			};
							
			// man or car							
		} 							
		else 
		{ 
			// "_onroad"	
			if (_onroad || (_incar)) then 
			{
				_tries2=0; 
						
				while {(!_loop2) && (_tries2 <100)} do 
				{
					_tries2=_tries2+1;
										
					_targetPosTemp = [_centerX,_centerY,_rangeX,_rangeY,_cosdir,_sindir,_areadir] call KRON_randomPos;
					_roads = (_targetPosTemp nearRoads 50); 
									
					if ((count _roads) > 0) then 
					{
						_targetPosTemp = getpos (_roads select 0);
						_targetPos = _targetPosTemp;
						_loop2 = TRUE;
						// if (KRON_UPS_Debug>0) then {player sidechat format["%1 Onroad just got new targetPos",_grpidx]};	
					};	
							sleep 0.05;	
				};	
				
			}
			else 
			{		
				// any place on ground
				_tries2=0; 
						
				while {(!_loop2) && (_tries2 <100)} do 
				{
					_tries2=_tries2+1;
					_targetPosTemp = [_centerX,_centerY,_rangeX,_rangeY,_cosdir,_sindir,_areadir] call KRON_randomPos;
									
					if (!surfaceIsWater _targetPosTemp) then 
					{
						_targetPos = _targetPosTemp; 
						_loop2 = TRUE;																			
						if (KRON_UPS_Debug>0) then {diag_log format["UPSMON: %1 Man just got new TP %2, %3",_grpidx,_targetPos,_tries2]};											
					};
					sleep 0.05;	
				};								
			};
		};
	};						

	_result = _targetPos;
	_result

};

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////// END PATROL MODULE /////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Aze_Assault = {

	_npc = _this select 0;
	_targetPos = _this select 1;
	
	_cntobjs1 = floor ((count units _npc) /2);
	
	// Create support team
	If (_cntobjs1 >=3) then 
	{
		_AttackTeam = [];
		{							
			if (_x iskindof "Man"  && unitReady _x && canmove _x && alive _x && vehicle _x == _x && _i < _cntobjs1 && _x != _npc && !((primaryWeapon _x ) in KRON_UPS_MG_WEAPONS)) then
			{
				_AttackTeam = _AttackTeam + [_x];
				_i = _i + 1;						
			};
		} foreach  units _npc;	
							
		_SupportTeam = (units _npc) - [_attacksquad];
		
		{
			Dostop _x; 
			_x Dowatch ObjNull;
			_x Dowatch _bldtarget; 
			_x suppressfor 15;
		} foreach _SupportTeam;
		
		(group _npc) enableAttack true;
	};
};