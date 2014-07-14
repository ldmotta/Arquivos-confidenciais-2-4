// Arquivo de inicialização

if (!isServer && isNull player) then {isJIP=true;} else {isJIP=false;};
if (!isDedicated) then {waitUntil {!isNull player && isPlayer player};};
if (!isMultiplayer) then { enableSaving [true, true]; } else { enableSaving [true, true]; };
enableTeamSwitch false;


// _missionName = "TESTE PATROL";
// _missionVersion = "0.2";

//PARAMS
PARAMEDITMODE = true;
PARAMSHOWINTRO = false;


//Ocupation
#include "mission\occupation.hpp";


// waitUntil { !isNull player }; // Wait for player to initialize
null = [] execVM "briefing.sqf";

// //Init UPSMON scritp (must be run on all clients)
// call compile preprocessFileLineNumbers "scripts\UPSMON\!R\markerAlpha.sqf";
// call compile preprocessFileLineNumbers "scripts\fhqtt.sqf";
// call compile preprocessFileLineNumbers "scripts\Init_UPSMON.sqf";	



// waitUntil {time > 1};

// [
//     [["OPERACAO: "+_missionName,"<t align = 'center' shadow = '1' size = '0.8' font='PuristaBold'>%1</t>"],
// 	["<br/><br/>TESTANDO MÓDULO UPSMON E GROOEOS"],
//     ["","<t align = 'center'</t>"]],
//     0,0,"<t color='#FFFFFFFF' align='center'>%1</t>"
// ] spawn BIS_fnc_typeText;

// skiptime (paramsArray select 2);
// [(paramsArray select 4), "false"] execvm "Grass_Changer\grass_changer.sqf";

// //by psycho
// ["%1 --- Executing TcB AIS init.sqf",diag_ticktime] call BIS_fnc_logFormat;
// enableSaving [false,false];
// enableTeamswitch false;

// // TcB AIS Wounding System --------------------------------------------------------------------------
// if (!isDedicated) then {
// 	TCB_AIS_PATH = "ais_injury\";
// 	{[_x] call compile preprocessFile (TCB_AIS_PATH+"init_ais.sqf")} forEach (if (isMultiplayer) then {playableUnits} else {switchableUnits});		// execute for every playable unit
	
// 	//{[_x] call compile preprocessFile (TCB_AIS_PATH+"init_ais.sqf")} forEach (units group player);													// only own group - you cant help strange group members
	
// 	//{[_x] call compile preprocessFile (TCB_AIS_PATH+"init_ais.sqf")} forEach [p1,p2,p3,p4,p5];														// only some defined units
// };
// // --------------------------------------------------------------------------------------------------------------

// =========================== UPSMON INSTALATION ================================
//Init UPSMON scritp (must be run on all clients)
//Init UPSMON script
call compile preprocessFileLineNumbers "scripts\Init_UPSMON.sqf";

//Process statements stored using setVehicleInit
// processInitCommands;
//Finish world initialization before mission is launched. 
finishMissionInit;

setviewdistance 1800;

// [format["INFO: Starting %1 version %2 init load finished",_missionName,_missionVersion],"green"] spawn groo_fnc_consoleMSG;

// O código abaixo pode ser útil para o set_loadout
// [[[],"playerConnected.sqf"],"BIS_fnc_execVM",false,true] spawn BIS_fnc_MP;
// Executes playerConnected.sqf script on server every time a player joins the game.

player allowDamage false; player setCaptive true;
sleep 2;
hint 'left click on the map to teleport, you are in ghost mode';
onMapSingleClick "player setpos _pos";