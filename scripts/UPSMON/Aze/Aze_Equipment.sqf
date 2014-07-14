Aze_getequipment = {
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

Aze_addequipment = {
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