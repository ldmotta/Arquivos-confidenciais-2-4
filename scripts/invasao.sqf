/**
 * ARMA3 Alpha Script de Invasão  versão 0.1  by M0TT4
 * Exemplo de uso: Adicione um GameLogic e no campo init, digit: nul = [this] execVM "invasao.sqf";
 *   OU: nul = [this, side, radius, spawn men, spawn vehicles, men ratio, vehicle ratio, special ["Behaviour", "Speed"]] execVM "militarize.sqf";
 *
 * Settings:
 *   side (0 = civilian, 1 = blue, 2 = red) PADRÃO: 2
 *   radius (from center position) PADRÃO: 150
 *   spawn men (true or false) PADRÃO: true
 *   spawn vehicles (true or false) PADRÃO: false
 *   men ratio (amount of spawning men is radius * men ratio, ie: 250 * 0.2 = 50 units) PADRÃO: 0.3
 *   vehicle ratio (amount of spawning vehicles is radius * vehicle ratio, ie: 250 * 0.1 = 25 vehicles) PADRÃO: 0.1
 *   special (lista com as opções de movimentação dos soldados que farão a invasão) PADRÃO: ["SAFE", "LIMITED"]
 *
 * Exemplo:
 *   nul = [this, 2, 150, true, false, 0.3, 0.02, ["AWARE", "FULL"]] execVM "invasao.sqf";
 *   Vai criar 45 unidades do teme vermelho, que irão invadir iniciando a um raio de 150m do gamelogic
 */

private ["_maxD","_mi","_dir","_range","_unitType","_unit","_radius","_men","_vehicles","_still","_centerPos","_menAmount","_vehAmount","_milHQ","_milGroup","_menArray","_blueMenArray","_redMenArray","_yellowMenArray","_sideOption","_vehArray","_vi","_pos","_blueCarArray","_redCarArray","_yellowCarArray","_sPos","_vCrew","_allUnitsArray","_menRatio","_vehRatio","_sPos2"];

_centerPos = getPos (_this select 0);
_sideOption = _this select 1;
_radius = _this select 2;
_men = _this select 3;
_vehicles = _this select 4;
_menRatio = _this select 5;
_vehRatio = _this select 6;
_Special = _this select 7;  // Is Behaviour, Speed

if(isNil("_sideOption"))then{_sideOption = 2;}else{_sideOption = _sideOption;};
if(isNil("_radius"))then{_radius = 150;}else{_radius = _radius;};
if(isNil("_men"))then{_men = true;}else{_men = _men;};
if(isNil("_vehicles"))then{_vehicles = false;}else{_vehicles = _vehicles;};
if(isNil("_menRatio"))then{_menRatio = 0.3;}else{_menRatio = _menRatio;};
if(isNil("_vehRatio"))then{_vehRatio = 0.02;}else{_vehRatio = _vehRatio;};
if(isNil("_Special"))then{_Special = ["SAFE", "LIMITED"];}else{_Special = _Special;};

// updated
_maxRange = _radius + 100;

// Special is 

_Behaviour = _Special select 0;
_Speed = _Special select 1;

if(isNil("_Behaviour"))then{_Behaviour = "SAFE";}else{_Behaviour = _Behaviour;};
if(isNil("_Speed"))then{_Speed = "LIMITED";}else{_Speed = _Speed;};

_menAmount = round (_radius * _menRatio);
_vehAmount = round (_radius * _vehRatio);

_allUnitsArray = [];

// All classes of the blue sodiers
_blueMenArray = ["B_soldier_AR_F","B_soldier_exp_F","B_Soldier_GL_F","B_soldier_M_F","B_medic_F","B_Soldier_F","B_soldier_repair_F","B_soldier_LAT_F","B_Soldier_SL_F","B_Soldier_lite_F","B_Soldier_TL_F"];

// All classes of the red sodiers
_redMenArray = ["O_Soldier_F","O_Soldier_AR_F","O_soldier_exp_F","O_Soldier_GL_F","O_soldier_M_F","O_medic_F","O_soldier_repair_F","O_Soldier_LAT_F","O_Soldier_lite_F","O_Soldier_SL_F","O_Soldier_TL_F"];

// All classes of the yellow sodiers
_yellowMenArray = ["C_man_1","C_man_polo_1_F","C_man_polo_2_F","C_man_polo_3_F","C_man_polo_4_F","C_man_polo_5_F","C_man_polo_6_F","C_man_1_1_F","C_man_1_2_F","C_man_1_3_F"];

// All classes of the blue cars
_blueCarArray = ["B_Hunter_F","B_Hunter_HMG_F","B_Hunter_RCWS_F","B_Quadbike_F"];

// All classes of the red cars
_redCarArray = ["O_Ifrit_F","O_Ifrit_GMG_F","O_Ifrit_MG_F","O_Quadbike_F"];

// All classes of the yellow cars
_yellowCarArray = ["c_offroad"];

// Decides about the side (0 = civilian, 1 = blue, 2 = red)
switch (_sideOption) do { 
    case 1: {
        _milHQ = createCenter west;
        _milGroup = createGroup west;
        _menArray = _blueMenArray;
        _vehArray = _blueCarArray;
    }; 
    case 2: {
        _milHQ = createCenter east;
        _milGroup = createGroup east;
        _menArray = _redMenArray;
        _vehArray = _redCarArray;
    }; 
    default {
        _milHQ = createCenter civilian;
        _milGroup = createGroup civilian;
        _menArray = _yellowMenArray;
        _vehArray = _yellowCarArray;
    }; 
};

// Vai ter unidades humanas
if(_men)then{
    _mi = 0;
    while {_mi < _menAmount}do{
        _mi = _mi + 1;
        _dir = random 360;
        _unitType = _menArray select (floor(random(count _menArray)));

        // Create a unit directly arround to _radius
        _range = (random(_maxRange - _radius)) + _radius;

        sleep 1;
        _spawnPos = [(_centerPos select 0) + (sin _dir) * _range, (_centerPos select 1) + (cos _dir) * _range, 0];
        if(surfaceIsWater _spawnPos)then{
            while{surfaceIsWater _spawnPos}do{
                _range = (random(_maxRange - _radius)) + _radius;
                _dir = _dir + 180;
                _spawnPos = [(_centerPos select 0) + (sin _dir) * _range, (_centerPos select 1) + (cos _dir) * _range, 0];
            };
        };
        
        hint formatText["%1", _spawnPos];

        _unit = _milGroup createUnit [_unitType, _spawnPos, [], 0, "NONE"];

        _unit setBehaviour _Behaviour;
        _unit setSpeedMode _Speed;
        _unit doMove _centerPos;

        _allUnitsArray = _allUnitsArray + [_unit];
    };
};
