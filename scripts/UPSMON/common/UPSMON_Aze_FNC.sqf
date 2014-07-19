UPSMON_arrayShufflePlus = {
	// func from KillzoneKid
    private ["_cnt","_el1","_rnd","_indx","_el2"];
	_cnt = count _this - 1;
    _el1 = _this select _cnt;
    _this resize _cnt;
    _rnd = random diag_tickTime * _cnt;
    for "_i" from 0 to _cnt do {
        _indx = floor random _rnd % _cnt;
        _el2 = _this select _indx;
        _this set [_indx, _el1];
        _el1 = _el2;
    };
    _this set [_cnt, _el1];
    _this
};


UPSMON_getminesclass =
{
	private ["_minesclassname","_minetype1","_minetype2","_cfgvehicles","_cfgvehicle","_inherit","_vehicle"];
	
	_minesclassname = [];
	_minetype1 = [];
	_minetype2 = [];
	_minetype3 = [];
	
	_APMines = [];
	_ATMines = [];
	_underwatermines = [];
	
	
	{
		_mineTriggerType = tolower gettext (_x >> "mineTriggerType");
		if (_mineTriggerType in ["radius","wire"]) then 
		{
			_mineMagnetic = getnumber (_x >> "mineMagnetic");
			_array = if (_mineMagnetic > 0) then {_ATMines} else {_APMines};
			_underwatermine=[tolower configname _x,"underwater"] call UPSMON_StrInStr;
			if (_underwatermine) then {_array=_underwatermines;};
			_array set [count _array,tolower configname _x];
		};
	} foreach ((configfile >> "CfgMineTriggers") call bis_fnc_returnchildren);

	{
		_cfgvehicle = _x;
		_inherit = inheritsFrom _cfgvehicle;
		If ((configName _inherit) == "MineBase") then
		{
			_vehicle = configName _cfgvehicle;
			_ammo = tolower gettext (_cfgvehicle >> "ammo");
			_trigger = tolower gettext (configfile >> "cfgAmmo" >> _ammo >> "mineTrigger");
			if (_trigger in _ATMines) then {_minetype1 set [count _minetype1,_vehicle];}; 
			if (_trigger in _APMines) then {_minetype2 set [count _minetype2,_vehicle];}; 
			if (_trigger in _underwatermines) then {_minetype3 set [count _minetype3,_vehicle];}; 
		};	
	} foreach ((configfile >> "CfgVehicles") call bis_fnc_returnchildren);

	_minesclassname = [_minetype1,_minetype2,_minetype3];
	_minesclassname
};

UPSMON_Haslos = 
{
	private ["_unit", "_target", "_range", "_fov", "_inView", "_inSight", "_inRange", "_knowsAbout"];

	_unit = [_this,0] call BIS_fnc_param; 
	_target = [_this,1] call BIS_fnc_param; 
	_range = [_this,2,100,[0]] call BIS_fnc_param; 
	_fov = [_this,3,130,[0]] call BIS_fnc_param; 

	_knowsAbout = false;
	_inRange = (_unit distance _target) < _range; 
	if (_inRange) then 
	{
		_inView = [position _unit, getdir _unit, _fov, position _target] call BIS_fnc_inAngleSector; 
		_inSight = count (lineIntersectsWith [eyePos _unit, eyepos _target, _unit, _target]) == 0; 
		_knowsAbout = _inView && _inSight;
	};
	
	_knowsAbout;  
};

UPSMON_LOS =
{
	private ["_poso","_posd","_visionBlock","_los_ok"];
	
	_poso = _this select 0;
	_posd = _this select 1;

	_poso set [2, (_poso select 2)+1];
	_posd set [2, (_posd select 2)+1];
	
	_los_ok = false;
	
	_visionBlock = terrainIntersect [_poso, _posd];
	If (!_visionBlock) then
	{
		_visionBlock = lineIntersects [[_poso select 0,_poso select 1,getTerrainHeightASL [_poso select 0,_poso select 1] + 0.25],[_posd select 0,_posd select 1,getTerrainHeightASL [_posd select 0,_posd select 1] + 0.25]];
		If (!_visionBlock) then
		{
			_los_ok = true;
		};
	};
		
	_los_ok;
};

UPSMON_DocreateWP = {
	private ["_grp","_targetpos","_wptype","_wpformation","_speedmode","_wp1","_radius","_CombatMode"];
	
	_grp = _this select 0;
	_targetpos = _this select 1;
	_wptype = _this select 2;
	_wpformation = _this select 3;
	_speedmode = _this select 4;
	_Behaviour = _this select 5;
	_CombatMode = _this select 6;
	_radius = _this select 7;
	
	while {(count (waypoints _grp)) > 0} do
	{
		deleteWaypoint ((waypoints _grp) select 0);
	};
			
	_wp1 = _grp addWaypoint [_targetPos,1];
	_wp1  setWaypointPosition [_targetPos,1];
	_wp1  setWaypointType _wptype;
	_wp1  setWaypointFormation _wpformation;		
	_wp1  setWaypointSpeed _speedmode;
	_wp1  setwaypointbehaviour _Behaviour;
	_wp1  setwaypointCombatMode _CombatMode;
	_wp1  setWaypointLoiterRadius _radius;
	
};
UPSMON_GothitParam = 
{
	private ["_npc","_gothit"];
	
	_npc = _this select 0;
	_gothit = false;
	
	If (isNil "tpwcas_running") then 
	{
		if (group _npc in UPSMON_GOTHIT_ARRAY || group _npc in UPSMON_GOTKILL_ARRAY) then
		{
			_gothit = true;
		};
	}
	else
	{
		_Supstate = [_npc] call UPSMON_supstatestatus;
		if (group _npc in UPSMON_GOTHIT_ARRAY || group _npc in UPSMON_GOTKILL_ARRAY || _Supstate >= 2) then
		{
			_gothit = true;
		};
	};
	
	_gothit
};

UPSMON_ValueOrd = 
{
	// From Rydgier
	private ["_array","_final","_highest","_ix"];

	_array = _this select 0;

	_final = [];

	while {((count _array) > 0)} do
		{
		_highest = [_array,3] call UPSMON_FindHighestWithIndex;
		_ix = _highest select 1;
		_highest = _highest select 0;
		
		_final set [(count _final),_highest];

		_array set [_ix,"Delete"];
		_array = _array - ["Delete"]
		};

	_final
};

UPSMON_FindHighestWithIndex = 
{
	// From Rydgier
	private ["_array","_ix","_highest","_valMax","_valAct","_index","_clIndex"];

	_array = _this select 0;
	_ix = _this select 1;

	_highest = [];

	if ((count _array) > 0) then 
		{
		_highest = _array select 0;
		_index = 0;
		_clIndex = 0;
		_valMax = _highest select _ix;

			{
			_valAct = _x select _ix;

			if (_valAct > _valMax) then
				{
				_highest = _x;
				_valMax = _valAct;
				_clIndex = _index
				};

			_index = _index + 1
			}
		foreach _array
		};

	[_highest,_clIndex]
};

UPSMON_TerraCognita = 
{
	// From Rydgier
	private ["_position","_posX","_posY","_radius","_precision","_sourcesCount","_urban","_forest","_hills","_flat","_sea","_valS","_value","_val0","_samples","_sGr","_hprev","_hcurr","_samplePos","_i","_rds"];	

	_position = _this select 0;
	_samples = _this select 1;
	_rds = 100;
	if ((count _this) > 2) then {_rds = _this select 2};

	if !((typeName _position) == "ARRAY") then {_position = getPosATL _position};

	_posX = _position select 0;
	_posY = _position select 1;

	_radius = 5;
	_precision = 1;
	_sourcesCount = 1;

	_urban = 0;
	_forest = 0;
	_hills = 0;
	_flat = 0;
	_sea = 0;

	_sGr = 0;
	_hprev = getTerrainHeightASL [_posX,_posY];

	for "_i" from 1 to 10 do
	{
		_samplePos = [_posX + ((random (_rds * 2)) - _rds),_posY + ((random (_rds * 2)) - _rds)];
		_hcurr = getTerrainHeightASL _samplePos;
		_sGr = _sGr + abs (_hcurr - _hprev)
	};

	_sGr = _sGr/10;

	{
		_valS = 0;

		for "_i" from 1 to _samples do
		{
			_position = [_posX + (random (_rds/5)) - (_rds/10),_posY + (random (_rds/5)) - (_rds/10)];


			_value = selectBestPlaces [_position,_radius,_x,_precision,_sourcesCount];

			_val0 = _value select 0;
			_val0 = _val0 select 1;

			_valS = _valS + _val0;
		};

		_valS = _valS/_samples;

		switch (_x) do
		{
			case ("Houses") : {_urban = _urban + _valS};
			case ("Trees") : {_forest = _forest + (_valS/3)};
			case ("Forest") : {_forest = _forest + _valS};
			case ("Hills") : {_hills = _hills + _valS};
			case ("Meadow") : {_flat = _flat + _valS};
			case ("Sea") : {_sea = _sea + _valS};
		};
	} foreach ["Houses","Trees","Forest","Hills","Meadow","Sea"];

	[_urban,_forest,_hills,_flat,_sea,_sGr]
};

UPSMON_supstatestatus = {
	private ["_npc","_azesupstate","_tpwcas_running"];
	
	_tpwcas_running = if (!isNil "tpwcas_running") then {true} else {false};

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
UPSMON_checksizetargetgrp = {
	private ["_mennear","_result","_pos","_radius"];

	_pos = _this select 0;
	_radius = _this select 1;
	_side = _this select 2;
	
	_mennear = _pos nearentities [["CAManBase"],_radius];
	_enemySides = _side call BIS_fnc_enemySides;
	_result = false;
	_allied = [];
	_eny = [];

	{
		If ((side _x in _enemySides) && _npc knowsabout _x >= UPSMON_knowsAboutEnemy) then {_eny = _eny + [_x];}
	} foreach _mennear;
	

	_result = [_eny];
	_result
};
UPSMON_checkallied = {
private ["_npc","_mennear","_result","_radius"];

	_npc = _this select 0;
	_radius = _this select 1;
	_side = side _npc;
	
	_mennear = _npc nearTargets 180;
	_result = false;
	_allied = [];
	_eny = [];
	_enemySides = _npc call BIS_fnc_enemySides;
	
	{
		_unit = _x select 4;
		_unitside = _x select 2;
		If ((alive _unit) && (_unitside == _side) && !(_unit in (units _npc)) && !(captive _unit)) then {_allied = _allied + [_x];};
		If ((alive _unit) && (_unitside in _enemySides) && _npc knowsabout _unit >= UPSMON_knowsAboutEnemy) then {_eny = _eny + [_x];}
	} foreach _mennear;
	

	_result = [_allied,_eny];
	_result
};

UPSMON_getequipment = 
{
	private ["_unit","_maguniformunit","_magbackunit","_magvestunit","_uniform","_headgear","_vest","_bag","_classbag","_itemsunit","_weaponsunit","_equipmentarray"];
	_unit = _this;
	_maguniformunit = [];
	_magbackunit = [];
	_magvestunit = [];


	_uniform = uniform _unit;
	If (_uniform != "") then {_maguniformunit = getMagazineCargo uniformContainer _unit;};

	_headgear = headgear _unit;

	_vest = vest _unit;
	If (_vest != "") then {_magvestunit = getMagazineCargo vestContainer _unit;};

	_bag = unitBackpack _unit;
	_classbag = typeOf _bag;
	If (_classbag != "") then {_magbackunit = getMagazineCargo backpackContainer _unit;};


	_itemsunit = items _unit;
	_assigneditems = assignedItems _unit;
	_weaponsunit = weaponsItems _unit;


	_allmag = [] + [_maguniformunit] + [_magvestunit] + [_magbackunit];
	_equipmentarray = [_uniform,_headgear,_vest,_classbag,_itemsunit,_assigneditems,_allmag,_weaponsunit];
	_equipmentarray
};

UPSMON_addequipment = {
	private ["_unit","_clonearray","_uniform","_headgear","_vest","_classbag","_itemsunit","_assigneditems","_allmag","_weaponsunit","_index","_array1","_array2","_magazineName","_count","_weapon","_item1","_item2","_item3"];
	_unit = _this select 0;

	_clonearray = _this select 1;
	_uniform = _clonearray select 0;
	_headgear = _clonearray select 1;
	_vest = _clonearray select 2;
	_classbag = _clonearray select 3;
	_itemsunit = _clonearray select 4;
	_assigneditems = _clonearray select 5;
	_allmag = _clonearray select 6;
	_weaponsunit = _clonearray select 7;


	removeAllAssignedItems _unit;
	removeHeadgear _unit;
	removeAllItemsWithMagazines _unit;
	removeAllWeapons _unit;
	removeAllContainers _unit;

	If (_uniform != "") then {_unit addUniform _uniform;};
	If (_vest != "") then {_unit addVest _vest;};
	If (_headgear != "") then {_unit addHeadgear _headgear;};
	If (_classbag != "") then {_unit addBackpack _classbag;};

	{
		_unit addItem _x;
	} foreach _itemsunit;

	{
		_unit addItem _x;
		_unit assignItem _x;
	} foreach _assigneditems;

	{
		If (count _x > 0) then 
		{
			_array1 = _x select 0;
			_array2 = _x select 1;
			_index = -1;
			{
				_index = _index + 1;
				_magazineName = _x;
				_count = _array2 select _index;
				_unit addMagazines [_magazineName, _count];
			} foreach _array1;
		};
	} foreach _allmag;

	_index = -1;

	{
		_index = _index +1;
		_weapon = _x select 0;
		_item1 = _x select 1;
		_item2 = _x select 2;
		_item3 = _x select 3;
		_magweapon1 = (_x select 4) select 0;
		_magweapon2 = "";
		if (count _x > 5) then {_magweapon2 = (_x select 5) select 0};
	
		if (_index == 0) then {{_item = _x; If (_item != "") then {_unit addPrimaryWeaponItem _item;}} foreach [_item1,_item2,_item3];};
		if (_index == 1) then {};
		if (_index == 2) then {{_item = _x; If (_item != "") then {_unit addHandgunItem _item;}} foreach [_item1,_item2,_item3];};
	
		_unit addMagazineGlobal _magweapon1;
		If (_magweapon2 != "") then {_unit addMagazineGlobal _magweapon2;};
		_unit addWeaponGlobal _weapon;
	} foreach _weaponsunit;
};

UPSMON_checkmunition = {
	private ["_npc","_units","_result","_unit","_weapon","_magazineclass","_magazines","_result1","_result2","_weapon","_sweapon","_mags","_magazinescount","_smagazineclass"];
	
	_npc = _this select 0;
	_units = units _npc;
	_result = [];
	_result1 = [];
	_result2 = [];
	_minmag = 2;	

	{
		If (!IsNull _x && alive _x && vehicle _npc == _npc) then
		{
			_unit = _x;
			_weapon = currentweapon _unit;
			_sweapon = secondaryWeapon _unit;
			_magazineclass = getArray (configFile / "CfgWeapons" / _weapon / "magazines");
			_smagazineclass = [];
			If (_sweapon != "") then {_smagazineclass = getArray (configFile / "CfgWeapons" / _sweapon / "magazines");}; 
			
			if (count _magazineclass > 0) then 
			{
				_mags = magazinesAmmoFull _unit;
				_magazinescount = 0;
				{_magclass = _x; _magazinescount1 = {(_x select 0) == _magclass} count _mags;_magazinescount = _magazinescount + _magazinescount1;} foreach _magazineclass;
				If (_magazinescount <= 2 && !(_unit in _result1)) then {_result1 = _result1 + [_unit]};
			};
			
			if (count _smagazineclass > 0) then 
			{
				_mags = magazinesAmmoFull _unit;
				_magazinescount = 0;
				{_magclass = _x; _magazinescount1 = {(_x select 0) == _magclass} count _mags;_magazinescount = _magazinescount + _magazinescount1;} foreach _smagazineclass;
				If (_magazinescount <= 0 && !(_unit in _result2)) then {_result2 = _result2 + [_unit]};
			};
			
		};
		
	} foreach _units;

	_result = [_result1,_result2];
	_result
	
};

UPSMON_Checkratio = {

	private ["_grp","_allies","_enies","_pointsallies","_pointsenies","_ratedveh","_Itarget","_result","_points","_vehicle","_MagazinesUnit","_Cargo","_armor"];
	
	_grp = _this select 0;
	_allies = _this select 1;
	_enies = _this select 2;
	_pointsallies = 0;
	_pointsenies = 0;
	_ratedveh = [];
	_Itarget = [];

	_allies set [count _allies, _grp];
	
	{
		_points = 0;
		If(!IsNull _x) then
		{
			If (({alive _x} count units _grp) > 0) then
			{
				_points = _x getvariable ["UPSMON_Grpratio",0];
				_pointsallies = _pointsallies + _points;
			};
		};
	} count _allies > 0;
	
	{
		_eni = _x select 0;
		_position = _x select 1;
		_points = 0;
		If (!IsNull _eni) then
		{
			If (alive _eni) then
			{

				if ((vehicle _eni) != _eni && !(Isnull assignedVehicle _eni) && !(_eni in (assignedCargo assignedVehicle _eni))) then 
				{
					
					if (!((assignedVehicle _eni) in _ratedveh)) then 
					{
						_vehicle = assignedVehicle _eni;
						if ((typeof _vehicle) iskindof "TANK" || (typeof _vehicle) iskindof "Wheeled_APC" || (typeof _vehicle) iskindof "StaticWeapon" || (typeof _vehicle) iskindof "Air") then 
						{
							_Itarget set [count _Itarget, [_eni,_position]];
						};
						_points = _points + 1;
						_ratedveh set [count _ratedveh, _vehicle];
						_MagazinesUnit=(magazines _vehicle);
						_Cargo  = getNumber  (configFile >> "CfgVehicles" >> typeof _vehicle >> "transportSoldier");
						_armor  = getNumber  (configFile >> "CfgVehicles" >> typeof _vehicle >> "armor");				
						_gunner = gunner _vehicle;
						_ammorated = [];
					
					If (!IsNull _gunner) then
					{
						If (alive _gunner) then
						{
							{
								_ammo = tolower gettext (configFile >> "CfgMagazines" >> _x >> "ammo");
								_hit	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "hit");
								
								If (!(_ammo in _ammorated)) then
								{
									_ammorated set [count _ammorated,_ammo];
									_points = _points + _hit;
								};
						
							} foreach _MagazinesUnit;
						};
					};
						_points = _points + _armor;
					};		
				}
				else
				{
					_sweapon = secondaryWeapon _eni;
					_smagazineclass = [];
					_ammorated = [];
					If (_sweapon != "") then 
					{_smagazineclass = getArray (configFile >> "CfgWeapons" >> _sweapon >> "magazines");};
					_MagazinesUnit=(magazines _eni);
				
					_points = _points + 1;
				
					{
						_ammo = tolower gettext (configFile >> "CfgMagazines" >> _x >> "ammo");
						_hit	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "hit");
						If (!(_ammo in _ammorated)) then
						{
							_ammorated set [count _ammorated,_ammo];
							If (_ammo iskindof "ShellBase" || (_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase") && (_ammo in _smagazineclass)) then
							{
								_points = _points + _hit;
							};
						};
					} foreach _MagazinesUnit;
				};
				_pointsenies = _pointsenies + _points;
				_pointsenies = _pointsenies + ((1+(morale _eni)) + (1-(damage _eni)) + ((_eni skillFinal "Endurance") + (_eni skillFinal "courage")));
			};
		};
	} count _enies > 0;
	
	_ratio = _pointsenies/_pointsallies;
	
	_result = [_ratio,_Itarget];
	_result;
	
};

UPSMON_analysegrp = {
	private ["_grp","_assignedvehicles","_typeofgrp","_capacityofgrp","_result","_vehicleClass","_MagazinesUnit","_Cargo","_gunner","_ammo","_irlock","_laserlock","_airlock","_checkbag","_staticteam","_points"];
	_grp = _this select 0;
	
	_assignedvehicles = [];
	_typeofgrp = [];
	_capacityofgrp = [];
	_engagementrange = 600;
	_result = [];
	_points = 0;
	
	if (({alive _x} count units _grp) == 0) exitwith {_result = [_typeofgrp,_capacityofgrp,_assignedvehicles,_engagementrange];_result;};
	
	If (_grp in UPSMON_ARTILLERY_WEST_UNITS || _grp in UPSMON_ARTILLERY_EAST_UNITS || _grp in UPSMON_ARTILLERY_GUER_UNITS) then {_typeofgrp = _typeofgrp + ["arti"];};
	
	{
		If (alive _x) then
		{
			if ((vehicle _x) != _x && !(Isnull assignedVehicle _x) && !(_x in (assignedCargo assignedVehicle _x))) then 
			{
				if (!((assignedVehicle _x) in _assignedvehicles)) then 
				{
					_vehicle = assignedVehicle _x;
					_assignedvehicles set [count _assignedvehicles, _vehicle];
					_MagazinesUnit=(magazines _vehicle);
					_Cargo  = getNumber  (configFile >> "CfgVehicles" >> typeof _vehicle >> "transportSoldier");
					_armor  = getNumber  (configFile >> "CfgVehicles" >> typeof _vehicle >> "armor");
					_gunner = gunner _vehicle;
					_ammorated = [];
					
					_points = _points + 1;
					
					If (!IsNull _gunner) then
					{
						If (alive _gunner) then
						{
							{
								_ammo = tolower gettext (configFile >> "CfgMagazines" >> _x >> "ammo");
								_irlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "irLock");
								_laserlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "laserLock");
								_airlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "airLock");
								_hit	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "hit");
					
								if (_airlock==1 && (_ammo iskindof "BulletBase") && !("aa1" in _capacityofgrp)) then
								{_capacityofgrp = _capacityofgrp + ["aa1"];};
								if (_airlock==2 && !(_ammo iskindof "BulletBase") && !("aa2" in _capacityofgrp)) then
								{_capacityofgrp = _capacityofgrp + ["aa2"];};
								if ((_irlock>0 || _laserlock>0) && 
								((_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase")) && !("at2" in _capacityofgrp)) then
								{_capacityofgrp = _capacityofgrp + ["at2"];};
								if (_ammo iskindof "ShellBase" && !("at3" in _capacityofgrp)) then
								{_capacityofgrp = _capacityofgrp + ["at3"];};
								if (_ammo iskindof "BulletBase" && (_hit >= 40) && !("at1" in _capacityofgrp)) then
								{_capacityofgrp = _capacityofgrp + ["at1"];};
								If (!(_ammo in _ammorated)) then
								{
									_points = _points + _hit;
									_ammorated set [count _ammorated,_ammo];
								};
						
							} foreach _MagazinesUnit;
						};
					};
					
					_points = _points + _armor;

					
					if (_vehicle iskindof "car" && !("car" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["car"];};
					if (_vehicle iskindof "staticweapon" && !("static" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["static"];};
					if (_vehicle iskindof "tank" && !("tank" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["tank"];};
					if (_vehicle iskindof "Wheeled_APC_F" && !("apc" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["apc"];};
					if (_vehicle iskindof "air" && !("air" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["air"];};
					if (_vehicle iskindof "Ship" && !("ship" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["ship"];};
					if (_cargo > 0 && !("transport" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["transport"];};
					if (!(Isnull _gunner) && !("armed" in _typeofgrp)) then 
					{_typeofgrp = _typeofgrp + ["armed"];_engagementrange = 1000;};
					
				};		
			}
			else
			{
				_sweapon = secondaryWeapon _x;
				_MagazinesUnit=(magazines _x);
				_smagazineclass = [];
				If (_sweapon != "") then 
				{
					_smagazineclass = getArray (configFile >> "CfgWeapons" >> _sweapon >> "magazines");
				};
				_ammorated = [];
				
				_points = _points + 1;
				
				{
					_ammo = tolower gettext (configFile >> "CfgMagazines" >> _x >> "ammo");
					_irlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "irLock");
					_laserlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "laserLock");
					_airlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "airLock");
					_hit	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "hit");

					if (_airlock==2 && !(_ammo iskindof "BulletBase") && !("aa2" in _capacityofgrp) && (_ammo in _smagazineclass)) then
					{_capacityofgrp = _capacityofgrp + ["aa2"];};
					if ((_irlock>0 || _laserlock>0) && 
					((_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase")) && !("at2" in _capacityofgrp) && (_ammo in _smagazineclass)) then
					{_capacityofgrp = _capacityofgrp + ["at2"];_engagementrange = 1000;};
					if ((_irlock==0 || _laserlock==0) && 
					((_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase")) && !("at1" in _capacityofgrp) && (_ammo in _smagazineclass)) then
					{_capacityofgrp = _capacityofgrp + ["at1"];};
					
					If (_ammo iskindof "ShellBase" || (_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase") && !(_ammo in _ammorated) && (_ammo in _smagazineclass)) then
					{
						_points = _points + _hit;
						_ammorated set [count _ammorated,_ammo];
					};
				} foreach _MagazinesUnit;
				
				if (!("infantry" in _typeofgrp)) then 
				{_typeofgrp = _typeofgrp + ["infantry"];};
			};
			_points = _points + ((1+(morale _x)) + (1-(damage _x)) + ((_x skillFinal "Endurance") + (_x skillFinal "courage")));
		};
	
	} foreach units _grp;
	
	_checkbag = [_grp] call UPSMON_GetStaticTeam;
	_staticteam = _checkbag select 0;
	If (count _staticteam == 2) then
	{
		_capacityofgrp = _capacityofgrp + ["staticbag"];
		_engagementrange = 1000;
	};
	_points = _points/(count units _grp);
	_grp setvariable ["UPSMON_Grpratio",_points];
	
	if (UPSMON_Debug>0) then {diag_log format ["Grpcompos/ typeofgrp:%1 Capacity:%2 Assignedvehicles:%3 range:%4 Points:%5",_typeofgrp,_capacityofgrp,_assignedvehicles,_engagementrange,_points];};
	
	_result = [_typeofgrp,_capacityofgrp,_assignedvehicles,_engagementrange];
	_result;
};

UPSMON_composeteam = {
	private ["_grp","_units","_Assltteam","_Supportteam","_Atteam","_result","_units","_at","_unit","_weapon","_sweapon","_typeweapon"];
	_grp = _this select 0;
	_Assltteam = [];
	_Supportteam = [];
	_Atteam = [];
	_AAteam = [];
	_result = [];
	
	if (({alive _x} count units _grp) == 0) exitwith {_result = [_Supportteam,_Assltteam,_Atteam,_AAteam];_result;};
	
	_units = units _grp;
	// add leader and people to team 1
	_Supportteam = _Supportteam + [leader _grp];
	_units = _units - [leader _grp];
	_unitsleft = _units;
	_vehchecked = [];
	
	{
		sleep .01;
		_unit = _x;
		if (alive _unit) then
		{
			if (canmove _unit) then
			{
				if (!(fleeing _unit)) then
				{
					if (vehicle _unit == _unit || (vehicle _unit != _unit && !(Isnull assignedVehicle _unit) && _unit in (assignedCargo assignedVehicle _unit))) then
					{
						_weapon = currentweapon _unit;
						_sweapon = secondaryWeapon _unit;
						_typeweapon = tolower gettext (configFile / "CfgWeapons" / _weapon / "cursor");
						if (_sweapon != "") then 
						{
							_smagazineclass = (getArray (configFile / "CfgWeapons" / _sweapon / "magazines")) select 0;
							_ammo = tolower gettext (configFile >> "CfgMagazines" >> _smagazineclass >> "ammo");
							_irlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "irLock");
							_laserlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "laserLock");
							_airlock	= getNumber (configfile >> "CfgAmmo" >> _ammo >> "airLock");
					
							if (_airlock==2 && !(_ammo iskindof "BulletBase") && !(_unit in _AAteam)) then
							{_AAteam = _AAteam + [_unit];};
							if ((_irlock==0 || _laserlock==0) && 
							((_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase") || (_ammo iskindof "RocketBase") || (_ammo iskindof "MissileBase")) && !(_unit in _ATteam)) then
							{_Atteam = _Atteam + [_unit];};
						};
						if (!(_unit in _Supportteam) && (_typeweapon in ["mg","srifle"] ||  _sweapon != "")) then
						{
							_Supportteam set [count _Supportteam, _unit];
							_unitsleft = _unitsleft - [_unit];
						};
					}
					else
					{
						if !(vehicle _unit in _vehchecked) then
						{
							_vehchecked set [count _vehchecked, vehicle _unit];
							_driver = driver vehicle _unit;
							If (!IsNull _driver) then {_unitsleft = _unitsleft - [_driver];_Supportteam set [count _Supportteam, _driver];};
							_commander = effectiveCommander vehicle _unit;
							If (!IsNull _commander) then 
							{
								_gunner = gunner vehicle _x;
								if (!IsNull _gunner) then
								{
									_Supportteam set [count _Supportteam,_gunner];
									_unitsleft = _unitsleft - [_gunner];
									If !(_commander in _Supportteam) then
									{
										_Supportteam set [count _Supportteam,_commander];
										_unitsleft = _unitsleft - [_gunner];
									};
								};
							};
						};
					};
				}
				else
				{
					_unitsleft = _unitsleft - [_unit];
				};
			}
			else
			{
				_unitsleft = _unitsleft - [_unit];
			};
		};
	} foreach _units;
	
	//Add the rest to the Assltteam
	_Assltteam = (_unitsleft-_Supportteam);
	
	if (count _Supportteam <= 1 && count _Assltteam > 3) then 
	{
		_arr2 = _Assltteam;
		_arr2 resize 2;
		_Supportteam = _Supportteam + _arr2;
	};
	//diag_log str _Assltteam;
	//diag_log str _Supportteam;
	{_x assignTeam "RED"} foreach _Assltteam;
	{_x assignTeam "BLUE"} foreach _Supportteam;
	
	_result = [_Supportteam,_Assltteam,_Atteam,_AAteam];
	_result;
};

UPSMON_checkbackpack =
{
	private ["_backpack","_cfg","_parents","_result","_gun","_tripod","_gun"];
	
	_backpack = _this select 0;
	_cfg = (configFile >> "cfgVehicles" >> _backpack);
	_parents = [_cfg,true] call BIS_fnc_returnParents;
	
	_result = [];
	_gun = "";
	_tripod = [];
	
	if ("Weapon_Bag_Base" in _parents) then 
	{
		_gun = gettext (configFile >> "cfgVehicles" >> _backpack >> "assembleInfo" >> "assembleTo");
		_tripod = getarray (configFile >> "cfgVehicles" >> _backpack >> "assembleInfo" >> "base");
		_result = [_gun,_tripod];
	};

	_result
};

UPSMON_GetStaticTeam = 
{
	private ["_grp","_position","_targetpos","_result","_staticTeam","_vehicle","_tripods","_unit","_backpack","_lots"];
	_grp = _this select 0;
	
	_result = [];
	_staticTeam = [];
	_vehicle = [];
	_tripods = [];
	
	{
		if (alive _x) then
		{
			_unit = _x;
			_backpack = backpack _Unit;
			If (_backpack != "") then 
			{
				_lots = [_backpack] call UPSMON_checkbackpack;
				if (count _lots > 0) exitwith {_vehicle = _lots select 0; _tripods = _lots select 1; _staticTeam = _staticTeam + [_x];};
			};
		};
	} foreach units _grp;
	
	if (count _staticTeam > 0) then
	{
		
		{
			if (alive _x) then
			{
				_unit = _x;
				_backpack = backpack _Unit;
				If (_backpack != "") then 
				{
					if (_backpack in _tripods) exitwith {_staticTeam = _staticTeam + [_x];};
				};
			};
			
		} foreach units _grp;
	};

	_result = [_staticTeam,_vehicle];
	_result
};

UPSMON_Unpackbag = 
{
	private["_gunner","_assistant","_position","_targetPos","_group","_weapon","_wait","_weapon","_tripodBP","_dirTo"];

	_gunner = 		_this select 0;
	_assistant = 	_this select 1;
	_position =		_this select 2;
	_targetPos = 	_this select 3;
	_group = 		group _gunner;
	_weapon = 		objNull;
	_group setvariable ["UPSMON_Mountstatic",true];
	{
		_x doMove _position;
		_x disableAI "AUTOTARGET";
		_x disableAI "TARGET";
		_x disableAI "FSM";
	} forEach [_gunner,_assistant];

	waitUntil{unitReady _gunner};
	_gunner disableAI "move";
	_assistant disableAI "move";

	_assistant action ["PutBag",_assistant];
	_gunner action ["Assemble",unitbackpack _gunner];

	_wait = true;
	while {_wait} do {
		_weapon = nearestObject [_position,"StaticWeapon"];
		if (alive _weapon ||!alive _assistant || !alive _gunner) then {_wait = false};
		sleep 0.1;
	};
	
	if (alive _gunner) then
	{
		_tripodBP = nearestObject [_position,"B_HMG_01_support_F"];
		_weapon = nearestObject [_position,"StaticWeapon"];
		_dirTo = [position _weapon,_targetPos] call BIS_fnc_dirTo;
		_weapon setDir _dirTo;
		deleteVehicle _tripodBP;
		sleep 2;
		_gunner assignAsGunner _weapon;
		_gunner moveInGunner _weapon;
		_gunner enableAI "AUTOTARGET";
		_gunner enableAI "TARGET";
		_gunner enableAI "FSM";
		sleep 1;
		_gunner commandWatch _targetPos;
	};
	
	if (alive _assistant) then
	{
		_assistant enableAI "AUTOTARGET";
		_assistant enableAI "TARGET";
		_assistant enableAI "FSM";
	};
	
	_group setvariable ["UPSMON_Mountstatic",false];
};

UPSMON_Packbag = 
{
	private["_gunner","_assistant","_weapon","_B_weapon","_B_tripod","_array","_position"];

	_gunner = 	_this select 0;
	_assistant = 	_this select 1;
	_weapon = 	vehicle _gunner;

	_B_weapon = "";
	_B_tripod = "";
	_array = getarray (configFile >> "cfgVehicles" >> typeof _weapon >> "assembleInfo" >> "dissasembleTo");
	If (count _array > 0) then
	{
		_B_weapon = _array select 0;
		_B_tripod = _array select 1;
	};
	
	_position = position _weapon;
	unassignVehicle _gunner;
	_gunner action ["getOut", _weapon];
	doGetOut _gunner;
	[_gunner] allowGetIn false;
	
	
	sleep 0.5;
	deletevehicle _weapon;
	sleep 1;
	
	if (alive _gunner && alive _assistant) then
	{
		if (_B_weapon != "" && _B_tripod != "") then
		{
			_gunner addBackpack _B_weapon;
			_assistant addBackpack _B_tripod;
		};
		sleep 1;
		_assistant enableAI "move";
		_gunner enableAI "move";	
	};
};

////////////////////////////////////////////////////////////////////// Target Module ////////////////////////////////////////////////////////

UPSMON_TargetAcquisition = {

	private ["_grp","_shareinfo","_closeenough","_timeontarget","_timeinfo","_react","_npc","_NearestEnemy","_target","_opfknowval","_attackPos","_Enemies","_Allies","_targetsnear","_Units","_dist","_newattackPos","_newtarget","_lasttarget"];
	
	_grp = _this select 0;
	_shareinfo = _this select 1;
	_closeenough = _this select 2;
	_timeontarget = _this select 3;
	_timeinfo = _this select 4;
	_react = _this select 5;
	_accuracy = 1000;

	_npc = leader _grp;
	
	_NearestEnemy = objNull;
	_target = objNull;
	_opfknowval = 0;
	_attackPos = [0,0];
	_Enemies = [];
	_Allies = [];
	_targetsnear = false;
	
		
	_Units = [_npc] call UPSMON_findnearestenemy;
	_Enemies = _Units select 0;
	_Allies = _Units select 1;
	
	If (count _Enemies > 0) then
	{
		_NearestEnemy = (_Enemies select 0) select 0;
	};

		If (IsNull _NearestEnemy) then 
		{	
			//Reveal targets found by members to leader
			{
				_Units = [_x] call UPSMON_findnearestenemy;
				_Enemies = _Units select 0;
				
				If (count _Enemies > 0) then
				{
					_NearestEnemy = (_Enemies select 0) select 0;
				};
				
				if ((!IsNull _NearestEnemy) && (_x knowsabout _NearestEnemy > UPSMON_knowsAboutEnemy) 
				&& (_npc knowsabout _NearestEnemy <= UPSMON_knowsAboutEnemy)) then 	
				{		
	 
					_npc reveal [_NearestEnemy,_x knowsabout _NearestEnemy];	
				
					_target = _NearestEnemy;
					_opfknowval = _npc knowsabout _target;
					_accuracy = (_Enemies select 0) select 2;
					_NearestEnemy setvariable ["UPSMON_lastknownpos", (_Enemies select 0) select 1, false];						
					if (UPSMON_Debug>0) then {diag_log format["%1: %2 added to targets",typeof _x, typeof _target]}; 						
				};
			} foreach units (group _npc);
		}
		else
		{
			_target = _NearestEnemy;
			_opfknowval = _npc knowsabout _target;
			_accuracy = (_Enemies select 0) select 2;
			_NearestEnemy setvariable ["UPSMON_lastknownpos",(_Enemies select 0) select 1, false];
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
				_dist = ([getposATL _npc,_attackPos] call UPSMON_distancePosSqr);				
			};
			//Shareinfo with allied
			If (_shareinfo=="SHARE" && _timeinfo > 15) then
			{
				//player sidechat "Share Info";
				_timeinfo = 0;
				[_enemies,_npc] spawn UPSMON_Shareinfos;
			};
		};
					
		If (_dist <= 300) then {_targetsnear = true;};
		
		_newtarget = _target;
			
		_lastTarget = (_grp getvariable "UPSMON_Lastinfos") select 4;			
			//If you change the target changed direction flanking initialize
			if (!isNull (_newtarget) && alive _newtarget && (_newtarget != _lastTarget || isNull (_lastTarget)) ) then {
				_timeontarget = time + UPSMON_maxwaiting;
				//_react = UPSMON_react;
				_attackPos = _newtarget getvariable ("UPSMON_lastknownpos");
				_target = _newtarget;			
			};	
		
		_result = [_Enemies,_Allies,_target,_dist,_opfknowval,_targetsnear,_attackPos,_timeontarget,_timeinfo,_react,_accuracy];
		
		_result
};

UPSMON_findnearestenemy = {
	private["_npc","_targets","_enemies","_allies","_enemySides","_friendlySides","_side","_unit"];
	_npc = _this select 0;
	_npcpos= getposATL _npc;
	_enemies = [];
	_allies  = [];
	_targets = [];
	
	if (_npc isKindof "CAManBase") then 
	{_targets = _npc nearTargets 800;};
	if (_npc isKindof "car") then 
	{
		If ((!isNull gunner (vehicle _npc)) && (gunner (vehicle _npc) == _npc) ) then 
		{_targets = _npc nearTargets 1000;} else {_targets = _npc nearTargets 500;};
	};
	if (_npc isKindof "Tank" || _npc isKindof "Wheeled_APC" || _npc isKindof "Ship") then 
	{
		If (((!isNull gunner (vehicle _npc)) && (gunner (vehicle _npc) == _npc)) || ((!isNull commander (vehicle _npc)) && (commander (vehicle _npc) == _npc))) then 
		{_targets =  _npc nearTargets 1500;} else {_targets = _npc nearTargets 500;};
	};
	if (_npc isKindof "StaticWeapon") then 
	{_targets = _npc nearTargets 1000;};
	if (_npc isKindof "air") then 
	{
		if ((driver (vehicle _npc) == _npc) || ((!isNull gunner (vehicle _npc)) && (gunner (vehicle _npc) == _npc))) then 
		{_targets = _npc nearTargets 2000;};
	};
	
	_enemySides = _npc call BIS_fnc_enemySides;
	_friendlySides = _npc call BIS_fnc_friendlySides;
	
	{
		_position = (_x select 0);
		_unit = (_x select 4);
		_side = (_x select 2);
		_accuracy = (_x select 5);

		if (_side in _enemySides) then
		{
			if (_accuracy < 300) then
			{
				if (count crew _unit > 0) then
				{
					if ((side driver _unit) in _enemySides) then
					{
						_enemies set [count _enemies, [_unit,_position,_accuracy]];
					};
				};
			};
		};
		If (_unit == leader group _unit) then
		{
			if (_unit != _npc) then
			{
				If (_side in _friendlySides) then
				{
					if (group _unit in UPSMON_NPCs) then
					{
						if (round ([_position,_npcpos] call UPSMON_distancePosSqr) <= 800) then
						{
							if (count crew _unit > 0) then
							{
								if ((side driver _unit) in _friendlySides) then
								{
									_allies set [count _allies, _unit];
								};
							};
						};
					};
				};
			};
		};
		
	} forEach _targets;

	If (count _enemies > 0) then
	{
		_enemies = [_enemies, [], { _npcpos distance(_x select 0)}, "ASCEND"] call BIS_fnc_sortBy;

	};
	//if (UPSMON_Debug>0) then {diag_log format ["Targets found by %1: %2",_npc,_enemies];};
	
	_result = [_enemies,_allies];
	_result
};

UPSMON_Shareinfos = {

	private ["_enemies","_npc","_arrnpc","_side","_pos","_alliednpc","_alliedlead","_enemy"];
	
	_enemies = _this select 0;
	_npc = _this select 1;
	_arrnpc = UPSMON_NPCs - [group _npc];
	_side = side _npc;
	_pos = getposATL _npc;
	_alliednpc = [];
	
	{
		If (!IsNull _x) then
		{
			If (alive (leader _x)) then
			{
				If (_side == side _x) then
				{
					If (round ([_pos,getposATL (leader _x)] call UPSMON_distancePosSqr)  <= UPSMON_sharedist) then 
					{
						_alliednpc set [count _alliednpc,_x];
					};
				};
			};
		};
	} count _arrnpc > 0;

			
	{
		_alliedlead = leader _x;
		if (alive _alliedlead) then
		{
			{
				_enemy = _x select 0;
				sleep 0.02;
				If (!IsNull _npc) then
				{
					If (alive _npc) then
					{
						If (!(IsNull _enemy)) then
						{
							If (alive _enemy) then 
							{
								If (_alliedlead knowsabout _enemy == 0) then
								{
									_alliedlead reveal [_enemy,4];
									if (UPSMON_Debug>0) then {diag_log format ["Target shared by RR to %2: %3",_alliednpc,_enemy];};
								};
							};
						};
					};
				};
			} foreach _enemies;
			sleep 0.02;
		};
	} count _alliednpc > 0;
		
};