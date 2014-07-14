///////////////////////////////////////////////////////////////// WITHDRAWAL MODULE ////////////////////////////////////////////////////

Aze_WITHDRAW = {
		private ["_npc","_target","_AttackPos","_dir1","_dir2","_targetPos","_artillerysideunits","_RadioRange","_array"]; 	
		_npc = _this select 0;
		_target = _this select 1;
		_AttackPos = _this select 2;
		_RadioRange = _this select 3;
		
		// angle from unit to target
		_dir1 = [getpos _npc,_AttackPos] call KRON_getDirPos;
		_dir2 = (_dir1+180) mod 360;
		
		_targetPos = [_npc,_dir2] call Aze_RetreatPosition;
		
					
		if (KRON_UPS_Debug>=1) then 
		{
			"avoid" setmarkerpos _targetPos;							
		};	
					
		_artillerysideunits = call (compile format ["KRON_UPS_ARTILLERY_%1_UNITS",_side]);
		_artillerysideFire = call (compile format ["KRON_UPS_ARTILLERY_%1_FIRE",_side]);
		
		If (_artillerysideFire
		&& _RadioRange > 0 
		&& count _artillerysideunits > 0) then 
		{
			_arti = [_artillerysideunits,"WP",_RadioRange,_npc] call Aze_selectartillery;
					
			If !(IsNull _arti) then 
			{
				[_arti,"WP",_target,_npc] spawn Aze_artilleryTarget;};
				if (KRON_UPS_Debug>0) then {player sidechat format ["Arti: %1",_arti];};
			};
				
			// New Code:
			If (_npc distance _target >= 200 && morale _npc < -1.2) then 
			{
				{
					{_x setCombatMode "BLUE";} foreach units _npc;
					_x setbehaviour "CARELESS"; 
					_x allowfleeing 1;
				} foreach units group _npc;
			} 
			else 
			{
				{
					{_x setCombatMode "GREEN";} foreach units _npc;
					_x setbehaviour "AWARE"; 
					_x allowfleeing 0;
				} foreach units group _npc;
			};
			// end new code
					
			if (KRON_UPS_Debug>0) then {player sidechat format["%1 All Retreat!!!",_grpidx]};

			_targetPos;
};

Aze_RetreatPosition = {

	private ["_npc","_dir2","_exp","_avoidPos","_bestplaces","_roadcheckpos"];
	_npc = _this select 0;
	_dir2 = _this select 1;

	_exp = "(1 + houses) * (1.5 + trees)* (1 - Sea)";
	If (("LandVehicle" countType [vehicle (_npc)]>0) || ("Air" countType [vehicle (_npc)]>0)) then {_exp = "(0.2 - trees) * (0.5 - houses) * (1 - forest) * (1 - hills) * (1 -Sea)";};	
			
	// avoidance position (right or left of unit)
	_avoidPos = [getpos _npc,_dir2, 150] call MON_GetPos2D;	

	_bestplaces = selectBestPlaces [_avoidPos,30,_exp,20,5];
	If ((count _bestplaces) > 0) then 
	{
		_avoidPos = (_bestplaces select 0) select 0;
	} else 
	{
		If (vehicle _npc iskindof "LandVehicle") then 
		{
			_roadcheckpos = _avoidPos nearRoads 50;
			If (count _roadcheckpos > 0) then {_avoidPos = _roadcheckpos select 0;};
		};
	};
	
	_avoidPos;
};