Aze_Askrenf = 
{
private ["_npc","_target","_radiorange","_renf","_fixedtargetpos"];

	_npc = _this select 0;
	_target = _this select 1;
	_radiorange = _this select 2;
	_side = (_npc getvariable "UPS_Grpinfos") select 0;
	_fixedtargetpos = getpos _npc;
	_renf = false;
	_renfgroup = ObjNull;
	_KRON_Renf = [];
	
		switch (_side) do 
	{
		case West: 
		{
			_KRON_Renf = KRON_UPS_REINFORCEMENT_WEST_UNITS;	
		};
		case EAST: 
		{
			_KRON_Renf = KRON_UPS_REINFORCEMENT_EAST_UNITS;
		};
		case GUER: 
		{
			_KRON_Renf = KRON_UPS_REINFORCEMENT_GUER_UNITS;		
		};
	
	};
	
	if (KRON_UPS_Debug>0) then {diag_log format["%1 ask reinforcement position %2 KRON_Renf: %3",_npc,_fixedtargetpos,_KRON_Renf]};
	If (count _KRON_Renf > 0 && !(isNull _npc) && alive _npc) then
	{
		_ArrayGrpRenf = [_KRON_Renf, [], { _npc distance _x }, "ASCEND"] call BIS_fnc_sortBy;
		{
			_alliednpc = _x;
			If (alive _alliednpc && _npc distance _alliednpc <= _radiorange && (_alliednpc getvariable "UPS_REINFORCEMENT") == "REINFORCEMENT") exitwith 
			{
				{
					_unit = _x; 
					_unit setvariable ["UPS_PosToRenf",[_fixedtargetpos select 0,_fixedtargetpos select 1]];
					_unit reveal [_target,1.5];
				} foreach units (group _alliednpc); 
				_renf = true;
				_renfgroup = _alliednpc;
				if (KRON_UPS_Debug>0 && _renf) then {diag_log format ["%1 sent in Reinforcement",_alliednpc];};
			};

		} foreach _KRON_Renf;
		
		If (_renf && !(isNull _renfgroup)) then
		{
		switch (_side) do 
		{
			case West: 
			{
				KRON_UPS_REINFORCEMENT_WEST_UNITS = KRON_UPS_REINFORCEMENT_WEST_UNITS - [_renfgroup];	
			};
			case EAST: 
			{
				KRON_UPS_REINFORCEMENT_EAST_UNITS = KRON_UPS_REINFORCEMENT_EAST_UNITS - [_renfgroup];
			};
			case GUER: 
			{
				KRON_UPS_REINFORCEMENT_GUER_UNITS = KRON_UPS_REINFORCEMENT_GUER_UNITS - [_renfgroup];		
			};
	
		};
		};
	};
	
	_renf
};
