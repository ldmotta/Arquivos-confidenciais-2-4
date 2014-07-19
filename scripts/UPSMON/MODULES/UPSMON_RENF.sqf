UPSMON_Askrenf = 
{
private ["_grp","_target","_radiorange","_renf","_fixedtargetpos","_side","_dir1","_dir2","_renfgroup","_KRON_Renf","_ArrayGrpRenf"];

	_npcpos = _this select 0;
	_targetpos = _this select 1;
	_radiorange = _this select 2;
	_side = _this select 3;
	_Enemies = _this select 4;
	_grp = _this select 7;
	
	_fixedtargetpos = [0,0];
	_renf = false;
	_renfgroup = ObjNull;
	_UPSMON_Renf = [];
	
		switch (_side) do 
	{
		case West: 
		{
			_UPSMON_Renf = UPSMON_REINFORCEMENT_WEST_UNITS - [_grp];	
		};
		case EAST: 
		{
			_UPSMON_Renf = UPSMON_REINFORCEMENT_EAST_UNITS - [_grp];
		};
		case resistance: 
		{
			_UPSMON_Renf = UPSMON_REINFORCEMENT_GUER_UNITS - [_grp];		
		};
	
	};
	
	if (UPSMON_Debug>0) then {diag_log format["%1 ask reinforcement position %2 KRON_Renf: %3",_npcpos,_fixedtargetpos,_UPSMON_Renf]};
	If (count _UPSMON_Renf > 0) then
	{
		_ArrayGrpRenf = [_UPSMON_Renf, [], {round ([_npcpos,getposATL (leader _x)] call UPSMON_distancePosSqr)}, "ASCEND"] call BIS_fnc_sortBy;
		
		{
			if (({alive _x} count units _x) > 0) then
			{
				_alliednpc = _x;
				If (alive (leader _alliednpc)) exitwith 
				{
					If (round ([_npcpos,getposATL (leader _alliednpc)] call UPSMON_distancePosSqr) <= _radiorange) then
					{
						If ((_alliednpc getvariable "UPSMON_REINFORCEMENT") == "REINFORCEMENT") then
						{
							_alliednpc setvariable ["UPSMON_PosToRenf",[_targetpos select 0,_targetpos select 1]];
							{
								_unit = _x;
								{_enemy = _x select 0; if (!isNull _enemy && alive _enemy) then {_unit reveal [_enemy,1.9];};} foreach _Enemies;
							} foreach units _alliednpc; 
							_renf = true;
							_renfgroup = _alliednpc;
							if (UPSMON_Debug>0 && _renf) then {diag_log format ["%1 sent in Reinforcement",_alliednpc];};
						};
					};
				};
			};
		} foreach _ArrayGrpRenf;
		
		
		If (_renf && !(isNull _renfgroup)) then
		{
		switch (_side) do 
		{
			case West: 
			{
				UPSMON_REINFORCEMENT_WEST_UNITS = UPSMON_REINFORCEMENT_WEST_UNITS - [_renfgroup];	
			};
			case EAST: 
			{
				UPSMON_REINFORCEMENT_EAST_UNITS = UPSMON_REINFORCEMENT_EAST_UNITS - [_renfgroup];
			};
			case resistance: 
			{
				UPSMON_REINFORCEMENT_GUER_UNITS = UPSMON_REINFORCEMENT_GUER_UNITS - [_renfgroup];		
			};
	
		};
		};
	};
	
	_renf
};